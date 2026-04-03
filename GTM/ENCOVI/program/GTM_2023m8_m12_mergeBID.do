* (Versión Stata 18)
 /***************************************************************************
					ARMONIZACIÓN DE ENCUESTAS DE HOGARES
			 Script de merge - Unión de módulos en una sola base 
			 
País: Guatemala
Año: 2023
Encuesta: ENCOVI
Ronda: Anual 
División MIG/SCL - IADB
Última versión: Marcela G. Rubio - Email: mrubio@iadb.org, marcelarubio28@gmail.com
Última modificación: Daniela Zuluaga -Email: danielazu2iadb.org da.zuluaga@hotmail.com
Última modificación: Pablo Cortés MIG/SCL
Última modificación: Jillie Chang SCL/SCL
Fecha última modificación: 21JUL2025
****************************************************************************/

 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 
clear
set more off

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

local PAIS GTM
local ENCUESTA ENCOVI
local ANO "2023"
local ronda m8_m12

global ruta =    "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_orig\dta\"
display "$ruta"

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"

capture log close
log using "`log_file'", replace 

/****************************************************************************
   II. Unir módulos en una sola base
*****************************************************************************/

******************************
*módulo de fuente de energía *
******************************
/*
se extrae pregunta: ¿El mes pasado, qué fuente de energía utilizó en su hogar para: Cocinar todos sus alimentos?" 
Respuesta: 
1. Regularmente 
2. Ocasionalmente 
3. Rara vez 
9. Nunca 
Se usa esta pregunta, que es la más parecida a la que se usó en la ENEI 2022 para armonizar combust_ch*/
 
use "$ruta\2023_C01SE_Fuentes.dta", clear
encode DESC_FUENTES, gen(fuente)
/*         1 Aserrín o basura
           2 Baterías 'acumulador' (unidades)
           3 Biomasa
           4 Candelas y/o veladoras (unidades)
           5 Carbón (libras)
           6 Electricidad (Kw/hr)
           7 Energía eólica (Kw/hr)
           8 Energía hídrica (Kw/hr)
           9 Gas propano (libras)
          10 Kerosene 'gas corriente' (botellas)
          11 Leña (si solo la recogen y/o cortan, estime su val
          12 Panel solar (Kw/hr) */

sort NO_HOGAR 
keep NO_HOGAR fuente P01E02
label copy labels4 P01E02, replace 
label val P01E02 P01E02
reshape wide P01E02, i(NO_HOGAR) j(fuente)
label variable P01E021 "fuente de energía usada para Cocinar el mes pasado - Aserrín o basura"
label variable P01E022 "fuente de energía usada para Cocinar el mes pasado -  Baterías 'acumulador' "
label variable P01E023 "fuente de energía usada para Cocinar el mes pasado - Biomasa"
label variable P01E024 "fuente de energía usada para Cocinar el mes pasado -  Candelas y/o veladoras"
label variable P01E025 "fuente de energía usada para Cocinar el mes pasado -  Carbón"
label variable P01E026 "fuente de energía usada para Cocinar el mes pasado - Electricidad"
label variable P01E027 "fuente de energía usada para Cocinar el mes pasado - Energía eólica"
label variable P01E028 "fuente de energía usada para Cocinar el mes pasado -  Energía hídrica "
label variable P01E029 "fuente de energía usada para Cocinar el mes pasado -  Gas propano"
label variable P01E0210 "fuente de energía usada para Cocinar el mes pasado -  Kerosene gas corriente"
label variable P01E0211 "fuente de energía usada para Cocinar el mes pasado -  Leña"
label variable P01E0212 "fuente de energía usada para Cocinar el mes pasado -  Panel solar"

save fuentes_energia_cocina.dta, replace

************************************
**** merge de TODOS los módulos ****
************************************

use "$ruta\2023_Personas.dta", clear
merge m:1 NO_HOGAR using "$ruta\2023_Hogares.dta"
ta _merge
drop _merge
merge m:1 NO_HOGAR using "$ruta\fuentes_energia_cocina.dta"
ta _merge
drop _merge
rename *, lower

/****************************************************************************
  III. Verificar que merge se haya hecho correctamente y no hayan duplicados
*****************************************************************************/
duplicates report no_hogar cp

/*
--------------------------------------
   Copies | Observations       Surplus
----------+---------------------------
        1 |        46017             0
-------------------------------------- */

/***************************************************************************
  IV. Guardar la base
****************************************************************************/
compress
saveold "`base_out'", replace
