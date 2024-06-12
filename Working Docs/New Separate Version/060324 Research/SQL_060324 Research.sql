declare @YearEnd date = '2023-12-01'--'#yearend#'
Declare @EndDt date = dateadd(dd,-1,dateadd(mm,1,@YearEnd))
DECLARE @BegDt date = dateadd(dd,1,dateadd(yy,-1,@EndDt))
DECLARE @Diff numeric(10,4) = datediff(day,@BegDt, @EndDt) + 1

--select @YearEnd YearEnd, @EndDt EntDt, @BegDt BegDt, @Diff Diff

--select a.
--from 
--(
  Select   '1' ord, p.hmy                 			        phmy  
	,ltrim(rtrim(p.scode))				        pcode  
	,ltrim(rtrim(p.saddr1))			        	PropertyDesc 
	,t.hmyperson						thmy
	,ltrim(rtrim(isnull(t.scode,''))) 					tscode
	,cep.hmy 			                        ExpPoolId  
	,ltrim(rtrim(cep.scode)) 			        ExpPoolCode  
	,ltrim(rtrim(cep.sdesc)) 			        ExpDesc
	,ltrim(rtrim(a.hChart)) 			        ChartId  
	,convert(nvarchar(100),a.hmy)				hAcct
	,ltrim(rtrim(a.scode)) 			        	AcctCode  
	,ltrim(rtrim(a.sdesc)) 			        	adesc 
  ,isnull(sum(case tot.thmy when 0 then isnull(tot.exp,0) else case tot.thmy when t.hmyperson then isnull(tot.exp,0) else 0 end end ) ,0) 		TotExp  
	,0 ExpOp
	,0 GrossUp
	,0 RecoveryFactor
	,0 PartialYear
	from Property p  
	inner join commpropconfig pc         on pc.hproperty = p.hmy
	inner join tenant t 		     on t.hproperty = p.hmy
	Inner Join CommPropExpensePool cp    on cp.hProperty = p.hMy  
	Inner Join CommExpensePool cep       on cep.hMy = cp.hExpensepool  
	Inner join CommExpensePoolAccts cepa on cepa.hExpensepool = cep.hMy   
	Inner join acct a                    on cepa.hAcct = a.hMy  
	Inner join(
							Select distinct p.hmy       phmy  
							,rc.hTenant	 thmy
							,rc.hExpensePool 						ExpPoolId
							,recgp.hmy      RecGrpID        Added 22824 
      							,recgp.scode    RecGrpCode      Added 22824 
							From property p
							inner join tenant t 		     on t.hproperty = p.hmy
							Inner join commRecoveryCalc rc on  p.hMy = rc.hProperty AND rc.bcalcestimate = 0 and isNull(rc.iCalculationType,1) = 1 AND rc.hTenant = t.hMyPerson
							inner join commrecoverygroup recgp on (recgp.hmy = rc.hrecoverygroup)
							 ADDED 22824 
							inner join camrule cr on rc.htenant = cr.htenant and rc.hcamrule = cr.hmy and rc.hexpensepool = cr.hexpensepool 
							inner join commamendments ca  on cr.htenant = ca.htenant and cr.hamendment = ca.hmy
                      						AND ((ISNULL(ca.dtStart,'2000-01-01') = '2023-12-31' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31')
								OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-01-01')
								OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31'))
							Where 1=1
							and t.hmyperson in (14698,14693)--#Condition2#
							--#Condition3#
							--#Condition5#
						) Recgroup on Recgroup.thmy = t.hMyPerson and Recgroup.ExpPoolId = cp.hExpensePool  

 Left outer join ( 
			 Select  
			  p.hmy 		   	        phmy  
			  ,0										thmy				
	                  ,0                      		exphmy 
			 ,t.hacct	   	  	        accthmy
   				, a.scode, a.sdesc
			 ,isnull(t.smtd,0)           		exp  	   	        
			 from  property p  		   	     	
			 inner join commpropconfig pc  on pc.hproperty = p.hmy  		   	        
			 Inner Join total t 	       on p.hMy = t.hppty
   			   left outer join acct a on t.hacct = a.hmy
			 where 1=1              
			 and p.hmy = 130 --#Condition1#       	 	        
			 and t.uMonth between '2023-01-01' and '2023-12-31'
			 and t.iBook = case 'cash' when 'cash' then 0 else 1 end  		            
			 UNION ALL                     
			 Select  		
			 p.hmy 	   		                phmy  
			 ,isnull(ce.htenant,0)				thmy
			 ,isnull(ce.hExpensepool,0)      	exphmy	   	   	        
			 ,isnull(ce.hacct,d.hAcct)       	accthmy  	   	       
   					, a.scode, a.sdesc
			 ,isnull(ce.cadjustment,0)       	exp                     
			 from  property p  		   	     	
			 inner join commpropconfig pc         	on pc.hproperty = p.hmy  		   	        
			 Inner Join Commexpenseadjustment ce    on p.hMy = ce.hproperty  		   	        
			 left outer Join detail d               on d.hmy = ce.hDetail 		   	        
			 left outer Join Commdenominator cd	on cd.hmy = ce.hDenominator 
   				LEFT OUTER JOIN acct a on a.hmy = isnull(ce.hacct,d.hAcct)
			 where 1=1               
			 and p.hmy = 130  --#Condition1#
			 and ce.dtadjustment between '2023-01-01' and '2023-12-31'     --order by scode
			) tot on tot.phmy = p.hmy and tot.accthmy = a.hmy and tot.exphmy = case tot.exphmy when 0 then tot.exphmy else cep.hmy end 

	 Added 022824 
	LEFT OUTER JOIN (
		select cr.hRecoveryGroup  1000000  + cr.hExpensePool as RecExpID, cr.hExpensePool, cr.hRecoveryGroup
  			, re.hmy, re.hCamRule, re.hAcct, re.hPropExpensePool, a.scode, a.sdesc, cr.hAmendment, cr.htenant
		from commrecoveryexclude re
		inner join acct a on re.hacct = a.hmy
		inner join camrule cr on re.hCamRule = cr.hmy
		inner join commamendments ca on cr.htenant = ca.htenant and cr.hamendment = ca.hmy 
			AND ((ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31')
			OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-01-01')
    			OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31'))
		inner join commrecoverygroup crg on cr.hRecoveryGroup = crg.hmy
      		--where 1=1
      		--and cr.htenant in (14698,14693)
      		--and cr.hExpensePool in (1188,1206) and cr.hRecoveryGroup in (3,4) 
      	--		order by a.scode
		 where cr.htenant = 14693 and cr.hExpensePool in (1188,1206) and cr.hRecoveryGroup in (3,4) 
	) AcctExc on acctexc.RecExpID = recgroup.RecGrpID  1000000 + cep.hmy and acctexc.htenant = t.hmyperson and acctexc.hacct = a.hmy



	where 1=1   
	and p.hmy = 130 -- #Condition1#
	and t.hmyperson in (14698,14693) --#Condition2#
	and acctexc.RecExpID is not null    Added 22824 	
	and  tot.Exp  0 
	and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,('2023-12-1'))
	and exists ( select 1 from camrule cr where cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson)
	and not exists ( select 1 from commrecoveryexclude re where re.hacct = a.hmy and re.hPropexpensepool = cp.hmy) 
	and not exists ( select 1 from commrecoveryexclude re inner join camrule cr  on cr.hmy = re.hCamrule 
		inner join commamendments ca  on cr.htenant = ca.htenant and cr.hamendment = ca.hmy
               	AND ((ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31')
			OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-01-01')
			OR (ISNULL(ca.dtStart,'2000-01-01') = '2023-01-01' AND ISNULL(ca.dtEnd,'2199-12-31') = '2023-12-31'))
		where re.hacct = a.hmy and re.hpropexpensepool = cep.hmy and cr.htenant = t.hmyperson) 
	group by p.hmy,p.scode,p.saddr1,t.scode,t.hmyperson,cep.hmy,cep.scode,cep.sdesc ,a.hchart,a.hmy,a.scode,a.sdesc
	
    --select  from commrecoveryexclude where hacct = 1527 and hCamRule in (43121,54430,54431      ,33782,39636)

	order by acctcode, thmy
	union all
	
Select   '2' ord, p.hmy                 			        phmy  
	,ltrim(rtrim(p.scode))				        pcode  
	,ltrim(rtrim(p.saddr1))			        	PropertyDesc 
	,t.hmyperson						thmy
	,ltrim(rtrim(isnull(t.scode,'')))					tscode
	,cep.hmy 			                        ExpPoolId  
	,ltrim(rtrim(cep.scode)) 			        ExpPoolCode  
	,ltrim(rtrim(cep.sdesc)) 			        ExpDesc  
	,'' 			        			ChartId  
	,''							hAcct
	,'' 					        	AcctCode  
	,''		 			        	adesc 
	,0			                 		TotExp  
	,AdjTotal.ExpOp						ExpOp
	,AdjTotal.GrossUp 				GrossUp
	,AdjTotal.RecoveryFactor			RecoveryFactor
	,case when (t.dtleasefrom  @BegDt and t.dtleasefrom   @EndDt) or
		    (t.dtleaseto  @BegDt and t.dtleaseto  @EndDt) 		    
	      then 1 
	      else 0 end  PartialYear
	from Property p  
	inner join commpropconfig pc         on pc.hproperty = p.hmy
	inner join tenant t 		     on t.hproperty = p.hmy
	Inner Join CommPropExpensePool cp    on cp.hProperty = p.hMy  
	Inner Join CommExpensePool cep       on cep.hMy = cp.hExpensepool
	Inner join(
		Select distinct p.hmy       phmy  
		,rc.hTenant	 thmy
		,rc.hExpensePool  ExpPoolId
		From property p
		inner join tenant t 		     on t.hproperty = p.hmy
		Inner join commRecoveryCalc rc on  p.hMy = rc.hProperty AND rc.bcalcestimate = 0 and isNull(rc.iCalculationType,1) = 1 AND rc.hTenant = t.hMyPerson
		inner join commrecoverygroup recgp on (recgp.hmy = rc.hrecoverygroup) 

		inner join camrule cr on rc.htenant = cr.htenant and rc.hcamrule = cr.hmy and rc.hexpensepool = cr.hexpensepool 
			and ((ISNULL(cr.dtfrom,'2199-12-31') = @YearEnd and ISNULL(cr.dtto,'2199-12-31') = @YearEnd)
			or cr.dtto BETWEEN @BegDt and @YearEnd)
		Where 1=1
		#Condition2#
		#Condition3#
		#Condition5#
		) Recgroup on Recgroup.thmy = t.hMyPerson and Recgroup.ExpPoolId = cp.hExpensePool  
	left outer join (
				Select p.hmy                 			        phmy  
				,t.hmyperson						thmy
				,isnull(t.scode,'') 					tscode
				,cep.hmy 			                        ExpPoolId  
				,isnull(rc.cexpensegrossup,0) 				GrossUp
				,isnull(rc.cexpenserecoveryfactor,0)			RecoveryFactor
				
				,sum(isnull(rc.cExpenseOperating,0))			ExpOp
				from Property p  
				inner join commpropconfig pc         on pc.hproperty = p.hmy
				inner join tenant t 		     on t.hproperty = p.hmy
				Inner Join CommPropExpensePool cp    on cp.hProperty = p.hMy  
				Inner Join CommExpensePool cep       on cep.hMy = cp.hExpensepool  
				inner join commrecoverycalc rc ON rc.htenant = t.hmyperson AND rc.bcalcestimate = 0 and rc.hexpensepool=cep.hmy and isNull(rc.iCalculationType,1) = 1

				inner join camrule cr on rc.htenant = cr.htenant and rc.hcamrule = cr.hmy and rc.hexpensepool = cr.hexpensepool 

				INNER JOIN commamendments ca on rc.htenant = ca.htenant and cr.hamendment = ca.hmy
				AND ((ISNULL(ca.dtStart,'2000-01-01') = @EndDt 
              				AND ISNULL(ca.dtEnd,'2199-12-31') = @EndDt) 
					OR (ISNULL(ca.dtStart,'2000-01-01') = @BegDt AND ISNULL(ca.dtEnd,'2199-12-31') = @BegDt) 
            				OR (ISNULL(ca.dtStart,'2000-01-01') = @BegDt AND ISNULL(ca.dtEnd,'2199-12-31') = @EndDt)) 
			where 1=1   
			#Condition1#
			#Condition2#
			and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,(@YearEnd))
				and rc.dtCalcTo = dateadd(dd,-1,(dateadd(mm,1,(@YearEnd))))
	and datepart(yyyy,rc.dtCalcTo) =  datepart(yyyy,(@YearEnd))
			group by p.hmy,t.scode,t.hmyperson,cep.hmy,rc.cexpensegrossup,rc.cexpenserecoveryfactor
		)AdjTotal on AdjTotal.phmy = p.hmy and AdjTotal.thmy = t.hmyperson and AdjTotal.exppoolid = cep.hmy
	where 1=1   
	#Condition1#
	#Condition2#
	and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,(@YearEnd))
	and exists ( select 1 from camrule cr where cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson)
	group by p.hmy,p.scode,p.saddr1,t.scode,t.hmyperson,cep.hmy,cep.scode,cep.sdesc ,AdjTotal.ExpOp, AdjTotal.GrossUp, AdjTotal.RecoveryFactor, t.dtleasefrom , t.dtleaseto
)a
order by a.ord
