
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

	🔵3.A.1) --This query calculates global summary statistics: min, max, average, and standard deviation for both average temperature and its uncertainty.
		--It uses aggregate functions (MIN, MAX, AVG, STDDEV) across the full dataset to provide a baseline of global values.
		--These metrics serve as a reference point to identify the distribution and outliers or comparing trends across countries or timeframes.

	select min(averagetemp) as min, 
			round(max(averagetemp)::numeric, 3) as max,--checks for important values 
			round(avg(averagetemp)::numeric, 3) as avg, 
			round(STDDEV(averagetemp)::numeric,3) as stddev,
			min(averagetempuncertainty) as min, 
			max(averagetempuncertainty) as max, 
			round(avg(averagetempuncertainty)::numeric,3) as avg, round(STDDEV(averagetempuncertainty)::numeric,3) as stddev
	from global_t;

	
	🔵3.A.2) --This query computes the average of each country’s min, max, mean, and standard deviation in a nested subquery.
		--The inner query calculates individual stats per country, which are then averaged in the outer query to give a meta-summary.
		--This provides insight into the typical variability and range of temperatures across countries, independent of global extremes.

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


	🔵3.A.i) --This query counts how many records have temperature uncertainty greater than the absolute value of the measured temperature.

	select count(*) 
	from global_t 
	where averagetempuncertainty > abs(averagetemp);




