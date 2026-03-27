clear
set more off
'
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
                 BASES DE DATOS DE ENCUESTA DE HOGARES
País: Barbados
Encuesta: BSLC 2023
Round: 
Autores: Ricardo Sierra  ricardo.sierra@gmail.com
Modificación 2026: Oscar Jaramillo oscarj@iadb.org
Última modificación:

****************************************************************************/
***************************************************************************
****************************************************************************/
import spss using "Y:\survey\BRB\BSLC\2023\a\data_orig\LFW2023.SAV"





*******************************
* VARIABLES DE IDENTIFICACIÓN *
*******************************
gen region_BID_c = 2
label var region_BID_c "Region BID"
label define region_BID 1"Centroamérica" 2"Caribe" 3"Andinos" 4"Cono Sur"
label values region_BID_c region_BID

***************
* REGION PAIS *
***************
g region_c=.

***********
*  PAIS   *
***********
gen pais_c="BRB"
label var pais_c "Acrónimo del país"

***********
*  ANIO   *
***********
gen anio_c = 2023
label variable anio_c "Año de la Encuesta"

**********************
* MES DE LA ENCUESTA *
**********************
gen mes_c = 12
label variable mes_c "Mes de la Encuesta"

***************
*    ZONA     *
***************
gen byte zona_c=.
*replace zona_c=1 if area==1 /* Urbana */
*replace zona_c=0 if area==2 /* Rural */
label variable zona_c "Zona geográfica"
label define zona_c 0"Rural" 1"Urbana"
label value zona_c zona_c

***************
* estrato_ci  *
***************
gen byte estrato_ci = STRATUM

**********************
******** UPM  ********
**********************
gen upm = .

******************************
*  IDENTIFICADOR DEL HOGAR   *
******************************
*tostring hhno, replace
*gen hh_id = string(real(hhno),"%03.0f")
*egen idh_ch= concat(edno hh_id rndno)
egen idh_ch = concat(RNDNO EDNO PARNO STRATUM HHNO)

label var idh_ch "Identificador Unico del Hogar"
tostring idh_ch, replace

*******************************
* IDENTIFICADOR DEL INDIVIDUO *
*******************************
egen idp_ci = concat(RNDNO EDNO PARNO STRATUM HHNO INDIVNO)

label var idp_ci "Identificador Individual dentro del Hogar"
tostring idp_ci, replace

*************************
* factor_ch *
*************************
gen factor_ch = Wtfactor
label var factor_ch "Factor de Expansion del Hogar"

*************************
* factor_ci *
*************************
gen factor_ci = Wtfactor
label var factor_ci "Factor de Expansion del Individuo"



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
gen sexo_ci = LSEX
label var sexo_ci "Sexo del individuo"
label define sexo 1"Masculino" 2"Femenino" 
label values sexo_ci sexo

***********
*  EDAD   *
***********
*1896 valores perdidos.
gen edad_ci=LAGE
label var edad_ci "Edad del individuo"

************************************
*  RELACION CON EL JEFE DE HOGAR   *
************************************
gen relacion_ci = .
replace relacion_ci = 1 if RELHD == 0  // Head
replace relacion_ci = 2 if RELHD == 1  // Spouse/partner
replace relacion_ci = 3 if inlist(RELHD, 2, 3)  // Son/daughter
replace relacion_ci = 4 if RELHD == 4  // Other relatives
replace relacion_ci = 5 if inlist(RELHD, 5, 6, 8)     // Other non-relatives

label var relacion_ci "relación con el jefe de hogar"
label define relacion 1"Jefe" 2"Cónguye, Esposo/a, Compañero/a" 3"Hijo/a" 4"Otros parientes" 5"Otros no parientes" 6"Servicio doméstico" 
label values relacion_ci relacion

******************
** miembros_ci ** 
***************** 
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
replace miembros_ci=1 if (relacion_ci>=1 & relacion_ci<=4)
label variable miembros_ci "Variable dummy que indica las personas que son miembros del Hogar"

*******************
*  ESTADO CIVIL   *
*******************
gen civil_ci = .
replace civil_ci = 1 if MARSTAT == 5                // Soltero (Never Married)
replace civil_ci = 2 if inlist(MARSTAT, 1, 2)       // Unión formal (Married) o informal (Common-law)
replace civil_ci = 3 if inlist(MARSTAT, 3, 4)       // Divorciado o Separado
replace civil_ci = 4 if MARSTAT == 6                // Viudo

label define civil_ci 1 "Soltero" 2 "Unión formal o informal" 3 "Divorciado o separado" 4 "Viudo"
label values civil_ci civil_ci

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
*  MIEMBROS EN EL HOGAR MENORES DE 6 AÑOS *
********************************************
* No hay menores de 7 años en la encuesta
egen nmenor6_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<6)), by (idh_ch)
label variable nmenor6_ch "Miembros menores a 6 años dentro del Hogar"

******************************************
*  MIEMBROS EN EL HOGAR MENORES DE 1 AÑO *
******************************************
* No hay menores de 7 años en la encuesta
egen nmenor1_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<1)),  by (idh_ch)
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
gen byte afro_ci = .

*********
*ind_ci*
*********	
gen byte ind_ci =. 		

**************
*noafroind_ci*
**************
gen byte noafroind_ci = .

*********
*afro_ch*
*********
gen afro_ch  = .

********
*ind_ch*
********	
gen ind_ch = .

**************
*noafroind_ch*
**************
gen noafroind_ch = .

*******************
***afroind_ano_ci**
*******************
gen afroind_ano_ci = .

************
*afroind_ci*
************
gen afroind_ci = .

************
*afroind_ch*
************
gen afroind_ch = .




************************
***** DISCAPACIDAD *****
************************
	
********
*dis_ci*
********
gen dis_ci = .

**********
*disWG_ci*
**********
gen disWG_ci = .

******************
*ISOalpha3_dis_ci*
******************
gen BRB_dis_ci = dis_ci

********
*dis_ch*
********
gen dis_ch = . 




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

replace condocup_ci = 1 if actvstat == 10
replace condocup_ci = 2 if actvstat == 20
replace condocup_ci = 3 if inlist(actvstat, 31, 32 33)
replace condocup_ci = 4 if edad_ci < 15

label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de edad limite"
label values condocup_ci condocup_ci

**************************
* CATEGORIA DE INACTIVIDAD  *
**************************
*Jubilados, pensionados
gen categoinac_ci = .
replace categoinac_ci = 1 if (actvstat == 33 & condocup_ci == 3)
replace categoinac_ci = 2 if (actvstat == 32 & condocup_ci == 3)
replace categoinac_ci = 3 if (actvstat == 31 & condocup_ci == 3)
replace categoinac_ci = 4 if inlist(actvstat, 34, 35) 
label var  categoinac_ci "Condición de Inactividad" 
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
gen cesante_ci = .
replace cesante_ci = 1 if condocup_ci == 2 & EVERWKD == 1
replace cesante_ci = 0 if condocup_ci == 2 & EVERWKD == 2

label var cesante_ci "Cesante"

***************
* DESOCUPADO  *
***************
gen desemp_ci = . 
replace desemp_ci = 1 if condocup_ci == 2
label var desemp_ci "Desocupado"
label define desocupado 1"Desocupado" 0"No desocupado"  
label values desemp_ci desocupado

*****************************
* TRABAJA MENOS DE 30 HORAS *
*****************************
gen subemp_ci = .
replace subemp_ci = 1 if condocup_ci == 1 & HRSWRKD <= 8 & WILLING == 1 & ABLE == 1
replace subemp_ci = 0 if condocup_ci == 1 & subemp_ci == .

label var subemp_ci "Personas en subempleo por horas"

***********************************
* DURACION DEL DESEMPLEO EN MESES *
***********************************		
gen durades_ci = .

replace durades_ci = 0    if condocup_ci == 2 & LSTLOOK == 1  // Never looked → 0
replace durades_ci = 0.5  if condocup_ci == 2 & LSTLOOK == 2  // 1 month or less → 0.5
replace durades_ci = 2.5  if condocup_ci == 2 & LSTLOOK == 3  // 2-3 months → midpoint
replace durades_ci = 6    if condocup_ci == 2 & LSTLOOK == 4  // 4 months or more → 6 

label var durades_ci "Duración búsqueda de empleo"

***********************************
* POBLACION ECONOMICAMENTE ACTIVA *
***********************************
gen pea_ci = .
replace pea_ci=1 if inlist(condocup_ci, 1, 2)
replace pea_ci=1 if inlist(condocup_ci, 3, 4)

label var pea_ci "Población económicamente activa"

**********************
*  NÚMERO DE EMPLEOS *
**********************
gen nempleos_ci = .
replace nempleos_ci = 1 if condocup_ci == 1 & TWOJOBS == 2
replace nempleos_ci = 2 if condocup_ci == 1 & TWOJOBS == 1

label define nempleos_ci 1 "Un empleo" 2 "Más de un empleo"
label values nempleos_ci nempleos_ci

*****************************************
* ANTIGUEDAD EN LA ACTIVIDAD PRINCIPAL  *
*****************************************
* NO EXISTE LA PREGUNTA
gen antiguedad_ci = .
label var antiguedad_ci "Años de trabajo en la actividad principal"

****************
* DESALENTADOS *
****************
gen desalent_ci = .
replace desalent_ci = 1 if condocup_ci == 3 & REASNSK == 2
replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .

label var desalent_ci "Trabajadores desalentados, personas que creen que por alguna razon no conseguiran trabajo" 

**********************************************
* HORAS TRABAJADAS EN LA ACTIVIDAD PRINCIPAL *
**********************************************
gen horaspri_ci = .

replace horaspri_ci = 0    if condocup_ci == 1 & HRSWRKD == 1   // None
replace horaspri_ci = 2.5  if condocup_ci == 1 & HRSWRKD == 2   // Under 5
replace horaspri_ci = 7    if condocup_ci == 1 & HRSWRKD == 3   // 5-9
replace horaspri_ci = 12   if condocup_ci == 1 & HRSWRKD == 4   // 10-14
replace horaspri_ci = 17   if condocup_ci == 1 & HRSWRKD == 5   // 15-19
replace horaspri_ci = 22   if condocup_ci == 1 & HRSWRKD == 6   // 20-24
replace horaspri_ci = 27   if condocup_ci == 1 & HRSWRKD == 7   // 25-29
replace horaspri_ci = 32   if condocup_ci == 1 & HRSWRKD == 8   // 30-34
replace horaspri_ci = 37   if condocup_ci == 1 & HRSWRKD == 9   // 35-39
replace horaspri_ci = 42   if condocup_ci == 1 & HRSWRKD == 10  // 40-44
replace horaspri_ci = 48   if condocup_ci == 1 & HRSWRKD == 11  // 45+ (conservative)
* HRSWRKD == 99 (Not stated) → remains missing

label var horaspri_ci "Horas trabajadas semanalmente en la actividad principal"

**************************
* TOTAL HORAS TRABAJADAS *
**************************
gen horastot_ci = horaspri_ci

****************************************************
* TRABAJA MENOS DE 30 HORAS Y NO DESEA TRABAJAR MAS*
****************************************************
gen tiempoparc_ci = .

* 1. Voluntary Part-time: < 30 hours AND does NOT want more work
* Note: WILLING == 2 means "No" (not willing/wanting more hours)
replace tiempoparc_ci = 1 if condocup_ci == 1 & horaspri_ci < 30 & WILLING == 2

* 0. Rest of the employed population
replace tiempoparc_ci = 0 if condocup_ci == 1 & tiempoparc_ci == .

replace tiempoparc_ci=. if emp_ci==0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

* NOTA. SE CALCULA SOLO PARA LA ACTIVIDAD PRINCIPAL

*********************************
* CATEGORIA OCUPACION PRINCIPAL *
*********************************
gen categopri_ci = .

replace categopri_ci = 1 if condocup_ci == 1 & EMPLSTAT == 1
replace categopri_ci = 2 if condocup_ci == 1 & EMPLSTAT == 4
replace categopri_ci = 3 if condocup_ci == 1 & inlist(EMPLSTAT, 2, 3, 6)
replace categopri_ci = 0 if condocup_ci == 1 & EMPLSTAT == 7

label define categopri_ci 0 "Otra clasificacion" 1 "Patron" 2 "Cuenta propia" ///
    3 "Asalariado" 4 "No remunerado"
label values categopri_ci categopri_ci

*********************************
* CATEGORIA OCUPACION SECUNDARIA*
*********************************
gen byte categosec_ci = .
replace categosec_ci = 1 if condocup_ci == 1 & EMPL2STAT == 1 //Employer
replace categosec_ci = 2 if condocup_ci == 1 & EMPL2STAT == 4 //Self-employed / Own-account
replace categosec_ci = 3 if condocup_ci == 1 & inlist(EMPL2STAT, 2, 3, 6) //Government + Private + Apprentice
replace categosec_ci = 0 if condocup_ci == 1 & EMPL2STAT == 7

* Labels
label var categosec_ci "Categoría ocupación secundaria"
label define categosec 1"Patrón o empleador" 2"Cuenta propia o independiente" 3"Empleado o asalariado" 4"Trabajador no remunerado"  
label values categosec_ci categosec

*********************************
*  RAMA DE ACTIVIDAD PRINCIPAL  *
*********************************
gen rama_ci = .
replace rama_ci = 1 if condocup_ci == 1 & inrange(INDUS, 1, 3)
replace rama_ci = 2 if condocup_ci == 1 & inrange(INDUS, 5, 9)
replace rama_ci = 3 if condocup_ci == 1 & inrange(INDUS, 10, 33)
replace rama_ci = 4 if condocup_ci == 1 & inrange(INDUS, 35, 39)
replace rama_ci = 5 if condocup_ci == 1 & inrange(INDUS, 41, 43)
replace rama_ci = 6 if condocup_ci == 1 & inrange(INDUS, 45, 47) | inrange(INDUS, 55, 56)
replace rama_ci = 7 if condocup_ci == 1 & inrange(INDUS, 49, 53)
replace rama_ci = 8 if condocup_ci == 1 & inrange(INDUS, 64, 82)
replace rama_ci = 9 if condocup_ci == 1 & inrange(INDUS, 84, 99)

* Labels
label define rama_ci 1"Agricultura" 2"Explotación de minas y canteras" 3"Industrias manufactureras" 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, rest. y hoteles" 7"Transporte y comunicaciones" 8"Establecimientos financieros" 9 "Servicios sociales, comunales y personales"
label values rama_ci rama_ci

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

*********************************
*  TRABAJA EN EL SECTOR PUBLICO *
*********************************
gen spublico_ci = .
replace spublico_ci = 1 if condocup_ci == 1 & EMPLSTAT == 2
replace spublico_ci = 0 if condocup_ci == 1 & inlist(EMPLSTAT, 1, 3, 4, 6, 7)

* Labels
label define spublico_ci 1 "Sector publico" 0 "Sector privado"
label values spublico_ci spublico_ci
label var spublico_ci "Personas que trabajan en el sector publico"

*************
* tamemp_ci *
*************
gen tamemp_ci = .

*********************************
*  COTIZA A LA SEGURIDAD SOCIAL *
*********************************
gen cotizando_ci = .

**************
* instcot_ci *
**************
gen instcot_ci = .

**********************************
* AFILIADO A LA SEGURIDAD SOCIAL *
**********************************
gen afiliado_ci = .

*********************
* TRABAJADOR FORMAL *
*********************
gen byte formal_ci = .
replace formal_ci = 1 if (cotizando_ci==1|afiliado_ci==1) & condocup_ci==1
replace formal_ci = 0 if cotizando_ci==0 & (condocup_ci==1 | condocup_ci==2)

********************
* TIPO DE CONTRATO *
********************
gen tipocontrato_ci = .

*****************************
* TIPO DE OCUPACION LABORAL *
*****************************
gen ocupa_ci = .

* Auxiliars
gen occ1d = floor(OCCUP/1000)
gen occ2d = floor(OCCUP/100)

replace ocupa_ci = 1 if condocup_ci == 1 & inlist(occ1d, 2, 3)
replace ocupa_ci = 2 if condocup_ci == 1 & occ1d == 1
replace ocupa_ci = 3 if condocup_ci == 1 & occ1d == 4
replace ocupa_ci = 4 if condocup_ci == 1 & inlist(occ2d, 52)
replace ocupa_ci = 5 if condocup_ci == 1 & occ1d == 5 & ocupa_ci == .
replace ocupa_ci = 6 if condocup_ci == 1 & occ1d == 6
replace ocupa_ci = 7 if condocup_ci == 1 & inlist(occ1d, 7, 8, 9)
replace ocupa_ci = 8 if condocup_ci == 1 & occ1d == 0
replace ocupa_ci = 9 if condocup_ci == 1 & OCCUP == 9999

label define ocupa_ci 1 "Profesionales y tecnicos" ///
                      2 "Directores y funcionarios superiores" ///
                      3 "Personal administrativo y nivel intermedio" ///
                      4 "Comerciantes y vendedores" ///
                      5 "Trabajadores en servicios" ///
                      6 "Trabajadores agricolas y afines" ///
                      7 "Obreros no agricolas y conductores" ///
                      8 "Fuerzas Armadas" ///
                      9 "Otras ocupaciones"
label values ocupa_ci ocupa_ci

********************************************
* RECIBE PENSION O JUBILACION CONTRIBUTIVA *
********************************************
gen pension_ci = .
replace pension_ci = 1 if SCINCOME == 1 | USINCOME == 1 //Main source of livelihood is Pension
replace pension_ci = 0 if (inrange(SCINCOME, 2, 7) | inrange(USINCOME, 2, 7)) & pension_ci == . //Other sources reported

label var pension_ci "Recibe pensión o jubilación contributiva"

***********************************************
* RECIBE PENSION O JUBILACION NO CONTRIBUTIVA *
***********************************************
gen pensionsub_ci = .

* 1. Non-contributory pension (proxy: public assistance)
replace pensionsub_ci = 1 if SCINCOME == 7 | USINCOME == 7

* 0. Rest of the population
replace pensionsub_ci = 0 if (inrange(SCINCOME,1,6) | inrange(USINCOME,1,6)) & pensionsub_ci == .

label var pensionsub_ci "Recibe pensión o jubilación NO contributiva"

**************
* tipopen_ci *
**************
g tipopen_ci = .

************************************************
*INSTITUCION QUE OTORGA LA PENSION O JUBILACION*
************************************************
gen instpen_ci = .
label var instpen_ci "Institución que otorga la pensión o jubilación"



  
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
gen double ylmpri_ci = .

* Weekly bracket midpoint, then monthlyize
replace ylmpri_ci = 140    *(52/12) if condocup_ci == 1 & EARNGS == 1
replace ylmpri_ci = 249.5  *(52/12) if condocup_ci == 1 & EARNGS == 2
replace ylmpri_ci = 349.5  *(52/12) if condocup_ci == 1 & EARNGS == 3
replace ylmpri_ci = 449.5  *(52/12) if condocup_ci == 1 & EARNGS == 4
replace ylmpri_ci = 549.5  *(52/12) if condocup_ci == 1 & EARNGS == 5
replace ylmpri_ci = 649.5  *(52/12) if condocup_ci == 1 & EARNGS == 6
replace ylmpri_ci = 749.5  *(52/12) if condocup_ci == 1 & EARNGS == 7
replace ylmpri_ci = 849.5  *(52/12) if condocup_ci == 1 & EARNGS == 8
replace ylmpri_ci = 949.5  *(52/12) if condocup_ci == 1 & EARNGS == 9
replace ylmpri_ci = 1150   *(52/12) if condocup_ci == 1 & EARNGS == 10
replace ylmpri_ci = 1625   *(52/12) if condocup_ci == 1 & EARNGS == 11

* Missing for not stated
replace ylmpri_ci = . if condocup_ci == 1 & EARNGS == 99

* Non-remunerated workers
replace ylmpri_ci = 0 if categopri_ci == 4

* Non-employed PET
replace ylmpri_ci = 0 if condocup_ci != 1 & condocup_ci != .

label var ylmpri_ci "Ingreso laboral monetario mensual actividad principal"

*************************************************
* INGRESO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
*************************************************
gen ylmsec_ci = .

label var ylmsec_ci "Monto mensual de ingreso laboral de la actividad secundaria"

************************************
* INGRESO MENSUAL OTRAS ACTIVIDADES*
************************************
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso mensual por otras actividades"

************************************
* INGRESO MENSUAL TODAS ACTIVIDADES*
************************************
gen ylm_ci = ylmpri_ci + ylmsec_ci + ylmotros_ci
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso mensual todas actividades"

*******************************
* INGRESO MENSUAL NO MONETARIO*
*******************************
gen ylnmpri_ci = .
label var ylnmpri_ci "Monto mensual de ingreso NO monetario de la actividad principal"

****************************************************
* INGRESO NO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
****************************************************
gen ylnmsec_ci=.
label var ylnmsec_ci "Ingreso mensual laboral NO monetario de la actividad secundaria"

*************************************************
* INGRESO MENSUAL NO MONETARIO OTRAS ACTIVIDADES*
*************************************************
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso mensual NO monetario por otras actividades"

*************************************************
* INGRESO MENSUAL NO MONETARIO TODAS ACTIVIDADES*
*************************************************
gen ylnm_ci = ylnmpri_ci + ylnmsec_ci + ylnmotros_ci
label var ylnm_ci "Ingreso mensual NO monetario todas actividades"

*******************
* ynlm_publico_ci *
*******************
gen ynlm_publico_ci = .

****************************
* ynlm_privado_transren_ci *
****************************
gen ynlm_privado_transren_ci = .

*************************
* ynlm_privado_otros_ci *
*************************
gen ynlm_privado_otros_ci = .

*******************
* ynlm_privado_ci *
*******************
gen ynlm_privado_ci = .

*****************
* ynlm_otros_ci *
*****************
gen ynlm_otros_ci = .

*************************************************
* INGRESO MENSUAL NO LABORAL OTRAS ACTIVIDADES  *
*************************************************
gen ynlm_ci = . 
label var ynlm_ci "Ingreso mensual NO laboral otras actividades"

**************************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO OTRAS ACTIVIDADES  *
**************************************************************
gen ynlnm_ci= .
label var ynlnm_ci "Ingreso mensual NO laboral NO monetario otras actividades"

***********
* ytot_ci *
***********
gen double ytot_ci = ylm_ci + ylnm_ci + ynlm_ci + ynlnm_ci

************************************
* INGRESO MENSUAL LABORAL DEL HOGAR*
************************************
bysort idh_ch: egen double ylm_ch = total(ylm_ci)
replace ylm_ch = . if missing(idh_ch)
label var ylm_ch "Ingreso Laboral Monetario del Hogar (Bruto)"

**************************************************
* INGRESO MENSUAL LABORAL NO MONETARIO DEL HOGAR *
**************************************************
bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi 
label var ylnm_ch "Ingreso Laboral No Monetario del Hogar"

*****************************************************
* INGRESO MENSUAL NO LABORAL NO MONETARIO DEL HOGAR *
*****************************************************
bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, mi 
label var ynlnm_ch "Ingreso No Laboral No Monetario del Hogar"

*******************
* ynlm_publico_ch *
*******************
bysort idh_ch: egen double ynlm_publico_ch = total(ynlm_publico_ci) if miembros_ci == 1, mi

****************************
* ynlm_privado_transren_ch *
****************************
bysort idh_ch: egen double ynlm_privado_transren_ch = total(ynlm_privado_transren_ci) if miembros_ci == 1, mi 

*************************
* ynlm_privado_otros_ch *
*************************
bysort idh_ch: egen double ynlm_privado_otros_ch = total(ynlm_privado_otros_ci) if miembros_ci == 1, mi

*******************
* ynlm_privado_ch *
*******************
egen double ynlm_privado_ch = rowtotal(ynlm_privado_otros_ch ynlm_privado_transren_ch), mi

*****************
* ynlm_otros_ch *
*****************
bysort idh_ch: egen ynlm_otros_ch = total(ynlm_otros_ci) if miembros_ci == 1, mi 

**************************************************
* INGRESO MENSUAL NO LABORAL MONETARIO DEL HOGAR *
**************************************************
egen double ynlm_ch = rowtotal(ynlm_privado_ch ynlm_publico_ch ynlm_otros_ch), mi 
label var ynlm_ch "Ingreso No Laboral Monetario del Hogar"

***********************************
* INGRESO MENSUAL TOTAL DEL HOGAR *
***********************************
egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
label var ytot_ch "Ingreso Mensual Total del Hogar"

*****************************************************
* INGRESO LABORAL POR HORA EN LA ACTIVIDAD PRINCIPA *
*****************************************************
gen double ylmhopri_ci = .
replace ylmhopri_ci = ylmpri_ci / (horaspri_ci * (52/12)) if condocup_ci == 1 & ylmpri_ci != . & horaspri_ci > 0 & horaspri_ci < .
replace ylmhopri_ci = . if horaspri_ci == 0
replace ylmhopri_ci = 0 if categopri_ci == 4

label var ylmhopri_ci "Salario horario monetario actividad principal"

*****************************************************
* INGRESO LABORAL POR HORA EN TODAS LAS ACTIVIDADES *
*****************************************************
gen byte ylmho_ci = ylm_ci / (4.3 * horastot_ci) 
replace ylmho_ci = . if ylmho_ci <= 0 

label var ylmho_ci "Salario horario monetario de todas las actividades"

*******************
*** nrylmpri_ci ***
*******************
gen byte nrylmpri_ci = . 
replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1 
replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1

label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal" 

*******************
*** nrylmpri_ch ***
*******************
by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1 
replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < . 
replace nrylmpri_ch = . if nrylmpri_ch == .

label variable nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

********************
***** ylmnr_ch *****
********************
by idh_ch, sort: egen byte ylmnr_ch = sum(ylm_ci) if miembros_ci == 1 
replace ylmnr_ch = . if nrylmpri_ch == 1

label var ylmnr_ch "Ingreso laboral monetario del hogar" 

***************************
* REMESAS EN MONEDA LOCAL *
***************************
gen remesas_ci = .

label var remesas_ci "Remesas en moneda local"

************************************
* REMESES EN MONEDA LOCAL DEL HOGAR*
************************************
by idh_ch, sort: egen byte remesas_ch = sum(remesas_ci) if miembros_ci == 1 

label var remesas_ch "Remesas del hogar en moneda local"

************************************
* INGRESO POR PENSION CONTRIBUTIVA *
************************************
gen ypen_ci=.
label var ypen_ci "Ingreso por pension contributiva"

***************************************
* INGRESO POR PENSION NO CONTRIBUTIVA *
***************************************
gen ypensub_ci=.
label var ypensub_ci "Ingreso por pensionc NO contributiva





*******************************
*******************************
*******************************
*    VARIABLES DE EDUCACION   *
*******************************
*******************************
*******************************
*************
***aedu_ci*** 
*************
gen aedu_ci = .
replace aedu_ci = 0 if EDUCLEV == 0
replace aedu_ci = 3 if EDUCLEV == 1
replace aedu_ci = 9 if EDUCLEV == 2
replace aedu_ci = 13 if EDUCLEV == 3
replace aedu_ci = 14 if EDUCLEV == 4
replace aedu_ci = . if EDUCLEV == 5
replace aedu_ci = . if EDUCLEV == 9

label var aedu_ci "Anios de educacion culminados"

***************
***edupre_ci***
***************
gen edupre_ci=.	 
label var edupre_ci "Ha completado educación preescolar"

**************
***eduui_ci***
**************
gen eduui_ci = .
label var eduui_ci "No ha completado la educación terciaria/universitaria"

**************
***eduuc_ci***
**************
* proxy
gen byte eduuc_ci = .
replace eduuc_ci = 1 if inlist(EDUCLEV, 3, 4)
replace eduuc_ci = 0 if inrange(EDUCLEV, 0, 2)
replace eduuc_ci = . if EDUCLEV == 5 | EDUCLEV == 9

label var eduuc_ci "Ha completado la educación terciaria/universitaria"

**************
***eduac_ci***
**************
gen byte eduac_ci = .
replace eduac_ci = 1 if EDUCLEV == 4
replace eduac_ci = 0 if EDUCLEV == 3

label var eduac_ci "Ha completado educación terciaria académica"

***************
***asiste_ci***
***************
gen asiste_ci = .
replace asiste_ci = 1 if CTRAINING == 1
label var asiste_ci "Asiste a algún centro de enseñanza"

***************
***edupub_ci***
***************
* proxt
gen byte edupub_ci = .
replace edupub_ci = 1 if inlist(PLACETR,12,13,14,15,16)
replace edupub_ci = . if inlist(PLACETR,11,21,31,41,51,81)
replace edupub_ci = . if inlist(PLACETR,19,22,32,42,52)

label var edupub_ci "Asiste a institucion publica"

****************
***asispre_ci***
****************
gen asispre_ci = .
label variable asispre_ci "Asistencia a Educacion preescolar"

**********************
***razonesnoasis_ci***
**********************
gen razonesnoasis_ci = .

***************
** repite_ci **
***************
gen repite_ci = .

******************
** repiteult_ci **
******************
gen repiteult_ci = .



*******************************
*******************************
*******************************
*    VARIABLES DE VIVIENDA    *
*******************************
*******************************
******************************

************
** luz_ch **
************
gen luz_ch = .

****************
** luzmide_ch **
****************
gen byte luzmide_ch = .

****************
** combust_ch **
****************
gen byte combust_ch = .

*************
** piso_ch **
*************
gen byte piso_ch = .

**************
** pared_ch **
**************
gen byte pared_ch = .

**************
** techo_ch **
**************
gen byte techo_ch = .

**************
** resid_ch **
**************
gen byte resid_ch = .

**************
** dorm_ch ***
**************
gen dorm_ch = .

****************
** cuartos_ch **
****************
gen cuartos_ch = .

***************
** cocina_ch **
***************
gen byte cocina_ch = .

***************
** telef_ch **
***************
gen byte telef_ch = .

***************
** refrig_ch **
***************
gen byte refrig_ch = .

**************
** freez_ch **
**************
gen byte freez_ch = .

*************
** auto_ch **
*************
gen byte auto_ch = .

**************
** compu_ch **
**************
gen byte compu_ch = .

*****************
** internet_ch **
*****************
gen byte internet_ch = .

************
** cel_ch **
************
gen byte cel_ch = .

*************
** ivi1_ch **
*************
gen byte vivi1_ch = .

**************
** vivi2_ch **
**************
gen byte vivi2_ch = .

*****************
** viviprop_ch **
*****************
gen byte viviprop_ch = .
replace viviprop_ch = 1 if LNDTNURE == 1
replace viviprop_ch = 0 if inlist(LNDTNURE, 2, 3, 4, 5)
replace viviprop_ch = . if LNDTNURE == 9

****************
** vivialq_ch **
****************
gen byte vivialq_ch = .
replace vivialq_ch = 1 if LNDTNURE == 3
replace vivialq_ch = 0 if inlist(LNDTNURE, 1, 2, 4, 5)
replace vivialq_ch = . if LNDTNURE == 9

*****************
** vivitit_ch **
*****************
gen byte vivitit_ch = .
replace vivitit_ch = 1 if LNDTNURE == 1
replace vivitit_ch = 0 if inlist(LNDTNURE, 2, 3, 4, 5)
replace vivitit_ch = . if LNDTNURE == 9

*******************
** vivialqimp_ch **
*******************
gen byte vivialqimp_ch = .




*************************
*** VARIABLES DE WASH ***
*************************
**************
** aguared_ch **
**************
gen byte aguared_ch = .

*******************
** aguafconsumo_ch **
*******************
gen double aguafconsumo_ch = .

*******************
** aguafuente_ch **
*******************
gen byte aguafuente_ch = .

*******************
** aguadist_ch **
*******************
gen byte aguadist_ch = .

*******************
** aguadisp1_ch **
*******************
gen byte aguadisp1_ch = .

*******************
** aguadisp2_ch **
*******************
gen byte aguadisp2_ch = .

*******************
** aguatrat_ch **
*******************
gen byte aguatrat_ch = .

*******************
** aguamala_ch **
*******************
gen byte aguamala_ch = 2 
replace aguamala_ch = 0 if aguafuente_ch<=7 
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=. 

*******************
** aguamejorada_ch **
*******************
gen byte aguamejorada_ch = 2 
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10 
replace aguamejorada_ch = 1 if aguafuente_ch<=7 

*******************
** aguamide_ch **
*******************
gen byte aguamide_ch = .

***********
** bano_ch **
***********
gen byte bano_ch = .

*************
** banoex_ch **
*************
gen byte banoex_ch = .

**************
** sinbano_ch **
**************
gen byte sinbano_ch = .

******************
** banomejorado_ch **
******************
gen byte banomejorado_ch= 2 
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0 
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6 





******************************
*** VARIABLES DE MIGRACION ***
******************************
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




**************************************
*** VARIABLES DE PROTECCIÓN SOCIAL ***
**************************************
************************
*** nmiembros_spl_ch ***
************************
bysort idh_ch: gen int nmiembros_spl_ch = _N 
replace nmiembros_spl_ch = . if missing(idh_ch)

label var nmiembros_spl_ch "Numero de miembros del hogar"

*******************
*** yneto_pc_ch *** 
******************* 
gen double yneto_pc_ch = (ytot_ch - ynlm_publico_ch) / nmiembros_spl_ch 

******************
** bene_cash_ch **
******************
gen byte bene_ind = 0
replace bene_ind = 1 if inlist(SCINCOME, 1, 7)
replace bene_ind = 1 if inlist(USINCOME, 1, 7)
replace bene_ind = 1 if inlist(IN2INCOM, 1, 7)
replace bene_ind = 1 if inlist(U2SINCOM, 1, 7)

* Marcar missing si todas las variables están missing
gen byte _all_missing = (missing(SCINCOME) & missing(USINCOME) & missing(IN2INCOM) & missing(U2SINCOM))
replace bene_ind = . if _all_missing == 1
drop _all_missing

egen byte bene_cash_ch = max(bene_ind), by(idh_ch)
label var bene_cash_ch "Hogar beneficiario de transferencia monetaria publica (1=Si, 0=No, .=No info)"

replace bene_cash_ch = . if missing(idh_ch)

*******************
** pensionsub_ch **
*******************
gen byte pensionsub_ind = 0

* Mark as beneficiary if any income source variable reports "Other public assistance" (code 7)
replace pensionsub_ind = 1 if inlist(SCINCOME, 7) | inlist(USINCOME, 7) ///
                          | inlist(IN2INCOM, 7) | inlist(U2SINCOM, 7)

* If ALL the income-source variables used are missing for the person, set individual to missing
gen byte _allinc_missing = (missing(SCINCOME) & missing(USINCOME) & missing(IN2INCOM) & missing(U2SINCOM))
replace pensionsub_ind = . if _allinc_missing == 1
drop _allinc_missing

egen byte pensionsub_ch = max(pensionsub_ind), by(idh_ch)
label var pensionsub_ch "Hogar: existe beneficiario de pensión no contributiva (1=Sí, 0=No, .=Sin info)"

replace pensionsub_ch = . if missing(idh_ch)







***********************************
* VARIABLES DE REFERENCIA EXTERNA *
***********************************
********************************
* SALARIO MINIMO MENSUAL LEGAL *
********************************
gen salmm_ci = 1473.3
label var salmm_ci "salario mínimo mensual legal"
* https://datosmacro.expansion.com/smi/barbados en BBD





/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/
order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad  
afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad  
condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo 
horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci  /// Ingresos individuo 
ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch  ytot_ch /// Ingresos del hogar 
ylmhopri_ci ylmho_ci /// ingreso por hora 
nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones 
aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación  
luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda  
freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda 
aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto 
aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto 
migrante_ci migrantiguo5_ci miglac_ci /// Migración   
nmiembros_sph_ch yneto_pc_ch bene_cash_ch pensionsub_ch   /// Protección social  
ynlm_publico_ch ynlm_privado_ch ynlm_privado_ci ynlm_publico_ci  /// Protección social ingresos 
salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa 
	 
	 
save "`base_out'", replace


log close
