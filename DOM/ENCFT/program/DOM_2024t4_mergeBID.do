* (Versión Stata 18)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: República Dominicana 
Encuesta: ENCFT
Año: 2024
Ronda: m10
Autores: Olga Dulce EDU/SCL
Última versión: 30JUN2025
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
local ANO "2024"
local ronda t4 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   
capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/

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

merge m:1 vivienda using "`base_in'\Vivienda.dta", force
tab _merge
drop _merge
sort vivienda hogar

merge m:1 vivienda hogar using "`base_in'\Hogar.dta", force
tab _merge
drop _merge

/****************************************************************************
  III. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/

duplicates report id_hogar id_persona
/*Duplicates in terms of id_hogar id_persona OK
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        17133             0
-------------------------------------- */
tab sexo [iw= factor_expansion ], mi
/*10,826,490 registros OK*/

/***************************************************************************
  IV. Guardar la base
****************************************************************************/
* Comprime y guarda base
compress
drop if periodo ==.
save "`base_out'",  replace

log close






