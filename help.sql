select pg_relation_size('employees') / 8192.0;

SELECT * FROM pg_user;

SELECT rolname, rolsuper FROM pg_roles;

ALTER USER andrey.dovbnya WITH SUPERUSER;

SELECT * FROM pg_locks pl


select *
from heap_page_items(get_raw_page('t_monobank_rates', 0));

select *
from get_raw_page('t_monobank_rates', 0);