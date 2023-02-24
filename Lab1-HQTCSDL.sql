-- Truy van cac Databases trong he thong
SELECT name FROM master.dbo.sysdatabases

-- Xuat thong bao co Databases Northwind hay khong
IF db_id('Northwind') IS NOT NULL
BEGIN
	SELECT 'database does exist'
END
ELSE
BEGIN
	SELECT 'database does not exist'
END

-- Truy van du lieu bang Customer
SELECT * FROM Customer

-- Truy van du lieu chi tiet Customer
SELECT Id,
	CONCAT(FirstName,' ', LastName) AS FullName,
	City, Country
FROM Customer

-- Truy van khach hang Germany va UK
SELECT COUNT(Id) AS SoKhachHang FROM Customer 
WHERE Country = 'Germany' OR Country = 'UK';

SELECT * FROM Customer
WHERE Country = 'Germany' OR Country = 'UK';

-- Liet ke khach hang tang dan theo FirstName va giam theo Country
SELECT * FROM Customer
ORDER BY FirstName ASC, Country DESC

-- Truy van khach hang co Id la
-- 5, 10
SELECT * FROM Customer
WHERE Id = 5 OR Id = 10
-- 1 den 10
SELECT * FROM Customer
WHERE Id >= 1 AND Id <= 10
-- 5 den 10
SELECT * FROM Customer
WHERE Id >= 5 AND Id <= 10