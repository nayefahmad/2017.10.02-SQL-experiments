
/********************************************************************
Census by minute
2019-08-26
Nayef 

Goal: trying to re-write the query for finding census by minute, using 
joins rather than than a for loop

For reference, see the query https://github.com/nayefahmad/SQL-experiments/blob/master/2018-10-19_lgh_hospitalist-census-by-tod-previous-query-copied-from-excel.sql

TODO: 
1. Hypothesis: I need to properly group the discharges before I can join on them in #t4

********************************************************************/

drop table if exists #datetimes
GO  
-- this GO statement ensures that the first thing SQL does is drop the table. This is necessary 
-- for the rest of the program to work

declare @startdate datetime = '2017-05-28 00:00:00.00' 
declare @horizon_in_minutes int = 1440  -- 4 weeks
declare @site varchar(50) = 'Richmond Hospital' 

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
				   where FacilityLongName = @site
						and CensusDate = @startdate
						-- todo: here you can add conditions for nursing unit, physician type, etc. 

				   group by CensusDate) 
where datetimes_col = @startdate 
--select * from #datetimes order by datetimes_col


-- add site column 
alter table #datetimes
add site varchar(25)

update #datetimes
set site = @site

-- select * from #datetimes order by datetimes_col


/********************************************************************************
Pull and group admits and discharges 
*********************************************************************************/
-- admits
drop table if exists #t2_admits_grouped
select AdjustedAdmissionDate
	, AdjustedAdmissionTime
	-- , (AdjustedAdmissionDate + AdjustedAdmissionTime) as admit_date_time
	, count(*) as num_admits
into #t2_admits_grouped
from ADTCMart.ADTC.AdmissionDischargeView 
where 1=1
	and AdmissionFacilityLongName = @site
	and AdjustedAdmissionDate = @startdate
group by AdjustedAdmissionDate
	, AdjustedAdmissionTime
order by AdjustedAdmissionDate
	, AdjustedAdmissionTime
-- select * from #t2_admits_grouped order by AdjustedAdmissionDate, AdjustedAdmissionTime

-- discharges
drop table if exists #t3_disch_grouped
select AdjustedDischargeDate
	, AdjustedDischargeTime
	, count(*) as num_disch
into #t3_disch_grouped
from ADTCMart.ADTC.AdmissionDischargeView 
where 1=1
	and DischargeFacilityLongName = @site
	and AdjustedDischargeDate = @startdate
group by AdjustedDischargeDate
	, AdjustedDischargeTime
order by AdjustedDischargeDate
	, AdjustedDischargeTime
-- select * from #t3_disch_grouped order by AdjustedDischargeDate, AdjustedDischargeTime


/********************************************************************************
Join datetimes table with admits and discharges 
*********************************************************************************/

drop table if exists #t4_admits_and_disch
select t1.datetimes_col
	, t1.site
	, t2.AdjustedAdmissionDate
	, t2.AdjustedAdmissionTime

	, t3.AdjustedDischargeDate
	, t3.AdjustedDischargeTime

	, t2.num_admits
	, t3.num_disch
	, t1.entry_count
	, t1.exit_count
into #t4_admits_and_disch
from #datetimes t1
	left join #t2_admits_grouped t2
	on t1.datetimes_col = (t2.AdjustedAdmissionDate + t2.AdjustedAdmissionTime) 

	left join #t3_disch_grouped t3
	on t1.datetimes_col = (t3.AdjustedDischargeDate + t3.AdjustedDischargeTime) 
-- select * from #t4_admits_and_disch order by datetimes_col

update #t4_admits_and_disch
set entry_count = isnull(entry_count, 0) + isnull(num_admits, 0)

update #t4_admits_and_disch
set exit_count = isnull(num_disch, 0) * -1

alter table #t4_admits_and_disch
add total_change int 

update #t4_admits_and_disch
set total_change = entry_count + exit_count

-- select * from #t4_admits_and_disch order by datetimes_col




-- use correlated subquery to find running total 
drop table if exists #t5_census_by_minute
select t4.datetimes_col
	, t4.site
	, t4.AdjustedAdmissionDate
	, t4.AdjustedAdmissionTime
	, t4.AdjustedDischargeDate
	, t4.AdjustedDischargeTime
	, t4.entry_count
	, t4.exit_count
	, t4.total_change
	, (select sum(total_change) 
		from #t4_admits_and_disch t4_2
		where t4_2.datetimes_col <= t4.datetimes_col
	) as census_minute_level

into #t5_census_by_minute
from #t4_admits_and_disch t4
order by datetimes_col

-- view: 
select * from #t5_census_by_minute order by datetimes_col


/*********************************************************************************
Validation with ADTC CensusView
*********************************************************************************/

-- ending figure from my calculation: 
select census_minute_level 
	, datetimes_col
from #t5_census_by_minute
where datetimes_col = (select max(datetimes_col) from #t5_census_by_minute)

-- check ending figure with census view figure: 
select count(PatientID) as census_from_ADTC
	, CensusDate
from ADTCMart.ADTC.CensusView
where FacilityLongName = @site
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

select sum(entry_count) - (select entry_count from #t5_census_by_minute where datetimes_col = @startdate)as [sum_entry_count]
	, sum(exit_count) as [sum_exit_count]
from #t5_census_by_minute
-- 114 discharges 

select count(*) as disch_from_adtc
from ADTCMart.ADTC.AdmissionDischargeView
where 1=1 
	and DischargeFacilityLongName = @site
	and AdjustedDischargeDate = @startdate 
-- 114 discharges 


------------------------------------------------------------------
-- Are we counting too many admits?? 
select count(*) as admit_from_adtc
from ADTCMart.ADTC.AdmissionDischargeView
where 1=1 
	and AdmissionFacilityLongName = @site
	and AdjustedAdmissionDate = @startdate 

-- disaggregated: 
--select PatientId
--	, AdjustedAdmissionDate
--	, AdjustedAdmissionTime
--from ADTCMart.ADTC.AdmissionDischargeView
--where 1=1 
--	and AdmissionFacilityLongName = @site
--	and AdjustedAdmissionDate = @startdate 
--order by AdjustedAdmissionDate, AdjustedAdmissionTime




