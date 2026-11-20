-- D-452: the admin console's check by passkey or a 6-digit admin PIN, recorded on the sign-in
-- session that made it, instead of a new sign-in. The API writes these tables (RLS on, no policies);
-- the API's admin rules and decide_approval accept a fresh check like a fresh sign-in, and as the
-- second step on an account with an authenticator.

create table public.admin_step_ups (
  -- The Supabase sign-in session (the token's session_id claim) the check was made on.
  session_id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  verified_at timestamptz not null,
  method text not null check (method in ('passkey', 'pin')),
  -- The passkey check's own session: one proof counts for one session only.
  proof_session_id uuid unique
);
create index admin_step_ups_verified_at on public.admin_step_ups (verified_at);
alter table public.admin_step_ups enable row level security;
revoke all on public.admin_step_ups from anon, authenticated;

create table public.admin_pins (
  user_id uuid primary key references auth.users (id) on delete cascade,
  -- scrypt$N$r$p$salt$hash (base64url); never the PIN itself.
  pin_hash text,
  -- Wrong PINs in a row; at 5 the PIN is turned off (pin_hash null) until set again.
  failures int not null default 0,
  disabled_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.admin_pins enable row level security;
revoke all on public.admin_pins from anon, authenticated;

-- A real sign-in within the last minute in this request's token (Supabase's signed `amr`) with the
-- second step when the account has an authenticator, or a passkey or PIN check on this sign-in
-- session within the last minute. Mirrors apps/server/src/api/admin-security.ts.
create or replace function public.fresh_admin_sign_in()
returns boolean
language sql stable
security definer
set search_path = ''
as $$
  with c as (
    select coalesce(nullif(current_setting('request.jwt.claims', true), ''), '{}')::jsonb as j
  ),
  recent as (
    select e ->> 'method' as method
    from c, jsonb_array_elements(
      case when jsonb_typeof(c.j -> 'amr') = 'array' then c.j -> 'amr' else '[]'::jsonb end
    ) e
    where jsonb_typeof(e) = 'object'
      and e ->> 'method' in ('password', 'otp', 'totp', 'oauth', 'sso/saml', 'magiclink', 'passkey')
      and jsonb_typeof(e -> 'timestamp') = 'number'
      and (e ->> 'timestamp')::numeric > 0
      and (e ->> 'timestamp')::numeric <= extract(epoch from now())
      and extract(epoch from now()) - (e ->> 'timestamp')::numeric <= 60
  )
  select
    exists (
      select 1 from public.admin_step_ups s, c
      where s.session_id::text = c.j ->> 'session_id'
        and s.user_id = (select auth.uid())
        and s.verified_at <= now()
        and s.verified_at > now() - interval '60 seconds'
    )
    or (
      exists (select 1 from recent)
      and (
        (select c.j ->> 'aal' from c) = 'aal2'
        -- A passkey is enough on its own (D-452).
        or exists (select 1 from recent where method = 'passkey')
        or not exists (
          select 1 from auth.mfa_factors f
          where f.user_id = (select auth.uid()) and f.status = 'verified'
        )
      )
    );
$$;

revoke all on function public.fresh_admin_sign_in() from public, anon, authenticated;

-- The worker role gets the same policy on every table with RLS (D-016, D-095); it never needs
-- these, but the rule is uniform.
select public.allow_worker('public.admin_step_ups');
select public.allow_worker('public.admin_pins');
