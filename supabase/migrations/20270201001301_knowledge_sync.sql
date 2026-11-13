-- Knowledge that keeps up (D-286): a source can sync every hour or few. Pieces whose text hasn't
-- changed keep their embeddings, and a source that hasn't changed at all isn't rewritten.
alter table public.knowledge_chunks add column if not exists text_hash text;
alter table public.knowledge_sources add column if not exists content_hash text;
create index if not exists knowledge_chunks_source_hash_idx on public.knowledge_chunks (source_id, text_hash);
