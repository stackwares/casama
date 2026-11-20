-- Bot pictures (docs/BOT-PICTURES-PLAN.md). A bot can use a picture of its own instead of a mascot
-- or its initials. Like profile photos (D-202) they live in Postgres: self-hosted stacks run no
-- object storage, and a bot picture is a few dozen kilobytes. The API serves them at
-- /v1/bot-images/{id} without a token (the id is random and only handed to people who can see the
-- bot), cached for good: a new picture always gets a new id.
--
-- bots.avatar_url names the picture in use as `image:<id>:<rrggbb><rrggbb>` (its two colours ride
-- along so widgets, the watch and notifications can tint without loading it).

create table public.bot_images (
  id uuid primary key default gen_random_uuid(),
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  created_by uuid references auth.users (id) on delete set null,
  source text not null check (source in ('upload', 'chat', 'generated', 'bot')),
  -- 512 px and 128 px WebP, metadata stripped by the server.
  large bytea not null check (octet_length(large) between 1 and 524288),
  small bytea not null check (octet_length(small) between 1 and 65536),
  -- The picture before cropping, for Re-crop (≤ 2048 px, no metadata). Kept for the newest two.
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
create index bot_images_bot_idx on public.bot_images (bot_id, used_at desc nulls last);
alter table public.bot_images enable row level security;
-- No user policies: only the API reads and writes pictures (and the worker, like every table).
select public.allow_worker('public.bot_images');

-- How many pictures each bot got a day, for the API's daily limits (pruning removes the rows
-- themselves, so they can't be counted). Old days are cleared as new ones are written.
create table public.bot_image_counts (
  bot_id uuid not null references public.bots (id) on delete cascade,
  day date not null default current_date,
  uploads int not null default 0,
  drawings int not null default 0,
  primary key (bot_id, day)
);
alter table public.bot_image_counts enable row level security;
select public.allow_worker('public.bot_image_counts');

-- The mascot a bot had before it got a picture: what "Remove picture" goes back to, and what a
-- shared template or pack carries instead (pictures never leave the workspace).
alter table public.bots add column prior_mascot text
  check (prior_mascot is null or prior_mascot ~ '^mascot:[a-z]+$');

-- Old web links: avatar_url used to take any address, and the extension loaded https ones, which
-- let anyone who could edit a bot point every teammate's browser at a tracking pixel. No app ever
-- set one; anything that isn't a mascot goes back to initials.
update public.bots set avatar_url = null
  where avatar_url is not null and avatar_url !~ '^mascot:(winky|sleepy|starry|lovey|cool|thinker|giggly|shy|focused|wow)$';

-- What avatar_url may hold. The app writes it straight through PostgREST, so the rule lives here:
-- null, a mascot the apps ship, or one of this bot's own pictures with the colours the server took
-- from it (so nobody can point a bot at another bot's picture or fake its colours).
create or replace function public.check_bot_avatar()
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
  if new.avatar_url is null
     or new.avatar_url ~ '^mascot:(winky|sleepy|starry|lovey|cool|thinker|giggly|shy|focused|wow)$' then
    null;
  else
    m := regexp_match(new.avatar_url,
      '^image:([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):([0-9a-f]{12})$');
    if m is null or not exists (
      select 1 from public.bot_images i
      where i.id = m[1]::uuid and i.bot_id = new.id and i.colors = m[2]
    ) then
      raise exception 'avatar_url must be null, a mascot, or one of this bot''s pictures'
        using errcode = '23514';
    end if;
  end if;
  -- Leaving a mascot for a picture: remember the mascot.
  if tg_op = 'UPDATE' and new.avatar_url like 'image:%' then
    if old.avatar_url like 'mascot:%' then
      new.prior_mascot := old.avatar_url;
    end if;
  elsif new.avatar_url like 'mascot:%' then
    new.prior_mascot := null;
  end if;
  return new;
end;
$$;

create trigger bots_check_avatar
  before insert or update of avatar_url on public.bots
  for each row execute function public.check_bot_avatar();

-- Keeps each bot's pictures small: the five most recently used (the Recent row) plus whichever is
-- in use, the originals of the newest two, and unused drawn candidates for a day.
create or replace function public.prune_bot_images(p_bot_id uuid)
returns void
language plpgsql security definer set search_path = ''
as $$
declare
  in_use uuid;
begin
  select (regexp_match(b.avatar_url, '^image:([0-9a-f-]{36}):'))[1]::uuid into in_use
    from public.bots b where b.id = p_bot_id;
  delete from public.bot_images i
    where i.bot_id = p_bot_id and i.candidate and i.created_at < now() - interval '1 day'
      and i.id is distinct from in_use;
  delete from public.bot_images i
    where i.bot_id = p_bot_id and not i.candidate and i.id is distinct from in_use
      and i.id not in (
        select k.id from public.bot_images k where k.bot_id = p_bot_id and not k.candidate
        order by coalesce(k.used_at, k.created_at) desc limit 5);
  update public.bot_images i set original = null, original_type = null
    where i.bot_id = p_bot_id and i.original is not null and i.id is distinct from in_use
      and i.id not in (
        select k.id from public.bot_images k where k.bot_id = p_bot_id and not k.candidate
        order by coalesce(k.used_at, k.created_at) desc limit 2);
end;
$$;
revoke all on function public.prune_bot_images(uuid) from public, anon, authenticated;

create or replace function public.bot_images_after_change()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  perform public.prune_bot_images(new.bot_id);
  return null;
end;
$$;

create trigger bot_images_prune
  after insert on public.bot_images
  for each row execute function public.bot_images_after_change();

-- Switching pictures (Recent, Undo) marks the one now in use, so Recent stays in order of use.
create or replace function public.bots_mark_image_used()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_image uuid;
begin
  v_image := (regexp_match(new.avatar_url, '^image:([0-9a-f-]{36}):'))[1]::uuid;
  if v_image is not null then
    update public.bot_images set used_at = now(), candidate = false where bot_images.id = v_image;
    perform public.prune_bot_images(new.id);
  end if;
  return null;
end;
$$;

create trigger bots_mark_image_used
  after update of avatar_url on public.bots
  for each row when (new.avatar_url is distinct from old.avatar_url)
  execute function public.bots_mark_image_used();
