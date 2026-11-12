-- D-213: bots only ask before really risky actions by default. The six templates that started bots
-- on "ask before acting" (executive assistant, support agent, writer, social manager, money helper,
-- recruiting screener) now start them on the default, "ask for risky actions". Bots already made from
-- those templates move too, unless someone changed the bot's autonomy since it was made (a choice we
-- keep). The bots_record_revision trigger records the old value, so each change shows in the bot's
-- history and can be undone there.
update public.bots b
set autonomy = 'ask_risky'
where b.autonomy = 'ask_always'
  and exists (
    select 1 from public.audit_log a
    where a.action = 'bot.created'
      and a.target_type = 'bot'
      and a.target_id = b.id
      and a.metadata ->> 'template' in (
        'executive-assistant', 'support-agent', 'writer', 'social-manager', 'money-helper',
        'recruiting-screener'
      )
  )
  and not exists (
    select 1 from public.bot_revisions r
    where r.bot_id = b.id and 'autonomy' = any (r.changed_fields)
  );
