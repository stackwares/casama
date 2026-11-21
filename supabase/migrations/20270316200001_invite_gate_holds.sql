-- An invite that let someone through the waitlist gate keeps its seat (D-474).
--
-- public.signup_invited_with_seat lets a sign-up through the gate when a pending workspace invite
-- for that address has a seat. Before this, revoking the invite once the person had signed up
-- deleted the row and freed the seat again, so a workspace could invite, let the person sign up,
-- revoke, and repeat: an unlimited way past the waitlist. Expiry did the same, more slowly.
--
-- Now an invite whose address signed up while it was pending holds its seat for gate purposes
-- after it is revoked (a hold row) or runs out, for as long as that person isn't a member of the
-- workspace. It changes nothing about who can join a workspace, only who an invite lets past the
-- gate.

create table public.invite_gate_holds (
  id uuid primary key default gen_random_uuid(),
  -- No foreign key: a workspace being deleted cascades to its invites, and the hold must not
  -- block that. A hold for a workspace that's gone is never counted.
  org_id uuid not null,
  user_id uuid not null,
  invite_created_at timestamptz not null,
  created_at timestamptz not null default now()
);
create index invite_gate_holds_org_idx on public.invite_gate_holds (org_id);
alter table public.invite_gate_holds enable row level security;
revoke all on public.invite_gate_holds from public, anon, authenticated;

-- An unaccepted invite deleted (revoked, declined, blocked) after its address signed up.
create or replace function public.invites_keep_gate_hold() returns trigger
language plpgsql security definer set search_path = '' as $$
begin
  if old.accepted_at is null then
    insert into public.invite_gate_holds (org_id, user_id, invite_created_at)
    select old.org_id, u.id, old.created_at
    from auth.users u
    where lower(u.email::text) = lower(old.email::text) and u.created_at >= old.created_at
      and u.created_at <= old.expires_at;
  end if;
  return old;
end;
$$;
revoke all on function public.invites_keep_gate_hold() from public, anon, authenticated;

create trigger invites_keep_gate_hold
  after delete on public.invites
  for each row execute function public.invites_keep_gate_hold();

create or replace function public.signup_invited_with_seat(p_email text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (
    select 1
    from public.invites i
    left join lateral (
      select e.limits -> 'seats' as seats from public.entitlements e
      where e.org_id = i.org_id order by e.created_at desc limit 1
    ) lim on true
    where lower(i.email::text) = lower(btrim(coalesce(p_email, '')))
      and i.accepted_at is null and i.expires_at > now()
      and (
        lim.seats is null or jsonb_typeof(lim.seats) <> 'number'
        or (lim.seats #>> '{}')::numeric >
           (select count(*) from public.memberships m where m.org_id = i.org_id)
           + (select count(*) from public.invites o
              where o.org_id = i.org_id and o.accepted_at is null and o.expires_at > now()
                and (o.created_at, o.id) < (i.created_at, i.id))
           -- Revoked invites whose person signed up through them.
           + (select count(distinct h.user_id) from public.invite_gate_holds h
              where h.org_id = i.org_id
                and not exists (select 1 from public.memberships m
                                where m.org_id = i.org_id and m.user_id = h.user_id))
           -- Run-out invites whose person signed up while they stood.
           + (select count(distinct u.id) from public.invites o
              join auth.users u on lower(u.email::text) = lower(o.email::text)
              where o.org_id = i.org_id and o.accepted_at is null and o.expires_at <= now()
                and u.created_at >= o.created_at and u.created_at <= o.expires_at
                and not exists (select 1 from public.memberships m
                                where m.org_id = i.org_id and m.user_id = u.id))
      ))
$$;
revoke all on function public.signup_invited_with_seat(text) from public, anon, authenticated;
