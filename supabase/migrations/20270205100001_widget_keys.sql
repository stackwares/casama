-- Widget keys (D-405, docs/WIDGETS-PLAN.md §8.3, §8.9).
--
-- The app asks the server for a key that its widgets fetch the glance with, on their own, with or
-- without the app. A key reads the glance and creation covers in its workspace and registers its
-- own refresh-push token; it can do nothing else. It is shown once and stored hashed. The API
-- creates keys (it hashes them); a person sees, changes and deletes only their own. The worker
-- reads push tokens to send refresh pushes and clears the ones Apple or Firebase say are gone.
create table if not exists public.widget_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  platform text not null check (platform in ('ios', 'android', 'macos')),
  key_hash text not null unique check (char_length(key_hash) between 32 and 128),
  label text check (char_length(label) <= 80),
  -- The glance it reads is private: counts and general words only (§10).
  private boolean not null default false,
  -- Where refresh pushes go: Apple's WidgetKit token or an Android phone's Firebase token.
  push_token text check (char_length(push_token) between 8 and 4096),
  push_kind text check (push_kind in ('apns_widgets', 'fcm')),
  -- Apple tokens from a development build go to Apple's sandbox.
  push_sandbox boolean,
  last_used_at timestamptz,
  created_at timestamptz not null default now(),
  check ((push_token is null) = (push_kind is null))
);

create index if not exists widget_keys_user_idx on public.widget_keys (user_id, org_id);
create index if not exists widget_keys_push_idx on public.widget_keys (push_token)
  where push_token is not null;

alter table public.widget_keys enable row level security;

drop policy if exists widget_keys_select on public.widget_keys;
create policy widget_keys_select on public.widget_keys for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists widget_keys_update on public.widget_keys;
create policy widget_keys_update on public.widget_keys for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.is_member(org_id));
drop policy if exists widget_keys_delete on public.widget_keys;
create policy widget_keys_delete on public.widget_keys for delete to authenticated
  using (user_id = (select auth.uid()));
-- Keys are made by the API, which hashes them; nobody inserts one directly. The key's hash never
-- leaves the server, not even to its owner, and a person changes only the label and the private
-- switch (push tokens go through the API, which checks them).
revoke all on public.widget_keys from anon, authenticated;
grant select (id, user_id, org_id, platform, label, private, push_kind, push_sandbox,
  last_used_at, created_at) on public.widget_keys to authenticated;
grant update (label, private) on public.widget_keys to authenticated;
grant delete on public.widget_keys to authenticated;
select public.allow_worker('public.widget_keys');
