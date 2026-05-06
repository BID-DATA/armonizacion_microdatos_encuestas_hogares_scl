

* (Versión Stata 17)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 global ruta = "${surveysFolder}"

local PAIS GTM
local ENCUESTA ENCOVI
local ANO "2023"
local ronda m8_m12


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
*local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                                                    
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Guatemala
Encuesta: ENCOVI
Round: a
Autores: 
Última versión:Daniela Zuluaga: danielazu@iadb.org - da.zuluaga@hotmail.com
Última modificación: Pablo Cortés pabloacortess@gmail.com
Fecha última modificación: Octubre de 2017

							SCL/MIG - IADB
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/


use "`base_in'", clear


/*
foreach v of varlist _all {
      capture rename `v' `=lower("`v'")'
   }

*/




gen factor_ci=factor
label var factor_ci "Factor de Expansion del Individuo"
**************************************************************************************************************
* HOUSEHOLD VARIABLES
**************************************************************************************************************

	****************
	* region_BID_c *
	****************
	
* REGION

gen region_c=depto
	
gen region_BID_c=1
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c


gen factor_ch=factor 
label var factor_ch "Factor de expansion del Hogar"

* ZONA
gen byte zona_c=1 if area==1 /* Urbana */
replace zona_c=0 if area==2 /* Rural */
label variable zona_c "ZONA GEOGRAFICA"
label define zona_c 0 "Rural" 1 "Urbana"
label value zona_c zona_c

* COUNTRY - YEAR
gen str3 pais_c="GTM"
label variable pais_c "Nonmbre del Pais"

gen anio_c=2023
label variable anio_c "Año de la Encuesta"

* Periodo de Referencia: del 07/00 al 11/00.
* This is the middle of the reference period
gen byte mes_c=9
label variable mes_c "Mes de la Encuesta"

*sexo
gen sexo_ci=ppa02
label variable sexo "sex of the individual"
label var sexo_ci "sexo del individuo"
label define sexo_ci 1 "hombre" 2 "mujer"  
label value sexo_ci sexo_ci

* parentesco
gen relacion_ci=1 if ppa05==1
replace relacion_ci=2 if ppa05==2
replace relacion_ci=3 if (ppa05==4 | ppa05==3)
replace relacion_ci=4 if (ppa05==5 | ppa05==6 | ppa05==7 | ppa05==8 | ppa05==9 | ppa05==10  | ppa05==11)
replace relacion_ci=5 if (ppa05==13 | ppa05==14)
replace relacion_ci=6 if ppa05==12
label var relacion_ci "parentesco o relacion con el jefe del hogar"
label define relacion_ci 1 "jefe(a)" 2 "esposo(a) o compañero(a)" 3 "hijo(a)" 4 "otro pariente" 5 "otro no pariente" 6 "empleada domestica" 
label value relacion_ci relacion_ci
 
* ppa03
* 99 is the top-code, not that age is missing 
* meses is also available
gen edad_ci=ppa03
label var edad_ci "edad del individuo"

* identificador del hogar
gen idh_ch=no_hogar 
label var idh_ch "identificador unico del hogar"

* identificador de la persona
egen idp_ci=concat(no_hogar cp) 
label var idp_ci "identificador individual dentro del hogar"
duplicates report no_hogar cp


sort idh_ch idp_ci

egen nconyuges_ch=sum(relacion_ci==2), by (idh_ch)
label variable nconyuges_ch "numero de conyuges"

egen nhijos_ch=sum(relacion_ci==3), by (idh_ch)
label variable nhijos_ch "numero de hijos"
egen notropari_ch=sum(relacion_ci>3 & relacion_ci<5), by (idh_ch)
label variable notropari_ch "numero de otros parientes "
egen notronopari_ch=sum(relacion_ci==5), by (idh_ch)
label variable notronopari_ch "numero de otros no parientes "
egen nempdom_ch=sum(relacion_ci==6), by (idh_ch)
label variable nempdom_ch "numero de empleados domesticos"

* household type (unipersonal, nuclear, ampliado, compuesto, corresidentes)    
* note: these are all defined in terms of relationship to household head

gen clasehog_ch=.
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0 /* unipersonal*/
replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0 /* nuclear (child with or without spouse but without other relatives)*/
replace clasehog_ch=2 if nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0 /* nuclear (spouse with or without children but without other relatives)*/
replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0 /* ampliado*/
replace clasehog_ch=4 if (nconyuges_ch>0 | nhijos_ch>0 | (notropari_ch>0 & notropari_ch<.)) & (notronopari_ch>0 & notronopari_ch<.) /* compuesto  (some relatives plus non relative)*/
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0 & notronopari_ch<./** corresidente*/

label variable clasehog_ch "clase hogar"
label define clasehog_ch 1 "unipersonal" 2 "nuclear" 3 "ampliado" 4 "compuesto" 5 "corresidente"
label value clasehog_ch clasehog_ch



* household composition variables 
/* note: these are unrelated to who is the head
   note: that childh denotes the number of children of the head, while numkids counts the number of all kids in the household */

sort idh_ch

* number of persons in the household (not including domestic employees or other relatives)
egen nmiembros_ch=sum(relacion_ci>0 & relacion_ci<5 ), by (idh_ch)
label variable nmiembros_ch "numero de miembros en el hogar"

egen nmayor21_ch=sum((relacion_ci>0 & relacion_ci<5 ) & (edad>=21)), by (idh_ch)
label variable nmayor21_ch "numero de personas de 21 años o mas dentro del hogar"

egen nmenor21_ch=sum((relacion_ci>0 & relacion_ci<5 ) & (edad<21)), by (idh_ch)
label variable nmenor21_ch "numero de personas menores a 21 años dentro del hogar"

egen nmayor65_ch=sum((relacion_ci>0 & relacion_ci<5 ) & (edad>=65)), by (idh_ch)
label variable nmayor65_ch "numero de personas de 65 años o mas dentro del hogar"

egen nmenor6_ch=sum((relacion_ci>0 & relacion_ci<5 ) & (edad<6)), by (idh_ch)
label variable nmenor6_ch "numero de niños menores a 6 años dentro del hogar"

egen nmenor1_ch=sum((relacion_ci>0 & relacion_ci<5 ) & (edad<1)),  by (idh_ch)
label variable nmenor1_ch "numero de niños menores a 1 año dentro del hogar"



*** estado civil para personas de 10 años o mas de ppa03
gen civil_ci=.  
replace civil_ci=1 if ppa08==1 /* soltero */
replace civil_ci=2 if ppa08==2 | ppa08==3 /* union formal o informal */
replace civil_ci=3 if ppa08==4 | ppa08==5 | ppa08==6 /* separado o divorciado */
replace civil_ci=4 if ppa08==7 /* viudo */
label var civil_ci "estado civil"
label define civil_ci 1 "soltero" 2 "union formal o informal" 3 "divorciado o separado" 4 "viudo"
label value civil_ci civil_ci
tab ppa08 civil_ci

*** reported head of household
gen jefe_ci=0
replace jefe_ci=1 if relacion_ci==1
label var jefe_ci "jefe de hogar declarado"

*** we want to know if there is only one head in each hh and if there is a hh with no head:
egen hh=sum(jefe_ci), by (idh_ch)
capture assert hh==1



gen byte miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"
tab ppa05 miembros_ci  


***************
***upm_ci***
***************

clonevar upm_ci=upm
label variable upm_ci "Unidad Primaria de Muestreo"

***************
***estrato_ci***
***************

gen estrato_ci=.
label variable estrato_ci "Estrato"

*** housing ***




         ******************************
         *** VARIABLES DE DIVERSIDAD **
         ******************************
* Pablo Cortés
		 *Feb 2021	

***************
***afroind_ci***
***************

*2021 ppa06 (1 xinca; 2 garifuna; 3 ladino; 4 extranjero; 5 maya) 
   /* 2022 1 Xinka 1
           2 Garífuna 1 
           3 Ladino 
           4 Afrodescendiente/Creole/Afro mestizo
           5 Extranjero
           6 Maya 1 */
		   
gen afroind_ci=. 
replace afroind_ci=1  if p04a07 == 1 | p04a07 ==2 | p04a07 ==3
replace afroind_ci=2  if p04a07 == 4
replace afroind_ci=3 if p04a07 == 5 | p04a07 == 6
replace afroind_ci=. if p04a07 ==.

label variable afroind_ci "Identificación étnica del individuo"
label define afroind_ci 1 "Indígena" 2 "Afrodescendiete" 3 "Otros" 9 "No se le pregunta"
label value afroind_ci afroind_ci


***************
***afro_ci***
***************

*2021 ppa06 (1 xinca; 2 garifuna; 3 ladino; 4 extranjero; 5 maya) 
   /* 2022 1 Xinka 1
           2 Garífuna 1 
           3 Ladino 
           4 Afrodescendiente/Creole/Afro mestizo
           5 Extranjero
           6 Maya 1 */
		   
gen afro_ci=. 
replace afro_ci=0  if p04a07 == 1 | p04a07 ==2 | p04a07 ==3
replace afro_ci=1  if p04a07 == 4
replace afro_ci=0 if p04a07 == 5 | p04a07 == 6
replace afro_ci=. if p04a07 ==.

label variable afro_ci "Identificación étnica del individuo"
label define afro_ci  1 "Afrodescendiete" 0 "Otros" 
label value afro_ci afro_ci

***************
***afroind_ch***
***************
	
* Identificación étnica del hogar según indentificación del jefe de hogar. 
gen afroind_jefe= afroind_ci if relacion_ci==1 
egen afroind_ch  = min(afroind_jefe), by(idh_ch) 
drop afroind_jefe

***************
***afro_ch***
***************
	
* Identificación étnica del hogar según indentificación del jefe de hogar. 
gen afro_jefe= afro_ci if relacion_ci==1 
egen afro_ch  = min(afro_jefe), by(idh_ch) 
drop afro_jefe

* br hogar_num id idh_ch relacion_ci afroind_ci afroind_jefe afroind_ch 


***************
***ind_ci***
***************

*2021 ppa06 (1 xinca; 2 garifuna; 3 ladino; 4 extranjero; 5 maya) 
   /* 2022 1 Xinka 1
           2 Garífuna 1 
           3 Ladino 
           4 Afrodescendiente/Creole/Afro mestizo
           5 Extranjero
           6 Maya 1 */
		   
gen ind_ci=. 
replace ind_ci=1  if p04a07 == 1 | p04a07 ==2 | p04a07 ==3
replace ind_ci=0  if p04a07 == 4
replace ind_ci=0 if p04a07 == 5 | p04a07 == 6
replace ind_ci=. if p04a07 ==.

label variable ind_ci "Identificación étnica del individuo"
label define ind_ci  1 "Indígena" 0 "Otros" 
label value afro_ci afro_ci


***************
***ind_ch***
***************
	
* Identificación étnica del hogar según indentificación del jefe de hogar. 
gen ind_jefe= ind_ci if relacion_ci==1 
egen ind_ch  = min(ind_jefe), by(idh_ch) 
drop ind_jefe


*****************
***noafroind_ci**
*****************

		gen byte noafroind_ci = . 
		replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
		replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1

***************
***noafroind_ch***
***************
		gen noafroind_jefe = noafroind_ci if relacion_ci == 1
		egen noafroind_ch = min(noafroind_jefe), by(idh_ch) 
		drop noafroind_jefe




*******************
***afroind_ano_c***
*******************

* Identifica el año en que se comenzó a utilizar en cada encuesta la metodología de medición de raza/etnicidad. 
gen afroind_ano_c=2014

*******************
***dis_ci***
*******************

gen dis_ci=0
replace dis_ci=1 if ppa07a > 1 | ppa07b > 1 | ppa07c > 1 | ppa07d > 1 | ppa07e > 1 | ppa07f > 1 
replace dis_ci= . if ppa07a >= 9 | ppa07b >= 9 | ppa07c >= 9 | ppa07d >= 9 | ppa07e >= 9 | ppa07f >= 9
replace dis_ci= . if ppa07a == . | ppa07b == . | ppa07c == . | ppa07d == . | ppa07e == . | ppa07f == .

*******************
***disWG_ci***
*******************

gen disWG_ci=0
replace disWG_ci=1 if ppa07a > 2 | ppa07b > 2 | ppa07c > 2 | ppa07d > 2 | ppa07e > 2 | ppa07f > 2 
replace disWG_ci= . if ppa07a >= 9 | ppa07b >= 9 | ppa07c >= 9 | ppa07d >= 9 | ppa07e >= 9 | ppa07f >= 9
replace disWG_ci= . if ppa07a == . | ppa07b == . | ppa07c == . | ppa07d == . | ppa07e == . | ppa07f == .

	
*******************
***dis_ch***
*******************

gen dis_ch=. 





gen luz_ch=.

replace luz_ch=1 if p01d24==1
replace luz_ch=0 if p01d24==2

gen luzmide_ch=.
replace luzmide_ch=1 if p01a05f==1
replace luzmide_ch=0 if p01a05f==2

****************
** combust_ch **
****************

*/En el 2022 se utilizaba la variable  p02b05 ¿Qué fuente de energía utiliza principal-mente este hogar para cocinar? Electricidad 1 Gas Propano 2 Gas corriente o kerosene  3 Leña 4 Carbón  5 No cocina 6 */
* donde combust_ch = 1 si la respuesta es 1, 2 o 3 
*En el 2023, se  utilizó la pregunta más próxima P01E02: El mes pasado, qué fuente de energía utilizó en su hogar para Cocinar todos sus alimentos? 
/*
P01E021 "fuente de energía usada para Cocinar el mes pasado - Aserrín o basura"
P01E022 "fuente de energía usada para Cocinar el mes pasado -  Baterías 'acumulador' "
P01E023 "fuente de energía usada para Cocinar el mes pasado - Biomasa"
P01E024 "fuente de energía usada para Cocinar el mes pasado -  Candelas y/o veladoras"
P01E025 "fuente de energía usada para Cocinar el mes pasado -  Carbón"
P01E026 "fuente de energía usada para Cocinar el mes pasado - Electricidad"
P01E027 "fuente de energía usada para Cocinar el mes pasado - Energía eólica"
P01E028 "fuente de energía usada para Cocinar el mes pasado -  Energía hídrica "
P01E029 "fuente de energía usada para Cocinar el mes pasado -  Gas propano"
P01E0210 "fuente de energía usada para Cocinar el mes pasado -  Kerosene gas corriente"
P01E0211 "fuente de energía usada para Cocinar el mes pasado -  Leña"
P01E0212 "fuente de energía usada para Cocinar el mes pasado -  Panel solar"

Para cada opción las alternativas son 
1. Regularmente 2. Ocasionalmente 3. Rara vez 9. Nunca
Se consideraron las categorías 1, 2. 
*/
gen combust_ch=0
replace combust_ch = 1 if inlist(p01e026,1,2) | inlist(p01e029,1,2) | inlist(p01e0210,1,2) 
replace combust_ch = . if p01e021==9& p01e022==9& p01e023==9& p01e024==9& p01e025==9& p01e026==9& p01e027==9& p01e028==9& p01e029==9& p01e0210==9& p01e0211==9& p01e0212==9


gen des1_ch=.
replace des1_ch=0 if p01d16==5
replace des1_ch=1 if p01d16==1 | p01d16==2 | p01d16==3
replace des1_ch=2 if p01d16==42

 
gen des2_ch=.
replace des2_ch=0 if p01d16==5
replace des2_ch=1 if p01d16==1 | p01d16==2 | p01d16==3 | p01d16==4


gen piso_ch=.
replace piso_ch=0 if p01a04==7
replace piso_ch=1 if p01a04>=1 & p01a04<=6
replace piso_ch=2 if p01a04==98

gen pared_ch=.
replace pared_ch=0 if p01a02==7 | p01a02==8
replace pared_ch=1 if p01a02>=1 & p01a02<=6
replace pared_ch=2 if p01a02==98

gen techo_ch=.
replace techo_ch=0 if p01a03==5 
replace techo_ch=1 if p01a03>=1 & p01a03<=4
replace techo_ch=2 if p01a03==98

gen resid_ch=.
replace resid_ch=0 if p01d22==1 | p01d22==2
replace resid_ch=1 if p01d22==3 | p01d22==4
replace resid_ch=2 if p01d22==5
replace resid_ch=3 if p01d22==6 | p01d22==98


**Daniela Zuluaga- Enero 2018: Se agregan las variables aguamejorada_ch y banomejorado_ch cuya sintaxis fue elaborada por Mayra Saenz**
	
*********************
***aguamejorada_ch***
*********************
/*
g       aguamejorada_ch = 1 if (p01d06 >=1 & p01d06  <=4) | p01d06  ==7
replace aguamejorada_ch = 0 if (p01d06  >=5 & p01d06  <=6) | p01d06  ==98
	*/
	
*********************
***banomejorado_ch***
*********************
/*
g       banomejorado_ch = 1 if (p01d17 >=1 & p01d17 <=4) & p01d18 == 1
replace banomejorado_ch = 0 if ((p01d17 >=1 & p01d17 <=4) & p01d18 == 2) & p01d17 ==5 
*/

gen dorm_ch=.
replace dorm_ch=p01d02 if p01d02>=0

gen cuartos_ch=.
replace cuartos_ch= p01d01 if  p01d01>=0

gen cocina_ch=.
replace cocina_ch=1 if p01d04==1
replace cocina_ch=0 if p01d04>=2 & p01d04<=7

gen telef_ch=.
replace telef_ch=1 if p01d20b==1
replace telef_ch=0 if p01d20b==2

gen refrig_ch=.


gen freez_ch=.

gen auto_ch=.


gen compu_ch=.

gen internet_ch=.
replace internet_ch=1 if  p01d20d ==1 
replace internet_ch=0 if  p01d20d ==2

gen cel_ch=.
replace cel_ch=1 if p01d20c==1
replace cel_ch=0 if p01d20c==2

gen vivi1_ch=.
replace vivi1_ch=1 if p01a01==1
replace vivi1_ch=2 if p01a01==2
replace vivi1_ch=3 if p01a01>=3 & p01a01<=98

gen vivi2_ch=.
replace vivi2_ch=1 if vivi1_ch==1 | vivi1_ch==2
replace vivi2_ch=0 if vivi1_ch==3

gen viviprop_ch=.
replace viviprop_ch=0 if p01b01==3
replace viviprop_ch=1 if p01b01==1
replace viviprop_ch=2 if p01b01==2
replace viviprop_ch=3 if p01b01==4 | p01b01==98

gen vivitit_ch=.


gen vivialq_ch=.
replace vivialq_ch=p01b03 if p01b03<99999

gen vivialqimp_ch=.
replace vivialqimp_ch=p01b02 if p01b02<99999


 ******************************
 ***  VARIABLES DE VIVIENDA  **
 ******************************

****************
***aguared_ch***
****************

		generate aguared_ch =.
		replace aguared_ch = 1 if p01a05a==1
		replace aguared_ch = 0 if p01a05a==2
		la var aguared_ch "Acceso a fuente de agua por red"

		*****************
		*aguafconsumo_ch*
		*****************

		gen aguafconsumo_ch = 0
		replace aguafconsumo_ch = 1 if (p01d06==1 | p01d06==2) & p01d06!=5
		replace aguafconsumo_ch = 2 if p01d06==3 & p01d06!=5
		*replace aguafconsumo_ch = 3 if p01d06==5 
		replace aguafconsumo_ch = 4 if p01d06==4 & p01d06!=5

		replace aguafconsumo_ch = 5 if p01d06==7 & p01d06!=5
		replace aguafconsumo_ch = 6 if p01d06==6 & p01d06!=5
		*replace aguafconsumo_ch = 8 if p01d06==5 
		replace aguafconsumo_ch = 10 if p01d06==5




*****************
*aguafuente_ch*
*****************
/*
Ubicación de la principal fuente de agua
1 Adentro de la casa
2 Afuera de la casa pero adentro del terreno (o a menos de 100mts de distancia)
3 Afuera de la casa y afuera del terreno (o a más de 100mts de distancia)
    1 Tubería_dentro
    2 Tubería_fuera
    3 Chorro_público
    4 Pozo
    5 Río_lago
    6 Camión
    7 Lluvia
    8 Otro (98 en el 2021)
 */
gen aguafuente_ch=.
		replace aguafuente_ch = 1 if (p01d06==1 | p01d06==2) & p01d06!=5
		replace aguafuente_ch = 2 if p01d06==3 & p01d06!=5
	   *replace aguafuente_ch = 3 if p01d06==5 
		replace aguafuente_ch = 4 if p01d06==4 & p01d06!=5

		replace aguafuente_ch = 5 if p01d06==7 & p01d06!=5
		replace aguafuente_ch = 6 if p01d06==6 & p01d06!=5
	   *replace aguafuente_ch = 8 if p01d06==5 
		replace aguafuente_ch = 10 if p01d06==5

*************
*aguadist_ch*
*************
gen aguadist_ch= 9


**************
*aguadisp1_ch*
**************

gen aguadisp1_ch =9

**************
*aguadisp2_ch*
**************

gen aguadisp2_ch = .
		replace aguadisp2_ch = 1 if p01d11 < 15 
		replace aguadisp2_ch = 2 if (p01d11 >= 15 & p01d11 < 30)
		replace aguadisp2_ch = 3 if (p01d11 >= 30)

**************
*aguatrat_ch*
**************

gen aguatrat_ch = .
		replace aguatrat_ch = 1 if p01d16 <5
		replace aguatrat_ch = 0 if p01d16 == 5


*************
*aguamala_ch*  Altered
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7 

*****************
***aguamide_ch***
*****************
gen aguamide_ch = 1 if  p01a05e==1
replace aguamide_ch =  0 if p01a05e==2
label var aguamide_ch "Usan medidor para pagar consumo de agua"
	
*****************
*bano_ch         *  Altered
*****************
gen bano_ch=.
replace bano_ch=0 if p01d17 == 5
replace bano_ch=1 if p01d17 == 1
replace bano_ch=2 if p01d17 == 2
replace bano_ch=6 if p01d17==3 | p01d17==4


***************
***banoex_ch***
***************
generate banoex_ch=0

replace bano_ch=1 if p01d18 == 1

la var banoex_ch "El servicio sanitario es exclusivo del hogar"

*****************
*banomejorado_ch*  Altered
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

************
*sinbano_ch*
************
gen sinbano_ch = 9

*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"



/*
************
***luz_ch***
************
g luz_ch=0
replace luz_ch=1 if p02b05==1 | p02a05c==1
label var luz_ch  "La principal fuente de iluminación es electricidad"

****************
***luzmide_ch***
****************
recode p02a05f (1=1 Si) (else=0 No), g (luzmide_ch)
label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

****************
***combust_ch***
****************
recode p02b05 (1/3=1 Sí) (else=0 No), g(combust_ch)
label var combust_ch "Principal combustible gas o electricidad" 

******************************
*	des1_ch
******************************
g des1_ch=0 if p02b07==5 //no tiene
replace des1_ch=1 if p02a05b==1 | p02b07==1 | p02b07==2 //red drenaje y fosa séptica
replace des1_ch=2 if p02b07==4 //letrina
replace des1_ch=3 if p02b07==3 //excusado

*/


*******************************************************************************************
* variables del mercado laboral

* personas de 5 años y mas de ppa03 *
* en 1998 este bloque de preguntas estaba dirigido a las personas de 7 años y mas de ppa03 *
*******************************************************************************************
/************************************************************************************************************
* 3. creación de nuevas variables de ss and lmk a incorporar en armonizadas
************************************************************************************************************/

*************
**salmm_ci***
*************

*1 = GUA 2023
gen salmm_ci= 101.05
label var salmm_ci "Salario minimo legal"

*********
*lp_ci***
*********

gen lp_ci =.
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci**
*********

gen lpe_ci =.
label var lpe_ci "Linea de indigencia oficial del pais"

/************************************************************************************************************
* 3. Creación de nuevas variables de SS and LMK a incorporar en Armonizadas
************************************************************************************************************/

gen condocup_ci=.
replace condocup_ci=1 if ocupados ==1 
replace condocup_ci=2 if desocupados ==1
replace condocup_ci=3 if inactivos ==1  & edad_ci>=7 & edad_ci!=.
replace condocup_ci=4 if edad<7

label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 7" 
label value condocup_ci condocup_ci

****************
*cotizando_ci***
****************

* MGD 11/16: es lo mismo que afiliados
* SGR 05/10/2017: se modifica line 1
* gen cotizando_ci=1 if p04c25a==1 & p04c25b>0 & p04c25a!=.
* 2021: P04C25A(afiliado) y P04C25B(monto)

gen cotizando_ci=1 if  p10c08a == 1 
recode cotizando_ci .=0 if condocup_ci==1 | condocup_ci==2
label var cotizando_ci "Cotizante a la Seguridad Social"

* Formalidad sin restringir PEA
* SGR 05/10/2017: se modifica line 1
* gen cotizando_ci1=1 if p04c25a==1 & p04c25b>0 & p04c25a!=.
gen cotizando_ci1=1 if p05c07a==1 & p05c07b>0 & p05c07b!=.
recode cotizando_ci1 .=0 if condocup_ci>=1 & condocup_ci<=3
label var cotizando_ci1 "Cotizante a la Seguridad Social"
	
****************
*afiliado_ci****
****************

gen afiliado_ci=.	
replace afiliado_ci=1 if  p10c08a == 1
replace afiliado_ci=0 if condocup_ci==2
label var afiliado_ci "Afiliado a la Seguridad Social"

****************
*tipopen_ci*****
****************

gen tipopen_ci=.
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

****************
*instpen_ci*****
****************

gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 

****************
*instcot_ci*****
****************

gen instcot_ci=.
label var instcot_ci "Institucion proveedora de la pension - variable original de cada pais" 



	

************
***emp_ci***
************
gen byte emp_ci=(condocup_ci==1)
label var emp_ci "Ocupado (empleado)"

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)
label var desemp_ci "Desempleado que busca empleo en el periodo de referencia"
  
*************
***pea_ci***
*************
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1
label var pea_ci "PoblaciÃ³n EconÃ³micamente Activa"

*************
**pension_ci*
*************

*2021: P05A05B Monto recibido por jubilaciones o pensiones, durante los últimos 3 meses
gen pension_ci=1 if p11a05b>0 & p11a05b!=.
recode pension_ci .=0 
label var pension_ci "1=Recibe pension contributiva"
	
*************
**cesante_ci*
*************

gen cesante_ci=1 if desemp_ci == 1 & p10b09 == 1
replace cesante_ci=0 if desemp_ci == 0
label var cesante_ci "desocupado - definicion oficial del pais"	

*************
**ypen_ci*
*************

gen ypen_ci=p11a05b/3 if p11a05b>0 & p11a05b!=.
label var ypen_ci "Valor de la pension contributiva"

*****************
**ypensub_ci*
*****************

gen byte ypensub_ci=.
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

***************
*pensionsub_ci*
***************

gen pensionsub_ci=.
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*****************
***desalent_ci***
*****************

/*2021 P04B04	
	3	No hay trabajo en la actualidad
	4	Hay trabajo pero no se lo dan a él (ella)
	5	Se cansó de buscar trabajo
 2022 P05B05F	
	4	No hay trabajo en la actualidad
	5	Hay trabajo pero no se lo dan
	6	Se cansó de buscar trabajo */
g desalent_ci = .
replace desalent_ci=(emp_ci==0 & ((p10b05 >= 4 & p10b05 <= 6) | (p10b05 >= 8 & p10b05 <= 11)) )
label var desalent_ci "Trabajadores desalentados"

*****************
***horaspri_ci***
*****************


*2023: p10e01c Horas trabajadas en la semana en la acitvidad principal*/
gen horaspri_ci = p10e01a if emp_ci==1
replace horaspri_ci=. if emp_ci==0
label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"

*****************
***horastot_ci***
*****************

egen horastot_ci=rsum(p10e01c) if emp_ci==1, missing /*adding secondary employment and extra time*/
label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"

******************************
*	subemp_ci
******************************

g subemp_ci=0 
replace subemp_ci=1 if emp_ci==1 & horaspri_ci<=30 & p10e02==1 & p10e04 > 0  //trabaja -30h, disponible y puede + horas
label var subemp_ci "Personas en subempleo por horas"

*******************
***tiempoparc_ci***
*******************

* MGR: Modifico serie en base a correcciones Laura Castrillo: se debe utilizar horaspri en lugar de horastot como había sido generada antes
g tiempoparc_ci=(emp_ci==1 & p10e02==2 & (horaspri_ci>=1 & horaspri_ci<30))
replace tiempoparc_ci=. if emp_ci != 1 | p10e02 == . | horaspri_ci == .
label var tiempoparc_ci "Personas que trabajan medio tiempo" 



******************
***categopri_ci***
******************

/**2021 p04c06 
   2022 p05c20 
           1 Empleado de gobierno
           2 Empleado de empresa privada
           3 Empleado jornalero o peón
           4 En el servicio doméstico
           5 Trabajador por cuenta propia NO agrícola
           6 Patrón empleador (a) socio (a) NO agrícola
           7 Trabajador por cuenta propia agrícola
           8 Patrón empleador (a) socio (a) agrícola
           9 Trabajador No remunerado (Familiar o No familiar)
        9999 Ignorado
*/
recode p10c21 (6 8=1 "Patrón") (5 7=2 "Cuenta Propia") (1/4=3 "Empleado") (9=4 "No remunerado") (else=.),g ( categopri_ci )
label variable categopri_ci "Categoria ocupacional"

******************
***categosec_ci***
******************
/*
p04d05 En este segundo trabajo usted es? 
1	Empleado de gobierno
2	Empleado de empresa privada
3	Empleado jornalero o peón
4	En el servicio doméstico
5	Trabajador por cuenta propia NO agrícola
6	Patrón empleador (a) socio (a) NO agrícola
7	Trabajador por cuenta propia agrícola
8	Patrón empleador (a) socio (a) agrícola
9	Trabajador No remunerado (Familiar o No familiar)
*/
recode p10d07 (6 8=1 "Patron") (5 7=2 "Cuenta propia") (1/4=3 "Empleado") (9=4 "No remunerado") (else=.),g ( categosec_ci )
label variable categosec_ci "Categoria ocupacional trabajo secundario"

*****************
*tipocontrato_ci*
*****************

* 2021 P04C08A EL CONTRATO ES 1 Por tiempo indefinido 2 Temporal. P04C07 TIENE CONTRATO 1 Si 2 No
* 2022 P05C23A el contrato es 1 Por tiempo indefinido 2 Temporal. P05C22 Contrato de trabajo 1 Sí 2No
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if (p10c24a==1 & p10c23==1) & categopri_ci==3
replace tipocontrato_ci=2 if (p10c24a==2 & p10c23==1)  & categopri_ci==3
replace tipocontrato_ci=3 if (p10c23==2 | tipocontrato_ci==.) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

*****************
***nempleos_ci***
*****************

*2021 P04C01 TRABAJOS: 1 Un solo trabajo 2	Dos trabajos 3	Tres o más trabajos
* 2022 se cambió condiciones porque en la categoría nempleos_ci=2 se incluían los p05c01 ==9999
gen nempleos_ci=.
replace nempleos_ci=1 if emp_ci==1 & p10c01==1 //ocupado con empleo con 1 empleo
replace nempleos_ci=2 if emp_ci==1 & p10c01>=2 //ocupado con 1 o + empleos
replace nempleos_ci=. if p05c01 ==9999 | p10c01==.
label var nempleos_ci "Número de empleos" 

******************************
*	spublico_ci 
******************************

gen spublico_ci= (p10c21 == 1) 
replace spublico_ci=. if emp_ci==0 
la var spublico_ci "Trabaja en sector publico"


*************
**ocupa_ci***
*************

*Modificaciion SGR se agrega en la categoria 8 el p04c02b_2d==0 
* 2021 p04c02b_2d ocupación a dos dígitos
gen ocupa_ci=.
replace ocupa_ci=1 if (p10c02_2d >=21 & p10c02_2d <=35) & emp_ci==1
replace ocupa_ci=2 if (p10c02_2d >=11 & p10c02_2d <=14) & emp_ci==1
replace ocupa_ci=3 if (p10c02_2d >=41 & p10c02_2d <=44) & emp_ci==1
replace ocupa_ci=4 if (p10c02_2d ==52 | p10c02_2d ==95) & emp_ci==1
replace ocupa_ci=5 if (p10c02_2d ==51 | (p10c02_2d >=53 & p10c02_2d <=54) | p10c02_2d ==91) & emp_ci==1
replace ocupa_ci=6 if ((p10c02_2d >=61 & p10c02_2d <=63) | p10c02_2d ==92) & emp_ci==1
replace ocupa_ci=7 if ((p10c02_2d >=71 & p10c02_2d <=83) | p10c02_2d ==93) & emp_ci==1
*replace ocupa_ci=8 if (p05c02b_2d >=1 & p05c02b_2d <=3) & emp_ci==1
replace ocupa_ci=8 if (p10c02_2d >=0 & p10c02_2d <=3) & emp_ci==1
replace ocupa_ci=9 if (p10c02_2d ==94 | p10c02_2d ==96) & emp_ci==1
label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci

*************
**rama_ci****
*************

* 2021 p04c04b_2d actividad a dos dígitos
gen rama_ci=.
replace rama_ci=1 if p10c03_2d >=1 & p10c03_2d <=3
replace rama_ci=2 if p10c03_2d >=5 & p10c03_2d <=9
replace rama_ci=3 if p10c03_2d >=10 & p10c03_2d <=33
replace rama_ci=4 if p10c03_2d >=35 & p10c03_2d <=39
replace rama_ci=5 if p10c03_2d >=41 & p10c03_2d <=43
replace rama_ci=6 if (p10c03_2d >=45 & p10c03_2d <=47) | (p10c03_2d >=55 & p10c03_2d <=56)
replace rama_ci=7 if (p10c03_2d >=49 & p10c03_2d <=53) | p10c03_2d ==61 
replace rama_ci=8 if p10c03_2d >=64 & p10c03_2d <=68
replace rama_ci=9 if (p10c03_2d >=69 & p10c03_2d <=99) | (p10c03_2d >=58 & p10c03_2d <=60) | (p10c03_2d >=62 & p10c03_2d <=63)
label var rama_ci "Rama de actividad de la ocupación principal"
label val rama_ci rama_ci
label var rama_ci "Rama de actividad"
label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7 "Transporte y almacenamiento", add
label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val rama_ci rama_ci

************
*durades_ci*
************


gen durades_ci=.
replace durades_ci= (p10b04/4.3) 
replace durades_ci=0.23 if p10b04==0
label variable durades_ci "Duracion del desempleo en meses"

******************
**antiguedad_ci***
******************

* Variable para la actividad secundaria. MGD 09/30/2014
/*gen mesaanio= (p04d17a/12)
egen antiguedad_ci=rsum(p04d17b mesaanio) if emp_ci==1, m*/
*SGR ModificaciÃ³n 22/01/2018 Las variables estaban intercambiadas
*2021 ¿Cuánto tiempo lleva (…….) trabajando en esta empresa, negocio o finca? P04C31A AÑOS P04C31B MESES
g mes_ant = (p10c12b/12)
egen antiguedad_ci= rsum(p10c12a mes_ant) if emp_ci==1,m
egen antiguedad_civ= rsum(p10c12a mes_ant) if emp_ci==1
replace antiguedad_ci =. if p10c12b==9999 // se agrega condición

*******************
***tamemp_ci***
*******************  
  
*Guatemala Pequeña 1 a 5, Mediana 6 a 50, Grande Más de 50
*2021 p04c05
/*2022 p05c43 se cambiaron categorias
		   1 1 persona 
           2 2 persona
           3 3 persona
           4 4 persona
           5 5 persona
           6 De 6 a 10
           7 De 11 a 50
           8 De 51 a 100
           9 De 101 a 200
          10 De 201 a 500
          11 De 501 o más
        9999 Ignorado
*/
gen tamemp_ci = 1 if p10c43>=1 & p10c43<=5
replace tamemp_ci = 2 if (p10c43>=6 & p10c43 <= 7) // decía  p04c05<=50, se cambia 50 por 7
replace tamemp_ci = 3 if (p10c43>7) & p10c43 != .
replace tamemp_ci =. if p10c43==9999 //se agrego esta condición
tab tamemp_ci
label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci
label var tamemp_ci "Tamaño de empresa"
  
*******************
***categoinac_ci***
*******************
/*
2021 p04a02
	3	Estudiar					
	4	Quehaceres del hogar		
	5	Jubilado(a) o pensionado(a) 
2022 p05a02
	4	Estudiar			  
	5	Quehaceres del Hogar  
	6	Jubilado o pensionado 
*/

gen categoinac_ci = .
replace categoinac_ci = 1 if  (p10a02==6 & condocup_ci==3)
replace categoinac_ci = 2 if  (p10a02==4 & condocup_ci==3)
replace categoinac_ci = 3 if  (p10a02==5 & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 
	
*******************
***formal***
*******************

* afiliado, cotizan con monto+, ocupado y año de la encuesta mayor a 1998
gen formal=1 if cotizando_ci==1
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c>1998
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008


gen byte formal_ci=.
replace formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
replace formal_ci=0 if formal_ci==. & (condocup_ci==1 | condocup_ci==2) 
label var formal_ci "1=afiliado o cotizante / PEA"

* Formalidad sin restricción a PEA
gen formal_1=0 if (condocup_ci>=1 & condocup_ci<=3)
replace formal_1=1 if cotizando_ci1==1
replace formal_1=1 if afiliado_ci==1 & (cotizando_ci1!=1 | cotizando_ci1!=0) & pais_c=="CRI"




         ******************************
         ***  VARIABLES DE INGRESOS  **
         ******************************

***************
***ylmpri_ci***
***************

foreach var of varlist p10c30b p10c31b  p10c32b p10c33b p10c34b{ 
g `var'tdp=`var'/12 
}
*egen ylmpri_ci= rsum(p04c10 p04c11c p04c12b *tdp), missing
*Mayra Sáenz Agosto, 2014: Los comentarios corresponden a la base de 2012, pero se conserva para futuras revisiones.
*MLO cambio esta restricccion: * Se excluye a las variables p04c22 p04c23 que tienen que ver con las ganancias netas de la actividad.
/* 
2021 (2022)
P04C13B	(p05c29b) CUÁNTO DINERO RECIBIÓ ¿Cuánto le pagaron por trabajar en su período vacacional? 
P04C14B	(p05c30b) CUÁNTO DINERO RECIBIÓ bono 14
P04C15B	(p05c31b) CUÁNTO DINERO RECIBIÓ aguinaldo
P04C16B	(p05c32b) CUÁNTO DINERO RECIBIÓ bono vacacional
P04C17B	(p05c33b) CUÁNTO DINERO RECIBIÓ algún quinceavo sueldo o diferido
P04C21B	(p05c37b) CUÁNTO DINERO RECIBIÓ bonos de productividad, de desempeño o por estímulos laborales
No incluye lo que recibió por alimentación/subsidio, vivienda, transporte recibidos en el trabajo
*/

egen ylmpri_ci = rsum(p10c27 p10c28c p10c29b  *tdp), missing
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 

*****************
***nrylmpri_ci***
*****************

g nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)
replace nrylmpri_ci=. if emp_ci!=1 | categopri_ci==4 /*excluding unpaid workers*/
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  

****************
***ylnmpri_ci***
****************

/*2021 (2022)
p04c18b (p05c34b) Valoración de los alimentos recibidos en el trabajo
p04c19b (p05c35b) Valoración del costo de la vivienda recibida en el trabajo
p04c20b (p05c36b) Valoración del costo del transporte recibido en el trabajo
*/
egen ylnmpri_ci=rsum(p10c36b p10c36b p10c37b), missing
label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal"   

***************
***ylmsec_ci***
***************
/*
2021 (2022)
p04d08b (------) Quinceavo sueldo, Bono vacacional, bonos de productividad, bonos de desempeño o estímulos laborales 2da ocu
p04d10b(p05d11b) bono 14 2da ocu
p04d11b (p05d12b) aguinaldo 2da ocu

p04d06 (p05d08) sueldo o salario mensual sin descuentos segundo trabajo 2da ocu
p04d09b(p05d10b) horas extras,comisiones, dietas o propinas 2da ocu
p04d12 (p05d13) ingreso neto o ganancia mensual de su empresa, negocio, actividad o profesión, después de gastos 2da ocu
p04d13 (----- ) ganancia o ingreso neto mensual por venta de cosechas, animales y/o subproductos agropecuarios 2da ocu
*/
foreach var of varlist p10d12b p10d13b{
g `var'tdpsec=`var'/12
}

egen ylmsec_ci=rsum(p10d09 p10d11b *tdpsec p10d14), missing
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 

****************
***ylnmsec_ci***
****************

* 2021 (2022) 
* p04d07b (p05d09b) Vivienda sin tener que pagarla, alimentación, Transporte
g ylnmsec_ci=p10d10b
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

*****************
***ylmotros_ci***
*****************

gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

******************
***ylnmotros_ci***
******************

gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

************
***ylm_ci***
************

egen ylm_ci= rsum(ylmpri_ci ylmsec_ci), missing
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso laboral monetario total"





*************
***ynlm_ci **
*************

*Modificación SGR 2017 la variable correcta es p05a18b, la p05a17b es el total
*egen rem=rsum( p05a17b p05a18b p05a19b), missing
*remesas 2021 (2022)
*p05a18b p05a19b p05a20b (p06c02b p06c03b p06c04b): remesas mes1, mes2, mes3
egen rem=rsum(p11c02b p11c03b p11c04b), missing


/*
2021 (2022)
p05a01b (p06a01b) alquileres
p05a02b (p06a02b) intereses
p05a03b (p06a03b) donaciones
p05a04b (p06a04b) pensión alimenticia
p05a05b (p06a05b) jubilación
p05a06b (p06a06b) becas 
p05a07b (p06a07b) seguro desempleo

p05a08b (p06b04b) rentas de propiedad marca, patentes y derechos
p05a09b (p05c38b accidente p05c39b despido) indemnización seguros de vida, accidentes o despido
p05a10b (p06b05b) premios
p05a11b (p06b06b) herencia
p05a12b (p06b07b) venta activos del hogar
p05a13b (p06b08b) acciones bonos
p05a14b (p06b01b) venta cosechas o animales
p05a15b (p06b02b) trabajos diferentes a los reportados otros ingresos
p05a16b no incluida (p06b03b) otros ingresos por negocios no agropecuarios diferentes a los ya reportados últimos 12m. Se agrega
*/	

foreach var of varlist p11a01b p11a02b p11a03b p11a04b p11a05b p11a06b rem{
g `var'tdp3=`var'/3
}

foreach var of varlist p11b01b p11b02b p11b03b p11b04b p11b05b p11b06b p11b07b p11b08b {
g `var'tdp3=`var'/12
}
egen ynlm_ci=rsum(*tdp3*), missing
label var ynlm_ci "Ingreso no laboral monetario" 


*************
*** ynlm_privado_ci **
*************

foreach var of varlist p11a01b p11a02b p11a03b p11a04b rem{
g `var'tdp3_priv=`var'/3
}

foreach var of varlist p11b01b p11b02b p11b03b p11b04b p11b05b p11b06b p11b07b p11b08b {
g `var'tdp3_priv =`var'/12
}


egen ynlm_privado_ci = rsum(*tdp3_priv*), missing
label var ynlm_privado_ci "Ingreso no laboral monetario privado" 


*************
*** ynlm_publico_ci **
*************

foreach var of varlist p11a05b p11a06b {
g `var'tdp3_publ =`var'/3
}

egen ynlm_publico_ci = rsum(*tdp3_publ*), missing
label var ynlm_publico_ci  "Ingreso no laboral monetario privado" 



*************
*** ynlm_privado_ch **
*************
egen ynlm_privado_ch = total(ynlm_privado_ci), by(idh_ch)


*************
*** ynlm_publico_ch **
*************
egen ynlm_publico_ch = total(ynlm_publico_ci), by(idh_ch)


**************
***ynlnm_ci***
**************
gen ynlnm_ci=.
label var ynlnm_ci "Ingreso no laboral no monetario" 

***************
***ylnm_ci***
***************
egen ylnm_ci=rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi

************************
*** HOUSEHOLD INCOME ***
************************

*******************
*** nrylmpri_ch ***
*******************
*Creating a Flag label for those households where someone has a ylmpri_ci as missing
by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.
label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

**************
*** ylm_ch ***
**************
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
label var ylm_ch "Ingreso laboral monetario del hogar"

***************
*** ylnm_ch ***
***************
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
label var ylnm_ch "Ingreso laboral no monetario del hogar"

*****************************************************************
*identificador de top-code del ingreso de la actividad principal*
*****************************************************************

gen tcylmpri_ci=.
**************************************************
*Identificador de los hogares en donde (top code)*
**************************************************
gen tcylmpri_ch=.

****************
*** ylmnr_ch ***
****************
by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1, missing
replace ylmnr_ch=. if nrylmpri_ch==1
label var ylmnr_ch "Ingreso laboral monetario del hogar"

***************
*** ynlm_ch ***
***************
by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing
label var ynlm_ch "Ingreso no laboral monetario del hogar"

**************
***ynlnm_ch***
**************
gen ynlnm_ch=.
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

********
***NA***
********
gen rentaimp_ch=.
label var rentaimp_ch "Rentas imputadas del hogar"

******************************
*	autocons_ci 
******************************
*variable p05a20b: corresponde a monto por remesas por lo que considero debería ser missing
*g autocons_ci=p05a20b
g autocons_ci=.
label var autocons_ci "Autoconsumo reportado por el individuo"

******************************
*	autocons_ch 
******************************
bys idh_ch: egen autocons_ch=sum(autocons_ci) if miembros_ci==1, missing
la var autocons_ch "Autoconsumo del Hogar"

****************
***remesas_ci***
****************
g remesas_ci=remtdp3
la var remesas_ci "Cash remittances from abroad"

****************
***remesas_ch***
****************
by idh_ch, sort: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing
label var remesas_ch "Remesas mensuales del hogar" 

*****************
***ylhopri_ci ***
*****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
label var ylmhopri_ci "Salario monetario de la actividad principal" 

***************
***ylmho_ci ***
***************
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario monetario de todas las actividades" 
	



***************
***ytot_ci ***
***************
	
egen double ytot_ci= rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi 	
	
	
***************
***ytot_ch ***
***************	
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi 	
	
	
***************
*** yneto_pc_ch ***
***************		
gen double yneto_pc_ch = .
* ylm_publico_ch no se identifica

         ******************************
         *** VARIABLES DE EDUCACIÓN  **
         ******************************

******************************
*	asiste_ci: Definida aqui como inscritos en plantel educativo en el presente anio escolar  OK
******************************
* P03A02 2021 es p04a02 en 2022: Inscripción escolar
g asiste_ci = (p04a02 == 1)
replace asiste_ci = . if p04a02 == .
notes: asiste is defined as enrolled in the current school year

*******************************************
*	aedu_ci: Anios de educacion COMPLETADOS
*******************************************

/* 2021 p03a01 y 2022 p04a01: analfabetos (2) que no contestan sobre nivel y grado
   202 la variabla p03a05b va de 1-6 y en el 2022 p04a05b va de 1-26:
           1 1ro primaria
           2 2do primaria
           3 3ro primaria
           4 4to primaria
           5 5to primaria
           6 6to primaria
           7 1ro básico
           8 2do básico
           9 3ro básico
          10 4to diversificado
          11 5to diversificado
          12 6to diversificado
          13 7mo diversificado
          14 1er año universidad
          15 2do año universidad
          16 3er año universidad
          17 4to año universidad
          18 5to año universidad
          19 6to año universidad
          20 1er año maestría
          21 2do año maestría
          22 3er año maestría
          23 1er año doctorado
          24 2do año doctorado
          25 3er año doctorado
          26 4to año doctorado 
		  
		  tab p04a05b p04a05a*/

* Antes del 2022 el código era así:
gen aedu_ci=.
replace	 aedu_ci=0  if p06b26a==1

*Modificación Mayra Sáenz Agosto 2015: Aunque en el cuestionario consta la categoría 0 = ninguno
*En la base de datos no se incluye la categoría. Por lo tanto, se considera ningun tipo de educación
*a los que no saben leer ni escribir y no responden ls preguntas de educación.
replace aedu_ci=0  if p06b01 ==2 & (p06b02a==2 & p06b02a==.)

*Primaria 
replace aedu_ci=1  if (p06b26a==2 & p06b26c==1)
replace aedu_ci=2  if (p06b26a==2 & p06b26c==2)
replace aedu_ci=3  if (p06b26a==2 & p06b26c==3)
replace aedu_ci=4  if (p06b26a==2 & p06b26c==4)
replace aedu_ci=5  if (p06b26a==2 & p06b26c==5)
replace aedu_ci=6  if (p06b26a==2 & p06b26c==6) 

*Secundaria
replace aedu_ci=7  if (p06b26a==3 & p06b26c==1) 
replace aedu_ci=8 if (p06b26a==3 & p06b26c==2) 
replace aedu_ci=9 if (p06b26a==3 & p06b26c==3) 
replace aedu_ci=10 if (p06b26a==4 & (p06b26c==2 | p06b26c==4)) 
replace aedu_ci=11 if (p06b26a==4 & p06b26c==5) 
replace aedu_ci=12 if (p06b26a==4 & p06b26c==6) 

*Superior
replace aedu_ci=13 if (p06b26a==5 & p06b26c==1)
replace aedu_ci=14 if (p06b26a==5 & p06b26c==2)
replace aedu_ci=15 if (p06b26a==5 & p06b26c==3)
replace aedu_ci=16 if (p06b26a==5 & p06b26c==4)
replace aedu_ci=17 if (p06b26a==5 & p06b26c==5) 
replace aedu_ci=18 if (p06b26a==5 & p06b26c==6) //ingenierias duran 6 años.  
replace aedu_ci=19 if (p06b26a==5 & p06b26c==7) //quizas es medicina

*Postgrado
replace aedu_ci=12+6 if (p06b26a==6 & p06b26c==1) 
replace aedu_ci=12+6+1 if (p06b26a==6 & p06b26c==2)

replace aedu_ci=12+6+2 + p06b26c if (p06b26a==7) // doctorado
//imputando los valores perdidos
replace aedu_ci=0 if p06b26a==0 & p06b26c==. 

label var aedu_ci "Anios de educacion aprobados"





******************************
*	eduno_ci
******************************
g byte eduno_ci=(aedu_ci==0)
replace eduno_ci=. if aedu_ci==.
la var eduno_ci "Personas sin educacion. Excluye preescolar"

******************************
*	edupi_ci 
******************************
g byte edupi_ci=(aedu_ci>=1 & aedu_ci<6)
replace edupi_ci=. if aedu_ci==.
la var edupi_ci "Personas que no han completado Primaria"

******************************
*	edupc_ci 
******************************
g byte edupc_ci=(aedu_ci==6)
replace edupc_ci=. if aedu_ci==.
la var edupc_ci "Primaria Completa"

******************************
*	edusi_ci 
******************************
g byte edusi_ci=(aedu_ci>6 & aedu_ci<11)
replace edusi_ci=. if aedu_ci==.
la var edusi_ci "Secundaria Incompleta" 

******************************
*	edusc_ci 
******************************
g byte edusc_ci=(aedu_ci==11) 
replace edusc_ci=. if aedu_ci==.
la var edusc_ci "Secundaria Completa" 

******************************
*	edus1i_ci 
******************************
g byte edus1i_ci=(aedu_ci>6 & aedu_ci<9)
replace edus1i_ci=. if aedu_ci==.
la var edus1i_ci "1er ciclo de Educacion Secundaria Incompleto"

******************************
*	edus1c_ci 
******************************
g byte edus1c_ci=(aedu_ci==9)
replace edus1c_ci=. if aedu_ci==.
la var edus1c_ci "1er ciclo de Educacion Secundaria Completo"

******************************
*	edus2i_ci 
******************************
g byte edus2i_ci=(aedu_ci>9 & aedu_ci<11)
replace edus2i_ci=. if aedu_ci==.
la var edus2i_ci "1er ciclo de Educacion Secundaria Incompleto"

******************************
*	edus2c_ci 
******************************
g byte edus2c_ci=(aedu_ci==11)
replace edus2c_ci=. if aedu_ci==.
la var edus2c_ci "2do ciclo de Educacion Secundaria Incompleto"

******************************
*	eduui_ci 
******************************
g byte eduui_ci=(aedu_ci>11 & aedu_ci<15) 
replace eduui_ci=. if aedu_ci==.
la var eduui_ci "Universitaria o Terciaria Incompleta"

******************************
*	eduuc_ci 
******************************
g byte eduuc_ci=aedu_ci>14
replace eduuc_ci=. if aedu_ci==.
la var eduuc_ci "Universitaria o Terciaria Completa"

******************************
*	edupre_ci 
******************************
g byte edupre_ci=.
label variable edupre_ci "Educacion preescolar"

******************************
*	asispre_ci
******************************
* 2021 p03a04a y 2022 p04a04a
g byte asispre_ci = p06b06a==1
la var asispre_ci "Asiste a Educacion preescolar"

**************
***eduac_ci***
**************
gen byte eduac_ci=. // esta disponible solo para los con titulo
label variable eduac_ci "Superior universitario vs superior no universitario"

******************************
*	pqnoasis_ci 
******************************

g pqnoasis_ci  = p06b24
**************
*pqnoasis1_ci*
**************

g       pqnoasis1_ci = .
replace pqnoasis1_ci = 1 if (p06b24==1) 
replace pqnoasis1_ci = 2 if (p06b24==2) 
replace pqnoasis1_ci = 3 if (p06b24==1 | p06b24==6 | p06b24== 7 | p06b24==10   ) 
replace pqnoasis1_ci = 4 if (p06b24==5)
replace pqnoasis1_ci = 5 if (p06b24==4 | p06b24== 9 |p06b24== 14)
replace pqnoasis1_ci = 7 if (p06b24== 15)
replace pqnoasis1_ci = 8 if (p06b24== 8 | p06b24== 11 | p06b24== 12 | p06b24== 13)
replace pqnoasis1_ci = 9 if (p06b24== 15)

 

******************************
*	repite_ci 
******************************
g repite_ci=.  /*NA*/
******************************
*	repiteult_ci 
******************************
g repiteult_ci=. /*NA*/


******************************
*	edupub_ci 
******************************
/*se cambia categoría
P03A02 2021 y p04a02 2022 (1=si)
P03A03 2021
           1 Público
           2 Privado
           3 Municipal
           4 Cooperativa
p04a03 2022
           1 Municipal
           2 Público
           3 Privado
           4 Cooperativa
          98 Otro
*/		  
g edupub_ci= (p06a02==1 | p06a02== 2 | p06a02==3) // asiste y es publico
replace edupub_ci=0 if  (p06a02==6 | p06a02== 7 | p06a02==5 | p06a02 == 4) // asiste y es privado
replace edupub_ci=. if p06a01 == 7 // no asiste
label define edupub_ci 1 "Público" 0 "Privado"
label value edupub_ci edupub_ci
la var edupub_ci "Personas que asisten a centros de ensenanza publicos"

    
	
	
	
	
         ******************************
		 *** VARIABLES DE MIGRACION *** 
         ******************************
		 * Variables incluidas por SCL/MIG Fernando Morales

	*******************
	*** migrante_ci ***
	*******************
	
	gen migrante_ci=.
	replace migrante_ci = 1 if ppa09a != 1000
	label var migrante_ci "=1 si es migrante"
	

	**********************
	*** migrantiguo5_ci ***
	**********************
	
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"

	
	

**************************************
*** VARIABLES DE PROTECCION SOCIAL ***
**************************************

* MIEMBROS DEL HOGAR
	gen x = 1
	bys idh_ch: egen nmiembros_sph_ch= sum(x)
	
**********************
	*** bene_cash_ch ***
**********************	
gen bene_cash_ch = .
*No hay forma de distinguir si las transferencias son públicas 	p10b11g p11a03a


**********************
*** pensionsub_ch ***
**********************	
bys idh_ch: egen pensionsub_ch = max(pensionsub_ci)  




/*_____________________________________________________________________________________________________*/
* verificación de que se encuentren todas las variables del sociometro y las nuevas de mercado laboral
* también se incluyen variables que se manejaban en versiones anteriores, estas son:
* firmapeq_ci nrylmpri_ch nrylmpri_ci tcylmpri_ch tcylmpri_ci tipopen_ci
/*_____________________________________________________________________________________________________*/

do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

 order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad 
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci  /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch  ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  nmiembros_sph_ch yneto_pc_ch bene_cash_ch pensionsub_ch   /// Protección social 
          ynlm_publico_ch ynlm_privado_ch ynlm_privado_ci ynlm_publico_ci  /// Protección social ingresos
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa








	
qui destring $var, replace


compress


saveold "`base_out'", replace


log close
