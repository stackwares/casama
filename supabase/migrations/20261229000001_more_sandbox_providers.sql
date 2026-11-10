-- More hosted sandbox providers (D-139).
alter table public.computers drop constraint computers_provider_check;
alter table public.computers add constraint computers_provider_check
  check (provider in ('docker', 'e2b', 'daytona', 'local', 'kasama-cloud', 'novita', 'kubernetes', 'incus', 'boat', 'railway'));
