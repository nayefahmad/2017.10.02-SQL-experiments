
/********************************************************************
Census by minute
2019-08-26
Nayef 

Goal: trying to re-write the query for finding census by minute, using 
joins rather than than a for loop

For reference, see the query https://github.com/nayefahmad/SQL-experiments/blob/master/2018-10-19_lgh_hospitalist-census-by-tod-previous-query-copied-from-excel.sql


********************************************************************/




drop table if exists #datetimes
GO  
-- this GO statement ensures that the first thing SQL does is drop the table. This is necessary 
-- for the rest of the program to work

declare @startdate datetime = '2019-09-28 00:00:00.00' 
declare @horizon_in_minutes int = 1440  -- 4 weeks

-- create table with a column of datetimes 
create table #datetimes (datetimes_col datetime) 

insert into #datetimes values 
	(@startdate) 

-- select * from #datetimes


-- use while loop to populate the table 
declare @counter int = 1 

while @counter <= @horizon_in_minutes
begin 
	insert into #datetimes values (DATEADD(mi, @counter, @startdate))
	set @counter = @counter + 1
end 

--select * from #datetimes order by datetimes_col


/*********************************************************************************/
-- add census at midnight as the first entry 
alter table #datetimes
add entry_count int, exit_count int

update #datetimes
set entry_count = (select count(PatientID) 
				   from ADTCMart.ADTC.CensusView
				   where FacilityLongName = 'Richmond Hospital' 
						and CensusDate = @startdate
						-- todo: here you can add conditions for nursing unit, physician type, etc. 

				   group by CensusDate) 
where datetimes_col = @startdate 

--select * from #datetimes order by datetimes_col


-- add site 
alter table #datetimes
add site varchar(25)

update #datetimes
set site = 'Richmond Hospital' 

-- select * from #datetimes order by datetimes_col


/********************************************************************************
Join datetime col to get full list of admits and discharges by minute
*********************************************************************************/
-- now join on ADTC.admissiondischarge: 
drop table if exists #t4_add_admits_discharges; 
select t1.datetimes_col
	, t1.[site]
	, t2_ad.AdjustedAdmissionDate
	, t2_ad.AdjustedAdmissionTime
	, t3_ad.AdjustedDischargeDate
	, t3_ad.AdjustedDischargeTime
	, t1.entry_count
	, t1.exit_count
into #t4_add_admits_discharges
from #datetimes t1
	LEFT JOIN ADTCMart.ADTC.AdmissionDischargeView t2_ad
		ON t1.datetimes_col = (t2_ad.AdjustedAdmissionDate + t2_ad.AdjustedAdmissionTime)
		and t1.site = t2_ad.[AdmissionFacilityLongName]
		-- todo: here you can add conditions for nursing unit code, admitting doctor type, etc.

	left join ADTCMart.ADTC.AdmissionDischargeView t3_ad
		on t1.datetimes_col = (t3_ad.AdjustedDischargeDate + t3_ad.AdjustedDischargeTime)
		and t1.site = t3_ad.DischargeFacilityLongName
		-- todo: here you can add conditions for nursing unit code, admitting doctor type, etc.

order by t1.datetimes_col

-- select * from #t4_add_admits_discharges order by datetimes_col

/*********************************************************************************
Code queue operations: enqueue and dequeue 
*********************************************************************************/

-- code every row with an admit as +1 in [entry_count]
update #t4_add_admits_discharges
set entry_count = 1 
where AdjustedAdmissionDate is not null 

-- code every row with an discharge as +1 in [exit_count]
update #t4_add_admits_discharges
set exit_count = -1
where AdjustedDischargeDate is not null 

-- select * from #t4_add_admits_discharges order by datetimes_col

-- deal with duplicate rows:
drop table if exists #t4_1_grouped; 
select datetimes_col
	, [site]
	, AdjustedAdmissionDate
	, AdjustedAdmissionTime
	, AdjustedDischargeDate
	, AdjustedDischargeTime
	, sum(entry_count) as entry_count
	, sum(exit_count) as exit_count
into #t4_1_grouped 
from #t4_add_admits_discharges
group by datetimes_col
	, [site]
	, AdjustedAdmissionDate
	, AdjustedAdmissionTime
	, AdjustedDischargeDate
	, AdjustedDischargeTime
order by datetimes_col

-- select * from #t4_1_grouped order by datetimes_col



-- find net changes to queue by minute: 
drop table if exists #t5_add_net_changes
select *
	, (isnull(entry_count, 0) + isnull(exit_count, 0)) as net_change
into #t5_add_net_changes
from #t4_1_grouped
order by datetimes_col

--select * from #t4_add_admits_discharges order by datetimes_col
--select * from #t5_add_net_changes order by datetimes_col




-- use correlated subquery to find running total 
drop table if exists #t6_census_by_minute
select t5_1.*
	, (select sum(net_change) 
		from #t5_add_net_changes t5_2
		where t5_2.datetimes_col <= t5_1.datetimes_col
	) as census_minute_level

into #t6_census_by_minute
from #t5_add_net_changes t5_1
order by datetimes_col

-- view: 
select * from #t6_census_by_minute order by datetimes_col


/*********************************************************************************
Validation with ADTC CensusView
*********************************************************************************/

-- ending figure from my calculation: 
select census_minute_level 
	, datetimes_col
from #t6_census_by_minute
where datetimes_col = (select max(datetimes_col) from #t5_add_net_changes)

-- check ending figure with census view figure: 
select count(PatientID) as census_from_ADTC
	, CensusDate
from ADTCMart.ADTC.CensusView
where FacilityLongName = 'Richmond Hospital' 
	and CensusDate between @startdate and dateadd(mi, @horizon_in_minutes, @startdate) 
group by CensusDate
order by CensusDate

-- hardcoded: 
--select count(*) as census_from_ADTC
--	, CensusDate
--from ADTCMart.ADTC.CensusView
--where FacilityLongName = 'Richmond Hospital' 
--	and CensusDate between '2018-05-27' and '2018-05-30' 
--group by CensusDate
--order by CensusDate



-- Why is the figure higher than it should be? Are we not counting all 
-- discharges properly? 

select sum(entry_count) - (select entry_count from #t6_census_by_minute where datetimes_col = @startdate)as [sum_entry_count]
	, sum(exit_count) as [sum_exit_count]
from #t5_add_net_changes
-- 114 discharges 

select count(*) as disch_from_adtc
from ADTCMart.ADTC.AdmissionDischargeView
where 1=1 
	and DischargeFacilityLongName = 'Richmond Hospital' 
	and AdjustedDischargeDate = @startdate 
-- 114 discharges 


-- Are we counting too many admits?? 
select count(*) as admit_from_adtc
from ADTCMart.ADTC.AdmissionDischargeView
where 1=1 
	and AdmissionFacilityLongName = 'Richmond Hospital' 
	and AdjustedAdmissionDate = @startdate 
