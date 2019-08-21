

/*----------------------------------------------------------------------
EXAMPLES FROM TRANSACT-SQL COOKBOOK 
2019-08-21
Nayef 
*/----------------------------------------------------------------------


-- Finding the Top N Values in a Set
--
-- Chapter 2 - Sets
-- Type of content: objects
-- Date: 2002-1-7
-- Version: 1.0
--
-- Authors: Ales Spetic, Jonathan Gennick

DROP TABLE if exists #Students
GO
CREATE TABLE #Students (
   CourseId CHAR(20),
   StudentName CHAR(40),
   Score DECIMAL(4,2),
   TermPaper INTEGER
)
GO

INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Andrew',15.60,4)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Andrew',10.40,2)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Andrew',11.00,3)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Bert',13.40,1)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Bert',11.20,2)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Bert',13.00,3)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Cindy',12.10,1)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('ACCN101','Cindy',16.20,2)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Andrew',20.20,1)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Andrew',21.70,2)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Andrew',23.10,3)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Cindy',12.10,1)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Cindy',14.40,2)
INSERT INTO #Students(CourseId,StudentName,Score, TermPaper) VALUES('MGMT120','Cindy',16.00,3)
GO



SELECT  s1.StudentName, s1.CourseId, s1.TermPaper, MAX(s1.Score) Score
FROM Students s1
GROUP BY s1.CourseId, s1.StudentName, s1.TermPaper
HAVING MAX(s1.Score) IN 
   (SELECT TOP 2 s2.Score 
       FROM Students s2
       WHERE s1.CourseId=s2.CourseId AND
          s1.StudentName=s2.StudentName
    ORDER BY s2.Score DESC)
ORDER BY s1.StudentName, s1.CourseId, s1.Score DESC


SELECT  s1.StudentName,s1.CourseId, s1.TermPaper, MAX(s1.Score) Score
FROM Students s1 INNER JOIN Students s2
   ON s1.CourseId=s2.CourseId AND
      s1.StudentName=s2.StudentName
GROUP BY s1.CourseId, s1.StudentName, s1.TermPaper
HAVING SUM(CASE WHEN s1.Score <= s2.Score THEN 1 END) <= 2
ORDER BY s1.StudentName, s1.CourseId, s1.Score DESC



