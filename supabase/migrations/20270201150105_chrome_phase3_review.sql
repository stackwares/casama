-- D-323 Phase 3 review: a routine runs for the person who made it, so once anyone else changes it
-- (another member, or a bot not acting for the creator), it may no longer use that person's own
-- browser and sign-ins: its browser goes back to the bot's computer and stays off the creator's
-- browser until the creator edits it again.
alter table public.routines add column if not exists edited_by_other boolean not null default false;
comment on column public.routines.edited_by_other is 'Changed by someone other than its creator since the creator last edited it (D-323): it can''t use the creator''s browser.';
