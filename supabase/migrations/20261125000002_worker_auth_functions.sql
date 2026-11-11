-- The worker never touches the auth schema directly (D-100 follow-up to D-095): Supabase doesn't
-- let the migration role grant on auth.users, so the two things system jobs need go through
-- narrow security-definer functions only casama_worker (and the API's postgres role) can call.

-- Whether a workspace's owner has confirmed their email (free computers need it; D-094).
create or replace function public.worker_owner_email_verified(p_org uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.memberships m join auth.users u on u.id = m.user_id
    where m.org_id = p_org and m.role = 'owner' and u.email_confirmed_at is not null)
$$;

-- Removes a user whose account deletion grace period has passed (privacy purge).
create or replace function public.worker_purge_user(p_user uuid)
returns void
language sql security definer set search_path = ''
as $$
  delete from auth.users u
  where u.id = p_user
    and exists (select 1 from public.account_deletions d where d.user_id = p_user and d.purge_after <= now());
$$;

revoke all on function public.worker_owner_email_verified(uuid) from public, anon, authenticated;
revoke all on function public.worker_purge_user(uuid) from public, anon, authenticated;
grant execute on function public.worker_owner_email_verified(uuid) to casama_worker;
grant execute on function public.worker_purge_user(uuid) to casama_worker;
