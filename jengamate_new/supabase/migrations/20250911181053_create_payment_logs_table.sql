CREATE TABLE public.payment_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id TEXT NOT NULL,
    event TEXT NOT NULL,
    level TEXT DEFAULT 'INFO',
    error_message TEXT,
    metadata JSONB,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
    user_id UUID
);

ALTER TABLE public.payment_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Enable read access for authenticated users"
ON public.payment_logs FOR SELECT
USING (auth.uid() IS NOT NULL);

CREATE INDEX ON public.payment_logs (timestamp);
