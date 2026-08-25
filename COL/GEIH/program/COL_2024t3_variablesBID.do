	*(Versión stata 17)

**# Bookmark #1
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
local ANO "2024"
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
Autores: 
Versión ...:
Juan Camilo Perdomo (SCL/SCL) - Email: ..., Fecha: 24 de septiembre de 2025

*************************************************************************** */

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use `base_in', clear

		
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
g anio_c = 2024

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
replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)	 // Personas que NO se identifican como afro o indígenas
replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)  // Personas que se identifican como afro o indígenas
replace noafroind_ci =. if (afro_ci==. & ind_ci==.)
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
recode categoinac_ci .=4 if ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3)
	
**********
***emp_ci*
**********
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
label var emp_ci "Ocupado (empleado)"
label define emp_ci 0"No" 1"Si", add
label value emp_ci emp_ci

**************
***cesante_ci*** 
**************
gen byte cesante_ci = .
replace cesante_ci = 1 if (p7430 == 1 & condocup_ci == 2) 
replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

***************
***desemp_ci***
***************	
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte desemp_ci = .
replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
label var desemp_ci "Desocupado (desempleado)"
label define desemp_ci 0"No " 1"Si", add
label value desemp_ci desemp_ci

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
***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
gen byte desalent_ci = .
replace desalent_ci = 1 if (p6280 == 2 & inrange(p6310, 4, 6) & condocup_ci == 3)
replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
label var desalent_ci "Desalentados"
label define desalent_ci 0"No" 1"Si", add
label value desalent_ci desalent_ci
	
*******************
***tiempoparc_ci***
*******************	
gen byte tiempoparc_ci = (horaspri_ci < 30 & p7090 == 2)
replace tiempoparc_ci = . if emp_ci == 0
	
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

* 1 -	Trabaja solo
* 2 -	2 a 3 personas
* 3 -	4 a 5 personas
* 4 -	6 a 10 personas
* 5 -	11 a 19 personas
* 6 -	20 a 30 personas
* 7 -	31 a 50 personas
* 8 -	51 a 100 personas
* 9 -	101 a 200 personas
* 10 - 201 o más personas

gen  byte tamemp_ci = .
replace tamemp_ci=1 if p3069>=1 & p3069<=3
replace tamemp_ci=2 if p3069>=4 & p3069<=7
replace tamemp_ci=3 if p3069>=8 & p3069<=10
	
******************
***cotizando_ci***
******************	
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte cotizando_ci = .
replace cotizando_ci = 1 if (p6920==1 & emp_ci==1)
replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0 "No"  1 "Si"
label value cotizando_ci cotizando_ci

*****************
***afiliado_ci***
*****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte afiliado_ci = .
replace afiliado_ci = 1 if(p6090==1 & emp_ci==1)
replace afiliado_ci = 0 if (afiliado_ci != 1 & inlist(condocup_ci, 1, 2))
label var afiliado_ci "Afiliado a la Seguridad Social"
label define afiliado_ci 0 "No"  1 "Si"
label value afiliado_ci afiliado_ci
	
***************
***instcot_ci***
***************	
gen  byte instcot_ci = p6930
	
**************
***formal_ci***
**************
gen byte formal_ci = .
replace formal_ci  = (cotizando_ci == 1)
	
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
gen oficio_c8_2 = substr(oficio_c8, 1, 2)
destring oficio_c8_2, replace
gen byte ocupa_ci=.
replace ocupa_ci = 1 if oficio_c8_2 >= 1  & oficio_c8_2 <= 19 & emp_ci == 1  
replace ocupa_ci = 2 if oficio_c8_2 >= 20 & oficio_c8_2 <= 21 & emp_ci == 1
replace ocupa_ci = 3 if oficio_c8_2 >= 30 & oficio_c8_2 <= 39 & emp_ci == 1
replace ocupa_ci = 4 if oficio_c8_2 >= 40 & oficio_c8_2 <= 49 & emp_ci == 1
replace ocupa_ci = 5 if oficio_c8_2 >= 50 & oficio_c8_2 <= 59 & emp_ci == 1
replace ocupa_ci = 6 if oficio_c8_2 >= 60 & oficio_c8_2 <= 64 & emp_ci == 1
replace ocupa_ci = 7 if oficio_c8_2 >= 70 & oficio_c8_2 <= 98 & emp_ci == 1  
replace ocupa_ci = 9 if oficio_c8_2 == 0  | oficio_c8_2 == 99 & emp_ci == 1 

**************
**pension_ci***
**************
gen byte pension_ci = (p7500s2 ==1) if !missing(p7500s2)
replace pension_ci = . if p7500s2 == 9
*replace pension_ci = . if
replace cotizando_ci = 1 if pension_ci==1 // según el manual "Todos los pensionados contributivos necesariamente cotizan a algún sistema de seguridad social, es decir no puede darse el caso que pension_ci == 1 & cotizando_ci != 1"
	
*****************
**pensionsub_ci**
*****************
gen byte pensionsub_ci = (p1661s3 == 1) if !missing(p1661s3)

***************
**tipopen_ci**
***************
gen byte tipopen_ci = . 
	
***************
**instpen_ci **
***************
gen byte instpen_ci = .


	**************************************************
	***  VARIABLES DE INGRESOS & PROTECCION SOCIAL ***
	**************************************************

* A. INGRESOS LABORALES A NIVEL DE INDIVIDUO

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


* B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO	

****************
***ytransf_ci***
****************
	* PNC - Pensiones sociales no contributivas: 
			* Colombia mayor (p1661s3a1)
	* PTMC - Programas de transferencias monetarias condicionadas: 
			* Más familias en acción (p1661s1a1)
			* Jovenes en acción (p1661s2a1)
	* POTROT - Programas de otras transferencias monetarias no condicionadas: 
			* Otras ayudas monetarias del gobierno (p1661s4a2)

	*** Beneficiarios a nivel individual:
		gen byte pnc_ci = (p1661s3 == 1) if !missing(p1661s3)
		gen byte ptmc_ci = (p1661s1 == 1 | p1661s2 == 1)
		replace ptmc_ci  = . if p1661s1 == .  & p1661s2 == .
		gen byte potrot_ci = (p1661s4 == 1) if !missing(p1661s4)
	
	*** Montos de transferencias a nivel individual (mensualizado):
	
		// Transferencia por PNC
		gen double ypnc_ci = p1661s3a1/12
		replace ypnc_ci = . if p1661s3a1 == 99 | p1661s3a1 == 98
		
		// Transferencia por PTMC	
		gen double yfamac_ci = p1661s1a1/12
		replace yfamac_ci = . if p1661s1a1 == 99 | p1661s1a1 == 98
		
		gen double yjovac_ci = p1661s2a1/12
		replace yjovac_ci = . if p1661s2a1 == 99 | p1661s2a1 == 98
		
		egen double yptmc_ci = rowtotal(yfamac_ci yjovac_ci) if ptmc_ci == 1, mi
			
		// Transferencia por OTROT
		gen double yotrot_ci = p1661s4a2/12
		replace yotrot_ci = . if p1661s4a2 == 99 | p1661s4a2 == 98

*** Ingreso individual por transferencias no contributivas:	
egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi	// Transferencias declaradas
drop yfamac_ci yjovac_ci

***********
* ypen_ci *
***********
gen double ypen_ci = p7500s2a1 if pension_ci == 1
replace ypen_ci = . if p7500s2a1 == 98 | p7500s2a1 == 99

**************
* ypensub_ci *
**************
gen ypensub_ci = ypnc_ci

**************
* remesas_ci *
**************
gen double remesas_ci = p7510s2a1/12 if p7510s2 == 1
replace remesas_ci = . if p7510s2a1 == 98 | p7510s2a1 == 99

***********
* ynlm_ci *
***********
	foreach var in p7500s1 p7500s2 p7500s3 p7510s1 p7510s2 p7510s3 p7510s5 p7510s6 p7510s7 { 
	gen m_`var' = `var'a1
	replace m_`var' = . if `var'a1 == 99 | `var'a1 == 98
	}
	
	gen double yarriendo  = m_p7500s1 	// iof6*
	replace yarriendo = iof6es if iof6 == 0 & iof6es != . & (p7500s1a1 == 98 | p7500s1 == 9)
	replace yarriendo = iof6es if iof6 == 0 & iof6es != . & iof6es < m_p7500s1 
	
	gen double yjubilacion = m_p7500s2	// iof2* // = ypen_ci
	replace yjubilacion = iof2   if iof2 != . & iof2es == . & p7500s2a1 == 98 
	replace yjubilacion = iof2es if iof2 == 0 & iof2es != . & p7500s2   == 9
	replace yjubilacion = iof2es if iof2 == 0 & iof2es < m_p7500s2 & p7500s2 == 1
	
	gen double ypenalimento  = m_p7500s3	// iof3h*
	gen double yayudafamil  = m_p7510s1/12	// iof3h*
	gen double yremesas	  = m_p7510s2/12	// iof3h* // = remesas_ci
	
	gen double yayudainsti = m_p7510s3/12	// iof3i*
	
	gen double yintereses = m_p7510s5/12	// iof1*
	replace yintereses = iof1es if iof1 == 0 & iof1es != . & (p7510s5a1 == 98 | p7510s5 == 9)
	replace yintereses = iof1es if iof1 == 0 & iof1es != . & iof1es < m_p7510s5 
	
	gen double ycesantia  = m_p7510s6/12
	gen double yotros	  = m_p7510s7/12
	
* Variable auxiliar para complemento de transferencias de instituciones (privadas y del extranjero)
gen double aux_ytransf_ci = ytransf_ci*(-1)
egen double delta_transf = rowtotal(yayudainsti aux_ytransf_ci), mi
	
egen double ynlm_ci = rowtotal(yarriendo yjubilacion ypenalimento yayudafamil remesas_ci ytransf_ci delta_transf yintereses ycesantia yotros), mi
	
*bys idh_ch: egen ing_nl = total(ynlm_ci), mi
*egen ynlm_ci_orig = rsum(iof1 iof2  iof3h iof3i iof6 iof1es iof2es  iof3hes iof3ies iof6es), m // Programacion previo al 2020
*bys idh_ch: egen ing_nlorig = total(ynlm_ci_orig), mi
* drop m_p7500s1 m_p7500s2 m_p7500s3 m_p7510s1 m_p7510s2 m_p7510s3 m_p7510s5 m_p7510s6 m_p7510s7
	

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

***************
*** ynet_ci ***
***************
egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
drop aux_ytransf_ci


* C. INGRESOS LABORALES Y NO LABORALES A NIVEL DE HOGAR

*********
* ylm_ch *
*********
bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1, mi

**********
* ylnm_ch *
**********
bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1, mi

****************
***ytransf_ch***
****************

*** Beneficiarios a nivel hogar:
	bys idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1
	bys idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1
	bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
	
	gen byte pcasht_ch = (ptmc_ch == 1 | pnc_ch == 1 | potrot_ch == 1)
	replace pcasht_ch = . if ptmc_ch == . & pnc_ch == . & potrot_ch == .

*** Montos de transferencias a nivel hogar:
	bys idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

*** Ingreso del Hogar por transferencias no contributivas
egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi

*************
* remesas_ch *
*************
by idh_ch, sort: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, mi

*********
* ynlm_ch *
*********
bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci==1, mi

***********
* ynlnm_ch *
***********
bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1, mi
 
**********
* ytot_ch *
**********
by idh_ch, sort: egen double ytot_ch = total(ytot_ci) if miembros_ci==1, mi

***************
*** ynet_ch ***
***************
gen aux_ytransf_ch = ytransf_ch*(-1)
egen ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
drop aux_ytransf_ch


* D. SALARIO POR HORA

***************
* ylmhopri_ci *
***************
generate double ylmhopri_ci = ylmpri_ci / horaspri_ci if emp_ci==1 & horaspri_ci>0
 
**********
* ylmho_ci *
**********
generate double ylmho_ci = ylm_ci / horastot_ci if emp_ci==1 & horastot_ci>0


* E. NO RESPUESTA
  
**************
* nrylmpri_ci *
**************
generate byte nrylmpri_ci = (emp_ci==1 & ylmpri_ci==.)

**************
* nrylmpri_ch *
**************
bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci==1



		****************************
		***VARIABLES DE EDUCACION***
		****************************
			
**************
***aedu_ci***
**************	

/*

Modificado: Manuel Marcos (2026-08-19)

P3042: ¿Cuál es el mayor nivel educativo alcanzado y el último grado o semestre aprobado por …...?

1	Ninguno
2	Preescolar 
3	Básica primaria (1o - 5o)
4	Básica secundaria (6o - 9o)
5	Media académica (Bachillerato clásico)
6	Media técnica (Bachillerato técnico)
7	Normalista. NOTA: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria
8	Técnica profesional
9	Tecnológica 
10	Universitaria
11	Especialización 
12	Maestría 
13	Doctorado 
99	No sabe, no informa

p3042s1: Grado al que asiste

# NOTAS METODOLÓGICAS #
#=====================#

- La educación normalista se toma como terciaria corta (post-secundaria)

- (06/07/2026): La Ley 2481 de 2025 estableció el marco normativo de las escuelas normales superiores 
como instituciones autorizadas para la oferta de educación superior, y define expresamente que estas operan 
mediante ciclos propedéuticos en la educación superior, otorgando el título de normalista superior en el 
Programa de Formación Complementaria y el título de licenciado en el programa de formación de maestros. Es 
decir, con la normativa vigente el normalista superior ya está formalmente incorporado como parte de la 
oferta de educación superior, aunque con un régimen especial. En este sentido, hay que evaluar si se ingresa 
como superior o no ya que esto podría afectar la comparabilidad.

- La educación secundaria se compone por básica secundaria + media (todo ello 
hace el bachillerato) que tiene en total 6 años de escolaridad (4 de básica secundaria +
2 de media)
	
- p3042s1 para niveles 7-13 está en semestres, por ello se divide entre 2 para convertir a años y
	se trunca hacia abajo cuando haya decimales. Si el valor es 3.9 años, se trunca a 3 años.
	
- La educación normalista suelen durar 4 semestres. La educación técnica profesional y la tecnológica  
puede llegar a durar 6 semestres. Cuando se ven 6 semestres asociados a lo "técnico", casi siempre se trata 
del ciclo completo técnico + tecnólogo sumados: los técnicos profesionales cuentan con una duración de cuatro 
a cinco semestres, y si se continúa con la tecnología esta agrega dos semestres más, totalizando seis semestres 
para llegar al título de tecnólogo.

- La educación universitaria tiene como máximo 12 semestres en el caso de Medicina y 10 para las demás.
Considerando esto, todos los valores mayores a 12 se truncarán a 12 semestres asumiendo que corresponden a 
la carrera profesional de medicina (esto es un supuesto práctico).

- La especialización es conceptualmente diferente a maestría y doctorado. Esta suele tener duración 
de entre 2 a 4 semestres, aunque para el caso de medicina puede durar 10 semestres incluso (especializaciones 
médico-quirúrgicas). Por ello, se divide entre 2 sin modificaciones y se hacen arreglos según corresponda.
	
- Los doctorados en colombia pueden tener duración de 10 semestre (5 años) como máximo. Todos los 
valores mayores a 10 se truncarán a 10 semestres (5 años).

*/


* Truncar los semestres a años para educación superior
gen sup_año = .
replace sup_año = trunc(p3042s1/2) if inrange(p3042, 7, 13)

gen aedu_ci = .

* Missing y no precisa
replace aedu_ci = . if p3042 == 99
replace aedu_ci = . if missing(p3042)

* Primaria incompleta
replace aedu_ci = 0 if inlist(p3042, 1, 2)          /*No ha terminado ningún nivel educativo*/
replace aedu_ci = 0 if p3042 == 3 & p3042s1 == 0    /*Recién inició el nivel*/
replace aedu_ci = 1 if p3042 == 3 & p3042s1 == 1    /*Primer grado de primaria*/
replace aedu_ci = 2 if p3042 == 3 & p3042s1 == 2	/*Segundo grado de primaria*/
replace aedu_ci = 3 if p3042 == 3 & p3042s1 == 3	/*Tercer grado de primaria*/
replace aedu_ci = 4 if p3042 == 3 & p3042s1 == 4	/*Cuarto grado de primaria*/
replace aedu_ci = 5 if p3042 == 3 & p3042s1 == 5	/*Quinto grado de primaria*/
replace aedu_ci = 5 if p3042 == 4 & p3042s1 == 0	/*Quinto grado de primaria*/

* Primaria completa (p3042==4) y grados de secundaria

replace aedu_ci = 6 if p3042 == 4 & p3042s1 == 1     /*Sexto grado de secundaria*/
replace aedu_ci = 7 if p3042 == 4 & p3042s1 == 2     /*Séptimo grado de secundaria*/
replace aedu_ci = 8 if p3042 == 4 & p3042s1 == 3     /*Octavo grado de secundaria*/
replace aedu_ci = 9 if p3042 == 4 & p3042s1 == 4     /*Noveno grado de secundaria*/
replace aedu_ci = 9 if p3042 == 5 & p3042s1 == 0     /*Noveno grado de secundaria*/
replace aedu_ci = 9 if p3042 == 6 & p3042s1 == 0     /*Noveno grado de secundaria*/

* Bachillerato

replace aedu_ci = 10 if p3042 == 5 & p3042s1 == 1    /*Primero de bachillerato*/
replace aedu_ci = 11 if p3042 == 5 & p3042s1 == 2    /*Segundo de bachillerato*/
replace aedu_ci = 10 if p3042 == 6 & p3042s1 == 1    /*Primero de bachillerato*/
replace aedu_ci = 11 if p3042 == 6 & p3042s1 == 2    /*Segundo de bachillerato*/
replace aedu_ci = 11 if p3042 == 7 & sup_año == 0    /*Bachiller terminado*/
replace aedu_ci = 11 if p3042 == 8 & sup_año == 0    /*Bachiller terminado*/
replace aedu_ci = 11 if p3042 == 9 & sup_año == 0    /*Bachiller terminado*/
replace aedu_ci = 11 if p3042 == 10 & sup_año == 0   /*Bachiller terminado*/

* Educación superior (normal, técnica, tecnológica, universitaria, etc.)

replace aedu_ci = 11 + sup_año if p3042 == 7 & sup_año == 1           /*Normalista primer año*/
replace aedu_ci = 11 + 2 if p3042 == 7 & sup_año >= 2                 /*Normalista segundo año*/

replace aedu_ci = 11 + sup_año if p3042 == 8 & sup_año == 1           /*Técnica profesional primer año*/
replace aedu_ci = 11 + sup_año if p3042 == 8 & sup_año == 2           /*Técnica profesional segundo año*/
replace aedu_ci = 11 + 3 if p3042 == 8 & sup_año >= 3                 /*Técnica profesional tercer año*/

replace aedu_ci = 11 + sup_año if p3042 == 9 & sup_año == 1           /*Tecnológica primer año*/
replace aedu_ci = 11 + sup_año if p3042 == 9 & sup_año == 2           /*Tecnológica segundo año*/
replace aedu_ci = 11 + 3 if p3042 == 9 & sup_año >= 3                 /*Tecnológica tercer año*/

replace aedu_ci = 11 + sup_año if p3042 == 10 & inrange(sup_año, 1, 5)    /*Universitario de 1 a 5 años*/
replace aedu_ci = 11 + 5 if p3042 == 10 & sup_año > 5                     /*Universitario 5 años*/

replace aedu_ci = 16 if p3042 == 11                                       /*Si hizo especializaciones se asume que tiene universitario 5 años*/
replace aedu_ci = 16 if p3042 == 12 & sup_año == 0                        /*Universitario 5 años*/
replace aedu_ci = 16 + sup_año if p3042 == 12 & sup_año == 1              /*Maestría 1 año*/
replace aedu_ci = 16 + 2 if p3042 == 12 & sup_año >= 2                    /*Maestría 2 años*/

replace aedu_ci = 18 if p3042 == 13 & sup_año == 0                        /*Maestría 2 años*/
replace aedu_ci = 18 + sup_año if p3042 == 13 & inrange(sup_año, 1, 2)    /*Doctorado 1 a 3 años*/
replace aedu_ci = 18 + 3 if p3042 == 13 & sup_año >= 3                    /*Doctorado 3 años*/

***************
***edupre_ci***
***************

gen edupre_ci = .

**************
***eduui_ci***
**************

gen eduui_ci = 0
replace eduui_ci = . if p3042 == 99
replace eduui_ci = . if missing(p3042)
replace eduui_ci = 1 if p3042 == 7 & sup_año == 1
replace eduui_ci = 1 if p3042 == 8 & sup_año == 1
replace eduui_ci = 1 if p3042 == 8 & sup_año == 2
replace eduui_ci = 1 if p3042 == 9 & sup_año == 1
replace eduui_ci = 1 if p3042 == 9 & sup_año == 2
replace eduui_ci = 1 if p3042 == 10 & inrange(sup_año, 1, 4)

***************
***eduuc_ci***
***************

gen eduuc_ci = 0
replace eduuc_ci = . if p3042 == 99
replace eduuc_ci = . if missing(p3042)
replace eduuc_ci = 1 if p3042 == 7 & sup_año == 1
replace eduuc_ci = 1 if p3042 == 7 & sup_año >= 2
replace eduuc_ci = 1 if p3042 == 8 & sup_año == 1
replace eduuc_ci = 1 if p3042 == 8 & sup_año == 2
replace eduuc_ci = 1 if p3042 == 8 & sup_año >= 3
replace eduuc_ci = 1 if p3042 == 9 & sup_año == 1
replace eduuc_ci = 1 if p3042 == 9 & sup_año == 2
replace eduuc_ci = 1 if p3042 == 9 & sup_año >= 3
replace eduuc_ci = 1 if p3042 == 10 & inrange(sup_año, 1, 5)
replace eduuc_ci = 1 if p3042 == 10 & sup_año > 5
replace eduuc_ci = 1 if p3042 == 11
replace eduuc_ci = 1 if p3042 == 12 & sup_año == 0
replace eduuc_ci = 1 if p3042 == 12 & sup_año == 1
replace eduuc_ci = 1 if p3042 == 12 & sup_año >= 2
replace eduuc_ci = 1 if p3042 == 13 & sup_año == 0
replace eduuc_ci = 1 if p3042 == 13 & inrange(sup_año, 1, 2)
replace eduuc_ci = 1 if p3042 == 13 & sup_año >= 3

**************
***eduac_ci***
**************

gen eduac_ci = 0
replace eduac_ci = . if p3042 == 99
replace eduac_ci = . if missing(p3042)
replace eduac_ci = 1 if p3042 == 10 & inrange(sup_año, 1, 5)
replace eduac_ci = 1 if p3042 == 10 & sup_año > 5
replace eduac_ci = 1 if p3042 == 11
replace eduac_ci = 1 if p3042 == 12 & sup_año == 0
replace eduac_ci = 1 if p3042 == 12 & sup_año == 1
replace eduac_ci = 1 if p3042 == 12 & sup_año >= 2
replace eduac_ci = 1 if p3042 == 13 & sup_año == 0
replace eduac_ci = 1 if p3042 == 13 & inrange(sup_año, 1, 2)
replace eduac_ci = 1 if p3042 == 13 & sup_año >= 3

***************
***asiste_ci***
***************

gen asiste_ci = .
replace asiste_ci = 1 if p6170 == 1
replace asiste_ci = 0 if p6170 == 2

***************
***edupub_ci***
***************

/*
p6170: ¿Actualmente asiste a alguna institución educativa (por ejemplo: jardín, escuela, colegio, universidad)?		
p3041: La institución a la que asiste es: 1. Pública o 2. privada	
*/

gen edupub_ci = .
replace edupub_ci = 1 if p6170 == 1 & p3041 == 1
replace edupub_ci = 0 if p6170 == 1 & p3041 == 2
	
***************
***asispre_ci**
***************

gen asispre_ci = 0
replace asispre_ci = 1 if p6170 == 1 & p3042 == 1
		
**************
*razonesnoasis_ci*
**************

* No cuenta con preguntas para esta variable

g razonesnoasis_ci = .



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
*g telef_ch = p5210s1 == 1
*replace telef_ch = . if p5210s1 == .
	
***************
***refrig_ch***
***************
g refrig_ch =.
*g refrig_ch = p5210s5 == 1
*replace refrig_ch = . if p5210s5 == .
	
**************
***freez_ch***
**************
g freez_ch = .
	
*************
***auto_ch***
*************
g auto_ch =.
*g auto_ch = p5210s22 == 1
*replace auto_ch = . if p5210s22 == .
	
**************
***compu_ch***
**************
g compu_ch =.
*g compu_ch = p5210s16 == 1
*replace compu_ch = . if p5210s16 == .
	
*****************
***internet_ch***
*****************
g internet_ch =.
*g internet_ch = p5210s3 == 1
*replace internet_ch = . if p5210s3 == . 
	
************
***cel_ch***
************
g cel_ch =.
*g cel_ch = 0
*replace cel_ch = p5220==1
*replace cel_ch = . if p5220 == .
	

**************
***vivi1_ch***
**************
g vivi1_ch = 1     	 if p4000 == 1
replace vivi1_ch = 2 if p4000 == 2
replace vivi1_ch = 3 if p4000 == 3 | p4000 == 4 | p4000 == 5 | p4000 == 6
replace vivi1_ch = . if p4000 == .
	
**************
***vivi2_ch***
**************
g vivi2_ch = (p4000 == 1 | p4000 == 2)
replace vivi2_ch = . if p4000 == .
	

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
*replace aguadisp1_ch = 1 if p4040==1
*replace aguadisp1_ch = 0 if p4040==2


**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9

*************
*aguamala_ch*  Altered
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7

*****************
***aguamide_ch***
*****************
generate aguamide_ch = .

*****************
****bano_ch******  Altered
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
*banomejorado_ch*  Altered
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


	

		****************************
		***VARIABLES DE EXTERNAS***
		****************************	
	
****************
*tipo_bienestar*
****************	
gen byte tipo_bienestar = .
replace tipo_bienestar  = 1

****************
* pobre_ine _ci*
****************	
gen byte pobre_ine_ci= pobre

**********************
*bienestar_agregado***
**********************	
gen bienestar_agregado = . 
replace bienestar_agregado = ingpcug

****************
*****lpe_ci ****
****************	
gen lpe_ci = . 
replace lpe_ci = li
	
****************
******ln_ci*****
****************	
gen ln_ci = .
replace ln_ci = lp


		
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
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch COL_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  lp19_2011 lp31_2011 lp5_2011 lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded


compress

saveold "`base_out'", version(12) replace

log close


