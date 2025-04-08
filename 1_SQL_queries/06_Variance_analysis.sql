select a.year, 
		a.filtered_std,
		case 
			when a.filtered_std > b.unfiltered_std then ' > '
			when a.filtered_std < b.unfiltered_std then ' < '
			else ' = '
		end as comparison,
		b.unfiltered_std
from (select extract(year from dt) as year,
			round(stddev(averagetemp)::numeric,3)as filtered_std 
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
