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

local PAIS BLZ
local ENCUESTA LFS
local ANO "2020"
local ronda m9

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: BLZ
Encuesta: LFS
Round: m9
Autores: 
Versión ...:
Nombre de autor (SCL/SCL) - Email: ..., Fecha:...
---------EXAMPLE---------: Alvaro Altamirano (LMK/SCL) - Email: alvaroalt@iadb.org, 24 de junio de 2020 PLEASE DELETE AFTER FILLING THIS PART
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
	gen byte region_BID_c=.
	replace region_BID_c=1


	********************
	*** region_c ****
	********************
	gen byte region_c = district
	label define region_c   ///
	1 "Corozal" 			///
	2 "Orange Walk"	 		///
	3 "Belize"				///
	4 "Cayo"				///
	5 "Stann Creek"			///
	6 "Toledo"
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="BLZ"

	******
	*anio*
	******
	gen int anio_c=2020
	
	******
	*mes_c*
	******
	gen int mes_c=9	

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=1 if urban_rural==1
	replace zona_c=0 if urban_rural==0
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch=group(interview__key interview__id)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	
	by interview__key: gen _seq = _n
	egen idp_ci = concat(idh_ch _seq)
	tostring idp_ci, replace format ("%20.0f") 
	drop _seq

	
	***********
	*factor_ci* 
	***********
	gen factor_ci=ind_weight
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=ind_weight
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if hl3==1
	replace sexo_ci = 2 if hl3==2

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=hl3 if hl3!=999999
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if hl4new==1
	replace relacion_ci = 2 if hl4new==2
	replace relacion_ci = 3 if hl4new==3
	replace relacion_ci = 4 if hl4new==4
	replace relacion_ci = 5 if hl4new==5
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=1
	
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if hl8new==1
	replace civil_ci = 2 if hl8new==2 
	replace civil_ci = 3 if hl8new==3 | hl8new==5
	replace civil_ci = 4 if hl8new==4
		
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
	replace afro_ci = 1 if inlist(hl6new, 1, 2)
	replace afro_ci = 0 if inlist(hl6new, 3, 4, 5)
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta
	replace ind_ci = 1 if hl6new == 3
	replace ind_ci = 0 if inlist(hl6new, 1, 2, 4, 5)

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci = 1 if hl6new == 4
	replace noafroind_ci = 0 if inlist(hl6new, 1, 2, 3, 5)	
	
	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.   // se queda como missing (.) si no existe la pregunta	

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1

	
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
	gen byte BLZ_dis_ci = .
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if status == 2 /* ocupado */
	replace condocup_ci = 2 if status == 3 /* desocupado */
	replace condocup_ci = 3 if status == 4 /* inactivo */
	replace condocup_ci = 4 if status == 1
	recode condocup_ci (.=4) if edad<14

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	/*replace categoinac_ci = 1 if (…== 2 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (… == 3 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (… == 4 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 | categoinac_ci != 2 | categoinac_ci != 3) & condocup_ci == 3)
	*/
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if condocup_ci == 2 & ea9anew == 1
	replace cesante_ci = 0 if condocup_ci == 2 & ea9anew == 2

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0 if emp_ci == 1
	replace subemp_ci = 1 if total_hrs_last_week<=30  & total_hrs_last_week != . & ea23a == 1 & ea23bnew == 1 & emp_ci == 1  //se utiliza la pregunta:  Desire to work more & available for additional work

	****************
	***durades_ci***
	****************
	gen byte durades_ci=ea11_1*12 if ea11_1<11 & ea11_1!=.

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
	replace nempleos_ci = 1 if ea14==1
	replace nempleos_ci = 2 if ea14==2
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
	*No se encuentra la variable en 2020

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	replace horaspri_ci = total_hrs_last_week if total_hrs_last_week!= 999999 &  total_hrs_last_week!=. & ea14==2 //quedaria en missing las presonas que tienen más de un trabajo 
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = .
	replace horastot_ci  = total_hrs_last_week if total_hrs_last_week!= 999999 &  total_hrs_last_week!=.
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci  =(total_hrs_last_week<30  & ea23bnew == 2) if total_hrs_last_week!= 999999 &  total_hrs_last_week!=.
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	replace categopri_ci  = 0 if ea18==8 & emp_ci ==1
	replace categopri_ci  = 1 if ea18==1 & emp_ci ==1
	replace categopri_ci  = 2 if ea18==2 & emp_ci ==1
	replace categopri_ci  = 3 if ((ea18>2 & ea18<6) | ea18==7) & emp_ci ==1
	replace categopri_ci  = 4 if ea18==6 & emp_ci ==1
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	replace rama_ci  = 0 if ...
	replace rama_ci  = 1 if ea17_bcea_main_industry>=1 & ea17_bcea_main_industry<4
	replace rama_ci  = 2 if ea17_bcea_main_industry==4
	replace rama_ci  = 3 if ea17_bcea_main_industry==5
	replace rama_ci  = 4 if ea17_bcea_main_industry==6
	replace rama_ci  = 5 if ea17_bcea_main_industry==7
	replace rama_ci  = 6 if ea17_bcea_main_industry==8 | ea17_bcea_main_industry==9
	replace rama_ci  = 7 if ea17_bcea_main_industry==10
	replace rama_ci  = 8 if ea17_bcea_main_industry==11
	replace rama_ci  = 9 if ea17_bcea_main_industry==14
	replace rama_ci  = 10 if ea17_bcea_main_industry==13
	

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 0 if  ea18!=3 & emp_ci == 1 & ea18<8
	replace spublico_ci  = 1 if  ea18==3 & emp_ci == 1  & ea18<8
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .

	
	***************
	***cotizando_ci***
	***************	
	gen  byte cotizando_ci = .
	replace cotizando_ci  = 0 if ea19a==2 & inlist(condocup_ci 1, 2)
	replace cotizando_ci  = 1 if ea19a==1 & emp_ci==1
	
	
	***************
	***afiliado_ci***
	***************	
	gen  byte afiliado_ci = .
	replace afiliado_ci  = = 0 if ea19a==2 & inlist(condocup_ci 1, 2)
	replace afiliado_ci  = 1 if ea19a==1 & emp_ci==1	
	
	***************
	***instcot_ci***
	***************	
	gen  byte instcot_ci = ""
	replace instcot_ci  = "Balize Social Security Board"	if cotizando_ci == 1
	
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

		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci=.
	replace ocupa_ci=1 if ea16main_occ==2 | ea16main_occ==3 & emp_ci==1
	replace ocupa_ci=2 if  ea16main_occ==1 & emp_ci==1
	replace ocupa_ci=3 if  ea16main_occ==4 & emp_ci==1
	replace ocupa_ci=6 if  ea16main_occ==6 | ea16main_occ==7 & emp_ci==1
	replace ocupa_ci=7 if  ea16main_occ==8 & emp_ci==1
	replace ocupa_ci=8 if  ea16main_occ==0  & emp_ci==1
	replace ocupa_ci=9 if ea16main_occ==5 | ea16main_occ==9 & emp_ci==1


	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 

	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 

	***************
	**tipopen_ci**
	***************
	gen byte tipopen_ci = . 
	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci = ""
	
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	generate double ylmpri_ci = . if emp_ci == 1

	************
	* ylmsec_ci *
	************
	generate double ylmsec_ci = .

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci=.
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	gen double ylnmpri_ci =.
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
	gen double ylnmsec_ci = .
*   egen double ylnmsec_ci = rowtotal(...) if emp_ci==1, mi
*   replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
	gen double ylnmotros_ci=.
*   egen double ylnmotros_ci = rowtotal(...) if emp_ci==1, mi
*   replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	gen double ynlm_ci = .
*	egen double ynlm_ci = rowtotal(...), mi
*	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci = .
*	replace ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .

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
	gen double ynlm_ch = .
 *   egen double ynlm_ch = rowtotal(...), mi
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
    generate double ylmhopri_ci = ylmpri_ci/horaspri_ci if emp_ci==1 & horaspri_ci>0
 
	**********
	* ylmho_ci *
	**********
    generate double ylmho_ci = ylm_ci/horastot_ci if emp_ci==1 & horastot_ci>0
  
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
    generate double remesas_ch = .


	**********
	* ypen_ci *
	**********
	generate double ypen_ci =.


	*************
	* ypensub_ci *
	*************
	generate double ypensub_ci = .
		
	
****************************
***VARIABLES DE EDUCACION***
****************************



	*********	
	*aedu_ci*
	*********
	gen aedu_ci=.
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron
	replace aedu_ci=0 if ((ed5==21 | ed5==26) | hl3<3) & ed3==2 // Cero anios de educación para aquellos que no han asistido nunca a ninguna institucion y los menores de 2 anios
	replace aedu_ci=ed5 if ed5<13 & ed3==2
	replace aedu_ci=13 if ed5>12 & ed5<17 & ed3==2
	replace aedu_ci=12+2 if ed5==17 & ed3==2
	replace aedu_ci=12+4 if ed5==18 & ed3==2
	replace aedu_ci=12+6 if ed5==19 & ed3==2
	
	replace aedu_ci=ed5-1 if ed4<13 & ed3==1
	replace aedu_ci=13-1 if ed4>12 & ed4<17 & ed3==1
	replace aedu_ci=12+1 if ed4==17 & ed3==1
	replace aedu_ci=12+3 if ed4==18 & ed3==1
	replace aedu_ci=12+5 if ed4==19 & ed3==1
	

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = (ed4==17 | ed4==18)
	replace eduui_ci = . if aedu_ci == . 

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = (ed5==17 | ed5==18 | ed5==19)
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci = 1 if ed5==19
	replace eduac_ci = 0 if ...
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.

	************
	*asispre_ci*
	************
	g asispre_ci=.


	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci=0 if ed3==1
	replace asiste_ci=1 if  ed3==2


	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if ed6==3
	replace pqnoasis1_ci =  2 if ed6==8
	replace pqnoasis1_ci =  3 if ed6==1 | ed6==7
	replace pqnoasis1_ci =  5 if ed6==2 | ed6==888888

	***********
	*edupub_ci*
	***********
	gen edupub_ci =.

		

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.

	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	
	
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

	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.

	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=.
	
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.

	
	***********
	*telef_ch*
	***********
	gen telef_ch=.
	
	************
	***cel_ch***
	************
	gen byte cel_ch=.

	***********
	*refrig_ch*
	***********
	gen refrig_ch=.

	
	***********
	*freez_ch*
	***********
	gen freez_ch=.

	
	***********
	*auto_ch*
	***********
	gen auto_ch=.

	
	***********
	*compu_ch*
	***********
	gen compu_ch=.

		
	***********
	*internet_ch*
	***********
	gen internet_ch=.

	
	***********
	*vivi1_ch*
	***********
	gen vivi1_ch=.

	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	
	
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

	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.


	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo _ch =.


	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.

	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.

	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =9
	
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

		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .

		
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
	replace migrante_ci=0 if hl7new==1
	replace migrante_ci=1 if inlist(hl7new,2,3,4)
	
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


	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine _ci= . 


	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 


	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 

	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 

	

	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
