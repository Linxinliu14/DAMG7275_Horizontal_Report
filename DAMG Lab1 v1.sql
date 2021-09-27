Use AdventureWorks2017;

Select * from Sales.SalesOrderHeader;
select * from Sales.SalesOrderDetail;
Select * from Sales.Customer;
Select distinct x.CustomerID, z.SalesOrderID from (select distinct CustomerID from Sales.SalesOrderHeader) x 
join Sales.SalesOrderHeader z
on z.CustomerID=x.CustomerID
join Sales.SalesOrderDetail y 
on z.SalesOrderID=y.SalesOrderID 
order by x.CustomerID;

with a as (Select x.CustomerID, y.FirstName,y.LastName from 
Sales.Customer x
join Person.Person y
on x.PersonID=y.BusinessEntityID);

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



select distinct x.CustomerID, STRING_AGG(y.ProductID, ',') as product from Sales.SalesOrderDetail y
join Sales.SalesOrderHeader x 
on y.SalesOrderID=x.SalesOrderID
group by x.CustomerID
order by x.CustomerID 


with a as (Select year(OrderDate) as y, 
		sum(TotalDue) as annualsale
		from Sales.SalesOrderHeader
		group by year(OrderDate)
		having year(OrderDate) in (2012,2013)
	)

	Select  c.yaer, 
	c.q, 
	c.quater, 
	right('   '+ cast(format(c.quater/a.annualsale, 'P2')as varchar), 14) as annual,
	c.change
	from (Select
	year(b.OrderDate) as yaer,
	b.q,
	right('   '+ cast(format(sum(b.TotalDue), 'N0')as varchar), 14) as quater, 
	right('   '+ cast(format(sum(b.TotalDue)-LAG(sum(b.TotalDue),1,0) over (order by sum(TotalDue) desc), 'N0' ) as varchar), 14)as change
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
	group by year(b.OrderDate),b.q 
	having year(b.OrderDate) in (2012,2013)
	) c, a
	where a.y=c.yaer
	order by c.yaer, c.q

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

	select x.OrderYear,
		format(x.[1st Quarter], 'N0') as [1st Quarter],
		right('   '+ cast(format(x.[1st Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[1st Quarter]-LAG(x.[1st Quarter],1,0) over (order by x.[1st Quarter] desc), 'N0' ) as varchar), 14)as [4to 1 Change],
		format(x.[2nd Quarter],'N0') as [2nd Quarter],
		right('   '+ cast(format(x.[2nd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[2nd Quarter]-LAG(x.[2nd Quarter],1,0) over (order by x.[2nd Quarter] desc), 'N0' ) as varchar), 14)as [1to 2 Change],
		format(x.[3rd Quarter],'N0') as [3rd Quarter],
		right('   '+ cast(format(x.[3rd Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[3rd Quarter]-LAG(x.[3rd Quarter],1,0) over (order by x.[3rd Quarter] desc), 'N0' ) as varchar), 14)as [2to 3 Change],
		format(x.[4th Quarter],'N0') as [4th Quarter],
		right('   '+ cast(format(x.[4th Quarter]/a.annualsale , 'P2')as varchar), 14) as [Annual %],
		right('   '+ cast(format(x.[4th Quarter]-LAG(x.[4th Quarter],1,0) over (order by x.[4th Quarter] desc), 'N0' ) as varchar), 14)as [3to  Change],
		format(a.annualsale,'N0' ) as AnnualSales,
		right('   '+ cast(format(a.annualsale-LAG(a.annualsale,1,0) over (order by a.annualsale desc), 'N0' ) as varchar), 14) as AnnualChange
	from x join (Select year(OrderDate) as y, 
		sum(TotalDue) as annualsale
		from Sales.SalesOrderHeader
		group by year(OrderDate)
		having year(OrderDate) in (2012,2013)
	) a
	on x.OrderYear=a.y
	where OrderYear in (2012,2013)
	order by OrderYear
	
		