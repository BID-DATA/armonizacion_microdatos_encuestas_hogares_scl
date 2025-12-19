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
cd $ruta

local PAIS BRB
local ENCUESTA BSLC
local ANO "2024"
local ronda a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Barbados
Encuesta: CALC 2024
Round: 
Autores: Ricardo Sierra  ricardo.sierra@gmail.com
Modificación 2025:
Última modificación:

****************************************************************************/
***************************************************************************
****************************************************************************/



use "`base_in'/BSLC 2024-25_01_Households_Public_Weighted.dta"

*use `base_in', clear
gen hhid=hh_id
duplicates report hhid 
sort hhid 

saveold "`base_in'/2024 RT001_Housing_plus.dta", replace


* Merge de base de hogar con base individual

use "`base_in'/BSLC 2024-25_02_Individuals_Public_Weighted.dta"
gen hhid=hh_id
gen memberid=id_member

duplicates report hhid memberid
sort hhid memberid

merge m:1 hhid using "`base_in'/2024 RT001_Housing_plus.dta"
drop _merge

*saveold "`base_in'/2024 RT001_Housing_plus.dta", replace


**********************
* AÑO DE LA ENCUESTA *
**********************
gen anio_c=2024
label variable anio_c "Año de la Encuesta"

**********************
* MES DE LA ENCUESTA *
**********************
gen mes_c=.
replace mes_c=9 	if fn_sample==1 | fn_sample==2 
replace mes_c=10 	if fn_sample==3 | fn_sample==4 
replace mes_c=11 	if fn_sample==5 | fn_sample==6
replace mes_c=12 	if fn_sample==7 
replace mes_c=13 	if fn_sample==8 | fn_sample==9 
replace mes_c=14 	if fn_sample==10 | fn_sample==11 
replace mes_c=15 	if fn_sample==12 | fn_sample==13 
replace mes_c=16 	if fn_sample==14 | fn_sample==15 
replace mes_c=17 	if fn_sample==6 

label variable mes_c "Mes de la Encuesta"

* NOTA RS: Abarca meses de 2 años (9-2024 a 5-2025)
* mes_c==13 equivale a enero 2025 y asi sucesivamente....

**********************
******** UPM  ********
**********************
gen upm=psu
label variable upm "Unidad primaria de muestreo"

*************************
* FACTORES DE EXPANSION *
*************************
gen wtfactor=weight
sum wtfactor
scalar pob=r(sum)
gen pop=wtfactor*(282336/pob) 
sum pop
ret list
gen factor_ch=pop 
drop pop
label var factor_ch "Factor de Expansion del Hogar"

gen factor_ci=factor_ch
label var factor_ci "Factor de Expansion del Individuo"

**************
* REGION BID *
**************
gen region_BID_c=2
label var region_BID_c "Region BID"
label define region_BID 1"Centroamérica" 2"Caribe" 3"Andinos" 4"Cono Sur"
label values region_BID_c region_BID

***************
* REGION PAIS *
***************
g region_ci=.


***************
* ine01 *
***************
gen ine01=cod_parish
label define ine01 24201 "st michael" 24202 "christ church" 24203 "st george" 24204 "st philip" 24205 "st john" 24206 "st james" 24207 "st thomas" 24208 "st joseph" 24209 "st andrew" 24210 "st peter" 24211 "st lucy"
label values ine01 ine01

***************
*    ZONA     *
***************
gen byte zona_c=.
*replace zona_c=1 if area==1 /* Urbana */
*replace zona_c=0 if area==2 /* Rural */
label variable zona_c "Zona geográfica"
label define zona_c 0"Rural" 1"Urbana"
label value zona_c zona_c

***********
*  PAIS   *
***********
gen pais_c="BRB"
label var pais_c "Acrónimo del país"

******************************
*  IDENTIFICADOR DEL HOGAR   *
******************************

*tostring hhno, replace
*gen hh_id = string(real(hhno),"%03.0f")
*egen idh_ch= concat(edno hh_id rndno)
gen idh_ch=hh_id
drop if idh_ch=="..."
destring idh_ch, replace
sort idh

label var idh_ch "Identificador Unico del Hogar"
tostring idh_ch, replace


*******************************
* IDENTIFICADOR DEL INDIVIDUO *
*******************************
tostring memberid, gen(indivno)
egen idp_ci= concat(idh indivno)
destring idp_ci, replace
sort idp_ci

label var idp_ci "Identificador Individual dentro del Hogar"
tostring idp_ci, replace
isid idp_ci



*******************************
*******************************
*******************************
*   VARIABLES DEMOGRÁFICAS    *
*******************************
*******************************
*******************************

***********
*  SEXO   *
***********
gen sexo_ci=sex
label var sexo_ci "Sexo del individuo"
label define sexo 1"Masculino" 2"Femenino" 
label values sexo_ci sexo

***********
*  EDAD   *
***********
*1896 valores perdidos.
gen edad_ci=age
label var edad_ci "Edad del individuo"

************************************
*  RELACION CON EL JEFE DE HOGAR   *
************************************
gen relacion_ci=1 if q01_03==1
replace relacion_ci=2 if q01_03==2
replace relacion_ci=3 if q01_03==3 
replace relacion_ci=4 if q01_03>=4 & q01_03<=12
replace relacion_ci=5 if q01_03==14  | q01_03==15
replace relacion_ci=6 if q01_03==13
label var relacion_ci "relación con el jefe de hogar"
label define relacion 1"Jefe" 2"Cónguye, Esposo/a, Compañero/a" 3"Hijo/a" 4"Otros parientes" 5"Otros no parientes" 6"Servicio doméstico" 
label values relacion_ci relacion


*******************
*  ESTADO CIVIL   *
*******************
gen civil_ci=.
replace civil_ci=1 if q01_06==6
replace civil_ci=2 if q01_06==1 | q01_06==2
replace civil_ci=3 if q01_06==3 | q01_06==4
replace civil_ci=4 if q01_06==5
label var civil_ci "Estado civil del individuo"
label define civil 1"Soltero" 2"Unión formal o informal" 3"Divorciado o separado" 4"Viudo" 
label values civil_ci civil

*******************
*  JEFE DE HOGAR  *
*******************
gen jefe_ci=0
replace jefe_ci=1 if relacion_ci==1
label var jefe_ci "Jefe de hogar"
label define jefe 1"Jefe de Hogar" 0"Otro" 
label values jefe_ci jefe

************************************
*  NUMERO DE CONYUGES EN EL HOGAR  *
************************************
egen nconyuges_ch=sum(relacion_ci==2), by (idh_ch)
replace nconyuges_ch =. if relacion_ci==.
label var nconyuges_ch "Número de Conyuges en el hogar"


************************************
*  NUMERO DE HIJOS EN EL HOGAR  *
************************************
egen nhijos_ch=sum(relacion_ci==3), by (idh_ch)
replace nhijos_ch =. if relacion_ci==.
label var nhijos_ch "Número de hijos en el hogar"


*******************************************
*  NUMERO DE OTROS PARIENTES EN EL HOGAR  *
*******************************************
egen notropari_ch=sum(relacion_ci==4), by (idh_ch)
label var notropari_ch "Número de otros parientes en el hogar"

*******************************************
*  NUMERO DE OTROS NO PARIENTES EN EL HOGAR  *
*******************************************
egen notronopari_ch=sum(relacion_ci==5), by (idh_ch)
label var notronopari_ch "Número de otros parientes en el hogar"


*************************************
*  NUMERO DE EMPLEADOS EN EL HOGAR  *
*************************************
egen nempdom_ch=sum(relacion_ci==6), by (idh_ch)
label var nempdom_ch "Número de empleados en el hogar"

*********************
*  CLASE DE HOGAR   *
*********************
gen clasehog_ch=.
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0 /* unipersonal*/
replace clasehog_ch=2 if nhijos_ch>0 & nhijos_ch!=. & notropari_ch==0 & notronopari_ch==0 /* nuclear (child with or without spouse but without other relatives)*/
replace clasehog_ch=2 if nconyuges_ch>0 & nconyuges_ch!=. & notropari_ch==0 & notronopari_ch==0 /* nuclear (spouse with or without children but without other relatives)*/
replace clasehog_ch=3 if notropari_ch>0 & notropari_ch!=. & notronopari_ch==0 /* ampliado*/
replace clasehog_ch=4 if nhijos_ch>0 & nhijos_ch!=. & notropari_ch==0 & notronopari_ch>0 & notronopari_ch!=. /* compuesto */
replace clasehog_ch=4 if nconyuges_ch>0 & nconyuges_ch!=. & notropari_ch==0 & notronopari_ch>0 & notronopari_ch!=. 
replace clasehog_ch=4 if notropari_ch>0 & notropari_ch!=. & notronopari_ch>0 & notronopari_ch!=. 
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0 & notronopari_ch!=./** corresidente*/
label var clasehog_ch "Clase de hogar"
label define clasehog 1"Unipersonal" 2"Nuclear" 3"Ampliado" 4"Compuesto" 5"Corresidente" 
label values clasehog_ch clasehog


*************************************
*  NUMERO DE MIEMBROS EN EL HOGAR  *
*************************************
egen nmiembros_ch=sum(relacion_ci>0 & relacion_ci<5), by (idh_ch)
replace nmiembros_ch=. if relacion_ci ==.
label variable nmiembros_ch "Numero de miembros en el Hogar"


************************************
*   DUMMY PARA MIEMBROS DEL HOGAR  *
************************************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
replace miembros_ci=1 if (relacion_ci>=1 & relacion_ci<=4)
label variable miembros_ci "Variable dummy que indica las personas que son miembros del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 15 AÑOS *
********************************************

by idh_ch, sort: egen nmenor15_ch=sum(relacion_ci==3 & age<=15)
label var nmenor15_ch "Numero de hijos menores a 15 años"


********************************************
*  MIEMBROS EN EL HOGAR MAYORES DE 21 AÑOS *
********************************************
egen nmayor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (age>=21)), by (idh_ch)
label variable nmayor21_ch "Numero de personas de 21 años o mas dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 21 AÑOS *
********************************************
egen nmenor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (age<21)), by (idh_ch)
label variable nmenor21_ch "Numero de personas menores a 21 años dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MAYORES DE 65 AÑOS *
********************************************
egen nmayor65_ch=sum((relacion_ci>0 & relacion_ci<5) & (age>=65)), by (idh_ch)
label variable nmayor65_ch "Numero de personas de 65 años o mas dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 6 AÑOS *
********************************************
* No hay menores de 7 años en la encuesta
egen nmenor6_ch=sum((relacion_ci>0 & relacion_ci<5) & (age<6)), by (idh_ch)
label variable nmenor6_ch "Miembros menores a 6 años dentro del Hogar"


******************************************
*  MIEMBROS EN EL HOGAR MENORES DE 1 AÑO *
******************************************
* No hay menores de 7 años en la encuesta
egen nmenor1_ch=sum((relacion_ci>0 & relacion_ci<5) & (age<1)),  by (idh_ch)
label variable nmenor1_ch "Miembros menores a 1 año dentro del Hogar"


			
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

/* q01_13: Does [NAME] consider himself / herself…
1	Black?
2	Mixed?
3	White?
4	Oriental?
5	East Indian?
6	Middle Eastern?
97	OTHER (SPECIFY)
*/



*********
*afro_ci*
*********
gen byte afro_ci = (q01_13==1 | q01_13==2) 	  

* Incluye black y mixed

*********
*ind_ci*
*********	
gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

**************
*noafroind_ci*
**************
gen byte noafroind_ci = (q01_13!=1 & q01_13!=2) 


************
*afroind_ci*
************
gen byte afroind_ci=. 
replace afroind_ci=2 if q01_13==1 | q01_13==2
replace afroind_ci=3 if q01_13>=3 & q01_13<=97
label define afroind_ci 1 "Indigenous" 2"African Descendant" 3"Other" 
label values afroind_ci afroind_ci



*********
*afro_ch*
*********
gen byte afro_jefe = afro_ci if relacion_ci==1
egen afro_ch  = max(afro_jefe), by(idh_ch) 
drop afro_jefe

********
*ind_ch*
********	
gen byte ind_jefe = ind_ci if relacion_ci==1
egen ind_ch = max(ind_jefe), by(idh_ch) 
drop ind_jefe

**************
*noafroind_ch*
**************
gen byte noafroind_jefe = noafroind_ci if relacion_ci==1
egen noafroind_ch = max(noafroind_jefe), by(idh_ch) 
drop noafroind_jefe

************
*afroind_ch*
************
gen byte afroind_jefe = afroind_ci if jefe_ci==1
egen afroind_ch = min(afroind_jefe), by(idh_ch) 
drop afroind_jefe 



/************************
***** DISCAPACIDAD *****
************************
 
q03_22: Does [NAME] have difficulty seeing, even if he / she is using glasses?
q03_23: Does [NAME] have difficulty hearing, even if he / she is using a hearing aid?
q03_24: Does [NAME] have difficulty walking or climbing steps?
q03_25: Does [NAME] have difficulty remembering or concentrating?
q03_26: Does [NAME] have difficulty with self care such as washing all over or dressing?			
			
1	No, no difficulty
2	Yes, some difficulty
3	Yes, a lot
4	Cannot see/hear/walk climb/remember
			
*/	
	
********
*dis_ci*
********
egen disab=rsum(q03_22 q03_23 q03_24 q03_25 q03_26)
gen byte dis_ci=(disab>=6)
replace dis_ci=. if q03_22==. & q03_23==. & q03_24==. & q03_25==. & q03_26==. 
drop disab
**********
*disWG_ci*
**********

foreach var in q03_22 q03_23 q03_24 q03_25 q03_26{
	gen `var'_WG=(`var'==3 | `var'==4)
}
egen dis_WG=rsum(q03_22_WG q03_23_WG q03_24_WG q03_25_WG q03_26_WG)


gen byte disWG_ci=(dis_WG>=1)
replace disWG_ci=. if q03_22==. & q03_23==. & q03_24==. & q03_25==. & q03_26==. 
drop q03_22_WG q03_23_WG q03_24_WG q03_25_WG q03_26_WG dis_WG

********
*dis_ch*
********
egen byte dis_ch = max(dis_ci), by(idh_ch) 

******************
*ISOalpha3_dis_ci*
******************
gen byte BRB_dis_ci = dis_ci



*******************************
*******************************
*******************************
*     VARIABLES LABORALES     *
*******************************
*******************************
*******************************

**************************
* CONDICION DE OCUPACION *
**************************

gen condocup_ci = .
replace condocup_ci = 1 if q04_03==1 | q04_05==1 | q04_07==1 |  q04_10==1 | q04_22==1 /* Farm andTemporary absence included*/
replace condocup_ci = 2 if (q04_03==2 | q04_05==2 | q04_07==2|  q04_10==2) & q04_33==1  /* Willing */
replace condocup_ci = 3 if missing(condocup_ci) & edad_ci >= 15
replace condocup_ci = 4 if edad_ci < 15
label define condocup 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menores de 15 años"
label values condocup_ci condocup

label variable condocup_ci "Condición de ocupación"
*Note farm included in ocupados

**************************
* CATEGORIA DE INACTIVIDAD  *
**************************
*Jubilados, pensionados
gen categoinac_ci =1 if (q04_37a==3 & condocup_ci==3)
label var  categoinac_ci "Condición de Inactividad" 

*Estudiantes
replace categoinac_ci=2 if (q04_37a==1 & condocup_ci==3)

*Quehaceres del Hogar
replace categoinac_ci=3 if (q04_37a==2 & condocup_ci==3)

*Otra razon
replace categoinac_ci=4  if  ((categoinac_ci !=1 & categoinac_ci !=2 & categoinac_ci !=3) & condocup_ci==3) 
label define inactivo 1"Jubilados o Pensionado" 2"Estudiante" 3"Hogar" 4"Otros inactivos"
label values categoinac_ci inactivo


************
* OCUPADO  *
************
gen emp_ci = (condocup_ci == 1)

label variable emp_ci "Ocupado"
label define ocupado 1 "Ocupado" 0 "No ocupado"
label values emp_ci ocupado


***********
* CESANTE *
***********
* NO INFO ON PREVIOUS WORK
gen cesante_ci=.
label var cesante_ci "Cesante"


***************
* DESOCUPADO  *
***************
gen desemp_ci=0 
replace desemp_ci=1 if condocup_ci==2
label var desemp_ci "Desocupado"
label define desocupado 1"Desocupado" 0"No desocupado"  
label values desemp_ci desocupado


***********************************
* DURACION DEL DESEMPLEO EN MESES *
***********************************
* q04_32: "For how long has [NAME] been without work and trying to find a job or start a business?
/* SOLO APLICA PARA LOS INACTIVOS	

LESS THAN 1 MONTH	
1 MONTH TO  3 MONTHS
3 MONTHS TO  6 MONTHS
6 MONTHS TO 12 MONTHS
1 YEAR TO 2 YEARS	
2 YEARS OR MORE
*/			
			
		
gen durades_ci=. if q04_32==.
replace durades_ci= 0.5 if q04_32==1
replace durades_ci=(1+3)/2 if q04_32==2
replace durades_ci=(3+6)/2 if q04_32==3
replace durades_ci=(6+12)/2 if q04_32==4
replace durades_ci=(12+24)/2 if q04_32==5
replace durades_ci=(24)/2 if q04_32==6	
label var durades_ci "Duración búsqueda de empleo"


***********************************
* POBLACION ECONOMICAMENTE ACTIVA *
***********************************
gen pea_ci=0
replace pea_ci=1 if condocup_ci==1 | condocup_ci==2
label var pea_ci "Población económicamente activa"


**********************
*  NÚMERO DE EMPLEOS *
**********************
gen nempleos_ci=.
replace nempleos_ci=1 if condocup==1 & q04_38==2
replace nempleos_ci=2 if condocup==1 & q04_38==1
label var nempleos_ci "Numero de empleos"
label define nempleos_ci 1 "un trabajo" 2 "dos o mas trabajos"
label values nempleos_ci nempleos_ci


*****************************************
* ANTIGUEDAD EN LA ACTIVIDAD PRINCIPAL  *
*****************************************
* NO EXISTE LA PREGUNTA
gen antiguedad_ci=.
label var antiguedad_ci "Años de trabajo en la actividad principal"



****************
* DESALENTADOS *
****************
* OJO: Solo aplica para desocupados

gen desalent_ci=0 if condocup_ci==2
replace desalent_ci=1 if (q04_34==6 | q04_34==6 | q04_34==7) & condocup_ci==2
label var desalent_ci "Trabajadores desalentados, personas que creen que por alguna razon no conseguiran trabajo" 



**********************************************
* HORAS TRABAJADAS EN LA ACTIVIDAD PRINCIPAL *
**********************************************
* q04_44: How many days per week does [NAME] usually work in this main job?						
* q04_45: How many hours per day does [NAME] usually work in this main job?			
					
gen	horaspri_ci = q04_45*q04_44
label var horaspri_ci "Horas trabajadas semanalmente en la actividad principal"


**********************************************
* HORAS TRABAJADAS EN LA ACTIVIDAD SECUNDARIA *
**********************************************
* q04_62: How many days per week does [NAME] usually work in this job?			
* q04_63: How many hours per day does [NAME] usually work in this job?			

gen horassec_ci=q04_63*q04_62
label var horassec_ci "Horas trabajadas en la actividad secundaria"

*NOTA: SOBRE-ESTIMACION DE HORAS SEMANALES CON ESTAS PREGUNTAS

**************************
* TOTAL HORAS TRABAJADAS *
**************************
gen horastot_ci=horaspri_ci+horassec_ci


*****************************
* TRABAJA MENOS DE 30 HORAS *
*****************************
* q04_66: During the past 4 weeks, did [NAME] look for additional or other paid work?			
* q04_67: Would [NAME] want to work more hours per week than usually worked, provided the extra hours are paid?			


gen subemp_ci=0
replace subemp_ci=1 if q04_66==1 & q04_67==1 & horastot_ci<=30 & emp_ci==1
label var subemp_ci "Personas en subempleo por horas"

****************************************************
* TRABAJA MENOS DE 30 HORAS Y NO DESEA TRABAJAR MAS*
****************************************************

gen tiempoparc_ci=((horaspri_ci>=1 & horaspri_ci<30) & q04_67==2 & emp_ci==1)
replace tiempoparc_ci=. if emp_ci==0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

* NOTA. SE CALCULA SOLO PARA LA ACTIVIDAD PRINCIPAL

*********************************
* CATEGORIA OCUPACION PRINCIPAL *
*********************************
/*q04_41: 'In [NAME]'s main job, does [NAME] work ...

1	in own business or farming activity?					SELF EMPLOYED
2	in a business or farm operated by a household member?	SELF EMPLOYED		
3	as an employee for someone else?						EMPLOYEE
4	as an apprentice, trainee, intern?						EMPLOYEE
5	helping a household member who works for someone else?	NO REMUNERATION	

NOTA: NO HAY FORMA DE IDENTIFICADOR A PATRONES/EMPLEADORES 

*/

gen categopri_ci=.
*replace categopri_ci = 1	if & emp_ci==1
replace categopri_ci = 2	if  (q04_41==1 | q04_41==2)& emp_ci==1
replace categopri_ci = 3 	if  (q04_41==3 | q04_41==4) & emp_ci==1
replace categopri_ci = 4	if  q04_41==5 & emp_ci==1


label var categopri_ci "Categoría ocupación principal"
label define categopri 1"Patrón o empleador" 2"Cuenta propia o independiente" 3"Empleado o asalariado" 4"Trabajador no remunerado"  
label values categopri_ci categopri
*NOTA: 5 missing que son Temporary Absence

*********************************
* CATEGORIA OCUPACION SECUNDARIA*
*********************************

gen categosec_ci=.
*replace categosec_ci = 1	if & emp_ci==1
replace categosec_ci = 2	if  (q04_59==1 | q04_59==2) & emp_ci==1
replace categosec_ci = 3 	if  (q04_59==3 | q04_59==4) & emp_ci==1
replace categosec_ci = 4	if  q04_59==5 & emp_ci==1

label var categosec_ci "Categoría ocupación secundaria"
label define categosec 1"Patrón o empleador" 2"Cuenta propia o independiente" 3"Empleado o asalariado" 4"Trabajador no remunerado"  
label values categosec_ci categosec

*********************************
*  RAMA DE ACTIVIDAD PRINCIPAL  *
*********************************	

gen s=substr(q04_40_cod_isic,1,2)
destring s, gen(division)

gen rama_ci=.
replace rama_ci=1 if (division>=1 & division<=3) & condocup_ci==1
replace rama_ci=2 if ((division>=5 & division<=9)) & condocup_ci==1
replace rama_ci=3 if (division>=10 & division<=33)  & condocup_ci==1
replace rama_ci=4 if (division>=35 & division<=39)   & condocup_ci==1
replace rama_ci=5 if (division>=41 & division<=43)  & condocup_ci==1
replace rama_ci=6 if ((division>=45 & division<=47)  | (division>=55 & division<=56))  & condocup_ci==1
replace rama_ci=7 if ((division>=49 & division<=53) | (division>=58 & division<=63)) & condocup_ci==1
replace rama_ci=8 if (division>=64 & division<=68)  & condocup_ci==1
replace rama_ci=9 if (division>=69 & division<99) & condocup_ci==1
label define rama_ci 1"Agricultura" 2"Explotación de minas y canteras" 3"Industrias manufactureras" 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, rest. y hoteles" 7"Transporte y comunicaciones" 8"Establecimientos financieros" 9 "Servicios sociales, comunales y personales"
label values rama_ci rama_ci
drop s division

/*
1	Agricultura, caza, silvicultura y pesca. (indus>=1 & indus<=3)
2	Explotación de minas y canteras. (indus>=6 & indus<=9)
3	Industrias manufactureras. (indus>=10 & indus<=32)
4	Electricidad, gas y agua. (indus>=35 & indus<=39)
5	Construcción. (indus>=41 & indus<=43)
6	Comercio al por mayor y menor, restaurantes, hoteles. (indus>=45 & indus<=47) (indus>=55 & indus<=56)
7	Transporte y comunicaciones. (indus>=49 & indus<=53) (indus>=58 & indus<=63)
8	Establecimientos financieros, seguros, bienes inmuebles. (indus>=64 & indus<=68)
9	Servicios sociales, comunales y personales. (indus>=69 & indus<=98)
*/

* rama secundaria

gen s=substr(q04_58_cod_isic,1,2)
destring s, gen(division_sec)


gen ramasec_ci=.
replace ramasec_ci=1 if (division>=1 & division<=3) & condocup_ci==1
replace ramasec_ci=2 if ((division>=5 & division<=9)) & condocup_ci==1
replace ramasec_ci=3 if (division>=10 & division<=33)  & condocup_ci==1
replace ramasec_ci=4 if (division>=35 & division<=39)   & condocup_ci==1
replace ramasec_ci=5 if (division>=41 & division<=43)  & condocup_ci==1
replace ramasec_ci=6 if ((division>=45 & division<=47)  | (division>=55 & division<=56))  & condocup_ci==1
replace ramasec_ci=7 if ((division>=49 & division<=53) | (division>=58 & division<=63)) & condocup_ci==1
replace ramasec_ci=8 if (division>=64 & division<=68)  & condocup_ci==1
replace ramasec_ci=9 if (division>=69 & division<99) & condocup_ci==1
label define ramasec_ci 1"Agricultura" 2"Explotación de minas y canteras" 3"Industrias manufactureras" 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, rest. y hoteles" 7"Transporte y comunicaciones" 8"Establecimientos financieros" 9 "Servicios sociales, comunales y personales"
label values ramasec_ci ramasec_ci
drop s division


*********************************
*  TRABAJA EN EL SECTOR PUBLICO *
*********************************
/* q04_49: What kind of enterprise / establishment does [NAME] work for in his or her main job?
1	Government or state-owned enterprise	
2	Private agricultural entity (local or foreign)		
3	Private non-agricultural entity (local or foreign)		
4	Other household(s) / individual: (ex: domestic worker)	
5	NGO, non-profit institution, or church		
6	International Org. or a foreign embassy	
*/

gen spublico_ci=0 
replace spublico_ci=1 if q04_49==1 & condocup_ci==1
label var spublico_ci "Personas que trabajan en el sector publico"
 
 
********************
* TAMAÑO DE EMPRESA*
********************
/*
q04_52: Including [NAME], how many people work at his or her place of work?
1	1
2	2 - 4
3	5 - 9
4	10 - 19
5	20 - 49
6	50+
*/

gen tamemp_ci=.
replace tamemp_ci=1 if q04_52==1 | q04_52==2
replace tamemp_ci=2 if q04_52==3 | q04_52==4 | q04_52==5
replace tamemp_ci=3 if q04_52>=6 & q04_52!=.
label var tamemp_ci "# empleados en la empresa segun rangos"
label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci


*********************************
*  COTIZA A LA SEGURIDAD SOCIAL *
*********************************
/*
q04_48: Are [NAME]'s earnings in this main job subject to NIS deductions? 
Or Does [NAME] regurlarly contribute to the NIS? 			
1	NIS DEDUCTIONS
2	CONTRIBUTE TO THE NIS
3	NONE
*/			
				

gen cotizando_ci=.
replace cotizando_ci=1 if q04_48==1 | q04_48==2
replace cotizando_ci=0 if q04_48==3
label var cotizando_ci "Cotizando a la seguridad social"
* NOTA: Se toman en cuenta contribuciones/deducciones al National Insurance Scheme

****************************************************
*  INSTITUCION DE SEGURIDAD SOCIAL A LA QUE COTIZA *
****************************************************
gen inscot_ci=.
label var inscot_ci "Institución de seguridad social a la que cotiza"

**********************************
* AFILIADO A LA SEGURIDAD SOCIAL *
**********************************

gen afiliado_ci=(q04_55e==1) 	
replace afiliado_ci=. if q04_55e==. 
label var afiliado_ci "Afiliado a la Seguridad Social"

* NOTA: Se toman en cuenta las personas que tienen el beneficio de pension/retirement 

*********************
* TRABAJADOR FORMAL *
*********************

gen byte formal_ci=.
replace formal_ci = 1 if (cotizando_ci==1|afiliado_ci==1) & condocup_ci==1
replace formal_ci =0 if cotizando_ci==0 & (condocup_ci==1 | condocup_ci==2)


******************************AQUI
********************
* TIPO DE CONTRATO *
********************

/*
q04_53: 'What is the status of your contract/agreement in your main job? 
1	Permanent / pensionable 		
2	Contract, less than 1 year		
3	Contract,1-5 years		
4	Contract, more than 5 years		
5	Without any contract 		
97	OTHER (SPECIFY)		
99	DON'T KNOW 		
*/		

gen tipocontrato_ci=. 
replace tipocontrato_ci=1 if q04_53==1
replace tipocontrato_ci=2 if q04_53>=2 & q04_53<=4
replace tipocontrato_ci=3 if q04_53==5 

label var tipocontrato_ci "Tipo de contrato"
label define tipocontrato 1"Permanente / Indefinido" 2"Temporal / Tiempo definido" 3"Sin contrato / Verbal"  
label values tipocontrato_ci tipocontrato

*****************************
* TIPO DE OCUPACION LABORAL *
*****************************
* ISCO 
destring q04_39_cod_isco, gen(occup)

gen ocupa_ci=.
replace ocupa_ci=1 if (occup>=2000 & occup<=3999) & emp_ci==1
replace ocupa_ci=2 if (occup>=1000 & occup<=1999) & emp_ci==1
replace ocupa_ci=3 if ((occup>=4000 & occup<=4999) | (occup>=9611 & occup<=9629)) & emp_ci==1
replace ocupa_ci=4 if ((occup>=5200 & occup<=5999) | (occup>=9110 & occup<=9113) | (occup>=9411 & occup<=9520)) & emp_ci==1
replace ocupa_ci=5 if ((occup>=5000 & occup<=5199) | (occup>=9120 & occup<=9162)) & emp_ci==1
replace ocupa_ci=6 if ((occup>=6000 & occup<=6999) | (occup>=9200 & occup<=9214)) & emp_ci==1
replace ocupa_ci=7 if ((occup>=7000 & occup<=8999) | (occup>=9300 & occup<=9334))& emp_ci==1
replace ocupa_ci=9 if (occup==9999) & emp_ci==1
label var ocupa_ci "Tipo de ocupacion laboral"
label define ocupa 1"Profesional o técnico" 2"Director o funcionario superior" 3"Personal administrativo o nivel intermedio" 4"Comerciante o vendedor" 5"Trabajador en servicios" 6"Trabajador agrícola o afines" 7"Obrero no agrícola, conductores de máquinas y vehículos de transporte y similares" 8"Fuerzas armadas" 9"Otras ocupaciones no clasificadas"
label values ocupa_ci ocupa



***********************************************
* RECIBE PENSION O JUBILACION NO CONTRIBUTIVA *
***********************************************
gen pensionsub_ci=.
label var pensionsub_ci "Recibe pensión o jubilación NO contributiva"

********************************************
* RECIBE PENSION O JUBILACION CONTRIBUTIVA *
********************************************
gen pension_ci=.
label var pension_ci "Recibe pensión o jubilación contributiva"

************************************************
*INSTITUCION QUE OTORGA LA PENSION O JUBILACION*
************************************************
gen instpen_ci=.
label var instpen_ci "Institución que otorga la pensión o jubilación"


*  DATA FROM MODULE ON SAFETY NETS NOT SUFFICIENT FOR CREATING VARs (can't identify specific beneficiary)

g tipopen_ci=.

* El modulo de safety nets incluye informacion de si algun miembro del hogar recibe 
* contributory/non-contributory old-age benefit. Solo se podria tener una variable a nivel del hogar (pension_ch)
* porque no se puede identificar directamente al beneficiario (sin asumir ciertas cosas)
  
*******************************
*******************************
*******************************
*     VARIABLES DE INGRESO    *
*******************************
*******************************
*******************************

*************************************
* INGRESO MONETARIO MENSUAL LABORAL *
*************************************

// Crear variable de ingreso laboral principal (mensual) según condición de ocupado

gen ylmpri_ci = . 
replace ylmpri_ci = q04_47_monthly if  emp_ci == 1 & categopri_ci==3 & (q04_47_monthly>=0 & q04_47_monthly!=.)
replace ylmpri_ci = q04_46_monthly if  emp_ci == 1 & categopri_ci==2 & (q04_46_monthly>=0 & q04_46_monthly!=.)

label variable ylmpri_ci "Monto mensual de ingreso laboral de la actividad principal"


*******************************
* INGRESO MENSUAL NO MONETARIO*
*******************************
gen ylnmpri_ci=.
label var ylnmpri_ci "Monto mensual de ingreso NO monetario de la actividad principal"

*************************************************
* INGRESO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
*************************************************
gen ylmsec_ci=.
replace ylmsec_ci = q04_64_monthly if  emp_ci == 1  & (q04_64_monthly>=0 & q04_64_monthly!=.)
replace ylmsec_ci = q04_65_monthly if  emp_ci == 1  & (q04_65_monthly>=0 & q04_65_monthly!=.)

label var ylmsec_ci "Monto mensual de ingreso laboral de la actividad secundaria"

****************************************************
* INGRESO NO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
****************************************************
gen ylnmsec_ci=.
label var ylnmsec_ci "Ingreso mensual laboral NO monetario de la actividad secundaria"

************************************
* INGRESO MENSUAL OTRAS ACTIVIDADES*
************************************
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso mensual por otras actividades"

*************************************************
* INGRESO MENSUAL NO MONETARIO OTRAS ACTIVIDADES*
*************************************************
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso mensual NO monetario por otras actividades"

************************************
* INGRESO MENSUAL TODAS ACTIVIDADES*
************************************
egen ylm_ci=rowtotal(ylmpri_ci ylmsec_ci)
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso mensual todas actividades"

*************************************************
* INGRESO MENSUAL NO MONETARIO TODAS ACTIVIDADES*
*************************************************
gen ylnm_ci= ylnmpri_ci + ylnmsec_ci + ylnmotros_ci
label var ylnm_ci "Ingreso mensual NO monetario todas actividades"

*************************************************
* INGRESO MENSUAL NO LABORAL OTRAS ACTIVIDADES  *
*************************************************
gen ynlm_ci=. 
*replace ynlm_ci= if apgvthlp==1
label var ynlm_ci "Ingreso mensual NO laboral otras actividades"

**************************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO OTRAS ACTIVIDADES  *
**************************************************************
gen ynlnm_ci= .
label var ynlnm_ci "Ingreso mensual NO laboral NO monetario otras actividades"
egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi


************************************
* INGRESO MENSUAL LABORAL DEL HOGAR*
************************************
egen ylm_ch=total(ylm_ci), by(idh_ch) missing
label var ylm_ch "Ingreso Laboral Monetario del Hogar (Bruto)"

**************************************************
* INGRESO MENSUAL LABORAL NO MONETARIO DEL HOGAR *
**************************************************
egen ylnm_ch=total(ylnm_ci), by(idh_ch) missing
label var ylnm_ch "Ingreso Laboral No Monetario del Hogar"

**************************************************
* INGRESO MENSUAL NO LABORAL MONETARIO DEL HOGAR *
**************************************************
egen ynlm_ch=total(ynlm_ci), by(idh_ch) missing
label var ynlm_ch "Ingreso No Laboral Monetario del Hogar"

*****************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO DEL HOGAR *
*****************************************************
egen ynlnm_ch=total(ynlnm_ci), by(idh_ch) missing
label var ynlnm_ch "Ingreso No Laboral No Monetario del Hogar"

***********************************
* INGRESO MENSUAL TOTAL DEL HOGAR *
***********************************
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
label var ytot_ch "Ingreso Mensual Total del Hogar"


*****************************************************
* INGRESO LABORAL POR HORA EN LA ACTIVIDAD PRINCIPA *
*****************************************************

gen ylmhopri_ci=ylmpri_ci/(4.3*horaspri_ci)
replace ylmhopri_ci=. if ylmhopri_ci<=0
label var ylmhopri_ci "Salario horario monetario de la actividad principal" 


*****************************************************
* INGRESO LABORAL POR HORA EN TODAS LAS ACTIVIDADES *
*****************************************************

gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario horario monetario de todas las actividades"

*******************
*** nrylmpri_ci ***
*******************
gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal" 

*******************
*** nrylmpri_ch ***
*******************
egen nrylmpri_ch = max(nrylmpri_ci), by (idh_ch) 
label variable nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

********************
***** ylmnr_ch *****
********************

egen ylmnr_ch=total(ylm_ci), by(idh_ch) missing
replace ylmnr_ch=. if nrylmpri_ch==1
label var ylmnr_ch "Ingreso laboral monetario del hogar" 



************************************************
* RENTA MENSUAL IMPUTADA DE LA VIVIENDA PROPIA *
************************************************
gen rentaimp_ch=.
label var rentaimp_ch "Renta imputada de la vivienda propia"
* TBD

*********************************************************
* MONTO MENSUAL DE INGRESO POR AUTOCONSUMO DEL INDIVIDUO*
*********************************************************
gen autocons_ci=.
label var autocons_ci "Monto mensual de ingreso por autoconsumo individuo"
* TBD

*****************************************************
* MONTO MENSUAL DE INGRESO POR AUTOCONSUMO DEL HOGAR*
*****************************************************
egen autocons_ch=sum(autocons_ci) if miembros_ci==1, by(idh_ch)
label var autocons_ch "Autoconsumo del Hogar"
* TBD

***************************
* REMESAS EN MONEDA LOCAL *
***************************

preserve

use "`base_in'/BSLC 2024-25_10_Assistance_Public_Weighted.dta",clear
for var q10_04 : recode X -1 = .
keep if cod_s10_received=="b"
cap keep if result==1
clonevar remesas=q10_04
collapse (sum) remesas, by(hh_id)
replace remesas=. if remesas==0
tempfile _1
save `_1'
restore

merge m:1 hh_id using `_1', nogen

gen remesas_ci=.
label var remesas_ci "Remesas en moneda local"
* NOTA: SE UTILIZAN SOLO REMESAS A NIVEL DEL HOGAR

************************************
* REMESES EN MONEDA LOCAL DEL HOGAR*
************************************
gen remesas_ch=remesas
label var remesas_ch "Remesas del hogar en moneda local"

************************************
* INGRESO POR PENSION CONTRIBUTIVA *
************************************
gen ypen_ci=.
label var ypen_ci "Ingreso por pension contributiva"
* TBD
***************************************
* INGRESO POR PENSION NO CONTRIBUTIVA *
***************************************
gen ypensub_ci=.
label var ypensub_ci "Ingreso por pensionc NO contributiva"
* TBD



*******************************
*******************************
*******************************
*    VARIABLES DE EDUCACION   *
*******************************
*******************************
*******************************

/*
q02_04: Has [NAME] ever attended school?
1	YES
2	NO

q02_14: Is [NAME] currently attending an educational institution (eg. school or university)? 
1	YES
2	NO


q02_17: In what level is [NAME] enrolled this school year? 
1	PRE-SCHOOL
2	RECEPTION
3	INFANTS A
4	INFANTS B
5	CLASS 1
6	CLASS 2
7	CLASS 3
8	CLASS 4
9	FORM 1
10	FORM 2
11	FORM 3
12	FORM 4
13	FORM 5
14	LOWER FORM 6
15	UPPER FORM 6
16	TECHNICAL VOCATIONAL
17	UNIVERSITY 1
18	UNIVERSITY 2
19	UNIVERSITY 3
20	UNIVERSITY 4
21	UNIVERSITY 5
22	BACHELLOR DEGREE
23	MASTER DEGREE
24	PHD DEGREE
25	NONE				


If not currently attending:

q02_07: What is the highest level [NAME] has completed?
1	PRE-SCHOOL
2	RECEPTION
3	INFANTS A
4	INFANTS B
5	CLASS 1
6	CLASS 2
7	CLASS 3
8	CLASS 4
9	FORM 1
10	FORM 2
11	FORM 3
12	FORM 4
13	FORM 5
14	LOWER FORM 6
15	UPPER FORM 6
16	TECHNICAL VOCATIONAL
17	UNIVERSITY 1
18	UNIVERSITY 2
19	UNIVERSITY 3
20	UNIVERSITY 4
21	UNIVERSITY 5
22	BACHELLOR DEGREE
23	MASTER DEGREE
24	PHD DEGREE
25	NONE

q02_08: What is [NAME]'s highest qualification attained?

1	NONE
2	COMMON ENTRANCE / BSSEE
3	SCHOOL LEAVING CERTIFICATE
4	CXC BASIC
5	CXC GENERAL / 'O' LEVEL
6	CITY AND GUILDS
7	GCE "A" / CAPE
8	DIPLOMA OR EQUIVALENT CERTIFICATE OF ACHIEVEMENT
9	TECHNICAL /  VOCATIONAL TRAINING
10	CVQ 
11	NVQ 
12	ASSOCIATE DEGREE / HIGHER DIPLOMA 
13	BACHELORS DEGREE
14	POST GRADUATE DIPLOMA / PROFESIONAL QUALIFICATION
15	MASTERS DEGREE
16	PHD DEGREE
97	OTHER (SPECIFY)
98	DON'T KNOW
*/	


* Nivel educativo
/*  0 = nunca asistió       
    1 = primario incompleto
    2 = primario completo    
    3 = secundario incompleto
    4 = secundario completo  
    5 = superior incompleto 
    6 = superior completo                                     
*/


gen     nivel = 0 if q02_04==2 		/* never attended */
replace nivel = 0 if q02_14==2 & (q02_07==1 | q02_07==2)	/* achieved pre or reception */ 
replace nivel = 0 if q02_17==1 | q02_17==2 | q02_17==3 		/* currently at pre, reception or infants A */

replace nivel = 1 if q02_07>=3 & q02_07<=7					/* achieved infants A to class 3 */
replace nivel = 1 if q02_17>=4 & q02_17<=8					/* currently at primary	*/

replace nivel = 2 if q02_07==8 								/* achieved primary */
replace nivel = 2 if q02_17==9 								/* currently at form 1 */

replace nivel = 3 if  q02_07>=9 & q02_07<=14 				/* achieved form 1 - form 6 */
replace nivel = 3 if  q02_14==1 & (q02_17>=10 & q02_17<=15)	/* currently in secondary */

replace nivel = 4 if  q02_07==15  							/* achieved secondary */
replace nivel = 4 if q02_17==16 | q02_17==17				/* currently in technical or university year 1 */

replace nivel = 5 if  q02_07>=16 & q02_07<=21				/* achieved technical or up to university year 5 */
replace nivel = 5 if  q02_14==1 & (q02_17>=18 & q02_17<=21)	/* currently in university year 2 to 5 */

replace nivel = 6 if q02_07>=22 & q02_07<=24				/* achieved bachelors degree or higher */
replace nivel = 6 if q02_17==23 | q02_17==24				/* currently in masters or phd */

replace nivel = . if edad<3
label define nivel 0"nunca asistió" 1"primario incompleto" 2"primario completo" 3"secundario incompleto" 4"secundario completo" 5"superior incompleto" 6"superior completo"
label values nivel nivel
	
*************
***aedu_ci*** 
*************

* Para los currently enrolled

gen aedu_ci = .
replace aedu_ci = 0 		if 		q02_17==1 | q02_17==2 | q02_17==3 
replace aedu_ci = 1 		if 		q02_17==4 			/* currently at infants B, completed 1 year in infants A */
replace aedu_ci = 2 		if 		q02_17==5 			/* currently at class 1, completed infants A and B  */
replace aedu_ci = 3 		if 		q02_17==6 			/* currently at class 2, completed infants and class 1  */
replace aedu_ci = 4 		if 		q02_17==7 			/* currently at class 3, completed infants and class 2  */
replace aedu_ci = 5 		if 		q02_17==8 			/* currently at class 4, completed infants and class 3  */

replace aedu_ci = 6 		if 		q02_17==9 			/* currently at form 1, completed primary (6 years)  */
replace aedu_ci = 7 		if 		q02_17==10 			/* currently at form 2, completed form 1  */
replace aedu_ci = 8 		if 		q02_17==11 			/* currently at form 3, completed form 2  */
replace aedu_ci = 9 		if 		q02_17==12 			/* currently at form 4, completed form 3  */
replace aedu_ci = 10 		if 		q02_17==13 			/* currently at form 5, completed form 4  */

replace aedu_ci = 11 		if 		q02_17==14 			/* currently at lower form 6, completed  secondary (+ 5 years)  */
replace aedu_ci = 12 		if 		q02_17==15 			/* currently at upper form 6, completed  lower form 6   */

replace aedu_ci = 12 		if 		q02_17==16 			/* currently technical/vocational. Assumes requirement is completed until upper form 6   */

replace aedu_ci = 13 		if 		q02_17==17 			/* currently at university 1,  completed secondary school */
replace aedu_ci = 14 		if 		q02_17==18 			/* currently at university 2,  completed university 1 */
replace aedu_ci = 15 		if 		q02_17==19 			/* currently at university 3,  completed university 2 */
replace aedu_ci = 16 		if 		q02_17==20 			/* currently at university 4,  completed university 3 */
replace aedu_ci = 17 		if 		q02_17==21 			/* currently at university 5,  completed university 4 */

replace aedu_ci = 18 		if 		q02_17==22 			/* bachelors degree   */

replace aedu_ci = 20 		if 		q02_17==22 			/* master degree. Assumes 2+ years after bachelor's   */

replace aedu_ci = 23 		if 		q02_17==22 			/* phd degree   Assumes 3+ years after master's */

*replace aedu_ci = 0 		if 		q02_17==25			/* answered NONE to q02_17 */


* Para los que no asisten
replace aedu_ci = 0 		if 		q02_14==2 & (q02_07==1 | q02_07==2)
replace aedu_ci = 1 		if 		q02_14==2 & q02_07==3		
replace aedu_ci = 2 		if 		q02_14==2 & q02_07==4		
replace aedu_ci = 3 		if 		q02_14==2 & q02_07==5		
replace aedu_ci = 4 		if 		q02_14==2 & q02_07==6		
replace aedu_ci = 5 		if 		q02_14==2 & q02_07==7		
replace aedu_ci = 6 		if 		q02_14==2 & q02_07==8
		
replace aedu_ci = 7 		if 		q02_14==2 & q02_07==9		
replace aedu_ci = 8 		if 		q02_14==2 & q02_07==10		
replace aedu_ci = 9 		if 		q02_14==2 & q02_07==11		
replace aedu_ci = 10 		if 		q02_14==2 & q02_07==12		
replace aedu_ci = 11 		if 		q02_14==2 & q02_07==13
		
replace aedu_ci = 12 		if 		q02_14==2 & q02_07==14		
replace aedu_ci = 13 		if 		q02_14==2 & q02_07==15		

replace aedu_ci = 13 		if 		q02_14==2 & q02_07==16		
replace aedu_ci = 14 		if 		q02_14==2 & q02_07==17		
replace aedu_ci = 15 		if 		q02_14==2 & q02_07==18		
replace aedu_ci = 16 		if 		q02_14==2 & q02_07==19		
replace aedu_ci = 17 		if 		q02_14==2 & q02_07==20		
replace aedu_ci = 18 		if 		q02_14==2 & q02_07==21		

replace aedu_ci = 19 		if 		q02_14==2 & q02_07==22		

replace aedu_ci = 21 		if 		q02_14==2 & q02_07==23		/* Masters */

replace aedu_ci = 24 		if 		q02_14==2 & q02_07==24		/* Phd Completed */	

*replace aedu_ci = 0 		if 		q02_14==2 & q02_07==25		/* answered NONE to q02_07 */


label var aedu_ci "Numero de años de educación culminados"

**************
* Line of code with indicator eduno_ci was deleted**************
* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted


***************
***edupre_ci***
***************
gen edupre_ci=.	 
label var edupre_ci "Ha completado educación preescolar"

**************
* Line of code with indicator edupi_ci was deleted**************
* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
**************
* Line of code with indicator edupc_ci was deleted**************
* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
**************
* Line of code with indicator edusi_ci was deleted**************
* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted
**************
* Line of code with indicator edusc_ci was deleted**************
* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted

**************
***eduui_ci***
**************
gen eduui_ci=(q02_07>=9 & q02_07<=15) & (q02_08<=7)
replace eduui_ci=. if q02_07>=25
label var eduui_ci "No ha completado la educación terciaria/universitaria"

**************
***eduuc_ci***
**************
gen eduuc_ci=(nivel==6) & (q02_08>=8 & q02_08<=16)
replace eduuc_ci=. if q02_07>=25
label var eduuc_ci "Ha completado la educación terciaria/universitaria"


**************
***eduac_ci***
**************
gen eduac_ci=.
replace eduac_ci=1 if nivel==6
replace eduac_ci=0 if nivel==5
label var eduac_ci "Ha completado educación terciaria académica"

***************
***asiste_ci***
***************
gen asiste_ci=(q02_14==1)
replace asiste_ci=. if q02_14==.
label var asiste_ci "Asiste a algún centro de enseñanza"


***edupub_ci***
***************
gen edupub_ci=.
replace edupub_ci=1 if q02_18==1
replace edupub_ci=0 if q02_18==2
label var edupub_ci "Asiste a centro de enseñanza pública"
label define edupub 1"Pública" 0"Privada"  
label values edupub_ci edupub


****************
***asispre_ci***
****************
gen byte asispre_ci=(q02_17==1 | q02_17==2 | q02_17==3)
replace asispre_ci=. if asiste_ci==.
label variable asispre_ci "Asistencia a Educacion preescolar"



*****************
* Line of code with indicator pqnoasis_ci was deleted*****************
* Line of code with indicator pqnoasis_ci was deleted
* Line of code with indicator pqnoasis_ci was deleted  
* Line of code with indicator pqnoasis_ci was deleted


******************
***pqnoasis1_ci***
******************
/* q02_15: Why is [NAME] not attending school this school year? 
1	HAD ENOUGH / COMPLETED SCHOOLING
2	AWAITING ADMISSION
3	NO SCHOOL / LACK OF TEACHERS
4	NO TIME
5	NO INTEREST
6	LACK OF MONEY
7	MARITAL OBLIGATION
8	SICKNESS
9	DISABILITY
10	SEPARATION OF PARENTS
11	DEATH OF PARENTS
12	TOO OLD TO ATTEND
13	DOMESTIC OBLIGATION
14	PREGNANCY
15	TOO YOUNG
16	POOR SCHOOL INFRASTRUCTURE (E.G. LACK OF AC)
17	UNFRIENDLY SCHOOL ENVIRONMENT
97	OTHER (SPECIFY)
*/

gen pqnoasis1_ci=.
replace pqnoasis1_ci=1 if q02_15==6
replace pqnoasis1_ci=2 if q02_15==5
replace pqnoasis1_ci=3 if q02_15==13 | q02_15==14 | q02_15==8 | q02_15==9 | q02_15==10 
replace pqnoasis1_ci=4 if q02_15==3 | q02_15==16  
replace pqnoasis1_ci=5 if q02_15==1 | q02_15==2 | q02_15==4 | q02_15==7 | q02_15==11 | q02_15==12 | q02_15==15 | q02_15==17 
label define pqnoasis 1"Problemas economicos/por trabajo" 2"Falta de interes/probemas de rendimiento" 3"Quehaceres domesticos/embarazo/cudiado de niños/problemas fam" 4"Problemas de acceso" 5"Otros" 

*NOTA. VARIABLE ESTA CAPPED EDAD<30

***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted* Line of code with indicator repite_ci was deleted
* Line of code with indicator repiteult was deleted* Line of code with indicator repiteult was deleted
******************



*******************************
*******************************
*******************************
*    VARIABLES DE VIVIENDA    *
*******************************
*******************************
*******************************


gen luz_ch=.
replace luz_ch=1 if q12_17==1
replace luz_ch=0 if q12_17==2


gen luzmide_ch=.
replace luzmide_ch=1 if q12_19==1
replace luzmide_ch=0 if q12_19>=2 & q12_19<=97 

*NOTA: Se asume con medidor a los hogares cuya fuente ppal de electricidad es BL&P (Barbados LIGHT & POWER CO.)

gen combust_ch=.
replace combust_ch=1 if q12_13<=3
replace combust_ch=0 if q12_13>=4 & q12_13<=7 


gen piso_ch=.
replace piso_ch=1 if q12_11>=1 & q12_11<=4  
replace piso_ch=2 if q12_11==5   


gen pared_ch=.
replace pared_ch=0 if q12_09>=6 & q12_09<=8
replace pared_ch=1 if q12_09>=1 & q12_09<=5
replace pared_ch=2 if q12_09>8
 

gen techo_ch=.
replace techo_ch=0 if q12_10==4
replace techo_ch=1 if q12_10==1 | q12_10==3 | q12_10==5
replace techo_ch=2 if q12_10==2 | q12_10==97


gen resid_ch=.
replace resid_ch=0 if q12_39==1 | q12_39==2
replace resid_ch=1 if q12_39==4 | q12_39==5 | q12_39==6
replace resid_ch=2 if q12_39==3 
replace resid_ch=3 if q12_39==97 



gen dorm_ch=.

gen cuartos_ch=.
replace cuartos_ch=q12_12
*NOTA: Include bedrooms, living room, dining room, and study room. 
* Do not count bathrooms, kitchens, laundry rooms, storage rooms, or veranda.


gen cocina_ch=(q12_15==1)

preserve
use "`base_in'/BSLC 2024-25_09_Assets_Public_Weighted",clear
/*
q08_02: How many [ITEM] (s) does your household own?
cod_s8 (Item Code)
101	Sofa or armchairs			
102	Mattress			
103	Bed			
104	Gas (or kerosene) cooker			
105	Stove (electric or gas)			
106	Refrigerator 						***
107	Freezer								***
108	Dishwasher			
109	Air conditioner			
110	Washing machine			
111	Clothes dryer			
112	Bicycle			
113	Motorbike			
114	Cars and other 4-wheel vehicles		***		
115	Generator			
116	Fan			
117	Microwave			
118	TV			
119	Computer or tablet					***	
120	Game console			
121	Satellite dish			
122	Smartphone			
123	Mobile phone (not smartphones)			
124	Water tank			
125	Solar water heater			
*/

keep if cod_s8==106 | cod_s8==119 | cod_s8==114 | cod_s8==107

gen refrig=(q08_01==1 & cod_s8==106)
gen compu=(q08_01==1 & cod_s8==119)
gen auto=(q08_01==1 & cod_s8==114)
gen freezer=(q08_01==1 & cod_s8==107)


collapse (sum) refrig compu auto freezer, by(hh_id)
tempfile _2
save `_2'
restore

merge m:1 hh_id using `_2', nogen

rename refrig refrig_ch
rename compu compu_ch
rename auto auto_ch
rename freezer freez_ch

gen telef_ch=.
gen internet=(q02_47==1)
egen internet_ch=max(internet), by(hh_id)
drop internet

gen cel_ch=.


gen vivi1_ch=.
replace vivi1_ch=1 if q12_01==1 | q12_01==2 | q12_01==4 
replace vivi1_ch=2 if q12_01==3 | q12_01==5 
replace vivi1_ch=3 if q12_01>=6

gen vivi2_ch=(vivi1_ch==1 | vivi1_ch==2)
replace vivi2_ch=. if vivi1_ch==. 


gen viviprop_ch=.
replace viviprop_ch=0 if q12_02==2 | q12_02==5
replace viviprop_ch=1 if q12_02==1
replace viviprop_ch=2 if q12_02==4
replace viviprop_ch=3 if q12_02==3


gen vivitit_ch=(q12_06==1)
replace vivitit_ch=. if q12_06==.
*NOTA. Solo incluye los que tienen TITLE/DEED

gen vivialq_ch=q12_05
recode vivialq_ch -1 = .

gen vivialqimp_ch=q12_04
recode vivialqimp_ch -1 = .

* (REPLICATING FROM SURINAME DO-FILE)
****************
***aguared_ch***
****************

gen aguared_ch =.
replace aguared_ch = 1 if (q12_34==1 |q12_34==2)
replace aguared_ch = 0 if q12_34>2
label var aguared_ch "Acceso a fuente de agua por red"

*********************
***aguafconsumo_ch***
*********************

gen aguafconsumo_ch =.
replace aguafconsumo_ch=1 if q12_26==1
replace aguafconsumo_ch=2 if q12_26==6
replace aguafconsumo_ch=3 if q12_26==3
replace aguafconsumo_ch=6 if q12_26==2
replace aguafconsumo_ch=6 if q12_26==5 | q12_26==4
label var aguafconsumo_ch "Principal fuente de agua para beber"


*******************
***aguafuente_ch***
*******************

gen aguafuente_ch=.
replace aguafuente_ch=1 if q12_34==1 | q12_34==2
replace aguafuente_ch=2 if q12_34==3
replace aguafuente_ch=4 if q12_34==4
replace aguafuente_ch=10 if q12_34==5
label var aguafuente_ch "Principal fuente de agua para todos usos"


*****************
***aguadist_ch***
*****************

gen aguadist_ch=.

/*replace aguadist_ch=0 if q12_34==97
replace aguadist_ch=1 if q12_34==1
replace aguadist_ch=2 if q12_34==2 | q12_34==3 | q12_34==4
replace aguadist_ch=3 if q12_34==5


label var aguadist_ch "Ubicación de la principal fuente de agua"
label def aguadist_ch 1"Dentro_de_la_vivienda" 2"Fuera_de_la_vivienda_pero_en_el_terreno", add modify
label def aguadist_ch 3"Fuera_de_la_vivienda_y_del_terreno", add modify
label val aguadist_ch aguadist_ch */
* NOTA: LA VARIABLE DE UBICACION (1	IN OWN DWELLING. 2 IN OWN YARD / PLOT 3	ELSEWHERE)
* SOLO SE PREGUNTA PARA LAS DE MAIN SOURCE OF DRINKING WATER==PUBLIC TAP / STANDPIPE


******************
***aguadisp1_ch***
******************

gen aguadisp1_ch=(q12_31==2)
lab var aguadisp1_ch "Continuidad de disponibilidad de agua suficiente"

******************
***aguadisp2_ch***
******************

gen aguadisp2_ch=.
replace aguadisp2_ch=1 if  q12_32>0 & q12_33>360 
replace aguadisp2_ch=2 if  q12_32>0 & (q12_33>=0 & q12_33<=360)
replace aguadisp2_ch=3 if  q12_32==0 
lab var aguadisp2_ch "Continuidad de disponibilidad de agua"

*****************
***aguatrat_ch***
*****************

gen aguatrat_ch =(q12_29==1)
replace aguatrat_ch=. if q12_29==.

*****************
***aguamala_ch***
*****************

gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*********************
***aguamejorada_ch***
*********************

gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7


*****************
***aguamide_ch***
*****************

gen aguamide_ch = .

*************
***bano_ch***
*************

gen bano_ch=.
replace bano_ch=0 if q12_36==8
replace bano_ch=1 if q12_36==1
replace bano_ch=2 if q12_36==2
replace bano_ch=4 if q12_36==3
replace bano_ch=3 if q12_36==4
replace bano_ch=5 if q12_36==5 | q12_36==7
replace bano_ch=6 if q12_36==9 | q12_36==97


***************
***banoex_ch***
***************

gen banoex_ch=(q12_38==2)
replace banoex_ch=. if q12_38==.

*********************
***banomejorada_ch***
*********************

gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6



******************************
*** VARIABLES DE MIGRACION ***
******************************

* Variables incluidas por SCL/MIG Fernando Morales

*******************
*** migrante_ci ***
*******************

gen migrante_ci = .
label var migrante_ci "=1 si es migrante"

**********************
*** migrantiguo5_ci ***
**********************

gen migrantiguo5_ci = .
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"


**********************
*** migrantelac_ci ***
**********************

gen miglac_ci= .


* NOTA: MODULO DE MIGRACION (5B) ES SOLO OUT-MIGRATION


***********************************
* VARIABLES DE REFERENCIA EXTERNA *
***********************************



********************************
* SALARIO MINIMO MENSUAL LEGAL *
********************************
gen salmm_ci =.
label var salmm_ci "salario mínimo mensual legal"
* TBD

****************************************
* LINEA DE POBREZA OFICIAL MONEDA LOCAL*
****************************************
gen lp_ci =.
label var lp_ci "Línea de pobreza oficial en moneda local"

************************************************
* LINEA DE POBREZA EXTREMA OFICIAL MONEDA LOCAL*
************************************************
gen lpe_ci =.
label var lpe_ci "Línea de pobreza extrema oficial en moneda local"

	
/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

cap order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch BRB_dis_ci /// Diversidad
condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación
luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
migrante_ci migrantiguo5_ci miglac_ci /// Migración
salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
/// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

*armonizar las variables originales de códigos de industria y ocupacion
clonevar codindustria=q04_40_cod_isic
clonevar codocupa= q04_39_cod_isco
*rename indus codindustria
*rename occup codocupa


compress


save "`base_out'", replace


log close
