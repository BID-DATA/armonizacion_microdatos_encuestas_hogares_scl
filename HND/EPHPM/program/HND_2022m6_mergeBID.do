/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Honduras
Encuesta: EPHPM
Round: m6
Autores: David Cornejo E-mail: davidcornejoarias@gmail.com - dcor@iadb.org
Última modificación: 

							SCL/GDI - IADB
****************************************************************************/
****************************************************************************/

clear all
set more off
global ruta = "${surveysFolder}"

local PAIS HND
local ENCUESTA EPHPM
local ANO "2022"
local ronda m6 

local base_out  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local ruta_in = "$ruta\\survey\\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

*Transformar la base SAV to DTA
import spss using "`ruta_in'\\Hogar2022.sav", case(lower)

saveold "`base_out'", replace
 
