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