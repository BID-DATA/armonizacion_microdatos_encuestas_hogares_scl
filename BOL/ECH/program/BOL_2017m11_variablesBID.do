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

local PAIS BOL
local ENCUESTA ECH
local ANO "2017"
local ronda m11 


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
*local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                                                    
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Bolivia
Encuesta: ECH
Round: m11

*************************************************************************** */
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

*************************************************************************** */


use "`base_in'", clear

	****************
	* region_BID_c *
	****************
	
gen region_BID_c=3

label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

	************
	* region_c *
	************
destring depto, gen(region_c)
gen ine01 = region_c

label define region_c ///
1"Chuquisaca"         ///     
2"La Paz"             ///
3"Cochabamba"         ///
4"Oruro"              ///
5"Potosí"             ///
6"Tarija"             ///
7"Santa Cruz"         ///
8"Beni"               ///
9"Pando"              
label value region_c region_c
label var region_c "division politica, estados"

***************
***factor_ch***
***************
gen factor_ch= factor
label variable factor_ch "Factor de expansion del hogar"

	***************
	***upm_ci***
	***************
gen upm_ci=upm
	***************
	***estrato_ci***
	***************
gen estrato_ci=estrato

***************
****idh_ch*****
***************
sort folio
egen idh_ch = group(folio)
destring idh_ch, replace
label variable idh_ch "ID del hogar"
tostring idh_ch, replace


**************
****idp_ci****
**************
gen idp_ci= nro
label variable idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


**********
***zona***
**********

gen byte zona_c=0 	if area==2
replace zona_c=1 	if area==1
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c
label variable zona_c "Zona del pais"

************
****pais****
************
gen str3 pais_c="BOL"
label variable pais_c "Pais"

**********
***anio***
**********
gen anio_c=2017
label variable anio_c "Anio de la encuesta"

*********
***mes***
*********
*19 de octubre al 20 de diciembre
gen mes_c=11
label variable mes_c "Mes de la encuesta"

*****************
***relacion_ci***
*****************
gen relacion_ci=.
replace relacion_ci=1 if  s02a_05==1
replace relacion_ci=2 if  s02a_05==2
replace relacion_ci=3 if  s02a_05==3 
replace relacion_ci=4 if  s02a_05>=4 &  s02a_05<=9
replace relacion_ci=5 if  s02a_05==10 |  s02a_05==12 
replace relacion_ci=6 if  s02a_05==11

label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes"
label define relacion_ci 6 "Empleado/a domestico/a", add
label value relacion_ci relacion_ci

****************************
***VARIABLES DEMOGRAFICAS***
****************************

***************
***factor_ci***
***************
gen factor_ci=factor_ch
label variable factor_ci "Factor de expansion del individuo"

**********
***sexo***
**********
gen sexo_ci = s02a_02
label var sexo_ci "Sexo del individuo" 
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********
gen edad_ci= s02a_03
label variable edad_ci "Edad del individuo"

*****************
***civil_ci***
*****************
gen civil_ci=.
replace civil_ci=1 		if s02a_10==1
replace civil_ci=2 		if s02a_10==2 | s02a_10==3
replace civil_ci=3 		if s02a_10==4 | s02a_10==5
replace civil_ci=4 		if s02a_10==6
label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci

*************
***jefe_ci***
*************
gen jefe_ci=(relacion_ci==1)
label variable jefe_ci "Jefe de hogar"

******************
***nconyuges_ch***
******************
by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************
by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************
by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************
by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
label variable notronopari_ch "Numero de no familiares"

****************
***nempdom_ch***
****************
by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
label variable nempdom_ch "Numero de empleados domesticos"

*****************
***clasehog_ch***
*****************
gen byte clasehog_ch=0
**** unipersonal
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
**** nuclear   (child with or without spouse but without other relatives)
replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
**** ampliado
replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
**** compuesto  (some relatives plus non relative)
replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
**** corresidente
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
label variable clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
label value clasehog_ch clasehog_ch

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
label variable nmiembros_ch "Numero de familiares en el hogar"

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

****************
***miembros_ci***
****************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************		
	*********
	*afro_ci*
	*********
	*tab s03a_04, m
	*tab s03a_04npioc, m
	
	gen byte afro_ci = .
	replace afro_ci= 1 if s03a_04npioc == 1  
	replace afro_ci = 0 if s03a_04npioc != 1 & s03a_04 != .
	tab afro_ci, m
	
	*********
	*ind_ci*
	*********
	gen byte ind_ci = .
	replace ind_ci = 1 if s03a_04npioc != 1 & s03a_04 == 1
	replace ind_ci = 0 if s03a_04npioc == 1 | s03a_04 == 2  | s03a_04 == 3
	tab ind_ci, m
	
	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci =1 if (afro_ci==0 & ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
	replace noafroind_ci =. if (afro_ci==. | ind_ci==.) //Esto solo en el caso que se tenga ambas opciones no disponibles. 
	ta noafroind_ci,m

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1
	ta afroind_ci,m
	
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
	foreach var in  s04a_06a s04a_06b s04a_06c s04a_06d s04a_06e s04a_06f {
	tab `var', m nolab
	}

	gen byte dis_ci = 0
	
	foreach i in a b c d e f  {
		forvalues j=2/4 {
			recode dis_ci 0=1 if s04a_06`i'==`j'
		}
	}

	recode dis_ci nonmiss=. if s04a_06a>=. & s04a_06b>=. & s04a_06c>=. & s04a_06d>=. & s04a_06e>=. & s04a_06f>=.
	
	tab dis_ci, m 
	
	**********
	*disWG_ci*
	**********
	gen byte disWG_ci = 0
	
	foreach i in a b c d e f  {
		forvalues j=3/4 {
			recode disWG_ci 0=1 if s04a_06`i'==`j'
		}
	}

	recode dis_ci nonmiss=. if s04a_06a>=. & s04a_06b>=. & s04a_06c>=. & s04a_06d>=. & s04a_06e>=. & s04a_06f>=.
	
	tab disWG_ci, m 
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte BOL_dis_ci = dis_ci
	
	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c=2012

************************************
*** VARIABLES DEL MERCADO LABORAL***
************************************
/************************************************************************************************************
* Líneas de pobreza oficiales
************************************************************************************************************/

*********
*lp_ci***
*********

gen lp_ci =z
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********
gen lpe_ci =zext
label var lpe_ci "Linea de indigencia oficial del pais"

*************
**salmm_ci***
*************
*https://www.ine.gob.bo/subtemas_cuadros/salarioMinimo_html/SalarioMinimo_41201.htm
gen salmm_ci= 2000	/*2017: 2000*/
label var salmm_ci "Salario minimo legal"

****************
*cotizando_ci***
****************
gen cotizando_ci=.
label var cotizando_ci "Cotizante a la Seguridad Social"

****************
*afiliado_ci****
****************
gen afiliado_ci= s06h_58b==1	
recode afiliado_ci .=0  if condact>=1 & condact<=3
label var afiliado_ci "Afiliado a la Seguridad Social"

****************
*tipopen_ci*****
****************

gen tipopen_ci=.
replace tipopen_ci=1 if s07a_01a>0 & s07a_01a!=.
replace tipopen_ci=2 if s07a_01d>0 & s07a_01d!=.
replace tipopen_ci=3 if s07a_01b>0 & s07a_01b!=.
replace tipopen_ci=4 if s07a_01c>0 & s07a_01c!=. 
replace tipopen_ci=12 if (s07a_01a>0 & s07a_01d>0) & (s07a_01a!=. & s07a_01d!=.)
replace tipopen_ci=13 if (s07a_01a>0 & s07a_01b>0) & (s07a_01a!=. & s07a_01b!=.)
replace tipopen_ci=23 if (s07a_01d>0 & s07a_01b>0) & (s07a_01d!=. & s07a_01b!=.)
replace tipopen_ci=123 if (s07a_01a>0 & s07a_01b>0 & s07a_01c>0) & (s07a_01a!=. & s07a_01b!=. & s07a_01c!=.)
label define tipopen_ci 1 "Jubilacion" 2 "Viudez/orfandad" 3 "Benemerito" 4 "Invalidez" 12 "Jub y viudez" 13 "Jub y benem" 23 "Viudez y benem" 123 "Todas"
label value tipopen_ci tipopen_ci
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

****************
*instpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 
gen instcot_ci=. 


****************
****condocup_ci*
****************

gen condocup_ci=.
replace condocup_ci=1 if s06a_01==1 | (s06a_02!=. & s06a_02<=7) | (s06a_03>=1 & s06a_03<=9)
replace condocup_ci=2 if (s06a_01==2 | s06a_02==8 | s06a_03==10) & s06a_05==1 & s06a_04==1 
recode condocup_ci .=3 if edad_ci>=7
recode condocup_ci .=4 if edad_ci<7
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 7" 
label value condocup_ci condocup_ci


*************
*cesante_ci* 
*************

gen cesante_ci = 1 if condocup_ci==2 & s06a_07==1
replace cesante_ci = 0 if condocup_ci==2 & s06a_07==2
label var cesante_ci "Desocupado - definicion oficial del pais"	

*************
*tamemp_ci
*************
*Bolivia Pequeña 1 a 5 Mediana 6 a 49 Grande Más de 49
gen tamemp_ci=.
replace tamemp_ci=1 if s06b_21>=1 & s06b_21<=5
replace tamemp_ci=2 if s06b_21>=6 & s06b_21<=49
replace tamemp_ci=3 if s06b_21>49 & s06b_21!=.
label var tamemp_ci "# empleados en la empresa segun rangos"
label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci

*Bolivia micro 1 a 4 pequeña 5 a 14 Mediana 15-40 Grande mas 41
gen tamemp=.
replace tamemp=1 if s06b_21>=1 & s06b_21<=4
replace tamemp=2 if s06b_21>=5 & s06b_21<=14
replace tamemp=3 if s06b_21>=15 & s06b_21<=40
replace tamemp=4 if s06b_21>=41 & s06b_21!=.
label var tamemp "# empleados en la empresa segun rangos"
label define tamemp 1 "Micro" 2 "Pequeña" 3 "Mediana" 4 "Grande"
label value tamemp tamemp


/* Esta sección es para los residentes habituales del hogar mayores a 7 años. Sin embargo, las variables construidas 
por el centro de estadística tienen en cuenta a la población con 10 años o más. Esto no es un problema dado que el 
programa para generar los indicadores de sociómetro restrige  todo a 15 o más años para que haya comparabilidad entre
países
*/

************
***emp_ci***
************
gen byte emp_ci=(condocup_ci==1)
label var emp_ci "Ocupado (empleado)"

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)
label var desemp_ci "Desempleado que buscó empleo en el periodo de referencia"
  
*************
***pea_ci***
*************
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1
label var pea_ci "Población Económicamente Activa"

*****************
***desalent_ci***
*****************
gen desalent_ci=(emp_ci==0 & (s06a_10==3 | s06a_10==4))
replace desalent_ci=. if emp_ci==.
label var desalent_ci "Trabajadores desalentados"

*****************
***horaspri_ci***
*****************

  * s6b_23b: 23b. cuantas horas en promedio trabaja al dia .. ? (minutos)
  *s6b_23a: 23a. cuantas horas en promedio trabaja al dia .. ? (horas)
  *s6b_22: 22. cuantos dias a la semana trabaja

  * Modificación Cesar Lins - Feb 2022 
 * The dataset has a calculated variable for the weekly hours worked:
 *   phrs - Horas trabajadas a la semana en la Ocupacion Principal
  
gen horaspri_ci = phrs
*label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"  
  

*****************
***horassec_ci***
*****************
  * The dataset has a calculated variable for the weekly hours worked:
  *   phrs - Horas trabajadas a la semana en la Ocupacion Secundaria
  
gen horassec_ci = shrs
  
*****************
***horastot_ci***
*****************
/*
Modificación Feb 22: Cesar Lins

Los datos originales tienen una variable calculada
que calcula la suma de las actividades primaria y secundaria:
  
  tothrs: horas trabajadas a la semana

*/
gen horastot_ci = tothrs

***************
***subemp_ci***
***************

* Se considera subempleo visible: quiere trabajar mas horas y esta disponible. 
gen subemp_ci=0
replace subemp_ci=1 if (s06h_52==1 & s06h_53==1)  & horaspri_ci <= 30 & emp_ci==1
label var subemp_ci "Personas en subempleo por horas"

*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci=.
*Mod. MLO 2015, 10
replace tiempoparc_ci=(s06h_52==2 & horaspri_ci<30 & emp_ci == 1)
replace tiempoparc_ci=. if emp_ci==0
*replace tiempoparc_ci=1 if s6_46==2 & horastot_ci<=30 & emp_ci == 1
*replace tiempoparc_ci=0 if s6_46==2 & emp_ci == 1 & horastot_ci>30
label var tiempoparc_ci "Personas que trabajan medio tiempo" 

******************
***categopri_ci***
******************
gen categopri_ci=.
replace categopri_ci=1 if s06b_16>=4 & s06b_16<=6
replace categopri_ci=2 if s06b_16==3
replace categopri_ci=3 if s06b_16==1 | s06b_16==2 | s06b_16==8
replace categopri_ci=4 if s06b_16==7
replace categopri_ci=. if emp_ci~=1
label define categopri_ci 1"Patron" 2"Cuenta propia" 
label define categopri_ci 3"Empleado" 4" No remunerado", add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional trabajo principal"

******************
***categosec_ci***
******************
gen categosec_ci=.
replace categosec_ci=1 if s06f_41>=4 & s06f_41<=6
replace categosec_ci=2 if s06f_41==3
replace categosec_ci=3 if s06f_41==1 | s06f_41==2 | s06f_41==8
replace categosec_ci=4 if s06f_41==7
label define categosec_ci 1"Patron" 2"Cuenta propia" 
label define categosec_ci 3"Empleado" 4 "No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"

*****************
*tipocontrato_ci*
*****************
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if s06b_17==4 & categopri_ci==3
replace tipocontrato_ci=2 if s06b_17==1 & categopri_ci==3
*replace tipocontrato_ci=3 if ((s6_21==2 | s6_21==4) | tipocontrato_ci==.) & categopri_ci==3
*Mod. MLO 2015,10
replace tipocontrato_ci=3 if ((s06b_17==2 | s06b_17==3 | s06b_17==5) | tipocontrato_ci==.) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

*****************
***nempleos_ci***
*****************
gen nempleos_ci=.
replace nempleos_ci=1 if emp_ci==1
replace nempleos_ci=2 if emp_ci==1 & s06e_39==1
label var nempleos_ci "Número de empleos" 
label define nempleos_ci 1 "Un empleo" 2 "Mas de un empleo"
label value nempleos_ci nempleos_ci
				
/*
*****************
***firmapeq_ci***
*****************
gen firmapeq_ci=.
replace firmapeq_ci=1 if  s6_20>=1 & s6_20<=5 
replace firmapeq_ci=0 if  s6_20>=6 & s6_20!=.
label var firmapeq_ci "Trabajadores informales"
 */
 
*****************
***spublico_ci***
*****************
gen spublico_ci=.
replace spublico_ci=1 if s06b_18==1 | s06b_18==2
replace spublico_ci=0 if (s06b_18>=3 & s06b_18<=6)
replace spublico_ci=. if emp_ci~=1
label var spublico_ci "Personas que trabajan en el sector público"

**************
***ocupa_ci***
**************
*cob_op:
*NA: No se puede estandarizar ya que no se distingue entre dos categorias:
*comerciantes y vendedores y trabajadores en servicios 

* MGD 5/24/2016: no es posible dividir entre trabajadores de los servicios y comerciantes.
* Usa CIUO-08
/*gen ocupa_ci=.
replace ocupa_ci=1 if (cob_op==2 | cob_op==3)& emp_ci==1
replace ocupa_ci=2 if (cob_op==1) & emp_ci==1
replace ocupa_ci=3 if (cob_op==4) & emp_ci==1
replace ocupa_ci=5 if (cob_op==5) & emp_ci==1
replace ocupa_ci=6 if (cob_op==6) & emp_ci==1
replace ocupa_ci=7 if (cob_op==7 | cob_op==8) & emp_ci==1
replace ocupa_ci=8 if (cob_op==0) & emp_ci==1
replace ocupa_ci=9 if (cob_op==9) & emp_ci==1
label define ocupa_ci 1 "profesional y tecnico" 2"director o funcionario sup" 3 "administrativo y nivel intermedio"
label define ocupa_ci 4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci 7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci 8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral"*/

* MGD 6/15/2017: usa variable a mas digitos para hacer la clasificación, se cambia a CIUO-08

gen longi=length(s06b_11a_cod)
g new_cod=substr(s06b_11a_cod,1,3) if longi>3
replace new_cod=s06b_11a_cod if longi<=3
destring new_cod, replace
gen ocupa_ci=.
replace ocupa_ci=1 if ((new_cod>=210 & new_cod<=352) | (new_cod>=21 & new_cod<=34)) & emp_ci==1
replace ocupa_ci=2 if ((new_cod>=110 & new_cod<=143) |  new_cod==11) & emp_ci==1
replace ocupa_ci=3 if ((new_cod>=410 & new_cod<=441) |  new_cod==41 |  new_cod==42 |  new_cod==43) & emp_ci==1
replace ocupa_ci=4 if ((new_cod>=520 & new_cod<=529) | (new_cod>=910 & new_cod<=911) | new_cod==52 | new_cod==91) & emp_ci==1
replace ocupa_ci=5 if ((new_cod>=510 & new_cod<=519) | (new_cod>=530 & new_cod<=541) | (new_cod>=910 & new_cod<=912) | new_cod==51) & emp_ci==1
replace ocupa_ci=6 if ((new_cod>=610 & new_cod<=634) | (new_cod>=920 & new_cod<=921) | new_cod==61) & emp_ci==1
replace ocupa_ci=7 if ((new_cod>=710 & new_cod<=835) | (new_cod>=930 & new_cod<=970) | new_cod==71 | new_cod==72 | new_cod==73 | new_cod==75 | new_cod==81 | new_cod==83)& emp_ci==1
replace ocupa_ci=8 if ((new_cod>=0 & new_cod<=8) | new_cod==10 | new_cod==20) & emp_ci==1

label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral"

*************
***rama_ci***
*************
/*
caeb_op:
0 Agricultura,Ganadería,Caza,Pesca y Silv
1 Explotación de Minas y Canteras
2 Industria Manufacturera
3 Suministro de electricidad,gas,vapor y
4 Suministro de agua, evac. de aguas res,
5 Construcción
6 Venta por mayor y menor,reparación de a
7 Transporte y Almacenamiento
8 Actividades de alojamiento y servicio d
9 Informaciones y Comunicaciones
10 Intermediación Financiera y Seguros
11 Actividades inmobiliarias
12 Servicios Profesionales y Técnicos
13 Actividades de Servicios Administrativo
14 Adm. Pública, Defensa y Seguridad Socia
15 Servicios de Educación
16 Servicios de Salud y Asistencia Social
17 Actividades artisticas,entretenimiento
18 Otras actividades de servicios
19 Actividades de Hogares Privados
20 Servicio de Organismos Extraterritorial
99 NS/NR
*/ 

gen rama_ci=.
replace rama_ci=1 if caeb_op==0 & emp_ci==1
replace rama_ci=2 if caeb_op==1 & emp_ci==1
replace rama_ci=3 if caeb_op==2 & emp_ci==1
replace rama_ci=4 if (caeb_op==3 | caeb_op==4) & emp_ci==1
replace rama_ci=5 if caeb_op==5 & emp_ci==1
replace rama_ci=6 if (caeb_op>=6 & caeb_op<=8) & emp_ci==1 
replace rama_ci=7 if caeb_op==7 & emp_ci==1
replace rama_ci=8 if (caeb_op>=10 & caeb_op<=11) & emp_ci==1
replace rama_ci=9 if (caeb_op==9 | (caeb_op>=12 & caeb_op<=20)) & emp_ci==1
label var rama_ci "Rama de actividad"
label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val rama_ci rama_ci

****************
***durades_ci***
****************
gen durades_ci=.
replace durades_ci=s06a_08a/4.3  if s06a_08b==2
replace durades_ci=s06a_08a       if s06a_08b==4
replace durades_ci=s06a_08a*12   if s06a_08b==8
label variable durades_ci "Duracion del desempleo en meses"

*******************
***antiguedad_ci***
*******************
gen antiguedad_ci=.	
replace antiguedad_ci=s06b_14a/52.14  	if s06b_14b==2 & emp_ci==1
replace antiguedad_ci=s06b_14a/12   	if s06b_14b==4 & emp_ci==1
replace antiguedad_ci=s06b_14a	   		if s06b_14b==8 & emp_ci==1
label var antiguedad_ci "Antiguedad en la actividad actual en anios"

*******************
***categoinac_ci***
*******************
*Modificacion MLO, 2015 m4 (se cambió s5_14 por s6_09)
gen categoinac_ci =1 	  if (s06a_09==3 & condocup_ci==3)
replace categoinac_ci = 2 if  (s06a_09==1 & condocup_ci==3)
replace categoinac_ci = 3 if  (s06a_09==2 & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"

*******************
***formal***
*******************
gen formal=1 if cotizando_ci==1

replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringe a ocupados solamente*/
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c>1998
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008

gen byte formal_ci=.
replace formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
replace formal_ci=0 if formal_ci==. & (condocup_ci==1 | condocup_ci==2) 
label var formal_ci "1=afiliado o cotizante / PEA"

g formal_1=afiliado_ci


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

	ynlm_ci: Ingreso no laboral monetario publico			
			
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

	ynlm_ch: Ingreso no laboral monetario del hogar
			Se suman los ingresos no laborales monetarios (ynlm_ci) de
			los miembros del hogar			
			
	ytot_ch: Ingreso mensual total del hogar
			Se suman todos los ingresos del hogar: ylm_ch, ylnm_ch, ynlm_ch, ynlnm_ch.
	
	ylmhopri_ci: Salario horario monetario de la actividad principal
			Se genera mediante las variables: ylm_ci y horastot_ci
	
	ylmho_ci: Salario horario monetario de todas las actividades.
			Se genera mediante las variables: ylmpri_ci y horaspri_ci
			
	nrylmpri_ci: Indica la no respuesta ingreso de la actividad principal.
			Se genera cuando un individuo no reporta ingresos laborales (ylmpri_ci==. ) y además la persona reporte estar ocupado (emp_ci==1)
			
	nrylmpri_ch: No respuesta a nivel hogar.
			Hogares con algún miembro que no respondió por ingresos
	
	remesas_ci: Variable continua que indica el monto mensual por remesas reportadas por el individuo en moneda local corriente.
	
	remesas_ch: Variable continua que indica el monto mensual por remesas del hogar. 
			Esta variable se genera a partir de la variable remesas_ci.

	ypen_ci: Ingreso por pensión contributiva
	
	ypensub_ci: Ingreso por pensión no contributiva.
*/


**********************************************
*** II. GENERACIÓN DE VARIABLES AUXILIARES ***		
**********************************************

*************************
******NO-LABORAL*********
*************************

*************
* intereses *
*************
gen yinteres = .
replace yinteres = s07a_02a	

**************
* alquileres *
**************

gen yalqui = .
replace yalqui = s07a_02b	


****************
* otras rentas *
****************

gen yotren = .
replace yotren = s07a_02c

**************
* jubilacion *
**************

gen yjubi = .
replace yjubi = s07a_01a 

**************
* benemerito *
**************

gen ybene = .
replace ybene = s07a_01b 

*************
* invalidez *
*************

gen yinvali = .
replace yinvali = s07a_01c

**********
* viudez *
**********

gen yviudez = .
replace yviudez = s07a_01d  


************************
* alquileres agricolas *
************************

gen yalqagri = .
replace yalqagri =  s07a_03a/12		


**************
* dividendos *
**************

gen ydivi = .
replace ydivi =  s07a_03b/12


*************************
* alquileres maquinaria *
*************************

gen yalqmaqui = .
replace yalqmaqui = s07a_03c/12

 
******************
* indem. trabajo *
******************

gen yindtr = .
replace yindtr =  s07a_04a/12


******************
* indem. seguros *
******************

gen yindseg = .
replace yindseg = s07a_04b/12


******************
* renta dignidad *
******************

gen ybono = .
replace ybono = s07a_01e0

******************
* otros ingresos *
******************

gen yotring = .
replace yotring = s07a_04c/12

*******************
* asist. familiar *
*******************
/*
  2  semanal
  3  quincenal
  4  mensual
  5  bimestral
  6  trimestral
  7  semestral
  8  anual
*/
* No hay la categoria de diario en s7b_5ab
gen yasistfam = .
replace yasistfam= s07b_05aa*4.3	if s07b_05ab==2
replace yasistfam= s07b_05aa*2		if s07b_05ab==3
replace yasistfam= s07b_05aa		if s07b_05ab==4
replace yasistfam= s07b_05aa/2		if s07b_05ab==5
replace yasistfam= s07b_05aa/3		if s07b_05ab==6
replace yasistfam= s07b_05aa/6		if s07b_05ab==7
replace yasistfam= s07b_05aa/12		if s07b_05ab==8

*********************
* Trans. monetarias *
*********************
* No hay la categoria de diario en s7b_5bb
gen 	ytransmon= .
replace ytransmon= s07b_05ba*4.3	if s07b_05bb==2
replace ytransmon= s07b_05ba*2		if s07b_05bb==3
replace ytransmon= s07b_05ba	    if s07b_05bb==4
replace ytransmon= s07b_05ba/2		if s07b_05bb==5
replace ytransmon= s07b_05ba/3		if s07b_05bb==6
replace ytransmon= s07b_05ba/6		if s07b_05bb==7
replace ytransmon= s07b_05ba/12		if s07b_05bb==8


***********
* remesas *
***********
/*
    MONEDA

A. BOLIVIANOS 
B. EUROS
C. DÓLARES
D. PESOS ARGENTINOS
E. REALES
F. PESOS CHILENOS
G. OTRO

https://www.bcb.gob.bo/?q=cotizaciones_tc
Al  3 DE ENERO DE 2017
*/

gen s6_112= .
replace s6_112 =  s07c_08a 			 if s07c_08b==1 /*bolivianos*/
replace s6_112 =  s07c_08a*7.22425   if s07c_08b==2 /*euro*/
replace s6_112 =  s07c_08a*6.96		 if s07c_08b==3 /*dolar*/
replace s6_112 =  s07c_08a*0.43199   if s07c_08b==4 /*peso argentino*/
replace s6_112 =  s07c_08a*2.10740   if s07c_08b==5 /*real*/
replace s6_112 =  s07c_08a*0.01023	 if s07c_08b==6 /*peso chileno*/
*replace s6_112 =  s07c_08a*2.00961   if s07c_08b==7 /*soles*/ En la 201 es Otro

* se suman remesas monetarias y en especie
egen rem = rsum(s07c_10 s6_112), m

gen yremesas = .
replace yremesas= rem*4.3		if s07c_07==2
replace yremesas= rem*2		    if s07c_07==3
replace yremesas= rem			if s07c_07==4
replace yremesas= rem/2			if s07c_07==5
replace yremesas= rem/3			if s07c_07==6
replace yremesas= rem/6			if s07c_07==7
replace yremesas= rem/12		if s07c_07==8

*****************************
* yliquido: salario líquido *
*****************************
/*s04c_17a:  ¿Cuánto es su salario líquido, excluyendo los descuentos de ley (AFP, IVA)? Monto (Bs)

s04c_17b: ¿Cuánto es su salario líquido, excluyendo los descuentos de ley (AFP, IVA)? Frecuencia de pago.
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
replace yliquido= s06c_25a*30	if s06c_25b==1
replace yliquido= s06c_25a*4.3	if s06c_25b==2
replace yliquido= s06c_25a*2	if s06c_25b==3
replace yliquido= s06c_25a		if s06c_25b==4
replace yliquido= s06c_25a/2	if s06c_25b==5
replace yliquido= s06c_25a/3	if s06c_25b==6
replace yliquido= s06c_25a/6	if s06c_25b==7
replace yliquido= s06c_25a/12	if s06c_25b==8


************************************
* ycomisio: Ingreso por comisiones *
************************************
*s04c_19aa: Durante los últimos doce meses, ¿recibió usted pagos en efectivo por: A.Comisiones, destajo, propinas, bonos de transporte o refrigerio? Monto (Bs)
gen ycomisio = .
replace ycomisio= s06c_27aa*30	if s06c_27ab==1
replace ycomisio= s06c_27aa*4.3	if s06c_27ab==2
replace ycomisio= s06c_27aa*2	if s06c_27ab==3
replace ycomisio= s06c_27aa		if s06c_27ab==4
replace ycomisio= s06c_27aa/2	if s06c_27ab==5
replace ycomisio= s06c_27aa/3	if s06c_27ab==6
replace ycomisio= s06c_27aa/6 	if s06c_27ab==7
replace ycomisio= s06c_27aa/12 	if s06c_27ab==8



**************************************
* yhrsextr: Ingreso por horas extras *
**************************************
* s04c_19ba - 19. Durante los últimos doce meses, ¿recibió usted pagos en efectivo por Horas Extras
gen yhrsextr= .
replace yhrsextr= s06c_27ba *30	    if s06c_27bb==1
replace yhrsextr= s06c_27ba *4.3  	if s06c_27bb==2
replace yhrsextr= s06c_27ba *2		if s06c_27bb==3
replace yhrsextr= s06c_27ba 		if s06c_27bb==4
replace yhrsextr= s06c_27ba /2		if s06c_27bb==5
replace yhrsextr= s06c_27ba /3		if s06c_27bb==6
replace yhrsextr= s06c_27ba /6	    if s06c_27bb==7
replace yhrsextr= s06c_27ba /12	    if s06c_27bb==8


************************************************
* yprima: Ingreso por prima/bono de producción *
************************************************
* s04c_18a - 18. Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Bono o prima de producción
gen yprima = .
replace yprima = s06c_26a/12


*******************************
* yaguina: Pago por aguinaldo *
*******************************
* s04c_18b - 18. Durante los últimos doce meses, ¿recibió usted pagos por:
* Pago por Aguinaldo
gen yaguina = .
replace yaguina = s06c_26b/12


*******************************************
* yactpri: ingreso actividad principal independientes *
*******************************************
*Aquí se tiene en cuenta el Ingreso Líquido de la Actividad Principal de los independientes 
* 24. Una vez descontadas todas sus obligaciones (sueldos, salarios, etc.),¿cuánto le queda para uso del hogar?
gen yactpri = .
replace yactpri= s06d_33a*30	if s06d_33b==1
replace yactpri= s06d_33a*4.3	if s06d_33b==2
replace yactpri= s06d_33a*2		if s06d_33b==3
replace yactpri= s06d_33a		if s06d_33b==4
replace yactpri= s06d_33a/2		if s06d_33b==5
replace yactpri= s06d_33a/3		if s06d_33b==6
replace yactpri= s06d_33a/6		if s06d_33b==7
replace yactpri= s06d_33a/12	if s06d_33b==8


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
* 31. ¿Cuánto es su salario líquido en ésta otra ocupación, excluyendolos descuentos de ley (AFP,IVA)?
gen yliquido2 = .
replace yliquido2= s06g_47a*30		if s06g_47b==1
replace yliquido2= s06g_47a*4.3		if s06g_47b==2
replace yliquido2= s06g_47a*2		if s06g_47b==3
replace yliquido2= s06g_47a			if s06g_47b==4
replace yliquido2= s06g_47a/2		if s06g_47b==5
replace yliquido2= s06g_47a/3		if s06g_47b==6
replace yliquido2= s06g_47a/6		if s06g_47b==7
replace yliquido2= s06g_47a/12		if s06g_47b==8

*****************
* yhrsextr2: Ingreso por horas extra de la actividad secundaria*
*****************
* 32. Durante los últimos doce meses, ha recibido:
* A. ¿Pago por horas extras, bono o prima de producción,aguinaldo?
gen yhrsextr2 = .
replace yhrsextr2=s06g_48a1/12 if s06g_48a==1


*************
* yalimen: Ingreso en alimentos *
*************
gen yalimen = .
replace yalimen= s06c_30a2 *30		if s06c_30a1 ==1 & s06c_30a==1
replace yalimen= s06c_30a2 *4.3 	if s06c_30a1 ==2 & s06c_30a==1
replace yalimen= s06c_30a2 *2		if s06c_30a1 ==3 & s06c_30a==1
replace yalimen= s06c_30a2 		    if s06c_30a1 ==4 & s06c_30a==1
replace yalimen= s06c_30a2 /2		if s06c_30a1 ==5 & s06c_30a==1
replace yalimen= s06c_30a2 /3		if s06c_30a1 ==6 & s06c_30a==1
replace yalimen= s06c_30a2 /6		if s06c_30a1 ==7 & s06c_30a==1
replace yalimen= s06c_30a2 /12		if s06c_30a1 ==8 & s06c_30a==1


**************
* ytranspo: Ingreso en transporte *
**************
* PARTE C: INGRESOS DEL TRABAJADOR ASALARIADO
* 21. Además de los ingresos recibidos en dinero por su trabajo, en los últimos doce meses ¿recibió, usted...
* B. Transporte hacia y desde el lugar de su trabajo?
gen ytranspo = .
replace ytranspo= s06c_30b2*30	    if s06c_30b1==1 & s06c_30b==1
replace ytranspo= s06c_30b2*4.3	    if s06c_30b1==2 & s06c_30b==1
replace ytranspo= s06c_30b2*2		if s06c_30b1==3 & s06c_30b==1
replace ytranspo= s06c_30b2 	    if s06c_30b1==4 & s06c_30b==1
replace ytranspo= s06c_30b2/2		if s06c_30b1==5 & s06c_30b==1
replace ytranspo= s06c_30b2/3		if s06c_30b1==6 & s06c_30b==1
replace ytranspo= s06c_30b2/6		if s06c_30b1==7 & s06c_30b==1
replace ytranspo= s06c_30b2/12	    if s06c_30b1==8 & s06c_30b==1


**************
* yvesti: Ingreso en vestimenta *
**************
gen yvesti = .
replace yvesti= s06c_30c2*30		if s06c_30c1==1 & s06c_30c==1
replace yvesti= s06c_30c2*4.3		if s06c_30c1==2 & s06c_30c==1
replace yvesti= s06c_30c2*2		    if s06c_30c1==3 & s06c_30c==1
replace yvesti= s06c_30c2			if s06c_30c1==4 & s06c_30c==1
replace yvesti= s06c_30c2/2		    if s06c_30c1==5 & s06c_30c==1
replace yvesti= s06c_30c2/3		    if s06c_30c1==6 & s06c_30c==1
replace yvesti= s06c_30c2/6		    if s06c_30c1==7 & s06c_30c==1
replace yvesti= s06c_30c2/12		if s06c_30c1==8 & s06c_30c==1


************
* yvivien: Ingreso en vivienda *
************
gen yvivien = .
replace yvivien= s06c_30d2*30		if s06c_30d1==1 & s06c_30d==1
replace yvivien= s06c_30d2*4.3	    if s06c_30d1==2 & s06c_30d==1
replace yvivien= s06c_30d2*2		if s06c_30d1==3 & s06c_30d==1
replace yvivien= s06c_30d2		    if s06c_30d1==4 & s06c_30d==1
replace yvivien= s06c_30d2/2		if s06c_30d1==5 & s06c_30d==1
replace yvivien= s06c_30d2/3		if s06c_30d1==6 & s06c_30d==1
replace yvivien= s06c_30d2/6		if s06c_30d1==7 & s06c_30d==1
replace yvivien= s06c_30d2/12		if s06c_30d1==8 & s06c_30d==1


*************
* yotros: Otros ingresos no monetarios *
*************
gen yotros = .
replace yotros= s06c_30e2*30	if s06c_30e1==1 & s06c_30e==1
replace yotros= s06c_30e2*4.3	if s06c_30e1==2 & s06c_30e==1
replace yotros= s06c_30e2*2	    if s06c_30e1==3 & s06c_30e==1
replace yotros= s06c_30e2		if s06c_30e1==4 & s06c_30e==1
replace yotros= s06c_30e2/2	    if s06c_30e1==5 & s06c_30e==1
replace yotros= s06c_30e2/3		if s06c_30e1==6 & s06c_30e==1
replace yotros= s06c_30e2/6		if s06c_30e1==7 & s06c_30e==1
replace yotros= s06c_30e2/12	if s06c_30e1==8 & s06c_30e==1


*************
* yalimen2: Ingreso en alimentos de la actividad secundaria *
*************
gen yalimen2 = .
replace yalimen2=s06g_48b1/12	if s06g_48b==1


**************
* yvivien2: Ingreso en vivienda de la actividad secundaria *
**************
*Modificación Cesar Lins - Feb 2021, replaced by 2017 variable names
gen yvivien2= .
replace yvivien2 = s06g_48c1/12	if s06g_48c==1


**************************************************************
*** III. CONSTRUCCIÓN DE LAS VARIABLES ARMONIZADAS DEL BID ***		
**************************************************************

*****************************************
*A. INGRESOS LABORALES A NIVEL INDIVIDUO* 
*****************************************

***************
***A.1.1 ylmpri_ci: Ingreso laboral monetario de actividad principal: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia). Considera ingresos corrientes y extraordinarios.***
***************
egen ylmpri_ci=rsum(yliquido ycomisio yhrsextr yprima yaguina yactpri), missing
replace ylmpri_ci=. if yliquido ==. & ycomisio ==. &  yhrsextr ==. & yprima ==. &  yaguina ==. &  yactpri==.  
replace ylmpri_ci=. if emp_ci~=1
replace ylmpri_ci=0 if categopri_ci==4
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 


***************
***A.1.2 ylmsec_ci: Ingreso laboral monetario de actividad secundaria. Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria.***
***************
egen ylmsec_ci= rsum(yliquido2 yhrsextr2), missing
replace ylmsec_ci=. if emp_ci~=1 & yhrsextr2==. & yliquido2 ==.
replace ylmsec_ci=0 if categosec_ci==4
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 


*****************
***A.1.3 ylmotros_ci: Ingreso laboral monetario de otras actividades. Variable continua que indica el monto mensual de ingresos monetarios provenientes de actividades distintas de la principal y secundaria. Incluye ingresos percibidos por desocupados o inactivos derivados de trabajos previos al cese. ***
*****************
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 


************
***A.1 ylm_ci: Ingreso laboral monetario total: Variable continua que indica el monto mensual total de ingresos laborales monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylmpri_ci, ymsec_ci e ylnmotros_ci.***
************
egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso laboral monetario total"


******************
***A.2.1 ylnmpri_ci: Ingreso laboral no monetario de actividad principal. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad principal de cada miembro del hogar. ***
******************
egen ylnmpri_ci=rsum(yalimen ytranspo yvesti yvivien yotros), missing
replace ylnmpri_ci=. if yalimen==. & ytranspo==. & yvesti==. & yvivien==. & yotros==.   
replace ylnmpri_ci=0 if categopri_ci==4


******************
****A.2.2 ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar. ****
******************
egen ylnmsec_ci=rsum(yalimen2  yvivien2), missing
replace ylnmsec_ci=. if yalimen2==.  & yvivien2==.  
replace ylnmsec_ci=0 if categosec_ci==4
replace ylnmsec_ci=. if emp_ci==0
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"


******************
***A.2.3 ylnmotros_ci: Ingresos laboral no monetario de otras actividades. Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de actividades distintas de la principal y/o secundaria de cada miembro del hogar.***
******************
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 


*************
***A.2 ylnm_ci: Ingreso laboral no monetario. Variable continua que indica el monto mensual total de ingresos laborales no monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylnmpri_ci, ylnmsec_ci e ylnmotros_ci.***
*************
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci), missing
replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==.
label var ylnm_ci "Ingreso laboral NO monetario total" 


********************************************
*B.	Ingresos no laborales a nivel individuo*
********************************************

****************
*B.1 ynlm_ci: Ingreso no laboral monetario público del individuo. Variable continua que indica el monto mensual del ingreso no laboral MONETARIO proveniente de otras fuentes no laborales.* 
**************** 
egen ynlm_ci=rsum(yinteres yalqui yjubi ybene yinvali yviudez yotren yalqagri ydivi yalqmaqui yindtr yindseg ybono yotring yasistfam ytransmon yremesas ), missing
replace ynlm_ci=. if 	yinteres==. & yalqui==. & yjubi==. & ybene==. & yinvali==. & yviudez==. & yotren==. & yalqagri==. & ydivi==. & yalqmaqui==. & yindtr==. & yindseg==. & ///
			ybono==. & yotring==. & yasistfam==. & ytransmon==. & yremesas==. 
label var ynlm_ci "Ingreso no laboral monetario"  


**************
*B.2 ynlnm_ci: Ingreso no laboral no monetario. Variable continua que indica el monto mensual del ingreso no laboral no monetario (otras fuentes). En esta categoría se encuentran otros beneficios y transferencias no monetarias como las donaciones en alimentos, útiles escolares, becas, entre otros.***
**************
*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
gen ynlnm_ci=.
label var ynlnm_ci "Ingreso no laboral no monetario" 


*******************************************
*C.	Ingresos totales a nivel de individuo**
*******************************************
**************
***C.1 ytot_ci: Ingreso mensual total del individuo que incluye las variables ylm_ci ylnm_ci ynlm_ci ynlnm_ci. ***
**************
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci),mi


****************************************************
*D.	Ingresos laborales y no laborales a nivel hogar*
****************************************************

**************
***D.1 ylm_ch: Variable continua que indica el monto mensual del ingreso laboral monetario del hogar, ignora las `No respuesta'.**
**************
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
label var ylm_ch "Ingreso laboral monetario del hogar" 


***************
***D.2 ylnm_ch: Ingreso laboral no monetario del hogar. Variable continua que indica el monto del ingreso laboral no monetario del hogar. ***
***************
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
label var ylnm_ch "Ingreso laboral no monetario del hogar"


****************
***D.3 ynlnm_ch: Ingreso no laboral no monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral no monetario del hogar (otras fuentes). ***
****************
*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

***********
***D.4 ynlm_ch: Ingreso no laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral monetario del hogar (otras fuentes). Es la suma de ynlm_publico_ch y ynlm_privado_ch.*
***********
by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing
label var ynlm_ch "Ingreso no laboral monetario del hogar"


***********************************
*E.	Ingresos totales a nivel hogar*
***********************************

**************
***E.1 ytot_ch: Ingreso mensual total del hogar *
**************
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi



*********************
*F.	Salario por hora*
*********************

*****************
***F.1 ylmhopri_ci: Variable continua que indica el monto del salario horario monetario de la actividad principal ***
*****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
label var ylmhopri_ci "Salario horario monetario de la actividad principal"


***************
***F.2 ylmho_ci: Variable continua que indica el monto del salario horario monetario de todas las actividades.*
****************
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario horario monetario de todas las actividades" 



*****************
*G.	No respuesta*
*****************

****************
*G.1 nrylmpri_ci: No respuesta a nivel individuo. Indica la no respuesta ingreso de la actividad principal. Para construir esta variable, se tiene en cuenta que no reporte ingresos laborales (ylmpri_ci==. ) y además la persona reporte estar ocupado (emp_ci==1)* 
**************** 
*Código extraído del manual
gen byte nrylmpri_ci = .
replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci ==1


****************
*G.2 nrylmpri_ch: No respuesta a nivel hogar. Hogares con algún miembro que no respondió por ingresos* 
**************** 
*Código extraído del manual
*************
by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
replace nrylmpri_ch = . if nrylmpri_ch == .


************
*H.	Remesas*
************

****************
*H.1 remesas_ci: Variable continua que indica el monto mensual por remesas reportadas por el individuo en moneda local corriente.* 
**************** 
gen remesas_ci=yremesas
label var ylmho_ci "Remesas reportadas por el individuo " 


****************
*H.2 remesas_ch: Variable continua que indica el monto mensual por remesas del hogar. Esta variable se genera a partir de la variable remesas_ci.* 
**************** 
by idh_ch, sort: egen byte remesas_ch = sum(remesas_ci) if miembros_ci == 1
label var ylmho_ci "Remesas del hogar" 


**************
*I.	Pensiones*
**************

*************
*I.1 ypen_ci: Ingreso por pensión contributiva: Variable continua que indica el monto mensual en moneda local corriente efectivamente recibido por el individuo por pensiones contributivas en sus distintas modalidades (jubilación, vejez, pensión, etc).*
*************
egen ypen_ci = rsum(s07a_01a s07a_01b s07a_01c s07a_01d), missing
label var ypen_ci "Valor de la pension contributiva"

*****************
**I.2 ypensub_ci: Ingreso por pensión no contributiva: Variable continua que indica el monto mensual en moneda local corriente recibido por la persona por pensiones no contributivas (adultos mayores).*
*****************
gen  ypensub_ci=s07a_01e0 
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

*_____________________________________________________________________________________________________*

*  Pobres extremos, pobres moderados, vulnerables y no pobres 
* con base en ingreso neto (Sin transferencias)
* y líneas de pobreza internacionales
gen     grupo_int = 1 if (y_pc_net<lp31_2011)
replace grupo_int = 2 if (y_pc_net>=lp31_2011 & y_pc_net<(lp31_2011*1.6))
replace grupo_int = 3 if (y_pc_net>=(lp31_2011*1.6) & y_pc_net<(lp31_2011*4))
replace grupo_int = 4 if (y_pc_net>=(lp31_2011*4) & y_pc_net<.)

tab grupo_int, gen(gpo_ingneto)

* Crear interacción entre recibirla la PTMC y el gpo de ingreso
gen ptmc_ingneto1 = 0
replace ptmc_ingneto1 = 1 if ptmc_ch == 1 & gpo_ingneto1 == 1

gen ptmc_ingneto2 = 0
replace ptmc_ingneto2 = 1 if ptmc_ch == 1 & gpo_ingneto2 == 1

gen ptmc_ingneto3 = 0
replace ptmc_ingneto3 = 1 if ptmc_ch == 1 & gpo_ingneto3 == 1

gen ptmc_ingneto4 = 0
replace ptmc_ingneto4 = 1 if ptmc_ch == 1 & gpo_ingneto4 == 1

lab def grupo_int 1 "Pobre extremo" 2 "Pobre moderado" 3 "Vulnerable" 4 "No pobre"
lab val grupo_int grupo_int


/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch BOL_dis_ci /// Diversidad
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


/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo) 
BOLIVIA usaba para las EIHs usaba como referencia el CIUO -88 */
rename s06b_11a_cod codocupa
rename caeb_op codindustria

compress


*Modificación Cesar Lins - Feb 2021 / saveold didn't work because labels are too long
save "`base_out'", replace 


log close

	