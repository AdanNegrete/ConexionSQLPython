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
from sales.customer c inner join sales.salesorderheader soh
on c.territoryid = soh.territoryid
and c.customerid = soh.customerid

--SQL Dinamico para conectar varias instancias
--Tabla vacia, no hay clientes en orden distinto
--Esa funciona, compara que el cliente sea el mismo y el territorio sea diferente
--D)
select c.customerid
from sales.Customer c inner join sales.SalesOrderHeader soh
on c.TerritoryID != soh.TerritoryID
and c.CustomerID != soh.CustomerID

select * from Sales.SalesTerritory

select t.[group], sod.ProductID, count(ProductId) as col
from sales.SalesOrderDetail sod
inner join sales.SalesOrderHeader soh
on sod.SalesOrderID = soh.SalesOrderID
inner join sales.SalesTerritory t
on soh.TerritoryID = t.TerritoryID
group by t.[Group], sod.ProductID
having count(sod.ProductID) = (select max(col) from ())