USE Northwind
SELECT name FROM master.dbo.sysdatabases

SELECT * 
FROM OrderItem;
SELECT * 
FROM [Order];
SELECT * 
FROM Customer;
SELECT * FROM Product;

-- Sắp xếp bảng tăng dần theo Unit Price và 20% dòng có Unit prcie cao nhất
SELECT * 
FROM
(
	SELECT RowNum, Id, OrderId, ProductId, UnitPrice, Quantity, 
	MAX(RowNum) OVER (ORDER BY (SELECT 1)) AS RowLast
	FROM (
			SELECT ROW_NUMBER() OVER (ORDER BY UnitPrice) AS RowNum,
			Id, OrderId, ProductId, UnitPrice, Quantity
			FROM OrderItem
	) AS DerivedTable
) Report
WHERE Report.RowNum >= 0.2*RowLast

-- Xuất danh sách các hóa đơn có phần trăm của sản phẩm
SELECT Id, OrderId, ProductId, UnitPrice, Quantity, STR([Percent]*100,5,2) + '%' AS [Percent]
FROM(
			SELECT Id, OrderId, ProductId, UnitPrice, Quantity,
			CONVERT(decimal,Quantity)/(SUM(Quantity) OVER (PARTITION BY OrderId)) AS [Percent]
			FROM OrderItem
	) AS Report
ORDER BY OrderId, [Percent]

-- Xuất danh sách cách nhà cung cấp
IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES
			WHERE TABLE_NAME = 'CountryOfCompany')
BEGIN
	DROP TABLE CountryOfCompany
END;

SELECT CompanyName, (CASE Country
WHEN 'USA' THEN 'USA'
WHEN 'UK' THEN 'UK'
WHEN 'France' THEN 'France'
WHEN 'Germany' THEN 'Germany'
ELSE 'Others'
END ) AS Country, Id, CONVERT(int, '1') AS TRUE INTO CountryOfCompany
FROM Supplier

SELECT Id, CompanyName,
ISNULL([USA], 0) AS 'USA',
ISNULL([UK], 0) AS 'UK',
ISNULL([France], 0) AS 'France',
ISNULL([Germany], 0) AS 'Germany',
ISNULL([Others], 0) AS 'Others'
FROM CountryOfCompany
PIVOT (SUM(TRUE) FOR Country IN ([USA], [UK],[France],[Germany],[Others])) AS PivotCountry

-- Xuất danh sách các hóa đơn theo form mẫu
SELECT O.Id, O.OrderNumber,
		OrderDate = CONVERT(varchar(10), O.OrderDate, 103),
		CustomerName = C.FirstName + SPACE(1) + C.Lastname,
		[Address] = 'Phone: ' + C.Phone + ', City: ' + C.City +	' and Country: ' + C.Country,
		Amount = LTRIM(STR(CAST(O.TotalAmount AS decimal(10,0)),10,0) + ' Euro')
FROM [Order] AS O
INNER JOIN Customer C ON O.CustomerId = C.Id

-- Xuất danh sách sản phẩm dưới dạng đóng gói bag
SELECT Id, ProductName, SupplierId, UnitPrice,
		Package = STUFF(Package, CHARINDEX('bags', Package), LEN('bags'), N'túi')
FROM Product
WHERE Package LIKE '%bags%'

-- Xuất danh sách các khách hàng theo tổng số hóa đơn
SELECT CustomerId = Report.Id,
		CustomerName = Report.FirstName + SPACE(1) + Report.LastName,
		OverallOrder = Report.OverallOrder,
		[Group] = NTILE(3) OVER (ORDER BY Report.OverallOrder DESC)
FROM(
SELECT C.Id, C.FirstName, C.LastName, [OverallOrder] = COUNT(ISNULL(CustomerId,0))
FROM Customer AS C
LEFT JOIN [Order] O ON C.Id = O.CustomerId
GROUP BY C.Id, C.FirstName, C.LastName
) AS Report