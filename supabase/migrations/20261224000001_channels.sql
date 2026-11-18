-- Chat apps (SPEC: Channels and Post-v1 roadmap → Chat apps; D-134): Telegram, email, SMS, Slack,
-- WhatsApp, Messenger, Feishu and iMessage. Each external thread maps to one conversation; a bot
-- only acts on messages from allowed senders, and everything else is logged.
create table public.channels (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  kind text not null check (kind in ('telegram', 'email', 'sms', 'slack', 'whatsapp', 'messenger', 'feishu', 'imessage')),
  name text not null check (char_length(name) between 1 and 100),
  -- Non-secret settings: addresses, numbers, ids, API bases.
  config jsonb not null default '{}'::jsonb,
  -- Secrets as JSON in Vault: tokens, signing secrets.
  vault_secret_id uuid,
  allowed_senders text[] not null default '{}',
  enabled boolean not null default true,
  last_inbound_at timestamptz,
  last_error text,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now()
);
create index channels_bot_idx on public.channels (bot_id);

create table public.channel_threads (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  thread_key text not null check (char_length(thread_key) between 1 and 500),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  -- Who to reply to and how: {to, subject, reply_to_id, slack_thread_ts, ...}
  reply jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (channel_id, thread_key)
);
create index channel_threads_conversation_idx on public.channel_threads (conversation_id);

create table public.channel_events (
  id uuid primary key default gen_random_uuid(),
  channel_id uuid not null references public.channels (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  direction text not null check (direction in ('in', 'out')),
  status text not null check (status in ('accepted', 'ignored', 'routine', 'sent', 'failed')),
  sender text,
  thread_key text,
  preview text check (char_length(preview) <= 300),
  detail text,
  created_at timestamptz not null default now()
);
create index channel_events_channel_idx on public.channel_events (channel_id, created_at desc);

alter table public.channels enable row level security;
alter table public.channel_threads enable row level security;
alter table public.channel_events enable row level security;
create policy channels_select on public.channels for select to authenticated using (public.can_access_bot(bot_id));
create policy channels_delete on public.channels for delete to authenticated using (public.can_manage_bot(bot_id));
create policy channel_events_select on public.channel_events for select to authenticated using (
  exists (select 1 from public.channels c where c.id = channel_id and public.can_manage_bot(c.bot_id)));
select public.allow_worker('public.channels');
select public.allow_worker('public.channel_threads');
select public.allow_worker('public.channel_events');
