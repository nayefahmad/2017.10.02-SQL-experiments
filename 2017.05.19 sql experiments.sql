

DECLARE @variable varchar(30); 
SET @variable = 'World'; 
SELECT @variable as Hello ; 

SELECT @variable; 

-- table variable: alternative to temptable
DECLARE @MyTableVar table(  
    LastStartDate datetime,
	ID int);  

INSERT INTO @MyTableVar
	VALUES('2017-01-01', 99921);

SELECT * FROM @MyTableVar; 
-------------------------------------------

DECLARE @date AS datetime = '2017-05-01'; 

SELECT ContinuumID, AdjustedDischargeDate 
FROM [ADTCMart].[ADTC].[vwAdmissionDischargeFact]
WHERE AdjustedDischargeDate = @date; 

-------------------------------------------
-- generate a string of dates: -------------------
-------------------------------------------
DROP TABLE #tempdates; 

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


