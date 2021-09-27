/*
	Linxin Liu
	NUID: 001565720
*/

/* Lab 1 - Review of the Data Hierarchy, Data Aggregation and Horizontal Reporting */

-- Question 1 (3 points)

/* Use an AdventureWorks database */
/* The following code creates a longlist report, as listed below. */

use AdventureWorks2017;
/* Part 1 (1 point)
   Please investigate the issue and find out what caused the issue.
   Give a detailed explanation of your findings. Writing some code
   to prove your explanation would be convincing. */
  
  /* Becaus there are multiple SalesOrderID for one CustomerID in SalesOrderHeader, the result is showing multiple lines.
   If we wish to make the result only shows one row of CustomerID, we need to make it join on CustomerID.
   The proof is 
		select distinct sh.CustomerID, sd.SalesOrderID from 
		Sales.SalesOrderHeader sh
		join Sales.SalesOrderDetail sd
		on sh.SalesOrderID=sd.SalesOrderID
	CustomerID SalesOrderID
	11000	43793
	11000	51522
	11000	57418
	11001	43767
	11001	51493
	11001	72773
	11002	43736
	11002	51238
	11002	53237
	11003	43701
	The result shows multiple CustomerID lines as well. 
	When I make it join on CustomerID, the result is one line. */


/* Part 2 (1 point)
   Modify the incorrect solution provided above to create the correct report. */
   with b as (Select sh.CustomerID, sd.ProductID from 
	Sales.SalesOrderHeader sh
	join Sales.SalesOrderDetail sd
	on sh.SalesOrderID=sd.SalesOrderID)

select distinct sh.CustomerID, pp.FirstName,pp.LastName,
stuff((select ', ', rtrim (cast(ProductID as char))
	   from b
	   where b.CustomerID=sh.CustomerID
	   order by sd.ProductID
	   for xml path('')), 1,2,'' ) as Product
from Sales.SalesOrderHeader sh
join 
Sales.SalesOrderDetail sd
on sd.SalesOrderID=sh.SalesOrderID
join Sales.Customer sc
on sc.CustomerID=sh.CustomerID
join Person.Person pp
on pp.BusinessEntityID =sc.PersonID
order by sh.CustomerID;



/* Part 3 (1 point)
   Use STRING_AGG to create the same report */

   select a.CustomerID, pp.FirstName,pp.LastName, a.product from
(select distinct x.CustomerID, STRING_AGG(y.ProductID, ',') as product from Sales.SalesOrderDetail y
	join Sales.SalesOrderHeader x 
	on y.SalesOrderID=x.SalesOrderID
	group by x.CustomerID) a
	join Sales.Customer sc
    on sc.CustomerID=a.CustomerID
    join Person.Person pp
    on pp.BusinessEntityID =sc.PersonID
	order by a.CustomerID



-- Question 2 (3 points)

/*
Write SQL code, containing PIVOT and LAG(), to create the attached report.
*/

/* Pivot table*/
with x as (select yaer as OrderYear, [1] as [1st Quarter], [2] as [2nd Quarter], [3] as [3rd Quarter], [4] as [4th Quarter]
	from (Select
	year(b.OrderDate) as yaer,
	b.q as qm,
	TotalDue
	from (Select OrderDate, (case  when month(OrderDate)=1 then 1
		when month(OrderDate)=2 then 1
		when month(OrderDate)=3 then 1
		when month(OrderDate)=4 then 2
		when month(OrderDate)=5 then 2
		when month(OrderDate)=6 then 2
		when month(OrderDate)=7 then 3
		when month(OrderDate)=8 then 3
		when month(OrderDate)=9 then 3
		when month(OrderDate)=10 then 4
		when month(OrderDate)=11 then 4
		else 4 end
		) as q,
		TotalDue
		from Sales.SalesOrderHeader
	) b
	where year(b.OrderDate) in (2012,2013)
	) as sourcetable 
	pivot ( sum(TotalDue)
	for  qm in ([1], [2], [3], [4]) ) as pivottable)

	/* Main part*/
	select x.OrderYear,
		right('   '+ cast(format(x.[1st Quarter], 'N0')as varchar), 14) as [1st Quarter],
		right('   '+ cast(format(x.[1st Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[1st Quarter] -LAG(x.[4th Quarter], 1, 0 )over (order by x.[1st Quarter] desc), 'N0' ) as varchar), 14)as [4to 1 Change],
		right('   '+ cast(format(x.[2nd Quarter],'N0')as varchar), 14) as [2nd Quarter],
		right('   '+ cast(format(x.[2nd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[2nd Quarter]-x.[1st Quarter], 'N0' ) as varchar), 14)as [1to 2 Change],
		right('   '+ cast(format(x.[3rd Quarter],'N0')as varchar), 14) as [3rd Quarter],
		right('   '+ cast(format(x.[3rd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[3rd Quarter]-x.[2nd Quarter], 'N0' ) as varchar), 14)as [2to 3 Change],
		right('   '+ cast(format(x.[4th Quarter],'N0')as varchar), 14) as [4th Quarter],
		right('   '+ cast(format(x.[4th Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[4th Quarter]-x.[3rd Quarter], 'N0' ) as varchar), 14)as [3to 4 Change],
		right('   '+ cast(format(a.annualsale,'N0' )as varchar), 14) as AnnualSales,
		(case when a.y=2012 and z.y=2012 then 
		right('   '+ cast(format(a.annualsale,'N0' )as varchar), 14)
		when  a.y=2013 and z.y=2012 then 
		right('   '+ cast(format(a.annualsale-z.annualsale, 'N0' ) as varchar), 14)
		end ) as AnnualChange
	from (Select year(OrderDate) as y, 
		sum(TotalDue) as annualsale
		from Sales.SalesOrderHeader
		group by year(OrderDate)
		having year(OrderDate) in (2012,2013)
	) z, x join 
		(Select year(OrderDate) as y, 
		sum(TotalDue) as annualsale
		from Sales.SalesOrderHeader
		group by year(OrderDate)
		having year(OrderDate) in (2012,2013)
	) a
	on x.OrderYear=a.y
	where z.y=2012
	order by OrderYear;