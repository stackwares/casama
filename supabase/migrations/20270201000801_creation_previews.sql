-- Documents in the Library open without their computer (D-280): a PDF of the latest version,
-- made by LibreOffice on the computer when the file is kept, and its first page as the cover.
alter table public.creations add column if not exists preview_key text;
