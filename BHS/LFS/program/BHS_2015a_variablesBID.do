
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

	*****************
	***internet_ch***
	*****************
	gen byte internet_ch = .

	************
	***vivi1_ch***
	************
	gen byte vivi1_ch = .

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
	* 1 = por red | 0 = fuera de red | . = no está
	gen byte aguared_ch = .

	***********************
	***aguafconsumo _ch***
	***********************
	* 0 = la encuesta NO pregunta agua para beber
	* 1..10 = categorías JMP (si existiera la pregunta)
	* Aquí, como no está en la base → asignamos 0 (no pregunta)
	gen byte aguafconsumo_ch = 0

	********************
	***aguafuente_ch***
	********************
	* 1..10 = categorías JMP para fuente general | . = no está
	gen byte aguafuente_ch = .

	******************
	***aguadist_ch***
	******************
	* 0 = no se especifica | 1 = dentro | 2 = en el lote | 3 = fuera del lote
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
	* 0 = mejorada | 1 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamala_ch = 2

	**********************
	***aguamejorada_ch***
	**********************
	* 1 = mejorada | 0 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamejorada_ch = 2

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
