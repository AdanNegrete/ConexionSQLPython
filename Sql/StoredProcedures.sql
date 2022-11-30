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
-- Consulta E
-- Actualizar  la  cantidad  de  productos  de  una  orden  que  se  provea
create procedure EUpdateSales (@cant int, @salesID int, @productID int) as
begin
	
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

					 --asignando a que locación se le retirará stock
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