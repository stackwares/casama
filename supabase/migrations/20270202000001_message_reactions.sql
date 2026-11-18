-- Message reactions (D-331, docs/REACTIONS-PLAN.md): an emoji on a message, from a person, a bot,
-- or someone in a chat app (Telegram, Slack, WhatsApp) who has no Casama account.
-- One reaction per person (or bot) per message, like Facebook: picking another replaces it.
-- Whoever can read the conversation sees its reactions; people add, change and remove only their
-- own. Bots and chat-app senders react through the worker. An emoji and who sent it is metadata,
-- so it isn't sealed (D-136 covers message content).

create table public.message_reactions (
  id uuid primary key default gen_random_uuid(),
  message_id uuid not null references public.messages (id) on delete cascade,
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid references auth.users (id) on delete cascade,
  bot_id uuid references public.bots (id) on delete cascade,
  -- A chat-app sender: "<channel id>:<their id in the app>", and the name the app gave.
  external_sender text check (char_length(external_sender) <= 400),
  external_name text check (char_length(external_name) <= 200),
  -- One emoji: a single grapheme of at most 16 code points (flags, keycaps, skin tones and
  -- ZWJ families fit). The API checks it is an emoji; the table only keeps out text.
  emoji text not null check (char_length(emoji) between 1 and 16 and emoji !~ '[[:space:]A-Za-z]'),
  source text not null default 'app' check (source in ('app', 'api', 'channel', 'bot')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (num_nonnulls(user_id, bot_id, external_sender) = 1),
  check (external_sender is null or source = 'channel')
);
create unique index message_reactions_user_uq on public.message_reactions (message_id, user_id) where user_id is not null;
create unique index message_reactions_bot_uq on public.message_reactions (message_id, bot_id) where bot_id is not null;
create unique index message_reactions_external_uq on public.message_reactions (message_id, external_sender) where external_sender is not null;
create index message_reactions_conversation_idx on public.message_reactions (conversation_id, message_id);
create index message_reactions_user_idx on public.message_reactions (user_id) where user_id is not null;
create index message_reactions_bot_idx on public.message_reactions (bot_id) where bot_id is not null;

-- The conversation and workspace always come from the message, so a row can't claim another chat.
-- Only messages people read (theirs and the bots' replies) take reactions.
create or replace function public.message_reactions_fill()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_conversation uuid;
  v_org uuid;
  v_role text;
begin
  select m.conversation_id, m.org_id, m.role into v_conversation, v_org, v_role
  from public.messages m where m.id = new.message_id;
  if v_conversation is null then
    raise exception 'message not found' using errcode = 'P0002';
  end if;
  if v_role not in ('user', 'assistant') then
    raise exception 'this message takes no reactions' using errcode = '22023';
  end if;
  new.conversation_id := v_conversation;
  new.org_id := v_org;
  if tg_op = 'UPDATE' then
    new.updated_at := now();
  end if;
  return new;
end;
$$;
revoke execute on function public.message_reactions_fill() from public, anon, authenticated;

create trigger message_reactions_fill
  before insert or update of message_id, emoji on public.message_reactions
  for each row execute function public.message_reactions_fill();

alter table public.message_reactions enable row level security;
create policy message_reactions_select on public.message_reactions for select to authenticated
  using (public.can_access_conversation(conversation_id));
create policy message_reactions_insert on public.message_reactions for insert to authenticated
  with check (user_id = (select auth.uid()) and bot_id is null and source in ('app', 'api')
              and public.can_access_conversation(conversation_id));
create policy message_reactions_update on public.message_reactions for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and bot_id is null and source in ('app', 'api')
              and public.can_access_conversation(conversation_id));
create policy message_reactions_delete on public.message_reactions for delete to authenticated
  using (user_id = (select auth.uid()));
grant select, insert, update, delete on public.message_reactions to authenticated;
select public.allow_worker('public.message_reactions');

-- Open chats update a message's reactions without reloading the thread. Its own event, so apps
-- from before reactions (which reload on conversation_activity) ignore it.
create or replace function public.broadcast_message_reaction()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  r record := coalesce(new, old);
begin
  perform realtime.send(
    jsonb_build_object('kind', 'reaction', 'message_id', r.message_id),
    'message_reaction',
    'conversation:' || r.conversation_id::text,
    true
  );
  return null;
end;
$$;
revoke execute on function public.broadcast_message_reaction() from public, anon, authenticated;

create trigger message_reactions_broadcast
  after insert or update or delete on public.message_reactions
  for each row execute function public.broadcast_message_reaction();

-- What the person thought of a run's reply (D-331 Phase 2): set from reactions on its messages.
alter table public.run_digests add column reaction text check (reaction in ('positive', 'negative'));

-- Chat apps (D-331 Phase 3): which message in Telegram, Slack or WhatsApp is which Casama message,
-- so a reaction there lands on the right message here and a bot's reaction goes to the right one
-- there. `ref` is the app's own id ("<chat>:<message id>" in Telegram, "<channel>:<ts>" in Slack,
-- the wamid in WhatsApp). Kept as long as the message.
create table public.channel_message_links (
  channel_id uuid not null references public.channels (id) on delete cascade,
  ref text not null check (char_length(ref) between 1 and 300),
  message_id uuid not null references public.messages (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (channel_id, ref)
);
create index channel_message_links_message_idx on public.channel_message_links (message_id);
alter table public.channel_message_links enable row level security;
-- Nobody reads these from the app; only the server and the worker use them.
select public.allow_worker('public.channel_message_links');
