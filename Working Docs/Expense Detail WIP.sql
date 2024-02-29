select a.*
from 
(Select   '1' ord, p.hmy                 			        phmy  
	,ltrim(rtrim(p.scode))				        pcode  
	,ltrim(rtrim(p.saddr1))			        	PropertyDesc 
	,t.hmyperson						thmy
	,ltrim(rtrim(isnull(t.scode,''))) 					tscode
	,cep.hmy 			                        ExpPoolId  
	,ltrim(rtrim(cep.scode)) 			        ExpPoolCode  
	,ltrim(rtrim(cep.sdesc)) 			        ExpDesc  
	,ltrim(rtrim(a.hChart)) 			        ChartId  
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
							From property p
							inner join tenant t 		     on t.hproperty = p.hmy
							Inner join commRecoveryCalc rc on  p.hMy = rc.hProperty AND rc.bcalcestimate = 0 and isNull(rc.iCalculationType,1) = 1 AND rc.hTenant = t.hMyPerson
							inner join commrecoverygroup recgp on (recgp.hmy = rc.hrecoverygroup)
							Where 1=1
							AND t.hmyperson in (14677,14673,14700)  -- Tenant scode  'vigillaw'
							--#Condition3#
							--#Condition5#
						) Recgroup on Recgroup.thmy = t.hMyPerson and Recgroup.ExpPoolId = cp.hExpensePool  
	Left outer join ( 
			 Select  
			  p.hmy 		   	        phmy  
			  ,0										thmy				
	                  ,0                      		exphmy 
			 ,t.hacct	   	  	        accthmy  	   	        
			 ,isnull(t.smtd,0)           		exp  	   	        
			 from  property p  		   	     	
			 inner join commpropconfig pc  on pc.hproperty = p.hmy  		   	        
			 Inner Join total t 	       on p.hMy = t.hppty  	 	   	        
			 where 1=1              
			 AND p.hMy =  130  -- 130 - WestPoint       	 	        
			 and t.uMonth between dateadd(mm,-11,('2023-12-31')) and dateadd(dd,-1,(dateadd(mm,1,('2023-12-31'))))
			 and t.iBook = case 'cash' when 'cash' then 0 else 1 end  		            
			 UNION ALL                     
			 Select  		
			 p.hmy 	   		                phmy  
			 ,isnull(ce.htenant,0)				thmy
			 ,isnull(ce.hExpensepool,0)      	exphmy	   	   	        
			 ,isnull(ce.hacct,d.hAcct)       	accthmy  	   	       
			 ,isnull(ce.cadjustment,0)       	exp                     
			 from  property p  		   	     	
			 inner join commpropconfig pc         	on pc.hproperty = p.hmy  		   	        
			 Inner Join Commexpenseadjustment ce    on p.hMy = ce.hproperty  		   	        
			 left outer Join detail d               on d.hmy = ce.hDetail 		   	        
			 left outer Join Commdenominator cd	on cd.hmy = ce.hDenominator  		   	        
			 where 1=1               
			 AND p.hMy =  130  -- 130 - WestPoint
			 and ce.dtadjustment between dateadd(mm,-11,('2023-12-31')) and dateadd(dd,-1,(dateadd(mm,1,('2023-12-31'))))
			) tot on tot.phmy = p.hmy and tot.accthmy = a.hmy and tot.exphmy = case tot.exphmy when 0 then tot.exphmy else cep.hmy end 
	where 1=1   
	AND p.hMy =  130  -- 130 - WestPoint
	AND t.hmyperson in (14677,14673,14700)  -- Tenant scode  'vigillaw'
	and  tot.Exp <> 0 
	and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,('2023-12-31'))
	and exists ( select 1 from camrule cr where cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson)
	and not exists ( select 1 from commrecoveryexclude re where re.hacct = a.hmy and re.hPropexpensepool = cp.hmy) 
	and not exists ( select 1 from commrecoveryexclude re inner join commrecovery cr  on cr.hmy = re.hRecovery inner join commrecoverygroupdet gd on gd.hmy = cr.hgroupdet where re.hacct = a.hmy and cr.hexpensepool = cep.hmy and gd.hprop = p.hmy  and re.hmy in (select re.hmy from commrecoveryexclude re inner join camrule cr on cr.hmy = re.hCamrule where re.hacct = a.hmy and cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson and isnull(cr.dtFROM,'2020-01-01') <= '2023-12-31' and isnull(cr.dtTO,'2199-12-31') >= '2023-12-31'))
	and not exists ( select 1 from commrecoveryexclude re inner join camrule cr  on cr.hmy = re.hCamrule where re.hacct = a.hmy and cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson and isnull(cr.dtFROM,'2020-01-01') <= '2023-12-31' and isnull(cr.dtTO,'2199-12-31') >= '2023-12-31')
	group by p.hmy,p.scode,p.saddr1,t.scode,t.hmyperson,cep.hmy,cep.scode,cep.sdesc ,a.hchart,a.scode,a.sdesc
	
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
	,'' 					        	AcctCode  
	,''		 			        	adesc 
	,0			                 		TotExp  
	,AdjTotal.ExpOp						ExpOp
	,AdjTotal.GrossUp 				GrossUp
	,AdjTotal.RecoveryFactor			RecoveryFactor
	,case when (t.dtleasefrom > dateadd(mm,-11,('2023-12-31')) and t.dtleasefrom  < dateadd(dd,-1,(dateadd(mm,1,('2023-12-31'))))) or
		    (t.dtleaseto > dateadd(mm,-11,('2023-12-31')) and t.dtleaseto < dateadd(dd,-1,(dateadd(mm,1,('2023-12-31'))))) 		    
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
							,rc.hExpensePool 						ExpPoolId
							From property p
							inner join tenant t 		     on t.hproperty = p.hmy
							Inner join commRecoveryCalc rc on  p.hMy = rc.hProperty AND rc.bcalcestimate = 0 and isNull(rc.iCalculationType,1) = 1 AND rc.hTenant = t.hMyPerson
	inner join commrecoverygroup recgp on (recgp.hmy = rc.hrecoverygroup) 
							Where 1=1
							AND t.hmyperson in (14677,14673,14700)  -- Tenant scode  'vigillaw'
							--#Condition3#
							--#Condition5#
						) Recgroup on Recgroup.thmy = t.hMyPerson and Recgroup.ExpPoolId = cp.hExpensePool  
	left outer join (
				Select   p.hmy                 			        phmy  
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
				where 1=1   
			AND p.hMy =  130  -- 130 - WestPoint
			AND t.hmyperson in (14677,14673,14700)  -- Tenant scode  'vigillaw'
			and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,('2023-12-31'))
				and rc.dtCalcTo <= dateadd(dd,-1,(dateadd(mm,1,('2023-12-31'))))
	and datepart(yyyy,rc.dtCalcTo) =  datepart(yyyy,('2023-12-31'))
			group by p.hmy,t.scode,t.hmyperson,cep.hmy,rc.cexpensegrossup,rc.cexpenserecoveryfactor
		)AdjTotal on AdjTotal.phmy = p.hmy and AdjTotal.thmy = t.hmyperson and AdjTotal.exppoolid = cep.hmy
	where 1=1   
	AND p.hMy =  130  -- 130 - WestPoint
	AND t.hmyperson in (14677,14673,14700)  -- Tenant scode  'vigillaw'
	and case isnull(cp.iRecoveryEOYMonth,0) when 0 then pc.iRecoveryEOYMonth else cp.iRecoveryEOYMonth end = datepart(mm,('2023-12-31'))
	and exists ( select 1 from camrule cr where cr.hexpensepool = cep.hmy and cr.htenant = t.hmyperson and isnull(cr.dtFROM,'2020-01-01') <= '2023-12-31' and isnull(cr.dtTO,'2199-12-31') >= '2023-12-31')
	group by p.hmy,p.scode,p.saddr1,t.scode,t.hmyperson,cep.hmy,cep.scode,cep.sdesc ,AdjTotal.ExpOp, AdjTotal.GrossUp, AdjTotal.RecoveryFactor, t.dtleasefrom , t.dtleaseto
)a
order by a.ord
