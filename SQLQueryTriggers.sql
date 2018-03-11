USE Northwind
GO
--Использование триггера для задания бизнес правила с учетом данных нескольких таблиц.
--БД Northwind.
--В таблице Products есть поле Discontinued – признак, что данный товар больше не поставляется(-1).  --Необходимо генерировать ошибку при попытке вставки в таблицу Order Details строки с номером товара, 
--который больше не поставляется. 
CREATE TRIGGER tr_ProdNot
ON [Order Details]
FOR INSERT,UPDATE
AS
DECLARE @Discontinued bit
SELECT @Discontinued=Discontinued FROM Products
JOIN INSERTED
ON dbo.Products.ProductID=INSERTED.ProductID
if(@Discontinued=-1)
BEGIN 
RAISERROR (N'Продукт больше не поставляется',16,1)
ROLLBACK TRAN
END
GO
INSERT INTO [order details] (orderID, ProductID, UnitPrice, Quantity, Discount)
VALUES(10355,5,12,5,0)
GO
INSERT INTO [order details] (orderID, ProductID, UnitPrice, Quantity, Discount)
VALUES(10355,6,12,5,0)
GO
UPDATE [order details] set ProductID = 5 where ProductID = 6 and OrderID = 10355

--Создать триггер, который срабатывает при изменении в Products
-- и не позволяет отпускать более половины имеющегося на складе количества определенного товара.
GO
CREATE TRIGGER tr_StopTrade
ON Products
FOR UPDATE
AS
DECLARE @unitAfterSale float
SELECT @unitAfterSale=(i.UnitsInStock)*100/d.UnitsInStock
FROM DELETED d JOIN INSERTED i
ON d.ProductID=i.ProductID
PRINT CAST(@unitAfterSale as nvarchar)
if(@unitAfterSale<50)
BEGIN
RAISERROR (N'На складе остается меньше половины товара',15,1)
ROLLBACK TRAN
END
GO
update products set unitsInStock = 30 where ProductID = 1
select * from products

update products set unitsInStock = 10 where ProductID = 1
select * from products
GO
--Создание триггера уровня БД,  запрещающего удаление и изменение таблиц
CREATE TRIGGER StopDropOrAlterTable
ON DATABASE
FOR DROP_TABLE,ALTER_TABLE
AS 
PRINT N'Вам запрещено изменять таблицы'
ROLLBACK
GO
DROP TABLE [Order Details]
GO
--Создание триггре запрещающего создавать создавать базу данных
CREATE TRIGGER StpCrtDtbs
ON ALL SERVER
FOR CREATE_DATABASE
AS
PRINT N'Вам запрещено создавать базы данных'
ROLLBACK
GO
USE MASTER
GO
CREATE DATABASE TryFromStopTrigger
GO
DROP TRIGGER StpCrtDtbs ON All SERVER
GO
--создаем триггрер с фунцией eventdata()
CREATE TRIGGER StpCrtDtbs
ON ALL SERVER
FOR CREATE_DATABASE
AS
SELECT EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)')
PRINT N'Вам запрещено создавать базы данных'
ROLLBACK
GO
CREATE DATABASE Try2 
GO
--Создать таблицу журнала, в которую будут записываться все событие уровня БД в виде:
-- время возникновения, пользователь, тип события, текст запроса
USE Northwind
GO
--удаляем страый триггер запрета создания таблиц
DROP TRIGGER StpCrtTbl ON DATABASE
GO
--создаем саму таблицу журнала
 CREATE TABLE DdlLog(
 IdEvent int PRIMARY KEY IDENTITY,
 TimeStart DATETIME NOT NULL,
 UserName nvarchar(30) NOT NULL,
 EventType nvarchar(max) NOT NULL,
 QueryText nvarchar(max)NOT NULL)
 GO
 --триггер при срабатывании которого все будет записываться в таблицу
 ALTER TRIGGER StopCreateTable
 ON DATABASE
 FOR CREATE_TABLE
 AS 
 --переменная для записи данных
 DECLARE @data XML
 SET @data=EVENTDATA()
 INSERT DllLog
 (TimeStart, UserName,EventType,QueryText)
  VALUES
  (GETDATE(),
   CONVERT(nvarchar(30),CURRENT_USER),
    @data.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(100)'),
	 @data.value('(/EVENT_INSTANSE/TSQLCommand)[1]', 'nvarchar(2000)'))
	 GO
	 CREATE TABLE Try4(NameSomething nvarchar(30))
	 GO
	 SELECT *
	 FROM dbo.DdlLog
	 GO
	





 