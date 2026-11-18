-- Computer details on the card (D-227): the desktop app reports its operating system when it
-- connects ("macOS 26.2", "Windows 11 Pro", "Ubuntu 24.04.1 LTS"), so a personal computer shows
-- more than its platform. Display text only; nothing decides on it.
alter table public.local_devices
  add column os_version text check (char_length(os_version) <= 80);
