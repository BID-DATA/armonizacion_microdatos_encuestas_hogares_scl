* (Versión Stata 19)
clear
set more off

*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.`'
 *________________________________________________________________________________________________________________*
 

global ruta = "${surveysFolder}"

local PAIS     ARG
local ENCUESTA EPHC
local ANO      "2025"
local ronda    s2

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: ARG
Encuesta: EPHC
Round: s2
Autores: Matías Isla y Matias Rodriguez (SCL/SCL)
Version: 10/08/2026
Mail: matiasi@iadb.org/mrodriguezm@iadb.org, 10 de agosto de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

	********************
	*** region_BID_c ***
	********************
	gen byte region_BID_c = 4

	****************
	*** region_c ***
	****************
	gen byte region_c = .
	replace region_c = 1 if (aglomerado>=2 & aglomerado<=3) | (aglomerado>=33 & aglomerado<=34) | aglomerado==38 /* Buenos Aires */
	replace region_c = 2 if aglomerado==22 /* Catamarca */
	replace region_c = 3 if aglomerado==8 /* Chaco */
	replace region_c = 4 if aglomerado==9  | aglomerado==91 /* Chubut */
	replace region_c = 5 if aglomerado==32 /* Ciudad de Buenos Aires */
	replace region_c = 6 if aglomerado==13 | aglomerado==36 /* Córdoba */
	replace region_c = 7 if aglomerado==12 /* Corrientes */
	replace region_c = 8 if aglomerado==6  | aglomerado==14 /* Entre Ríos */
	replace region_c = 9 if aglomerado==15 /* Formosa */
	replace region_c = 10 if aglomerado==19 /* Jujuy */
	replace region_c = 11 if aglomerado==30 /* La Pampa */
	replace region_c = 12 if aglomerado==25 /* La Rioja */
	replace region_c = 13 if aglomerado==10 /* Mendoza */
	replace region_c = 14 if aglomerado==7 /* Misiones */
	replace region_c = 15 if aglomerado==17 /* Neuquén */
	replace region_c = 16 if aglomerado==93 /* Río Negro */
	replace region_c = 17 if aglomerado==23 /* Salta */
	replace region_c = 18 if aglomerado==27 /* San Juan */
	replace region_c = 19 if aglomerado==26 /* San Luis */
	replace region_c = 20 if aglomerado==20 /* Santa Cruz */
	replace region_c = 21 if aglomerado>=4 & aglomerado<=5 /* Santa Fe */
	replace region_c = 22 if aglomerado==18 /* Santiago del Estero */
	replace region_c = 23 if aglomerado==31 /* Tierra del Fuego */
	replace region_c = 24 if aglomerado==29 /* Tucumán */

	*************
	*** ine01 ***
	*************
	gen int ine01 = .
	replace ine01 = 6  if (aglomerado>=2 & aglomerado<=3) | (aglomerado>=33 & aglomerado<=34) | aglomerado==38
	replace ine01 = 10 if aglomerado==22
	replace ine01 = 22 if aglomerado==8
	replace ine01 = 26 if aglomerado==9  | aglomerado==91
	replace ine01 = 2  if aglomerado==32
	replace ine01 = 14 if aglomerado==13 | aglomerado==36
	replace ine01 = 18 if aglomerado==12
	replace ine01 = 30 if aglomerado==6  | aglomerado==14
	replace ine01 = 34 if aglomerado==15
	replace ine01 = 38 if aglomerado==19
	replace ine01 = 42 if aglomerado==30
	replace ine01 = 46 if aglomerado==25
	replace ine01 = 50 if aglomerado==10
	replace ine01 = 54 if aglomerado==7
	replace ine01 = 58 if aglomerado==17
	replace ine01 = 62 if aglomerado==93
	replace ine01 = 66 if aglomerado==23
	replace ine01 = 70 if aglomerado==27
	replace ine01 = 74 if aglomerado==26
	replace ine01 = 78 if aglomerado==20
	replace ine01 = 82 if aglomerado>=4 & aglomerado<=5
	replace ine01 = 86 if aglomerado==18
	replace ine01 = 94 if aglomerado==31
	replace ine01 = 90 if aglomerado==29

	**************
	*** pais_c ***
	**************
	gen str3 pais_c = "ARG"

	**************
	*** anio_c ***
	**************
	gen int anio_c = 2025

	******************
	*** semestre_c ***
	******************
	gen byte semestre_c = 2

	*************
	*** mes_c ***
	*************
	gen int mes_c = .

	**************
	*** zona_c ***
	**************
	gen byte zona_c = 1

	******************
	*** estrato_ci ***
	******************
	gen estrato_ci = .

	**************
	*** upm_ci ***
	**************
	gen upm_ci = aglomerado

	**************
	*** idh_ch ***
	**************
	sort codusu aglomerado nro_hogar trimestre
	egen idh_ch = group(codusu aglomerado nro_hogar trimestre)
	tostring idh_ch, replace

	**************
	*** idp_ci ***
	**************
	gen idp_ci = componente
	tostring idp_ci, replace

	*****************
	*** factor_ci ***
	*****************
	gen factor_ci = pondera

	*****************
	*** factor_ch ***
	*****************
	gen factor_ch = pondera


****************************
***VARIABLES DEMOGRAFICAS***
****************************

	***************
	*** sexo_ci ***
	***************
	gen byte sexo_ci = ch04
	replace sexo_ci = . if !inlist(ch04, 1, 2)

	***************
	*** edad_ci ***
	***************
	gen int edad_ci = ch06
	replace edad_ci = 0  if ch06 == -1
	replace edad_ci = 98 if edad_ci >= 98 & edad_ci != .

	*******************
	*** relacion_ci ***
	*******************
	/* ch03: 1=Jefe, 2=Cónyuge, 3=Hijo, 4-9=Otros parientes, 10=No parientes */
	gen byte relacion_ci = .
	replace relacion_ci = 1 if ch03 == 1
	replace relacion_ci = 2 if ch03 == 2
	replace relacion_ci = 3 if ch03 == 3
	replace relacion_ci = 4 if ch03 >= 4 & ch03 <= 9
	replace relacion_ci = 5 if ch03 == 10

	*******************
	*** miembros_ci ***
	*******************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	***********************
	*** miembros_one_ci ***
	***********************
	gen byte miembros_one_ci = inrange(ch03, 1, 10)

	****************
	*** civil_ci ***
	****************
	/* ch07: 1=Unido, 2=Casado, 3=Separado/divorciado, 4=Viudo, 5=Soltero */
	gen byte civil_ci = .
	replace civil_ci = 1 if ch07 == 5
	replace civil_ci = 2 if inlist(ch07, 1, 2)
	replace civil_ci = 3 if ch07 == 3
	replace civil_ci = 4 if ch07 == 4

	***************
	*** jefe_ci ***
	***************
	gen byte jefe_ci = (relacion_ci == 1)
	replace jefe_ci = . if relacion_ci == .

	********************
	*** nconyuges_ch ***
	********************
	by idh_ch, sort: egen byte nconyuges_ch = sum(relacion_ci == 2)

	*****************
	*** nhijos_ch ***
	*****************
	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)

	********************
	*** notropari_ch ***
	********************
	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)

	**********************
	*** notronopari_ch ***
	**********************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)

	******************
	*** nempdom_ch ***
	******************
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)

	*******************
	*** clasehog_ch ***
	*******************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

	********************
	*** nmiembros_ch ***
	********************
	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci <= 5)
	replace nmiembros_ch = . if relacion_ci == .

	*******************
	*** nmayor21_ch ***
	*******************
	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))

	*******************
	*** nmenor21_ch ***
	*******************
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))

	*******************
	*** nmayor65_ch ***
	*******************
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))

	******************
	*** nmenor6_ch ***
	******************
	by idh_ch, sort: egen byte nmenor6_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))

	******************
	*** nmenor1_ch ***
	******************
	by idh_ch, sort: egen byte nmenor1_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	***************
	*** afro_ci ***
	***************
	/* La EPH no pregunta autoidentificación étnico-racial */
	gen byte afro_ci = .

	**************
	*** ind_ci ***
	**************
	gen byte ind_ci = .

	********************
	*** noafroind_ci ***
	********************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if (afro_ci == 0 | ind_ci == 0)
	replace noafroind_ci = 0 if (afro_ci == 1 | ind_ci == 1)
	replace noafroind_ci = . if (afro_ci == . & ind_ci == .)

	*********************
	*** afroind_ano_c ***
	*********************
	gen byte afroind_ano_c = .

	******************
	*** afroind_ci ***
	******************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	***************
	*** afro_ch ***
	***************
	gen byte afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	**************
	*** ind_ch ***
	**************
	gen byte ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	********************
	*** noafroind_ch ***
	********************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	******************
	*** afroind_ch ***
	******************
	gen byte afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	**************
	*** dis_ci ***
	**************
	/* La EPH no incluye el módulo Washington Group ni pregunta simple de
	   discapacidad */
	gen byte dis_ci = .

	****************
	*** disWG_ci ***
	****************
	gen byte disWG_ci = .

	**************
	*** dis_ch ***
	**************
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	******************
	*** ARG_dis_ci ***
	******************
	gen byte ARG_dis_ci = dis_ci


***********************************
***VARIABLES DEL MERCADO LABORAL***
***********************************

	*******************
	*** condocup_ci ***
	*******************
	/* estado: 0=Entrevista individual no realizada, 1=Ocupado, 2=Desocupado,
	   3=Inactivo, 4=Menor de 10 años. La PET de la EPH arranca en 10 años y los
	   trabajadores familiares sin remuneración se clasifican como ocupados */
	gen byte condocup_ci = .
	replace condocup_ci = 1 if estado == 1
	replace condocup_ci = 2 if estado == 2
	replace condocup_ci = 3 if estado == 3 & edad_ci >= 10 & edad_ci != .
	replace condocup_ci = 4 if estado == 4
	replace condocup_ci = . if estado == 0

	**********************
	*** categoinac_ci ***
	**********************
	/* cat_inac: 1=Jubilado/pensionado, 2=Rentista, 3=Estudiante, 4=Ama de casa,
	   5=Menor de 6, 6=Discapacitado, 7=Otros */
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (cat_inac == 1 & condocup_ci == 3)
	replace categoinac_ci = 2 if (cat_inac == 3 & condocup_ci == 3)
	replace categoinac_ci = 3 if (cat_inac == 4 & condocup_ci == 3)
	replace categoinac_ci = 4 if ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3)

	**************
	*** emp_ci ***
	**************
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)

	*****************
	*** desemp_ci ***
	*****************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)

	**************
	*** pea_ci ***
	**************
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	******************
	*** cesante_ci ***
	******************
	/* pp10d: ¿Ha trabajado alguna vez? 1=Sí, 2=No */
	gen byte cesante_ci = .
	replace cesante_ci = 1 if pp10d == 1
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci == 2

	*******************
	*** desalent_ci ***
	*******************
	/* pp02b: buscó trabajo, pp02e: 3=se cansó de buscar, 4=poco trabajo en esta época */
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (pp02b == 2 & inlist(pp02e, 3, 4) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)

	*******************
	*** horaspri_ci ***
	*******************
	/* pp3e_tot: horas semanales en la ocupación principal (999 = Ns/Nr) */
	gen horaspri_ci = pp3e_tot
	replace horaspri_ci = . if pp3e_tot == 999

	*******************
	*** horastot_ci ***
	*******************
	gen otrashoras = pp3f_tot if pp3f_tot != 999
	egen horastot_ci = rsum(horaspri_ci otrashoras), missing
	replace horastot_ci = . if horaspri_ci == . & otrashoras == .
	drop otrashoras

	*****************
	*** subemp_ci ***
	*****************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if pp03g == 1 & (horastot_ci >= 1 & horastot_ci <= 30) & emp_ci == 1
	replace subemp_ci = . if emp_ci == .

	*********************
	*** tiempoparc_ci ***
	*********************
	gen byte tiempoparc_ci = (horastot_ci >= 1 & horastot_ci <= 30) & (pp03g == 2 & emp_ci == 1)
	replace tiempoparc_ci = . if emp_ci == 0 | emp_ci == .

	******************
	*** durades_ci ***
	******************
	gen durades_ci = .

	gen byte durades1_ci = pp10a
	replace durades1_ci = . if pp10a == 0 | pp10a == 9

	*******************
	*** nempleos_ci ***
	*******************
	/* pp03c: 1=un solo empleo, 2=más de uno; pp03d: cantidad de ocupaciones */
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if pp03c == 1 & pp03d == 0
	replace nempleos_ci = 2 if pp03d > 1 & pp03d != .
	replace nempleos_ci = . if pp03d == .

	*********************
	*** antiguedad_ci ***
	*********************
	/* Cuatro fuentes según categoría ocupacional. Para los tramos se usa el valor
	   medio de cada rango (truncada) */

	/* Servicio doméstico (continua) */
	gen ant_m = pp04b3_mes
	replace ant_m = . if pp04b3_mes == -1 | pp04b3_mes == 99 | pp04b3_mes < 0
	gen ant_a = pp04b3_ano
	replace ant_a = . if pp04b3_ano == -1 | pp04b3_ano == 99 | pp04b3_ano < 0
	replace ant_m = ant_m/12
	egen antiguedad1 = rsum(ant_a ant_m), missing
	replace antiguedad1 = . if pp04b3_mes == 0 & pp04b3_ano == 0

	/* Independientes (continua) */
	gen ant_mc = pp05b2_mes
	replace ant_mc = . if pp05b2_mes == -1 | pp05b2_mes == 99 | pp05b2_mes < 0
	gen ant_ac = pp05b2_ano
	replace ant_ac = . if pp05b2_ano == -1 | pp05b2_ano == 99 | pp05b2_ano < 0
	replace ant_mc = ant_mc/12
	egen antiguedad2 = rsum(ant_ac ant_mc), missing
	replace antiguedad2 = . if pp05b2_mes == 0 & pp05b2_ano == 0

	/* Empleados y obreros (tramos pp07a) */
	gen antiguedad3 = 0 if pp07a == 1 /* menos de 1 mes */
	replace antiguedad3 = 0.17 if pp07a == 2 /* 1-3 meses a 2/12 */
	replace antiguedad3 = 0.33 if pp07a == 3 /* 3-6 meses a 4/12 */
	replace antiguedad3 = 0.75 if pp07a == 4 /* 6m-1 año a 9/12 */
	replace antiguedad3 = 3 if pp07a == 5 /* 1-5 años */
	replace antiguedad3 = 5 if pp07a == 6 /* más de 5 años */
	replace antiguedad3 = . if pp07a == 0 | pp07a == 9

	/* Independientes (tramos pp05h) */
	gen antiguedad4 = 0 if pp05h == 1
	replace antiguedad4 = 2/12 if pp05h == 2
	replace antiguedad4 = 4/12 if pp05h == 3
	replace antiguedad4 = 9/12 if pp05h == 4
	replace antiguedad4 = 3 if pp05h == 5
	replace antiguedad4 = 5 if pp05h == 6
	replace antiguedad4 = . if pp05h == 0 | pp05h == 9

	gen antiguedad_ci = antiguedad1 if antiguedad1 != .
	replace antiguedad_ci = antiguedad2 if antiguedad2 != .
	replace antiguedad_ci = antiguedad3 if antiguedad3 != .
	replace antiguedad_ci = antiguedad4 if antiguedad4 != .
	drop ant_m ant_a ant_mc ant_ac antiguedad1 antiguedad2 antiguedad3 antiguedad4

	*******************
	*** categopri_ci ***
	*******************
	/* cat_ocup: 1=Patrón, 2=Cuenta propia, 3=Obrero/empleado, 4=TFSR, 9=Ns/Nr */
	gen byte categopri_ci = cat_ocup if emp_ci == 1
	replace categopri_ci = . if categopri_ci < 1 | categopri_ci > 4
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1

	********************
	*** categosec_ci ***
	********************
	/* La EPH no releva la categoría ocupacional de la actividad secundaria */
	gen byte categosec_ci = .

	***************
	*** rama_ci ***
	***************
	/* pp04b_cod es int con la CAES-Mercosur. Los códigos se almacenan sin los
	   ceros a la izquierda: 805 ocupados quedan con 2 o 3 dígitos (p.ej. 101 =
	   "0101" = división 01). Se normaliza a 4 dígitos y se mapea por DIVISIÓN
	   (primeros 2 dígitos), lo que reproduce los rangos de 4 dígitos de la serie
	   previa. Los códigos de 2 dígitos ya son divisiones y se usan directo. */
	tostring pp04b_cod, gen(_caes4) format(%04.0f) force
	gen int _caesdiv = real(substr(_caes4, 1, 2))
	replace _caesdiv = pp04b_cod if _caesdiv == 0 & pp04b_cod > 0

	gen byte rama_ci = .
	replace rama_ci = 1 if inrange(_caesdiv,  1,  3) & emp_ci == 1 /* Agricultura, caza, silvicultura y pesca */
	replace rama_ci = 2 if inrange(_caesdiv,  5,  9) & emp_ci == 1 /* Explotación de minas y canteras */
	replace rama_ci = 3 if inrange(_caesdiv, 10, 33) & emp_ci == 1 /* Industrias manufactureras */
	replace rama_ci = 4 if inrange(_caesdiv, 35, 39) & emp_ci == 1 /* Electricidad, gas y agua */
	replace rama_ci = 5 if _caesdiv == 40 & emp_ci == 1 /* Construcción */
	replace rama_ci = 6 if (inrange(_caesdiv, 45, 48) | inrange(_caesdiv, 55, 56)) & emp_ci == 1 /* Comercio, restaurantes y hoteles */
	replace rama_ci = 7 if inrange(_caesdiv, 49, 53) & emp_ci == 1 /* Transporte y almacenamiento */
	replace rama_ci = 8 if inrange(_caesdiv, 64, 82) & emp_ci == 1 /* Establecimientos financieros, seguros e inmuebles */
	replace rama_ci = 9 if (inrange(_caesdiv, 58, 63) | inrange(_caesdiv, 83, 99)) & emp_ci == 1	/* Servicios sociales y comunales */
	replace rama_ci = . if pp04b_cod == 9999 /* Ns/Nr */
	drop _caes4 _caesdiv

	*******************
	*** ramasec_ci ***
	*******************
	gen byte ramasec_ci = .

	*****************
	*** tamemp_ci ***
	*****************
	/* pp04c: tramos 1..12 (12 = más de 500 personas), 99 = Ns/Nr.
	   pp04c99 (1=hasta 5, 2=6-40, 3=más de 40) actúa como respaldo del 99. */
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if (pp04c >= 1 & pp04c <= 5)
	replace tamemp_ci = 1 if (pp04c == 99 & pp04c99 == 1)
	replace tamemp_ci = 2 if pp04c > 5 & pp04c <= 8
	replace tamemp_ci = 2 if (pp04c == 99 & pp04c99 == 2)
	replace tamemp_ci = 3 if pp04c > 8 & pp04c <= 12 & pp04c != . & pp04c != 99
	replace tamemp_ci = 3 if (pp04c == 99 & pp04c99 == 3)

	*******************
	*** spublico_ci ***
	*******************
	gen byte spublico_ci = .
	replace spublico_ci = 1 if pp04a == 1 & emp_ci == 1
	replace spublico_ci = 0 if inlist(pp04a, 2, 3) & emp_ci == 1

	********************
	*** cotizando_ci ***
	********************
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if (pp07h == 1 | pp07i == 1) & emp_ci == 1
	replace cotizando_ci = 0 if cotizando_ci != 1 & inlist(condocup_ci, 1, 2)

	******************
	*** instcot_ci ***
	******************
	gen instcot_ci = .

	*******************
	*** afiliado_ci ***
	*******************
	gen byte afiliado_ci = .

	*****************
	*** formal_ci ***
	*****************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	***********************
	*** tipocontrato_ci ***
	***********************
	/* pp07c: 1=tiene tiempo de finalización (temporal), 2=no (permanente) */
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if pp07c == 2 & categopri_ci == 3
	replace tipocontrato_ci = 2 if pp07c == 1 & categopri_ci == 3

	****************
	*** ocupa_ci ***
	****************
	tostring pp04d_cod, replace format(%05.0f) force
	gen ocup1 = substr(pp04d_cod, 1, 2)
	gen ocup2 = substr(pp04d_cod, 3, 1)
	gen ocup3 = substr(pp04d_cod, 4, 1)
	gen ocup4 = substr(pp04d_cod, 5, 1)
	destring ocup1 ocup2 ocup3 ocup4, replace

/* La CNO 2001 codifica el carácter ocupacional (ocup1) y la calificación (ocup4)
 en dígitos distintos y por eso hace falta una regla de precedencia (sin esto, 
 queda vacía la categoría 2) */

	gen byte ocupa_ci = .
	replace ocupa_ci = 2 if ocup1 >= 0 & ocup1 <= 7
	replace ocupa_ci = 1 if ocup4 >= 1 & ocup4 <= 2 & ocupa_ci != 2
	replace ocupa_ci = 3 if (ocup1 == 10 | ocup1 == 11 | ocup1 == 20) & ocupa_ci != 1
	replace ocupa_ci = 4 if ocup1 >= 30 & ocup1 <= 33 & ocupa_ci != 1
	replace ocupa_ci = 5 if ((ocup1 >= 36 & ocup1 <= 47) | (ocup1 >= 52 & ocup1 <= 58)) & ocupa_ci != 1
	replace ocupa_ci = 6 if ocup1 >= 60 & ocup1 <= 65 & ocupa_ci != 1
	replace ocupa_ci = 7 if ocup1 >= 70 & ocup1 <= 92 & ocupa_ci != 1
	replace ocupa_ci = 8 if ocup1 >= 48 & ocup1 <= 49 & ocupa_ci != 1
	replace ocupa_ci = 9 if (ocup1 == 34 | ocup1 == 35 | ocup1 == 50 | ocup1 == 51) & ocupa_ci != 1
	replace ocupa_ci = . if estado != 1 & ocup1 == 99
	replace ocupa_ci = . if emp_ci != 1
	drop ocup1 ocup2 ocup3 ocup4


****************
***PENSIONES ***
****************

	******************
	*** pension_ci ***
	******************
	gen byte pension_ci = 0
	replace pension_ci = 1 if v2_01_m > 0 & v2_01_m != . /* jubilación/pensión por aportes del trabajo */

	*********************
	*** pensionsub_ci ***
	*********************
	gen byte pensionsub_ci = 0
	replace pensionsub_ci = 1 if (v2_02_m > 0 & v2_02_m != .) | (v2_03_m > 0 & v2_03_m != .) /* moratoria/ama de casa + otras no contributivas */

	******************
	*** tipopen_ci ***
	******************
	/* 1=contributiva por aportes, 2=moratoria/ama de casa, 3=otras no contributivas.
	   Prioridad a la contributiva en los casos de solapamiento. */
	gen byte tipopen_ci = .
	replace tipopen_ci = 3 if v2_03_m > 0 & v2_03_m != .
	replace tipopen_ci = 2 if v2_02_m > 0 & v2_02_m != .
	replace tipopen_ci = 1 if v2_01_m > 0 & v2_01_m != .

	******************
	*** instpen_ci ***
	******************
	gen instpen_ci = .

	****************
	*** ypen_ci ***
	****************
	gen double _pen01 = v2_01_m  if v2_01_m  > 0 & v2_01_m  != .
	gen double _agu01 = v21_01_m/12 if v21_01_m > 0 & v21_01_m != . /* aguinaldo prorrateado */
	egen double ypen_ci = rowtotal(_pen01 _agu01), missing
	replace ypen_ci = . if pension_ci != 1
	drop _pen01 _agu01

	*******************
	*** ypensub_ci ***
	*******************
	gen double _pen02 = v2_02_m  if v2_02_m  > 0 & v2_02_m  != .
	gen double _agu02 = v21_02_m/12 if v21_02_m > 0 & v21_02_m != .
	gen double _pen03 = v2_03_m  if v2_03_m  > 0 & v2_03_m  != .
	gen double _agu03 = v21_03_m/12 if v21_03_m > 0 & v21_03_m != .
	egen double ypensub_ci = rowtotal(_pen02 _agu02 _pen03 _agu03), missing
	replace ypensub_ci = . if pensionsub_ci != 1
	drop _pen02 _agu02 _pen03 _agu03


**************************
***VARIABLES DE INGRESO***
**************************

	destring ipcf, dpcomma replace

	******************
	*** ylmpri_ci ***
	******************
	/* p21: ingreso de la ocupación principal (-9 = no respuesta). */
	gen double ylmpri_ci = .
	replace ylmpri_ci = p21 if emp_ci == 1
	replace ylmpri_ci = 0 if p21 < 0 & p21 != -9 & emp_ci == 1
	replace ylmpri_ci = . if p21 == . | p21 == -9

	*****************
	*** ylmsec_ci ***
	*****************
	/* tot_p12 mezcla ocupación secundaria, ocupación previa y retroactivos:
	   no aísla la actividad secundaria */
	gen double ylmsec_ci = .

	*******************
	*** ylmotros_ci ***
	*******************
	gen double ylmotros_ci = .

	******************
	*** ylnmpri_ci ***
	******************
	gen double ylnmpri_ci = .

	******************
	*** ylnmsec_ci ***
	******************
	gen double ylnmsec_ci = .

	********************
	*** ylnmotros_ci ***
	********************
	gen double ylnmotros_ci = .

	**************
	*** ylm_ci ***
	**************
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing

	***************
	*** ylnm_ci ***
	***************
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	***************
	*** ynlm_ci ***
	***************
	/* t_vi: monto total de ingresos no laborales (-9 = no respuesta) */
	gen double ynlm_ci = t_vi
	replace ynlm_ci = 0 if ynlm_ci < 0 & t_vi != -9
	replace ynlm_ci = . if t_vi == . | t_vi == -9

	****************
	*** ynlnm_ci ***
	****************
	gen double ynlnm_ci = .

	***************
	*** ytot_ci ***
	***************
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing

	**************
	*** ylm_ch ***
	**************
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, missing

	***************
	*** ylnm_ch ***
	***************
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, missing

	***************
	*** ynlm_ch ***
	***************
	bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, missing

	****************
	*** ynlnm_ch ***
	****************
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, missing

	***************
	*** ytot_ch ***
	***************
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), missing

	*******************
	*** ylmhopri_ci ***
	*******************
	/* p21 es mensual y las horas son semanales: 4.3 semanas/mes */
	gen double ylmhopri_ci = ylmpri_ci/(4.3*horaspri_ci) if emp_ci == 1 & horaspri_ci > 0 & horaspri_ci != .
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	*****************
	*** ylmho_ci ***
	*****************
	gen double ylmho_ci = ylm_ci/(4.3*horastot_ci) if emp_ci == 1 & horastot_ci > 0 & horastot_ci != .
	replace ylmho_ci = . if ylmho_ci <= 0

	*******************
	*** nrylmpri_ci ***
	*******************
	gen byte nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)

	*******************
	*** nrylmpri_ch ***
	*******************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1

	******************
	*** remesas_ci ***
	******************
	gen double remesas_ci = .

	******************
	*** remesas_ch ***
	******************
	bysort idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, missing


****************************
***VARIABLES DE EDUCACION***
****************************

	replace ch11 = . if ch11 == 9
	replace ch12 = . if ch12 == 99 | ch12 == 9 /* 9 = educación especial, recuperada por nivel_ed */
	replace ch13 = . if ch13 == 9
	destring ch14, replace
	replace ch14 = . if ch14 == 98 | ch14 == 99

	***************
	*** aedu_ci ***
	***************
	/* primaria completa=6, EGB=9,
	   secundario/polimodal=12, terciario=15, universitario=17, posgrado=19 */
	gen aedu_ci = .

	/* Quienes no terminaron el último nivel al que asistieron */
	replace aedu_ci = 0 if (ch10 == 0 | ch10 == 3) /* nunca asistió / no corresponde */
	replace aedu_ci = 0 if ch12 == 1 /* preescolar */
	replace aedu_ci = ch14 if ch12 == 2 | ch12 == 3 & ch13 == 2
	replace aedu_ci = ch14+6  if ch12 == 4 & ch13 == 2
	replace aedu_ci = ch14+9  if ch12 == 5 & ch13 == 2
	replace aedu_ci = ch14+12 if ch12 == 6 & ch13 == 2
	replace aedu_ci = ch14+12 if ch12 == 7 & ch13 == 2
	replace aedu_ci = ch14+17 if ch12 == 8 & ch13 == 2

	/* Quienes terminaron el último nivel al que asistieron */
	replace aedu_ci = 6  if ch12 == 2 & ch13 == 1
	replace aedu_ci = 9  if ch12 == 3 & ch13 == 1
	replace aedu_ci = 12 if ch12 == 4 & ch13 == 1
	replace aedu_ci = 12 if ch12 == 5 & ch13 == 1
	replace aedu_ci = 15 if ch12 == 6 & ch13 == 1
	replace aedu_ci = 17 if ch12 == 7 & ch13 == 1
	replace aedu_ci = 19 if ch12 == 8 & ch13 == 1

	/* Imputación de respaldo por nivel_ed */
	replace aedu_ci = 6  if nivel_ed == 2 & aedu_ci == .
	replace aedu_ci = 12 if nivel_ed == 4 & aedu_ci == .
	replace aedu_ci = 17 if nivel_ed == 6 & aedu_ci == .
	replace aedu_ci = 0  if nivel_ed == 7 & aedu_ci == .

	****************
	*** eduui_ci ***
	****************
	gen byte eduui_ci = (ch12 == 6 | ch12 == 7) & ch13 == 2
	replace eduui_ci = . if aedu_ci == .

	****************
	*** eduuc_ci ***
	****************
	gen byte eduuc_ci = ((ch12 == 6 | ch12 == 7) & ch13 == 1) | ch12 == 8
	replace eduuc_ci = . if aedu_ci == .

	****************
	*** eduac_ci ***
	****************
	gen byte eduac_ci = 1 if ch12 == 7 | ch12 == 8
	replace eduac_ci = 0 if ch12 == 6
	replace eduac_ci = . if aedu_ci == .

	*****************
	*** edupre_ci ***
	*****************
	gen byte edupre_ci = .

	******************
	*** asispre_ci ***
	******************
	gen byte asispre_ci = (ch10 == 1 & ch12 == 1)

	****************
	*** asiste_ci ***
	****************
	gen byte asiste_ci = (ch10 == 1)
	replace asiste_ci = . if ch10 == 0 | ch10 == 9

	************************
	*** razonesnoasis_ci ***
	************************
	/* La EPH no pregunta motivos de no asistencia */
	gen razonesnoasis_ci = .

	*****************
	*** edupub_ci ***
	*****************
	/* Missing para quienes no asisten actualmente */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if ch11 == 1 & asiste_ci == 1
	replace edupub_ci = 0 if ch11 == 2 & asiste_ci == 1


******************************
***VARIABLES DE LA VIVIENDA***
******************************

	**************
	*** luz_ch ***
	**************
	gen luz_ch = .

	******************
	*** luzmide_ch ***
	******************
	gen luzmide_ch = .

	******************
	*** combust_ch ***
	******************
	/* ii8: 1=Gas de red, 2=Gas de tubo/garrafa, 3=Kerosene/leña/carbón */
	gen byte combust_ch = 0
	replace combust_ch = 1 if ii8 == 1 | ii8 == 2
	replace combust_ch = . if ii8 == 0 | ii8 == 9

	***************
	*** piso_ch ***
	***************
	/* CREAR VACÍO — metodología en revisión (manual oct 2025) */
	gen piso_ch = .

	****************
	*** pared_ch ***
	****************
	gen pared_ch = .

	****************
	*** techo_ch ***
	****************
	/* CREAR VACÍO — metodología en revisión (manual oct 2025) */
	gen techo_ch = .

	****************
	*** resid_ch ***
	****************
	gen resid_ch = .

	***************
	*** dorm_ch ***
	***************
	gen dorm_ch = ii2 if ii3 == 2
	replace dorm_ch = . if ii2 == 99

	******************
	*** cuartos_ch ***
	******************
	gen cuartos_ch = ii1
	replace cuartos_ch = . if ii1 == 99

	*****************
	*** cocina_ch ***
	*****************
	gen byte cocina_ch = 0
	replace cocina_ch = 1 if ii4_1 == 1
	replace cocina_ch = . if ii4_1 == 0 | ii4_1 == 9

	****************
	*** telef_ch ***
	****************
	gen telef_ch = .

	*****************
	*** refrig_ch ***
	*****************
	gen refrig_ch = .

	****************
	*** freez_ch ***
	****************
	gen freez_ch = .

	***************
	*** auto_ch ***
	***************
	gen auto_ch = .

	****************
	*** compu_ch ***
	****************
	gen compu_ch = .

	*******************
	*** internet_ch ***
	*******************
	gen internet_ch = .

	**************
	*** cel_ch ***
	**************
	gen cel_ch = .

	****************
	*** vivi1_ch ***
	****************
	/* iv1: 1=Casa, 2=Depto, 3=Pieza inquilinato, 4=Pieza hotel/pensión,
	   5=Local no construido para habitación, 6=Otros (iv1_esp) */
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if iv1 == 1
	replace vivi1_ch = 2 if iv1 == 2
	replace vivi1_ch = 3 if inlist(iv1, 3, 4, 5, 6)

	****************
	*** vivi2_ch ***
	****************
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if vivi1_ch == 1 | vivi1_ch == 2
	replace vivi2_ch = 0 if vivi1_ch == 3

	*******************
	*** viviprop_ch ***
	*******************
	/* ii7: 1=Propietario vivienda y terreno, 2=Propietario sólo vivienda,
	   3=Inquilino, 4-8=Ocupante en distintas figuras */
	gen byte viviprop_ch = .
	replace viviprop_ch = 1 if inlist(ii7, 1, 2)
	replace viviprop_ch = 2 if ii7 == 3
	replace viviprop_ch = 3 if ii7 >= 4 & ii7 <= 8
	replace viviprop_ch = . if ii7 == 0 | ii7 == 9

	*****************
	*** vivitit_ch ***
	*****************
	gen vivitit_ch = .

	*****************
	*** vivialq_ch ***
	*****************
	gen vivialq_ch = .

	********************
	*** vivialqimp_ch ***
	********************
	gen vivialqimp_ch = .


**********************
***VARIABLES DE WASH***
**********************

	*******************
	*** aguadist_ch ***
	*******************
	/* iv6: 1=Cañería dentro de la vivienda, 2=Fuera de la vivienda pero dentro
	   del terreno, 3=Fuera del terreno */
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if iv6 == 1
	replace aguadist_ch = 2 if iv6 == 2
	replace aguadist_ch = 3 if iv6 == 3

	************************
	*** aguafconsumo_ch ***
	************************
	/* Encuesta no pregunta sobre agua para beber.
	   La EPH sólo releva la fuente de uso general (iv6/iv7). */
	gen byte aguafconsumo_ch = 0

	*********************
	*** aguafuente_ch ***
	*********************
	/* iv7: 1=Red pública, 2=Perforación con bomba a motor, 3=Perforación con bomba
	   manual, 4=Otra (iv7_esp) */
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1 if iv7 == 1 & iv6 < 3
	replace aguafuente_ch = 2 if iv7 == 1 & iv6 == 3
	replace aguafuente_ch = 10 if iv7 > 1
	replace aguafuente_ch = 10 if aguafuente_ch == . & jefe_ci == 1

	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch != .

	*****************
	*** aguared_ch ***
	*****************
	gen byte aguared_ch = .
	replace aguared_ch = 1 if inlist(aguafuente_ch, 1, 2)
	replace aguared_ch = 0 if aguafuente_ch >= 3 & aguafuente_ch != .

	*******************
	*** aguadisp1_ch ***
	*******************
	/* La EPH no pregunta por la continuidad del servicio */
	gen byte aguadisp1_ch = 9

	*******************
	*** aguadisp2_ch ***
	*******************
	gen byte aguadisp2_ch = 9

	******************
	*** aguatrat_ch ***
	******************
	/* La EPH no pregunta si se trata el agua antes de consumirla */
	gen byte aguatrat_ch = 9

	******************
	*** aguamide_ch ***
	******************
	gen byte aguamide_ch = .

	***************
	*** bano_ch ***
	***************
	/* iv8: tiene baño/letrina; iv9: ubicación; iv10: tipo; iv11: desagüe */
	gen byte bano_ch = .
	replace bano_ch = 0 if iv9 == 3 | inlist(iv8, 0, 2, 9) | iv8 == . /* sin instalaciones */
	replace bano_ch = 1 if inlist(iv9, 1, 2) & inlist(iv10, 1, 2) & iv11 == 1 /* inodoro a red de desagüe */
	replace bano_ch = 2 if inlist(iv9, 1, 2) & inlist(iv10, 1, 2) & iv11 == 2 /* inodoro a cámara séptica */
	replace bano_ch = 3 if inlist(iv9, 1, 2) & ((inlist(iv10, 1, 2, 3) & iv11 == 3) | (iv10 == 3 & inlist(iv11, 1, 2)))	/* letrina u otro mejorado */
	replace bano_ch = 4 if inlist(iv9, 1, 2) & inlist(iv10, 1, 2, 3) & iv11 == 4 /* descarga a hoyo/excavación */
	replace bano_ch = 6 if inlist(iv8, 1) & (inlist(iv9, 0, 9) | inlist(iv10, 0, 9) | inlist(iv11, 0, 9)) & bano_ch == . /* sin clasificar */

	*****************
	*** banoex_ch ***
	*****************
	/* ii9: 1=Uso exclusivo, 2=Compartido en la vivienda, 3=Compartido con otra
	   vivienda, 4=No tiene baño */
	gen byte banoex_ch = 0
	replace banoex_ch = 1 if ii9 == 1
	replace banoex_ch = . if ii9 == 0 | ii9 == 9

	******************
	*** sinbano_ch ***
	******************
	gen byte sinbano_ch = .
	replace sinbano_ch = 0 if bano_ch > 0 & bano_ch != .
	replace sinbano_ch = 1 if iv8 == 1 & iv9 == 3
	replace sinbano_ch = 3 if inlist(iv8, 0, 2, 9) | iv8 == .
	replace sinbano_ch = 1 if iv8 == 2 & ii9 == 3

	*******************
	*** aguamala_ch ***
	*******************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	***********************
	*** aguamejorada_ch ***
	***********************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	***********************
	*** banomejorado_ch ***
	***********************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6 & bano_ch != .


****************************
***VARIABLES DE MIGRACION***
****************************

	*******************
	*** migrante_ci ***
	*******************
	/* ch15: 1=Esta localidad, 2=Otra localidad de la provincia, 3=Otra provincia,
	   4=País limítrofe, 5=Otro país, 9=Ns/Nr (excluido) */
	gen byte migrante_ci = (inlist(ch15, 4, 5)) if ch15 != . & ch15 != 9

	***********************
	*** migrantiguo5_ci ***
	***********************
	/* ch16: residencia hace 5 años */
	gen byte migrantiguo5_ci = .
	replace migrantiguo5_ci = 1 if inlist(ch16, 1, 2, 3) & migrante_ci == 1
	replace migrantiguo5_ci = 0 if inlist(ch16, 6, 4, 5, 0) & migrante_ci == 1
	replace migrantiguo5_ci = . if inlist(ch16, 9) | migrante_ci == 0

	*****************
	*** miglac_ci ***
	*****************
	gen miglac_ci = 1 if (ch15==4 | inlist(ch15_cod, 201, 202, 203, 205, 206, 207, 208, 209, 210) | ///
	inlist(ch15_cod, 211, 213, 214, 215, 216, 217, 218, 219, 220) | ///
	inlist(ch15_cod, 221, 222, 224, 225, 226, 232, 233, 236, 237) | ///
	inlist(ch15_cod, 239, 240)) & migrante_ci == 1
	replace miglac_ci = 0 if miglac_ci != 1 & migrante_ci == 1
	replace miglac_ci = . if migrante_ci == 0


************************
***VARIABLES EXTERNAS***
************************

	**********************
	*** tipo_bienestar ***
	**********************
	gen byte tipo_bienestar = 1
	
	**********************
	* bienestar_agregado *
	**********************
	gen bienestar_agregado = itf
	
	*Metodología oficial de cálculo de las líneas de pobreza INDEC https://www.indec.gob.ar/uploads/informesdeprensa/eph_pobreza_03_269225CA3217.pdf

	*Adulto equivalente por persona (tabla INDEC; ch06=edad, ch04: 1=varón, 2=mujer)
	gen double adequiv = .
	replace adequiv = 0.35 if ch06==0       
	replace adequiv = 0.37 if ch06==1
	replace adequiv = 0.46 if ch06==2
	replace adequiv = 0.51 if ch06==3
	replace adequiv = 0.55 if ch06==4
	replace adequiv = 0.60 if ch06==5
	replace adequiv = 0.64 if ch06==6
	replace adequiv = 0.66 if ch06==7
	replace adequiv = 0.68 if ch06==8
	replace adequiv = 0.69 if ch06==9
	* Varones 10+
	replace adequiv = 0.79 if ch04==1 & ch06==10
	replace adequiv = 0.82 if ch04==1 & ch06==11
	replace adequiv = 0.85 if ch04==1 & ch06==12
	replace adequiv = 0.90 if ch04==1 & ch06==13
	replace adequiv = 0.96 if ch04==1 & ch06==14
	replace adequiv = 1.00 if ch04==1 & ch06==15
	replace adequiv = 1.03 if ch04==1 & ch06==16
	replace adequiv = 1.04 if ch04==1 & ch06==17
	replace adequiv = 1.02 if ch04==1 & inrange(ch06,18,29)
	replace adequiv = 1.00 if ch04==1 & inrange(ch06,30,60)
	replace adequiv = 0.83 if ch04==1 & inrange(ch06,61,75)
	replace adequiv = 0.74 if ch04==1 & inrange(ch06,76,98)
	* Mujeres 10+
	replace adequiv = 0.70 if ch04==2 & ch06==10
	replace adequiv = 0.72 if ch04==2 & ch06==11
	replace adequiv = 0.74 if ch04==2 & ch06==12
	replace adequiv = 0.76 if ch04==2 & inrange(ch06,13,14)
	replace adequiv = 0.77 if ch04==2 & inrange(ch06,15,17)
	replace adequiv = 0.76 if ch04==2 & inrange(ch06,18,29)
	replace adequiv = 0.77 if ch04==2 & inrange(ch06,30,45)
	replace adequiv = 0.76 if ch04==2 & inrange(ch06,46,60)
	replace adequiv = 0.67 if ch04==2 & inrange(ch06,61,75)
	replace adequiv = 0.63 if ch04==2 & inrange(ch06,76,98)
	* (ch06==99 = Ns/Nr queda en missing a propósito)
	
	*Adultos equivalentes del hogar
	bysort codusu nro_hogar: egen double adeq_hogar = total(adequiv)
	
	*******
	*ln_ci*
	*******
	gen double cbt_ae = .
	replace cbt_ae =302605.6233  if region==1  & trimestre==3
	replace cbt_ae = 286923.3833 if region==42 & trimestre==3
	replace cbt_ae = 252282.6967 if region==41 & trimestre==3
	replace cbt_ae =244736  if region==40 & trimestre==3
	replace cbt_ae = 299050.19 if region==43 & trimestre==3
	replace cbt_ae =353498.3267  if region==44 & trimestre==3
	replace cbt_ae = 407749.85 if region==1  & trimestre==4
	replace cbt_ae = 387545.02 if region==42 & trimestre==4
	replace cbt_ae = 342567.19 if region==41 & trimestre==4
	replace cbt_ae = 328204.11 if region==40 & trimestre==4
	replace cbt_ae = 402749.32 if region==43 & trimestre==4
	replace cbt_ae = 477519.42 if region==44 & trimestre==4
	
	gen double ln_ci = cbt_ae * adeq_hogar
	
	********
	*lpe_ci*
	********
	gen double cba_ae = .
	replace cba_ae = 135479.06 if region==1  & trimestre==3
	replace cba_ae = 120706.4567 if region==42 & trimestre==3
	replace cba_ae = 120881.8267 if region==41 & trimestre==3
	replace cba_ae = 118023.7067 if region==40 & trimestre==3
	replace cba_ae = 133886.9367 if region==43 & trimestre==3
	replace cba_ae = 139523.1033 if region==44 & trimestre==3
	replace cba_ae = 183406.61  if region==1  & trimestre==4
	replace cba_ae = 163537.54 if region==42 & trimestre==4
	replace cba_ae = 164443.07 if region==41 & trimestre==4
	replace cba_ae = 159074.04 if region==40 & trimestre==4
	replace cba_ae = 181157.15 if region==43 & trimestre==4
	replace cba_ae = 189251.96 if region==44 & trimestre==4

	gen double lpe_ci = cba_ae * adeq_hogar
	
	****************
	* pobre_ine_ci*
	**************** 
	gen byte pobre_ci = (bienestar_agregado < ln_ci) if !missing(bienestar_agregado, ln_ci)
	
	*******************
	* pobre_ine_ext_ci*
	******************* 
	gen byte pobre_ine_ext_ci = (bienestar_agregado < lpe_ci) if !missing(bienestar_agregado, lpe_ci)

	

	/*_____________________________________________________________________________________________________*/

	* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
    * Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza

	/*_____________________________________________________________________________________________________*/
	

	do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

	
	/*_____________________________________________________________________________________________________*/
	* Verificación de que se encuentren todas las variables armonizadas 
	/*_____________________________________________________________________________________________________*/
	
	
      order region_BID_c region_c pais_c anio_c mes_c zona_c idh_ch idp_ci factor_ci factor_ch estrato_ci upm_ci /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	/// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci /// Ingresos individuo
     ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch   ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci pobre_ine_ci pobre_ine_ext_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




saveold "`base_out'", version(12) replace

cap log close
