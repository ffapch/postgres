create table if not exists customers (
    customer_id bigint,
    title text,
    first_name text,
    last_name text,
    suffix text,
    email text,
    gender text,
    ip_address text,
    phone text,
    street_address text,
    city text,
    state text,
    postal_code text,
    latitude text,
    longitude text,
    date_added timestamp without time zone
);

/*
begin;
\copy customers from program 'curl "http://academy.sql.ua/secret/customers.csv"' with (format csv, header);
end;
*/

-----------------------------------------before idx
explain analyze
select * from customers
where ip_address = '18.131.58.65';

/*
 * Seq Scan on customers  (cost=0.00..1668.00 rows=1 width=141) (actual time=0.026..9.010 rows=1 loops=1)
  Filter: (ip_address = '18.131.58.65'::text)
 * */

-----------------------------------------create generic idx
create index ip_idx on customers(ip_address);

-----------------------------------------after generic idx
explain analyze
select * from customers
where ip_address = '18.131.58.65';

/*
 * Index Scan using ip_idx on customers  (cost=0.29..8.31 rows=1 width=141) (actual time=0.045..0.046 rows=1 loops=1)
  Index Cond: (ip_address = '18.131.58.65'::text)
 * */

-----------------------------------------create ix_ip_where
create index ix_ip_where on customers(ip_address)
where ip_address = '18.131.58.65';

-----------------------------------------after ix_ip_where
explain analyze
select * from customers
where ip_address = '18.131.58.65';

/*
 * Index Scan using ix_ip_where on customers  (cost=0.12..8.14 rows=1 width=141) (actual time=0.024..0.024 rows=1 loops=1)
 * */

-----------------------------------------suffix of Jr before ix_jr
explain analyze
select * from customers
where suffix = 'Jr';

/*
 * Seq Scan on customers  (cost=0.00..1668.00 rows=105 width=141) (actual time=0.011..6.810 rows=102 loops=1)
  Filter: (suffix = 'Jr'::text)
 */

----------------------------------------create ix_jr
create index ix_jr on customers(suffix);

-----------------------------------------after ix_jr
explain analyze
select * from customers
where suffix = 'Jr';

/*
 * Bitmap Heap Scan on customers  (cost=5.10..313.52 rows=105 width=141) (actual time=0.062..0.192 rows=102 loops=1)
  Recheck Cond: (suffix = 'Jr'::text)
  Heap Blocks: exact=101
  ->  Bitmap Index Scan on ix_jr  (cost=0.00..5.08 rows=105 width=0) (actual time=0.046..0.046 rows=102 loops=1)
        Index Cond: (suffix = 'Jr'::text)
 * */
