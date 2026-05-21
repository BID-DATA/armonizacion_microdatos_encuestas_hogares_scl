* MERGE
* ARGENTINA EPHC. 2o Sem. 2025

clear
set more off

global ruta = "${surveysFolder}"
local ano 25
local trims t3 t4
local modulos hogar individual

*** Bases originales 
foreach modulo of local modulos {

		import delimited "$ruta\survey\ARG\EPHC\20`ano'\\t3\data_orig\usu_`modulo'_T3`ano'.txt", encoding(ISO-8859-2) clear 
		save "$ruta\survey\ARG\EPHC\20`ano'\t3\data_orig\usu_`modulo'_t320`ano'.dta", replace

		import delimited "$ruta\survey\ARG\EPHC\20`ano'\t4\data_orig\usu_`modulo'_T4`ano'.txt", encoding(ISO-8859-2) clear 
		save "$ruta\survey\ARG\EPHC\20`ano'\t4\data_orig\usu_`modulo'_t420`ano'.dta", replace
		
		*import excel "$ruta\survey\ARG\EPHC\20`ano'\\t4\data_orig\usu_`modulo'_T4`ano'.xlsx", sheet("Sheet 1") firstrow clear
		*rename *, lower
		*save "$ruta\survey\ARG\EPHC\20`ano'\t4\data_orig\usu_`modulo'_t420`ano'.dta", replace

}


*** Modulos trimestres
foreach trim of local trims {

		local base_in  = "$ruta\survey\ARG\EPHC\20`ano'\\`trim'\data_orig"
		local base_out = "$ruta\survey\ARG\EPHC\20`ano'\\`trim'\data_merge"
	
		use "`base_in'\usu_individual_`trim'20`ano'.dta", clear
		sort codusu nro_hogar aglomerado
		*save, replace

		use "`base_in'\usu_individual_`trim'20`ano'.dta", clear
		sort codusu nro_hogar aglomerado

		merge m:1 codusu nro_hogar aglomerado using "`base_in'\usu_hogar_`trim'20`ano'.dta"

		tab _merge // Matched 88649

		save "`base_out'\ARG_20`ano'`trim'.dta", replace
		clear
}


*** Append de trimestres
use "$ruta\survey\ARG\EPHC\20`ano'\t3\data_merge\ARG_20`ano't3.dta"
append using "$ruta\survey\ARG\EPHC\20`ano'\t4\data_merge\ARG_20`ano't4.dta", force


* Arma ponderador semestral
replace pondera=pondera/2
replace pondera=round(pondera)
drop _merge

* Importante, comparo que la cantidad de individuos creada por mi sea igual a la del INDEC
sort codusu nro_hogar
capture drop id
egen id = group(codusu nro_hogar trimestre)  

gen uno = 1
egen miembros = sum(uno) if ch03 != ., by(id)
replace miembros = 0 if miembros == .

compare miembros ix_tot //  88649 iguales 
more

drop id uno miembros
isid codusu aglomerado nro_hogar trimestre componente

* Comprime y guarda base
compress
save "$ruta\survey\ARG\EPHC\20`ano'\s2\data_merge\ARG_20`ano's2.dta", replace


