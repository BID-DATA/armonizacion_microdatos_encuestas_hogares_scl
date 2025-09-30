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


		****************************
		***VARIABLES DEMOGRAFICAS***
		****************************

*************
***sexo_ci***
*************
	g sexo_ci = p3271


**********
***edad***
**********
	g edad_ci = p6040
	
*****************
***relacion_ci***
*****************
	g 		relacion_ci = 1 if p6050 == 1
	replace relacion_ci = 2 if p6050 == 2
	replace relacion_ci = 3 if p6050 == 3
	replace relacion_ci = 4 if inlist(p6050,4,5,6,7,8,9)
	replace relacion_ci = 5 if p6050 == 11 | p6050 == 12 | p6050 == 13 
	replace relacion_ci = 6 if p6050 == 10
	
*********************
****Estado Civil*****
*********************
	g 		civil_ci = .
	replace civil_ci = 1 if p6070 == 6
	replace civil_ci = 2 if p6070==1 | p6070==2 | p6070==3
	replace civil_ci = 3 if p6070==4 
	replace civil_ci = 4 if p6070==5

*************
***jefe_ci***
*************
	g jefe_ci = relacion_ci == 1

******************
***nconyuges_ch***
******************
	bys idh_ch: egen nconyuges_ch = sum(relacion_ci == 2)
	

***************
***nhijos_ch***
***************
	bys idh_ch: egen nhijos_ch = sum(relacion_ci == 3)
	

******************
***notropari_ch***
******************
	bys idh_ch: egen notropari_ch = sum(relacion_ci == 4)
	
********************
***notronopari_ch***
********************
	bys idh_ch: egen notronopari_ch = sum(relacion_ci == 5)
	
****************
***nempdom_ch***
****************
	bys idh_ch: egen nempdom_ch = sum(relacion_ci == 6)

*****************
***clasehog_ch***
*****************
	g byte clasehog_ch = 0
**** unipersonal
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
**** nuclear (child with or without spouse but without other relatives)
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
**** ampliado
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
**** compuesto (some relatives plus non relative)
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
**** corresidente
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	
*****************
***miembros_ci***
*****************
gen byte miembros_ci=(relacion_ci>=1 & relacion_ci<=5) 
replace miembros_ci=. if relacion_ci==.

*****************
*miembros_one_ci*
*****************
gen byte miembros_one_ci=(p6050>=1 & p6050<=13)
replace miembros_one_ci=0 if p6050==10
replace miembros_one_ci=. if p6050==.
	
*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
	
*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
	
*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
	
****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


	*****************************
	***VARIABLES DE DIVERSIDAD***
	*****************************
	
*********
*afro_ci*
*********
**Pregunta: De acuerdo con su cultura, pueblo o rasgos físicos, … es o se reconoce como:(P6080)
*1- Indigena 2- Gitano - Rom 3- Raizal del archipiélago de San Andrés y providencia 
*4- Palenquero de San basilio o descendiente 5- Negro(a), mulato(a), Afrocolombiano(a) o Afrodescendiente 
*6- Ninguno de los anteriores (mestizo, blanco, etc)
tab p6080, m
	
gen byte afro_ci = . 	  
replace afro_ci = 1 if p6080 == 3 | p6080 == 4 | p6080 == 5
replace afro_ci = 0 if p6080 != 3 & p6080 != 4 & p6080 != 5 & p6080 != .
tab afro_ci, m
	
*********
*ind_ci*
*********	
gen byte ind_ci =. 
replace ind_ci = 1 if p6080 == 1
replace ind_ci = 0 if p6080 != 1 & p6080 != .
	
tab ind_ci, m

**************
*noafroind_ci*
**************
gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
replace noafroind_ci =1 if (afro_ci==0 & ind_ci==0)
replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
replace noafroind_ci =. if (afro_ci==. | ind_ci==.) //Esto solo en el caso que se tenga ambas opciones no disponibles. 
tab noafroind_ci,m

************
*afroind_ci*
************
gen byte afroind_ci=. 
replace afroind_ci=1 if ind_ci==1 
replace afroind_ci=2 if afro_ci==1
replace afroind_ci=3 if noafroind_ci == 1
ta afroind_ci,m
	
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
gen byte dis_ci = .
replace dis_ci = 1 if p1906s1<=3 | p1906s2<=3 | p1906s3<=3 | p1906s4<=3 | p1906s5<=3 | p1906s6<=3 | p1906s7<=3
replace dis_ci = 0 if p1906s1==4 & p1906s2==4 & p1906s3==4 & p1906s4==4 & p1906s5==4 & p1906s6==4 & p1906s7==4 
tab dis_ci, m	
	
**********
*disWG_ci*
**********
gen byte disWG_ci=.
replace disWG_ci = 1 if p1906s1<=2 | p1906s2<=2 | p1906s3<=2 | p1906s4<=2 | p1906s5<=2 | p1906s6<=2 | p1906s7<=2
replace disWG_ci = 0 if p1906s1>=3 & p1906s2>=3 & p1906s3>=3 & p1906s4>=3 & p1906s5>=3 & p1906s6>=3 & p1906s7>=3 
tab disWG_ci, m
	
********
*dis_ch*
********
egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
******************
*ISOalpha3_dis_ci*
******************
gen byte COL_dis_ci = dis_ci


			****************************
			***VARIABLES DE EDUCACION***
			****************************
			
**************
***aedu_ci***
**************	
	g aedu_ci = . 
* 0 años de educacion 
	replace aedu_ci = 0 if p3042 == 1 | p3042 == 2 
	replace aedu_ci = 0 if p3042 == 3 & p3042s1 == 0 
*Primaria
	replace aedu_ci = 1 if p3042 == 3 & p3042s1 == 1
	replace aedu_ci = 2 if p3042 == 3 & p3042s1 == 2
	replace aedu_ci = 3 if p3042 == 3 & p3042s1 == 3
	replace aedu_ci = 4 if p3042 == 3 & p3042s1 == 4
	replace aedu_ci = 5 if p3042 == 3 & p3042s1 == 5
	replace aedu_ci = 5 if p3042 == 4 & p3042s1 == 0
*Secundaria (se incluye normalista como otra modalidad de secundaria)
	replace aedu_ci = 6  if p3042 == 4 & p3042s1 == 1
	replace aedu_ci = 7  if p3042 == 4 & p3042s1 == 2
	replace aedu_ci = 8  if p3042 == 4 & p3042s1 == 3
	replace aedu_ci = 9  if p3042 == 4 & p3042s1 == 4	
	replace aedu_ci = 9  if p3042 == 5 & p3042s1 == 0	
	replace aedu_ci = 9  if p3042 == 6 & p3042s1 == 0
	replace aedu_ci = 9  if p3042 == 7 & p3042s1 == 0
	replace aedu_ci = 9  if p3042 == 7 & p3042s1 == 1
		
	replace aedu_ci = 10 if p3042 == 5 & p3042s1 == 1
	replace aedu_ci = 10 if p3042 == 6 & p3042s1 == 1
	replace aedu_ci = 10 if p3042 == 7 & p3042s1 == 2
	replace aedu_ci = 10 if p3042 == 7 & p3042s1 == 3
	replace aedu_ci = 11 if p3042 == 5 & p3042s1 == 2
	replace aedu_ci = 11 if p3042 == 6 & p3042s1 == 2
	replace aedu_ci = 11 if p3042 == 7 & p3042s1 == 4
	
*Superior
	replace aedu_ci = 12 if p3042 == 7 & p3042s1 == 5
	replace aedu_ci = 11+ trunc(p3042s1/2) if p3042>=8 & p3042<=13
	
*Missing
	replace aedu_ci =. if p3042==99
	replace aedu_ci =. if p3042s1==99

***************
***edupre_ci***
***************
	g byte edupre_ci =.

**************
***eduui_ci***
**************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria

	g byte eduui_ci = (inlist(p3042, 8, 9, 10, 11, 12, 13) & inlist(p3043, 2, 3, 4)) 
	replace eduui_ci = . if aedu_ci == .

***************
***eduuc_ci***
***************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria

	g byte eduuc_ci = (inlist(p3042, 8, 9, 10, 11, 12, 13) & inlist(p3043, 5, 6, 7, 8, 9, 10))
	replace eduuc_ci = . if aedu_ci == .

**************
***eduac_ci***
**************

	gen byte eduac_ci = .
	replace eduac_ci = 1 if (inlist(p3042, 10, 11, 12, 13) & inlist(p3043, 7, 8, 9, 10))
	replace eduac_ci = 0 if (inlist(p3042, 8, 9 ) & inlist(p3043, 5, 6))


***************
***asiste_ci***
***************
	g asiste_ci = 1 if p6170 == 1
	replace asiste_ci = 0 if p6170 == 2
	

***************
***edupub_ci***
***************
	g edupub_ci =.
	replace edupub=1 if p3041 == 1 & p6170==1
	replace edupub_ci = 0 if p3041 == 2 & p6170==1
	
	
***************
***asispre_ci**
***************
	g asispre_ci= (p6170==1 & p3042==2 & p3042s1 <2)
	
		
**************
*pqnoasis1_ci*
**************
g pqnoasis1_ci = .


		****************************
		***VARIABLES DE VIVIENDA***
		****************************	
	
***********
*luz_ch*
***********
g luz_ch = p4030s1 == 1 
replace luz_ch=. if p4030s1==.	
	
***********
*luzmide_ch*
***********
g luzmide_ch = .			
	
************
*combust_ch*
************
g combust_ch = (p5080 == 1 | p5080 == 3 | p5080 == 4)
replace combust_ch =. if p5080==.			
	
**********
*piso_ch*
**********
g piso_ch = (p4020 != 1 & p4020 != .)
replace piso_ch = . if p4020 ==.	
	
***********
*pared_ch*
***********
g pared_ch = (p4010 >= 1 & p4010 <= 3)
replace pared_ch = . if p4010 == .	
	
***********
*techo_ch*
***********
g techo_ch = .	
	
**********
*resid_ch*
**********
g resid_ch = 0		 if p5040 == 1
replace resid_ch = 1 if p5040 == 4
replace resid_ch = 2 if p5040 == 2 | p5040 == 3
replace resid_ch = 3 if p5040 == 5
replace resid_ch = . if p5040 == .	

*************
***dorm_ch***
*************
g dorm_ch = p5010
	
****************
***cuartos_ch***
****************
g cuartos_ch = p5000
	
***************
***cocina_ch***
***************
g cocina_ch = 0 if p5070 >= 2 & p5070 <= 6
replace cocina_ch = 1 if p5070 == 1
	
**************
***telef_ch***
**************
g telef_ch =.
*g telef_ch = p5210s1 == 1
*replace telef_ch = . if p5210s1 == .
	
***************
***refrig_ch***
***************
g refrig_ch =.
*g refrig_ch = p5210s5 == 1
*replace refrig_ch = . if p5210s5 == .
	
**************
***freez_ch***
**************
g freez_ch = .
	
*************
***auto_ch***
*************
g auto_ch =.
*g auto_ch = p5210s22 == 1
*replace auto_ch = . if p5210s22 == .
	
**************
***compu_ch***
**************
g compu_ch =.
*g compu_ch = p5210s16 == 1
*replace compu_ch = . if p5210s16 == .
	
*****************
***internet_ch***
*****************
g internet_ch =.
*g internet_ch = p5210s3 == 1
*replace internet_ch = . if p5210s3 == . 
	
************
***cel_ch***
************
g cel_ch =.
*g cel_ch = 0
*replace cel_ch = p5220==1
*replace cel_ch = . if p5220 == .
	

**************
***vivi1_ch***
**************
g vivi1_ch = 1     	 if p4000 == 1
replace vivi1_ch = 2 if p4000 == 2
replace vivi1_ch = 3 if p4000 == 3 | p4000 == 4 | p4000 == 5 | p4000 == 6
replace vivi1_ch = . if p4000 == .
	
**************
***vivi2_ch***
**************
g vivi2_ch = (p4000 == 1 | p4000 == 2)
replace vivi2_ch = . if p4000 == .
	

*****************
***viviprop_ch***
*****************
g viviprop_ch = 0 if p5090 == 3
replace viviprop_ch = 1 if p5090 == 1
replace viviprop_ch = 2 if p5090 == 2
replace viviprop_ch = 3 if p5090 == 4 | p5090 == 5 | p5090 == 6
replace viviprop_ch = . if p5090 == .
	
****************
***vivitit_ch***
****************
g vivitit_ch = .
	
****************
***vivialq_ch***
****************
g vivialq_ch = p5140 if p5140 >= 10000
	
*******************
***vivialqimp_ch***
*******************
g vivialqimp_ch = p5130 if p5130 >= 10000 


	***********************
	***VARIABLES DE WASH***
	***********************

****************
***aguared_ch***
****************
generate aguared_ch =.
replace aguared_ch = 1 if p4030s5==1 
replace aguared_ch = 0 if p4030s5==2

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0
replace aguafconsumo_ch = 1 if p5050==1 
replace aguafconsumo_ch = 2 if p5050==7 
replace aguafconsumo_ch = 3 if p5050==10 
replace aguafconsumo_ch = 5 if p5050==5 
replace aguafconsumo_ch = 6 if p5050==8 
replace aguafconsumo_ch = 7 if p5050==2
replace aguafconsumo_ch = 8 if p5050==6  
replace aguafconsumo_ch = 9 if (p5050==4 | p5050==9)
replace aguafconsumo_ch = 10 if (p5050==3| p5050==2)

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.
replace aguafuente_ch = 1 if p5050==1 
replace aguafuente_ch = 2 if p5050==7 
replace aguafuente_ch = 3 if p5050==10 
replace aguafuente_ch = 5 if p5050==5 
replace aguafuente_ch = 6 if p5050==8 
replace aguafuente_ch = 7 if p5050==2
replace aguafuente_ch = 8 if p5050==6  
replace aguafuente_ch = 9 if (p5050==4 | p5050==9)
replace aguafuente_ch = 10 if (p5050==3 | p5050==2)
replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1

*************
*aguadist_ch*
*************
gen aguadist_ch=.
replace aguadist_ch=1 if (p5050==1 | p5050==2)
replace aguadist_ch=0 if p5050>2


**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =.
*replace aguadisp1_ch = 1 if p4040==1
*replace aguadisp1_ch = 0 if p4040==2


**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9

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
generate aguamide_ch = .

*****************
****bano_ch******  Altered
*****************
gen bano_ch=.
replace bano_ch=0 if p5020==6
replace bano_ch=1 if p5020==1
replace bano_ch=2 if p5020==2
replace bano_ch=4 if p5020==5
replace bano_ch=6 if p5020==3 | p5020 ==4
replace bano_ch=6 if bano_ch ==. & jefe_ci==1


***************
***banoex_ch***
***************
generate banoex_ch=.
replace banoex_ch = 1 if p5030==1
replace banoex_ch = 0 if p5030==2

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if p5020<6


*****************
*banomejorado_ch*  Altered
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

