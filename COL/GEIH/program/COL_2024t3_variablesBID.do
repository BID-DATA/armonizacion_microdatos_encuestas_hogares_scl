*(Versión stata 17)

**# Bookmark #1
clear
set more off

*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: \\sapidbshares.file.core.windows.net\idbshares\SURVEYS
 * Se tiene acceso al servidor técnicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 

global ruta = "${surveysFolder}"


local PAIS COL
local ENCUESTA GEIH
local ANO "2024"
local ronda t3 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Colombia
Encuesta: GEIH
Round: t3
Autores: 
Versión ...:
Juan Camilo Perdomo (SCL/SCL) - Email: ..., Fecha: 24 de septiembre de 2025

*************************************************************************** */

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

		
		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************

**************
**Region_BID**
**************
gen region_BID_c=.
replace region_BID_c=3 

***************
***region_c ***
***************
gen region_c=real(dpto)
label define region_c       /// 
	5  "Antioquia"	        ///
	8  "Atlantico"	        ///
	11 "Bogota, D.C"	    ///
	13 "Bolivar" 	        ///
	15 "Boyace"	            ///
	17 "Caldas"	            ///
	18 "Caqueta"	        ///
	19 "Cauca"	            ///
	20 "Cesar"	            ///
	23 "Cordoba"	        ///
	25 "Cundinamarca"       ///
	27 "Choco"	            ///
	41 "Huila"	            ///
	44 "La Guajira"	        ///
	47 "Magdalena"	        ///
	50 "Meta"	            ///
	52 "Narino"	            ///
	54 "Norte de Santander"	///
	63 "Quindio"	        ///
	66 "Risaralda"	        ///
	68 "Santander"	        ///
	70 "Sucre"	            ///
	73 "Tolima"	            ///
	76 "Valle"	
label value region_c region_c

************
****pais_c****
************
g str3 pais_c = "COL"

**********
***anio_c***
**********
g anio_c = 2024

**********
***mes_c***
**********

destring mes, replace
gen mes_c=mes

**********
***zona_c***
**********
destring clase, replace
g zona_c = clase == 1

*********
*estrato*
*********
gen estrato_ci=.
	
*****************************
*unidad primaria de muestreo*
*****************************
gen upm_ci=.

***************
****idh_ch*****
***************
gen idh_ch = idh
tostring idh_ch, replace

**************
****idp_ci****
**************
g idp_ci=orden
tostring idp_ci, replace

***************
***factor_ci***
***************
g factor_ci=fex_c18

***************
***factor_ch***
***************
g factor_ch=fex_c18






