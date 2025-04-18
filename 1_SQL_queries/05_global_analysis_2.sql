/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴5.E) ANALYZE THE GLOBAL TEMPERATURE TREND OVER TIME. IF THE DATASET INCLUDED CONTINENTS, THE SAME METHOD COULD BE USED FOR CONTINENT-BASED TRENDS
---------------------------------------------------------------------------------------------------------------------------------------------*/

--These queries use REGR_SLOPE to measure temperature increase per year, both globally and by continent.
--They compare trends across four key periods (from 1743, 1850, 1900, and 1950 onward) and use CTEs for clarity and comparison.
--The final query performs the same trend analysis grouped by continent, helping explore regional climate dynamics.

	🔵5.E.1) --retrieves the regression slope per country per year 

	select round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
	from global_IQR 
	group by year);

	🔵5.E.2) --Calculates global temperature regression slopes from 1743, 1850, 1900, and 1950 to 2013 to compare long-term warming trend
	with year_1743 as (
	select round(regr_slope(avg_temp, year)::numeric, 5) as slope_per_year
	from (
	    select extract(year from dt) as year, 
	           avg(averagetemp) as avg_temp
	    from global_IQR
	    where extract(year from dt)  >= 1743
		and averagetemp is not null
	    group by year)
	), year_1850 as (
	select round(regr_slope(avg_temp, year)::numeric, 5) as slope_per_year
	from (
	    select extract(year from dt) as year, 
	           avg(averagetemp) as avg_temp
	    from global_IQR
	    where extract(year from dt) >= 1850 
		and averagetemp is not null
	    group by year)
	), year_1900 as (
	select round(regr_slope(avg_temp, year)::numeric, 5) as slope_per_year
	from (
	    select extract(year from dt) as year, 
	           avg(averagetemp) as avg_temp
	    from global_IQR
	    where extract(year from dt) >= 1900 
		and averagetemp is not null
	    group by year)
	), year_1950 as (
	select round(regr_slope(avg_temp, year)::numeric, 5) as slope_per_year
	from (
	    select extract(year from dt) as year, 
	           avg(averagetemp) as avg_temp
	    from global_IQR
	    where extract(year from dt) >= 1950 
		and averagetemp is not null
	    group by year)
	)
	select *
	from year_1743
	cross join year_1850
	cross join year_1900
	cross join year_1950


	🔵5.E.3) --retrieves the regression slope per continent per year

	select continent, 
			round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select continent, 
				extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
			from global_land_temp 
			group by continent, year) 
	group by continent
	having regr_slope(avg_temp_per_year, year) is not null
	order by continent, temp_increase desc;



/*-------------------------------------------------------------
🔴5.F) WHICH COUNTRIES HAVE THE MOST MISSING TEMPERATURE DATA?
-------------------------------------------------------------*/

--The first query counts null temperature records per country. 
--The second estimates missing records by comparing each country’s record count to Germany’s (the highest).
--These approaches help identify data availability gaps and assess overall dataset quality by region.

	🔵5.F.1) --counting missing values (‘null’)
	select country, count(country) from global_t 
	where averagetemp is null
	group by country 
	order by count(country) desc;

	🔵5.F.2) --counting missing record (including nulls) taking as comparison Germany who showed the highest numbers of records. 
		--Choosing the average of number of records per country would have given the same list 
		--in terms ouf countries but different count for the missing records.
		
	select country, 
		abs(count(*) - 
			(select count(*) as total_records 
			from global_t 
			where country = 'Germany')) as difference
	from global_t			
	where country !=  'Antarctica'
	group by country
	order by difference desc;


/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴5.G) WHAT IS THE AVERAGE TEMPERATURE TREND IN EUROPE (NO CONTINENT COLUMNS WAS PROVIDED IN THE TABLE AND EUROPE WAS LISTED AS A COUNTRY) AND 5 COUNTRIES IN EUROPE OVER THE LAST 50 YEARS?
---------------------------------------------------------------------------------------------------------------------------------------------*/

--These queries analyze warming trends for 'Europe' (listed as a country) and five European nations.
--They apply REGR_SLOPE to temperature averages per year from 1975 onward, helping assess recent regional warming.
--Another query lists all country names for validation or manual grouping by region.

	🔵5.G.1)-- retrieves for regression slope of countries per year

	select country, 
			round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select country, 	
				extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
			from global_t 
			where country = 'Europe' and extract(year from dt) > '1975' 
			group by country, year)
	group by country
	having regr_slope(avg_temp_per_year, year) is not null
	order by temp_increase desc;


	🔵5.G.2)--asses which European countries are in the table

	select distinct(country) 
	from global_t 
	order by country; 

	🔵5.G.3) --retrieves highest temp increase overtime (in 5 countries)

	select country, 
			round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select country, 
				extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
			from global_t 
			where country IN ('Albania', 'Belgium', 'Bulgaria', 'Croatia', 'Denmark') 
			and extract(year from dt) >'1975' 
			group by country, year) as uropean_countries
	group by country
	having regr_slope(avg_temp_per_year, year) is not null
	order by temp_increase desc;
