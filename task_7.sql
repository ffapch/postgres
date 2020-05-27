--------------------------------------------------------------#1


----------------------------------------------------------------pg_stat_statements
create extension if not exists pg_stat_statements;
alter system set shared_preload_libraries = 'pg_stat_statements';

--run in console
--pg_ctl restart -D 'C:/Program Files/PostgreSQL/12/data'

set pg_stat_statements.track = 'all';
select pg_stat_statements_reset();

select
	substring(regexp_replace(query,' +',' ','g') for 100) as query,
	calls,
	round(total_time)/1000 as time_sec,
	shared_blks_hit + shared_blks_read + shared_blks_written as shared_blks
from pg_stat_statements
order by time_sec desc;

/*
query                                                                                               |calls|time_sec|shared_blks|
----------------------------------------------------------------------------------------------------|-----|--------|-----------|
vacuum full                                                                                         |    1| 272.068|     757331|
select pg_sleep($1)                                                                                 |   12| 122.005|          0|
update bookings.airports_data¶set "timezone" = $1¶where "airport_code" = $2                         |   13|   62.77|        140|
SELECT i.*,i.indkey as keys,c.relname,c.relnamespace,c.relam,c.reltablespace,tc.relname as tabrelnam|   17|  53.256|        802|
--EXPLAIN (costs off, analyze)¶SELECT count(*) ¶FROM flights f¶INNER JOIN boarding_passes b on b.   |    4|  20.262|     243615|
create index idx_fare_conditions on ticket_flights(fare_conditions)                                 |    1|  14.351|      70152|
CREATE INDEX boarding_passes_flight_id_boarding_no_seat_no ON bookings.boarding_passes USING btree (|    1|   9.353|      58554|
CREATE INDEX boarding_passes_boarding_no ON bookings.boarding_passes USING btree (boarding_no)      |    1|   8.404|      58454|
vacuum VERBOSE                                                                                      |    1|   6.469|     804720|
EXPLAIN (costs off, analyze)¶SELECT f.flight_id, b.seat_no¶FROM flights f¶INNER JOIN boarding_pas   |    1|   5.735|      61119|
--EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)¶--EXPLAIN (ANALYZE, COSTS)¶SELECT t.*¶FROM|    2|   4.083|     105857|
select pg_sleep($1)                                                                                 |    4|   4.042|          0|
EXPLAIN (costs off, analyze)¶SELECT count(*) ¶FROM flights f¶INNER JOIN boarding_passes b on b.fl   |    2|   3.819|     122253|
vacuum verbose ANALYZE                                                                              |    1|   3.437|     114348|
EXPLAIN analyze¶SELECT count(*) ¶FROM flights f¶INNER JOIN boarding_passes b on b.flight_id = f.f   |    1|   1.913|      61019|
analyze bookings.boarding_passes                                                                    |    2|   1.575|      60357|
explain (costs off, analyze)¶SELECT ticket_no, flight_id, boarding_no, seat_no¶FROM bookings.board  |    2|   1.485|     116618|
explain analyze¶SELECT ticket_no, flight_id, boarding_no, seat_no¶FROM bookings.boarding_passes¶w   |    1|   0.755|      58282|
 */

---------------------------------------------------------------log_min_duration_statement
show logging_collector;
--on
show log_directory;
--log
alter system set log_min_duration_statement to 100;
select pg_reload_conf();

select pg_sleep(2);
/*
messages from log
2020-05-27 14:05:00.257 EEST [9756] ÑÎÎÁÙÅÍÈÅ:  ïðîäîëæèòåëüíîñòü: 2001.063 ìñ  âûïîëíåíèå <unnamed>: select pg_sleep(2)
2020-05-27 14:08:59.932 EEST [3532] ÑÎÎÁÙÅÍÈÅ:  ïðîäîëæèòåëüíîñòü: 5159.450 ìñ  âûïîëíåíèå <unnamed>:
SELECT count(*) 
	FROM flights f
	INNER JOIN boarding_passes b on b.flight_id = f.flight_id
 */

---------------------------------------------------------------log_deadlock
alter system set log_lock_waits to true;
alter system set deadlock_timeout to 100;
select pg_reload_conf();

--execute in first session
begin;

update bookings.airports_data
set "timezone" = 'Unknown'
where "airport_code" = 'YKS';

select pg_sleep(5);

rollback;

--execute in second session
begin;

update bookings.airports_data
set "timezone" = 'Unknown'
where "airport_code" = 'YKS';

rollback;

/*
2020-05-27 16:06:00.582 EEST [7148] ÑÎÎÁÙÅÍÈÅ:  ïðîöåññ 7148 ïðîäîëæàåò îæèäàòü â ðåæèìå ShareLock áëîêèðîâêó "òðàíçàêöèÿ 683" â òå÷åíèå 100.039 ìñ
2020-05-27 16:06:00.582 EEST [7148] ÏÎÄÐÎÁÍÎÑÒÈ:  Process holding the lock: 2008. Wait queue: 7148.
2020-05-27 16:06:00.582 EEST [7148] ÊÎÍÒÅÊÑÒ:  ïðè èçìåíåíèè êîðòåæà (0,1) â îòíîøåíèè "airports_data"
2020-05-27 16:06:00.582 EEST [7148] ÎÏÅÐÀÒÎÐ:  update bookings.airports_data
	set "timezone" = 'Unknown'
	where "airport_code" = 'YKS'
2020-05-27 16:06:03.900 EEST [7148] ÑÎÎÁÙÅÍÈÅ:  ïðîöåññ 7148 ïîëó÷èë â ðåæèìå ShareLock áëîêèðîâêó "òðàíçàêöèÿ 683" ÷åðåç 3418.209 ìñ
2020-05-27 16:06:03.900 EEST [7148] ÊÎÍÒÅÊÑÒ:  ïðè èçìåíåíèè êîðòåæà (0,1) â îòíîøåíèè "airports_data"
2020-05-27 16:06:03.900 EEST [7148] ÎÏÅÐÀÒÎÐ:  update bookings.airports_data
	set "timezone" = 'Unknown'
	where "airport_code" = 'YKS'
 */



---------------------------------------------------------------#2
-- check seq_scans
SELECT schemaname,
       relname,
       seq_scan,
       seq_tup_read,
       idx_scan,
       seq_tup_read / seq_scan AS avg
FROM pg_stat_user_tables
WHERE seq_scan > 0
ORDER BY seq_tup_read DESC
LIMIT 20;

/*
schemaname|relname        |seq_scan|seq_tup_read|idx_scan|avg    |
----------|---------------|--------|------------|--------|-------|
bookings  |boarding_passes|     102|   360404931|      85|3533381|
bookings  |ticket_flights |      42|   235185034|     235|5599643|
bookings  |tickets        |      12|    26548913|     248|2212409|
bookings  |flights        |      91|    12462486|     182| 136950|
bookings  |bookings       |       6|     8444440|       2|1407406|
bookings  |seats          |       7|        6156|       0|    879|
bookings  |airports_data  |      29|        3029|       4|    104|
bookings  |aircrafts_data |       6|          54|       0|      9|
 */

-- unused indexes
SELECT s.schemaname,
       s.relname                      AS tablename,
       s.indexrelname                 AS indexname,
       pg_relation_size(s.indexrelid) AS index_size
FROM pg_catalog.pg_stat_user_indexes s
         JOIN pg_catalog.pg_index i ON s.indexrelid = i.indexrelid
WHERE s.idx_scan = 0      -- has never been scanned
  AND 0 <> ALL (i.indkey) -- no index column is an expression
  AND NOT i.indisunique   -- is not a UNIQUE index
  AND NOT EXISTS -- does not enforce a constraint
    (SELECT 1
     FROM pg_catalog.pg_constraint c
     WHERE c.conindid = s.indexrelid)
ORDER BY pg_relation_size(s.indexrelid) DESC;

/*
schemaname|tablename     |indexname          |index_size|
----------|--------------|-------------------|----------|
bookings  |ticket_flights|idx_fare_conditions| 196599808|
 */


-- low_used_indexes
SELECT pg_stat_user_indexes.schemaname || '.' || pg_stat_user_indexes.relname tablemane
     , pg_stat_user_indexes.indexrelname
     , pg_stat_user_indexes.idx_scan
     , psut.write_activity
     , psut.seq_scan
     , psut.n_live_tup
     , pg_size_pretty(pg_relation_size(pg_index.indexrelid::regclass)) as     size
from pg_stat_user_indexes
         join pg_index
              ON pg_stat_user_indexes.indexrelid = pg_index.indexrelid
         join (select pg_stat_user_tables.relid
                    , pg_stat_user_tables.seq_scan
                    , pg_stat_user_tables.n_live_tup
                    , (coalesce(pg_stat_user_tables.n_tup_ins, 0)
                           + coalesce(pg_stat_user_tables.n_tup_upd, 0)
                           - coalesce(pg_stat_user_tables.n_tup_hot_upd, 0)
        + coalesce(pg_stat_user_tables.n_tup_del, 0)
        ) as write_activity
               from pg_stat_user_tables) psut
              on pg_stat_user_indexes.relid = psut.relid
where pg_index.indisunique is false
  and pg_stat_user_indexes.idx_scan::float / (psut.write_activity + 1)::float < 0.01
  and psut.write_activity > case when pg_is_in_recovery() then -1 else 10000 end
order by 3 ASC, 1, 2;

/*
tablemane               |indexrelname                                 |idx_scan|write_activity|seq_scan|n_live_tup|size   |
------------------------|---------------------------------------------|--------|--------------|--------|----------|-------|
bookings.ticket_flights |idx_fare_conditions                          |       0|       8391852|      42|   8391708|187 MB |
bookings.boarding_passes|boarding_passes_boarding_no                  |       4|       7925812|     102|   7925688|170 MB |
bookings.boarding_passes|boarding_passes_flight_id_boarding_no_seat_no|      13|       7925812|     102|   7925688|238 MB |
bookings.flights        |idx_actual_scheduled_departure               |      36|        214867|      91|    214867|6512 kB|
bookings.ticket_flights |idx_flight_id                                |      55|       8391852|      42|   8391708|180 MB |
 */


-- redundant_indexes
WITH index_data AS
         (SELECT *,
                 string_to_array(indkey::text, ' ')                  as key_array,
                 array_length(string_to_array(indkey::text, ' '), 1) as nkeys
          from pg_index)
SELECT i1.indrelid::regclass::text,
       pg_get_indexdef(i1.indexrelid)                  main_index,
       pg_get_indexdef(i2.indexrelid)                  redundant_index,
       pg_size_pretty(pg_relation_size(i2.indexrelid)) redundant_index_size
FROM index_data as i1
         JOIN
     index_data as i2
     ON i1.indrelid = i2.indrelid AND i1.indexrelid <> i2.indexrelid
WHERE (regexp_replace(i1.indpred, 'location \d+', 'location', 'g') IS NOT DISTINCT FROM
       regexp_replace(i2.indpred, 'location \d+', 'location', 'g'))
  AND (regexp_replace(i1.indexprs, 'location \d+', 'location', 'g') IS NOT DISTINCT FROM
       regexp_replace(i2.indexprs, 'location \d+', 'location', 'g'))
  AND ((i1.nkeys > i2.nkeys and not i2.indisunique) OR (i1.nkeys = i2.nkeys and
                                                        ((i1.indisunique and i2.indisunique and (i1.indexrelid > i2.indexrelid)) or
                                                         (not i1.indisunique and not i2.indisunique and
                                                          (i1.indexrelid > i2.indexrelid)) or
                                                         (i1.indisunique and not i2.indisunique))))
  AND i1.key_array[1:i2.nkeys] = i2.key_array
ORDER BY pg_relation_size(i2.indexrelid) desc, i1.indexrelid::regclass::text, i2.indexrelid::regclass::text;

/*
indrelid|main_index|redundant_index|redundant_index_size|
--------|----------|---------------|--------------------|
*/

----------------------------------------------------------------------------summary
drop index idx_fare_conditions;
drop index boarding_passes_boarding_no;
