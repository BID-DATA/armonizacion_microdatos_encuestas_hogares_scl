/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Honduras
Encuesta: EPHPM
Round: m6
Autores: Mayte Ysique E-mail: mysique@pucp.pe - maytes@iadb.org
Última modificación: 

							SCL/GDI - IADB
****************************************************************************/
****************************************************************************/

clear all
set more off
global ruta = "${surveysFolder}"

local PAIS HND
local ENCUESTA EPHPM
local ANO "2025"
local ronda m7

local base_out  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local ruta_in = "$ruta\\survey\\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

*Transformar la base SAV to DTA
use "`ruta_in'\\EPHPM JDULIO 2025.dta", clear


foreach v of varlist _all {
    local lbl : variable label `v'
    if length("`lbl'") > 80 {
        label variable `v' "`=substr("`lbl'", 1, 80)'"
    }
}

saveold "`base_out'", replace
 
