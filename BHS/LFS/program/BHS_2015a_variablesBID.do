
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

global ruta = "${surveysFolder}"

local PAIS BHS
local ENCUESTA LFS
local ANO "2014"
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
	
	********************
	*** region_BID_c ****
	********************
	gen region_BID_c=2

	********************
	*** region_BID_c ****
	********************
	gen region_c = island
	
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
	capture drop idh_ch idp_ci
	* Use available household keys: island + hhno uniquely identify a household; ind_no is person within HH.
	capture confirm variable island
	local has_island = (_rc==0)
	capture confirm variable hhno
	local has_hh = (_rc==0)
	capture confirm variable ind_no
	local has_ind = (_rc==0)

	* Build household id with available pieces
	if `has_island' & `has_hh' {
		egen long __idh = group(island hhno)
	}
	else if `has_hh' {
		egen long __idh = group(hhno)
	}
	else if `has_island' {
		egen long __idh = group(island)
	}
	else {
		gen long __idh = _n
	}

	tostring __idh, replace
	rename __idh idh_ch
	
	******************
	*** idp_ci *******
	******************
	if `has_ind' {
		egen str20 idp_ci = concat(idh_ch ind_no), punct("_")
	}
	else {
		tostring _n, gen(__nstr)
		egen str20 idp_ci = concat(idh_ch __nstr), punct("_")
		drop __nstr
	}

	duplicates report idh_ch idp_ci
	
	***********
	*factor_ci* 
	***********
	capture drop factor_ci factor_ch
	capture confirm variable weights
	local has_pwt = (_rc==0)
	capture confirm variable hweights
	local has_hhwt = (_rc==0)

	if `has_pwt' {
		clonevar factor_ci = weights
	}
	else if `has_hhwt' {
		clonevar factor_ci = hweights
	}
	else {
		gen double factor_ci = 1
	}

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	if `has_hhwt' {
		clonevar factor_ch = hweights
	}
	else {
		clonevar factor_ch = factor_ci
	}

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
	capture drop relacion_ci
	capture confirm variable rel_head
	if _rc==0 {
		gen byte relacion_ci = .
		replace relacion_ci = 1 if rel_head==1
		replace relacion_ci = 2 if rel_head==2
		replace relacion_ci = 3 if rel_head==3
		replace relacion_ci = 4 if inlist(rel_head,4,7,8,9,10,11,12,13)   // other relatives (broad catch)
		replace relacion_ci = 5 if inlist(rel_head,5,14,15,16,17,18,19,20) // non-relatives/boarders/guests
		replace relacion_ci = 6 if rel_head==6                               // domestic employee
	}
	else {
		gen byte relacion_ci = .
	}

	**************
	*Estado Civil*
	**************
	gen byte civil_ci = .

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci = (relacion_ci==1)
	replace jefe_ci = . if relacion_ci==.	
	
	**************
	*nconyuges_ch*
	**************
	bysort idh_ch: egen byte nconyuges_ch   = total(relacion_ci==2)
	
	***********
	*nhijos_ch*
	***********
	bysort idh_ch: egen byte nhijos_ch      = total(relacion_ci==3)

	**************
	*notropari_ch*
	**************
	bysort idh_ch: egen byte notropari_ch   = total(relacion_ci==4)

	****************
	*notronopari_ch*
	****************
	bysort idh_ch: egen byte notronopari_ch = total(relacion_ci==5)

	************
	*nempdom_ch*
	************
	bysort idh_ch: egen byte nempdom_ch     = total(relacion_ci==6)

	foreach v in nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch {
		replace `v' = . if relacion_ci==.
	}	
	
	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch = 2 if (nhijos_ch>0 | nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
	replace clasehog_ch = 3 if notropari_ch>0  & notronopari_ch==0
	replace clasehog_ch = 4 if ( (nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & notronopari_ch>0 )
	replace clasehog_ch = 5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
	
	**************
	*nmiembros_ch*
	**************
	bysort idh_ch: egen byte nmiembros_ch = total(inrange(relacion_ci,1,5))

	*************
	*nmayor21_ch*
	*************
	bysort idh_ch: egen byte nmayor21_ch  = total(inrange(relacion_ci,1,5) & edad_ci>=21 & edad_ci!=.)

	*************
	*nmenor21_ch*
	*************
	bysort idh_ch: egen byte nmenor21_ch  = total(inrange(relacion_ci,1,5) & edad_ci<21)

	*************
	*nmayor65_ch*
	*************
	bysort idh_ch: egen byte nmayor65_ch  = total(inrange(relacion_ci,1,5) & edad_ci>=65 & edad_ci!=.)

	************
	*nmenor6_ch*
	************
	bysort idh_ch: egen byte nmenor6_ch   = total(inrange(relacion_ci,1,5) & edad_ci<6)

	************
	*nmenor1_ch*
	************
	bysort idh_ch: egen byte nmenor1_ch   = total(inrange(relacion_ci,1,5) & edad_ci<1)

	*************
	*miembros_ci*
	*************
	capture drop miembros_ci
	gen byte miembros_ci = (relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci = . if relacion_ci==.

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	gen byte afro_ci = .
	gen byte ind_ci = .
	gen byte noafroind_ci = .
	gen byte afro_ch = .
	gen byte ind_ch  = .
	gen byte noafroind_ch = .
	gen byte afroind_ci = .
	gen byte afroind_ch = .
	
*******************************************************
***        VARIABLES DE DISCAPACIDAD (WG)           ***
*******************************************************

	gen byte dis_ci = .
	gen byte disWG_ci = .
	gen byte BHS_dis_ci = dis_ci
	bysort idh_ch: egen byte dis_ch = max(dis_ci)

	
**********************************
***VARIABLES DE MERCADO LABORAL***
**********************************

	*************
	*condocup_ci*
	*************
	* Grupo de referencia: personas entrevistadas (se controla edad mínima).
	* 1 Ocupado | 2 Desocupado | 3 Inactivo | 4 Menor edad límite
	gen byte condocup_ci = .
	* Ocupado: trabajó ≥1h o ausente con vínculo
	replace condocup_ci = 1 if (anywork==1) ///
		| (temporarily_abse==1 & (i15_expect_retur==1| i17_date_retur==1))
	* Desocupado: no ocupado + buscó (acciones) + disponible
	replace condocup_ci = 2 if condocup_ci==. & edad_ci>=15 ///
		& ( i44_did_you_look==1 ///
			| i50a_govt==1 | i50b_private==1 | i50c_person==1 ///
			| i50d_ads==1  | i50e_inquired==1| i50f_business==1 | i50g_other==1) ///
		& ( i49_offered_a_jo==1 | i31_available<. )
	* Inactivo
	replace condocup_ci = 3 if condocup_ci==. & edad_ci>=15
	* Menor edad
	replace condocup_ci = 4 if edad_ci<15

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
	replace categoinac_ci = 4 if condocup_ci==3 & inlist(i43_activity,3,7,9)

	****************
	***emp_ci*******
	****************
	* 1=Ocupado; 0=No ocupado; . = missing original
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci==1) if condocup_ci<.

	****************
	***desemp_ci****
	****************
	* 1=Desocupado; 0=No desocupado; . = missing
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci==2) if condocup_ci<.
		
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
	* Duración del desempleo (meses) — i51_how_long_lon (semanas)
	gen double durades_ci = .
	replace durades_ci = i51_how_long_lon*52/12 if condocup_ci==2 & i51_how_long_lon<.

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
	replace nempleos_ci = 1 if i24_paid_jobs==1
	replace nempleos_ci = 2 if i24_paid_jobs>=2 & i24_paid_jobs<.	

	********************
	***antiguedad_ci****
	********************
	gen double antiguedad_ci = .

	local SURVEY_YEAR = 2015

	replace antiguedad_ci = `SURVEY_YEAR' - i18_start_work ///
		if emp_ci==1 & inrange(i18_start_work, 1900, `SURVEY_YEAR')  // año plausible

	replace antiguedad_ci = 0 if emp_ci==1 & antiguedad_ci<1 & antiguedad_ci!=.
	replace antiguedad_ci = . if emp_ci==1 & (antiguedad_ci<0 | antiguedad_ci>80)

	replace antiguedad_ci = . if emp_ci==0

	****************
	***desalent_ci***
	****************
	* Usa variable oficial 'discouraged'
	gen byte desalent_ci = .
	replace desalent_ci = 1 if discouraged==1
	replace desalent_ci = 0 if discouraged!=. & discouraged!=1

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
	* 0 Otra | 1 Patrón | 2 Cuenta propia | 3 Asalariado | 4 No remunerado
	gen byte categopri_ci = .
	replace categopri_ci = i33_category if emp_ci==1 & inrange(i33_category,1,4)
	replace categopri_ci = 0 if emp_ci==1 & missing(categopri_ci)

	*******************
	***categosec_ci****
	*******************
	* No hay variable explícita para categoría del empleo secundario → missing
	gen byte categosec_ci = .

	************
	***rama_ci**
	************
	* Rama 1..10 (se copia de indgrp si compatible)
	gen byte rama_ci = .
	replace rama_ci = indgrp if emp_ci==1 & inrange(indgrp,1,10)

	*****************
	***spublico_ci***
	*****************
	* 1 si rama_ci==10 (Gobierno)
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci==1 & rama_ci==10
	replace spublico_ci = 0 if emp_ci==1 & rama_ci!=10 & rama_ci!=.

	**************
	***ocupa_ci***
	**************
	* Ocupación 1..9 (se copia de occgrp si compatible)
	gen byte ocupa_ci = .
	replace ocupa_ci = occgrp if emp_ci==1 & inrange(occgrp,1,9)

	****************
	***tamemp_ci****
	****************
	* 1 Peq [1–5], 2 Med [6–50], 3 Gran 50+
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if emp_ci==1 & i68_business_size>=1 & i68_business_size<=5
	replace tamemp_ci = 2 if emp_ci==1 & i68_business_size>=6 & i68_business_size<=50
	replace tamemp_ci = 3 if emp_ci==1 & i68_business_size>50

	*****************
	***cotizando_ci***
	*****************/
	* Proxy: National Insurance (i42a_insurance)
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if emp_ci==1 & i42a_insurance==1
	replace cotizando_ci = 0 if emp_ci==1 & i42a_insurance==0

	****************
	***instcot_ci****
	****************/
	* 1 National Insurance; 2 Privado
	gen byte instcot_ci = .
	replace instcot_ci = 1 if emp_ci==1 & i42a_insurance==1
	replace instcot_ci = 2 if emp_ci==1 & i42b_private==1

	****************
	***afiliado_ci***
	****************/
	* Proxy de afiliación (mismo indicador de NI)
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if emp_ci==1 & i42a_insurance==1
	replace afiliado_ci = 0 if emp_ci==1 & i42a_insurance==0

	*****************
	***formal_ci*****
	*****************
	* 1 si cotiza o (proxy) afiliado; 0 si no cotiza
	gen byte formal_ci = .
	replace formal_ci = 1 if emp_ci==1 & (cotizando_ci==1 | afiliado_ci==1)
	replace formal_ci = 0 if emp_ci==1 & cotizando_ci==0

	**********************
	***tipocontrato_ci****
	**********************
	* Asalariados (i33_category==3): 1 Permanente | 2 Temporal | 3 Sin contrato | 0 Con contr. s/ discr.
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if emp_ci==1 & i33_category==3 & i34_contract==1 & (i35_duration==0 | i35_duration==.)
	replace tipocontrato_ci = 2 if emp_ci==1 & i33_category==3 & i34_contract==1 &  i35_duration==1
	replace tipocontrato_ci = 3 if emp_ci==1 & i33_category==3 & i34_contract==0

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
***VARIABLES DE EDUCACION***
****************************

	gen byte aedu_ci = education
	gen byte eduui_ci = .
	gen byte eduuc_ci = .
	gen byte eduac_ci = .
	gen byte edupre_ci = .
	gen byte asispre_ci = .
	gen byte asiste_ci = .
	gen byte pqnoasis1_ci = .
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
    replace telef_ch = (fixed_telephone==1) if fixed_telephone<.

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
    replace compu_ch = (computer==1) if computer<.

	*****************
	***internet_ch***
	*****************
	gen byte internet_ch = .
	capture confirm variable internet
	if _rc==0 {
		replace internet_ch = 1 if internet==1
	}
	capture confirm variable home_internet
	if _rc==0 {
		replace internet_ch = 1 if home_internet>0 & home_internet<.
	}
	capture confirm variable away_from_home
	if _rc==0 {
		replace internet_ch = 1 if away_from_home>0 & away_from_home<.
	}
	replace internet_ch = 0 if internet_ch==. & ///
		( (internet<.) | (home_internet<.) | (away_from_home<.) )
		
	************
	***vivi1_ch***
	************
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if inlist(dwelling,1,2)
	replace vivi1_ch = 2 if dwelling==3
	replace vivi1_ch = 3 if inlist(dwelling,4,5)
	
	*****************
	***viviprop_ch***
	*****************
	gen byte viviprop_ch = .
	replace viviprop_ch = 1 if tenure==1
	replace viviprop_ch = 3 if tenure==2
	replace viviprop_ch = 0 if tenure==3
	replace viviprop_ch = . if tenure==9 | missing(tenure)
	
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
	gen byte aguafconsumo_ch = 0

	********************
	***aguafuente_ch***
	********************
	* 1..10 = categorías JMP para fuente general | . = no está
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1  if water_supply==1
	replace aguafuente_ch = 5  if water_supply==2   // asumimos pozo/cisterna privada protegida (ajustar si codebook dice lluvia=6)
	replace aguafuente_ch = 3  if water_supply==3
	replace aguafuente_ch = 10 if water_supply==4
	replace aguafuente_ch = .  if water_supply==5 | missing(water_supply)

	******************
	***aguadist_ch***
	******************
	* 0 = no se especifica | 1 = dentro | 2 = en el lote | 3 = fuera del lote
	* Si no está la pregunta → 0
	gen byte aguadist_ch = 0
	replace aguadist_ch = 1 if water_supply==1
	replace aguadist_ch = 2 if water_supply==2
	replace aguadist_ch = 3 if inlist(water_supply,3,4)
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
	replace aguamala_ch = 0 if inlist(aguafuente_ch,1,2,3,4,5,6,7)   // “buena”
	replace aguamala_ch = 1 if inlist(aguafuente_ch,8,9)             // “mala”
	replace aguamala_ch = 2 if aguafuente_ch==10 | missing(aguafuente_ch)

	**********************
	***aguamejorada_ch***
	**********************
	* 1 = mejorada | 0 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 1 if inlist(aguafuente_ch,1,2,3,4,5,6,7)  // mejorada
	replace aguamejorada_ch = 0 if inlist(aguafuente_ch,8,9)            // no mejorada
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
	replace banomejorado_ch = 1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch = 0 if (bano_ch==0 | bano_ch>=4) & bano_ch!=6	
		
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
	gen byte tipo_bienestar = 1

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
		

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
 
saveold "`base_out'", version(12) replace

cap log close
