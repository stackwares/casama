-- Attention rules (SPEC: Attention rules; D-153). Proactive notifications carry an urgency; non-urgent
-- ones are held (inbox only, no push) while the person is focused, driving, in a meeting or over the
-- daily cap, and the next brief bundles them. Each records why it was sent.
alter table public.notifications drop constraint notifications_push_status_check;
alter table public.notifications add constraint notifications_push_status_check
  check (push_status in ('sent', 'deferred', 'none', 'held', 'bundled'));
alter table public.notifications add column urgency text check (urgency in ('low', 'normal', 'urgent'));
alter table public.notifications add column held_reason text check (held_reason in ('focus', 'meeting', 'driving', 'daily_cap', 'low_urgency'));
create index notifications_held_idx on public.notifications (user_id, created_at) where push_status = 'held';
