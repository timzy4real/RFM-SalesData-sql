
---SELECTING DATABASE
USE Portfolio;

---INSPECTING DATA
SELECT *
FROM sales_data_sample;

---CHECKING UNIQUE VALUES
SELECT DISTINCT status
FROM sales_data_sample; ---Nice to plot
SELECT DISTINCT year_id
FROM sales_data_sample;
SELECT DISTINCT productline
FROM sales_data_sample; ---Nice to plot
SELECT DISTINCT country
FROM sales_data_sample; ---Nice to plot
SELECT DISTINCT dealsize
FROM sales_data_sample; ---Nice to plot
SELECT DISTINCT territory
FROM sales_data_sample; ---Nice to plot

---ANALYSIS
---Let's start by grouping sales by productline to see which product sells the most
SELECT productline, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY productline
ORDER BY 2 DESC;

SELECT year_id, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY year_id
ORDER BY 2 DESC; ---2005 was the lowest period for sales

SELECT DISTINCT month_id
FROM sales_data_sample
WHERE year_id =2005; ---They operated 5months in 2005, reason why they made low sales

SELECT dealsize, SUM(sales) Revenue
FROM sales_data_sample
GROUP BY dealsize
ORDER BY 2 DESC;

---What was the best month for sales in a specific year? How much was earned that month?
SELECT month_id, SUM(sales) Revenue, COUNT(ordernumber) Frequency
FROM sales_data_sample
WHERE year_id = 2004 ---Change year to see the rest
GROUP BY month_id
ORDER BY 2 DESC;

---November seems to be the month, what product do they sell in November, Classic Cars I believe
 

---Who is the best Customer (this could be best answered with REF(Recency-Frequency-Monetary))
---RFM Analysis is an indexing technique that uses past purchase behavior to segment customers using 3 metrics (Recency-Frequency-Monetary)
---RECENCY - last order date
---FREQUENCY - count of total orders
---MONETARY VALUE - total spend
SELECT
customername,
    SUM(sales) MonetaryValue,
    AVG(sales) AvgMonetaryValue,
    COUNT(ordernumber) Frequency,
    MAX(orderdate) last_order_date,---last order date from the customers
    (SELECT MAX(orderdate) FROM sales_data_sample) Max_order_date,---max date in the entire data set
	DATEDIFF(DAY, MAX(orderdate), (SELECT MAX(orderdate) FROM sales_data_sample)) Recency
FROM sales_data_sample
GROUP BY customername;


DROP TABLE IF EXISTS #RFM
WITH RFM AS
(
	SELECT
	Customername,
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ordernumber) Frequency,
		MAX(orderdate) last_order_date,---last order date from the customers
		(SELECT MAX(orderdate) FROM sales_data_sample) Max_order_date,---max date in the entire data set
	DATEDIFF(DAY, MAX(orderdate), (SELECT MAX(orderdate) FROM sales_data_sample)) Recency
	FROM sales_data_sample
	GROUP BY customername
),
RFM_Calc AS  
(
	SELECT r.*,
		NTILE(4) OVER(ORDER BY Recency DESC) RFM_Recency,
		NTILE(4) OVER(ORDER BY Frequency) RFM_Frequency,
		NTILE(4) OVER(ORDER BY MonetaryValue) RFM_Monetary
	FROM RFM AS r
)
SELECT 
	c.*, RFM_Recency + RFM_Frequency + RFM_Monetary AS RFM_Cell, ---concatination
	CAST(RFM_Recency AS VARCHAR) + CAST(RFM_Frequency AS VARCHAR) + CAST(RFM_Monetary AS VARCHAR) AS RFM_Cell_String ---casting concatination as string
INTO #RFM ---to ease ur burden from running this script all the time create a Temp Table
FROM RFM_Calc AS c

SELECT *
FROM #RFM

---now we will do a segmentation using CASE STATEMENT
SELECT CUSTOMERNAME, RFM_Recency, RFM_Frequency, RFM_Monetary,
	CASE
		WHEN RFM_Cell_String IN (111,122,121,122,123,132,211,114,141) THEN 'Lost Customers' ---lost customers
		WHEN RFM_Cell_String IN (133,134,143,244,334,343,344,144) THEN 'Slipping away, cannot lose' ---(big spenders who haven't purchased lately) slipping away
		WHEN RFM_Cell_String IN (311,411,331) THEN 'New Customers'
		WHEN RFM_Cell_String IN (222,223,233,322) THEN 'Potential Churners'
		WHEN RFM_Cell_String IN (323,333,321,422,332,432) THEN 'Active' ---(customers who buy often & recently, but at low price points)
		WHEN RFM_Cell_String IN (433,434,443,444) THEN 'Loyal'
	END RFM_Segment

FROM #RFM


---what product are most often sold together?
---we will be doing lots of SUB-QUERIES
---we will convert rows to columns
SELECT DISTINCT OrderNumber, STUFF(

	(SELECT ',' + PRODUCTCODE --- SUB_QUERY (2)	to see the product code we'll do another
	FROM sales_data_sample p
	WHERE OrderNumber IN
		(
			SELECT OrderNumber	---SUB-QUERY (1)
			FROM (
				SELECT OrderNumber, COUNT(*) rn
				FROM sales_data_sample 
				WHERE STATUS = 'Shipped'
				GROUP BY OrderNumber
			) m
			WHERE rn = 2
		)
		AND p.OrderNumber = s.OrderNumber
		FOR XML PATH(''))

		,1,1, '') ProductCodes

FROM sales_data_sample s
ORDER BY 2 DESC

---The above analysis is good for ADVERT or CAMPAIGN
