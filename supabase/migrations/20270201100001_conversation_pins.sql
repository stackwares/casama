-- Topics can be renamed and pinned (Improve app 2). A pinned conversation lists after the
-- person's General and before the rest. Who may rename or pin is checked by the API: the person
-- who started it, or someone who manages its bot (the same rule as deleting it).
alter table public.conversations add column pinned_at timestamptz;
