
drop table if exists #datetimes
GO  
-- this GO statement ensures that the first thing SQL does is drop the table. This is necessary 
-- for the rest of the program to work

declare @startdate datetime = '2019-01-01 00:00:00.00' 

-- create table with a column of datetimes 
drop table if exists #datetimes
create table #datetimes (datetimes_col datetime) 

insert into #datetimes values 
	(@startdate) 

-- select * from #datetimes


-- use while loop to populate the table 
declare @counter int = 1 

while @counter <= 1440
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
					and CensusDate = '2019-01-01'
				   group by CensusDate) 
where datetimes_col = '2019-01-01 00:00:00.000' 

select * from #datetimes order by datetimes_col



-- now join on ADTC.admissiondischarge: 
drop table if exists #t4_add_admits_discharges; 
select t1.datetimes_col
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
	left join ADTCMart.ADTC.AdmissionDischargeView t3_ad
		on t1.datetimes_col = (t3_ad.AdjustedDischargeDate + t3_ad.AdjustedDischargeTime)
order by t1.datetimes_col




select * 
	, (isnull(count_admits, 0) - isnull(count_discharges, 0)) as net_change 
from (
	select * 
	, case when AdjustedAdmissionDate is not null then 1 end as count_admits
	, case when AdjustedDischargeDate is not null then 1 end as count_discharges

	from #t4_add_admits_discharges 
) as sub1
order by datetimes_col
 



 
