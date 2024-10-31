
/*
Autor: Olga Dulce
 */

*** MERGE COLOMBIA GEIH 2023 (t3) ****
*------------------------------*	

clear
set more off
local anio =2023
local ronda1 a
local ronda2 t3
local ruta "${surveysFolder}\survey\COL\GEIH\\`anio'\"
local m7 ="`ruta'\`ronda1'\data_orig\m7\" 
local m8 ="`ruta'\`ronda1'\data_orig\m8\" 
local m9 ="`ruta'\`ronda1'\data_orig\m9\" 
local t3 ="`ruta'\`ronda2'\data_orig\"
local out ="`ruta'\`ronda2'\data_merge\"



*
*1. Bases anuales con homologacion de ingresos:
*----------------------------------------------

clear
use "`ruta'\`ronda1'\data_orig\anual_homologado_DANE\HOGARES.dta", clear

merge 1:m directorio secuencia_p using "`ruta'\`ronda1'\data_orig\anual_homologado_DANE\PERSONAS.dta", force
drop _merge
egen id =concat (directorio secuencia_p orden)
sort id
save "`ruta'\`ronda1'\data_merge\pov_anual.dta", replace
destring mes, replace
keep if mes>=7 & mes<=9

keep  impaes- id impa-iof6 nper-fex_c dominio
save "`ruta'\`ronda1'\data_merge\pov_t3.dta", replace



*2. Append entre meses
*------------------------

*Personas
use "`m7'\Características generales, seguridad social en salud y educación.dta", clear
append using "`m8'\Características generales, seguridad social en salud y educación.dta"
append using "`m9'\Características generales, seguridad social en salud y educación.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
compress
save "`t3'col_personas.dta", replace

*Desocupados
use "`m7'\No ocupados.dta", clear
append using "`m8'\No ocupados.dta"
append using "`m9'\No ocupados.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
compress
save "`t3'col_desocupados.dta", replace
				
*Fuerza Trabajo
use "`m7'\Fuerza de trabajo.dta", clear
append using "`m8'\Fuerza de trabajo.dta"
append using "`m9'\Fuerza de trabajo.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
compress
save "`t3'col_ft.dta", replace

*ocupados
use "`m7'\Ocupados.dta", clear
append using "`m8'\Ocupados.dta"
append using "`m9'\Ocupados.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
compress
save "`t3'col_ocupados.dta", replace

*otrasactv
use "`m7'\Otras formas de trabajo.dta", clear
append using "`m8'\Otras formas de trabajo.dta"
append using "`m9'\Otras formas de trabajo.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
*rename clase CLASE
sort id
compress
save "`t3'col_otrasactv.dta", replace

*otros ingresos
use "`m7'\Otros ingresos e impuestos.dta", clear
append using "`m8'\Otros ingresos e impuestos.dta"
append using "`m9'\Otros ingresos e impuestos.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
*rename clase CLASE
sort id
compress
save "`t3'col_otrosing.dta", replace
 
*Vivienda y Hogares
use "`m7'\Datos del hogar y la vivienda.dta", clear
append using "`m8'\Datos del hogar y la vivienda.dta"
append using "`m9'\Datos del hogar y la vivienda.dta"
egen idh = concat(DIRECTORIO SECUENCIA_P)
*rename clase CLASE
sort idh
compress
save "`t3'col_viv.dta", replace

/*
*Tipo de investigación
use "`m7'\Tipo de investigación.dta", clear
append using "`m8'\Tipo de investigación.dta"
append using "`m9'\Tipo de investigación.dta"
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
compress
save "`t3'col_tipo.dta"
*/


** Módulo de migración 
use "`m7'\Migración.dta", clear
append using "`m8'\Migración.dta"
append using "`m9'\Migración.dta"

*ren (Mes Directorio Secuencia_p Orden Fex_c_2011) (MES DIRECTORIO SECUENCIA_P ORDEN fex_c_2011)
egen id = concat(DIRECTORIO SECUENCIA_P ORDEN)
sort id
rename *, lower
compress
save "`out'\COL_`anio't3migracion.dta", replace




*3. Merge de los 8 modulos trimestrales
*-----------------------------------------------

use "`t3'\col_personas.dta", clear

merge 1:1 id using "`t3'\col_desocupados.dta"  
drop _merge
sort id
merge 1:1 id using "`t3'\col_ft.dta"
drop _merge
sort id
merge 1:1 id using "`t3'\col_ocupados.dta"
drop _merge
sort id
merge 1:1 id using "`t3'\col_otrasactv.dta"
drop _merge
sort id
*merge 1:1 id using "`t3'\col_tipo.dta"
*drop _merge
*sort id
merge 1:1 id using "`t3'\col_otrosing.dta"
drop _merge
egen idh = concat(DIRECTORIO SECUENCIA_P)
sort idh
merge m:1 idh using "`t3'\col_viv.dta"
drop _merge 
sort id
rename *, lower
compress
save "`out\'COL_`anio't3.dta", replace



*4. Append zonas
*---------------

clear
use "`out'\COL_2023t3.dta", clear
replace fex_c18=fex_c18/3
merge 1:1 id using "`out'\COL_2023t3migracion.dta"
sort id
drop _merge
merge 1:1 id using "`ruta'\`ronda1'\data_merge\pov_t3.dta"
compress
save "`ruta'\`ronda2'\data_merge\COL_2023t3.dta", replace
















