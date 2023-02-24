use Northwind;
go
----------------------------------------------------------------------------
-- 1. Tạo view:
--    uvw_DetailProductInOrder với các cột sau 
--    OrderId, OrderNumber, OrderDate, ProductId, 
--    ProductInfo (= ProductName + Package. Ví dụ: Chai 10 boxes x 20 bags), 
--    UnitPrice và Quantity
-----------------------------------------------------------------------------

CREATE VIEW vw_DetailProductInOrder
AS 
	SELECT OI.OrderId, O.OrderNumber, O.OrderDate, OI.ProductId,
			P.ProductName + SPACE(1) + P.Package AS ProductInfo,
			OI.UnitPrice, OI.Quantity
	FROM [Order] AS O, Product AS P
	INNER JOIN OrderItem AS OI ON P.Id = OI.ProductId;
GO

SELECT *
FROM vw_DetailProductInOrder;

--   uvw_AllProductInOrder với các cột sau OrderId, OrderNumber, OrderDate, ProductList
--   (ví dụ “11,42,72” với OrderId 1), và TotalAmount ( = SUM(UnitPrice * Quantity)) theo
--   mỗi OrderId  (Gợi ý dùng FOR XML PATH để tạo cột ProductList)
go
CREATE VIEW uvw_AllProductInOrder
AS 
	SELECT OI2.OrderId, O.OrderNumber, O.OrderDate,
		SUBSTRING(
		(
			SELECT ','+CONVERT(NVARCHAR,OI1.ProductId)
			FROM OrderItem AS OI1
			WHERE OI1.OrderId = OI2.OrderId
			ORDER BY OI1.OrderId
			FOR XML PATH('')
			), 2, 100) ProductList,
			TotalAmount = SUM(OI2.Quantity*OI2.UnitPrice)
	FROM [Order] AS O INNER JOIN  OrderItem AS OI2 ON OI2.OrderId = O.Id
GROUP BY OI2.OrderId, O.OrderNumber, O.OrderDate;
GO

SELECT * FROM uvw_AllProductInOrder;

-----------------------------------------------------------------------------------------------
-- 2. Dùng view “uvw_DetailProductInOrder“ truy vấn những thông tin có OrderDate trong tháng 7
-----------------------------------------------------------------------------------------------

SELECT *
FROM vw_DetailProductInOrder
WHERE MONTH(OrderDate) = 7;

-------------------------------------------------------------------------------------------------
-- 3. Dùng view “uvw_AllProductInOrder” truy vấn những hóa đơn Order có ít nhất 3 product trở lên
-------------------------------------------------------------------------------------------------

SELECT *
FROM uvw_AllProductInOrder
WHERE LEN(ProductList) - LEN(REPLACE(ProductList, ',', '')) >= 2;

-------------------------------------------------------------------------------------------
-- 4. Hai view trên đã readonly chưa ? Có những cách nào làm hai view trên thành readonly ?
-------------------------------------------------------------------------------------------
-- Hai view trên chưa readonly. Vì ta vẫn dùng lệnh WHERE để truy vấn được
-- Có 3 cách để làm một view trở thành readonly: dùng trigger,
--		thêm "UNION SELECT NULL, NULL, NULL, NULL, NULL WHERE 1 = 0"
--		thêm WITH CHECK OPTION

-- CÁCH 1:
GO
CREATE TRIGGER vw_DetailProductInOrder_Trigger_OnInsertOrUpdateOrDelete
ON vw_DetailProductInOrder
INSTEAD OF INSERT, UPDATE, DELETE
AS
BEGIN
	RAISERROR('You are not allowed to insert, update, or delete through this view', 16, 1)
END;

-- Kiểm tra
UPDATE vw_DetailProductInOrder SET UnitPrice = 10
WHERE MONTH(OrderDate) = 7;

-- CÁCH 2:
go
CREATE VIEW uvw_AllProductInOrder_A
AS 
	SELECT OI2.OrderId, O.OrderNumber, O.OrderDate,
		SUBSTRING(
		(
			SELECT ','+CONVERT(NVARCHAR,OI1.ProductId)
			FROM OrderItem AS OI1
			WHERE OI1.OrderId = OI2.OrderId
			ORDER BY OI1.OrderId
			FOR XML PATH('')
			), 2, 100) ProductList,
			TotalAmount = SUM(OI2.Quantity*OI2.UnitPrice)
	FROM [Order] AS O INNER JOIN  OrderItem AS OI2 ON OI2.OrderId = O.Id
GROUP BY OI2.OrderId, O.OrderNumber, O.OrderDate
UNION SELECT NULL, NULL, NULL, NULL, NULL WHERE 1 = 0
GO;

-- Kiểm tra
UPDATE uvw_AllProductInOrder_A SET OrderId = 10
WHERE TotalAmount >= 1000;

-------------------------------------------------------------------------------------
-- 5. Thống kê về thời gian thực thi khi gọi hai view trên. View nào chạy nhanh hơn ?
-------------------------------------------------------------------------------------

SET STATISTICS IO, TIME ON
GO

SELECT * FROM vw_DetailProductInOrder; -- View thứ 1
SELECT * FROM uvw_AllProductInOrder;	-- View thứ 2

-- View thứ 2 chạy nhanh hơn view thứ 1 (84ms < 11167ms)




