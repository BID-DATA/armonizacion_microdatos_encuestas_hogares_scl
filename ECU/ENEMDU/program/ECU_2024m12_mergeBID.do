* (Versión Stata 18)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2024
Autores: Oscar Jaramillo SPL / Jillie Chang SCL 
Última versión: 07JUL2015
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
local ANIO 2024
local RONDA m12

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig\\" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/

* Base de hogares

use "`base_in'\enemdu_vivienda_hogar_2024_12.dta", clear
duplicates report id_vivienda id_hogar 
/*--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        27610             0
--------------------------------------*/

* Sort de base
use "`base_in'\enemdu_persona_2024_12.dta", clear
duplicates report id_vivienda id_hogar id_persona
/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        27610             0
--------------------------------------*/
tostring ciudad, replace

merge m:1 id_vivienda id_hogar  using "`base_in'\enemdu_vivienda_hogar_2024_12.dta"

/****************************************************************************
  III. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/
tab _merge
drop if _merge <3
drop _merge

duplicates report id_vivienda id_hogar id_persona
/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        27610             0
--------------------------------------*/

/***************************************************************************
  IV. Guardar la base
****************************************************************************/
compress
save "`base_out'", replace

log close



