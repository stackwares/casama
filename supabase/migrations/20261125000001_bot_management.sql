-- Bots that manage bots, sidebar folders and bot settings history (SPEC: Post-v1 roadmap →
-- Bots that manage bots, App polish; D-100).

create table public.bot_folders (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (char_length(name) between 1 and 60),
  sort_key double precision not null default 0,
  created_at timestamptz not null default now(),
  unique (org_id, name)
);
alter table public.bot_folders enable row level security;
create policy bot_folders_select on public.bot_folders for select to authenticated using (public.is_member(org_id));
create policy bot_folders_write on public.bot_folders for all to authenticated
  using (public.is_member(org_id)) with check (public.is_member(org_id));
select public.allow_worker('public.bot_folders');

alter table public.bots add column folder_id uuid references public.bot_folders (id) on delete set null;
alter table public.bots add column sort_key double precision not null default 0;
-- Archived bots leave the sidebar and do not run; their history and chats are kept.
alter table public.bots add column archived_at timestamptz;

-- Every change to a bot's settings keeps the previous version, with who changed it.
create table public.bot_revisions (
  id uuid primary key default gen_random_uuid(),
  org_id uuid not null references public.organizations (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  -- the settings before the change: {name, persona_md, model_policy, autonomy, budget, default_computer_id, archived_at}
  snapshot jsonb not null,
  changed_fields text[] not null default '{}',
  changed_by_user uuid references auth.users (id) on delete set null,
  changed_by_bot uuid references public.bots (id) on delete set null,
  created_at timestamptz not null default now()
);
create index bot_revisions_bot_idx on public.bot_revisions (bot_id, created_at desc);
alter table public.bot_revisions enable row level security;
create policy bot_revisions_select on public.bot_revisions for select to authenticated
  using (public.can_access_bot(bot_id));
select public.allow_worker('public.bot_revisions');

create or replace function public.bots_record_revision()
returns trigger
language plpgsql security definer set search_path = ''
as $$
declare
  v_fields text[] := '{}';
  v_actor_bot uuid := nullif(current_setting('casama.actor_bot', true), '')::uuid;
  v_actor_user uuid := nullif(nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub', '')::uuid;
begin
  if new.name is distinct from old.name then v_fields := array_append(v_fields, 'name'); end if;
  if new.persona_md is distinct from old.persona_md then v_fields := array_append(v_fields, 'persona_md'); end if;
  if new.model_policy is distinct from old.model_policy then v_fields := array_append(v_fields, 'model_policy'); end if;
  if new.autonomy is distinct from old.autonomy then v_fields := array_append(v_fields, 'autonomy'); end if;
  if new.budget is distinct from old.budget then v_fields := array_append(v_fields, 'budget'); end if;
  if new.default_computer_id is distinct from old.default_computer_id then v_fields := array_append(v_fields, 'default_computer_id'); end if;
  if new.archived_at is distinct from old.archived_at then v_fields := array_append(v_fields, 'archived_at'); end if;
  if array_length(v_fields, 1) is null then
    return new;
  end if;
  insert into public.bot_revisions (org_id, bot_id, snapshot, changed_fields, changed_by_user, changed_by_bot)
  values (old.org_id, old.id, jsonb_build_object(
    'name', old.name, 'persona_md', old.persona_md, 'model_policy', old.model_policy, 'autonomy', old.autonomy,
    'budget', old.budget, 'default_computer_id', old.default_computer_id, 'archived_at', old.archived_at),
    v_fields, case when v_actor_bot is null then v_actor_user end, v_actor_bot);
  return new;
end;
$$;
create trigger bots_record_revision after update on public.bots
  for each row execute function public.bots_record_revision();
