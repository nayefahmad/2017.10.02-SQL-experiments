
drop table if exists #t1_full_list; 

select PatientID
	, StartDate
into #t1_full_list
from [EDMart].[dbo].[vwEDVisitIdentifiedRegional]
where FacilityShortName = 'LGH' 
	and StartDate between '2018-01-01' and '2018-02-28'; 

Select * from #t1_full_list order by StartDate; 

-------------------------------------------------------------------------
-- Q1. Select all patients who have more than 1 record. 
-------------------------------------------------------------------------
-- using "having" clause 
select PatientID
	, count(*) as num 
from #t1_full_list
group by PatientID
having count(*) > 1
order by num, PatientID; 

-- using CTE 
with grouped as (
	select patientID
		, count(*) as num 
	from #t1_full_list
	group by PatientID
	) 
select * 
from grouped
where num > 1
order by num, PatientID
	


