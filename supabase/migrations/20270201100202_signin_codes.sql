-- Scan to sign in (D-296): a signed-in app shows a QR code, and a phone that scans it is signed in
-- to the same account on the same server. The code in the QR is traded here, once and within a few
-- minutes, for a one-time sign-in token from Auth. Only its hash is kept.
create table public.signin_codes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  code_hash text not null unique,
  expires_at timestamptz not null,
  used_at timestamptz,
  used_by text check (char_length(used_by) <= 80),
  created_at timestamptz not null default now()
);
create index signin_codes_user_idx on public.signin_codes (user_id, created_at desc);
alter table public.signin_codes enable row level security;
-- No policies: only the API reads and writes sign-in codes.
