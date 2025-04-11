
							/*===========================================================
							🧹 DATA CLEANING & QUALITY CHECKS

							This script includes:
							- Missing value/records analysis (overall, per country/year, % above threshold)
							- Comparison of missing data before and after 1850
							- Identification of duplicate temperature records
							===========================================================*/

-- NOTE: A proper explanation of the approach and the results of this analysis is presented in the main paper

/*----------------------------------
🔴2.A) CHECK FOR MISSING VALUES (NULLs).
----------------------------------*/

	🔵2.A.1) --checks for presence of missing values: compares how many null values and non-null values are present in key columns;
		-- uses COUNT(column) to assess overall completeness.

	select count(*) as total, 
		count(dt) as dt_notnull,
		count(averagetemp) as avg_notnull,
		count(averagetempuncertainty) as averagetemp_uncert_notnull,
		count(country) as country_notnull
	from global_t;

	🔵2.A.2) --Identifies where missing temperature data occurs 
		--by grouping rows by country and year, filtering for NULL temperature fields.
		
	select country,    
		extract(year from dt) as year, 
		count(*) as missing_values 
	from global_t
	where averagetemp is null or averagetempuncertainty is null 
	group by country, year
	order by country, year

	**Results:**
	-- Lists amount of missing values per country/year
	-- Most countries have sparse missing data; at a first glance it seems like gaps are more common pre-1850
	-- with some countries that don't even have records in early years
		
	-- Let's invesigate this further!


	🔵2.A.3) --This query calculates the percentage of missing values per country and identifies those exceeding a 5% threshold.
		--It joins a subquery counting nulls with a subquery counting total records per country, then filters with a HAVING clause.
		--This flags countries with potentially unreliable data that may affect the validity of further analysis.

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
    	HAVING ROUND(nulls.null_count::NUMERIC / COUNT(*)::NUMERIC * 100, 2) > 5) AS filtered_countries;

	**Results**
	-- 92 countries out of 243 total. 5% is not a negligible amount and 92 countries is a little under half of the total. 
	-- The next query investigates the concentration of missing data in early years: the data collection starts in 1943
	-- and measuring methods where more unrelaible at that time
		

	🔵2.A.4) -- Calculates the number of NULL temperature values before 1850 vs. total per country using two subqueries 
		-- (null_temps_column_1850 and null_temp_total_column), then joins them on country to compare the results.  
		-- Computes the percentage of missing values for both timeframes and their difference using ROUND(...::numeric/count(...)...), 
		-- and finally groups everything by country to summarize the proportion of early missing data.

	select global_t.country, 
		count(*) as notnull_count, 
		null_count_before_1850, 
		null_count_total,
		round(null_count_before_1850::numeric/count(*)::numeric,5)*100 as percentage_before_1850,
		round(null_count_total::numeric/count(*)::numeric, 5)*100 as total_percentage,
		(round(null_count_total::numeric/count(*)::NUMERIC, 5)*100 - 
		round(null_count_before_1950::numeric/count(*)::numeric,5)*100) as difference_percentages
	from global_t
	join (select global_t.country, 
			count(*) as null_count_before_1850 
			from global_t 
			where averagetemp is null and extract(year from dt) < 1850
			group by global_t.country) as null_temps_column_1850
	on global_t.country = null_temps_column_1850.country
	left join (select global_t.country, 
				count(*) as null_count_total
				from global_t
				where averagetemp is null
				group by global_t.country) as null_temp_total_column
	on global_t.country = null_temp_total_column.country
	group by global_t.country, null_count_before_1850, null_count_total
	order by country;

	**Results**:
	-- the difference in percentage between before_1950 and total null values is extremely small, 
	-- indicating that most missing data are concentrated before 1950 
	-- confirming the hypothesis that data collection became more consistent/reliable after the mid-20th century
		

	🔵2.A.5)--some hard coding to calculate the share of valid (non-null) temperature records for fixed 25-year intervals across the full dataset.
		--It uses multiple subqueries with EXTRACT(YEAR FROM dt) to filter by period, then divides by the total valid count.
		--This gives a clear timeline of data availability, showing which historical periods are well-covered vs. underrepresented.
	select (select count(*) as total from global_t
	where averagetemp is not null) as total,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1743 and 1775
	and averagetemp is not null) as data_1743_1775,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1776 and 1800
	and averagetemp is not null) as data_1776_1800,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1801 and 1825
	and averagetemp is not null) as data_1801_1825,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1826 and 1850
	and averagetemp is not null) as data_1826_1850,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1851 and 1875
	and averagetemp is not null) as data_1851_1875,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1876 and 1900
	and averagetemp is not null) as data_1876_1900,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1901 and 1925
	and averagetemp is not null) as data_1901_1925,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1926 and 1950
	and averagetemp is not null) as data_1926_1950,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1951 and 1975
	and averagetemp is not null) as data_1951_1975,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 1976 and 2000
	and averagetemp is not null) as data_1976_2000,
	(select round((count(*)::numeric/t.total)*100,3) from global_t
	where extract(year from dt) between 2001and 2013
	and averagetemp is not null) as data_2001_2013,
	from (select count(*) as total from global_t
			where averagetemp is not null ) as t

	--P.S. Although a Common Table Expression (CTE) would improve efficiency, 
	--the hardcoded logic was used intentionally for clarity and to explicitly demonstrate the structure of each time interval.

		
 	🔵2.A.6)--This query counts valid records for each country across predefined 25-year intervals.
		--It uses conditional aggregation with COUNT(CASE WHEN...) and groups by country to track data consistency over time.
		--This helps assess whether specific countries have sufficient historical coverage for longitudinal analysis.
		
	SELECT 
	  country,
	  COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1743 AND 1775 THEN 1 END) AS count_1743_1775,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1776 AND 1800 THEN 1 END) AS count_1776_1800,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1801 AND 1825 THEN 1 END) AS count_1801_1825,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1826 AND 1850 THEN 1 END) AS count_1826_1850,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1851 AND 1875 THEN 1 END) AS count_1851_1875,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1876 AND 1900 THEN 1 END) AS count_1876_1900,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1901 AND 1925 THEN 1 END) AS count_1901_1925,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1926 AND 1950 THEN 1 END) AS count_1926_1950,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1951 AND 1975 THEN 1 END) AS count_1951_1975,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 1976 AND 2000 THEN 1 END) AS count_1976_2000,
	COUNT(CASE WHEN EXTRACT(YEAR FROM dt) BETWEEN 2001 AND 2013 THEN 1 END) AS count_2001_2013,
	FROM global_t
	WHERE averagetemp IS NOT NULL
	GROUP BY country
	ORDER BY country;


	
	select (select count(averagetemp) from global_t where extract(year from dt) > 1850) as after_1850,
	(select count(averagetemp)from global_t where extract(year from dt) < 1850) as before_1850
		

/*----------------------------------------------
🔴2.B) IDENTIFY POTENTIAL DUPLICATE RECORDS.🔷
----------------------------------------------*/

	--This query detects duplicate temperature readings for the same country and date with identical values.
	--It groups by country, dt, averagetemp and filters identical combinations of these 3 values with HAVING COUNT(*) > 1.
	--This ensures data integrity by flagging and potentially removing redundancies that could skew results.

	select country, 
			dt, 
			averagetemp, 	
			count(*) 
	from global_t
	where averagetemp is not null 
	group by country, dt,averagetemp
	having count(*) > 1
	order by country, dt;

**Results**
-- no repetead values were found
