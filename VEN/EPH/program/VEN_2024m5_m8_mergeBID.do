* (Versión Stata 18)
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: 
Encuesta: EPH
Round: m5_m8
Autores: Jillie Chang
Fecha última modificación: 27MAR2025

							SCL/SCL - IADB
****************************************************************************/
****************************************************************************/

*****************************
* Definir parámetros y ruta *
*****************************
clear
set more off
global ruta = "${surveysFolderRestricted}"
local PAIS VEN
local ENCUESTA EPH
local ANO "2024"
local ronda m5_m8
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"       

******************
* merge de bases *
******************

* individual   13009 registros
use "$ruta\survey\VEN\EPH\2024\m5_m8\data_orig\miembros-encoded-pnh-2024.dta", clear
* hogar 
merge m:1 id_hogar using  "$ruta\survey\VEN\EPH\2024\m5_m8\data_orig\hogares-encoded-pnh-2024.dta"
drop _merge
format id_hogar  %20.0f

generate date = date(fecha_encuesta, "YMD")
format %td date
gen year =substr(fecha_encuesta,1,4)
destring year, replace

keep if year ==2024

compress
save "`base_out'", replace

*************
* Revisión  *
*************
duplicates report id_hogar id_miembro
/* Duplicates in terms of id_hogar id_miembro
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |         6513             0
--------------------------------------


