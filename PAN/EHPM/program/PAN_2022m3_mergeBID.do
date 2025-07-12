* Elaborado por: Daniela Zuluaga
* Fecha: Junio 2020

clear

global ruta = "${surveysFolder}"

local PAIS PAN
local ENCUESTA EHPM
local ANO "2022"
local ronda m3 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   
capture log close
log using "`log_file'", replace 



					****************
					***MERGE 2022***
					****************
					
use "`base_in'\hogar.dta", clear
rename *, lower
rename hogar_no hogar
sort llave_sec  hogar
tempfile hogar_mod
save `hogar_mod' , replace

use "`base_in'\vivienda.dta", clear
rename hogar_no hogar
sort llave_sec  hogar
tempfile vivienda_mod
save `vivienda_mod' , replace

use "`base_in'\panama_disability.dta", clear
sort llave_sec  hogar nper
egen idh_ch = group(llave_sec hogar)
destring nper, gen (idp_ci)
tostring idh_ch, gen(idh_ch_string) format("%20.0f")
tostring idp_ci, gen(idp_ci_string) format("%20.0f")
gen guion = "_"
egen idPerson = concat(idh_ch_string guion idp_ci_string)
tempfile panama_disability
save `panama_disability' , replace

use "`base_in'\poblacion.dta", clear
sort llave_sec  hogar nper
egen idh_ch = group(llave_sec hogar)
destring nper, gen (idp_ci)
tostring idh_ch, gen(idh_ch_string) format("%20.0f")
tostring idp_ci, gen(idp_ci_string) format("%20.0f")
gen guion = "_"
egen idPerson = concat(idh_ch_string guion idp_ci_string)
merge m:1 idPerson using `panama_disability' 
drop idp_ci idp_ci_string idh_ch idh_ch_string idPerson _merge

merge m:1 llave_sec hogar using `hogar_mod' 
drop _merge

sort llave_sec  hogar
merge m:1 llave_sec hogar using `vivienda_mod'
drop if _merge!=3
drop _merge

* Comprime y guarda base
compress
saveold "`base_out'", replace v(12)

log close
