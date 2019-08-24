

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

-- Solution 1: using top 1 
-- You can't just use max(age) and group by patientID. That would give e.g. 
-- Amy's max age during the day, Bob's max age during the day, etc. (FAIL) 

select top 1 t1.patientid, t1.age
from #t1_ed_visits t1
order by t1.age desc 

-- Now what if I want to report this patientid and age somewhere else? 
-- No easy way to do it 


-- Solution 2: using variables 
declare @max_age as int = (select max(age) 
						   from #t1_ed_visits) 
-- select @max_age  -- result 

declare @max_age_pt_id as int = (select patientID 
								 from #t1_ed_visits 
								 where age = @max_age)
-- select @max_age_pt_id -- result 

select patientid, age 
from #t1_ed_visits
where PatientID = @max_age_pt_id; 

-- let's use those variables to query another table: 
--select patientID, [AdmissionAge], adjustedadmissiondate 
--from ADTCMart.[ADTC].[AdmissionDischargeView]
--where patientId = @max_age_pt_id
--order by AdmissionAge


-- Solution 3: using a scalar, self-contained subquery
-- benefit: 1 step instead of 2 steps 
select patientId, age 
from #t1_ed_visits
where age = (select max(age) 
			 from #t1_ed_visits) 



