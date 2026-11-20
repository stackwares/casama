-- Bot widgets (docs/BOT-WIDGET-PLAN.md §7): a canvas is what one bot keeps on one person's Canvas
-- widget. Bots write through the worker; a person reads and clears their own, and changes only
-- whether it is paused and whether it shows on a locked phone.
create table if not exists public.widget_canvases (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  name text not null default 'Main' check (char_length(name) between 1 and 40),
  -- The checked document (packages/domain/src/canvas.ts): a look and a schedule or a rotation.
  -- Sealed where the workspace seals text (D-136).
  content jsonb not null,
  version integer not null default 1,
  status text not null default 'waiting' check (status in ('waiting', 'shown', 'paused')),
  hide_when_locked boolean not null default false,
  until timestamptz,
  set_at timestamptz not null default now(),
  set_by_run uuid references public.runs (id) on delete set null,
  -- Write limits (§12.3): the hour's and the day's count, from when each window began.
  writes_hour integer not null default 0,
  hour_from timestamptz not null default now(),
  writes_day integer not null default 0,
  day_from timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, bot_id, name)
);
create index if not exists widget_canvases_user_idx on public.widget_canvases (user_id, org_id);
create index if not exists widget_canvases_bot_idx on public.widget_canvases (bot_id);

alter table public.widget_canvases enable row level security;
drop policy if exists widget_canvases_select on public.widget_canvases;
create policy widget_canvases_select on public.widget_canvases for select to authenticated
  using (user_id = (select auth.uid()));
drop policy if exists widget_canvases_update on public.widget_canvases;
create policy widget_canvases_update on public.widget_canvases for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
drop policy if exists widget_canvases_delete on public.widget_canvases;
create policy widget_canvases_delete on public.widget_canvases for delete to authenticated
  using (user_id = (select auth.uid()));
revoke all on public.widget_canvases from anon, authenticated;
grant select on public.widget_canvases to authenticated;
grant update (status, hide_when_locked) on public.widget_canvases to authenticated;
grant delete on public.widget_canvases to authenticated;
select public.allow_worker('public.widget_canvases');

-- A canvas's pictures, already checked, shrunk and re-encoded by the server. The bytes live in
-- the object store when the server has one (blob_key), here otherwise.
create table if not exists public.widget_canvas_pictures (
  canvas_id uuid not null references public.widget_canvases (id) on delete cascade,
  hash text not null check (hash ~ '^[0-9a-f]{16,64}$'),
  tone text not null check (tone in ('light', 'dark')),
  size integer not null,
  blob_key text,
  bytes bytea,
  created_at timestamptz not null default now(),
  primary key (canvas_id, hash),
  check ((blob_key is null) <> (bytes is null))
);
alter table public.widget_canvas_pictures enable row level security;
revoke all on public.widget_canvas_pictures from anon, authenticated;
select public.allow_worker('public.widget_canvas_pictures');

-- Object store bytes of a removed picture are deleted by the maintenance (D-290).
drop trigger if exists widget_canvas_pictures_blobs on public.widget_canvas_pictures;
create trigger widget_canvas_pictures_blobs after delete on public.widget_canvas_pictures
  for each row execute function public.queue_deleted_blobs();

-- Which Canvas sizes a device last drew, and when: how the server knows a Canvas widget is placed.
alter table public.widget_keys add column if not exists canvas_seen jsonb;

-- The grant (§7): "this bot may show things on my widgets", per person and bot.
alter table public.device_grants drop constraint device_grants_kind_check;
alter table public.device_grants add constraint device_grants_kind_check
  check (kind in ('calendar', 'reminders', 'contacts', 'places', 'photos', 'health', 'notifications', 'activity',
                  'browser_tab', 'browser_history', 'widgets'));

-- Leaving a workspace takes the person's canvases there with their keys (D-410 audit).
create or replace function public.memberships_drop_device_keys() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.watch_keys where org_id = old.org_id and user_id = old.user_id;
  delete from public.widget_keys where org_id = old.org_id and user_id = old.user_id;
  delete from public.widget_canvases where org_id = old.org_id and user_id = old.user_id;
  return null;
end $$;
revoke execute on function public.memberships_drop_device_keys() from public, anon, authenticated;
