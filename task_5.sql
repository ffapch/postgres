
SET max_parallel_workers_per_gather = 0;

EXPLAIN (costs off, analyze)
SELECT f.flight_id, b.seat_no
FROM flights f
INNER JOIN boarding_passes b on b.flight_id = f.flight_id;

/*
Hash Join (actual time=76.245..5568.431 rows=7925812 loops=1)
  Hash Cond: (b.flight_id = f.flight_id)
  ->  Seq Scan on boarding_passes b (actual time=0.012..1814.204 rows=7925812 loops=1)
  ->  Hash (actual time=75.350..75.351 rows=214867 loops=1)
        Buckets: 131072  Batches: 4  Memory Usage: 2917kB
        ->  Seq Scan on flights f (actual time=0.009..30.016 rows=214867 loops=1)
Planning Time: 0.285 ms
Execution Time: 5910.131 ms
 */

set work_mem to '16 MB';

EXPLAIN (costs off, analyze)
SELECT f.flight_id, b.seat_no
FROM flights f
INNER JOIN boarding_passes b on b.flight_id = f.flight_id;

/*
Hash Join (actual time=77.305..3497.902 rows=7925812 loops=1)
  Hash Cond: (b.flight_id = f.flight_id)
  ->  Seq Scan on boarding_passes b (actual time=0.015..1165.567 rows=7925812 loops=1)
  ->  Hash (actual time=76.159..76.159 rows=214867 loops=1)
        Buckets: 262144  Batches: 1  Memory Usage: 9602kB
        ->  Seq Scan on flights f (actual time=0.020..30.391 rows=214867 loops=1)
Planning Time: 0.324 ms
Execution Time: 3835.202 ms
 */

EXPLAIN (costs off, analyze)
SELECT count(*) 
FROM flights f
INNER JOIN boarding_passes b on b.flight_id = f.flight_id;

/*
Aggregate (actual time=3713.060..3713.060 rows=1 loops=1)
  ->  Hash Join (actual time=81.916..3184.249 rows=7925812 loops=1)
        Hash Cond: (b.flight_id = f.flight_id)
        ->  Seq Scan on boarding_passes b (actual time=0.011..1187.115 rows=7925812 loops=1)
        ->  Hash (actual time=80.917..80.918 rows=214867 loops=1)
              Buckets: 262144  Batches: 1  Memory Usage: 9602kB
              ->  Seq Scan on flights f (actual time=0.014..31.891 rows=214867 loops=1)
Planning Time: 0.280 ms
Execution Time: 3714.719 ms
 */

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

EXPLAIN analyze
SELECT count(*) 
FROM flights f
INNER JOIN boarding_passes b on b.flight_id = f.flight_id;

/*
Finalize Aggregate  (cost=94716.35..94716.36 rows=1 width=8) (actual time=1952.813..1952.813 rows=1 loops=1)
  ->  Gather  (cost=94715.93..94716.34 rows=4 width=8) (actual time=1951.208..1964.065 rows=5 loops=1)
        Workers Planned: 4
        Workers Launched: 4
        ->  Partial Aggregate  (cost=93715.93..93715.94 rows=1 width=8) (actual time=1837.666..1837.666 rows=1 loops=5)
              ->  Parallel Hash Join  (cost=5467.82..88762.38 rows=1981422 width=0) (actual time=31.871..1634.617 rows=1585162 loops=5)
                    Hash Cond: (b.flight_id = f.flight_id)
                    ->  Parallel Seq Scan on boarding_passes b  (cost=0.00..78093.22 rows=1981422 width=4) (actual time=0.059..789.064 rows=1585162 loops=5)
                    ->  Parallel Hash  (cost=3887.92..3887.92 rows=126392 width=4) (actual time=30.479..30.479 rows=42973 loops=5)
                          Buckets: 262144  Batches: 1  Memory Usage: 10496kB
                          ->  Parallel Seq Scan on flights f  (cost=0.00..3887.92 rows=126392 width=4) (actual time=0.018..24.426 rows=107434 loops=2)
Planning Time: 0.303 ms
Execution Time: 1964.128 ms
 */
