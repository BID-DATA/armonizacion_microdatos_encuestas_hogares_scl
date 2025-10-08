*(Versión stata 17)

clear
set more off

*________________________________________________________________________________________________________________*

* Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
* utilizar un loop)
* Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
* Se tiene acceso al servidor unicamente al interior del BID.
* El servidor contiene las bases de datos MECOVI.
*________________________________________________________________________________________________________________*
 
global ruta = "${surveysFolder}"

local PAIS GTM
local ENCUESTA ENEIC
local ANO "2024"
local ronda t1
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: GTM
Encuesta: ENEIC
Round: t1
Autores: 
Versión: Juan Camilo Perdomo (SCL/SCL) - Email: ..., Fecha: Octubre de 2025
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=.
	replace region_BID_c=1


	********************
	*** region_c ****
	********************
	gen region_c=p02a05b
	label define region_c  ///
    1 "Guatemala"  ///
    2 "El Progreso"  ///
    3 "Sacatepéquez"  ///
    4 "Chimaltenango"  ///
    5 "Escuintla"  ///
    6 "Santa Rosa"  ///
    7 "Sololá" ///
	8 "Totonicapán" ///
	9 "Quetzaltenango" ///
	10 "Suchitepéquez" ///
	11 "Retalhuleu" ///
	12 "San Marcos" ///
	13 "Huehuetenango" ///
	14 "Quiché" ///
	15 "Baja Verapaz" ///
	16 "Alta Verapaz" ///
	17 "Petén" ///
	18 "Izabal" ///
	19 "Zacapa" ///
	20 "Chiquimula" ///
	21 "Jalapa" ///
	22 "Jutiapa"
   label values region_c region_c

	*************
	* pais_c    *
	*************
	gen str3 pais_c="GTM"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=.
	* La variable corresponde al trimestre y siempre toma el valor 1

	******
	*zona*
	******
	gen zona_c=(p00a10==1)
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	*****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	gen idh_ch=num_hogar
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen new_id = string(num_hogar) + "_" + string(num_persona)
	gen idp_ci= new_id
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=factor_p
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=factor_h
	


	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
