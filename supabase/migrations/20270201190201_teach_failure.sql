-- D-334: a teach draft that couldn't be written (out of credits, a plan limit, or another failure)
-- keeps why, so the app and Casama for Chrome can say so (and offer plans for billing codes).
alter table public.teach_sessions add column if not exists error_code text
  check (char_length(error_code) <= 100);
alter table public.teach_sessions add column if not exists error_message text
  check (char_length(error_message) <= 2000);
