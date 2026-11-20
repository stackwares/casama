-- Project covers: a project can pick one of the app's painted covers (an art name such as
-- `sailboat`), shown in the project list and on its screens. Null keeps today's look: the newest
-- creation's picture or a glyph.

alter table public.projects
  add column cover text check (cover is null or cover ~ '^[a-z][a-z0-9-]{0,39}$');
