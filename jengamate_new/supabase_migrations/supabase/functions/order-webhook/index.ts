import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { orderId, eventType, metadata } = await req.json()

    if (!orderId || !eventType) {
      throw new Error('orderId and eventType are required')
    }

    // Create Supabase admin client
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        }
      }
    )

    // Get order details
    const { data: order, error: orderError } = await supabaseAdmin
      .from('orders')
      .select(`
        *,
        customer:profiles!orders_customer_id_fkey(*),
        supplier:profiles!orders_supplier_id_fkey(*),
        order_items(*, product:products(*))
      `)
      .eq('id', orderId)
      .single()

    if (orderError || !order) {
      throw new Error(`Order not found: ${orderError?.message}`)
    }

    // Handle different event types
    switch (eventType) {
      case 'order_created':
        await handleOrderCreated(supabaseAdmin, order, metadata)
        break
      case 'order_updated':
        await handleOrderUpdated(supabaseAdmin, order, metadata)
        break
      case 'payment_received':
        await handlePaymentReceived(supabaseAdmin, order, metadata)
        break
      case 'order_shipped':
        await handleOrderShipped(supabaseAdmin, order, metadata)
        break
      case 'order_delivered':
        await handleOrderDelivered(supabaseAdmin, order, metadata)
        break
      default:
        console.log(`Unhandled event type: ${eventType}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: `Order webhook processed for event: ${eventType}`
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('Error in order webhook:', error)
    return new Response(
      JSON.stringify({
        error: error.message,
        details: error.stack
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        status: 400,
      }
    )
  }
})

async function handleOrderCreated(supabaseAdmin: any, order: any, metadata: any) {
  // Create audit log
  await supabaseAdmin.from('audit_log').insert({
    user_id: order.customer_id,
    action: 'create',
    resource_type: 'order',
    resource_id: order.id,
    old_values: null,
    new_values: order,
  })

  // Send notification to supplier
  await createNotification(supabaseAdmin, {
    user_id: order.supplier_id,
    title: 'New Order Received',
    message: `You have received a new order #${order.order_number} from ${order.customer.first_name}`,
    type: 'order',
    data: { order_id: order.id }
  })

  // Send notification to customer
  await createNotification(supabaseAdmin, {
    user_id: order.customer_id,
    title: 'Order Placed Successfully',
    message: `Your order #${order.order_number} has been placed successfully`,
    type: 'order',
    data: { order_id: order.id }
  })

  // Update order status if needed
  if (order.status === 'pending') {
    await supabaseAdmin
      .from('orders')
      .update({ status: 'processing' })
      .eq('id', order.id)
  }
}

// Helper: post event to Firebase syncing endpoint (idempotent upserts expected on the receiver)
async function postToFirebase(resource: string, eventType: string, payload: any) {
  try {
    const firebaseUrl = Deno.env.get('FIREBASE_SYNC_URL');
    const firebaseSecret = Deno.env.get('FIREBASE_SYNC_SECRET');
    if (!firebaseUrl) {
      console.log('FIREBASE_SYNC_URL not configured, skipping Firebase sync');
      return;
    }

    const resp = await fetch(firebaseUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-sync-secret': firebaseSecret ?? '',
      },
      body: JSON.stringify({ resource, eventType, payload }),
    });

    if (!resp.ok) {
      const text = await resp.text();
      console.error(`Failed to post ${resource} ${eventType} to Firebase: ${resp.status} ${text}`);
    } else {
      console.log(`Posted ${resource} ${eventType} to Firebase successfully`);
    }
  } catch (e) {
    console.error('postToFirebase error', e);
  }
}

async function handleOrderUpdated(supabaseAdmin: any, order: any, metadata: any) {
  // Create audit log
  await supabaseAdmin.from('audit_log').insert({
    user_id: metadata.updated_by || order.customer_id,
    action: 'update',
    resource_type: 'order',
    resource_id: order.id,
    old_values: metadata.old_values,
    new_values: metadata.new_values,
  })

  // Send notifications based on status change
  if (metadata.old_values?.status !== metadata.new_values?.status) {
    const statusMessages = {
      'shipped': 'Your order has been shipped',
      'delivered': 'Your order has been delivered',
      'cancelled': 'Your order has been cancelled',
      'refunded': 'Your order has been refunded',
    }

    if (statusMessages[order.status]) {
      await createNotification(supabaseAdmin, {
        user_id: order.customer_id,
        title: 'Order Status Updated',
        message: statusMessages[order.status],
        type: 'order_update',
        data: { order_id: order.id, new_status: order.status }
      })
    }
  }
}

async function handlePaymentReceived(supabaseAdmin: any, order: any, metadata: any) {
  // Update order payment status
  await supabaseAdmin
    .from('orders')
    .update({
      payment_status: 'paid',
      status: order.status === 'pending' ? 'processing' : order.status
    })
    .eq('id', order.id)

  // Create financial transaction
  await supabaseAdmin.from('financial_transactions').insert({
    user_id: order.customer_id,
    type: 'payment',
    amount: order.total_amount,
    currency: order.currency,
    description: `Payment for order #${order.order_number}`,
    reference_id: order.id,
    order_id: order.id,
  })

  // Send notifications
  await createNotification(supabaseAdmin, {
    user_id: order.customer_id,
    title: 'Payment Confirmed',
    message: `Payment of ${order.currency} ${order.total_amount} for order #${order.order_number} has been confirmed`,
    type: 'payment',
    data: { order_id: order.id, amount: order.total_amount }
  })

  await createNotification(supabaseAdmin, {
    user_id: order.supplier_id,
    title: 'Payment Received',
    message: `Payment of ${order.currency} ${order.total_amount} received for order #${order.order_number}`,
    type: 'payment',
    data: { order_id: order.id, amount: order.total_amount }
  })

  // Post payment event to Firebase sync endpoint so Firestore is kept in sync
  try {
    await postToFirebase('payment', 'created', {
      id: metadata.payment_id || metadata.paymentId || null,
      order_id: order.id,
      orderId: order.id,
      amount: metadata.amount ?? order.total_amount,
      payment_method: metadata.payment_method ?? 'unknown',
      status: metadata.status ?? 'completed',
      payment_proof_url: metadata.payment_proof_url ?? null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      metadata: metadata,
    });
  } catch (e) {
    console.error('Failed to post payment event to Firebase', e);
  }
}

async function handleOrderShipped(supabaseAdmin: any, order: any, metadata: any) {
  await createNotification(supabaseAdmin, {
    user_id: order.customer_id,
    title: 'Order Shipped',
    message: `Your order #${order.order_number} has been shipped${order.tracking_number ? ` with tracking number: ${order.tracking_number}` : ''}`,
    type: 'shipping',
    data: { order_id: order.id, tracking_number: order.tracking_number }
  })
}

async function handleOrderDelivered(supabaseAdmin: any, order: any, metadata: any) {
  await createNotification(supabaseAdmin, {
    user_id: order.customer_id,
    title: 'Order Delivered',
    message: `Your order #${order.order_number} has been delivered successfully`,
    type: 'delivery',
    data: { order_id: order.id }
  })

  // Create commission entry for supplier
  const commissionAmount = calculateCommission(order.total_amount, order.supplier.role)
  if (commissionAmount > 0) {
    await supabaseAdmin.from('user_commissions').insert({
      user_id: order.supplier_id,
      order_id: order.id,
      amount: commissionAmount,
      status: 'pending',
    })
  }
}

async function createNotification(supabaseAdmin: any, notification: any) {
  await supabaseAdmin.from('notifications').insert({
    ...notification,
    created_at: new Date().toISOString(),
    read: false,
  })
}

function calculateCommission(orderAmount: number, userRole: string): number {
  // Simple commission calculation - can be made more sophisticated
  const commissionRate = userRole === 'supplier' ? 0.05 : 0.02 // 5% for suppliers, 2% for others
  return orderAmount * commissionRate
}
