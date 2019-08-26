
drop table if exists #datetimes
GO  
-- this GO statement ensures that the first thing SQL does is drop the table. This is necessary 
-- for the rest of the program to work

declare @startdate datetime = '2018-04-28 00:00:00.00' 
declare @horizon_in_minutes int = 525600  -- 4 weeks

-- create table with a column of datetimes 
drop table if exists #datetimes
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



-- add census at midnight as the first entry 
alter table #datetimes
add entry_count int, exit_count int


update #datetimes
set entry_count = (select count(*) 
				   from ADTCMart.ADTC.CensusView
				   where FacilityLongName = 'Richmond HOspital' 
					and CensusDate = @startdate
				   group by CensusDate) 
where datetimes_col = @startdate 


-- add site 
alter table #datetimes
add site varchar(25)

update #datetimes
set site = 'Richmond Hospital' 


-- select * from #datetimes order by datetimes_col



-- now join on ADTC.admissiondischarge: 
drop table if exists #t4_add_admits_discharges; 
select t1.datetimes_col
	, t1.site
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




update #t4_add_admits_discharges
set entry_count = 1 
where AdjustedAdmissionDate is not null 

update #t4_add_admits_discharges
set exit_count = -1
where AdjustedDischargeDate is not null 

 
-- select * from #t4_add_admits_discharges order by datetimes_col
drop table if exists #t5_add_net_changes
select *
	, (isnull(entry_count, 0) + isnull(exit_count, 0)) as net_change
into #t5_add_net_changes
from #t4_add_admits_discharges
order by datetimes_col

 
-- select * from #t5_add_net_changes order by datetimes_col




-- use correlated subquery to find running total 
select t5_1.*
	, (
	select sum(net_change) 
	from #t5_add_net_changes t5_2
	where t5_2.datetimes_col <= t5_1.datetimes_col
	) as census_minute_level

from #t5_add_net_changes t5_1
order by datetimes_col

