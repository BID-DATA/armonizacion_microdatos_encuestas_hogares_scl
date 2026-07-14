
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

global ruta = "${surveysFolderRestricted}"

local PAIS BHS
local ENCUESTA LFS
local ANO "2017"
local ronda a


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                                             
       
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Bahamas
Encuesta: LFS
Round: a
Autores: Maria Alejandra Zegarra
Versión ...: Octubre 2025

/***************************************************************************/
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use `base_in', clear
			
**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	
	*************************
	*** region_ según BID****
	*************************
	gen region_BID_c=2

	********************
	*** region_c *******
	********************
	gen region_c = island
	label define region_c ///
	1 "New Providence" ///
	2 "Grand Bahama" ///
	3 "Abaco" ///
	4 "Other Family Islands" 
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c = "BHS"

	******
	*anio*
	******
	gen int anio_c = `ANO'

	******
	*mes_c*
	******
	gen int mes_c = .
	
	******
	*zona*
	******
	gen zona_c = 1

	*********
	*estrato*
	*********
	gen estrato_ci = .

	*****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci = .
	
	******************
	*** idh_ch ******
	******************
	egen idh_ch = group(island hhno)
	tostring idh_ch, replace

	******************
	*** idp_ci *******
	******************
	duplicates report island hhno ind_no sex age
	egen idp_ci= concat(island hhno ind_no sex age)
	tostring idp_ci, replace

	duplicates report idh_ch idp_ci

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch= weights
	bys idh_ch: egen aux = max(factor_ch)
	replace factor_ch=aux if factor_ch==.
	drop aux
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=weight 
	bys idh_ch: egen aux = max(factor_ch)
	replace factor_ci=aux if factor_ci==.
	drop aux
	
****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci = sex

	*********
	*edad_ci*
	*********
	gen int edad_ci = age

	**************
	**relacion_ci**
	**************
	gen byte relacion_ci = .
	replace relacion_ci = 1 if rel_head==1
	replace relacion_ci = 2 if rel_head==2
	replace relacion_ci = 3 if rel_head==3
	replace relacion_ci = 4 if inlist(rel_head,4,7,8,9,10,11,12,13)   // other relatives (broad catch)
	replace relacion_ci = 5 if inlist(rel_head,5,14,15,16,17,18,19,20) // non-relatives/boarders/guests
	replace relacion_ci = 6 if rel_head==6                               // domestic employee

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = inlist(rel_head,1,2,3,5)
	replace miembros_ci = . if rel_head==9

	*****************
	*miembros_one_ci*
	*****************
	gen byte miembros_one_ci = (rel_head >= 1 & rel_head <= 5)
	replace miembros_one_ci = . if rel_head == 9
	
	**************
	*Estado Civil*
	**************
	gen civil_ci=.
	replace civil_ci=1 if marital_statu ==1
	replace civil_ci=2 if marital_statu ==2 | marital_statu ==3

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci = (relacion_ci==1)
	replace jefe_ci = . if relacion_ci==.	
	
	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
	replace nconyuges_ch =. if relacion_ci==.
	
	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.

	****************
	*notronopari_ch*
	****************
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	replace notronopari_ch=. if relacion_ci==.

	************
	*nempdom_ch*
	************
	by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.

	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch = 2 if (nhijos_ch>0 | nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
	replace clasehog_ch= 3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
	replace clasehog_ch = 4 if ( (nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & notronopari_ch>0 )
	replace clasehog_ch = 5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
	
	**************
	*nmiembros_ch*
	**************
	bysort idh_ch: egen byte nmiembros_ch = total(inrange(relacion_ci,1,5))
	replace nmiembros_ch=. if relacion_ci ==.
	tab nmiembros_ch, mi

	*************
	*nmayor21_ch*
	*************
	bysort idh_ch: egen byte nmayor21_ch  = total(inrange(relacion_ci,1,5) & edad_ci>=21 & edad_ci!=.)
	replace nmayor21_ch =. if relacion_ci==.

	*************
	*nmenor21_ch*
	*************
	bysort idh_ch: egen byte nmenor21_ch  = total(inrange(relacion_ci,1,5) & edad_ci<21)
	replace nmenor21_ch =. if relacion_ci==.

	*************
	*nmayor65_ch*
	*************
	bysort idh_ch: egen byte nmayor65_ch  = total(inrange(relacion_ci,1,5) & edad_ci>=65 & edad_ci!=.)
	replace nmayor65_ch =. if relacion_ci==.

	************
	*nmenor6_ch*
	************
	bysort idh_ch: egen byte nmenor6_ch   = total(inrange(relacion_ci,1,5) & edad_ci<6)
	replace nmenor6_ch =. if relacion_ci==.

	************
	*nmenor1_ch*
	************
	bysort idh_ch: egen byte nmenor1_ch   = total(inrange(relacion_ci,1,5) & edad_ci<1)
	replace nmenor1_ch =. if relacion_ci==.

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
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)
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

	************
	*afroind_ch*
	************
 	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 
	
	**************
	*noafroind_ch*
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci==1
	egen noafroind_ch = max(noafroind_jefe), by(idh_ch) 
	drop noafroind_jefe

	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c=.
	
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
	gen byte `PAIS'_dis_ci = .
		
**********************************
***VARIABLES DE MERCADO LABORAL***
**********************************

	*************
	*condocup_ci*
	*************
	gen condocup_ci =.
	replace condocup_ci = 1 if employ==1
	replace condocup_ci = 2 if employ==2
	replace condocup_ci = 3 if employ==3
	replace condocup_ci = 4 if edad_ci<15
	label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"
	label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor de PET"
	label value condocup_ci condocup_ci
	
	***************
	*categoinac_ci*
	***************
	gen byte categoinac_ci = .
	/*
	i43_activity:
	1 Looking For Work | 2 Waiting to Start Job  -> no se usan para inactivos
	3 Unable to work   -> Otros inactivos (4)
	4 At Home          -> Quehaceres (3)
	5 At School        -> Estudiante (2)
	6 Retired          -> Jubilado/Pensionado (1)
	7 Other            -> Otros inactivos (4)
	9 Not Stated       -> Otros inactivos (4)
	*/
	replace categoinac_ci = 1 if condocup_ci==3 & i43_activity==6
	replace categoinac_ci = 2 if condocup_ci==3 & i43_activity==5
	replace categoinac_ci = 3 if condocup_ci==3 & i43_activity==4
	replace categoinac_ci = 4 if condocup_ci==3 & (categoinac_ci!=1 & categoinac_ci!=2 & categoinac_ci!=3)

	****************
	***emp_ci*******
	****************
	* 1=Ocupado; 0=No ocupado; . = missing original
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la 	sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	****************
	***desemp_ci****
	****************
	* 1=Desocupado; 0=No desocupado; . = missing
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci
		
	*****************
	***cesante_ci****
	*****************
	* Desocupado que trabajó antes
	gen byte cesante_ci = .
	replace cesante_ci = 1 if condocup_ci==2 & workbefore==1
	replace cesante_ci = 0 if condocup_ci==2 & cesante_ci!=1

	*****************
	***durades_ci****
	*****************
	gen double durades_ci = .
	replace durades_ci = 0.5 if i51_how_long_lon==1 & condocup_ci==2
	replace durades_ci = 2   if i51_how_long_lon==2 & condocup_ci==2
	replace durades_ci = 4.5 if i51_how_long_lon==3 & condocup_ci==2
	replace durades_ci = 9   if i51_how_long_lon==4 & condocup_ci==2
	replace durades_ci = 12  if i51_how_long_lon==5 & condocup_ci==2
	replace durades_ci = .   if inlist(i51_how_long_lon,6,9,.) | condocup_ci!=2
	
	****************
	***pea_ci*******
	****************/
	* 1 si condocup_ci=1/2; 0 si condocup_ci=3/4
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)

	*****************
	***subemp_ci*****
	*****************
	* Subempleo visible: <30h principal + desea/busca + disponible (ocupados)
	gen byte subemp_ci = .
	replace subemp_ci = 0 if emp_ci==1
	replace subemp_ci = 1 if emp_ci==1 ///
		& i25a_main_job<30 & i25a_main_job<. ///
		& (i44_did_you_look==1) ///
		& (i49_offered_a_jo==1 | i31_available<.)
		
	******************
	***nempleos_ci****
	******************
	* 1 un empleo; 2 dos o más
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if i24_paid_jobs==2
	replace nempleos_ci = 2 if i24_paid_jobs==3 
	
	********************
	***antiguedad_ci****
	********************
	gen double antiguedad_ci = . 

	replace antiguedad_ci = 0.5 if i18_start_work==1 & emp_ci==1
	replace antiguedad_ci = 2   if i18_start_work==2 & emp_ci==1
	replace antiguedad_ci = 5   if i18_start_work==3 & emp_ci==1
	replace antiguedad_ci = 9   if i18_start_work==4 & emp_ci==1
	replace antiguedad_ci = 12  if i18_start_work==5 & emp_ci==1
	replace antiguedad_ci = .   if inlist(i18_start_work,9,.) | emp_ci!=1

	****************
	***desalent_ci***
	****************
	* Usa variable oficial 'discouraged'
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (discouraged == 1 & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	*****************
	***horaspri_ci***
	*****************
	* Horas trabajadas en actividad principal (semana ref.)
	gen double horaspri_ci = .
	replace horaspri_ci = i25a_main_job if i25a_main_job<.
	replace horaspri_ci = . if emp_ci==0

	*****************
	***horastot_ci***
	*****************
	* Suma de horas principal + otras (semana ref.)
	gen double horastot_ci = .
	replace horastot_ci = i25a_main_job if i25a_main_job<.
	replace horastot_ci = horastot_ci + i25b_other_jobs if i25b_other_jobs<.
	replace horastot_ci = . if emp_ci==0 | (i25a_main_job==. & i25b_other_jobs==.)

	*******************
	***tiempoparc_ci***
	*******************
	* 1 si trabaja <30h en principal (sin requerir deseo de no ampliar horas)
	gen byte tiempoparc_ci = .
	replace tiempoparc_ci = (horaspri_ci>=1 & horaspri_ci<30) if emp_ci==1

	*******************
	***categopri_ci****
	*******************
	gen byte categopri_ci = .

	replace categopri_ci = 1 if inlist(i33_category,1,2) & emp_ci==1   // público
	replace categopri_ci = 2 if i33_category==3 & emp_ci==1            // privado
	replace categopri_ci = 3 if i33_category==5 & emp_ci==1            // empleador
	replace categopri_ci = 4 if i33_category==6 & emp_ci==1            // cuenta propia
	replace categopri_ci = 5 if inlist(i33_category,4,7) & emp_ci==1   // no remunerado

	replace categopri_ci = . if inlist(i33_category,8,9) | emp_ci!=1   // otros / no aplica

	*******************
	***categosec_ci****
	*******************
	* No hay variable explícita para categoría del empleo secundario 
	gen byte categosec_ci = .

	************
	***rama_ci**
	************
	gen byte rama_ci = .
	replace rama_ci=1 if (i62_business_act>=113 & i62_business_act<=399) & emp_ci==1
	replace rama_ci=2 if i62_business_act>=510 & i62_business_act<=999 & emp_ci==1
	replace rama_ci=3 if i62_business_act>=1000 & i62_business_act<=3399 & emp_ci==1
	replace rama_ci=4 if i62_business_act>=3500 & i62_business_act<=3999 & emp_ci==1
	replace rama_ci=5 if i62_business_act>=4100 & i62_business_act<=4399 & emp_ci==1
	replace rama_ci=6 if ((i62_business_act>=4500 & i62_business_act<=4799) | (i62_business_act>=5500 & i62_business_act<=5699)) & emp_ci==1
	replace rama_ci=7 if i62_business_act>=4900 & i62_business_act<=5399 & emp_ci==1
	replace rama_ci=8 if (i62_business_act>=6400 & i62_business_act<=6899) & emp_ci==1
	replace rama_ci=9 if ((i62_business_act>=5800 & i62_business_act<=6399) | (i62_business_act>=6900 & i62_business_act<=9999)) & emp_ci==1

	/** rama secundaria
	gen ramasec_ci=.
	replace ramasec_ci=1 if (i75_activity>=113 & i75_activity<=399) & emp_ci==1
	replace ramasec_ci=2 if i75_activity>=510 & i75_activity<=999 & emp_ci==1
	replace ramasec_ci=3 if i75_activity>=1000 & i75_activity<=3399 & emp_ci==1
	replace ramasec_ci=4 if i75_activity>=3500 & i75_activity<=3999 & emp_ci==1
	replace ramasec_ci=5 if i75_activity>=4100 & i75_activity<=4399 & emp_ci==1
	replace ramasec_ci=6 if ((i75_activity>=4500 & i75_activity<=4799) | (i75_activity>=5500 & i75_activity<=5699)) & emp_ci==1
	replace ramasec_ci=7 if i75_activity>=4900 & i75_activity<=5399 & emp_ci==1
	replace ramasec_ci=8 if (i75_activity>=6400 & i75_activity<=6899) & emp_ci==1
	replace ramasec_ci=9 if ((i75_activity>=5800 & i75_activity<=6399) | (i75_activity>=6900 & i75_activity<=9999)) & emp_ci==1
	*/
	
	*****************
	***spublico_ci***
	*****************
	gen spublico_ci=1 if ((i33_category==1 | i33_category==2) & condocup_ci==1)
	replace spublico_ci=0 if spublico_ci==. & condocup_ci==1

	**************
	***ocupa_ci***
	**************
	* Ocupación 1..9 (se copia de occgrp si compatible)
	gen byte ocupa_ci = .
	replace ocupa_ci=1 if ((i56_occupation>=2111 & i56_occupation<=3522))& emp_ci==1
	replace ocupa_ci=2 if ((i56_occupation>=1111 & i56_occupation<=1439)) & emp_ci==1
	replace ocupa_ci=3 if ((i56_occupation>=4110 & i56_occupation<=4419))& emp_ci==1
	replace ocupa_ci=4 if ((i56_occupation>=5200 & i56_occupation<=5249) | (i56_occupation>=9510 & i56_occupation<=9520)) & emp_ci==1
	replace ocupa_ci=5 if ((i56_occupation>=5110 & i56_occupation<=5169) | (i56_occupation>=5310 & i56_occupation<=5419) | (i56_occupation>=9110 & i56_occupation<=9129) | (i56_occupation>=9610 & i56_occupation<=9711)) & emp_ci==1
	replace ocupa_ci=6 if ((i56_occupation>=6110 & i56_occupation<=6349) | (i56_occupation>=9211 & i56_occupation<=9216)) & emp_ci==1
	replace ocupa_ci=7 if ((i56_occupation>=7111 & i56_occupation<=8350) | (i56_occupation>=9310 & i56_occupation<=9412))& emp_ci==1

	****************
	***tamemp_ci****
	****************
	* 1 Peq [1–5], 2 Med [6–50], 3 Gran 50+
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if i76_business_size==1 | i76_business_size==2
	replace tamemp_ci = 2 if i76_business_size==3 | i76_business_size==4
	replace tamemp_ci = 3 if i76_business_size==5

	*****************
	***cotizando_ci***
	*****************/
	gen byte cotizando_ci = .

	****************
	***instcot_ci****
	****************/
	gen byte instcot_ci = .

	****************
	***afiliado_ci***
	****************/
	gen byte afiliado_ci = .

	*****************
	***formal_ci*****
	*****************
	gen byte formal_ci = .

	**********************
	***tipocontrato_ci****
	**********************
	gen byte tipocontrato_ci = .

	replace tipocontrato_ci = 1 if i34_contract==1 & i35_duration==2 & inlist(i33_category,1,2,3,4)
	replace tipocontrato_ci = 2 if i34_contract==1 & i35_duration==1 & inlist(i33_category,1,2,3,4)
	replace tipocontrato_ci = 3 if i34_contract==2                    & inlist(i33_category,1,2,3,4)
	replace tipocontrato_ci = 0 if i34_contract==1 & missing(i35_duration) & inlist(i33_category,1,2,3,4)
	
	*************
	* pension_ci *
	*************
	* 1 = recibe empleo/seguro/pensión (pública o privada)
	generate byte pension_ci = (i42a_insurance == 1 | i42b_private == 1)

	****************
	* pensionsub_ci *
	****************
	* Pública/subsidiada
	generate byte pensionsub_ci = (i42a_insurance == 1)

	*****************
	***tipopen_ci****
	*****************
	gen byte tipopen_ci = .

	*****************
	***instpen_ci****
	*****************
	gen byte instpen_ci = .

****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	gen double ylmpri_ci = .

	* Asalariados. Usa ingreso anual del empleo principal
	replace ylmpri_ci = i79a1_main_job/12 if inlist(categopri_ci,1,2) & emp_ci==1

	* Independientes. Usa ingreso anual de negocio propio
	replace ylmpri_ci = i79b1_own_busin/12 if inlist(categopri_ci,3,4) & emp_ci==1

	* No remunerados
	replace ylmpri_ci = 0 if categopri_ci==5 & emp_ci==1

	* Filtrado de rangos. Ceros solo válidos para no remunerados
	replace ylmpri_ci = . if ylmpri_ci<0
	replace ylmpri_ci = . if ylmpri_ci==0 & !(categopri_ci==5 & emp_ci==1)
	replace ylmpri_ci = . if ylmpri_ci>=999999999/12

	* Consistencia por condición laboral
	replace ylmpri_ci = 0 if emp_ci==0

	replace ylmpri_ci = 0 if (condocup_ci==2 | condocup_ci==3) & edad_ci>=15

	************
	* ylmsec_ci *
	************
	gen double ylmsec_ci = .

	* 1) Ocupados: tomar ingreso anual del/los otros trabajos y convertir a mensual
	replace ylmsec_ci = i79a2_second_job/12 if emp_ci==1

	* 2) Filtrado de valores: excluir negativos, ceros espurios y extremos
	replace ylmsec_ci = . if ylmsec_ci<0
	replace ylmsec_ci = . if ylmsec_ci>=999999999/12

	* 3) No remunerados => 0
	* Nota: si tienes categosec_ci (categoría del empleo secundario), úsala aquí.
	* Mientras no exista, usamos tu categoría principal como respaldo.
	replace ylmsec_ci = 0 if emp_ci==1 & inlist(categopri_ci,5)

	* 4) No ocupados => 0 (regla PET; si ya tienes edad_ci puedes restringir a >=15)
	replace ylmsec_ci = 0 if emp_ci==0
	capture confirm variable edad_ci

	replace ylmsec_ci = 0 if (condocup_ci==2 | condocup_ci==3) & edad_ci>=15

	**************
	* ylmotros_ci *
	**************
	gen double ylmotros_ci = .
	
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	generate double ylnmpri_ci = .

	**************
	* ylnmsec_ci *
	**************
	generate double ylnmsec_ci = .

	****************
	* ylnmotros_ci *
	****************
	generate double ylnmotros_ci = .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi

	**********
	* ynlm_ci *
	**********
	gen double ynlm_ci = i79b2_source/12 if inrange(i79b2_source,0,999999999)

	***********
	* ynlnm_ci *
	***********
	generate double ynlnm_ci = .

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

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1, mi

	*********
	* ynlm_ch *
	*********
	bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci==1, mi

	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
		
	***************
	* ylmhopri_ci *
	***************
	generate double ylmhopri_ci = ylmpri_ci / horaspri_ci if emp == 1 & horaspri_ci > 0

	**********
	* ylmho_ci *
	**********
	generate double ylmho_ci = ylm_ci / horastot_ci if emp == 1 & horastot_ci > 0

	**************
	* nrylmpri_ci *
	**************
	gen byte nrylmpri_ci = .
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci ==1

	**************
	* nrylmpri_ch *
	**************
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .

	*************
	* remesas_ci *
	*************
	generate byte remesas_ci = .

	*************
	* remesas_ch *
	*************
	by idh_ch, sort: egen byte remesas_ch = sum(remesas_ci) if miembros_ci == 1
	 
	**********
	* ypen_ci *
	**********
	* No hay monto directo; incluido en i79b2_source (Other Sources)
	generate double ypen_ci = .

	*************
	* ypensub_ci *
	*************
	/* Monto de pensión subsidiada (no disponible en esta encuesta)
	   Se deja como missing siguiendo el manual de armonización. */
	generate double ypensub_ci = .
	
****************************
***VARIABLES DE EDUCACION***
****************************

	**************
	***aedu_ci***
	**************
	gen aedu_ci = .

	* 1. No Schooling
	replace aedu_ci = 0 if education == 1

	* 2. Incomplete Primary (0-5 años)
	replace aedu_ci = 0 if education == 2   // si quieres puedes poner 0–5 si tienes grado

	* 3. Primary completa (6 años)
	replace aedu_ci = 6 if education == 3

	* 4. Incomplete Secondary (Secundaria baja incompleta = 7–8)
	replace aedu_ci = 7 if education == 4   // asignación mínima si no hay grado

	* 5. Complete Secondary (Secundaria baja completa = 9)
	replace aedu_ci = 9 if education == 5

	* 6. University 1–2 (terciaria corta = +2 años)
	replace aedu_ci = 12 + 2 if education == 6   // 14 años

	* 7. University 3+ (grado universitario = +4 años)
	replace aedu_ci = 12 + 4 if education == 7   // 16 años

	* 8. Other tertiary institution (técnico / vocacional)
	* normalmente = terciaria corta (2 años)
	replace aedu_ci = 12 + 2 if education == 8   // 14 años

	* 9. Not stated → missing
	replace aedu_ci = . if education == 9

	* Truncar decimales (por si existieran)
	replace aedu_ci = floor(aedu_ci)
	
	**************
	***eduui_ci***
	**************
	gen eduui_ci = .

	* 1 = educación superior incompleta
	replace eduui_ci = 1 if inlist(education,6,7,8) & inlist(highest_certi,1,2,3,4)

	* 0 = educación superior completa (tiene título)
	replace eduui_ci = 0 if inlist(highest_certi,5,6,7,8,9)

	* missing resto
	replace eduui_ci = . if inlist(education,1,2,3,4,5) | highest_certi==99

	label var eduui_ci "Superior técnica/universitaria incompleta"

	**************
	***eduuc_ci***
	**************
	gen eduuc_ci = .

	* 1 = superior completa o posgrado
	replace eduuc_ci = 1 if inlist(highest_certi, 5,6,7,8,9)

	* 0 = superior no completada (nivel superior pero sin título)
	replace eduuc_ci = 0 if inlist(education,6,7,8) & inlist(highest_certi,1,2,3,4)

	* missing para resto
	replace eduuc_ci = . if inlist(education,1,2,3,4,5) | highest_certi==99

	label var eduuc_ci "Superior completa o posgrado"

	**************
	***eduac_ci***
	**************
	gen eduac_ci = .

	* 1 = educación universitaria (completa o incompleta)
	replace eduac_ci = 1 if inlist(education,6,7)
	replace eduac_ci = 1 if inlist(highest_certi,6,7)

	* 0 = educación técnica / superior no universitaria
	replace eduac_ci = 0 if inlist(highest_certi,5,8,9)

	* missing resto (ya está)
	replace eduac_ci = . if inlist(education,1,2,3,4,5) & inlist(highest_certi,1,2,3,4,99)

	label var eduac_ci "Superior universitaria (1) vs técnica (0)"

	**************
	***edupre_ci***
	**************
	gen byte edupre_ci = .

	**************
	***asiste_ci***
	**************
	gen asiste_ci = .

	**********************
	***razonesnoasis_ci***
	**********************
	gen byte razonesnoasis_ci = .

	**************
	***edupub_ci***
	**************
	gen byte edupub_ci = .
 	
****************************
***VARIABLES DE VIVIENDA***
****************************		

	***********
	***luz_ch***
	***********
	gen byte luz_ch = .
	replace luz_ch = 1 if lighting==1
	replace luz_ch = 0 if inlist(lighting,2,3,4)
	replace luz_ch = . if lighting==5 | missing(lighting)
	
	***************
	***luzmide_ch***
	***************
	gen byte luzmide_ch = .

	***************
	***combust_ch***
	***************
	gen byte combust_ch = .

	***********
	***piso_ch***
	***********
	gen piso_ch = .

	************
	***pared_ch***
	************
	gen pared_ch = .

	************
	***techo_ch***
	************
	gen techo_ch = .

	************
	***resid_ch***
	************
	gen byte resid_ch = .

	***********
	***dorm_ch***
	***********
	gen dorm_ch = .

	****************
	***cuartos_ch***
	****************
	gen cuartos_ch = .

	*************
	***cocina_ch***
	*************
	gen byte cocina_ch = .

	************
	***telef_ch***
	************
	gen byte telef_ch = .
	replace telef_ch = 1 if fixed_telephone==1
	replace telef_ch = 0 if fixed_telephone==2

	***************
	***refrig_ch***
	***************
	gen byte refrig_ch = .

	*************
	***freez_ch***
	*************
	gen byte freez_ch = .

	***********
	***auto_ch***
	***********
	gen byte auto_ch = .

	************
	***compu_ch***
	************
	gen byte compu_ch = .
	replace compu_ch = 1 if computer==1
	replace compu_ch = 0 if computer==2

	*****************
	***internet_ch***
	*****************
	gen byte internet_ch = .
	replace internet_ch = 1 if internet==1
	replace internet_ch = 0 if internet==2
		
	************
	***cel_ch***
	************
	gen byte cel_ch = .
	replace cel_ch = 0 if cellular==1
	replace cel_ch = 1 if inlist(cellular,2,3,4)

	************
	***vivi1_ch***
	************
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if inlist(dwelling, 1, 2)   // Single detached o attached = Casa
	replace vivi1_ch = 2 if dwelling == 3            // Apartment flat = Departamento
	replace vivi1_ch = 3 if inlist(dwelling, 4, 5)   // Adjunta a negocio u Otro = Otros
	replace vivi1_ch = . if dwelling == 9            // No declarado

	************
	***vivi2_ch***
	************
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if inlist(vivi1_ch, 1, 2)
	replace vivi2_ch = 0 if vivi1_ch == 3
	
	*****************
	***viviprop_ch***
	*****************
	gen byte viviprop_ch = .
	replace viviprop_ch = 1 if tenure == 1           // Propia (se asume totalmente pagada)
	replace viviprop_ch = 0 if tenure == 2           // Alquilada
	replace viviprop_ch = 3 if tenure == 3           // Ocupada / cedida / de facto
	replace viviprop_ch = . if tenure == 9           // No sabe / no responde

	****************
	***vivitit_ch***
	****************
	gen byte vivitit_ch = .

	****************
	***vivialq_ch***
	****************
	gen double vivialq_ch = .

	*********************
	***vivialqimp_ch***
	*********************
	gen double vivialqimp_ch = .

****************************
***VARIABLES DE WASH***
****************************

	**************
	***aguared_ch***
	**************
	gen byte aguared_ch = .
	replace aguared_ch = 1 if water_supply==1
	replace aguared_ch = 0 if inlist(water_supply,2,3,4)
	replace aguared_ch = . if water_supply==5 | missing(water_supply)

	***********************
	***aguafconsumo _ch***
	***********************
	gen byte aguafconsumo_ch = .

	********************
	***aguafuente_ch***
	********************
	* 1..10 = categorías JMP para fuente general | . = no está
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1  if water_supply==1                 // piped
	replace aguafuente_ch = 7  if water_supply==2                 // private not piped -> otra mejorada (proxy)
	replace aguafuente_ch = 2  if water_supply==3                 // public well/tank/pump -> standpipe (proxy)
	replace aguafuente_ch = 10 if inlist(water_supply,4,5,9) | missing(water_supply) 

	******************
	***aguadist_ch***
	******************
	* 0 NS; 1 dentro; 2 predio; 3 fuera del terreno
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if water_supply==1
	replace aguadist_ch = 1 if water_supply==2
	replace aguadist_ch = 3 if water_supply==3
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	*******************
	***aguadisp1_ch***
	*******************
	* 1 = suficiente | 2 = no suficiente | 9 = no existe la pregunta
	* Si no está la pregunta → 9
	gen byte aguadisp1_ch = 9

	*******************
	***aguadisp2_ch***
	*******************
	* 1 = < mitad del tiempo | 2 = > mitad | 3 = sin cortes | 9 = no existe la pregunta
	* Si no está la pregunta → 9
	gen byte aguadisp2_ch = 9

	******************
	***aguatrat_ch***
	******************
	* 1 = trata | 0 = no trata | . = no está
	gen byte aguatrat_ch = .

	******************
	***aguamala_ch***
	******************
	* 0 = mejorada | 1 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7 & aguafuente_ch!=.
	replace aguamala_ch = 1 if aguafuente_ch>7  & aguafuente_ch!=10 & aguafuente_ch!=.

	**********************
	***aguamejorada_ch***
	**********************
	* 1 = mejorada | 0 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 1 if aguafuente_ch<=7 & aguafuente_ch!=.
	replace aguamejorada_ch = 0 if aguafuente_ch>7  & aguafuente_ch!=10 & aguafuente_ch!=.

	******************
	***aguamide_ch***
	******************
	* 1 = con medidor | 0 = sin medidor | . = no está
	gen byte aguamide_ch = .

	************
	***bano_ch***
	************
	* 0 = sin inst. | 1 = red | 2 = fosa | 3 = letrina mejorada | 4 = descarga a cuerpo de agua/suelo
	* 5 = no mejorada | 6 = no clasificable | . = no está
	gen byte bano_ch = .

	**************
	***banoex_ch***
	**************
	* 1 = uso exclusivo | 0 = compartido | . = no está
	gen byte banoex_ch = .

	***************
	***sinbano_ch***
	***************
	* 0 = tiene baño | 1 = usa público/vecino | 2 = defecación al aire libre | 3 = no especifica | . = no está
	gen sinbano_ch = .

	**********************
	***banomejorado_ch***
	**********************
	* 1 = mejorado | 0 = no mejorado | 2 = no clasificable
	* Si no hay info de bano_ch → 2
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch = 0 if (bano_ch==0 | bano_ch>=4) & bano_ch!=6	
		
****************************
*** VARIABLES DE MIGRACIÓN***
****************************

	*****************
	*** migrante_ci **
	*****************
	gen byte migrante_ci = .
	replace migrante_ci = 0 if where_born == 1    // Bahamas
	replace migrante_ci = 1 if where_born == 2    // Abroad
	replace migrante_ci = . if where_born == 9    // Not Stated

	******************
	* migrantiguo5_ci *
	******************
	* Migrante en los últimos 5 años
	gen byte migrantiguo5_ci = .

	****************
	* miglac_ci *
	****************
	*----------------------------------------------------
	* miglac_ci
	* 1 = migrante de América Latina o el Caribe
	* 0 = migrante de fuera de la región
	* . = no migrante o no clasificable
	*
	* Proxy: citizenship (solo para migrantes)
	*   3 Haiti, 4 Jamaica, 5 Other Caribbean → LAC
	*   2 United States → no LAC
	*   1 Bahamas o 6 Other → no clasificable
	*----------------------------------------------------
	gen byte miglac_ci = .
	replace miglac_ci = 1 if migrante_ci==1 & inlist(citizenship,3,4,5)
	replace miglac_ci = 0 if migrante_ci==1 & citizenship==2
	replace miglac_ci = . if migrante_ci==1 & inlist(citizenship,1,6)
	replace miglac_ci = . if migrante_ci==0 | migrante_ci==.
		
****************************
*** VARIABLES EXTERNAS  ***
****************************

	****************
	* tipo_bienestar *
	****************
	gen byte tipo_bienestar = .

	****************
	* pobre_ine_ci *
	****************
	gen byte pobre_ine_ci = .

	****************
	* bienestar_agregado *
	****************
	gen bienestar_agregado = .

	****************
	* lpe_ci *
	****************
	gen lpe_ci= . 

	****************
	* ln_ci *
	****************
	gen ln_ci = .
		
	
/*	
 order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad 
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci  /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch  ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  nmiembros_sph_ch yneto_pc_ch bene_cash_ch pensionsub_ch   /// Protección social 
          ynlm_publico_ch ynlm_privado_ch ynlm_privado_ci ynlm_publico_ci  /// Protección social ingresos
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa
*/	

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
 
 
saveold "`base_out'", version(12) replace

cap log close
