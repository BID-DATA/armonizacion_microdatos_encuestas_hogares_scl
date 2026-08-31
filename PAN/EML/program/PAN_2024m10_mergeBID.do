********************************************************************************
********************************************************************************
* MERGE BASES DE PANAMA // EN CASO DE QUE SEA EML

clear

global ruta = "${surveysFolder}"

local PAIS PAN
local ENCUESTA EML
local ANO "2024"
local ronda m10 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
capture log close
log using "`log_file'", replace 

clear all

local base hogar persona vivienda

foreach v in `base' {

import dbase "`base_in'/`v'.dbf", clear
save "`base_in'/`v'.dta", replace
set more off
}

* MERGE PERSONA | HOGAR | VIVIENDA

use "`base_in'/hogar.dta", clear
rename *, lower
egen idhogar= group(llave_sec prov dist unidad cuest hogar)
duplicates report idhogar // cero duplicados
sort idhogar
duplicates report llave_sec hogar // cero duplicados
compress
save "`base_in'/hogar_eml.dta" , replace

use "`base_in'/vivienda.dta", clear
rename *, lower
egen idhogar= group(llave_sec prov dist unidad cuest hogar)
duplicates report idhogar // cero duplicados
sort idhogar
duplicates report llave_sec hogar // cero duplicados
compress
save "`base_in'/vivienda_eml.dta", replace

***** 
use "`base_in'/persona.dta", clear
rename *, lower
egen idhogar = group(llave_sec prov dist cuest hogar)
duplicates report idhogar 
sort idhogar
duplicates report llave_sec hogar nper // cero duplicados 39353 registros


*merge m:1 idhogar  using "`base_in'/hogar_eml.dta"
merge m:1 llave_sec hogar using "`base_in'/hogar_eml.dta"
tab _merge
drop _merge   // all matched (3)

*no se estan uniendo 829 observaciones 
*merge m:1 idhogar using "`base_in'/vivienda_eml.dta"
*keep if _merge==3
*drop _merge

* se unen todos los registros 
merge m:1 llave_sec hogar using "`base_in'/vivienda_eml.dta"
tab _merge   // 355 registros del módulo persona no tienen información del módulo vivienda 
/* Matching result from |
                  merge |      Freq.     Percent        Cum.
------------------------+-----------------------------------
        Master only (1) |        355        0.90        0.90
            Matched (3) |     38,998       99.10      100.00
------------------------+-----------------------------------
                  Total |     39,353      100.00  */

				
* Comprime y guarda base
compress
save "`base_out'", replace

erase "`base_in'\hogar_eml.dta"
erase "`base_in'\vivienda_eml.dta"

log close
