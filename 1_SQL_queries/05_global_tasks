/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴5.C) ANALYZE THE GLOBAL TEMPERATURE TREND OVER TIME. IF THE DATASET INCLUDED CONTINENTS, THE SAME METHOD COULD BE USED FOR CONTINENT-BASED TRENDS
---------------------------------------------------------------------------------------------------------------------------------------------*/

	🔵5.C.1) retrieves the regression slope per country per year 

	select round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase 
	from (select extract(year from dt) as year, 
				round(avg(averagetemp)::numeric,2) as avg_temp_per_year
	from global_t 
	group by year);


	🔵5.C.2) retrieves the regression slope per continent per year

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
🔴5.D) WHICH COUNTRIES HAVE THE MOST MISSING TEMPERATURE DATA?
-------------------------------------------------------------*/

select country, count(country) from global_t 
where averagetemp is null
group by country 
order by count(country) desc;


/*---------------------------------------------------------------------------------------------------------------------------------------------
🔴5.E) WHAT IS THE AVERAGE TEMPERATURE TREND IN EUROPE (NO CONTINENT COLUMNS WAS PROVIDED IN THE TABLE AND EUROPE WAS LISTED AS A COUNTRY) AND 5 COUNTRIES IN EUROPE OVER THE LAST 50 YEARS?
---------------------------------------------------------------------------------------------------------------------------------------------*/
	
	🔵5.E.1) retrieves for regression slope of countries per year

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


	🔵5.E.2)asses which European countries are in the table

	select distinct(country) 
	from global_t 
	order by country; 

	🔵5.E.3) retrieves highest temp increase overtime (in 5 countries)

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
