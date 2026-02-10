*(Versión stata 17)

clear
set more off

*________________________________________________________________________________________________________________*

* Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
* utilizar un loop)
* Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
* Se tiene acceso al servidor unicamente al interior del BID.
* El servidor contiene las bases de datos MECOVI.
*________________________________________________________________________________________________________________*
 
global ruta = "${surveysFolder}"

local PAIS HND
local ENCUESTA EPHPM
local ANO "2025"
local ronda m6 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: HND
Encuesta: EPHPM
Round: m6
Autores: Lina Arias
Versión ...:
Nombre de autor (SCL/SCL) - Email: linarias8@hotmail.com, Fecha: 08/02/2025

****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=1


	********************
	*** region_c ****
	********************
	gen byte region_c = DEPTO
	label define region_c ///
			   1 "Atlantida" ///
			   2 "Colon" ///
			   3 "Comayagua" ///
			   4 "Copan" ///
			   5 "Cortes" ///
			   6 "Choluteca" ///
			   7 "El Paraiso" ///
			   8 "Francisco Morazan" ///
			  10 "Intibuca" ///
			  12 "La paz" ///
			  13 "Lempira" ///
			  14 "Ocotepeque" ///
			  15 "Olancho" ///
			  16 "Santa Barbara " ///
			  17 "Valle" ///
			  18 "Yoro"
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="HND"

	******
	*anio*
	******
	gen int anio_c=2025
	
	******
	*mes_c*
	******
	gen int mes_c=7

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=1 if DOMINIO==1 | DOMINIO==2 | DOMINIO==3 | DOMINIO==4 // Urbana
	replace zona_c=0 if DOMINIO==5 // Rural
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=DOMINIO
	
	******************
	*idh_ch (idhogar)*
	******************
	gen idh_ch=HOGAR
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen idp_ci = NPER
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=FACTOR
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=FACTOR
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if SEXO==1
	replace sexo_ci = 2 if sexo==2

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=EDAD if EDAD!=.
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci=1 if RELA_J==1 // Jefe del Hogar
	replace relacion_ci=2 if RELA_J==2 // Cónyugue/Pareja
	replace relacion_ci=3 if RELA_J==3 | RELA_J==4 // Hijo/a y Hijastro/a
	replace relacion_ci=4 if RELA_J>=5 & RELA_J<=8 // Otros parientes
	replace relacion_ci=5 if RELA_J==9 // No parientes
	replace relacion_ci=6 if RELA_J==10 // Empleado/a
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=miembros_ci // No hay variable directa - usamos RELA_J
	
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if CIVIL==5 // Soltero
	replace civil_ci=2 if CIVIL==1 | CIVIL==6 // Unión formal
	replace civil_ci=3 if CIVIL==3 | CIVIL==4 // Divorciado/Separado
	replace civil_ci=4 if CIVIL==2 // Viudo
		
	*********
	*jefe_ci*
	*********
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
		
	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	
	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.

	
	**************
	*notropari_ch*
	**************
   by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5)
   replace notronopari_ch=. if relacion_ci==.          

	
		
	****************
	*nempdom_ch*
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.
 
		
	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch=0
	**** unipersonal
	replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (child with or without spouse but without other relatives)
	replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (spouse with or without children but without other relatives)
	replace clasehog_ch=2 if nhijos_ch==0 & nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** ampliado
	replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
	**** compuesto (some relatives plus non relative)
	replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	**** corresidente
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***

*******************************************************
	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	
	
	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.   // se queda como missing (.) si no existe la pregunta	

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	
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
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if CONDACT==1
	replace condocup_ci = 2 if CONDACT==2
	replace condocup_ci = 3 if CONDACT==3 & TIPINAC==3 //Inactivos
	replace condocup_ci = 4 if edad_ci<5 //Según la encuesta, las preguntas sobre ocupación se hacen a personas de 5 años en adelante

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
    replace categoinac_ci = 1 if (inlist(CA514,1,2) & condocup_ci == 3) //Jubilado o Pensionado
	replace categoinac_ci = 2 if  (CA514 == 4 & condocup_ci == 3) //Estudiante
	replace categoinac_ci = 3 if  (CA514 == 5 & condocup_ci == 3) //Quehaceres domesticos
	replace categoinac_ci = 4 if  (!inlist(CA514,1,2,4,5) & condocup_ci == 3) //Otros Inactivos

	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if CA517 == 1 & condocup_ci == 2 //Ha trabajado antes (CA517==1) y ahora está desocupado (condocup_ci==2) 
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci ==2 

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if TOTHRSOP<30 & CA522==1 & CA523==1 & condocup_ci==1

	****************
	***durades_ci***
	****************
	gen byte durades_ci=round(CA516TIEMPO) if CA516DSM==3 & CA516DSM!=. & CA516TIEMPO!=.
	replace durades_ci=round(CA516TIEMPO*(52/12)) if CA516DSM==2 & CA516DSM!=. & CA516TIEMPO!=.
	replace durades_ci=round(CA516TIEMPO/30) if CA516DSM==1 & CA516DSM!=. & CA516TIEMPO!=.

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)
		
	****************
	*** nempleos_ci***
	****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if CA519==1
	replace nempleos_ci = 2 if CA519==2
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .
	*replace antiguedad_ci = 1 if ...
	*replace antiguedad_ci = ... if emp_ci == 1
	
	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .
	replace desalent_ci = 1 if CA513==6 & condocup_ci==3 
	replace desalent_ci=0 if CA513!=6 & condocup_ci==3 

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = TOTHRSOP
	replace horaspri_ci = . if emp_ci == 0
	
	***************
	***horastot_ci ***
	***************	
	egen  byte horastot_ci  = rsum(OC_605_LUNES OC_605_MARTES OC_605_MIERCOLES OC_605_JUEVES OC_605_VIERNES OC_605_SABADO OC_605_DOMINGO ///
	OC_605_LUNES1 OC_605_MARTES1 OC_605_MIERCOLES1 OC_605_JUEVES1 OC_605_VIERNES1 OC_605_SABADO1 OC_605_DOMINGO1), mi
	replace horastot_ci  = . if emp_ci == 0 
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = (horaspri_ci<=30 & CA522==2) if condocup_ci==1  
	replace tiempoparc_ci  = . if emp_ci==0
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if ...
	replace categopri_ci  = 1 if inlist(OC609,6) & condocup_ci==1
	replace categopri_ci  =	2 if inlist(OC609,7) & condocup_ci==1
	replace categopri_ci  =	3 if inlist(OC609,1,2,3,4,5,9,10,11) & condocup_ci==1
	replace categopri_ci  =	4 if inlist(OC609,8) & condocup_ci==1
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	*replace categosec_ci  = 0 if ...
	replace categosec_ci  = 1 if inlist(OC6091,6) & condocup_ci==1
	replace categosec_ci  = 2 if inlist(OC6091,7) & condocup_ci==1
	replace categosec_ci  = 3 if inlist(OC6091,1,2,3,4,5,9,10,11) & condocup_ci==1
	replace categosec_ci  = 4 if inlist(OC6091,8) & condocup_ci==1	

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	replace  rama_ci  = 1 if RAMAOP==1 & emp_ci==1 
	replace  rama_ci=2 if RAMAOP==2 & emp_ci==1 
	replace  rama_ci=3 if RAMAOP==3 & emp_ci==1
	replace  rama_ci=4 if RAMAOP==4 | RAMAOP==5  & emp_ci==1
	replace  rama_ci=5 if RAMAOP==6  & emp_ci==1
	replace  rama_ci=6 if RAMAOP==7 | RAMAOP==9  & emp_ci==1
	replace  rama_ci=7 if RAMAOP==8 | RAMAOP==10 & emp_ci==1
	replace  rama_ci=8 if inrange(RAMAOP,11,14)  & emp_ci==1
	replace  rama_ci=9 if inrange(RAMAOP,15,21)  & emp_ci==1

	
	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 1 if inlist(OC609,1,4,9) & emp_ci==1
	replace spublico_ci=0 if inlist(OC609,2,3,5,6,7,8,10,11) & emp_ci==1
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	replace tamemp_ci  = 1 if (OC_608_CUANTAS>=1 & OC_608_CUANTAS<=5) & emp_ci==1 
	replace tamemp_ci = 2 if (OC_608_CUANTAS>=6 & OC_608_CUANTAS<=50) & emp_ci==1 
	replace tamemp_ci = 3 if (OC_608_CUANTAS>50) & OC_608_CUANTAS!=. & emp_ci==1 
	replace tamemp_ci=. if  OC_608_CUANTAS>=99999 
	
	
	***************
	***cotizando_ci***
	***************	
	gen  byte cotizando_ci = .
	*replace cotizando_ci  = 0 if ...
	*replace cotizando_ci  = 1 if ...
	
	
	***************
	***afiliado_ci***
	***************	
	gen  byte afiliado_ci = .
	*replace afiliado_ci  = 0 if ...
	*replace afiliado_ci  = 1 if ...	
	
	***************
	***instcot_ci***
	***************	
	gen byte instcot_ci=. if cotizando_ci == 1
	
	**************
	***formal_ci***
	**************
	gen byte formal_ci = .
	replace formal_ci  =  1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)
	
	*******************
	***tipocontrato_ci***
	*******************
	gen byte tipocontrato_ci = .
	*replace tipocontrato_ci = 1 if … & categopri_ci == 3
	*replace tipocontrato_ci = 2 if … & categopri_ci == 3
	*replace tipocontrato_ci = 3 if … & categopri_ci == 3
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci=.
	replace ocupa_ci=1 if OCUPAOP==2 & emp_ci==1
	replace ocupa_ci=2 if OCUPAOP==1 & emp_ci==1
	replace ocupa_ci=3 if (OCUPAOP==3 | OCUPAOP==4) & emp_ci==1
	replace ocupa_ci=4 if OCUPAOP==5 & emp_ci==1
	replace ocupa_ci=5 if OCUPAOP==7 & emp_ci==1
	replace ocupa_ci=6 if OCUPAOP==6 & emp_ci==1
	replace ocupa_ci=7 if OCUPAOP==8 & emp_ci==1
	replace ocupa_ci=8 if OCUPAOP==10 & emp_ci==1
	replace ocupa_ci=9 if OCUPAOP==9 & emp_ci==1

	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	*replace pension_ci=1 if …
	*replace pension_ci=0 if …
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
	*replace pensionsub_ci = 1 if …
	*replace pensionsub_ci = 0 if …
	
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
	generate double ylmpri_ci =ytraop if emp_ci==1

	************
	* ylmsec_ci *
	************
	generate double ylmsec_ci = ytraos if emp_ci==1

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci =. if emp_ci==1
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	gen double ylnmpri_ci =.

	**************
	* ylnmsec_ci *
	**************
    gen double ylnmsec_ci = .

	****************
	* ylnmotros_ci *
	****************
    gen double ylnmotros_ci = .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	egen double ynlm_ci = rowtotal(yotrf), mi
	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci = .

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
    egen double ynlm_ch = rowtotal(yotrfhg), mi
 
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
    generate double remesas_ci = .

	*************
	* remesas_ch *
	*************
    generate double remesas_ch = yhReme


	**********
	* ypen_ci *
	**********
	generate double ypen_ci = . if pension_ci==1

	
	*************
	* ypensub_ci *
	*************
	generate double ypensub_ci = . if pensionsub_ci==1
		
****************************
***VARIABLES DE EDUCACION***
****************************

	*********	
	*aedu_ci*
	*********
	gen aedu_ci=.
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron
	replace aedu_ci=0 if (ED05>=1 & ED05<=3) // Hasta educación pre-básica
	replace aedu_ci=ED08 if ED05==4  & ED08<99 // Educación básica
	replace aedu_ci=9+ED08 if ED05==5 & ED08<99 //9 años de basica - ciclo comun
	replace aedu_ci=9+ED08 if ED05==6 & ED08<99 //9 años de basica - ciclo div
	replace aedu_ci=11+ED08 if (ED05==7 |ED05==8 |ED05==9) & ED08<99 // Terciario 
	replace aedu_ci=15+ED08 if (ED05==10) & ED08<99 //Post

	*Este grupo de variables es para quienes "sí siguen educando	actualmente"
	replace aedu_ci=0 if (ED10>=1 & ED10<=3) // Hasta educación pre-básica
	replace aedu_ci=ED13 - 1 if ED10==4 & ED13<99 // Educación básica
	replace aedu_ci=9+ED13 - 1 if ED10==5 //9 años de basica - ciclo comun
	replace aedu_ci=9+ED13 - 1 if ED10==6 //9 años de basica- ciclo div
	replace aedu_ci=11+ED13 - 1 if (ED10==7 | ED10==8 | ED10==9) //Terciario
	replace aedu_ci=15+ED13 - 1 if (ED10==10) & ED13<99 //Post

			

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci =0
	replace eduui_ci= 1 if (ED07==2 & inrange(ED05,7,9)) // no finalizó estudios
	replace eduui_ci=1 if inrange(ED10,7,9) 

	replace eduui_ci = . if aedu_ci == . 

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = (ED07==1 & inrange(ED05,6,8)) 
	replace eduuc_ci=1 if inrange(ED05,9,11) 
	replace eduuc_ci=1 if inrange(ED10,9,10)  & eduuc_ci==0
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci = 1 if eduui_ci+eduuc_ci==1
	replace eduac_ci= 0 if eduui_ci+eduuc_ci==0
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.


	************
	*asispre_ci*
	************
	g asispre_ci=.
	replace asispre_ci = 1 if ED10==3
	*replace asispre_ci = 0 if ED03==0

	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci=0 if ED03==1
	replace asiste_ci=1 if ED03==2


	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if inlist(ED04,8, 13)
	replace pqnoasis1_ci =  2 if inlist(ED04,3)
	replace pqnoasis1_ci =  3 if  inlist(ED04,4, 12, 6)
	replace pqnoasis1_ci =  4 if inlist(ED04,5)
	replace pqnoasis1_ci =  5 if inlist(ED04,1,	2, 7, 9, 10, 11,12,14,15)
	

	***********
	*edupub_ci*
	***********
	gen edupub_ci =.
	replace edupub_ci = 1 if inlist(ED14,1,2,3,10) & asiste_ci==1
	replace edupub_ci=  0 if inlist(ED14,4,5,6,7,9) & asiste_ci==1
		

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=1 if V07<5 & V07!=.	
	replace luz_ch=0 if V07>4 & V07!=.	
	
	
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if inlist(H04,1,5)
	replace combust_ch=1 if inlist(H04,2,3,4) 
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen piso_ch=.	
	
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*resid_ch*
	***********
	gen resid_ch=.
	replace resid_ch=0 if V08<4
	replace resid_ch=1 if V08==4 | V08==6		
	replace resid_ch=2 if V08==7	
	replace resid_ch=3 if V08==8	
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.
	replace dorm_ch=H09 if H09!=.
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=.
	
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
	replace cocina_ch=0 if H03==2	
	replace cocina_ch=1 if H03==1	
	
	***********
	*telef_ch*
	***********
	gen telef_ch=.
	replace telef_ch=0 if H01_7==0	
	replace telef_ch=1 if (H01_7>=1 & H01_7!=.) 	
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	replace refrig_ch=0 if H01_1==0
	replace refrig_ch=1 if (H01_1>=1 & H01_1!=.)
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	
	***********
	*auto_ch*
	***********
	gen auto_ch=.
	replace auto_ch=0 if H01_8==0
	replace auto_ch=1 if  (H01_8>=1 & H01_8!=.)
	
	***********
	*compu_ch*
	***********
	gen compu_ch=.
	replace compu_ch=0 if  H01_11==0
	replace compu_ch=1 if (H01_11>=1 & H01_11!=.)
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=0 if TIC03==0
	replace internet_ch=1 if (TIC03==1 & AT05_1==1) 
	
	***********
	*cel_ch
	***********
	gen cel_ch=(TIC09==1)
	replace cel_ch=. if TIC09==.
	
	***********
	*vivi1_ch*
	***********
	gen vivi1_ch=.
	replace vivi1_ch=1 if inlist(V01,1,3) // Casa individual, rancho o improvisada
	replace vivi1_ch=2 if inlist(V01,4) // Apartamento / Departamento
	replace vivi1_ch=3 if inlist(V01,5,7) // Otros
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch=0 if V10==1 // Alquilada
	replace viviprop_ch=1 if V10==3 // Propia y totalmente pagada
	replace viviprop_ch=2 if V10==2 // Propia y pagandola
	replace viviprop_ch=3 if inlist(V10,4,5,6,7) // Ocupada
	replace viviprop_ch=. if V10==.	
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.

	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=.

	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=.
	replace vivialqimp_ch=V11 if V11<99999
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.
	replace aguared_ch = 1 if V05==1
	replace aguared_ch = 0 if V05>1

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =.
	replace aguafconsumo_ch = 0 

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if V05==1
	replace aguafuente_ch = 2 if V05==4  & V06>2
	*replace aguafuente_ch = 3 if …
	*replace aguafuente_ch = 4 if …
	*replace aguafuente_ch = 5 if 
	replace aguafuente_ch = 6 if V05==6 | V05==7
	replace aguafuente_ch = 7 if V05==8
	replace aguafuente_ch = 8 if V05==5
	replace aguafuente_ch = 9 if  V05==9
	replace aguafuente_ch = 10 if V05==3 | V05==2
	

	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if V06==1 
	replace aguadist_ch= 2 if V06==2 
	replace aguadist_ch= 3 if V06==3 & V06==4 
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =.
	replace aguadisp1_ch = 9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =.
	replace aguadisp2_ch = 9
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.

	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.

	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7
	
	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .

	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
	replace bano_ch = 0 if inlist(H06,9) 
 	replace bano_ch=1 if inlist(H07,1)
	replace bano_ch=2 if inlist(H07,2) 
	replace bano_ch=3 if inlist(H07,5, 6,7) 
	replace bano_ch=4 if inlist(H07,3) 
	replace bano_ch=5 if inlist(H07,4) 
	replace bano_ch=6 if inlist(H07,8) 
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	replace banoex_ch =  1 if H08==1
	replace banoex_ch = 0 if H08==2
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if bano_ch>0
	replace sinbano_ch = 3 if bano_ch==0
		
	******************
    ** banomejorado_ch ** - 
    *****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci= .

	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.


	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = .


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
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if Pobreza==3
	replace pobre_ine_ci= 1 if Pobreza<3

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = yperhg

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci =.
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = .
	

	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
