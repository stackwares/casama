-- Phone-call voice (SPEC: Phone-call voice; D-135): the bot rings the person's phone. iOS rings
-- through PushKit and CallKit (VoIP tokens), Android through a high-priority FCM data message,
-- desktop and web through an in-app banner.
create table public.voip_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique check (char_length(token) between 8 and 400),
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now()
);
create index voip_tokens_user_idx on public.voip_tokens (user_id);

create table public.voice_calls (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  run_id uuid references public.runs (id) on delete set null,
  conversation_id uuid references public.conversations (id) on delete set null,
  reason text not null check (char_length(reason) between 1 and 500),
  status text not null default 'ringing' check (status in ('ringing', 'answered', 'declined', 'missed', 'cancelled')),
  expires_at timestamptz not null default now() + interval '45 seconds',
  answered_at timestamptz,
  ended_at timestamptz,
  created_at timestamptz not null default now()
);
create index voice_calls_user_idx on public.voice_calls (user_id, created_at desc);
create index voice_calls_ringing_idx on public.voice_calls (expires_at) where status = 'ringing';

alter table public.voip_tokens enable row level security;
alter table public.voice_calls enable row level security;
create policy voip_tokens_own on public.voip_tokens for all to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy voice_calls_select on public.voice_calls for select to authenticated using (user_id = (select auth.uid()));
select public.allow_worker('public.voip_tokens');
select public.allow_worker('public.voice_calls');
