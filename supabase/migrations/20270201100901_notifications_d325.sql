-- D-325: reply pushes, "don't buzz the chat you're looking at", per-kind push settings.

-- Which chat each of a person's app installs has on screen (client_id: one per install). The worker
-- skips a reply push while any install has that conversation open (a focus is fresh for 45 s).
create table public.chat_focus (
  user_id uuid not null references auth.users (id) on delete cascade,
  client_id text not null check (char_length(client_id) between 8 and 64),
  conversation_id uuid references public.conversations (id) on delete set null,
  updated_at timestamptz not null default now(),
  primary key (user_id, client_id)
);
create index chat_focus_conversation_idx on public.chat_focus (conversation_id, updated_at)
  where conversation_id is not null;
alter table public.chat_focus enable row level security;
create policy chat_focus_own on public.chat_focus for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
select public.allow_worker('public.chat_focus');

-- Push on/off per group (replies, needs_you, routines, suggestions, account; missing = on) and
-- hide_reply_text (missing = off).
alter table public.profiles add column push_prefs jsonb not null default '{}'::jsonb;

-- Apps from D-325 write 2: on Android they draw approval pushes themselves, with buttons.
alter table public.devices add column push_version smallint not null default 0;

-- 'off': the inbox row is kept but no push went out (setting off, or the chat was on screen).
alter table public.notifications drop constraint notifications_push_status_check;
alter table public.notifications add constraint notifications_push_status_check
  check (push_status in ('sent', 'deferred', 'none', 'held', 'bundled', 'off'));

-- The app decides what to draw from the broadcast (D-325): a reply already read because its chat
-- is on screen gets no banner, and Windows and Linux draw only rows whose push went out.
create or replace function public.notifications_broadcast()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform realtime.send(
    jsonb_build_object('id', new.id, 'kind', new.kind, 'payload', new.payload, 'created_at', new.created_at,
                       'read_at', new.read_at, 'push_status', new.push_status, 'urgency', new.urgency,
                       'held_reason', new.held_reason),
    'notification', 'user:' || new.user_id::text, true);
  return null;
end;
$$;
