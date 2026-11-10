-- Calls for you (SPEC: Calls for you; D-141): bots place outbound phone calls through the
-- workspace's Twilio account, on the live-voice stack.
create table public.org_telephony (
  org_id uuid primary key references public.organizations (id) on delete cascade,
  provider text not null default 'twilio' check (provider in ('twilio')),
  account_sid text not null check (account_sid ~ '^AC[0-9a-fA-F]{32}$'),
  from_number text not null check (from_number ~ '^\+[1-9][0-9]{7,14}$'),
  vault_secret_id uuid not null,
  -- Business numbers by default: consumer numbers (by Twilio Lookup) need this on.
  allow_personal_numbers boolean not null default false,
  daily_cap integer not null default 10 check (daily_cap between 0 and 500),
  updated_at timestamptz not null default now()
);
alter table public.org_telephony enable row level security;
create policy org_telephony_select on public.org_telephony for select to authenticated using (public.has_role(org_id, 'admin'));
select public.allow_worker('public.org_telephony');

-- Numbers bots may never call (Kasama Cloud keeps a list; self-hosters can add their own).
create table public.call_deny_list (
  prefix text primary key check (prefix ~ '^\+[0-9]{1,15}$'),
  reason text,
  created_at timestamptz not null default now()
);
alter table public.call_deny_list enable row level security;
select public.allow_worker('public.call_deny_list');

-- A person's own phone, for taking over a call.
alter table public.profiles add column phone_number text check (phone_number is null or phone_number ~ '^\+[1-9][0-9]{7,14}$');

create table public.outbound_calls (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  number text not null,
  purpose text not null check (char_length(purpose) between 1 and 500),
  notes text check (char_length(notes) <= 4000),
  status text not null default 'queued' check (status in ('queued', 'ringing', 'in_progress', 'completed', 'failed', 'busy', 'no_answer', 'ended_by_user', 'taken_over')),
  provider_call_id text,
  -- The stream's one-time secret (only its hash is kept).
  stream_token_hash text not null,
  transcript jsonb not null default '[]'::jsonb,
  seconds integer,
  error text,
  started_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now()
);
create index outbound_calls_org_day_idx on public.outbound_calls (org_id, created_at desc);
alter table public.outbound_calls enable row level security;
create policy outbound_calls_select on public.outbound_calls for select to authenticated using (user_id = (select auth.uid()) or public.can_manage_bot(bot_id));
select public.allow_worker('public.outbound_calls');

alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'stt_seconds',
                  'voice_seconds', 'media_images', 'media_video_seconds', 'search_queries', 'data_calls', 'phone_minutes'));
