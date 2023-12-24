-- 0.0
SELECT firstName, lastName, title
FROM employee
LIMIT 5;

-- 1.1 get employee and manager name
SELECT emp.firstName, emp.lastName, emp.title,
mng.firstName, mng.lastName
FROM employee emp
INNER JOIN employee mng
ON emp.managerId = mng.employeeId

-- 1.2 get employee sales person who had no sales
SELECT emp.firstName, emp.lastName
FROM employee emp
LEFT JOIN sales sls 
    ON emp.employeeId = sls.employeeId
WHERE emp.title = 'Sales Person' 
AND sls.salesId IS NULL;

-- 1.3 get cust and sales all incld missing data (sqlite cannot outer join)
SELECT cst.customerId, cst.firstName, cst.lastName, sls.salesId, sls.salesAmount
FROM customer cst
INNER JOIN sales sls
ON cst.customerId = sls.customerId
UNION
SELECT cst.customerId, cst.firstName, cst.lastName, sls.salesId, sls.salesAmount
FROM customer cst
LEFT JOIN sales sls
ON cst.customerId = sls.customerId
WHERE sls.salesId ISNULL
UNION
SELECT cst.customerId, cst.firstName, cst.lastName, sls.salesId, sls.salesAmount
FROM sales sls
LEFT JOIN customer cst
ON sls.customerId = cst.customerId
WHERE cst.customerId ISNULL

-- 2.1 cars sold per employee
SELECT emp.firstName, emp.lastName, emp.title, COUNT (*) as NumOfCars
FROM sales sls
INNER JOIN employee emp ON sls.employeeId = emp.employeeId
GROUP BY emp.employeeId
ORDER BY NumOfCars DESC

-- 2.2 find most and least expensive per employee
SELECT emp.firstName, emp.lastName, emp.title, MAX(sls.salesAmount) as MaxPrice, MIN(sls.salesAmount) as MinPrice
FROM sales sls
INNER JOIN employee emp ON sls.employeeId = emp.employeeId
WHERE sls.soldDate >= date('now','start of year')
GROUP BY emp.employeeId

-- 2.3 employee that sold more than 5 cars this year
SELECT emp.firstName, emp.lastName, emp.title, COUNT (*) as NumOfCars
FROM sales sls
INNER JOIN employee emp ON sls.employeeId = emp.employeeId
WHERE sls.soldDate >= date('now','start of year')
GROUP BY emp.employeeId
HAVING NumOfCars >= 5
ORDER BY NumOfCars DESC

-- 3.1 summarise sales per year
SELECT strftime('%Y', sls.soldDate) as SoldYear, SUM(sls.salesAmount) as AnnualSales
FROM sales sls
GROUP BY SoldYear

-- 3.1 using CTE
WITH cte AS (
SELECT strftime('%Y', soldDate) AS soldYear, 
  salesAmount
FROM sales
)
SELECT soldYear, 
  FORMAT("$%.2f", sum(salesAmount)) AS AnnualSales
FROM cte
GROUP BY soldYear
ORDER BY soldYear

-- 3.2 sales by employee by month in 2021
SELECT emp.firstName AS FirstName, emp.lastName AS LastName, 
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '01'
    THEN sls.salesAmount END) as JanSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '02'
    THEN sls.salesAmount END) as FebSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '03'
    THEN sls.salesAmount END) as MarSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '04'
    THEN sls.salesAmount END) as AprSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '05'
    THEN sls.salesAmount END) as MaySales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '06'
    THEN sls.salesAmount END) as JunSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '07'
    THEN sls.salesAmount END) as JulSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '08'
    THEN sls.salesAmount END) as AugSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '09'
    THEN sls.salesAmount END) as SepSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '10'
    THEN sls.salesAmount END) as OctSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '11'
    THEN sls.salesAmount END) as NovSales,
SUM(CASE 
    WHEN strftime('%m', sls.soldDate) = '12'
    THEN sls.salesAmount END) as DecSales
FROM sales sls
INNER JOIN employee emp ON sls.employeeID = emp.employeeID
WHERE sls.soldDate >= '2021-01-01' AND sls.soldDate < '2022-01-01'
GROUP BY emp.employeeID

-- 3.3 sales of electric cars
SELECT *
FROM model

SELECT sls.salesId, sls.inventoryId, sls.salesAmount
FROM sales sls
INNER JOIN inventory inv ON sls.inventoryId = inv.inventoryId
WHERE inv.inventoryId IN (
SELECT inv.inventoryId
FROM inventory inv
INNER JOIN model mdl ON inv.modelId = mdl.modelId
WHERE mdl.EngineType = 'Electric')

-- 4.1 for each SalesPerson, rank cars model sold the most
SELECT emp.firstName, emp.lastName, mdl.model, 
count(sls.salesId) as NumOfCars,
rank() OVER (PARTITION BY sls.employeeId ORDER BY count(sls.salesId) DESC) as RANK
FROM employee emp
INNER JOIN sales sls ON emp.employeeId = sls.employeeId
INNER JOIN inventory inv ON sls.inventoryId = inv.inventoryId
INNER JOIN model mdl ON mdl.modelId = inv.modelId
GROUP BY emp.firstName, emp.lastName, mdl.model

-- 4.2 sales per month and annual running total
SELECT strftime('%Y', sls.soldDate) as SoldYear, strftime('%m', sls.soldDate) as SoldMonth, sum(sls.salesAmount) as AmountSales
FROM sales sls
GROUP BY SoldYear, SoldMonth
ORDER BY SoldYear, SoldMonth

WITH cte_sales AS (
SELECT strftime('%Y', sls.soldDate) as SoldYear, strftime('%m', sls.soldDate) as SoldMonth, sum(sls.salesAmount) as AmountSales
FROM sales sls
GROUP BY SoldYear, SoldMonth
)
SELECT SoldYear, SoldMonth, AmountSales,
SUM(AmountSales) OVER (PARTITION BY SoldYear ORDER BY SoldYear, SoldMonth) AS AnnualRunningSales
FROM cte_sales
ORDER BY SoldYear,SoldMonth

-- 4.3 numbers of cars sold this month and lastmonth
SELECT strftime('%Y-%m', sls.soldDate) AS monthYear, 
count(sls.salesId) as NumberOfCars,
LAG (count(*),1,0) OVER calMonth as LastMonthSales
FROM sales sls
GROUP BY monthYear
WINDOW calMonth AS (ORDER BY strftime('%Y-%m', sls.soldDate))
ORDER BY monthYear



