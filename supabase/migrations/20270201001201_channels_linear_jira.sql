-- Linear and Jira issues as a way to give a bot work (D-285).
alter table public.channels drop constraint if exists channels_kind_check;
alter table public.channels add constraint channels_kind_check
  check (kind in ('telegram', 'email', 'sms', 'slack', 'whatsapp', 'messenger', 'feishu', 'imessage', 'teams', 'discord', 'linear', 'jira'));
