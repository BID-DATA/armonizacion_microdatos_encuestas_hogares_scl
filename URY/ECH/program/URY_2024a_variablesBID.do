*(Versión stata 17)

**# Bookmark #1
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

local PAIS URY
local ENCUESTA ECH
local ANO "2024"
local ronda a  


local log_file = "$ruta\\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\\harmonized\\`PAIS'\\`ENCUESTA'\\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: URY
Encuesta: ECH
Round: a
Autores: Lina Maria Arias (SCL/SCL) - Email: linarias8@gmail.com, 22 de sep de 2025
Versión ...: v1
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

*Replacing NAs
ds, has(type string)
foreach v in `r(varlist)' {
	replace `v' = "" if `v' == "NA"
	}

	********************
	*** region_BID_c ****
	********************
	gen region_BID_c=.
	replace region_BID_c = 4 
	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c


	********************
	*** region_BID_c ****
	********************
	gen ine01 = dpto
	gen region_c = dpto
	label define region_c  1 "Montevideo" ///
           2 "Artigas" /// 
           3 "Canelones" /// 
           4 "Cerro Largo" /// 
           5 "Colonia" /// 
           6 "Durazno" /// 
           7 "Flores" /// 
           8 "Florida" /// 
           9 "Lavalleja" /// 
          10 "Maldonado" /// 
          11 "Paysandú" /// 
          12 "Río Negro" /// 
          13 "Rivera" /// 
          14 "Rocha" /// 
          15 "Salto" /// 
          16 "San José" /// 
          17 "Soriano" /// 
          18 "Tacuarembó" ///
          19 "Treinta y Tres" 
label value region_c region_c

	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="URY"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=mes	

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=.
	replace zona_c=1 if (region_4 == 1 | region_4 == 2)
	replace zona_c=0 if (region_4 == 3 | region_4 == 4)
	label variable zona_c "Zona del pais"
	label define zona_c 1 "Urbana" 0 "Rural"
	label value zona_c zona_c
	
	*********
	*estrato*
	*********
	gen estrato_ci=estred13
	label define estrato 1 "Montevideo - Nivel económico bajo" ///
	2 "Montevideo - Nivel económico medio - bajo" ///
	3 "Montevideo - Nivel económico medio" ///
	4 "Montevideo - Nivel económico medio - alto" ///
	5 "Montevideo - Nivel económico alto" ///
	6 "Zona metropolitana" ///
	7 "Interior Norte (Artigas, Rivera, Cerro Largo, Treinta y Tres)" ///
	8 "Costa Este (Canelones, Maldonado, Rocha)" ///
	9 "Litoral Norte (Salto, Paysandú, Río Negro)" ///
	10 "Litoral Sur (Soriano, Colonia, San José)" ///
	11 "Centro Norte (Tacuarembó, Durazno)" ///
	12 "Centro Sur (Flores, Florida, Lavalleja)" 
	label value estrato_ci estrato
	
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	tostring id , gen(idh_ch)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(idh_ch nper)
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=w_ano
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=w_ano 
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=e26
	label var sexo_ci "Sexo del Individuo"
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci


	*********
	*edad_ci*
	*********
	gen int edad_ci=e27
	
	**************
	**relacion_ci**
	**************
	gen relacion_ci =.
	replace relacion_ci = 1 if (e30 == 1)
	replace relacion_ci = 2 if (e30 == 2)
	replace relacion_ci = 3 if (e30 >= 3 & e30 <= 5)
	replace relacion_ci = 4 if (e30 >= 6 & e30 <= 12)
	replace relacion_ci = 5 if (e30 == 13)
	replace relacion_ci = 6 if (e30 == 14)
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if (e36 == 5 & e33 ==2) 
	replace civil_ci = 2 if (e33 == 1)
	replace civil_ci = 2 if (e36 == 3 & e33 ==2) 
	replace civil_ci = 3 if (e36 == 1 & e33 ==2) | (e36 == 2 & e33 ==2) 
	replace civil_ci = 4 if (e36 == 4 & e33 ==2) | (e36 == 6 & e33 ==2)
		
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

		
	****************
	*notronopari_ch*
	****************
	
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	label variable notronopari_ch "Numero de no familiares"


	****************
	***nempdom_ch***
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.
         

		
	************
	*nempdom_ch*
	************

	gen empldom_ci=0
	replace empldom_ci=1 if e30==14
		  
		
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

	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***

*******************************************************
	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	replace afro_ci = 1 if e29_1 == 1 
	replace afro_ci = 0 if e29_1 == 2
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 	
	replace ind_ci = 1 if e29_4 == 1 
	replace ind_ci = 0 if e29_4 == 2 // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci =1 if (afro_ci==0 & ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
	replace noafroind_ci =. if (afro_ci==. | ind_ci==.) //Esto solo en el caso que se tenga ambas opciones no disponibles. 

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
	gen byte ARG_dis_ci = .
	

	
****************************
***VARIABLES DE EDUCACION***
****************************


	*********	
	*aedu_ci*
	*********

	// Reemplazar 9 con 0 - es inicio de ese año escolar 
	foreach v of varlist e51_2 e51_4_a e51_4_b e51_5 e51_6 e51_8 e51_9 e51_10 e51_11 {
		replace `v' = 0 if `v' == 9
	}	

	replace e51_2=0 if e51_2==12

	** Se generan años aprobados para los niveles ** 	
	egen mb_añostc = rowmax(e51_4_a e51_4_b) /*computa el maximo de Media Básica Liceo o tecnico (CETP-UTU)*/	
	egen ms_añostc = rowmax(e51_5 e51_6) /*computa el maximo de Media Superior Liceo o tecnico (CETP-UTU)*/		
	egen sup_años = rowmax(e51_8 e51_9 e51_10) /*computa el maximo de superior: magisterio, universitario o terciario no universitario */

	gen años_prim = e51_2
	gen años_cb_mb = mb_añostc
	gen años_cb_ms = ms_añostc
	gen años_sup = sup_años
	gen años_post = e51_11

	foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
		destring `v', replace force
	}

	gen aedu_ci = 0
	qui foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
		replace aedu_ci = aedu_ci + `v' if !missing(`v')
	}

	replace aedu_ci =. if (años_prim==. & años_cb_mb==. & años_cb_ms==. & años_sup==. & años_post==.)

	** eliminamos variables temporales
	drop años_prim años_cb_mb años_cb_ms años_sup años_post


	**********
	*eduui_ci*
	**********
	gen byte eduui_ci =0
	replace eduui_ci=1 if e215_1==2 & (e218_1!=1 & e221_1!=1) 
	replace eduui_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)
	replace eduui_ci=1 if e221_1==2 & (e215_1!=1 & e218_1!=1)
	

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci =0
	replace eduuc_ci=1 if e215_1==1 | e218_1==1 | e221_1==1  

	**********
	*eduac_ci*
	**********
	gen eduac_ci =.
	replace eduac_ci=0 if e215_1==1 | e221_1==1 & (e218_1!=1)   
	replace eduac_ci=0 if (e215_1==2 | e221_1==2) & (e218_1==0)  
	replace eduac_ci=1 if e218_1==1 
	replace eduac_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)  
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.

	************
	*asispre_ci*
	************
	g asispre_ci=.
	replace asispre_ci =1 if e579==13 | e579==14

	***********
	*asiste_ci*
	***********
	gen asiste_ci=(e49 == 3)


	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if inlist(e202, 7, 9)
	replace pqnoasis1_ci =  2 if inlist(e202, 1, 2)
	replace pqnoasis1_ci =  3 if inlist(e202, 8, 10, 11)
	replace pqnoasis1_ci =  4 if inlist(e202, 3, 4)
	replace pqnoasis1_ci =  5 if inlist(e202, 5, 6)
	

	***********
	*edupub_ci*
	***********
	gen edupub_ci =. if (asiste_ci != 1)
	replace edupub_ci = 1 if (e581 == 1 | e581a == 1) & (asiste_ci == 1)
	replace edupub_ci = 0 if (e581 == 2 | e581 == 3 | e581a == 2) & (asiste_ci == 1)
		


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
