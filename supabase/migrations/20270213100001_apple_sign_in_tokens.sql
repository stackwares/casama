-- Sign in with Apple token revocation (D-420, App Store 5.1.1(v)). When someone deletes their
-- account, Casama must revoke the Apple tokens it holds for them through Apple's REST API. Apple
-- only hands out a refresh token for an authorization code, so the app sends the code it gets at
-- sign-in and the API swaps it for a refresh token, kept here (the token itself lives in Vault).
-- One row per person and Apple client id: the app's bundle id for the system sheet, the Services
-- ID for the browser sign-in. Only the API and the worker read it; people never do.
create table public.apple_sign_in_tokens (
  user_id uuid not null references auth.users (id) on delete cascade,
  client_id text not null check (char_length(client_id) between 1 and 200),
  -- Apple's stable user id (the token's sub), checked against the person's Apple identity.
  apple_sub text not null check (char_length(apple_sub) between 1 and 200),
  vault_secret_id uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, client_id)
);
alter table public.apple_sign_in_tokens enable row level security;
select public.allow_worker('public.apple_sign_in_tokens');

-- The token goes with its row, however the row goes (revoked, replaced, or the account purged
-- and the row cascading away). The worker can't delete from Vault itself.
create or replace function public.apple_sign_in_tokens_forget_secret()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  delete from vault.secrets s where s.id = old.vault_secret_id;
  return old;
end;
$$;
revoke all on function public.apple_sign_in_tokens_forget_secret() from public, anon, authenticated;

create trigger apple_sign_in_tokens_forget_secret
  after delete on public.apple_sign_in_tokens
  for each row execute function public.apple_sign_in_tokens_forget_secret();

-- A replaced token's old secret goes too.
create or replace function public.apple_sign_in_tokens_replace_secret()
returns trigger
language plpgsql security definer set search_path = ''
as $$
begin
  if old.vault_secret_id is distinct from new.vault_secret_id then
    delete from vault.secrets s where s.id = old.vault_secret_id;
  end if;
  return new;
end;
$$;
revoke all on function public.apple_sign_in_tokens_replace_secret() from public, anon, authenticated;

create trigger apple_sign_in_tokens_replace_secret
  after update of vault_secret_id on public.apple_sign_in_tokens
  for each row execute function public.apple_sign_in_tokens_replace_secret();
