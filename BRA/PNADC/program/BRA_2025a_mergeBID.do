* (Versión Stata 19)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*

/*==================================================
project:       PNADC - Brasil
Author:       David Cornejo
E-email:       dcor@iadb.org
url:           
Dependencies:  SLC/EDU
Ultima actualización: Maria Alejandra Zegarra
----------------------------------------------------
Creation Date:    17 Abril 2026          
==================================================*/

/*==================================================
              0: Program set up
==================================================*/

*Updated by Alvaro Altamirano on June 2020:
	*Use the following python code to translate IBGE's SAS import dicts to STATA import dicts
	/*import re
	text = re.sub("@", "_column (", text)
	text = re.sub("(?<=\(\d{4}) ", ") ", text)
	text = re.sub("  \$", "%", text)
	text = re.sub("(?<=  \$\d)\.", "g", text)
	text = re.sub("\/\*", "\"", text)
	text = re.sub("\*\/", "\"", text)
	text = re.sub("   (?=\d{1,})", " %", text)
	text = re.sub("r(?<=\d)\.", "g", text)
	*/

local pais BRA	
local ano 2025
local ronda a // visita 1

global input  "${surveysFolder}\survey\BRA\PNADC\\`ano'\\`ronda'\data_orig"
global output "${surveysFolder}\survey\BRA\PNADC\\`ano'\\`ronda'\data_merge" 

/*==================================================
              1: txt. to .dta 
==================================================*/

infile using "${input}\input_`ano'.do", using("${input}\PNADC_2025_visita1_20260508\PNADC_`ano'_visita1.txt")
		save   "${input}\PNADC_`ano'`ronda'.dta", replace

foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }
*Versión 12 no acepta labels con más de 79 caracteres
 foreach i of varlist _all {
local longlabel: var label `i'
local shortlabel = substr(`"`longlabel'"',1,79)
label var `i' `"`shortlabel'"'
}

/*==================================================
              3: Guardo base anual 
==================================================*/
compress
save   "${output}\\`pais'_`ano'`ronda'.dta", replace
exit

*_______________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*

 
