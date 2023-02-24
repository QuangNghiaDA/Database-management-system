use Northwind
select name from master.dbo.sysdatabases
 -- Tran Quang Nghia
 -- 19110392
 -- Lab 4 - DBM

-- 1. Theo mỗi  OrderID cho biết số lượng Quantity của mỗi ProductID chiếm tỷ lệ bao nhiêu phần trăm
SELECT Id, OrderId, ProductId, UnitPrice, Quantity,
		SUM (Quantity) OVER (PARTITION BY OrderId) AS QuantityByOrderId,
		CAST((CONVERT(DECIMAL,Quantity)/(SUM (Quantity) OVER (PARTITION BY OrderId))*100)
		AS DECIMAL(6,2)) AS PercentByQuantity
FROM OrderItem;

-- Theo mỗi  OrderID cho biết UniPrice của mỗi ProductID chiếm tỷ lệ bao nhiêu phần trăm
SELECT Id, OrderId, ProductId, UnitPrice, Quantity,
		SUM(UnitPrice) OVER (PARTITION BY OrderId) AS UnitPriceByOrderId,
		CAST((UnitPrice/(SUM(UnitPrice) OVER (PARTITION BY OrderId))*100)
			AS DECIMAL(6,2)) AS PercentByUnitPrice
FROM OrderItem;

-- 2. Xuất các hóa đơn kèm theo thông tin ngày trong tuần của hóa đơn là: Thứ 2, 3,4,5,6,7, Chủ Nhật
SELECT DATENAME(w,OrderDate) AS [Date Name],*
FROM [Order];

-- 3. Với mỗi ProductID trong OrderItem xuất các thông tin gồm:
-- OrderID, ProductID, ProductName, UnitPrice, Quantity, ContactInfo, ContactType.
-- Trong đó ContactInfo ưu tiên Fax, nếu không thì dùng Phone của Supplier sản phẩm đó.
-- Còn ContactType là ghi chú đó là loại ContactInfo nào.

SELECT O.OrderId, O.ProductId, P.ProductName, O.UnitPrice,
		COALESCE(S.Fax, S.Phone) AS ContactInfo,
		CASE COALESCE(S.Fax, S.Phone) WHEN Fax THEN 'Fax' ELSE 'Phone' END AS ContactType
FROM OrderItem AS O, Product AS P, Supplier AS S;

-- 4. Cho biết Id của database Northwind, Id của bảng Supplier, 
-- Id của User mà bạn đang đăng nhập là bao nhiêu.
-- Cho biết tên User dang đăng nhập
SELECT DB_ID('Northwind');
SELECT DB_NAME(7);
SELECT OBJECT_ID('Supplier');
SELECT USER_ID();
SELECT USER_NAME(1);

-- 5. Cho biết thông tin user_update, user_seek, user_scan và user_lookup 
-- trên bảng Order trong database Northwind

SELECT [TableName] = OBJECT_NAME(object_id),
user_updates, user_seeks, user_scans, user_lookups
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID('Northwind')
and OBJECT_NAME(object_id) = 'Order';

-- 6. Dùng with để phân chia cây như sau: Mức 0 là các quốc gia (Country),
-- Mức 1 là các thành phố (City) thuộc quốc gia đó, 
-- Mức 2 là các hóa đơn (Order) thuộc Country-City đó

WITH OrderCategory(Country, City, IdOrder, alevel)
AS(
	SELECT DISTINCT Country,
	City = CAST('' AS NVARCHAR(255)),
	IdOrder = CAST('' AS NVARCHAR(255)),
	alevel = 0
	FROM [Order]  Od left join Customer C ON Od.CustomerId = C.id

	UNION ALL

	SELECT C.Country,
	City = CAST(C.City AS NVARCHAR(255)),
	IdOrder = CAST('' AS NVARCHAR(255)),
	alevel = OC.alevel +1
	FROM OrderCategory OC
	INNER Join Customer C ON OC.Country = C.Country
	WHERE OC.alevel =0

	UNION All

	SELECT C.Country,
	City = Cast(C.City As NVARCHAR(255)),
	CompanyName = CAST(Od.Id AS NVARCHAR(255)),
	alevel = OC.alevel +1
	FROM Customer C
	INNER join [Order] Od on Od.CustomerId = C.Id
	INNER Join OrderCategory OC  On C.Country = OC.Country AND OC.City = C.City
	WHERE OC.alevel =1
)
SELECT 	
	[Quoc Gia] = CASE WHEN alevel =0 then Country else '--' END,
	[Thanh Pho] = CASE WHEN alevel =1 then City else '----' END,
	[Hoa Don] = IdOrder,
	Cap = alevel
FROM (SELECT distinct *
	FROM OrderCategory
) Report
ORDER BY Country, City, IdOrder, alevel

-- 7. Xuất những hóa đơn từ khách hàng France mà có tổng số lượng Quantity lớn hơn 50 
-- của các sản phẩm thuộc hóa đơn ấy
WITH SumByQuantity AS
(
	SELECT OrderId, SUM(Quantity) AS SumQuantity FROM OrderItem
	GROUP BY OrderId
	HAVING SUM(Quantity) > 50
	
),
CusByCountry AS
(
	SELECT SQ.*
	FROM SumByQuantity AS SQ
	INNER JOIN Customer AS C ON SQ.OrderId = C.Id
	WHERE C.Country = 'France'
)
SELECT * FROM CusByCountry;

