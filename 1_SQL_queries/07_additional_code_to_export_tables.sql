
							/*------------------------------------------------------------
							📊 POWER BI INTEGRATION NOTE
							
							Most of the queries in this script were also used to generate 
							the tables and columns imported into Power BI to create the 
							corresponding visualizations. Each query served a dual purpose: 
							performing the analysis in SQL and supplying clean, 
							ready-to-visualize datasets for the Power BI dashboard.
							
							Below is an example of a longer query used to generate a specific 
							set of columns for one of the Power BI dashboards.
							------------------------------------------------------------*/

-- Example: Yearly temperature range and average per continent (post-1900)

with after_1975 as(
select country, --highest temp increase overtime (in 5 countries)
		round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase_1975
from (select country, 
			extract(year from dt) as year, 
			round(avg(averagetemp)::numeric,2) as avg_temp_per_year
		from global_t
		where averagetemp is not null
		and extract(year from dt) >1975
		group by country, year)
		group by country),		
total as(
select country, 
		round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase_total
from (select country, 
			extract(year from dt) as year, 
			round(avg(averagetemp)::numeric,2) as avg_temp_per_year
			from global_t
			where averagetemp is not null
			group by country, year)
			group by country),			
after_1850 as (
select country,
		round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase_1850
from (select country, 
			extract(year from dt) as year, 
			round(avg(averagetemp)::numeric,2) as avg_temp_per_year
		from country_Z_1850
		where averagetemp is not null
		group by country, year)
		group by country),		
after_Z_1850 as (
select country,
		round(regr_slope(avg_temp_per_year, year)::numeric,5) as temp_increase_Z_1850
from (select country, 
			extract(year from dt) as year, 
			round(avg(averagetemp)::numeric,2) as avg_temp_per_year
		from global_1850
		where averagetemp is not null
		group by country, year)
		group by country)
select
  total.country,
  total.temp_increase_total,
 t1975.temp_increase_1975,
  t1850.temp_increase_1850,
  tZ1850.temp_increase_Z_1850
from total
join after_1975 as t1975 on total.country = t1975.country
join after_1850 as t1850 on total.country = t1850.country
join after_Z_1850 as tZ1850 on total.country = tZ1850.country
order by total.country asc;
