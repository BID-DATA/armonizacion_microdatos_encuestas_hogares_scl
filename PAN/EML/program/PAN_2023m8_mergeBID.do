*David Cornejo
clear

global ruta = "${surveysFolder}"

local PAIS PAN
local ENCUESTA EML
local ANO "2023"
local ronda m8 

*local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   
*capture log close
*log using "`log_file'", replace 



					****************
					***MERGE 2012***
					****************
					
import dbase using  "`base_in'\hogar.dbf", clear

foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }
egen idhogar= concat(llave_sec prov dist estra unidad cuest hogar)
duplicates report idhogar
sort idhogar
saveold "`base_in'\hogar1.dta", replace


import dbase using "`base_in'\vivienda.dbf", clear
foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }
egen idhogar= concat(llave_sec prov dist estra unidad cuest hogar)
duplicates report idhogar
sort idhogar
save "`base_in'\vivienda1.dta", replace

import dbase using "`base_in'\emergent.dbf", clear
foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }
egen idhogar= concat(llave_sec prov dist estra unidad cuest hogar)
destring nper, gen (idindividuo)
egen idind= concat(llave_sec prov dist estra unidad cuest hogar nper)
duplicates report idhogar
duplicates report idind
sort idind
save "`base_in'\emergent.dta", replace

import dbase using "`base_in'\persona.dbf", clear
foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }
egen idhogar= concat(llave_sec prov dist estra unidad cuest hogar)
egen idind= concat(llave_sec prov dist estra unidad cuest hogar nper)
duplicates report idhogar
sort idhogar

merge m:1 idind using "`base_in'\emergent.dta"
tab _merge
drop _merge

merge m:1 idhogar using "`base_in'\hogar1.dta"
tab _merge
drop _merge

*no se estan uniendo 508 observaciones 
sort idhogar
merge m:1 idhogar using "`base_in'\vivienda1.dta"
tab _merge
keep if _merge==3
drop _merge

* Comprime y guarda base
compress
saveold "`base_out'", replace

*log close
erase "`base_in'\hogar1.dta"
erase "`base_in'\vivienda1.dta"
