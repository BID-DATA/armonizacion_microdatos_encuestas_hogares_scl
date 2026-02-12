* (Versión Stata 18)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2025
Autores: Oscar Jaramillo SPL / Matias Rodriguez SCL 
Última versión: 02/02/2026
División: SPL/SCL y SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"
 
local PAIS ECU
local ENCUESTA ENEMDU
local ANIO 2025
local RONDA m12
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig\1_BDD_ENEMDU_2025_12_SPSS" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/

* Base de hogares
import spss "`base_in'\enemdu_vivienda_hogar_2025_12.sav", clear
tostring ciudad, replace
id_vivienda id_hogar
/*--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        8748             0
--------------------------------------*/
sort area estrato upm vivienda hogar 
capture ssc install renlabv
renlabv
saveold "`base_in'\hogares.dta",  version(12) replace


* Base de personas
import spss "`base_in'\enemdu_persona_2025_12.sav", clear
tostring ciudad, replace
duplicates report id_vivienda id_hogar id_persona
/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        27880             0
--------------------------------------*/

capture ssc install renlabv
renlabv
sort area estrato upm vivienda hogar p01
saveold "`base_in'\miembros.dta", version(12) replace


/****************************************************************************
  III. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/
merge m:1 area estrato upm  vivienda hogar using "`base_in'\hogares.dta"
drop _merge


duplicates report id_vivienda id_hogar id_persona
/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        27880             0
--------------------------------------*/

/***************************************************************************
  IV. Guardar la base
****************************************************************************/
*destring fexp ingpc,  dpcomma replace
*destring *, replace
saveold "`base_out'", version(12) replace

log close









