
						/*===========================================================									
						    🌡️ GLOBAL TEMPERATURE ANALYSIS — VARIANCE & VOLATILITY
						
						    This script includes:
						    - Comparison of global temperature standard deviation (with and without outliers)
						    - Global variability trend over time (regression slope)
						    - Regional and continental variability (post-1850)
						    - Country-level analysis of temperature variability trends
						===========================================================*/


/*--------------------------------------------
🔴6.A) GLOBAL STDDEV: FILTERED VS UNFILTERED
---------------------------------------------*/

-- This query compares yearly global standard deviation of temperature with and without extreme outliers.
--It performs a FULL OUTER JOIN on filtered and unfiltered datasets, and displays a symbol comparing variability shifts over time.
--This helps understand how outliers impact the volatility of global temperature records.

select a.year, 
       a.filtered_std,
       case 
            when a.filtered_std > b.unfiltered_std then ' > '
            when a.filtered_std < b.unfiltered_std then ' < '
            else ' = '
       end as comparison,
       b.unfiltered_std
from (
    select extract(year from dt) as year,
           round(stddev(averagetemp)::numeric, 3) as filtered_std 
    from global_t
    where averagetemp > -12.98
    group by year
) as a
full outer join (
    select extract(year from dt) as year,
           round(stddev(averagetemp)::numeric, 3) as unfiltered_std
    from global_t
    group by year
) as b
on a.year = b.year
group by a.year, a.filtered_std, b.unfiltered_std
order by a.year;


/*--------------------------------------------
🔴6.B) GLOBAL VARIABILITY TREND (LINEAR SLOPE)
---------------------------------------------*/

--This query tracks the linear trend of global temperature variability over time using standard deviation.
--It groups by year, calculates STDDEV, and applies REGR_SLOPE to measure if variability is increasing.
--The result indicates whether fluctuations in global temperatures are becoming more pronounced.

select round(regr_slope(global_std_overtime, year)::numeric, 5)
from (
    select extract(year from dt) as year, 
           stddev(averagetemp) as global_std_overtime
    from global_t
    group by year
    order by year
);


/*--------------------------------------------------
🔴6.C) CONTINENTAL VARIABILITY (1850–2013)
---------------------------------------------------*/

--These queries analyze temperature variability per continent after 1850 by computing yearly and average standard deviations.
--They group data by year and continent (stored in the 'country' column), helping highlight regions with greater climate instability.
--This also enables comparison across continents on how much temperatures fluctuate yearly.
-- 6.C.1) Yearly stddev per continent (post-1850) 

select country, 
       extract(year from dt) as year, 
       stddev(averagetemp) as std_peryear
from country_Z_1850
where country in ('Africa', 'Asia', 'Australia', 'Europe', 'North America', 'South America')
  and averagetemp is not null
group by country, year
order by country, year asc;

--NOTE: in this database continents were listed in the country column, therefore the filter on country is actually filtering continents

-- 6.C.2) Average stddev per continent (post-1850)

select country, 
       round(avg(std_peryear)::numeric, 3) as tot_variance_Z_1850
from (
    select country, 
           extract(year from dt) as year, 
           stddev(averagetemp) as std_peryear
    from country_Z_1850
    where country in ('Africa', 'Asia', 'Australia', 'Europe', 'North America', 'South America')
      and averagetemp is not null
    group by country, year
) as temp_variability
group by country
order by avg(std_peryear) desc;


/*--------------------------------------------------
🔴6.D) COUNTRY-LEVEL TEMPERATURE VARIABILITY TREND
---------------------------------------------------*/

--This query calculates a regression slope for standard deviation over time per country (excluding continents).
--It groups by year and country, computes yearly STDDEV, and then applies REGR_SLOPE to measure the trend.
--The output identifies which countries are experiencing the most rapid growth in temperature variability.

select country, 
       round(regr_slope(global_std_overtime, year)::numeric, 5) as variability
from (
    select country, 
           extract(year from dt) as year, 
           stddev(averagetemp) as global_std_overtime
    from country_Z_1850
    where averagetemp is not null
    group by country, year
) as country_var
where country not in ('Africa', 'Asia', 'Australia', 'Europe', 'North America', 'South America')
group by country
order by regr_slope(global_std_overtime, year) desc;
