

/*--------------------------------------------------------- 
Subquery examples 
2019-08-24
Nayef 

From "SQL Server TSQL Fundamentals" by Itzik Ben-Gan 

-- Question 1: Return ungrouped cols for the visit with max age
-- Question 2: return rows in ED data with patients who exist in ADTC data 
-- Question 3: Calculate a running/cumulative total  
-- Question 4: Find discharge disposition of each patient's latest ED visit 
-- Question 5: Express the row amount as a percentage of total column amount 

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
-- Question 1: Return info on the visit with max age
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

-- unrelated side note: to update a variable that already exists, use a SET statement 
-- set @max_age = 999; 
-- select @max_age; -- result 

declare @max_age_pt_id as int = (select patientID 
								 from #t1_ed_visits 
								 where age = @max_age)
-- select @max_age_pt_id -- result 

select patientid, age 
from #t1_ed_visits
where PatientID = @max_age_pt_id; 

-- unrelated: let's use those variables to query another table: 
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
-- Question 3: Calculate a running total  
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

	-- Inner query: 
	-- This is a correlated, scalar subquery in the SELECT statement of outer query: 
	, (select sum(amount)  -- note that group by not necessary to get the sum 
	from #t5_for_running_total t5_2  -- referring to same table as in the outer query 
	where t5_2.id <= t5.id  -- this is where outer and inner queries are linked together 
	) as cumulative_total_using_subquery  -- result of subquery is a single number (scalar subquery), which is why it can be in the SELECT statement 

from #t5_for_running_total t5



-- solution 2: using window functions: 
select t5.id
	, t5.amount
	, sum(t5.amount) over(order by id
						  rows between unbounded preceding and current row) as cumulative_total_using_window
from #t5_for_running_total t5




---------------------------------------------------------------------
-- Question 4: Find discharge disposition of all patient's latest ED visit 
---------------------------------------------------------------------

-- set up #t6 
drop table if exists #t6_ed_data; 
select * 
into #t6_ed_data
from EDMart.dbo.vwEDVisitIdentifiedRegional
where 1=1 
	and StartDate between '2018-01-01' and '2019-01-01' 
	and FacilityShortName = 'RHS' 



-- solution 1: using group by: 
drop table if exists #t7_find_latest_ed_startdate; 
select patientid
	--, DischargeDispositionCode
	, count(startdate) as num_visits 
	, max(StartDate) as latest_visit
into #t7_find_latest_ed_startdate
from #t6_ed_data
group by patientid
	--, DischargeDispositionCode
order by patientId

-- select * from #t7_find_latest_ed_startdate order by patientid  -- result

/*
note that I can't pull the DischargeDispositionCode in this query where I find the 
max start date. That would cause the grouping to be more granular than patient-level, 
going to patient-DischargeDispositionCode level, which I don't want. 

Instead, I have to join this result back against #t6: 
*/

select t7.*
	, t6.DischargeDispositionDescription
from #t7_find_latest_ed_startdate t7
left join #t6_ed_data t6 
	on t7.PatientID = t6.PatientID
	and t7.latest_visit = t6.StartDate
order by patientId



-- Solution 2: using scalar, correlated subquery in the WHERE clause of the outer query: 
select t6_1.patientid
	, t6_1.StartDate
	, t6_1.DischargeDispositionDescription

from #t6_ed_data t6_1
where StartDate = (Select max(StartDate)
				   from #t6_ed_data t6_2
				   where t6_1.PatientID = t6_2.PatientID)
order by PatientID

-- Note that PatientID = 18 shows up twice because they have 2 discharges on the same day 




---------------------------------------------------------------------
-- Question 5: Express the row amount as a percentage of total column amount 
---------------------------------------------------------------------

-- set up an example table 
drop table if exists #t8_ed_visits_by_year
select StartDateFiscalYear
	, count(*) as annual_ed_visits
into #t8_ed_visits_by_year
from EDMart.dbo.vwEDVisitIdentifiedRegional
where FacilityShortName = 'RHS' 
group by StartDateFiscalYear
order by StartDateFiscalYear



-- Solution 1: using self-contained subquery in the SELECT clause of outer query: 
select t8_1.StartDateFiscalYear
	, t8_1.annual_ed_visits
	, cast(100. * t8_1.annual_ed_visits/(select sum(t8_2.annual_ed_visits)
									     from #t8_ed_visits_by_year t8_2) 
	as numeric(5, 2)) as percentage_of_total  -- numeric(5, 2) -> 5 is the "precision"; 2 is the "scale" 
from #t8_ed_visits_by_year t8_1
order by StartDateFiscalYear



-- Solution 2: using window function: 
select StartDateFiscalYear
	, annual_ed_visits

	-- over( ) with no arguments just means that the "window" is over the whole column 
	, cast(100. * annual_ed_visits/sum(annual_ed_visits) over() as numeric(5, 2))as percent_of_total
from #t8_ed_visits_by_year
order by StartDateFiscalYear





