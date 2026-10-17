
-- =========================================================
-- DEVY BEAUTY BAR
-- ROYAL SCRATCH & WIN DATABASE
-- Supabase PostgreSQL
-- =========================================================

create extension if not exists pgcrypto;

-- =========================================================
-- 1. MANAGER ACCESS
-- Add the manager's Supabase Auth user ID here after
-- creating the manager account.
-- =========================================================

create table if not exists public.manager_users (
    user_id uuid primary key references auth.users(id) on delete cascade,
    created_at timestamptz not null default now()
);

alter table public.manager_users enable row level security;

revoke all on public.manager_users from anon, authenticated;
grant select on public.manager_users to authenticated;

-- Only an existing manager can read manager membership.
create policy "Managers can view manager membership"
on public.manager_users
for select
to authenticated
using (
    user_id = (select auth.uid())
);

-- =========================================================
-- 2. CUSTOMERS
-- =========================================================

create table if not exists public.customers (
    id uuid primary key default gen_random_uuid(),

    full_name text not null,
    phone text,
    email text,

    entry_status text not null default 'pending'
        check (entry_status in ('pending', 'completed')),

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create index if not exists customers_created_at_idx
on public.customers (created_at desc);

create index if not exists customers_phone_idx
on public.customers (phone);

alter table public.customers enable row level security;

revoke all on public.customers from anon, authenticated;
grant select, insert, update, delete
on public.customers to authenticated;

create policy "Managers can read customers"
on public.customers
for select
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can insert customers"
on public.customers
for insert
to authenticated
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can update customers"
on public.customers
for update
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can delete customers"
on public.customers
for delete
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

-- =========================================================
-- 3. PRIZES
-- =========================================================

create table if not exists public.prizes (
    id uuid primary key default gen_random_uuid(),

    name text not null unique,
    description text,

    stock_quantity integer not null default 0
        check (stock_quantity >= 0),

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

alter table public.prizes enable row level security;

revoke all on public.prizes from anon, authenticated;
grant select, insert, update, delete
on public.prizes to authenticated;

create policy "Managers can read prizes"
on public.prizes
for select
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can insert prizes"
on public.prizes
for insert
to authenticated
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can update prizes"
on public.prizes
for update
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can delete prizes"
on public.prizes
for delete
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

-- =========================================================
-- 4. SCRATCH ENTRIES / PRIZE WINS
-- =========================================================

create table if not exists public.scratch_entries (
    id uuid primary key default gen_random_uuid(),

    customer_id uuid not null
        references public.customers(id) on delete restrict,

    prize_id uuid
        references public.prizes(id) on delete restrict,

    entry_code text unique,

    status text not null default 'pending'
        check (status in ('pending', 'completed')),

    created_at timestamptz not null default now()
);

create index if not exists scratch_entries_customer_idx
on public.scratch_entries (customer_id);

create index if not exists scratch_entries_prize_idx
on public.scratch_entries (prize_id);

alter table public.scratch_entries enable row level security;

revoke all on public.scratch_entries from anon, authenticated;
grant select, insert, update, delete
on public.scratch_entries to authenticated;

create policy "Managers can read scratch entries"
on public.scratch_entries
for select
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can insert scratch entries"
on public.scratch_entries
for insert
to authenticated
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can update scratch entries"
on public.scratch_entries
for update
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can delete scratch entries"
on public.scratch_entries
for delete
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

-- =========================================================
-- 5. PRIZE REDEMPTIONS
-- =========================================================

create table if not exists public.redemptions (
    id uuid primary key default gen_random_uuid(),

    scratch_entry_id uuid not null unique
        references public.scratch_entries(id) on delete restrict,

    redeemed_by uuid references auth.users(id) on delete set null,

    redeemed_at timestamptz not null default now(),

    notes text
);

create index if not exists redemptions_redeemed_at_idx
on public.redemptions (redeemed_at desc);

alter table public.redemptions enable row level security;

revoke all on public.redemptions from anon, authenticated;
grant select, insert, update, delete
on public.redemptions to authenticated;

create policy "Managers can read redemptions"
on public.redemptions
for select
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can insert redemptions"
on public.redemptions
for insert
to authenticated
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
    and redeemed_by = (select auth.uid())
);

create policy "Managers can update redemptions"
on public.redemptions
for update
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
)
with check (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

create policy "Managers can delete redemptions"
on public.redemptions
for delete
to authenticated
using (
    exists (
        select 1
        from public.manager_users m
        where m.user_id = (select auth.uid())
    )
);

-- =========================================================
-- 6. AUTOMATIC UPDATED_AT
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

drop trigger if exists customers_set_updated_at
on public.customers;

create trigger customers_set_updated_at
before update on public.customers
for each row
execute function public.set_updated_at();

drop trigger if exists prizes_set_updated_at
on public.prizes;

create trigger prizes_set_updated_at
before update on public.prizes
for each row
execute function public.set_updated_at();

-- =========================================================
-- 7. DASHBOARD SUMMARY VIEW
-- =========================================================

create or replace view public.manager_dashboard_summary
with (security_invoker = true)
as
select
    (select count(*) from public.customers) as total_customers,

    (select count(*)
     from public.customers
     where entry_status = 'completed') as completed_entries,

    (select count(*)
     from public.scratch_entries
     where prize_id is not null) as prize_wins,

    (select count(*)
     from public.redemptions) as redeemed_prizes;

revoke all on public.manager_dashboard_summary
from anon, authenticated;

grant select on public.manager_dashboard_summary
to authenticated;

-- =========================================================
-- 8. SECURITY NOTE
-- No public customer-data access is granted here.
-- Manager access requires Supabase Auth AND a matching
-- row in public.manager_users.
--
-- Create the manager account first, then add its user ID:
--
-- INSERT INTO public.manager_users (user_id)
-- VALUES ('YOUR-MANAGER-AUTH-USER-UUID');
--
-- Do not insert a placeholder UUID.
-- Never expose a service_role key in browser JavaScript.
-- =========================================================
