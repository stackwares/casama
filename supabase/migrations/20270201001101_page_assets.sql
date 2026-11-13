-- Sites and games with real files (D-289): a page published from a folder keeps its other files
-- (images, sounds, scripts, styles) in the object store, listed here per page version.
alter table public.pages add column if not exists assets_version int;
create table public.page_assets (
  page_id uuid not null references public.pages (id) on delete cascade,
  version int not null,
  path text not null check (char_length(path) between 1 and 300),
  org_id uuid not null references public.organizations (id) on delete cascade,
  mime text not null,
  blob_key text not null,
  size bigint not null check (size >= 0),
  primary key (page_id, version, path)
);
alter table public.page_assets enable row level security;
create policy page_assets_select on public.page_assets for select to authenticated
  using (public.can_view_page(page_id));
select public.allow_worker('public.page_assets');
