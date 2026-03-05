*Elaboración: Lina Arias
*febrero, 2026
global ruta = "${surveysFolder}"

local PAIS TTO
local ENCUESTA HBS
local ANO "2023"
local ronda a

*local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_orig"
local base_out = "$ruta\\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"

*** Base a nivel de hogar
use "`base_in'\HBS2023.dta", clear

* Hay duplicados en base a nivel de hogar

duplicates report interview__key interview__id

*** MERGE ***

merge 1:m interview__key interview__id using "`base_in'\HHCharacteristics.dta"
keep if _merge==3 // 402 _merge==2 se borraron

drop _merge 

saveold "`base_out'", replace
