* (Versión Stata 12)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 


global ruta = "${surveysFolder}"

local PAIS CHL
local ENCUESTA CASEN
local ANO "2000"
local ronda m11_m12 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Chile
Encuesta: CASEN
Round: Noviembre - Diciembre
Autores: 
Versión 2007: Victoria
Versión 2012: Yanira Oviedo (YO), Yessenia Loaysa (YL)
Modificación 2014: Mayra Sáenz - Email: mayras@iadb.org - saenzmayra.a@gmail.com
Última versión: María Laura Oliveri (MLO) - Email: mloliveri@iadb.org, lauraoliveri@yahoo.com
Fecha última modificación: 26 de Marzo de 2013

							SCL/LMK - IADB
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/


use `base_in', clear

		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************
		
	****************
	* region_BID_c *
	****************
	
gen region_BID_c=4
/***** revision July 29,2005  Suzanne

removed condition (& edad_ci<18) froom the following two lines:

by idh_ch: egen byte nhijos_ch=sum((relacion_ci==3) & edad_ci<18)
by idh_ch: egen byte notropari_ch=sum((relacion_ci==4) & edad_ci>=18)

******* revision June 8 2006 MFP
removed desemp1 and desemp2 because the reference period of 2 months implies that those variables
can't be created.
Now desemp3== old definition of desemp1

previous code:

gen desemp1_ci=(o1==2 & o2==2 & o3==1) *El periodo de referencia de la encuesta es de dos meses!
gen desemp2_ci=(desemp1_ci | (o1==2 & o2==2 & o3==2 & (o7==7)))
gen desemp3_ci=(desemp2_ci | (o4>8 & o4<=300))
***/

/*** revision October 16 2006 (Victoria)
The code for the education dummies was changed in order to make it
comparable with the following years and also to make the returns
to education coherent. 
Old code can be seen in the "VARIABLES EDUCATIVAS" sector

Also two new conditions were added to the creation of aedu_ci
*/

/*** revision October 23 2006 (Victoria)
Change the code for ynlm_ci that double counted some variables.
Old code can be seen in the "VARIABLES DE DEMANDA LABORAL" section
*/
/*** revision January 24 2007 (Ma Fda)
Change the code for firmapeq. It was created as tamfirma(1=more than 5 employees)
This change implied the respective change in sociometro's program (DONE!)
*/

/**** revision August 2007 (Victoria) ***

With the unification Sociometro/Equis we decided to add two new varibales: howner and floor.
This variables were already created for Atlas

gen howner=(viviprop_ch==1 | viviprop==2);
replace howner=. if viviprop_ch==.;
gen floor=(piso_ch==1);
replace floor=. if piso_ch==.;

Also, the orginal data was replaced with the new Mecovi versions
*****/


/******************
VARIABLES DEL HOGAR
*******************/
gen factor_ch=expr
ren segmento seg
ren folio f
egen idh_ch=group(r p c z seg f)
tostring idh_ch, replace

gen idp_ci=o
tostring idp_ci, replace

gen zona_c=z
replace zona_c=0 if z==2
gen pais_c="CHL"
gen anio_c=2000
gen mes_c=11
gen relacion_ci=pco1
replace relacion_ci=4 if pco1>=4 & pco1<=10
replace relacion_ci=5 if pco1==11
replace relacion_ci=6 if pco1==12

/*************************************
VARIABLES DE INFRAESTRUCTURA DEL HOGAR
**************************************/
gen aguared_ch=(v11==1 | v11==2 | v11==3)
gen aguadist_ch=v12
gen aguamala_ch=(v11==5|v11==6)
gen aguamide_ch=(v11==1 |v11==2)
gen luz_ch=(v15<=5)
gen luzmide_ch=(v15==1 | v15==2)
replace luzmide_ch=. if luz_ch==0
gen combust_ch=.
gen bano_ch=((v9!=0 & v32==.) | v32>0 & v32<=3)
gen banoex_ch=(v32==. | v32<v9)
replace banoex_ch=. if bano_ch==0 
gen des1_ch=0 if bano_ch==0 | v14==7
replace des1_ch=1 if v14==1 | v14==2
replace des1_ch=2 if v14==3 | v14==4
replace des1_ch=3 if v14==5 | v14==6
gen des2_ch=des1_ch
replace des2_ch=. if des1_ch==3
gen piso_ch=0 if v18==5
replace piso_ch=1 if v18<5
gen pared_ch=0 if v16>=4 & v16<=7
replace pared_ch=1 if v16<4
replace pared_ch=2 if v16==8
gen techo_ch=0 if v20>=5
replace techo_ch=1 if v20<5
gen resid_ch=.

 **Daniela Zuluaga- Enero 2018: Se agregan las variables aguamejorada_ch y banomejorado_ch cuya sintaxis fue elaborada por Mayra Saenz**
	
 *********************
 ***aguamejorada_ch***
 *********************
g       aguamejorada_ch = 1 if (v11 >=1 & v11 <=4)
replace aguamejorada_ch = 0 if (v11 >=5 & v11 <=6) | v12 == 3 

 *********************
 ***banomejorado_ch***
 *********************
g       banomejorado_ch = 1 if  (v14 >=1 & v14 <=4) 
replace banomejorado_ch = 0 if  (v14 >=5 & v14 <=7)

gen dorm_ch=v4 
egen piezaviv=rsum(v4 v5 v6 v7 v8 v9 v10), missing
replace piezaviv=. if v4==. & v5==. & v6==. & v7==. & v8==. & v9==. & v10==. 
egen piezahog=rsum(v27 v28 v29 v30 v31 v32 v33), missing
replace piezahog=. if v27==. & v28==. & v29==. & v30==. & v31==. & v32==. & v33==. 
gen cuartos_ch=piezaviv 
gen cocina_ch=(v8!=0)
sort idh_ch
by idh_ch: egen telef_ch=sum(p3==1)
replace telef_ch=1 if telef_ch>=1
by idh_ch: egen refrig_ch=sum(p2==1)
replace refrig_ch=1 if refrig_ch>=1
gen freez_ch=.
gen auto_ch=.
by idh_ch: egen compu_ch=sum(p6==1)
replace compu_ch=1 if compu_ch>=1
by idh_ch: egen internet_ch=sum(p7==1)
replace compu_ch=1 if compu_ch==1

/*****
cel_ch
*****/
sort idh_ch
by idh_ch: egen cel_ch=sum(p8==1)
replace cel_ch=1 if cel_ch>=1
replace cel_ch=. if p8==9 | p8==.

gen vivi1_ch=1 if v22==1 | v22==2
replace vivi1_ch=2 if v22==3
replace vivi1_ch=3 if v22>3
gen vivi2_ch=(vivi1_ch==1 | vivi1_ch==2)
gen viviprop_ch=0 if v23==5 | v23==6
replace viviprop_ch=1 if v23==1 | v23==3
replace viviprop_ch=2 if v23==2 | v23==4
replace viviprop_ch=3 if v23==10
replace viviprop_ch=4 if v23>6 & v23<=9
recode v24 (99999999=.)
gen vivitit_ch=.
gen vivialq_ch=v24 if viviprop_ch==0 /*Cuanto paga y cuanto pagaria estan en la misma pregunta*/
gen vivialqimp_ch=v24 if viviprop_ch!=0


/* new variables August 2007 */

gen howner=(viviprop_ch==1 | viviprop==2)
replace howner=. if viviprop_ch==.
gen floor=(piso_ch==1)
replace floor=. if piso_ch==.


/*********************
VARIABLES DEMOGRAFICAS
*********************/
gen factor_ci=expr
gen sexo_ci=sexo
gen edad_ci=edad

gen civil_ci=1 if ecivil==7
replace civil_ci=2 if ecivil==1 | ecivil==2
replace civil_ci=3 if ecivil==3 | ecivil==4 | ecivil==5
replace civil_ci=4 if ecivil==6

gen jefe_ci=(relacion_ci==1)
sort idh_ch
by idh_ch: egen byte nconyuges_ch=sum(relacion_ci==2) 
by idh_ch: egen byte nhijos_ch=sum(relacion_ci==3)
by idh_ch: egen byte notropari_ch=sum(relacion_ci==4)
by idh_ch: egen byte notronopari_ch=sum(relacion_ci==5)
by idh_ch: egen byte nempdom_ch=sum(relacion_ci==6)
gen byte clasehog_ch=0
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0 /*Unipersonal*/
replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0 /*Nuclear (child with or without spouse but without other relatives)*/
replace clasehog_ch=2 if nhijos_ch==0 & nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0 /*Nuclear (spouse with or without children but without other relatives)*/
replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0 /*Ampliado*/
replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))/*Compuesto (some relatives plus non relative)*/
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0 /*Corresidente*/
sort idh_ch
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))

gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"


	***************
	***upm_ci***
	***************
gen upm_ci=. 

	***************
	***estrato_ci**
	***************

clonevar estrato_ci=estrato
label variable estrato_ci "Estrato"


          ******************************
          *** VARIABLES DE DIVERSIDAD **
          ******************************
*Nathalia Maya & Antonella Pereira
*Julio 2021	

	***************
	***afroind_ci***
	***************
**Pregunta: Pueblos indígenas, pertenece usted o es descendiente de alguno de ellos? (etnia) (Aimara 1; Rapa-Nui 2; Quechua 3; Mapuche 4; Atacameño 5; Coya 6; Kawashkar 7; Yagán 8; No pertenece a ningún pueblo indígena 0; sin dato 9)
gen afroind_ci=. 
replace afroind_ci=1 if (etnia >=1 & etnia <=8 )
replace afroind_ci=3 if etnia==0
replace afroind_ci=. if etnia==9

	***************
	***afroind_ch***
	***************
gen afroind_jefe= afroind_ci if relacion_ci==1
egen afroind_ch  = min(afroind_jefe), by(idh_ch) 
drop afroind_jefe

	*******************
	***afroind_ano_c***
	*******************
gen afroind_ano_c=2000

	*******************
	***dis_ci***
	*******************
gen dis_ci=. 

	*******************
	***dis_ch***
	*******************
gen dis_ch=. 


/***************************
VARIABLES DE DEMANDA LABORAL
****************************/


****************
****condocup_ci*
****************

gen condocup_ci=.
replace condocup_ci=1 if (o1==1 | o2==1)
replace condocup_ci=2 if ((o1==2 | o2==2) & (o3==1))
recode condocup_ci (.=3) if edad_ci>=12 
replace condocup_ci=4 if edad<12
label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de PET" 
label value condocup_ci condocup_ci

************
***emp_ci***
************
gen emp_ci=(condocup_ci==1)

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)

*************
***pea_ci***
*************
gen pea_ci=(emp_ci==1 | desemp_ci==1)
*gen emp_ci=(o1==1 | (o1==2 & o2==1))
* Utiliza CIUO-88 (MGD 6/16/17)
gen ocupa_ci=.
replace ocupa_ci=1 if (o8>=2100 & o8<=3480) & emp_ci==1
replace ocupa_ci=2 if (o8>=1100 & o8<=1319) & emp_ci==1
replace ocupa_ci=3 if (o8>=4100 & o8<=4223) & emp_ci==1
replace ocupa_ci=4 if ((o8>=9100 & o8<=9113) | (o8>=5200 & o8<=5230)) & emp_ci==1
replace ocupa_ci=5 if ((o8>=5100 & o8<=5169) | (o8>=9100 & o8<=9162)) & emp_ci==1
replace ocupa_ci=6 if ((o8>=6100 & o8<=6210) | (o8>=9200 & o8<=9220)) & emp_ci==1
replace ocupa_ci=7 if ((o8>=7100 & o8<=8340) | (o8>=9300 & o8<=9333))  & emp_ci==1
replace ocupa_ci=8 if o8==110 & emp_ci==1
replace ocupa_ci=9 if o8==9999 & emp_ci==1


label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras", add
label value ocupa_ci ocupa_ci


****************
***  rama_ci ***
****************	
/*
gen rama_ci=substr(string(o9),1,1)
destring rama_ci, replace
replace rama_ci=. if emp_ci==0 | rama_ci<=0
*/

gen rama_ci=.
replace rama_ci=1 if (o9>=1110 & o9<=1499)   & emp_ci==1
replace rama_ci=2 if (o9>=2000 & o9<=2990) & emp_ci==1
replace rama_ci=3 if (o9>=3000 & o9<=3990) & emp_ci==1
replace rama_ci=4 if (o9>=4000 & o9<=4990) & emp_ci==1
replace rama_ci=5 if o9==5000 & emp_ci==1
replace rama_ci=6 if (o9>=6000 & o9<=6990) & emp_ci==1
replace rama_ci=7 if (o9>=7000 & o9<=7990) & emp_ci==1
replace rama_ci=8 if (o9>=8000 & o9<=8400) & emp_ci==1
replace rama_ci=9 if (o9>=9000  & o9<=9900) & emp_ci==1


gen horaspri_ci=o14
replace horaspri_ci=. if emp_ci==0 | o14==999

gen horastot_ci=horaspri_ci


***************************
***VARIABLES DE INGRESOS***
***************************

**************************************************************
*** CONSTRUCCIÓN DE LAS VARIABLES ARMONIZADAS DEL BID ***		
**************************************************************

* A.	Ingresos laborales a nivel individuo

***************
* A.1.1 ylmpri_ci: Ingreso laboral monetario de actividad principal: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia). Considera ingresos corrientes y extraordinarios.***
***************
gen 		ylmpri_ci=yopraj 
replace 	ylmpri_ci=. if emp_ci==0
label var 	ylmpri_ci "Ingreso laboral monetario actividad principal" 


***************
* A.1.2 ylmsec_ci: Ingreso laboral monetario de actividad secundaria. Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria.***
***************
*No hay variables de ingreso de la ocupación secundaria
gen 	 	ylmsec_ci=.
label var 	ylmsec_ci "Ingreso laboral monetario segunda actividad" 



*****************
* A.1.3 ylmotros_ci: Ingreso laboral monetario de otras actividades. Variable continua que indica el monto mensual de ingresos monetarios provenientes de actividades distintas de la principal y secundaria. Incluye ingresos percibidos por desocupados o inactivos derivados de trabajos previos al cese. ***
*****************
*ytrsaj: Ingreso de otras ocupaciones
gen 	  ylmotros_ci =	ytrsaj if emp_ci == 1  
replace   ylmotros_ci = . if ytrsaj <= 0 | ytrsaj >= 999999999
replace   ylmotros_ci = 0 if categopri_ci == 4
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 


************
* A.1 ylm_ci : Ingreso laboral monetario total: Variable continua que indica el monto mensual total de ingresos laborales monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylmpri_ci, ymsec_ci e ylmotros_ci.***
************
* Escrita como en el manual
gen double  ylm_ci =rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi
replace 	ylm_ci=. if emp_ci!=1
label var   ylm_ci "Ingreso laboral monetario total" 



*************************
* Ingreso No Monetario *
*************************


******************
*** A.2.1 ylnmpri_ci: Ingreso laboral no monetario de actividad principal. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad principal de cada miembro del hogar. ***
******************
*No hay variables de ingreso laboral no monetario
gen 	  ylnmpri_ci=. // No hace falta condiciones
label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal" 


******************
* A.2.2 ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar. ****
******************
*No hay variables de ingreso laboral no monetario
gen 	  ylnmsec_ci=. // No hace falta condiciones
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"


******************
*** A.2.3 ylnmotros_ci: Ingresos laboral no monetario de otras actividades. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de actividades distintas de la principal y/o secundaria de cada miembro del hogar.***
******************
*yespaj: Remuneraciones en especie
gen 		ylnmotros_ci= yespaj if emp_ci == 1
label var   ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 


****************
* nrylmpri_ci * 
****************
gen 	nrylmpri_ci=(emp_ci==1 & ylmpri_ci==.)
replace nrylmpri_ci=. if emp_ci==0



*************
* A.2 ylnm_ci:  Ingreso laboral no monetario. Variable continua que indica el monto mensual total de ingresos laborales no monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylnmpri_ci, ylnmsec_ci e ylnmotros_ci.***
*************
gen double ylnm_ci =rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
label var  ylnm_ci "Ingreso laboral NO monetario total"  




************************************************
* B.	Ingresos no laborales a nivel individuo
************************************************

* B.1 ynlm_ci:  Ingreso no laboral monetario público del individuo. Variable continua que indica el monto mensual del ingreso no laboral MONETARIO proveniente de otras fuentes no laborales. 
****
gen 	yautaj1= yautaj //  ingreso autónomo en el hogar
replace yautaj1= 0 if yautaj==.

gen 	ytrabaj1= ytrabaj //  ingreso del trabajo
replace ytrabaj1= 0 if ytrabaj==.

gen 	ysubaj1= ysubaj // subsidios monetarios
replace ysubaj1= 0 if ysubaj==.

* 
gen negytrabaj1     = -ytrabaj1
replace negytrabaj1 = 0 if ytrabaj1==.

egen    ynlm_ci = rsum(yautaj1 negytrabaj1  ysubaj1), missing
replace ynlm_ci=. if yautaj==. & ytrabaj==. & ysubaj==.  
label var ynlnm_ci "Ingreso no laboral monetario" 
*******************************************************************************


***********************************************************
****************
* nrylmpri_ch  * 
**************** 
sort idh_ch 
by idh_ch: egen nrylmpri_ch=max(nrylmpri_ci) if miembros_ci==1

*************************************************************


**************
***B.2 ynlnm_ci: Ingreso no laboral no monetario. Variable continua que indica el monto mensual del ingreso no laboral no monetario (otras fuentes). En esta categoría se encuentran otros beneficios y transferencias no monetarias como las donaciones en alimentos, útiles escolares, becas, entre otros.***
**************
*No hay variables de ingreso no laboral no monetario
gen       ynlnm_ci=.
label var ynlnm_ci "Ingreso no laboral no monetario" 



*******************************************************************************
* C.Ingresos total a nivel de individuo
********************************************************************************
* C.1 ytot_ci: Ingreso mensual total del individuo que incluye las variables ylm_ci ylnm_ci ynlm_ci ynlnm_ci. ***
**************
*Código extraído del manual
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)
label var ytot_ci "Ingreso mensual total del individuo" 


*******************************************************************************
* D.	Ingresos laborales y no laborales a nivel hogar
********************************************************************************

**************
* D.1 ylm_ch : Ingreso laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso laboral monetario del hogar, ignora las `No respuesta'.**
**************
*Código extraído del manual
bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi
label var ylm_ch "Ingreso laboral monetario del hogar"


***************
* D.2 ylnm_ch: Ingreso laboral no monetario del hogar. Variable continua que indica el monto del ingreso laboral no monetario del hogar. ***
***************
*Código extraído del manual
bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi
label var ylnm_ch "Ingreso laboral no monetario del hogar"


/*
****************
* ylmnr_ch       * 
****************
gen ylmnr_ch=ylm_ch
replace ylmnr_ch=. if nrylmpri_ch==1
*/


*******************************************************************************
* E.	Ingresos total a nivel de hogar
********************************************************************************

****************
* ynlm_ch 
****************
by idh_ch: egen ynlm_ch=sum(ynlm_ci)if miembros_ci==1, missing


****************
*** ynlnm_ch: Ingreso no laboral no monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral no monetario del hogar (otras fuentes). ***
****************
*Como no hay variables de ingreso no monetario, esta variable queda como missing
gen ynlnm_ch=.
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"


**************
*** E.1 ytot_ch: Ingreso mensual total del hogar *
**************
*Código extraído del manual
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
* regla de consistencia: tab ytot_ch if ytot_ch<0



*******************************************************************************
* F.	Salario por hora
********************************************************************************


*****************
* F.1 ylmhopri_ci: Variable continua que indica el monto del salario horario monetario de la actividad principal ***
*****************
*Código extraído del manual
gen byte  ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
replace   ylmhopri_ci = . if ylmhopri_ci <= 0
label var ylmhopri_ci "Salario monetario de la actividad principal" 


***************
* F.2 ylmho_ci: Variable continua que indica el monto del salario horario monetario de todas las actividades.*
****************
*Código extraído del manual
gen byte  ylmho_ci = ylm_ci / (4.3 * horastot_ci)
replace   ylmho_ci = . if ylmho_ci <= 0
label var ylmho_ci "Salario monetario de todas las actividades"





gen rentaimp_ch=yaimhaj
gen autocons_ch=.
gen remesas_ci=.
gen remesas_ch=.

gen durades_ci=o4/4.3
replace durades_ci=. if o4==999 /*| activ!=2*/
label var durades_ci "Duración del desempleo"

g year=anio_c
g mes=12
g date1=mdy(o16m, 01, o16a)
g date2=mdy(mes, 31 , year)
replace date2=. if date1==. 
format 	date1 %td
format 	date2 %td	

g tiempotrab=date2-date1
g antiguedad_ci=tiempotrab/365
/*gen antiguedad_ci=(2000-o16a)+((11-o16m)/12)+1 if o16m<=11
replace antiguedad_ci=(2000-o16a)+1 if o16m==12 | o16m==99/*Hay una cita en una de las bananas originales en donde dicen que 
las entrevistas fueron realizadas casi finalizando el ciclo lectivo (y, como consecuencia, se consideraba que ese año se 
sumaba a aedu). Por lo tanto, podemos suponer que las entrevistas se realizaron en noviembre a los efectos de calcular le 
tenure.*/
replace antiguedad_ci=. if o16a==9999 | o16m==99*/

/****************************
VARIABLES DEL MERCADO LABORAL
*****************************/
/*gen desemp1_ci=. 
gen desemp2_ci=.
gen desemp3_ci=(o1==2 & o2==2 & o3==1)
/*El periodo de referencia de la encuesta es de dos meses!*/
gen pea1_ci=.
gen pea2_ci=.
gen pea3_ci=(emp_ci==1 | desemp3_ci==1)*/

gen desalent_ci=(o1==2 & o2==2 & o3==2 & o7==8)

gen subemp_ci=.
gen tiempoparc_ci=.
gen categopri_ci=.
replace categopri_ci=1 if o10==1
replace categopri_ci=2 if o10==2
replace categopri_ci=3 if o10>=3 & o10<=7
replace categopri_ci=4 if o10==8
replace categopri_ci=. if emp_ci==0
gen categosec_ci=.

/*
gen contrato_ci=(o11>=1 & o11<=3)
replace contrato_ci=. if emp_ci==0
gen segsoc_ci=(o17<=7)
replace segsoc_ci=. if emp_ci==0 /*Esta variable es solo para los empleados!!!: La pregunta 25 es para todas las personas, 
tengan empleo o no*/
*/
gen nempleos_ci=1 if o29==2
replace nempleos_ci=2 if o29==1

/*
gen firmapeq_ci=0 if o13=="A" | o13=="B"
replace firmapeq_ci=1 if o13=="C" | o13=="D" | o13=="E" | o13=="F"
replace firmapeq_ci=. if o13=="X" | emp_ci==0
*cambio en 01/24/07*
ren firmapeq_ci tamfirma_ci
gen firmapeq_ci=1 if tamfirma_ci==0
replace firmapeq_ci=0 if tamfirma_ci==1
replace firmapeq_ci=. if emp_ci==0
drop tamfirma_ci
*/

* Mod MLO incorporacion 2015/10
gen spublico_ci=(o10==3 | o10==4 | o10==9)
replace spublico_ci=. if emp_ci!=1
label var spublico_ci "Personas que trabajan en el sector público"

/*******************
VARIABLES EDUCATIVAS
*******************/
*************
***aedu_ci*** 
************* 

gen byte aedu_ci=.
replace aedu_ci=0 if e9==0 | e9==1 | e9==16 
replace aedu_ci=e8 if e9==2 | e9==3 
replace aedu_ci=. if e9==4 
*We assume that 'e9==4', Diferential Education, will be equivalent to missing

*NEW: 16 Oct 2006 (Victoria)
replace aedu_ci=6 if (e8>=6 & e9==2) 
replace aedu_ci=8 if (e8>=8 & e9==3) 
*

replace aedu_ci=e8+6 if e9==5 | e9==7
replace aedu_ci=e8+8 if e9==6 | e9==8
replace aedu_ci=e8+12 if e9>=9 & e9<14
replace aedu_ci=e8+17 if e9==15 /*See the original variable wich is not correct for this category*/
replace aedu_ci=. if e9==99

*****************
***asiste_ci***
*****************

gen asiste_ci=(e3==1)
replace asiste_ci=0 if e8==. | e9==16
label variable asiste_ci "Asiste actualmente a la escuela"

* We substract one year of education for those who are attending school at the moment that the survey took place
replace aedu_ci=aedu_ci-1 if aedu_ci!=0 & asiste_ci==1

/*
OLD CODE:
* Line of code with indicator edus2c_ci was deleted
gen eduui_ci=(e9==9 | e9==11 | e9==13) 
gen eduuc_ci=(e9==10 | e9==12 | e9==14 | e9==15)
* Line of code with indicator edusc_ci was deleted*/


*****************
* Line of code with indicator pqnoasis_ci was deleted*****************
*Modificado Mayra Sáenz Junio, 2016: antes se generaba como missing
* Line of code with indicator pqnoasis_ci was deleted
**************
*pqnoasis1_ci*
**************
**Daniela Zuluaga- Enero 2018: Se agrega la variable pqnoasis1_ci cuya sintaxis fue elaborada por Mayra Saenz**

g       pqnoasis1_ci = 1 if e5 ==6
replace pqnoasis1_ci = 2 if e5 ==7
replace pqnoasis1_ci = 3 if e5 ==9 | e5 ==15 | e5 ==16
replace pqnoasis1_ci = 4 if e5 ==11
replace pqnoasis1_ci = 5 if e5 ==8 | e5 ==10
replace pqnoasis1_ci = 7 if e5 ==1 | e5 ==12 
replace pqnoasis1_ci = 8 if e5 ==2  | e5 ==3  | e5 ==4
replace pqnoasis1_ci = 9 if e5 ==5 | e5 ==13 | e5 ==14 | e5 ==17 | e5 ==18 | e5 ==19 | e5 ==20

label define pqnoasis1_ci 1 "Problemas económicos" 2 "Por trabajo" 3 "Problemas familiares o de salud" 4 "Falta de interés" 5	"Quehaceres domésticos/embarazo/cuidado de niños/as" 6 "Terminó sus estudios" 7	"Edad" 8 "Problemas de acceso"  9 "Otros"
label value  pqnoasis1_ci pqnoasis1_ci

**************
* Line of code with indicator eduno_ci was deleted**************

* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted
**************
* Line of code with indicator edupi_ci was deleted**************

* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
**************
* Line of code with indicator edupc_ci was deleted**************

* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
**************
* Line of code with indicator edusi_ci was deleted**************

* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted
**************
* Line of code with indicator edusc_ci was deleted**************

* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted
***************
* Line of code with indicator edus1i_ci was deleted***************

* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted
***************
* Line of code with indicator edus1c_ci was deleted***************

* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted
***************
* Line of code with indicator edus2i_ci was deleted***************

* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted
***************
* Line of code with indicator edus2c_ci was deleted***************

* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted
**************
***eduui_ci***
**************

gen byte eduui_ci=0
replace eduui_ci=1 if (aedu_ci>12 & e9==9) | (aedu_ci>12 & e9==11) | (aedu_ci>12 & e9==13)
replace eduui_ci=. if aedu_ci==.
label variable eduui_ci "Universitaria incompleta"

***************
***eduuc_ci****
***************

gen byte eduuc_ci=0
replace eduuc_ci=1 if aedu_ci>12 &  (e9==10 | e9==12 | e9==14 | e9==15)
replace eduuc_ci=. if aedu_ci==.
label variable eduuc_ci "Universitaria incompleta o mas"


***************
***edupre_ci***
***************

gen edupre_ci=(e9==1)
replace edupre_ci=. if e9 == . | e9 == 99
label variable edupre_ci "Educacion preescolar"


**************
***eduac_ci***
**************
gen eduac_ci=.
replace eduac_ci=0 if e9>=9 & e9<=12
replace eduac_ci=1 if e9==13 & e9<=15
label variable eduac_ci "Superior universitario vs superior no universitario"

foreach var of varlist edu* {
replace `var'=. if  aedu_ci==.
}


* Line of code with indicator repiteult was deletedgen edupub_ci=.

***********************
*** CHILE 2000	    ***
***********************

 
 tab pco1
 tab nucleo
 tab pco1 nucleo
 tab pco1 nucleo if nucleo==0
 tab pco2 if pco1==12

 rename expr factor /* Expansión Regional */
 rename z area
 rename e1 alfabet
 rename e3 asiste
 rename e9 nivel
 rename e8 ultgrado
 rename v23 tenencia
 rename v11 agua
 rename v12 lugabast
 rename v14 servsani
 rename v16 pared
 rename v18 piso
 rename v22 tipoviv
 rename o10 categ
 rename o13 tamest

 gen     incl=1 if (pco1>=1 &  pco1<=12)
 replace incl=0 if  pco1==12 | (pco1==11 & nucleo==0)

** AREA

 tab area [w=factor]

** Gender classification of the population refering to the head of the household.

 sort r p c area seg f o 

* Household ID

 gen x=1 if pco1==1 	
 gen id_hogar=sum(x)
 drop x

 gen     sexo_d_=1 if pco1==1 & sexo==1
 replace sexo_d_=2 if pco1==1 & sexo==2

 egen sexo_d=max(sexo_d_), by(id_hogar)
 
 tab sexo    [w=factor]
 tab sexo_d [w=factor]

 tab sexo sexo_d if pco1==1

** Years of education. 

* ESC => "Escolaridad": Years of education for the population with 15 years or more of age.


 tab nivel ultgrado if asiste==1 & (nivel==6 | nivel==8) & edad==17
 tab nivel ultgrado if asiste==1 & (nivel==6 | nivel==8) & edad==17 & esc==12

 gen     anoest=0  if (nivel==4 | nivel==16 | nivel==1)
 replace anoest=1  if (nivel==2 | nivel==3) & ultgrado==1
 replace anoest=2  if (nivel==2 | nivel==3) & ultgrado==2
 replace anoest=3  if (nivel==2 | nivel==3) & ultgrado==3
 replace anoest=4  if (nivel==2 | nivel==3) & ultgrado==4
 replace anoest=5  if (nivel==2 | nivel==3) & ultgrado==5
 replace anoest=6  if (nivel==2 | nivel==3) & ultgrado==6
 replace anoest=7  if ((nivel==3) & ultgrado==7) | ((nivel==5 | nivel==7) & ultgrado==1)
 replace anoest=8  if ((nivel==3) & ultgrado==8) | ((nivel==5 | nivel==7) & ultgrado==2)
 replace anoest=9  if ((nivel==5 | nivel==7) & ultgrado==3) | ((nivel==6 | nivel==8) & ultgrado==1)
 replace anoest=10 if ((nivel==5 | nivel==7) & ultgrado==4) | ((nivel==6 | nivel==8) & ultgrado==2)
 replace anoest=11 if ((nivel==5 | nivel==7) & ultgrado==5) | ((nivel==6 | nivel==8) & ultgrado==3)
 replace anoest=12 if ((nivel==5 | nivel==7) & ultgrado==6) | ((nivel==6 | nivel==8) & ultgrado==4)
 replace anoest=13 if (nivel==8 & ultgrado==5) | ((nivel>=9 & nivel<=14) & ultgrado==1) 
 replace anoest=14 if ((nivel>=9 & nivel<=14) & ultgrado==2)
 replace anoest=15 if ((nivel>=9 & nivel<=14) & ultgrado==3) 
 replace anoest=16 if ((nivel>=10 & nivel<=14) & ultgrado==4)
 replace anoest=17 if ((nivel>=12 & nivel<=14) & ultgrado==5)  | (nivel==15 & ultgrado==5)
 replace anoest=18 if ((nivel>=13 & nivel<=15) & ultgrado==6)
 replace anoest=19 if ((nivel>=13 & nivel<=15) & ultgrado==7)
 replace anoest=20 if nivel==15 & ultgrado==8
 replace anoest=21 if nivel==15 & ultgrado==9

 tab anoest esc,missing /* Esc= Escolaridad */
 tab anoest esc if edad>=15, missing


** Economic Active Population 

* For the population with 15 years or more of age.
* 1. Ocupado	2. Desocupado

 gen     activi=1 if (o1==1 | o2==1) & edad>=15
 replace activi=2 if o3==1           & edad>=15
 replace activi=3 if activ==.        & edad>=15

 tab activi [w=factor]
 tab activi [w=factor] if incl==1 
 
 rename activi peaa

 gen     tasadeso=0 if peaa==1 
 replace tasadeso=1 if peaa==2 
************************
*** MDGs CALCULATION ***
************************

*** GOAL 2. ACHIEVE UNIVERSAL PRIMARY EDUCATION
* ISCED 1

 gen     NERP=0 if (edad>=6 & edad<=11) & (asiste==1 | asiste==2)
 replace NERP=1 if (edad>=6 & edad<=11) & (asiste==1) & (nivel==1 | (nivel==3 & (ultgrado>=1 & ultgrado<=5)))

** Target 3, Additional Indicator: Net Attendance Ratio in Secondary
* ISCED 2 & 3

 gen     NERS=0 if (edad>=12 & edad<=17) & (asiste==1 | asiste==2)
 replace NERS=1 if (edad>=12 & edad<=17) & (asiste==1) & ((nivel==3 & (ultgrado>=6 & ultgrado<=8)) | ((nivel==6 | nivel==8) & (ultgrado>=1 & ultgrado<=3)))

** Upper secondary
* Tasa de Neta de Matrícula en la Enseñanza Media

 gen     NERS2=0 if (edad>=14 & edad<=17) & (asiste==1 | asiste==2)
 replace NERS2=1 if (edad>=14 & edad<=17) & (asiste==1) & ((nivel==3 & ultgrado==8) | ((nivel==6 | nivel==8) & (ultgrado>=1 & ultgrado<=3)))

** Target 3, Indicator: Literacy Rate of 15-24 Years Old
* At least 5 years of formal education

 gen     ALFABET=0 if (edad>=15 & edad<=24) & (anoest>=0 & anoest<99) 
 replace ALFABET=1 if (edad>=15 & edad<=24) & (anoest>=5 & anoest<99)

** Target 3, Indicator: Literacy Rate of 15-24 Years Old
* Knows how to read & write

 gen     ALFABET2=0 if (edad>=15 & edad<=24) & (alfabet==1 | alfabet==2)
 replace ALFABET2=1 if (edad>=15 & edad<=24) & (alfabet==1) 

*** GOAL 3 PROMOTE GENDER EQUALITY AND EMPOWER WOMEN

 gen prim=1 if asiste==1 & (nivel==1 | (nivel==3 & (ultgrado>=1 & ultgrado<=5)))
 gen sec=1 if  asiste==1 & (((nivel==3) & (ultgrado>=6 & ultgrado<=8)) | ((nivel==6 | nivel==8) & (ultgrado>=1 & ultgrado<=3)))
 gen ter=1 if  asiste==1 & ((nivel==13 | nivel==9 | nivel==11) |  ((nivel==6 | nivel==8) & ultgrad>=4))

** Target 4, Indicator: Ratio Girls to boys in primary, secondary and tertiary (%)

** Target 4, Ratio of Girls to Boys in Primary*

 gen RPRIMM=1 if (prim==1) & sexo==2 
 replace RPRIMM=0 if RPRIMM==. 
 gen RPRIMH=1 if (prim==1) & sexo==1 
 replace RPRIMH=0 if RPRIMH==.

 gen RATIOPRIM=0 if     (prim==1) & sexo==2  
 replace RATIOPRIM=1 if (prim==1)  & sexo==1   
	
** Target 4, Ratio of Girls to Boys in Secondary*

 gen RSECM=1 if (sec==1) & sexo==2 
 replace RSECM=0 if RSECM==.
 gen RSECH=1 if (sec==1) & sexo==1 
 replace RSECH=0 if RSECH==.

 gen RATIOSEC=0     if (sec==1) & sexo==2 
 replace RATIOSEC=1 if (sec==1) & sexo==1  
	
** Target 4, Indicator: Ratio of Girls to Boys in Tertiary*

 gen RTERM=1 if (ter==1) & sexo==2 
 replace RTERM=0 if RTERM==.
 gen RTERH=1 if (ter==1) & sexo==1 
 replace RTERH=0 if RTERH==.

 gen RATIOTER=0     if (ter==1) & sexo==2 
 replace RATIOTER=1 if (ter==1) & sexo==1  

** Target 4, Indicator: Ratio of Girls to Boys in Primary, Secondary and Tertiary*

 gen RALLM=1 if (prim==1 | sec==1 | ter==1) & sexo==2 
 replace RALLM=0 if RALLM==.
 gen RALLH=1 if (prim==1 | sec==1 | ter==1) & sexo==1 
 replace RALLH=0 if RALLH==.

 gen RATIOALL=0 if     (prim==1 | sec==1 | ter==1) & sexo==2  
 replace RATIOALL=1 if (prim==1 | sec==1 | ter==1) & sexo==1    

** Target 4, Indicator: Ratio of literate women to men 15-24 year olds*
* Knows how to read & write

 gen MA2=1 if ((alfabet==1) & (edad>=15 & edad<=24) & (sexo==2)) 
 replace MA2=0 if MA2==.
 gen HA2=1 if ((alfabet==1) & (edad>=15 & edad<=24) & (sexo==1)) 
 replace HA2=0 if HA2==.

 gen RATIOLIT2=0     if ((alfabet==1) & (edad>=15 & edad<=24) & (sexo==2)) 
 replace RATIOLIT2=1 if ((alfabet==1) & (edad>=15 & edad<=24) & (sexo==1)) 

** Target 4, Indicator: Ratio of literate women to men 15-24 year olds*
* At least 5 years of formal education

 gen MA=1 if ((anoest>=5 & anoest<99) & (edad>=15 & edad<=24) & (sexo==2)) 
 replace MA=0 if MA==.
 gen HA=1 if ((anoest>=5 & anoest<99) & (edad>=15 & edad<=24) & (sexo==1)) 
 replace HA=0 if HA==.

 gen RATIOLIT=0 if     ((anoest>=5 & anoest<99) & (edad>=15 & edad<=24) & (sexo==2)) 
 replace RATIOLIT=1 if ((anoest>=5 & anoest<99) & (edad>=15 & edad<=24) & (sexo==1)) 

** Target 4, Indicator: Share of women in wage employment in the non-agricultural sector (%)

* Without domestic Service
* INCL==1 ==> Excludes nucleo 0

 gen     WENAS=0 if incl==1 & ((edad>=15 & edad<=64) & ((categ>=3 & categ<=5) | categ==9) & (rama>=2 & rama<=9))
 replace WENAS=1 if incl==1 & ((edad>=15 & edad<=64) & ((categ>=3 & categ<=5) | categ==9) & (rama>=2 & rama<=9) & (sexo==2))

* RURAL AREAS ARE NOT PRESENTED FOR THIS INDICATOR
 
** Target 4, Indicator: Share of women in wage employment in the non-agricultural sector (%)
* With domestic servants
* INCL==1 ==> Excludes nucleo 0

 gen     WENASD=0 if incl==1 & ((edad>=15 & edad<=64) & ((categ>=3 & categ<=7) | categ==9) & (rama>=2 & rama<=9)) 
 replace WENASD=1 if incl==1 & ((edad>=15 & edad<=64) & ((categ>=3 & categ<=7) | categ==9) & (rama>=2 & rama<=9) & (sexo==2))

*** GOAL 7 ENSURE ENVIROMENTAL SUSTAINABILITY

** Access to Electricity ** Additional Indicator

* Gender classification of the population refers to the head of the household.

 gen     ELEC=0 if (v15>=1 & v15<=6) /* Total population excluding missing information */
 replace ELEC=1 if (v15>=1 & v15<=5)

** Target 9, Indicator: Proportion of the population using solidfuels (%)

* NA

** Target 10, Indicator: Proportion of the population with sustainable access to an improved water source (%)

* Gender classification of the population refers to the head of the household.

 gen     WATER=0 if (agua>=1 & agua<=6) /* Total population excluding missing information */
 replace WATER=1 if (agua>=1 & agua<=4) 

** Target 10, Indicator: Proportion of Population with Access to Improved Sanitation, Urban and Rural (%)

* Gender classification of the population refers to the head of the household.

 gen     SANITATION=0 if (servsani>=1 & servsani<=7) /* Total population excluding missing information */
 replace SANITATION=1 if (servsani>=1 & servsani<=2)

** Target 11, Indicator: Proportion of the population with access to secure tenure (%)

* PERSONS PER ROOM

 egen nrocuart_hog1=rsum(v4 v5 v6 v7), missing
 egen nrocuart_hogrest=rsum(v27 v28 v29 v30), missing
 recode nrocuart_hogrest (0=.)

 gen nrocuart=nrocuart_hog1 if v25==1
 replace nrocuart=nrocuart_hogrest if (v25>=2 & v25<=9)

 gen persroom=numper/nrocuart

* Indicator components

* 1. Non secure tenure or type of dwelling.

 gen     secten_1=0 if ((tenencia>=1 & tenencia<=10) & (tipoviv>=1 & tipoviv<=8)) /* Total population excluding missing information */
 replace secten_1=1 if ((tenencia>=7 & tenencia<=10) | (tipoviv>=6 & tipoviv<=8))

* 2. Low quality of the floor or walls materials.

 gen     secten_2=0 if ((pared>=1 & pared<=8) & (piso>=1 & piso<=5)) /* Total population excluding missing information */
 replace secten_2=1 if ((pared==5 | pared==7 | pared==8) | (piso==5)) 

* 3. Crowding (defined as not more than two people sharing the same room)

 gen secten_3=1     if (persroom>2) 

* 4. Lack of basic services

 gen secten_4=1	    if (SANITATION==0 | WATER==0)

* Gender classification of the population refers to the head of the household.

 gen     SECTEN=1 if (secten_1>=0 & secten_1<=1) & (secten_2>=0 & secten_2<=1) /* Total population excluding missing information */
 replace SECTEN=0 if (secten_1==1 | secten_2==1 | secten_3==1 | secten_4==1)

* Dirt floors ** Additional indicator
* 9.a Material predominante en el piso de la vivienda

* Gender classification of the population refers to the head of the household.

 gen     DIRT=0 if (piso>=1 & piso<=5) /* Total population excluding missing information */
 replace DIRT=1 if (piso==5)

** GOAL 8. DEVELOP A GLOBAL PARTNERSHIP FOR DEVELOPMENT

** Target 16, Indicator: Unemployment Rate of 15 year-olds (%)
* INCL==1 ==> Excludes nucleo 0

 gen     UNMPLYMENT15=0 if incl==1 & (edad>=15 & edad<=24) & (tasadeso==0 | tasadeso==1) 
 replace UNMPLYMENT15=1 if incl==1 & (edad>=15 & edad<=24) & (tasadeso==1) 

* Telephone Lines and Cellular Subscribers 

* Fixed Line
* Household head

 gen     tel=1 if p3==1 & pco1==1
 replace tel=0 if tel==. & p3!=9 & pco1==1

 egen telefono=max(tel), by(id_hogar)

* Cellular
* Any household member with cellular service

 gen     cel=1 if (p8==1) 
 replace cel=0 if cel==. & p8!=9 

 egen celular=max(cel), by(id_hogar)
 
* Gender classification of the population refers to the head of the household.

 gen     TELCEL=0 if (telefono>=0 & telefono<=1) & (celular>=0 & celular<=1) /* Total population excluding missing information */
 replace TELCEL=1 if (telefono==1 | celular==1) 


** FIXED LINES

* Gender classification of the population refers to the head of the household.

 gen     TEL=0 if (telefono>=0 & telefono<=1) /* Total population excluding missing information */
 replace TEL=1 if (telefono==1) 

** CEL LINES

* Gender classification of the population refers to the head of the household.

 gen     CEL=0 if (celular>=0 & celular<=1) /* Total population excluding missing information */
 replace CEL=1 if (celular==1)

** Target 18, Indicator: "Personal computers in use per 100 population"

* Computers
* Household head

 gen     comp=1 if p6==1 & pco1==1
 replace comp=0 if comp==. & p6!=9 & pco1==1

 egen computador=max(comp), by(id_hogar)

* Gender classification of the population refers to the head of the household.

 gen     COMPUTER=0 if (computador>=0 & computador<=1) /* Total population excluding missing information */
 replace COMPUTER=1 if (computador==1)

* Target 18, Indicator: "Internet users per 100 population"

** Internet access 
* Household head

* Conexión a internet  

 gen     inte=1 if p7==1 & pco1==1
 replace inte=0 if inte==. & p7!=9 & pco1==1

 egen internet=max(inte), by(id_hogar)

 gen     INTUSERS=0 if (internet>=0 & internet<=1) /* Total population excluding missing information */
 replace INTUSERS=1 if (internet==1)

************************************************************************
**** ADDITIONAL SOCIO - ECONOMIC COMMON COUNTRY ASESSMENT INDICATORS ****
************************************************************************

** CCA 19. Proportion of children under 15 who are working
* INCLUDES POPULATION 12 TO 15 YEARS-OLD
* INCL==1 ==> Excludes nucleo 0

 gen     CHILDREN=0 if incl==1 & (edad>=12 & edad<=14) 
 replace CHILDREN=1 if incl==1 & ((edad>=12 & edad<=14) & (o1==1 | o2==1))

** CCA 41 Number of Persons per Room*

 generate PERSROOM2=persroom if pco1==1


 gen     popinlessthan2=1 if persroom<=2
 replace popinlessthan2=0 if popinlessthan2==.

* Gender classification of the population refers to the head of the household.

 gen     PLT2=0 if persroom<.	/* Total population excluding missing information */
 replace PLT2=1 if (popinlessthan2==1)

gen     DISCONN=0 if (edad>=15 & edad<=24)
replace DISCONN=1 if (edad>=15 & edad<=24) & (o7>=8 & o7<=10)


*** Proportion of population below corresponding grade for age

 gen     rezago=0       if (anoest>=0 & anoest<99)  & edad==6 /* This year of age is not included in the calculations */
	 
 replace rezago=1 	if (anoest>=0 & anoest<1 )  & edad==7
 replace rezago=0 	if (anoest>=1 & anoest<99)  & edad==7
 
 replace rezago=1 	if (anoest>=0 & anoest<2 )  & edad==8
 replace rezago=0	if (anoest>=2 & anoest<99)  & edad==8

 replace rezago=1 	if (anoest>=0 & anoest<3 )  & edad==9
 replace rezago=0	if (anoest>=3 & anoest<99)  & edad==9

 replace rezago=1 	if (anoest>=0 & anoest<4 )  & edad==10
 replace rezago=0	if (anoest>=4 & anoest<99)  & edad==10

 replace rezago=1 	if (anoest>=0 & anoest<5 )  & edad==11
 replace rezago=0	if (anoest>=5 & anoest<99)  & edad==11

 replace rezago=1	if (anoest>=0 & anoest<6)   & edad==12
 replace rezago=0	if (anoest>=6 & anoest<99)  & edad==12

 replace rezago=1 	if (anoest>=0 & anoest<7)   & edad==13
 replace rezago=0	if (anoest>=7 & anoest<99)  & edad==13

 replace rezago=1 	if (anoest>=0 & anoest<8)   & edad==14
 replace rezago=0	if (anoest>=8 & anoest<99)  & edad==14

 replace rezago=1 	if (anoest>=0 & anoest<9 )  & edad==15
 replace rezago=0	if (anoest>=9 & anoest<99)  & edad==15

 replace rezago=1 	if (anoest>=0  & anoest<10) & edad==16
 replace rezago=0	if (anoest>=10 & anoest<99) & edad==16

 replace rezago=1 	if (anoest>=0  & anoest<11) & edad==17
 replace rezago=0	if (anoest>=11 & anoest<99) & edad==17

* Primary and Secondary [ISCED 1, 2 & 3]

 gen     REZ=0 if (edad>=7 & edad<=17) & (rezago==1 | rezago==0)
 replace REZ=1 if (edad>=7 & edad<=17) & (rezago==1)

* Primary completion rate [15 - 24 years of age]

 gen     PRIMCOMP=0 if (edad>=15 & edad<=24) & (anoest>=0  & anoest<99)
 replace PRIMCOMP=1 if (edad>=15 & edad<=24) & (anoest>=6  & anoest<99)

* Average years of education of the population 15+

 gen     AEDUC_15=anoest if ((edad>=15 & edad<.) & (anoest>=0 & anoest<99))


 gen     AEDUC_15_24=anoest if ((edad>=15 & edad<=24) & (anoest>=0 & anoest<99))

 gen     AEDUC_25=anoest if ((edad>=25 & edad<.) & (anoest>=0 & anoest<99))

 gen GFA=(anoest/(edad-6)) if (edad>=7 & edad<=17) & (anoest>=0 & anoest<99)

* Grade for age primary

 gen GFAP=(anoest/(edad-6)) if (edad>=7 & edad<=11) & (anoest>=0 & anoest<99)

* Grade for age Secondary

 gen GFAS=(anoest/(edad-6)) if (edad>=12 & edad<=17) & (anoest>=0 & anoest<99)



/************************************************************************************************************
* 3. Creación de nuevas variables de SS and LMK a incorporar en Armonizadas
************************************************************************************************************/

*********
*lp_ci***
*********

gen lp_ci =.
replace lp_ci= 40562     if zona_c==1  /*urbana*/
replace lp_ci= 27328     if zona_c==0	/*rural*/
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********

gen lpe_ci =.
replace lpe_ci= 20281     if zona_c==1  /*urbana*/
replace lpe_ci= 15616     if zona_c==0	/*rural*/
label var lpe_ci "Linea de indigencia oficial del pais"

****************
*cotizando_ci***
****************
gen cotizando_ci=.
replace cotizando_ci=1 if (o17 >= 1 & o17 <= 5)
recode cotizando_ci .=0 if (condocup_ci==1 | condocup_ci==2)
label var cotizando_ci "Cotizante a la Seguridad Social"

****************
*afiliado_ci****
****************
gen afiliado_ci=.	
replace afiliado_ci=1 if (o17 >= 1 & o17<= 6)
recode afiliado_ci .=0
label var afiliado_ci "Afiliado a la Seguridad Social"


****************
*tipopen_ci*****
****************

gen tipopen_ci=.
* no esta la variable
label define  t 1 "Jubilacion" 2 "Pension invalidez" 3 "Pension viudez" 12 " Jub y inv" 13 "Jub y viud" 23 "Viud e inv"  123 "Todas"
label value tipopen_ci t

label var tipopen_ci "Tipo de pension - variable original de cada pais" 


****************
*instpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 

****************
*instcot_ci*****
****************
gen instcot_ci=.
replace instcot_ci=o17 if o17<=5
label var instcot_ci "Institucion a la que cotiza - variable original de cada pais" 


*****************
*tipocontrato_ci*
*****************
/*
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if o15==1 & categopri_ci==3
replace tipocontrato_ci=2 if o15==2 & categopri_ci==3
replace tipocontrato_ci=3 if o11 ==3 & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
*/	
* Corregido por la variable de firmo o no firmo y no por el tipo de trabajo MGD 06/16/2014	
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if o11==1 & categopri_ci==3
replace tipocontrato_ci=2 if (o11==2 | o11==3) & categopri_ci==3
replace tipocontrato_ci=3 if (o11>=4 | tipocontrato_ci==.) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
	
	
*************
*cesante_ci* 
*************
gen cesante_ci=1 if o5==1
replace cesante_ci=0 if o5==2
label var cesante_ci "Desocupado - definicion oficial del pais"	

**************
***tamemp_ci**
**************

gen tamemp_ci=1 if tamest=="A" | tamest=="B" 
replace tamemp_ci=2 if tamest=="C" | tamest=="D"
replace tamemp_ci=3 if tamest=="E" | tamest=="F"

label var tamemp_ci "# empleados en la empresa segun rangos"
label define tamemp_ci 1 "Pequena" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci

*************
**pension_ci*
*************
*MLO: estas variables vienen en el modulo de ignresos complementario ajustado por CEPAL
egen auxpen=rsum(yjubaj yinvaj ymonaj yvitaj yorfaj yotpaj), missing
gen pension_ci=1 if auxpen>0 & auxpen!=.
recode pension_ci .=0
label var pension_ci "1=Recibe pension contributiva"

*************
**ypen_ci*
*************

gen ypen_ci=auxpen
replace ypen_ci=. if auxpen<0
drop auxpen
label var ypen_ci "Valor de la pension contributiva"

***************
*pensionsub_ci*
***************
*egen auxpens=rsum(ypasaj)
egen auxpens=rsum(ypa1aj ypa2aj ypa3aj), missing
gen pensionsub_ci=1 if auxpens>0 & auxpens!=.
recode pensionsub_ci .=0
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*****************
**ypensub_ci*
*****************
destring auxpens, replace
gen  ypensub_ci=auxpens
replace ypensub_ci=. if auxpens<0
drop auxpens
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"



*************
**salmm_ci***
*************
* CHL 2000
gen salmm_ci= 	100000
label var salmm_ci "Salario minimo legal"

*************
***tecnica_ci**
*************

gen tecnica_ci=.
replace tecnica_ci=1 if nivel==9 | nivel==10
recode tecnica_ci .=0 
label var tecnica_ci "1=formacion terciaria tecnica"


**************
**categoinac_ci*
****************


gen categoinac_ci=1 if o7==5
replace categoinac_ci=2 if o7==4
replace categoinac_ci=3 if o7==1
replace categoinac_ci=4 if o7==2 | o7==3 | o7==6 | o7==7 | o7==8 | o7==9 | o7==10


label var categoinac_ci "Condición de inactividad"
	label define categoinac_ci 1 "jubilado/pensionado" 2 "estudiante" 3 "quehaceres_domesticos" 4 "otros_inactivos" 
	label value categoinac_ci categoinac_ci
	

***************
***formal_ci***
***************

gen byte formal_ci=1 if cotizando_ci==1 & (condocup_ci==1 | condocup_ci==2)
recode formal_ci .=0 if (condocup_ci==1 | condocup_ci==2)
label var formal_ci "1=afiliado o cotizante / PEA"

* variables que faltan crear
gen ylmotros_ci=.
gen tcylmpri_ci =.
gen tcylmpri_ch =.
gen autocons_ci=.
gen region_c=.

*YL -> elimino var comp para que no genere problemas al SOCIOMETERO (esta var no es necesaria)
drop comp

egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)

*******************
*** SALUD  ***
*******************

*******************
*** cobsalud_ci ***
*******************

gen cobsalud_ci=.
replace cobsalud_ci=1 if ((s1>=0 & s1<7) | s1==8) 
replace cobsalud_ci=0 if s1==7

label var cobsalud_ci "Tiene cobertura de salud"
label define cobsalud_ci 0 "No" 1 "Si" 
label value cobsalud_ci cobsalud_ci

************************
*** tipocobsalud_ci  ***
************************

gen tipocobsalud_ci=1 if s1>=0 & s1<=5
replace tipocobsalud_ci=2 if s1==6
replace tipocobsalud_ci=3 if s1==8
replace tipocobsalud_ci=0 if cobsalud==0
replace tipocobsalud_ci=. if s1==9

label var tipocobsalud_ci "Tipo cobertura de salud"
lab def tipocobsalud_ci 0"Sin cobertura" 1"Publico" 2"Privado" 3"otro" 
lab val tipocobsalud_ci tipocobsalud_ci


*********************
*** probsalud_ci  ***
*********************
* Nota: se pregunta si tuvieron problemas de salud en últimos 30 días.
 
gen probsalud_ci=1 if  s15==1 
replace probsalud_ci=0 if s15==2
replace probsalud_ci=. if s15==.

label var probsalud_ci "Tuvo algún problema de salud en los ultimos días"
lab def probsalud_ci 0 "No" 1 "Si"
lab val probsalud_ci probsalud_ci

*********************
*** distancia_ci  ***
*********************
gen distancia_ci=.

label var distancia_ci "Dificultad de acceso a salud por distancia"
lab def distancia_ci 0 "No" 1 "Si"
lab val distancia_ci distancia_ci

*****************
*** costo_ci  ***
*****************
* reporta que no tuvo consulta por costo
gen costo_ci=.
replace costo_ci=0 if s22!=3 
replace costo_ci=1 if s22==3 
replace costo_ci=. if s22==9

label var costo_ci "Dificultad de acceso a salud por costo"
lab def costo_ci 0 "No" 1 "Si"
lab val costo_ci costo_ci

********************
*** atencion_ci  ***
********************
gen atencion_ci=.
replace atencion_ci=0 if s22!=6
replace atencion_ci=1 if s22==6
replace atencion_ci=. if s22==9

label var atencion_ci "Dificultad de acceso a salud por problemas de atencion"
lab def atencion_ci 0 "No" 1 "Si"
lab val atencion_ci atencion_ci


******************************
*** VARIABLES DE MIGRACION ***
******************************

	*******************
	*** migrante_ci ***
	*******************
	
	gen migrante_ci=.
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migantiguo5_ci ***
	**********************
	
	gen migantiguo5_ci=.
	label var migantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** migrantelac_ci ***
	**********************
	
	gen migrantelac_ci=.
	label var migrantelac_ci "=1 si es migrante proveniente de un pais LAC"
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"
		

	**************************
	** REGIONES **************
	************************** 
	
   gen ine01=.   
   replace ine01=1 if  r==1				/*Arica y Parinacota*/
   replace ine01=2 if  r==2				/*Antofagasta*/
   replace ine01=3 if  r==3				/*Atacama*/
   replace ine01=4 if  r==4				/*Coquimbo*/
   replace ine01=5 if  r==5		    	/*Valparaíso*/
   replace ine01=6 if  r==6				/*O'Higgins*/
   replace ine01=7 if  r==7				/*Maule*/
   replace ine01=8 if  r==8				/*Bío Bío*/
   replace ine01=9 if  r==9				/*La Araucanía*/
   replace ine01=10 if r==10			/*Los Lagos*/
   replace ine01=11 if r==11			/*Aysén*/
   replace ine01=12 if r==12			/*Magallanes y Antártica Chilena*/
   replace ine01=13 if r==13			/*Metropolitana Santiago*/

	label define ine01 1"Arica y Parinacota" 2"Antofagasta" 3"Atacama" 4"Coquimbo" 5"Valparaíso" 6"O'Higgins" 7"Maule" 8"Bío Bío" 9"La Araucanía" 10"Los Lagos" 11"Aysén" 12"Magallanes y Antártica Chilena" 13"Metropolitana Santiago"
	label value ine01 ine01
	label var ine01 " Primera division politico-administrativa, Región"
	
	
	**************************
	** PROVINCIAS ************
	**************************
	
   gen ine02=.   
   replace ine02=11 if provi==11			/*Arica*/
   replace ine02=12 if provi==12			/*Parinacota*/
   replace ine02=13 if provi==13			/*Iquique*/
   replace ine02=21 if provi==21			/*Tocopilla*/
   replace ine02=22 if provi==22		    /*El Loa*/
   replace ine02=23 if provi==23			/*Antofagasta*/
   replace ine02=31 if provi==31			/*Chañaral*/
   replace ine02=32 if provi==32			/*Copiapó*/
   replace ine02=33 if provi==33			/*Huasco*/
   replace ine02=41 if provi==41			/*Elqui*/
   replace ine02=42 if provi==42			/*Limarí*/
   replace ine02=43 if provi==43			/*Choapa*/
   replace ine02=51 if provi==51			/*Petorca*/
   replace ine02=52 if provi==52			/*Los Andes*/
   replace ine02=53 if provi==53	    	/*San Felipe de Aconcagua*/
   replace ine02=54 if provi==54			/*Quillota*/
   replace ine02=55 if provi==55			/*Valparaíso*/
   replace ine02=56 if provi==56			/*San Antonio*/
   replace ine02=61 if provi==61			/*Cachapoal*/
   replace ine02=62 if provi==62			/*Colchagua*/
   replace ine02=63 if provi==63			/*Cardenal Caro*/
   replace ine02=71 if provi==71			/*Curico*/
   replace ine02=72 if provi==72			/*Talca*/
   replace ine02=73 if provi==73			/*Linares*/
   replace ine02=74 if provi==74	    	/*Cauquenes*/
   replace ine02=81 if provi==81			/*Ñuble*/
   replace ine02=82 if provi==82			/*Bio Bío*/
   replace ine02=83 if provi==83			/*Concepción*/
   replace ine02=84 if provi==84			/*Arauco*/
   replace ine02=91 if provi==91			/*Malleco*/
   replace ine02=92 if provi==92			/*Cautín*/
   replace ine02=101 if provi==101			/*Valdivia*/
   replace ine02=102 if provi==102			/*Osorno*/
   replace ine02=103 if provi==103			/*Llanquihue*/
   replace ine02=104 if provi==104			/*Chiloé*/
   replace ine02=105 if provi==105			/*Palena*/
   replace ine02=111 if provi==111			/*Cohaique*/
   replace ine02=112 if provi==112	    	/*Aisén*/
   replace ine02=113 if provi==113			/*General Carrera*/
   replace ine02=114 if provi==114			/*Capitán Prat*/
   replace ine02=121 if provi==121			/*Última Esperanza*/
   replace ine02=122 if provi==122			/*Magallanes*/
   replace ine02=123 if provi==123			/*Tierra del Fuego*/
   replace ine02=131 if provi==131			/*Santiago*/
   replace ine02=132 if provi==132			/*Chacabuco*/
   replace ine02=133 if provi==133			/*Cordillera*/
   replace ine02=134 if provi==134			/*Maipo*/
   replace ine02=135 if provi==135			/*Melipilla*/
   replace ine02=136 if provi==136			/*Talagante*/

	label define ine02 11"Arica" 12"Parinacota" 13"Iquique" 21"Tocopilla" 22"El Loa" 23"Antofagasta" 31"Chañaral" 32"Copiapó" 33"Huasco" 41"Elqui" 42"Limarí" 43"Choapa" 51"Petorca" 52"Los Andes" 53"San Felipe de Aconcagua" 54"Quillota" 55"Valparaíso" 56"San Antonio" 61"Cachapoal" 62"Colchagua" 63"Cardenal Caro" 71"Curico" 72"Talca" 73"Linares" 74"Cauquenes" 81"Ñuble" 82"Bio Bío" 83"Concepción" 84"Arauco" 91"Malleco" 92"Cautín" 101"Valdivia" 102"Osorno" 103"Llanquihue" 104"Chiloé" 105"Palena" 111"Cohaique" 112"Aisén" 113"General Carrera" 114"Capitán Prat" 121"Última Esperanza" 122"Magallanes" 123"Tierra del Fuego" 131"Santiago" 132"Chacabuco" 133"Cordillera" 134"Maipo" 135"Melipilla" 136"Talagante"
	label value ine02 ine02
	label var ine02 " Segunda division politico-administrativa, Provincia"
	
		
/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci pqnoasis1_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded
 /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

rename o9 codindustria
rename o8 codocupa

compress

saveold "`base_out'", replace


log close




