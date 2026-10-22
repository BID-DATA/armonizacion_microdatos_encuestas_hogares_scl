* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2021-2025
Autores: Matias Rodriguez SCL 
Última versión: 02/19/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"
 
local PAIS ECU
local ENCUESTA ENEMDU
local ANIO 2020
local RONDA m12
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/

* Base de hogares
import spss "`base_in'\enemdu_vivienda_hogar_`ANIO'_12.sav", clear
destring ciudad, replace
duplicates r id_vivienda id_hogar

/*--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |                     0
--------------------------------------*/

sort area estrato upm vivienda hogar 
capture ssc install renlabv
renlabv
saveold "`base_in'\hogares.dta",  version(12) replace


* Base de personas
import spss "`base_in'\enemdu_persona_`ANIO'_12.sav", clear
duplicates report id_vivienda id_hogar id_persona

/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |                     0
--------------------------------------*/

sort area estrato upm vivienda hogar p01
capture ssc install renlabv
renlabv
saveold "`base_in'\miembros.dta", version(12) replace


/****************************************************************************
  III. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/
merge m:1 area estrato upm  vivienda hogar using "`base_in'\hogares.dta"
duplicates report id_vivienda id_hogar id_persona

/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |                     0
--------------------------------------*/

drop _merge


/***************************************************************************
  IV. Guardar la base
****************************************************************************/
saveold "`base_out'", version(12) replace

log close

