USE [Northwind]

----------------
-- 1. Trigger --
----------------


-- Viết trigger khi xóa một OrderId thì xóa luôn các thông tin của Order đó trong bảng OrderItem.
-- Nếu có Foreign Key Constraint xảy ra không cho xóa thì hãy xóa Foreign Key Constraint đó đi rồi thực thi

CREATE TRIGGER [dbo].[Trigger_OrderIdDelete]
ON [dbo].[Order]
FOR DELETE 
AS

DECLARE @DeletedOrderId INT
SELECT @DeletedOrderId = Id FROM deleted
DELETE FROM OrderItem WHERE OrderId = @DeletedOrderId

PRINT 'OrderID = ' + LTRIM(STR(@DeletedOrderId)) + ' da duoc xoa.';

ALTER TABLE OrderItem DROP CONSTRAINT FK_ORDERITE_REFERENCE_ORDER;
DROP TRIGGER [dbo].[Trigger_OrderIdDelete];

DELETE FROM [Order] WHERE Id = 1


-- Viết trigger khi xóa hóa đơn của khách hàng Id = 1 thì báo lỗi không cho xóa sau đó ROLL BACK lại.
-- Lưu ý: Đưa trigger này lên làm Trigger đầu tiên thực thi xóa dữ liệu trên bảng Order
CREATE TRIGGER [dbo].[Trigger_CustomerID1Delete]
ON [dbo].[Customer]
FOR DELETE 
AS

	DECLARE @DeletedCustomerID INT
	SELECT @DeletedCustomerID = Id FROM deleted
	
	IF (@DeletedCustomerID = 1)
	BEGIN 
		RAISERROR ('CustomerID = 1 khong xoa duoc', 16, 1);
		ROLLBACK TRANSACTION
	END

EXEC sp_settriggerorder @triggername='Trigger_CustomerID1Delete', @order='First', @stmttype='DELETE';
SELECT * FROM Customer;
-- Xóa bỏ Foreign Key Constraint để kiểm nghiệm trigger
ALTER TABLE [Order] DROP CONSTRAINT FK_ORDER_REFERENCE_CUSTOMER;
DELETE FROM [Customer]
WHERE Id = 1; -- Kiểm tra

-- Viết Trigger không cho phép cập nhật Phone là NULL
-- hay trong Phone có chữ cái ở bảng Supplier.
-- Nếu có thì báo lỗi và ROLLBACK lại.

SELECT * FROM Customer;
CREATE TRIGGER [dbo].[Trigger_UpdateCustomer]
ON [dbo].[Customer]
FOR UPDATE
AS

	DECLARE @UpdatePhone NVARCHAR(20)
	IF UPDATE(Phone)
	BEGIN 
		SELECT @UpdatePhone = Phone FROM inserted
		IF @UpdatePhone IS NULL OR @UpdatePhone LIKE '%[^0-9]%'
		BEGIN 
		RAISERROR ('Phone khong duoc NULL hoac co chu cai.', 16, 1);
		ROLLBACK TRANSACTION
		END
	END

UPDATE Customer SET Phone = NULL WHERE Id = 1;

----------------
-- 2. Cursor  --
----------------

-- Viết một function với input vào Country và xuất ra danh sách các Id và Company Name 
-- ở thành phố đó theo dạng sau 
-- INPUT : ‘USA’
-- OUTPUT : Companies in USA are : New Orleans Cajun Delights(ID:2) ; Grandma Kelly's Homestead(ID:3) ...

SELECT * FROM Product;
SELECT * FROM Supplier;

CREATE FUNCTION dbo.ufn_ListSupplierByCountry (@CountryDescr NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS 
BEGIN
	DECLARE @SupplierList NVARCHAR(MAX) = 'Companies in ' + @CountryDescr + ' are : ';
	DECLARE @Id INT;
	DECLARE @CompanyName NVARCHAR(MAX);

	DECLARE SupplierCursor CURSOR READ_ONLY
	FOR 
	SELECT Id, CompanyName FROM Supplier
	WHERE LOWER(Country) LIKE LOWER(@CountryDescr)

	OPEN SupplierCursor

	FETCH NEXT FROM SupplierCursor INTO @Id, @CompanyName

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SupplierList = @SupplierList + @CompanyName + '(ID:' + LTRIM(STR(@Id)) + ') ; '; 
		FETCH NEXT FROM SupplierCursor INTO @Id, @CompanyName
	END

	CLOSE SupplierCursor
	DEALLOCATE SupplierCursor

	RETURN @SupplierList
END

SELECT dbo.ufn_ListSupplierByCountry('USA')

--------------------
-- 3.Transaction  --
--------------------

-- Viết các dòng lệnh cập nhật Quantity của các sản phẩm trong bảng OrderItem mà 
-- có OrderID được đặt từ khách hàng USA.
-- Quantity được cập nhật bằng cách input vào một @DFactor sau đó Quantity được tính theo công thức:
--									Quantity = Quantity / @DFactor.
-- Ngoài ra còn xuất ra cho biết số lượng hóa đơn đã được cập nhật.
-- (Sử dụng TRANSACTION để đảm bảo nếu có lỗi xảy ra thì ROLL BACK lại)
SELECT * FROM OrderItem;
SELECT * FROM [Order];
SELECT * FROM Customer;
SELECT * FROM Product;
SELECT * FROM Supplier;

BEGIN TRY 
	BEGIN TRANSACTION UpdateQuantityTrans

		SET NOCOUNT ON;

		DECLARE @NumOfUpdateRecords INT = 0;
		DECLARE @DFactor INT;
		SET @DFactor = 1;

		UPDATE OI SET Quantity = Quantity / @DFactor
		FROM OrderItem OI
		INNER JOIN [Order] AS O ON OI.OrderId = O.Id
		INNER JOIN Customer AS C ON C.Id = O.CustomerId
		WHERE C.Country LIKE '%USA%'

		SET @NumOfUpdateRecords = @@ROWCOUNT
		PRINT 'Cap nhat thanh cong ' + LTRIM(STR(@NumOfUpdateRecords)) + ' (don vi) trong bang OrderItem.';

	COMMIT TRANSACTION UpdateQuantityTrans
END TRY
BEGIN CATCH
	ROLLBACK TRAN UpdateQuantityTrans
	PRINT 'Cap nhat that bai. Xem chi tiet: ';
	PRINT ERROR_MESSAGE();
END CATCH


--------------------
-- 4. Temp Table  --
--------------------
-- Viết TRANSACTION với Input là hai quốc gia.
-- Sau đó xuất thông tin là quốc gia nào có số sản phẩm cung cấp (thông tin qua Supplier) nhiều hơn.
-- Cho biết số lượng sản phẩm cúng cấp của mỗi quốc gia. Sử dụng cả hai dạng bảng tạm (# và @).

SELECT * FROM Supplier;

BEGIN TRY 
BEGIN TRANSACTION CompareTwoContriesTrans

	SET NOCOUNT ON;
	DECLARE @Country1 NVARCHAR(MAX);
	DECLARE @Country2 NVARCHAR(MAX);
	
	SET @Country1 = 'USA';
	SET @Country2 = 'France';

	CREATE TABLE #SupplierInfo1 
	(
		SuppierCountry NVARCHAR(MAX)
	)

	DECLARE @SupplierInfo2 TABLE 
	(
		SuppierCountry NVARCHAR(MAX)
	)

	INSERT INTO #SupplierInfo1
	SELECT Id AS SupplierCountry
	FROM Supplier
	WHERE Country = @Country1
	GROUP BY Id;

	INSERT INTO @SupplierInfo2
	SELECT Id AS SupplierCountry
	FROM Supplier
	WHERE Country = @Country2
	GROUP BY Id;

	DECLARE @Count1 INT
	SET @Count1 = (SELECT COUNT(*) FROM #SupplierInfo1)
	DECLARE @Count2 INT
	SET @Count2 = (SELECT COUNT(*) FROM @SupplierInfo2)

	PRINT @Country1 + ' co ' + LTRIM(STR(@Count1)) + ' nha cung cap.';
	PRINT @Country2 + ' co ' + LTRIM(STR(@Count2)) + ' nha cung cap.';

	PRINT
	CASE 
		WHEN @Country1 = @Country2
			THEN 'So nha cung cap cua ' + @Country1 + ' bang voi ' + @Country2
		WHEN @Country1 > @Country2
			THEN 'So nha cung cap cua ' + @Country1 + ' lon hon ' + @Country2 
		ELSE 'So nha cung cap cua ' + @Country1 + ' be hon ' + @Country2
	END

	DROP TABLE #SupplierInfo1

COMMIT TRANSACTION  CompareTwoContriesTrans
END TRY

BEGIN CATCH
	ROLLBACK TRAN CompareTwoContriesTrans
	PRINT 'Xay ra loi'
	PRINT ERROR_MESSAGE();
END CATCH;

