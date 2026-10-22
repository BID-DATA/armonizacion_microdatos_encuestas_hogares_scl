***********************
***** MERGE 2022 ******
***********************
* David Cornejo, dcor@iadb.org

clear

global ruta = "${surveysFolder}"

local PAIS SLV
local ENCUESTA EHPM
local ANO "2023"
local ronda a 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
 
capture log close
log using "`log_file'", replace 
* Sort 

* ehpm_2023
import spss using "`base_in'\Encuesta de Hogares de Propositos Multiples 2023.sav", clear

   

* comprime y guarda base
compress
saveold "`base_out'", v(12) replace

log close

