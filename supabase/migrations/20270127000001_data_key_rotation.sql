-- Data key rotation (D-238). Rotating the server key (D-136) only rewraps data keys, which doesn't
-- help when the database itself leaked: a stolen copy's data keys still open its rows. Replacing a
-- data key retires the old one (it still opens rows, but nothing new is sealed with it), makes a new
-- one, and the worker reseals every row from the old key to the new one in the background. The old
-- key is deleted only once nothing in the database still holds a value sealed with it.

alter table public.org_keys add column retired_at timestamptz;
alter table public.org_keys drop constraint org_keys_org_id_key;
-- One key seals new writes; retired keys only open older rows until they're resealed.
create unique index org_keys_active_idx on public.org_keys (org_id) where retired_at is null;
create index org_keys_org_idx on public.org_keys (org_id);

alter table public.user_keys add column retired_at timestamptz;
alter table public.user_keys drop constraint user_keys_user_id_key;
create unique index user_keys_active_idx on public.user_keys (user_id) where retired_at is null;
create index user_keys_user_idx on public.user_keys (user_id);

-- The first table that still holds a value sealed with this key, or null. It looks at every text
-- and json column in public (nested values too), not just the columns the worker reseals, so a key
-- is never deleted while anything, anywhere, still needs it. Security definer: row level security
-- must not hide a row from this check.
create or replace function public.content_key_in_use(p_key uuid)
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  r record;
  v_found boolean;
  v_pattern text := '%enc:v1:' || p_key::text || ':%';
begin
  for r in
    select c.oid::regclass as rel, c.relname,
           string_agg(format('%I::text like %L', a.attname, v_pattern), ' or ') as cond
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    join pg_attribute a on a.attrelid = c.oid and a.attnum > 0 and not a.attisdropped
    where n.nspname = 'public' and c.relkind in ('r', 'p') and not c.relispartition
      and c.relname not in ('org_keys', 'user_keys')
      and a.atttypid in ('text'::regtype, 'jsonb'::regtype, 'json'::regtype, 'varchar'::regtype)
    group by c.oid, c.relname
  loop
    execute format('select exists (select 1 from %s where %s)', r.rel, r.cond) into v_found;
    if v_found then
      return r.relname::text;
    end if;
  end loop;
  return null;
end;
$$;
revoke all on function public.content_key_in_use(uuid) from public, anon, authenticated;
grant execute on function public.content_key_in_use(uuid) to casama_worker;
