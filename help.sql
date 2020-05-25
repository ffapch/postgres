select pg_relation_size('employees') / 8192.0;

SELECT * FROM pg_user;

SELECT rolname, rolsuper FROM pg_roles;

ALTER USER andrey WITH SUPERUSER;

SELECT * FROM pg_locks pl


select *
from heap_page_items(get_raw_page('t_monobank_rates', 0));

select *
from get_raw_page('t_monobank_rates', 0);


show config_file;

set work_mem to '64 MB';

select CURRENT_SETTING('work_mem');

show max_parallel_workers_per_gather;
--2

show min_parallel_table_scan_size;
--8MB

show max_worker_processes;
--8

show max_parallel_workers;
--8

set max_parallel_workers_per_gather = 10;

set force_parallel_mode to on;