* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Barbados
Año: 2023
Autores: Matias Rodriguez SCL 
Última versión: 0/26/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolderRestricted}"
 
local PAIS BRB
local ENCUESTA LFS
local ANIO 2022
local RONDA a
*local log_file = "$ruta\survey\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

*capture log close
*log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base y drop duplciates
*****************************************************************************/

* Base de hogares
import spss "`base_in'\LFW2022_correct.SAV", clear // (202 vars, 11,366 obs)
duplicates report _all //0

/***************************************************************************
  IV. Guardar la base
****************************************************************************/
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

saveold "`base_out'", version(12) replace
*log close


