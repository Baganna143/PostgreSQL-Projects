                                                    -- SQL Pancard project

-- table creation
create table pancard_information(
	pancard text
);

select * from pancard_information;


--handling missing data
select * from pancard_information where pancard is null;


--handling duplicate values
select pancard, count(1) from pancard_information group by pancard having count(1)>1;


--handling trailling and leading spaces
select pancard from pancard_information where pancard <> trim(pancard);


--Data cleaning and preprocessing
create table cln_pancard_information as 
(select distinct upper(trim(pancard)) as pancard from pancard_information where pancard is not null and trim(pancard) <> '');
select * from cln_pancard_information;

                                              -- Pancard Validation

--pattern matching
select pancard from cln_pancard_information 
where pancard ~ '^[A-Z]{5}[0-9]{4}[A-Z]$';


--checking adjacent characters
create or replace function chk_adjacent_char(p_str text)
returns boolean
language plpgsql
as $$
begin
	for i in 1..(length(p_str)-1)
	loop
		if substring(p_str,i,1) = substring(p_str,i+1,1)
		then 
		return true;
		end if;
	end loop;
		return false;
end $$;


--checking character sequence
create or replace function chk_char_sequence(p_str text)
returns boolean
language plpgsql
as $$
begin
	for i in 1..(length(p_str)-1)
	loop
		if ascii(substring(p_str,i+1,1)) - ascii(substring(p_str,i,1)) <> 1
		then
			return false;
		end if;
	end loop;
			return true;
end $$;


--Categorisation


create view formatted_pancards as		
		(select pancard from cln_pancard_information
		where pancard ~ '^[A-Z]{5}[0-9]{4}[A-Z]$' 
		and chk_adjacent_char(substring(pancard,1,5)) = false
		and chk_char_sequence(substring(pancard,1,5)) = false
		and chk_adjacent_char(substring(pancard,6,4)) = false
		and chk_char_sequence(substring(pancard,6,4)) = false);



--Summary of problem statement
select Total_Processed, Valid_Pans, Invalid_Pans, (Total_Processed - (Invalid_Pans+Valid_Pans)) as missing_pans
from (select (select count(*) from pancard_information) as Total_Processed,
	   count(pancard) filter(where status = 'Valid pan') as Valid_Pans,
	   count(pancard) filter(where status = 'Invalid pan') as Invalid_Pans
from
(select cln.pancard,
	case when vld.pancard is null
	then 'Invalid pan'
	else 'Valid pan'
	end as status
from cln_pancard_information as cln
left join formatted_pancards as vld
on cln.pancard = vld.pancard));













