-- Casama Cloud pricing (D-244): Free, Plus, Pro and Max, with yearly at ten months' price. Limits
-- live in plans.limits and are editable from the Admin screen; saving a plan recomputes every
-- workspace on it. Self-hosted servers keep the 'selfhost' plan and never read these rows.

alter table public.credit_packs add column if not exists price_label text;

-- Daily spend on Casama's model key moves from code into the plan (cloud_daily_usd).
insert into public.plans (code, name, interval, limits, store_product_ids, sort, price_label) values
  ('free', 'Free', 'none',
   '{"credit_gate": true, "monthly_credits_usd": 1, "max_bots": 2, "max_computers": 1, "computer_hours": 5, "seats": 1, "cloud_daily_usd": 0.25}',
   '{}', 0, null),
  ('plus', 'Plus', 'month',
   '{"credit_gate": true, "monthly_credits_usd": 5, "max_bots": 5, "max_computers": 2, "computer_hours": 30, "seats": 2, "cloud_daily_usd": 5}',
   '{"app_store": "ai.casama.plus.monthly", "google_play": "casama_plus:monthly"}', 1, '$15 / month'),
  ('plus_yearly', 'Plus (yearly)', 'year',
   '{"credit_gate": true, "monthly_credits_usd": 5, "max_bots": 5, "max_computers": 2, "computer_hours": 30, "seats": 2, "cloud_daily_usd": 5}',
   '{"app_store": "ai.casama.plus.yearly", "google_play": "casama_plus:yearly"}', 2, '$150 / year'),
  ('pro', 'Pro', 'month',
   '{"credit_gate": true, "monthly_credits_usd": 10, "max_bots": 20, "max_computers": 5, "computer_hours": 100, "seats": 5, "cloud_daily_usd": 10}',
   '{"app_store": "ai.casama.pro.monthly", "google_play": "casama_pro:monthly"}', 3, '$39 / month'),
  ('pro_yearly', 'Pro (yearly)', 'year',
   '{"credit_gate": true, "monthly_credits_usd": 10, "max_bots": 20, "max_computers": 5, "computer_hours": 100, "seats": 5, "cloud_daily_usd": 10}',
   '{"app_store": "ai.casama.pro.yearly", "google_play": "casama_pro:yearly"}', 4, '$390 / year'),
  ('max', 'Max', 'month',
   '{"credit_gate": true, "monthly_credits_usd": 50, "max_bots": 50, "max_computers": 10, "computer_hours": 400, "seats": 10, "cloud_daily_usd": 25}',
   '{"app_store": "ai.casama.max.monthly", "google_play": "casama_max:monthly"}', 5, '$149 / month'),
  ('max_yearly', 'Max (yearly)', 'year',
   '{"credit_gate": true, "monthly_credits_usd": 50, "max_bots": 50, "max_computers": 10, "computer_hours": 400, "seats": 10, "cloud_daily_usd": 25}',
   '{"app_store": "ai.casama.max.yearly", "google_play": "casama_max:yearly"}', 6, '$1,490 / year')
on conflict (code) do update set
  name = excluded.name, interval = excluded.interval, limits = excluded.limits,
  store_product_ids = excluded.store_product_ids, sort = excluded.sort,
  price_label = excluded.price_label, active = true;

-- Store packs cost more than their face value (the stores keep 15–30%); web checkout is face value.
insert into public.credit_packs (code, name, credits_usd, store_product_ids, price_label) values
  ('credits_10', '$10 of credits', 10, '{"app_store": "ai.casama.credits.10", "google_play": "casama_credits_10"}', '$10'),
  ('credits_25', '$25 of credits', 25, '{"app_store": "ai.casama.credits.25", "google_play": "casama_credits_25"}', '$25')
on conflict (code) do update set
  name = excluded.name, credits_usd = excluded.credits_usd,
  store_product_ids = excluded.store_product_ids, price_label = excluded.price_label, active = true;

-- Workspaces keep their plan; refresh their copy of its limits (owner overrides stay on top).
update public.entitlements e
   set limits = p.limits || coalesce(e.overrides, '{}'::jsonb), updated_at = now()
  from public.plans p
 where p.code = e.plan_code and e.plan_code <> 'selfhost';

-- ---------------------------------------------------------------------------
-- Server-wide billing settings (one row), editable from the Admin screen.
-- ---------------------------------------------------------------------------
create table public.billing_settings (
  id boolean primary key default true check (id),
  -- Charged on top of what Casama pays for metered usage on its own keys (docs/COSTS.md).
  markup numeric(6, 3) not null default 1.3 check (markup >= 1),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);
insert into public.billing_settings (id) values (true) on conflict do nothing;
alter table public.billing_settings enable row level security;
-- Only the server reads and writes it.
revoke all on public.billing_settings from anon, authenticated;

-- ---------------------------------------------------------------------------
-- Seats: the plan's seat count holds for every way someone joins a workspace.
-- ---------------------------------------------------------------------------
create or replace function public.enforce_seats()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_limit jsonb;
  v_count int;
begin
  select e.limits -> 'seats' into v_limit
  from public.entitlements e where e.org_id = new.org_id
  order by e.created_at desc limit 1;
  if v_limit is null or jsonb_typeof(v_limit) <> 'number' then return new; end if;

  -- Two joins at once can't both take the last seat.
  perform pg_advisory_xact_lock(hashtext('seats:' || new.org_id::text));
  select count(*)::int into v_count from public.memberships m
  where m.org_id = new.org_id and m.user_id <> new.user_id;
  if v_count >= (v_limit #>> '{}')::numeric then
    raise exception 'This workspace''s plan allows % people. Upgrade to add more.', v_limit #>> '{}'
      using errcode = 'PT402', detail = 'plan_limit';
  end if;
  return new;
end;
$$;

drop trigger if exists memberships_enforce_seats on public.memberships;
create trigger memberships_enforce_seats before insert or update of org_id on public.memberships
  for each row execute function public.enforce_seats();

-- Calls through the server's Composio account are metered (app_calls).
alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'stt_seconds',
                  'voice_seconds', 'media_images', 'media_video_seconds', 'search_queries', 'data_calls', 'phone_minutes',
                  'app_calls'));
