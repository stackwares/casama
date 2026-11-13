-- Microsoft Teams and Discord as chat apps (D-278).
alter table public.channels drop constraint if exists channels_kind_check;
alter table public.channels add constraint channels_kind_check
  check (kind in ('telegram', 'email', 'sms', 'slack', 'whatsapp', 'messenger', 'feishu', 'imessage', 'teams', 'discord'));
