-- D-338: starter requests written for the person. An empty chat shows four tappable requests; a
-- cheap model writes them from the person's local time, the bot's apps, what they shared about
-- themselves and what they asked lately (packages/agent/src/starters.ts). One list per person and
-- bot, kept about a day; `source` says whether the model wrote it or rules stood in.
create table if not exists public.chat_starters (
  user_id uuid not null references auth.users (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  org_id uuid not null references public.organizations (id) on delete cascade,
  -- [{emoji, text}]
  items jsonb not null default '[]'::jsonb,
  source text not null check (source in ('ai', 'rules')),
  model text,
  generated_at timestamptz not null default now(),
  primary key (user_id, bot_id)
);
create index if not exists chat_starters_bot_idx on public.chat_starters (bot_id);

-- Read and written only through the API and the worker: they can hold what the person shared.
alter table public.chat_starters enable row level security;
revoke all on public.chat_starters from anon, authenticated;
select public.allow_worker('public.chat_starters');

-- Leaving a workspace drops the lists written there (they came from its bots).
create or replace function public.memberships_drop_starters() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  delete from public.chat_starters where org_id = old.org_id and user_id = old.user_id;
  return null;
end $$;
revoke execute on function public.memberships_drop_starters() from public, anon, authenticated;

drop trigger if exists memberships_drop_starters on public.memberships;
create trigger memberships_drop_starters after delete on public.memberships
  for each row execute function public.memberships_drop_starters();
