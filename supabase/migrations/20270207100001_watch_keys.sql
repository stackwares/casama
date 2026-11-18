-- Casama on the wrist (D-410, docs/WATCH-PLAN.md §8.2, §8.10, §10).
--
-- A watch makes its own key and keeps it; only the key's fingerprint (sha256 of
-- "casama-watch-key:" + key) ever leaves the watch, and that is what is stored here. The phone
-- registers the fingerprint with the person's session, or the person allows a code the watch
-- shows. The API does both (it checks who may); a person sees and removes only their own watches
-- and never a fingerprint. The worker reads push tokens to reach a watch away from its phone and
-- clears the ones Apple or Firebase say are gone.
create table if not exists public.watch_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  platform text not null check (platform in ('watchos', 'wearos')),
  key_hash text not null unique check (key_hash ~ '^[0-9a-f]{64}$'),
  name text not null check (char_length(name) between 1 and 80),
  model text check (char_length(model) <= 80),
  app_version text check (char_length(app_version) <= 40),
  os_version text check (char_length(os_version) <= 40),
  -- Signed in from the phone app, or with a code the watch showed.
  paired_by text not null default 'phone' check (paired_by in ('phone', 'code')),
  -- The watch's own push token: Apple's for the watch app, or a Wear OS watch's Firebase token.
  push_token text check (char_length(push_token) between 8 and 4096),
  push_kind text check (push_kind in ('apns', 'fcm')),
  -- Apple tokens from a development build go to Apple's sandbox.
  push_sandbox boolean,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  check ((push_token is null) = (push_kind is null))
);

create index if not exists watch_keys_user_idx on public.watch_keys (user_id, org_id);
create index if not exists watch_keys_push_idx on public.watch_keys (push_token)
  where push_token is not null;

alter table public.watch_keys enable row level security;

drop policy if exists watch_keys_select on public.watch_keys;
create policy watch_keys_select on public.watch_keys for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists watch_keys_delete on public.watch_keys;
create policy watch_keys_delete on public.watch_keys for delete to authenticated
  using (user_id = (select auth.uid()));
-- Keys are registered by the API, which checks the workspace and the fingerprint; nobody inserts
-- or changes one directly. The fingerprint never leaves the server, not even to its owner.
revoke all on public.watch_keys from anon, authenticated;
grant select (id, user_id, org_id, platform, name, model, app_version, os_version, paired_by,
  push_kind, push_sandbox, last_used_at, created_at) on public.watch_keys to authenticated;
grant delete on public.watch_keys to authenticated;
select public.allow_worker('public.watch_keys');

-- Codes a watch shows when no phone app is at hand (§8.2): eight characters, stored hashed, good
-- for ten minutes and one use. Only the API reads or writes them.
create table if not exists public.watch_key_requests (
  id uuid primary key default gen_random_uuid(),
  code_hash text not null unique check (char_length(code_hash) between 32 and 128),
  key_hash text not null check (key_hash ~ '^[0-9a-f]{64}$'),
  platform text not null check (platform in ('watchos', 'wearos')),
  name text not null check (char_length(name) between 1 and 80),
  model text check (char_length(model) <= 80),
  app_version text check (char_length(app_version) <= 40),
  os_version text check (char_length(os_version) <= 40),
  tries int not null default 0,
  expires_at timestamptz not null default now() + interval '10 minutes',
  claimed_by uuid references auth.users (id) on delete set null,
  claimed_org uuid references public.organizations (id) on delete set null,
  claimed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists watch_key_requests_expires_idx on public.watch_key_requests (expires_at);

alter table public.watch_key_requests enable row level security;
revoke all on public.watch_key_requests from anon, authenticated;
-- The worker sweeps old codes.
select public.allow_worker('public.watch_key_requests');

-- The person's watch settings (§6.10), the same for all their watches. The API writes them.
create table if not exists public.watch_prefs (
  user_id uuid primary key references auth.users (id) on delete cascade,
  -- What a watch may allow: up to medium risk, low risk only, or nothing.
  allow text not null default 'medium' check (allow in ('medium', 'low', 'none')),
  -- Off: watches show counts and general words only.
  show_details boolean not null default true,
  -- The short answers under a reply; null is the built-in list.
  quick_replies text[] check (quick_replies is null or cardinality(quick_replies) between 1 and 6),
  updated_at timestamptz not null default now()
);

alter table public.watch_prefs enable row level security;
drop policy if exists watch_prefs_select on public.watch_prefs;
create policy watch_prefs_select on public.watch_prefs for select to authenticated
  using (user_id = (select auth.uid()));
revoke all on public.watch_prefs from anon, authenticated;
grant select on public.watch_prefs to authenticated;
select public.allow_worker('public.watch_prefs');
