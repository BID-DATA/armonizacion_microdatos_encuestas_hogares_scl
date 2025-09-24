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

************
* Region_BID *
************
gen region_BID_c=.
replace region_BID_c=3 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

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
label var region_c "division politico-administrativa, departamento"

************
****pais_c****
************
g str3 pais_c = "COL"
la var pais_c "País"

**********
***anio_c***
**********
g anio_c = 2024
la var anio_c "Año de la encuesta"

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
la var zona_c "Zona del país"
la de zona_c 1 "Urbana" 0 "Rural"
la val zona_c zona_c

*********
*estrato*
*********
gen estrato_ci=.
	
*****************************
*unidad primaria de muestreo*
*****************************
gen upm_ci=...

***************
****idh_ch*****
***************
gen idh_ch = idh
la var idh_ch "ID del hogar"
tostring idh_ch, replace


**************
****idp_ci****
**************
g idp_ci=orden
la var idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


***************
***factor_ci***
***************
g factor_ci=fex_c18
la var factor_ci "Factor de expansión del individuo"

***************
***factor_ch***
***************
g factor_ch=fex_c18
la var factor_ch "Factor de expansión del hogar"

		****************************
		***VARIABLES DEMOGRAFICAS***
		****************************

*************
***sexo_ci***
*************
	g sexo_ci = p3271
	la var sexo_ci "Sexo del individuo" 
	la define sexo_ci 1 "Hombre" 2 "Mujer"
	la val sexo_ci sexo_ci

**********
***edad***
**********
	g edad_ci = p6040
	la var edad_ci "Edad del individuo (años)"

*****************
***relacion_ci***
*****************
	g 		relacion_ci = 1 if p6050 == 1
	replace relacion_ci = 2 if p6050 == 2
	replace relacion_ci = 3 if p6050 == 3
	replace relacion_ci = 4 if inlist(p6050,4,5,6,7,8,9)
	replace relacion_ci = 5 if p6050 == 11 | p6050 == 12 | p6050 == 13 
	replace relacion_ci = 6 if p6050 == 10
	la var relacion_ci "Relación con el jefe del hogar"
	la de relacion_ci 	1 "Jefe/a" 				///
						2 "Esposo/a" 			///
						3 "Hijo/a" 				///
						4 "Otros parientes" 	///
						5 "Otros no parientes" 	///
						6 "Empleado/a doméstico/a"
	la val relacion_ci relacion_ci

	
*****************
****civil_ci*****
*****************
	g 		civil_ci = .
	replace civil_ci = 1 if p6070 == 6
	replace civil_ci = 2 if p6070==1 | p6070==2 | p6070==3
	replace civil_ci = 3 if p6070==4 
	replace civil_ci = 4 if p6070==5
	la var civil_ci "Estado civil"
	la de civil_ci 	1 "Soltero" 				///
					2 "Unión formal o informal" ///
					3 "Divorciado o separado" 	///
					4 "Viudo"
	la val civil_ci civil_ci

**************
***jefe_ci***
*************
	g jefe_ci = relacion_ci == 1
	la var jefe_ci "Jefe de hogar"

******************
***nconyuges_ch***
******************
	bys idh_ch: egen nconyuges_ch = sum(relacion_ci == 2)
	la var nconyuges_ch "Número de cónyuges"

***************
***nhijos_ch***
***************
	bys idh_ch: egen nhijos_ch = sum(relacion_ci == 3)
	la var nhijos_ch "Número de hijos"

******************
***notropari_ch***
******************
	bys idh_ch: egen notropari_ch = sum(relacion_ci == 4)
	la var notropari_ch "Número de otros familiares"

********************
***notronopari_ch***
********************
	bys idh_ch: egen notronopari_ch = sum(relacion_ci == 5)
	la var notronopari_ch "Número de no familiares"

****************
***nempdom_ch***
****************
	bys idh_ch: egen nempdom_ch = sum(relacion_ci == 6)
	la var nempdom_ch "Número de empleados domésticos"

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
	
	la variable clasehog_ch "Tipo de hogar"
	la de clasehog_ch 	1 "Unipersonal" 	///
						2 "Nuclear" 		///
						3 "Ampliado" 		///
						4 "Compuesto" 		///
						5 "Corresidente"
	la val clasehog_ch clasehog_ch

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	la var nmiembros_ch "Número de familiares en el hogar"

****************
***miembros_ci***
****************
	g miembros_ci = (relacion_ci <= 4)
	la var miembros_ci "Miembro del hogar"
	
*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
	la var nmayor21_ch "Número de familiares mayores a 21 años"

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
	la var nmenor21_ch "Número de familiares menores a 21 años"

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
	la var nmayor65_ch "Número de familiares mayores a 65 años"

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
	la var nmenor6_ch "Número de familiares menores a 6 años"

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
	la var nmenor1_ch "Número de familiares menores a 1 año"



*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
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
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta
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
	ta noafroind_ci,m

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
	la var edupre_ci "Educación preescolar"


**************
***eduui_ci***
**************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria

	g byte eduui_ci = (inlist(p3042, 8, 9, 10, 11, 12, 13) & inlist(p3043, 2, 3, 4)) 
	replace eduui_ci = . if aedu_ci == .
	label variable eduui_ci "Superior incompleto"


***************
***eduuc_ci***
***************
* Nota: normalista es una modalidad especial que no hace parte de superior pero es postsecundaria

	g byte eduuc_ci = (inlist(p3042, 8, 9, 10, 11, 12, 13) & inlist(p3043, 5, 6, 7, 8, 9, 10))
	replace eduuc_ci = . if aedu_ci == .
	label variable eduuc_ci "Superior completo"

**************
***eduac_ci***
**************

	gen byte eduac_ci = .
	replace eduac_ci = 1 if (inlist(p3042, 10, 11, 12, 13) & inlist(p3043, 7, 8, 9, 10))
	replace eduac_ci = 0 if (inlist(p3042, 8, 9 ) & inlist(p3043, 5, 6))
	label variable eduac_ci "Superior universitario vs superior no universitario"


***************
***asiste_ci***
***************
	g asiste_ci = 1 if p6170 == 1
	replace asiste_ci = 0 if p6170 == 2
	la var asiste_ci "Asiste actualmente a la escuela"
	

***************
***edupub_ci***
***************
	g edupub_ci =.
	replace edupub=1 if p3041 == 1 & p6170==1
	replace edupub_ci = 0 if p3041 == 2 & p6170==1
	la var edupub_ci "Asiste a un centro de enseñanza público"


	
***************
***asispre_ci**
***************
	g asispre_ci= (p6170==1 & p3042==2 & p3042s1 <2)
	la var asispre_ci "Asiste a educación prescolar"

		
**************
*pqnoasis1_ci*
**************
g pqnoasis1_ci = .


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close







