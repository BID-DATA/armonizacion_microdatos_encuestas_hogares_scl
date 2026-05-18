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

local PAIS HND
local ENCUESTA EPHPM
local ANO "2021"
local ronda m6 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   



capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Honduras
Encuesta: EPHPM
Round: m6
Autores: 
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
* no disponible base septiembre hasta el momento
****************************************************************************/


use "`base_in'", clear

foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }

		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************
	
********
*anio_c*
********
gen anio_c = 2021

*******
*mes_c*
*******
gen mes_c = 6
label define mes_c 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre" 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto"
label value mes_c mes_c

********
*pais_c*
********
gen pais_c = "HND"

****************
* region_BID_c *
****************
	
gen region_BID_c= 1 

label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

************
* Region_c *
************
gen region_c = dominio
destring region_c, replace

/* En 2021 la encuesta presenta ciudades
1. - Distrito Central --> Francisco Morazan
2. - San Pedro Sula --> Cortes
3. - Ciudades medianas --> Varios departamentos
4. - Ciudades Pequeñas --> Varios departamentos
5. - Rural --> Varios departamentos*/ 

label define region_c  ///
           1 "Francisco Morazan" ///
           2 "Cortes" ///
		   3 "Ciudades medianas" ///
           4 "Ciudades pequeñas" ///
           5 "Rural"
 
label value region_c region_c
label var region_c "Division política, departamentos"

********
*zona_c*
********
gen zona_c = 1 if dominio == 1 | dominio == 2 | dominio == 3 
replace zona_c = 0 if dominio == 4 | dominio == 5
label define zona_c 0 "Rural" 1 "Urbana" 
label value zona_c zona_c

***************
**estrato_ci***
***************
gen estrato_ci = .
label variable estrato_ci "Estrato"

***************
***upm_ci******
***************
* Cada una de estas UPM tiene en promedio 90 viviendas, no identificables 
gen upm_ci = .
label variable upm_ci "Unidad Primaria de Muestreo"

********
*idh_ch*
********
* se clona variable ya que de la forma tradicional se generan hogares de 52 miembros en lugar de 16 miembros como lo indica la variable.
clonevar idh_ch = hogar
format hogar %14.0g
format idh_ch %14.0g
tostring idh_ch, replace


********
*idp_ci*
********
gen idp_ci = string(hogar) + string(nper)
tostring idp_ci, replace


***********
*factor_ci*
***********
* La encuesta es por hogares, no hay factor para individuos, por consistencia se mantiene mismo valor que variable factor
gen factor_ci=factor
label var factor_ci "Factor de Expansion de los individuos"

***********
*factor_ch*
***********
gen factor_ch = factor
label var factor_ch "Factor de Expansion del Hogar"


	****************************
	***VARIABLES DEMOGRAFICAS***
	****************************
	
*********
*sexo_ci*
*********
gen sexo_ci = ch03
label var sexo "Sexo del Individuo"
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

*********
*edad_ci*
*********
gen edad_ci = ch04 
label var edad_ci "Edad del Individuo"

*************
*relacion_ci*
*************
gen relacion_ci=.
replace relacion_ci = 1 if ch02 == 1
replace relacion_ci = 2 if ch02 == 2
replace relacion_ci = 3 if ch02 == 3 | ch02 == 4
replace relacion_ci = 4 if ch02 >= 5 & ch02 <= 8 
replace relacion_ci = 5 if ch02 == 9
replace relacion_ci = 6 if ch02 == 10
label var relacion_ci "Relacion con el Jefe de Hogar"
label define relacion_ci 1 "Jefe de Hogar" 2 "conyuge" 3 "Hijos" 4 "Otros Parientes" 5 "Otros no Parientes" 6 "Servicio Domestico"
label value relacion_ci relacion_ci

**********
*civil_ci*
**********
gen civil_ci=.
replace civil_ci = 1 if ch05 == 5
replace civil_ci = 2 if ch05 == 1 | ch05 == 6
replace civil_ci = 3 if ch05 == 3 | ch05 == 4
replace civil_ci = 4 if ch05 == 2
label var civil_ci "Estado Civil"
label define civil_ci 1 "Soltero" 2 "Union Formal o Informal" 3 "Divorciado o Separado" 4 "Viudo"
label value civil_ci civil_ci

*************
***jefe_ci***
*************
gen jefe_ci = (relacion_ci==1)
label variable jefe_ci "Jefe de hogar"

******************
***nconyuges_ch***
******************
by idh_ch, sort: egen nconyuges_ch = sum(relacion_ci == 2)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************
by idh_ch, sort: egen nhijos_ch = sum(relacion_ci == 3)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************
by idh_ch, sort: egen notropari_ch = sum(relacion_ci == 4)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************
by idh_ch, sort: egen notronopari_ch = sum(relacion_ci == 5)
label variable notronopari_ch "Numero de no familiares"

****************
***nempdom_ch***
****************
****************
by idh_ch, sort: egen nempdom_ch = sum(relacion_ci == 6)
label variable nempdom_ch "Numero de empleados domesticos"

****************
***clasehog_ch***
*****************
gen byte clasehog_ch=0
**** unipersonal
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
**** nuclear   (child with or without spouse but without other relatives)
replace clasehog_ch=2 if (nhijos_ch>0 | nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
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

****************
***miembros_ci***
****************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"

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


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	
	*********
	*ind_ci*
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

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
	gen byte HND_dis_ci = .


	************************************
	*** VARIABLES DEL MERCADO LABORAL***
	************************************
	
****************
****condocup_ci*
****************
/*
Siguiendo la metodlogía planteada por la autoridad estadística

DESOCUPADOS = Hacen parte de los desocupados los cesantes, los aspirantes y 
los iniciadores.

no es posible calcular los aspirantes e iniciadores en esta encuesta, la edad mínima cambia a 15 26/9/2021
*/
* Comprobacion con variables originales.  Se considera ocupado a quienes estan en trabajos no remunerados. 5/28/2014 MGD
* La edad minima de la encuesta se cambia a 5 anios.

gen condocup_ci = .
replace condocup_ci = 1 if !missing(categop) & edad_ci >= 15
by idh_ch, sort: egen perd_trabajo = total(ed043)
* Solamente se puede identificar a los cesantes de la población desocupada
gen cesantes = 1 if condocup_ci == 1 & perd_trabajo > 0 
replace condocup_ci = 2 if cesantes == 1
replace condocup_ci = 3 if missing(condocup_ci) & edad_ci >= 15
replace condocup_ci = 4 if edad_ci < 15

label var condocup_ci "Condición de ocupación de acuerdo a definición de cada país"
label define condocup_ci  1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 15" 
label values condocup_ci condocup_ci
drop perd_trabajo cesantes

*******************
***categoinac_ci***
*******************
gen categoinac_ci = . // Sólo el 2021 no se realizó la pregunta de razones de inactividad
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"
label values categoinac_ci categoinac_ci

************
***emp_ci***
************
gen emp_ci = condocup_ci == 1

*************
*nempleos_ci*
*************
gen nempleos_ci = .
replace nempleos_ci = 1 if condocup_ci == 1
replace nempleos_ci = 2 if condocup_ci == 1 & il26_1 == 1
replace nempleos_ci = 3 if il26_1 == 1 & il26_2 == 1
replace nempleos_ci = 4 if il26_2 == 1 & il26_3 == 1

***************
*antiguedad_ci*
***************
generat antiguedad_ci =.
label var antiguedad_ci "Antiguedad en la Ocupacion Actual (en anios)"

****************
***desemp_ci***
****************
gen desemp_ci = condocup_ci == 2

*************
*cesante_ci* 
*************
gen cesante_ci =.
by idh_ch, sort: egen perd_trabajo = total(ed043)
replace cesante_ci = 1 if !missing(categop) & edad_ci >= 15 & perd_trabajo > 0
label var cesante_ci "Desocupado - definicion oficial del pais"
drop perd_trabajo

************
*durades_ci*
************
gen durades_ci =.
label var durades "Duracion del Desempleo (en meses)"

*************
***pea_ci***
*************
gen pea_ci = (emp_ci == 1 | desemp_ci == 1)

*************
*desalent_ci*
*************
gen desalent_ci =.

*************
*horaspri_ci*
*************
* No hay variable para horas trabajadas en esta encuesta, solo las horas extra
gen horaspri_ci = .

************
*horastot_ci
************
* No hay variable para horas trabajadas en esta encuesta, solo las horas extra
gen horastot_ci = .

***********
*subemp_ci*
***********
gen subemp_ci = .
label var subemp_ci "Trabajadores subempleados"

***************
*tiempoparc_ci*
***************
gen tiempoparc_ci = . 
label var tiempoparc_ci "Trabajadores a medio tiempo"

**************
*categopri_ci*
**************
gen categopri_ci = .
replace categopri_ci = 1 if (cp526 == 7) | (cp526 == 8)  
replace categopri_ci = 2 if (cp526 == 6) | (cp526 == 5)  
replace categopri_ci = 3 if (cp526 <= 4)
replace categopri_ci = 4 if (cp526 == 9)

label var categopri_ci "Categoria ocupacional actividad principal"
label define categopri_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
label values categopri_ci categopri_ci

****************
* categosec_ci *
****************
gen categosec_ci = .
replace categosec_ci = 1 if (cp542 == 7) | (cp542 == 8)
replace categosec_ci = 2 if (cp542 == 6) | (cp542 == 5) 
replace categosec_ci = 3 if cp542 <= 4 
replace categosec_ci = 4 if cp542 == 9

label var categosec_ci "Categoria ocupacional actividad secundaria"
label define categosec_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
label value categosec_ci categosec_ci

*********
*rama_ci*
*********
*No se puede identificar la rama en esta encuesta
gen rama_ci = .

label var rama_ci "Rama de actividad"
label val rama_ci rama_ci

*************
*spublico_ci*
*************
gen spublico_ci = (cp526 == 1)

*************
*tamemp_ci
*************
* Honduras. Pequeña 1-5, Mediana 6-50, Grande Más de 50.
* No es posible calcularlo en esta encuesta
gen tamemp_ci = .

****************
*cotizando_ci***
****************
gen cotizando_ci = .
replace cotizando_ci = 1 if (oih01_lps >= 1 | oih01_us >= 1) 
replace cotizando_ci = 0 if (missing(oih01_lps) | missing(oih01_us)) & (condocup_ci == 2 | condocup_ci == categopri_ci == 2)

label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0 "No cotiza" 1 "Cotiza a la SS" 
label value cotizando_ci cotizando_ci

****************
*instcot_ci*****
****************
* 2021 No se puede calcular esta variable en esta encuesta
*DZ Marzo 2019: Se genera la variable como missing value ya que (cp517) tiene múltiple respuesta, y no se puede decidir arbitrariamente a cual de las instituciones se asocia*
gen instcot_ci = .
/*
replace instcot_ci=1 if ce433_1==1
replace instcot_ci=2 if ce433_2==1
replace instcot_ci=3 if ce433_3==1
replace instcot_ci=4 if ce433_4==1
replace instcot_ci=5 if ce433_5==1
replace instcot_ci=6 if ce433_6==1
replace instcot_ci=7 if ce433_7==1
replace instcot_ci=8 if ce433_8==1
replace instcot_ci=9 if ce433_9==1
replace instcot_ci=10 if ce433_10==1


label define instcot_ci 1 "rap" 2 "injupemp" 3 "inprema" 4"ipm" 5 "ihss" 6 "Fondo privado de pensiones" 7 "Seguro medico privado" 8 "Gremio o asociacion de trabajadores" 9 "Ninguna de las anteriores" 10 "Otro"
label value instcot_ci instcot_ci  
label var instcot_ci "Institucion proveedora de la pension - variable original de cada pais" 
*/

****************
*afiliado_ci****
****************
gen afiliado_ci = .
label var afiliado_ci "Afiliado a la Seguridad Social"

*******************
*****formal_ci*****
*******************
gen formal_ci = ((cotizando_ci == 1 | afiliado_ci ==1) & condocup_ci == 1)


*****************
*tipocontrato_ci*
*****************
/*
        CE34B-433 ¿Esta trabajando bajo |
                              contrato? |      Freq.     Percent        Cum.
----------------------------------------+-----------------------------------
        1. Contrato indiviudal temporal |        652       11.06       11.06
2. Contrato individual permanente/acuer |      2,555       43.33       54.38
                  3. Contrato colectivo |         48        0.81       55.20
                      4. Acuerdo verbal |      2,581       43.77       98.97
                 9. No sabe/no responde |         61        1.03      100.00
----------------------------------------+-----------------------------------
                                  Total |      5,897      100.00
 
*/
/*
gen tipocontrato_ci=.
replace tipocontrato_ci= 1 if ce34==2 |ce34==3 
replace tipocontrato_ci= 2 if ce34==1
replace tipocontrato_ci= 3 if ce34==4

* MOdificacion condicionada a categopri==3 MGD
gen tipocontrato_ci=.
replace tipocontrato_ci= 1 if (ce434==2 | ce434==3 ) & categopri_ci==3
replace tipocontrato_ci= 2 if ce434==1 & categopri_ci==3
replace tipocontrato_ci= 3 if (ce434==4  & tipocontrato_ci==.) & categopri_ci==3 
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
*/
gen tipocontrato_ci = .


***************
****ocupa_ci***
***************
/*gen oc= ce425cod
tostring oc, replace
gen labor=substr(oc,1,4)
destring labor, replace 
drop oc

gen ocupa_ci=.
replace ocupa_ci=1 if labor>=2000 & labor<=3999 & emp_ci==1
replace ocupa_ci=2 if labor>=1000 & labor<=1999 & emp_ci==1
replace ocupa_ci=3 if labor>=4000 & labor<=4999 & emp_ci==1
replace ocupa_ci=4 if ((labor>=5200 & labor<=5299) | (labor>=9100 & labor<=9119)) & emp_ci==1
replace ocupa_ci=5 if ((labor>=5100 & labor<=5199) | (labor>=9120 & labor<=9169)) & emp_ci==1
replace ocupa_ci=6 if ((labor>=6000 & labor<=6999) | (labor>=9210 & labor<=9213)) & emp_ci==1
replace ocupa_ci=7 if ((labor>=7000 & labor<=8999) | (labor>=9311 & labor<=9333)) & emp_ci==1
replace ocupa_ci=8 if labor>0 & labor<=9999 & emp_ci==1 & ocupa_ci==.
replace ocupa_ci=9 if labor==9999 & emp_ci==1
drop labor 

label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci*/
* No es posible identificar esta varaiable en esta encuesta
gen ocupa_ci = .

***************
*pensionsub_ci*
***************
*gen pensionsub_ci=1 if ypensub_ci!=. 
* 2014, 01 Revision MLO
*2021 No es posible identificar si la pension o jubilación es contributiva o no contributiva
gen pensionsub_ci = .

*************
**pension_ci*
*************
*2021 No es posible identificar si la pension o jubilación es contributiva o no contributiva
gen pension_ci = .

****************
***tipopen_ci***
****************
gen tipopen_ci = .
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

****************
***instpen_ci***
****************
gen instpen_ci = .
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 



	************************************
	******* VARIABLES DE INGRESO *******
	************************************
	
***************
***ylmpri_ci***
***************
egen ylmpri_ci = rowtotal(ysmop ycmop), missing
label var ylmpri_ci "Ingreso Laboral Monetario de la Actividad Principal"

************
*ylnmpri_ci*
************
egen ylnmpri_ci = rowtotal(yseop yceop), missing
label var ylnmpri_ci "Ingreso Laboral No Monetario de la Actividad Principal"

***********
*ylmsec_ci*
***********
egen ylmsec_ci = rowtotal(ysmos ycmos), missing
label var ylmsec_ci "Ingreso Laboral Monetario de la Actividad Secundaria"

************
*ylnmsec_ci*
************
egen ylnmsec_ci = rowtotal(yseos yceos), missing
label var ylnmsec_ci "Ingreso Laboral No Monetario de la Actividad Secundaria"

*****************
***ylmotros_ci***
*****************
gen ylmotros_ci = .
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos"

******************
***ylnmotros_ci***
******************
gen ylnmotros_ci = .
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

************
***ylm_ci***
************
egen ylm_ci = rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
label var ylm_ci "Ingreso laboral monetario total"

*************
***ylnm_ci***
*************
egen ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
label var ylnm_ci "Ingreso laboral NO monetario total"  

*************
***ynlm_ci***
*************
egen ynlm_ci = rsum(oih01_lps oih02_lps oih03_lps oih04 oih05_lps oih06_lps oih07_lps oih11 oih12_lps oih13 oih14 oih15), missing
label var ynlm_ci "Ingreso No Laboral Monetario"

**************
***ynlnm_ci***
**************
egen ynlnm_ci = rsum(oih08 oih09 oih10), missing 
label var ynlnm_ci "Ingreso No Laboral No Monetario" 
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)


**************
*** ylm_ch ***
**************
by idh_ch, sort: egen ylm_ch = sum(ylm_ci) if miembros_ci == 1, missing 
label var ylm_ch "Ingreso laboral monetario del hogar"

***************
*** ylnm_ch ***
***************
by idh_ch, sort: egen ylnm_ch = sum(ylnm_ci) if miembros_ci == 1, missing 
label var ylnm_ch "Ingreso laboral no monetario del hogar"

*****************
***nrylmpri_ci***
*****************
gen nrylmpri_ci = .
replace nrylmpri_ci = 1 if missing(ylmpri_ci) & emp_ci == 1
replace nrylmpri_ci = . if emp_ci != 1 | categopri_ci == 4
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  


*******************
*** nrylmpri_ch ***
*******************
by idh_ch, sort: egen sum_nrylmpri = total(nrylmpri_ci)
gen nrylmpri_ch = 1 if sum_nrylmpri > 0
label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"
drop sum_nrylmpri

****************
*** ylmnr_ch ***
****************
by idh_ch, sort: egen ylmnr_ch = sum(ylm_ci) if miembros_ci == 1, missing 
replace ylmnr_ch = . if nrylmpri_ch == 1
label var ylmnr_ch "Ingreso laboral monetario del hogar"

***************
*** ynlm_ch ***
***************
by idh_ch, sort: egen ynlm_ch = sum(ynlm_ci) if miembros_ci == 1, missing 
label var ynlm_ch "Ingreso no laboral monetario del hogar"

**************
***ynlnm_ch***
**************
by idh_ch, sort: egen ynlnm_ch = sum(ynlnm_ci) if miembros_ci == 1, missing 
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

*****************
***ylmhopri_ci***
*****************
gen ylmhopri_ci = .
label var ylmhopri_ci "Salario monetario de la actividad principal" 

***************
***ylmho_ci ***
***************
gen ylmho_ci = .
label var ylmho_ci "Salario monetario de todas las actividades" 

****************
***remesas_ci***
****************
egen remesas_ci = rsum(oih12_lps oih12_lps_esp), missing
label var remesas_ci "Remesas Individuales"

****************
***remesas_ch***
****************
bys idh_ch: egen remesas_ch = sum(remesas_ci) if miembros_ci==1, missing
label var remesas_ch "Remesas mensuales del hogar"

*************
**ypen_ci*
*************
/*gen pension1= oih1_lps/3 
gen jubilacion1= oih2_lps/3
egen ypen_ci=rsum(pension1 jubilacion1), missing
label var ypen_ci "Valor de la pension contributiva"*/
* DZ Sep 2017: corrección se le agrega la pensión y jubilación recibida en usd**
* 2021 Hay monto por pensiones pero no se puede identificar, pensión contributiva y no contributiva
gen ypen_ci = .
label var ypen_ci "Valor de la pension contributiva"

*****************
**ypensub_ci*
*****************
gen ypensub_ci = .
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"



	************************************
	****** VARIABLES DE EDUCACIÓN ******
	************************************

*************
***aedu_ci***
*************
* No hay años de escolaridad en 2021, sacamos la variable de las dicótomicas del máximo nivel alcanzado
gen aedu_ci = .

**************
* Line of code with indicator eduno_ci was deleted**************
* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted
***************
***edupre_ci***
***************
gen edupre_ci = (ed051 == 1)
la var edupre_ci "Tiene Educacion preescolar"

**************
* Line of code with indicator edupi_ci was deleted**************
* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
**************
* Line of code with indicator edupc_ci was deleted**************
* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
**************
* Line of code with indicator edusi_ci was deleted**************
* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted
**************
* Line of code with indicator edusc_ci was deleted**************
* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted
***************
* Line of code with indicator edus1i_ci was deleted***************
* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted
***************
* Line of code with indicator edus1c_ci was deleted***************
* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted
***************
* Line of code with indicator edus2i_ci was deleted***************
* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted
***************
* Line of code with indicator edus2c_ci was deleted***************
* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted
**************
***eduui_ci*** 
**************
gen eduui_ci = (ed053 == 1 & ed054 == 0)
replace eduui_ci = . if aedu_ci == .
la var eduui_ci "Superior Incompleto"

**************
***eduuc_ci*** 
**************
gen eduuc_ci = (ed054 == 1)
replace eduuc_ci = . if aedu_ci == .
la var eduuc_ci "Superior Completo"

**************
***eduac_ci***
**************
gen eduac_ci = .
replace eduac_ci = 1 if ed054 == 1 
label variable eduac_ci "Superior universitario vs superior no universitario"

***************
***asiste_ci***
***************
*DZ Mar 2019:Se agrega centro de educación temprana**
generat asiste_ci = .
replace asiste_ci = 1 if ed03 == 1 
label var asiste "Personas que actualmente asisten a centros de enseñanza"

***************
***edupub_ci*** 
***************
gen edupub_ci = .
replace edupub_ci = 1 if ed061 == 1
replace edupub_ci = 0 if ed062 == 1
label var edupub_ci "1 = personas que asisten a centros de enseñanza publicos"

***************
***asipre_ci***
***************
gen asispre_ci = (ed051 == 1 & asiste_ci == 1) 
label var asispre_ci "Asiste a educacion prescolar"

**************
***pqnoasis*** 
**************
* Line of code with indicator pqnoasis_ci was deleted* Line of code with indicator pqnoasis_ci was deleted
******************
***pqnoasis1_ci***
******************
*DZ Noviembre 2017: Se agrega la variable pqnoasis1_ci cuya sintaxis fue elaborada por Mayra Saenz
gen pqnoasis1_ci = 1 if ed043 == 1
replace pqnoasis1_ci = 2 if ed043 == 1
replace pqnoasis1_ci = 3 if ed047 == 1 | ed048 == 1 | ed049 == 1 
replace pqnoasis1_ci = 4 if ed041 == 1
replace pqnoasis1_ci = 5 if ed049 == 1
replace pqnoasis1_ci = 8 if ed042 == 1 | ed044 == 1 | ed045 == 1
replace pqnoasis1_ci = 9 if ed046 == 1 | ed0410 == 1

label define pqnoasis1_ci 1 "Problemas económicos" 2 "Por trabajo" 3 "Problemas familiares o de salud" 4 "Falta de interés" 5	"Quehaceres domésticos/embarazo/cuidado de niños/as" 6 "Terminó sus estudios" 7	"Edad" 8 "Problemas de acceso"  9 "Otros"
label value  pqnoasis1_ci pqnoasis1_ci

***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted* Line of code with indicator repite_ci was deleted
******************
* Line of code with indicator repiteult was deleted* Line of code with indicator repiteult was deleted
	************************************
	******* VARIABLES DE VIVIENDA ******
	************************************

********
*luz_ch*
********
* No hay esta pregunta en 2021 aproximamos con oi02
destring oi02, replace
gen luz_ch = (oi02 > 0)

************
*luzmide_ch*
************
gen luzmide_ch = .

************
*combust_ch*
************
gen combust_ch = (h02 == 2 | h02 == 3 | h02 == 4)

************
**piso_ch***
************
gen piso_ch = . 

************
**pared_ch**
************
gen pared_ch = .
replace pared_ch = 0 if h04r == 7
replace pared_ch = 1 if h04r == 1 | h04r == 2 
replace pared_ch = 2 if h04r == 3 | h04r == 5 | h04r == 6 | h04r == 8

label var pared_ch "Materiales de construcción de las paredes"
label def pared_ch 0"No permanentes" 1"Permanentes" 2 "Otros"
label val pared_ch pared_ch

************
**techo_ch**
************
gen techo_ch = .

************
**resid_ch**
************
gen resid_ch = .

************
***dorm_ch**
************
gen dorm_ch = .
destring h03r, replace
replace dorm_ch = h03r

************
***cuartos_ch**
************
* Solo existe la variable sin incluir baños y cocina
gen cuartos_ch = .

***********
*cocina_ch*
***********
gen cocina_ch = .

**********
*telef_ch*
**********
gen telef_ch = (h0107 > 0)

***********
*regrig_ch*
***********
gen refrig_ch = (h0101 > 0)

**********
*freez_ch*
**********
gen freez_ch = .

*********
*auto_ch*
*********
* DZ Jul 2017: corrección de categoría respecto al anio anterior**
gen auto_ch = (h0108 > 0)

**********
*compu_ch*
**********
* DZ Jul 2017: corrección de categoría respecto al anio anterior**
gen compu_ch = (h0111 > 0)

*************
*internet_ch*
*************
/* La respuesta es a nivel de persona, por lo que un mismo hogar puede tener diferentes respuestas. Por lo que se utiliza la jefatura de hogar.
   TIC03. Durante los últimos 3 meses, ¿tuvo acceso a internet?   	
       1 Si
       2 No
       9 Ns/Nr
   TIC051.  ¿En qué sitios tuvo acceso a internet? En su casa
	   0 No
	   1 Si
	   . missing 	*/
gen internet_jh = (tic03==1 & tic051==1) & relacion_ci==1	// Posee conexión a internet
replace internet_jh = . if (tic03==. | tic03==9) & tic051==. & relacion_ci==1					// No tiene
bys idh_ch: egen internet_ch = max(internet_jh)
drop internet_jh
	
********
*cel_ch*
********
/* La respuesta es a nivel de persona, según el manual cel_ch = 1 si al menos un integrante tiene celular.
TIC09 ¿Tiene teléfono celular? 
         1 Si
         2 No */
bys idh_ch: egen cel_ch = min(tic09)
replace cel_ch = 0 if cel_ch == 2

**********
*vivi1_ch*
**********
gen vivi1_ch = .
label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
label def vivi1_ch 1"Casa" 2"Departamento" 3"Otros"
label val vivi1_ch vivi1_ch

**********
*vivi2_ch*
**********
gen vivi2_ch = .

*************
*viviprop_ch*
*************
* Solo es posible identificar una categoría
	/* oi03. Su vivienda es alquilada:
	       1 Si
           2 No */
	gen viviprop_ch=.
	replace viviprop_ch=0 if inlist(oi03,1)
	
	label define viviprop_ch 		0 "Alquilada" ///
									1 "Propia y totalmente pagada" ///
									2 "Propia y en proceso de pago" ///
									3 "Ocupada (propia de facto)"
	
	label value viviprop_ch viviprop_ch

	
****************
***vivitit_ch***
****************
gen vivitit_ch = (ed111 == 1)
label var vivitit_ch "El hogar posee un titulo de propiedad"


****************
***vivialq_ch***
****************
egen vivialq_ch = rowtotal(cp530_3 il05b_2 il05b_3 cp546_2), missing
label var vivialq_ch "Alquiler mensual"
*Renta = Monto de la renta mensual de la vivienda

*******************
***vivialqimp_ch***
*******************
gen vivialqimp_ch = oi04
label var vivialqimp_ch "Alquiler mensual imputado"


	************************************
	********* VARIABLES DE WASH ********
	************************************

****************
***aguared_ch***
****************
generate aguared_ch = (h04u == 1)
la var aguared_ch "Acceso a fuente de agua por red"

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0

*****************
**aguafuente_ch**
*****************
gen aguafuente_ch = .

*************
*aguadist_ch*
*************
gen aguadist_ch = .

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch = 9

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9
*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"

*************
*aguamala_ch*
*************
gen aguamala_ch = 2

*****************
*aguamejorada_ch*
*****************
gen aguamejorada_ch = 2

*****************
***aguamide_ch***
*****************
gen aguamide_ch = . // Es una variable proxy sobre el servicio sanitario (h04u == 1)
label var aguamide_ch "Usan medidor para pagar consumo de agua"

*****************
*****bano_ch*****
*****************
gen bano_ch = .
*replace bano_ch = 0 if h04u == . 
replace bano_ch = 1 if h04u == 1
replace bano_ch = 2 if h04u == 2
replace bano_ch = 3 if  h04u == 6 | h04u == 7
replace bano_ch = 4 if h04u == 3 | h04u == 4 
replace bano_ch = 6 if h04u == 8 | h04u == 5  | h04u ==.

label var bano_ch "Tipo de instalación sanitaria del hogar"
label def bano_ch 0 "Sin instalaciones" 1 "Inodoro a red de desague" 2 "Inodoro a fosa séptica" 3 "Letrina mejorada / otra instalación mejorada" 4 "Indoro/letrina a cuerpo de agua superficial o suelo" 5 "Instalación no mejorada" 6 "Instalación que no se puede clasificar"
label val bano_ch bano_ch

***************
***banoex_ch***
***************
generate banoex_ch = 9
la var banoex_ch "El servicio sanitario es exclusivo del hogar"

***************
**sinbano_ch***
***************
generate sinbano_ch = 3
replace sinbano_ch = 0 if bano_ch>0 & bano_ch!=.

*****************
*banomejorado_ch*
*****************
gen banomejorado_ch = 2
replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6


	************************************
	******** VARIABLES MIGRACIÓN *******
	************************************
	
*******************
*** migrante_ci ***
*******************
gen migrante_ci = .
label var migrante_ci "=1 si es migrante"
* Base no tiene esta pregunra

**********************
*** migrantiguo5_ci ***
**********************
gen migrantiguo5_ci = .
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
/* Encuesta pregunta sobre años viviendo en este lugar, no sabemos si pudo vivir en Honduras y mudarse de ciudad */

**********************
***** miglac_ci ******
**********************
gen miglac_ci = .
label var miglac_ci "=1 si es migrante proveniente de un pais LAC"



	************************************
	** VARIABLES DE PROTECCIÓN SOCIAL **
	************************************
	
******************
***** y_hog ******
******************
egen y_hog = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)
by idh_ch, sort: replace y_hog = sum(y_hog)

*****************
***** y_pc ******
*****************
gen y_pc = y_hog / miembros_ci

****************
*** ing_ptmc ***
****************
egen ing_ptmc = rowtotal(oih04 oih08 oih09 oih10 oih11 oih13 oih14 oih15), missing

****************
* ing_pension **
****************
egen ing_pension = rowtotal(oih04 oih13 oih14), missing

****************
*** y_pc_net ***
****************
gen y_pc_net = (y_hog - ing_ptmc) / miembros_ci

*******************
* percibe_ptmc_ci *
*******************
gen percibe_ptmc_ci = (ing_ptmc > 0)

*******************
***** ptmc_ch *****
*******************
by idh_ch, sort: gen ptmc_ch = 1 if sum(ing_ptmc > 0)

*******************
*** mayor64_ci ****
*******************
gen mayor64_ci = (edad_ci > 64)

*******************
** pnc_elegible ***
*******************
gen pnc_elegible = (edad_ci > 64)

************
** pnc_ci **
************
gen pnc_ci = .



	************************************
	* VARIABLES DE REFERENCIA EXTERNA **
	************************************

*************
**salmm_ci***
*************
* HON 2021
* Acuerdo Ejecutivo No. 001-2021, No.35,636 del 23 de junio del 2021: Acuerda: Artículo 1. Fijar el Ajuste al Salario Mínimo, mismo que entrará en vigencia a partir del uno (01) de julio del dos mil veintiuno (2021)
gen salmm_ci = 8843.37
label var salmm_ci "Salario minimo legal"

*************
** lp_ci ***
*************

gen lp_ci=3829.1 if zona_c==1
replace lp_ci=1917.4 if zona_c==0

*************
**lpe_ci***
*************

gen lpe_ci=.
	
/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch HND_dis_ci /// Diversidad
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
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded


/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/
*clonevar codocupa = ce425cod 
*clonevar codindustria = ce428cod

compress

**DZ Agosto 2019: Se truncan labels de las variables para poder guardarlos en una versión antigua de stata**
foreach i of varlist _all { 
local longlabel: var label `i' 
local shortlabel = substr("`longlabel'",1,79) 
label var `i' "`shortlabel'"
}
saveold "`base_out'", version(12) replace


log close
