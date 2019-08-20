

/*---------------------------------------------------------------------------
QUERY TO COUNT NUMBER OF PAST ED ADMISSIONS IN LAST X DAYS FOR EACH PATIENT ADMITTED TO ACUTE 

todo: 
> line 45

---------------------------------------------------------------------------*/


-- parameters: ----------------------------
declare @num_admission_cutoff as int = 0; 


--cleanup: --------------------------------
if object_id ('tempdb.dbo.#t1_all_acute') is not null drop table								#t1_all_acute; 
if object_id ('tempdb.dbo.#t2_frequent_admits_phns') is not null drop table						#t2_frequent_admits_phns; 
if object_id ('tempdb.dbo.#t3_ADR_extract_with_subset_of_patients ') is not null drop table		#t3_ADR_extract_with_subset_of_patients ; 
if object_id ('tempdb.dbo.#t4_fix_dates') is not null drop table								#t4_fix_dates; 
if object_id ('tempdb.dbo.#t5_encntrs_excluding_zeroEDVisit_cases') is not null drop table		#t5_encntrs_excluding_zeroEDVisit_cases; 


-- Create a list of all patients with acute admissions in 2016/17 or 2017/18, with the number of admissions
-- 174141 rows 
select PHN
	, ROW_NUMBER() over(partition by PHN order by admitdate asc) 
		as RowNum
	, MCCPlusCode+' '+MCCPlus as MCC
into #t1_all_acute
from [ADRMart].[dbo].[vwAbstractFact]
where FiscalYear in ('2016/2017', '2017/2018') 
	and CareType = 'A' 
	and PHN > '9000000000'  -- remove invalid Patient IDs 
order by PHN
	, RowNum



-- Create a distinct list of PHNs with more than @num_admission_cutoff acute admissions 
--	in the specified time period and at least one of them for MHA (MCC 17)
-- 10449 rows

select distinct PHN
into #t2_frequent_admits_phns
from #t1_all_acute
where RowNum > @num_admission_cutoff  -- params 
	and MCC like '17%'  --TODO: we may not need this



-- Create an extract of PHNs, Admission/Discharge dates, CMGs and MCC for those patients identified above
-- 21303 rows

select phns.PHN
	, AdmitDate
	, DischargeDate
	, CMGPlusCode+' '+CMGPlusDesc	as CMG
	, MCCPlusCode+' '+MCCPlus		as MCC
into #t3_ADR_extract_with_subset_of_patients 
from #t2_frequent_admits_phns phns
	left join [ADRMART].[dbo].[vwAbstractFact] a
	on phns.PHN = a.PHN
where FiscalYear in ('2016/2017', '2017/2018') 
	and CareType = 'A'
order by PHN
	, AdmitDate



-- Convert the date ids into date format
-- 21303 rows 

select ad.PHN
	, b.shortdate as AdmissionDate
	, c.shortdate as DischDate
	, ad.CMG
	, ad.MCC
into #t4_fix_dates
from #t3_ADR_extract_with_subset_of_patients  ad 
	left join ADTCMart.dim.Date b
	on ad.AdmitDate = b.DateID
	left join ADTCMart.dim.Date c
	on ad.DischargeDate = c.DateID



-- List each acute Admission with the corresponding number of ED visits in the 
-- year before Admission (only lists admissions where ED visits > 0)
-- 20539 rows

select AD.PHN	
	, AD.AdmissionDate
	, AD.DischDate
	, count(ED.[VisitID]) as [EDVisits_year_prior]
into #t5_encntrs_excluding_zeroEDVisit_cases
from #t4_fix_dates AD 
	left join EDMart.[dbo].[vwEDVisitIdentifiedRegional] ED
	on AD.PHN = ED.PHN
where ED.StartDate between dateadd(day,-365,AD.AdmissionDate) and AD.AdmissionDate-- < AD.AdmitDate
group by AD.PHN
	, AD.AdmissionDate
	, AD.DischDate
	, AD.CMG
	, AD.MCC
order by AD.PHN, AD.AdmissionDate



-- Lists all acute admissions, with or without ED visits in the year before admission
select a.PHN
	, a.AdmissionDate
	, a.DischDate
	, a.CMG
	, a.MCC
	, isnull([EDVisits_year_prior], 0) as EDVisits
from #t4_fix_dates a 
	left join #t5_encntrs_excluding_zeroEDVisit_cases b
	on a.PHN = b.PHN 
		and a.AdmissionDate = b.AdmissionDate 
		and a.DischDate = b.DischDate
order by a.PHN
	, a.AdmissionDate
	, EDVisits





