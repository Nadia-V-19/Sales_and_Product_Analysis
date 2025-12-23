# Identify the top 5 most revenue-generating products 
  
  -- I want to see if the product was sold more than once:
  Select ProductID
  FROM SalesOrderDetail;
  -- Result: 542 rows returned, and the next step is the group all of products

 Select ProductID
 FROM SalesOrderDetail
 GROUP BY ProductID;
 -- Result: 142 rows returned. I can see now that different orders might have the same item.

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

# Inventory stock analysis

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

-- Calculated the projected min reserve (safety stock). This was done by taking the total units sold for the year, dividing them by 12 months, and applying a safety stock factor of 1.5.

SELECT 
    p.Name AS ProductName, 
    ROUND(SUM(sod.LineTotal), 2) AS TotalRevenue,
    SUM(sod.OrderQty) AS TotalUnitsSold,
    ROUND(CAST(SUM(sod.OrderQty) AS FLOAT) / 12, 1) AS MonthlyAverageSales,
    ROUND((CAST(SUM(sod.OrderQty) AS FLOAT) / 12) * 1.5, 0) AS    RecommendedMinStock
FROM Product AS p
JOIN SalesOrderDetail AS sod ON p.ProductID = sod.ProductID
GROUP BY p.Name
ORDER BY TotalRevenue DESC
LIMIT 5;

# Customers analysis
	
-- Customer list with the total spent amount, how often they buy from us, and their average purchase amount.

SELECT 
 c.customerID, 
 c.FirstName || ' ' || c.LastName AS FullName,
 COUNT (soh.SalesOrderID) AS OrderCount, 
 ROUND (SUM(soh.TotalDue), 2) AS TotalSpent,
 ROUND (AVG(soh.TotalDue), 2) AS AverageTicket
FROM customer AS c
JOIN SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalSpent DESC;

-- Customer Segmentation: VIP, Loyal, Standart.

SELECT 
    c.FirstName || ' ' || c.LastName AS FullName,
    SUM(soh.TotalDue) AS TotalSpent,
    CASE 
        WHEN SUM(soh.TotalDue) > 50000 THEN 'VIP'
        WHEN SUM(soh.TotalDue) BETWEEN 10000 AND 50000 THEN 'Loyal'
        ELSE 'Standard'
    END AS CustomerSegment
FROM Customer AS c
JOIN SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalSpent DESC;

-- Identifying Region & City.

SELECT 
    a.CountryRegion,
    a.City,
    COUNT(soh.SalesOrderID) AS TotalOrders,
    ROUND(SUM(soh.TotalDue), 2) AS RegionRevenue,
    ROUND(AVG(soh.TotalDue), 2) AS AverageCheck
FROM SalesOrderHeader AS soh
JOIN Address AS a ON soh.ShipToAddressID = a.AddressID
GROUP BY a.CountryRegion, a.City
ORDER BY RegionRevenue DESC;

-- I would like to see where our clients are living.

SELECT 
    c.FirstName || ' ' || c.LastName AS FullName,
    a.City,
    a.CountryRegion,
    ROUND(SUM(soh.TotalDue), 2) AS TotalSpent,
    CASE 
        WHEN SUM(soh.TotalDue) > 50000 THEN 'VIP'
        WHEN SUM(soh.TotalDue) BETWEEN 10000 AND 50000 THEN 'Loyal'
        ELSE 'Standard'
    END AS Segment
FROM Customer AS c
JOIN SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
JOIN CustomerAddress AS ca ON c.CustomerID = ca.CustomerID
JOIN Address AS a ON ca.AddressID = a.AddressID
GROUP BY c.CustomerID, a.City, a.CountryRegion
ORDER BY TotalSpent DESC;

# Promotion Effectiveness
	
-- I want to see if VIP clients have a discount.

SELECT 
    c.FirstName || ' ' || c.LastName AS FullName,
    a.City,
    soh.SalesOrderID,
    ROUND(SUM(sod.OrderQty * sod.UnitPrice), 2) AS GrossAmount, 
    ROUND(SUM(sod.LineTotal), 2) AS NetAmount,             
    ROUND(SUM(sod.OrderQty * sod.UnitPrice) - SUM(sod.LineTotal), 2) AS DiscountMoney,
    ROUND(AVG(sod.UnitPriceDiscount) * 100, 1) AS AvgDiscountPercent 
FROM Customer AS c
JOIN SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
JOIN SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN CustomerAddress AS ca ON c.CustomerID = ca.CustomerID
JOIN Address AS a ON ca.AddressID = a.AddressID
WHERE c.LastName IN ('Liu', 'Grande', 'Kurtz', 'Laszlo', 'Chor')
   OR a.City IN ('London', 'Woolston')
GROUP BY soh.SalesOrderID
ORDER BY NetAmount DESC;

-- Kevin Liu discount looks like anomaly it is too big, will check on him.

SELECT
   SalesOrderID,
   UnitPrice,
   OrderQty,
   UnitPriceDiscount,
   (UnitPrice * OrderQty * UnitPriceDiscount) AS DiscountAmountPerLine
   FROM SalesOrderDetail
   WHERE SalesOrderID = 71783;

-- Recalculation of discount

SELECT 
    c.FirstName || ' ' || c.LastName AS FullName,
    a.City,
    soh.SalesOrderID,
    ROUND(SUM(sod.OrderQty * sod.UnitPrice), 2) AS GrossAmount, 
    ROUND(SUM(sod.LineTotal), 2) AS NetAmount,             
    ROUND(SUM(sod.OrderQty * sod.UnitPrice) - SUM(sod.LineTotal), 2) AS DiscountMoney,
    ROUND((SUM(sod.OrderQty * sod.UnitPrice) - SUM(sod.LineTotal)) / SUM(sod.OrderQty * sod.UnitPrice) * 100, 2) AS EffectiveDiscountPercent
FROM Customer AS c
JOIN SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
JOIN SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN CustomerAddress AS ca ON c.CustomerID = ca.CustomerID
JOIN Address AS a ON ca.AddressID = a.AddressID
WHERE c.LastName IN ('Liu', 'Grande', 'Kurtz', 'Laszlo', 'Chor')
   OR a.City IN ('London', 'Woolston')
GROUP BY soh.SalesOrderID
ORDER BY NetAmount DESC;















