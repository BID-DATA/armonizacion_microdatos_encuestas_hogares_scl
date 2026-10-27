* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: BOL
Año: 2006
Autores: Matias Rodriguez SCL 
Última versión: 10/15/2026
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
local ANIO 2006
local RONDA a
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Merge
****************************************************************************/

import spss using "`base_in'\base_2026\H_2006_TERCEROS.sav", clear
sort numero, stable
renlabv

save "`base_in'\base_2026\H2006.dta", replace


import spss using "`base_in'\base_2026\P_2006_TERCEROS.sav", clear
sort numero, stable
renlabv

save "`base_in'\base_2026\P2006.dta", replace

*Merge 

merge m:1 numero using "`base_in'\base_2026\H2006.dta"
sort numero
tab _merge
drop _merge
save "`base_out'", replace 

