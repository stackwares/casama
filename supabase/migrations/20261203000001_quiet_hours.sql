-- Quiet hours (SPEC: Post-v1 roadmap → App polish; D-109). Pushes wait until a person's quiet
-- hours end (the inbox row is written right away), except urgent approvals. Each person can
-- override quiet hours per bot.
alter table public.profiles add column quiet_hours jsonb;

create table public.user_bot_settings (
  user_id uuid not null references auth.users (id) on delete cascade,
  bot_id uuid not null references public.bots (id) on delete cascade,
  -- default: my quiet hours; always: this bot may always push; custom: quiet_hours below
  quiet text not null default 'default' check (quiet in ('default', 'always', 'custom')),
  quiet_hours jsonb,
  updated_at timestamptz not null default now(),
  primary key (user_id, bot_id)
);
alter table public.user_bot_settings enable row level security;
create policy user_bot_settings_own on public.user_bot_settings for all to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()) and public.can_access_bot(bot_id));
select public.allow_worker('public.user_bot_settings');

alter table public.notifications add column push_status text not null default 'sent'
  check (push_status in ('sent', 'deferred', 'none'));
alter table public.notifications add column push_after timestamptz;
create index notifications_deferred_idx on public.notifications (push_after) where push_status = 'deferred';
