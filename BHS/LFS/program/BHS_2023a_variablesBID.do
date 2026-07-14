
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
local ANO "2023"
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
	gen zona_c = .

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
	gen byte civil_ci = .

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci     = (relacion_ci==1)
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

	replace categoinac_ci = 1 if condocup_ci==3 & major_activity==6
	replace categoinac_ci = 2 if condocup_ci==3 & major_activity==5
	replace categoinac_ci = 3 if condocup_ci==3 & major_activity==4
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
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
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
	replace durades_ci = 0.5 if available_since==1 & condocup_ci==2
	replace durades_ci = 2   if available_since==2 & condocup_ci==2
	replace durades_ci = 4.5 if available_since==3 & condocup_ci==2
	replace durades_ci = 9   if available_since==4 & condocup_ci==2
	replace durades_ci = 12  if available_since==5 & condocup_ci==2
	replace durades_ci = .   if inlist(available_since,6,9,.) | condocup_ci!=2
	
	****************
	***pea_ci*******
	****************/
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)

	*****************
	***subemp_ci*****
	*****************
	* Subempleo visible: <30h principal + desea/busca + disponible (ocupados)
	gen byte subemp_ci = .
			
	******************
	***nempleos_ci****
	******************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if inrange(income_source_njobs,1,1)
	replace nempleos_ci = 2 if income_source_njobs>=2 & income_source_njobs<. & income_source_njobs<20

	********************
	***antiguedad_ci****
	********************
	gen double antiguedad_ci = .

	replace antiguedad_ci = 0.5 if when_did_you_start_working_a==1 & emp_ci==1
	replace antiguedad_ci = 2   if when_did_you_start_working_a==2 & emp_ci==1
	replace antiguedad_ci = 5   if when_did_you_start_working_a==3 & emp_ci==1
	replace antiguedad_ci = 9   if when_did_you_start_working_a==4 & emp_ci==1
	replace antiguedad_ci = 12  if when_did_you_start_working_a==5 & emp_ci==1
	replace antiguedad_ci = .   if inlist(when_did_you_start_working_a,9,.) | emp_ci!=1

	****************
	***desalent_ci***
	****************
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
	gen double horaspri_ci = .

	*****************
	***horastot_ci***
	*****************
	gen double horastot_ci = .

	*******************
	***tiempoparc_ci***
	*******************
	gen byte tiempoparc_ci = .

	*******************
	***categopri_ci****
	*******************
	gen byte categopri_ci = .

	*******************
	***categosec_ci****
	*******************
	gen byte categosec_ci = .

	************
	***rama_ci**
	************
	gen byte rama_ci = .

	*****************
	***spublico_ci***
	*****************
	gen byte spublico_ci = .
	
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci = .

	****************
	***tamemp_ci****
	****************
	gen byte tamemp_ci = .

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

	*****************
	***pension_ci****
	*****************
	gen byte pension_ci = .

	********************
	***pensionsub_ci****
	********************
	gen byte pensionsub_ci = .

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
	replace ylmpri_ci = main_job_income/12 if emp_ci==1

	* Independientes. Usa ingreso anual de negocio propio
	replace ylmpri_ci = own_bus_income/12 if emp_ci==1

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
	replace ylmsec_ci = secd_job_income/12 if emp_ci==1

	* 2) Filtrado de valores: excluir negativos, ceros espurios y extremos
	replace ylmsec_ci = . if ylmsec_ci<0
	replace ylmsec_ci = . if ylmsec_ci>=999999999/12

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
	gen double ynlm_ci = oth_sour_income/12 if inrange(oth_sour_income,0,999999999)

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

	**********
	* aedu_ci
	**********
	rename what_is_your_highest_level education
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

	replace aedu_ci = . if education == 9

	* Truncar decimales (por si existieran)
	replace aedu_ci = floor(aedu_ci)

	**********
	* eduuc_ci
	**********	
	gen eduuc_ci = .

	* 1 = superior completa (tecnica, universitaria o posgrado)
	replace eduuc_ci = 1 if inlist(what_is_your_highest_certi,5,6,7,8,9)

	* 0 = nivel superior pero incompleto (no tiene título)
	replace eduuc_ci = 0 if inlist(education,6,7,8) ///
		& inlist(what_is_your_highest_certi,1,2,3,4)

	**********
	* eduui_ci
	**********
	gen eduui_ci = .

	* 1 = superior incompleta
	replace eduui_ci = 1 if inlist(education,6,7,8) ///
		& inlist(what_is_your_highest_certi,1,2,3,4)

	* 0 = superior completa (técnica o universitaria)
	replace eduui_ci = 0 if inlist(what_is_your_highest_certi,5,6,7,8,9)

	**************
	***eduac_ci***
	**************
	gen eduac_ci = .

	* 1 = universitaria (completa o incompleta)
	replace eduac_ci = 1 if inlist(education,6,7)
	replace eduac_ci = 1 if inlist(what_is_your_highest_certi,6,7)

	* 0 = técnica superior
	replace eduac_ci = 0 if inlist(what_is_your_highest_certi,5,8,9)

	* missing resto
	replace eduac_ci = . if inlist(education,1,2,3,4,5) ///
		& inlist(what_is_your_highest_certi,1,2,3,4)

	**************
	***asiste_ci***
	**************
	gen asiste_ci = .

	**************
	***razonesnoasis_ci***
	**************
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
	capture confirm variable fixed_telephone
	if _rc==0 replace telef_ch = (fixed_telephone==1) if fixed_telephone<.

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
	capture confirm variable computer
	if _rc==0 replace compu_ch = (computer==1) if computer<.

	*****************
	***internet_ch***
	*****************
	gen byte internet_ch = .
	capture confirm variable internet
	if _rc==0 replace internet_ch = 1 if internet==1
	capture confirm variable away_from_home

	************
	***vivi1_ch***
	************
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if inlist(dwelling,1,2)     // Casa
	replace vivi1_ch = 2 if dwelling==3               // Departamento
	replace vivi1_ch = 3 if inlist(dwelling,4,5)      // Otro

	*****************
	***viviprop_ch***
	*****************
	gen byte viviprop_ch = .

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

	***********************
	***aguafconsumo _ch***
	***********************
	gen byte aguafconsumo_ch = 0

	********************
	***aguafuente_ch***
	********************
	gen byte aguafuente_ch = .

	******************
	***aguadist_ch***
	******************
	* Si no está la pregunta → 0
	gen byte aguadist_ch = 0

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
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if inlist(aguafuente_ch,1,2,3,4,5,6,7)
	replace aguamala_ch = 1 if inlist(aguafuente_ch,8,9)
	replace aguamala_ch = 2 if aguafuente_ch==10 | missing(aguafuente_ch)

	**********************
	***aguamejorada_ch***
	**********************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 1 if inlist(aguafuente_ch,1,2,3,4,5,6,7)
	replace aguamejorada_ch = 0 if inlist(aguafuente_ch,8,9)
	replace aguamejorada_ch = 2 if aguafuente_ch==10 | missing(aguafuente_ch)

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
	
****************************
*** VARIABLES DE MIGRACIÓN***
****************************

	*****************
	*** migrante_ci **
	*****************
	gen byte migrante_ci = .

	******************
	* migrantiguo5_ci *
	******************
	* Migrante en los últimos 5 años
	gen byte migrantiguo5_ci = .

	****************
	* miglac_ci *
	****************
	* Migrante internacional (fuera de LAC → 1)
	gen byte miglac_ci = .
	
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
