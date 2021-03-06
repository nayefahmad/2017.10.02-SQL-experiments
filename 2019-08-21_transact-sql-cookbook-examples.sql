

/*----------------------------------------------------------------------
Finding the Top N Values in a Set
Example from 'Transact SQL Cookbook' 
2019-08-21
Nayef 

Let's say your grade will be based only on your top 2 term papers. 
Write a query that pulls top 2 scores for each student 

*/----------------------------------------------------------------------


DROP TABLE if exists #Students
GO
CREATE TABLE #Students (
   CourseId CHAR(20),
   StudentName CHAR(40),
   Score DECIMAL(4,2),
   TermPaper INTEGER
)
GO

INSERT INTO #Students VALUES('ACCN101','Andrew',15.60,4)
INSERT INTO #Students VALUES('ACCN101','Andrew',10.40,2)
INSERT INTO #Students VALUES('ACCN101','Andrew',11.00,3)
INSERT INTO #Students VALUES('ACCN101','Bert',13.40,1)
INSERT INTO #Students VALUES('ACCN101','Bert',11.20,2)
INSERT INTO #Students VALUES('ACCN101','Bert',13.00,3)
INSERT INTO #Students VALUES('ACCN101','Cindy',12.10,1)
INSERT INTO #Students VALUES('ACCN101','Cindy',16.20,2)
INSERT INTO #Students VALUES('MGMT120','Andrew',20.20,1)
INSERT INTO #Students VALUES('MGMT120','Andrew',21.70,2)
INSERT INTO #Students VALUES('MGMT120','Andrew',23.10,3)
INSERT INTO #Students VALUES('MGMT120','Cindy',12.10,1)
INSERT INTO #Students VALUES('MGMT120','Cindy',14.40,2)
INSERT INTO #Students VALUES('MGMT120','Cindy',16.00,3)
GO

select * from #Students



/*------------------------------------------------------------
Solution 1:
This uses operators specific to TSQL 

Note that this is a correlated sub-query - i.e. one that won't run on its 
own, because it's dependent on the outer query.

The benefit of correlated sub-queries is that they allow you do take each 
row of the outer query, and check it against the results of another query 

Here, we take each {student, course, termpaper, max(score)} row from the 
outer query, and we compare it with the list of 2 rows of {score} in the 
inner query. 

Only if the score in the outer query matches with one of the top 2 will it
be returned


*/------------------------------------------------------------

SELECT  s1.StudentName, s1.CourseId, s1.TermPaper, s1.Score 
FROM #Students s1
where s1.score IN (
	
	-- correlated sub-query: for each row in outer query, check 
	-- against a list produced by the sub-query below. 
	
	-- If the score in outer query row is not in the list returned
	-- by the sub-query, then that row is deleted from the outer 
	-- query 
	SELECT TOP 2 s2.Score 
    FROM #Students s2  -- note that the sub-query is from the same table as the outer query 
    WHERE s2.CourseId = s1.CourseId AND    -- think of replacing the reference to s1.CourseID with the value of courseID in the current row of the outer query that is under consideration
          s2.StudentName = s1.StudentName
	order by s2.Score desc)
order by s1.StudentName, s1.CourseId, s1.TermPaper







/*------------------------------------------------------------
Solution 2:
This is more general across diff versions of SQL 
*/------------------------------------------------------------

SELECT s1.StudentName, s1.CourseId, s1.TermPaper, MAX(s1.Score) Score
FROM #Students s1 INNER JOIN #Students s2
   ON s1.CourseId=s2.CourseId AND
      s1.StudentName=s2.StudentName
GROUP BY s1.CourseId, s1.StudentName, s1.TermPaper
HAVING SUM(CASE WHEN s1.Score <= s2.Score THEN 1 END) <= 2
ORDER BY s1.StudentName, s1.CourseId, Score DESC

-- Recall that the logical order of SQL clauses is: from, where, groupby, having, select 

-- That's why the MAX( ) in the SELECT clause only operates on the top 2 scores, 
-- instead of all scores. 


-- Let's take a closer look at what that self-join does, without aggregating: 
select * from #Students order by StudentName, CourseId, TermPaper; 

select s1.StudentName as s1_name
	, s1.CourseId as s1_course
	, s1.TermPaper as s1_paper
	, s1.Score as s1_score
	
	, s2.StudentName as s2_name
	, s2.CourseId as s2_course
	, s2.TermPaper as s2_paper
	, s2.Score as s2_score 

FROM #Students s1 INNER JOIN #Students s2
   ON s1.CourseId=s2.CourseId AND
      s1.StudentName=s2.StudentName
order by s1_name, s1_course, s1_paper
	, s2_name, s2_course, s2_paper

-- Note that the inner self-join is like a cross-join within groups defined 
-- by the join conditions. E.g. Cross join within Course/Student_Name groups 

-- Here's what the cross self-join does: 
/*
select s1.*, s2.* 
from #Students s1 
cross join #Students s2
order by s1.StudentName, s1.CourseId, s1.TermPaper
	, s2.StudentName, s2.CourseId, s2.TermPaper
*/