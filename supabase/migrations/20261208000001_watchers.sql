-- Watchers (SPEC: Post-v1 roadmap → Watchers; D-116): "tell me when". The worker checks pages,
-- replies, query results and times without a model; only a change wakes the bot, with the change.
create table public.watchers (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  name text not null check (char_length(name) between 1 and 120),
  kind text not null check (kind in ('page_change', 'reply', 'query', 'time')),
  -- page_change: {url, anchor?, browser?}; reply: {source: 'ticket', task_id}; query: {integration_id, tool, args}; time: {at}
  target jsonb not null,
  condition_md text not null default '' check (char_length(condition_md) <= 2000),
  on_match_md text not null default '' check (char_length(on_match_md) <= 4000),
  check_every_seconds integer not null default 900 check (check_every_seconds between 60 and 604800),
  expires_at timestamptz,
  status text not null default 'active' check (status in ('active', 'paused', 'done', 'expired')),
  last_value_hash text,
  last_value text,
  last_checked_at timestamptz,
  next_check_at timestamptz not null default now(),
  fired_count integer not null default 0,
  last_error text,
  conversation_id uuid references public.conversations (id) on delete set null,
  project_id uuid references public.projects (id) on delete set null,
  created_at timestamptz not null default now()
);
create index watchers_due_idx on public.watchers (next_check_at) where status = 'active';
alter table public.watchers enable row level security;
create policy watchers_select on public.watchers for select to authenticated using (public.can_access_bot(bot_id));
create policy watchers_update on public.watchers for update to authenticated using (public.can_manage_bot(bot_id)) with check (public.can_manage_bot(bot_id));
create policy watchers_delete on public.watchers for delete to authenticated using (public.can_manage_bot(bot_id));
select public.allow_worker('public.watchers');
