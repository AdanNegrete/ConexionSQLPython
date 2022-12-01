/*resta de conjuntos*/

select distinct b.TerritoryID from (
select territoryid
from sales.Customer
where customerid = '9') as a
inner join  (select territoryID
from sales.SalesOrderHeader
where CustomerID = '9') as b
on a.TerritoryID=b.TerritoryID


select c.customerid
from AdventureWorks2019.sales.customer c inner join AdventureWorks2019.sales.salesorderheader soh
on c.territoryid = soh.territoryid
and c.customerid = soh.customerid

--SQL Dinamico para conectar varias instancias
--Tabla vacia, no hay clientes en orden distinto
--Esa funciona, compara que el cliente sea el mismo y el territorio sea diferente
--D)
select c.customerid
from AdventureWorks2019.sales.Customer c inner join AdventureWorks2019.sales.SalesOrderHeader soh
on c.TerritoryID != soh.TerritoryID
and c.CustomerID != soh.CustomerID

select * from Sales.SalesTerritory

select t.[group], sod.ProductID, count(ProductId) as col
from AdventureWorks2019.sales.SalesOrderDetail sod
inner join AdventureWorks2019.sales.SalesOrderHeader soh
on sod.SalesOrderID = soh.SalesOrderID
inner join AdventureWorks2019.sales.SalesTerritory t
on soh.TerritoryID = t.TerritoryID
group by t.[Group], sod.ProductID
having count(sod.ProductID) = (select max(col) from ())

/**********************************************************************************************/
--A

select soh.TerritoryID, sum(a.LineTotal) as total_venta
from AdventureWorks2019.sales.SalesOrderHeader soh
inner join
(select salesorderid, productid, orderqty, linetotal
from AdventureWorks2019. sales.salesorderdetail sod
where ProductID in (
		select productid
		from AdventureWorks2019.Production.Product
		where ProductSubcategoryID in (
			select ProductSubcategoryID
			from AdventureWorks2019.Production.ProductSubcategory
			where ProductCategoryID in (
				select ProductCategoryID
				from AdventureWorks2019.Production.ProductCategory
				where ProductCategoryID = 1
				)))) as a
inner join
(select [name], TerritoryID 
from AdventureWorks2019.sales.SalesTerritory
) as b
on TerritoryID = b.TerritoryID
on soh.SalesOrderID = a.SalesOrderID
group by soh.TerritoryID
order by soh.TerritoryID
go

/**********************************************************************************************/
--B

/**********************************************************************************************/
--C

create or alter procedure cc_updateLocation (@localidad int, @cat int) as
begin
	if exists(select *
		from AdventureWorks2017.Production.ProductInventory as pii
		where pii.LocationID = @localidad and
		ProductID in (
			select ProductID
			from AdventureWorks2017.Production.ProductSubcategory
			where ProductCategoryID = @cat
		)) 
		begin
			update AdventureWorks2017.Production.ProductInventory
			set Quantity = Quantity + ROUND((Quantity * 0.05), 0)
			from AdventureWorks2017.Production.ProductInventory as pii
			where pii.LocationID = @localidad and
			ProductID in (
				select ProductID
				from AdventureWorks2017.Production.ProductSubcategory
				where ProductCategoryID = @cat
			)
		end
	else
		begin
			SELECT NULL
		end
end

exec cc_updateLocation @localidad = 60, @cat = 1

/**********************************************************************************************/
--D

select t.[group], sod.ProductID, count(ProductId) as col
from AdventureWorks2019.sales.SalesOrderDetail sod
inner join AdventureWorks2019.sales.SalesOrderHeader soh
on sod.SalesOrderID = soh.SalesOrderID
inner join AdventureWorks2019.sales.SalesTerritory t
on soh.TerritoryID = t.TerritoryID
group by t.[Group], sod.ProductID
/**********************************************************************************************/
--E
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

/**********************************************************************************************/
--F


/**********************************************************************************************/
--G


/****************************************************************************/
-------------------------------  CONSULTA H  -------------------------------
/****************************************************************************/
create procedure MejorEmpleado (@territory varchar(3)) as
	begin
		select top 1 SalesPersonID, count(SalesPersonID) NumPedidos, TerritoryID 
		from AdventureWorks2019.Sales.SalesOrderHeader
		where TerritoryID = @territory
		group by SalesPersonID,TerritoryID
		order by NumPedidos desc
	end
go
------------------------------------------------------------------------------
execute MejorEmpleado @territory= 5

/****************************************************************************/
-------------------------------  CONSULTA I  -------------------------------
/****************************************************************************/
create procedure GruposI (@f1 varchar(50), @f2 varchar(50)) as
	begin
		select t.[Group], sum(sod.LineTotal) as VentasTotales
		from AdventureWorks2019.sales.SalesOrderHeader soh
		inner join AdventureWorks2019.sales.SalesOrderDetail sod
		on soh.SalesOrderID = sod.SalesOrderID
		inner join AdventureWorks2019.sales.SalesTerritory t
		on soh.TerritoryID = t.TerritoryID
		where OrderDate between @f1 AND @f2
		group by t.[Group]
	end
go
------------------------------------------------------------------------------
execute GruposI @f1 = '2011-06-01', @f2 = '2011-12-31'

/****************************************************************************/
-------------------------------  CONSULTA J  -------------------------------
/****************************************************************************/
create procedure PeoresVentas (@f1 date, @f2 date) as
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
exec JFechas'2011-05-01','2011-05-31';
go

