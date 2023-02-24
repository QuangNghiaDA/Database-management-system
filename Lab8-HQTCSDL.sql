USE [Northwind]


--------------------------------------
-- Trần Quang Nghĩa					--
-- 19110392							--
-- Lab 8							--
-- DBM								--
--------------------------------------

---------------         STORED PROCEDURE        ----------------

-- 1. Viết một stored procudure với:
--          Input là một mã khách hàng CustomerId
--			Output là một hóa đơn OrderId của khách hàng có Total Amount nhỏ nhất
--					và một hóa đơn có Total Amount lớn nhất

-- Tạo Procedure
CREATE PROCEDURE usp_GetCustomerId_MaxMinTotalAmount
	@CustomerId INT,
	@MinOrderId INT OUTPUT,
	@MaxOrderId INT OUTPUT,
	@MinTotalAmount DECIMAL(12,2) OUTPUT,
	@MaxTotalAmount DECIMAL(12,2) OUTPUT
AS
BEGIN

	SELECT TOP 1 @MinOrderId = Id, @MinTotalAmount = TotalAmount
	FROM [Order]
	WHERE @CustomerId = CustomerId
	ORDER BY TotalAmount;

	SELECT TOP 1 @MaxOrderId = Id, @MaxTotalAmount = TotalAmount
	FROM [Order]
	WHERE @CustomerId = CustomerId
	ORDER BY TotalAmount DESC;

END;


-- Kiểm tra kết quả
DECLARE @CustomerId INT
DECLARE	@MinOrderId INT 
DECLARE	@MaxOrderId INT 
DECLARE	@MinTotalAmount DECIMAL(12,2) 
DECLARE	@MaxTotalAmount DECIMAL(12,2) 
SET @CustomerId = 2

EXEC usp_GetCustomerId_MaxMinTotalAmount 
									@CustomerId, 
									@MinOrderId OUTPUT, 
									@MaxOrderId OUTPUT,
									@MinTotalAmount OUTPUT,
									@MaxTotalAmount OUTPUT
SELECT @CustomerId AS CustomerId, 
	@MinOrderId AS MinOrderId, @MinTotalAmount AS MinTotalAmount,
	@MaxOrderId AS MaxOrderId, @MaxTotalAmount AS MaxTotalAmount;

-- Xóa Procedure
DROP PROCEDURE usp_GetCustomerId_MaxMinTotalAmount;


-- 2. Viết một Stored Procedure để thêm vào một Customer 
-- với Input là FirstName, LastName, City, Country, và Phone.
-- Lưu ý nếu các input mà rỗng hoặc Input đó đã có trong bảng thì báo lỗi tương ứng và ROLL BACK lại.


CREATE PROCEDURE usp_InsertNewCustomer
				@FirstName NVARCHAR(50),
				@LastName NVARCHAR(50),
				@City NVARCHAR(50),
				@Country NVARCHAR(50),
				@Phone NVARCHAR(50)

AS 
BEGIN 
   -- Khách hàng có trong bảng
	IF( EXISTS(SELECT * FROM Customer WHERE @FirstName = FirstName AND
											@LastName = LastName AND
											@City = City AND
											@Country = Country AND
											@Phone = Phone))
	BEGIN
		PRINT N'Thông tin khách hàng đã tồn tại!'
		RETURN -1
	END

	-- Inut rỗng
	IF (LEN(@FirstName) = 0 OR
		LEN(@LastName) = 0 OR
		LEN(@City) = 0 OR
		LEN(@Country) = 0 OR
		LEN(@Phone) = 0)
	BEGIN 
		PRINT N'Thông tin của khách hàng không được để trống!'
		RETURN -1
	END

	BEGIN TRY 
		BEGIN TRANSACTION

			INSERT INTO [dbo].[Customer]([FirstName],[LastName],[City],[Country],[Phone])
			VALUES (@FirstName, @LastName, @City, @Country, @Phone)
			PRINT N'Cập nhật dữ liệu thành công!'
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		DECLARE @ERR NVARCHAR(MAX)
		SET @ERR = ERROR_MESSAGE()
		PRINT N'Có lỗi sau trong quá trình thêm dữ liệu vào bảng Customer:'
		RAISERROR(@ERR, 16, 1);
		RETURN -1
	END CATCH
END;

-- Kiểm tra: Chèn thêm thông tin của khách hàng sau:

DECLARE @StateInsert1 INT
EXEC @StateInsert1 = usp_InsertNewCustomer N'Quang Nghĩa', N'Trần', 
										N'TP. Hồ Chí Minh', N'VN', '123456'
PRINT @StateInsert1;

DELETE FROM Customer
WHERE FirstName = N'Quang Nghĩa' AND LastName = N'Trần';

SELECT * FROM Customer;
DROP PROCEDURE usp_InsertNewCustomer;


-- 3. Viết store Procedure cập nhật lại UnitPrice của sản phẩm trong bảng
-- OrderItem. Khi cập nhật lại UnitPrice này thì cũng phải cập nhật lại
-- Total Amount trong bảng Order tương ứng với Total Amount = SUM(UnitPrice*Quantity)

CREATE PROCEDURE usp_UpdateUnitPrice
				@OrderItemId INT,
				@UnitPrice DECIMAL(12,2)
AS 
BEGIN

	   -- Hóa đơn không có trong bảng
	IF( NOT EXISTS(SELECT * FROM OrderItem WHERE @OrderItemId = Id))
	BEGIN
		PRINT N'Thông tin hóa đơn không tồn tại!'
		RETURN -1
	END

	DECLARE @OrderId INT
	SET @OrderId = (SELECT OrderId FROM OrderItem WHERE Id = @OrderItemId)
	BEGIN TRY 
		BEGIN TRANSACTION
			UPDATE OrderItem SET UnitPrice = @UnitPrice WHERE Id = @OrderItemId
			UPDATE [Order] SET TotalAmount = (SELECT SUM(@UnitPrice*Quantity) 
								FROM OrderItem 
								WHERE OrderId = @OrderItemId) WHERE Id = @OrderId
			PRINT N'Cập nhật thành công!'
		COMMIT TRANSACTION
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		DECLARE @ERR NVARCHAR(MAX)
		SET @ERR = ERROR_MESSAGE()
		PRINT N'Có lỗi trong quá trình cập nhật!'
		RAISERROR(@ERR, 16, 1);
		RETURN -1
	END CATCH
END;

DROP PROCEDURE usp_UpdateUnitPrice;

-- Kiểm tra lỗi
DECLARE @StateUpdate1 INT
EXEC @StateUpdate1 = usp_UpdateUnitPrice 9999, 1000.0
PRINT @StateUpdate1;

-- Cập nhật UnitPrice
DECLARE @StateUpdate2 INT
EXEC @StateUpdate2 = usp_UpdateUnitPrice 4, 15.0
PRINT @StateUpdate2;

SELECT * FROM [Order] WHERE Id = 2;
SELECT * FROM OrderItem WHERE OrderId = 2;