* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: República Dominicana 
Encuesta: ENCFT
Año: 2023
Ronda: m10
Autores: Olga Dulce EDU/SCL, Matias Rodriguez SCL/SCL
Última versión: 16SEPT2026
División: SPL/SCL y SCL/SCL - IADB
*******************************************************************************/
clear all
set more off 

local PAIS DOM
local ENCUESTA ENCFT
local ANO "2023"
local RONDA t3

global tag = "`PAIS'_`ANO'_`ENCUESTA'-`RONDA'"
global ruta = "$datalibweb_IDB\\`PAIS'\\$tag\\${tag}_V01_M\Data"
global base_anual = "$datalibweb_IDB\\`PAIS'\\`PAIS'_`ANO'_`ENCUESTA'-a\\`PAIS'_`ANO'_`ENCUESTA'-a_V01_M\Data\Stata"

*local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
*capture log close
*log using "`log_file'", replace 


/****************************************************************************
   I. Conversión de bases de formato excel a stata
*****************************************************************************/
global modulos "Vivienda Hogar Miembros"
foreach mod of global modulos {
import excel "$ruta\Original\Base ENCFT `ANO'1 - `ANO'4", sheet("`mod'") firstrow case(lower) clear
rename *, lower
save "$base_anual\\`mod'_a", replace

keep if trimestre == `ANO'3
save "$ruta\Stata\\`mod'", replace
clear
}

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/
use "$ruta\Stata\Miembros.dta", clear

merge m:1 vivienda using "$ruta\Stata\Vivienda.dta", force
tab _merge
drop _merge
sort vivienda hogar

merge m:1 vivienda hogar using "$ruta\Stata\Hogar.dta", force
tab _merge
drop _merge // n = 18,144


/****************************************************************************
  III. Verificar duplicados y guarda la base
*****************************************************************************/
drop if periodo ==.
isid id_hogar id_persona
summarize factor_expansion
display %20.4f r(sum)  //   10721425

compress
save "$ruta\Stata\\`PAIS'_`ANO'`RONDA'.dta",  replace
