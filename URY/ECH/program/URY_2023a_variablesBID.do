* (Versión Stata 12)
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

local PAIS URY
local ENCUESTA ECH
local ANO "2023"
local ronda a 


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
*local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

                                                
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES 
País: Uruguay
Encuesta: ECH

****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/

use `base_in', clear 

/************************************************************************/
/*				VARIABLES DEL HOGAR			*/
/************************************************************************/

*Replacing NAs
ds, has(type string)
foreach v in `r(varlist)' {
	replace `v' = "" if `v' == "NA"
	}


*1. Anio de la encuesta
gen anio_c=2023
label variable anio_c "Anio de la encuesta" 

*2. Mes de la encuesta
gen mes_c=mes

*3. País
gen str3 pais_c = "URY"


*4. region_BID_c
gen region_BID_c=.
replace region_BID_c = 4 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

*5. region_c 
gen ine01 = dpto
gen region_c = dpto
label define region_c  1 "Montevideo" ///
           2 "Artigas" /// 
           3 "Canelones" /// 
           4 "Cerro Largo" /// 
           5 "Colonia" /// 
           6 "Durazno" /// 
           7 "Flores" /// 
           8 "Florida" /// 
           9 "Lavalleja" /// 
          10 "Maldonado" /// 
          11 "Paysandú" /// 
          12 "Río Negro" /// 
          13 "Rivera" /// 
          14 "Rocha" /// 
          15 "Salto" /// 
          16 "San José" /// 
          17 "Soriano" /// 
          18 "Tacuarembó" ///
          19 "Treinta y Tres" 
label value region_c region_c


*6. Zona C 
gen zona_c=.
replace zona_c=1 if (region_4 == 1 | region_4 == 2)
replace zona_c=0 if (region_4 == 3 | region_4 == 4)
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

*7.estrato_ci
gen estrato_ci = estred13

*8. upm_ci
gen upm_ci =.

*9. Identificador del hogar
tostring id , gen(idh_ch)
tostring idh_ch, replace


*10. Identificador de persona
egen idp_ci = concat(idh_ch nper)
tostring idp_ci, replace


*11. Factor de expansión del hogar: 
gen factor_ch = w_ano 
label var factor_ch "Factor de Expansion del Hogar"

*12. Factor de expansión del hogar: 
gen factor_ci = w_ano 
label var factor_ch "Factor de Expansion del Hogar"

******** Variables Demograficas ********************* 


*Sexo
gen sexo_ci = e26
label var sexo_ci "Sexo del Individuo"
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

*Edad
gen edad_ci = e27
label var edad_ci "Edad del Individuo"

*Relación o parentesco con el jefe de hogar
/*
e30:
1 - Referente del hogar
2 - Esposo/a o compañero/a
3 - Hijo/a de ambos
4 - Hijo/a solo de la persona referente
5 - Hijo/a sólo del esposo/a compañero/a
6 - Yerno/nuera
7 - Padre/madre
8 - Suegro/a
9 - Hermano/a
10 - Cuñado/a
11 - Nieto/a
12 - Otro pariente
13 - Otro no pariente
14 - Servicio doméstico o familiar del mismo		  
*/

gen relacion_ci =.
replace relacion_ci = 1 if (e30 == 1)
replace relacion_ci = 2 if (e30 == 2)
replace relacion_ci = 3 if (e30 >= 3 & e30 <= 5)
replace relacion_ci = 4 if (e30 >= 6 & e30 <= 12)
replace relacion_ci = 5 if (e30 == 13)
replace relacion_ci = 6 if (e30 == 14)
label define relacion_ci 1 "Jefe" 2 "Conyuge" 3 "Hijo" 4 "Otros Parientes" 5 "Otros no Parientes" 6 "Servicio Domestico"
label values relacion_ci relacion_ci


*Estado civil
/*CODIGO ANTERIOR
gen civil_ci = 2 	if (e33 == 1)
replace civil_ci = 1  if (e36 == 5 & e33 == 2)
replace civil_ci = 3  if ((e36 == 1 | e36 == 2 | e36 == 3) & e33 == 2)
replace civil_ci = 4  if ((e36 == 4 | e36 == 6) & e33 == 2)*/

/*civil_ci
Variable que identifica el estado civil del individuo.
1	Soltero
2	Unión formal o informal
3	Divorciado o separado
4	Viudo*/

* Importante combinar e35 & e36 
gen civil_ci=.
replace civil_ci = 1 if (e36 == 5 & e33 ==2) 
replace civil_ci = 2 if (e33 == 1)
replace civil_ci = 2 if (e36 == 3 & e33 ==2) 
replace civil_ci = 3 if (e36 == 1 & e33 ==2) | (e36 == 2 & e33 ==2) 
replace civil_ci = 4 if (e36 == 4 & e33 ==2) | (e36 == 6 & e33 ==2)

label var civil_ci "Estado Civil"
label define civil_ci 1 "Soltero" 2 "Union Formal o Informal" 3 "Divorciado o Separado" 4 "Viudo"
label value civil_ci civil_ci


**************
***jefe_ci***
*************

gen jefe_ci = (relacion_ci == 1)
label variable jefe_ci "Jefe de hogar"


******************
***nconyuges_ch***
******************

by idh_ch, sort: egen nconyuges_ch = sum(relacion_ci==2)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************

by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************

by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************

by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
label variable notronopari_ch "Numero de no familiares"


****************
***nempdom_ch***
****************
****************
by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
label variable nempdom_ch "Numero de empleados domesticos"


*****************
***clasehog_ch***
*****************

gen byte clasehog_ch=.
**** unipersonal
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
**** nuclear   (child with or without spouse but without other relatives)
replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
**** ampliado
replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
**** compuesto  (some relatives plus non relative)
replace clasehog_ch=4 if (nhijos_ch>0| nconyuges_ch>0|notropari_ch>0) & notronopari_ch>0
**** corresidente
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

label variable clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
label value clasehog_ch clasehog_ch

******************
***nmiembros_ch***
******************

by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
label variable nmiembros_ch "Numero de familiares en el hogar"

*****************
***nmayor21_ch***
*****************

by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************

by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************

by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************

by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************

by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

****************
***miembros_ci***
****************

gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar" 
									

									
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
/*Pregunta: ¿Cree tener ascendencia...?
e29_1	1 = Si / 2 = No           Afro o negra
e29_2	1 = Si / 2 = No           Amarilla
e29_3	1 = Si / 2 = No           Blanca
e29_4	1 = Si / 2 = No           Indígena
e29_5  	 						  Otro 
e29_6   						  Ascendencia principal [NO UTILIZAMOS ESTA VARIABLE PARA CONSTRUIR NUESTRAS 
															VARIABLES DE IDENTIFICACIÓN ÉTNICO-RACIAL]
 */
**Pueden reportar más de una identidad por lo que hay una población afroindigena.


	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  
	replace afro_ci = 1 if e29_1 == 1 
	replace afro_ci = 0 if e29_1 == 2
	
	*********
	*ind_ci*
	*********	
	gen byte ind_ci =. 
	replace ind_ci = 1 if e29_4 == 1 
	replace ind_ci = 0 if e29_4 == 2
	
	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci = 1 if (afro_ci == 0 | ind_ci == 0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci = 0 if (afro_ci == 1 | ind_ci == 1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci = . if (afro_ci == . & ind_ci == .)
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
	gen byte URY_dis_ci = .

*  VARIABLES LABORALES

****condocup_ci*
****************
gen condocup_ci =.
*Se genera variable con base en variable original de la encuesta pobpcoac
replace condocup_ci = 1 if (pobpcoac == 2)
replace condocup_ci = 2 if (pobpcoac == 3 | pobpcoac == 4 | pobpcoac == 5)
replace condocup_ci = 3 if (pobpcoac >= 6 & pobpcoac <= 11)
replace condocup_ci = 4 if (pobpcoac == 1)
label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor que 14"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"

*******************
***categoinac_ci***
*******************
gen categoinac_ci = .
replace categoinac_ci = 1 if ((pobpcoac == 9 | pobpcoac == 10) & condocup_ci == 3) // Jubilados o pensionistas
replace categoinac_ci = 2 if  (pobpcoac == 7 & condocup_ci == 3) // Estudiantes
replace categoinac_ci = 3 if  (pobpcoac == 6 & condocup_ci == 3) // Quehaceres del hogar
replace categoinac_ci = 4 if  ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3) // Otros inactivos
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 
label values categoinac_ci categoinac_ci

***emp_ci***
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
label var emp_ci "Ocupado (empleado)"
label define emp_ci 0"No" 1"Si", add
label value emp_ci emp_ci

destring f70, replace
gen nempleos_ci = f70

gen antiguedad_ci =.

***desemp_ci****
gen desemp_ci=(condocup_ci==2)

*cesante_ci* 
gen cesante_ci=.
replace cesante_ci=1 if (pobpcoac == 4 | pobpcoac == 5)
replace cesante_ci=0 if pobpcoac == 3

*durades_ci
gen durades_ci=f113/4.3 if f113>0
replace durades_ci=. if pobpcoac!=3 & pobpcoac!=4 & pobpcoac!=5

***pea_ci****
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1

*desalent_ci
***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
gen byte desalent_ci = .
replace desalent_ci = 1 if (f299 == 2 & f108 == 4 & condocup_ci == 3)
replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)
label var desalent_ci "Desalentados"
label define desalent_ci 0 "No" 1 "Si", add
label value desalent_ci desalent_ci

*horaspri_ci
gen horaspri_ci=f85
replace horaspri_ci=. if f85==98 | emp_ci==0

gen horastot_ci = (f85 + f98)
replace horastot_ci=. if f85==98 | emp_ci==0
replace horastot_ci=. if f98==98 | emp_ci==0


gen subemp_ci = 0
replace subemp_ci = 1 if (horaspri_ci >= 1 & horaspri_ci <= 30) & (f102 == 1 & f103 == 1)

gen tiempoparc_ci = (horaspri_ci >= 1 & horaspri_ci < 30 & f102 == 2)
replace tiempoparc_ci =. if emp_ci == 0

*66. Categoría ocupacional en la actividad principal

/*
f73	1	Asalariado/a privado/a
	2	Asalariado/a público/a
	3	Miembro de cooperativa de producción o trabajo
	4	Patrón/a
	9	Cuenta propia
	7	Miembro del hogar no remunerado
	8	Trabajador/a de un programa social de empleo

*/

gen categopri_ci = 1 	if (f73 == 4)
replace categopri_ci = 2 	if (f73 == 3 | f73 == 9)
replace categopri_ci = 3 	if (f73 == 1 | f73 == 2 | f73 == 8)
replace categopri_ci = 4 	if (f73 == 7) 
replace categopri_ci =. 	if (emp_ci != 1 | f73 == 0)

label define categopri_ci 1"Patron" 2"Cuenta propia" 
label define categopri_ci 3"Empleado" 4"No remunerado", add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional trabajo principal"

*67. Categoría ocupacional en la actividad secundaria

/*
f92	1	Asalariado/a privado/a
	2	Asalariado/a público/a
	3	Miembro de cooperativa de producción o trabajo
	4	Patrón/a
	9	Cuenta propia
	7	Miembro del hogar no remunerado
	8	Trabajador/a de un programa social de empleo


*/

gen categosec_ci = 1 if (f92 == 4)
replace categosec_ci = 2 if (f92 == 9 | f92 == 3)
replace categosec_ci = 3 if (f92 == 1 | f92 == 2 | f92 == 8)
replace categosec_ci = 4 if (f92 == 7) 
replace categosec_ci =. if (f92 == 0)

label define categosec_ci 1"Patron" 2"Cuenta propia" 
label define categosec_ci 3"Empleado" 4" No remunerado", add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo principal"

*26. Rama laboral de la actividad principal   
/*
destring f72_2, replace force
recode f72_2 (0000/0400=1 "Agricultura, caza, silvicultura y pesca") (0500/1000=2 "Explotación de minas y canteras") (1010/3400=3 "Industrias manufactureras") /*
*/ (3500/4000=4 "Electricidad, gas y agua") (4100/4400=5 "Construcción") (4400/4800=6 "Comercio, restaurantes y hoteles") /*
*/ (4900/6400=7 "Transporte y almacenamiento") (6410/8300=8 "Establecimientos financieros, seguros e inmuebles") /*
*/ (8400/9900=9 "Servicios sociales y comunales"),gen(rama_ci)
replace rama_ci=. if condocup_ci !=1
*/
destring f72_2, replace force
gen rama_ci=.
replace rama_ci=1 if (f72_2>0 & f72_2<=400) & emp_ci==1
replace rama_ci=2 if (f72_2>=500 & f72_2<=1000) & emp_ci==1
replace rama_ci=3 if (f72_2>=1010 & f72_2<=3400) & emp_ci==1
replace rama_ci=4 if (f72_2>=3500 & f72_2<=4000) & emp_ci==1
replace rama_ci=5 if (f72_2>=4100 & f72_2<=4400) & emp_ci==1
replace rama_ci=6 if ((f72_2>=4500 & f72_2<=4800) | (f72_2>=5500 & f72_2<=5700))& emp_ci==1
replace rama_ci=7 if ((f72_2>=4900 & f72_2<=5400) | (f72_2>=6100 & f72_2<=6199)) & emp_ci==1
replace rama_ci=8 if (f72_2>=6400 & f72_2<=8300) & emp_ci==1
replace rama_ci=9 if ((f72_2>=5800 & f72_2<=6090) | (f72_2>=6200 & f72_2<=6399) | (f72_2>=8400 & f72_2<=9900))& emp_ci==1

gen spublico_ci = (f73 == 2)
replace spublico =. if emp_ci ==.

gen tamemp_ci = 1 if (f77 == 1 | f77 == 2) // 1 a 4 personas
replace tamemp_ci = 2 if (f77 >= 3 & f77 <= 5) // 5 a 49 personas
replace tamemp_ci = 3 if (f77 >= 7 & f77 <= 9) // 50 o más personas
replace tamemp_ci =. if (f77 == 0 | f77 ==.)
label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
label values tamemp_ci tamaño

****************
*cotizando_ci***
****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte cotizando_ci = .
replace cotizando_ci = 1 if ((f82==1 | f96==1) & emp_ci==1)
replace cotizando_ci = 0 if ((f82==2 | f96==2) & inlist(condocup_ci, 1, 2) )
label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0 "No"  1 "Si"
label value cotizando_ci cotizando_ci

********************
*** instcot_ci *****
********************

gen instcot_ci=f83
replace instcot_ci=. if instcot_ci==0
label define  instcot_ci 1"bps" 2"bps y afap" 3"policial" 4"militar" 5"profesional" 6 "notarial" 7"bancaria" 8"en el exterior"
label value instcot_ci instcot_ci
label var instcot_ci "institución a la cual cotiza por su trabajo"

****************
*afiliado_ci**** 
****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte afiliado_ci = .
replace afiliado_ci = 1 if ((f82==1 | f96==1) & emp_ci==1)
replace afiliado_ci = 0 if ((f82==2 | f96==2) & inlist(condocup_ci, 1, 2))
label var afiliado_ci "Afiliado a la Seguridad Social"
label define afiliado_ci 0 "No"  1 "Si"
label value afiliado_ci afiliado_ci

*******************
***formal***
*******************
gen byte formal_ci = (cotizando_ci == 1)
label var formal_ci "1=afiliado o cotizante / PEA"

*****************
*tipocontrato_ci*
*****************
gen tipocontrato_ci=. /* No preguntan*/

*25. Ocupación laboral actividad principal *** 
destring f71_2, replace
gen ocupa_ci =.
replace ocupa_ci=1 if (f71_2>=2111 & f71_2<=3522) & emp_ci==1
replace ocupa_ci=2 if (f71_2>=1111 & f71_2<=1439) & emp_ci==1
replace ocupa_ci=3 if (f71_2>=4110 & f71_2<=4419 | f71_2>=410 & f71_2<=430) & emp_ci==1
replace ocupa_ci=4 if ((f71_2>=5211 & f71_2<=5249) | (f71_2>=9510 & f71_2<=9520)) & emp_ci==1
replace ocupa_ci=5 if ((f71_2>=5111 & f71_2<=5169) | (f71_2>=5311 & f71_2<=5419) | (f71_2>=9111 & f71_2<=9129) | (f71_2>=9611 & f71_2<=9624) ) & emp_ci==1 /*Aunque no esta desagregado en la base, esta es la desagregación a tres digitos de la CIUO-88*/
replace ocupa_ci=6 if ((f71_2>=6111 & f71_2<=6340) | (f71_2>=9211 & f71_2<=9216)) & emp_ci==1
replace ocupa_ci=7 if ((f71_2>=7111 & f71_2<=8350) | (f71_2>=9311 & f71_2<=9412)) & emp_ci==1 /*Incluye artesanos y operarios en hilanderias*/
replace ocupa_ci=8 if (f71_2>=110 & f71_2<=310) & emp_ci==1
replace ocupa_ci=9 if (f71_2==9629) & emp_ci==1

label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1"Profesional y tecnico" 2"Director o funcionario sup" 3"Administrativo y nivel intermedio"
label define ocupa_ci  4 "Comerciantes y vendedores" 5 "En servicios" 6 "Trabajadores agricolas", add
label define ocupa_ci  7 "Obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci


*************
**pension_ci*
*************
// Existe un filtro para la sección de jubilados, pero hay inconsistencias entre f124_1, f125, g_it_1 & g148_1*:
egen double aux_jub = rowtotal(g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_10 g148_1_11 g148_1_12), mi
gen byte f_jub = (aux_jub > 0) if !missing(aux_jub) 	// Reportó algun monto en la sección de jubilaciones
replace f_jub = . if f124_1 == "0" & f_jub == 0		    // Se excluye a quienes no se les realiza la pregunta

gen pension_ci = f_jub
replace pension_ci = 0 if g148_1_11 > 0 & pension_ci == 1	 // Se excluyen jubilaciones extranjeras


***************
*pensionsub_ci*
***************
// Existe un filtro para la sección de pensionista, pero hay inconsistencias entre f124_2, f125, g_it_2 & g148_2*:
egen double aux_pens = rowtotal(g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9 g148_2_10 g148_2_11 g148_2_12), mi
gen byte f_pens = (aux_pens > 0) if !missing(aux_pens) 		// Reportó algun monto en la sección de pensiones
replace f_pens = . if f124_2 == "0" & f_pens == 0		    // Se excluye a quienes no se les realiza la pregunta

gen pensionsub_ci = (f125 == 1 & f_pens == 1) if !missing(f_pens)
replace pensionsub_ci = 0 if g148_2_11 > 0 & pensionsub_ci == 1 	// Se excluyen pensiones extranjeras
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

****************
*tipopen_ci*****
****************
gen tipopen_ci = f125
replace tipopen_ci =. if f125 == 0
label define tipopen_ci 1"vejez" 2"fallecimiento" 3"invalidez" 4"extranjero" 5"victima" 6"hijos de fallecidos por violencia doméstica" 7"pensión especial reparatoria" 8"pensión reparatoria personas trans"
label var tipopen_ci "Tipo de pension - variable original de cada pais" 
label value tipopen_ci tipopen_ci


****************
*instpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 


*************************************************
*** VARIABLES DE INGRESOS & PROTECCION SOCIAL ***
*************************************************

*A. INGRESO LABORAL (MONETARIO Y NO MONETARIO) ***

*29. Ingreso laboral monetario actividad principal

/* Relacion de Dependencia
SUELDO O JORNALES LÍQUIDOS	                            g126_1		
COMISIONES, INCENTIVOS, HORAS EXTRAS, HABILITACIONES	g126_2	
VIÁTICOS NO SUJETOS A RENDICIÓN	                        g126_3	
PROPINAS	                                            g126_4	
AGUINALDO	                                            g126_5	
SALARIO VACACIONAL	                                    g126_6	
PAGOS ATRASADOS	                                        g126_7	

Cuenta propia
DISTRIBUCIÓN DE UTILIDADES	g143	$	

recibió ingresos por medianería o
aparcería, pastoreo o ganado a capitalización? g259

RETIRO REALIZADO PARA GASTOS DEL HOGAR	g142	$
*/

gen g143_ = g143/12
gen g145_ = g259/12

destring g126_7, replace
destring g142, replace

egen double ylmpri_ci = rowtotal(g126_1 g126_2  g126_3  g126_4  g126_5  g126_6  g126_7 g142 g143_ g145_ g133_2) if emp_ci == 1, missing

replace ylmpri_ci=. if (g126_1==. & g126_2==. & g126_3==. &  g126_4==. &  g126_5==. &  g126_6==. &  g126_7==. &  g143_==. & g145_==.)


*30. Ingreso laboral no monetario actividad principal
*BOLETOS DE TRANSPORTE	                                g126_8	
*Alimentos g127_3
*Tickets de alimentacion g128_1
*Vivienda o alojamiento g129_2
* Otra retribución en especie g130_1
* Otro tipo de complemento pagado por el empleador g131_1
*Principal: ¿Cuánto hubiera tenido que pagar por esos productos que consumió el mes pasado? g133_1
/*
	

RETIRO DE PRODUCTOS PARA CONSUMO PROPIO (trabajador no agropecuario)	g144_1	$	Monto que habría tenido que pagar por esos bienes
RETIRO DE PRODUCTOS PARA CONSUMO PROPIO (trabajador agropecuario)	
    g144_2_1	$	Valor de lo consumido en carnes o chacinados
	g144_2_2	$	Valor de lo consumido en lácteos
	g144_2_3	$	Valor de lo consumido en huevos y aves
	g144_2_4	$	Valor de lo consumido en productos de la huerta
	g144_2_5	$	Valor consumido en otros alimentos


g127_1	Nº	Cantidad de desayunos / meriendas
g127_2	Nº	Cantidad de almuerzos / cenas
g127_3	$	Otros - Monto estimado
*/

gen desay = (g127_1*mto_desay)
gen almue = (g127_2*mto_almue)
*gen cuota = En este año no se pregunta acerca de la cuota mutual.
/*
DERECHO A PASTOREO	g132_1	Nº	Vacunos
DERECHO A PASTOREO	g132_2	Nº	Ovinos
DERECHO A PASTOREO	g132_3	Nº	Equinos
*/

gen vacas = (g132_1*mto_vacas)
gen oveja = (g132_2*mto_oveja)
gen caballo = (g132_3*mto_caball)

*No costa la variable disse en el formulario.

destring g144_1, replace 

egen double ylnmpri_ci = rowtotal(desay almue vacas oveja caballo g126_8 g127_3 g128_1 g129_2 g130_1 g131_1 g133_1 g144_1 g144_2_1 g144_2_2 g144_2_3 g144_2_4 g144_2_5) if emp_ci==1, missing

*31. Ingreso Laboral Monetario actividad secundaria
/*
SUELDO O JORNALES LÍQUIDOS	g134_1	
COMISIONES, INCENTIVOS, HORAS EXTRAS, HABILITACIONES	g134_2	
VIÁTICOS NO SUJETOS A RENDICIÓN	g134_3	
PROPINAS	g134_4	
AGUINALDO	g134_5	
SALARIO VACACIONAL	g134_6	
PAGOS ATRASADOS	g134_7	
DERECHO A CULTIVO PARA CONSUMO PROPIO g141_2	$	Monto percibido por la venta de esos productos
*/
egen double ylmsec_ci = rowtotal(g134_1 g134_2  g134_3  g134_4  g134_5  g134_6  g134_7 g141_2) if emp_ci == 1, missing 

*32. Ingreso laboral no monetario actividad secundaria
/*
BOLETOS DE TRANSPORTE	g134_8	
COMIDAS Y MERIENDAS	g135_3	
TIQUES DE ALIMENTACIÓN	g136_1	
RECIBIÓ VIVIENDA O ALOJAMIENTO	g137_2	
RECIBIÓ OTRO TIPO DE RETRIBUCIÓN EN ESPECIE	g138_1	
RECIBIÓ ALGÚN OTRO TIPO DE COMPLEMENTO PAGADO POR EL EMPLEADOR	g139_1	$	Monto estimado

*/

**Secundaria: DERECHO A CULTIVO PARA CONSUMO PROPIO g141_1	$	Monto que habría tenido que pagar por esos productos
/*RECIBIÓ ALIMENTOS O BEBIDAS	g135_1	Nº	Número de desayunos / meriendas
RECIBIÓ ALIMENTOS O BEBIDAS	g135_2	Nº	Número de almuerzos / cenas
DERECHO A PASTOREO	g140_1	Nº	Vacunos
DERECHO A PASTOREO	g140_2	Nº	Ovinos
DERECHO A PASTOREO	g140_3	Nº	Equinos
*/

destring g135_1, replace
destring g135_2, replace

gen desaysec = (g135_1*mto_desay)
gen almuesec = (g135_2*mto_almue)
*gen cuota = En este año no se pregunta acerca de la cuota mutual.

gen vacassec = (g140_1*mto_vacas)
gen ovejasec = (g140_2*mto_oveja)
gen caballosec = (g140_3*mto_caball)

destring g135_3, replace
destring g136_1, replace
destring g137_2, replace
destring g138_1, replace
destring g139_1, replace

egen double ylnmsec_ci = rowtotal(desaysec almuesec vacassec ovejasec caballosec g134_8 g135_3 g136_1 g137_2 g138_1 g139_1 g141_1) if emp_ci ==1, missing


*****************
***nrylmpri_ci***
*****************
g nrylmpri_ci = (ylmpri_ci==. & emp_ci==1)
replace nrylmpri_ci =. if emp_ci != 1 | categopri_ci == 4 /*excluding unpaid workers*/
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal" 

*33. Ingreso laboral monetario otros trabajos
egen double ylmotros_ci = rowtotal(g126_1 g126_2  g126_3  g126_4  g126_5  g126_6  g126_7  g142 g143_ g145_ g133_2 g134_1 g134_2  g134_3  g134_4  g134_5  g134_6  g134_7 g141_2) if emp_ci==0 , missing

*34. Ingreso laboral no monetario otros trabajos
egen double ylnmotros_ci = rowtotal(desay almue vacas oveja caballo g126_8 g127_3  g128_1 g129_2 g130_1 g131_1 g133_1 g144_1 g144_2_1 g144_2_2 g144_2_3 g144_2_4 g144_2_5 desaysec almuesec vacassec ovejasec caballosec g134_8 g135_3 g136_1 g137_2 g138_1 g139_1 g141_1) if emp_ci == 0, missing


*35. Identificador de No respuesta (NR) del ingreso de la actividad principal

gen nrylmpri=.

*36. Identificador del top-code del ingreso de la actividad principal

gen tcylmpri_ci=.


*37. Ingreso laboral monetario total

egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==. & ylmotros_ci==.

* Nota Marcela G. Rubio - Abril 2014
* Incluyo ingreso laboral monetario otros como parte del ingreso laboral monetario total ya que no había sido incluido

*38. Ingreso laboral no monetario total

egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==. & ylnmotros_ci==.

* Nota Marcela G. Rubio - Abril 2014
* Incluyo ingreso laboral no monetario otros como parte del ingreso laboral no monetario total ya que no había sido incluido


*B. INGRESO NO LABORAL (MONETARIO Y NO MONETARIO) ***

********************************************************
*** ytransf_ci: Transferencias de programas sociales ***
********************************************************

* PNC - Pensiones sociales no contributivas:
		* 1 Pensiones de vejez f125 == 1
* PTMC - Programas de transferencias monetarias condicionadas:
		* 2 Asignaciones familiares - Plan de Equidad del MIDES g255== 1 
		* 2b Partida adicional de AFAM PE (se suma al monto porque en el filtro está contenido)
* POTROT - Programas de otras transferencias monetarias no condicionadas
		* 3 Pensión por invalidez f125==3
		* 4 Pensión a las víctimas de delitos violentos f125== 5
		* 5 Pensión para hijos de fallecidos por violencia doméstica f125== 6
		* 6 Pensión Especial Reparatoria f125== 7
		* 7 Pensión Reparatoria Ley Integral para Personas Trans f125== 8
		* 8 Tarjeta Uruguay Social (TUS)
			* MIDES e560_1==1
			* INDA  e560_2==1
			* Bono de Crianza e560_3==1 (desde el 2023)

/*Nota: Existe inconsistencias entre los filtros y montos de la seccion de pensiones no
contributivas: f124_2, f125, g_it_2, g148_2*. En la seccion laboral se creó un filtro auxiliar
para identificar a las personas que declaran al menos un monto en esta sección.
	* Variable filtro auxiliar jubilados f_jub & suma de monto aux_jub (+g148_1*)
	* Variable filtro auxiliar pensiones f_pens & suma de monto aux_pens (+g148_2*) */

*** Beneficiarios a nivel individual:
	
	// PNC
	gen byte pnc_ci = (f125 == 1 & f_pens == 1) if !missing(f_pens)

	// PTMC
	gen byte ptmc_ci = (g255 == 1) if g255 != 0
	replace ptmc_ci = 1 if g257 > 0 & g257 != .
	replace ptmc_ci = 0 if g257 == 0 & g255 != 0
	
	// POTROT	
	gen byte inval_ci = (f125 == 3 & f_pens == 1) if !missing(f_pens)
	replace inval_ci = 0 if inval_ci == 1 & aux_pens > 0 & (g148_2_1 == 0 & g148_2_2 == 0 & g148_2_3 == 0)  // Se les reclasifica como no beneficiarios, ya que solo reciben dinero de otras fuentes 
		
	gen byte vdelit_ci = (f125 == 5 & f_pens == 1) if !missing(f_pens)
		
	gen byte violdom_ci = (f125 == 6 & f_pens == 1) if !missing(f_pens)
		
	gen byte pesprep_ci = (f125 == 7 & f_pens == 1) if !missing(f_pens)
	replace pesprep_ci = 0 if pesprep_ci== 1 & g148_2_10 > 0 & (g148_2_1 == 0 & g148_2_2 == 0 & g148_2_3 == 0)  // Se les reclasifica como no beneficiarios a personas que indican "otra"
	
	gen byte petrans_ci = (f125 == 8 & f_pens == 1)
	replace petrans_ci = 0 if petrans_ci== 1 & g148_2_10 > 0 & (g148_2_1 == 0 & g148_2_2 == 0 & g148_2_3 == 0)  // Se les reclasifica como no beneficiarios a personas que indican "otra"
		
	gen byte tus_ci = (e560_1 == 1 | e560_2 == 1 | e560_3 == 1)
	replace tus_ci = . if e560_1 == 0 & e560_2 == 0 & e560_3 == 0
	
	gen byte potrot_ci = (inval_ci == 1 | vdelit_ci == 1 | violdom_ci == 1 | pesprep_ci == 1 | petrans_ci == 1 |tus_ci == 1)
	replace potrot_ci = . if inval_ci == . & vdelit_ci == . & violdom_ci == . & pesprep_ci == . & petrans_ci == . & tus_ci == .
	
*** Montos de transferencias a nivel individual:

	// Transferencias PNC
	egen double ypnc_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if pnc_ci == 1, mi
		
	// Transferencias PTMC
	gen double yadicional_ci = g261_1 if g261 == 2
	egen double yptmc_ci = rowtotal(g257 yadicional_ci) if ptmc_ci == 1
	
	// Otras transferencias POTROT
	egen double yinval_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if inval_ci == 1, mi	
	egen double yvdelit_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if vdelit_ci == 1, mi
	egen double yvioldom_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if violdom_ci == 1, mi
	egen double ypesprep_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if pesprep_ci == 1, mi
	egen double ypetrans_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if petrans_ci == 1, mi
	egen double ytus_ci = rowtotal(e560_1_1 e560_2_1 e560_3_1) if tus_ci == 1, mi
		
	egen double yotrot_ci = rowtotal(yinval_ci yvdelit_ci yvioldom_ci ypesprep_ci ypetrans_ci ytus_ci), mi


*** Ingreso individual por transferencias no contributivas
egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi


*** Remesas: Estan reportadas a nivel de hogar (h172_1) ***
gen remesas_ci = .


*** ypen_ci: Jubilación contributiva ***
egen double ypen_ci = rowtotal(g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_10 g148_1_12) if f_jub == 1, mi  // Se excluyen pensiones del exterior (g148_1_11)

replace ypen_ci = . if pension_ci == .
label var ypen_ci "Valor de la pension contributiva"


*** ypen_ci: Pensión no contributiva ***
gen ypensub_ci = ypnc_ci
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"


*39. ynlm_ci. Ingreso no laboral monetario (otras fuentes) ***

/*
Recibió el mes pasado por JUBILACIONES:			
BPS - CAJA INDUSTRIA Y COMERCIO	g148_1_1	$	
BPS - CAJA CIVIL Y ESCOLAR	g148_1_2	$	
BPS - RURAL Y SERVICIO DOMÉSTICO	g148_1_3	$	
UNIÓN POSTAL	g148_1_4	$	
POLICIAL	g148_1_5	$	
MILITAR	g148_1_6	$	
PROFESIONAL	g148_1_7	$	
NOTARIAL	g148_1_8	$	
BANCARIA	g148_1_9	$	
AFAP (ingresos provenientes únicamente de alguna AFAP)	g148_1_12	$	
OTRA 	g148_1_10	$	
OTRO PAÍS	g148_1_11	$	

Recibió el mes pasado por PENSIONES:			
BPS - CAJA INDUSTRIA Y COMERCIO	g148_2_1	$	
BPS - CAJA CIVIL Y ESCOLAR	g148_2_2	$	
BPS - RURAL Y SERVICIO DOMÉSTICO	g148_2_3	$	
UNIÓN POSTAL	g148_2_4	$	
POLICIAL	g148_2_5	$	
MILITAR	g148_2_6	$	
PROFESIONAL	g148_2_7	$	
NOTARIAL	g148_2_8	$	
BANCARIA	g148_2_9	$	
AFAP (ingresos provenientes únicamente de alguna AFAP)	g148_2_12	$	
OTRA 	g148_2_10	$	
OTRO PAÍS	g148_2_11	$	

SEGURO DE DESEMPLEO	g148_3	$	
COMPENSACIONES POR ACCIDENTE, MATERNIDAD O ENFERMEDAD	g148_4	$	
BECAS, SUBSIDIOS, DONACIONES	g148_5_1	$	Del país
	g148_5_2	$	Del extranjero

COBRA HOGAR CONSTITUIDO g149 mto_hogcon 

RECIBE PENSIÓN ALIMENTICIA O ALGUNA CONTRIBUCIÓN POR DIVORCIO O SEPARACIÓN		
	g153_1	$	Del país
	g153_2	$	Del extranjero
G4 OTROS INGRESOS			
	g154_1	$	Monto que cobró el mes pasado */


// Variable para el beneficio social de "hogar constituido" (y no está declarado en el sueldo)
gen double tr_hogc = mto_hogcon if g149 == 1 & g149_1 == 2


// Otras pensiones no contributivas: policial, militar, profesionales, notarial, bancario, AFAP, Otra
 
egen double aux_pnc = rowtotal(g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9 g148_2_10 g148_2_12), mi

	foreach v in pnc inval vdelit violdom pesprep petrans {
		gen `v'_2 = y`v'_ci
		replace `v'_2 = 0 if y`v'_ci == .
	}

gen double otras_pension148 = (aux_pnc - pnc_2 - inval_2 - vdelit_2 - violdom_2 - pesprep_2 - petrans_2)
drop pnc_2 inval_2 vdelit_2 violdom_2 pesprep_2 petrans_2


// Se agregan los ingresos no laborales: transferencias del extranjero, becas, desemeplo

egen double ynlm_ci = rowtotal(ypen_ci g148_1_11 tr_hogc ytransf_ci otras_pension148 g148_2_11 g148_3 g148_4 g148_5_1 g148_5_2 g153_1 g153_2 g154_1 remesas_ci), mi


*40. ynlnm_ci. Ingreso no laboral no monetario ***

/* TIPO DE CANASTA	e246	
		7	Celíacos
		14  Canasta MIDES (UCC, INDA, emergencia o cualquier otra proporcionada por MIDES)
		11	Otra (sin monto) */		

gen double canasta_celi = (e247 * indaceliac) if e246 == 7
gen double canasta_emer = (e247 * indaemer) if e246 == 14

egen double ynlnm_ci = rowtotal(canasta_celi canasta_emer), mi


***************
*** ytot_ci ***
*************** 
egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi


***************
*** ynet_ci: Ingreso neto individual = Ingreso primario + transferencias privadas ***
***************
gen double aux_ytransf_ci = ytransf_ci*(-1)
egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
drop aux_ytransf_ci


*C. INGRESOS DEL HOGAR ***


*41. Identificador de los hogares en donde alguno de los miembros no sabe/No responde el ingreso de
*la actividad principal.

by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, mi
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.
label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"


*42. Identificador de los hogares en donde alguno de los miembros reporta
*como top code el ingreso de la actividad principal

gen tcylmpri_ch=.


*43. Ingreso laboral monetario del hogar

bys idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi


*44. Ingreso laboral no monetario del hogar

bys idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi

****************
*** ylmnr_ch ***
****************
by idh_ch, sort: egen ylmnr_ch = total(ylm_ci) if miembros_ci==1, mi
replace ylmnr_ch=. if nrylmpri_ch==1


**************************************************************************
*** ytransf_ch: Ingresos por Transferencias no contributivas del Hogar ***
**************************************************************************

*** Beneficiarios a nivel hogar:
	bys idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1
	bys idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1
	bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
	
	gen byte pcasht_ch = (ptmc_ch == 1 | pnc_ch == 1 | potrot_ch == 1)
	replace pcasht_ch = . if ptmc_ch == . & pnc_ch == . & potrot_ch == .

*** Montos de transferencias a nivel hogar:
	bys idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

*** Ingreso del Hogar por transferencias no contributivas
egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi


****************
***remesas_ch***
****************
/* Preguntas nivel de HOGAR y ANUAL:
RECIBIÓ ALGUNA COLABORACIÓN ECONÓMICA DE ALGÚN FAMILIAR DEL EXTERIOR h172_1 $ Anual */

gen double  h172_1m =  h172_1/12
gen double remesas_ch = h172_1m if miembros_ci == 1
label var remesas_ch "Remesas mensuales del hogar" 


*******************************************************
*** ynlm_ch: Ingreso no laboral monetario del hogar ***
*******************************************************

/* Preguntas nivel de HOGAR >
	RECIBE DINERO DE ALGÚN FAMILIAR U OTRO HOGAR DEL PAÍS h155_1 $Mensual
	FUERON ALQUILADAS 	h160_1	$	Alquileres del país
	FUERON ALQUILADAS 	h160_2	$	Alquileres del extranjero
	RECIBIÓ POR ARRENDAMIENTO	h163_1	$	Arrendamientos del país
	RECIBIÓ POR ARRENDAMIENTO	h163_2	$	Arrendamientos del extranjero
	RECIBIÓ POR MEDIANERÍA	h164	$	
	RECIBIÓ POR PASTOREO	h165	$	
	RECIBIÓ POR GANADO A CAPITALIZACIÓN	h166	$	
	RECIBIÓ POR INTERESES	h167_1_1	$	Intereses del país o del extranjero
	RECIBIÓ POR UTILIDADES Y DIVIDENDOS DE ALGÚN NEGOCIO EN EL QUE NO TRABAJA	h170_3	$	Utilidades y dividendos del país o del extranjero
	RECIBIÓ INDEMINZACIÓN POR DESPIDO	h171_1	$		
	RECIBIÓ ALGÚN INGRESO EXTRAORDINARIO	h173_1	$ */

// Se mensualizan los monto anuales:
foreach i in h160_1 h160_2 h163_1 h163_2 h164 h165 h166 h167_1_3 h170_3 h171_1 h173_1 {
gen double `i'm = `i'/12  
}

egen double otrosing_nlh = rowtotal(h155_1 h160_1m h160_2m h163_1m h163_2m h164m h165m h166m h167_1_3m h170_3m h171_1m h173_1m), mi
drop  h160_1m h160_2m h163_1m h163_2m h164m h165m h166m h167_1_3m h170_3m h171_1m  h173_1m h172_1m

bys idh_ch: egen double ing_nlm = total(ynlm_ci) if miembros_ci == 1, mi
egen double ynlm_ch = rowtotal(ing_nlm otrosing_nlh remesas_ch) if miembros_ci == 1, mi


****************
*** ynlnm_ch ***
****************

/* Preguntas nivel de HOGAR:
RECIBE AYUDA EN ESPECIE DE ALGÚN FAMILIAR U OTRO HOGAR DEL PAÍS h156_1 $ Mensual */

bys idh_ch: egen double ing_nlnm = total(ynlnm_ci) if miembros_ci == 1, mi

egen double ynlnm_ch = rowtotal(ing_nlnm h156_1) if miembros_ci == 1, mi


*************
***ytot_ch***
*************
egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci == 1, mi

***************
*** ynet_ch ***
***************
gen double aux_ytransf_ch = ytransf_ch*(-1)
egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
drop aux_ytransf_ch



*47. Salario monetario de la actividad principal en horas

gen double ylmhopri_ci = ylmpri_ci/(horaspri_ci*4.2)
replace ylmhopri_ci=. if ylmhopri_ci<=0

*48. Salario monetario de todas las actividades

gen double ylmho_ci = ylm_ci/(horastot_ci*4.2)
replace ylmho_ci=. if ylmho_ci<=0


*********
*lp_ci***
*********
*https://www5.ine.gub.uy/documents/Demograf%C3%ADayEESS/HTML/ECH/Pobreza/2023/Estimaci%C3%B3n%20de%20la%20pobreza%20por%20el%20m%C3%A9todo%20del%20ingreso%20anual%202023.html

gen lp_ci =.
replace lp_ci =  18620 if mes==1 & region==1
replace lp_ci =  19006 if mes==2 & region==1
replace lp_ci =  19246 if mes==3 & region==1
replace lp_ci =  19431 if mes==4 & region==1
replace lp_ci =  19575 if mes==5 & region==1
replace lp_ci =  19561 if mes==6 & region==1
replace lp_ci =  19519 if mes==7 & region==1
replace lp_ci =  19500 if mes==8 & region==1
replace lp_ci =  19547	if mes==9 & region==1
replace lp_ci =  19641 if mes==10 & region==1
replace lp_ci =  19723 if mes==11 & region==1
replace lp_ci =  19819 if mes==12 & region==1


replace lp_ci =   12138 if mes==1 & region==2
replace lp_ci =   12484 if mes==2 & region==2
replace lp_ci =   12673 if mes==3 & region==2
replace lp_ci =   12809 if mes==4 & region==2
replace lp_ci =   12932 if mes==5 & region==2
replace lp_ci =   12926 if mes==6 & region==2
replace lp_ci =   12846 if mes==7 & region==2
replace lp_ci =   12777 if mes==8 & region==2
replace lp_ci =   12761 if mes==9 & region==2
replace lp_ci =   12829 if mes==10 & region==2
replace lp_ci =   12892 if mes==11 & region==2
replace lp_ci =   12908 if mes==12 & region==2


replace lp_ci =   8342 if mes==1 & region==3
replace lp_ci =   8504 if mes==2 & region==3
replace lp_ci =   8645 if mes==3 & region==3
replace lp_ci =   8764 if mes==4 & region==3
replace lp_ci =   8871	if mes==5 & region==3
replace lp_ci =   8860 if mes==6 & region==3
replace lp_ci =   8774	if mes==7 & region==3
replace lp_ci =   8706	if mes==8 & region==3
replace lp_ci =   8682 if mes==9 & region==3
replace lp_ci =   8748	if mes==10 & region==3
replace lp_ci =   8798	if mes==11 & region==3
replace lp_ci =   8807	if mes==12 & region==3

label var lp_ci "Linea de pobreza oficial del pais"


*********
*lpe_ci***
*********
gen lpe_ci =.
replace lpe_ci =   5013 if mes==1 & region==1
replace lpe_ci =   5105 if mes==2 & region==1
replace lpe_ci =   5193 if mes==3 & region==1
replace lpe_ci =   5315 if mes==4 & region==1
replace lpe_ci =   5411 if mes==5 & region==1
replace lpe_ci =   5368 if mes==6 & region==1
replace lpe_ci =   5313 if mes==7 & region==1
replace lpe_ci =   5278 if mes==8 & region==1
replace lpe_ci =   5245 if mes==9 & region==1
replace lpe_ci =   5292 if mes==10 & region==1
replace lpe_ci =   5290 if mes==11 & region==1
replace lpe_ci =   5310 if mes==12 & region==1

replace lpe_ci =   4661 if mes==1 & region==2
replace lpe_ci =   4755 if mes==2 & region==2
replace lpe_ci =   4863 if mes==3 & region==2
replace lpe_ci =   4977 if mes==4 & region==2
replace lpe_ci =   5074 if mes==5 & region==2
replace lpe_ci =   5060 if mes==6 & region==2
replace lpe_ci =   4981 if mes==7 & region==2
replace lpe_ci =   4912 if mes==8 & region==2
replace lpe_ci =   4867 if mes==9 & region==2
replace lpe_ci =   4911 if mes==10 & region==2
replace lpe_ci =   4919 if mes==11 & region==2
replace lpe_ci =   4915 if mes==12 & region==2

replace lpe_ci =  4188 if mes==1 & region==3
replace lpe_ci =  4276 if mes==2 & region==3
replace lpe_ci =  4383 if mes==3 & region==3
replace lpe_ci =  4491 if mes==4 & region==3
replace lpe_ci =  4582 if mes==5 & region==3
replace lpe_ci =  4567 if mes==6 & region==3
replace lpe_ci =  4493 if mes==7 & region==3
replace lpe_ci =  4428 if mes==8 & region==3
replace lpe_ci =  4385 if mes==9 & region==3
replace lpe_ci =  4429 if mes==10 & region==3
replace lpe_ci =  4438 if mes==11 & region==3
replace lpe_ci =  4434 if mes==12 & region==3

label var lpe_ci "Linea de indigencia oficial del pais"




** Variables de referencia externa

*************
**salmm_ci***
*************
*https://www.gub.uy/ministerio-trabajo-seguridad-social/comunicacion/noticias/salario-minimo-nacional-21107-desde-1o-enero
gen salmm_ci = 21107
label var salmm_ci "Salario minimo legal"


*51. Autoconsumo reportado por el individuo
*Principal: ¿Cuánto hubiera tenido que pagar por esos productos que consumió el mes pasado? g133_1
*Secundaria: DERECHO A CULTIVO PARA CONSUMO PROPIO g141_1	$	Monto que habría tenido que pagar por esos productos
/*

RETIRO DE PRODUCTOS PARA CONSUMO PROPIO (trabajador no agropecuario)	g144_1	$	Monto que habría tenido que pagar por esos bienes
RETIRO DE PRODUCTOS PARA CONSUMO PROPIO (trabajador agropecuario)	
    g144_2_1	$	Valor de lo consumido en carnes o chacinados
	g144_2_2	$	Valor de lo consumido en lácteos
	g144_2_3	$	Valor de lo consumido en huevos y aves
	g144_2_4	$	Valor de lo consumido en productos de la huerta
	g144_2_5	$	Valor consumido en otros alimentos

*/
             
egen autocons_ci = rsum(g141_1 g133_1 g144_1 g144_2_1 g144_2_2 g144_2_3 g144_2_4 g144_2_5), missing


*52. Autoconsumo del hogar

bys idh_ch: egen autocons_ch=sum(autocons_ci) if miembros_ci==1
la var autocons_ch "Autoconsumo del Hogar"



*************************************
**** VARIABLES EDUCACION ************
*************************************
*************************************
*	   AEDU_CI
*************************************	   
/*Para la suma de años educativos se generan variables temporales de maximo para niveles que son equivalentes, se imputa el maximo correspondiente a cada nivel de manera de no sobreestimar los años de educacion aprobados*/

* e51_2 = PRIMARIA COMÚN (>= 1 & < 6) --> 6 completa
* e51_3 = PRIMARIA ESPECIAL (no se considera)
* e51_4_a = EDUCACIÓN MEDIA BÁSICA - LICEO (>= 6 & <= 9)
* e51_4_b = EDUCACIÓN MEDIA BÁSICA - CETP-UTU (>= 6 & <= 9)
* e51_5 = EDUCACIÓN MEDIA SUPERIOR - LICEO (> 9 & <= 12)
* e51_6 = EDUCACIÓN MEDIA SUPERIOR - CETP-UTU (> 9 & <= 12)
* e51_8 = MAGISTERIO O PROFESORADO (> 12)
* e51_9 = UNIVERSIDAD O SIMILAR (> 12)
* e51_10 = TERCIARIO NO UNIVERSITARIO (> 12)
* e51_11 = POSGRADO (> 12)

// Convertir todas las variables a numéricas si es necesario
foreach v of varlist e51_2 e51_4_a e51_4_b e51_5 e51_6 e51_8 e51_9 e51_10 e51_11 {
    destring `v', replace force
}

// Reemplazar 9 con 0 - es inicio de ese año escolar 
foreach v of varlist e51_2 e51_4_a e51_4_b e51_5 e51_6 e51_8 e51_9 e51_10 e51_11 {
    replace `v' = 0 if `v' == 9
}	

** Se generan años aprobados para los niveles ** 	
egen mb_añostc = rowmax(e51_4_a e51_4_b) /*computa el maximo de Media Básica Liceo o tecnico (CETP-UTU)*/	
egen ms_añostc = rowmax(e51_5 e51_6) /*computa el maximo de Media Superior Liceo o tecnico (CETP-UTU)*/		
egen sup_años = rowmax(e51_8 e51_9 e51_10) /*computa el maximo de superior: magisterio, universitario o terciario no universitario */

gen años_prim = e51_2
gen años_cb_mb = mb_añostc
gen años_cb_ms = ms_añostc
gen años_sup = sup_años
gen años_post = e51_11

foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
    destring `v', replace force
}

gen aedu_ci = 0
qui foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
    replace aedu_ci = aedu_ci + `v' if !missing(`v')
}

replace aedu_ci =. if (años_prim==. & años_cb_mb==. & años_cb_ms==. & años_sup==. & años_post==.)

** eliminamos variables temporales
drop años_prim años_cb_mb años_cb_ms años_sup años_post


***************
***edupre_ci***
***************

gen edupre_ci =.
label variable edupre_ci "Tiene educacion preescolar"

****************
***asispre_ci***
****************
gen asispre_ci =0
replace asispre_ci =1 if e579==13 | e579==14
la var asispre_ci "Asiste a educacion prescolar"

** asiste_ci ** 
gen byte asiste_ci = (e49 == 3)
*89. Razones para no asistir a la escuela
* Se genera como mising porque no hay para todas las preguntas. 
* Line of code with indicator pqnoasis_ci was deleted

****************
***pqnoasis1_ci***
****************
* pqnoasis1_ci was replaced by razonesnoasis_ci, June 2025 * 

**********************
***razonesnoasis_ci***
**********************
gen  razonesnoasis_ci=.
replace razonesnoasis_ci = 1 if inlist(e202, 7, 9)
replace razonesnoasis_ci = 2 if inlist(e202, 1, 2)
replace razonesnoasis_ci = 3 if inlist(e202, 8, 10, 11)
replace razonesnoasis_ci = 4 if inlist(e202, 3, 4)
replace razonesnoasis_ci = 5 if inlist(e202, 5, 6)

label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
label value  razonesnoasis_ci razonesnoasis_ci
	
*92. Personas que asisten a centros de ensenanza públicos
gen edupub_ci = 1 if (e581 == 1 | e581a == 1) & (asiste_ci == 1)
replace edupub_ci = 0 if (e581 == 2 | e581 == 3 | e581a == 2) & (asiste_ci == 1)
replace edupub_ci =. if (asiste_ci != 1)

***************
***eduuc_ci***
***************

gen eduuc_ci = 0
replace eduuc_ci=1 if e215_1==1 | e218_1==1 | e221_1==1  


**************
***eduui_ci***
**************
gen eduui_ci = 0
replace eduui_ci=1 if e215_1==2 & (e218_1!=1 & e221_1!=1) 
replace eduui_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)
replace eduui_ci=1 if e221_1==2 & (e215_1!=1 & e218_1!=1)
 

***************
***eduac_ci****
***************
gen eduac_ci=.
replace eduac_ci=0 if e215_1==1 | e221_1==1 & (e218_1!=1)   
replace eduac_ci=0 if (e215_1==2 | e221_1==2) & (e218_1==0)  
replace eduac_ci=1 if e218_1==1 
replace eduac_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)  

***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted

		**********************************
		**** VARIABLES DE LA VIVIENDA ****
		**********************************

*93. Acceso a una fuente de agua por red
/*
d11 
1 Red general
2 Pozo surgente no protegido
3 Pozo surgente protegido
4 Aljibe
5 Arroyo, río
6 Otro
*/

gen aguared_ch = (d11 == 1)
replace aguared_ch =. if d11 ==.

*****************
*aguafconsumo_ch*
*****************

gen aguafconsumo_ch =.
replace aguafconsumo_ch = 1 if d11==1 & d12==1
replace aguafconsumo_ch = 2 if d11==1 & d12>1
replace aguafconsumo_ch = 4 if d11==3
replace aguafconsumo_ch = 6 if d11==4
replace aguafconsumo_ch = 8 if d11==5
replace aguafconsumo_ch = 9 if d11==2 
replace aguafconsumo_ch = 10 if d11==6

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.
replace aguafuente_ch = 1 if d11==1 & d12==1
replace aguafuente_ch = 2 if d11==1 & d12>1
replace aguafuente_ch = 4 if d11==3
replace aguafuente_ch = 6 if d11==4
replace aguafuente_ch = 8 if d11==5
replace aguafuente_ch = 9 if d11==2 
replace aguafuente_ch = 10 if d11==6


*94. Ubicación principal de la fuente de agua

gen aguadist_ch = d12
replace aguadist_ch=. if d12 == 4

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch = 9
*label var aguadisp1 "= 9 la encuesta no pregunta si el servicio de agua es constante"


**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9
*label var aguadisp2_ch "= 9 la encuesta no pregunta si el servicio de agua es constante"


*************
*aguamala_ch*  
*************
gen aguamala_ch= 0
replace aguamala_ch= 1 if (d11==2 | d11==5)
replace aguamala_ch= 2 if d11==6

*****************
*aguamejorada_ch*  Altered
*****************

gen aguamejorada_ch= 1 
replace aguamejorada_ch= 0 if (d11==2 |d11==5)
replace aguamejorada_ch= 2 if d11==6
*label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"


*96. El hogar usa un medidor para pagar por su consumo de agua

gen aguamide_ch=.

*97. La principal fuente de iluminación es electricidad

gen luz_ch = (d18 == 1)

*98. El hogar usa un medidor para pagar la electricidad

gen luzmide_ch=.

*99. El combustible principal usado en el hogar es gas o electricidad

gen combust_ch = 1 if (d20 == 1 | d20 == 2 | d20 == 3 | d20 == 4)
replace combust_ch = 0 if combust_ch ==.

*100. Tipo de instalaciones sanitarias

*****************
*bano_ch         *  Altered
*****************
gen bano_ch=0
replace bano_ch=1 if d16==1 
replace bano_ch=2 if d16==2 
replace bano_ch=6 if d16==4
replace bano_ch=4 if d16==3 


*101. El servicio higiénico es de uso exclusivo del hogar

gen banoex_ch = 1 if (d15 == 1)
replace banoex_ch = 0 if (d15 == 2)


*****************
*banomejorado_ch*  
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6 

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if d14>0
*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9
*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"



*102. Tipo de desagüe incluyendo la definición de unimproved del MDG

gen des1_ch =.
replace des1_ch = 0 if (d13 == 3)
replace des1_ch = 1 if (d16 == 1 | (d16 == 2 & d13 == 1))
replace des1_ch = 2 if (d16 == 2 & d13 == 2)
replace des1_ch = 3 if (d16 == 3 | d16 == 4)

*103. Tipo de desagüe sin incluir la definición de unimproved del mdg

gen des2_ch =.
replace des2_ch = 0 if (d13 == 3)
replace des2_ch = 1 if (d16 == 1 | d16 == 2) 
replace des2_ch = 2 if (d16 == 3 | d16 == 4)


*104. Materiales de construcción del piso

gen piso_ch =.
replace piso_ch = 0 if (c4 == 5)
replace piso_ch = 1 if (c4 == 1 | c4 == 2 | c4 == 3)
replace piso_ch = 2 if (c4 == 4)

*105. Materiales de construcción de las paredes

gen pared_ch =.
replace pared_ch = 0 if (c2 == 6)
replace pared_ch = 1 if (c2 < 6)

*106. Materiales de construcción del techo

gen techo_ch =.
replace techo_ch = 0 if (c3 == 6 | c3 == 5)
replace techo_ch = 1 if (c3 < 5)

*107. Método de eliminación de residuos
gen resid_ch =.



*108. Cantidad de habitaciones que se destinan exclusivamente para dormir
gen dorm_ch = d10

*109. Cantidad de habitaciones en el hogar
gen cuartos_ch = d9

*110. Si existe un cuarto separado para cocinar
gen cocina_ch =.
replace cocina_ch = 1 if (d19 == 1 | d19 == 2)
replace cocina_ch = 0 if (d19 == 3)

*111. El hogar tiene servicio telefónico fijo

gen telef_ch = (d21_17 == 1)


*112. El hogar posee heladera o refrigerador

gen refrig_ch = (d21_3 == 1)

*113. El hogar posee freezer o congelador

gen freez_ch =.

*114. El hogar posee automóvil particular

gen auto_ch = (d21_18 == 1)

*115. El hogar posee computadora

gen compu_ch = (d21_15 == 1)

*116. El hogar posee conexión a internet

gen internet_ch = (d21_16 == 1)

*117. El hogar tiene servicio telefónico celular

/*

No hicieron esta pregunta en 2021

replace e60 = 0 if (e60 == 2)
bys idh_ch: egen byte cel = sum(e60)
gen cel_ch = 1 if (cel >= 1 & cel !=.)
replace cel_ch = 0 if (cel == 0)
*/

gen cel_ch =.

*118. Tipo de vivienda en la que reside el hogar

gen vivi1_ch = 1 if (c1 == 1)
replace vivi1_ch = 2 if (c1 == 3 | c1 == 4)
replace vivi1_ch = 3 if (c1 == 2 | c1 == 5)

*119. La vivienda en la que reside el hogar es una casa o un departamento

gen vivi2_ch = 1 if (c1 != 5)
replace vivi2 = 0 if (vivi2 ==.)

*120. Propiedad de la vivienda

gen viviprop_ch =.
replace viviprop_ch = 0 if (d8_1 == 5)
replace viviprop_ch = 1 if (d8_1 == 2 | d8_1 == 4)
replace viviprop_ch = 2 if (d8_1 == 1 | d8_1 == 3)
replace viviprop_ch = 3 if (d8_1 >= 6 & d8_1 <= 9)


*121. El hogar posee un título de propiedad

gen vivitit_ch =.

*122. Alquiler mensual

gen vivialq_ch = d8_3 if (viviprop_ch == 0)

*123. Alquiler mensual imputado

gen vivialqimp_ch = d8_3 if (viviprop_ch != 0)



******************************
*** VARIABLES DE MIGRACION *** 
******************************

	*******************
	*** migrante_ci ***
	*******************
	
	gen byte migrante_ci = (e37 == 4)
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migrantiguo5 ***
	**********************
	
	gen migrantiguo5_ci = 1 if migrante_ci == 1 & e38_1>=5
	replace migrantiguo5_ci = 1 if migrante_ci == 1 & (e236==1| e236==2 |e236==3 )
	replace migrantiguo5_ci = 0 if migrante_ci == 1 & e236==4

	
	**********************
	*** miglac ***
	**********************
	** La variable e234_2 usa codigo sistema WITS 
	gen miglac_ci =0
	replace miglac_ci = 1 if inlist(e234_2, 660, 28, 32, 533, 44, 52, 84, 68, 76, 152, 170, 188, 192, 531, 212, 218, 222, 320, 254, 328, 332, 340, 136, 796, 92, 388, 484, 558, 591, 600, 604, 214, 659, 658, 534, 670, 662, 740, 780, 862)
	replace miglac_ci=. if migrante_ci==0

	
	
/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

*_____________________________________________________________________________________________________*

*  Pobres extremos, pobres moderados, vulnerables y no pobres 
* con base en ingreso neto (Sin transferencias)
* y líneas de pobreza internacionales
gen     grupo_int = 1 if (ynet_ch_pc <lp31_2011)
replace grupo_int = 2 if (ynet_ch_pc >=lp31_2011 & ynet_ch_pc <(lp31_2011*1.6))
replace grupo_int = 3 if (ynet_ch_pc >=(lp31_2011*1.6) & ynet_ch_pc <(lp31_2011*4))
replace grupo_int = 4 if (ynet_ch_pc >=(lp31_2011*4) & ynet_ch_pc <.)
tab grupo_int, gen(gpo_ingneto)

* Crear interacción entre recibirla la PTMC y el gpo de ingreso
gen ptmc_ingneto1 = 0
replace ptmc_ingneto1 = 1 if ptmc_ch == 1 & gpo_ingneto1 == 1

gen ptmc_ingneto2 = 0
replace ptmc_ingneto2 = 1 if ptmc_ch == 1 & gpo_ingneto2 == 1

gen ptmc_ingneto3 = 0
replace ptmc_ingneto3 = 1 if ptmc_ch == 1 & gpo_ingneto3 == 1

gen ptmc_ingneto4 = 0
replace ptmc_ingneto4 = 1 if ptmc_ch == 1 & gpo_ingneto4 == 1

lab def grupo_int 1 "Pobre extremo" 2 "Pobre moderado" 3 "Vulnerable" 4 "No pobre"
lab val grupo_int grupo_int

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

* Ordenar variables en el orden especificado

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch URY_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci  razonesnoasis_ci  asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded



compress

save "`base_out'", replace

log close
