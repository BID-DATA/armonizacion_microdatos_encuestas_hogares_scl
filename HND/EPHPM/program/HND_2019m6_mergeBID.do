		*************************************************************
		***PROGRAMA PARA TRANSFORMAR BASE DE DATOS MERGE***
		*************************************************************
*Elaborado por: David COrnejo


clear

global ruta = "${surveysFolder}"

local PAIS HND
local ENCUESTA EPHPM
local ANO "2019"
local ronda m6

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
   
capture log close
log using "`log_file'", replace 


	


*Base de datos
import spss using "`base_in'\EPHPM_2019_NUEVA METODOLOGJIA.sav"

* Comprime y guarda base
compress
saveold "`base_out'", replace

log close