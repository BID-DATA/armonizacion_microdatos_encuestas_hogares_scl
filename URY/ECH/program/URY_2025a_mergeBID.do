* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2021-2025
Autores: Matias Rodriguez SCL 
Última versión: 04/24/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"
 
local PAIS URY
local ENCUESTA ECH
local ANIO 2025
local RONDA a
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/


import delimited "`base_in'\ECH_2025_implantacion.csv", encoding(UTF-8) 



/***************************************************************************
  III. Guardar la base
****************************************************************************/
save "`base_out'", replace

log close








