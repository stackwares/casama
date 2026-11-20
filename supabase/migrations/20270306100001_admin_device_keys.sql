-- D-453: the screen lock is the whole admin check. A key made in the device's secure hardware
-- (Secure Enclave, Android Keystore), usable only after Face ID, a fingerprint or the device
-- passcode, signs a one-time challenge; the API checks the signature with the public key kept
-- here and records the check on the sign-in session (admin_step_ups, D-452). The API writes these
-- tables (RLS on, no policies).

create table public.admin_device_keys (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null check (length(name) between 1 and 80),
  -- SubjectPublicKeyInfo, DER, base64: an EC P-256 key.
  public_key text not null check (length(public_key) between 80 and 400),
  created_at timestamptz not null default now(),
  last_used_at timestamptz
);
create index admin_device_keys_user on public.admin_device_keys (user_id);
alter table public.admin_device_keys enable row level security;
revoke all on public.admin_device_keys from anon, authenticated;

create table public.admin_device_challenges (
  id uuid primary key default gen_random_uuid(),
  key_id uuid not null references public.admin_device_keys (id) on delete cascade,
  -- The sign-in session that asked; the check counts for it only.
  session_id uuid not null,
  challenge text not null,
  expires_at timestamptz not null,
  used_at timestamptz
);
create index admin_device_challenges_expires on public.admin_device_challenges (expires_at);
alter table public.admin_device_challenges enable row level security;
revoke all on public.admin_device_challenges from anon, authenticated;

alter table public.admin_step_ups drop constraint admin_step_ups_method_check;
alter table public.admin_step_ups
  add constraint admin_step_ups_method_check check (method in ('passkey', 'pin', 'device'));

-- The worker role gets the same policy on every table with RLS (D-016, D-095); it never needs
-- these, but the rule is uniform.
select public.allow_worker('public.admin_device_keys');
select public.allow_worker('public.admin_device_challenges');
