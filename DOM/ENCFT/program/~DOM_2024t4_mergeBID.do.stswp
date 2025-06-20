* (Versión Stata 18)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 


global ruta = "${surveysFolder}"

local PAIS DOM
local ENCUESTA ENCFT
local ANO "2024"
local ronda t4 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   

*capture log close
*log using "`log_file'", replace 


/*************************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Republica Dominicana
Encuesta: ENCFT
Round: m10
Autores: Olga Dulce
							SCL/SCL - IADB
**************************************************************************************/

*Conversión de bases de formato excel a stata
/*
clear all
global modulos "Vivienda Hogar Miembros"
foreach mod of global modulos {
import excel "`base_in'Base ENCFT 20241 - 20244", sheet("`mod'") firstrow case(lower) clear
rename *, lower
keep if trimestre == 20244
saveold "`base_in'\`mod'", replace
clear
}
*/

*Consolidando la información*
*****************************

use "`base_in'\Miembros.dta", clear

merge m:m vivienda using "`base_in'\Vivienda.dta", force
tab _merge
drop _merge
sort vivienda hogar

merge m:m vivienda hogar using "`base_in'\Hogar.dta", force
tab _merge
drop _merge

* Comprime y guarda base
compress
drop if periodo ==.
save "`base_out'",  replace






