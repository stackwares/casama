-- ChatGPT plan sign-in (SPEC: Model gateway → ChatGPT plan sign-in; D-091).
-- A `chatgpt` credential holds one person's ChatGPT plan tokens in Vault. It is personal: only
-- runs on its owner's behalf use it.

alter table public.model_credentials drop constraint model_credentials_provider_check;
alter table public.model_credentials add constraint model_credentials_provider_check
  check (provider in ('openai', 'anthropic', 'google', 'xai', 'openrouter', 'openai_compatible', 'fal',
                      'brave_search', 'tavily', 'deepgram', 'elevenlabs', 'cartesia', 'fish_audio',
                      'chatgpt'));

-- The person whose plan this is (chatgpt only).
alter table public.model_credentials
  add column owner_user_id uuid references auth.users (id) on delete cascade;
-- ok | plan_usage_off (signed in, plan usage not granted) | needs_reconnect (tokens unusable)
alter table public.model_credentials
  add column status text not null default 'ok'
  check (status in ('ok', 'plan_usage_off', 'needs_reconnect'));
-- Owner settings, e.g. {"fallback_on_limit": true}.
alter table public.model_credentials add column settings jsonb not null default '{}'::jsonb;
-- Non-secret sign-in facts: {"client_id": "oaiapp_…", "sub": "…", "email": "…"}.
alter table public.model_credentials add column oauth jsonb not null default '{}'::jsonb;
-- Last successful token refresh, so idle plans are refreshed before their refresh token expires.
alter table public.model_credentials add column refreshed_at timestamptz;
alter table public.model_credentials add constraint model_credentials_chatgpt_owner
  check (provider <> 'chatgpt' or owner_user_id is not null);
create index model_credentials_owner_idx on public.model_credentials (owner_user_id)
  where owner_user_id is not null;

-- Who paid for a usage row: a stored key (default) or the person's ChatGPT plan (cost 0).
alter table public.usage_ledger add column source text not null default 'key'
  check (source in ('key', 'chatgpt_plan'));

-- Members see a personal credential exists (unchanged select policy). Admins may delete any
-- credential; the owner may delete their own plan.
drop policy model_credentials_delete on public.model_credentials;
create policy model_credentials_delete on public.model_credentials for delete to authenticated
  using (public.has_role(org_id, 'admin') or owner_user_id = (select auth.uid()));
