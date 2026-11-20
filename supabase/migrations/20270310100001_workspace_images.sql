-- Workspace pictures (docs/WORKSPACE-PICTURES-PLAN.md). A workspace can use a picture of its own
-- instead of an icon or initial. Mirrors public.bot_images (D-456): stored in Postgres, served
-- without a token at /v1/workspace-images/{id} with immutable caching.
--
-- organizations.avatar_url names the picture in use as `image:<id>:<rrggbb><rrggbb>`.

create table public.workspace_images (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  source text not null check (source in ('upload', 'generated')),
  -- 512 px and 128 px WebP, metadata stripped by the server.
  large bytea not null check (octet_length(large) between 1 and 524288),
  small bytea not null check (octet_length(small) between 1 and 65536),
  -- The picture before cropping, for Re-crop (<= 2048 px, no metadata). Kept for the newest two.
  original bytea check (original is null or octet_length(original) between 1 and 3145728),
  original_type text check (original_type in ('image/jpeg', 'image/png', 'image/webp')),
  -- Where the last crop sat on the original: {x, y, scale, rotation, mirror, background}.
  crop jsonb,
  colors text not null check (colors ~ '^[0-9a-f]{12}$'),
  -- A picture Casama drew that nobody has used yet ("Make one with AI"); gone after a day.
  candidate boolean not null default false,
  used_at timestamptz,
  created_at timestamptz not null default now()
);
create index workspace_images_org_idx on public.workspace_images (org_id, used_at desc nulls last);
alter table public.workspace_images enable row level security;
-- No user policies: only the API reads and writes pictures (and the worker, like every table).
select public.allow_worker('public.workspace_images');

-- How many pictures each workspace got a day, for the API's daily limits (pruning removes the rows
-- themselves, so they can't be counted). Old days are cleared as new ones are written.
create table public.workspace_image_counts (
  org_id uuid not null references public.organizations (id) on delete cascade,
  day date not null default current_date,
  uploads int not null default 0,
  drawings int not null default 0,
  primary key (org_id, day)
);
alter table public.workspace_image_counts enable row level security;
select public.allow_worker('public.workspace_image_counts');

alter table public.organizations add column avatar_url text;

-- What organizations.avatar_url may hold: null, or one of this workspace's own pictures with the
-- colours the server extracted from it (so nobody can point a workspace at another workspace's
-- picture or an arbitrary URL).
create or replace function public.check_workspace_avatar()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  m text[];
begin
  if tg_op = 'UPDATE' then
    if new.avatar_url is not distinct from old.avatar_url then
      return new;
    end if;
  end if;
  if new.avatar_url is null then
    return new;
  end if;
  m := regexp_match(new.avatar_url,
    '^image:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):([0-9a-f]{12})$');
  if m is null or not exists (
    select 1 from public.workspace_images i
    where i.id = m[1]::uuid and i.org_id = new.id and i.colors = m[2]
  ) then
    raise exception 'avatar_url must be null or one of this workspace''s pictures'
      using errcode = '23514';
  end if;
  return new;
end;
$$;

create trigger organizations_check_avatar
  before insert or update of avatar_url on public.organizations
  for each row execute function public.check_workspace_avatar();

-- Keeps each workspace's pictures small: the five most recently used (the Recent row) plus
-- whichever is in use, the originals of the newest two, and unused drawn candidates for a day.
create or replace function public.prune_workspace_images(p_org_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  in_use uuid;
begin
  select (regexp_match(o.avatar_url, '^image:([0-9a-f-]{36}):'))[1]::uuid into in_use
    from public.organizations o where o.id = p_org_id;
  delete from public.workspace_images i
    where i.org_id = p_org_id and i.candidate and i.created_at < now() - interval '1 day'
      and i.id is distinct from in_use;
  delete from public.workspace_images i
    where i.org_id = p_org_id and not i.candidate and i.id is distinct from in_use
      and i.id not in (
        select k.id from public.workspace_images k where k.org_id = p_org_id and not k.candidate
        order by coalesce(k.used_at, k.created_at) desc limit 5);
  update public.workspace_images i set original = null, original_type = null
    where i.org_id = p_org_id and i.original is not null and i.id is distinct from in_use
      and i.id not in (
        select k.id from public.workspace_images k where k.org_id = p_org_id and not k.candidate
        order by coalesce(k.used_at, k.created_at) desc limit 2);
end;
$$;
revoke all on function public.prune_workspace_images(uuid) from public, anon, authenticated;

create or replace function public.workspace_images_after_change()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.prune_workspace_images(new.org_id);
  return null;
end;
$$;

create trigger workspace_images_prune
  after insert on public.workspace_images
  for each row execute function public.workspace_images_after_change();

-- Switching pictures (Recent, Undo) marks the one now in use, so Recent stays in order of use.
create or replace function public.organizations_mark_image_used()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_image uuid;
begin
  v_image := (regexp_match(new.avatar_url, '^image:([0-9a-f-]{36}):'))[1]::uuid;
  if v_image is not null then
    update public.workspace_images set used_at = now(), candidate = false where workspace_images.id = v_image;
    perform public.prune_workspace_images(new.id);
  end if;
  return null;
end;
$$;

create trigger organizations_mark_image_used
  after update of avatar_url on public.organizations
  for each row when (new.avatar_url is distinct from old.avatar_url)
  execute function public.organizations_mark_image_used();
