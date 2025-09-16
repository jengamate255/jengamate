-- Migration: add text search helper functions to find records by non-UUID identifiers
-- This helps clients pass legacy IDs (like Firebase IDs) and still resolve
-- the intended resource by performing a safe text-based lookup.

-- RPC to find payment by text id or fallback to uuid
CREATE OR REPLACE FUNCTION public.payments_find(p_id text)
RETURNS SETOF payments AS $$
BEGIN
  -- If input is a valid UUID, match by id
  IF p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN QUERY SELECT * FROM payments WHERE id::text = p_id;
  END IF;

  -- Otherwise attempt to match by transaction_id or metadata fields
  RETURN QUERY
    SELECT * FROM payments
    WHERE transaction_id = p_id
       OR (metadata->>'received_id') = p_id
       OR user_id::text = p_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RPC to find orders by text id or fallback to uuid
CREATE OR REPLACE FUNCTION public.orders_find(p_id text)
RETURNS SETOF orders AS $$
BEGIN
  IF p_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
    RETURN QUERY SELECT * FROM orders WHERE id::text = p_id;
  END IF;

  RETURN QUERY
    SELECT * FROM orders
    WHERE external_id = p_id
       OR customer_id::text = p_id
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


