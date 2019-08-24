

/*--------------------------------------------------------- 
Subquery examples 
2019-08-24
Nayef 

From "SQL Server TSQL Fundamentals"

*/---------------------------------------------------------

drop table if exists #t1_ed_visits;  

-- let's create a table to play with 
select * 
into #t1_ed_visits 
from EDMart.[dbo].[vwEDVisitIdentifiedRegional]
where FacilityShortName = 'LGH' 
	and StartDate = '2018-01-01' 




-- Q1 Return info on the visit with max age

-- Solution 1
select patientID, max(age) as max_age
into #t2_max_age
from #t1_ed_visits
group by patientID












