
* (Versión Stata 13)
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
Ultima actualización: Maria Alejandra Zegarra, October 2025
----------------------------------------------------
Creation Date:    25 Jun 2019 - 10:57:54            
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

	set trace on 
local pais BRA	
local ano 2024
local ronda a

global surveysFolder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"

global input  "${surveysFolder}\BRA\PNADC\\`ano'\\`ronda'\data_orig"
global output "${surveysFolder}\BRA\PNADC\\`ano'\\`ronda'\data_merge" 

*global input  "${surveysFolder}\survey\BRA\PNADC\\`ano'\\`ronda'\data_orig"
*global output "${surveysFolder}\survey\BRA\PNADC\\`ano'\\`ronda'\data_merge" 

/*==================================================
              1: txt. to .dta 
==================================================*/

infix using "${input}\input_2024.dct", clear
save "${output}\PNADC_`ano'`ronda'.dta", replace


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
