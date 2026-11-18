-- Takeover requests whose run already ended stopped nobody and kept a "needs you" count on the
-- bot (a deploy failed the waiting run; nothing closed its request). Close them.
update public.takeover_requests t set status = 'expired', resolved_at = now()
where t.status in ('pending', 'taken')
  and exists (select 1 from public.runs r where r.id = t.run_id and r.status in ('completed', 'failed', 'cancelled'));
