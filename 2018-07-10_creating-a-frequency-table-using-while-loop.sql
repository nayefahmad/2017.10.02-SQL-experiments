
-----------------------------------------------------------------------------------------------------------------------------------
 /* For 6E, 6W, and SCO units in LGH, calculates a frequency table based on how many patients are in the units at midnight
 Comparing patiets who had an OR operation vs all patients */
-----------------------------------------------------------------------------------------------------------------------------------

-- A table with possible number of patients at census time
IF OBJECT_ID('tempdb.dbo.#tempCensusCounter') IS NOT NULL DROP TABLE #tempCensusCounter; 

CREATE TABLE #tempCensusCounter (CensusCount Int);  

Declare @CensusCounter Int
Set @CensusCounter = 1

While @CensusCounter <= 70
BEGIN 
	Insert Into #tempCensusCounter (CensusCount) values (@CensusCounter)
	Set @CensusCounter = @CensusCounter + 1
End
--Select * From #tempCensusCounter

-- Census in 6E, 6W, SCO considering all patients
IF OBJECT_ID('tempdb.dbo.#SurgeryCensusAllPatients') IS NOT NULL DROP TABLE #SurgeryCensusAllPatients 
Select CensusDate, Count(PatientID) as CensusForSurgery
Into #SurgeryCensusAllPatients
FROM [ADTCMart].[ADTC].[vwCensusFact] 
Where CensusDate >= '2017-01-01'
and FacilityLongName = 'Lions Gate hospital'
and NursingUnitCode in ('6E', '6W', 'SCO')
Group by CensusDate
-- Select * From #SurgeryCensusAllPatients

-- Census in 6E, 6W, SCO considering OR patients only
IF OBJECT_ID('tempdb.dbo.#SurgeryCensusORPatients') IS NOT NULL DROP TABLE #SurgeryCensusORPatients 
Select a.CensusDate, Count(a.PatientID) as CensusForSurgeryFromOR
Into #SurgeryCensusORPatients
FROM [ADTCMart].[ADTC].[vwCensusFact] a
Inner Join (Select Distinct PatientID, AccountNum From [ORMart].[dbo].[vwRegionalORCompletedCase]) b on a.PatientID = b.PatientId and a.AccountNum = b.AccountNum
Where a.CensusDate >= '2017-01-01'
and a.FacilityLongName = 'Lions Gate hospital'
and a.NursingUnitCode in ('6E', '6W', 'SCO')
Group by a.CensusDate
--Select * From  #SurgeryCensusORPatients order by CensusDate



Select a.CensusCount, b.SurgeryCensusForAllPatients, c.SurgeryCensusForORPatients
From #tempCensusCounter a
Left join (Select CensusForSurgery, count(CensusDate) as SurgeryCensusForAllPatients From #SurgeryCensusAllPatients Group by CensusForSurgery) b on a.CensusCount = b.CensusForSurgery
Left join (Select CensusForSurgeryFromOR, count(CensusDate) as SurgeryCensusForORPatients From #SurgeryCensusORPatients Group by CensusForSurgeryFromOR) c on a.CensusCount = c.CensusForSurgeryFromOR
Group by a.CensusCount, b.SurgeryCensusForAllPatients, c.SurgeryCensusForORPatients
Order by a.CensusCount



