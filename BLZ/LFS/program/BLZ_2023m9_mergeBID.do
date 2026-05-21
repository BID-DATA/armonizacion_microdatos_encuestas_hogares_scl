* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2021-2025
Autores:Lina Arias - PEC SCL
Última versión: 05/19/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"
 
local PAIS BLZ
local ENCUESTA LFS
local ANIO 2023
local RONDA m9
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Importar spss
*****************************************************************************/
import spss "`base_in'\Sept_2021 - Microdata.sav", clear // 7480 obs
rename *, lower
duplicates report _v1 hl3 hl4new hl5
drop if ind_weight==. //847 obs
/***************************************************************************
  III. Guardar la base
****************************************************************************/
saveold "`base_out'", version(12) replace

log close
