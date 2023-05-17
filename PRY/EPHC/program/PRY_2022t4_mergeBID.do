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
 
global ruta = "${surveysFolder}\\survey\PRY\EPHC\2022\t4\data_orig"

local PAIS PRY
local ENCUESTA EPHC
local ANO "2022"
local ronda t4

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"


log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Paraguay
Encuesta: EPHC 
Round: t4 2022
Autores:
Versión: Cecilia Giambruno
Última versión: 
Fecha de última modificación: Abril 2023
							   SCL - IADB
****************************************************************************/

*Convierto la bases a dta, les hago rename y las sorteo:

/*4to trimestre*/
import spss "$ruta\REG02_EPHC_4to Trim 2022.sav", clear
rename *, lower
cap sort upm nvivi nhoga
cap sort upm nvivi nhoga l02
save "$ruta\reg02_ephc_t4_2020.dta", replace

saveold "`base_out'", v(12) replace

log close