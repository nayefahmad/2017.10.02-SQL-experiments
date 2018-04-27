
------------------------------------
--FENCEPOST ERRORS 
------------------------------------

select datediff(day, '2018-01-1 23:59 PM', '2018-01-02 00:01 AM') 

/*
-- FROM tableau: IF DATEDIFF('day',[Start Date], TODAY()) < 1

*/


-------------------------------------------------
-- testing last 7 days 

-- if we run at '2018-01-10 11:59 PM', nothing before '2018-01-03 11:59 PM' should be included 
select case when datediff(day, '2018-01-03 09:00 AM', '2018-01-10 11:59 PM') <= 7 then 'included in range' else 'not included in range'  end; 
-- included in range
-- wrong: actually '2018-01-03 09:00 AM' shouldn't be included in range 

select case when datediff(hour, '2018-01-03 09:00 AM', '2018-01-10 11:59 PM') <= (7*24) then 'included in range' else 'not included in range'  end;
-- not included in range
-- this is right 

select case when datediff(hour, '2018-01-03 10:58 PM', '2018-01-10 11:59 PM') <= (7*24) then 'included in range' else 'not included in range'  end;
-- this is right 


-- what if we replace "<= 7" with "< 7"? --------------
-- if we run at '2018-01-10 02:00 PM', everything after '2018-01-03 02:00 PM' should be included 
select case when datediff(day, '2018-01-03 03:00 PM', '2018-01-10 02:00 PM') < 7 then 'included in range' else 'not included in range'  end; 
-- not included in range
-- this is wrong 

select case when datediff(day, '2018-01-03 03:00 PM', '2018-01-10 02:00 PM') <= (7*24) then 'included in range' else 'not included in range'  end; 
-- included in range
-- this is right 



