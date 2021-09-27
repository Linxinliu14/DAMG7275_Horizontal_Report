
/* Lab 1 - Review of the Data Hierarchy, Data Aggregation and Horizontal Reporting */

-- Question 1 (3 points)

/* Use an AdventureWorks database */
/* The following code creates a longlist report, as listed below. */

use AdventureWorks2017;

SELECT DISTINCT h.CustomerID, p.FirstName, p.LastName, d.ProductID
FROM Sales.SalesOrderHeader h
JOIN Sales.Customer c
ON h.CustomerID = c.CustomerID
join Sales.SalesOrderDetail d
on d.SalesOrderID=h.SalesOrderID
JOIN Person.Person p
ON c.PersonID = p.BusinessEntityID
ORDER BY h.CustomerID;

/*
CustomerID	FirstName	LastName	ProductID
11000		Jon			Yang		707
11000		Jon			Yang		771
11000		Jon			Yang		779
11000		Jon			Yang		878
11000		Jon			Yang		881
11000		Jon			Yang		923
11000		Jon			Yang		934
11000		Jon			Yang		966
11001		Eugene		Huang		708
11001		Eugene		Huang		712
11001		Eugene		Huang		777
11001		Eugene		Huang		779
11001		Eugene		Huang		870
11001		Eugene		Huang		871
11001		Eugene		Huang		872
11001		Eugene		Huang		878
11001		Eugene		Huang		884
11001		Eugene		Huang		997
*/

/* We want to create a shortlist report containing the same data
   without duplicating the customer info. The code below tried to do it
   but the generated report had an issue. It duplicated some
   customer info, as listed below. */

select distinct sh.CustomerID, pp.FirstName,pp.LastName,
stuff((select ', ', rtrim (cast(ProductID as char))
	   from Sales.SalesOrderDetail  
	   where SalesOrderID= sh.SalesOrderID
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

/*
CustomerID	FirstName	LastName	Product
11003		Christy		Zhu			773
11003		Christy		Zhu			783, 871, 870, 712
11003		Christy		Zhu			957, 934, 923, 873
11004		Elizabeth	Johnson		772
11004		Elizabeth	Johnson		780, 878, 707
11004		Elizabeth	Johnson		955, 708
11005		Julio		Ruiz		778
11005		Julio		Ruiz		780, 930, 921, 873
11005		Julio		Ruiz		955
*/


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
		right('   '+ cast(format(x.[1st Quarter]-LAG(x.[1st Quarter],1,0) over (order by x.[1st Quarter] desc), 'N0' ) as varchar), 14)as [4to 1 Change],
		right('   '+ cast(format(x.[2nd Quarter],'N0')as varchar), 14) as [2nd Quarter],
		right('   '+ cast(format(x.[2nd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[2nd Quarter]-LAG(x.[2nd Quarter],1,0) over (order by x.[2nd Quarter] desc), 'N0' ) as varchar), 14)as [1to 2 Change],
		right('   '+ cast(format(x.[3rd Quarter],'N0')as varchar), 14) as [3rd Quarter],
		right('   '+ cast(format(x.[3rd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[3rd Quarter]-LAG(x.[3rd Quarter],1,0) over (order by x.[3rd Quarter] desc), 'N0' ) as varchar), 14)as [2to 3 Change],
		right('   '+ cast(format(x.[4th Quarter],'N0')as varchar), 14) as [4th Quarter],
		right('   '+ cast(format(x.[4th Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[4th Quarter]-LAG(x.[4th Quarter],1,0) over (order by x.[4th Quarter] desc), 'N0' ) as varchar), 14)as [3to  Change],
		right('   '+ cast(format(a.annualsale,'N0' )as varchar), 14) as AnnualSales,
		right('   '+ cast(format(a.annualsale-LAG(a.annualsale,1,0) over (order by a.annualsale desc), 'N0' ) as varchar), 14) as AnnualChange
	from x join 
		(Select year(OrderDate) as y, 
		sum(TotalDue) as annualsale
		from Sales.SalesOrderHeader
		group by year(OrderDate)
		having year(OrderDate) in (2012,2013)
	) a
	on x.OrderYear=a.y
	where OrderYear in (2012,2013)
	order by OrderYear

