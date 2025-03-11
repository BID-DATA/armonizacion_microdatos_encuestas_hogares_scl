* (Versión Stata 18)
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: 
Encuesta: EPH
Round: m8_m10
Autores: Jillie Chang
Fecha última modificación: 10MAR2025

							SCL/SCL - IADB
****************************************************************************/
****************************************************************************/

*****************************
* Definir parámetros y ruta *
*****************************
clear
set more off
global ruta = "\\sapidbshares.file.core.windows.net\idbrestrictedshares\SCL_DATAFILES_RESTRICTED\"
local PAIS VEN
local ENCUESTA EPH
local ANO "2023"
local ronda m8_m10
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"       

******************
* merge de bases *
******************

* individual   6,499 registros
use "$ruta\survey\VEN\EPH\2023\m8_m10\data_orig\miembros-encoded-pnh-2023.dta", clear
* hogar 
merge m:1 id_hogar using  "$ruta\survey\VEN\EPH\2023\m8_m10\data_orig\hogares-encoded-pnh-2023.dta"
drop _merge
* ingresos
merge m:1 id_miembro using  "$ruta\survey\VEN\EPH\2023\m8_m10\data_orig\ingresos-encoded-pnh-2023.dta"
drop _merge
format id_hogar  %20.0f
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
        1 |         6499             0
--------------------------------------*/

