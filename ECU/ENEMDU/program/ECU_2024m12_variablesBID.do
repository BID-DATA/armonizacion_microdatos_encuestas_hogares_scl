* (Versión Stata 12)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
* ________________________________________________________________________________________________________________*
 
 
global ruta = "${surveysFolder}"
global gitFolder = "${gitFolder}"

local PAIS ECU
local ENCUESTA ENEMDU
local ANO "2024"
local ronda m12 


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Ecuador
Encuesta: ENEMDU
Round: m12
Modificado por: Oscar Jaramillo (oscar.10000@hotmail.com)
Fecha última modificación: Junio 2025
*/
****************************************************************************/

use `base_in', clear


		*************************
		***VARIABLES DEL HOGAR***
		*************************
		
**************
* Region_BID *
**************
gen region_BID_c = .
replace region_BID_c = 3
label define region_BID_lbl ///
    1 "Centroamérica (CID)" ///
    2 "Caribe (CCB)" ///
    3 "Andinos (CAN)" ///
    4 "Cono Sur (CSC)"
label values region_BID_c region_BID_lbl
label variable region_BID_c "Regiones BID"

***************
***region_c ***
***************
destring ciudad, gen(_ciudad)
gen region_c = .
replace region_c = int(_ciudad / 10000)
gen canton = int(_ciudad / 100)
recode region_c (14/16 = 89) (19/22 = 89)
replace region_c = 23 if canton == 1706
replace region_c = 24 if inlist(canton, 917, 915, 926)
label define region_c_lbl ///
    1 "Azuay" ///
    2 "Bolívar" ///
    3 "Cañar" ///
    4 "Carchi" ///
    5 "Cotopaxi" ///
    6 "Chimborazo" ///
    7 "El Oro" ///
    8 "Esmeraldas" ///
    9 "Guayas" ///
    10 "Imbabura" ///
    11 "Loja" ///
    12 "Los Ríos" ///
    13 "Manabí" ///
    17 "Pichincha" ///
    18 "Tungurahua" ///
    23 "Santo Domingo de los Tsáchilas" ///
    24 "Santa Elena" ///
    89 "Amazonia" ///
    90 "zonas no delimitadas"
label values region_c region_c_lbl
drop canton _ciudad 
label variable region_c "division politico-administrativa, provincia"

*************
****pais_c***
*************
gen str3 pais_c = "ECU"
label variable pais_c "Pais"

************
***anio_c***
************
gen anio_c = 2024
label variable anio_c "Anio de la encuesta" 

***********
***mes_c***
***********
gen mes_c = 12
label var mes_c "Mes de la encuesta" 

*************
****zona_c***
*************
gen zona_c = 1 		if area == 1
replace zona_c = 0 	if area == 2
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

***************
***estrato_ci***
***************
clonevar estrato_ci = estrato
label variable estrato_ci "Estrato"

***************
***upm_ci***
***************
clonevar upm_ci = upm
label variable upm_ci "Unidad Primaria de Muestreo"

*************
****idh_ch***
*************
gen idh_ch = id_vivienda+id_hogar
label variable idh_ch "ID del hogar"

*************
****idp_ci***
*************
gen idp_ci =  id_vivienda+id_hogar+ id_persona
label variable idp_ci "ID de la persona en el hogar"

duplicates report id_vivienda id_hogar id_persona

***************
***factor_ci***
***************
gen factor_ci = fexp
label variable factor_ci "Factor de expansion del individuo"

***************
***factor_ch***
***************
gen factor_ch = fexp
label variable factor_ch "Factor de expansion del hogar"


			****************************
			***VARIABLES DEMOGRAFICAS***
			****************************

*************
***sexo_ci***
*************
gen sexo_ci = p02
label var sexo_ci "Sexo del individuo" 
label def sexo_ci 1 "Masculino" 2 "Femenino" 
label val sexo_ci sexo_ci

*************
***edad_ci***
*************
gen edad_ci = p03 if p03 < 99
label variable edad_ci "Edad del individuo"

*****************
***relacion_ci***
*****************
gen relacion_ci = 1 if p04 == 1
replace relacion_ci = 2 if p04 == 2
replace relacion_ci = 3 if p04 == 3
replace relacion_ci = 4 if inrange(p04, 4, 7)
replace relacion_ci = 5 if p04 == 9
replace relacion_ci = 6 if p04 == 8
label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci_lbl ///
    1 "Jefe/a" ///
    2 "Esposo/a" ///
    3 "Hijo/a" ///
    4 "Otros parientes" ///
    5 "Otros no parientes" ///
    6 "Empleado/a domestico/a"
label values relacion_ci relacion_ci_lbl

**************
***civil_ci***
**************
*p06: para personas de 12 años o más
gen civil_ci = 1 if p06 == 6
replace civil_ci = 2 if inlist(p06, 1, 5)
replace civil_ci = 3 if inlist(p06, 2, 3)
replace civil_ci = 4 if p06 == 4
label variable civil_ci "Estado civil"
label define civil_ci ///
    1 "Soltero" ///
    2 "Union formal o informal" ///
    3 "Divorciado o separado" ///
    4 "Viudo"
label values civil_ci civil_ci

*************
***jefe_ci***
*************
gen jefe_ci = (relacion_ci == 1)
label variable jefe_ci "Jefe de hogar"
label define jefe_ci 1 "Si" 0 "No"
label values jefe_ci jefe_ci

******************
***nconyuges_ch***
******************
by idh_ch, sort: egen nconyuges_ch = sum(relacion_ci == 2)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************
by idh_ch, sort: egen nhijos_ch = sum(relacion_ci == 3)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************
by idh_ch, sort: egen notropari_ch = sum(relacion_ci == 4)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************
by idh_ch, sort: egen notronopari_ch = sum(relacion_ci == 5)
label variable notronopari_ch "Numero de no familiares"

****************
***nempdom_ch***
****************
by idh_ch, sort: egen nempdom_ch = sum(relacion_ci == 6)
label variable nempdom_ch "Numero de empleados domesticos"

*****************
***clasehog_ch***
*****************
gen byte clasehog_ch = 0
**** unipersonal
replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
**** nuclear   (child with or without spouse but without other relatives)
replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
**** ampliado
replace clasehog_ch = 3 if ((clasehog_ch == 2 & notropari_ch > 0) & notronopari_ch == 0) | (notropari_ch > 0 & notronopari_ch == 0) 
**** compuesto  (some relatives plus non relatives)
replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
**** corresidente
replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0
label variable clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
label value clasehog_ch clasehog_ch

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci < 5)
label variable nmiembros_ch "Numero de familiares en el hogar"

*****************
***miembros_ci***
*****************
gen miembros_ci = (relacion_ci >= 1 & relacion_ci < 5)
label variable miembros_ci "Miembro del hogar"

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch = sum((miembros_ci == 1) & (edad_ci >= 21))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch = sum((miembros_ci == 1) & (edad_ci < 21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch = sum((miembros_ci == 1) & (edad_ci >= 65))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch = sum((miembros_ci == 1) & (edad_ci < 6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch = sum((miembros_ci == 1) & (edad_ci < 1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"


         ******************************
         *** VARIABLES DE DIVERSIDAD **
         ******************************
*Nathalia Maya & Antonella Pereira
*Feb 2021
*Oscar Jaramillo Jun 2025 

*************
***afro_ci***
*************
gen afro_ci = (p15 == 2 | p15 == 3)
label variable afro_ci "1 = Se autoidentifica como negro o afro"

************
***ind_ci***
************
gen ind_ci = (p15 == 1) 
label variable ind_ci "1 = Se autoidentifica como indígena"

******************
***noafroind_ci***
******************
gen noafroind_ci = (afro_ci == 0 | ind_ci == 0) 
label variable noafroind_ci "1 = No se autoidentifica como indígena o negro"

*************
***afro_ch***
*************
by idh_ch, sort: egen byte afro_ch = max(afro_ci == 1 & jefe_ci == 1) 
label variable afro_ch "1 = Hogares donde el jefe de hogar se autoidentifica como negro"

************
***ind_ch***
************
by idh_ch, sort: egen byte ind_ch = max(ind_ci == 1 & jefe_ci == 1) 
label variable ind_ch "1 = Hogares donde el jefe de hogar se autoidentifica como indígena"

******************
***noafroind_ch***
******************
by idh_ch, sort: egen byte noafroind_ch = max(noafroind_ci == 1 & jefe_ci == 1) 
label variable noafroind_ch "1 = Hogares donde el jefe de hogar no se autoidentifica como indígena o negro"

*******************
***afroind_ano_c***
*******************
gen afroind_ano_c = 2010

***************
***afroind_ci***
***************
**Pregunta: p15 (1 indígena, 2 afroecuatoriano, 3 negro, 4 mulato, 5 montuvio, 6 mestizo, 7 blanco, 8 otro) 
gen afroind_ci = . 
replace afroind_ci = 1  if p15 == 1
replace afroind_ci = 2 if p15 == 2 | p15 == 3
replace afroind_ci = 3 if p15 == 4 | p15 == 5 | p15 == 6| p15 ==7 | p15 == 8
replace afroind_ci = . if p15 == . 
replace afroind_ci = . if (p15 == . & edad_ci < 5)
label variable afroind_ci "Autoidentificación étnica"

***************
***afroind_ch***
***************
by idh_ch, sort: egen byte afroind_ch = max(afroind_ci == 1 & jefe_ci == 1) 
label variable afroind_ch "1 = Hogares donde el jefe de hogar se autoidentifica como indígena o negro"
	
	
         ********************************
         *** SITUACIÓN DE DISCAPACIDAD **
         ********************************
		 
************
***dis_ci***
************
gen dis_ci = .

**************
***disWG_ci***
**************
gen disWG_ci = .

*********************
***ECUpais_dis_ci***
*********************
gen ECUpais_dis_ci = .

************
***dis_ch***
************
gen dis_ch = . 


		***********************************
		***VARIABLES DEL MERCADO LABORAL***
		***********************************
	
***************
**condocup_ci**
***************
*al cambiar la categoria 4 a <5 toca generar nuevamente la variable condocup caso contrario el grupo 6-9 se van a inactivos
gen condocup_ci = .
replace condocup_ci = 1 if p20 == 1 | p21 < 12 | p22 == 1 
replace condocup_ci = 2 if (p20 == 2 | p21 == 12 | p22 == 2) & p32 < 11
replace condocup_ci = 3 if condocup_ci != 1 & condocup_ci != 2
replace condocup_ci = 4 if edad_ci < 15
label define condocup_ci 1 "ocupados" 2 "desocupados" 3 "inactivos" 4 "menor de PET"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion"

*******************
***categoinac_ci***
*******************
gen categoinac_ci = 1 if (p36 == 2 & condocup_ci == 3)
replace categoinac_ci = 2 if  (p36 == 3 & condocup_ci == 3)
replace categoinac_ci = 3 if  (p36 == 4 & condocup_ci == 3)
replace categoinac_ci = 4 if  ((categoinac_ci != 1 | categoinac_ci != 2 | categoinac_ci != 3) & condocup_ci == 3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"

************
***emp_ci***
************
gen emp_ci = (condocup_ci == 1)
label var emp_ci "1 = ocupados"

*************
**cesante_ci* 
*************
gen cesante_ci = (p37 == 1 & condocup_ci == 2)
label var cesante_ci "1 = Cesante, desocupado pero trabajó antes"

***************
***desemp_ci***
***************
gen desemp_ci = (condocup_ci == 2)
label var desemp_ci "Desempleado que buscó empleo en el periodo de referencia"

***************
***subemp_ci***
***************
	/*
	*la li p27
	gen subemp_ci=0
	replace subemp_ci=1 if (p27>=1 & p27<=3) & horastot_ci<=30 & emp_ci==1
	replace subemp_ci =. if emp_ci ==.
	label var subemp_ci "Personas en subempleo por horas"
	*/
	*Modificacion MGD 06/18/2014 solo horas de actividad principal y considerando dos alternativas en subempleo visible.
gen subemp_ci = (p51a <= 30 & p27 < 4 & p30 < 7)
label var subemp_ci "Personas en subempleo por horas"

****************
***durades_ci***
****************
gen durades_ci= p33 / 4.33
label variable durades_ci "Duracion del desempleo en meses"

************
***pea_ci***
************
gen pea_ci = (emp_ci == 1 | desemp_ci == 1)
label var pea_ci "Población Económicamente Activa"

*****************
***nempleos_ci***
*****************
*la li p50
gen nempleos_ci = p50
replace nempleos_ci = . if emp_ci != 1
label var nempleos_ci "Número de empleos" 
label define nempleos_ci 1 "Un empleo" 2 "Mas de un empleo"
label value nempleos_ci nempleos_ci

***************
*antiguedad_ci*
***************
* MLO: no se puede distinguir menos de 1 año (indicados como  0)
gen antiguedad_ci = p45
label var antiguedad_ci "antiguedad laboral (anios) - aproximacion"	

*****************
***desalent_ci***
*****************
gen desalent_ci = (p32 < 11 & (p34 == 6 | p34 == 7))
label var desalent_ci "Trabajadores desalentados"

*****************
***horaspri_ci***
*****************
gen horaspri_ci = p51a
replace horaspri_ci = . if p51a == 999
replace horaspri_ci = . if emp_ci == 0
label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"

*****************
***horastot_ci***
*****************
egen horastot_ci = rsum(p51a p51b p51c) if emp_ci == 1
replace horastot_ci = . if p51a == . & p51b == . & p51c == .
replace horastot_ci = . if emp_ci == 0
label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"
	
*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci = (horaspri_ci < 30 & p27 == 4 & emp_ci == 1)
replace tiempoparc_ci = . if emp_ci == 0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

******************
***categopri_ci***
******************
gen categopri_ci = .
replace categopri_ci = 1 if p42 == 5
replace categopri_ci = 2 if p42 == 6
replace categopri_ci = 3 if (p42 <= 4) | p42 == 10
replace categopri_ci = 4 if (p42 >= 7 & p42 <= 9)
replace categopri_ci = . if emp_ci == 0
label define categopri_ci 1 "Patron" 2 "Cuenta propia" 0 "Otro"
label define categopri_ci 3 "Empleado" 4 "No remunerado" , add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional"

******************
***categosec_ci***
******************
gen categosec_ci = .
replace categosec_ci = 1 if p54 == 5
replace categosec_ci = 2 if p54 == 6	
replace categosec_ci = 3 if (p54 <= 4) | p54 == 10
replace categosec_ci = 4 if (p54 >= 7 & p54 <= 9)
label define categosec_ci 1 "Patron" 2 "Cuenta propia" 0 "Otro"
label define categosec_ci 3 "Empleado" 4 "No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional en la segunda actividad"

*************
***rama_ci***
*************
gen rama_ci = .

replace rama_ci = 1 if (p40 >=  111 & p40 <=  322) & emp_ci == 1
replace rama_ci = 2 if (p40 >=  510 & p40 <=  990) & emp_ci == 1
replace rama_ci = 3 if (p40 >= 1010 & p40 <= 3320) & emp_ci == 1
replace rama_ci = 4 if (p40 >= 3510 & p40 <= 3900) & emp_ci == 1
replace rama_ci = 5 if (p40 >= 4100 & p40 <= 4390) & emp_ci == 1
replace rama_ci = 6 if ((p40 >= 4510 & p40 <= 4799) | (p40 >= 5510 & p40 <= 5630)) & emp_ci == 1
replace rama_ci = 7 if ((p40 >= 4911 & p40 <= 5320) | (p40 >= 6110 & p40 <= 6190)) & emp_ci == 1
replace rama_ci = 8 if (p40 >= 6411 & p40 <= 8299) & emp_ci == 1
replace rama_ci = 9 if ((p40 >= 5811 & p40 <= 6020) | (p40 >= 6201 & p40 <= 6399) | (p40 >= 8410 & p40 <= 9900)) & emp_ci == 1

label variable rama_ci "Rama de actividad de la ocupación principal"

label define rama_ci ///
    1 "Agricultura, caza, silvicultura y pesca" ///
    2 "Explotación de minas y canteras" ///
    3 "Industrias manufactureras" ///
    4 "Electricidad, gas y agua" ///
    5 "Construcción" ///
    6 "Comercio, restaurantes y hoteles" ///
    7 "Transporte y almacenamiento" ///
    8 "Establecimientos financieros, seguros e inmuebles" ///
    9 "Servicios sociales y comunales"

label values rama_ci rama_ci

*****************
***spublico_ci***
*****************
gen spublico_ci = (p42 == 1 & emp_ci == 1)
replace spublico_ci = . if emp_ci == .
label var spublico_ci "Personas que trabajan en el sector público"

*************
**tamemp_ci**
*************
*Ecuador Pequeña 1 a 5 Mediana 6 a 50 Grande Más de 50
*1 = menos de 100
*2 = más de 100
gen tamemp_ci = .

replace tamemp_ci = 1 if p47a == 1 & (p47b >= 1 & p47b <= 5)
replace tamemp_ci = 2 if p47a == 1 & p47b >= 6 & p47b <= 50
replace tamemp_ci = 3 if (p47a == 2) | (p47b > 50 & p47b != .)

label var tamemp_ci "# empleados en la empresa segun rangos"
label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci

****************
*cotizando_ci***
****************
*Modficación SGR 15 de julio de 2018. Desde la encuesta 2017 existe una pregunta a los de 15 años y más. 
/*gen cotizando_ci=0     if condocup_ci==1 | condocup_ci==2 
replace cotizando_ci=1 if (p44f==1)  & cotizando_ci==0 /*solo a emplead@s y asalariad@s, difiere con los otros paises*/
replace cotizando_ci=1 if (p44f==1)  & p61b1<=4  & cotizando_ci==0
label var cotizando_ci "Cotizante a la Seguridad Social"
*/
gen cotizando_ci = (p44f == 1 | p61b1 <= 4) 
label var cotizando_ci "Cotizante a la Seguridad Social"

********************
*** instcot_ci *****
********************
gen instcot_ci = "IESS" if p61b1 < 2
replace instcot_ci = "Seguro campesino" if p61b1 == 3
replace instcot_ci = "ISSFA o ISSPOL" if p61b1 == 4
label var instcot_ci "Institución a la cual cotiza"

****************
***afiliado_ci**
****************
gen afiliado_ci = (p05a <= 4) /*IESS, ISSFA e ISSPOL requieren afiliación*/
label var afiliado_ci "Afiliado a la Seguridad Social"
*Nota: seguridad social comprende solo los que en el futuro me ofrecen una pension.

***************
***formal_ci***
***************
gen formal_ci = (cotizando_ci == 1 | afiliado_ci == 1)
label var formal_ci "1=afiliado o cotizante, formal"

*****************
*tipocontrato_ci*
*****************
gen tipocontrato_ci = . /* Solo disponible para asalariados*/
replace tipocontrato_ci = 1 if (p43 == 1 | p43 == 2) & categopri_ci == 3
replace tipocontrato_ci = 2 if (p43 == 3) & categopri_ci == 3
replace tipocontrato_ci = 3 if (p43 >= 4 & p43 <= 6) & categopri_ci == 3
label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
	
**************
***ocupa_ci***
**************
* Modificacion MGD 07/29/2014: se utiliza CIUO-08.
generat ocupa_ci = .

replace ocupa_ci = 1 if (p41 >= 2111 & p41 <= 3522) & emp_ci == 1
replace ocupa_ci = 2 if (p41 >= 1111 & p41 <= 1439) & emp_ci == 1
replace ocupa_ci = 3 if (p41 >= 4110 & p41 <= 4419) & emp_ci == 1
replace ocupa_ci = 4 if ((p41 >= 5211 & p41 <= 5249) | (p41 >= 9510 & p41 <= 9520)) & emp_ci == 1
replace ocupa_ci = 5 if ((p41 >= 5110 & p41 <= 5169) | (p41 >= 5311 & p41 <= 5419) | (p41 >= 9111 & p41 <= 9129) | (p41 >= 9610 & p41 <= 9624)) & emp_ci == 1
replace ocupa_ci = 6 if ((p41 >= 6110 & p41 <= 6340) | (p41 >= 9210 & p41 <= 9216)) & emp_ci == 1
replace ocupa_ci = 7 if ((p41 >= 7111 & p41 <= 8350) | (p41 >= 9310 & p41 <= 9412)) & emp_ci == 1
replace ocupa_ci = 8 if (p41 >= 110 & p41 <= 310) & emp_ci == 1
replace ocupa_ci = 9 if p41 >= 9629 & p41 != . & emp_ci == 1

label define ocupa_ci 1 "profesional y tecnico" 2 "director o funcionario sup" 3 "administrativo y nivel intermedio"
label define ocupa_ci 4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci 7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci 8 "FFAA" 9 "Otras ", add

label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral"

*************
**pension_ci*
*************
gen pension_ci = (p72a == 1) /* A todas las per mayores de cinco*/
replace pension_ci = . if p72a == .
label var pension_ci "1=Recibe pension contributiva"

***************
*pensionsub_ci*
***************
gen pensionsub_ci = (p75 == 1)
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

************
*tipopen_ci*
************
gen tipopen_ci = .
label var tipopen_ci "Tipo de pensión que recibe - variable original de cada país"

**************
**instpen_ci**
**************
gen instpen_ci = .
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 



		**************************
		***VARIABLES DE INGRESO***
		**************************
    
***************
***ylmpri_ci***
***************
tab p65
gen p65b = p65*-1
egen ylmpri_ci = rsum(p63 p64b p65b p66 p67) , m
replace ylmpri_ci = . if p63 == . & p64b == . & p65b == . & p66 == . & p67 == .
replace ylmpri_ci = . if ylmpri_ci >= 999999
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 

****************
***ylnmpri_ci***
****************
gen ylnmpri_ci = p68b
replace ylnmpri_ci = . if ylnmpri_ci >= 999999
label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal"   

***************
***ylmsec_ci***
***************
gen ylmsec_ci = p69 
replace ylmsec_ci = . if ylmsec_ci >= 999999
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 

****************
***ylnmsec_ci***
****************
gen ylnmsec_ci = p70b
replace ylnmsec_ci = . if ylnmsec_ci >= 999999 
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

*****************
***ylmotros_ci***
*****************
gen ylmotros_ci = .
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

******************
***ylnmotros_ci***
******************
gen ylnmotros_ci = .
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

************
***ylm_ci***
************
egen ylm_ci = rsum(ylmpri_ci ylmsec_ci), m
replace ylm_ci = . if ylmpri_ci == . &  ylmsec_ci == .
label var ylm_ci "Ingreso laboral monetario total"  

*************
***ylnm_ci***
*************
egen ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci), m
replace ylnm_ci = . if ylnmpri_ci == . &  ylnmsec_ci == .
label var ylnm_ci "Ingreso laboral NO monetario total" 
	
*********************
***ynlm_publico_ci***
*********************
egen ynlm_publico_ci = rsum(p76 p78), m  // bono de desarrollo humano y bono de discapacidad
label var ynlm_publico_ci "Ingreso no laboral público"

*************
***ynlm_ci***
*************
* MGR: agrego ingreso recibido por Bono de Discapacidad Joaquín Gallegos Lara
egen ynlm_ci = rsum(p71b p72b p73b p74b p76 p78), m
replace ynlm_ci = . if p71b == . & p72b == . & p73b == . & p74b == . & p76 == . & p78 == .
replace ynlm_ci = . if ynlm_ci >= 999999
label var ynlm_ci "Ingreso no laboral monetario"  

*********************
***ynlm_privado_ci***
*********************
gen ynlm_privado_ci = ynlm_ci - ynlm_publico_ci
label var ynlm_privado_ci "Ingreso no laboral público"

**************
***ynlnm_ci***
**************
gen ynlnm_ci = .
label var ynlnm_ci "Ingreso no laboral no monetario" 

*************
***ytot_ci***
*************
egen ytot_ci = rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), m
label var ytot_ci "Ingreso total del individuo"

************
***ylm_ch***
************
by idh_ch, sort: egen ylm_ch = sum(ylm_ci) if miembros_ci == 1
label var ylm_ch "Ingreso laboral monetario del hogar"

*************
***ylnm_ch***
*************
by idh_ch, sort: egen ylnm_ch = sum(ylnm_ci) if miembros_ci == 1
label var ylnm_ch "Ingreso laboral no monetario del hogar"

**************
***ynlnm_ch***
**************
gen ynlnm_ch = .
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

*********************
***ynlm_publico_ch***
*********************
by idh_ch, sort: egen ynlm_publico_ch = sum(ynlm_publico_ci) if miembros_ci == 1
label var ynlm_publico_ch "Ingreso no laboral monetario público del hogar"

*********************
***ynlm_privado_ch***
*********************
by idh_ch, sort: egen ynlm_privado_ch = sum(ynlm_privado_ci) if miembros_ci == 1
label var ynlm_privado_ch "Ingreso no laboral monetario privado del hogar"

*************
***ynlm_ch***
*************
by idh_ch, sort: egen ynlm_ch = sum(ynlm_ci) if miembros_ci==1
label var ynlm_ch "Ingreso no laboral monetario del hogar"

*************
***ytot_ch***
*************
by idh_ch, sort: egen ytot_ch = sum(ytot_ci) if miembros_ci==1
label var ytot_ch "Ingreso no laboral monetario del hogar"

*****************
***ylmhopri_ci***
*****************
gen ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
replace ylmhopri_ci = . if ylmhopri_ci <= 0
label var ylmhopri_ci "Salario monetario de la actividad principal" 

**************
***ylmho_ci***
**************
gen ylmho_ci = ylm_ci / (horastot_ci * 4.3)
label var ylmho_ci "Salario monetario de todas las actividades" 

*****************
***nrylmpri_ci***
*****************
gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"

*****************
***nrylmpri_ch***
*****************
by idh_ch, sort: egen nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
replace nrylmpri_ch = . if nrylmpri_ch == .
label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

**************
***ylmnr_ch***
**************
by idh_ch, sort: egen ylmnr_ch = sum(ylm_ci) if miembros_ci == 1
replace ylmnr_ch = . if nrylmpri_ch == 1
label var ylmnr_ch "Ingreso laboral monetario del hogar"

****************
***remesas_ci***
****************
gen remesas_ci = p74b
replace remesas_ci = . if p74b >= 999999
label var remesas_ci "Remesas mensuales reportadas por el individuo" 

****************
***remesas_ch***
****************
by idh_ch, sort: egen remesas_ch = sum(remesas_ci) if miembros_ci == 1
label var remesas_ch "Remesas mensuales del hogar"	
	
*************
***ypen_ci***
*************
gen ypen_ci = p72b if pension_ci == 1
replace ypen_ci = . if ypen_ci == 999999 
label var ypen_ci "Valor de la pension contributiva"

****************
***ypensub_ci***
****************
gen ypensub_ci = p76 if pensionsub_ci == 1
replace ypensub_ci = . if ypensub_ci == 999999
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

			
			****************************
			***VARIABLES DE EDUCACION***
			****************************

*************
***aedu_ci***
*************
gen aedu_ci = .

replace aedu_ci = 0 if p10a == 1 | p10a == 2 | p10a == 3
replace aedu_ci = p10b if p10a == 4 // Años primaria
replace aedu_ci = p10b - 1 if p10a ==5 // Años educacion básica 1 a 10 nuevos sistema - se resta uno porque considera un año de educacion inicial  
replace aedu_ci = 0 if p10a == 5 & aedu_ci == -1 // para que no queden en -1 los de 0 años aprobados 
replace aedu_ci = p10b + 6  if p10a == 6 // secundaria
replace aedu_ci = p10b + 9  if p10a == 7 // bachillerato
replace aedu_ci = p10b + 12 if p10a == 8 | p10a == 9 //superior
replace aedu_ci = p10b + 16 if p10a == 10 // posgrado

label var aedu_ci "Anios de educacion aprobados"

***************
***edupre_ci***
***************
gen edupre_ci = .
label variable edupre_ci "Educacion preescolar"

**************
***eduui_ci***
**************
gen eduui_ci = (p12a == 2 & p10a == 9) | (p12a == 2 & p10a == 8)
replace eduui_ci = . if aedu_ci == . 
label variable eduui_ci "Superior incompleto"

***************
***eduuc_ci***
***************
gen byte eduuc_ci = (p12a == 1 & p10a == 9) | (p12a == 1 & p10a == 8) | (p10a == 10)	
replace eduuc_ci = . if aedu_ci == . 
label variable eduuc_ci "Superior completo"

**************
***eduac_ci***
**************
gen eduac_ci = .	
replace eduac_ci = 1 if p10a == 9 | p10a == 10 
replace eduac_ci = 0 if p10a == 8
label variable eduac_ci "Superior universitario vs superior no universitario"

***************
***asiste_ci***
***************
gen asiste_ci = (p07 == 1)
replace asiste_ci = . if p07 == .
label variable asiste_ci "Asiste actualmente a la escuela"

***************
***edupub_ci***
***************
gen edupub_ci = .
label var edupub_ci "Asiste a un centro de ensenanza público"

***************
***asispre_ci**
***************
* No viene la preguntá pe01 en la base 2018, 2019, 2020
gen asispre_ci = .
la var asispre_ci "Asiste a educacion prescolar"

**************
*pqnoasis1_ci*
**************
gen pqnoasis1_ci = 1 if p09 == 3
replace pqnoasis1_ci = 2 if p09 == 5
replace pqnoasis1_ci = 3 if p09 == 7 | p09 == 9
replace pqnoasis1_ci = 4 if p09 == 11
replace pqnoasis1_ci = 5 if p09 == 8 | p09 == 12 | p09 == 15
replace pqnoasis1_ci = 6 if p09 == 2
replace pqnoasis1_ci = 7 if p09 == 1
replace pqnoasis1_ci = 8 if p09 == 10 | p09 == 13
replace pqnoasis1_ci = 9 if p09 == 4 | p09 == 6 | p09 == 14 | p09 == 16 | p09 == 17

label define pqnoasis1_ci ///
    1 "Problemas económicos" ///
    2 "Por trabajo" ///
    3 "Problemas familiares o de salud" ///
    4 "Falta de interés" ///
    5 "Quehaceres domésticos/embarazo/cuidado de niños/as" ///
    6 "Terminó sus estudios" ///
    7 "Edad" ///
    8 "Problemas de acceso" ///
    9 "Otros"

label value pqnoasis1_ci pqnoasis1_ci



	**********************************
	**** VARIABLES DE LA VIVIENDA ****
	**********************************

************
***luz_ch***
************
gen luz_ch = (vi12 == 1 | vi12 == 2)
label var luz_ch  "La principal fuente de iluminación es electricidad"
	
****************
***luzmide_ch***
****************
gen luzmide_ch = .
label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

****************
***combust_ch***
****************
gen combust_ch = 0
replace combust_ch = 1 if  vi08 == 1 | vi08 == 3 
label var combust_ch "Principal combustible gas o electricidad"  

*************
***piso_ch***
*************
gen piso_ch = 0 	if vi04a == 7

replace piso_ch = 1	if vi04a == 1 |vi04a == 2 | vi04a == 3 | vi04a == 4 
replace piso_ch = 2 if vi04a == 5 | vi04a == 6 | vi04a == 8 	
replace piso_ch = . if vi04a == .

label var piso_ch "Materiales de construcción del piso"  
label def piso_ch 0"Piso de tierra" 1"Materiales permanentes" 2"Otros materiales"
label val piso_ch piso_ch
		
**************
***pared_ch***
**************
gen pared_ch = 0 if vi05a == 5 | vi05a == 6 | vi05a == 7
replace pared_ch = 1 if vi05a >= 1 & vi05a <= 4

label var pared_ch "Materiales de construcción de las paredes"
label define pared_ch 0 "No permanentes" 1 "Permanentes"
label value pared_ch pared_ch

**************
***techo_ch***
**************
gen techo_ch = 0 if vi03a == 5 | vi03a == 6
replace techo_ch = 1 if vi03a >= 1 & vi03a <= 4

label var techo_ch "Materiales de construcción del techo"
label define techo_ch 0 "No permanentes" 1 "Permanentes"
label value techo_ch techo_ch

**************
***resid_ch***
**************
gen resid_ch = 0 if vi13 == 1 | vi13 == 2
replace resid_ch = 1 if vi13 == 4
replace resid_ch = 2 if vi13 == 3
replace resid_ch = 3 if vi13 == 5
replace resid_ch = . if vi13 == .

label var resid_ch "Método de eliminación de residuos"
label define resid_ch 0 "Recolección pública o privada" 1 "Quemados o enterrados"
label define resid_ch 2 "Tirados a un espacio abierto" 3 "Otros", add
label value resid_ch resid_ch

*************
***dorm_ch***
*************
*Dado que hay hogares que reportan 0 habitaciones exclusivas para dormir, pues la vivienda está constituída por
*un sólo ambiente, a estos hogares se les imputa 1 habitación. A los hogares que dicen no tener cuartos exclusivos 
*para dormir, pero que viven en viviendas de 2 o más habitaciones se les asigna missing
gen dorm_ch = vi07
replace dorm_ch = 1 if vi07 == 0 & vi06 == 1
replace dorm_ch = . if vi07 == 0 & vi06 > 1
label var dorm_ch "Habitaciones para dormir"
	
****************
***cuartos_ch***
****************
gen cuartos_ch = vi06 if vi06 < 99
label var cuartos_ch "Habitaciones en el hogar"
		
***************
***cocina_ch***
***************
*Modificado por SGR 2019.
gen cocina_ch = 1 if vi07b == 1
replace cocina_ch = 0 if vi07b == 2
label var cocina_ch "Cuarto separado y exclusivo para cocinar"

**************
***telef_ch***
**************
gen telef_ch = .
label var telef_ch "El hogar tiene servicio telefónico fijo"
	
***************
***refrig_ch***
***************
gen refrig_ch = .
label var refrig_ch "El hogar posee refrigerador o heladera"
		
**************
***freez_ch***
**************
gen freez_ch = .
label var freez_ch "El hogar posee congelador"

*************
***auto_ch***
*************
gen auto_ch = .
label var auto_ch "El hogar posee automovil particular"

**************
***compu_ch***
**************
gen compu_ch = .
label var compu_ch "El hogar posee computador"
	
*****************
***internet_ch***
*****************
gen internet_ch = .
label var internet_ch "El hogar posee conexión a Internet"

************
***cel_ch***
************
gen cel_ch = .
label var cel_ch "El hogar tiene servicio telefonico celular"
	
**************
***vivi1_ch***
**************
gen vivi1_ch = 1 if vi02 == 1
replace vivi1_ch = 2 if vi02 == 2
replace vivi1_ch = 3 if vi02 >= 3 & vi02 <= 7
replace vivi1_ch = . if vi02 == .

label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
label define vivi1_ch 1 "Casa" 2 "Departamento" 3 "Otros"
label value vivi1_ch vivi1_ch

		
**************
***vivi2_ch***
**************
gen vivi2_ch = 0
replace vivi2_ch = 1 if vi02 == 1 | vi02 == 2
replace vivi2_ch = . if vi02 == .

label var vivi2_ch "La vivienda es casa o departamento"

*****************
***viviprop_ch***
*****************
gen viviprop_ch = .

replace viviprop_ch = 0 if vi14 == 1 | vi14 == 2
replace viviprop_ch = 1 if vi14 == 4
replace viviprop_ch = 2 if vi14 == 3
replace viviprop_ch = 3 if vi14 >= 5 & vi14 < .

label var viviprop_ch "Propiedad de la vivienda"
label define viviprop_ch 0 "Alquilada" 1 "Propia y totalmente pagada" 2 "Propia y en proceso de pago"
label define viviprop_ch 3 "Ocupada (propia de facto)", add
label value viviprop_ch viviprop_ch
	
****************
***vivitit_ch***
****************
gen vivitit_ch = .
label var vivitit_ch "El hogar posee un título de propiedad"

****************
***vivialq_ch***
****************
gen vivialq_ch = .
label var vivialq_ch "Alquiler mensual"

*******************
***vivialqimp_ch***
*******************
gen vivialqimp_ch = .
label var vivialqimp_ch "Alquiler mensual imputado"



	***************************
	**** VARIABLES DE WASH ****
	***************************

****************
***aguared_ch***
****************
gen aguared_ch = (vi10 == 1)
replace aguared_ch = . if vi10 == .
label var aguared_ch "Acceso a fuente de agua por red"

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0
label var aguafconsumo_ch "Principal fuente de agua para beber"

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch = 0
replace aguafuente_ch = 1 if vi10 == 1
replace aguafuente_ch = 2 if vi10 == 2
replace aguafuente_ch = 6 if vi10 == 4
replace aguafuente_ch = 8 if vi10 == 6
replace aguafuente_ch = 10 if (vi10 == 3 | vi10 == 5 | vi10 == 7)
label var aguafuente_ch "Principal fuente de agua del hogar para todos los usos"

*************
*aguadist_ch*
*************
gen aguadist_ch = 0
replace aguadist_ch = 1 if vi10a == 1
replace aguadist_ch = 2 if vi10a == 2
replace aguadist_ch = 3 if vi10a == 3
label var aguadist_ch "Ubicación de la principal fuente de agua"

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch = 9
label var aguadisp1_ch "Continuidad de disponibilidad de agua suficiente"

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9
label var aguadisp2_ch "Continuidad de disponibilidad de agua suficiente en días"

*************
*aguatrat_ch*
*************
gen aguatrat_ch = .
label var aguatrat_ch "=1 El agua es tratada antes de su uso"

*************
*aguamala_ch*
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch <= 7 
replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10
label var aguamala_ch "=1 La principal fuente de agua no es mejorada"

*****************
*aguamejorada_ch*
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
replace aguamejorada_ch = 1 if aguafuente_ch <= 7 
label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"

*****************
***aguamide_ch***
*****************
gen aguamide_ch = .
replace aguamide_ch = 1 if vi101 == 1 | vi10 == 1
replace aguamide_ch = 0 if vi101 == 2 | (vi101 != 1 &  vi10 != 1)
label var aguamide_ch "Usan medidor para pagar consumo de agua"

*************
***bano_ch***
*************
gen bano_ch = 6
replace bano_ch = 0 if vi09 == 5 & vi09a != 1
replace bano_ch = 1 if vi09 == 1
replace bano_ch = 2 if vi09 == 2
replace bano_ch = 3 if vi09 == 3
replace bano_ch = 4 if vi09 == 5 & vi09a == 1
replace bano_ch = 6 if vi09 == 4

label var bano_ch "Tipo de instalación sanitaria"

***************
***banoex_ch***
***************
gen banoex_ch = 9
label var banoex_ch "El servicio sanitario es exclusivo del hogar"

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if vi09! = 5 | vi09a == 1
replace sinbano_ch = 1 if vi09a == 3
replace sinbano_ch = 2 if vi09a == 2
label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

*****************
*banomejorado_ch*
*****************
gen banomejorado_ch = 2
replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6
label var banomejorado_ch "Indica si las instalaciones sanitarias son mejoradas"



	*****************************
	**** VARIABLES MIGRACIÓN ****
	*****************************
	
*******************
*** migrante_ci ***
*******************
gen migrante_ci = (p15aa == 3)
label var migrante_ci "=1 si es migrante"
	
**********************
*** migantiguo5_ci ***
**********************
gen migrantiguo5_ci = .
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
**********************
*** miglac_ci ***
**********************
gen miglac_ci = (inlist(p15ab, 32, 44, 52, 68, 76, 84, 152, 170, 188, 214, 222, 320, 328, 332, 340, 388, 484, 558, 591, 600, 604, 740, 780, 858, 862) & migrante_ci == 1) if migrante_ci != .
replace miglac_ci = 0 if !inlist(p15ab, 32, 44, 52, 68, 76, 84, 152, 170, 188, 214, 222, 320, 328, 332, 340, 388, 484, 558, 591, 600, 604, 740, 780, 858, 862) & migrante_ci == 1
replace miglac_ci = . if migrante_ci == 0

label var miglac_ci "=1 si es migrante proveniente de un pais LAC"


		**********************************
		* VARIABLES DE PROTECCIÓN SOCIAL *
		**********************************

************************
*** nmiembros_sph_ch ***
************************
bys idh_ch: gen nmiembros_sph_ch = _N 
label var nmiembros_sph_ch "Número total de personas en el hogar"

*******************
*** yneto_pc_ch ***
*******************
gen double yneto_pc_ch = (ytot_ch - ynlm_publico_ci) / nmiembros_sph_ch
label var yneto_pc_ch "Ingreso del hogar neto mensualizado de transferencias públicas per cápita"

********************
*** bene_cash_ch ***
********************
egen bene_cash_ch = max(p75 == 1 | p77 == 1), by(idh_ch)
label var bene_cash_ch "Indica si alguna persona en el hogar es beneficiaria de alguna transferencia pública"

*********************
*** pensionsub_ch ***
*********************
egen pensionsub_ch = max(pensionsub_ci), by(idh_ch)
label var pensionsub_ch "Indica si alguna persona en el hogar es beneficiaria de alguna transferencia pública"


		***********************************
		* VARIABLES DE REFERENCIA EXTERNA *
		***********************************

*************
**salmm_ci***
*************
*  Acuerdo ministerial MDT-2024-300, el Ministerio de Trabajo
gen salmm_ci = 470
label var salmm_ci "Salario minimo legal"

***********
***lp_ci***
***********
* https://www.ecuadorencifras.gob.ec/documentos/web-inec/POBREZA/2024/Diciembre/202412_Boletin_pobreza.pdf
gen lp_ci = 91.43
label var lp_ci "Linea de pobreza oficial del pais"

*************
***lpe_ci ***
*************
* https://www.ecuadorencifras.gob.ec/documentos/web-inec/POBREZA/2024/Diciembre/202412_Boletin_pobreza.pdf
gen lpe_ci = 51.53
label var lpe_ci "Linea de indigencia oficial del pais"


/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/

do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

*_____________________________________________________________________________________________________*


/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

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



/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/
*rename p41 codocupa
*rename p40 codindustria

compress

save "`base_out'", replace

log close

