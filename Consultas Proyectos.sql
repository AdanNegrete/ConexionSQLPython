select soh.TerritoryID, sum(a.LineTotal) as VentasTotales
from AdventureWorks2019.sales.SalesOrderHeader soh
inner join
(select salesorderID, productID, orderqty, linetotal
from AdventureWorks2019. sales.salesorderdetail sod
where ProductID in (
		select productID
		from AdventureWorks2019.Production.Product
		where ProductSubcategoryID in (
			select ProductSubcategoryID
			from AdventureWorks2019.Production.ProductSubcategory
			where ProductCategoryID in (
				select ProductCategoryID
				from AdventureWorks2019.Production.ProductCategory
				where ProductCategoryID = 1
				)))) as a
inner join (
	select [name], TerritoryID 
	from AdventureWorks2019.sales.SalesTerritory
	) as b
on soh.SalesOrderID = a.SalesOrderID
on TerritoryID = b.TerritoryID
group by soh.TerritoryID
order by soh.TerritoryID