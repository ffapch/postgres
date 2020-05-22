 SET max_parallel_workers_per_gather = 0;
 

--EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS, FORMAT JSON)
EXPLAIN (ANALYZE, COSTS)
SELECT t.*
FROM tickets t
INNER JOIN ticket_flights tf ON tf.ticket_no = t.ticket_no
INNER JOIN flights f ON f.flight_id = tf.flight_id
WHERE tf.fare_conditions = 'Business'
  AND f.actual_departure - f.scheduled_departure > interval '5 hour';

 /*  
  Merge Join  (cost=213409.42..364723.93 rows=276001 width=104) (actual time=2953.057..2953.073 rows=2 loops=1)
  Merge Cond: (t.ticket_no = tf.ticket_no)
  ->  Index Scan using tickets_pkey on tickets t  (cost=0.43..139110.29 rows=2949857 width=104) (actual time=0.008..556.171 rows=1336684 loops=1)
  ->  Materialize  (cost=213408.99..214788.99 rows=276001 width=14) (actual time=1605.588..1605.591 rows=2 loops=1)
        ->  Sort  (cost=213408.99..214098.99 rows=276001 width=14) (actual time=1605.582..1605.583 rows=2 loops=1)
              Sort Key: tf.ticket_no
              Sort Method: quicksort  Memory: 25kB
              ->  Hash Join  (cost=6742.28..183748.34 rows=276001 width=14) (actual time=299.481..1605.561 rows=2 loops=1)
                    Hash Cond: (tf.flight_id = f.flight_id)
                    ->  Seq Scan on ticket_flights tf  (cost=0.00..174832.50 rows=828007 width=18) (actual time=0.012..1459.405 rows=859656 loops=1)
                          Filter: ((fare_conditions)::text = 'Business'::text)
                          Rows Removed by Filter: 7532196
                    ->  Hash  (cost=5847.00..5847.00 rows=71622 width=4) (actual time=59.480..59.480 rows=1 loops=1)
                          Buckets: 131072  Batches: 1  Memory Usage: 1025kB
                          ->  Seq Scan on flights f  (cost=0.00..5847.00 rows=71622 width=4) (actual time=45.601..59.461 rows=1 loops=1)
                                Filter: ((actual_departure - scheduled_departure) > '05:00:00'::interval)
                                Rows Removed by Filter: 214866
Planning Time: 0.670 ms
Execution Time: 2953.290 ms
  */
  

create index idx_actual_scheduled_departure on flights((actual_departure-scheduled_departure));
ANALYZE flights;
 
/*
Nested Loop  (cost=12.82..177024.38 rows=8 width=104) (actual time=257.071..1612.163 rows=2 loops=1)
  ->  Hash Join  (cost=12.39..177018.45 rows=8 width=14) (actual time=257.022..1612.078 rows=2 loops=1)
        Hash Cond: (tf.flight_id = f.flight_id)
        ->  Seq Scan on ticket_flights tf  (cost=0.00..174832.50 rows=828007 width=18) (actual time=0.032..1537.304 rows=859656 loops=1)
              Filter: ((fare_conditions)::text = 'Business'::text)
              Rows Removed by Filter: 7532196
        ->  Hash  (cost=12.36..12.36 rows=2 width=4) (actual time=0.018..0.018 rows=1 loops=1)
              Buckets: 1024  Batches: 1  Memory Usage: 9kB
              ->  Index Scan using idx_actual_scheduled_departure on flights f  (cost=0.42..12.36 rows=2 width=4) (actual time=0.008..0.009 rows=1 loops=1)
                    Index Cond: ((actual_departure - scheduled_departure) > '05:00:00'::interval)
  ->  Index Scan using tickets_pkey on tickets t  (cost=0.43..0.74 rows=1 width=104) (actual time=0.036..0.036 rows=1 loops=2)
        Index Cond: (ticket_no = tf.ticket_no)
Planning Time: 0.881 ms
Execution Time: 1612.214 ms
*/

create index idx_flight_id on ticket_flights(flight_id);
ANALYZE ticket_flights;

/*
Nested Loop  (cost=1.28..840.16 rows=8 width=104) (actual time=0.089..0.125 rows=2 loops=1)
  ->  Nested Loop  (cost=0.85..834.42 rows=8 width=14) (actual time=0.057..0.072 rows=2 loops=1)
        ->  Index Scan using idx_actual_scheduled_departure on flights f  (cost=0.42..12.36 rows=2 width=4) (actual time=0.011..0.012 rows=1 loops=1)
              Index Cond: ((actual_departure - scheduled_departure) > '05:00:00'::interval)
        ->  Index Scan using idx_flight_id on ticket_flights tf  (cost=0.43..410.92 rows=11 width=18) (actual time=0.042..0.056 rows=2 loops=1)
              Index Cond: (flight_id = f.flight_id)
              Filter: ((fare_conditions)::text = 'Business'::text)
              Rows Removed by Filter: 10
  ->  Index Scan using tickets_pkey on tickets t  (cost=0.43..0.72 rows=1 width=104) (actual time=0.025..0.025 rows=1 loops=2)
        Index Cond: (ticket_no = tf.ticket_no)
Planning Time: 1.186 ms
Execution Time: 0.160 ms
 */