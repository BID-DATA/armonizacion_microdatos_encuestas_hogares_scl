*(Versión stata 17)

clear
set more off

*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: \\sapidbshares.file.core.windows.net\idbshares\SURVEYS
 * Se tiene acceso al servidor técnicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*


global ruta = "${surveysFolder}"


local PAIS COL
local ENCUESTA GEIH
local ANO "2025"
local ronda t3
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"


capture log close
cap log using "`log_file'", replace

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO
País: Colombia
Encuesta: GEIH
Round: t3
Año: 2025
Autores:
Claude HDMF System — 2026-06-18
Basado en: COL_2024t3_variablesBID.do (armonizacion_microdatos_encuestas_hogares_scl)
Mejoras HDMF 2025:
  - afiliado_ci: usa p6100 (régimen contributivo/especial) en lugar de p6090
  - formal_ci: restringido a condocup_ci==1 (solo ocupados)
  - ocupa_ci: derivado del primer dígito de oficio_c8 (método directo ISCO-08)
  - asiste_ci: verificado en p6170 (no p3038)
  - Añadido: edu_isced, parcial_ci
  - Añadido: mig_pais_ci, mig_pais_code
  - Añadido: profesion_ci, cinef13_ci, profesion3_ci (campo de estudio ISCED-F 2013)

*************************************************************************** */

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear


		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************

**************
**Region_BID**
**************
gen region_BID_c=.
replace region_BID_c=3

***************
***region_c ***
***************
gen region_c=real(dpto)
label define region_c       ///
	5  "Antioquia"	        ///
	8  "Atlantico"	        ///
	11 "Bogota, D.C"	    ///
	13 "Bolivar" 	        ///
	15 "Boyacá"	            ///
	17 "Caldas"	            ///
	18 "Caquetá"	        ///
	19 "Cauca"	            ///
	20 "Cesar"	            ///
	23 "Córdoba"	        ///
	25 "Cundinamarca"       ///
	27 "Chocó"	            ///
	41 "Huila"	            ///
	44 "La Guajira"	        ///
	47 "Magdalena"	        ///
	50 "Meta"	            ///
	52 "Narino"	            ///
	54 "Norte de Santander"	///
	63 "Quindío"	        ///
	66 "Risaralda"	        ///
	68 "Santander"	        ///
	70 "Sucre"	            ///
	73 "Tolima"	            ///
	76 "Valle del Cauca"	///
	81 "Arauca"	            ///
	85 "Casanare"	        ///
	86 "Putumayo"	        ///
	88 "Archipiélago de San Andrés, Providencia y Santa Catalina" ///
	91 "Amazonas"	        ///
	94 "Guainía"	        ///
	95 "Guaviare"	        ///
	97 "Vaupés" 	        ///
	99 "Vichada"
label value region_c region_c

************
****pais_c****
************
g str3 pais_c = "COL"

**********
***anio_c***
**********
g anio_c = 2025

**********
***mes_c***
**********

destring mes, replace
gen mes_c=mes

**********
***zona_c***
**********
destring clase, replace
g zona_c = clase == 1

*********
*estrato*
*********
gen estrato_ci=.

*****************************
*unidad primaria de muestreo*
*****************************
gen upm_ci=.

***************
****idh_ch*****
***************
gen idh_ch = idh
tostring idh_ch, replace

**************
****idp_ci****
**************
g idp_ci=orden
tostring idp_ci, replace

***************
***factor_ci***
***************
g factor_ci=fex_c18

***************
***factor_ch***
***************
g factor_ch=fex_c18


		****************************
		***VARIABLES DEMOGRAFICAS***
		****************************

*************
***sexo_ci***
*************
g sexo_ci = p3271


**********
***edad***
**********
g edad_ci = p6040

*****************
***relacion_ci***
*****************
g 		relacion_ci = 1 if p6050 == 1
replace relacion_ci = 2 if p6050 == 2
replace relacion_ci = 3 if p6050 == 3
replace relacion_ci = 4 if inlist(p6050,4,5,6,7,8,9)
replace relacion_ci = 5 if p6050 == 11 | p6050 == 12 | p6050 == 13
replace relacion_ci = 6 if p6050 == 10

*********************
****Estado Civil*****
*********************
g 		civil_ci = .
replace civil_ci = 1 if p6070 == 6
replace civil_ci = 2 if p6070==1 | p6070==2 | p6070==3
replace civil_ci = 3 if p6070==4
replace civil_ci = 4 if p6070==5

*************
***jefe_ci***
*************
g jefe_ci = relacion_ci == 1

******************
***nconyuges_ch***
******************
bys idh_ch: egen nconyuges_ch = sum(relacion_ci == 2)


***************
***nhijos_ch***
***************
bys idh_ch: egen nhijos_ch = sum(relacion_ci == 3)


******************
***notropari_ch***
******************
bys idh_ch: egen notropari_ch = sum(relacion_ci == 4)

********************
***notronopari_ch***
********************
bys idh_ch: egen notronopari_ch = sum(relacion_ci == 5)

****************
***nempdom_ch***
****************
bys idh_ch: egen nempdom_ch = sum(relacion_ci == 6)

*****************
***clasehog_ch***
*****************
g byte clasehog_ch = 0
**** unipersonal
replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
**** nuclear (child with or without spouse but without other relatives)
replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
**** ampliado
replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
**** compuesto (some relatives plus non relative)
replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
**** corresidente
replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)

*****************
***miembros_ci***
*****************
gen byte miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
replace miembros_ci=. if relacion_ci==.

*****************
*miembros_one_ci*
*****************
gen byte miembros_one_ci=(p6050>=1 & p6050<=13)
replace miembros_one_ci=0 if p6050==10
replace miembros_one_ci=. if p6050==.

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


	*****************************
	***VARIABLES DE DIVERSIDAD***
	*****************************

*********
*afro_ci*
*********
**Pregunta: De acuerdo con su cultura, pueblo o rasgos físicos, … es o se reconoce como:(P6080)
*1- Indigena 2- Gitano - Rom 3- Raizal del archipiélago de San Andrés y providencia
*4- Palenquero de San basilio o descendiente 5- Negro(a), mulato(a), Afrocolombiano(a) o Afrodescendiente
*6- Ninguno de los anteriores (mestizo, blanco, etc)
tab p6080, m

gen byte afro_ci = .
replace afro_ci = 1 if p6080 == 3 | p6080 == 4 | p6080 == 5
replace afro_ci = 0 if p6080 != 3 & p6080 != 4 & p6080 != 5 & p6080 != .
tab afro_ci, m

*********
*ind_ci*
*********
gen byte ind_ci =.
replace ind_ci = 1 if p6080 == 1
replace ind_ci = 0 if p6080 != 1 & p6080 != .

tab ind_ci, m

**************
*noafroind_ci*
**************
gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
replace noafroind_ci =1 if (afro_ci==0 & ind_ci==0)
replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
replace noafroind_ci =. if (afro_ci==. | ind_ci==.) //Esto solo en el caso que se tenga ambas opciones no disponibles.
tab noafroind_ci,m

************
*afroind_ci*
************
gen byte afroind_ci=.
replace afroind_ci=1 if ind_ci==1
replace afroind_ci=2 if afro_ci==1
replace afroind_ci=3 if noafroind_ci == 1
ta afroind_ci,m

*******************
***afroind_ano_c***
*******************
gen afroind_ano_c=2006

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
gen byte dis_ci = .
replace dis_ci = 1 if p1906s1<=3 | p1906s2<=3 | p1906s3<=3 | p1906s4<=3 | p1906s5<=3 | p1906s6<=3 | p1906s7<=3
replace dis_ci = 0 if p1906s1==4 & p1906s2==4 & p1906s3==4 & p1906s4==4 & p1906s5==4 & p1906s6==4 & p1906s7==4
tab dis_ci, m

**********
*disWG_ci*
**********
gen byte disWG_ci=.
replace disWG_ci = 1 if p1906s1<=2 | p1906s2<=2 | p1906s3<=2 | p1906s4<=2 | p1906s5<=2 | p1906s6<=2 | p1906s7<=2
replace disWG_ci = 0 if p1906s1>=3 & p1906s2>=3 & p1906s3>=3 & p1906s4>=3 & p1906s5>=3 & p1906s6>=3 & p1906s7>=3
tab disWG_ci, m

********
*dis_ch*
********
egen byte dis_ch = max(dis_ci), by(idh_ch)

******************
*ISOalpha3_dis_ci*
******************
gen byte COL_dis_ci = dis_ci

		**********************************
		***VARIABLES DE MERCADO LABORAL***
		**********************************

*************
*condocup_ci*
*************
gen byte condocup_ci = .
replace condocup_ci=1 if oci==1
replace condocup_ci=2 if dsi==1
replace condocup_ci=3 if fft==1
replace condocup_ci=4 if edad_ci<15 // Las preguntas sobre ocupación se hacen a personas de 10 años en adelante. Pero en la BBDD sólo existe información disponible desde los 15 años.

*******************
***categoinac_ci***
*******************
gen byte categoinac_ci = .
replace categoinac_ci=1 if p7450==5 & condocup_ci==3
recode categoinac_ci .=2 if (p7450==2 | p6240==3) & condocup_ci==3
recode categoinac_ci .=3 if (p7450==3 | p6240==4) & condocup_ci==3
replace categoinac_ci=4 if !inlist(categoinac_ci,1,2,3) & condocup_ci==3 & categoinac_ci==.

**********
***emp_ci*
**********
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if condocup_ci != .

**************
***cesante_ci***
**************
gen byte cesante_ci = .
replace cesante_ci = 1 if (p7430 == 1 & condocup_ci == 2)
replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

***************
***desemp_ci***
***************
gen byte desemp_ci = .
replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .

***************
***horaspri_ci***
***************
gen  byte horaspri_ci = p6800
replace horaspri_ci = . if emp_ci == 0

***************
***horastot_ci ***
***************
egen horastot_ci  = rowtotal(p6800 p7045)
replace horastot_ci = . if p6800 == . & p7045 == .
replace horastot_ci  = . if emp_ci == 0

***************
***subemp_ci***
***************
gen byte subemp_ci = 0
replace subemp_ci = 1 if horaspri_ci <= 30  & p7090 == 1 & p7160==1
replace subemp_ci = . if emp_ci == .

****************
***durades_ci***
****************
gen byte durades_ci=p7250 / 4.3
replace durades_ci = . if p7250 == 999 | p7250 == 998

***********
***pea_ci***
***********
gen byte pea_ci = .
replace pea_ci = 1 if inlist(condocup_ci,1,2)
replace pea_ci = 0 if inlist(condocup_ci,3,4)

*****************
***nempleos_ci***
*****************
gen byte nempleos_ci = .
replace nempleos_ci = 1 if emp_ci == 1 & p7040 == 2
replace nempleos_ci = 2 if emp_ci == 1 & p7040 == 1
replace nempleos_ci = . if p7040 == .
replace nempleos_ci = . if emp_ci == 0

******************
***antiguedad_ci***
******************
gen byte antiguedad_ci = p6426 / 12
replace antiguedad_ci = . if emp_ci == 0 | p6426 == 999

***************
***desalent_ci***
***************
g desalent_ci = inrange(p6310, 4, 6)
replace desalent_ci = . if p6310 == .

*******************
***tiempoparc_ci***
*******************
gen byte tiempoparc_ci = (horaspri_ci < 30 & p7090 == 2)
replace tiempoparc_ci = . if emp_ci == 0

***************
***parcial_ci***
***************
gen byte parcial_ci = .
replace parcial_ci = (horaspri_ci < 35) if emp_ci == 1 & horaspri_ci != .
label define parcial_lb 1 "Parcial (<35h)" 0 "Completo (>=35h)"
label values parcial_ci parcial_lb
label var parcial_ci "1 = trabajador a tiempo parcial (horaspri_ci < 35h)"

******************
***categopri_ci***
******************
gen  byte categopri_ci = .
replace categopri_ci = 1 if p6430 == 5
replace categopri_ci = 2 if p6430 == 4
replace categopri_ci = 3 if p6430 == 1 | p6430 == 2 | p6430 == 3
replace categopri_ci = 4 if p6430 == 6 | p6430 == 7
replace categopri_ci = 0 if p6430 == 8 | p6430==9
replace categopri_ci = . if emp_ci == 0

******************
***categosec_ci***
******************
gen  byte categosec_ci = .
replace categosec_ci = 1 if p7050 == 5
replace categosec_ci = 2 if p7050 == 4
replace categosec_ci = 3 if p7050 == 1 | p7050 == 2 | p7050 == 3
replace categosec_ci = 4 if p7050 == 6 | p7050 == 7
replace categosec_ci = 0 if p7050 == 8
replace categosec_ci = . if emp_ci == 0

***************
***rama_ci ***
***************
destring rama4d_r4, replace
g rama_ci = .
replace rama_ci=1 if (rama4d_r4>=100 & rama4d_r4<=322) & emp_ci==1
replace rama_ci=2 if (rama4d_r4>=510 & rama4d_r4<=990) & emp_ci==1
replace rama_ci=3 if (rama4d_r4>=1010 & rama4d_r4<=3320) & emp_ci==1
replace rama_ci=4 if (rama4d_r4>=3510 & rama4d_r4<=3900) & emp_ci==1
replace rama_ci=5 if (rama4d_r4>=4100 & rama4d_r4<=4390) & emp_ci==1
replace rama_ci=6 if ((rama4d_r4>=4510 & rama4d_r4<=4799) | (rama4d_r4>=5510 & rama4d_r4<=5630))& emp_ci==1
replace rama_ci=7 if ((rama4d_r4>=4911 & rama4d_r4<=5320) | (rama4d_r4>=6110 & rama4d_r4<=6190)) & emp_ci==1
replace rama_ci=8 if (rama4d_r4>=6411 & rama4d_r4<=8299) & emp_ci==1
replace rama_ci=9 if ((rama4d_r4>=5811 & rama4d_r4<=6022) | (rama4d_r4>=6201 & rama4d_r4<=6399) | (rama4d_r4>=8411 & rama4d_r4<=9900)) & emp_ci==1

***************
***spublico_ci ***
***************
gen  byte spublico_ci = (p6430 == 2 | p7050 ==2)
replace spublico_ci = . if emp_ci == 0

***************
***tamemp_ci ***
***************
* Actualizado para considerar pregunta realizada a Ocupados 17/02/2026
* p3069 ¿Cuántas personas en total tiene la empresa, negocio o finca, donde ... trabajaba? (Ocupados)
* 1 - Trabaja solo  |  2 - 2 a 3 personas  |  3 - 4 a 5 personas  |  4 - 6 a 10 personas
* 5 - 11 a 19 personas  |  6 - 20 a 30 personas  |  7 - 31 a 50 personas
* 8 - 51 a 100 personas  |  9 - 101 a 200 personas  |  10 - 201 o más personas
gen  byte tamemp_ci = .
replace tamemp_ci=1 if p3069>=1 & p3069<=3
replace tamemp_ci=2 if p3069>=4 & p3069<=7
replace tamemp_ci=3 if p3069>=8 & p3069<=10

******************
***cotizando_ci***
******************
gen  byte cotizando_ci = .
replace cotizando_ci=1 if p6920==1
replace cotizando_ci=0 if p6920==2 | (condocup_ci==2 & p6920!=1)

*****************
***afiliado_ci***
*****************
* FIX-COL-01 (QA 2026-04-21): usar p6100 (régimen contributivo/especial) en lugar de p6090
* p6090==1 incluye Régimen Subsidiado (informal), inflando formalidad; p6100 restringe a contributivo/especial
gen  byte afiliado_ci = inlist(p6100, 1, 2)
replace afiliado_ci=. if p6090==9

***************
***instcot_ci***
***************
gen  byte instcot_ci = p6930

**************
***formal_ci***
**************
gen byte formal_ci = .
replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
replace formal_ci = 0 if (cotizando_ci == 0 & afiliado_ci == 0) & condocup_ci == 1

*********************
***tipocontrato_ci***
*********************
gen byte tipocontrato_ci = .
replace tipocontrato_ci=1 if p6460==1 & condocup_ci==1
replace tipocontrato_ci=2 if p6460==2 & condocup_ci==1
replace tipocontrato_ci=3 if p6450==1 & condocup_ci==1
replace tipocontrato_ci=3 if p6440==2 & condocup_ci==1

**************
***ocupa_ci***
**************
* FIX-COL-02 (HDMF 2025): derivado del primer dígito de oficio_c8 (CIUO-08, 4-digit string)
* Método anterior (2024) usaba 2 dígitos y agrupaba incorrectamente grupos 7/8/9
* oficio_c8 iniciando con "0" = Fuerzas Armadas (ISCO 0) → missing per HDMF convention
gen byte ocupa_ci = .
replace ocupa_ci = real(substr(trim(oficio_c8), 1, 1)) if emp_ci == 1
replace ocupa_ci = . if emp_ci == 1 & substr(trim(oficio_c8), 1, 1) == "0"
replace ocupa_ci = . if emp_ci != 1
label define ocupa_lbl 1 "Managers" 2 "Professionals" 3 "Technicians" 4 "Clerical" 5 "Services/Sales" 6 "Skilled Agri" 7 "Craft" 8 "Machine operators" 9 "Elementary", replace
label values ocupa_ci ocupa_lbl
label var ocupa_ci "ISCO-08 major group (1-digit, from oficio_c8 CIUO-08)"


**************
**pension_ci***
**************
gen byte pension_ci=.
replace pension_ci=(p7500s2a1>0 & p7500s2a1!=.)
replace cotizando_ci = 1 if pension_ci==1 // según el manual "Todos los pensionados contributivos necesariamente cotizan a algún sistema de seguridad social"

*****************
**pensionsub_ci**
*****************
gen byte pensionsub_ci = .
replace pensionsub_ci =(p1661s3==1)
replace cotizando_ci = 0 if pensionsub_ci==1

***************
**tipopen_ci**
***************
gen byte tipopen_ci = .

***************
**instpen_ci **
***************
gen byte instpen_ci = .


	****************************
	***VARIABLES DE INGRESO***
	****************************

*************
* ylmpri_ci *
*************
egen ylmpri_ci = rsum(impa impaes) if emp_ci==1, m
replace ylmpri_ci = . if impa==. & impaes==.

************
* ylmsec_ci *
************
egen ylmsec_ci = rsum(isa isaes) if emp_ci==1, m
replace ylmsec_ci=. if isa==. & isaes==.

**************
* ylmotros_ci *
**************
egen ylmotros_ci= rsum(imdi imdies), m
* REVISAR PORQUE SI LO LIMITO A emp_ci==1 SE GENERA TODO COMO MISSING

*********
* ylm_ci *
*********
egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

**************
* ylnmpri_ci *
**************
egen ylnmpri_ci = rsum(ie iees) if emp_ci==1, m
replace ylnmpri_ci=. if ie==. & iees==.
replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

**************
* ylnmsec_ci *
**************
*egen double ylnmsec_ci = rowtotal(...) if emp_ci==1, mi
*replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .
g ylnmsec_ci = . /*No se pregunta ingreso por especies para act secundaria */

****************
* ylnmotros_ci *
****************
*egen double ylnmotros_ci = rowtotal(...) if emp_ci==1, mi
*replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .
g ylnmotros_ci = .

**********
* ylnm_ci *
**********
egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

**********
* ynlm_ci *
**********
egen ynlm_ci = rsum(iof1 iof2  iof3h iof3i iof6 iof1es iof2es  iof3hes iof3ies iof6es), m
replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

***********
* ynlnm_ci *
***********
*egen double ynlnm_ci = rowtotal(...), mi
*replace ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .
g ynlnm_ci = .

**********
* ytot_ci *
**********
egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

*********
* ylm_ch *
*********
bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1

**********
* ylnm_ch *
**********
bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1

***********
* ynlnm_ch *
***********
bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1

*********
* ynlm_ch *
*********
bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci==1

**********
* ytot_ch *
**********
egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

***************
* ylmhopri_ci *
***************
generate double ylmhopri_ci = ylmpri_ci / horaspri_ci if emp_ci==1 & horaspri_ci>0

**********
* ylmho_ci *
**********
generate double ylmho_ci = ylm_ci / horastot_ci if emp_ci==1 & horastot_ci>0

**************
* nrylmpri_ci *
**************
generate byte nrylmpri_ci = (emp_ci==1 & ylmpri_ci==.)

**************
* nrylmpri_ch *
**************
bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci==1

*************
* remesas_ci *
*************
generate double remesas_ci = p7510s2a1/12 if p7510s2a1>9999 & p7510s2a1!=.

*************
* remesas_ch *
*************
by idh_ch, sort: egen double remesas_ch = sum(remesas_ci) if relacion_ci >= 1 & relacion_ci <= 5

**********
* ypen_ci *
**********
egen ypen_ci = rsum(iof2 iof2es), m

*************
* ypensub_ci *
*************
egen ypensub_ci = rsum(iof2 iof2es) if pensionsub_ci==1, m


		****************************
		***VARIABLES DE EDUCACION***
		****************************

**************
***aedu_ci***
**************
// CORREGIDA: Educación superior codificada correctamente con semestres / 2
// p3042s1 para niveles 7-13 está en semestres — se divide por 2 para convertir a años

/*
1  Ninguno  |  2  Preescolar  |  3  Básica primaria (1o-5o)
4  Básica secundaria (6o-9o)  |  5  Media académica  |  6  Media técnica
7  Normalista  |  8  Técnica profesional  |  9  Tecnológica
10 Universitaria  |  11 Especialización  |  12 Maestría  |  13 Doctorado
99 No sabe, no informa
*/

g aedu_ci = .
* 0 años de educacion
replace aedu_ci = 0 if p3042 == 1 | p3042 == 2

* en años
// Primaria: p3042s1 = grado 1-5 (relativo)
replace aedu_ci = p3042s1 if p3042==3
// Secundaria básica: p3042s1 = grado relativo 1-4 (6o-9o en absoluto) → 5+grado = 6-9 años totales
replace aedu_ci = 5 + p3042s1 if p3042 == 4
// Media: p3042s1 = grado relativo → 11+grado
replace aedu_ci = 11 + p3042s1 if inlist(p3042, 5, 6)

// Superior: p3042s1 está en semestres → convertir a años (trunc(sem/2)), con topes por nivel
g sup_top = trunc(p3042s1/2)
replace sup_top = 5 if p3042 == 10 & p3042s1 > 10    // universitaria: máx 5 años adicionales
replace sup_top = 2 if inlist(p3042, 11, 12) & p3042s1 > 4  // especialización/maestría: máx 2
replace sup_top = 3 if p3042 == 13 & p3042s1 > 6     // doctorado: máx 3

replace aedu_ci = 11 + sup_top if inlist(p3042, 7, 8, 9, 10)   // normalista, técnica, tecnológica, univ
replace aedu_ci = 16 + sup_top if inlist(p3042, 11, 12)         // especialización, maestría (11+5=16 base)
replace aedu_ci = 18 + sup_top if inlist(p3042, 13)             // doctorado (11+5+2=18 base)

drop sup_top

* ISCED-2011 attainment (0–8)
gen byte edu_isced = .
replace edu_isced = 0 if aedu_ci == 0                        // ISCED 0: menos de primaria
replace edu_isced = 1 if aedu_ci >= 5 & aedu_ci < 9         // ISCED 1: primaria
replace edu_isced = 2 if aedu_ci >= 9 & aedu_ci < 11        // ISCED 2: secundaria baja
replace edu_isced = 3 if aedu_ci == 11                       // ISCED 3: secundaria alta
replace edu_isced = 4 if p3042 == 7                          // ISCED 4: post-secundaria no terciaria (Normalista)
replace edu_isced = 5 if inlist(p3042, 8, 9)                 // ISCED 5: terciaria ciclo corto
replace edu_isced = 6 if p3042 == 10                         // ISCED 6: bachiller o equivalente
replace edu_isced = 7 if inlist(p3042, 11, 12)               // ISCED 7: maestría o equivalente
replace edu_isced = 8 if p3042 == 13                         // ISCED 8: doctorado
replace edu_isced = . if inlist(p3042, ., 99)
label define edu_isced_lbl ///
  0 "ISCED 0 Early childhood / less than primary" ///
  1 "ISCED 1 Primary" ///
  2 "ISCED 2 Lower secondary" ///
  3 "ISCED 3 Upper secondary" ///
  4 "ISCED 4 Post-secondary non-tertiary" ///
  5 "ISCED 5 Short-cycle tertiary" ///
  6 "ISCED 6 Bachelor's or equivalent" ///
  7 "ISCED 7 Master's or equivalent" ///
  8 "ISCED 8 Doctoral or equivalent"
label values edu_isced edu_isced_lbl


***************
***edupre_ci***
***************
g byte edupre_ci =.

**************
***eduui_ci***
**************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria
g byte eduui_ci = 0
replace eduui_ci = 1 if inlist(p3042, 8, 9, 10) & p3043<5
replace eduui_ci = . if aedu_ci == .

***************
***eduuc_ci***
***************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria
g byte eduuc_ci = (inlist(p3042, 8, 9, 10, 11, 12, 13) & inlist(p3043, 5, 6, 7, 8, 9, 10))
replace eduuc_ci = . if aedu_ci == .

**************
***eduac_ci***
**************
gen byte eduac_ci = .
replace eduac_ci = 1 if (inlist(p3042, 10, 11, 12, 13) & inlist(p3043, 7, 8, 9, 10))
replace eduac_ci = 0 if (inlist(p3042, 8, 9 ) & inlist(p3043, 5, 6))

***************
***asiste_ci***
***************
* FIX-COL-03 (QA 2026-05-28): p6170 es la variable correcta (no p3038)
* p6170: 1=sí asiste actualmente, 2=no — verificado en script de referencia MECOVI
gen byte asiste_ci = .
replace asiste_ci = 1 if p6170 == 1
replace asiste_ci = 0 if p6170 == 2

***************
***edupub_ci***
***************
g edupub_ci =.
replace edupub_ci = 1 if p3041 == 1 & p6170==1
replace edupub_ci = 0 if p3041 == 2 & p6170==1

***************
***asispre_ci**
***************
g asispre_ci= (p6170==1 & p3042==2 & p3042s1 <2)

**************
*razonesnoasis_ci*
**************
g razonesnoasis_ci = .

*------------------------------------------------------------
* Campo de estudio — ISCED-F 2013 (p3042s2, 4 dígitos)
*------------------------------------------------------------
gen profesion_ci=p3042s2
label define lbl_p3042s2 ///
11   "Programas y certificaciones básicos" ///
21   "Alfabetización y Aritmética Elemental" ///
31   "Competencias personales y desarrollo" ///
111  "Ciencias de la educación" ///
112  "Formación para docentes de educación preprimaria" ///
113  "Formación para docentes sin asignatura de especialización" ///
114  "Formación para docentes con asignatura de especialización" ///
119  "Educación no clasificada en otra parte" ///
188  "Programas y certificaciones interdisciplinarios relativos a educación" ///
211  "Técnicas Audiovisuales y Producción para Medios de Comunicación" ///
212  "Diseño Industrial, de Moda e Interiores" ///
213  "Bellas Artes" ///
214  "Artesanías" ///
215  "Música y Artes Escénicas" ///
219  "Artes no clasificados en otra parte" ///
221  "Religión y Teología" ///
222  "Historia y Arqueología" ///
223  "Filosofía y Ética" ///
229  "Humanidades (excepto idiomas) no clasificados en otra parte" ///
231  "Adquisición del lenguaje" ///
232  "Literatura y Lingüística" ///
239  "Idiomas no clasificados en otra parte" ///
288  "Programas y certificaciones interdisciplinarios relativos a Artes y Humanidades" ///
311  "Economía" ///
312  "Ciencias Políticas y Educación Cívica" ///
313  "Psicología" ///
314  "Sociología, antropología y estudios culturales" ///
315  "Trabajo Social" ///
319  "Ciencias Sociales y del Comportamiento no clasificados en otra parte" ///
321  "Periodismo y Reportajes" ///
322  "Bibliotecología, Información y Archivística" ///
329  "Periodismo e Información no clasificados en otra parte" ///
388  "Programas y certificaciones interdisciplinarios relativos a Ciencias Sociales, Periodismo e Información" ///
411  "Contabilidad e Impuestos" ///
412  "Gestión Financiera, Administración Bancaria y Seguros" ///
413  "Gestión y administración" ///
414  "Mercadeo y Publicidad" ///
415  "Secretariado y trabajo de oficina" ///
416  "Ventas al por mayor y al por menor" ///
417  "Competencias laborales" ///
419  "Educación Comercial y Administración no clasificados en otra parte" ///
421  "Derecho" ///
488  "Programas y certificaciones interdisciplinarios relativos a Administración de Empresas y Derecho" ///
511  "Biología" ///
512  "Bioquímica" ///
519  "Ciencias Biológicas y afines no clasificados en otra parte" ///
521  "Ciencias del Medio Ambiente" ///
522  "Medio Ambiente Natural y Vida Silvestre" ///
529  "Medio Ambiente no clasificados en otra parte" ///
531  "Química" ///
532  "Ciencias de la Tierra" ///
533  "Física" ///
539  "Ciencias Físicas no clasificadas en otra parte" ///
541  "Matemáticas" ///
542  "Estadística" ///
588  "Programas y certificaciones interdisciplinarios relativos a Ciencias Naturales, Matemáticas y Estadística" ///
611  "Uso de computadores" ///
612  "Diseño y Administración de Redes y Bases de datos" ///
613  "Desarrollo y Análisis de software y Aplicaciones" ///
619  "TIC no clasificados en otra parte" ///
688  "Programas y certificaciones interdisciplinarios relativos a TIC" ///
711  "Ingeniería y Procesos Químicos" ///
712  "Tecnología de protección del medio ambiente" ///
713  "Electricidad y Energía" ///
714  "Electrónica y Automatización" ///
715  "Mecánica y profesiones afines a la Metalistería" ///
716  "Vehículos, Barcos y Aeronaves de motor" ///
719  "Ingeniería y profesiones afines no clasificadas en otra parte" ///
721  "Procesamiento de alimentos" ///
722  "Industria y Procesamiento de Materiales (vidrio, papel, plástico y madera)" ///
723  "Productos textiles (prendas de vestir, calzado y artículos de marroquinería)" ///
724  "Minería y Extracción" ///
729  "Industria y Procesamiento no clasificados en otra parte" ///
731  "Arquitectura y Urbanismo" ///
732  "Construcción e Ingeniería Civil" ///
788  "Programas y certificaciones interdisciplinarios relativos a Ingeniería, Industria y Construcción" ///
811  "Producción Agrícola y Ganadera" ///
812  "Horticultura (técnicas de huertas, invernaderos, viveros y jardines)" ///
819  "Agropecuario no clasificado en otra parte" ///
821  "Silvicultura" ///
831  "Pesca y Acuicultura" ///
841  "Veterinaria" ///
888  "Programas y certificaciones interdisciplinarios relativos a Agropecuario, Silvicultura, Pesca y Veterinaria" ///
911  "Odontología y estudios dentales" ///
912  "Medicina" ///
913  "Enfermería" ///
914  "Tecnología de diagnóstico y tratamiento médico" ///
915  "Fisioterapia, fonoaudiología, nutrición y dietética, optometría, terapia ocupacional y terapia respiratoria" ///
916  "Farmacia" ///
917  "Medicina y terapia alternativa y complementaria, y partería tradicional" ///
918  "Instrumentación quirúrgica" ///
919  "Salud no clasificada en otra parte" ///
921  "Asistencia a adultos, adultos mayores con o sin discapacidad" ///
922  "Asistencia, protección y servicios a la infancia, adolescencia y juventud" ///
929  "Bienestar no clasificado en otra parte" ///
988  "Programas y certificaciones interdisciplinarios relativos a Salud y Bienestar" ///
1011 "Servicios domésticos" ///
1012 "Peluquería y tratamientos de belleza" ///
1013 "Hotelería, restaurantes y servicios de banquetes" ///
1014 "Deportes" ///
1015 "Viajes, turismo y actividades recreativas" ///
1016 "Servicios de tanatopraxia" ///
1019 "Servicios personales no clasificados en otra parte" ///
1021 "Saneamiento de la comunidad" ///
1022 "Salud y protección laboral" ///
1029 "Servicios de Higiene y Salud Ocupacional no clasificados en otra parte" ///
1031 "Educación militar y de defensa" ///
1032 "Protección de las personas y de la propiedad" ///
1039 "Servicios de Seguridad no clasificados en otra parte" ///
1041 "Servicios de transporte" ///
1088 "Programas y certificaciones interdisciplinarios relativos a Servicios", replace
label values profesion_ci lbl_p3042s2
label var profesion_ci "Área/campo de educación (ISCED-F 2013, 4 dígitos sin ceros)"

* ISCED-F agregado a 2 dígitos (campo de estudio)
gen byte cinef13_ci = .
replace cinef13_ci = 10 if inrange(p3042s2,1000,1099)
replace cinef13_ci = 9  if inrange(p3042s2, 900, 999)
replace cinef13_ci = 8  if inrange(p3042s2, 800, 899)
replace cinef13_ci = 7  if inrange(p3042s2, 700, 799)
replace cinef13_ci = 6  if inrange(p3042s2, 600, 699)
replace cinef13_ci = 5  if inrange(p3042s2, 500, 599)
replace cinef13_ci = 4  if inrange(p3042s2, 400, 499)
replace cinef13_ci = 3  if inrange(p3042s2, 300, 399)
replace cinef13_ci = 2  if inrange(p3042s2, 200, 299)
replace cinef13_ci = 1  if inrange(p3042s2, 100, 199)
replace cinef13_ci = 0  if inrange(p3042s2,   0,  99)

label define lbl_cinef13_ci ///
0  "Programas y certificaciones genéricos" ///
1  "Educación" ///
2  "Artes y Humanidades" ///
3  "Ciencias Sociales, Periodismo e Información" ///
4  "Administración de Empresas y Derecho" ///
5  "Ciencias Naturales, Matemáticas y Estadística" ///
6  "Tecnología de la Información y la Comunicación (TIC)" ///
7  "Ingeniería, Industria y Construcción" ///
8  "Agropecuario, Silvicultura, Pesca y Veterinaria" ///
9  "Salud y bienestar" ///
10 "Servicios", replace
label values cinef13_ci lbl_cinef13_ci

* ISCED-F agregado a 3 dígitos (consecutivos)
capture drop profesion3_ci
gen byte profesion3_ci = .
replace profesion3_ci = 1 if profesion_ci == 11
replace profesion3_ci = 2 if profesion_ci == 21
replace profesion3_ci = 3 if profesion_ci == 31
replace profesion3_ci = 4 if inrange(profesion_ci, 111, 199)
replace profesion3_ci = 5 if inrange(profesion_ci, 211, 219)
replace profesion3_ci = 6 if inrange(profesion_ci, 221, 229)
replace profesion3_ci = 7 if inrange(profesion_ci, 231, 239)
replace profesion3_ci = 5 if profesion_ci == 288
replace profesion3_ci = 8 if inrange(profesion_ci, 311, 319)
replace profesion3_ci = 9 if inrange(profesion_ci, 321, 329)
replace profesion3_ci = 8 if profesion_ci == 388
replace profesion3_ci = 10 if inrange(profesion_ci, 411, 419)
replace profesion3_ci = 11 if profesion_ci == 421
replace profesion3_ci = 10 if profesion_ci == 488
replace profesion3_ci = 12 if inrange(profesion_ci, 511, 519)
replace profesion3_ci = 13 if inrange(profesion_ci, 521, 529)
replace profesion3_ci = 14 if inrange(profesion_ci, 531, 539)
replace profesion3_ci = 15 if inrange(profesion_ci, 541, 542)
replace profesion3_ci = 12 if profesion_ci == 588
replace profesion3_ci = 16 if inrange(profesion_ci, 611, 619) | profesion_ci == 688
replace profesion3_ci = 17 if inrange(profesion_ci, 711, 719) | profesion_ci == 788
replace profesion3_ci = 18 if inrange(profesion_ci, 721, 729)
replace profesion3_ci = 19 if inrange(profesion_ci, 731, 732)
replace profesion3_ci = 20 if inrange(profesion_ci, 811, 819) | profesion_ci == 888
replace profesion3_ci = 21 if profesion_ci == 821
replace profesion3_ci = 22 if profesion_ci == 831
replace profesion3_ci = 23 if profesion_ci == 841
replace profesion3_ci = 24 if inrange(profesion_ci, 911, 919) | profesion_ci == 988
replace profesion3_ci = 25 if inrange(profesion_ci, 921, 929)
replace profesion3_ci = 26 if inrange(profesion_ci, 1011, 1019) | profesion_ci == 1088
replace profesion3_ci = 27 if inrange(profesion_ci, 1021, 1029)
replace profesion3_ci = 28 if inrange(profesion_ci, 1031, 1039)
replace profesion3_ci = 29 if profesion_ci == 1041

capture label drop lbl_profesion3_ci
label define lbl_profesion3_ci ///
    1  "Programas y certificaciones básicas" ///
    2  "Alfabetización y Aritmética Elemental" ///
    3  "Competencias personales y desarrollo" ///
    4  "Educación" ///
    5  "Artes" ///
    6  "Humanidades (excepto idiomas)" ///
    7  "Idiomas" ///
    8  "Ciencias Sociales y del Comportamiento" ///
    9  "Periodismo e Información" ///
    10 "Educación Comercial y Administración" ///
    11 "Derecho" ///
    12 "Ciencias Biológicas y afines" ///
    13 "Medio Ambiente" ///
    14 "Ciencias Físicas" ///
    15 "Matemáticas y Estadística" ///
    16 "Tecnologías de la Información y la Comunicación (TIC)" ///
    17 "Ingeniería y Profesiones afines" ///
    18 "Industria y Procesamiento" ///
    19 "Arquitectura y Construcción" ///
    20 "Agropecuario" ///
    21 "Silvicultura" ///
    22 "Pesca y acuicultura" ///
    23 "Veterinaria" ///
    24 "Salud" ///
    25 "Bienestar" ///
    26 "Servicios personales" ///
    27 "Servicios de Higiene y Salud Ocupacional" ///
    28 "Servicios de seguridad" ///
    29 "Servicios de transporte", replace
label values profesion3_ci lbl_profesion3_ci
label var profesion3_ci "Área/campo de educación (ISCED-F 2013, agregado 3 dígitos, consecutivo)"


		****************************
		***VARIABLES DE VIVIENDA***
		****************************

***********
*luz_ch*
***********
g luz_ch = p4030s1 == 1
replace luz_ch=. if p4030s1==.

***********
*luzmide_ch*
***********
g luzmide_ch = .

************
*combust_ch*
************
g combust_ch = (p5080 == 1 | p5080 == 3 | p5080 == 4)
replace combust_ch =. if p5080==.

**********
*piso_ch*
**********
g piso_ch = (p4020 != 1 & p4020 != .)
replace piso_ch = . if p4020 ==.

***********
*pared_ch*
***********
g pared_ch = (p4010 >= 1 & p4010 <= 3)
replace pared_ch = . if p4010 == .

***********
*techo_ch*
***********
g techo_ch = .

**********
*resid_ch*
**********
g resid_ch = 0		 if p5040 == 1
replace resid_ch = 1 if p5040 == 4
replace resid_ch = 2 if p5040 == 2 | p5040 == 3
replace resid_ch = 3 if p5040 == 5
replace resid_ch = . if p5040 == .

*************
***dorm_ch***
*************
g dorm_ch = p5010

****************
***cuartos_ch***
****************
g cuartos_ch = p5000

***************
***cocina_ch***
***************
g cocina_ch = 0 if p5070 >= 2 & p5070 <= 6
replace cocina_ch = 1 if p5070 == 1

**************
***telef_ch***
**************
g telef_ch =.

***************
***refrig_ch***
***************
g refrig_ch =.

**************
***freez_ch***
**************
g freez_ch = .

*************
***auto_ch***
*************
g auto_ch =.

**************
***compu_ch***
**************
g compu_ch =.

*****************
***internet_ch***
*****************
g internet_ch =.

************
***cel_ch***
************
g cel_ch =.


**************
***vivi1_ch***
**************
* Cambio en 2025 P4005 es el tipo de la vivienda
g vivi1_ch = 1     	 if p4005 == 1
replace vivi1_ch = 2 if p4005 == 2
replace vivi1_ch = 3 if p4005 == 3 | p4005 == 4 | p4005 == 5 | p4005 == 6
replace vivi1_ch = . if p4005 == .

**************
***vivi2_ch***
**************
g vivi2_ch = (vivi1_ch == 1 | vivi1_ch == 2)
replace vivi2_ch = . if vivi1_ch == .


*****************
***viviprop_ch***
*****************
g viviprop_ch = 0 if p5090 == 3
replace viviprop_ch = 1 if p5090 == 1
replace viviprop_ch = 2 if p5090 == 2
replace viviprop_ch = 3 if p5090 == 4 | p5090 == 5 | p5090 == 6
replace viviprop_ch = . if p5090 == .

****************
***vivitit_ch***
****************
g vivitit_ch = .

****************
***vivialq_ch***
****************
g vivialq_ch = p5140 if p5140 >= 10000

*******************
***vivialqimp_ch***
*******************
g vivialqimp_ch = p5130 if p5130 >= 10000


	***********************
	***VARIABLES DE WASH***
	***********************

****************
***aguared_ch***
****************
generate aguared_ch =.
replace aguared_ch = 1 if p4030s5==1
replace aguared_ch = 0 if p4030s5==2

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0
replace aguafconsumo_ch = 1 if p5050==1
replace aguafconsumo_ch = 2 if p5050==7
replace aguafconsumo_ch = 3 if p5050==10
replace aguafconsumo_ch = 5 if p5050==5
replace aguafconsumo_ch = 6 if p5050==8
replace aguafconsumo_ch = 7 if p5050==2
replace aguafconsumo_ch = 8 if p5050==6
replace aguafconsumo_ch = 9 if (p5050==4 | p5050==9)
replace aguafconsumo_ch = 10 if (p5050==3| p5050==2)

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.
replace aguafuente_ch = 1 if p5050==1
replace aguafuente_ch = 2 if p5050==7
replace aguafuente_ch = 3 if p5050==10
replace aguafuente_ch = 5 if p5050==5
replace aguafuente_ch = 6 if p5050==8
replace aguafuente_ch = 7 if p5050==2
replace aguafuente_ch = 8 if p5050==6
replace aguafuente_ch = 9 if (p5050==4 | p5050==9)
replace aguafuente_ch = 10 if (p5050==3 | p5050==2)
replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1

*************
*aguadist_ch*
*************
gen aguadist_ch=.
replace aguadist_ch=1 if (p5050==1 | p5050==2)
replace aguadist_ch=0 if p5050>2


**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =.


**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9

*************
*aguamala_ch*
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7

*****************
***aguamide_ch***
*****************
generate aguamide_ch = .

*****************
****bano_ch******
*****************
gen bano_ch=.
replace bano_ch=0 if p5020==6
replace bano_ch=1 if p5020==1
replace bano_ch=2 if p5020==2
replace bano_ch=4 if p5020==5
replace bano_ch=6 if p5020==3 | p5020 ==4
replace bano_ch=6 if bano_ch ==. & jefe_ci==1


***************
***banoex_ch***
***************
generate banoex_ch=.
replace banoex_ch = 1 if p5030==1
replace banoex_ch = 0 if p5030==2

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if p5020<6


*****************
*banomejorado_ch*
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6


		******************************
		*** VARIABLES DE MIGRACION ***
		******************************

*******************
*** migrante_ci ***
*******************
gen migrante_ci= (p3373==3)

**********************
*** migrantiguo5_ci ***
**********************
gen migrantiguo5_ci=(migrante_ci==1 & inlist(p3382,2,3)) if migrante_ci!=. & p3382!=1
replace migrantiguo5_ci = 0 if p3382 == 4 & migrante_ci==1 & migrante_ci!=. & p3382!=1
replace migrantiguo5_ci = . if migrante_ci==0

**********************
*** miglac_ci ***
**********************
destring p3373s3, replace

gen miglac_ci=(migrante_ci==1 & inlist(p3373s3, ///
32,   /* Argentina */ ///
68,   /* Bolivia */ ///
76,   /* Brasil */ ///
152,  /* Chile */ ///
170,  /* Colombia */ ///
188,  /* Costa Rica */ ///
192,  /* Cuba */ ///
214,  /* República Dominicana */ ///
218,  /* Ecuador */ ///
222,  /* El Salvador */ ///
320,  /* Guatemala */ ///
332,  /* Haití */ ///
340,  /* Honduras */ ///
484,  /* México */ ///
558,  /* Nicaragua */ ///
591,  /* Panamá */ ///
600,  /* Paraguay */ ///
604,  /* Perú */ ///
630,  /* Puerto Rico */ ///
858,  /* Uruguay */ ///
862,  /* Venezuela */ ///
44,   /* Bahamas */ ///
52,   /* Barbados */ ///
84,   /* Belice */ ///
28,   /* Antigua y Barbuda */ ///
212,  /* Dominica */ ///
308,  /* Granada */ ///
388,  /* Jamaica */ ///
659,  /* Saint Kitts y Nevis */ ///
662,  /* Santa Lucía */ ///
670,  /* San Vicente y las Granadinas */ ///
780,  /* Trinidad y Tabago */ ///
328,  /* Guyana */ ///
740,  /* Suriname */ ///
533,  /* Aruba */ ///
531   /* Curazao */ ///
)) if migrante_ci!=.

**********************
*** mig_pais_code ***
**********************
gen mig_pais_code = .
replace mig_pais_code = p3373s3 if migrante_ci==1 & migrante_ci!=.

**********************
*** mig_pais_ci ***
**********************
* Merge contra tabla de códigos para obtener nombre del país de nacimiento
* Ajustar la ruta del lookup según el entorno de ejecución
local lookup_mig = "$ruta\survey\COL\GEIH\lookup\mig_pais_code.dta"

gen mig_pais_ci = ""
capture merge m:1 p3373s3 using "`lookup_mig'", keep(master match) nogenerate
if _rc == 0 {
	replace mig_pais_ci = pais if migrante_ci==1 & migrante_ci!=.
	capture drop pais
}


	****************************
	***VARIABLES EXTERNAS***
	****************************

****************
*tipo_bienestar*
****************
gen byte tipo_bienestar = .
replace tipo_bienestar  = 1

****************
* pobre_ine_ci *
****************
capture gen byte pobre_ine_ci = pobre
if _rc != 0 gen byte pobre_ine_ci = .

**********************
*bienestar_agregado***
**********************
capture gen bienestar_agregado = ingpcug
if _rc != 0 gen bienestar_agregado = .

****************
*****lpe_ci ****
****************
gen lpe_ci = .
capture replace lpe_ci = li

****************
******ln_ci*****
****************
gen ln_ci = .
capture replace ln_ci = lp


/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, IPC, PPP, líneas de pobreza
* Solo disponible en el servidor SCL (requiere $gitFolder y $surveysFolder definidos)
/*_____________________________________________________________________________________________________*/


/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas
/*_____________________________________________________________________________________________________*/

  order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch idp_ci factor_ci factor_ch /// Identificación
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch COL_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci parcial_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci /// Empleo
  cotizando_ci instcot_ci afiliado_ci formal_ci tipocontrato_ci ocupa_ci /// Empleo
  pension_ci pensionsub_ci tipopen_ci instpen_ci /// Pensiones
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci nrylmpri_ci /// Ingresos individuo
  ylm_ch ylnm_ch ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci edu_isced eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  profesion_ci cinef13_ci profesion3_ci /// Campo de estudio
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamiento
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch /// Agua y saneamiento
  migrante_ci migrantiguo5_ci miglac_ci mig_pais_code mig_pais_ci /// Migración
  tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci ln_ci , first


compress

saveold "`base_out'", version(12) replace

log close
