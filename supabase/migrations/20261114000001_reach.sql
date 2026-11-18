-- Phase 6: voice, the local computer companion and the owner console.

-- Voice usage and providers (BYO keys, D-065).
alter table public.usage_ledger drop constraint usage_ledger_kind_check;
alter table public.usage_ledger add constraint usage_ledger_kind_check
  check (kind in ('tokens_in', 'tokens_out', 'computer_seconds', 'stream_seconds', 'tts_chars', 'stt_seconds',
                  'voice_seconds', 'media_images', 'media_video_seconds', 'search_queries'));
alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal',
                      'brave_search', 'tavily', 'deepgram', 'elevenlabs', 'cartesia', 'fish_audio'));

-- Per-bot voice: {tts_provider, tts_voice, stt_provider, realtime_voice}
alter table public.bots add column voice jsonb not null default '{}'::jsonb;

-- A voice call's tool call runs as an agent run (trigger 'voice') without a model step.
alter table public.runs add column voice_call jsonb;

-- Read-aloud audio, cached per message and voice. Served by the API only.
create table public.tts_cache (
  message_id uuid not null references public.messages (id) on delete cascade,
  voice_key text not null,
  mime text not null,
  audio bytea not null,
  created_at timestamptz not null default now(),
  primary key (message_id, voice_key)
);
alter table public.tts_cache enable row level security;
-- No policies: only the API (server role) reads and writes it.

-- Local computer companion devices (D-066). The token is stored hashed.
create table public.local_devices (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  computer_id uuid references public.computers (id) on delete set null,
  name text not null check (char_length(name) between 1 and 80),
  platform text not null check (platform in ('macos', 'windows', 'linux')),
  token_hash text not null unique,
  -- {shell, files, browser, desktop}: each true only after the user approves it
  capabilities jsonb not null default '{}'::jsonb,
  allowed_roots text[] not null default '{}',
  allowed_bot_ids uuid[] not null default '{}',
  enabled boolean not null default true,
  last_seen_at timestamptz,
  created_at timestamptz not null default now()
);
create index local_devices_org_idx on public.local_devices (org_id);
alter table public.local_devices enable row level security;
create policy local_devices_select on public.local_devices for select to authenticated
  using (user_id = (select auth.uid()) or public.has_role(org_id, 'admin'));
