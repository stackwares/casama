-- Hosted bot mail (BOT-EMAIL-PLAN, D-449): one address per bot on Casama Cloud's mail domain.
-- A claimed name is never reissued: releasing, archiving or deleting leaves a tombstone row that
-- keeps local_part reserved.
create table public.mail_addresses (
  id uuid primary key default gen_random_uuid(),
  -- Unique over every row, retired ones included, so a name is never claimed twice.
  local_part text not null unique
    check (local_part ~ '^[a-z0-9][a-z0-9._-]{1,38}[a-z0-9]$' and local_part not like '%..%'),
  -- Nulls on delete: the tombstone stays, linked to nothing.
  org_id uuid references public.organizations (id) on delete set null,
  bot_id uuid references public.bots (id) on delete set null,
  channel_id uuid references public.channels (id) on delete set null,
  status text not null default 'active' check (status in ('active', 'paused', 'retired')),
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  released_at timestamptz,
  -- Set when delivery events pause the address by itself; only the instance owner lifts it.
  auto_paused_at timestamptz
);
-- A bot has at most one live address; a retired one stays only as a tombstone.
create unique index mail_addresses_live_bot_idx on public.mail_addresses (bot_id)
  where status in ('active', 'paused');
create index mail_addresses_org_idx on public.mail_addresses (org_id);

-- Every mail in or out of a hosted address. Text is sealed like chat messages; the original MIME
-- and attachments live in object storage under raw_key and files[].key.
create table public.mail_messages (
  id uuid primary key default gen_random_uuid(),
  address_id uuid not null references public.mail_addresses (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  direction text not null check (direction in ('in', 'out')),
  from_addr text not null,
  from_name text,
  to_addrs text[] not null default '{}',
  -- The plus tag it arrived on (ada+shop@), empty when there is none.
  to_tag text not null default '',
  subject text not null default '',
  content jsonb not null default '[]'::jsonb,
  files jsonb not null default '[]'::jsonb,
  -- The Message-ID header: the sender's for mail in, Casama's own (<uuid@domain>) for mail out.
  message_id text,
  -- Mail out: the id the sending service gave it (delivery events carry this one).
  provider_message_id text,
  in_reply_to text,
  thread_key text,
  sender_check text not null default 'none' check (sender_check in ('pass', 'fail', 'none')),
  verdict text not null check (verdict in ('allowed', 'stranger', 'automatic')),
  conversation_id uuid references public.conversations (id) on delete set null,
  size integer not null default 0,
  raw_key text,
  -- Whether this sent mail went to someone new (mail_new_day counts these).
  to_new boolean not null default false,
  expires_at timestamptz,
  created_at timestamptz not null default now()
);
create index mail_messages_address_idx on public.mail_messages (address_id, created_at desc);
create index mail_messages_conversation_idx on public.mail_messages (conversation_id);
create index mail_messages_thread_idx on public.mail_messages (address_id, thread_key, created_at desc);
-- A Worker retry (POST delivered, response lost) must not keep the same mail twice: one
-- row per Message-ID on an address. Mail without a Message-ID is never deduplicated.
create unique index mail_messages_address_message_idx
  on public.mail_messages (address_id, direction, message_id) where message_id is not null;

-- Suppressions (hard bounces, spam complaints, opt-outs and "stop" replies) and delivery events.
create table public.mail_suppressions (
  id uuid primary key default gen_random_uuid(),
  address_id uuid not null references public.mail_addresses (id) on delete cascade,
  email text not null,
  reason text not null check (reason in ('bounce', 'complaint', 'optout', 'stop')),
  created_at timestamptz not null default now(),
  unique (address_id, email)
);
create index mail_suppressions_address_idx on public.mail_suppressions (address_id);

create table public.mail_events (
  id uuid primary key default gen_random_uuid(),
  address_id uuid not null references public.mail_addresses (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  -- Cloudflare's event id: a delivery reported twice is stored once.
  event_id text not null,
  message_id text,
  event text not null check (event in ('delivered', 'bounced', 'complained')),
  -- Only hard bounces suppress and count toward the automatic pause.
  hard boolean not null default false,
  recipient text not null,
  detail text,
  created_at timestamptz not null default now(),
  unique (address_id, event_id)
);
create index mail_events_address_idx on public.mail_events (address_id, created_at desc);

-- Losing its workspace, bot or channel retires an address instead of freeing its name.
create or replace function public.mail_address_retire_orphan()
returns trigger language plpgsql as $$
begin
  if new.org_id is null or new.bot_id is null or new.channel_id is null then
    new.status := 'retired';
    new.released_at := coalesce(new.released_at, now());
    new.updated_at := now();
  end if;
  return new;
end;
$$;
create trigger mail_addresses_retire_orphan
  before insert or update of org_id, bot_id, channel_id on public.mail_addresses
  for each row execute function public.mail_address_retire_orphan();

-- Whenever an address is retired (released, bot archived, or bot/channel deleted), its kept mail
-- expires in 30 days so nothing stays forever out of reach.
create or replace function public.mail_address_expire_messages()
returns trigger language plpgsql as $$
begin
  if old.status is distinct from 'retired' and new.status = 'retired' then
    update public.mail_messages
       set expires_at = now() + interval '30 days'
     where address_id = new.id and expires_at is null;
  end if;
  return new;
end;
$$;
create trigger mail_addresses_expire_messages
  after update of status on public.mail_addresses
  for each row execute function public.mail_address_expire_messages();

-- Archiving a bot retires its hosted address and disables its hosted channel.
create or replace function public.mail_address_retire_on_bot_archive()
returns trigger language plpgsql as $$
declare
  v_channel_id uuid;
begin
  if old.archived_at is null and new.archived_at is not null then
    for v_channel_id in
      update public.mail_addresses
         set status = 'retired', released_at = coalesce(released_at, now()), updated_at = now()
       where bot_id = new.id and status in ('active', 'paused')
       returning channel_id
    loop
      if v_channel_id is not null then
        update public.channels set enabled = false where id = v_channel_id;
      end if;
    end loop;
  end if;
  return new;
end;
$$;
create trigger bots_retire_mail_on_archive
  after update of archived_at on public.bots
  for each row execute function public.mail_address_retire_on_bot_archive();

-- Every sent mail is counted with its real cost, not billed (BOT-EMAIL-PLAN §10).
alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'stt_seconds',
                  'voice_seconds', 'media_images', 'media_video_seconds', 'search_queries', 'data_calls', 'phone_minutes',
                  'app_calls', 'emails_sent'));

alter table public.mail_addresses enable row level security;
alter table public.mail_messages enable row level security;
alter table public.mail_suppressions enable row level security;
alter table public.mail_events enable row level security;
-- Members who manage the bot read its address and mail; everything is written through the API.
create policy mail_addresses_select on public.mail_addresses for select to authenticated
  using (bot_id is not null and public.can_manage_bot(bot_id));
create policy mail_messages_select on public.mail_messages for select to authenticated
  using (exists (select 1 from public.mail_addresses a where a.id = address_id and a.bot_id is not null
                 and public.can_manage_bot(a.bot_id)));
create policy mail_suppressions_select on public.mail_suppressions for select to authenticated
  using (exists (select 1 from public.mail_addresses a where a.id = address_id and a.bot_id is not null
                 and public.can_manage_bot(a.bot_id)));
create policy mail_events_select on public.mail_events for select to authenticated
  using (exists (select 1 from public.mail_addresses a where a.id = address_id and a.bot_id is not null
                 and public.can_manage_bot(a.bot_id)));
select public.allow_worker('public.mail_addresses');
select public.allow_worker('public.mail_messages');
select public.allow_worker('public.mail_suppressions');
select public.allow_worker('public.mail_events');

-- Plan limits for hosted mail (BOT-EMAIL-PLAN §8): addresses per workspace, mail to new people
-- a day, all mail sent a day, mailbox size in MB. Weekly plans match their monthly tier (D-432).
-- A key a plan already has (say, edited from the Admin screen) is kept: the defaults go on the left of ||.
update public.plans set limits =
  '{"max_mail_addresses": 1, "mail_new_day": 0, "mail_sent_day": 20, "mail_storage_mb": 100}'::jsonb
  || limits
where code = 'free';
update public.plans set limits =
  '{"max_mail_addresses": 2, "mail_new_day": 10, "mail_sent_day": 100, "mail_storage_mb": 1024}'::jsonb
  || limits
where code in ('plus', 'plus_yearly', 'plus_weekly');
update public.plans set limits =
  '{"max_mail_addresses": 5, "mail_new_day": 30, "mail_sent_day": 300, "mail_storage_mb": 5120}'::jsonb
  || limits
where code in ('pro', 'pro_yearly', 'pro_weekly');
update public.plans set limits =
  '{"max_mail_addresses": 15, "mail_new_day": 100, "mail_sent_day": 1000, "mail_storage_mb": 20480}'::jsonb
  || limits
where code in ('max', 'max_yearly', 'max_weekly');

-- Every workspace's limits again from the one formula (plan, extra people, trial, then the
-- owner's overrides on top). Self-hosted keeps its own.
update public.entitlements e
   set limits = public.entitlement_limits(e.plan_code, e.subscription_id, e.overrides), updated_at = now()
 where e.plan_code <> 'selfhost';
