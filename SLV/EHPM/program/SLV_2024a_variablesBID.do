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

local PAIS SLV
local ENCUESTA EHPM
local ANO "2024"
local ronda a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: El Salvador
Encuesta: EHPM
Round: a
Autores: Matias Rodriguez (SCL/SCL) - Email: mrodriguezm@iadb.org, 03 de octubre de 2025
Versión: 1 
Matias Rodriguez (SCL/SCL) - Email: mrodriguezm@iadb.org, 03 de octubre de 2025


****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear


import spss using "C:\Users\mrodriguezm\OneDrive - Inter-American Development Bank Group\Datalib\EHPM SPSS 2024\EHPM 2024.sav", clear

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
	gen byte region_c = r004
	label define region_c   ///
	1 "Ahuachapán" ///
    2 "Santa Ana" ///
    3 "Sonsonate" ///
    4 "Chalatenango" ///
    5 "La Libertad" ///
    6 "San Salvador" ///
    7 "Cuscatlán" ///
    8 "La Paz" ///
    9 "Cabañas" ///
    10 "San Vicente" ///
    11 "Usulután" ///
    12 "San Miguel" ///
    13 "Morazán" ///
    14 "La Unión" 		
	label value region_c region_c
		    
	*************
	* pais_c    *
	*************
	gen str3 pais_c="SLV"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=r015

	******
	*zona*
	******
	*NOTA: En 2024 no hay zona
	
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
	gen idh_ch = idboleta

	***************
	****idp_ci*****
	***************
	*egen idp_ci = concat(...)
	gen idp_ci=r101
	tostring idp_ci, replace format ("%20.0f") 

	***********
	*factor_ci* 
	***********
	gen factor_ci=fac00
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=fac00 /*todos los factores 00-04 son los mismos*/


****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if r104==1
	replace sexo_ci = 2 if r104==2

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=r106 if r106>=0

	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if r103==1
	replace relacion_ci = 2 if r103==2
	replace relacion_ci = 3 if r103==3
	replace relacion_ci = 4 if r103>=4 & r103<=9
	replace relacion_ci = 5 if r103==11
	replace relacion_ci = 6 if r103==10

	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)

	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=...
	*Chequear 
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci=1 if r107==6
	replace civil_ci=2 if r107==1 | r107==2 
	replace civil_ci=3 if r107==4 | r107==5
	replace civil_ci=4 if r107==3

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
		
	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	
	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.

	**************
	*notropari_ch*
	**************
   by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5)
   replace notronopari_ch=. if relacion_ci==.          
		
	****************
	*nempdom_ch*
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.
* chequear
	
	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch=0
	**** unipersonal
	replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (child with or without spouse but without other relatives)
	replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (spouse with or without children but without other relatives)
	replace clasehog_ch=2 if nhijos_ch==0 & nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** ampliado
	replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
	**** compuesto (some relatives plus non relative)
	replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	**** corresidente
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***

*******************************************************
	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	
	*********
	*afro_ch*
	*********
	gen byte afro_jefe = afro_ci if relacion_ci==1
	egen afro_ch  = max(afro_jefe), by(idh_ch) 
	drop afro_jefe
	
	********
	*ind_ch*
	********	
	gen byte ind_jefe = ind_ci if relacion_ci==1
	egen ind_ch = max(ind_jefe), by(idh_ch) 
	drop ind_jefe

	**************
	*noafroind_ch*
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci==1
	egen noafroind_ch = max(noafroind_jefe), by(idh_ch) 
	drop noafroind_jefe

	************
	*afroind_ch*
	************
 	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 

	********
	*dis_ci*
	********
	gen byte dis_ci=.
	
	**********
	*disWG_ci*
	**********
	gen byte disWG_ci=.
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte SLV_dis_ci = .
	
****************************
***VARIABLES DE MERCADO LABORAL***
* NOTA: Actualmente se está revisando el manual
****************************

****************************
***VARIABLES DE INGRESO***
* NOTA: SE SIGUE REVISANDO EL MANUAL
****************************
	
****************************
***VARIABLES DE EDUCACION***
****************************



	*********	
	*aedu_ci*
	*********
	gen aedu_ci=aproba1

	**********
	*eduui_ci*
	**********
	gen eduui_ci=(aedu_ci>=12 & r217==2) // mayor o igual a 12 anios de estudio y titulo de bachiller general
	replace eduui_ci=1 if aedu_ci>=13 & (r217==3 | r217==.) // mas de 12 anios de estudio, bachiller tecnico o perdido
	replace eduui_ci=. if aedu_ci==.

	**********
	*eduuc_ci*
	**********
	gen eduuc_ci=(aedu_ci>12 & r217>=4 & r217<=9) // mas de 12 anios de estudio pero con titulo terciario; incluye profesorado
	replace eduuc_ci=. if aedu_ci==.

	**********
	*eduac_ci*
	**********
	gen eduac_ci=.
	replace eduac_ci=1 if r214==4
	replace eduac_ci=0 if r214==5
	
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.
	replace edupre_ci = 1 if ....
	replace edupre_ci = 0 if ....
gen edupre_ci=(r209==1)

	************
	*asispre_ci*
	************
	gen asispre_ci=(r203==1 & r204==1) // no consideramos menores de 3 años (r201a)

	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci=0 if ...
	replace asiste_ci=1 if ...
	gen asiste_ci=(r203==1)
	replace asiste_ci=. if r203==.

	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if ...
	replace pqnoasis1_ci =  2 if ...
	replace pqnoasis1_ci =  3 if ...
	replace pqnoasis1_ci =  4 if ...
	replace pqnoasis1_ci =  5 if ...
*DZ Jul 2017: cambio de nombre de la variable respecto a anio anterior*
gen pqnoasis_ci=r219 
label var pqnoasis_ci "Razones para no asistir a la escuela"
gen      pqnoasis1_ci=1 if r219==3
replace pqnoasis1_ci=2 if r219==1
replace pqnoasis1_ci=3 if r219==4  | r219==5  | r219==6
replace pqnoasis1_ci=4 if r219==10
replace pqnoasis1_ci=5 if r219==2  | r219==12 | r219==15 | r219==16
replace pqnoasis1_ci=6 if r219==8
replace pqnoasis1_ci=7 if r219==7 
replace pqnoasis1_ci=8 if r219==9  | r219==13 | r219==14 | r219==18
replace pqnoasis1_ci=9 if r219==11 | r219==17 


	***********
	*edupub_ci*
	***********		
	gen edupub_ci=.
	replace edupub_ci=1 if r210a==1 & r203==1
	replace edupub_ci=0 if (r210a==2 | r210a==3) & r203==1

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=0 if ...
	replace luz_ch=1 if r311==1 | r311==2 | r311==5 | r311==6
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	replace luzmide_ch=0 if ...
	replace luzmide_ch=1 if ...
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if ...
	replace combust_ch=1 if  r320==1 | r320==2 | r320==3
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen piso_ch=.
	replace piso_ch=0 	if r304==5
	replace piso_ch=1 	if r304>=1 & r304<=4
	replace piso_ch=2 	if r304==6
		
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	replace pared_ch=0 	if r303==2 | r303==3 |r303==5 |r303==6 |r303==7 
	replace pared_ch=1 	if r303==1 | r303==4
	replace pared_ch=2 	if r303==8
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	replace techo_ch=1 	if r302>=1 & r302<=4
	replace techo_ch=0 	if r302>=5 & r302<=6 
	replace techo_ch=2 	if r302==7
		
	***********
	*resid_ch*
	***********
	gen resid_ch=.
	replace resid_ch=0 if r322==1 | r322==2
	replace resid_ch=1 if r322==4 | r322==5
	replace resid_ch=2 if r322==6
	replace resid_ch=3 if r322==3 | r322==7

		
	***********
	*dorm_ch*
	***********
	gen dorm_ch=r306
	replace dorm_ch=. if r306==.
	label var dorm_ch "Habitaciones para dormir"
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=r305
	replace cuartos_ch=. if r305==.
	label var cuartos_ch "Habitaciones en el hogar"	
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
	replace cocina_ch==0 if ...	
	replace cocina_ch==1 if ...	
	label var cocina_ch "Cuarto separado y exclusivo para cocinar"
	
	***********
	*telef_ch*
	***********
	gen telef_ch=.
	replace telef_ch=0 if r3211a==2	
	replace telef_ch=1 if r3211a==1
	label var telef_ch "El hogar tiene servicio telefónico fijo"
		
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	replace refrig_ch=0 if r32305a==2
	replace refrig_ch=1 if r32305a==1
	label var refrig_ch "El hogar posee refrigerador o heladera"
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	replace freez_ch=0 if ...
	replace freez_ch=1 if ...
	label var freez_ch "El hogar posee congelador"
	
	***********
	*auto_ch*
	***********
	gen auto_ch=.
	replace auto_ch=0 if r32312a==2
	replace auto_ch=1 if r32312a==1
	label var auto_ch "El hogar posee automovil particular"
	
	***********
	*compu_ch*
	***********
	gen compu_ch=.
	replace compu_ch=0 if r32309a==2
	replace compu_ch=1 if r32309a==1
	label var compu_ch "El hogar posee computador"
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=0 if r3213a==2
	replace internet_ch=1 if r3213a==1
	
	***********
	*vivi1_ch*
	gen vivi1_ch=.
	replace vivi1_ch=1 if r301==1 
	replace vivi1_ch=2 if r301==2
	replace vivi1_ch=3 if r301>=3 & r301<=9

	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch=0 	if r308==1
	replace viviprop_ch=1 	if r308==3
	replace viviprop_ch=2 	if r308==2 
	replace viviprop_ch=3 	if r308 >=4 & r308<9
	replace viviprop_ch=. 	if r308==.

****************
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch= r308c  
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=r310a 
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.
	replace aguared_ch = 1 if r312==1 | r312==2| r312==3| r312==4
	replace aguared_ch = 0 if r312> 4
	
	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo _ch =.
	replace aguafconsumo _ch = 0 if …
	replace aguafconsumo _ch = 1 if …
	replace aguafconsumo _ch = 2 if …
	replace aguafconsumo _ch = 3 if …
	replace aguafconsumo _ch = 4 if …
	replace aguafconsumo _ch = 5 if …
	replace aguafconsumo _ch = 6 if …
	replace aguafconsumo _ch = 7 if …
	replace aguafconsumo _ch = 8 if …
	replace aguafconsumo _ch = 9 if …
	replace aguafconsumo _ch = 10 if …
gen aguafconsumo_ch = 0

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if r312==1 | r312==2| r312==3| r312==4
	replace aguafuente_ch = 2 if r313==2
	replace aguafuente_ch= 4 if (r313==5 | r313==5.1)
	replace aguafuente_ch = 5 if r313==10
	replace aguafuente_ch= 6 if r313==3
	replace aguafuente_ch= 7 if r312==4.1 | r313==8 | r313==1 |r313==11
	replace aguafuente_ch = 8 if r313==7 | r313 ==9
	replace aguafuente_ch= 9 if  r313==6 |r313==6.1
	replace aguafuente_ch= 10 if r313==13 | r313==12 |r313==4 | r313==4.1   

	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if  (r312==1 | r312==2) | r313==1 | r313==3 | r313==4| r313==5 | r313==6
	replace aguadist_ch= 2 if  (r312==3| r312==4|r312 == 4.1)
	replace aguadist_ch=3 if r313==2 | r313==4.1| r313==5.1 | r313==6.1 | r313==12 | r313==11 | r313==6.1
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.


	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =.
	replace aguadisp1_ch = 1 if …
	replace aguadisp1_ch = 2 if …
	replace aguadisp1_ch = 9 if …
gen aguadisp1_ch =9

	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =.
	replace aguadisp2_ch = 1 if …
	replace aguadisp2_ch = 2 if …
	replace aguadisp2_ch = 3 if …
	replace aguadisp2_ch = 9 if …
gen aguadisp2_ch = 1 if r312d<=3 | r312h<=11 
replace aguadisp2_ch = 2 if r312d>=4 & r312h>=12
replace aguadisp2_ch = 3 if r312d==7 & r312h ==24
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	replace aguatrat_ch = 0 if …
	replace aguatrat_ch = 1 if …
	
	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7 

	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .
	replace aguamide_ch = 0 if …
	replace aguamide_ch = 1 if...
gen aguamide_ch = .

	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
	replace bano_ch = 0 if …
	replace bano_ch = 1 if …
	replace bano_ch = 2 if …
	replace bano_ch = 3 if …
	replace bano_ch = 4 if …
	replace bano_ch = 5 if …
	replace bano_ch = 6 if …
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	replace banoex_ch = 0 if …
	replace banoex_ch = 1 if …
generate banoex_ch=9

	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if …
	replace sinbano_ch = 1 if…
	replace sinbano_ch = 2 if…
	replace sinbano_ch = 3 if…
gen sinbano_ch = 3
replace sinbano_ch = 1 if r315==1
replace sinbano_ch = 2 if (r317a==3|r317a==4) & r315==2
replace sinbano_ch = 0 if r314 == 1 | r314 == 2 

*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

	******************
    ** banomejorado_ch ** - 
    *****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci= .
	replace migrante_ci=0 if ...
	replace migrante_ci=1 if ...
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.
	replace migrantiguo5_ci=0 if ...
	replace migrantiguo5_ci=1 if ...

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = .
	replace miglac_ci = 0 if ...
	replace miglac_ci = 1 if ...
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar*
	****************
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 
	replace tipo_bienestar  = 2

	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine _ci= . 
	replace pobre_ine _ci= 0 if …
	replace pobre_ine _ci= 1 if …

fre pobreza li
* revisar si es consumo o ingreso
	*consumo es mas estable
* revisar porque li son dos 
*  Pobres extremos, pobres moderados, vulnerables y no pobres 
* con base en ingreso neto (Sin transferencias)
* y líneas de pobreza internacionales

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = …
*buscar 

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lp_ci= li
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace lp_ci= li*2
	* Pobreza normal= linea pobreza extrema *2
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close