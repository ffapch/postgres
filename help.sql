------------------------------------------------------------------------------------------------roles
SELECT rolname, rolsuper FROM pg_roles;
ALTER USER andrey WITH SUPERUSER;

------------------------------------------------------------------------------------------------size
create extension pageinspect;

select pg_relation_size('employees') / 8192.0;
select *
from heap_page_items(get_raw_page('t_monobank_rates', 0));
select *
from get_raw_page('t_monobank_rates', 0);

------------------------------------------------------------------------------------------------config
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

------------------------------------------------------------------------------------------------generate_series
create table t (a float);
insert into t select random() from generate_series(1,3);

------------------------------------------------------------------------------------------------extensions
select * from pg_available_extensions where name like 'pl%';

create extension pg_stat_statements;

------------------------------------------------------------------------------------------------locks
select pg_backend_pid();
select locktype, relation::REGCLASS, virtualxid, transactionId, mode, granted from pg_locks pl;
select pg_blocking_pids(2728); --processes who blocks our transaction 2728
select * from pg_stat_activity where pid = any(pg_blocking_pids(2728));

------------------------------------------------------------------------------------------------pg_stat_statements monitoring
create extension pg_stat_statements;
alter system set shared_preload_libraries = 'pg_stat_statements';
pg_ctl restart -D /var/lib/postgresql/data
set pg_stat_statements.track = 'all';
select pg_stat_statements_reset();
select * from pg_class;

-------------------------------------------------------------------------------------------------logging
show logging_collector;
show log_directory;
show data_directory;
show log_lock_waits;
show log_connections;
show log_duration;
show log_min_duration_statement;

----------------------------------------------------
alter system set log_min_duration_statement to 1000;
select pg_reload_conf(); -- reload config due to changes
----------------------------------------------------
load 'auto_explain';
set auto_explain.log_min_duration = 1000;
set auto_explain.log_analyze = true;
----------------------------------------------------

select pg_sleep(2);
