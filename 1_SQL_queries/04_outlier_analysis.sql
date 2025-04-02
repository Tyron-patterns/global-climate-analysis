				
													/*===========================================================
													📄 04_outlier_analysis.sql
													⚠️ OUTLIER DETECTION & VARIABILITY COMPARISON

													This script includes:
													- Z-score outlier detection at the global and country levels
													- Outlier counts for specific countries
													- Country ranking by number of temperature outliers
													- Comparison of standard deviation with and without outliers
													===========================================================*/
													

/*---------------------------------------------------
🔴3.F) CAN YOU IDENTIFY ANY OUTLIERS IN THE DATASET?
--------------------------------------------------*/

	🔵3.F.1)Z-score Global level

		🟡3.F.1.i) checks if there are countries with temps outside 3xstddev (or |Z|>3)
		select country, 
		averagetemp, 
		       	(averagetemp - global_avg) / global_stddev as z_score
		from (select country, 
		averagetemp,
		           (select avg(averagetemp) from global_land_temp_country) as global_avg,
		           (select stddev(averagetemp) from global_land_temp_country) as global_stddev
		   	from global_land_temp_country)
		where abs((averagetemp - global_avg) / global_stddev) > 3
		order by z_score desc;


		🟡3.F.1.ii) counting the number of outliers

		select country, 
		count(averagetemp)
		from (select country, 
		averagetemp,
		           (select avg(averagetemp) from global_land_temp_country) as global_avg,
		           (select stddev(averagetemp) from global_land_temp_country) as global_stddev
		    	from global_land_temp_country)
		where (averagetemp - global_avg) / global_stddev not between -3 and 3
		group by country 
		order by country;


	🔵3.F.2)Z-score Country Level

		🟡3.F.2.i) -- checks if outliers are present through WINDOW function
		select country, 
		averagetemp, 
		      	(SELECT country, 
		(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
		       	STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
		FROM global_land_temp_country)
		from global_land_temp_country;


		🟡3.F.2.ii) counting the number of outliers for the consistency check for Cambodia
		select country, -- counting the number of outliers for the consistency check for Cambodia
		count(*) as temp_outliers 	
		from (SELECT country, 
		averagetemp, 
		(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
		       		STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
		FROM global_land_temp_country
		       	WHERE averagetemp IS NOT NULL)
		where z_score not between -3 and 3
		group by country  
		having country = 'Cambodia' 


		🟡3.F.3.iii) counting the number of total records for Cambodia

		select country, 
		count(*), 
		z_score as total_temps 
		from (SELECT country, 
		averagetemp, 
		(averagetemp - AVG(averagetemp) OVER (PARTITION BY country)) / 
		       		STDDEV(averagetemp) OVER (PARTITION BY country) AS z_score 
		FROM global_land_temp_country
		       	WHERE averagetemp IS NOT NULL)
		group by country 
		having 'country' = 'Cambodia' 


		🟡3.F.3.iv) checks if outliers are present through WITH function

		WITH temp_outlier_counts AS (
		    select country, 
		           count(*) as temp_outliers
		    from (select country, 
		               averagetemp, 
		               (averagetemp - avg(averagetemp) OVER (PARTITION BY country)) / 
		               stddev(averagetemp) OVER (PARTITION BY country) as z_score 
		        from global_land_temp_country
		        where averagetemp is not null) as temp_data
		    where z_score not between -3 and 3 -- filtering outliers
		    group by country)
		SELECT * FROM temp_outlier_counts
		where temp_outliers = (select max(temp_outliers) from temp_outlier_counts) 
		   or temp_outliers = (select min(temp_outliers) from temp_outlier_counts);


	🔵3.F.3) Z-score Country Level, different approach

		🟡3.F.3.i) counting the number of outliers

		select per_country.country, 
		country_avg, 
		country_stddev, 
		count(averagetemp) as temp_outliers
		from (select country, 
		avg(averagetemp) as country_avg, 
				stddev(averagetemp) as country_stddev
			from global_land_temp_country 
		where averagetemp is not null
			group by country) as per_country
		join global_land_temp_country 
		on per_country.country = global_land_temp_country.country
		where (averagetemp - country_avg) / country_stddev not between -3 and 3
		group by per_country.country, country_avg, country_stddev


		🟡3.F.3.ii) average of total records for countries presenting outliers

		select round(avg(temp_outliers)::numeric, 3) 
		from (select per_country.country, 
					country_avg, 
					country_stddev, 
					ount(averagetemp) as temp_outliers
				from (select country, 
							avg(averagetemp) as country_avg, 
							stddev(averagetemp) as country_stddev
						from global_land_temp_country 
						where averagetemp is not null
						group by country) as per_country
		join global_land_temp_country 
		on per_country.country = global_land_temp_country.country
		where (averagetemp - country_avg) / country_stddev not between -3 and 3
		group by per_country.country, country_avg, country_stddev


		🟡3.F.3.iii) using WITH to retrieve the average of total records for countries presenting outliers

		WITH temp_outlier_counts AS
		(select round(avg(temp_outliers),3),  
				country_avg, 
				country_stddev, 
				count(averagetemp) as temp_outliers
		from (select country, 
					avg(averagetemp) as country_avg, 
					stddev(averagetemp) as country_stddev
				from global_land_temp_country 
				where averagetemp is not null
				group by country) as per_country
		join global_land_temp_country 
		on per_country.country = global_land_temp_country.country
		where (averagetemp - country_avg) / country_stddev not between -3 and 3
		group by per_country.country, country_avg, country_stddev)

		SELECT * FROM temp_outlier_counts
		where temp_outliers = (select max(temp_outliers) from temp_outlier_counts)
		or temp_outliers = (select min(temp_outliers) from temp_outlier_counts)




/*-----------------------------------------------------------------------------------------
🔴3.G) COMPARING STANDARD DEVIATION FOR GLOBAL DATASET WITH OUTLIERS AND WITHOUT OUTLIERS
------------------------------------------------------------------------------------------*/

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
			from global_land_temp_country
			where averagetemp > -12.98
			group by year) as a
full outer join (select extract(year from dt) as year,
			round(stddev(averagetemp)::numeric,3) as unfiltered_std
			from global_land_temp_country
			group by year) as b
on a.year=b.year
group by a.year, a.filtered_std, b.unfiltered_std
order by a.year 
