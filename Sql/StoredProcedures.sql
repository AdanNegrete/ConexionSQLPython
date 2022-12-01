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

--Procedimiento de listado de los productos
GO
CREATE OR ALTER PROCEDURE usp_ProductList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT productid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.Production.Product Order By id;'
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
CREATE OR ALTER PROCEDURE sp_productoSolicitado @p_group nvarchar(50)  
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

/****************************************************************************/
-------------------------------  CONSULTA C  -------------------------------
--Actualizar el stock disponible en un 5%de los productos de la categoría 
--que se provea como argumento de entrada
/****************************************************************************/

GO
create or alter procedure cc_updateStock (@localidad varchar(10), @cat varchar(10),@InstP varchar(max)) as
begin
BEGIN  TRAN
	DECLARE @SQLc nvarchar(max)
	SET @SQLc=
	
	'if exists(select *
		from ['+@InstP+'].AW_Equipo6.Production.ProductInventory as pii
		where pii.LocationID = @localidad and
		ProductID in (
			select ProductID
			from ['+@InstP+'].AW_Equipo6.Production.ProductSubcategory
			where ProductCategoryID = @cat
		)) 
		begin
			update ['+@InstP+'].AW_Equipo6.Production.ProductInventory
			set Quantity = Quantity + ROUND((Quantity * 0.05), 0)
			from ['+@InstP+'].AW_Equipo6.Production.ProductInventory as pii
			where pii.LocationID = @localidad and
			ProductID in (
				select ProductID
				from ['+@InstP+'].AW_Equipo6.Production.ProductSubcategory
				where ProductCategoryID = @cat
			)
		end
	else
		begin
			SELECT NULL
		end'


exec sys.[sp_executesql] @SQLc
COMMIT TRAN
end
/**********************************************************************************************/
EXEC cc_updateStock '60', '1'
go

/**********************************************************************************************/
-- Consulta E
-- Actualizar  la  cantidad  de  productos  de  una  orden  que  se  provea
GO
CREATE OR ALTER PROCEDURE usp_ConsEUpdtSales (@cant varchar(max), @salesID varchar(20), @productID varchar(20), @InstS varchar(max), @InstP varchar(max)) AS
BEGIN
	BEGIN TRAN
	SET NOCOUNT ON
	DECLARE @SQL_CONS1 nVARCHAR(MAX), @SQL_CONS2 nVARCHAR(MAX)
	DECLARE @SQL_UPDT1 nVARCHAR(MAX), @SQL_UPDT2 nVARCHAR(MAX)
	DECLARE @salida_c1 nvarchar(max), @salida_c2 nvarchar(max)
	DECLARE @params_c1 nvarchar(max), @params_c2 nvarchar(max)
	DECLARE @msg varchar(max)

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

					SET @msg = 'Success'
					print 'Success'
				end
			else
				begin 
					SET @msg = 'NoProducts' --Si no hay productos en existencia
					print N'No hay productos en existencia'
				end
		end
	else
		begin
			SET @msg = 'NoOrder'
			print N'El producto no se encuentra en la orden'
		end
		SELECT @msg
COMMIT TRAN
END

go
------------------------------------------------------------------------------------------------------
exec usp_ConsEUpdtSales '5', '43659', '776', 'NEGA-PC', 'NEGA-PC'
go
/****************************************************************************/
-------------------------------  CONSULTA F  -------------------------------
--Actualizar el método de envío de una orden que se reciba como argumento 
--en la instrucción de actualización
/****************************************************************************/
create or alter procedure UpdateShip (@method varchar(20), @salesID varchar(20)) as
begin
begin tran
declare @sqlf nvarchar(max)
set @sqlf =
	'if exists(select * from ['+@InstS+'].AW_Equipo6.Purchasing.ShipMethod
		where ShipMethodID = '+@method+')
		begin
			update ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader
			set ShipMethodID = '+@method+'
			where SalesOrderID = '+@salesID+'
		end
	else
		begin
			select null --En caso de que no exista
		end'
EXEC sys.[sp_executesql] @SQL
commit tran
end
go
------------------------------------------------------------------------------------------------------
select SalesOrderID, ShipMethodID from AdventureWorks2019.Sales.SalesOrderHeader
exec UpdateShip @method = 3,@salesID = 43659
go

/****************************************************************************/
-------------------------------  CONSULTA G  -------------------------------
--Actualizar el correo electrónico de una cliente que se reciba como argumento 
--en la instrucción de actualización
/****************************************************************************/
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

exec UpdateEmail @customerID = 11000, @newemail = 'ejemplo@mail.com'

/****************************************************************************/
-------------------------------  CONSULTA H  -------------------------------
--Determinar el empleado que atendió más ordenes por territorio/región
/****************************************************************************/
create or alter procedure MejorEmpleado (@territory varchar(3)) as
	begin
		begin tran
		declare @sql nvarchar(max)
		set @sql =
			'select top 1 SalesPersonID, count(SalesPersonID) NumPedidos, TerritoryID 
			from ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader
			where TerritoryID = '+@territory+'
			group by SalesPersonID,TerritoryID
			order by NumPedidos desc'
		EXEC sys.[sp_executesql] @SQL
		commit tran
	end
go
------------------------------------------------------------------------------
execute MejorEmpleado @territory= 5

/****************************************************************************/
-------------------------------  CONSULTA I  -------------------------------
--Determinar paraun rango de fechas establecidas como argumento de entrada, 
--cual es el total de las ventasen cada una de las regiones
/****************************************************************************/
Create or Alter procedure Grupos_I (@f1 date, @f2 date, @InstS varchar(max) ) as
	begin
		BEGIN TRAN
		DECLARE @SQLi nvarchar(max)
		SET @SQLi =
		'select t.[Group], sum(sod.LineTotal) as VentasTotales
			from ['+@InstS+'].AW_Equipo6.sales.SalesOrderHeader soh
			inner join ['+@InstS+'].AW_Equipo6.sales.SalesOrderDetail sod
			on soh.SalesOrderID = sod.SalesOrderID
			inner join ['+@InstS+'].AW_Equipo6.sales.SalesTerritory t
			on soh.TerritoryID = t.TerritoryID
			where OrderDate between '+@f1+' AND '+@f2+'
			group by t.[Group]
		'
		
		EXEC sys.[sp.executesql] @SQLi
		COMMIT TRAN
	end

go

------------------------------------------------------------------------------

execute Grupos_I '2011-06-01', '2011-12-31', 'NEGA-PC'
/****************************************************************************/
-------------------------------  CONSULTA J  -------------------------------
--Determinar los5 productos menos vendidos en un rango de fecha 
--establecido como argumento de entrada
/****************************************************************************/
create procedure PeoresVenta (@f1 date, @f2 date) as
begin
	set nocount on;
	select top 5 sod.ProductID, sum(sod.LineTotal) Ventas
	from AdventureWorks2019.Sales.SalesOrderHeader soh
inner join AdventureWorks2019.Sales.SalesOrderDetail sod
	on soh.SalesOrderID = sod.SalesOrderID
	where OrderDate BETWEEN @f1 AND @f2
	group by sod.ProductID
	order by ventas desc
end
go
------------------------------------------------------------------------------
exec PeoresVenta '2011-05-01','2011-05-31';
go


