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
local ANO "2014"
local ronda a

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"



/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Bahamas
Encuesta: LFS
Round: a
Autores: Melany Gualavisi - Email: melanyg@iadb.org
Última versión: 
Fecha última modificación: 12/22/2015

							SCL/LMK - IADB
****************************************************************************/

	*CONFORMACIÓN BASE ÚNICA BAHAMAS 2012*

use  "$ruta\Bahamas_LFS_2014_housing.dta", clear
sort island hhno result_code 
duplicates report  island hhno result_code 
duplicates report  island hhno 
*duplicates tag  island hhno result_code , gen(dup)
duplicates tag  island hhno , gen(dup)
tab dup
br if dup>=1
drop if hhno ==.
drop if dup ==1 & result_code!=1 //al revisar la base los duplicados con result_code 1 no tienen información en los campos
duplicates report island hhno
save "$ruta\housing.dta", replace

use "$ruta\Bahamas_LFS_2014_individual.dta", clear
duplicates report  island hhno  ind_no  // hay duplicados en obs pero al revisar tienen características diferentes
duplicates tag  island hhno ind_no , gen(dup)  //52
tab dup
br if dup>=1
sort island hhno result_code 
merge  m:1 island hhno using "$ruta\housing.dta"
br if _merge ==1
drop if _merge ==2

tab _merge
/*
   Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
        Master only (1) |          3        0.05        0.05
            Matched (3) |      6,014       99.95      100.00
------------------------+-----------------------------------
                  Total |      6,017      100.00
*/

drop _merge

save "`base_out'", replace

