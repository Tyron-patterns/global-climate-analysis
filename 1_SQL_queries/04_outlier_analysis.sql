				
							/*===========================================================
							⚠️ OUTLIER DETECTION & VARIABILITY COMPARISON
	
							This script includes:
							- Z-score outlier detection at the global and country levels
							- Outlier counts for specific countries
							- Country ranking by number of temperature outliers
							- Comparison of standard deviation with and without outliers
							===========================================================*/
									

/*---------------------------------------------------
🔴4) IDENTIFICATION OF OUTLIERS
--------------------------------------------------*/

	🔵4.A.1)--Z-score Global level

		🟡3.A.1.i) --The first query calculates the Z-score of each temperature value against global average and stddev, filtering those with |Z| > 3.
			--The second query counts outliers per country by grouping values that fall outside the standard Z-score range.
			--These steps help identify extreme deviations globally and understand which countries contribute most to those anomalies.
		select country, 
			averagetemp, 
			       	(averagetemp - global_avg) / global_stddev as z_score
		from (select country, 
				averagetemp,
			        (select avg(averagetemp) from global_t) as global_avg,
			        (select stddev(averagetemp) from global_t) as global_stddev
			from global_t)
		where abs((averagetemp - global_avg) / global_stddev) > 3
		order by z_score desc;



		🟡4.A.1.ii) --counting the number of outliers

		select country, 
		count(averagetemp)
		from (select country, 
		averagetemp,
		           (select avg(averagetemp) from global_t) as global_avg,
		           (select stddev(averagetemp) from global_t) as global_stddev
		    	from global_t)
		where (averagetemp - global_avg) / global_stddev not between -3 and 3
		group by country 
		order by country;

	-- P.S. CTE would have been slightly more efficient

	🔵4.B.2)Z-score Country Level

		🟡4.B.2.i) -- This block uses window functions to calculate Z-scores relative to each country’s mean and stddev for every temperature record.
			--It checks for outliers (|Z| > 3), counts how many there are for Cambodia, and compares this to its total records.
			--This ensures country-level consistency and supports case-by-case outlier diagnostics with contextual baselines.
	
		select country, 
			averagetemp,
			(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
       			STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
		from global_1850;



		🟡4.B.2.ii)--This query uses a CTE to compute Z-scores and outlier counts for each country, then selects those with the most and fewest outliers.
			--The logic combines partitioned Z-scores with filtering and aggregation for comparison.
			--It pinpoints the most anomalous and most stable countries in terms of temperature distribution.
		select country,
		count(*) as temp_outliers 	
		from (SELECT country, 
		averagetemp, 
		(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
		       		STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
		FROM global_t
		       	WHERE averagetemp IS NOT NULL)
		where z_score not between -3 and 3
		group by country  
		having country = 'Cambodia' 


		🟡4.B.3.iii) --counting the number of total records for Cambodia for consistency check

		select country, 
		count(*), 
		z_score as total_temps 
		from (SELECT country, 
			averagetemp, 
			(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
		       		STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
			FROM global_t
		       	WHERE averagetemp IS NOT NULL)
		group by country 
		having country = 'Cambodia' 


		🟡4.B.3.iv) --checks if outliers are present through WITH function

		WITH temp_outlier_counts AS (
    		select country, 
           		count(*) as temp_outliers
    		from (select country, 
               			averagetemp, 
               			(averagetemp - avg(averagetemp) OVER (PARTITION BY country)) / 
               			stddev(averagetemp) OVER (PARTITION BY country) as z_score 
        	     from global_1850
        	     where averagetemp is not null) as temp_data
    		where z_score not between -3 and 3 -- filtering outliers
    		group by country)
		SELECT * FROM temp_outlier_counts;
			
		where temp_outliers = (select max(temp_outliers) from temp_outlier_counts) 
   		or temp_outliers = (select min(temp_outliers) from temp_outlier_counts);
		--add to retrieve countries per max and min count of outliers


	🔵4.C.3) --These queries use a JOIN approach instead of window functions to calculate per-country Z-scores and count outliers.
		--They also compute the average number of outliers across countries and repeat the process using a CTE for readability.
		--This alternate approach confirms earlier results and offers flexibility in querying or exporting results.

		🟡4.C.3.i) --counting the number of outliers

		select per_country.country, -- counting the number of outliers
			country_avg, 
			country_stddev, 
			count(averagetemp) as temp_outliers
		from (select country, 
				avg(averagetemp) as country_avg, 
				stddev(averagetemp) as country_stddev
			from global_1850
			where averagetemp is not null
			group by country) as per_country
		join global_1850
		on per_country.country = global_1850.country
		where (averagetemp - country_avg) / country_stddev not between -3 and 3
		group by per_country.country, country_avg, country_stddev



		🟡4.C.3.ii) --average of total records for countries presenting outliers

		select round(avg(temp_outliers)::numeric, 3) 
		from (select per_country.country, 
				country_avg, 
				country_stddev, 
				count(averagetemp) as temp_outliers
			from (select country, 
				avg(averagetemp) as country_avg, 
				stddev(averagetemp) as country_stddev
				from global_t 
				where averagetemp is not null
				group by country) as per_country
		join global_1850
		on per_country.country = global_1850.country
		where (averagetemp - country_avg) / country_stddev not between -3 and 3
		group by per_country.country, country_avg, country_stddev)



		🟡4.C.3.iii) --using WITH to retrieve the average of total records for countries presenting outliers

		WITH temp_outlier_counts AS (
 		SELECT per_country.country,               
   			country_avg, 
    			country_stddev, 
    			COUNT(global_1850.averagetemp) AS temp_outliers
  		FROM ( SELECT country, 
      				AVG(averagetemp) AS country_avg, 
      				STDDEV(averagetemp) AS country_stddev
    			FROM global_1850
    			WHERE averagetemp IS NOT NULL
   			GROUP BY country) AS per_country
    		JOIN global_1850
    		ON per_country.country = global_1850.country
    		WHERE (averagetemp - country_avg) / country_stddev NOT BETWEEN -3 AND 3
   		GROUP BY per_country.country, country_avg, country_stddev )
		SELECT * 
		FROM temp_outlier_counts;
		
		WHERE temp_outliers = (SELECT MAX(temp_outliers) FROM temp_outlier_counts)
   		OR temp_outliers = (SELECT MIN(temp_outliers) FROM temp_outlier_counts);
		--add to retrieve countries per max and min count of outliers




/*-----------------------------------------------------------------------------------------
🔴4.G) COMPARING STANDARD DEVIATION FOR GLOBAL DATASET WITH OUTLIERS AND WITHOUT OUTLIERS
------------------------------------------------------------------------------------------*/
--This query compares standard deviation per year with and without extreme outliers filtered (using -12.98 as a cutoff).
--It performs a FULL OUTER JOIN between filtered and unfiltered results, adding a comparison indicator (>, <, =).
--It highlights how much yearly variability is driven by extreme values, reinforcing the value of outlier treatment.
	
select a.year, 
		a.filtered_std,
		case 
			when a.filtered_std > b.unfiltered_std then ' > '
			when a.filtered_std < b.unfiltered_std then ' < '
			else ' = '
		end as comparison,
		b.unfiltered_std
from (select extract(year from dt) as year,
			round(stddev(averagetemp)::numeric,3)	as filtered_std 
			from global_t
			where averagetemp > -12.98
			group by year) as a
full outer join (select extract(year from dt) as year,
			round(stddev(averagetemp)::numeric,3) as unfiltered_std
			from global_t
			group by year) as b
on a.year=b.year
group by a.year, a.filtered_std, b.unfiltered_std
order by a.year 
