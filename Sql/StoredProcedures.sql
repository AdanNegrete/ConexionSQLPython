--Procedimiento de listado de los territorios
CREATE OR ALTER PROCEDURE usp_TerritoryList @Inst varchar(max) AS
BEGIN
BEGIN TRAN
	DECLARE @SQL nvarchar(MAX)
	SET @SQL = 'SELECT territoryid as id, [name] as name FROM ['+@Inst+'].AW_Equipo6.sales.SalesTerritory;'
    EXEC sys.[sp_executesql] @SQL
COMMIT TRAN
END


/**********************************************************************************************/
--A
--Creacion del sp para realizar la consulta remota
create procedure ATotalProductos (@cat int) as
begin
	select soh.TerritoryID, sum(a.LineTotal) as VentasTotales
	from AdventureWorks2019.Sales.SalesOrderHeader soh
	inner join
	(select salesorderid, productid, orderqty, linetotal
	from AdventureWorks2019.Sales.salesorderdetail sod
	where ProductID in (
			select productid
			from AdventureWorks2019.Production.Product
			where ProductSubcategoryID in (
				select ProductSubcategoryID
				from AdventureWorks2019.Production.ProductSubcategory
				where ProductCategoryID in (
					select ProductCategoryID
					from AdventureWorks2019.Production.ProductCategory
					where ProductCategoryID = @cat 
					)))) as a
	on soh.SalesOrderID = a.SalesOrderID
	group by soh.TerritoryID
	order by soh.TerritoryID
end
go
--Ejecucion del SP
exec ATotalProductos 1
go
