

/*--------------------------------------------------------- 
Subquery examples 
2019-08-24
Nayef 

From "SQL Server TSQL Fundamentals" by Itzik Ben-Gan 

*/---------------------------------------------------------

drop table if exists #t1_ed_visits;  
drop table if exists #t2_adtc;  

-- let's create a table to play with 
select * 
into #t1_ed_visits 
from EDMart.[dbo].[vwEDVisitIdentifiedRegional]
where FacilityShortName = 'LGH' 
	and StartDate = '2018-01-01' 

-- select t1.patientid, t1.* from #t1_ed_visits t1 order by t1.patientid

select * 
into #t2_adtc
from ADTCMart.ADTC.AdmissionDischargeView
where AdmissionFacilityLongName = 'LIONS GATE HOSPITAL' 
	and AdjustedAdmissionDate between '2018-01-01' and '2018-01-07' 

select t2.patientid, t2.* from #t2_adtc t2 order by t2.patientid 

---------------------------------------------------------------------
-- Q1 Return info on the visit with max age
---------------------------------------------------------------------

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











---------------------------------------------------------------------
-- Question 2: return rows in ED data with patients who exist in ADTC data 
---------------------------------------------------------------------

drop table if exists #t3; 


-- Solution 1: using inner join 
select t1.patientid, t1.age --t2.adjustedadmissiondate
into #t3
from #t1_ed_visits t1
	inner join #t2_adtc t2
		on t1.patientid =  t2.patientid
order by t1.age desc 

-- select * from #t3 order by age desc  


/*
Note that 52 year old with ptID = 16590860 shows up twice. 

Why? Because they have 2 admissions in #t2_adtc, one on Jan 1st, one 
on Jan 5th. 

Do we want these to show up as 2 separate rows? It depends. 
> Do you want 1 row per admission? Then Yes. 
> Do you want 1 row per patient? Then No. 

Note that we can remove the duplicate by using "SELECT distinct", 
but you'd have to first recognize that there might be duplicates. 

*/


--Solution 2: using sub-query 
drop table if exists #t4;

select t1.patientid, t1.age
into #t4
from #t1_ed_visits t1
where t1.patientID in (select patientID   -- you can also use WHERE column NOT IN subquery_result
					   from #t2_adtc) 
order by age desc  

-- select * from #t4 order by age desc; 

/*
Note that here we don't get duplicate patientIDs caused by 2 admissions in #t2_adtc

Another advantage of the subquery approach: it's very easy to negate: just use 
"WHERE column **NOT IN** subquery_result"

*/
---------------------------------------------------------------------
-- Question 3: Find patients in ED data who aren't in ADTC data (INTERSECT and EXCEPT) 
---------------------------------------------------------------------




---------------------------------------------------------------------
-- Question 4: Calculate a running total  
---------------------------------------------------------------------

-- create a table: 
drop table if exists #t5_for_running_total; 
create table #t5_for_running_total (id int, amount int); 

insert into #t5_for_running_total values 
	(1, 15), 
	(2, 300), 
	(3, 22.4), 
	(4, 32), 
	(5, 1200);
	
select * from #t5_for_running_total;  


-- solution 1: using a correlated subquery 
/*
Note that this is a correlated sub-query - i.e. one that won't run on its 
own, because it's dependent on the outer query.

The benefit of correlated sub-queries is that they allow you do take each 
row of the outer query, and check it against the results of another query 
*/

select t5.id
	, t5.amount 

	-- correlated scalar subquery in the SELECT statement of outer query: 
	, (select sum(amount)  -- note that group by not necessary to get the sum 
	from #t5_for_running_total t5_2
	where t5_2.id <= t5.id  -- this is where outer and inner queries are linked together 
	) as cumulative_total  -- result of subquery is a single number (scalar subquery), which is why it can be in the SELECT statement 

from #t5_for_running_total t5







