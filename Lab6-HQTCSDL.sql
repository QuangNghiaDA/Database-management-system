USE Northwind;
GO


-- 1. Viết hàm truyền vào một CustomerId và xuất ra tổng giá tiền (Total Amount)của các hóa đơn từ
-- khách hàng đó. Sau đó dùng hàm này xuất ra tổng giá tiền từ các hóa đơn của tất cả khách hàng.

CREATE FUNCTION fu_TotalAmountCustID (@CustimerID INT = 0)
RETURNS DEC(12,1)
AS 
BEGIN
	DECLARE @TotalAmount DEC(12,1)
	SELECT @TotalAmount = TotalAmount
	FROM [Order]
	WHERE CustomerId = @CustimerID
	RETURN @TotalAmount
END;

SELECT *, dbo.fu_TotalAmountCustID(Id) AS TotalAmount
FROM Customer;

-- Viết hàm truyền vào Id của khách hàng và xuất ra Họ và tên của khách hàng đó.
-- Sau đó dùng hàm này xuất ra họ tên tất cả khách hàng (Làm thêm)

SELECT * FROM Customer;
CREATE FUNCTION fuCustomer (@CustomerID INT = 0)
RETURNS NVARCHAR(50)
AS
BEGIN
	DECLARE @FullName NVARCHAR(50);
	SELECT @FullName = FirstName + SPACE(1) + LastName
	FROM Customer
	WHERE Id = @CustomerID
	RETURN @FullName
END;

SELECT *, dbo.fuCustomer(Id) AS FullName
FROM Customer;

-- 2. Viết hàm truyền vào hai số và xuất ra danh sách các sản phẩm có UnitPrice 
-- nằm trong khoảng hai số đó.

CREATE FUNCTION fu_ConditionUnitPrice 
(
	@a DEC(12,1),
	@b DEC(12,1)
)
RETURNS TABLE
AS
RETURN(
	SELECT *
	FROM OrderItem
	WHERE UnitPrice >= @a AND UnitPrice <= @b
);

SELECT * FROM dbo.fu_ConditionUnitPrice(10, 20);

-- Tạo hàm truyền vào một hoặc nhiều ký tự và trả về các nhà cung cấp từ quốc gia 
-- bắt đầu bằng ký tự đó (Làm thêm)
CREATE FUNCTION fu_SupplierByCountry (@Country NVARCHAR(50))
RETURNS TABLE
RETURN
(
	SELECT *
	FROM Supplier
	WHERE Country LIKE @Country + '%'
);

SELECT * FROM fu_SupplierByCountry('Br');

-- 3. Viết hàm truyền vào một danh sách các tháng 'June;July;August;September'
-- và xuất ra thông tin của các hóa đơn có trong những tháng đó.
-- Viết cả hai hàm dưới dạng inline và multi statement
-- sau đó cho biết thời gian thực thi của mỗi hàm, so sánh và đánh giá

CREATE FUNCTION fu_OrderbyMonth_inl 
( 
	@Month1 INT,
	@Month2 INT,
	@Month3 INT,
	@Month4 INT
)
RETURNS TABLE
RETURN 
(
	SELECT *
	FROM [Order]
	WHERE MONTH(OrderDate) = @Month1 OR
			MONTH(OrderDate) = @Month2 OR
			MONTH(OrderDate) = @Month3 OR
			MONTH(OrderDate) = @Month4
);

SELECT * FROM [Order];
SELECT * FROM fu_OrderbyMonth_inl(6, 7, 8, 9);

CREATE FUNCTION fu_OrderbyMonth_multi 
(
	@Month1 INT,
	@Month2 INT,
	@Month3 INT,
	@Month4 INT
)
RETURNS @ResultTable TABLE (Id INT, OrderDate DATETIME, OrderNumber INT,
							CustomerId INT, TotalAmount DEC)
AS
BEGIN
	INSERT INTO @ResultTable
	SELECT *
	FROM [Order]
	WHERE MONTH(OrderDate) = @Month1 OR
			MONTH(OrderDate) = @Month2 OR
			MONTH(OrderDate) = @Month3 OR
			MONTH(OrderDate) = @Month4
	RETURN
END;

SELECT * FROM fu_OrderbyMonth_multi(6, 7, 8, 9);

SET STATISTICS TIME ON
SELECT * FROM fu_OrderbyMonth_inl(6, 7, 8, 9);
SELECT * FROM fu_OrderbyMonth_multi(6, 7, 8, 9);
SET STATISTICS TIME OFF;

-- 4. Viết hàm kiểm tra mỗi hóa đơn có không quá 5 sản phẩm (bảng OrderItem). 
-- Nếu insert quá 5 sản phẩm cho một hóa đơn thì báo lỗi và không cho insert.

SELECT * FROM [OrderItem];

CREATE FUNCTION fu_CheckOrderItem (@OrderId INT)
RETURNS BIT
AS
BEGIN 
	DECLARE @Check BIT, @Count INT 
	SELECT @Count = COUNT(OrderId)  FROM OrderItem 
	WHERE OrderId = @OrderId
	GROUP BY OrderId
	IF  @Count <= 5
		SET @Check = 0;
	ELSE
		SET @Check = 1;
	RETURN @Check
END;

SELECT *, dbo.fu_CheckOrderItem(Id) AS CheckNumberOfOrder FROM [Order]

ALTER TABLE OrderItem WITH NOCHECK
ADD CONSTRAINT CheckQuantityExistences
    CHECK (dbo.fu_CheckOrderItem (OrderId) = 1);
GO

INSERT INTO OrderItem VALUES(10, 10, 10, 6);
