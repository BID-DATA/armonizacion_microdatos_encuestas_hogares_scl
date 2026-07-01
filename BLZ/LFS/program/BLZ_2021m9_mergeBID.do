* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: BLZ
Año: 2021
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
local ANIO 2021
local RONDA m9
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Importar spss
*****************************************************************************/
import spss "`base_in'\Sept_2021- Microdata.sav", clear // 9,482 obs
rename *, lower
drop if ind_weight==. //17
/***************************************************************************
  III. Guardar la base
****************************************************************************/
saveold "`base_out'", version(12) replace

log close
