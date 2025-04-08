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
FROM total
JOIN after_1975 as t1975 ON total.country = t1975.country
JOIN after_1850 as t1850 ON total.country = t1850.country
JOIN after_Z_1850 as tZ1850 ON total.country = tZ1850.country
ORDER BY total.country asc;
