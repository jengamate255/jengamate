import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { initializeApp, getApps, cert } from 'npm:firebase-admin/app'
import { getAuth } from 'npm:firebase-admin/auth'

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
    const { firebaseIdToken } = await req.json()
    if (!firebaseIdToken) {
      throw new Error('Firebase ID token is required')
    }

    // Initialize Firebase Admin if not already initialized
    if (getApps().length === 0) {
      initializeApp({
        credential: cert({
          projectId: Deno.env.get('FIREBASE_PROJECT_ID'),
          clientEmail: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
          privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
        })
      })
    }

    const auth = getAuth()

    // Verify the Firebase token
    const decodedToken = await auth.verifyIdToken(firebaseIdToken)
    const { uid, email, phone_number } = decodedToken

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

    // Try to get the user by email
    const { data: existingUser, error: getUserError } = await supabaseAdmin.auth.admin.listUsers({
      filter: {
        email: email || `${uid}@firebase.user`,
      },
    })

    if (!getUserError && existingUser?.users?.length > 0) {
      // User exists, generate a new session
      const { data: signInData, error: signInError } = await supabaseAdmin.auth.admin.generateLink({
        type: 'magiclink',
        email: email || `${uid}@firebase.user`,
      })

      if (signInError) throw signInError

      return new Response(
        JSON.stringify({
          supabaseAccessToken: signInData.properties.access_token,
          supabaseRefreshToken: signInData.properties.refresh_token,
        }),
        {
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          },
        }
      )
    }

    // User doesn't exist, create a new one
    const { data: newUser, error: createError } = await supabaseAdmin.auth.admin.createUser({
      email: email || `${uid}@firebase.user`,
      email_confirm: true,
      phone: phone_number,
      phone_confirm: true,
      user_metadata: {
        firebase_uid: uid,
      },
    })

    if (createError) throw createError

    // Generate a session for the new user
    const { data: signInData, error: signInError } = await supabaseAdmin.auth.admin.generateLink({
      type: 'magiclink',
      email: email || `${uid}@firebase.user`,
    })

    if (signInError) throw signInError

    return new Response(
      JSON.stringify({
        supabaseAccessToken: signInData.properties.access_token,
        supabaseRefreshToken: signInData.properties.refresh_token,
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      }
    )
  } catch (error) {
    console.error('Error in exchange-firebase-token:', error)
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