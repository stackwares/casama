-- Bot-to-bot switch (SPEC: Post-v1 roadmap → Bot-to-bot switch; D-133): owners and admins can stop
-- bots from @mentioning, messaging and delegating to each other. Subagents still work.
alter table public.organizations add column allow_bot_to_bot boolean not null default true;
