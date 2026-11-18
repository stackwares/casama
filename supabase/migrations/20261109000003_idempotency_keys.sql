-- Stored responses for the Idempotency-Key header on mutating API requests.
create table public.idempotency_keys (
  user_id uuid not null references auth.users (id) on delete cascade,
  key text not null check (char_length(key) between 1 and 255),
  method text not null,
  path text not null,
  status integer not null,
  response jsonb not null,
  created_at timestamptz not null default now(),
  primary key (user_id, key)
);
create index idempotency_keys_created_at_idx on public.idempotency_keys (created_at);

alter table public.idempotency_keys enable row level security;

create policy idempotency_keys_select on public.idempotency_keys
  for select to authenticated using (user_id = (select auth.uid()));
create policy idempotency_keys_insert on public.idempotency_keys
  for insert to authenticated with check (user_id = (select auth.uid()));

-- Clients never need these rows directly.
revoke all on public.idempotency_keys from anon;
