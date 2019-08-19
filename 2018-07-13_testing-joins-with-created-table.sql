
if object_id ('tempdb.dbo.#t1') is not null drop table #t1;
if object_id ('tempdb.dbo.#t2') is not null drop table #t2;

create table #t1 (id int
				  , named varchar(25)); 
insert into #t1 
values  ('1', 'alice'), 
		('4', 'bob'); 


select * from #t1; 



create table #t2 (id int)
insert into #t2
values ('1'), ('2'), ('3'), ('4'), ('5'); 

select * from #t2; 

------------------------------------------------------------
-- joins
------------------------------------------------------------
select #t1.id
	, #t1.named
	, #t2.id
from #t1
right join #t2 
	on #t1.id = #t2.id


select #t1.id
	, #t1.named
	, #t2.id
from #t1
left join #t2 
	on #t1.id = #t2.id