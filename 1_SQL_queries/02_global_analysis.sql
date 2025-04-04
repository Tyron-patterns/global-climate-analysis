
							/*===========================================================									
							🌡️ GLOBAL TEMPERATURE ANALYSIS

							This script includes:
							- Summary statistics (min, max, avg, stddev globally and per country)
							- Hottest and coldest years
							- Regression slope of temperature increase per country and continent
							- Europe-specific trends and fast-warming countries
							- Countries with the most missing temperature data
							===========================================================*/

/*---------------------------------
🔴3.A) CHECK FOR MEANINGFUL VALUES
----------------------------------*/

	🔵3.A.1) retrieves important values on a global level

	select min(averagetemp) as min, 
			round(max(averagetemp)::numeric, 3) as max,--checks for important values 
			round(avg(averagetemp)::numeric, 3) as avg, 
			round(STDDEV(averagetemp)::numeric,3) as stddev,
			min(averagetempuncertainty) as min, 
			max(averagetempuncertainty) as max, 
			round(avg(averagetempuncertainty)::numeric,3) as avg, round(STDDEV(averagetempuncertainty)::numeric,3) as stddev
	from global_t;

	
	🔵3.A.2) retrieves average of important values on a country level

	select round(avg(min_temp)::numeric,3) as avg_min, -- average important values on a country level
			round(avg(max_temp)::numeric,3) as avg_max, 
			round(avg(avg_temp)::numeric,3) as avg_avg_temp, 
			round(avg(stddev_temp)::numeric,3) as avg_stddev
	from (select country, 
	min(averagetemp) as min_temp, 
		round(max(averagetemp)::numeric, 3) as max_temp, 
		round(avg(averagetemp)::numeric, 3) as avg_temp, 
		round(STDDEV(averagetemp)::numeric,3) as stddev_temp
		from global_t
		group by country 
	order by country);


	🔵3.A.i) checks the magnitud of uncertainties related to each measures

	select count(*) 
	from global_t 
	where averagetempuncertainty > abs(averagetemp);




/*------------------------------------------------------------------------------------------------------------
🔴3.A) FIND THE HOTTEST AND COLDEST YEARS GLOBALLY. IF NEEDED, USE LIMIT 5 TO RETRIEVE ONLY THE TOP 5 RESULTS
-------------------------------------------------------------------------------------------------------------*/

	🔵3.A.1) retrieves hottest years globally
	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp) desc
	limit 5;


	🔵3.A.2) retrieves coldest years globally

	select extract(year from dt) as year, 
			avg(averagetemp) as avg_temp 
	from global_t 
	where averagetemp is not null 
	group by year 
	order by avg(averagetemp)
	limit 5;



/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴3.B) CALCULATE AND RANK THE AVERAGE TEMPERATURE CHANGE FOR EACH COUNTRY OVER TIME. HIGHLIGHT THE TOP 15 FASTEST-WARMING COUNTRIES AND RETRIEVE THE FULL DATASET IF NEEDED
---------------------------------------------------------------------------------------------------------------------------------------------*/

	🔵3.B.1) Version A: Regression for all years

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


	🔵3.B.2)Version B: Regression post-1900 (used in main analysis)

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



