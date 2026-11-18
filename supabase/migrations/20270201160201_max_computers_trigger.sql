-- The plan's limit on hosted computers (max_computers) is enforced in the database too. The API
-- counts and then inserts, so two creates at once could both see room for one more and both
-- insert. The advisory lock makes them take turns, and the count runs after the lock.
--
-- Unlike enforce_max_bots this checks every write, not only signed-in ones: computers are only
-- created by the server (there is no insert policy for users), so the server's own writes are
-- the ones that need it. Local computers (this Mac, a phone) don't count, as in the API.
-- SQLSTATE PT402 makes the API (and PostgREST) answer 402 plan_limit, which opens the paywall.

create or replace function public.enforce_max_computers()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_limit jsonb;
  v_count int;
begin
  if new.provider = 'local' then return new; end if;
  -- An update matters only when it moves a hosted computer into a workspace or makes one hosted.
  if tg_op = 'UPDATE' and new.org_id = old.org_id and old.provider <> 'local' then
    return new;
  end if;

  select e.limits -> 'max_computers' into v_limit
  from public.entitlements e where e.org_id = new.org_id
  order by e.created_at desc limit 1;
  if v_limit is null or jsonb_typeof(v_limit) <> 'number' then return new; end if;

  -- Two creates at once can't both take the last slot.
  perform pg_advisory_xact_lock(hashtext('max_computers:' || new.org_id::text));
  select count(*)::int into v_count from public.computers c
  where c.org_id = new.org_id and c.provider <> 'local' and c.id <> new.id;
  if v_count >= (v_limit #>> '{}')::numeric then
    raise exception 'Your plan allows % computers. Upgrade to add more.', v_limit #>> '{}'
      using errcode = 'PT402', detail = 'plan_limit';
  end if;
  return new;
end;
$$;

revoke execute on function public.enforce_max_computers() from public, anon, authenticated;

drop trigger if exists computers_enforce_max_computers on public.computers;
create trigger computers_enforce_max_computers
  before insert or update of org_id, provider on public.computers
  for each row execute function public.enforce_max_computers();
