ALTER TABLE public.chat_rooms
ADD COLUMN product_id UUID REFERENCES public.products(id);

CREATE INDEX ON public.chat_rooms (product_id);
