-- Whether a bot's ring reached anything (D-438): a phone took it, or a computer or browser could
-- show the banner. A ring that reached nothing doesn't count toward the ring limits (D-426), so
-- a phone with no call token yet doesn't hold back the next try for the cooldown.
alter table public.voice_calls add column reached boolean not null default true;
