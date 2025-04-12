USE db_mobilemanufacturer;

--1. List the states in which we have customers who have bought cellphones from 2005 till today.
SELECT DISTINCT L.State
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_LOCATION AS L
ON F.IDLocation = L.IDLocation
WHERE YEAR(F.Date) > 2004

--2. Which state in the US is buying the most Samsung cellphones?
SELECT TOP 1 L.State, COUNT(*) AS TOTAL_PURCHASES
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_LOCATION AS L
ON F.IDLocation = L.IDLocation
INNER JOIN DIM_MODEL AS M
ON F.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER AS MF
ON M.IDManufacturer = MF.IDManufacturer
WHERE L.Country = 'US' AND MF.Manufacturer_Name = 'Samsung'
GROUP BY L.State
ORDER BY TOTAL_PURCHASES DESC

--3. Show the number of transactions for each model per zip code per state.
SELECT M.Model_Name, L.ZipCode, L.State, COUNT(*) AS TOTAL_TRANSACTIONS
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_LOCATION AS L
ON F.IDLocation = L.IDLocation
INNER JOIN DIM_MODEL AS M
ON F.IDModel = M.IDModel
GROUP BY M.Model_Name, L.ZipCode, L.State

--4. Show the cheapest cellphone.
SELECT TOP 1 M.IDModel ,M.Model_Name, M.Unit_price 
FROM DIM_MODEL  AS M
ORDER BY M.Unit_price ASC


--5. Find out the average price for each model in the top 5 manufacturers in terms of 
--sales quantity and order by average price
WITH TOP_5_MANUFACTURERS
AS(
		SELECT TOP 5 MF.IDManufacturer, SUM(F.Quantity) AS SALES_QTY, AVG(F.TotalPrice) AS AVG_PRICE 
		FROM FACT_TRANSACTIONS AS F
		INNER JOIN DIM_MODEL AS M
		ON F.IDModel = M.IDModel
		INNER JOIN DIM_MANUFACTURER AS MF
		ON M.IDManufacturer = MF.IDManufacturer
		GROUP BY MF.IDManufacturer
		ORDER BY SALES_QTY DESC,AVG_PRICE ASC
)
SELECT MF.Manufacturer_Name, M.Model_Name, AVG(F.TotalPrice) AS AVG_PRICE
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M
ON F.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER AS MF ON M.IDManufacturer = MF.IDManufacturer
WHERE M.IDManufacturer IN (SELECT IDManufacturer FROM TOP_5_MANUFACTURERS)
GROUP BY MF.Manufacturer_Name, M.Model_Name

--6. List the names of the customers and the average amount spent in 2009, where the average is higher than 500.
SELECT C.Customer_Name, AVG(F.TotalPrice) AS AVERAGE_AMOUNT
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_CUSTOMER AS C
ON F.IDCustomer = C.IDCustomer
WHERE YEAR(F.Date) = 2009
GROUP BY C.Customer_Name
HAVING AVG(F.TotalPrice) > 500

--7. List if there is any model that was in the top 5 in terms of quantity, simultaneously
-- in 2008, 2009 and 2019
SELECT T.Model_Name
FROM(
SELECT TOP 5 M.Model_Name,SUM(F.Quantity) AS TOTAL_QTY
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
INNER JOIN DIM_DATE AS D	ON F.Date = D.DATE
WHERE D.YEAR = 2008
GROUP BY M.Model_Name
ORDER BY TOTAL_QTY DESC

UNION ALL

SELECT TOP 5 M.Model_Name,SUM(F.Quantity) AS TOTAL_QTY
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
INNER JOIN DIM_DATE AS D ON F.Date = D.DATE
WHERE D.YEAR = 2009
GROUP BY M.Model_Name
ORDER BY TOTAL_QTY DESC

UNION ALL

SELECT TOP 5 M.Model_Name,SUM(F.Quantity) AS TOTAL_QTY
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
INNER JOIN DIM_DATE AS D ON F.Date = D.DATE
WHERE D.YEAR = 2010
GROUP BY M.Model_Name
ORDER BY TOTAL_QTY DESC
) AS T
GROUP BY T.Model_Name
HAVING COUNT(*) = 3

--8. Show the manufacturers with the 2nd top sales in the year 2009 and the manufacturer with the second
--top sales in year 2010
SELECT T.Manufacturer_Name,T.YEAR_,T.TOTAL_SALES
FROM (
	SELECT MF.Manufacturer_Name,YEAR(F.Date) AS YEAR_ ,SUM(F.TotalPrice) AS TOTAL_SALES
	FROM FACT_TRANSACTIONS AS F
	INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
	INNER JOIN DIM_MANUFACTURER AS MF ON M.IDManufacturer = MF.IDManufacturer
	WHERE YEAR(F.Date) = 2009
	GROUP BY MF.Manufacturer_Name,YEAR(F.Date)
	ORDER BY TOTAL_SALES DESC
	OFFSET 1 ROWS
	FETCH NEXT 1 ROWS ONLY

	UNION ALL

	SELECT MF.Manufacturer_Name, YEAR(F.Date) AS YEAR_,SUM(F.TotalPrice) AS TOTAL_SALES
	FROM FACT_TRANSACTIONS AS F
	INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
	INNER JOIN DIM_MANUFACTURER AS MF ON M.IDManufacturer = MF.IDManufacturer
	WHERE YEAR(F.Date) = 2010
	GROUP BY MF.Manufacturer_Name,YEAR(F.Date)
	ORDER BY TOTAL_SALES DESC
	OFFSET 1 ROWS
	FETCH NEXT 1 ROWS ONLY
) AS T

--9. Show the manufacturers who sold cellphones in 2010 but did not in 2009
SELECT MF.IDManufacturer, MF.Manufacturer_Name
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER AS MF ON M.IDManufacturer = MF.IDManufacturer
WHERE YEAR(F.Date) = 2010
EXCEPT
SELECT MF.IDManufacturer, MF.Manufacturer_Name
FROM FACT_TRANSACTIONS AS F
INNER JOIN DIM_MODEL AS M ON F.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER AS MF ON M.IDManufacturer = MF.IDManufacturer
WHERE YEAR(F.Date) = 2009

--10. Find top 10 customers and their average spend, average quantity by each year.
--Also find the percentage of change in their spend.

WITH TOP10CUSTOMERS
AS(
	SELECT TOP 10 F.IDCustomer
	FROM FACT_TRANSACTIONS AS F
	GROUP BY F.IDCustomer
	ORDER BY SUM(F.TotalPrice) DESC
),
CUSTOMER_YEARLY_SPEND
AS(
	SELECT F.IDCustomer,
	YEAR(F.Date) AS YEAR_,
	AVG(F.TotalPrice) AS AVG_SPEND,
	AVG(F.Quantity) AS AVG_QTY
	FROM FACT_TRANSACTIONS AS F
	INNER JOIN DIM_CUSTOMER AS C ON F.IDCustomer = C.IDCustomer
	WHERE F.IDCustomer IN (SELECT IDCustomer FROM TOP10CUSTOMERS)
	GROUP BY F.IDCustomer, YEAR(F.Date)
)
SELECT *,
((C.AVG_SPEND - LAG(C.AVG_SPEND,1) OVER(PARTITION BY C.IDCUSTOMER ORDER BY C.YEAR_))/
LAG(C.AVG_SPEND,1) OVER(PARTITION BY C.IDCUSTOMER ORDER BY C.YEAR_))*100 AS PERCENTAGE_CHANGE
FROM CUSTOMER_YEARLY_SPEND AS C

	