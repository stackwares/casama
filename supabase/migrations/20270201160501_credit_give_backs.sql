-- Billing audit 2026-11-17 (D-333): credits given back keep their expiry.
--
-- Money given back (a hold larger than the usage it stood in for: a positive 'usage' entry; a
-- failed run's usage waived: a positive 'refund' entry) became a new lot that never expired. Month
-- credits that would lapse could be turned into credits that never do by holding and releasing
-- them. Now a give-back refills the lots it was spent from: open (unexpired) lots that are partly
-- spent, the soonest to lapse first, as spending takes them. What's left beyond that (the lots it
-- came from have lapsed since) lapses at the end of next month, like a month's credits.
--
-- Otherwise credit_apply is unchanged from 20270129000101.

create or replace function public.credit_apply(
  p_org uuid, p_delta numeric, p_reason text, p_reference text, p_note text default null)
returns numeric
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_bal numeric;
  v_new numeric;
  v_lot numeric;
  v_left numeric;
  v_add numeric;
  r record;
begin
  perform 1 from public.organizations where id = p_org for update;
  select balance_after into v_bal from public.credit_ledger where org_id = p_org order by seq desc limit 1;
  v_bal := coalesce(v_bal, 0);
  if p_reference is not null and exists (
    select 1 from public.credit_ledger where org_id = p_org and reason = p_reason and reference = p_reference) then
    return v_bal;
  end if;
  v_new := v_bal + p_delta;
  insert into public.credit_ledger (org_id, delta, reason, reference, note, balance_after)
  values (p_org, p_delta, p_reason, p_reference, p_note, v_new);

  if p_delta > 0 then
    -- Only the part above zero becomes spendable credit; the rest pays off a negative balance.
    v_lot := greatest(v_new, 0) - greatest(v_bal, 0);
    if v_lot > 0 and p_reason in ('usage', 'refund') then
      -- A give-back refills the open lots it was spent from.
      v_left := v_lot;
      for r in
        select id, amount - remaining as room from public.credit_lots
        where org_id = p_org and remaining < amount
          and (expires_at is null or expires_at > now())
        order by expires_at nulls last, created_at
        for update
      loop
        exit when v_left <= 0;
        v_add := least(r.room, v_left);
        update public.credit_lots set remaining = remaining + v_add where id = r.id;
        v_left := v_left - v_add;
      end loop;
      if v_left > 0 then
        insert into public.credit_lots (org_id, reason, reference, amount, remaining, expires_at)
        values (p_org, p_reason, p_reference, v_left, v_left,
                date_trunc('month', now()) + interval '2 months');
      end if;
    elsif v_lot > 0 then
      insert into public.credit_lots (org_id, reason, reference, amount, remaining, expires_at)
      values (p_org, p_reason, p_reference, v_lot, v_lot, public.credit_lot_expiry(p_reason, p_reference));
    end if;
  elsif p_delta < 0 and p_reason <> 'expire' then
    -- Spend the credits that lapse first.
    v_left := -p_delta;
    for r in
      select id, remaining from public.credit_lots
      where org_id = p_org and remaining > 0
      order by expires_at nulls last, created_at
      for update
    loop
      exit when v_left <= 0;
      update public.credit_lots set remaining = remaining - least(r.remaining, v_left) where id = r.id;
      v_left := v_left - least(r.remaining, v_left);
    end loop;
  end if;
  return v_new;
end;
$$;
revoke execute on function public.credit_apply(uuid, numeric, text, text, text) from public, anon, authenticated;
