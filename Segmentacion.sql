CREATE DATABASE AW_Equipo6

USE AW_Equipo6

/************************************************
    Segmentación del esquema PRODUCTION
***********************************************/
--Creacion esquema en BD Production
go
Create schema Production
go
------------------------------------------------------------------------------ LISTO
--Mete los datos dentro del esquema desde la BD del LS
select productid, name, productnumber, color, safetystocklevel,
   standardcost, listprice, size, productsubcategoryid,
   productmodelid, sellstartdate, sellenddate, discontinueddate
   into Production.Product
   from AdventureWorks2019.production.product
	--Ver que los datos se copiaron del LS al esquema
select * from Production.product
------------------------------------------------------------------------------ LISTO
select productcategoryid, name
   into Production.ProductCategory
   from AdventureWorks2019.production.ProductCategory
	--Ver que los datos se copiaron del LS al esquema
select * from Production.ProductCategory
------------------------------------------------------------------------------ LISTO
select productdescriptionid, description 
	into Production.ProductDescription
	from AdventureWorks2019.production.ProductDescription
	--Ver que los datos se copiaron del LS al esquema
select * from Production.ProductDescription
------------------------------------------------------------------------------ LISTO
select productid, locationid, shelf, bin, quantity 
	into Production.ProductInventory
	from AdventureWorks2019.production.ProductInventory
	--Ver que los datos se copiaron del LS al esquema
select * from production.ProductInventory
------------------------------------------------------------------------------ LISTO
select locationid, name, costrate, availability
	into Production.Location
	from AdventureWorks2019.production.Location
	--Ver que los datos se copiaron del LS al esquema
select * from production.Location

/************************************************
    Segmentación del esquema SALES
***********************************************/
go
Create schema sales
go
------------------------------------------------------------------------------ LISTO
select Salesorderid, orderdate, duedate, shipdate
   status, OnlineOrderFlag, salesordernumber,
   purchaseordernumber, accountnumber, customerid,
   salespersonid, territoryid,  currencyrateID,
   subtotal, TaxAmt, freight, totaldue 
   into Sales.SalesOrderHeader
   --from LinkedServer.AdventureWorks2019.Sales.SalesOrderHeader
   from AdventureWorks2019.Sales.SalesOrderHeader
   Select * from sales.SalesOrderHeader

------------------------------------------------------------------------------ LISTO
select salesorderid, salesorderdetailid, 
   carriertrackingnumber, orderqty, productid,
   specialofferid, unitprice, unitpriceDiscount,
   linetotal 
   into Sales.SalesOrderDetail
   --from LinkedServer.AdventureWorks2019.sales.SalesOrderDetail
   from AdventureWorks2019.sales.SalesOrderDetail
   select * from sales.SalesOrderDetail

------------------------------------------------------------------------------ LISTO
select specialofferid, description, discountpct, type, category,
   startdate, enddate, minqty, maxqty
   into Sales.SpecialOffer
   from AdventureWorks2019.sales.SpecialOffer
   --Ver que los datos se copiaron del LS al esquema
   select * from Sales.SpecialOffer

------------------------------------------------------------------------------ LISTO
select specialofferid, productid 
	into sales.SpecialOfferProduct
	from AdventureWorks2019.sales.SpecialOfferProduct
select * from  sales.SpecialOfferProduct

------------------------------------------------------------------------------ LISTO
select businessEntityID, territoryID, salesQuota, bonus, CommissionPct,
  salesytd, saleslastyear
  into sales.SalesPerson
  from AdventureWorks2019.sales.SalesPerson
select * from  sales.SalesPerson

------------------------------------------------------------------------------ LISTO
select customerid, personid, storeid, territoryid, accountnumber
	into sales.customer
	from AdventureWorks2019.sales.customer
select * from  sales.customer

------------------------------------------------------------------------------ LISTO

select businessentityid, name,  salespersonid 
	into Sales.Store
	from AdventureWorks2019.sales.store
select * from  sales.Store

------------------------------------------------------------------------------ LISTO
select territoryid, [name], countryregioncode, [Group], salesytd,
	saleslastyear, costytd, costlastyear
	INTO sales.SalesTerritory
	from AdventureWorks2019.sales.SalesTerritory
select * from  sales.SalesTerritory

------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
------------------------------------------------------------------------------
							--TRIGGERS
/*
	Creacion de FK entre sales.offerprodcut y production.product
	FALTAN 8 TRIGGERS EN VENTAS
*/
go
create trigger tr_fk_sop_product on sales.specialofferproduct
for insert, update as
if not exists (select productID
			from Productionbd.Production.Product
			where ProductID in (select ProductID
								from inserted)
			)
			rollback --No se puede en MySQL
--intead of: Ejecutar cuerpo de trigger en lugar del disparador (solo 1 por tabla)

/************************************************
    Segmentación del esquema OTHER
***********************************************/

