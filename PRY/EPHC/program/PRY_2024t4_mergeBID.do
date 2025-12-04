* (Version Stata 18)

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
Versión: 
Fecha de última modificación: 
							   SCL - Mayo 2023
							   SPH - Sep 2024
							   SCL - Agosto 2025
****************************************************************************/

*Convierto las bases descargadas a dta, les hago rename y las sorteo:

/*Vivienda e inventario de bienes duraderos*/
import spss "$ruta\REG01_EPHC_ANUAL_2024.sav", clear 

* Creo que hubo problemas en levantar los "labels"
* " invalid numeric value for value label labels22 

rename *, lower
capture sort upm nvivi nhoga // asegurando orden por upm nvivi nhoga
isid   upm nvivi nhoga // aseguro uniqueness

* upm  : unidad primaria de muestreo
* nvivi: Número de orden de la vivienda
* nhoga: Número de orden del hogar dentro de la vivienda


/* transformo a texto*/
gen upms   =	string(upm)
gen nvivis =	string(nvivi)
gen nhogas =	string(nhoga)

replace upms   = substr("00000" + upms, -5, 5)   /*de acuerdo a documentación upm siempre tiene 5 caracteres */
replace nvivis = substr("000" + nvivis, -3, 3)   /*de acuerdo a documentación upm siempre tiene 3 caracteres */

save "$ruta\vivienda_ephc2024.dta", replace
*****************************************************************************************************


/*Ingreso familiar*/
import spss "$ruta\INGREFAM_EPHC_ANUAL_2024.sav", clear
rename *, lower
cap sort upm nvivi nhoga // asegurando orden por upm nvivi nhoga
isid upm nvivi nhoga   // aseguro uniqueness

gen upms   = string(upm)
gen nvivis = string(nvivi)
gen nhogas = string(nhoga)

replace upms   = substr("00000" + upms, -5, 5) /*de acuerdo a documentación upm siempre tiene 5 caracteres */
replace nvivis = substr("000" + nvivis, -3, 3) /*de acuerdo a documentación upm siempre tiene 3 caracteres */

save "$ruta\ingrefam_ephc2024.dta", replace
*****************************************************************************************************


/*Poblacion*/
import spss "$ruta\REG02_EPHC_ANUAL_2024.sav", clear // Ingresos individuales
* Creo que hubo problemas en levantar los "labels"
* sale varias veces "invalid numeric value for value label"

rename *, lower
cap sort upm nvivi nhoga l02
isid upm nvivi nhoga  l02 // aseguro uniqueness a nivel individuo

* upm : unidad primaria de muestreo
* nvivi: Número de orden de la vivienda
* nhoga: Número de orden del hogar dentro de la vivienda
* l02  : Línea de la persona

/* transformo a texto*/
gen upms =	string(upm)
gen nvivis=	string(nvivi)
gen nhogas=	string(nhoga)
gen l02s= 	string(l02)


replace upms   = substr("00000" + upms, -5, 5)     /*de acuerdo a documentación upm siempre tiene 5 caracteres */
replace nvivis = substr("000" + nvivis, -3, 3)    /*de acuerdo a documentación upm siempre tiene 3 caracteres */
replace l02s   = substr("00" + l02s, -2, 2)        /*de acuerdo a documentación upm siempre tiene 2 caracteres */


* Numero de observaciones totales de individuos: 57,744  

save "$ruta\poblacion_ephc2024.dta", replace
*****************************************************************************************************



/*4to trimestre - trabajo */
*Solo responden personas de 10 años a más*/
import spss "$ruta\e0b1f-REG02_EPHC_4º Trim 2024.SAV", clear 
* Creo que hubo problemas en levantar los "labels"
* sale varias veces "invalid numeric value for value label"
rename *, lower
cap sort upm nvivi nhoga l02
isid upm nvivi nhoga  l02 // aseguro uniqueness a nivel individuo

gen upms   = string(upm)
gen nvivis = string(nvivi)
gen nhogas = string(nhoga)
gen l02s   = string(l02)

replace upms = substr("00000" + upms, -5, 5)    /*de acuerdo a documentación upm siempre tiene 5 caracteres */
replace nvivis = substr("000" + nvivis, -3, 3)  /*de acuerdo a documentación upm siempre tiene 3 caracteres */
replace l02s = substr("00" + l02s, -2, 2)       /*de acuerdo a documentación upm siempre tiene 2 caracteres */

* Numero de observaciones totales: 16,382 

* Notar que no todas las preguntas son respondidas por el individuo - las puede responder el jefe o la esposa
* la pregunta a01a - dice "Línea de  la persona que responde"

save "$ruta\reg02_ephc_t4_2024.dta", replace

*/
*****************************************************************************************************






*****************************************************************************************************
/*Unifico los modulos de interes: vivienda, ingresos y personas*/
 
 
use "$ruta\vivienda_ephc2024.dta", clear // vivienda
cap sort upms nvivis nhogas
merge 1:1 upms nvivis nhogas using "$ruta\ingrefam_ephc2024.dta" // merge ingreso familiar
* todos  Matched 17,242  (_merge==3) -- 17,242 observaciones de hogares
keep if _merge == 3 
drop _merge
sort upms nvivis nhogas 
 
 
merge 1:m upms nvivis nhogas  using "$ruta\poblacion_ephc2024.dta" // poblacion + ingresos - base individual
* todos Matched  57,744  (_merge==3) -- 57,744 observaciones de individuos
keep if _merge == 3
drop _merge
sort upms nvivis nhogas l02s 
 
merge m:m upms nvivis nhogas l02s using "$ruta\reg02_ephc_t4_2024.dta" // + Base del 4to Trimestre
* todos Matched 16,382  (_merge==3) -- 16,382 observaciones de individuos
keep if _merge == 3
*Al correr este codigo me paso de tener 57,744 observaciones a 16,382 que provienen de la base reg02_ephc_t4_2024.dta que es la del 4to trimestre. 41,362 observaciones de la base master hasta este punto no hacen match con la del 4to trimeste.
drop _merge
sort upms nvivis nhogas l02s 

save "`base_out'", replace 
* 16,7382  observaciones de personas - nivel individual 

/* Se puede limpiar la ruta de las bases recien creadas*/

erase "$ruta\vivienda_ephc2024.dta"
erase "$ruta\ingrefam_ephc2024.dta"
erase "$ruta\poblacion_ephc2024.dta"
erase "$ruta\reg02_ephc_t4_2024.dta"


capture log close
