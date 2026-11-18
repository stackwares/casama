-- The topic an accepted suggestion started, so its card can open it again and say what happened.
alter table public.suggestions
  add column conversation_id uuid references public.conversations (id) on delete set null;
