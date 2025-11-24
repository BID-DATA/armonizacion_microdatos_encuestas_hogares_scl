*El presente do file genera las variables de ingreso asignadas a Javier Torres

*País:	Bolivia
*Año :	2003-2004	
*******************

***************************
***VARIABLES DE INGRESOS***
***************************
/* Para construir las variables del BID es necesario generar previamente un conjunto de variables auxiliares. La encuesta de Bolivia contiene variables raw, que sirven como insumos para dichas variables.

La estructura de este do-file es la siguiente:

		I.	Listado de variables auxiliares requeridas.
			Se presenta, siguiendo el orden del manual del BID, cada variable del 
			BID junto con las variables auxiliares necesarias para su construcción.
			Para cada variable auxiliar se incluye su definición correspondiente.

		II	Generación de todas las variables auxiliares.
			En esta sección se crean, de manera ordenada y consecutiva, todas 
			las variables auxiliares identificadas en el paso anterior.

		III	Construcción de las variables del BID.
			Finalmente, utilizando las variables auxiliares previamente generadas, 
			se construyen las variables del BID.
*/

******************************************
*** I. LISTADO DE VARIABLES AUXILIARES ***		
******************************************

/*	ylmpri_ci: Ingreso laboral monetario de actividad principal
			yliquido: Ingreso liquido
			ycomisio: Ingreso por comisiones
			yhrsextr: Ingreso por horas extra
			yprima	: Ingreso por bono o prima de productividad
			yaguina	: Ingreso por aguinaldo
			yactpri	: Ingreso actividad principal de independientes

	ylmsec_ci: Ingreso laboral monetario de actividad secundaria
			yliquido2: Ingreso liquido de la actividad secundaria

	ylmotros_ci: Ingreso laboral monetario de otras actividades
			Missing, no hay variables de de ingresos otras ocupaciones 
	
	ylm_ci: Ingreso laboral monetario del individuo 
			Esta variable se genera a partir de: ylmpri_ci y ylmsec_ci
	
	ylnmpri_ci: Ingreso laboral no monetario de actividad principal.
			yalimen : Ingreso en alimentos
			ytranspo: Ingreso en transporte
			yvesti	: Ingreso en vestimenta
			yvivien	: Ingreso en vivienda
	
	ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria:
			Missing, no hay variables de ingresos laborales no monetarios.
	
	ylnmotros_ci: Ingresos laboral no monetario de otras actividades.
			Missing, no hay variables de ingresos de otras ocupaciones
	
	ylnm_ci: Ingreso laboral no monetario
			Esta variable se genera a partir de: ylnmpri_ci y ylnmsec_ci. 
	
	ynlnm_ci: Ingreso no laboral no monetario
			Missing, no hay variables al respecto.
	
	ytot_ci: Ingreso mensual total del individuo.
			Esta variable se genera a partir de: ylm_ci, ylnm_ci, ynlm_ci y ynlnm_ci.
			
	ylm_ch: Ingreso laboral monetario del hogar.
			Se suman los ingresos laborales (ylm_ci) de todos los individuos del hogar 
			
	ylnm_ch: Ingreso laboral no monetario del hogar.
			Se suman los ingresos laborales no monetarios (ylnm_ci) de 
			los miembros del hogar.
			
	ynlnm_ch: Ingreso no laboral no monetario del hogar.
			Se suman los ingresos no laborales no monetarios (ynlnm_ci) de
			los miembros del hogar
	
	ytot_ch: Ingreso mensual total del hogar
			Se suman todos los ingresos del hogar: ylm_ch, ylnm_ch, ynlm_ch, ynlnm_ch.
	
	ylmho_ci: Salario horario monetario de todas las actividades.
			Se genera mediante las variables: ylmpri_ci y horaspri_ci
	
	ylhopri_ci: Salario horario monetario de la actividad principal
			Se genera mediante las variables: ylm_ci y horastot_ci
*/


**********************************************
*** II. GENERACIÓN DE VARIABLES AUXILIARES ***		
**********************************************
*****************************
* c: salario líquido *
*****************************
gen a4_23a2 = .
replace a4_23a2 = a4_23a 		if a4_23b==1
replace a4_23a2 = a4_23a*7.50 	if a4_23b==2

gen yliquido = .
replace yliquido= a4_23a2*30	if a4_23c==1
replace yliquido= a4_23a2*4.3	if a4_23c==2
replace yliquido= a4_23a2*2		if a4_23c==3
replace yliquido= a4_23a2		if a4_23c==4
replace yliquido= a4_23a2/3		if a4_23c==5
replace yliquido= a4_23a2/6		if a4_23c==6
replace yliquido= a4_23a2/12	if a4_23c==7


************************************
* ycomisio: Ingreso por comisiones *
************************************
gen a4_24a12 = .
replace a4_24a12 = a4_24a1 		if a4_24a2==1
replace a4_24a12 = a4_24a1*7.50	if a4_24a2==2

gen ycomisio = .
replace ycomisio= a4_24a12*30	if a4_24a3==1
replace ycomisio= a4_24a12*4.3	if a4_24a3==2
replace ycomisio= a4_24a12*2	if a4_24a3==3
replace ycomisio= a4_24a12		if a4_24a3==4
replace ycomisio= a4_24a12/3	if a4_24a3==5
replace ycomisio= a4_24a12/6	if a4_24a3==6
replace ycomisio= a4_24a12/12	if a4_24a3==7


**************************************
* yhrsextr: Ingreso por horas extras *
**************************************
gen a4_24d12 = .
replace a4_24d12 = a4_24d1 		if a4_24d2==1
replace a4_24d12 = a4_24d1*7.50	if a4_24d2==2

gen yhrsextr= .
replace yhrsextr= a4_24d12*30	if a4_24d3==1
replace yhrsextr= a4_24d12*4.3	if a4_24d3==2
replace yhrsextr= a4_24d12*2	if a4_24d3==3
replace yhrsextr= a4_24d12		if a4_24d3==4
replace yhrsextr= a4_24d12/3	if a4_24d3==5
replace yhrsextr= a4_24d12/6	if a4_24d3==6
replace yhrsextr= a4_24d12/12	if a4_24d3==7


************************************************
* yprima: Ingreso por prima/bono de producción *
************************************************
gen yprima = .
replace yprima = a4_26a1 		if a4_26a2==1
replace yprima = a4_26a1*7.50	if a4_26a2==2


*******************************
* yaguina: Pago por aguinaldo *
*******************************
gen yaguina = .
replace yaguina = a4_26b1 		if a4_26b2==1
replace yaguina = a4_26b1*7.50	if a4_26b2==2


*******************************************
* yactpri: ingreso actividad principal independientes *
*******************************************
gen a4_35a2 = .
replace a4_35a2 = a4_35a 		if a4_35b==1
replace a4_35a2 = a4_35a*7.50 	if a4_35b==2

gen yactpri = .
replace yactpri= a4_35a2*30		if a4_35c==1
replace yactpri= a4_35a2*4.3	if a4_35c==2
replace yactpri= a4_35a2*2		if a4_35c==3
replace yactpri= a4_35a2		if a4_35c==4
replace yactpri= a4_35a2/3		if a4_35c==5
replace yactpri= a4_35a2/6		if a4_35c==6
replace yactpri= a4_35a2/12		if a4_35c==7


********************************
* yliquido2: salario liquido 2 *
********************************
/*         1 diario
           2 semanal
           3 quicenal
           4 mensual
           5 bimestral
           6 trimestral
           7 semestral
           8 anual
*/
gen a4_41a2 = .
replace a4_41a2 = a4_41a 		if a4_41b==1
replace a4_41a2 = a4_41a*7.50 	if a4_41b==2

gen yliquido2 = .
replace yliquido2= a4_41a2*30	if a4_41c==1
replace yliquido2= a4_41a2*4.3	if a4_41c==2
replace yliquido2= a4_41a2*2	if a4_41c==3
replace yliquido2= a4_41a2		if a4_41c==4
replace yliquido2= a4_41a2/3	if a4_41c==5
replace yliquido2= a4_41a2/6	if a4_41c==6
replace yliquido2= a4_41a2/12	if a4_41c==7


*************
* yalimen: Ingreso en alimentos *
*************
gen yalimen = .
replace yalimen= a4_27a3*30		if a4_27a2==1 & a4_27a1==1
replace yalimen= a4_27a3*4.3	if a4_27a2==2 & a4_27a1==1
replace yalimen= a4_27a3*2		if a4_27a2==3 & a4_27a1==1
replace yalimen= a4_27a3		if a4_27a2==4 & a4_27a1==1
replace yalimen= a4_27a3/3		if a4_27a2==5 & a4_27a1==1
replace yalimen= a4_27a3/6		if a4_27a2==6 & a4_27a1==1
replace yalimen= a4_27a3/12		if a4_27a2==7 & a4_27a1==1


**************
* ytranspo: Ingreso en transporte *
**************
gen ytranspo = .
replace ytranspo= a4_27b3*30	if a4_27b2==1 & a4_27b1==1
replace ytranspo= a4_27b3*4.3	if a4_27b2==2 & a4_27b1==1
replace ytranspo= a4_27b3*2		if a4_27b2==3 & a4_27b1==1
replace ytranspo= a4_27b3		if a4_27b2==4 & a4_27b1==1
replace ytranspo= a4_27b3/3		if a4_27b2==5 & a4_27b1==1
replace ytranspo= a4_27b3/6		if a4_27b2==6 & a4_27b1==1
replace ytranspo= a4_27b3/12	if a4_27b2==7 & a4_27b1==1


**************
* yvesti: Ingreso en vestimenta *
**************
gen yvesti = .
replace yvesti= a4_27c3*30		if a4_27c2==1 & a4_27c1==1
replace yvesti= a4_27c3*4.3		if a4_27c2==2 & a4_27c1==1
replace yvesti= a4_27c3*2		if a4_27c2==3 & a4_27c1==1
replace yvesti= a4_27c3			if a4_27c2==4 & a4_27c1==1
replace yvesti= a4_27c3/3		if a4_27c2==5 & a4_27c1==1
replace yvesti= a4_27c3/6		if a4_27c2==6 & a4_27c1==1
replace yvesti= a4_27c3/12		if a4_27c2==7 & a4_27c1==1


************
* yvivien: Ingreso en vivienda *
************
gen yvivien = .
replace yvivien= a4_27d3*30		if a4_27d2==1 & a4_27d1==1
replace yvivien= a4_27d3*4.3	if a4_27d2==2 & a4_27d1==1
replace yvivien= a4_27d3*2		if a4_27d2==3 & a4_27d1==1
replace yvivien= a4_27d3		if a4_27d2==4 & a4_27d1==1
replace yvivien= a4_27d3/3		if a4_27d2==5 & a4_27d1==1
replace yvivien= a4_27d3/6		if a4_27d2==6 & a4_27d1==1
replace yvivien= a4_27d3/12		if a4_27d2==7 & a4_27d1==1



**************************************************************
*** III. CONSTRUCCIÓN DE LAS VARIABLES ARMONIZADAS DEL BID ***		
**************************************************************

***************
***ylmpri_ci: Ingreso laboral monetario de actividad principal: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia). Considera ingresos corrientes y extraordinarios.***
***************
egen ylmpri_ci=rsum(yliquido ycomisio yhrsextr yprima yaguina yactpri), missing
replace ylmpri_ci=. if yliquido ==. & ycomisio ==. &  yhrsextr ==. & yprima ==. &  yaguina ==. &  yactpri==.  
replace ylmpri_ci=. if emp_ci~=1
replace ylmpri_ci=0 if categopri_ci==4
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 


***************
***ylmsec_ci: Ingreso laboral monetario de actividad secundaria. Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria.***
***************
egen ylmsec_ci= rsum(yliquido2), missing
replace ylmsec_ci=. if emp_ci~=1 & yliquido2 ==.
replace ylmsec_ci=0 if categosec_ci==4
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 


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
egen ylnmpri_ci=rsum(yalimen ytranspo yvesti yvivien), missing
replace ylnmpri_ci=. if yalimen==. & ytranspo==. & yvesti==. & yvivien==.    
replace ylnmpri_ci=0 if categopri_ci==4


******************
****ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar. ****
******************
gen ylnmsec_ci=.
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"


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
*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
gen ynlnm_ci=.
label var ynlnm_ci "Ingreso no laboral no monetario" 


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


 