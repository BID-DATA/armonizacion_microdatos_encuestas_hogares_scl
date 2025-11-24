*El presente do file genera las variables de ingreso asignadas a Javier Torres

*País:	Bolivia
*Año :	2001	


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
replace ypridb=s626a*30 if s626b==1 
replace ypridb=s626a*4.3 if s626b==2 
replace ypridb=s626a*2 if s626b==3 
replace ypridb=s626a if s626b==4 
replace ypridb=s626a/6 if s626b==5
replace ypridb=s626a/12 if s626b==6

replace ypridb=0 if categopri_ci==4 

*Ingresos extras
local sub="a b c"
foreach i of local sub {
gen ypriex`i'=.
replace ypriex`i'=s627`i'2/12 if s627`i'1==1
replace ypriex`i'=0 if s627`i'1==2
}

egen ypridbd=rsum(ypridb ypriexa ypriexb ypriexc), missing
replace ypridbd=. if ypridb==. & ypriexa==. & ypriexb==. & ypriexc==.

*Para los trabajadores independientes 
gen yprijbi=.
replace yprijbi=s631a*30 if s631b==1 
replace yprijbi=s631a*4.3 if s631b==2 
replace yprijbi=s631a*2 if s631b==3 
replace yprijbi=s631a if s631b==4 
replace yprijbi=s631a/6 if s631b==5
replace yprijbi=s631a/12 if s631b==6

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
replace ysecb=s640a*30 if s640b==1 
replace ysecb=s640a*4.3 if s640b==2 
replace ysecb=s640a*2 if s640b==3 
replace ysecb=s640a if s640b==4 
replace ysecb=s640a/6 if s640b==5
replace ysecb=s640a/12 if s640b==6
replace ysecb=0 if categosec_ci==4 

*Ingresos extras
gen yxsa=s641b/12 
gen yxsa1=s641b/12 

egen ysecbd=rsum(ysecb yxsa yxsa1), missing
replace ysecbd=. if ysecb==. & yxsa==. & yxsa1==.

*Para los trabajadores independientes
gen ysecjbi=.
replace ysecjbi=s644a*30 if s644b==1 
replace ysecjbi=s644a*4.3 if s644b==2 
replace ysecjbi=s644a*2 if s644b==3 
replace ysecjbi=s644a if s644b==4 
replace ysecjbi=s644a/6 if s644b==5
replace ysecjbi=s644a/12 if s644b==6

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
local nnn="a b c d e"
foreach i of local nnn {

gen especie`i'=.
replace especie`i'=s628`i'3*30  if s628`i'2==1
replace especie`i'=s628`i'3*4.3 if s628`i'2==2
replace especie`i'=s628`i'3*2   if s628`i'2==3
replace especie`i'=s628`i'3     if s628`i'2==4
replace especie`i'=s628`i'3/3   if s628`i'2==5
replace especie`i'=s628`i'3/6   if s628`i'2==6
replace especie`i'=s628`i'3/12   if s628`i'2==7
replace especie`i'=0 if s628`i'1==2
}
egen ylnmprid=rsum(especiea especieb especiec especied especiee), missing
replace ylnmprid=. if especiea==. &  especieb==. & especiec==. & especied==. & especiee==. 
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
*Ingreso laboral no monetario de los dependientes
foreach i of local nnn {

gen especiesec`i'=.
replace especiesec`i'=s642`i'3*30  if s642`i'2==1
replace especiesec`i'=s642`i'3*4.3 if s642`i'2==2
replace especiesec`i'=s642`i'3*2   if s642`i'2==3
replace especiesec`i'=s642`i'3     if s642`i'2==4
replace especiesec`i'=s642`i'3/3   if s642`i'2==5
replace especiesec`i'=s642`i'3/6   if s642`i'2==6
replace especiesec`i'=s642`i'3/12  if s642`i'2==7
replace especiesec`i'=0 if s642`i'1==2
}

egen ylnmsecd=rsum(especieseca especiesecb especiesecc especiesecd especiesece), missing
replace ylnmsecd=. if especieseca==. &  especiesecb==. & especiesecc==. & especiesecd==. & especiesece==. 
replace ylnmsecd=0 if categosec_ci==4
replace ylnmsecd=. if emp_ci~=1

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


 