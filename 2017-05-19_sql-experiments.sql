

DECLARE @variable varchar(30); 
SET @variable = 'World'; 
SELECT @variable as Hello ; 

SELECT @variable; 



------------------------------------------
-- creating and altering tables: 
------------------------------------------

drop table if exists #mrn_table; 

-- create table: 
create table #mrn_table (
	mrn_column varchar(25), 
	site_column varchar(5)
); 

-- insert values into table 
insert into #mrn_table (mrn_column) values
	('0127310'), 
	('0132089'), 
	('0133944'), 
	('0134023'), 
	('0136946'), 
	('0155160'), 
	('0157635'), 
	('0159164'), 
	('0161662'), 
	('0172490'), 
	('0179664'); 

--result: 
select * from #mrn_table; 

-- add a colum with alter + add ----------------------
alter table #mrn_table
add age int


--result: 
select * from #mrn_table; 


-- update specific values useing update + set: ------------------
update #mrn_table
set site_column = 'LGH' 

update #mrn_table
set age = 120 
where mrn_column = '0155160' 


--result: 
select * from #mrn_table; 




-----------------------------------------------------------
-- table variable: alternative to temptable
-----------------------------------------------------------

DECLARE @MyTableVar table(  
    LastStartDate datetime,
	ID int);  

INSERT INTO @MyTableVar
	VALUES('2017-01-01', 99921);

SELECT * FROM @MyTableVar; 


DECLARE @table2 table(  
    LastStartDate datetime,
	ID int);  

INSERT INTO @table2
	VALUES('2017-01-01', 99921)
		,('2017-10-31', 32332) ;
SELECT * From @table2; 

-- Select * from @table2 where ID IN @MyTableVar;  might be better to do an inner join 
select * from @table2 a inner join @MyTableVar b on a.ID=b.ID; 



-------------------------------------------

DECLARE @date AS datetime = '2017-05-01'; 

SELECT ContinuumID, AdjustedDischargeDate 
FROM [ADTCMart].[ADTC].[vwAdmissionDischargeFact]
WHERE AdjustedDischargeDate = @date; 




---------------------------------------------------------------
-- generate a string of dates: 
---------------------------------------------------------------
DROP TABLE if exists #tempdates; 

declare @date as datetime; set @date  = '2015-12-31'; 
create table #tempdates (date_seq datetime);	-- create table with 1 column "date_seq", which is formatted as a date

while @date <= '2016-01-30'
begin
	set @date = DATEADD(dd, 1, @date)
	insert into #tempdates 
	values (@date)
end;  
select * from #tempdates; 



--------------------------------------------
--https://www.simple-talk.com/sql/t-sql-programming/window-functions-in-sql/ 

--Here is a skeleton table we can use for the rest of this article. 
CREATE TABLE #Personnel_Assignments
	(emp_name VARCHAR(10) NOT NULL, 
	 dept_name VARCHAR(15) NOT NULL
	 PRIMARY KEY (emp_name, dept_name), 
	 salary_amt DECIMAL (8,2) NOT NULL
	 CHECK (salary_amt > 0.00)
	 );

--SELECT * FROM #Personnel_Assignments; 

--dummy data: 
INSERT INTO #Personnel_Assignments
	VALUES
	('Aaron', 'acct', 3000.00), 
	('Abaddon', 'acct', 3000.00), 
	('Abbott', 'acct', 3000.00), 
	('Abel', 'acct', 3500.00), 
	('Absalom', 'acct', 5500.00), 
	('Shannen', 'ship', 1000.00), 
	('Shannon', 'ship',2000.00), 
	('Shaquille', 'ship', 3000.00), 
	('Sheamus', 'ship', 4000.00), 
	('Shelah', 'ship', 3000.00), 
	('Shelby', 'ship', 4500.00), 
	('Sheldon', 'ship', 5500.00), 
	('Hamilton', 'HR',2300.00), 
	('Hamish', 'HR', 1000.00), 
	('Hamlet', 'HR', 1200.00), 
	('Hammond', 'HR', 800.00), 
	('Hamuel', 'HR', 700.00), 
	('Hanael', 'HR', 600.00), 
	('Hanan', 'HR', 1000.00);

--SELECT * FROM #Personnel_Assignments; 







--------------------------------------
--CONVERTING date in int format into datetime format
--------------------------------------
/*
Problem: admitdate in [ADRMart].[dbo].[vwAbstractFact] is an int; admittime is separately given as hh:mm format
How to combine these to cast into a datetime object? 
*/

--SELECT Datepart(hh, AdmitTime), Datepart(mi, AdmitTime) FROM [ADRMart].[dbo].[vwAbstractFact];

IF OBJECT_ID('tempdb.dbo.#temp1') IS NOT NULL DROP TABLE #temp1; 

SELECT hr, [min], 
	hr+[min] as timeID, 
	AdmitDate, 
	(convert(varchar(10), AdmitDate)+(hr+[min])) as admitdatetimeID, 
	(substring(Cast(admitDate as varchar), 1,4) + '-' + 
		substring(Cast(admitDate as varchar), 5,2) + '-' + 
		substring(Cast(admitDate as varchar), 7,2) + ' ' + 
		hr + ':' + [min]
		) as date2, 
	CAST(substring(Cast(admitDate as varchar), 1,4) + '-' + 
		substring(Cast(admitDate as varchar), 5,2) + '-' + 
		substring(Cast(admitDate as varchar), 7,2) + ' ' + 
		hr + ':' + [min]
		as datetime) as admitdatetime 
INTO #temp1
FROM (SELECT 
		(CASE 
			WHEN Datepart(hh, AdmitTime) <10 THEN ('0' + cast(Datepart(hh, AdmitTime) as varchar(2)))
			ELSE cast(Datepart(hh, AdmitTime) as varchar(2))
		END) AS hr, 
		(CASE 
			WHEN Datepart(mi, AdmitTime) <10 THEN ('0' + cast(Datepart(mi, AdmitTime) as varchar(2)))
			ELSE cast(Datepart(mi, AdmitTime) as varchar(2))
		END) AS [MIN], 
		AdmitDate
	FROM [ADRMart].[dbo].[vwAbstractFact]
	) AS sub; 

--SELECT * FROM #temp1 WHERE admitdatetime >= '2015-01-01' ORDER BY admitdatetime; 

-------------------------------------------
--check: join with Dim.Date table: 
-------------------------------------------
Select a.ShortDate,b.*
From [ADRMart].[Dim].[Date] a 
	LEFT JOIN #temp1 b 
	ON cast(a.ShortDate as datetime) = b.admitdatetime
ORDER BY a.ShortDate; 


---------------------------------------------------------------


----------------------------------------------------
--2. CONVERT date as int into date as datetime object: 
----------------------------------------------------
--This will be necessary in the next query below (query 3)

Select AdmitDate, AdmitTime,
	DischargeDate, DischargeTime, 
	-- convert AdmitDate and AdmitTime into datetime format: 
	CAST(
			--first find yyyy-mm-dd: 
		substring(Cast(admitDate as varchar), 1,4) + '-' + 
		substring(Cast(admitDate as varchar), 5,2) + '-' + 
		substring(Cast(admitDate as varchar), 7,2) + ' ' + 
			
			--find hr:
		(CASE WHEN Datepart(hh, AdmitTime) <10 
			THEN ('0' + cast(Datepart(hh, AdmitTime) as varchar(2)))
			ELSE cast(Datepart(hh, AdmitTime) as varchar(2))
		END) + ':' + 
			
			--find min 
		(CASE 
			WHEN Datepart(mi, AdmitTime) <10 
			THEN ('0' + cast(Datepart(mi, AdmitTime) as varchar(2)))
			ELSE cast(Datepart(mi, AdmitTime) as varchar(2))
		END) 
	as datetime) as admitdatetime, 
	
	
	-- convert DischDate and DishcargeTime into datetime format: 
	CAST(
			--first find yyyy-mm-dd: 
		substring(Cast(DischargeDate as varchar), 1,4) + '-' + 
		substring(Cast(DischargeDate as varchar), 5,2) + '-' + 
		substring(Cast(DischargeDate as varchar), 7,2) + ' ' + 
			
			--find hr:
		(CASE WHEN Datepart(hh, DischargeTime) <10 
			THEN ('0' + cast(Datepart(hh, DischargeTime) as varchar(2)))
			ELSE cast(Datepart(hh, DischargeTime) as varchar(2))
		END) + ':' + 
			
			--find min 
		(CASE 
			WHEN Datepart(mi, DischargeTime) <10 
			THEN ('0' + cast(Datepart(mi, DischargeTime) as varchar(2)))
			ELSE cast(Datepart(mi, DischargeTime) as varchar(2))
		END) 
	as datetime) as dischargedatetime

From #tempdb 


-------------------------------------------
--Extract month and year from date
-------------------------------------------

SELECT CensusDate, 
	DATEDIFF(MONTH, 0, CensusDate) as [full months]  --how many *full* months from date=0 is CensusDate? 

	, DATEADD(MONTH
		, DATEDIFF(MONTH, 0, CensusDate)		--DATEDIFF (datepart , startdate , enddate ) 
		, 0) AS [year_month_date_field]

	-- DATEADD (datepart=MONTH , number= N, result from datediff field , date=0 [base datetime value??])
	-- This counts N full months from base time period. 
	-- E.g. if 2000-01-01 is base time, then both 2000-06-04 and 2000-06-15 are 6 *full* months from base, so 
		--they're assigned the same value of 2000-06-01

	, datename(month, censusdate) as [month name]

FROM [ADTCMart].[ADTC].[vwCensusFact]
WHERE CensusDate between '2016-01-01' and '2017-06-28' 
	AND FacilityCode = '0112' 
	and nursingunitcode='6e' 
--GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, CensusDate), 0) 
ORDER BY CensusDate; 


------------------------------------
--INCLUDE QUESTION IN QUERY RESULTS, so that it's easy to follow flow of logic
------------------------------------

SELECT ContinuumID
	, 'what are the continuumIDs?' as question
FROM [ADTCMart].[ADTC].[vwAdmissionDischargeFact]; 


------------------------------------
--"INLINE VIEWS": select statement in the from segment: 
------------------------------------
--inline view used to define the name "half_of_starttomd", which can then be referred to in outer query. 

Select avg(half_of_starttomd) as avg_half_of_starttomd
	, min(half_of_starttomd) as min_half_of_starttomd
	, max(half_of_starttomd) as max_half_of_starttomd
from(
	Select ContinuumID
		, Starttomd
		, StartToMD/(2*1.0) as half_of_starttomd 
	from EDMart.[dbo].[vwEDVisitIdentifiedRegional]
	where FacilityLongName='Lions Gate Hospital' 
		and StartDateFiscalYear='16/17'
	) as sub1; 



---------------------
-- WINDOW FUNCTION EXAMPLE 
---------------------

Select StartDate
	, ContinuumID 
	, FirstEmergencyAreaCode
	, TriageAcuityCode 
	, count(*) OVER (PARTITION by TriageAcuityCode) as CTAS_total  -- for each row, also include a column that 
																   -- shows the total num cases on that day that had the same CTAS 
From EDMart.[dbo].[vwEDVisitIdentifiedRegional]
Where StartDate = '2017-01-01' 
	and FacilityLongName = 'Lions Gate Hospital' 
Order by StartDate
	, TriageAcuityCode; 


---------------------------------------------
-- Updating tables with UPDATE+SET and ALTER + ADD 
---------------------------------------------
drop table if exists #emp; 

create table #emp (
	id int
	, name varchar(15)
)


insert into #emp values
	('1', 'Amy')
	, ('2', 'Bob')
	, ('3', 'Cat')
	, ('4', 'Dylan')

-- select * from #emp 

alter table #emp
add company varchar(25); 

update #emp
set company = 'Facebook' 
where name = 'Bob'

-- select * from #emp 



drop table if exists #orders; 
create table #orders(
	order_id int
	, amount int 
	, emp_id int
) 

insert into #orders values 
	('1', '455', '2')
	, ('2', '1200', '2')
	, ('3', '41', '36')

-- select * from #orders


select * 
from #emp e
left join #orders o
	on e.id = o.emp_id; 

select * 
from #emp e
inner join #orders o
	on e.id = o.emp_id; 

select * 
from #emp e
right join #orders o
	on e.id = o.emp_id; 


select count (name) as count_names 
from #emp e 
left join #orders o 
	on e.id = o.emp_id

select count (distinct name) as count_distinct_names 
from #emp e 
left join #orders o 
	on e.id = o.emp_id



---------------------------------------------------------------------
-- Question: Find patients in ED data who aren't in ADTC data (INTERSECT and EXCEPT) 
---------------------------------------------------------------------

-- let's create tables to play with 
drop table if exists #t1_ed_visits;  
drop table if exists #t2_adtc;  

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
-- select t2.patientid, t2.* from #t2_adtc t2 order by t2.patientid 



-- find set intersection: 
select patientID 
from #t1_ed_visits

INTERSECT 

select patientID 
from #t2_adtc

-- let's check with a join: first repeat the above query, 
-- then get the setdiff with EXCEPT

-- note that when using a join, it's easy to forget to use "distinct", and 
-- than will give the wrong number bcoz of duplicates 

select patientID 
from #t1_ed_visits
INTERSECT 
select patientID 
from #t2_adtc

EXCEPT 

select distinct t1.patientID  
from #t1_ed_visits t1
	inner join #t2_adtc t2
		on t1.PatientID = t2.PatientID

/* this part is required because it matters which table appears first in EXCEPT  
EXCEPT

select patientID 
from #t1_ed_visits
INTERSECT 
select patientID 
from #t2_adtc
*/








