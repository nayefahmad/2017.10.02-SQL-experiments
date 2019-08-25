

---------------------------------------------------------
--UPDATED MH READMISSIONS QUERY - PULLING ALL CASES FROM 2012 TO PRESENT
---------------------------------------------------------


/* MHSU Readmissions within 30 Days Indicator */
--BEFORE RUNNING QUERY:  Change date criteria in two places (once in Episode Building section
--Step 1 and once in the Denominator section).  See "Dates" tab on excel spreadsheet for details.

--This query is based on an adaptation of the 30 Day Readmit query (v7):
/* DIFFERENCES:
1. TRANSFERS: Just have to be discharged from prev facility on same day as facility discharged to.
2. Do not delete episodes with Daycare as both head and tail.  Instead delete episodes with Daycare as head (applies to num and denominator).
3. Do not exlude episodes with Mental illness (MCC=17) and Palliative Care (MRDx = Z51.5) before creating num and den tables.  Instead, exclude episodes where the 
   age is < 15. 
4. Exclude Episodes where a selected mental illness is NOT coded as the most responsible diagnosis.
5. Do not exclude from denominator those discharge dispositions of self signout, or not return from a pass.
6. PatientGroups are not assigned.
7. Do not exclude episodes from numerator with Mental Illness (MCC: 17), Chemotherapy as MRDx (Z511), PallCare as MRDx (Z515), and deliveries

--May 12, 2017:  Added these new fields:
DischNursingUnit
DischNursingUnitCode
MHFollowupForm
MHFollowupDate
InvoluntaryAdmit
CMGPlusDesc
PatientID
HealthAuthorityName
LHAName

--Aug 9, 2017:  Version 3 created with the following CORRECTION and updates:
1.Denominator exclusions:  Exclude deaths as originally intended (using correct disposition code of 07 instead of 06).
2.Additional notes added throughout query indicating where the query is different from the basic 30 day readmit indicator.

*/

--For Nayef (Aug 23, 2018):  
--Just changed the date criteria to look at cases discharged between April 1, 2012 and Feb 22, 2018 (end of p12), and...
--Created some queries at the end to get an extract for the num, den, as well as num with associated den (if wanted).


--EPISODE BUILDING:

/*** Step 1 ***/
-- Step 1A: Create a table containing all DAD Acute and Daycare records.
-- Exclusions: stillborns and cadavers.  Inclusions: Gender = M or F. 
-- First part will contain duplicates, due to two or more records containing different ETLAuditIDs, MRNs and/or Accounts.  This is 
-- taken care of in the second part.  Note: MRN and Account were removed from the query for this reason.   

USE ADRMart
drop table [#a_withoutrecordID_ungrouped]
--DAD Acute data
SELECT 
(CASE WHEN a.CareType = 'A' then 'Acute' 
      WHEN a.CareType = 'D' then 'Daycare' 
	  ELSE 'Unknown'
	  end) LOC, 
a.ETLAuditId, a.[FiscalYear], 
a.[ChartNumber] [ChartNum], a.[RegisterNumber][AcctNum],
[AdmitDate], d1.[shortdate] [AdmissionDate], [AdmitTime], d1.[shortdate]+[AdmitTime] AdmissionDateandTime,
a.[DischargeDate] DischargeDateINT, d2.[shortdate] [DischargeDate], [DischargeTime], d2.[shortdate]+[DischargeTime] DischargeDateandTime,
[AdmissionCategoryCode],[AdmissionCategoryDesc],
DischargeDispositionCode, DischargeDisposition,
[EntryCode],[EntryCodeDesc],
[Gender], a.FacilityShortName [InstitutionName]
      ,a.[InstitutionNumber] [InstitutionNum]
      ,[InstitutionToName] [ToInstitutionName]
      ,[InstitutionToCode] [ToInstitutionNum]
      ,[InstitutionFromName] [FromInstitutionName]
      ,[InstitutionFromCode] [FromInstitutionNum]
	  ,a.[PHN]
      ,[BirthDate]
      ,[PatientAge] age
      ,a.Dx1Code
      ,Dx2Code
      ,Dx3Code
      ,Dx4Code
      ,Dx5Code
      ,Dx6Code
      ,Dx7Code
      ,Dx8Code
      ,Dx9Code
      ,Dx10Code
      ,Dx11Code
      ,Dx12Code
      ,Dx13Code
      ,Dx14Code
      ,Dx15Code
      ,Dx16Code
      ,Dx17Code
      ,Dx18Code
      ,Dx19Code
      ,Dx20Code
      ,Dx21Code
      ,Dx22Code
      ,Dx23Code
      ,Dx24Code
      ,Dx25Code
 
	  --start of new fields for surgical analysis:
	  ,a.Dx1Desc
      ,Dx2Desc
      ,Dx3Desc
      ,Dx4Desc
      ,Dx5Desc
      ,Dx6Desc
      ,Dx7Desc
      ,Dx8Desc
      ,Dx9Desc
      ,Dx10Desc
      ,Dx11Desc
      ,Dx12Desc
      ,Dx13Desc
      ,Dx14Desc
      ,Dx15Desc
      ,Dx16Desc
      ,Dx17Desc
      ,Dx18Desc
      ,Dx19Desc
      ,Dx20Desc
      ,Dx21Desc
      ,Dx22Desc
      ,Dx23Desc
      ,Dx24Desc
      ,Dx25Desc
	  ,DxType1Code
      ,DxType2Code
      ,DxType3Code
      ,DxType4Code
      ,DxType5Code
      ,DxType6Code
      ,DxType7Code
      ,DxType8Code
      ,DxType9Code
      ,DxType10Code
      ,DxType11Code
      ,DxType12Code
      ,DxType13Code
      ,DxType14Code
      ,DxType15Code
      ,DxType16Code
      ,DxType17Code
      ,DxType18Code
      ,DxType19Code
      ,DxType20Code
      ,DxType21Code
      ,DxType22Code
      ,DxType23Code
      ,DxType24Code
      ,DxType25Code
	  ,a.Px1Code
      ,Px2Code
      ,Px3Code
      ,Px4Code
      ,Px5Code
      ,Px6Code
      ,Px7Code
      ,Px8Code
      ,Px9Code
      ,Px10Code
      ,Px11Code
      ,Px12Code
      ,Px13Code
      ,Px14Code
      ,Px15Code
      ,Px16Code
      ,Px17Code
      ,Px18Code
      ,Px19Code
      ,Px20Code
	  ,a.Px1Desc
      ,Px2Desc
      ,Px3Desc
      ,Px4Desc
      ,Px5Desc
      ,Px6Desc
      ,Px7Desc
      ,Px8Desc
      ,Px9Desc
      ,Px10Desc
      ,Px11Desc
      ,Px12Desc
      ,Px13Desc
      ,Px14Desc
      ,Px15Desc
      ,Px16Desc
      ,Px17Desc
      ,Px18Desc
      ,Px19Desc
      ,Px20Desc
	  ,mccPlusCode MCC
	  ,MCCPlus MCCDesc
	  ,CMGPlusCode CMG
	  ,CMGPlusDesc
	  ,[CMGStatusDesc]
	  ,a.GradeAssignment
      ,[Partition]
	  ,CaseWeight RIW
	  --, NULL [DPGCode]
	  --, NULL [DPGDesc]
	  ,LOS
	  ,AcuteDays
	  ,ALCDays
	  --,RIW
	  --,DPG_RIW
	  ,ELOS

	  ,[MostRespProviderCode]
	  ,[MostRespProviderService]
	  ,[MainPtServiceCode]
	  ,[MainPtServiceDesc]


	  --added may 12, 2017:
		,DischNursingUnit
		,DischNursingUnitCode
		,MHFollowupForm
		,MHFollowupDate
		,InvoluntaryAdmit
		,a.PatientID
		,HealthAuthorityName
		,LHAName

	--added Aug 16, 2018 for Suhail's deep dive
	     ,AdmitNursingUnit
	    ,AdmitNursingUnitCode
		,HSDAName


into [#a_withoutrecordID_ungrouped]
FROM [ADRMart].[dbo].[vwAbstractFact] a
LEFT JOIN [Dim].[Date] d1 on a.AdmitDate = d1.dateid
LEFT JOIN [Dim].[Date] d2 on a.DischargeDate = d2.dateid
left join  [ADRMart].[dbo].[vwDx] dx on a.etlauditid = dx.etlauditid
left join  [ADRMart].[dbo].[vwPx] px on a.etlauditid = px.etlauditid
left join  [ADRMart].[Dim].[CMG] c ON a.CMGPlusCode = c.CMGCode

where 
--For BSC Indicator (Quarterly basis):
d2.[shortdate] between '2012-04-01' and '2018-03-24' --FY2012 thru FY2018-12  --for Nayef request Aug 23, 2018
--d2.[shortdate] between '2012-04-01' and '2012-07-21' --FY2013-Q1
--d2.[shortdate] between '2012-06-22' and '2012-10-13' --FY2013-Q2
--d2.[shortdate] between '2012-09-14' and '2013-01-05' --FY2013-Q3
--d2.[shortdate] between '2012-12-07' and '2013-03-31' --FY2013-Q4
--d2.[shortdate] between '2013-04-01' and '2013-07-20' --FY2014-Q1
--d2.[shortdate] between '2013-06-21' and '2013-10-12' --FY2014-Q2
--d2.[shortdate] between '2013-09-13' and '2014-01-04' --FY2014-Q3
--d2.[shortdate] between '2013-12-06' and '2014-03-31' --FY2014-Q4
--d2.[shortdate] between '2014-04-01' and '2014-07-19' --FY2015-Q1
--d2.[shortdate] between '2014-06-20' and '2014-10-11' --FY2015-Q2
--d2.[shortdate] between '2014-09-12' and '2015-01-03' --FY2015-Q3
--d2.[shortdate] between '2014-12-05' and '2015-03-31' --FY2015-Q4
--d2.[shortdate] between '2015-04-01' and '2016-03-31' --FY2016  --for Suhail readmit extract request
--d2.[shortdate] between '2015-04-01' and '2015-07-18' --FY2016-Q1
--d2.[shortdate] between '2015-06-19' and '2015-10-10' --FY2016-Q2
--d2.[shortdate] between '2015-09-11' and '2016-01-02' --FY2016-Q3
--d2.[shortdate] between '2015-12-04' and '2016-03-31' --FY2016-Q4
--d2.[shortdate] between '2016-04-01' and '2017-03-31' --FY2017  --for Suhail readmit extract request
--d2.[shortdate] between '2016-04-01' and '2016-07-16' --FY2017-Q1
--d2.[shortdate] between '2016-06-17' and '2016-10-08' --FY2017-Q2
--d2.[shortdate] between '2016-09-09' and '2016-12-31' --FY2017-Q3
--d2.[shortdate] between '2016-12-02' and '2017-03-31' --FY2017-Q4
--d2.[shortdate] between '2017-04-01' and '2017-07-15' --FY2018-Q1
--d2.[shortdate] between '2017-06-16' and '2017-10-07' --FY2018-Q2
--d2.[shortdate] between '2017-09-08' and '2017-12-30' --FY2018-Q3


and Gender in ('Male', 'Female') and [AdmissionCategoryCode] NOT IN ('S', 'R', 'N')
and len(a.PHN) > 1 /*valid PHN*/
--and len(a.PHN) = 10 and left(a.PHN, 1) = '9' /*valid PHN*/
and a.caretype in ('A', 'D')

--55594 rows

--Step 1B: Create a new table like the one created in step 1A, but with unique records only (based on lowest ETLAuditID), and just four fields.  
--Purpose:  To prepare to filter the entire dataset in Step 1C for unique records only.
drop table [#a_uniquerecords]
select PHN, PatientID, Admissiondateandtime, DischargeDateandTime, BirthDate, Min(ETLAuditID) ETLAuditIDmin
into [#a_uniquerecords]
from [#a_withoutrecordID_ungrouped]
group by PHN, PatientID, Admissiondateandtime, DischargeDateandTime, BirthDate
GO
--178939 rows


--Step 1C:  Create a new table like the one created in step 1A, but filtered for unique records.  
Drop table [#a_withoutrecordID] 
select g.*  
INTO [#a_withoutrecordID]
FROM [#a_withoutrecordID_ungrouped] g inner join
[#a_uniquerecords] u on g.ETLAuditID = u.ETLAuditIDmin
GO
--178939 rows

--Step 1D:  Create copy of the same table with a unique sequence ID ("RecordID") added for each record.
drop table [#a]
Select RecordID = ROW_NUMBER() OVER (ORDER BY PHN, BirthDate, AdmissionDateandTime, DischargeDateandTime), *
INTO [#a]
from [#a_withoutrecordID]
GO
--178939 rows
-- select * from #a

/*** Step 2 ***/
--USING ALL DATA (not just ONE PHN)

--Create Separate tables for Original Admit and Readmit.  Start with one table that has all records, plus their 
--readmit date (if applicable).  Then create another table with the readmits from the first table, and their readmit 
--dates (if applicable).  Carry on for 10 tables total (there were, at one time, 10 readmits within 6 hours for the same patient, at the most). 


--First set of Original and Subsequent Admits:
drop table [#a1]
select OA.PHN, OA.PatientID,  OA.BirthDate, OA.RecordID, OA.AdmissionDateandTime, OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a1]	
from 
	(	select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, ToInstitutionNum
		from  [#a]
    ) OA left outer join 
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			OA.PatientID = RA.PatientID and
			OA.BirthDate = RA.BirthDate and
			OA.RecordID <> RA.RecordID and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital 
			--(DIFF FROM 30DAY READMIT QUERY)
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
--			-- ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) between 360 and 720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND 
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, OA.PatientID, OA.BirthDate, OA.RecordID, OA.AdmissionDateandTime, OA.DischargeDateandTime 
GO
-- 178939 rows

--Second set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):

drop table [#a2]
select OA.PHN, OA.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a2]	
from 
--original admit
	(	select a1.PHN, A1.PatientID, a1.BirthDate,a1.RecordID, a1.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a1] a1
		inner join [#a] a on 
			a1.PHN = a.PHN AND
			a1.PatientID = a.PatientID and 
			a1.BirthDate = a.Birthdate AND
			a1.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, patientid, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND 
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--2127 rows


--Third set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):

drop table [#a3]
select OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime
into [#a3]	
from 
--original admit
	(	select a2.PHN, a2.PatientID,  a2.BirthDate, a2.RecordID, a2.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a2] a2
		inner join [#a] a on 
			a2.PHN = a.PHN AND
			a2.PatientID = a.PatientID and 
			a2.BirthDate = a.Birthdate AND
			a2.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID,  BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a] 
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--269 rows


--Fourth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):

drop table [#a4]
select OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a4]	
from 
--original admit
	(	select a3.PHN, a3.PatientID, a3.BirthDate, a3.RecordID, a3.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a3] a3
		inner join [#a] a on 
			a3.PHN = a.PHN AND
			a3.PatientID = a.PatientID and 
			a3.BirthDate = a.Birthdate AND
			a3.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN,PatientID,  BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6)  
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--40 rows


--Fifth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):

drop table [#a5]
select OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a5]	
from 
--original admit
	(	select a4.PHN, a4.PatientID, a4.BirthDate, a4.RecordID, a4.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a4] a4
		inner join [#a] a on 
			a4.PHN = a.PHN AND
			a4.PatientID = a.PatientID and
			a4.BirthDate = a.Birthdate AND
			a4.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--9 rows

--Sixth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):

drop table [#a6]
select OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a6]	
from 
--original admit
	(	select a5.PHN, a5.PatientID,  a5.BirthDate, a5.RecordID, a5.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a5] a5
		inner join [#a] a on 
			a5.PHN = a.PHN AND
			a5.PatientID = a.PatientID and
			a5.BirthDate = a.Birthdate AND
			a5.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--0 rows

--Seventh set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):
drop table [#a7]
select OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a7]	
from 
--original admit
	(	select a6.PHN, a6.PatientID, a6.BirthDate, a6.RecordID, a6.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a6] a6
		inner join [#a] a on 
			a6.PHN = a.PHN AND
			a6.PatientID = a.PatientID and 
			a6.BirthDate = a.Birthdate AND
			a6.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND 
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
-- 0 records

--Eighth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):
drop table [#a8]
select OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a8]	
from 
--original admit
	(	select a7.PHN, a7.PatientID, a7.BirthDate, a7.RecordID, a7.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a7] a7
		inner join [#a] a on 
			a7.PHN = a.PHN AND
			a7.PatientID = a.PatientID and 
			a7.BirthDate = a.Birthdate AND
			a7.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			
			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--0 rows


--Ninth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):
drop table [#a9]
select OA.PHN, oa.PatientID, OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a9]	
from 
--original admit
	(	select a8.PHN, a8.PatientID,  a8.BirthDate, a8.RecordID, a8.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a8] a8
		inner join [#a] a on 
			a8.PHN = a.PHN AND
			a8.PatientID = a.PatientID and 
			a8.BirthDate = a.Birthdate AND
			a8.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			
			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6) 
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--0 rows

--Tenth set of Original and Subsequent Admits (using test PHN i.e. from #a_subset):
drop table [#a10]
select OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime [AdmissionDateandTime], OA.DischargeDateandTime, min(RA.AdmissionDateandTime) As ReadmitAdmitDateandTime

into [#a10]	
from 
--original admit
	(	select a9.PHN, a9.PatientID,  a9.BirthDate, a9.RecordID, a9.ReadmitAdmitDateandTime, a.DischargeDateandTime, a.InstitutionNum, a.ToInstitutionNum
		from  [#a9] a9
		inner join [#a] a on 
			a9.PHN = a.PHN AND
			a9.PatientID = a.PatientID and 
			a9.BirthDate = a.Birthdate AND
			a9.ReadmitAdmitDateandTime = a.AdmissionDateandTime
    ) OA left outer join 
--readmit
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDateandTime, DischargeDateandTime, InstitutionNum, FromInstitutionNum
		from  [#a]
    ) RA on OA.PHN = RA.PHN and
			oa.PatientID = ra.PatientID and 
			OA.BirthDate = RA.BirthDate and
			OA.DischargeDateandTime < RA.AdmissionDateandTime and
			OA.InstitutionNum <> RA.InstitutionNum and

			
			--Admission to a general hospital/day surgery facility occurs on the same day as discharge from another general hospital
			Datediff(day, OA.DischargeDateandTime, RA.AdmissionDateandTime) = 0

--		    --1. Admission to an acute care institution or day surgery facility occurs within six hours of discharge from 
--			--   another acute care institution or day surgery facility, regardless of whether either institution codes the transfer; or
--		--	((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=360) 
--			((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=6)  
--				OR
--			-- 2. Admission to an acute care institution or day surgery facility occurs within 6 to 12 hours of discharge 
--			--    from another acute care institution or day surgery facility and at least one of the institutions codes the transfer.
----			 ((Datediff(minute, OA.DischargeDateandTime, RA.AdmissionDateandTime) <=720) AND 
--			 ((Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime) > 6 and 
--				(Datediff(hh, OA.DischargeDateandTime, RA.AdmissionDateandTime)<=12)) AND
--			  (OA.[ToInstitutionNum] is not null or RA.[FromInstitutionNum] is not null)))
     
group by OA.PHN, oa.PatientID,  OA.BirthDate, OA.RecordID, OA.ReadmitAdmitDateandTime, OA.DischargeDateandTime 
GO
--0 rows

/*** Step 3 ***/
-- Bring the Readmits Together into One Table, showing one record per RecordID, with all the readmits 
-- since that record on the same line. 

drop table [#readmits]
Select a1.PHN, a1.PatientID, a1.BirthDate, a1.RecordID RecordID0, 0 TranSeqNum0, 
a1.AdmissionDateandTime AdmitDate0, a1.DischargeDateandTime DischDate0, 

a2.RecordID RecordID1,(CASE WHEN a2.AdmissionDateandTime is not null THEN 1 ELSE NULL END) TranSeqNum1, 
a2.AdmissionDateandTime AdmitDate1, a2.DischargeDateandTime DischDate1, 
 
a3.RecordID RecordID2, (CASE WHEN a3.AdmissionDateandTime is not null THEN 2 ELSE NULL END) TranSeqNum2, 
a3.AdmissionDateandTime AdmitDate2, a3.DischargeDateandTime DischDate2,

a4.RecordID RecordID3, (CASE WHEN a4.AdmissionDateandTime is not null THEN 3 ELSE NULL END) TranSeqNum3, 
a4.AdmissionDateandTime AdmitDate3, a4.DischargeDateandTime DischDate3,

a5.RecordID RecordID4,(CASE WHEN a5.AdmissionDateandTime is not null THEN 4 ELSE NULL END) TranSeqNum4, 
a5.AdmissionDateandTime AdmitDate4, a5.DischargeDateandTime DischDate4,

a6.RecordID RecordID5, (CASE WHEN a6.AdmissionDateandTime is not null THEN 5 ELSE NULL END) TranSeqNum5, 
a6.AdmissionDateandTime AdmitDate5, a6.DischargeDateandTime DischDate5,

a7.RecordID RecordID6, (CASE WHEN a7.AdmissionDateandTime is not null THEN 6 ELSE NULL END) TranSeqNum6, 
a7.AdmissionDateandTime AdmitDate6, a7.DischargeDateandTime DischDate6,

a8.RecordID RecordID7, (CASE WHEN a8.AdmissionDateandTime is not null THEN 7 ELSE NULL END) TranSeqNum7, 
a8.AdmissionDateandTime AdmitDate7, a8.DischargeDateandTime DischDate7,

a9.RecordID RecordID8, (CASE WHEN a9.AdmissionDateandTime is not null THEN 8 ELSE NULL END) TranSeqNum8, 
a9.AdmissionDateandTime AdmitDate8, a9.DischargeDateandTime DischDate8,

a10.RecordID RecordID9, (CASE WHEN a10.AdmissionDateandTime is not null THEN 9 ELSE NULL END) TranSeqNum9, 
a10.AdmissionDateandTime AdmitDate9, a10.DischargeDateandTime DischDate9


into [#readmits]
from [#a1] a1
LEFT JOIN [#a2]  a2 
	ON a1.PHN = a2.PHN and a1.BirthDate = a2.BirthDate and a1.ReadmitAdmitDateandTime = a2.AdmissionDateandTime
LEFT JOIN [#a3]  a3 
	ON a2.PHN = a3.PHN and a2.BirthDate = a3.BirthDate and a2.ReadmitAdmitDateandTime = a3.AdmissionDateandTime
LEFT JOIN [#a4]  a4 
	ON a3.PHN = a4.PHN and a3.BirthDate = a4.BirthDate and a3.ReadmitAdmitDateandTime = a4.AdmissionDateandTime
LEFT JOIN [#a5]  a5 
	ON a4.PHN = a5.PHN and a4.BirthDate = a5.BirthDate and a4.ReadmitAdmitDateandTime = a5.AdmissionDateandTime
LEFT JOIN [#a6]  a6 
	ON a5.PHN = a6.PHN and a5.BirthDate = a6.BirthDate and a5.ReadmitAdmitDateandTime = a6.AdmissionDateandTime
LEFT JOIN [#a7]  a7 
	ON a6.PHN = a7.PHN and a6.BirthDate = a7.BirthDate and a6.ReadmitAdmitDateandTime = a7.AdmissionDateandTime
LEFT JOIN [#a8]  a8 
	ON a7.PHN = a8.PHN and a7.BirthDate = a8.BirthDate and a7.ReadmitAdmitDateandTime = a8.AdmissionDateandTime
LEFT JOIN [#a9]  a9 
	ON a8.PHN = a9.PHN and a8.BirthDate = a9.BirthDate and a8.ReadmitAdmitDateandTime = a9.AdmissionDateandTime
LEFT JOIN [#a10]  a10 
	ON a9.PHN = a10.PHN and a9.BirthDate = a10.BirthDate and a9.ReadmitAdmitDateandTime = a10.AdmissionDateandTime
GO
--178941 rows (Note:  Two extra records b/c of these two record IDs with overlapping disch/admit date times:  75538, 75537).  Don't worry about these.


--select * from [#readmits]
--where PHN = '9050753168'
--order by RecordID0	

/*** Step 4 ***/
--Create a table with one row per transfer, for every transfer combination.
--Add all possible records.
Drop table [#readmits_column]
Select PHN, PatientID,  BirthDate, RecordID0 RecordID, RecordID0 RecIDofFirstDisch, TranSeqNum0 TranSeqNum, AdmitDate0 AdmitDate, 
DischDate0 DischDate
into [#readmits_column]
from [#readmits]
GO
--178941 rows

--Add records again that represent the first transfer from the preceding discharge.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID1, r.TranSeqNum1, r.AdmitDate1, r.DischDate1
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate1 
where r.AdmitDate1 is not null
GO
--2129 rows

--Add records again that represent the second transfer from 2 discharges ago.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID2, r.TranSeqNum2, r.AdmitDate2, r.DischDate2
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and  a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate2 
where r.AdmitDate2 is not null
GO
--269 rows

--Add records again that represent the third transfer from 3 discharges ago.
Insert into [#readmits_column] (PHN, PatientID,  BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID3, r.TranSeqNum3, r.AdmitDate3, r.DischDate3
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and  a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate3 
where r.AdmitDate3 is not null
GO
--40 rows

--Add records again that represent the fourth transfer from 4 discharges ago.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID4, r.TranSeqNum4, r.AdmitDate4, r.DischDate4
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate4 
where r.AdmitDate4 is not null
GO
--9 rows

--Add records again that represent the fifth transfer from 5 discharges ago.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID5, r.TranSeqNum5, r.AdmitDate5, r.DischDate5
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate5 
where r.AdmitDate5 is not null
GO
--0 rows

--Add records again that represent the sixth transfer from 6 discharges ago.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID,  r.BirthDate, a.RecordID, r.RecordID6, r.TranSeqNum6, r.AdmitDate6, r.DischDate6
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate6 
where r.AdmitDate6 is not null
GO
--0 rows

--Add records again that represent the seventh transfer from 7 discharges ago.
Insert into [#readmits_column] (PHN, PatientID,  BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID7, r.TranSeqNum7, r.AdmitDate7, r.DischDate7
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate7 
where r.AdmitDate7 is not null
GO
--0 rows

--Add records again that represent the eighth transfer from 8 discharges ago.
Insert into [#readmits_column] (PHN, PatientID,  BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID8, r.TranSeqNum8, r.AdmitDate8, r.DischDate8
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate8 
where r.AdmitDate8 is not null
GO
--0 rows

--Add records again that represent the ninth transfer from 9 discharges ago.
Insert into [#readmits_column] (PHN, PatientID, BirthDate, RecordID, RecIDofFirstDisch, TranSeqNum, AdmitDate, DischDate)
select r.PHN, r.PatientID, r.BirthDate, a.RecordID, r.RecordID9, r.TranSeqNum9, r.AdmitDate9, r.DischDate9
from [#readmits] r
INNER JOIN [#a] a ON a.PHN = r.PHN and a.PatientID = r.PatientID and a.BirthDate = r.BirthDate and a.AdmissionDateandTime = R.AdmitDate9 
where r.AdmitDate9 is not null
GO
--0 rows



/*** Step 5 ***/
--Produce list of only desired records with recordID, episodeID and transfersequenceID.

drop table [#episodes_prep]
select phn, PatientID, birthdate, recordid, max(TranSeqNum) TrSeqNum
into [#episodes_prep]
from [#readmits_column] 
--where PHN = '9050753168'
group by phn, PatientID, birthdate, recordid
order by phn, PatientID, birthdate, recordid
GO
--178939 rows

drop table [#episodes]
select r.* 
into [#episodes]
from [#readmits_column] r
inner join [#episodes_prep] e
on r.recordid = e.recordid and 
r.transeqnum = e.trseqnum
order by recordid
GO
--178944 rows

--select * 
--from  [#episodes]
--order by recordid

/*** THE END OF BUILDING EPISODES YAY!!!!!!!!!!! ***/

----------------------------------------------------------------------------------------

/** POST EPISODE-BUILDING **/

--Step 1: Adding Head and Tail Flag to Episodes

--select * from  [#episodes]

--determine tail of episode
--Note:  RecIDofFirstDisch = EpisodeID = RecordID of the very first record in the episode.
DROP TABLE [#headtail]
select  PHN, PatientID, BirthDate, RecIDofFirstDisch, Max(TranSeqNum) highestseqnum 
INTO [#headtail]
from  [#episodes]
group by PHN, PatientID, BirthDate, RecIDofFirstDisch
GO
--176813 rows

--pull all episode records, with head and tail flags, into a new table called:  #episodes1
drop table [#episodes1]
select e.*, (CASE WHEN TranSeqNum = 0 THEN 1 ELSE 0 END) EpisodeHead, 
(CASE WHEN h.RecIDofFirstdisch is not null THEN 1 ELSE 0 END) EpisodeTail,
0 [IndexEpisode]
INTO [#episodes1]
from  [#episodes] e
LEFT OUTER JOIN [#headtail] h
ON e.PHN = h.PHN and
e.PatientID = h.PatientID and 
e.BirthDate = h.BirthDate and
e.RecIDofFirstDisch = h.RecIDofFirstDisch and
e.TranSeqNum = h.highestseqnum
--where e.phn = '9050753168'
order by e.Recordid
GO
--178944 rows



--Step 2: Create new table called [#episodes2] with episode ID and seq #, headflag, tailflag, and then all other fields from original table (for flagging 
--specific criteria in next steps).

drop table  [#episodes2]
select RecIDofFirstDisch, TranSeqNum, EpisodeHead, Episodetail, IndexEpisode, a.*
into [#episodes2]
from [#a] a
join [#episodes1] e
on a.recordid = e.recordid
GO
--178944 rows


--Step 3. Eliminate Episodes that start with Day Care cases.  Admission must be to a general hospital for denominator cases  (DIFF FROM 30D READMIT QUERY)

delete 
from [#episodes2] 
where recidoffirstdisch in 
	(select recidoffirstdisch from [#episodes2] 
	 where 
		--(episodetail = 1 and LOC = 'Daycare') or
		  episodehead = 1 and LOC = 'Daycare')
GO
--97111 rows


--Step 4: Exclude Episodes where age on admission < 15.  Applies to denominator, and thus numerator too.   (DIFF FROM 30D READMIT QUERY)

delete 
from [#episodes2] 
where recidoffirstdisch in 
	(select recidoffirstdisch from [#episodes2] 
	 where episodehead = 1 and Age < 15 and Age <> '')
GO
--97111 rows

-- Step 5:  Exclude Episodes where a selected mental illness is NOT coded as the most responsible diagnosis.  (DIFF FROM 30D READMIT QUERY)

--select episodes where Mental illness is coded as the mrdx on the first record of the episode
drop table [#mh]
select distinct recidoffirstdisch
into [#mh] 
from [#episodes2] 
where recidoffirstdisch in (select recidoffirstdisch from  [#episodes2] where episodehead = 1 and
--substance-related disorders:
(Dx1Code = 'F55' or Dx1Code like 'F1[0-9]%' or 

--schizophrenia, delusional and non-organic psychotic disorders:
Dx1Code like 'F20[0-3]' or Dx1Code like 'F20[5-9]' or
Dx1Code like 'F2[2-5]%' or Dx1Code like 'F2[8-9]%' or
Dx1Code = 'F531' or

--mood/affective disorders:
Dx1Code like 'F3[0-4]%' or Dx1Code like 'F3[8-9]%' or Dx1Code = 'F530' or

--anxiety disorders:
Dx1Code like 'F4[0-3]%' or Dx1Code in ('F488', 'F489', 'F938') or

--selected disorders of adult personality and behaviour:
Dx1Code like 'F6[0-2]%' or Dx1Code like 'F6[8-9]%' or Dx1Code = 'F21' or

--Eating disorders:
Dx1Code in ('F50', 'F500', 'F501', 'F502', 'F503', 'F504', 'F505', 'F508', 'F509')) 
)





--make a new episodes table where only the MH episodes identified above are included:
drop table #episodes3
select ep.* into #episodes3
from #episodes2 ep
inner join [#mh] mh on ep.recidoffirstdisch  = mh.recidoffirstdisch 


  



/** ELIGIBLE EPISODES:  **/

--Step 1: Flag Index Episode:
--Determine index episode for each PHN

drop table [#index]
select PHN, PatientID, BirthDate, Min(RecordID) [index]
into [#index]
from [#episodes3] 
group by PHN, PatientID, BirthDate
GO
--57261 rows selected

--Update index episode field for each PHN (currently has a default value of zero).
UPDATE  [#episodes3]
SET [#episodes3].IndexEpisode = 1
FROM [#episodes3]
JOIN [#index] ON [#episodes3].PHN = [#index].PHN AND
[#episodes3].BirthDate = [#index].BirthDate
WHERE [#index].[index]= [#episodes3].recidoffirstdisch
GO
--58687 rows updated
--see PHN 9052936279 for good example



--Step 2: Create tables for NUMERATOR and DENOMINATOR

drop table [#num]
select * into [#num] from  [#episodes3]
GO
--73677 rows

drop table [#den]
select * into [#den] from  [#episodes3]
GO
--73677 rows


/** DENOMINATOR **/

--Step 1:  Exclude Episodes with:
--Discharge from Mar 2 to Mar 31st
--Discharge disposition of: death
--Admitted to DTU but went home instead of to an inpatient unit.

--(DIFF FROM 30DAY READMIT QUERY)
delete from [#den] where recidoffirstdisch in (
Select  recidoffirstdisch from [#den]
left join [dbo].[vwDTUDischargedHome] DTU on [#den].ETLAuditID = DTU.[Acute_ETLAuditID]
where EpisodeTail = 1 and ((DischargeDispositionCode ='07') --corrected Aug 9, 2017 (this is the one change made for version 3).  Previously incorrectly using'06'.
--((DischargeDispositionCode in ('06', '07', '12'))

--Disposition Codes:  self-signouts (06), deaths (07), and not return from a pass (12)


--for BSC Indicator (Quarterly BASIS):
--or (dischargedateandtime between '2012-06-22' and '2012-07-21 23:59') --FY2013-Q1
--or (dischargedateandtime between '2012-09-14' and '2012-10-13 23:59') --FY2013-Q2
--or (dischargedateandtime between '2012-12-07' and '2013-01-05 23:59') --FY2013-Q3
--or (dischargedateandtime between '2013-03-02' and '2013-03-31 23:59') --FY2013-Q4
--or (dischargedateandtime between '2013-06-21' and '2013-07-20 23:59') --FY2014-Q1
--or (dischargedateandtime between '2013-09-13' and '2013-10-12 23:59') --FY2014-Q2
--or (dischargedateandtime between '2013-12-06' and '2014-01-04 23:59') --FY2014-Q3
--or (dischargedateandtime between '2014-03-02' and '2014-03-31 23:59') --FY2014-Q4
--or (dischargedateandtime between '2014-06-20' and '2014-07-19 23:59') --FY2015-Q1
--or (dischargedateandtime between '2014-09-12' and '2014-10-11 23:59') --FY2015-Q2
--or (dischargedateandtime between '2014-12-05' and '2015-01-03 23:59') --FY2015-Q3
--or (dischargedateandtime between '2015-03-02' and '2015-03-31 23:59') --FY2015-Q4
--or (dischargedateandtime between '2015-06-19' and '2015-07-18 23:59') --FY2016-Q1
--or (dischargedateandtime between '2015-09-11' and '2015-10-10 23:59') --FY2016-Q2
--or (dischargedateandtime between '2015-12-04' and '2016-01-02 23:59') --FY2016-Q3
--or (dischargedateandtime between '2016-03-02' and '2016-03-31 23:59') --FY2016-Q4   --and FY2016 for Suhail's readmit extract request
--or (dischargedateandtime between '2016-03-25' and '2016-03-31 23:59') --FY2016-Q4   --and FY2016 for Suhail's 7 day readmit extract request

--or (dischargedateandtime between '2016-06-17' and '2016-07-16 23:59') --FY2017-Q1
--or (dischargedateandtime between '2016-09-09' and '2016-10-08 23:59') --FY2017-Q2
--or (dischargedateandtime between '2016-12-02' and '2016-12-31 23:59') --FY2017-Q3
--or (dischargedateandtime between '2017-03-02' and '2017-03-31 23:59') --FY2017-Q4  --and FY2017 for Suhail's readmit extract request
--or (dischargedateandtime between '2017-03-25' and '2017-03-31 23:59') --FY2017-Q4  --and FY2017 for Suhail's 7 day readmit extract request

--or (dischargedateandtime between '2017-06-16' and '2017-07-15 23:59') --FY2018-Q1
--or (dischargedateandtime between '2017-09-08' and '2017-10-07 23:59') --FY2018-Q2
--or (dischargedateandtime between '2017-12-01' and '2017-12-30 23:59') --FY2018-Q3
or (dischargedateandtime between '2018-02-23' and '2018-03-24 23:59') --FY2018-P12  --for Nayef's request Aug 23, 2018


--to exclude DTU patients (criteria added Jan 21, 2014):
or DTU.[Acute_ETLAuditID]  is not null))

GO
--9478 rows deleted



--Step 2:  Keep only the tail record of each episode:


delete from [#den] where 
Episodetail <> 1
GO
--1513 rows deleted


--select * from [#den]
--where InstitutionName = 'UBC Health Sciences Centre' and patientgroup = 'surg'
----[#den] where Institutionname like 'Bell%' and patientgroup = 'ob'

--Step 4:  Calculate Denominator for All Patient Groups by Institution:
drop table [#dentable]
select (CASE WHEN Institutionname = 'Richmond Hospital' THEN 'The Richmond Hospital'
		    ELSE Institutionname END) [Site], count(*) [Den]
into [#dentable]
from [#den]
group by (CASE WHEN Institutionname = 'Richmond Hospital' THEN 'The Richmond Hospital'
		    ELSE Institutionname END)
order by (CASE WHEN Institutionname = 'Richmond Hospital' THEN 'The Richmond Hospital'
		    ELSE Institutionname END)
GO

--select * from #dentable



------------------------------------------------------------------------------------------------------------------------------------
/** NUMERATOR **/

--Step 1: Numerator Inclusions:

--Include only head record of each episode
delete 
from [#num] 
where EpisodeHead <> 1 
GO
--1815 deleted


--Step 2:  Exclude from numerator all admits to DTU but went home instead of to an inpatient unit.

delete n from [#num] n
left join [dbo].[vwDTUDischargedHome] DTU on n.ETLAuditID = DTU.[Acute_ETLAuditID]
where DTU.[Acute_ETLAuditID]  is not null
--1844 rows

--Step 3: Numerator Calculation:


--Determine the first readmit (in num dataset) within 30 days after the discharge record(in den dataset).
  
drop table [#num_final]
select OD.PHN as [readmit_PHN]
	, od.PatientID as [readmit_PatientID]
	, OD.BirthDate as [readmit_BirthDate]
	, OD.RecordID as [readmit_RecordID]
	, OD.AdmissionDate as      [prev_AdmissionDate]
	, OD.DischargeDate as      [prev_DischargeDate] 
	, OD.InstitutionName as    [readmit_InstitutionName]
	, min(RA.AdmissionDate) As ReadmitAdmitDate
into [#num_final]	
from 
	(	select PHN, PatientID, BirthDate, RecordID, AdmissionDate, DischargeDate,  InstitutionName
		from  [#den]
    ) OD  join 
	(   select PHN, PatientID, BirthDate, RecordID, AdmissionDate, DischargeDate, InstitutionName
		from  [#num]
    ) RA on OD.PHN = RA.PHN and
			od.PatientID = ra.PatientID and 
			OD.BirthDate = RA.BirthDate and
			OD.RecordID <> RA.RecordID and
			OD.DischargeDate <= RA.AdmissionDate and
			((Datediff(day,  OD.dischargedate, RA.admissiondate) <=30) and (Datediff(day,  OD.dischargedate, RA.admissiondate) >=0))
  group by OD.PHN, od.PatientID, OD.BirthDate, OD.RecordID, OD.AdmissionDate, OD.DischargeDate,  OD.InstitutionName
GO
--5604 rows

--NEW CODE (April 8, 2015):  Delete records in #num_final table that have the same readmit case for more than one denominator case.

drop table [#dups]
select readmit_PHN, readmit_PatientID, readmit_BirthDate, ReadmitAdmitDate, count(*) cases 
into [#dups]
from [#num_final]	
group by readmit_PHN, readmit_PatientID, readmit_BirthDate, ReadmitAdmitDate
having count(*) > 1 

--select top 1 * from #dups

drop table [#dedup]
select nf.readmit_PHN, nf.readmit_PatientID, nf.readmit_BirthDate, min(readmit_RecordID) earliestDischarge
into [#dedup]
from [#num_final] nf
inner join [#dups] dups on nf.readmit_PHN = dups.readmit_PHN and nf.readmit_PatientID = dups.readmit_PatientID and nf.readmit_BirthDate = dups.readmit_BirthDate and nf.ReadmitAdmitDate = dups.ReadmitAdmitDate
group by nf.readmit_PHN, nf.readmit_PatientID, nf.readmit_BirthDate

--select top 1 * from #dedup

delete nf 
from [#num_final] nf
left join [#dedup] ded on nf.readmit_PHN = ded.readmit_PHN and nf.readmit_PatientID = ded.readmit_PatientID and nf.readmit_BirthDate = ded.readmit_BirthDate and nf.readmit_RecordID = ded.earliestDischarge
where ded.readmit_PHN is not null and ded.readmit_BirthDate is not null and ded.earliestDischarge is not null
 



--Final Results:
drop table [#numtable]
select  
(Case When readmit_InstitutionName = 'Richmond Hospital' THEN 'The Richmond Hospital' ELSE readmit_InstitutionName END) [Site], 
count(*) Num
into [#numtable]
from [#num_final]
group by  (Case When readmit_InstitutionName = 'Richmond Hospital' THEN 'The Richmond Hospital' ELSE readmit_InstitutionName END)
order by  (Case When readmit_InstitutionName = 'Richmond Hospital' THEN 'The Richmond Hospital' ELSE readmit_InstitutionName END)
GO





-------------------------------------------------------------------------------------------
--FINAL CALCULATION:
-------------------------------------------------------------------------------------------

select 
CASE 
	WHEN d.[Site] in ('BCGH', 'RWLMH', 'PRGH', 'SGH', 'SMH') THEN 'Coastal Rural'
	WHEN d.[Site] = 'LGH' THEN 'Coastal Urban'
	WHEN d.[Site] = 'RHS' THEN 'Richmond'
	WHEN d.[Site] in ('UBCH', 'VGH') THEN 'Vancouver'
	WHEN d.[Site] = 'SPH' THEN 'PHC'
	ELSE 'Unknown' END Entity,
 d.[Site]
 , Num
 , Den
from [#dentable] d
	left join [#numtable] n on 
	d.[Site] = n.[Site]



--------------------------------------------------------------------
-- records included in test data set for MH Readmissions predictive model: 
--------------------------------------------------------------------
if OBJECT_ID('tempdb.dbo.##mhreadmit_traindata') is not null drop table ##mhreadmit_traindata; 

--select * from #den; 

select d.PHN as				[denom_PHN]
	, d.PatientID as		[denom_PatientID]
	, d.RecordID as			[denom_RecordID] 
	, d.BirthDate as		[denom_BirthDate] 
	, d.InstitutionName as	[denom_Institution]
	, d.AdmissionDate as	[denom_AdmissionDate] 
	, d.DischargeDate as	[denom_DischargeDate] 
	, nf.*
	, case when nf.ReadmitAdmitDate is not null then 1 else 0 end as Readmit_Flag 

into ##mhreadmit_traindata 
from #den d
	left join #num_final nf 
	on d.PHN = NF.readmit_PHN
	and d.PatientID = nf.readmit_PatientID 
	and d.BirthDate = nf.readmit_BirthDate
	and d.RecordID = nf.readmit_RecordID
order by d.PHN
	,  d.RecordID


--check:  ------------
select * from ##mhreadmit_traindata order by denom_admissionDate, denom_PHN, denom_RecordID; 



