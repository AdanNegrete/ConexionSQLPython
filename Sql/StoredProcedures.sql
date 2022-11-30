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
GO
CREATE OR ALTER PROCEDURE usp_ConsEUpdtSales (@cant varchar(max), @salesID varchar(20), @productID varchar(20), @InstS varchar(max), @InstP varchar(max)) AS
BEGIN
	BEGIN TRAN
	
	DECLARE @SQL_CONS1 nVARCHAR(MAX), @SQL_CONS2 nVARCHAR(MAX)
	DECLARE @SQL_UPDT1 nVARCHAR(MAX), @SQL_UPDT2 nVARCHAR(MAX)
	DECLARE @salida_c1 nvarchar(max), @salida_c2 nvarchar(max)
	DECLARE @params_c1 nvarchar(max), @params_c2 nvarchar(max)

	-- Ejecutando primer query de verificación de existencia
	SET @SQL_CONS1 = 'select @salida_out_1=SalesOrderID from ['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail where SalesOrderID = '+@salesID+' and ProductID = '+@productID+';' 
	SET @params_c1 = N'@salida_out_1 nvarchar(max) OUTPUT';

	-- Ejecutando segundo query de verificación de inventario
	SET @SQL_CONS2 = 'select top 1 @salida_out_2=LocationID from ['+@InstP+'].AW_Equipo6.Production.ProductInventory where ProductID = '+@productID+' and Quantity >= '+@cant+';' 
	SET @params_c2 = N'@salida_out_2 nvarchar(max) OUTPUT';

	-- Preparando querys de Update
	SET @SQL_UPDT1 = 'update ['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail set OrderQty = OrderQty + '+@cant+' where SalesOrderID = '+@salesID+' and ProductID = '+@productID+';' 
	SET @SQL_UPDT2 = 'update ['+@InstP+'].AW_Equipo6.Production.ProductInventory set Quantity = Quantity - '+@cant+' where ProductID = '+@productID+' and LocationID = '+@salida_c2+';'

	EXEC sys.[sp_executesql] @SQL_CONS1,@params_c1,@salida_out_1 = @salida_c1 OUTPUT
	EXEC sys.[sp_executesql] @SQL_CONS2,@params_c2,@salida_out_2 = @salida_c2 OUTPUT

	if @salida_c1 = @salesID
		begin
			
			if @salida_c2 is NOT NULL
				begin
					--actualizando venta
					EXEC sys.[sp_executesql] @SQL_UPDT1;

					--Cambiar el Stock del producto
					EXEC sys.[sp_executesql] @SQL_UPDT2;
				end
			else
				begin 
					select null --Si no hay productos en existencia
					print N'No hay productos en existencia'
				end
		end
	else
		begin
			select null, @salida_c1, @salesID --Si el producto no existe
			print N'El producto no se encuentra en la orden'
		end
COMMIT TRAN
END


go
------------------------------------------------------------------------------------------------------
exec usp_ConsEUpdtSales '5', '43659', '776', 'NEGA-PC', 'NEGA-PC'
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