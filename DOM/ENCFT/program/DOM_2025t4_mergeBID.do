* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: República Dominicana 
Encuesta: ENCFT
Año: 2025
Ronda: m10
Autores: Olga Dulce EDU/SCL, Matias Rodriguez SCL/SCL
Última versión: 19MAYO2026
División: SPL/SCL y SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"

local PAIS DOM
local ENCUESTA ENCFT
local ANO "2025"
local ronda t4 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_a  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\a\data_orig\Base ENCFT 2025\"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   
capture log close
log using "`log_file'", replace 


/****************************************************************************
   II. Conversión de bases de formato excel a stata
*****************************************************************************/
global modulos "Vivienda Hogar Miembros"
foreach mod of global modulos {
import excel "`base_a'Base ENCFT 2025", sheet("`mod'") firstrow case(lower) clear
rename *, lower
keep if trimestre == 20254
saveold "`base_in'\`mod'", replace
clear
}

/****************************************************************************
   III. Unir módulos en una sola base
*****************************************************************************/
use "`base_in'\Miembros.dta", clear

merge m:1 vivienda using "`base_in'\Vivienda.dta", force
tab _merge
drop _merge
sort vivienda hogar

merge m:1 vivienda hogar using "`base_in'\Hogar.dta", force
tab _merge
drop _merge


/****************************************************************************
  IV. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/

duplicates report id_hogar id_persona
/*Duplicates in terms of id_hogar id_persona OK
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        17533             0
-------------------------------------- */
tab sexo [iw= factor_expansion ], mi
/*10,906,662 registros OK*/

/***************************************************************************
  V. Guardar la base
****************************************************************************/
* Comprime y guarda base
local PAIS DOM
local ENCUESTA ENCFT
local ANO "2025"
local ronda t4 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"

compress
drop if periodo ==.
save "`base_out'",  replace



