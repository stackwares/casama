-- Check-in costs (D-247): an event scan now carries what changed (sender and subject, event and
-- time), so the scan starts there instead of searching everything. Cleared when the scan starts.
alter table public.bot_checkins add column scan_note text;
