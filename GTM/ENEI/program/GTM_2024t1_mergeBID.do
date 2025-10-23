* (Version Stata 17)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*

local PAIS GTM
local ENCUESTA ENEIC
local ANO "2024"
local ronda t1

global ruta = "${surveysFolder}\\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_orig"
display "$ruta"

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
display "`log_file'"

local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"
display "`base_out'"

capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Guatemala
Encuesta: ENEIC
Round: Octubre
Autores: Mélany Gualavisí
Última versión: Juan Perdomo
Fecha última modificación: Octubre 2025

							SCL/LMK - IADB
****************************************************************************/

*1. Import original dataset Excel/SPSS and save it as dta
*Excel: import excel "$ruta\ENEI-1-2022_HOGARES.xlsx", sheet("Sheet1") firstrow clear case(lower)

import spss "$ruta\Hogares_ENEIC_IV 2024.sav" , clear
rename FACTOR factor_h
*label values * // se remueven labels porque hay conflicto con base a nivel de peronas
save "$ruta\ENEIC-1-2024_HOGARES.dta", replace 

import spss "$ruta\Personas_ENEIC_IV 2024.sav",clear
rename FACTOR factor_p
save "$ruta\ENEIC-1-2024_PERSONAS.dta", replace

*2. Merge

use "$ruta\ENEIC-1-2024_PERSONAS.dta", clear
sort NUM_HOGAR
merge m:1 NUM_HOGAR using "$ruta\ENEIC-1-2024_HOGARES.dta"
tab _merge
drop _merge
rename *, lower
saveold "`base_out'", version(12) replace

log close


