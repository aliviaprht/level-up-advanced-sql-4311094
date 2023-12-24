-- try lead and lag
SELECT DISTINCT sls.soldDate AS date, 
count(sls.salesId) AS NumOfCars,
LAG (count(*),1,0) OVER calDate as PrevDaySales,
LEAD(count(*),1,0) OVER calDate as NextDaySales
FROM sales sls
GROUP BY sls.soldDate
WINDOW calDate AS (ORDER BY sls.soldDate)
ORDER BY sls.soldDate ASC

-- Get next sales date
SELECT sls.employeeId, sls.soldDate,
LEAD (sls.soldDate) OVER (PARTITION BY sls.employeeId ORDER BY sls.soldDate) AS nextSalesDate
FROM sales sls

-- find date different
WITH NextDay AS (
SELECT sls.employeeId, sls.soldDate,
LEAD (sls.soldDate) OVER (PARTITION BY sls.employeeId ORDER BY sls.soldDate) AS nextSalesDate
FROM sales sls
)
SELECT employeeId, soldDate, nextSalesDate,
JULIANDAY(nextSalesDate) - JULIANDAY(soldDate) AS dateDifferent
FROM NextDay
WHERE dateDifferent = 1

-- Count Streaks *salah nii*
WITH NextDay AS (
SELECT sls.employeeId, sls.soldDate,
LEAD (sls.soldDate) OVER (PARTITION BY sls.employeeId ORDER BY sls.soldDate) AS nextSalesDate
FROM sales sls
)
SELECT employeeId, soldDate,
count(*) OVER(PARTITION BY employeeId, soldDate) AS streak
FROM NextDay
WHERE JULIANDAY(nextSalesDate) - JULIANDAY(soldDate) = 1
GROUP BY employeeId

-- try other -- nah ini bener
WITH get_flag AS (
SELECT employeeId, soldDate,
CASE WHEN DATETIME(soldDate, '-1 days') = LAG(soldDate) OVER (PARTITION BY employeeID ORDER BY soldDate) THEN 0 ELSE 1 END AS running_flag
FROM sales
), get_streak AS (
SELECT employeeId, soldDate, running_flag, 
SUM(running_flag) OVER (PARTITION BY employeeId ORDER BY soldDate) AS streaks
FROM get_flag
GROUP BY employeeId, soldDate
), count_streaks AS (
SELECT employeeId, streaks, count(*) AS continue_streaks
FROM get_streak
GROUP BY employeeId, streaks
)
SELECT employeeId, MAX(continue_streaks) as max_streak
FROM count_streaks
GROUP BY employeeId
HAVING max_streak > 1


SELECT employeeId, soldDate,
CASE WHEN DATETIME(soldDate, '-1 days') = LAG(soldDate) OVER (PARTITION BY employeeID ORDER BY soldDate) THEN 0 ELSE 1 END AS running_flag
FROM sales
WHERE employeeId = 33
