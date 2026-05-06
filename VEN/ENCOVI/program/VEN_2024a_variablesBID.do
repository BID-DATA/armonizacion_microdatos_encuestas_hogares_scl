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

local PAIS VEN
local ENCUESTA ENCOVI
local ANO "2024"
local ronda a 

local log_file = "$ruta/harmonized/`PAIS'/`ENCUESTA'/log/`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta/survey/`PAIS'/`ENCUESTA'/`ANO'/`ronda'/data_merge/`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\\harmonized/`PAIS'/`ENCUESTA'/data_arm/`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 

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
	
	gen byte region_BID_c=3



	********************
	*** region_c ****
	********************
	gen byte region_c =entidad
	
	label define region_c   ///
	1	"Distrito Federal"  ///
	3	"Anzoategui"  ///
	4	"Apure " ///
	5	"Aragua " ///
	6	"Barinas " ///
	7	"Bolívar " ///
	8	"Carabobo " ///
	9	"Cojedes " ///
	11	"Falcón"  ///
	12	"Guárico"  ///
	13	"Lara"  ///
	14	"Mérida"  ///
	15	"Miranda"  ///
	16	"Monagas"  ///
	17	"Nueva Esparta"  /// 
	18	"Portuguesa"  ///
	19	"Sucre"  ///
	20	"Táchira"  ///
	21	"Trujillo"  ///
	22	"Yaracuy"  ///
	23	"Zulia"  ///
	24	"La Guaira" 			
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="VEN"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=.

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=.
	
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
	gen idh_ch=ID
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen idp_ci = codpersona
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=Peso_Persona
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=Peso_Hogar
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if control_sexo=="01"
	replace sexo_ci = 2 if control_sexo=="02"

	*********
	*edad_ci*
	*********
	gen int edad_ci=s6q5
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if s6q2==1
	replace relacion_ci = 2 if s6q2==2
	replace relacion_ci = 3 if s6q2==3 | s6q2==4
	replace relacion_ci = 4 if s6q2>4 & s6q2<12
	replace relacion_ci = 5 if s6q2==12
	*replace relacion_ci = 6 if  // empleado domesticos
	
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
	replace civil_ci = 1 if s6q6_01==8
	replace civil_ci = 2 if s6q6_01>=1 & s6q6_01<5
	replace civil_ci = 3 if s6q6_01>=5 & s6q6_01<7
	replace civil_ci = 4 if s6q6_01==4
		
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
	gen byte afro_ci =0
	replace afro_ci = 1 if s6q7_01==2 // se queda como missing (.) si no existe la pregunta
	
	*********
	*ind_ci*
	*********	
	gen byte ind_ci =0 
	replace ind_ci=1 if s6q7_01==1 // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =0 
	replace noafroind_ci=1 if s6q7_01==3 // se queda como missing (.) si no existe la pregunta

	************
	*afroind_ci*
	************
	gen byte afroind_ci=2024
	
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
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if (s9q1==1 | (s9q1==2 | s9q2<13))
	replace condocup_ci=2 if (s9q1==3 | (s9q1==4) )
	replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2 & edad_ci!=.
	replace condocup_ci=4 if edad_ci<10

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (s9q3 == 17 & condocup_ci == 3)
	replace categoinac_ci = 2 if (s9q3 == 13 & condocup_ci == 3)
	replace categoinac_ci = 3 if (s9q3 == 14 & condocup_ci == 3)
	replace categoinac_ci = 4 if ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3)
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci =(s9q12<30 & s9q26==1) if emp_ci==1

	****************
	***durades_ci***
	****************
	gen byte durades_ci=s9q7a*(52/12)

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
	*replace nempleos_ci = 1 if ...
	*replace nempleos_ci = 2 if ...
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .
*	replace antiguedad_ci = 1 if ...
*	replace antiguedad_ci = ... if emp_ci == 1
	
	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .
	replace desalent_ci = (s9q8==1 | s9q8==3 | s9q8==5) & condocup_ci==3

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	replace horaspri_ci =s9q12 if emp_ci==1
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = .
	replace horastot_ci  =s9q14 if s9q14<160 & emp_ci==1
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen byte tiempoparc_ci= ((horaspri_ci >= 1 & horaspri_ci < 30) & s9q26==2 & emp_ci == 1) 
	replace tiempoparc_ci = . if emp_ci == 0

	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if ...
	replace categopri_ci  = 1 if (s9q11== 3 & emp_ci==1)
	replace categopri_ci  = 2 if  (s9q11==4 | s9q11==7) & emp_ci==1
	replace categopri_ci  = 3 if  (s9q11== 1 | s9q11==2 | s9q11==9) & emp_ci==1
	replace categopri_ci  = 4 if (s9q11==8 & emp_ci==1)
	

	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	/*replace categosec_ci  = 0 if ...
	replace categosec_ci  = 1 if ...
	replace categosec_ci  = 2 if ...
	replace categosec_ci  = 3 if ...
	replace categosec_ci  = 4 if ...	
*/
	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	replace rama_ci  = 0 if s9q10>8
	replace rama_ci  = 1 if s9q10==1
	replace rama_ci  = 2 if s9q10==2
	replace rama_ci  = 3 if s9q10==3
	replace rama_ci  = 4 if s9q10==4
	replace rama_ci  = 5 if s9q10==5
	replace rama_ci  = 6 if s9q10==6
	replace rama_ci  = 7 if s9q10==7
	replace rama_ci  = 8 if s9q10==8
	*replace rama_ci  = 9 if 

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 0 if s9q11!=1 & emp_ci==1
	replace spublico_ci  = 1 if s9q11==1 & emp_ci==1
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	replace tamemp_ci  = 1 if s9q11c<4
	replace tamemp_ci  = 2 if s9q11c>3 & s9q11c<6
	replace tamemp_ci  = 3 if s9q11c>5
	
	
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
	replace tipocontrato_ci = 1 if s9q11b==1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if s9q11b==2 & categopri_ci == 3
	replace tipocontrato_ci = 3 if s9q11b==3 | s9q11b==4 & categopri_ci == 3
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci=.
	replace ocupa_ci=1 if s9q9==2 & emp_ci==1
	replace ocupa_ci=2 if s9q9==1 & emp_ci==1
	replace ocupa_ci=3 if s9q9==3 & emp_ci==1
	*replace ocupa_ci=4 if & emp_ci==1
	*Çreplace ocupa_ci=5 if  … & emp_ci==1
	replace ocupa_ci=6 if  s9q9==6  & emp_ci==1
	replace ocupa_ci=7 if  s9q9==7 | s9q9==8 & emp_ci==1
	replace ocupa_ci=8 if  s9q9==10 & emp_ci==1
	replace ocupa_ci=9 if  s9q9==5 | s9q9==9 & emp_ci==1

	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	replace pension_ci=1 if s9q1==8
	replace pension_ci=0 if s9q1!=8 & s9q1
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
	*replace pensionsub_ci =1 
	*replace pensionsub_ci = 0 
	
	***************
	**tipopen_ci**
	***************
	gen byte tipopen_ci = . 
	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci =.

****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	egen double ylmpri_ci =rowtotal(IngLabMonV_CI IngLabMonE_w) if emp_ci==1, mi

	************
	* ylmsec_ci *
	************
	generate double ylmsec_ci =. if emp_ci==1

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
	egen double ylnmpri_ci = rowtotal(IngLabNoMon_CI) if emp_ci==1, mi
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
    gen double ylnmsec_ci =. if emp_ci==1
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
	egen double ynlm_ci = rowtotal(PenyJubEps PenyJubV InstprivVps PersprivV_w escolarpub Bonosytransf_CI), mi
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
    *egen double ynlm_ch = rowtotal(ynlm_privado_ch ynlm_publico_ch ynlm_otros_ch), mi
	 gen double ynlm_ch =.
 
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
    generate double remesas_ch =Rentaimp

	**********
	* ypen_ci *
	**********
	egen double ypen_ci = rowtotal(PenyjubV_CI PenyJubE) if pension_ci==1

	*************
	* ypensub_ci *
	*************
	generate double ypensub_ci =. if pensionsub_ci==1
		
	
****************************
***VARIABLES DE EDUCACION***
****************************



	*********	
	*aedu_ci*
	*********

	gen aedu_ci=.
	recode s7q11* s7q4* (99=.) (98=.)
	
	gen anos_sup = s7q11b 
	replace anos_sup = trunc(s7q11b*0.5) if s7q11a==2
	replace anos_sup = trunc(s7q11b*0.33) if s7q11a==3
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron
	replace aedu_ci=0  if s7q11==1  // Cero anios de educación para aquellos que no han asistido nunca a ninguna institucion y los menores de 2 anios
	replace aedu_ci=0 if s7q11==2 // Prescolar
	replace aedu_ci=s7q11b   if s7q11==3 // Regimen anterior: Básica (1-9)
	replace aedu_ci=s7q11b+9 if s7q11==4 // Régimen anterior: Media Diversificado y Profesional
	replace aedu_ci=s7q11b if s7q11==6 // Régimen actual: Primaria (1-6)
	replace aedu_ci=s7q11b+6 if s7q11==6 // Régimen actual: Media (1-6)
	replace aedu_ci=11+anos_sup      if s7q11a==1 & (s7q11==7 | s7q11==8) // Técnico (TSU) | Universitario
	replace aedu_ci=16+anos_sup       if s7q11a==1 & s7q11==9 // Posgrado

			
	**********
	*eduui_ci*
	**********
	// está estudiando superior y su mayor grado es menor que superior completo
	gen byte eduui_ci = 0
	replace eduui_ci = 1 if s7q4 == 4 & anos_sup<3
	replace eduui_ci = 1 if s7q4 == 5 & anos_sup<5
	// ultimo nivel alcanzado es superior pero menor que completo
	replace eduui_ci = 1 if s7q11==7 & anos_sup<3
	replace eduui_ci = 1 if s7q11==8 & anos_sup<5
	
	replace eduui_ci = 0 if s7q11==9
	replace eduui_ci = . if aedu_ci == .
	
	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = 0
	replace eduuc_ci = 1 if s7q4 == 4 & anos_sup>=3
	replace eduuc_ci = 1 if s7q4 == 5 & anos_sup>=5
	replace eduuc_ci = 1 if s7q4 == 6
	
	replace eduuc_ci = 1 if s7q11==7 & anos_sup>=3
	replace eduuc_ci = 1 if s7q11==8 & anos_sup>=5
	replace eduuc_ci = 1 if s7q11==9

	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci = 1 if inlist(s7q11, 8, 9) | inlist(s7q4, 5, 6)
	replace eduac_ci = 0 if s7q11 == 7 | s7q4 == 4
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.

	************
	*asispre_ci*
	************
	g asispre_ci=(s7q4==1)

	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci=1 if s7q3==1 
	replace asiste_ci=0 if s7q3==2 			


	*************
	*razonesnoasis_ci*
	**************
	gen razonesnoasis_ci=. 
	replace razonesnoasis_ci =  1 if s7q1305==1 | s7q1306==1 | s7q1308==1
	replace razonesnoasis_ci =  2 if s7q1301==1 | s7q1309==1 | s7q1315==1
	replace razonesnoasis_ci =  3 if s7q1307==1 | s7q1313==1 | s7q1314==1
	replace razonesnoasis_ci =  4 if s7q1302==1 | s7q1303==1 | s7q1304==1 | s7q1310==1 | s7q1311==1 | s7q1312==1
	replace razonesnoasis_ci =  5 if s7q1316==1


	***********
	*edupub_ci*
	***********
	gen edupub_ci =.
	replace edupub_ci = 1 if s7q5==2
	replace edupub_ci = 0 if s7q5==1
		

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=0 if s4q703==1 | s4q704==1
	replace luz_ch=1 if s4q701==1 | s4q702==1
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if s5q1604==1 | s5q1605==1
	replace combust_ch=1 if s5q1601==1 | s5q1602==1 | s5q1603==1
	
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
	replace resid_ch=0 if s4q901==1 | s4q902==1
	replace resid_ch=1 if s4q905==1		
	replace resid_ch=2 if s4q903==1 | s4q906==1	| s4q904==1
	replace resid_ch=3 if s4q907==1
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.
	replace dorm_ch=s5q1 if s5q1<12
	
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
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	replace refrig_ch=0 if s5q6_01_01==2
	replace refrig_ch=1 if s5q6_01_01==1
	
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
	replace compu_ch=0 if s5q6_05_01==2 | s5q6_04_01==2
	replace compu_ch=1 if s5q6_05_01==1 | s5q6_04_01==1
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=0 if s5q6_10_01==2
	replace internet_ch=1 if s5q6_10_01==1
	
	***********
	*internet_ch*
	***********
	gen vivi1_ch=.
	replace vivi1_ch=1 if s4q4==1 | s4q4==2 
	replace vivi1_ch=2 if s4q4==3 | s4q4==4
	replace vivi1_ch=3 if s4q4>4
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch=0 if s5q7==4 | s5q7==5
	replace viviprop_ch=1 if s5q7==1 | s5q7==2	
	replace viviprop_ch=2 if s5q7==3
	replace viviprop_ch=3 if s5q7>5	
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	replace vivitit_ch=0 if s5q7==2 | s5q7==3
	replace vivitit_ch=1 if s5q7==1
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=.
	replace vivialq_ch=s5q11 if s5q11!=. 
	
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
	replace aguared_ch = 1 if s4q5==1 
	replace aguared_ch = 0 if s4q5>1 & s4q5!=.

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =0

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if s4q5==1
	replace aguafuente_ch = 2 if s4q5==2
	replace aguafuente_ch = 4 if s4q5==4
	replace aguafuente_ch = 6 if s4q5==3
	replace aguafuente_ch = 8 if s4q5==5
	replace aguafuente_ch = 9 if s4q5==6
	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =.
	replace aguadisp2_ch = 1 if  s4q6==3|s4q6==4|s4q6==5
	replace aguadisp2_ch = 2 if s4q6==2
	replace aguadisp2_ch = 3 if s4q6==1
	
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
	replace bano_ch = 0 if s4q10==5
	replace bano_ch = 1 if s4q10==1
	replace bano_ch = 2 if s4q10==2
	replace bano_ch = 6 if s4q10==3| s4q10==4
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch =.
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 3 if s4q10!=.
	replace sinbano_ch = 0 if s4q10!=5
		
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
	replace pobre_ine_ci= 0 if Pobrezaporlinea==1
	replace pobre_ine_ci= 1 if Pobrezaporlinea==2  | Pobrezaporlinea==3

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = .
	replace bienestar_agregado =IngresoHogartotalconrentaimputad if IngresoHogartotalconrentaimputad!=.

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

