-- Casama's monthly email from the app (D-408). The list itself lives in Resend (D-404); this keeps
-- each person's choice and what Resend was last told, so a failed call is tried again later.
--
-- A person reads only their own row. The API writes it (it also talks to Resend); the worker retries
-- rows whose sync failed. Nobody else, not even people in the same workspace, sees the choice.
create table if not exists public.newsletter_subscriptions (
  user_id uuid primary key references auth.users (id) on delete cascade,
  -- The person's choice. Off until they turn it on: nobody is added without asking.
  subscribed boolean not null default false,
  -- Where the last choice was made: settings, signup, card (the one-time card), or email (they
  -- unsubscribed from an email, which Resend's webhook reports).
  changed_via text check (changed_via in ('settings', 'signup', 'card', 'email')),
  changed_at timestamptz not null default now(),
  -- When the app asked (the sign-up box or the one-time card), so the card shows only once.
  asked_at timestamptz,
  -- The address Resend has for this person because of the app, null when it has none.
  resend_email text check (char_length(resend_email) <= 320),
  -- Resend hasn't been told about the latest change (a failed call, an email change, a deletion).
  sync_due boolean not null default false,
  sync_tries integer not null default 0,
  synced_at timestamptz,
  -- Bumped on every change, so a slow sync can't mark a newer change as done.
  version integer not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists newsletter_subscriptions_due_idx on public.newsletter_subscriptions (user_id)
  where sync_due;
create index if not exists newsletter_subscriptions_email_idx on public.newsletter_subscriptions (lower(resend_email))
  where resend_email is not null;

alter table public.newsletter_subscriptions enable row level security;

drop policy if exists newsletter_subscriptions_select on public.newsletter_subscriptions;
create policy newsletter_subscriptions_select on public.newsletter_subscriptions for select to authenticated
  using (user_id = (select auth.uid()));
-- Changes go through the API, which tells Resend; the address Resend has is never shown.
revoke all on public.newsletter_subscriptions from anon, authenticated;
grant select (user_id, subscribed, changed_via, changed_at, asked_at) on public.newsletter_subscriptions
  to authenticated;

select public.allow_worker('public.newsletter_subscriptions');

-- A changed sign-in email moves the subscription: the worker removes the old address from Resend
-- and adds the new one (when they're subscribed).
create or replace function public.newsletter_email_changed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.newsletter_subscriptions
  set sync_due = true, version = version + 1
  where user_id = new.id and (subscribed or resend_email is not null);
  return new;
end;
$$;
revoke all on function public.newsletter_email_changed() from public, anon, authenticated;

drop trigger if exists on_auth_user_email_newsletter on auth.users;
create trigger on_auth_user_email_newsletter
after update of email on auth.users
for each row when (old.email is distinct from new.email)
execute function public.newsletter_email_changed();
