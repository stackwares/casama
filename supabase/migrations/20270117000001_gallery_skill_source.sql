-- Gallery skills (D-184) install with their own source, checked against the gallery index hash.
alter table public.skills drop constraint skills_source_check;
alter table public.skills add constraint skills_source_check
  check (source in ('manual', 'catalog', 'github', 'bot', 'plugin', 'gallery'));
