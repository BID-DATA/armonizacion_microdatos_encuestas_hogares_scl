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
 
 
* Se armonizó usando los datos de t3, porque t4 no estaban completos/disponibles.

global ruta = "${surveysFolder}"

local PAIS PER
local ENCUESTA ENAHO
local ANO "1995"
local ronda t4 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Perú
Encuesta: ENAHO
Round: t4
Autores: 
Última versión: Natalia Tosi - Email: nvtosi@gmail.com - nvieiratosi@iadb.org
Fecha última modificación: Noviembre 2022

							SCL/LMK - IADB
****************************************************************************/
****************************************************************************/

use `base_in', clear

foreach var of varlist * {
  rename `var' `=strlower("`var'")'
}

***************
***region_c ***
***************
tostring ubi, replace
gen digito ="0"
gen length = length(ubi)
egen aux = concat(digito ubi) if length==5
replace ubi=aux if length==5
drop digito length aux 

gen region_c=real(substr(ubi,1,2))
label define region_c ///
1"Amazonas"	          ///
2"Ancash"	          ///
3"Apurimac"	          ///
4"Arequipa"	          ///
5"Ayacucho"	          ///
6"Cajamarca"	      ///
7"Callao"	          ///
8"Cusco"	          ///
9"Huancavelica"	      ///
10"Huanuco"	          ///
11"Ica"	              ///
12"Junin"	          ///
13"La libertad"	      ///
14"Lambayeque"	      ///
15"Lima"	          ///
16"Loreto"	          ///
17"Madre de Dios"	  ///
18"Moquegua"	      ///
19"Pasco"	          ///
20"Piura"	          ///
21"Puno"	          ///
22"San Martín"	      ///
23"Tacna"	          ///
24"Tumbes"	          ///
25"Ucayali"	
label value region_c region_c
label var region_c "division politico-administrativa, departamento" 

************************
*** region según BID ***
************************
gen region_BID_c=3 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c


***************
*****ine01*****
***************

gen ine01=real(substr(ubi,1,2))
label define ine01 ///
1"Amazonas"	          ///
2"Ancash"	          ///
3"Apurimac"	          ///
4"Arequipa"	          ///
5"Ayacucho"	          ///
6"Cajamarca"	      ///
7"Callao"	          ///
8"Cusco"	          ///
9"Huancavelica"	      ///
10"Huanuco"	          ///
11"Ica"	              ///
12"Junin"	          ///
13"La libertad"	      ///
14"Lambayeque"	      ///
15"Lima"	          ///
16"Loreto"	          ///
17"Madre de Dios"	  ///
18"Moquegua"	      ///
19"Pasco"	          ///
20"Piura"	          ///
21"Puno"	          ///
22"San Martín"	      ///
23"Tacna"	          ///
24"Tumbes"	          ///
25"Ucayali"	
label value ine01 ine01
label var ine01 "division politico-administrativa, departamento" 


***************
***factor_ch***
***************

gen factor_ch = s01
label variable factor_ch "Factor de expansion del hogar"

***************
****idh_ch*****
**************

sort  ubi seg viv hog 
egen idh_ch= group( ubi seg viv hog)
label variable idh_ch "ID del hogar"

*************
****idp_ci****
**************

gen idp_ci = giiian
label variable idp_ci "ID de la persona en el hogar"

**********
***zona***
**********

gen byte zona_c = 1 if (g000b1 == 11 | g000b1 == 21 | g000b1== 22)
replace zona_c = 0 if (g000b1 == 32 | g000b1 == 42)

label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

************
****pais****
************

gen str3 pais_c = "PER"
label variable pais_c "Pais"

**********
***anio***
**********

gen anio_c = 1995
label variable anio_c "Anio de la encuesta"

*********
***mes***
*********

gen mes_c = .
label variable mes_c "Mes de la encuesta"

*****************
***relacion_ci***
*****************

gen relacion_ci =.
replace relacion_ci = 1 if (g43 == 1)
replace relacion_ci = 2 if (g43 == 2)
replace relacion_ci = 3 if (g43 == 3)
replace relacion_ci = 4 if (g43 >= 4 & g43 <= 6)
replace relacion_ci = 5 if (g43 == 8 | g43 == 9)
replace relacion_ci = 6 if (g43 == 7)

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

gen factor_ci = s01
label variable factor_ci "Factor de expansion del individuo"


***************
***upm_ci***
***************

gen upm_ci = g000b2


***************
***estrato_ci***
***************

gen estrato_ci = g000b1

* 11 = Urbano
* 21 = Urbano
* 22 = Semiurbano 
* 32 = Rural
* 42 = Rural


**********
***sexo***
**********

gen sexo_ci= g45

label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********

gen edad_ci = g46a if (g46b == 1)
replace edad_ci = 0 if (g46b == 2)
replace edad_ci =. if (g46a ==.)
label variable edad_ci "Edad del individuo"


*****************
***civil_ci***
*****************

gen civil_ci =.
replace civil_ci = 1 if (g50 == 6)
replace civil_ci = 2 if (g50 == 1 | g50 == 2)
replace civil_ci = 3 if (g50 == 4 | g50 == 5)
replace civil_ci = 4 if (g50 == 3)

label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci


*************
***jefe_ci***
*************

gen jefe_ci = (relacion_ci == 1)
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

by idh_ch, sort: egen nmiembros_ch=sum(relacion_ci>=1 & relacion_ci<=4)
label variable nmiembros_ch "Numero de familiares en el hogar"

*****************
***nmayor21_ch***
*****************

by idh_ch, sort: egen nmayor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=21)
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************

by idh_ch, sort: egen nmenor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<21)
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************

by idh_ch, sort: egen nmayor65_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=65)
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************

by idh_ch, sort: egen nmenor6_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<6)
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************

by idh_ch, sort: egen nmenor1_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<1)
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

****************
***miembros_ci***
****************

gen miembros_ci=(relacion_ci<5)
label variable miembros_ci "Miembro del hogar"


******************************
*** VARIABLES DE DIVERSIDAD **
******************************

***************
***afroind_ci***
***************
	
**Pregunta (solo al jefe y cónyugue) por sus antepasados y de acuerdo a sus costumbres, �ud. se considera:(p46) (1 quechua; 2 aymara; 3 nativo o indígena de la amazonía; 4 negro/ mulato/zambo; 5 blanco; 6 mestizo; 7 otro; 8 no sabe)

gen afroind_ci=.

	***************
	***afroind_ch***
	***************
	
gen afroind_jefe = afroind_ci if relacion_ci==1
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


************************************
*** VARIABLES DEL MERCADO LABORAL***
************************************

/* Esta sección es para los residentes habituales del hogar mayores a 14 años*/


****************
****condocup_ci*
****************
gen condocup_ci =.
replace condocup_ci = 1 if (g63 == 1)
replace condocup_ci = 2 if (g63 == 2 | g63 == 3)
replace condocup_ci = 3 if (g63 >= 4 & g63 <= 9)
replace condocup_ci = 4 if (edad_ci < 14)
label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor de PET"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"


****************
*afiliado_ci****
****************
gen byte afiliado_ci =.	
label var afiliado_ci "Afiliado a la Seguridad Social"
*Nota: seguridad social comprende solo los que en el futuro me ofrecen una pension.


****************
*tipopen_ci*****
****************
gen tipopen_ci =.
replace tipopen_ci = 1 if (g75 == 1)
replace tipopen_ci = 2 if (g75 == 2)
replace tipopen_ci = 3 if (g75 == 3)
label var tipopen_ci "Tipo de pensión"
label define tipopen_ci 1 "AFP" 2 "IPSS o ONP" 3 "Otro" 
label value tipopen_ci tipopen_ci

********************
*** instcot_ci *****
********************
gen instcot_ci =.
label var instcot_ci "institución a la cual cotiza"

****************
*cotizando_ci***
****************

gen cotizando_ci =. 
label var cotizando_ci "Cotizante a la Seguridad Social"

gen cotizapri_ci =.
label var cotizapri_ci "Cotizante a la Seguridad Social por su trabajo principal"


*****************
*tipocontrato_ci*
*****************

gen tipocontrato_ci =.
replace tipocontrato_ci = 1 if (g73 == 1)
replace tipocontrato_ci = 2 if (g73 == 2)
replace tipocontrato_ci = 3 if (g73 == 3)

label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
* Opciones de contrato diferentes en la encuesta, entonces no son comparables con los demás países/años


*************
*tamemp_ci***
*************
/*
gen tamemp_ci=ocprango 
label define  tamemp_ci 1"menos de 100" 2"de 100 a 499" 3"de 500 y más p"
label var tamemp_ci "# empleados en la empresa de la actividad principal"
*/

gen tamemp_ci =.
label define tamaño 1"pequeña" 2"mediana" 3"grande"
label values tamemp_ci tamaño
* Opciones de respuestas diferentes en la encuesta, entonces no son comparables con los demás países/años

****************
**categoinac_ci*
****************

gen categoinac_ci = 1 if (p63 == 6 & condocup_ci == 3)
replace categoinac_ci = 2 if  (p63 == 5 & condocup_ci == 3)
replace categoinac_ci = 3 if  (p63 == 4 & condocup_ci == 3)
replace categoinac_ci = 4 if  ((p63 >= 7 &  p63 <= 9) & condocup_ci == 3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"
label value categoinac_ci categoinac_ci


*******************
***formal***
*******************

capture gen formal = 1 if cotizando_ci == 1
replace formal = 1 if (tipocontrato_ci >= 1 & tipocontrato_ci <= 2)
replace formal = 0 if (tipocontrato_ci == 3)


replace formal = 1 if afiliado_ci == 1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c > 1998
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c <= 2006
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c >= 2008

capture gen byte formal_ci=.
replace formal_ci=1 if formal==1 & (condocup_ci == 1 | condocup_ci == 2)
replace formal_ci = 0 if (formal_ci ==. & (condocup_ci==1 | condocup_ci == 2)) | formal == 0
label var formal_ci "1=afiliado o cotizante / PEA"


*************
**pension_ci*
*************

gen pension_ci =.
replace pension_ci = 1 if (g75 >= 1 & g75 <= 3) 
replace pension_ci = 0 if (g75 == 4) 

*************
**  ypen_ci *
*************

gen ypen_ci =.
replace ypen_ci = g1031a if (g1031a >= 0)
 
/*Nota: La pregunta resume el monto de todas las 
transferencias no se puede distinguir cual es por pensiones*/
label var ypen_ci "Valor de la pension contributiva"

****************
*instpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 

***************
*pensionsub_ci*
***************

gen pensionsub_ci=.
replace ypen_ci = 1 if (g1031 == 1 | g1033 == 1 | g1034 == 1 | g1035 == 1)
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*****************
**  ypensub_ci  *
*****************
gen ypensub_ci=.
replace ypen_ci = (g1031a + g1033a + g1034a + g1035a) if (g1031a >= 0 | g1033a >= 0 | g1034a >= 0 | g1035a >= 0)

label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

*************
*cesante_ci* 
*************

generat cesante_ci = 0 if (condocup_ci == 2)
replace cesante_ci = 1 if (p90 == 1 & condocup_ci == 2)
label var cesante_ci "Desocupado - definicion oficial del pais"


*********
*lp_ci***
*********
gen lp_ci =.
label var lp_ci "Linea de pobreza oficial del pais"

*********
*li_ci***
*********
gen lpe_ci =. 
label var lpe_ci "Linea de indigencia oficial del pais"

/************************************************************************************************************
* 3. Creación de nuevas variables de SS and LMK a incorporar en Armonizadas
************************************************************************************************************/

*************
**salmm_ci***
*************

gen salmm_ci =.
replace salmm_ci = 132
label var salmm_ci "Salario minimo legal"

***************
***tecnica_ci**
***************
gen tecnica_ci =.
label var tecnica_ci "=1 formacion terciaria tecnica"	

************
***emp_ci***
************
gen emp_ci = (condocup_ci == 1)

****************
***desemp_ci***
****************
gen desemp_ci = (condocup_ci == 2)

*************
***pea_ci***
*************

gen pea_ci = (emp_ci == 1 | desemp_ci == 1)


*****************
***desalent_ci***
*****************

gen desalent_ci = (emp_ci == 0 & (p87 == 2 | p87 == 3))

*****************
***horaspri_ci***
*****************


* REVISAR AQUI


gen horaspri_ci =.
replace horaspri_ci = p51 if (p51 > 0)
replace horaspri_ci=. if emp_ci ~= 1

*****************
***horastot_ci***
*****************

gen p518_alt = p61
replace p518_alt =. if p61 ==.

egen horastot_ci = rsum(horaspri_ci p518_alt)
replace horastot_ci =. if (horaspri_ci ==. & p518_alt ==.)
replace horastot_ci =. if (emp_ci ~= 1)

drop p518_alt

***************
***subemp_ci***
***************
/*
/*Sobre las horas normalmente trabajadas*/
gen subemp_ci=0
replace subemp_ci=1 if (thtrabaj==1 & horastot_ci<=30) & thdispon==1 
replace subemp_ci=1 if (thtrabaj==2 & thnormal<=30) & thdispon==1
replace subemp_ci=. if emp_ci==.
*/

* Modificacion con subempleo visible: quiere trabajar mas horas y esta disponible a trabajar mas horas. MGD 06/19/2014
gen subemp_ci = 0
replace subemp_ci = 1 if (horaspri_ci <= 30 & p66 == 1 & emp_ci == 1) 

*******************
***tiempoparc_ci***
*******************
/*Sobre las horas normalmente trabajadas*/

gen tiempoparc_ci = 0
/*replace tiempoparc_ci=1 if (thtrabaj==1 & horastot_ci<=30) & thdispon==2
replace tiempoparc_ci=1 if (thtrabaj==2 & thnormal<=30) & thdispon==2
replace tiempoparc_ci=. if emp_ci==.*/
* 10/20/2015 MGD: no se usa las horas totales trabajadas sino solo las de la actividad principal.

replace tiempoparc_ci = 1 if ((horaspri_ci >= 1 & horaspri_ci < 30) & p66 == 2 & emp_ci == 1)
replace tiempoparc_ci =. if (emp_ci == 0)


******************
***categopri_ci***
******************
* 10/20/2015 MGD: se añade la categoria otra clasificacion para sacarlos de los no remunerados
* Categorias no comparables a los demás años, variable no armonizada para no generar anomalias

gen categopri_ci =.

label define categopri_ci 0 "Otra clasificación" 1"Patron" 2"Cuenta propia" 
label define categopri_ci 3"Empleado" 4" No remunerado", add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional trabajo principal"


******************
***categosec_ci***
******************
* 10/20/2015 MGD: se añade la categoria otra clasificacion para sacarlos de los no remunerados

gen categosec_ci=.

label define categosec_ci 0 "Otra clasificación"  1"Patron" 2"Cuenta propia" 
label define categosec_ci 3"Empleado" 4 "No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"


*****************
***nempleos_ci***
*****************

gen nempleos_ci =.

/*
*****************
***firmapeq_ci***
*****************

gen firmapeq_ci=.
replace firmapeq_ci=1 if ocpnrotr<=5
replace firmapeq_ci=0 if ocpnrotr>5
replace firmapeq_ci=0 if ocprango==2 | ocprango==3
replace firmapeq_ci=. if emp_ci~=1
*/

*****************
***spublico_ci***
*****************

gen spublico_ci = (p43 == 3 | p43 == 4 | p43 == 7)
replace spublico_ci =. if (emp_ci ~= 1)

**************
***ocupa_ci***
**************
* No esta disponible la lista de codigos de ocupación, entonces no se armoniza esta variable

gen ocupa_ci =.


*************
***rama_ci***
*************
* No esta disponible la lista de codigos de rama, entonces no se armoniza esta variable

gen rama_ci=.


****************
***durades_ci***
****************

gen durades_ci=.


*******************
***antiguedad_ci***
*******************

gen antiguedad_ci=.


*************************************************************************************
*******************************INGRESOS**********************************************
*************************************************************************************

**************
***ylmpri_ci***
***************
* Ingreso laboral monetario mensual proveniente de la actividad principal.

gen ylmpri_ci = p73

*******************
*** nrylmpri_ci ***
*******************

gen nrylmpri_ci=.

******************
*** ylnmpri_ci ***
******************

gen ylnmpri_ci =.


***************
***ylmsec_ci***
***************

gen ylmsec_ci =.


******************
****ylnmsec_ci****
******************

gen ylnmsec_ci =.


************
***ylm_ci***
************

gen ylm_ci =.

*************
***ylnm_ci***
*************

gen ylnm_ci =.


*************
***ynlm_ci***
*************

gen ynlm_ci =.
gen remesas_ci =.

**************
***ynlnm_ci***
**************

gen ynlnm_ci =.

********************
***Transferencias***
********************

*-Monetarias
* 1997
gen trac_pri =.
gen trac_pub =.

*-No Monetarias
*Se generan a partir de 2001
gen dona_pub =.
gen dona_pri =.

* TOTAL (las privadas incluyen transferencias del exterior)

gen trat_pri =.
gen trat_pub =.

****************
*Rentas y otros*
****************
gen rtasot =.
label var rtasot "Rentas y otros"


************************
*** HOUSEHOLD INCOME ***
************************

*******************
*** nrylmpri_ch ***
*******************
*Creating a Flag label for those households where someone has a ylmpri_ci as missing

gen nrylmpri_ch =.


**************
*** ylm_ch ***
**************

gen ylm_ch =.

****************
*** ylmnr_ch ***
****************

gen ylmnr_ch =.

***************
*** ylnm_ch ***
***************

gen ylnm_ch =.


**********************************************************************************************
***TCYLMPRI_CH : Identificador de los hogares en donde alguno de los miembros reporta como
*** top-code el ingreso de la actividad principal. .
***********************************************************************************************
gen tcylmpri_ch =.
label var tcylmpri_ch "Id hogar donde alg򮠭iembro reporta como top-code el ingr de activ. principal"

***********************************************************************************************
***TCYLMPRI_CI : Identificador de top-code del ingreso de la actividad principal.
***********************************************************************************************
gen tcylmpri_ci =.
label var tcylmpri_ci "Identificador de top-code del ingreso de la actividad principal"

*****************
***ylmotros_ci***
*****************

gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

gen ylnmotros_ci=.

******************
*** remesas_ch ***
******************

gen remesas_ch =.

***************
*** ynlm_ch ***
***************

gen ynlm_ch =.

****************
*** ynlnm_ch ***
****************

gen ynlnm_ch =.

*******************
*** autocons_ci ***
*******************

gen autocons_ci = p72        
replace autocons_ci=. if p72==99999
replace autocons_ci=. if emp_ci ~= 1


*******************
*** autocons_ch ***
*******************

by idh_ch, sort: egen autocons_ch=sum(autocons_ci) if miembros_ci==1

*******************
*** rentaimp_ch ***
*******************

*gen rentaimp_ch=alqmens2
*replace rentaimp_ch=. if alqmens2==9999

*Modificación Mayra Sáenz - Julio 2015
gen rentaimp_ch =.

*****************
***ylhopri_ci ***
*****************

gen ylmhopri_ci =.


***************
***ylmho_ci ***
***************

gen ylmho_ci =.





* REVISAR HASTA AQUI




****************************
***VARIABLES DE EDUCACION***
****************************

/*En esta sección es sólo para los residentes habituales 
mayores a los 3 años de edad*/

gen nivel_educ = g52a

label define nivel_educ 1"Sin Nivel" 2"Inicial" 3"Primaria" 4"Secundaria" 5"Sup.No Univ.Incomp." 6"Sup.No Univ.Comp." 7"Sup.Univ.Incopm." 8"Sup.Univ.Comp." 9"Missing/Otro"
label value  nivel_educ nivel_educ
label variable nivel_educ "Nivel Educación"

*******

destring g52b, replace
gen byte aedu_ci =.

replace aedu_ci = 0 if (nivel_educ == 1 | nivel_educ == 2)

replace aedu_ci = 1 if (nivel_educ == 3 & g52b == 0)
replace aedu_ci = 1 if (nivel_educ == 3 & g52b == 0)
replace aedu_ci = 2 if (nivel_educ == 3 & g52b == 1)
replace aedu_ci = 3 if (nivel_educ == 3 & g52b == 2)
replace aedu_ci = 4 if (nivel_educ == 3 & g52b == 3)
replace aedu_ci = 5 if (nivel_educ == 3 & g52b == 4)
replace aedu_ci = 6 if (nivel_educ == 3 & (g52b == 5 | g52b == 6)) | (nivel_educ == 4 & g52b == 0)

replace aedu_ci = 7 if (nivel_educ == 4 & g52b == 1)
replace aedu_ci = 8 if (nivel_educ == 4 & g52b == 2)
replace aedu_ci = 9 if (nivel_educ == 4 & g52b == 3)
replace aedu_ci = 10 if (nivel_educ == 4 & g52b == 4)
replace aedu_ci = 11 if (nivel_educ == 4 & g52b == 5) | (nivel_educ == 5 & g52b == 0)

replace aedu_ci = 12 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 1
replace aedu_ci = 13 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 2
replace aedu_ci = 14 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 3
replace aedu_ci = 15 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 4
replace aedu_ci = 16 if ((nivel_educ >= 5 & nivel_educ <= 8) & g52b == 5) | ((nivel_educ == 6 | nivel_educ == 8) & g52b == 0)
replace aedu_ci = 17 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 6
replace aedu_ci = 18 if (nivel_educ >= 5 & nivel_educ <= 8) & g52b == 7 

replace aedu_ci =. if (nivel_educ == 9 | nivel_educ ==.)


**************
***eduno_ci***
**************

gen byte eduno_ci = (aedu_ci == 0) 
replace eduno_ci=. if aedu_ci==.
label variable eduno_ci "Cero anios de educacion"


**************
***edupi_ci***
**************

gen byte edupi_ci = (aedu_ci > 0 & aedu_ci < 6)
replace edupi_ci =. if aedu_ci ==.
label variable edupi_ci "Primaria incompleta"


**************
***edupc_ci***
**************

gen byte edupc_ci = (aedu_ci == 6)
replace edupc_ci=. if aedu_ci==.
label variable edupc_ci "Primaria completa"


**************
***edusi_ci***
**************

gen byte edusi_ci = (aedu_ci > 6 & aedu_ci < 11)
replace edusi_ci =. if aedu_ci == .
label variable edusi_ci "Secundaria incompleta"


**************
***edusc_ci***
**************

gen byte edusc_ci = (aedu_ci == 11)
replace edusc_ci =. if aedu_ci==.
label variable edusc_ci "Secundaria completa"


***************
***edus1i_ci***
***************

gen byte edus1i_ci = (aedu_ci > 6 & aedu_ci < 9)
replace edus1i_ci=. if aedu_ci ==.
label variable edus1i_ci "1er ciclo de la secundaria incompleto"


***************
***edus1c_ci***
***************

gen byte edus1c_ci = (aedu_ci == 9)
replace edus1c_ci=. if aedu_ci==.
label variable edus1c_ci "1er ciclo de la secundaria completo"


***************
***edus2i_ci***
***************

gen byte edus2i_ci = (aedu_ci == 10)
replace edus2i_ci=. if aedu_ci==.
label variable edus2i_ci "2do ciclo de la secundaria incompleto"


***************
***edus2c_ci***
***************

gen byte edus2c_ci = (aedu_ci == 11)
replace edus2c_ci =. if aedu_ci==.
label variable edus2c_ci "2do ciclo de la secundaria completo"


**************
***eduui_ci***
**************

gen byte eduui_ci = (aedu_ci >= 12) & (nivel_educ == 5 | nivel_educ == 7)
replace eduui_ci=. if aedu_ci==.
label variable eduui_ci "Universitaria incompleta"


***************
***eduuc_ci***
***************

gen byte eduuc_ci = (aedu_ci >= 12) & (nivel_educ == 6 | nivel_educ == 8)
replace eduuc_ci =. if aedu_ci==.
label variable eduuc_ci "Universitaria completa o mas"


***************
***edupre_ci***
***************

gen byte edupre_ci=.
label variable edupre_ci "Educacion preescolar"


**************
***eduac_ci***
**************
gen byte eduac_ci =.
replace eduac_ci = 1 if (nivel_educ == 7 | nivel_educ == 8)
replace eduac_ci = 0 if (nivel_educ == 5 | nivel_educ == 6)
label variable eduac_ci "Superior universitario vs superior no universitario"


***************
***asiste_ci***
***************

gen asiste_ci = g53 if (g53 ~= 7 | g53 ~= .)
label variable asiste_ci "Asiste actualmente a la escuela"


*****************
***pqnoasis_ci***
*****************

gen pqnoasis_ci =.

label variable pqnoasis_ci "Razones para no asistir a la escuela"
label define pqnoasis_ci 1 "Estoy trabajando"
label define pqnoasis_ci 2 "No me interesa", add
label define pqnoasis_ci 3 "Por enfermedad", add
label define pqnoasis_ci 4 "Prob. econ", add
label define pqnoasis_ci 5 "Prob.fam", add
label define pqnoasis_ci 6 "Bajas notas", add
label define pqnoasis_ci 7 "Termino", add
label define pqnoasis_ci 8 "Otra razón", add
label define pqnoasis_ci 99 "Missing", add
label value pqnoasis_ci pqnoasis_ci


**************
*pqnoasis1_ci*
**************
**Daniela Zuluaga- Enero 2018: Se agrega la variable pqnoasis1_ci cuya sintaxis fue elaborada por Mayra Saenz**

gen pqnoasis1_ci = .
label define pqnoasis1_ci 1 "Problemas económicos" 2 "Por trabajo" 3 "Problemas familiares o de salud" 4 "Falta de interés" 5	"Quehaceres domésticos/embarazo/cuidado de niños/as" 6 "Terminó sus estudios" 7	"Edad" 8 "Problemas de acceso"  9 "Otros"
label value  pqnoasis1_ci pqnoasis1_ci


***************
***repite_ci***
***************

gen repite_ci=.
gen repiteult_ci=.

***************
***edupub_ci***
***************

gen byte edupub_ci = .
label variable asiste_ci "Asisten a centros de enseñanza publicos"


**********************************
**** VARIABLES DE LA VIVIENDA ****
**********************************

gen aguared_ch = (g29 == 1 | g29 == 2)
label variable aguared_ch "Acceso a una fuente de agua por red"


gen aguadist_ch = 1 if g29 == 1
replace aguadist_ch = 2 if g29 == 2
replace aguadist_ch = 3 if g29 >= 3 & g29 <= 7
replace aguadist_ch =. if g29 == 9 
label variable aguadist_ch "Ubicación de la principal fuente de agua"

gen aguamala_ch=.
/*NA*/

gen aguamide_ch=.
/*NA*/

gen byte luz_ch = 1 if g34 == 1
replace luz_ch =. if g34 == 9
label variable luz_ch "La principal fuente de iluminación es electricidad"

gen luzmide_ch=.
/*NA*/

gen combust_ch =.
/*NA*/

gen bano_ch = (g248 == 1)


gen byte banoex_ch = (g248 == 1 & g33 == 1)
replace banoex_ch = . if (g248 ==.)


gen des1_ch = 0 if (g32 == 5)
replace des1_ch = 1 if (g32 == 1 | g32 == 2)
replace des1_ch = 2 if (g32 == 3)
replace des1_ch = 3 if (g32 == 4)

gen des2_ch = 0 if g32 == 5
replace des2_ch = 1 if (g32>=1 | g32<=2)
replace des2_ch = 2 if (g32 == 3)

gen piso_ch =.
replace piso_ch = 0 if (g22 == 6)
replace piso_ch = 1 if (g22 => 1 & g22 <= 5)
replace piso_ch = 2 if (g22 == 7)


gen pared_ch=.
/*NA*/

gen techo_ch=.
/*NA*/

gen resid_ch=.
/*NA*/

**Daniela Zuluaga- Enero 2018: Se agregan las variables aguamejorada_ch y banomejorado_ch cuya sintaxis fue elaborada por Mayra Saenz**
	
*********************
***aguamejorada_ch***
*********************
g       aguamejorada_ch = 1 if (g29 >= 1 & g29 <= 3) | g29 == 5
replace aguamejorada_ch = 0 if (g29 >= 6 & g29 <= 7) | g29 == 4
		
		
*********************
***banomejorado_ch***
*********************
g       banomejorado_ch = 1 if (g32 >= 1 & g32 <= 3)
replace banomejorado_ch = 0 if (g32 >= 4 & g32 <= 5)

gen dorm_ch = g23

gen cuartos_ch =.
/*NA*/

gen byte cocina_ch = (g247 == 1)

gen telef_ch = (g3917 == 1)
gen refrig_ch = (g395 == 1)
gen freez_ch =.
/*NA*/
gen auto_ch = (g399 == 1)
gen compu_ch= (g3918 == 1)
gen internet_ch =.
/*NA*/

gen cel_ch =.
/*NA*/

gen vivi1_ch = 1 if (g18 == 1)
replace vivi1_ch = 2 if (g18 == 2)
replace vivi1_ch = 3 if (g18 > 2)

gen vivi2_ch = (g18 <= 2)


gen viviprop_ch = 0 if g25 == 1
replace viviprop_ch = 1 if g25 == 2
replace viviprop_ch = 2 if g25 == 3
replace viviprop_ch = 3 if g25 == 6


gen byte vivitit_ch = (viviprop_ch == 1 | viviprop_ch == 2)

gen vivialq_ch = g26a if (viviprop_ch == 0 & g26b ~= 9999)
*Monto mensual pagado por el alquiler de la vivienda.


/*gen vivialqimp_ch=alqmens2
replace vivialqimp_ch=. if alqmens2==9999*/

*Modificación Mayra Sáenz - Julio 2015
gen vivialqimp_ch = g26b if (viviprop_ch == 0 & g26b ~= 9999)


**************
*** SALUD  ***
**************

*******************
*** cobsalud_ci ***
*******************

gen cobsalud_ci=.
replace cobsalud_ci = 1 if (g74 >= 1 | g74 <= 3)
replace cobsalud_ci = 0 if (g74 == 4)

label var cobsalud_ci "Tiene cobertura de salud"
label define cobsalud_ci 0 "No" 1 "Si" 
label value cobsalud_ci cobsalud_ci


************************
*** tipocobsalud_ci  ***
************************

gen tipocobsalud_ci=.
label var tipocobsalud_ci "Tipo cobertura de salud"
lab def tipocobsalud_ci 0"Sin cobertura" 1"essalud" 2"Privado" 3"entidad prestadora" 4"policiales" 5"sis" 6"universitario" 7"escolar privado" 8"otro" 
lab val tipocobsalud_ci tipocobsalud_ci



*********************
*** probsalud_ci  ***
*********************
* Nota: se pregunta si tuvieron problemas de salud en últimas 4 semanas. 

gen probsalud_ci=.
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
gen costo_ci=.

label var costo_ci "Dificultad de acceso a salud por costo"
lab def costo_ci 0 "No" 1 "Si"
lab val costo_ci costo_ci


********************
*** atencion_ci  ***
********************
gen atencion_ci=.

label var atencion_ci "Dificultad de acceso a salud por problemas de atencion"
lab def atencion_ci 0 "No" 1 "Si"
lab val atencion_ci atencion_ci


******************************
*** VARIABLES DE MIGRACION ***
******************************

* Variables incluidas por SCL/MIG Fernando Morales

	*******************
	*** migrante_ci ***
	*******************
	
	gen migrante_ci =.
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
	** Fuente: Los codigos de paises se obtiene del censo de peru (redatam)
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci=.
	replace miglac_ci = 0 if migrantelac_ci != 1  & migrante_ci == 1
	replace miglac_ci = . if migrante_ci == 0
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"
	** Fuente: Los codigos de paises se obtiene del censo de peru (redatam)



/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables del SOCIOMETRO y las nuevas de mercado laboral
* También se incluyen variables que se manejaban en versiones anteriores, estas son:
* firmapeq_ci nrylmpri_ch nrylmpri_ci tcylmpri_ch tcylmpri_ci tipopen_ci
/*_____________________________________________________________________________________________________*/

order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch	idh_ch	idp_ci	factor_ci sexo_ci edad_ci ///
relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch ///
clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch	nmenor1_ch	condocup_ci ///
categoinac_ci nempleos_ci emp_ci antiguedad_ci	desemp_ci cesante_ci durades_ci	pea_ci desalent_ci subemp_ci ///
tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci ///
formal_ci tipocontrato_ci ocupa_ci horaspri_ci horastot_ci	pensionsub_ci pension_ci tipopen_ci instpen_ci	ylmpri_ci nrylmpri_ci ///
tcylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci	ylmotros_ci	ylnmotros_ci ylm_ci	ylnm_ci	ynlm_ci	ynlnm_ci ylm_ch	ylnm_ch	ylmnr_ch  ///
ynlm_ch	ynlnm_ch ylmhopri_ci ylmho_ci rentaimp_ch autocons_ci autocons_ch nrylmpri_ch tcylmpri_ch remesas_ci remesas_ch	ypen_ci	ypensub_ci ///
salmm_ci aedu_ci eduno_ci edupi_ci edupc_ci	edusi_ci edusc_ci eduui_ci eduuc_ci	edus1i_ci ///
edus1c_ci edus2i_ci edus2c_ci edupre_ci eduac_ci asiste_ci pqnoasis_ci pqnoasis1_ci	repite_ci repiteult_ci edupub_ci tecnica_ci ///
aguared_ch aguadist_ch aguamala_ch aguamide_ch luz_ch luzmide_ch combust_ch	bano_ch banoex_ch des1_ch des2_ch piso_ch aguamejorada_ch banomejorado_ch  ///
pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch freez_ch auto_ch compu_ch internet_ch cel_ch ///
vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch	vivialqimp_ch , first



compress

saveold "`base_out'", replace
log off
log close
