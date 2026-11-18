-- Ask for a secret in chat (SPEC: Post-v1 roadmap → Ask for a secret; D-101). A bot's
-- secrets.request waits durably for a person to save a value through a protected card; the value
-- goes from the card to the API and into Vault, never into messages, events, logs or model input.

create table public.secret_requests (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  run_id uuid not null references public.runs (id) on delete cascade,
  conversation_id uuid references public.conversations (id) on delete set null,
  name text not null check (name ~ '^[A-Z][A-Z0-9_]{0,63}$'),
  service text not null check (char_length(service) between 1 and 80),
  allowed_hosts text[] not null check (cardinality(allowed_hosts) between 1 and 10),
  reason text not null default '' check (char_length(reason) <= 1000),
  status text not null default 'pending' check (status in ('pending', 'fulfilled', 'declined', 'expired')),
  secret_id uuid references public.secrets (id) on delete set null,
  resolved_by uuid references auth.users (id) on delete set null,
  resolved_at timestamptz,
  expires_at timestamptz not null default now() + interval '24 hours',
  created_at timestamptz not null default now()
);
create index secret_requests_org_idx on public.secret_requests (org_id, status);
create index secret_requests_run_idx on public.secret_requests (run_id);
alter table public.secret_requests enable row level security;
-- People who can use the bot see its requests (never a value: there is none here). The API
-- resolves them after checking who may answer.
create policy secret_requests_select on public.secret_requests for select to authenticated
  using (public.can_access_bot(bot_id));
select public.allow_worker('public.secret_requests');
