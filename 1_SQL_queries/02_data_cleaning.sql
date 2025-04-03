
							/*===========================================================
							🧹 DATA CLEANING & QUALITY CHECKS

							This script includes:
							- Missing value analysis (overall, per country/year, % above threshold)
							- Comparison of missing data before and after 1950
							- Identification of duplicate temperature records
							===========================================================*/

-- NOTE: A proper explanation of the approach and the results of this analysis is presented in the main paper

/*----------------------------------
🔴1.C) CHECK FOR MISSING VALUES (NULLs).
----------------------------------*/

	🔵1.C.1) --checks for presence of missing data 

	select count(*) as total, 
		count(dt) as dt_notnull,
		count(averagetemp) as avg_notnull,
		count(averagetempuncertainty) as averagetemp_uncert_notnull,
		count(country) as country_notnull
	from global_t;

	🔵1.C.2) --lists the amount of missing data per country
		
	select country,    
		extract(year from dt) as year, 
		count(*) as missing_values 
	from global_t
	where averagetemp is null or averagetempuncertainty is null 
	group by country, year
	order by country, year

	**Results:**
	-- Lists amount of missing values per country/year
	-- Most countries have sparse missing data; at a first glance it seems like gaps are more common pre-1950
	-- with some countries that don't even have records in early years
		
	-- Let's invesigate this further!


	🔵1.C.3) checks for number of country with more than 6% of missing 

	SELECT COUNT(*) AS countries_with_high_missing
	FROM (SELECT total.country,
        	COUNT(*) AS total_count,
        	nulls.null_count,
        	ROUND(nulls.null_count::NUMERIC / COUNT(*)::NUMERIC * 100, 2) AS missing_percentage
    		FROM global_t AS total
   	LEFT JOIN (SELECT country, 
            		COUNT(*) AS null_count
        	FROM global_t
        	WHERE averagetemp IS NULL
        	GROUP BY country) AS nulls ON total.country = nulls.country
    	GROUP BY total.country, nulls.null_count
    	HAVING ROUND(nulls.null_count::NUMERIC / COUNT(*)::NUMERIC * 100, 2) > 6) AS filtered_countries;

	**Results**
	-- 92 countries out of 243 total. 6% is not a negligible amount and 92 countries is a little under half of the total. 
	-- The next query investigates the concentration of missing data in early years: the data collection starts in 1943
	-- and measuring methods where more unrelaible at that time


	🔵1.C.4) checks for difference in percentage before and after 1950

	select global_t.country, 
		count(*) as notnull_count, 
		null_count_before_1950, 
		null_count_total,
		round(null_count_before_1950::numeric/count(*)::numeric,5)*100 as percentage_before_1950,
		round(null_count_total::numeric/count(*)::numeric, 5)*100 as total_percentage,
		(round(null_count_total::numeric/count(*)::NUMERIC, 5)*100 - 
		round(null_count_before_1950::numeric/count(*)::numeric,5)*100) as difference_percentages
	from global_t
	join (select global_t.country, 
			count(*) as null_count_before_1950 
			from global_t 
			where averagetemp is null and extract(year from dt) < 1950
			group by global_t.country) as null_temps_column_1950
	on global_t.country = null_temps_column_1950.country
	left join (select global_t.country, 
				count(*) as null_count_total
				from global_t
				where averagetemp is null
				group by global_t.country) as null_temp_total_column
	on global_t.country = null_temp_total_column.country
	group by global_t.country, null_count_before_1950, null_count_total
	order by country;

	**Results**:
	-- the difference in percentage between before_1950 and total null values is extremely small, 
	-- indicating that most missing data are concentrated before 1950 
	-- confirming the hypothesis that data collection became more consistent/reliable after the mid-20th century

select (select count(averagetemp) from global_t where extract(year from dt) > 1850) as after_1850,
(select count(averagetemp)from global_t where extract(year from dt) < 1850) as before_1950

/*----------------------------------------------
🔴1.D) IDENTIFY POTENTIAL DUPLICATE RECORDS.🔷
----------------------------------------------*/

--checks for repeated values (identical temperatures for the same country on the same date)

select country, 
		dt, 
		averagetemp, 
		averagetempuncertainty, 	
		count(*) 
from global_t
where averagetemp is not null 
group by country, dt,averagetemp, averagetempuncertainty 
having count(*) > 1
order by country, dt;

**Results**
-- no repetead values were found
