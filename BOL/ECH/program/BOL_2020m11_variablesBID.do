*El presente do file genera las variables de ingreso asignadas a Javier Torres

*País:	Bolivia
*Año :	2020	

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
			yotros	: Otros ingresos no monetarios de la actividad principal
	
	ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria:
			yalimen2: Ingreso en alimentos
			yvivien2: Ingreso en vivienda
	
	ylnmotros_ci: Ingresos laboral no monetario de otras actividades.
			Missing, no hay variables de ingresos de otras ocupaciones
	
	ylnm_ci: Ingreso laboral no monetario
			Esta variable se genera a partir de: ylnmpri_ci y ylnmsec_ci. 
	
	ynlnm_ci: Ingreso no laboral no monetario
			yalimento	: Ingreso por transferencias para alimentos
			yotro_bono2	: Ingreso por transferencias de bonos
	
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
/* ¿Cuánto es su salario líquido, excluyendo los descuentos de ley (AFP, IVA)? Monto (Bs)

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
gen yliquido = .
replace yliquido= s04c_18a*30	if s04c_18b==1
replace yliquido= s04c_18a*4.3	if s04c_18b==2
replace yliquido= s04c_18a*2	if s04c_18b==3
replace yliquido= s04c_18a		if s04c_18b==4
replace yliquido= s04c_18a/2	if s04c_18b==5
replace yliquido= s04c_18a/3	if s04c_18b==6
replace yliquido= s04c_18a/6	if s04c_18b==7
replace yliquido= s04c_18a/12	if s04c_18b==8


************************************
* ycomisio: Ingreso por comisiones *
************************************
* Durante los últimos doce meses, ¿recibió usted pagos en efectivo por: A.Comisiones, destajo, propinas, bonos de transporte o refrigerio? Monto (Bs)
gen ycomisio = .
replace ycomisio= s04c_20aa*30	if s04c_20ab==1
replace ycomisio= s04c_20aa*4.3	if s04c_20ab==2
replace ycomisio= s04c_20aa*2	if s04c_20ab==3
replace ycomisio= s04c_20aa		if s04c_20ab==4
replace ycomisio= s04c_20aa/2	if s04c_20ab==5
replace ycomisio= s04c_20aa/3	if s04c_20ab==6
replace ycomisio= s04c_20aa/6 	if s04c_20ab==7
replace ycomisio= s04c_20aa/12 	if s04c_20ab==8


**************************************
* yhrsextr: Ingreso por horas extras *
**************************************
* Durante los últimos doce meses, ¿recibió usted pagos en efectivo por Horas Extras
gen yhrsextr= .
replace yhrsextr= s04c_20ba *30	    if s04c_20bb==1
replace yhrsextr= s04c_20ba *4.3  	if s04c_20bb==2
replace yhrsextr= s04c_20ba *2		if s04c_20bb==3
replace yhrsextr= s04c_20ba 		if s04c_20bb==4
replace yhrsextr= s04c_20ba /2		if s04c_20bb==5
replace yhrsextr= s04c_20ba /3		if s04c_20bb==6
replace yhrsextr= s04c_20ba /6	    if s04c_20bb==7
replace yhrsextr= s04c_20ba /12	    if s04c_20bb==8


************************************************
* yprima: Ingreso por prima/bono de producción *
************************************************
* Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Bono o prima de producción
gen yprima = .
replace yprima = s04c_19a/12


*******************************
* yaguina: Pago por aguinaldo *
*******************************
* Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Aguinaldo
gen yaguina = .
replace yaguina = s04c_19b/12


*******************************************
* yactpri: ingreso actividad principal independientes *
*******************************************
*Aquí se tiene en cuenta el Ingreso Líquido de la Actividad Principal de los independientes 
*  Una vez descontadas todas sus obligaciones (sueldos, salarios, etc.),¿cuánto le queda para uso del hogar?
gen yactpri = .
replace yactpri= s04d_25a*30	if s04d_25b==1
replace yactpri= s04d_25a*4.3	if s04d_25b==2
replace yactpri= s04d_25a*2		if s04d_25b==3
replace yactpri= s04d_25a		if s04d_25b==4
replace yactpri= s04d_25a/2		if s04d_25b==5
replace yactpri= s04d_25a/3		if s04d_25b==6
replace yactpri= s04d_25a/6		if s04d_25b==7
replace yactpri= s04d_25a/12	if s04d_25b==8


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
* PARTE F: INGRESO LABORAL DE LA OCUPACIÓN SECUNDARIA
* ¿Cuánto es su salario líquido en ésta otra ocupación, excluyendolos descuentos de ley (AFP,IVA)?
gen yliquido2 = .
replace yliquido2= s04f_35a*30		if s04f_35b==1
replace yliquido2= s04f_35a*4.3		if s04f_35b==2
replace yliquido2= s04f_35a*2		if s04f_35b==3
replace yliquido2= s04f_35a			if s04f_35b==4
replace yliquido2= s04f_35a/2		if s04f_35b==5
replace yliquido2= s04f_35a/3		if s04f_35b==6
replace yliquido2= s04f_35a/6		if s04f_35b==7
replace yliquido2= s04f_35a/12		if s04f_35b==8


*****************
* yhrsextr2: Ingreso por horas extra de la actividad secundaria*
*****************
*  Durante los últimos doce meses, ha recibido:
* ¿Pago por horas extras, bono o prima de producción,aguinaldo?
gen yhrsextr2 = .
replace yhrsextr2=s04f_36a1/12 if s04f_36a==1


*************
* yalimen: Ingreso en alimentos *
*************
gen yalimen = .
replace yalimen= s04c_22a2 *30		if s04c_22a1 ==1 & s04c_22a==1
replace yalimen= s04c_22a2 *4.3 	if s04c_22a1 ==2 & s04c_22a==1
replace yalimen= s04c_22a2 *2		if s04c_22a1 ==3 & s04c_22a==1
replace yalimen= s04c_22a2 		    if s04c_22a1 ==4 & s04c_22a==1
replace yalimen= s04c_22a2 /2		if s04c_22a1 ==5 & s04c_22a==1
replace yalimen= s04c_22a2 /3		if s04c_22a1 ==6 & s04c_22a==1
replace yalimen= s04c_22a2 /6		if s04c_22a1 ==7 & s04c_22a==1
replace yalimen= s04c_22a2 /12		if s04c_22a1 ==8 & s04c_22a==1


**************
* ytranspo: Ingreso en transporte *
**************
*  INGRESOS DEL TRABAJADOR ASALARIADO
* Además de los ingresos recibidos en dinero por su trabajo, en los últimos doce meses ¿recibió, usted...
* Transporte hacia y desde el lugar de su trabajo?
gen ytranspo = .
replace ytranspo= s04c_22b2*30	    if s04c_22b1==1 & s04c_22b==1
replace ytranspo= s04c_22b2*4.3	    if s04c_22b1==2 & s04c_22b==1
replace ytranspo= s04c_22b2*2		if s04c_22b1==3 & s04c_22b==1
replace ytranspo= s04c_22b2 	    if s04c_22b1==4 & s04c_22b==1
replace ytranspo= s04c_22b2/2		if s04c_22b1==5 & s04c_22b==1
replace ytranspo= s04c_22b2/3		if s04c_22b1==6 & s04c_22b==1
replace ytranspo= s04c_22b2/6		if s04c_22b1==7 & s04c_22b==1
replace ytranspo= s04c_22b2/12	    if s04c_22b1==8 & s04c_22b==1


**************
* yvesti: Ingreso en vestimenta *
**************
gen yvesti = .
replace yvesti= s04c_22c*30			if s04c_22c1==1 & s04c_22c==1
replace yvesti= s04c_22c*4.3		if s04c_22c1==2 & s04c_22c==1
replace yvesti= s04c_22c*2		    if s04c_22c1==3 & s04c_22c==1
replace yvesti= s04c_22c			if s04c_22c1==4 & s04c_22c==1
replace yvesti= s04c_22c/2		    if s04c_22c1==5 & s04c_22c==1
replace yvesti= s04c_22c/3		    if s04c_22c1==6 & s04c_22c==1
replace yvesti= s04c_22c/6		    if s04c_22c1==7 & s04c_22c==1
replace yvesti= s04c_22c/12			if s04c_22c1==8 & s04c_22c==1


************
* yvivien: Ingreso en vivienda *
************
gen yvivien = .
replace yvivien= s04c_22d2*30		if s04c_22d1==1 & s04c_22d==1
replace yvivien= s04c_22d2*4.3	    if s04c_22d1==2 & s04c_22d==1
replace yvivien= s04c_22d2*2		if s04c_22d1==3 & s04c_22d==1
replace yvivien= s04c_22d2		    if s04c_22d1==4 & s04c_22d==1
replace yvivien= s04c_22d2/2		if s04c_22d1==5 & s04c_22d==1
replace yvivien= s04c_22d2/3		if s04c_22d1==6 & s04c_22d==1
replace yvivien= s04c_22d2/6		if s04c_22d1==7 & s04c_22d==1
replace yvivien= s04c_22d2/12		if s04c_22d1==8 & s04c_22d==1


*************
* yotros: Otros ingresos no monetarios *
*************
gen yotros = .
replace yotros= s04c_22e2*30	if s04c_22e1==1 & s04c_22e==1
replace yotros= s04c_22e2*4.3	if s04c_22e1==2 & s04c_22e==1
replace yotros= s04c_22e2*2	    if s04c_22e1==3 & s04c_22e==1
replace yotros= s04c_22e2		if s04c_22e1==4 & s04c_22e==1
replace yotros= s04c_22e2/2	    if s04c_22e1==5 & s04c_22e==1
replace yotros= s04c_22e2/3		if s04c_22e1==6 & s04c_22e==1
replace yotros= s04c_22e2/6		if s04c_22e1==7 & s04c_22e==1
replace yotros= s04c_22e2/12	if s04c_22e1==8 & s04c_22e==1

*************
* yalimen2: Ingreso en alimentos de la actividad secundaria *
*************
gen yalimen2 = .
replace yalimen2=s04f_36b1/12	if s04f_36b==1


**************
* yvivien2: Ingreso en vivienda de la actividad secundaria *
**************
gen yvivien2= .
replace yvivien2=s04f_36c1/12	if s04f_36c==1


**************
* yalimento: Ingreso en alimentos por transferencias *
**************
gen yalimento= .
replace yalimento = s05b_05ca*4.3	    if s05b_05cb==2
replace yalimento= s05b_05ca*2			if s05b_05cb==3
replace yalimento= s05b_05ca	        if s05b_05cb==4
replace yalimento= s05b_05ca/2			if s05b_05cb==5
replace yalimento= s05b_05ca/3			if s05b_05cb==6
replace yalimento= s05b_05ca/6			if s05b_05cb==7
replace yalimento= s05b_05ca/12			if s05b_05cb==8


**************
* yotro_bono2: Ingreso no monetario de bonos estatales *
**************
gen yotro_bono2= .
replace yotro_bono2= s05b_06fa	    	if s05b_06fb==4
replace yotro_bono2= s05b_06fa/12		if s05b_06fb==8


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
egen ylnmpri_ci=rsum(yalimen ytranspo yvesti yvivien yotros), missing
replace ylnmpri_ci=. if yalimen==. & ytranspo==. & yvesti==. & yvivien==. & yotros==.   
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
egen ynlnm_ci=rsum(yalimento yotro_bono2), missing
replace ynlnm_ci=. if yalimento==. & yotro_bono2==.
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


 