* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Barbados
Año: 2023
Autores: Matias Rodriguez SCL 
Última versión: 02/19/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "\\sapidbshares.file.core.windows.net\\idbrestrictedshares\\SCL_DATAFILES_RESTRICTED"
 
local PAIS BRB
local ENCUESTA LFS
local ANIO 2023
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
import spss "`base_in'\LFW2023.SAV", clear
duplicates report _all
duplicates tag, gen(dup)
*br if dup>0  //1 personas con todas las variables duplicadas 34 veces, y 5 personas duplicadas. Se eliminan 38 obs
duplicates drop //12031 obs quedan de 12069
drop dup
duplicates r PARNO STRATUM HHNO INDIVNO LIDNO LSEX LAGE DATE VISITNO RNDNO EDNO


/***************************************************************************
  IV. Guardar la base
****************************************************************************/
saveold "`base_out'", version(12) replace
*log close


