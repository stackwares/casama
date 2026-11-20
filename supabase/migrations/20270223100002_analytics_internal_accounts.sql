-- Batch email lookup for analytics internal/test account classification (D-095: worker never reads
-- auth.users directly). Returns lower-cased emails so the server can match INTERNAL_EMAILS /
-- INTERNAL_EMAIL_DOMAINS without sending addresses to any analytics sink.
create or replace function public.worker_user_emails(p_users uuid[])
returns table (user_id uuid, email text)
language sql stable security definer set search_path = ''
as $$
  select u.id as user_id, lower(u.email)::text as email
  from auth.users u
  where u.id = any(p_users) and u.email is not null
$$;

revoke all on function public.worker_user_emails(uuid[]) from public, anon, authenticated;
grant execute on function public.worker_user_emails(uuid[]) to casama_worker;
