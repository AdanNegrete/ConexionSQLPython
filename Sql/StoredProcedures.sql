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

--Procedimiento de listado de las Regiones (SalesTerritory)
GO
CREATE OR ALTER PROCEDURE usp_RegionList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT [Group] FROM ['+@Inst+'].AW_Equipo6.Sales.SalesTerritory Group By [Group];'
    EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END

--Procedimiento de listado de los localidades
GO
CREATE OR ALTER PROCEDURE usp_LocationList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT locationid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.Production.Location Order By id;'
    EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END

--Procedimiento de listado de Métodos
GO
CREATE OR ALTER PROCEDURE usp_MethodList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT shipmethodid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.Other.ShipMethod Order By id;'
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
GO
CREATE OR ALTER PROCEDURE usp_ConsBProdSol @p_group varchar(50), @InstS varchar(max), @InstP varchar(max) AS
BEGIN
	BEGIN TRAN
	DECLARE @SQL nvarchar(max)
	IF @p_group = 'North'
		SET @p_group = 'North America'
	SET @SQL =
		'SELECT TOP 1 SUM(Terr.lineTotal) as TVentas, Prod.Name as Producto, Prod.ProductID as Id
		FROM ['+@InstP+'].AW_Equipo6.Production.Product Prod
		inner join
		(SELECT	ProductID, lineTotal 
			FROM ['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail sod
			WHERE SalesOrderID in
				(SELECT	SalesOrderID FROM ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader soh
				WHERE TerritoryID in
					(SELECT	TerritoryID	FROM ['+@InstS+'].AW_Equipo6.Sales.SalesTerritory st
					WHERE [Group] = '''+@p_group+'''))) as Terr
		ON Prod.ProductID = Terr.ProductID
		GROUP BY Prod.Name,	Prod.ProductID
		ORDER by TVentas DESC'
	EXEC sys.[sp_executesql] @SQL
	COMMIT TRAN
END 

-- Se realizó un procedimiento adicional en esta consulta para obtener el territorio con más demanda
GO
CREATE OR ALTER PROCEDURE usp_ConsBTerr @p_group varchar(50),@id_prod varchar(20), @InstS varchar(max) AS
BEGIN
	BEGIN TRAN
	DECLARE @SQL nvarchar(max)
	IF @p_group = 'North'
		SET @p_group = 'North America'
	SET @SQL =
		'SELECT st.[name] as Territory FROM ['+@InstS+'].AW_Equipo6.SALES.SalesTerritory as st
		INNER JOIN
			(SELECT TOP 1 sum(a.linetotal) as TVentas,sh.territoryid
			FROM ['+@InstS+'].AW_Equipo6.SALES.SalesOrderHeader sh 
			Inner join
				(SELECT salesorderid, linetotal 
				FROM ['+@InstS+'].AW_Equipo6.Sales.SalesOrderDetail sod
				WHERE SalesOrderID in
					(SELECT	SalesOrderID FROM ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader soh
					WHERE TerritoryID in
						(SELECT	TerritoryID	FROM ['+@InstS+'].AW_Equipo6.Sales.SalesTerritory
						WHERE [Group] = '''+ @p_group +''')) 
				AND productid = '+@id_prod+') as A
			on a.salesorderid=sh.Salesorderid
			GROUP BY sh.territoryid
			ORDER BY TVentas DESC) AS T
		ON st.territoryid=T.territoryid'
	EXEC sys.[sp_executesql] @SQL
	COMMIT TRAN
END 
------------------------------------------------------------------------------------------------------
EXECUTE usp_ConsBProdSol 'North America', 'SALESEX', 'PRODUCTIONEX'
EXECUTE usp_ConsBTerr 'North America','782', 'SALESEX'
/****************************************************************************/
-------------------------------  CONSULTA C  -------------------------------
--Actualizar el stock disponible en un 5%de los productos de la categoría 
--que se provea como argumento de entrada
/****************************************************************************/

GO
create or alter procedure usp_ConsCUpdtProd (@localidad varchar(30), @cat varchar(30),@InstP varchar(max)) as
begin
BEGIN  TRAN
	SET NOCOUNT ON
	set xact_abort on
	DECLARE @SQL nvarchar(max)
	DECLARE @salida_c1 nvarchar(max)
	DECLARE @params_c1 nvarchar(max)
	SET @params_c1 = N'@salida_out_1 nvarchar(max) OUTPUT'

	SET @SQL=
	
	'if exists(select *	from ['+@InstP+'].AW_Equipo6.Production.ProductInventory as pii
				where pii.LocationID = '+@localidad+' and ProductID in 
					(select ProductID from ['+@InstP+'].AW_Equipo6.Production.ProductSubcategory
						where ProductCategoryID = '+@cat+')) 
		begin
			update ['+@InstP+'].AW_Equipo6.Production.ProductInventory
			set Quantity = Quantity + ROUND((Quantity * 0.05), 0)
			from ['+@InstP+'].AW_Equipo6.Production.ProductInventory as pii
			where pii.LocationID = '+@localidad+' and ProductID in 
				(select ProductID from ['+@InstP+'].AW_Equipo6.Production.ProductSubcategory
					where ProductCategoryID = '+@cat+')
			SET @salida_out_1 = ''Success''
		end
	else
		begin
			SET @salida_out_1 = ''NoProducts''
		end'
	exec sys.[sp_executesql] @SQL,@params_c1,@salida_out_1 = @salida_c1 OUTPUT


	SELECT @salida_c1

	set xact_abort off
COMMIT TRAN
END
/**********************************************************************************************/
EXEC usp_ConsCUpdtProd '60', '1', 'NEGA-PC'
select * from AW_Equipo6.Production.ProductInventory as pii
				where pii.LocationID = '5' and ProductID in 
					(select ProductID from AW_Equipo6.Production.ProductSubcategory
						where ProductCategoryID = '3')
go

/**********************************************************************************************/
-- Consulta E
-- Actualizar  la  cantidad  de  productos  de  una  orden  que  se  provea
GO
CREATE OR ALTER PROCEDURE usp_ConsEUpdtSales (@cant varchar(max), @salesID varchar(20), @productID varchar(20), @InstS varchar(max), @InstP varchar(max)) AS
BEGIN
	BEGIN TRAN
	SET NOCOUNT ON
	--set xact_abort on
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
					begin try
						--actualizando venta
						EXEC sys.[sp_executesql] @SQL_UPDT1;

						--Cambiar el Stock del producto
						EXEC sys.[sp_executesql] @SQL_UPDT2;

						SET @msg = 'Success'
						print 'Success'
					end try
					begin catch 
						SET @msg = 'Fallo en la actualización'
					end catch
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
		--set xact_abort off
COMMIT TRAN
END

go
------------------------------------------------------------------------------------------------------
exec usp_ConsEUpdtSales '5', '45167', '750', 'NEGA-PC', 'NEGA-PC'
select * from [NEGA-PC].AW_Equipo6.SALES.SalesOrderDetail;
go
/****************************************************************************/
-------------------------------  CONSULTA F  -------------------------------
--Actualizar el método de envío de una orden que se reciba como argumento 
--en la instrucción de actualización
/****************************************************************************/
CREATE OR ALTER PROCEDURE usp_ConsFUpdtMet (@method varchar(50), @salesID varchar(50), @InstS varchar(max),@InstO varchar(max)) as
BEGIN
	BEGIN TRAN
	SET NOCOUNT ON
	set xact_abort ON
	DECLARE @SQL nvarchar(max)
	DECLARE @salida_c1 nvarchar(max)
	DECLARE @params_c1 nvarchar(max)
	SET @params_c1 = N'@salida_out_1 nvarchar(max) OUTPUT'

	SET @SQL =
		'if exists(select * from ['+@InstO+'].AW_Equipo6.Other.ShipMethod
			where ShipMethodID = '+@method+')
			begin
				update ['+@InstS+'].AW_Equipo6.Sales.SalesOrderHeader
				set ShipMethodID = '+@method+'
				where SalesOrderID = '+@salesID+';

				SET @salida_out_1 = ''Success''
			end
		else
			begin
				SET @salida_out_1 = ''NotOrder''
			end'
	EXEC sys.[sp_executesql] @SQL,@params_c1,@salida_out_1 = @salida_c1 OUTPUT

	SELECT @salida_c1
	COMMIT TRAN
	set xact_abort OFF
END
go
------------------------------------------------------------------------------------------------------
select SalesOrderID, ShipMethodID from AW_Equipo6.Sales.SalesOrderHeader WHERE Salesorderid='43659'
exec usp_ConsFUpdtMet '3','43659', 'NEGA-PC','NEGA-PC'
exec usp_MethodList 'NEGA-PC'
go

/****************************************************************************/
-------------------------------  CONSULTA G  -------------------------------
--Actualizar el correo electrónico de una cliente que se reciba como argumento 
--en la instrucción de actualización
/****************************************************************************/
CREATE OR ALTER PROCEDURE usp_ConsGUpdtEml (@customerID varchar(30), @newEmail nvarchar(50), @InstS varchar(max),@InstO varchar(max)) as
BEGIN
	BEGIN TRAN

	SET NOCOUNT ON
	set xact_abort ON
	DECLARE @SQL nvarchar(max)
	DECLARE @salida_c1 nvarchar(max)
	DECLARE @params_c1 nvarchar(max)

	SET @params_c1 = N'@salida_out_1 nvarchar(max) OUTPUT'
	
	SET @SQL =
		'if exists(select * from ['+@InstS+'].AW_Equipo6.Sales.Customer
		where CustomerID = '+@customerID+' and PersonID is not null)
			begin
				update ['+@InstO+'].AW_Equipo6.Other.EmailAddress	
				set EmailAddress = '''+@newEmail+'''
				where BusinessEntityID = (
					select PersonID from ['+@InstS+'].AW_Equipo6.Sales.Customer
					where CustomerID = '+@customerID+')

					SET @salida_out_1 = ''Success''
			end
		else
			begin
				SET @salida_out_1 = ''NoCustomer''
			end'
	
	EXEC sys.[sp_executesql] @SQL,@params_c1,@salida_out_1 = @salida_c1 OUTPUT

	SELECT @salida_c1
	COMMIT TRAN
	set xact_abort OFF
END
go

exec usp_ConsGUpdtEml '11000', 'ejemplo@mail.com', 'NEGA-PC', 'NEGA-PC'
SELECT p.FIRSTNAME, ea.EmailAddress, cum.customerid FROM Other.Person as p
inner join Other.EmailAddress AS ea ON ea.BusinessEntityID=p.BusinessEntityID
inner join sales.customer AS cum ON cum.personid = ea.BusinessEntityID
where cum.customerid='11000'

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


