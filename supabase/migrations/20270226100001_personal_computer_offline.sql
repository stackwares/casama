-- A person's own computer that was offline when a bot reached for it was saved as broken, with an
-- error naming it by id (D-447). Offline is its ordinary resting state: put those back.
update public.computers
set state = 'stopped', error = null
where kind = 'local' and state = 'error' and error like '%is offline%';

-- Computers paired before D-447 were all named "This computer", which is only true on the computer
-- itself. Name them after their person and system, as a phone or a bot sees them.
with named as (
  select d.id as device_id, d.computer_id,
         coalesce(nullif(split_part(btrim(p.display_name), ' ', 1), '') || '''s ', '')
           || case d.platform when 'macos' then 'Mac' when 'windows' then 'Windows PC'
                              when 'linux' then 'Linux computer' else 'computer' end as name
  from public.local_devices d
  left join public.profiles p on p.user_id = d.user_id
  where d.name = 'This computer'
), devices as (
  update public.local_devices d set name = n.name from named n where d.id = n.device_id
)
update public.computers c set name = n.name
from named n where c.id = n.computer_id and c.name = 'This computer';
