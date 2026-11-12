-- Sign-up analytics (D-208, ANALYTICS-PLAN §4.3). Sign-up happens in a database trigger the server
-- never sees, so the worker sweeps profiles that have not been reported yet. The worker never reads
-- auth.* itself (D-095): it goes through these security-definer functions.

-- Workspace admins can turn usage analytics off for the whole workspace (ANALYTICS-PLAN §5.1): no server
-- events or rollups for its runs, and the app stops identifying people while it is the current workspace.
alter table public.organizations add column if not exists analytics_opt_out boolean not null default false;

-- Everyone who exists when this ships is already "reported": only new people produce signed_up.
update public.profiles set analytics_signup_sent_at = created_at where analytics_signup_sent_at is null;

-- New, not-yet-reported people who have not opted out, with how they signed up (the provider name only).
create or replace function public.worker_new_signups(p_limit integer default 200)
returns table (user_id uuid, created_at timestamptz, provider text)
language sql stable security definer set search_path = '' as $$
  select p.user_id, u.created_at, coalesce(u.raw_app_meta_data ->> 'provider', 'email')
  from public.profiles p
  join auth.users u on u.id = p.user_id
  where p.analytics_signup_sent_at is null and not p.analytics_opt_out
  order by u.created_at
  limit greatest(1, least(p_limit, 1000))
$$;
revoke all on function public.worker_new_signups(integer) from public, anon, authenticated;
grant execute on function public.worker_new_signups(integer) to casama_worker;

create or replace function public.worker_mark_signups_sent(p_users uuid[])
returns integer language sql security definer set search_path = '' as $$
  with done as (
    update public.profiles set analytics_signup_sent_at = now()
    where user_id = any(p_users) and analytics_signup_sent_at is null
    returning 1
  )
  select count(*)::integer from done
$$;
revoke all on function public.worker_mark_signups_sent(uuid[]) from public, anon, authenticated;
grant execute on function public.worker_mark_signups_sent(uuid[]) to casama_worker;
