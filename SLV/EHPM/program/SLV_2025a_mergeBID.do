***********************
***** MERGE 2025 ******
***********************
* Matias Rodriguez, mrodriguezm@iadb.org

clear

global ruta = "${surveysFolder}"

local PAIS SLV
local ENCUESTA EHPM
local ANO "2025"
local ronda a 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
 
capture log close
log using "`log_file'", replace 

* ehpm_2025
import spss using "`base_in'\Base de datos EHPM 2025.sav", clear

duplicates r  idboleta r101 //  56463

* comprime y guarda base
compress
saveold "`base_out'", v(12) replace

log close
