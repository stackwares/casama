-- The plan's bot limit holds for every way a bot becomes active, not only POST /v1/bots. The app
-- archives and unarchives bots (and restores a revision, which can bring back archived_at = null)
-- straight through PostgREST, so archive one, create another, then unarchive the first used to
-- get past max_bots. Inserting a bot directly or moving one into another workspace did too.
--
-- Only writes made as a signed-in user are checked (the app, and the server acting for a user).
-- The server's own admin writes (the welcome bot, a bot creating a bot) do their own checks.
-- SQLSTATE PT402 makes PostgREST answer 402, and the app shows the paywall for it.

create or replace function public.enforce_max_bots()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_limit jsonb;
  v_count int;
begin
  if coalesce(auth.jwt() ->> 'role', '') <> 'authenticated' then return new; end if;
  if new.archived_at is not null then return new; end if;
  -- An update matters only when it brings a bot back or moves an active one into a workspace.
  if tg_op = 'UPDATE' and old.archived_at is null and new.org_id = old.org_id then
    return new;
  end if;

  select e.limits -> 'max_bots' into v_limit
  from public.entitlements e where e.org_id = new.org_id
  order by e.created_at desc limit 1;
  if v_limit is null or jsonb_typeof(v_limit) <> 'number' then return new; end if;

  -- Two restores at once can't both take the last slot.
  perform pg_advisory_xact_lock(hashtext('max_bots:' || new.org_id::text));
  select count(*)::int into v_count from public.bots b
  where b.org_id = new.org_id and b.archived_at is null and b.id <> new.id;
  if v_count >= (v_limit #>> '{}')::numeric then
    raise exception 'Your plan allows % bots. Upgrade to add more.', v_limit #>> '{}'
      using errcode = 'PT402', detail = 'plan_limit';
  end if;
  return new;
end;
$$;

drop trigger if exists bots_enforce_max_bots on public.bots;
create trigger bots_enforce_max_bots before insert or update of archived_at, org_id on public.bots
  for each row execute function public.enforce_max_bots();
