-- JengaMate core schema for Supabase (Postgres)
-- Run this in Supabase SQL editor or via CLI.

-- 1) Helper: resolve current user id and role
create or replace function public.current_user_id()
returns uuid
language sql
stable
as $$
  select nullif(auth.uid()::text, '')::uuid;
$$;

create or replace function public.current_user_role()
returns text
language plpgsql
stable
as $$
declare r text;
begin
  select role into r from public.profiles where id = public.current_user_id();
  return r;
end;
$$;

-- 2) Profiles (public user profile shadowing auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  display_name text,
  role text check (role in ('admin','supplier','engineer')) default 'engineer',
  is_approved boolean default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_profiles_role on public.profiles(role);

alter table public.profiles enable row level security;

-- Policies: users manage own profile; admin sees all
create policy if not exists "profiles_select_self_or_admin"
  on public.profiles for select
  using (
    id = auth.uid() or exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
    )
  );

create policy if not exists "profiles_update_self_or_admin"
  on public.profiles for update
  using (
    id = auth.uid() or exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
    )
  ) with check (
    id = auth.uid() or exists (
      select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
    )
  );

-- 3) Taxonomies
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  parent_id uuid references public.categories(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.categories enable row level security;
create policy if not exists "categories_read_all" on public.categories for select using (true);
-- Admin manage categories
create policy if not exists "categories_admin_write" on public.categories for insert with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "categories_admin_update" on public.categories for update using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "categories_admin_delete" on public.categories for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 4) Products
create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  price numeric not null check (price >= 0),
  category_id uuid references public.categories(id) on delete set null,
  supplier_id uuid not null references public.profiles(id) on delete restrict,
  image_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_products_category on public.products(category_id);
create index if not exists idx_products_supplier on public.products(supplier_id);

alter table public.products enable row level security;
create policy if not exists "products_read_all" on public.products for select using (true);
-- Suppliers manage their products; admin manage all
create policy if not exists "products_insert_supplier_or_admin" on public.products for insert
  with check (supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "products_update_owner_or_admin" on public.products for update
  using (supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "products_delete_owner_or_admin" on public.products for delete
  using (supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 5) RFQs
create table if not exists public.rfqs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text,
  description text,
  status text check (status in ('open','in_progress','closed','cancelled')) default 'open',
  created_at timestamptz not null default now()
);

alter table public.rfqs enable row level security;
-- owner read; supplier/admin read (mirroring rules)
create policy if not exists "rfqs_read_owner_supplier_admin" on public.rfqs for select using (
  user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('supplier','admin'))
);
create policy if not exists "rfqs_insert_owner" on public.rfqs for insert with check (user_id = auth.uid());
create policy if not exists "rfqs_update_owner_supplier_admin" on public.rfqs for update using (
  user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('supplier','admin'))
);

-- 6) Quotes
create table if not exists public.quotes (
  id uuid primary key default gen_random_uuid(),
  rfq_id uuid not null references public.rfqs(id) on delete cascade,
  supplier_id uuid not null references public.profiles(id) on delete restrict,
  customer_id uuid references public.profiles(id) on delete set null,
  amount numeric not null check (amount >= 0),
  status text,
  created_at timestamptz not null default now()
);

create index if not exists idx_quotes_rfq on public.quotes(rfq_id);
create index if not exists idx_quotes_supplier on public.quotes(supplier_id);

alter table public.quotes enable row level security;
create policy if not exists "quotes_read_participants" on public.quotes for select using (
  supplier_id = auth.uid() or customer_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
create policy if not exists "quotes_insert_supplier" on public.quotes for insert with check (supplier_id = auth.uid());
create policy if not exists "quotes_update_participants_admin" on public.quotes for update using (
  supplier_id = auth.uid() or customer_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- 7) Orders
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id) on delete restrict,
  supplier_id uuid not null references public.profiles(id) on delete restrict,
  status text check (status in ('pending','confirmed','processing','shipped','delivered','cancelled','completed')) default 'pending',
  total_amount numeric not null check (total_amount >= 0),
  is_locked boolean default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_orders_buyer on public.orders(buyer_id);
create index if not exists idx_orders_supplier on public.orders(supplier_id);

alter table public.orders enable row level security;
create policy if not exists "orders_read_participants_or_admin" on public.orders for select using (
  buyer_id = auth.uid() or supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
create policy if not exists "orders_insert_buyer" on public.orders for insert with check (buyer_id = auth.uid());
create policy if not exists "orders_update_participants_admin" on public.orders for update using (
  buyer_id = auth.uid() or supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);

-- 8) Payments
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  amount numeric not null check (amount >= 0),
  status text check (status in ('processing','verified','rejected')) default 'processing',
  created_at timestamptz not null default now()
);

create index if not exists idx_payments_order on public.payments(order_id);

alter table public.payments enable row level security;
create policy if not exists "payments_read_order_participants" on public.payments for select using (
  exists (
    select 1 from public.orders o where o.id = payments.order_id and (o.buyer_id = auth.uid() or o.supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  )
);
create policy if not exists "payments_insert_buyer" on public.payments for insert with check (
  exists (select 1 from public.orders o where o.id = order_id and o.buyer_id = auth.uid())
);
create policy if not exists "payments_update_participants_admin" on public.payments for update using (
  exists (
    select 1 from public.orders o where o.id = payments.order_id and (o.buyer_id = auth.uid() or o.supplier_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'))
  )
);

-- 9) Chat
create table if not exists public.chat_rooms (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now()
);

create table if not exists public.chat_participants (
  room_id uuid references public.chat_rooms(id) on delete cascade,
  user_id uuid references public.profiles(id) on delete cascade,
  primary key (room_id, user_id)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.chat_rooms(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete restrict,
  content text not null check (char_length(content) <= 1000),
  timestamp timestamptz not null default now()
);

alter table public.chat_rooms enable row level security;
alter table public.chat_participants enable row level security;
alter table public.messages enable row level security;

-- Chat policies: participant read/write
create policy if not exists "chat_rooms_participant_read" on public.chat_rooms for select using (
  exists (select 1 from public.chat_participants cp where cp.room_id = id and cp.user_id = auth.uid())
);
create policy if not exists "chat_participants_self_read" on public.chat_participants for select using (
  user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')
);
create policy if not exists "messages_read_participant" on public.messages for select using (
  exists (select 1 from public.chat_participants cp where cp.room_id = messages.room_id and cp.user_id = auth.uid())
);
create policy if not exists "messages_insert_sender_participant" on public.messages for insert with check (
  sender_id = auth.uid() and exists (select 1 from public.chat_participants cp where cp.room_id = messages.room_id and cp.user_id = auth.uid())
);

-- 10) Notifications
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text,
  body text,
  is_read boolean default false,
  created_at timestamptz not null default now()
);

alter table public.notifications enable row level security;
create policy if not exists "notifications_self_read" on public.notifications for select using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "notifications_self_update_is_read" on public.notifications for update using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "notifications_insert_admin_or_supplier" on public.notifications for insert with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role in ('admin','supplier')));

-- 11) Reviews
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  rating int not null check (rating between 1 and 5),
  comment text,
  created_at timestamptz not null default now()
);

alter table public.reviews enable row level security;
create policy if not exists "reviews_read_all_auth" on public.reviews for select using (auth.uid() is not null);
create policy if not exists "reviews_insert_self" on public.reviews for insert with check (user_id = auth.uid());
create policy if not exists "reviews_update_delete_self_or_admin" on public.reviews for update using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "reviews_delete_self_or_admin" on public.reviews for delete using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 12) Withdrawals
create table if not exists public.withdrawals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount numeric not null check (amount > 0),
  status text default 'pending',
  created_at timestamptz not null default now()
);

alter table public.withdrawals enable row level security;
create policy if not exists "withdrawals_read_self_or_admin" on public.withdrawals for select using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "withdrawals_insert_supplier_self" on public.withdrawals for insert with check (user_id = auth.uid() and exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'supplier'));
create policy if not exists "withdrawals_update_admin" on public.withdrawals for update using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "withdrawals_delete_admin" on public.withdrawals for delete using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 13) Commission tiers and commissions
create table if not exists public.commission_tiers (
  id uuid primary key default gen_random_uuid(),
  role text not null check (role in ('engineer','supplier')),
  name text not null,
  badge_text text not null,
  badge_color text not null,
  min_products int not null default 0,
  min_total_value numeric not null default 0,
  rate_percent numeric not null check (rate_percent >= 0 and rate_percent <= 1),
  ord int not null default 0
);

alter table public.commission_tiers enable row level security;
create policy if not exists "commission_tiers_read_auth" on public.commission_tiers for select using (auth.uid() is not null);
create policy if not exists "commission_tiers_admin_write" on public.commission_tiers for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

create table if not exists public.commissions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  total numeric not null default 0,
  direct numeric not null default 0,
  referral numeric not null default 0,
  active numeric not null default 0,
  status text default 'pending',
  min_payout_threshold numeric not null default 0,
  metadata jsonb default '{}'::jsonb,
  updated_at timestamptz not null default now()
);

alter table public.commissions enable row level security;
create policy if not exists "commissions_read_self_or_admin" on public.commissions for select using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "commissions_admin_write" on public.commissions for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 14) Financial transactions
create table if not exists public.financial_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date timestamptz not null default now(),
  amount numeric not null,
  type text,
  reference text
);

alter table public.financial_transactions enable row level security;
create policy if not exists "transactions_read_self_or_admin" on public.financial_transactions for select using (user_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "transactions_insert_self" on public.financial_transactions for insert with check (user_id = auth.uid());

-- 15) Referrals
create table if not exists public.referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_id uuid not null references public.profiles(id) on delete cascade,
  referred_id uuid references public.profiles(id) on delete set null,
  status text default 'active',
  created_at timestamptz not null default now()
);

alter table public.referrals enable row level security;
create policy if not exists "referrals_read_self_or_admin" on public.referrals for select using (referrer_id = auth.uid() or exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "referrals_insert_self" on public.referrals for insert with check (referrer_id = auth.uid());

-- 16) Moderation items
create table if not exists public.moderation_items (
  id uuid primary key default gen_random_uuid(),
  status text default 'pending',
  payload jsonb default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.moderation_items enable row level security;
create policy if not exists "moderation_read_admin" on public.moderation_items for select using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));
create policy if not exists "moderation_admin_write" on public.moderation_items for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 17) Config (key/value)
create table if not exists public.app_config (
  key text primary key,
  value jsonb not null default '{}'::jsonb
);

alter table public.app_config enable row level security;
create policy if not exists "config_read_all_auth" on public.app_config for select using (auth.uid() is not null);
create policy if not exists "config_admin_write" on public.app_config for all using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin')) with check (exists (select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'));

-- 18) Storage buckets (to be created via Supabase dashboard or storage APIs):
-- buckets: product-images, user-uploads, payment-proofs
-- Add storage policies mirroring product ownership; omitted here for brevity.

-- Seed policy helper: ensure a profile exists for current auth user on signup via trigger (optional)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, email, display_name, role, is_approved)
  values (new.id, new.email, new.raw_user_meta_data->>'display_name', coalesce(new.raw_app_meta_data->>'role','engineer'), false)
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
