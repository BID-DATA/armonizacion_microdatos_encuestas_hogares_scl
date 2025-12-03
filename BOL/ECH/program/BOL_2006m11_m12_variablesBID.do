*El presente do file genera las variables de ingreso asignadas a Javier Torres

*País:	Bolivia
*Año :	2006
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
			yhrsextr2: Ingreso por horas extra de la actividad secundaria

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
			yalimen2: Ingreso en alimentos
			yvivien2: Ingreso en vivienda
	
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
* yliquido: salario líquido *
*****************************
/*  ¿Cuánto es su salario líquido, excluyendo los descuentos de ley (AFP, IVA)? Monto (Bs)

¿Cuánto es su salario líquido, excluyendo los descuentos de ley (AFP, IVA)? Frecuencia de pago.
		1. Diario 
		2. Semanal 
		3. Quincenal 
		4. Mensual 
		5. Bimestral 
		6. Trimestral 
		7. Semestral 
		8. Anual
*/
*Las variables se trasladan a frecuencia mensual.
gen s5_29a2 = .
replace s5_29a2 = s5_29a 		if s5_29b=="A"
replace s5_29a2 = s5_29a*8.1 	if s5_29b=="B"

gen yliquido = .
replace yliquido= s5_29a2*30	if s5_29c==1
replace yliquido= s5_29a2*4.3	if s5_29c==2
replace yliquido= s5_29a2*2		if s5_29c==3
replace yliquido= s5_29a2		if s5_29c==4
replace yliquido= s5_29a2/2		if s5_29c==5
replace yliquido= s5_29a2/3		if s5_29c==6
replace yliquido= s5_29a2/6 	if s5_29c==7
replace yliquido= s5_29a2/12	if s5_29c==8


************************************
* ycomisio: Ingreso por comisiones *
************************************
* Durante los últimos doce meses, ¿recibió usted pagos en efectivo por: A.Comisiones, destajo, propinas, bonos de transporte o refrigerio? Monto (Bs)
gen ycomisio = .
replace ycomisio= s5_31a1*30	if s5_31a2==1
replace ycomisio= s5_31a1*4.3	if s5_31a2==2
replace ycomisio= s5_31a1*2		if s5_31a2==3
replace ycomisio= s5_31a1		if s5_31a2==4
replace ycomisio= s5_31a1/2		if s5_31a2==5
replace ycomisio= s5_31a1/3		if s5_31a2==6
replace ycomisio= s5_31a1/6 	if s5_31a2==7
replace ycomisio= s5_31a1/12	if s5_31a2==8


**************************************
* yhrsextr: Ingreso por horas extras *
**************************************
* Durante los últimos doce meses, ¿recibió usted pagos en efectivo por Horas Extras
gen yhrsextr= .
replace yhrsextr= s5_31b1*30	if s5_31b2==1
replace yhrsextr= s5_31b1*4.3	if s5_31b2==2
replace yhrsextr= s5_31b1*2		if s5_31b2==3
replace yhrsextr= s5_31b1		if s5_31b2==4
replace yhrsextr= s5_31b1/2		if s5_31b2==5
replace yhrsextr= s5_31b1/3		if s5_31b2==6
replace yhrsextr= s5_31b1/6 	if s5_31b2==7
replace yhrsextr= s5_31b1/12	if s5_31b2==8


************************************************
* yprima: Ingreso por prima/bono de producción *
************************************************
* Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Bono o prima de producción
gen yprima = .
replace yprima = (s5_30a1)/12 		if s5_30a2=="A"
replace yprima = (s5_30a1*8.1)/12		if s5_30a2=="B"


*******************************
* yaguina: Pago por aguinaldo *
*******************************
* Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Aguinaldo
gen yaguina = .
replace yaguina = (s5_30b1)/12 		if s5_30b2=="A"
replace yaguina = (s5_30b1*8.1)/12 	if s5_30b2=="B"


*******************************************
* yactpri: ingreso actividad principal independientes *
*******************************************
*Aquí se tiene en cuenta el Ingreso Líquido de la Actividad Principal de los independientes 
*  Una vez descontadas todas sus obligaciones (sueldos, salarios, etc.),¿cuánto le queda para uso del hogar?
gen s5_36a2 = .
replace s5_36a2 = s5_36a 		if s5_36b=="A"
replace s5_36a2 = s5_36a*8.1 		if s5_36b=="B"

gen yactpri = .
replace yactpri= s5_36a2*30		if s5_36c==1
replace yactpri= s5_36a2*4.3	if s5_36c==2
replace yactpri= s5_36a2*2		if s5_36c==3
replace yactpri= s5_36a2		if s5_36c==4
replace yactpri= s5_36a2/2		if s5_36c==5
replace yactpri= s5_36a2/3		if s5_36c==6
replace yactpri= s5_36a2/6		if s5_36c==7
replace yactpri= s5_36a2/12		if s5_36c==8


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
gen s5_45a2 = .
replace s5_45a2 = s5_45a 		if s5_45b=="A"
replace s5_45a2 = s5_45a*8.1 	if s5_45b=="B"

gen yliquido2 = .
replace yliquido2= s5_45a2*30		if s5_45c==1
replace yliquido2= s5_45a2*4.3		if s5_45c==2
replace yliquido2= s5_45a2*2		if s5_45c==3
replace yliquido2= s5_45a2		    if s5_45c==4
replace yliquido2= s5_45a2/2		if s5_45c==5
replace yliquido2= s5_45a2/3		if s5_45c==6
replace yliquido2= s5_45a2/6		if s5_45c==7
replace yliquido2= s5_45a2/12		if s5_45c==8

*****************
* yhrsextr2: Ingreso por horas extra de la actividad secundaria*
*****************
* Durante los últimos doce meses, ha recibido:
* ¿Pago por horas extras, bono o prima de producción,aguinaldo?
gen yhrsextr2 = .
replace yhrsextr2=s5_46a2/12 if s5_46a1==1


*************
* yalimen: Ingreso en alimentos *
*************
gen yalimen = .
replace yalimen= s5_33a3*30		if s5_33a2==1 & s5_33a1==1
replace yalimen= s5_33a3*4.3	if s5_33a2==2 & s5_33a1==1
replace yalimen= s5_33a3*2		if s5_33a2==3 & s5_33a1==1
replace yalimen= s5_33a3		if s5_33a2==4 & s5_33a1==1
replace yalimen= s5_33a3/2		if s5_33a2==5 & s5_33a1==1
replace yalimen= s5_33a3/3		if s5_33a2==6 & s5_33a1==1
replace yalimen= s5_33a3/6		if s5_33a2==7 & s5_33a1==1
replace yalimen= s5_33a3/12		if s5_33a2==8 & s5_33a1==1


**************
* ytranspo: Ingreso en transporte *
**************
* INGRESOS DEL TRABAJADOR ASALARIADO
* Además de los ingresos recibidos en dinero por su trabajo, en los últimos doce meses ¿recibió, usted...
* Transporte hacia y desde el lugar de su trabajo?
gen ytranspo = .
replace ytranspo= s5_33b3*30	if s5_33b2==1 & s5_33b1==1
replace ytranspo= s5_33b3*4.3	if s5_33b2==2 & s5_33b1==1
replace ytranspo= s5_33b3*2		if s5_33b2==3 & s5_33b1==1
replace ytranspo= s5_33b3		if s5_33b2==4 & s5_33b1==1
replace ytranspo= s5_33b3/3		if s5_33b2==6 & s5_33b1==1
replace ytranspo= s5_33b3/6		if s5_33b2==7 & s5_33b1==1
replace ytranspo= s5_33b3/12	if s5_33b2==8 & s5_33b1==1



**************
* yvesti: Ingreso en vestimenta *
**************
gen yvesti = .
replace yvesti= s5_33c3*30		if s5_33c2==1 & s5_33c1==1
replace yvesti= s5_33c3*4.3		if s5_33c2==2 & s5_33c1==1
replace yvesti= s5_33c3*2		if s5_33c2==3 & s5_33c1==1
replace yvesti= s5_33c3			if s5_33c2==4 & s5_33c1==1
replace yvesti= s5_33c3/2		if s5_33c2==5 & s5_33c1==1
replace yvesti= s5_33c3/3		if s5_33c2==6 & s5_33c1==1
replace yvesti= s5_33c3/6		if s5_33c2==7 & s5_33c1==1
replace yvesti= s5_33c3/12		if s5_33c2==8 & s5_33c1==1

************
* yvivien: Ingreso en vivienda *
************
gen yvivien = .
replace yvivien= s5_33d3*30		if s5_33d2==1 & s5_33d1==1
replace yvivien= s5_33d3*4.3	if s5_33d2==2 & s5_33d1==1
replace yvivien= s5_33d3*2		if s5_33d2==3 & s5_33d1==1
replace yvivien= s5_33d3		if s5_33d2==4 & s5_33d1==1
replace yvivien= s5_33d3/3		if s5_33d2==6 & s5_33d1==1
replace yvivien= s5_33d3/12		if s5_33d2==8 & s5_33d1==1


*************
* yalimen2: Ingreso en alimentos de la actividad secundaria *
*************
gen yalimen2 = .
replace yalimen2= s5_46b2/12		if s5_46b1==1


**************
* yvivien2: Ingreso en vivienda de la actividad secundaria *
**************
gen yvivien2= .
replace yvivien2= s5_46c2/12 if s5_46c1==1


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
egen ylmsec_ci= rsum(yliquido2 yhrsextr2), missing
replace ylmsec_ci=. if emp_ci~=1 & yhrsextr2==. & yliquido2 ==.
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
egen ylnmsec_ci=rsum(yalimen2  yvivien2), missing
replace ylnmsec_ci=. if yalimen2==.  & yvivien2==.  
replace ylnmsec_ci=0 if categosec_ci==4
replace ylnmsec_ci=. if emp_ci==0
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


 