begin;

----------------------------- tables-----------------------------
create table if not exists t_minfin_auction (id serial primary key, auction json, created_at TIMESTAMPTZ DEFAULT Now());
create table if not exists t_monobank_rates (id serial primary key, currency json, created_at TIMESTAMPTZ DEFAULT Now());
create table if not exists t_currency_codes (entity varchar(100), currency varchar(100), alphabetic_code char(3), numeric_code int2, minor_unit varchar(10), withdrawal_date varchar(50));


----------------------------- views -----------------------------
create or replace view v_currency_codes as
select distinct lower(alphabetic_code) as alphabetic_code, numeric_code
FROM public.t_currency_codes
where alphabetic_code is not null and numeric_code is not null;

create or replace view v_minfin_auction as
select Minfin.*, CC.numeric_code as currency_code
from 
	(select
		lower(json_object_keys(item.auction)) as currency,
		(item.auction -> json_object_keys(item.auction) ->> 'ask')::numeric as ask,
		(item.auction -> json_object_keys(item.auction) ->> 'bid')::numeric as bid,
		item.created_at as created_at
	from 
		(select auction, created_at
		from t_minfin_auction
		order by id desc
		limit 1) as item
	) as Minfin
left join v_currency_codes as CC on CC.alphabetic_code = Minfin.currency;
	

create or replace view v_monobank_rates as
select
	(json_array_elements(item.currency) ->> 'currencyCodeA')::int2 as currency_code_A,
	(json_array_elements(item.currency) ->> 'currencyCodeB')::int2 as currency_code_B,
	to_timestamp((json_array_elements(item.currency) ->> 'date')::numeric) as date,
	(json_array_elements(item.currency) ->> 'rateBuy')::numeric as rateBuy,
	(json_array_elements(item.currency) ->> 'rateSell')::numeric as rateSell
from
	(select	currency
	from t_monobank_rates
	order by id desc
	limit 1) as item;

end;

--------------------------------load data-------------------------------
/*
\copy t_minfin_auction(auction) from program 'curl "https://academy.sql.ua/secret/minfin_auction.json"';
\copy t_monobank_rates(currency) from program 'curl "https://api.monobank.ua/bank/currency"';
\copy t_currency_codes from program 'curl "http://academy.sql.ua/secret/dict_currencies.csv"' DELIMITER ',' CSV HEADER;
*/

--------------------------------processing------------------------------

select pg_advisory_lock(1);

begin transaction isolation level repeatable read;

with constants AS (
	select 980 as uah_code,
	'час купувати у Monobank' as recommendation
)
select 
	Now() as time_processing,
	Monobank.currency_code_a as currency_code,
	Monobank.ratesell as monobank_sell_rate,
	Minfin.bid as minfin_bid_rate,
	(case when
		Monobank.RateSell < Minfin.bid
	then (select recommendation from constants) end) as recommendation
from v_minfin_auction as Minfin
inner join v_monobank_rates as Monobank on Monobank.currency_code_a = Minfin.currency_code 
where Monobank.currency_code_b = (select uah_code from constants)
	and Monobank.ratesell is not null
	and Minfin.bid is not null;

end transaction;

select pg_advisory_unlock(1);



/*
drop view if exists v_currency_codes cascade;
drop view if exists v_minfin_auction cascade;
drop view if exists v_monobank_rates cascade;
drop table if exists t_currency_codes cascade;
drop table if exists t_monobank_rates cascade;
drop table if exists t_minfin_auction cascade;
*/
