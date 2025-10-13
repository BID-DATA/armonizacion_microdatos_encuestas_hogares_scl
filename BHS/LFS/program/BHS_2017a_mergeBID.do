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
 
global ruta = "${surveysFolder}\\survey\\BHS\LFS\\2014\\a\\data_orig"

local PAIS BHS
local ENCUESTA LFS
local ANO "2017"
local ronda a

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"

capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Bahamas
Encuesta: LFS
Round: a
Autores: Maria Alejandra Zegarra - Email: mariale.zegarra@gmail.com
Última versión: 
Fecha última modificación: 10/10/2025

							SCL/LMK - IADB
****************************************************************************/

use  "$ruta\Bahamas_LFS_`ANO'_housing_2.dta", clear
sort island hhno  
duplicates report  island hhno  
duplicates tag  island hhno , gen(dup)
tab dup
br if dup>=1
drop if hhno ==.
drop if dup ==1
duplicates report island hhno
save "$ruta\housing.dta", replace

use "$ruta\Bahamas_LFS_`ANO'_individual_2.dta", clear
duplicates report  island hhno  ind_no  // hay duplicados en obs pero al revisar tienen características diferentes
duplicates tag  island hhno ind_no , gen(dup)  //52
tab dup
br if dup>=1
sort island hhno  
merge  m:1 island hhno using "$ruta\housing.dta"
br if _merge ==1
drop if _merge ==2

tab _merge


drop _merge

save "`base_out'", replace

