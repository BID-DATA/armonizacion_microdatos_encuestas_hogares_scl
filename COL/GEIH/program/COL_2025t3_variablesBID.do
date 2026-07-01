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
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)


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
	g byte rama_ci = .
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
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

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
	egen double ylmpri_ci = rsum(impa impaes) if emp_ci==1, m
	replace ylmpri_ci = . if impa==. & impaes==.

	************
	* ylmsec_ci *
	************
	egen double ylmsec_ci = rsum(isa isaes) if emp_ci==1, m
	replace ylmsec_ci=. if isa==. & isaes==.

	**************
	* ylmotros_ci *
	**************
	egen double ylmotros_ci= rsum(imdi imdies), m
	* REVISAR PORQUE SI LO LIMITO A emp_ci==1 SE GENERA TODO COMO MISSING

	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	egen double ylnmpri_ci = rsum(ie iees) if emp_ci==1, m
	replace ylnmpri_ci=. if ie==. & iees==.
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
	g double ylnmsec_ci = . /*No se pregunta ingreso por especies para act secundaria */

	****************
	* ylnmotros_ci *
	****************
	g double ylnmotros_ci = .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	egen double ynlm_ci = rsum(iof1 iof2  iof3h iof3i iof6 iof1es iof2es  iof3hes iof3ies iof6es), m
	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	g double ynlnm_ci = .

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
	egen double ypen_ci = rsum(iof2 iof2es), m

	*************
	* ypensub_ci *
	*************
	egen double ypensub_ci = rsum(iof2 iof2es) if pensionsub_ci==1, m


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
	g byte edupub_ci =.
	replace edupub_ci = 1 if p3041 == 1 & p6170==1
	replace edupub_ci = 0 if p3041 == 2 & p6170==1

	**************
	*razonesnoasis_ci*
	**************
	g byte razonesnoasis_ci = .

	***************
	***asispre_ci**
	***************
	g byte asispre_ci= (p6170==1 & p3042==2 & p3042s1 <2)


	****************************
	***VARIABLES DE VIVIENDA***
	****************************

	***********
	*luz_ch*
	***********
	g byte luz_ch = p4030s1 == 1
	replace luz_ch=. if p4030s1==.

	***********
	*luzmide_ch*
	***********
	g byte luzmide_ch = .

	************
	*combust_ch*
	************
	g byte combust_ch = (p5080 == 1 | p5080 == 3 | p5080 == 4)
	replace combust_ch =. if p5080==.

	**********
	*piso_ch*
	**********
	g byte piso_ch = (p4020 != 1 & p4020 != .)
	replace piso_ch = . if p4020 ==.

	***********
	*pared_ch*
	***********
	g byte pared_ch = (p4010 >= 1 & p4010 <= 3)
	replace pared_ch = . if p4010 == .

	***********
	*techo_ch*
	***********
	g byte techo_ch = .

	**********
	*resid_ch*
	**********
	g byte resid_ch = 0		 if p5040 == 1
	replace resid_ch = 1 if p5040 == 4
	replace resid_ch = 2 if p5040 == 2 | p5040 == 3
	replace resid_ch = 3 if p5040 == 5
	replace resid_ch = . if p5040 == .

	*************
	***dorm_ch***
	*************
	g byte dorm_ch = p5010

	****************
	***cuartos_ch***
	****************
	g byte cuartos_ch = p5000

	***************
	***cocina_ch***
	***************
	g byte cocina_ch = 0 if p5070 >= 2 & p5070 <= 6
	replace cocina_ch = 1 if p5070 == 1

	**************
	***telef_ch***
	**************
	g byte telef_ch =.

	***************
	***refrig_ch***
	***************
	g byte refrig_ch =.

	**************
	***freez_ch***
	**************
	g byte freez_ch = .

	*************
	***auto_ch***
	*************
	g byte auto_ch =.

	**************
	***compu_ch***
	**************
	g byte compu_ch =.

	*****************
	***internet_ch***
	*****************
	g byte internet_ch =.

	************
	***cel_ch***
	************
	g byte cel_ch =.


	**************
	***vivi1_ch***
	**************
	* Cambio en 2025 P4005 es el tipo de la vivienda
	g byte vivi1_ch = 1     	 if p4005 == 1
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
	g byte viviprop_ch = 0 if p5090 == 3
	replace viviprop_ch = 1 if p5090 == 1
	replace viviprop_ch = 2 if p5090 == 2
	replace viviprop_ch = 3 if p5090 == 4 | p5090 == 5 | p5090 == 6
	replace viviprop_ch = . if p5090 == .

	****************
	***vivitit_ch***
	****************
	g byte  vivitit_ch = .

	****************
	***vivialq_ch***
	****************
	g double vivialq_ch = p5140 if p5140 >= 10000

	*******************
	***vivialqimp_ch***
	*******************
	g double vivialqimp_ch = p5130 if p5130 >= 10000


	***********************
	***VARIABLES DE WASH***
	***********************

	****************
	***aguared_ch***
	****************
	generate byte aguared_ch =.
	replace aguared_ch = 1 if p4030s5==1
	replace aguared_ch = 0 if p4030s5==2

	*****************
	*aguafconsumo_ch*
	*****************
	gen byte aguafconsumo_ch = 0
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
	gen byte aguafuente_ch =.
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
	gen byte aguadist_ch=.
	replace aguadist_ch=1 if (p5050==1 | p5050==2)
	replace aguadist_ch=0 if p5050>2

	**************
	*aguadisp1_ch*
	**************
	gen byte aguadisp1_ch =.

	**************
	*aguadisp2_ch*
	**************
	gen byte aguadisp2_ch = 9

	*************
	*aguatrat_ch*
	*************
	ge byte aguatrat_ch = 9

	*************
	*aguamala_ch*
	*************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

	*****************
	*aguamejorada_ch*
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7

	*****************
	***aguamide_ch***
	*****************
	generate byte aguamide_ch = .

	*****************
	****bano_ch******
	*****************
	gen byte bano_ch=.
	replace bano_ch=0 if p5020==6
	replace bano_ch=1 if p5020==1
	replace bano_ch=2 if p5020==2
	replace bano_ch=4 if p5020==5
	replace bano_ch=6 if p5020==3 | p5020 ==4
	replace bano_ch=6 if bano_ch ==. & jefe_ci==1


	***************
	***banoex_ch***
	***************
	generate byte banoex_ch=.
	replace banoex_ch = 1 if p5030==1
	replace banoex_ch = 0 if p5030==2

	*****************
	*banomejorado_ch*
	*****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

	************
	*sinbano_ch*
	************
	gen byte sinbano_ch = 3
	replace sinbano_ch = 0 if p5020<6





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
	gen byte tipo_bienestar = 1


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
