

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

local PAIS TTO
local ENCUESTA HBS
local ANO "2023"
local ronda a 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: ....
Encuesta: ...
Round: ...
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
	replace region_BID_c=2


	********************
	*** region_c ****
	********************
	gen byte region_c = .
	
	replace region_c=municipality
	label define region_c   ///
	11	"Port of Spain"	///
	35	"Mayaro/Rio Claro"	///
	36	"Sangre Grande"	///
	37	"Princes Town"	///
	38	"Penal/Debe"	///
	39	"Siparia"	///
	12	"City of San Fernando"	///
	21	"Borough of Arima"	///
	22	"Borough of Chaguanas"	///
	23	"Borough of Point Fortin"	///
	31	"Diego Martin"	///
	32	"San Juan/Laventille"	///
	33	"Tunapuna/Piarco"	///
	34	"Couva/Tabaquite/Talparo"	///
	91	"St. George"	///
	92	"St. Mary"	///
	93	"St. Andrew"	///
	94	"St. Patrick"	///
	95	"St. David"	///
	96	"St. Paul"	///
	97	"St. John"	
	
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="TTO"

	******
	*anio*
	******
	gen int anio_c=2023
	
	******
	*mes_c*
	******
	gen int mes_c=.

	******
	*zona*
	******
	gen zona_c=.
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=PSU
	
	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch=group(interview__key interview__id)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(interview__key interview__id HHCharacteristics__id)
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=.
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=.
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if p1_2==1
	replace sexo_ci = 2 if p1_2==2

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=p1_3 if p1_3!=.
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if p1_1==1
	replace relacion_ci = 2 if p1_1==2 | p1_1==3
	replace relacion_ci = 3 if p1_1>3 & p1_1<7
	replace relacion_ci = 4 if p1_1>6 & p1_1<11
	replace relacion_ci = 5 if p1_1==77
	replace relacion_ci = 6 if p1_1==11

	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=.
	
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if p1_7==1 & (p1_8==6)
	replace civil_ci = 2 if p1_8==1 | p1_8==2
	replace civil_ci = 3 if p1_7==5 | p1_7==4
	replace civil_ci = 4 if p1_7==3
		
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
	gen byte tto_dis_ci = .
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if p6_1==1
	replace condocup_ci = 2 if p6_1==2 & p6_2==1
	replace condocup_ci = 3 if p6_1==2 & p6_2==2
	replace condocup_ci = 4 if p1_3<15

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (p6_3== 3 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (p6_3 == 1 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (p6_3== 2 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci ==.) & condocup_ci == 3)
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if p6_4==6
	replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	*replace subemp_ci = 1 if ... 

	****************
	***durades_ci***
	****************
	gen byte durades_ci=.

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
	replace nempleos_ci = 1 if p6_16==2
	replace nempleos_ci = 2 if p6_16==1
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
	replace desalent_ci = (p6_2==2 & p6_3==7)

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	*replace horaspri_ci = . if ... 
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = .
	*replace horastot_ci  = . if ... 
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .
	*replace tiempoparc_ci  = . if ... 
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if ...
	replace categopri_ci  = 1 if p6_8==5
	replace categopri_ci  = 2 if p6_8==6
	replace categopri_ci  = 3 if p6_8==1 | p6_8==2 | p6_8==3 | p6_8==4 | p6_8==8 | p6_8==9
	replace categopri_ci  = 4 if p6_8==7
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	/*replace rama_ci  = 0 if ...
	replace rama_ci  = 1 if ...
	replace rama_ci  = 2 if ...
	replace rama_ci  = 3 if ...
	replace rama_ci  = 4 if ...
	replace rama_ci  = 5 if ...
	replace rama_ci  = 6 if ...
	replace rama_ci  = 7 if ...
	replace rama_ci  = 8 if ...
	replace rama_ci  = 9 if ...*/

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 0 if p6_8>=4 & p6_8<10
	replace spublico_ci  = 1 if p6_8>=1 & p6_8<4
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	*replace tamemp_ci  = 1 if ...
	*replace tamemp_ci  = 2 if ...
	*replace tamemp_ci  = 3 if ...
	
	
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
	gen  byte instcot_ci=.	
	
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
	/*replace ocupa_ci=1 if … & emp_ci==1
	replace ocupa_ci=2 if  … & emp_ci==1
	replace ocupa_ci=3 if  … & emp_ci==1
	replace ocupa_ci=4 if  … & emp_ci==1
	replace ocupa_ci=5 if  … & emp_ci==1
	replace ocupa_ci=6 if  …  & emp_ci==1
	replace ocupa_ci=7 if  … & emp_ci==1
	replace ocupa_ci=8 if  …  & emp_ci==1
	replace ocupa_ci=9 if  …  & emp_ci==1
*/
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
	generate double ylmpri_ci =. if emp_ci==1
	replace ylmpri_ci =(ps17_3*(52/12)) if emp_ci==1 & ps17_2==1 & ps17_2>0
	replace ylmpri_ci =(ps17_3*2) if emp_ci==1 & ps17_2==2 & ps17_2>0
	replace ylmpri_ci =ps17_3 if emp_ci==1 & ps17_2==3 & ps17_2>0
	replace ylmpri_ci =(ps17_3/2) if emp_ci==1 & ps17_2==4 & ps17_2>0
	replace ylmpri_ci =(ps17_3/12) if emp_ci==1 & ps17_2==5 & ps17_2>0

	************
	* ylmsec_ci *
	************
	generate double ylmsec_ci = . if emp_ci==1
	replace ylmsec_ci =ps17_26*(52/12) if emp_ci==1 & ps17_25==1 & ps17_26>0
	replace ylmsec_ci =ps17_26*(2) if emp_ci==1 & ps17_25==2 & ps17_26>0
	replace ylmsec_ci =ps17_26 if emp_ci==1 & ps17_25==3 & ps17_26>0
	replace ylmsec_ci =ps17_26/2 if emp_ci==1 & ps17_25==4 & ps17_26>0
	replace ylmsec_ci =ps17_26/12 if emp_ci==1 & ps17_25==5 & ps17_26>0

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci =ps17_11+ps17_15 if emp_ci==1
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	egen double ylnmpri_ci = rowtotal(ps17_13) if emp_ci==1, mi
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
    egen double ylnmsec_ci = rowtotal(ps17_38 ps17_40) if emp_ci==1, mi
    replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
    gen double ylnmotros_ci =. if emp_ci==1
    replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	gen double ynlm_ci = .
	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci =.
	replace ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .

	**********
	* ytot_ci *
	**********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

	*********
	* ylm_ch *
	*********
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1, mi

	**********
	* ylnm_ch *
	**********
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1, mi
	
	*********
	* ynlm_ch *
	*********
    bysort idh_ch:  egen double ynlm_ch = total(ynlm_ci)  if miembros_ci==1, mi

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1, mi

 
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
    generate double remesas_ch = .


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
	
	gen a=p5_5-6 if p5_5!=99
	replace a=12 if p5_4==6
	
	gen aedu_ci=.
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron

	replace aedu_ci=0 if p5_4==1  // Cero anios de educación para aquellos que no han asistido nunca a ninguna institucion y los menores de 2 anios
	replace aedu_ci=0 if p5_4==2 & p5_5==2 // Prescolar
	replace aedu_ci=a if p5_4>2 & p5_4<8 

	drop a	

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci =(p5_4==6)
	replace eduui_ci = . if aedu_ci == . 

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = (p5_4==7)
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci = .
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
	replace asiste_ci=0 if p5_2==2
	replace asiste_ci=1 if p5_2==1


	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if p5_7==2 | p5_7==4
	replace pqnoasis1_ci =  2 if p5_7==6
	replace pqnoasis1_ci =  3 if p5_7==5 | p5_7==9 | p5_7==10 | p5_7==13
	replace pqnoasis1_ci =  4 if p5_7==3 | p5_7==16
	replace pqnoasis1_ci =  5 if p5_7==1 | p5_7==7 | p5_7==8 | p5_7==11 | p5_7==12 | p5_7==14 | p5_7==15 | p5_7==77

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
	replace luz_ch=0 if h1_17==3 | h1_17==4 | h1_17==77 		
	replace luz_ch=1 if h1_17==1 | h1_17==2	
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	*replace luzmide_ch=0 if ...
	*replace luzmide_ch=1 if ...		
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if h1_18==3 | h1_18==24 | h1_18==77 | h1_18==88
	replace combust_ch=1 if h1_18==1 | h1_18==2	
	
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
	replace resid_ch=0 if h1_19==1
	replace resid_ch=1 if h1_19==3 | h1_19==5  		
	replace resid_ch=2 if h1_19==2
	replace resid_ch=3 if h1_19==6 | h1_19==77	
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.
	replace dorm_ch=h1_22 if h1_22!=.
	
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
	replace telef_ch=0 if h1_24__1==0
	replace telef_ch=1 if h1_24__1==1	
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	replace refrig_ch=0 if h1_s25a7==0
	replace refrig_ch=1 if h1_s25a7>0
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	replace freez_ch=0 if h1_25b__4==1
	replace freez_ch=1 if h1_25b__4==0
	
	***********
	*auto_ch*
	***********
	gen auto_ch=.

	
	***********
	*compu_ch*
	***********
	gen compu_ch=.
	replace compu_ch=0 if  h1_25b__2==0
	replace compu_ch=1 if  h1_25b__2==1
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=0 if h1_24__2==0
	replace internet_ch=1 if h1_24__2==1
	
	************
	***cel_ch***
	************
	gen byte cel_ch=(h1_25a1==1) if h1_25a1!=.

	
	***********
	*vivi1_ch*
	***********
	gen vivi1_ch=.
	replace vivi1_ch=1 if h1_5==1 | h1_5==2 
	replace vivi1_ch=2 if h1_5==3 | h1_5==4 
	replace vivi1_ch=3 if h1_5==5 | h1_5==10 | h1_5==98 | h1_5==7 | h1_5==8 | h1_5==9
	
	**************
	***vivi2_ch***
	**************
	gen byte vivi2_ch=(h1_5==1 | h1_5==2)
	replace vivi2_ch=. if h1_5==.

	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch = 0 if (h2_1>1 & h2_1<6) | (h2_2>0 & h2_2<5)
	replace viviprop_ch = 4 if h2_1 == 1 | h2_2==1 
	*replace viviprop_ch = 2 if h2_1 == 
	replace viviprop_ch = 3 if h2_1==6 | h2_1==7 | h2_1==77 | (h2_2>4 & h2_2<99) 
	replace viviprop_ch = . if h2_1 == . & h2_2 ==.


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
	replace aguared_ch = 1 if h1_7==1 | h1_7==2
	replace aguared_ch = 0 if h1_7!=1 | h1_7!=2 | h1_7!=. | h1_7!=99

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =.
	*replace aguafconsumo_ch = 0 if 
	replace aguafconsumo_ch = 1 if h1_9>0 & h1_9<3
	replace aguafconsumo_ch = 2 if h1_9==3
	replace aguafconsumo_ch = 3 if h1_9==8
	replace aguafconsumo_ch = 4 if h1_9==1
	replace aguafconsumo_ch = 5 if h1_9==4
	replace aguafconsumo_ch = 6 if h1_9==6 | h1_9==5
	*replace aguafconsumo_ch = 7 if 
	replace aguafconsumo_ch = 8 if h1_9==7
	replace aguafconsumo_ch = 9 if h1_9==77
	*replace aguafconsumo_ch = 10 if …

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if h1_7==1 | h1_7==2
	replace aguafuente_ch = 2 if h1_7==3
	*replace aguafuente_ch = 3 if …
	replace aguafuente_ch = 4 if h1_7==4
	*replace aguafuente_ch = 5 if …
	replace aguafuente_ch = 6 if h1_7==6
	*replace aguafuente_ch = 7 if …
	replace aguafuente_ch = 8 if h1_7==7 | h1_7==5
	replace aguafuente_ch = 9 if h1_7==77
	*replace aguafuente_ch = 10 if
	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if h1_7==1
	replace aguadist_ch = 2 if h1_7==2
	*replace aguadist_ch = 3 if …
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
	replace aguadisp2_ch = 1 if h1_8==2  |  h1_8==4
	replace aguadisp2_ch = 2 if h1_8==3
	replace aguadisp2_ch = 3 if h1_8==1
	*replace aguadisp2_ch = 9 if …
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	*replace aguatrat_ch = 0 if …
	*replace aguatrat_ch = 1 if …
	
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
	*replace aguamide_ch = 0 if …
	*replace aguamide_ch = 1 if...
	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
	*replace bano_ch = 0 if …
	replace bano_ch = 1 if h1_13==1
	replace bano_ch = 2 if h1_13==2
	*replace bano_ch = 3 if …
	*replace bano_ch = 4 if …
	*replace bano_ch = 5 if …
	replace bano_ch = 6 if h1_13==3 | h1_13==77 | h1_13==88
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	replace banoex_ch = 0 if h1_14==2 
	replace banoex_ch = 1 if h1_14==1
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if h1_14==1
	*replace sinbano_ch = 1 if…
	*replace sinbano_ch = 2 if…
	replace sinbano_ch = 3 if h1_14==2 & h1_15==2
		
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
	gen migrante_ci= (p07==1)


	
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
	gen byte pobre_ine_ci= . 


	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado =.

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci = .
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = .
	

	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
save "`base_out'", replace

cap log close

