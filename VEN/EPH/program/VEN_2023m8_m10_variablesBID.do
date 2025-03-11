* (Versión Stata 18)
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES -  
País: VEN
Encuesta: EPH
Round: m8_m10
Autores: Jillie Chang - jilliechangkcomt@gmail.com
Fecha última modificación: 14MAR2025

							SCL/SCL - IADB
****************************************************************************/
****************************************************************************/


******************************************************************
*****************  Definir rutas y abrir base ********************
******************************************************************

clear
set more off
 
global ruta = "${surveysFolderRestricted}"
local PAIS VEN
local ENCUESTA EPH
local ANO "2023"
local ronda m8_m10
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 

use "`base_in'", clear

******************************************************************
*****************  Armonización de variables  ********************
******************************************************************

	**************************
	***** Identificación *****
	**************************

************************
*** region según BID ***
************************
gen region_BID_c=3 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

************
* region_c *
************
gen region_c= 1 if estado ==5 
replace region_c=3 if estado ==1
replace region_c=5 if estado ==2
replace region_c=7 if estado ==3
replace region_c=8 if estado ==4
replace region_c=12 if estado ==6
replace region_c=13 if estado ==7
replace region_c=14 if estado ==8
replace region_c=15 if estado ==9
replace region_c=16 if estado ==10
replace region_c=17 if estado ==11
replace region_c=18 if estado ==12
replace region_c=20 if estado ==13
replace region_c=21 if estado ==14
replace region_c=23 if estado ==16
replace region_c=24 if estado ==15

label define region_c  ///
1	"Distrito Federal"  ///
2	"Amazonas " ///
3	"Anzoategui"  ///
4	"Apure " ///
5	"Aragua " ///
6	"Barinas " ///
7	"Bolívar " ///
8	"Carabobo " ///
9	"Cojedes " ///
10	"Delta Amacuro"  ///
11	"Falcón"  ///
12	"Guárico"  ///
13	"Lara"  ///
14	"Mérida"  ///
15	"Miranda"  ///
16	"Monagas"  ///
17	"Nueva Esparta"  /// 
18	"Portuguesa"  ///
19	"Sucre"  ///
20	"Táchira"  ///
21	"Trujillo"  ///
22	"Yaracuy"  ///
23	"Zulia"  ///
24	"Vargas" 
	    
label value region_c region_c
label var region_c " Primera División política - Entidades Federativas"

************
****pais****
************
gen str pais_c="VEN"

**********
***anio***
**********
gen anio_c=2021

*********
***mes***
*********
gen mes_c=.

**********
***zona***
**********
gen zona_c=.

***************
***estrato_ci**
***************
gen estrato_ci=.

***************
***upm_ci***
***************
gen upm_ci=.
label variable upm_ci "Unidad Primaria de Muestreo"

**************
*** idh_ch ***
**************
tostring id_hogar, gen(idh_ch) format("%20.0f")
egen unique_tag = tag(idh_ch)
count if unique_tag == 1 //se verifica que son 2000 hogares

**************
*** idp_ci ***
**************
tostring id_miembro, gen(idp_ci) format("%20.0f")
duplicates report idp_ci

***************
***factor_ci***
***************
gen factor_ci=peso_indiv_ajustado

***************
***factor_ch***
***************
gen factor_ch=peso_ajustado


