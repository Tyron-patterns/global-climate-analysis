
/*------------------------------------------------------------------------------------------------------------
🔵3.A) COMPARE GLOBAL TEMPERATURE STATISTICS WITH AND WITHOUT IQR OUTLIER FILTERING (USING INLINE SUBQUERIES)
------------------------------------------------------------------------------------------------------------*/
	select round(min(averagetemp)::numeric,3) as unfiltered_min, 
	round(max(averagetemp)::numeric,3) as unfiltered_max, 
	round(avg(averagetemp)::numeric,3) as unfiltered_avg, 
	round(stddev(averagetemp)::numeric,3) as unfiltered_std,
	'<--------------------------------->' as unfiltered_____filtered,
	(select round(min(averagetemp)::numeric,3) as filtered_min from global_IQR), 
	(select round(max(averagetemp)::numeric,3) as filtered_max from global_IQR), 
	(select round(avg(averagetemp)::numeric,3) as filtered_avg from global_IQR), 
	(select round(stddev(averagetemp)::numeric,3) as filtered_std from global_IQR)
	from global_t
	
	with filtered as ( -- comparing values using virtual table
	select  round(min(averagetemp)::numeric,3) as filtered_min,
			round(max(averagetemp)::numeric,3) as filtered_max,
			round(avg(averagetemp)::numeric,3) as filtered_avg,
			round(stddev(averagetemp)::numeric,3) as filtered_std
			from global_IQR
	), unfiltered as ( 
	select round(min(averagetemp)::numeric,3) as unfiltered_min, 
	round(max(averagetemp)::numeric,3) as unfiltered_max, 
	round(avg(averagetemp)::numeric,3) as unfiltered_avg, 
	round(stddev(averagetemp)::numeric,3) as unfiltered_std,
	from global_t)
	select filtered.*,   
	'<--------------------------------->' as unfiltered_____filtered,
	unfiltered.*
	from unfiltered CROSS JOIN filtered


/*------------------------------------------------------------------------------------------------------------
🔴3.B) FIND THE HOTTEST AND COLDEST YEARS GLOBALLY. IF NEEDED, USE LIMIT 5 TO RETRIEVE ONLY THE TOP 5 RESULTS
-------------------------------------------------------------------------------------------------------------*/

	🔵3.B.1) retrieves hottest years globally
	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp) desc
	limit 5;


	🔵3.B.2) retrieves coldest years globally

	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t 
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp)
	limit 5;



/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴3.C) CALCULATE AND RANK THE AVERAGE TEMPERATURE CHANGE FOR EACH COUNTRY OVER TIME. HIGHLIGHT THE TOP 15 FASTEST-WARMING COUNTRIES AND RETRIEVE THE FULL DATASET IF NEEDED
---------------------------------------------------------------------------------------------------------------------------------------------*/

	🔵3.C.1) Version A: Regression for all years

	select country, 
			round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select country, 
				extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
		from global_t 
		where averagetemp is not null 								
		and country not in ('North America', 'South America', 'Africa', 'Europe', 'Australia', 'Asia')
		group by year, country) 
	group by country 
	having regr_slope(avg_temp_per_year, year) is not null
	order by temp_increase desc;


	-- include to retrieve only the 15 fastest warming countries

	order by temp_increase desc 
	limit 15;

	-- include to retrieve the single fastest warming country

	order by temp_increase desc 
	limit 1;


	🔵3.C.2)Version B: Regression post-1900 (used in main analysis)

	select country, 
			round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year,
				country
			from global_t 
			group by year, country) 
	where year > '1900' -- remove to retrieve ranking for the entire time span
	group by country
	having regr_slope (avg_temp_per_year, year) is not null
	order by temp_increase desc;



/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴3.D) Identify the country with the highest temperature increase. Optionally, filter for the last century (year > 1900)
---------------------------------------------------------------------------------------------------------------------------------------------*/

select country, --highest temp increase overtime in 1900
round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
from (select extract(year from dt) as year, 
round(avg(averagetemp)::numeric,2) as avg_temp_per_year,
country
from global_t 
group by year, country) 
where year > '1900' -- remove to retrieve ranking for the entire time span
group by country
having regr_slope (avg_temp_per_year, year) is not null
order by temp_increase desc;
