-- The admin bot (D-435, docs/ADMIN-BOT-PLAN.md). Its tools run in the worker, which never reads the
-- auth schema directly (D-095): what they need from auth.users goes through these narrow
-- security-definer functions, callable only by casama_worker (and their owner, the API's role).

-- One account: its email (lower case), whether it's confirmed, whether it's banned now.
create or replace function public.worker_admin_user(p_user uuid)
returns table (email text, confirmed boolean, banned boolean)
language sql stable security definer set search_path = ''
as $$
  select lower(u.email)::text, u.email_confirmed_at is not null, coalesce(u.banned_until > now(), false)
  from auth.users u where u.id = p_user
$$;

-- Accounts whose email contains the text (at least two characters), newest first, at most 20.
create or replace function public.worker_admin_find_users(p_q text)
returns table (id uuid, email text, created_at timestamptz, last_sign_in_at timestamptz, banned boolean)
language sql stable security definer set search_path = ''
as $$
  select u.id, u.email::text, u.created_at, u.last_sign_in_at, coalesce(u.banned_until > now(), false)
  from auth.users u
  where length(btrim(coalesce(p_q, ''))) >= 2
    and u.email ilike '%' || replace(replace(replace(btrim(p_q), '\', '\\'), '%', '\%'), '_', '\_') || '%'
  order by u.created_at desc
  limit 20
$$;

-- Totals for the overview.
create or replace function public.worker_admin_user_counts()
returns table (accounts integer, new_7d integer, banned integer)
language sql stable security definer set search_path = ''
as $$
  select count(*)::int,
         (count(*) filter (where u.created_at > now() - interval '7 days'))::int,
         (count(*) filter (where u.banned_until > now()))::int
  from auth.users u
$$;

-- Bans an account (no sign-in, every session and refresh token gone) or lifts the ban. An account
-- being deleted by its owner (D-072) stays banned. Returns whether the account exists.
create or replace function public.worker_admin_set_ban(p_user uuid, p_banned boolean)
returns boolean
language plpgsql security definer set search_path = ''
as $$
begin
  if not exists (select 1 from auth.users u where u.id = p_user) then
    return false;
  end if;
  if p_banned then
    update auth.users set banned_until = 'infinity'::timestamptz where id = p_user;
    -- Supabase Auth's session tables (absent in some test databases).
    if to_regclass('auth.sessions') is not null then
      execute 'delete from auth.sessions where user_id = $1' using p_user;
    end if;
    if to_regclass('auth.refresh_tokens') is not null then
      execute 'delete from auth.refresh_tokens where user_id = $1' using p_user::text;
    end if;
  else
    update auth.users set banned_until = null
    where id = p_user and not exists (select 1 from public.account_deletions d where d.user_id = p_user);
  end if;
  return true;
end;
$$;

revoke all on function public.worker_admin_user(uuid) from public, anon, authenticated;
revoke all on function public.worker_admin_find_users(text) from public, anon, authenticated;
revoke all on function public.worker_admin_user_counts() from public, anon, authenticated;
revoke all on function public.worker_admin_set_ban(uuid, boolean) from public, anon, authenticated;
grant execute on function public.worker_admin_user(uuid) to casama_worker;
grant execute on function public.worker_admin_find_users(text) to casama_worker;
grant execute on function public.worker_admin_user_counts() to casama_worker;
grant execute on function public.worker_admin_set_ban(uuid, boolean) to casama_worker;
