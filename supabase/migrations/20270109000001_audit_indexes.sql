-- Audit 2026-11: indexes for the worker's periodic queries and the unread badge.
create index if not exists run_events_org_created_idx on public.run_events (org_id, created_at);
create index if not exists messages_org_created_idx on public.messages (org_id, created_at);
create index if not exists device_readings_period_end_idx on public.device_readings (period_end);
create index if not exists device_event_log_received_idx on public.device_event_log (received_at);
create index if not exists device_requests_created_idx on public.device_requests (created_at);
create index if not exists notifications_unread_idx on public.notifications (user_id, org_id) where read_at is null;
create index if not exists routines_trigger_type_idx on public.routines ((trigger ->> 'type')) where enabled;

