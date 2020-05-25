----------------------------------------------------#1
create or replace function cut_name(last_name text, first_name text, middle_name text) returns text 
language plpgsql 
immutable
as
$$
declare 
	last_name_trim text := trim(last_name);
	first_name_trim text := trim(leading first_name);
	middle_name_trim text := trim(leading middle_name);
begin 
	return upper(left(last_name_trim, 1)) || right(last_name_trim, char_length(last_name_trim) - 1) || ' ' || upper(left(first_name_trim, 1)) || '. ' || upper(left(middle_name_trim, 1)) || '.';
end
$$;

select cut_name('Ivanov', 'Ivan', 'Petrovich');
select cut_name(' shalts ', ' andrey', ' nikiforovich ');


----------------------------------------------------#2
create or replace function quadratic_equation(a real, b real, c real) returns RECORD
language plpgsql
as
$$
declare 
	D real;
	quadratic_roots RECORD;
begin
	D := b*b - 4*a*c;
	if D > 0 then
		select (-b - sqrt(D))/(2*a) as x1, (-b + sqrt(D))/(2*a) as x2 into quadratic_roots;
	elsif D = 0 then
		select -b/(2*a) as x1, null as x2 into quadratic_roots;
	else 
		select null as x1, null as x2 into quadratic_roots;
	end if;
	return quadratic_roots;
end
$$;

select quadratic_equation(2, 5 , -7);  --D > 0
select quadratic_equation(16, -8 , 1); --D = 0
select quadratic_equation(9, -6 , 2);  --D < 0

----------------------------------------------------#3
alter function quadratic_equation(a real, b real, c real) strict immutable;