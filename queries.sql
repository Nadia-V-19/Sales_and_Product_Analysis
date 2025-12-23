# Identify the top 5 most revenue-generating products 
  
  -- I want to see if the product was sold more than once:
  Select ProductID
  FROM SalesOrderDetail;
  -- Result: 542 rows returned, and next group all products

 Select ProductID
 FROM SalesOrderDetail
 GROUP BY ProductID;
 -- Result: 142 rows returned, I can see now that different orders might have the same item.

 -- Group product, round amount, and sum amount for a list of 5 products, and change the column names.

SELECT 
    p.Name AS ProductName, 
	  p.ProductNumber AS SKU,
    ROUND(SUM(sod.LineTotal), 2) AS TotalRevenue
FROM Product AS p
JOIN SalesOrderDetail AS sod ON p.ProductID = sod.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC
LIMIT 5;

-- Count how many items were sold.

SELECT 
    p.Name AS ProductName, 
	p.ProductNumber AS SKU,
	ROUND(SUM(sod.LineTotal), 2) AS TotalRevenue,
	SUM(sod.OrderQTY) AS TotalUnitsSold
FROM Product AS p
JOIN SalesOrderDetail AS sod ON p.ProductID = sod.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC
LIMIT 5;

-- 


