*El presente do file genera las variables de ingreso asignadas a Javier Torres

*País:	Bolivia
*Año :	2000


***************************
***VARIABLES DE INGRESOS***
***************************

**************************************************************
*** CONSTRUCCIÓN DE LAS VARIABLES ARMONIZADAS DEL BID ***		
**************************************************************

***************
***ylmpri_ci: Ingreso laboral monetario de actividad principal: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia). Considera ingresos corrientes y extraordinarios.***
***************

*Para los trabajadores dependientes

*Ingreso basico
gen ypridb=.
replace ypridb=saliqp*30 if frecsalp==1 
replace ypridb=saliqp*4.3 if frecsalp==2 
replace ypridb=saliqp*2 if frecsalp==3 
replace ypridb=saliqp if frecsalp==4 
replace ypridb=saliqp/6 if frecsalp==5
replace ypridb=saliqp/12 if frecsalp==6

replace ypridb=0 if categopri_ci==4 

*Ingresos extras
local sub="hep prip aguip"
foreach i of local sub {
gen ypriex`i'=.
replace ypriex`i'=ing`i'/12 if rec`i'==1
replace ypriex`i'=0 if rec`i'==2
}

egen ypridbd=rsum(ypridb ypriexhep ypriexprip ypriexaguip), missing
replace ypridbd=. if ypridb==. & ypriexhep==. & ypriexprip==. & ypriexaguip==.

*Para los trabajadores independientes 
gen yprijbi=.
replace yprijbi=ingliqp*30 if frecinp==1 
replace yprijbi=ingliqp*4.3 if frecinp==2 
replace yprijbi=ingliqp*2 if frecinp==3 
replace yprijbi=ingliqp if frecinp==4 
replace yprijbi=ingliqp/6 if frecinp==5
replace yprijbi=ingliqp/12 if frecinp==6

*Ingreso laboral monetario para todos
egen ylmpri_ci=rsum(yprijbi ypridbd), missing
replace ylmpri_ci=. if ypridbd==. & yprijbi==. 
replace ylmpri_ci=. if emp_ci~=1


***************
***ylmsec_ci: Ingreso laboral monetario de actividad secundaria. Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria.***
***************

*Para los trabajadores dependientes

*Ingreso basico
gen ysecb=.
replace ysecb=saliqs*30 if frecsals==1 
replace ysecb=saliqs*4.3 if frecsals==2 
replace ysecb=saliqs*2 if frecsals==3 
replace ysecb=saliqs if frecsals==4 
replace ysecb=saliqs/6 if frecsals==5
replace ysecb=saliqs/12 if frecsals==6

replace ysecb=0 if categosec_ci==4 

*Ingresos extras

gen yxsa=inghes/12 
replace yxsa=. if reches==0
replace yxsa=0 if reches==2

gen yxsa1=ingpris/12 
replace yxsa1=. if recpris==0
replace yxsa1=0 if recpris==2

gen yxsa2=ingaguis/12 
replace yxsa2=. if recaguis==0
replace yxsa2=0 if recaguis==2


egen ysecbd=rsum(ysecb yxsa yxsa1 yxsa2), missing
replace ysecbd=. if ysecb==. & yxsa==. & yxsa1==. & yxsa2==.


*Para los trabajadores independientes

gen ysecjbi=.
replace ysecjbi=ingliqs*30 if frecins==1 
replace ysecjbi=ingliqs*4.3 if frecins==2 
replace ysecjbi=ingliqs*2 if frecins==3 
replace ysecjbi=ingliqs if frecins==4 
replace ysecjbi=ingliqs/6 if frecins==5
replace ysecjbi=ingliqs/12 if frecins==6

*Ingreso laboral monetario para todos

egen ylmsec_ci=rsum(ysecjbi ysecbd), missing
replace ylmsec_ci=. if ysecjbi==. & ysecbd==.
replace ylmsec_ci=. if emp_ci~=1



*****************
***ylmotros_ci: Ingreso laboral monetario de otras actividades. Variable continua que indica el monto mensual de ingresos monetarios provenientes de actividades distintas de la principal y secundaria. Incluye ingresos percibidos por desocupados o inactivos derivados de trabajos previos al cese. ***
*****************
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 


************
***ylm_ci: Ingreso laboral monetario total: Variable continua que indica el monto mensual total de ingresos laborales monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylmpri_ci, ymsec_ci e ylnmotros_ci.***
************
egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso laboral monetario total"


******************
*** ylnmpri_ci: Ingreso laboral no monetario de actividad principal. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad principal de cada miembro del hogar. ***
******************

*Ingreso laboral no monetario de los dependientes

local nnn="alip trap vesp vivp otrp"
foreach i of local nnn {

gen especie`i'=.
replace especie`i'=ing`i'*30  if frec`i'==1
replace especie`i'=ing`i'*4.3 if frec`i'==2
replace especie`i'=ing`i'*2   if frec`i'==3
replace especie`i'=ing`i'     if frec`i'==4
replace especie`i'=ing`i'/3   if frec`i'==5
replace especie`i'=ing`i'/6   if frec`i'==6
replace especie`i'=ing`i'/12  if frec`i'==7
replace especie`i'=0 if rec`i'==2
}

egen ylnmprid=rsum(especiealip especietrap especievesp especievivp especieotrp), missing
replace ylnmprid=. if especiealip==. & especietrap==. & especievesp==. & especievivp==. & especieotrp==. 
replace ylnmprid=0 if categopri_ci==4


*Ingreso laboral no monetario de los independientes (autoconsumo)

gen ylnmprii=.

*Ingreso laboral no monetario para todos

egen ylnmpri_ci=rsum(ylnmprid ylnmprii), missing
replace ylnmpri_ci=. if ylnmprid==. & ylnmprii==.
replace ylnmpri_ci=. if emp_ci~=1



******************
****ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar. ****
******************

local nsn="alis tras vess vivs otrs"
foreach i of local nsn {

gen especie`i'=.
replace especie`i'=ing`i'*30  if frec`i'==1
replace especie`i'=ing`i'*4.3 if frec`i'==2
replace especie`i'=ing`i'*2   if frec`i'==3
replace especie`i'=ing`i'     if frec`i'==4
replace especie`i'=ing`i'/3   if frec`i'==5
replace especie`i'=ing`i'/6   if frec`i'==6
replace especie`i'=ing`i'/12  if frec`i'==7
replace especie`i'=0 if rec`i'==2
}

egen ylnmsecd=rsum(especiealis especietras especievess especievivs especieotrs), missing
replace ylnmsecd=. if especiealis==. & especietras==. & especievess==. & especievivs==. & especieotrs==. 
replace ylnmsecd=0 if categosec_ci==4


*Ingreso laboral no monetario de los independientes (autoconsumo)

gen ylnmseci=.

*Ingreso laboral no monetario para todos

egen ylnmsec_ci=rsum(ylnmsecd ylnmseci), missing
replace ylnmsec_ci=. if ylnmsecd==. & ylnmseci==.
replace ylnmsec_ci=. if emp_ci==0



******************
***ylnmotros_ci: Ingresos laboral no monetario de otras actividades. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de actividades distintas de la principal y/o secundaria de cada miembro del hogar.***
******************
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 


*************
***ylnm_ci: Ingreso laboral no monetario. Variable continua que indica el monto mensual total de ingresos laborales no monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylnmpri_ci, ylnmsec_ci e ylnmotros_ci.***
*************
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci), missing
replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==.
label var ylnm_ci "Ingreso laboral NO monetario total" 


**************
***ynlnm_ci: Ingreso no laboral no monetario. Variable continua que indica el monto mensual del ingreso no laboral no monetario (otras fuentes). En esta categoría se encuentran otros beneficios y transferencias no monetarias como las donaciones en alimentos, útiles escolares, becas, entre otros.***
**************
gen ynlnm_ci=.


**************
***ytot_ci: Ingreso mensual total del individuo que incluye las variables ylm_ci ylnm_ci ynlm_ci ynlnm_ci. ***
**************
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci),mi


**************
*** ylm_ch: Ingreso laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso laboral monetario del hogar, ignora las `No respuesta'.**
**************
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
label var ylm_ch "Ingreso laboral monetario del hogar" 


***************
*** ylnm_ch: Ingreso laboral no monetario del hogar. Variable continua que indica el monto del ingreso laboral no monetario del hogar. ***
***************
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
label var ylnm_ch "Ingreso laboral no monetario del hogar"


****************
*** ynlnm_ch: Ingreso no laboral no monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral no monetario del hogar (otras fuentes). ***
****************
*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"


**************
***ytot_ch: Ingreso mensual total del hogar *
**************
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi


*****************
***ylhopri_ci: Variable continua que indica el monto del salario horario monetario de la actividad principal ***
*****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
label var ylmhopri_ci "Salario horario monetario de la actividad principal"


***************
***ylmho_ci: Variable continua que indica el monto del salario horario monetario de todas las actividades.*
****************
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario horario monetario de todas las actividades" 


 