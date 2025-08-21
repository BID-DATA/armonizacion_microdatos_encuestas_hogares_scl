* (Version Stata 17)

clear all
set more off
capture log close

*________________________________________________________________________________________________________________*

* Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
* utilizar un loop)
* Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
* Se tiene acceso al servidor 򮩣amente al interior del BID.
* El servidor contiene las bases de datos MECOVI.
*________________________________________________________________________________________________________________*
 
global ruta = "${surveysFolder}\\survey\PRY\EPHC\2024\t4\data_orig"

local PAIS PRY
local ENCUESTA EPHC
local ANO "2024"
local ronda t4

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"


log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Paraguay
Encuesta: EPHC 
Round: t4 2024
Autores:
Versión: David Cornejo
Fecha de última modificación: 
							   SCL - Mayo 2023
							   SPH - Sep 2024
							   SCL - Agosto 2025
****************************************************************************/

*Convierto las bases descargadas a dta, les hago rename y las sorteo:

/*Vivienda e inventario de bienes duraderos*/
import spss "$ruta\REG01_EPHC_ANUAL_2024.sav", clear
rename *, lower
cap sort upm nvivi nhoga

gen upms =	string(upm)
gen nvivis=	string(nvivi)
gen nhogas=	string(nhoga)

replace upms = substr("00000" + upms, -5, 5) /*de acuerdo a documentación upm siempre tiene 5 caracteres */
replace nvivis = substr("000" + nvivis, -3, 3) /*de acuerdo a documentación upm siempre tiene 3 caracteres */

save "$ruta\vivienda_ephc2024.dta", replace

/*Ingreso familiar*/
import spss "$ruta\INGREFAM_EPHC_ANUAL_2024.sav", clear
rename *, lower
cap sort upm nvivi nhoga

gen upms =	string(upm)
gen nvivis=	string(nvivi)
gen nhogas=	string(nhoga)

*replace upms = substr("00000" + upms, -5, 5) /*de acuerdo a documentación upm siempre tiene 5 caracteres */
*replace nvivis = substr("000" + nvivis, -3, 3) /*de acuerdo a documentación upm siempre tiene 3 caracteres */

save "$ruta\ingrefam_ephc2024.dta", replace

/*Poblcion*/
import spss "$ruta\REG02_EPHC_ANUAL_2024.sav", clear
rename *, lower
cap sort upm nvivi nhoga l02

gen upms =	string(upm)
gen nvivis=	string(nvivi)
gen nhogas=	string(nhoga)
gen l02s= 	string(l02)

*replace upms = substr("00000" + upms, -5, 5) /*de acuerdo a documentación upm siempre tiene 5 caracteres */
*replace nvivis = substr("000" + nvivis, -3, 3) /*de acuerdo a documentación upm siempre tiene 3 caracteres */
*replace l02s = substr("00" + l02s, -2, 2) /*de acuerdo a documentación upm siempre tiene 2 caracteres */

save "$ruta\poblacion_ephc2024.dta", replace

/*4to trimestre*/
import spss "$ruta\e0b1f-REG02_EPHC_4º Trim 2024.SAV", clear
rename *, lower
cap sort upm nvivi nhoga l02

gen upms =	string(upm)
gen nvivis=	string(nvivi)
gen nhogas=	string(nhoga)
gen l02s= 	string(l02)

*replace upms = substr("00000" + upms, -5, 5) /*de acuerdo a documentación upm siempre tiene 5 caracteres */
*replace nvivis = substr("000" + nvivis, -3, 3) /*de acuerdo a documentación upm siempre tiene 3 caracteres */
*replace l02s = substr("00" + l02s, -2, 2) /*de acuerdo a documentación upm siempre tiene 2 caracteres */

save "$ruta\reg02_ephc_t4_2024.dta", replace

/*Unifico los modulos de interes para el sociometro: vivienda, ingresos y personas*/
 
use "$ruta\reg02_ephc_t4_2024.dta", clear

cap sort upms nvivis nhogas l02s
merge m:1 upms nvivis nhogas using "$ruta\vivienda_ephc2024.dta"
keep if _merge == 3
drop _merge
sort upms nvivis nhogas l02s

merge m:1 upms nvivis nhogas using "$ruta\ingrefam_ephc2024.dta"
keep if _merge == 3
drop _merge
sort upms nvivis nhogas l02s

merge m:m upms nvivis nhogas l02s using "$ruta\poblacion_ephc2024.dta"
keep if _merge == 3
drop _merge
sort upms nvivis nhogas l02s


save "`base_out'", replace

log close
