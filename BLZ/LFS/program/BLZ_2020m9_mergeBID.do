* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 2021-2025
Autores:Lina Arias - PEC SCL
Última versión: 05/19/2026
División: SCL/SCL - IADB
*******************************************************************************/

clear all
set more off 

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"
 
local PAIS BLZ
local ENCUESTA LFS
local ANIO 2020
local RONDA m9
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANIO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\data_orig" 
local base_out = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANIO'\\`RONDA'\\data_merge\\`PAIS'_`ANIO'`RONDA'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Importar spss
*****************************************************************************/
import spss "`base_in'\Sept_2020 - Microdata.sav", clear // 7480 obs
rename *, lower

local varlist catmain catprevious mainindust reasondiff informalemp ind_weight income_month district ea10new ea11_1 ea11_2 ea11merge ea12anew ea13new ea14 ea15a ea15b ea16main_occ ea16previous_occ ea17_bcea_main_industry ea17_main_isic ea17_previous_isic ea18 ea19a ea19b ea1new ea23a ea23bnew ea25new ea26new ea27new ea2new ea30new ea3new ea4new ea5new ea6 ea7 ea8new ea9anew ea9bnew ed3 ed4 ed5 ed6 hl3 hl4new hl5 hl6new hl7new hl8new status tot_pop total_hrs_last_week total_postcovidhrs total_precovidhrs urban_rural

foreach x of local varlist {

destring `x', replace ignore("NA")

}

/***************************************************************************
  III. Guardar la base
****************************************************************************/
saveold "`base_out'", version(12) replace

log close
