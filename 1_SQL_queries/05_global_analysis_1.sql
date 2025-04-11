
/*------------------------------------------------------------------------------------------------------------
🔵5.A) COMPARE GLOBAL TEMPERATURE STATISTICS WITH AND WITHOUT IQR OUTLIER FILTERING (USING INLINE SUBQUERIES)
------------------------------------------------------------------------------------------------------------*/
--These two queries calculate summary statistics (min, max, avg, stddev) for both filtered and unfiltered datasets.
--The first uses inline subqueries to contrast results directly in one SELECT; the second leverages CTEs and CROSS JOIN for efficiency.
--Together they highlight how IQR filtering affects the global distribution and demonstrate two flexible SQL methods.

	🔵5.A.1)--Temperature statistics without IQR filter
		
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

	--NOTE: this verison is not as efficient as the following one because every 'filtered' row runs a separate query.
	--this version purpose is to showcase querying abilities!
		
	🔵5.A.1)--Temperature statistics with IQR filter
		
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

	-- NOTE: The second query is more efficient as it avoids repeated subqueries by using a CTE and a CROSS JOIN. 
	-- However, both versions are included to demonstrate alternative querying methods and showcase flexibility in SQL logic and syntax.

/*------------------------------------------------------------------------------------------------------------
🔴5.B) FIND THE HOTTEST AND COLDEST YEARS GLOBALLY. IF NEEDED, USE LIMIT 5 TO RETRIEVE ONLY THE TOP 5 RESULTS
-------------------------------------------------------------------------------------------------------------*/

--These queries group temperature data by year and calculate the average to rank the hottest and coldest years.
--They use ORDER BY on the average temperature and LIMIT 5 to return the top extremes.
--This gives a clear overview of historic temperature peaks and troughs globally.

	🔵5.B.1) --retrieves coldest years globally
		
	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp) desc
	limit 5;


	🔵5.B.2)--retrieves coldest years globally

	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t 
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp)
	limit 5;



/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴5.C) CALCULATE AND RANK THE AVERAGE TEMPERATURE CHANGE FOR EACH COUNTRY OVER TIME. HIGHLIGHT THE TOP 15 FASTEST-WARMING COUNTRIES AND RETRIEVE THE FULL DATASET IF NEEDED
---------------------------------------------------------------------------------------------------------------------------------------------*/

--These queries calculate the slope of temperature change over time using REGR_SLOPE across years per country.
--Version A includes all years; Version B filters for post-1900 to reflect modern warming trends more accurately.
--They help identify the fastest-warming countries and can be adjusted to retrieve top N results or the single highest.

	🔵5.C.1) Version A: Regression for all years

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


	🔵3.C.2)--Version B: Regression post-1900 (used in main analysis)

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
🔴5.D) Identify the country with the highest temperature increase. Optionally, filter for the last century (year > 1900)
---------------------------------------------------------------------------------------------------------------------------------------------*/

--This query isolates the country with the steepest warming trend since 1900 using linear regression.
--It groups average temperature by year, runs REGR_SLOPE, and sorts by the slope to find the top result.
--Useful for spotlighting climate hotspots and contextualizing national-level climate change impacts.


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
