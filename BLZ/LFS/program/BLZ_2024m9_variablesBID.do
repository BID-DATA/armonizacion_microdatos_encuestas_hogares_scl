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

local PAIS BLZ
local ENCUESTA LFS
local ANO "2024"
local ronda m9

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

*log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Belize
Encuesta: LFS
Round: April
Autores: 
Modificación 2023: Natalia Tosi y Mayte Ysique
Fecha última modificación: Agosto 2023

							SCL/LMK - IADB
*************************************************************************** */
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

*************************************************************************** */
use `base_in', clear


**********************
* AÑO DE LA ENCUESTA *
**********************
gen anio_c = 2024

*************************
* FACTORES DE EXPANSION *
*************************
gen factor_ch = final_weight
label var factor_ch "Factor de Expansion del Hogar"

gen factor_ci = final_weight
label var factor_ci "Factor de Expansion del Individuo"

**************
* REGION BID *
**************
gen region_BID_c = 1
label var region_BID_c "Region BID"
label define region_BID 1"Centroamérica" 2"Caribe" 3"Andinos" 4"Cono Sur"
label values region_BID_c region_BID

***************
* REGION PAIS *
***************

* district: 1=Corozal, 2=Orange Walk, 3=Belize, 4=Cayo, 5=Stann Creek, 6=Toledo

gen byte ine01 = district
label define ine01   	///
1 "Corozal" 			///
2 "Orange Walk"	 		///
3 "Belize"				///
4 "Cayo"				///
5 "Stann Creek"			///
6 "Toledo"
label value ine01 ine01

***************
*    ZONA     *
***************
gen byte zona_c = (urban_rural == 1)
replace zona_c = . if missing(urban_rural)

label variable zona_c "Zona geográfica"
label define zona_c 0 "Rural" 1 "Urbana"
label value zona_c zona_c

***********
*  MES   *
***********
g mes_c = 4

***********
*  PAIS   *
***********
gen pais_c = "BLZ"
label var pais_c "Acrónimo del país"

******************************
*  IDENTIFICADOR DEL HOGAR   *
******************************
egen idh_ch = group(_v1)
label var idh_ch "Identificador Unico del Hogar"
tostring idh_ch, replace

*sort HHID PNUM
*quietly by HHID PNUM: gen rep = cond(_N == 1, 0, _n)

*******************************
* IDENTIFICADOR DEL INDIVIDUO *
*******************************

*Crear un identificador único por persona dentro del hogar
sort interview__key _v1
by interview__key: gen _seq = _n
egen idp_ci = concat(idh_ch _seq)
label var idp_ci "Identificador Individual dentro del Hogar"
tostring idp_ci, replace format ("%20.0f")
drop _seq

************************************
*  RELACION CON EL JEFE DE HOGAR   *
************************************

* hl4new: 1=Head, 2=Spouse/Partner, 3=Child, 4=Grandchild, 5=Other, 9=DK/NS
gen byte relacion_ci = .
replace relacion_ci = 1 if hl4new == 1
replace relacion_ci = 2 if hl4new == 2
replace relacion_ci = 3 if hl4new == 3
replace relacion_ci = 4 if hl4new == 4
replace relacion_ci = 5 if hl4new == 5

* DK/NS (9) se deja como missing

label var relacion_ci "relación con el jefe de hogar"
label define relacion 1"Jefe" 2"Cónguye, Esposo/a, Compañero/a" 3"Hijo/a" 4"Otros parientes" 5"Otros no parientes" 6"Servicio doméstico" 
label values relacion_ci relacion


************************************
* DUMMY PARA NO MIEMBROS DEL HOGAR *
************************************

* Create a dummy indicating this person's income should NOT be included (Comentario: No entiendo a qué va esta nota. parece contradictoria con el label)
gen miembros_ci= 1
label variable miembros_ci "Variable dummy que indica las personas que son miembros del Hogar"

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
* hl5: 1=Male, 2=Female, 3=DK/NS
gen byte sexo_ci = .
replace sexo_ci = 1 if hl5 == 1
replace sexo_ci = 2 if hl5 == 2

*DK/NS (3) se deja como missing

label var sexo_ci "sexo del individuo"
label define sexo 1"Masculino" 2"Femenino" 
label values sexo_ci sexo

***********
*  EDAD   *
***********
gen edad_ci = hl3 
label var edad_ci "edad del individuo"

*******************
*  ESTADO CIVIL   *
*******************
* No hay la pregunta. MGD 08/27/2014
* Para 2024 sí hay la pregunta y una adicional de estado civil actualizado
* hl8new: 1=Never Married, 2=Married, 3=Divorced, 4=Widowed, 5=Legally Separated, 9=DK/NS
	* hl9: 1=Married living w/spouse, 2=Married not living, 3=Common-law 5+yr,
	*      4=Living together <5yr, 5=Visiting partner, 7=Not in union
	
gen byte civil_ci = .
replace civil_ci = 1 if hl8new == 1
replace civil_ci = 2 if hl8new == 2
replace civil_ci = 2 if inlist(hl9, 3, 4, 5)
replace civil_ci = 3 if hl8new == 3 | hl8new == 5
replace civil_ci = 4 if hl8new == 4

label var civil_ci "Estado civil del individuo"
label define civil 1"Soltero" 2"Unión formal o informal" 3"Divorciado o separado" 4"Viudo" 
label values civil_ci civil

*******************
*  JEFE DE HOGAR  *
*******************

gen byte jefe_ci = .
replace jefe_ci = 1 if (relacion_ci == 1)
replace jefe_ci = 0 if (relacion_ci != 1) & (relacion_ci != .)

label var jefe_ci "Jefe de hogar"
label define jefe 1"Jefe de Hogar" 2"Otro" 
label values jefe_ci jefe

/*
replace jefe_ci=1 if relacion_ci==1
label var jefe_ci "Jefe de hogar"
label define jefe 1"Jefe de Hogar" 2"Otro" 
label values jefe_ci jefe
*/

************************************
*  NUMERO DE CONYUGES EN EL HOGAR  *
************************************

egen nconyuges_ch=sum(relacion_ci==2), by (idh_ch)
replace nconyuges_ch = . if relacion_ci == .
label var nconyuges_ch "Número de Conyuges en el hogar"

************************************
*  NUMERO DE HIJOS EN EL HOGAR  *
************************************
egen nhijos_ch=sum(relacion_ci==3), by (idh_ch)
replace nhijos_ch = . if relacion_ci == .
label var nhijos_ch "Número de hijos en el hogar"

*******************************************
*  NUMERO DE OTROS PARIENTES EN EL HOGAR  *
*******************************************
egen notropari_ch=sum(relacion_ci==4), by (idh_ch)
replace notropari_ch = . if relacion_ci == .
label var notropari_ch "Número de otros parientes en el hogar"

*******************************************
*  NUMERO DE OTROS NO PARIENTES EN EL HOGAR  *
*******************************************
egen notronopari_ch=sum(relacion_ci==5), by (idh_ch)
replace notronopari_ch = . if relacion_ci == .
label var notronopari_ch "Número de otros parientes en el hogar"

*************************************
*  NUMERO DE EMPLEADOS EN EL HOGAR  *
*************************************
egen nempdom_ch=sum(relacion_ci==6), by (idh_ch)
replace nempdom_ch = . if relacion_ci == .
label var nempdom_ch "Número de empleados en el hogar"

*********************
*  CLASE DE HOGAR   *
*********************
gen clasehog_ch=.

replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0 /* unipersonal*/
replace clasehog_ch=2 if nhijos_ch>0 & nhijos_ch!=. & notropari_ch==0 & notronopari_ch==0 /* nuclear (child with or without spouse but without other relatives)*/
replace clasehog_ch=2 if nconyuges_ch>0 & nconyuges_ch!=. & notropari_ch==0 & notronopari_ch==0 /* nuclear (spouse with or without children but without other relatives)*/
replace clasehog_ch=3 if notropari_ch>0 & notropari_ch!=. & notronopari_ch==0 /* ampliado*/
replace clasehog_ch=4 if nhijos_ch>0 & nhijos_ch!=. & notropari_ch==0 & notronopari_ch>0 & notronopari_ch!=. /* nuclear (child with or without spouse but without other relatives)*/
replace clasehog_ch=4 if nconyuges_ch>0 & nconyuges_ch!=. & notropari_ch==0 & notronopari_ch>0 & notronopari_ch!=. /* nuclear (spouse with or without children but without other relatives)*/
replace clasehog_ch=4 if notropari_ch>0 & notropari_ch!=. & notronopari_ch>0 & notronopari_ch!=. /* ampliado*/
replace clasehog_ch=4 if nconyuges_ch>0 | nhijos_ch>0 | (notropari_ch>0 & notropari_ch<.) & (notronopari_ch>0 & notronopari_ch<.) /* compuesto  (some relatives plus non relative)*/
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

**************************
*  MIEMBROS EN EL HOGAR  *
**************************
g miembros_ch=0
replace miembros_ch=1 if relacion_ci>=1 & relacion_ci<=4
label var miembros_ch "Miembros en el hogar"
label define miembros 1"Miembro" 2"No miembro"  
label values miembros_ch miembros

********************************************
*  MIEMBROS EN EL HOGAR MAYORES DE 21 AÑOS *
********************************************
egen nmayor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci>=21)), by (idh_ch)												
label variable nmayor21_ch "Numero de personas de 21 años o mas dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 21 AÑOS *
********************************************
egen nmenor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<21)), by (idh_ch)
label variable nmenor21_ch "Numero de personas menores a 21 años dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MAYORES DE 65 AÑOS *
********************************************
egen nmayor65_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci>=65)), by (idh_ch)
label variable nmayor65_ch "Numero de personas de 65 años o mas dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 65 AÑOS *
********************************************
egen nmenor65_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<=65 & edad_ci != .)), by (idh_ch)
label variable nmenor65_ch "Miembros de 65 años o menos dentro del Hogar"

********************************************
*  MIEMBROS EN EL HOGAR MENORES DE 6 AÑOS *
********************************************
egen nmenor6_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<6)), by (idh_ch)
label variable nmenor6_ch "Miembros menores a 6 años dentro del Hogar"

******************************************
*  MIEMBROS EN EL HOGAR MENORES DE 1 AÑO *
******************************************
egen nmenor1_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<1)),  by (idh_ch)
label variable nmenor1_ch "Miembros menores a 1 año dentro del Hogar"


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
*la variable HL6 tiene una clasificación
*1= Creole
*2= Garifuna
*3= Maya
*4= Mestizo/Hispanic
*5= Mennonite --------------------- ya no está en 2024
*6= East Indian --------------------- ya no está en 2024
*7= Other --------------------- ya no está en 2024
*9= DK/NS

	*********
	*afro_ci*
	*********
	
	* hl6new: 1=Creole, 2=Garifuna, 3=Maya, 4=Mestizo/Hispanic, 5=Other, 9=DK/NS
	* Creole (1) y Garifuna (2) se consideran afrodescendientes en Belize
	
	gen byte afro_ci = .
	replace afro_ci = 1 if inlist(hl6new, 1, 2)
	replace afro_ci = 0 if inlist(hl6new, 3, 4, 5)
	
	*********
	*ind_ci*
	*********	
	* Maya (3) se considera indígena en Belize
	gen byte ind_ci = .
	replace ind_ci = 1 if hl6new == 3
	replace ind_ci = 0 if inlist(hl6new, 1, 2, 4, 5)
	
	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci == 0 & ind_ci == 0
	replace noafroind_ci = 0 if afro_ci == 1 | ind_ci == 1

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1

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

	********
	*dis_ci*
	********
	* No hay variables de discapacidad en esta encuesta
	gen byte dis_ci=.
	
	**********
	*disWG_ci*
	**********
	gen byte disWG_ci=.
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte BLZ_dis_ci = .



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

*************
*condocup_ci*
*************
* status: 1=Under 14, 2=Employed, 3=Unemployed, 4=PNLF, 5=DK/NS

gen byte condocup_ci = .
replace condocup_ci = 1 if status == 2 /* ocupado */
replace condocup_ci = 2 if status == 3 /* desocupado */
replace condocup_ci = 3 if status == 4 /* inactivo */
replace condocup_ci = 4 if status == 1
* DK/NS: clasificamos según edad
replace condocup_ci = 3 if status == 5 & edad_ci >= 14
replace condocup_ci = 4 if status == 5 & edad_ci < 14
	
label define condocup 1"Ocupado" 2"Desocupado" 3"Inactivo" 4 "Menores de 14 años"
label values condocup_ci condocup
label var condocup_ci "Condición de ocupación"

**************************
* CATEGORIA DE INACTIVIDAD  *
**************************

* ea12: razón de inactividad
* 7=Retired/Pensioner, 2=In school, 1=Personal/family, otros=4

gen byte categoinac_ci = .
replace categoinac_ci = 1 if ea12 == 7 & condocup_ci == 3 /* Jubilados, pensionados */
replace categoinac_ci = 2 if ea12 == 2 & condocup_ci == 3 /* Estudiantes */
replace categoinac_ci = 3 if ea12 == 1 & condocup_ci == 3 /* Quehaceres del Hogar */
replace categoinac_ci = 4 if (categoinac_ci == . & condocup_ci == 3) /* Otra razon */

label define inactivo 1 "Jubilados o Pensionado" 2 "Estudiante" 3 "Hogar" 4 "Otros", replace
label values categoinac_ci inactivo

************
* OCUPADO  *
************
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if condocup_ci != .
label var emp_ci "Ocupado"
label define ocupado 1"Ocupado" 0"No ocupado"  
label values emp_ci ocupado

***********
* CESANTE *
***********
* Cesante = desocupado que trabajó antes
* ea19new: 1=Yes, 2=No (¿trabajó antes?)

gen byte cesante_ci = .
replace cesante_ci = 1 if condocup_ci == 2 & ea19new == 1
replace cesante_ci = 0 if condocup_ci == 2 & ea19new == 2
label var cesante_ci "Cesante"

***************
* DESOCUPADO  *
***************
gen desemp_ci=0 
replace desemp_ci=1 if condocup_ci==2
label var desemp_ci "Desocupado"
label define desocupado 1"Desocupado" 0"No desocupado"  
label values desemp_ci desocupado

*****************************
* TRABAJA MENOS DE 30 HORAS *
*****************************
* MGD 08/29/2014: no hay la pregunta de si desea trabajar mas horas, pero se utiliza disponibilidad para otro trabajo.

* Subempleo visible: trabaja menos de 30 horas y quiere trabajar más
* ea32: 1=Yes, 2=No  (Pregunta ¿quiere trabajar más horas?)

gen subemp_ci=0
replace subemp_ci = 1 if total_hrs_last_week < 35 & total_hrs_last_week != . & ea32 == 1 & emp_ci == 1 /* Decía <= a 30 horas y lo he reemplazado por < 30 horas */
replace subemp_ci = . if emp_ci != 1
label var subemp_ci "Trabaja menos de 30 horas"

***********************************
* DURACION DEL DESEMPLEO EN MESES *
***********************************
*La variable esta definida por intervalos de tiempo. Se uso el punto medio del intervalo
*gen durades_ci=.
/*
replace durades_ci=0.5 if condocup_ci==2 & cq124==1
replace durades_ci=2 if condocup_ci==2 & cq124==2
replace durades_ci=5 if condocup_ci==2 & cq124==3
replace durades_ci=10 if condocup_ci==2 & cq124==4
replace durades_ci=12 if condocup_ci==2 & cq124==5
*/
/*
gen durades_ci_inter=.
replace durades_ci_inter=1 if condocup_ci==2 & periodunempl==1
replace durades_ci_inter=2 if condocup_ci==2 & periodunempl==2
replace durades_ci_inter=3 if condocup_ci==2 & periodunempl==3

label var durades_ci "Duración de desempleo o búsqueda de empleo - Intervalos"
label define desocupado_int 1"Menos de un año" 2 "Entre 1 y 5 años"  3 "Entre 5 y 10 años"  
label values durades_ci_inter desocupado_int
*/

* Duración del desempleo en meses
* ea18_yearsmerge tiene la duración en años (con decimales, variable numérica con labels)
* Se necesita usar el valor numérico directamente

gen durades_ci = .
replace durades_ci = ea18_yearsmerge*12 if condocup_ci == 2 & ea18_yearsmerge < 999998

***********************************
* POBLACION ECONOMICAMENTE ACTIVA *
***********************************

gen byte pea_ci = .
replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
replace pea_ci = 0 if inlist(condocup_ci, 3, 4)
label var pea_ci "Población económicamente activa"

**********************
*  NÚMERO DE EMPLEOS *
**********************
* ea21: 1=Yes, 2=No (¿tiene trabajo adicional?)

gen byte nempleos_ci = .
replace nempleos_ci = 1 if emp_ci == 1 & ea21 == 2
replace nempleos_ci = 2 if emp_ci == 1 & ea21 == 1
replace nempleos_ci = . if emp_ci == 0

label var nempleos_ci "Numero de empleos"
label define nempleos_ci 1 "un trabajo" 2 "dos o mas trabajos"
label values nempleos_ci nempleos_ci

*****************************************
* ANTIGUEDAD EN LA ACTIVIDAD PRINCIPAL  *
*****************************************
* No hay variable de antigüedad en el empleo actual en 2024

gen antiguedad_ci=.
*gen antiguedad_ci=cq141 if cq141<99 & emp_ci==1
label var antiguedad_ci "Años de trabajo en la actividad principal"
***La variable  esta dividida como intervalos.
/*
gen antiguedad_ci_grupo=jobyears if jobyears<6 & emp_ci==1
label var antiguedad_ci_grupo "Años de trabajo en la actividad principal (intervalos)"
label define antiguedad 1"Entre 0 y 5 años" 2 "Entre 6 y 10 años" 3 "Entre 11 y 15 años"  4 "Entre 16 y 20 años" 5"Entre 21 y 25 años" 6"Más de 26 años", replace
label values antiguedad_ci_grupo antiguedad
*/

****************
* DESALENTADOS *
****************
* Desalentado: inactivo que no busca trabajo por razones de mercado
* ea12: 13=No suitable work, 14=No resources, 16=Tired of looking
gen byte desalent_ci = .
replace desalent_ci = 1 if condocup_ci == 3 & inlist(ea12, 13, 14, 16)
replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .

label var desalent_ci "Trabajadores desalentados, personas que creen que por alguna razon no conseguiran trabajo" 

****************************************************
* TRABAJA MENOS DE 30 HORAS Y NO DESEA TRABAJAR MAS*
****************************************************
* MGD 08/29/2014: no hay la pregunta de si desea trabajar mas horas, pero se utiliza disponibilidad para otro trabajo.

gen byte tiempoparc_ci = .
replace tiempoparc_ci = 1 if total_hrs_last_week < 30 & total_hrs_last_week != . & emp_ci == 1
replace tiempoparc_ci = 0 if total_hrs_last_week >= 30 & total_hrs_last_week != . & emp_ci == 1

label var tiempoparc_ci "Trabaja menos de 30 horas"

**# Bookmark #2

*********************************
* CATEGORIA OCUPACION PRINCIPAL *
*********************************
* ea25: 1=Self-employed w/employees, 2=Self-employed w/o employees,
*       3=Employee(Govt), 4=Employee(NGO), 5=Employee(Intl Org),
*       6=Contributing family worker, 7=Domestic worker, 8=Employee(Private), 9=Apprentice
	
gen byte categopri_ci = .
replace categopri_ci = 1 if ea25 == 1 & emp_ci == 1
replace categopri_ci = 2 if ea25 == 2 & emp_ci == 1
replace categopri_ci = 3 if inlist(ea25, 3, 4, 5, 7, 8, 9) & emp_ci == 1
replace categopri_ci = 4 if ea25 == 6 & emp_ci == 1
label var categopri_ci "Categoría ocupación principal"
label define categopri 0 "Otros" 1 "Patrón o empleador" 2 "Cuenta propia o independiente" 3 "Empleado o asalariado" 4 "Trabajador no remunerado"
label values categopri_ci categopri


*********************************
* CATEGORIA OCUPACION SECUNDARIA*
*********************************
* No hay información detallada de empleo secundario en 2024

gen byte categosec_ci = .
	
/*
gen categosec_ci=.

replace categosec_ci=0 if catother==1 & condocup_ci==1
replace categosec_ci=3 if (catother==2 | catother==3 ) & condocup_ci==1
replace categosec_ci=4 if catother==4 & condocup_ci==1
label var categosec_ci "Categoría ocupación secundaria"
label define categosec  0 "Otros" 1"Patrón o empleador" 2"Cuenta propia o independiente" 3"Empleado o asalariado" 4"Trabajador no remunerado"  
label values categosec_ci categosec 
*/


*********************************
*  RAMA DE ACTIVIDAD PRINCIPAL  *
*********************************
*** MGD 08/29/2014: CIIU REV. 3

*Para 2024:
*bcea_main_industry: 1=Agriculture, 2=Aquaculture, 3=Forestry, 4=Mining,
*   5=Manufacturing, 6=Electricity/Gas/Water, 7=Construction,
*   8=Wholesale/Retail, 9=Tourism, 10=Transport, 11=Financial,
*   12=Real Estate, 13=Govt Services, 14=Community/Social/Personal, 9999=DK
gen byte rama_ci = .
replace rama_ci = 1 if inlist(bcea_main_industry, 1, 2, 3) & emp_ci == 1
replace rama_ci = 2 if bcea_main_industry == 4 & emp_ci == 1
replace rama_ci = 3 if bcea_main_industry == 5 & emp_ci == 1
replace rama_ci = 4 if bcea_main_industry == 6 & emp_ci == 1
replace rama_ci = 5 if bcea_main_industry == 7 & emp_ci == 1
replace rama_ci = 6 if inlist(bcea_main_industry, 8, 9) & emp_ci == 1
replace rama_ci = 7 if bcea_main_industry == 10 & emp_ci == 1
replace rama_ci = 8 if inlist(bcea_main_industry, 11, 12) & emp_ci == 1
replace rama_ci = 9 if inlist(bcea_main_industry, 13, 14) & emp_ci == 1
label define rama_ci 1"Agricultura, caza, silvicultura o pesca" 2"Minas y Canteras" 3"Manufactura" 4"Electricidad, gas o agua" 5"Construcción" 6"Comercio al por mayor, restaurantes o hoteles" 7"Transporte o almacenamiento" 8"Establecimientos financieros, seguros o bienes inmuebles" 9"Servicios sociales, comunales o personales" 
label values rama_ci rama_ci

* rama secundaria
* No hay información detallada de empleo secundario en 2024
/*
gen ramasec_ci=.
replace ramasec_ci=1 if (EA21_6new<=3) & emp_ci==1 /* indmisic for 2004 */
replace ramasec_ci=2 if (EA21_6new==4) & emp_ci==1
replace ramasec_ci=3 if (EA21_6new==5) & emp_ci==1
replace ramasec_ci=4 if (EA21_6new==6) & emp_ci==1
replace ramasec_ci=5 if (EA21_6new==7) & emp_ci==1
replace ramasec_ci=6 if (EA21_6new==8 | EA21_6new==9) & emp_ci==1
replace ramasec_ci=7 if (EA21_6new==10 ) & emp_ci==1
replace ramasec_ci=8 if (EA21_6new==11 | EA21_6new==12) & emp_ci==1
replace ramasec_ci=9 if (EA21_6new==13 | EA21_6new==14) & emp_ci==1
label define ramasec_ci 1"Agricultura, caza, silvicultura o pesca" 2"Minas y Canteras" 3"Manufactura" 4"Electricidad, gas o agua" 5"Construcción" 6"Comercio al por mayor, restaurantes o hoteles" 7"Transporte o almacenamiento" 8"Establecimientos financieros, seguros o bienes inmuebles" 9"Servicios sociales, comunales o personales" 
label values ramasec_ci ramasec_ci
*/

*********************************
*  TRABAJA EN EL SECTOR PUBLICO *
*********************************

gen byte spublico_ci = .
replace spublico_ci = 1 if ea25 == 3 & emp_ci == 1
replace spublico_ci = 0 if ea25 != 3 & ea25 != . & emp_ci == 1
label var spublico_ci "Personas que trabajan en el sector publico"

********************
* TAMAÑO DE EMPRESA*
********************
* MYN 08/16/2023: esta variable no esta incluida en la base (pero si esta en el cuestionario - )
* No hay variable de tamaño de empresa en 2024

g tamemp_ci=.
/*
gen tamemp_ci=1 if cq129y==1
label var  tamemp_ci "Tamaño de Empresa" 
*Empresas medianas
replace tamemp_ci=2 if cq129y==2 | cq129y==3
*Empresas grandes
replace tamemp_ci=3 if cq129y==4
label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
label values tamemp_ci tamaño
*/

*********************************
*  COTIZA A LA SEGURIDAD SOCIAL *
*********************************
* MGD 09/02/2014: no hay variable de cotizacion en la encuesta LFS. 
* No hay variable de de cotizacion en 2024

gen cotizando_ci=.
/*replace cotizando_ci=1 if q432==1
replace cotizando_ci=0 if q432==2
label var cotizando_ci "Cotizando a la seguridad social"
*/

****************************************************
*  INSTITUCION DE SEGURIDAD SOCIAL A LA QUE COTIZA *
****************************************************
* No hay información sobre afiliación a seguridad social

gen inscot_ci=.
label var inscot_ci "Institución de seguridad social a la que cotiza"

**********************************
* AFILIADO A LA SEGURIDAD SOCIAL *
**********************************
* MGD 09/02/2014: no hay variable de afiliacion en la encuesta LFS.
* No hay información sobre afiliación a seguridad social en 2024

gen afiliado_ci=.
/*replace afiliado_ci=1 if q429==1
replace afiliado_ci=0 if q429==2
label var afiliado_ci "Afiliado a la seguridad social"
*/

g pension_ci=.
g tipopen_ci=.

*********************
* TRABAJADOR FORMAL *
*********************
* MGD 09/02/2014: no hay variable de afiliacion en la encuesta LFS.
* informalemp: 0=formal, 100=Informally employed
	
gen byte formal_ci = .
replace formal_ci = 1 if informalemp == 0 & condocup_ci == 1
replace formal_ci = 0 if informalemp == 100 & condocup_ci == 1
	
/*	
gen formal_ci=.
g formal_1=.
replace formal_ci=0 if condocup_ci==1 & afiliado_ci==0 & cotizando_ci==0
replace formal_ci=1 if condocup_ci==1 & (afiliado_ci==1 | cotizando_ci==1)
*/

********************
* TIPO DE CONTRATO *
********************
* MGD 09/02/2014: no hay informacion de tipo de contrato en LFS
* No hay información sobre tipo de contrato en 2024

gen tipocontrato_ci=. 
/*replace tipocontrato_ci=3 if q426==2 | (q426==1 & q427==2)
label var tipocontrato_ci "Tipo de contrato"
label define tipocontrato 1"Permanente / Indefinido" 2"Temporal / Tiempo definido" 3"Sin contrato / Verbal"  
label values tipocontrato_ci tipocontrato
*/

*****************************
* TIPO DE OCUPACION LABORAL *
*****************************
* MGD 09/02/2014: CIUO-88
* Para 2024:
* ea23main_occ: 0=Armed Forces, 1=Managers, 2=Professionals, 3=Technicians,
	*   4=Clerical, 5=Services/Sales, 6=Skilled Agri, 7=Craft, 8=Plant/Machine,
	*   9=Elementary, 99=DK/NS
* La clasificación ahora tiene 8 categorías y no 9 porque "5=Services/Sales" está agrupado en una sola

gen byte ocupa_ci = .
replace ocupa_ci = 1 if inlist(ea23main_occ, 2, 3) & emp_ci == 1
replace ocupa_ci = 2 if ea23main_occ == 1 & emp_ci == 1
replace ocupa_ci = 3 if ea23main_occ == 4 & emp_ci == 1
replace ocupa_ci = 4 if ea23main_occ == 5 & emp_ci == 1
replace ocupa_ci = 5 if ea23main_occ == 6 & emp_ci == 1
replace ocupa_ci = 6 if inlist(ea23main_occ, 7, 8) & emp_ci == 1
replace ocupa_ci = 7 if ea23main_occ == 0 & emp_ci == 1
replace ocupa_ci = 8 if ea23main_occ == 9 & emp_ci == 1
label var ocupa_ci "Tipo de ocupacion laboral"
label define ocupa 0 "Otros" 1"Profesional o técnico" 2"Director o funcionario superior" 3"Personal administrativo o nivel intermedio" 4"Comerciante o vendedor y trabajador en servicios" 5"Trabajador agrícola o afines" 6"Obrero no agrícola, conductores de máquinas y vehículos de transporte y similares" 7"Fuerzas armadas" 8"Otras ocupaciones no clasificadas"
label values ocupa_ci ocupa

/*
gen ocupa_ci=.
replace ocupa_ci=1 if (cq130m>=2000 & cq130m<=3999) & emp_ci==1
replace ocupa_ci=2 if (cq130m>=1000 & cq130m<=1999) & emp_ci==1
replace ocupa_ci=3 if (cq130m>=4000 & cq130m<=4999) & emp_ci==1
replace ocupa_ci=4 if ((cq130m>=5200 & cq130m<=5999) | (cq130m>=9111 & cq130m<=9113)) & emp_ci==1
replace ocupa_ci=5 if ((cq130m>=5000 & cq130m<=5199) | (cq130m>=9120 & cq130m<=9162)) & emp_ci==1
replace ocupa_ci=6 if ((cq130m>=6000 & cq130m<=6999) | (cq130m>=9200 & cq130m<=9213)) & emp_ci==1
replace ocupa_ci=7 if ((cq130m>=7000 & cq130m<=8999) | (cq130m>=9300 & cq130m<=9333))& emp_ci==1
replace ocupa_ci=8 if (cq130m>=0 & cq130m<=999)  & emp_ci==1
replace ocupa_ci=9 if (cq130m==9119 | cq130m==9999) & emp_ci==1
label var ocupa_ci "Tipo de ocupacion laboral"
label define ocupa 1"Profesional o técnico" 2"Director o funcionario superior" 3"Personal administrativo o nivel intermedio" 4"Comerciante o vendedor" 5"Trabajador en servicios" 6"Trabajador agrícola o afines" 7"Obrero no agrícola, conductores de máquinas y vehículos de transporte y similares" 8"Fuerzas armadas" 9"Otras ocupaciones no clasificadas"
label values ocupa_ci ocupa
*/

**********************************************
* HORAS TRABAJADAS EN LA ACTIVIDAD PRINCIPAL *
**********************************************

/*
replace horaspri_ci=cq132m if cq132m!=99
*/

gen double horaspri_ci = total_hrs_last_week if emp_ci == 1
label var horaspri_ci "Horas trabajadas en la actividad principal"

**************************
* TOTAL HORAS TRABAJADAS *
**************************
*gen horastot_ci=EA22_3new
*replace horastot_ci=. if EA22_3new==999

gen double horastot_ci = total_hrs_last_week if emp_ci == 1

label var horastot_ci "Total horas trabajadas"

***********************************************
* RECIBE PENSION O JUBILACION NO CONTRIBUTIVA *
***********************************************
gen pensionsub_ci=.
*replace pensionsub_ci=1 if
label var pensionsub_ci "Recibe pensión o ubilación NO contributiva"


************************************************
*INSTITUCION QUE OTORGA LA PENSION O JUBILACION*
************************************************
gen instpen_ci=.
label var instpen_ci "Institución que otorga la pensión o jubilación"


*******************************
*******************************
*******************************
*     VARIABLES DE INGRESO    *
*******************************
*******************************
*******************************


*************************************
* DUMMIES DE INDIVIDUO Y HOGAR *
*************************************
* Se van a crear pero no se usan para 2024

*** Dummy Individual si no reporta el ingreso laboral monetario de la actividad principal
gen byte nrylmpri_ci=0
replace nrylmpri_ci=1 if emp_ci==1 & income_month==.
label var nrylmpri_ci "Identificador de No Respuesta del Ingreso Monetario de la Actividad Principal"

*** Dummy para el Hogar
capture drop nrylmpri_ch
sort idh
egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, by(idh_ch)
replace nrylmpri_ch=1 if nrylmpri_ch>1 & nrylmpri_ch~=. & miembros_ci==1 
label var nrylmpri_ch "Identificador de Hogares en donde alguno de los miembros No Responde el Ingreso Monetario de la Actividad Principal"


*************************************
* INGRESO MONETARIO MENSUAL LABORAL *
*************************************
* income_month: ingreso mensual reportado (variable numérica continua)
generate double ylmpri_ci = income_month if emp_ci == 1

label var ylmpri_ci "Monto mensual de ingreso laboral de la actividad principal"

/*
gen income=.
replace income= (119/2) if cq142==1
replace income= (120+239)/2 if cq142==2
replace income= ((240+359)/2) if cq142==3
replace income= ((360+479)/2) if cq142==4
replace income= ((480+599)/2) if cq142==5
replace income= ((600+719)/2) if cq142==6
replace income= ((720+839)/2) if cq142==7
replace income= ((840+959)/2) if cq142==8
replace income= ((960+1079)/2) if cq142==9
replace income= ((1080+1199)/2) if cq142==10
replace income= ((1200+1319)/2) if cq142==11
replace income= ((1320+1439)/2) if cq142==12
replace income= ((1440+1559)/2) if cq142==13
replace income= ((1560+1679)/2) if cq142==14
replace income= ((1680+1799)/2) if cq142==15
replace income= ((1800+1919)/2) if cq142==16
replace income= ((1920+2039)/2) if cq142==17
replace income= ((2040+2159)/2) if cq142==18
replace income= ((2160+2279)/2) if cq142==19
replace income= ((2280+2399)/2) if cq142==20
replace income= ((2400+2519)/2) if cq142==21
replace income= ((2520+2639)/2) if cq142==22
replace income= ((2640+2759)/2) if cq142==23
replace income= ((2760+2879)/2) if cq142==24
replace income= ((2880+2999)/2) if cq142==25

gen ylmpri_ci=.
replace ylmpri_ci=income*30 if cq143==1
replace ylmpri_ci= income*4.3 if cq143==2
replace ylmpri_ci= income*2 if cq143==3
replace ylmpri_ci= income if cq143==4 | cq143==8
replace ylmpri_ci= income/12 if cq143==5
replace ylmpri_ci= 0 if cq143==6 | cq143==9*/

*******************************
* INGRESO MENSUAL NO MONETARIO*
*******************************
gen ylnmpri_ci=.
label var ylnmpri_ci "Monto mensual de ingreso NO monetario de la actividad principal"

*************************************************
* INGRESO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
*************************************************
* No hay información de ingresos del empleo secundario

gen ylmsec_ci=.
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
gen double ylm_ci = ylmpri_ci 

*************************************************
* INGRESO MENSUAL NO MONETARIO TODAS ACTIVIDADES*
*************************************************
gen ylnm_ci= .
label var ylnm_ci "Ingreso mensual NO monetario todas actividades"

*************************************************
* INGRESO MENSUAL NO LABORAL OTRAS ACTIVIDADES  *
*************************************************
gen ynlm_ci=. 
label var ylnm_ci "Ingreso mensual NO laboral otras actividades"

**************************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO OTRAS ACTIVIDADES  *
**************************************************************
gen ynlnm_ci= .
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

label var ylnm_ci "Ingreso mensual NO laboral NO monetario otras actividades"

************************************
* INGRESO MENSUAL LABORAL DEL HOGAR*
************************************
*gen ylm_ch=.
bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi
label var ylm_ch "Ingreso Laboral Monetario del Hogar (Bruto)"

**************************************************
* INGRESO MENSUAL LABORAL NO MONETARIO DEL HOGAR *
**************************************************
gen ylnm_ch=.
label var ylnm_ch "Ingreso Laboral No Monetario del Hogar"

**************************************************************
* INGRESO MENSUAL NO LABORAL OTRAS ACTIVIDADES no respuesta  *
**************************************************************
gen ylmnr_ch=.
label var ylmnr_ch "Ingreso Laboral Monetario del Hogar, considera 'missing' la No Respuesta"

**************************************************
* INGRESO MENSUAL NO LABORAL MONETARIO DEL HOGAR *
**************************************************
gen ynlm_ch=.
label var ynlm_ch "Ingreso No Laboral Monetario del Hogar"

*****************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO DEL HOGAR *
*****************************************************
gen ynlnm_ch=.
label var ynlnm_ch "Ingreso No Laboral No Monetario del Hogar"

*****************************************************
* INGRESO LABORAL POR HORA EN LA ACTIVIDAD PRINCIPA *
*****************************************************
* income_month es mensual, horaspri_ci es semanal -> ingreso por hora = mensual / (horas * 4.33)
* 4.33 es factor para convertir de meses a semanas  
gen double ylmhopri_ci = ylmpri_ci/(horaspri_ci*4.33) if emp_ci == 1 & horaspri_ci > 0

*gen ylmhopri_ci=.

label var ylmhopri_ci "Salario horario monetario de la actividad principal"

*****************************************************
* INGRESO LABORAL POR HORA EN TODAS LAS ACTIVIDADES *
*****************************************************

gen double ylmho_ci = ylm_ci/(horastot_ci*4.33) if emp_ci == 1 & horastot_ci > 0

*gen ylmho_ci=.
label var ylmho_ci "Salario horario monetario de todas las actividades"

************************************************
* RENTA MENSUAL IMPUTADA DE LA VIVIENDA PROPIA *
************************************************
gen rentaimp_ch=.
label var rentaimp_ch "Renta imputada de la vivienda propia"

*********************************************************
* MONTO MENSUAL DE INGRESO POR AUTOCONSUMO DEL INDIVIDUO*
*********************************************************
gen autocons_ci=.
label var autocons_ci "Monto mensual de ingreso por autoconsumo individuo"

*****************************************************
* MONTO MENSUAL DE INGRESO POR AUTOCONSUMO DEL HOGAR*
*****************************************************
gen autocons_ch=.
label var autocons_ch "Autoconsumo del Hogar"

***************************
* REMESES EN MONEDA LOCAL *
***************************
gen remesas_ci=.
label var remesas_ci "Remesas en moneda local"

************************************
* REMESES EN MONEDA LOCAL DEL HOGAR*
************************************
by idh_ch: gen remesas_ch=.
label var remesas_ch "Remesas en moneda local"

************************************
* INGRESO POR PENSION CONTRIBUTIVA *
************************************
gen ypen_ci=.
label var ypen_ci "Ingreso por pensionc contributiva"

***************************************
* INGRESO POR PENSION NO CONTRIBUTIVA *
***************************************
gen ypensub_ci=.
label var ypensub_ci "Ingreso por pensionc NO contributiva"

********************************
* SALARIO MINIMO MENSUAL LEGAL *
********************************
* MYN Fuente: https://datosmacro.expansion.com/smi/belice 
* Se actualiza el dato con la misma fuente de 2018 y se especifica que el monto está en dólares beliceños

gen salmm_ci =1039.2
label var salmm_ci "salario mínimo mensual legal"

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


*******************************
*******************************
*******************************
*    VARIABLES DE EDUCACION   *
*******************************
*******************************
*******************************

*************
** aedu_ci **
*************
/*
MGD 09/09/2014: Clasificacion de añ de educacion en BLZ.  
	
Se toma como referencia:
	
	- Primary Primary School - 8 years
	- Secondary CSEC (Caribbean Secondary Education Certificate) Examinations - 4 years
	- Post-secondary CXC Caribbean Advanced Placement Examination (CAPE)- 2 years (para quienes no culminaron la secundaria)   
	- Tertiary University  

La ultima categoria es mas de dos años de universidad y se asumen 16 completos.

Segun la clasificacion de la UNESCO 6 anos en belice corresponden a primaria, aunque en belice primaria sean 8
	
*/

/*
MAMB 06/04/2026: 

Para el nivel vocacional la equivalencia es entre secundaria y terciaria. Según años de escolaridad quedaría así: 

Pre-vocational -> secundaria baja (9 años) - equivalente o preparatorio para el primer ciclo de secundaria
Nivel 1 -> secundaria alta (10 años)
Nivel 2 -> secundaria alta (11 años) - equivale a terminar la secundaria
Nivel 3 -> Terciaria (12 años) - equivale a especialización técnica

*/

/*
gen aedu_ci = .

replace aedu_ci = ed5 	if ed5<=12
replace aedu_ci = 14		if ED5New==13
replace aedu_ci = 16		if ED5New==14 //4 years of bachelor (Tha programs last between 2/4 years)
replace aedu_ci = 18		if ED5New==15 //2 years of Masters 
replace aedu_ci = 0 		if ED5New==17 | ED5New==18
*/

gen aedu_ci = .

* Nunca asistió / None
replace aedu_ci = 0 if ed5 == 22  // Never Attended
replace aedu_ci = 0 if ed5 == 21  // None

* Nivel Primario (Infant 1=1, Infant 2=2, Standard 1-6 = 3-8 años)
replace aedu_ci = 1 if ed5 == 1   // Infant 1
replace aedu_ci = 2 if ed5 == 2   // Infant 2
replace aedu_ci = 3 if ed5 == 3   // Standard 1
replace aedu_ci = 4 if ed5 == 4   // Standard 2
replace aedu_ci = 5 if ed5 == 5   // Standard 3
replace aedu_ci = 6 if ed5 == 6   // Standard 4
replace aedu_ci = 7 if ed5 == 7   // Standard 5
replace aedu_ci = 8 if ed5 == 8   // Standard 6

* Nivel Secundario (1st-4th Form = 9-12 años)
replace aedu_ci = 9  if ed5 == 9  // 1st Form
replace aedu_ci = 10 if ed5 == 10 // 2nd Form
replace aedu_ci = 11 if ed5 == 11 // 3rd Form
replace aedu_ci = 12 if ed5 == 12 // 4th Form

* Vocacional (se asimila a secundaria)
replace aedu_ci = 9  if ed5 == 13 // Pre vocational
replace aedu_ci = 10 if ed5 == 14 // Level 1 vocational
replace aedu_ci = 11 if ed5 == 15 // Level 2 vocational


* Nivel Terciario
replace aedu_ci = 12 if ed5 == 16 // Level 3 vocational (Se asimila como terciaria)
replace aedu_ci = 14 if ed5 == 17 // Associate/6th Form Junior College
replace aedu_ci = 16 if ed5 == 18 // Bachelors
replace aedu_ci = 18 if ed5 == 19 // Master's or Higher
	

label var aedu_ci "número de años de educación culminados"


**************
** eduui_ci **
**************
// NO se identifica estudios no universitarios.
gen byte eduui_ci = .
replace eduui_ci = 1 if aedu_ci >= 12 & aedu_ci < 16 & aedu_ci != .
replace eduui_ci = 0 if (aedu_ci < 12 | aedu_ci >= 16) & aedu_ci != .
replace eduui_ci = . if aedu_ci == .
label var eduui_ci "No ha completado la educación terciaria"

**************
** eduuc_ci **
**************
gen byte eduuc_ci = .
replace eduuc_ci = 1 if aedu_ci >= 16 & aedu_ci != .
replace eduuc_ci = 0 if aedu_ci < 16 & aedu_ci != .
replace eduuc_ci = . if aedu_ci == .
label var eduuc_ci "Ha completado la educación terciaria"

***************
** edupre_ci **
***************
gen edupre_ci = .
label var edupre_ci "Ha completado educación preescolar"

***************
** asispre_ci **
***************
gen asispre_ci = . 
label var asispre_ci "Ha completado educación preescolar"

**************
** eduac_ci **
**************
// No se distingue entre universitario y no universitario
gen eduac_ci=.
label var eduac_ci "Ha completado educación terciaria académica"

***********
*asiste_ci*
***********
gen byte asiste_ci = .
replace asiste_ci = 1 if ed3new == 1
replace asiste_ci = 0 if ed3new == 2

/*
replace asiste_ci = 1 if ((cq16 == 1 | cq16 == 2) & cq13 > 14) | ((q51 == 1 | q51 == 2) & cq13 <= 14)
replace asiste_ci = 0 if (cq16 == 3  & cq13 > 14) |  (q51 == 3  & cq13 <= 14)
label var asiste_ci "Asiste a algún centro de enseñanza"
*/

*************
*pqnoasis1_ci*
**************
* ed6: razón de no asistencia
* 1=Too young, 2=Financial, 3=Working, 4=Domestic, 6=Illness, 7=Not interested

gen byte pqnoasis1_ci = .
replace pqnoasis1_ci = 1 if ed6 == 2
replace pqnoasis1_ci = 2 if ed6 == 7
replace pqnoasis1_ci = 3 if ed6 == 3 | ed6 == 4
replace pqnoasis1_ci = 4 if ed6 == 6
replace pqnoasis1_ci = 5 if ed6 == 1 | ed6 == 888888

***********
*edupub_ci*
***********
* No hay información sobre tipo de institución educativa (pública/privada)
gen byte edupub_ci = .


*******************************
*******************************
*******************************
*    VARIABLES DE VIVIENDA    *
*******************************
*******************************
*******************************


***********
*aguared_ch*
***********
* hh7: 1=Public piped dwelling, 2=Public piped yard, 3=Private piped,
*      4=Standpipe, 6=Protected well, 7=Unprotected well,
*      8=Private catchment, 9=River/Creek

gen byte aguared_ch = .
replace aguared_ch = 1 if inlist(hh7, 1, 2, 3, 4)
replace aguared_ch = 0 if inlist(hh7, 6, 7, 8, 9)

***********
*aguafconsumo_ch*
***********
* hh8: Household main source of drinking water
*      1=Bottled, 2=Public piped, 3=Private piped, 4=Standpipe,
*      5=Protected well, 6=Unprotected well, 7=Private catchment, 8=River

gen byte aguafconsumo_ch = .
replace aguafconsumo_ch = 1 if hh8 == 2
replace aguafconsumo_ch = 2 if hh8 == 3
replace aguafconsumo_ch = 3 if hh8 == 4
replace aguafconsumo_ch = 4 if hh8 == 5
replace aguafconsumo_ch = 5 if hh8 == 6
replace aguafconsumo_ch = 6 if hh8 == 7
replace aguafconsumo_ch = 7 if hh8 == 8
replace aguafconsumo_ch = 8 if hh8 == 1
replace aguafconsumo_ch = 9 if hh8 == 888888
replace aguafconsumo_ch = 10 if hh8 == 999999

*********************
gen aguafuente_ch =.
/*
replace aguafuente_ch= 1 if h8==1 | h8==2 | h71==1 | h72==1
replace aguafuente_ch= 3 if h8==6 | h76==1
replace aguafuente_ch= 4 if h8==4 | h74==1
replace aguafuente_ch= 7 if h8==3 | h73==1
replace aguafuente_ch= 8 if h8==7 | h77==1
replace aguafuente_ch= 9 if h8==5 | h75==1
replace aguafuente_ch= 10 if h8==8 | h78==1
replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1
*/

*********************

gen aguadist_ch=0

*********************
gen aguadisp1_ch = 9

*********************
gen aguadisp2_ch = 9

*********************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10
*label var aguamala_ch "= 1 si la fuente de agua no es mejorada"
*********************


gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7
*label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"

*********************
gen aguamide_ch = .
*********************

******************************
* Tipo de conexión a desagüe *
******************************
*  hh4a: 1 Water closet linked to BWS sewer system,
*		 2 Water closet linked to septic tank 
*        3 Pit latrine, ventilated and elevated 
*        4 Pit latrine, ventilated and not elevated
*        5 Pit latrine, elevated and not ventilated
*        6 Pit latrine, not ventilated and not elev  
*        7 None
*        8 Other
 
gen bano_ch=.
replace bano_ch=0 if  hh4a == 7
replace bano_ch=1 if  hh4a == 1
replace bano_ch=2 if  hh4a == 2
replace bano_ch=3 if  inlist(hh4a, 3, 4)
replace bano_ch=5 if  inlist(hh4a, 5, 6)
replace bano_ch=6 if  hh4a >= 888888 & hh4a < 999999

label define bano_ch_lbl ///
    0 "Sin instalaciones" ///
    1 "Inodoro a red de desagüe" ///
    2 "Inodoro a fosa séptica" ///
    3 "Letrina mejorada / otra instalación mejorada" ///
    4 "Inodoro/letrina a cuerpo de agua superficial o suelo" ///
    5 "Instalación no mejorada" ///
    6 "Instalación que no se puede clasificar"

label values bano_ch bano_ch_lbl
label variable bano_ch "Tipo de instalación sanitaria"

*********************
* Baño exclusivo 
*********************
* hh4b: 1=Yes (compartido), 2=No
gen byte banoex_ch = .
replace banoex_ch = 0 if hh4b == 2
replace banoex_ch = 1 if hh4b == 1

********************
** banomejorado_ch 
********************

gen byte banomejorado_ch = 2
replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6

*****************
** sinbano_ch **
*****************

gen byte sinbano_ch = .
replace sinbano_ch = 0 if bano_ch > 0 & bano_ch != .
replace sinbano_ch = 1 if bano_ch == 0
replace sinbano_ch = 3 if bano_ch == .

******************
* aguatrat_ch 
*****************
* Si el agua de consumo es embotellada/purificada = tratamiento

gen byte aguatrat_ch = .
replace aguatrat_ch = 1 if hh8 == 1
replace aguatrat_ch = 0 if hh8 != 1 & hh8 != . & hh8 < 999999

*****************************
*  ILUMINACION ES ELÉCTRICA *
*****************************
* hh5: 1=BEL, 2=Other source, 5=Gas/Kerosene, 6=Candle, 8=None

gen byte luz_ch = .
replace luz_ch = 1 if inlist(hh5, 1, 2)
replace luz_ch = 0 if inlist(hh5, 5, 6, 8)

/*
replace luz_ch=1 if h4<=3
replace luz_ch=0 if h4>3 & h4!=9
*/
label var luz_ch "La iluminación del hogar es eléctrica"

************************
*  USA MEDIDOR DE LUZ  *
************************
* BEL (Belize Electricity Limited) tiene medidores

gen byte luzmide_ch = .
replace luzmide_ch = 1 if hh5 == 1
replace luzmide_ch = 0 if hh5 == 2 & luz_ch == 1
	
*replace luzmide_ch=1 if
label var luzmide_ch "Usa medidor de luz para pagar por su consumo"

********************************************
*  USA COMBUSTIBLE COMO FUENTE DE ENERGIA  *
********************************************
* hh6: 1=Gas, 2=Wood/charcoal, 3=Kerosene, 4=Electricity, 5=Does not cook
gen byte combust_ch = .
replace combust_ch = 1 if inlist(hh6, 1, 4)
replace combust_ch = 0 if inlist(hh6, 2, 3)
label var combust_ch "Usa combustible como fuente de energía"

*******************************************
*  TIPO DE DESAGÜE incluyendo Unimproved  *
*******************************************
gen des1_ch=.
/*
replace des1_ch=0 if h3==8
replace des1_ch=1 if h3==1
replace des1_ch=2 if h3==2
replace des1_ch=3 if h3>=3 & h3<=6
*/
label var des1_ch "Tipo de desague incluyendo Unimproved"
label define des1 0"El hogar no tiene servicio higienico" 1"Desagüe conectado a la red general" 2"Desagüe conectado a un pozo o letrina" 3"El desagüe se comunica con la superficie"
label values des1_ch des1

*******************************************
* TIPO DE DESAGÜE sin incluir Unimproved  *
*******************************************
gen des2_ch=.
/*
replace des1_ch=0 if h3==8
replace des1_ch=1 if h3==1
replace des1_ch=2 if h3>=2 & h3<=7
*/
label var des2_ch "Tipo de desague sin incluir Unimproved"
label define des2 0"El hogar no tiene servicio higienico" 1"Desagüe conectado a la red general" 2"Resto de alternativas"
label values des2_ch des2

**********************************
* MATERIAL PREDOMINANTE DEL PISO *
**********************************
* hh11: 1=Earth/Sand, 2=Wood planks, 3=Plywood, 4=Parquet, 5=Vinyl,
*       6=Ceramic tiles, 7=Cement/Concrete, 8=Carpet

gen byte piso_ch = .
replace piso_ch = 0 if hh11 == 1
replace piso_ch = 1 if inlist(hh11, 2, 3, 7)
replace piso_ch = 2 if inlist(hh11, 4, 5, 6, 8)

label var piso_ch "Material predominante del piso"
label define piso 0"No permanentes/Tierra" 1"Permanentes: Cemento, cerámica, mosaico, madera" 2"Otros materiales"
label values piso_ch piso

****************************************
* MATERIAL PREDOMINANTE DE LAS PAREDES *
****************************************
* hh10: 1=No Walls, 2=Cane/Palm, 3=Palmetto, 4=Bamboo, 5=Stone w/mud,
	*       6=Plywood, 7=Cardboard, 8=Reused wood, 9=Cement/Concrete,
	*       10=Stone w/lime, 11=Bricks, 12=Cement blocks, 13=Wood planks,
	*       14=Wood and concrete, 15=Stucco

gen byte pared_ch = .
replace pared_ch = 0 if inlist(hh10, 1, 2, 3, 4, 7, 8)
replace pared_ch = 1 if inlist(hh10, 9, 10, 11, 12, 13, 14, 15)
replace pared_ch = 2 if inlist(hh10, 5, 6, 888888)

label var pared_ch "Material predominante de las paredes"
label define pared_ch 0"No permanentes/naturales o desechos" 1"Permanentes: ladrillo, madera, prefabricado, zinc, cemento" 2"Otros materiales"
label values pared_ch pared_ch

***********************************
* MATERIAL PREDOMINANTE DEL TECHO *
***********************************
* hh9: 1=Sheet Metal, 2=Shingle(asphalt), 3=Shingle(Wood), 5=Concrete,
*      8=Thatch, 9=Makeshift

gen byte techo_ch = .
replace techo_ch = 0 if inlist(hh9, 8, 9)
replace techo_ch = 1 if inlist(hh9, 1, 2, 3, 5)
replace techo_ch = 2 if hh9 == 888888

label var techo_ch "Material predominante del techo"
label define techo_ch 0"No permanentes/naturales o desechos" 1"Permanentes: lámina de metal o zinc, cemento o madera" 2"Otros materiales"
label values techo_ch techo_ch

*************************************
* MÉTODO DE ELIMINACION DE RESIDUOS *
*************************************
* MGD 09/02/2014: no hay variable en LFS
gen resid_ch=.
/*replace resid_ch=0 if q29==1 
replace resid_ch=1 if q29==4 | q29==5
replace resid_ch=2 if q29==2 | q29==3
replace resid_ch=3 if q29==6 | q29==7
label var resid_ch "Metodo de eliminacion de residuos"
label define resid 0"Recolección pública o privada" 1"Quemados o enterrados" 2"Tirados en un espacio abierto" 3"Otros"
label values resid_ch resid
*/

*****************************************
*  CANTIDAD DE DORMITORIOS EN EL HOGAR  *
*****************************************
* MGD 09/02/2014: no hay variable en LFS
* Para 2024:
* hh3: número de habitaciones para dormir (1-8, 999999=DK)

gen dorm_ch = hh3
replace dorm_ch = . if hh3 >= 999999
label var dorm_ch "Cantidad de dormitorios en el hogar"

*****************************************
*  CANTIDAD DE CUARTOS EN EL HOGAR  *
*****************************************
* MGD 09/02/2014: no hay variable en LFS
gen cuartos_ch=.
label var cuartos_ch "Cantidad de cuartos en el hogar"

**********************************
*  CUARTO EXCLUSIVO A LA COCINA  *
**********************************
* MGD 09/02/2014: no hay variable en LFS
gen cocina_ch=.

*label define cocina 1"Si" 2"No" 9"NS/NR"
*label values cocina_ch cocina
label var cocina_ch "Cuarto exclusivo a la cocina"

*************************
*  TIENE TELEFONO FIJO  *
*************************
* hh13b: 1=Yes, 2=No (teléfono fijo)
gen byte telef_ch = .
replace telef_ch = 1 if hh13b == 1
replace telef_ch = 0 if hh13b == 2

label var telef_ch "Tiene teléfono fijo"

***********************************
*  TIENE HELADERA O REFRIGERADOR  *
***********************************
* hh12b: 1=Yes, 2=No

gen byte refrig_ch = .
replace refrig_ch = 1 if hh12b == 1
replace refrig_ch = 0 if hh12b == 2

label var refrig_ch "Tiene heladera o refrigerador"

********************************
*  TIENE FREEZER O CONGELADOR  *
********************************

gen byte freez_ch = .
label var freez_ch "Tiene freezer o congelador"

*********************
*  TIENE AUTOMOVIL  *
*********************
* hh12q: 1=Yes, 2=No (vehículo a motor privado)

gen byte auto_ch = .
replace auto_ch = 1 if hh12q == 1
replace auto_ch = 0 if hh12q == 2
*replace auto_ch=1 if
label var auto_ch "Tiene automovil"

*********************
*  TIENE COMPUTADOR  *
*********************
* MAMB: la base de datos tiene un error de etiqueta. Las variables
* hh12m y hh12n hacen referencia a tenencia de computadora, posiblemente
* una de ellas sea laptop pero no se sabe

gen byte compu_ch = .

/*
replace compu_ch=1 if h62==1
replace compu_ch=0 if h62==2
*/
label var compu_ch "Tiene computador"

*******************************
*  TIENE CONEXION A INTERNET  *
*******************************
* hh13c

gen byte internet_ch = .
replace internet_ch = 1 if hh13c == 1
replace internet_ch = 0 if hh13c == 2

label var internet_ch "Tiene acceso a internet"

*******************
*  TIENE CELULAR  *
*******************
* hh12l: 1=Yes, 2=No (celular)

gen byte cel_ch = .
replace cel_ch = 1 if hh12l == 1
replace cel_ch = 0 if hh12l == 2

label var cel_ch "Tiene celular"

**********************
*  TIPO DE VIVIENDA  *
**********************
* MGD 09/02/2014: no hay variable.

* hh1: 1=Private house, 2=Apartment, 3=Duplex, 4=Barracks

gen byte vivi1_ch = .
replace vivi1_ch = 1 if hh1 == 1
replace vivi1_ch = 2 if inlist(hh1, 2, 3)
replace vivi1_ch = 3 if inlist(hh1, 4, 888888)

label define vivi1_ch 1"Casa" 2"Departamento" 3"Otro tipo"
label values vivi1_ch vivi1_ch

************************
*  CASA O DEPARTAMENTO *
************************
* MGD 09/02/2014: no hay variable.
gen vivi2_ch=.
/*replace vivi2_ch=1 if q11==1 | q11==2 | q11==4 | q11==3
replace vivi2_ch=0 if q11==5 | q11==6 | q11==7
label var vivi2_ch "Casa o departamento"
*/
********************
*  VIVIENDA PROPIA *
********************
* hh2: 1=Own/hire-purchase, 2=Lease, 3=Rent-Private, 4=Rent-Government, 5=Rent-free, 6=Squat

gen byte viviprop_ch = .
replace viviprop_ch = 0 if inlist(hh2, 3, 4)
replace viviprop_ch = 1 if hh2 == 1
replace viviprop_ch = 2 if hh2 == 2
replace viviprop_ch = 3 if inlist(hh2, 5, 6)
	
label var viviprop_ch "Vivienda propia"
label define viviprop 0"Arrendada" 1"Propia y totalmente pagada" 2 "Propia y en proceso de pago" 3 "Ocupada(propia de facto)" 4"Otra"
label values viviprop_ch viviprop

********************************
*  POSEE TITULO DE PROPIEDAD   *
********************************
* MGD 09/02/2014: no hay variable.
gen vivitit_ch=.
/*replace vivitit_ch=1 if q14==1
replace vivitit_ch=0 if q14==2
label var vivitit_ch "El hogar posee un título de propiedad"
*/
********************************
*  MONTO DE PAGO POR ALQUILER   *
********************************
gen vivialq_ch=.
label var vivialq_ch "Monto pagado por el alquiler"

***********************************
*  VALOR ESTIMADO DE LA VIVIENDA  *
***********************************
gen vivialqimp_ch=.
label var vivialqimp_ch "Monto ud cree le pagarían por su vivienda"

* Variables no generadas
g tcylmpri_ci=.
g tcylmpri_ch=.
g instcot_ci=.

	****************************
	***VARIABLES DE MIGRACIÓN***
	****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci= .
	replace migrante_ci=0 if ...
	replace migrante_ci=1 if ...
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.
	replace migrantiguo5_ci=0 if ...
	replace migrantiguo5_ci=1 if ...

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = .
	replace miglac_ci = 0 if ...
	replace miglac_ci = 1 if ...
	

	****************************
	***VARIABLES DE EXTERNAS***
	****************************	
	
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 
    replace tipo_bienestar  = 1  if …
    replace tipo_bienestar  = 2 if …


	****************
	 * pobre_ine_ci*
	****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if …
	replace pobre_ine_ci= 1 if …

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = …

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci = …
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = …
	

	/*_____________________________________________________________________________________________________*/

	* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
    * Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza

	/*_____________________________________________________________________________________________________*/
	

	do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

	
	/*_____________________________________________________________________________________________________*/
	* Verificación de que se encuentren todas las variables armonizadas 
	/*_____________________________________________________________________________________________________*/
	
	
      order region_BID_c region_c pais_c anio_c mes_c zona_c idh_ch idp_ci factor_ci factor_ch estrato_ci upm_ci /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad
	  /// Agregar aquí: ISO3pais_dis_ci (renombrar con código del país, ej. COL_dis_ci)
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	/// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci /// Ingresos individuo
     ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch   ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




saveold "`base_out'", version(12) replace

cap log close
