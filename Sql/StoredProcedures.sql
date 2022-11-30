--Procedimiento de listado de los territorios
CREATE OR ALTER PROCEDURE usp_TerritoryList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT territoryid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.sales.SalesTerritory;'
    EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END

--Procedimiento de listado de las categorias
GO
CREATE OR ALTER PROCEDURE usp_CategoryList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT productcategoryid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.Production.ProductCategory Order By id;'
    EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END

/**********************************************************************************************/
-- Consulta A
-- Procedimiento de busqueda de ventas totales por territorio
GO
CREATE OR ALTER PROCEDURE usp_ConsATVTerr @cat varchar(2), @InstS varchar(max), @InstP varchar(max) AS
BEGIN
	BEGIN TRAN
	DECLARE @SQL nvarchar(max)
	SET @SQL =
		'SELECT c2.TerrName, c1.VentasTotales FROM
			(select soh.TerritoryID, sum(a.LineTotal) as VentasTotales
			from ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader soh
			inner join
			(select salesorderid, productid, orderqty, linetotal
			from ['+@InstS+'].AW_Equipo6.Sales.salesorderdetail sod
			where ProductID in (
					select productid
					from ['+@InstP+'].AW_Equipo6.Production.Product
					where ProductSubcategoryID in (
						select ProductSubcategoryID
						from ['+@InstP+'].AW_Equipo6.Production.ProductSubcategory
						where ProductCategoryID in (
							select ProductCategoryID
							from ['+@InstP+'].AW_Equipo6.Production.ProductCategory
							where ProductCategoryID ='+@cat+' 
							)))) as a
			on soh.SalesOrderID = a.SalesOrderID
			group by soh.TerritoryID) AS c1
		INNER JOIN
			(select [name] as TerrName, territoryid from ['+@InstS+'].AW_Equipo6.sales.SalesTerritory) AS c2
		ON c1.TerritoryID = c2.TerritoryID
		order by c2.TerrName'
	EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END

GO
------------------------------------------------------------------------------------------------------
EXEC usp_ConsATVTerr '01', 'NEGA-PC', 'NEGA-PC'
go

/**********************************************************************************************/
-- Consulta B
----Determinar producto mas solicitado
CREATE PROCEDURE sp_productoSolicitado @p_group nvarchar(50)  
AS
BEGIN 
	'SELECT
	TOP 1 SUM(T.lineTotal) as total_ventas,
	p.Name as Nombre,
	p.ProductID
FROM
	['+@InstP+'].AW_Equipo6.Production.Product p
inner join(
	SELECT
		ProductID,
		lineTotal
	FROM
		['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail sod
	WHERE
		SalesOrderID in(
		SELECT
			SalesOrderID
		FROM
			['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader soh
		WHERE
			TerritoryID in(
			SELECT
				TerritoryID
			FROM
				['+@InstS+'].AW_Equipo6.Sales.SalesTerritory st
			WHERE
				[Group] = @p_group
			)
		)
	) as T
	on
	p.ProductID = T.ProductID
GROUP BY
	p.Name,
	p.ProductID
ORDER by
	total_ventas DESC
	'
END 
------------------------------------------------------------------------------------------------------
EXECUTE sp_productoSolicitado 'Pacific'


/**********************************************************************************************/
-- Consulta E
-- Actualizar  la  cantidad  de  productos  de  una  orden  que  se  provea
CREATE OR ALTER usp_ConsEUpdtSales (@cant varchar(max), @salesID varchar(3), @productID varchar(3), @InstS varchar(max), @InstP varchar(max)) AS
BEGIN
	BEGIN TRAN
	DECLARE @SQL_CONS1 = 'select * from ['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail where SalesOrderID = '+@salesID+' and ProductID = '+@productID 
	DECLARE @SQL_CONS2 =
	if exists(select * from AdventureWorks2019.Sales.SalesOrderDetail 
		where SalesOrderID = @salesID and ProductID = @productID)
		begin
			if exists(select top 1 LocationID from AdventureWorks2019.Production.ProductInventory
						where ProductID = @productID and Quantity >= @cant )
				begin
					--actualizando venta
					update AdventureWorks2019.Sales.SalesOrderDetail 
					set OrderQty = OrderQty + @cant
					where SalesOrderID = @salesID and ProductID = @productID

					 --asignando a que locaci�n se le retirar� stock
					declare @locationID int
					set @locationID = (select top 1 LocationID from AdventureWorks2019.Production.ProductInventory
					where ProductID = @productID and Quantity >= @cant)

					--Cambiar el Stock del producto
					update AdventureWorks2019.Production.ProductInventory
					set Quantity = Quantity - @cant
					where ProductID = @productID and LocationID = @locationID
				end
			else
				begin 
					select null --Si no hay productos en existencia
				end
			end
			else
				begin
				select null --Si el producto no existe
				end
			end
go
------------------------------------------------------------------------------------------------------
exec EUpdateSales @cant = 1, @salesID = 43659, @productID  = 776
go

/**********************************************************************************************/
-- Consulta F
--Actualizar el método de envío de una orden que se reciba como argumento
create procedure UpdateShip (@method int, @salesID int) as
begin
	if exists(select * from AdventureWorks2019.Purchasing.ShipMethod
		where ShipMethodID = @method)
		begin
			--Actualizar metodo de envio
			update AdventureWorks2019.Sales.SalesOrderHeader
			set ShipMethodID = @method
			where SalesOrderID = @salesID
		end
	else
		begin
			select null --En caso de que no exista
		end
end
go	
------------------------------------------------------------------------------------------------------
select SalesOrderID, ShipMethodID from AdventureWorks2019.Sales.SalesOrderHeader
exec UpdateShip @method = 3,@salesID = 43659
go
/**********************************************************************************************/
-- Consulta F
--Actualizar el método de envío de una orden que se reciba como argumento

create procedure UpdateEmail (@customerID varchar (10), @newEmail varchar(50)) as
begin
	if exists(select * from AdventureWorks2019.Sales.Customer
	where CustomerID = @customerID and PersonID is not null)
		begin
			update AdventureWorks2019.Person.EmailAddress	
			set EmailAddress = @newEmail
			where BusinessEntityID = (
				select PersonID from AdventureWorks2019.Sales.Customer
				where CustomerID = @customerID)
		end
	else
		begin
			select null
		end
end
go

exec UpdateEmail @customerID = 11000, @newemail = 'asasasasasa'