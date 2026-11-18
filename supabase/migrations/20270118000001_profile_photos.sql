-- Profile photos (D-202). A person's own picture: one they upload, or a copy of the photo Google
-- shares at sign-in. Self-hosted stacks have no object storage by default, and a photo is a
-- 512 px image of a few dozen kilobytes, so it lives here and the API serves it.
--
-- Each new photo gets a new random id, and the photo is served at /v1/photos/{id} without a token
-- so images cache like any other picture. Only people who can already see the profile learn the
-- id (the API hands it out with your own profile and the workspace's member list).
create table public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  content_type text not null check (content_type in ('image/jpeg', 'image/png', 'image/webp')),
  bytes bytea not null check (octet_length(bytes) between 1 and 1048576),
  source text not null default 'upload' check (source in ('upload', 'provider')),
  created_at timestamptz not null default now()
);
alter table public.profile_photos enable row level security;
-- No user policies: only the API reads and writes photos (and the worker, like every table).
select public.allow_worker('public.profile_photos');

-- When the sign-in photo was copied, or found missing, so it's tried once and a removed photo
-- doesn't come back by itself.
alter table public.profiles add column photo_import_tried_at timestamptz;
