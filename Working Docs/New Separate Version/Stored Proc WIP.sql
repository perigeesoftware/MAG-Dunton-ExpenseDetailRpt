declare @YearEnd date = '2024-12-01'			
Declare @EndDt date = dateadd(dd,-1,dateadd(mm,1,@YearEnd))			
DECLARE @BegDt date = dateadd(dd,1,dateadd(yy,-1,@EndDt))			
DECLARE @Diff numeric(10,4) = datediff(day,@BegDt, @EndDt) + 1			
			
WITH CTE_Pool as (
select x.*, CONVERT(Numeric(10,8),AmendmentDays / @Diff) as CalcFactor 			
FROM (			
select ca.hmy as hAmendment
  	, t.hmyperson as hTenant		
  	, t.scode as TenantCode		
	, ux.hUnit, ux.hAmendment as uxAmendment, ux.dtLeaseFrom, ux.dtLeaseTo, ux.dSqFt, ca.dcontractarea		
  , YEAR(ISNULL(ca.DtEnd,'2199-12-31')) as YrEnd 		
  	, ca.iStatus, cs.sStatus as AmendStatus, ca.iType, ct.type as AmendType, ca.iSequence, ca.dtStart, ca.dtEnd, ca.dtMoveOut, ca.bReplaceAll, ca.sDesc		
	, CASE 
  		WHEN ISNULL(ca.dtStart,'1910-01-01') = ISNULL(ca.dtEnd,'2199-12-31') 
  		THEN 0
	    WHEN ISNULL(ca.dtStart,'1910-01-01') >= @BegDt and  ISNULL(ca.dtEnd,'2199-12-31') <= @EndDt
  		THEN DATEDIFF(d,ca.dtStart,ca.dtEnd) + 1			
  		WHEN ISNULL(ca.dtStart,'1910-01-01') < @BegDt AND ISNULL(ca.dtEnd,'2199-12-31') <= @EndDt		
		THEN DATEDIFF(d,@BegDt,ca.dtEnd) + 1 	
		WHEN ISNULL(ca.dtStart,'1910-01-01') >= @BegDt and ISNULL(ca.dtEnd,'2199-12-31') >= @BegDt AND ISNULL(ca.dtEnd,'2199-12-31') >= @EndDt   	
		THEN DATEDIFF(d,ca.dtStart,@EndDt) + 1	
  		ELSE @Diff END as AmendmentDays	
  	, YEAR(ISNULL(ca.dtEnd,'2199-12-31')) as AmendEndYear
  	--, ca.*                           		
from tenant T			
inner join commamendments ca			
	on t.hmyperson = ca.htenant		
inner join commamendmenttype ct
  	on ct.itype = ca.itype
inner join commamendmentstatus cs
  	on cs.istatus = ca.istatus
INNER JOIN unitxref ux
  	on ca.hmy = ux.hAmendment
  	and ux.dtLeaseTo >= @BegDt
where t.scode in ('gscouts','itrans','quiat','wekick')			
--and ca.itype in (0,1,2,3,6) /* 0 Original, 1 Renewal, 2 Expansion, 3 Contraction, 6 Modification) */			
--and ca.iStatus in (1,2) /* 1 Activated, 2 Superseded */			
and (
  	   (ISNULL(ca.dtStart,'1910-01-01') <= @EndDt AND ISNULL(ca.dtEnd,'2199-12-31') >= @EndDt)  -- spans entire Year			
	OR (ISNULL(ca.dtStart,'1910-01-01') >= @BegDt AND ISNULL(ca.dtStart,'1910-01-01') <= @EndDt) -- starts within Year
    OR (ISNULL(ca.dtStart,'1910-01-01') <= @BegDt AND ISNULL(ca.dtEnd,'1910-01-01') >= @BegDt AND ISNULL(ca.dtEnd,'1910-01-01') <= @EndDt) -- ends within Year
    OR (ISNULL(ca.dtStart,'1910-01-01') >= @BegDt AND ISNULL(ca.dtEnd,'2199-12-31') <= @EndDt)	-- starts and ends Year
	)
) X
WHERE x.AmendmentDays > 0
)

, CTE_AmendmentDetail AS (
select c.*, tsf.TotSqFt, convert(Numeric(10,8),c.dSqFt / tsf.TotSqFt) as SqFtFactor
FROM CTE_Pool C
INNER JOIN (
  		SELECT hTenant, Sum(dSqFt) as TotSqFt
  		FROM (SELECT distinct hTenant, hUnit, dSqFt from CTE_Pool) P
  		GROUP BY hTenant
  	) TSF
    on c.htenant = tsf.htenant
WHERE c.iSequence = (select max(d.iSequence) from CTE_Pool D
                      where c.htenant = d.htenant
                      and c.hunit = d.hunit
                      and c.dtLeaseFrom = d.dtLeaseFrom
                      and c.dtLeaseTo = d.dtLeaseTo)
and c.dSqFt <> 0
)

select * from cte_amendmentdetail
  order by TenantCode, hAmendment			

