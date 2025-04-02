

										/*===========================================================
										🧹 DATA CLEANING & QUALITY CHECKS

										This script includes:
										- Missing value analysis (overall, per country/year, % above threshold)
										- Comparison of missing data before and after 1950
										- Identification of duplicate temperature records
										===========================================================*/


/*----------------------------------
🔴1.C) CHECK FOR MISSING VALUES.
----------------------------------*/

	🔵1.C.1) --checks for presence of missing data

	select count(*) as total, 
	count(dt) as dt_notnull,
	count(averagetemp) as avg_notnull,
	count(averagetempuncertainty) as averagetemp_uncert_notnull,
	count(country) as country_notnull
	from global_land_temp_country;

	🔵1.C.2) --lists the amount of missing data per country
	select country,    
	extract(year from dt) as year, 
	count(*) as missing_values 
	from global_land_temp_country
	where averagetemp is null or averagetempuncertainty is null 
	group by country, year
	order by country


	🔵1.C.3) checks for percentage of missing data above 6%

	select count(*)  
	from (select global_land_temp_country.country, 
				count(*) as notnull_count, 
				null_count, 
				round(null_count::numeric/count(*)::numeric, 5)*100 as percentage
			from global_land_temp_country)
	join (select global_land_temp_country.country, 
				count(*) as null_count 
			from global_land_temp_country 
			where averagetemp is null 
			group by global_land_temp_country.country) as null_temps_column
	on global_land_temp_country.country = null_temps_column.country
	group by global_land_temp_country.country, null_count 
	having round(null_count::numeric/count(*)::numeric, 5)*100 >6  
	order by global_land_temp_country.country)


	🔵1.C.4) checks for difference in percentage before and after 1950

	select global_land_temp_country.country, 
		count(*) as notnull_count, 
		null_count_1950, 
		null_count_total,
		round(null_count_1950::numeric/count(*)::numeric,5)*100 as percentage_1950,
		round(null_count_total::numeric/count(*)::numeric, 5)*100 as total_percentage,
		(round(null_count_total::numeric/count(*)::NUMERIC, 5)*100 - 
		round(null_count_1950::numeric/count(*)::numeric,5)*100) as difference_percentages
	from global_land_temp_country
	join (select global_land_temp_country.country, 
			count(*) as null_count_1950 
			from global_land_temp_country 
			where averagetemp is null and extract(year from dt) < 1950
			group by global_land_temp_country.country) as null_temps_column_1950
	on global_land_temp_country.country = null_temps_column_1950.country
	left join (select global_land_temp_country.country, 
				count(*) as null_count_total
				from global_land_temp_country
				where averagetemp is null
				group by global_land_temp_country.country) as null_temp_total_column
	on global_land_temp_country.country = null_temp_total_column.country
	group by global_land_temp_country.country, null_count_1950, null_count_total
	order by country;




/*----------------------------------------------
🔴1.D) IDENTIFY POTENTIAL DUPLICATE RECORDS.🔷
----------------------------------------------*/

--checks for repeated values (identical temperatures for the same country on the same date)

select country, 
		dt, 
		averagetemp, 
		averagetempuncertainty, 	
		count(*) 
from global_land_temp_country
where averagetemp is not null 
group by country, dt,averagetemp, averagetempuncertainty 
having count(*) > 1
order by country, dt;
