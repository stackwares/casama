-- Share a bot as a template (SPEC: Post-v1 roadmap → App polish; D-110). A share link holds a
-- snapshot of the template (never secrets); the token is stored hashed.
create table public.bot_shares (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete set null,
  token_hash text not null unique,
  snapshot jsonb not null,
  created_by uuid references auth.users (id) on delete set null,
  expires_at timestamptz,
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
alter table public.bot_shares enable row level security;
create policy bot_shares_select on public.bot_shares for select to authenticated using (public.is_member(org_id));
select public.allow_worker('public.bot_shares');
