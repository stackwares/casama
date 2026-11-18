-- Computers switched to the desktop profile only for a takeover go back to headless when they
-- next sleep (D-178): a desktop needs about four times the memory of a headless computer.
alter table public.computers
  add column desktop_for_takeover boolean not null default false;
