USE Northwind
SELECT name FROM master.dbo.sysdatabases

-- Xuat danh sach nha cung cap
SELECT S.Id, 
	S.CompanyName, S.ContactName, S.City, S.Country, S.Phone,
	MIN(P.UnitPrice) AS [MinPrice], MAX(P.UnitPrice) AS [MaxPrice],
	COUNT(P.SupplierId)
FROM Product AS P
INNER JOIN Supplier AS S ON P.SupplierId = S.Id
GROUP BY S.Id, S.CompanyName, P.SupplierId, S.ContactName, S.City, S.Country, S.Phone
ORDER BY S.Id DESC


-- Danh sach nha cung cap co su khac biet gia <= 30
SELECT S.Id, 
	S.CompanyName, S.ContactName, S.City, S.Country, S.Phone,
	MIN(P.UnitPrice) AS [MinPrice], MAX(P.UnitPrice) AS [MaxPrice],
	COUNT(P.SupplierId)
FROM Product AS P
INNER JOIN Supplier AS S ON P.SupplierId = S.Id
GROUP BY S.Id, S.CompanyName, P.SupplierId, S.ContactName, S.City, S.Country, S.Phone
HAVING MAX(P.UnitPrice) - MIN(P.UnitPrice) <=30
ORDER BY S.Id DESC


-- Danh sach hoa don co tong gia chi tra
SELECT O.Id, O.OrderNumber, O.OrderDate, 
		OI.UnitPrice, OI.Quantity,
		'VIP' AS [Decription], 
		(OI.UnitPrice*OI.Quantity) AS [TongGiaChiTra]
FROM [Order] AS O, OrderItem AS OI
WHERE OI.UnitPrice*OI.Quantity >= 1500
UNION
SELECT O.Id, O.OrderNumber, O.OrderDate,
		OI.UnitPrice, OI.Quantity,
		'Normal' AS [Decription], 
		(OI.UnitPrice*OI.Quantity) AS [TongGiaChiTra]
FROM [Order] AS O, OrderItem AS OI
WHERE OI.UnitPrice*OI.Quantity < 1500


-- Hoa don thang 7 khong co France
SELECT O.Id, O.OrderNumber, O.OrderDate, C.Country
FROM [Order] AS O, Customer AS C
WHERE EXISTS (SELECT * FROM [Order] WHERE O.Id = C.Id AND MONTH(O.OrderDate) = 7)
EXCEPT
SELECT O.Id, O.OrderNumber, O.OrderDate, C.Country
FROM [Order] AS O, Customer AS C
WHERE C.Country = 'France'


-- Danh sach hoa don co TotalAmount trong top 5
SELECT O.Id, O.OrderNumber, O.OrderDate, O.TotalAmount
FROM [Order] AS O
WHERE O.TotalAmount IN (SELECT TOP 5 TotalAmount FROM [Order] ORDER BY TotalAmount DESC)