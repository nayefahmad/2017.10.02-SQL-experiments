
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