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

local PAIS     URY
local ENCUESTA ECH
local ANO      2025
local ronda    a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Uruguay
Encuesta: ECH
Round: a
Autores: Matías Isla y David Cornejo (SCL/SCL)
Version: 28/04/2026
Mail: matiasi@iadb.org/dcor@iadb.org, 28 de abril de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use "`base_in'", clear

/* Convertir "NA" strings a vacío */
ds, has(type string)
foreach v in `r(varlist)' {
	replace `v' = "" if `v' == "NA"
}

/* Destring de variables que cambiaron a string entre 2024 y 2025 */
destring f71_2, replace force
destring f113,  replace force

/* Variables educativas string en 2025. convertir para comparaciones numéricas */
gen byte _e579_n  = real(e579)
gen byte _e581_n  = real(e581)
gen byte _e581a_n = real(e581a)


**********************************
***VARIABLES DE IDENTIFICACION ***
**********************************

	********************
	*** region_BID_c ***
	********************
	gen byte region_BID_c = 4

	********************
	*** region_c      ***
	********************
	gen byte region_c = dpto

	***********
	*** pais_c ***
	***********
	gen str3 pais_c = "URY"

	***********
	*** anio_c ***
	***********
	gen int anio_c = 2025

	**********
	*** mes_c ***
	**********
	gen int mes_c = mes

	***********
	*** zona_c ***
	***********
	gen byte zona_c = .
	replace zona_c = 1 if region_4 == 1 | region_4 == 2
	replace zona_c = 0 if region_4 == 3 | region_4 == 4

	****************
	*** estrato_ci ***
	****************
	gen estrato_ci = estred13

	**********
	*** upm_ci ***
	**********
	gen upm_ci = .

	********************
	*** idh_ch / idp_ci ***
	********************
	tostring id,   gen(idh_ch) format("%12.0f")
	tostring nper, gen(_nper_str) format("%02.0f")
	gen idp_ci = idh_ch + _nper_str
	drop _nper_str

	*****************
	*** factor_ci ***
	*****************
	gen factor_ci = w_ano

	*****************
	*** factor_ch ***
	*****************
	gen factor_ch = w_ano


****************************
***VARIABLES DEMOGRAFICAS ***
****************************

	***********
	*** sexo_ci ***
	***********
	gen byte sexo_ci = e26

	***********
	*** edad_ci ***
	***********
	gen int edad_ci = e27

	**************
	*** relacion_ci ***
	**************
	gen byte relacion_ci = .
	replace relacion_ci = 1 if e30 == 1
	replace relacion_ci = 2 if e30 == 2
	replace relacion_ci = 3 if e30 >= 3 & e30 <= 5
	replace relacion_ci = 4 if e30 >= 6 & e30 <= 12
	replace relacion_ci = 5 if e30 == 13
	replace relacion_ci = 6 if e30 == 14

	***************
	*** miembros_ci ***
	***************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	******************
	*** miembros_one_ci ***
	******************
	gen byte miembros_one_ci = 1

	**********
	*** civil_ci ***
	**********
	/* e36: 1=sep UL prev, 2=divorciado, 3=casado(incl sep no div), 4=viudo casam, 5=soltero, 6=viudo UL */
	gen byte civil_ci = .
	replace civil_ci = 1 if e36 == 5 & e33 == 2
	replace civil_ci = 2 if e33 == 1
	replace civil_ci = 2 if e36 == 3 & e33 == 2
	replace civil_ci = 3 if (e36 == 1 | e36 == 2) & e33 == 2
	replace civil_ci = 4 if (e36 == 4 | e36 == 6) & e33 == 2

	*********
	*** jefe_ci ***
	*********
	gen byte jefe_ci = .
	replace jefe_ci = 1 if relacion_ci == 1
	replace jefe_ci = 0 if relacion_ci != 1 & relacion_ci != .

	********************
	*** nconyuges_ch ***
	********************
	by idh_ch, sort: egen byte nconyuges_ch   = sum(relacion_ci == 2)
	replace nconyuges_ch = . if relacion_ci == .
	
	*****************
	*** nhijos_ch ***
	*****************
	by idh_ch, sort: egen byte nhijos_ch      = sum(relacion_ci == 3)
	replace nhijos_ch = . if relacion_ci == .

	********************
	*** notropari_ch ***
	********************
	by idh_ch, sort: egen byte notropari_ch   = sum(relacion_ci == 4)
	replace notropari_ch = . if relacion_ci == .

	**********************
	*** notronopari_ch ***
	**********************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	replace notronopari_ch = . if relacion_ci == .

	******************
	*** nempdom_ch ***
	******************
	by idh_ch, sort: egen byte nempdom_ch     = sum(relacion_ci == 6)
	replace nempdom_ch = . if relacion_ci == .

	*******************
	*** clasehog_ch ***
	*******************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	replace clasehog_ch = 4 if (nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0)
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

	********************
	*** nmiembros_ch ***
	********************
	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci <= 5)

	******************
	*** nmayor21_ch***
	******************
	by idh_ch, sort: egen byte nmayor21_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))

	*******************
	*** nmenor21_ch ***
	*******************
	by idh_ch, sort: egen byte nmenor21_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))
	
	*******************
	*** nmayor65_ch ***
	*******************
	by idh_ch, sort: egen byte nmayor65_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))
	
	******************
	*** nmenor6_ch ***
	******************	
	by idh_ch, sort: egen byte nmenor6_ch   = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))

	******************
	*** nmenor1_ch ***
	******************
	by idh_ch, sort: egen byte nmenor1_ch   = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	***************
	*** afro_ci ***
	***************
	gen byte afro_ci = .
	replace afro_ci = 1 if e29_1 == 1
	replace afro_ci = 0 if e29_1 == 2

	********
	*** ind_ci ***
	********
	gen byte ind_ci = .
	replace ind_ci = 1 if e29_4 == 1
	replace ind_ci = 0 if e29_4 == 2

	**************
	*** noafroind_ci ***
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if (afro_ci == 0 | ind_ci == 0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci = 0 if (afro_ci == 1 | ind_ci == 1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci = . if (afro_ci == . & ind_ci == .)

	****************
	*** afroind_ano_c ***
	****************
	gen int afroind_ano_c = 2025

	*************
	*** afroind_ci ***
	*************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	***************
	*** afro_ch ***
	***************
	gen byte _afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(_afro_jefe), by(idh_ch)
	drop _afro_jefe

	**************
	*** ind_ch ***
	**************
	gen byte _ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(_ind_jefe), by(idh_ch)
	drop _ind_jefe

	********************
	*** noafroind_ch ***
	********************
	gen byte _noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(_noafroind_jefe), by(idh_ch)
	drop _noafroind_jefe

	******************
	*** afroind_ch ***
	******************
	gen byte _afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(_afroind_jefe), by(idh_ch)
	drop _afroind_jefe

	**************
	*** dis_ci ***
	**************
	gen byte dis_ci   = .

	****************
	*** disWG_ci ***
	****************
	gen byte disWG_ci = .
	
	**************
	*** dis_ch ***
	**************
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	*************
	*** URY_dis_ci ***
	*************
	gen byte URY_dis_ci = .


****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	**************
	*** condocup_ci ***
	**************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if pobpcoac == 2
	replace condocup_ci = 2 if pobpcoac == 3 | pobpcoac == 4 | pobpcoac == 5
	replace condocup_ci = 3 if pobpcoac >= 6 & pobpcoac <= 11
	replace condocup_ci = 4 if pobpcoac == 1

	*****************
	*** categoinac_ci ***
	*****************
	/* pobpcoac: 6=qqhh, 7=estud, 8=rentista, 9=pensionista, 10=jubilado, 11=otro */
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (pobpcoac == 9 | pobpcoac == 10) & condocup_ci == 3
	replace categoinac_ci = 2 if pobpcoac == 7 & condocup_ci == 3
	replace categoinac_ci = 3 if pobpcoac == 6 & condocup_ci == 3
	replace categoinac_ci = 4 if categoinac_ci == . & condocup_ci == 3

	**************
	*** emp_ci ***
	**************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	******************
	*** cesante_ci ***
	******************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if pobpcoac == 4 | pobpcoac == 5
	replace cesante_ci = 0 if pobpcoac == 3

	*****************
	*** desemp_ci ***
	*****************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci

	**********
	*** subemp_ci ***
	**********
	gen byte subemp_ci = .
	replace subemp_ci = 0 if emp_ci == 1
	replace subemp_ci = 1 if emp_ci == 1 & f85 < 31 & f102 == 1 & (f103 == 1 | f103 == 3)

	***********
	*** durades_ci ***
	***********
	/* f113 en semanas (ya destringado arriba) a meses */
	gen int durades_ci = round(f113 / 4.3) if f113 > 0
	replace durades_ci = . if pobpcoac != 3 & pobpcoac != 4 & pobpcoac != 5

	*********
	*** pea_ci ***
	*********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	***********
	*** nempleos_ci ***
	***********
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if f70 == 1 & emp_ci == 1
	replace nempleos_ci = 2 if f70 > 1 & f70 != . & emp_ci == 1

	***************
	*** antiguedad_ci ***
	***************
	gen byte antiguedad_ci = .
	replace antiguedad_ci = anio_c - f307 if emp_ci == 1 & f307 > 1900 & f307 <= anio_c
	replace antiguedad_ci = 0 if antiguedad_ci < 1 & antiguedad_ci != .

	***********
	*** desalent_ci ***
	***********
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (f299 == 2 & f108 == 4 & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0 "No" 1 "Si", add
	label value desalent_ci desalent_ci
	
	***********
	*** horaspri_ci ***
	***********
	gen byte horaspri_ci = .
	replace horaspri_ci = f85 if f85 != 98 & emp_ci == 1

	***********
	*** horastot_ci ***
	***********
	gen int horastot_ci = .
	replace horastot_ci = f85 + f98 if emp_ci == 1 & f85 != 98 & f98 != 98 & f98 != .
	replace horastot_ci = f85 if emp_ci == 1 & f85 != 98 & (f98 == . | f98 == 98)

	***************
	*** tiempoparc_ci ***
	***************
	gen byte tiempoparc_ci = .
	replace tiempoparc_ci = 0 if emp_ci == 1
	replace tiempoparc_ci = 1 if emp_ci == 1 & horaspri_ci >= 1 & horaspri_ci < 30 & f102 == 2

	***************
	*** categopri_ci ***
	***************
	/* f73: 1=asal.priv, 2=asal.pub, 3=socio coop, 4=empleador, 7=mbr.hogar, 8=prog.social, 9=cta.propia */
	gen byte categopri_ci = .
	replace categopri_ci = 1 if f73 == 4 & emp_ci == 1
	replace categopri_ci = 2 if (f73 == 3 | f73 == 9) & emp_ci == 1
	replace categopri_ci = 3 if (f73 == 1 | f73 == 2 | f73 == 8) & emp_ci == 1
	replace categopri_ci = 4 if f73 == 7 & emp_ci == 1
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1

	***************
	*** categosec_ci ***
	***************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if f92 == 4
	replace categosec_ci = 2 if f92 == 9 | f92 == 3
	replace categosec_ci = 3 if f92 == 1 | f92 == 2 | f92 == 8
	replace categosec_ci = 4 if f92 == 7
	replace categosec_ci = 0 if categosec_ci == . & nempleos_ci == 2

	*********
	*** rama_ci ***
	*********
	gen byte rama_ci = .
	replace rama_ci = 1 if (f72_2 > 0    & f72_2 <= 400)  & emp_ci == 1
	replace rama_ci = 2 if (f72_2 >= 500  & f72_2 <= 1000) & emp_ci == 1
	replace rama_ci = 3 if (f72_2 >= 1010 & f72_2 <= 3400) & emp_ci == 1
	replace rama_ci = 4 if (f72_2 >= 3500 & f72_2 <= 4000) & emp_ci == 1
	replace rama_ci = 5 if (f72_2 >= 4100 & f72_2 <= 4400) & emp_ci == 1
	replace rama_ci = 6 if ((f72_2 >= 4500 & f72_2 <= 4800) | (f72_2 >= 5500 & f72_2 <= 5700)) & emp_ci == 1
	replace rama_ci = 7 if ((f72_2 >= 4900 & f72_2 <= 5400) | (f72_2 >= 6100 & f72_2 <= 6199)) & emp_ci == 1
	replace rama_ci = 8 if (f72_2 >= 6400 & f72_2 <= 8300) & emp_ci == 1
	replace rama_ci = 9 if ((f72_2 >= 5800 & f72_2 <= 6090) | (f72_2 >= 6200 & f72_2 <= 6399) | (f72_2 >= 8400 & f72_2 <= 9900)) & emp_ci == 1

	*************
	*** spublico_ci ***
	*************
	gen byte spublico_ci = .
	replace spublico_ci = 0 if emp_ci == 1
	replace spublico_ci = 1 if f73 == 2 & emp_ci == 1

	**********
	*** tamemp_ci ***
	**********
	/* f77: 1=1pers, 2=2-4, 3=5-9, 4=10-19, 5=20-49, 7=50-99, 8=100-199, 9=200+ */
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if (f77 == 1 | f77 == 2) & emp_ci == 1
	replace tamemp_ci = 2 if (f77 >= 3 & f77 <= 5)  & emp_ci == 1
	replace tamemp_ci = 3 if (f77 >= 7 & f77 <= 9)  & emp_ci == 1

	***************
	*** cotizando_ci ***
	***************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((f82==1 | f96==1) & emp_ci==1)
	replace cotizando_ci = 0 if ((f82==2 | f96==2) & inlist(condocup_ci, 1, 2) )
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	***********
	*** afiliado_ci ***
	***********
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if ((f82==1 | f96==1) & emp_ci==1)
	replace afiliado_ci = 0 if ((f82==2 | f96==2) & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci
	
	**********
	*** instcot_ci ***
	**********
	gen byte instcot_ci = f83 if cotizando_ci == 1
	replace instcot_ci = . if instcot_ci == 0

	**********
	*** formal_ci ***
	**********
	gen byte formal_ci = .
	replace formal_ci = 1 if cotizando_ci == 1 & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	***************
	*** tipocontrato_ci ***
	***************
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if f283 == 6 & categopri_ci == 3
	replace tipocontrato_ci = 2 if (f283 >= 1 & f283 <= 5) & f283 != . & categopri_ci == 3

	**********
	*** ocupa_ci ***
	**********
	gen byte ocupa_ci = .
	replace ocupa_ci = 1 if (f71_2 >= 2111 & f71_2 <= 3522) & emp_ci == 1
	replace ocupa_ci = 2 if (f71_2 >= 1111 & f71_2 <= 1439) & emp_ci == 1
	replace ocupa_ci = 3 if ((f71_2 >= 4110 & f71_2 <= 4419) | (f71_2 >= 410 & f71_2 <= 430)) & emp_ci == 1
	replace ocupa_ci = 4 if ((f71_2 >= 5211 & f71_2 <= 5249) | (f71_2 >= 9510 & f71_2 <= 9520)) & emp_ci == 1
	replace ocupa_ci = 5 if ((f71_2 >= 5111 & f71_2 <= 5169) | (f71_2 >= 5311 & f71_2 <= 5419) | (f71_2 >= 9111 & f71_2 <= 9129) | (f71_2 >= 9611 & f71_2 <= 9624)) & emp_ci == 1
	replace ocupa_ci = 6 if ((f71_2 >= 6111 & f71_2 <= 6340) | (f71_2 >= 9211 & f71_2 <= 9216)) & emp_ci == 1
	replace ocupa_ci = 7 if ((f71_2 >= 7111 & f71_2 <= 8350) | (f71_2 >= 9311 & f71_2 <= 9412)) & emp_ci == 1
	replace ocupa_ci = 8 if (f71_2 >= 110 & f71_2 <= 310) & emp_ci == 1
	replace ocupa_ci = 9 if f71_2 == 9629 & emp_ci == 1


****************************
***VARIABLES DE PENSIONES***
****************************

	**********
	*** pension_ci ***
	**********
	// Existe un filtro para la sección de jubilados, pero hay inconsistencias entre f124_1, f125, g_it_1 & g148_1*:
	egen double aux_jub = rowtotal(g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_10 g148_1_11 g148_1_12), mi
	gen byte f_jub = (aux_jub > 0) if !missing(aux_jub) 	// Reportó algun monto en la sección de jubilaciones
	replace f_jub = . if f124_1 == 0 & f_jub == 0		    // Se excluye a quienes no se les realiza la pregunta

	gen pension_ci = f_jub
	replace pension_ci = 0 if g148_1_11 > 0 & pension_ci == 1	 // Se excluyen jubilaciones extranjeras

	***************
	*** pensionsub_ci ***
	***************
	// Existe un filtro para la sección de pensionista, pero hay inconsistencias entre f124_2, f125, g_it_2 & g148_2*:
	egen double aux_pens = rowtotal(g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9 g148_2_10 g148_2_11 g148_2_12), mi
	gen byte f_pens = (aux_pens > 0) if !missing(aux_pens) 		// Reportó algun monto en la sección de pensiones
	replace f_pens = . if f124_2 == 0 & f_pens == 0		    // Se excluye a quienes no se les realiza la pregunta
	
	gen pensionsub_ci = (f125 == 1 & f_pens == 1) if !missing(f_pens)
	replace pensionsub_ci = 0 if g148_2_11 > 0 & pensionsub_ci == 1 	// Se excluyen pensiones extranjeras
	
	**********
	*** tipopen_ci ***
	**********
	gen byte tipopen_ci = f125
	replace tipopen_ci = . if f125 == 0 | f125 == .

	**********
	*** instpen_ci ***
	**********
	gen byte instpen_ci = .


*************************************************
*** VARIABLES DE INGRESOS & PROTECCION SOCIAL ***
*************************************************

*A. INGRESO LABORAL (MONETARIO Y NO MONETARIO) ***

	***********
	*** ylmpri_ci ***
	***********
	egen double ylmpri_ci = rowtotal(g126_1 g126_2 g126_3 g126_4 g126_5 g126_6 g126_7 g142 g143 g133_2) if emp_ci == 1, missing

	***********
	*** ylmsec_ci ***
	***********
	egen double ylmsec_ci = rowtotal(g134_1 g134_2 g134_3 g134_4 g134_5 g134_6 g134_7 g141_2) if emp_ci == 1, missing

	***********
	*** ylmotros_ci ***
	***********
	/* No hay tercer empleo en ECH (era copia de sec en 2024: error corregido) */
	gen double ylmotros_ci = . if emp_ci == 1

	*********
	*** ylm_ci ***
	*********
	egen double ing_lab = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	
		// Tratamiento asignaciones familiares del Plan de Equidad (evitar doble contabilización con transferencia no contributiva)
		gen afam_sueldo = (g150 == 1 & g255 == 1 & g256 == 1) if g150 != 0
			
		// Se resta del ingreso laboral SÓLO en caso que ylm_ci > g257
		gen indica = 1 if (ing_lab < g257) & ing_lab != . & g257 != 0 & afam_sueldo == 1
		replace indica = 2 if (ing_lab > g257) & ing_lab != . & g257 != 0 & afam_sueldo == 1 & indica == .
		gen double aux_afam = g257*(-1) if indica == 2
	
	// El ingreso laboral principal sin la asignacion familiar del Plan Equidad (incluida en el sueldo):
	egen double ylm_ci = rowtotal(ing_lab aux_afam), mi	

	***********
	*** ylnmpri_ci ***
	***********
	gen double desay   = g127_1 * mto_desay
	gen double almue   = g127_2 * mto_almue
	gen double vacas   = g132_1 * mto_vacas
	gen double oveja   = g132_2 * mto_oveja
	gen double caballo = g132_3 * mto_caball
	destring g144_1, replace force

	egen double ylnmpri_ci = rowtotal(desay almue vacas oveja caballo g126_8 g127_3 g128_1 g129_2 g130_1 g131_1 g133_1 g144_1 g144_2_1 g144_2_2 g144_2_3 g144_2_4 g144_2_5) if emp_ci == 1, missing
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .
	drop desay almue vacas oveja caballo

	***********
	*** ylnmsec_ci ***
	***********
	destring g135_1 g135_2 g135_3 g136_1 g137_2 g138_1 g139_1, replace force
	gen double desaysec   = g135_1 * mto_desay
	gen double almuesec   = g135_2 * mto_almue
	gen double vacassec   = g140_1 * mto_vacas
	gen double ovejasec   = g140_2 * mto_oveja
	gen double caballosec = g140_3 * mto_caball

	egen double ylnmsec_ci = rowtotal(desaysec almuesec vacassec ovejasec caballosec g134_8 g135_3 g136_1 g137_2 g138_1 g139_1 g141_1) if emp_ci == 1, missing
	replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .
	drop desaysec almuesec vacassec ovejasec caballosec

	***********
	*** ylnmotros_ci ***
	***********
	gen double ylnmotros_ci = . if emp_ci == 1

	*********
	*** ylnm_ci ***
	*********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .
	
	
*B. INGRESO NO LABORAL (MONETARIO Y NO MONETARIO) ***

	********************************************************
	*** ytransf_ci: Transferencias de programas sociales ***
	********************************************************
	
	* PNC - Pensiones sociales no contributivas:
			* 1 Pensiones de vejez f125 == 1
	* PTMC - Programas de transferencias monetarias condicionadas:
			* 2 Asignaciones familiares - Plan de Equidad del MIDES g255== 1 
	* POTROT - Programas de otras transferencias monetarias no condicionadas
			* 3 Pensión por invalidez f125==3
			* 4 Pensión a las víctimas de delitos violentos f125== 5
			* 5 Pensión para hijos de fallecidos por violencia doméstica f125== 6
			* 6 Pensión Especial Reparatoria f125== 7
			* 7 Pensión Reparatoria Ley Integral para Personas Trans f125== 8
			* 8 Tarjeta Uruguay Social (TUS) > e584 == 1 (desde el 2024 el monto se reporta junto)
					
	/*Nota: Existe inconsistencias entre los filtros y montos de la seccion de pensiones no	contributivas: f124_2, f125, g_it_2, g148_2*. En la seccion laboral se creó un filtro auxiliar para identificar a las personas que declaran al menos un monto en esta sección.
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
			
		gen byte tus_ci = (e584 == 1) if e584 != 0
				
		gen byte potrot_ci = (inval_ci == 1 | vdelit_ci == 1 | violdom_ci == 1 | pesprep_ci == 1 | petrans_ci == 1 |tus_ci == 1)
		replace potrot_ci = . if inval_ci == . & vdelit_ci == . & violdom_ci == . & pesprep_ci == . & petrans_ci == . & tus_ci == .
		
	*** Montos de transferencias a nivel individual:
	
		// Transferencias PNC
		egen double ypnc_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if pnc_ci == 1, mi
			
		// Transferencias PTMC
		gen double yptmc_ci = g257 if ptmc_ci == 1
		
		// Otras transferencias POTROT
		foreach x in inval vdelit violdom pesprep petrans{
			egen double y`x'_ci = rowtotal(g148_2_1 g148_2_2 g148_2_3) if `x'_ci == 1, mi	
		}
		gen double ytus_ci = e584_1 if tus_ci == 1
			
		egen double yotrot_ci = rowtotal(yinval_ci yvdelit_ci yvioldom_ci ypesprep_ci ypetrans_ci ytus_ci), mi
	
	
	*** Ingreso individual por transferencias no contributivas
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi
	
	******************
	*** remesas_ci ***
	******************
	gen double remesas_ci = .
	
	***************
	*** ypen_ci: Jubilación contributiva ***
	***************
	egen double ypen_ci = rowtotal(g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_10 g148_1_12) if f_jub == 1, mi  // Se excluyen pensiones del exterior (g148_1_11)
	replace ypen_ci = . if pension_ci == .

	******************
	*** ypensub_ci ***
	******************
	gen double ypensub_ci = ypnc_ci
	
	*********
	*** ynlm_ci ***
	*********

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

	**********
	*** ynlnm_ci ***
	**********
	gen double canasta_celi = (e247 * indaceliac) if e246 == 7
	gen double canasta_emer = (e247 * indaemer) if e246 == 14
	egen double ynlnm_ci = rowtotal(canasta_celi canasta_emer), mi

	*********
	*** ytot_ci ***
	*********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
	
	***************
	*** ynet_ci: Ingreso neto individual = Ingreso primario + transferencias privadas ***
	***************
	gen double aux_ytransf_ci = ytransf_ci*(-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
	drop aux_ytransf_ci


*C. INGRESOS DEL HOGAR ***

	**************
	*** ylm_ch ***
	**************
	bysort idh_ch: egen double ylm_ch   = total(ylm_ci)   if miembros_ci == 1, mi
	
	***************
	*** ylnm_ch ***
	****************
	bysort idh_ch: egen double ylnm_ch  = total(ylnm_ci)  if miembros_ci == 1, mi
	
	***************
	* ytransf_ch: Ingresos por Transferencias no contributivas del Hogar ***
	***************
	
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
	gen double  h172_1m =  h172_1/12
	gen double remesas_ch = h172_1m if miembros_ci == 1
	
	***********
	* ynlm_ch *
	***********
	// [Pendiente decisión de agregar: h167_2_3 h167_3_3 h167_4_3]
	foreach i in h160_1 h160_2 h163_1 h163_2 h164 h165 h166 h167_1_3 h170_3 h171_1 h173_1 {
		gen double `i'm = `i'/12  
	}

	egen double otrosing_nlh = rowtotal(h155_1 h160_1m h160_2m h163_1m h163_2m h164m h165m h166m h167_1_3m h170_3m h171_1m h173_1m), mi
	drop  h160_1m h160_2m h163_1m h163_2m h164m h165m h166m h167_1_3m h170_3m h171_1m  h173_1m h172_1m

	bys idh_ch: egen double ing_nlm = total(ynlm_ci) if miembros_ci == 1, mi
	egen double ynlm_ch = rowtotal(ing_nlm otrosing_nlh remesas_ch) if miembros_ci == 1, mi

	***********
	* ynlnm_ch *
	***********
	// Transferencias en especie desde otros hogares (h156_1 a nivel hogar)
	bys idh_ch: egen double ing_nlnm = total(ynlnm_ci) if miembros_ci == 1, mi
	egen double ynlnm_ch = rowtotal(ing_nlnm h156_1) if miembros_ci == 1, mi
	 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci == 1, mi
	
	***************
	*** ynet_ch ***
	***************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	*******************
	*** ylmhopri_ci ***
	*******************
	gen double ylmhopri_ci = ylmpri_ci / horaspri_ci if emp_ci == 1 & horaspri_ci > 0

	****************
	*** ylmho_ci ***
	****************
	gen double ylmho_ci = ylm_ci / horastot_ci if emp_ci == 1 & horastot_ci > 0

	*******************
	*** nrylmpri_ci ***
	*******************
	gen byte nrylmpri_ci = (emp_ci == 1 & ylmpri_ci == .)

	*******************
	*** nrylmpri_ch ***
	*******************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1



****************************
***VARIABLES DE EDUCACION***
****************************

	*********
	*** aedu_ci ***
	*********
	/* Reemplazar 9=inicio año escolar sin aprobados -> 0, e51_2==12 -> 0 */
	foreach v of varlist e51_2 e51_4_a e51_4_b e51_5 e51_6 e51_8 e51_9 e51_10 e51_11 {
		replace `v' = 0 if `v' == 9
	}
	replace e51_2 = 0 if e51_2 == 12

	/* Máximo por nivel (Liceo y UTU mutuamente excluyentes por diseño ECH) */
	egen double mb_años  = rowmax(e51_4_a e51_4_b)
	egen double ms_años  = rowmax(e51_5 e51_6)
	egen double sup_años = rowmax(e51_8 e51_9 e51_10)

	gen double aedu_ci = 0
	foreach v of varlist e51_2 mb_años ms_años sup_años e51_11 {
		replace aedu_ci = aedu_ci + `v' if !missing(`v')
	}
	replace aedu_ci = . if (e51_2 == . & mb_años == . & ms_años == . & sup_años == . & e51_11 == .)
	drop mb_años ms_años sup_años

	**********
	*** eduui_ci ***
	**********
	gen byte eduui_ci = 0
	replace eduui_ci = 1 if e215_1 == 2 & (e218_1 != 1 & e221_1 != 1)
	replace eduui_ci = 1 if e218_1 == 2 & (e215_1 != 1 & e221_1 != 1)
	replace eduui_ci = 1 if e221_1 == 2 & (e215_1 != 1 & e218_1 != 1)

	**********
	*** eduuc_ci ***
	**********
	gen byte eduuc_ci = 0
	replace eduuc_ci = 1 if e215_1 == 1 | e218_1 == 1 | e221_1 == 1

	**********
	*** eduac_ci ***
	**********
	gen byte eduac_ci = .
	replace eduac_ci = 0 if e215_1 == 1 | (e221_1 == 1 & e218_1 != 1)
	replace eduac_ci = 0 if (e215_1 == 2 | e221_1 == 2) & e218_1 == 0
	replace eduac_ci = 1 if e218_1 == 1
	replace eduac_ci = 1 if e218_1 == 2 & (e215_1 != 1 & e221_1 != 1)
	replace eduac_ci = . if aedu_ci == .

	**********
	*** edupre_ci ***
	**********
	gen byte edupre_ci = .

	***********
	*** asispre_ci ***
	***********
	/* _e579_n = real(e579): 13=infancia 0-2, 14=inicial 3-5 */
	gen byte asispre_ci = .
	replace asispre_ci = 1 if _e579_n == 13 | _e579_n == 14
	replace asispre_ci = 0 if asispre_ci == . & e579 != ""

	***********
	*** asiste_ci ***
	***********
	gen byte asiste_ci = (e49 == 3)

	*****************
	*** razonesnoasis_ci ***
	*****************
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(e202, 7, 9)
	replace razonesnoasis_ci = 2 if inlist(e202, 1, 2, 5)
	replace razonesnoasis_ci = 3 if inlist(e202, 8, 10, 11)
	replace razonesnoasis_ci = 4 if inlist(e202, 3, 4, 6)
	replace razonesnoasis_ci = . if asiste_ci == 1

	**********
	*** edupub_ci ***
	**********
	gen byte edupub_ci = . if asiste_ci != 1
	replace edupub_ci = 1 if (_e581_n == 1 | _e581a_n == 1) & asiste_ci == 1
	replace edupub_ci = 0 if (_e581_n == 2 | _e581_n == 3 | _e581a_n == 2) & asiste_ci == 1

	drop _e579_n _e581_n _e581a_n


****************************
***VARIABLES DE VIVIENDA ***
****************************

	*******
	*** luz_ch ***
	*******
	gen byte luz_ch = .
	replace luz_ch = 0 if d18 > 1 & d18 < 5
	replace luz_ch = 1 if d18 == 1

	**********
	*** luzmide_ch ***
	**********
	gen byte luzmide_ch = .

	**********
	*** combust_ch ***
	**********
	gen byte combust_ch = .
	replace combust_ch = 1 if d20 == 1 | d20 == 2 | d20 == 3 | d20 == 4
	replace combust_ch = 0 if d20 == 5 | d20 == 6 | d20 == 7

	***************
	*** piso_ch ***
	***************
	/* CREAR VACÍO - metodología en revisión (manual oct 2025) */
	gen piso_ch  = .

	****************
	*** pared_ch ***
	****************
	/* CREAR VACÍO - metodología en revisión (manual oct 2025) */
	gen pared_ch = .

	****************
	*** techo_ch ***
	****************
	/* CREAR VACÍO - metodología en revisión (manual oct 2025) */
	gen techo_ch = .

	****************
	*** resid_ch ***
	*********
	gen byte resid_ch = .

	**********************
	*** dorm_ch / cuartos_ch ***
	**********************
	gen byte dorm_ch = d10
	gen byte cuartos_ch = d9

	**********
	*** cocina_ch ***
	**********
	gen byte cocina_ch = .
	replace cocina_ch = 1 if d19 == 1 | d19 == 2
	replace cocina_ch = 0 if d19 == 3

	*********
	*** telef_ch ***
	*********
	gen byte telef_ch = (d21_17 == 1)
	replace telef_ch = . if d21_17 == .

	**********
	*** refrig_ch ***
	**********
	gen byte refrig_ch = (d21_3 == 1)
	replace refrig_ch = . if d21_3 == .

	*********
	*** freez_ch ***
	*********
	gen byte freez_ch = .

	*******
	*** auto_ch ***
	*******
	gen byte auto_ch = (d21_18 == 1)
	replace auto_ch = . if d21_18 == .

	*******
	*** compu_ch ***
	*******
	gen byte compu_ch = (d21_15 == 1)
	replace compu_ch = . if d21_15 == .

	*******************
	*** internet_ch ***
	*******************
	gen byte internet_ch = (d21_16 == 1)
	replace internet_ch = . if d21_16 == .

	**************
	*** cel_ch ***
	**************
	gen byte cel_ch = .

	****************
	*** vivi1_ch ***
	****************
	/* c1: 1=casa, 2=apart/casa complejo, 3=apart altura, 4=apt una planta, 5=local */
	gen vivi1_ch=.
	replace vivi1_ch=1 if (c1 == 1)	
	replace vivi1_ch = 2 if (c1 == 3 | c1 == 4)
	replace vivi1_ch = 3 if (c1 == 2 | c1 == 5)

	****************
	*** vivi2_ch ***
	****************
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if vivi1_ch == 1 | vivi1_ch == 2
	replace vivi2_ch = 0 if vivi1_ch == 3

	*******************
	*** viviprop_ch ***
	*******************
	gen byte viviprop_ch = .
	replace viviprop_ch = 0 if d8_1 == 5
	replace viviprop_ch = 1 if d8_1 == 2 | d8_1 == 4
	replace viviprop_ch = 2 if d8_1 == 1 | d8_1 == 3
	replace viviprop_ch = 3 if d8_1 >= 6 & d8_1 <= 9 & d8_1 != .

	******************
	*** vivitit_ch ***
	******************
	gen byte vivitit_ch = .

	******************
	*** vivialq_ch ***
	******************
	gen double vivialq_ch    = d8_3 if viviprop_ch == 0

	**********************
	*** vivialqprop_ch ***
	**********************
	gen double vivialqimp_ch = d8_3 if viviprop_ch != 0 & viviprop_ch != .


****************************
***VARIABLES DE WASH***
****************************

	**********
	*** aguared_ch ***
	**********
	gen byte aguared_ch = (d11 == 1)
	replace aguared_ch = . if d11 == .

	****************
	*** aguafconsumo_ch ***
	****************
	gen byte aguafconsumo_ch = .
	replace aguafconsumo_ch = 1  if d11 == 1
	replace aguafconsumo_ch = 4  if d11 == 3
	replace aguafconsumo_ch = 8  if d11 == 5
	replace aguafconsumo_ch = 9  if d11 == 2
	replace aguafconsumo_ch = 10 if d11 == 4 | d11 == 6


	**************
	*** aguafuente_ch ***
	**************
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1  if d11 == 1
	replace aguafuente_ch = 4  if d11 == 3
	replace aguafuente_ch = 8  if d11 == 5
	replace aguafuente_ch = 9  if d11 == 2
	replace aguafuente_ch = 10 if d11 == 4 | d11 == 6

	**************
	*** aguadist_ch ***
	**************
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if d12 == 1
	replace aguadist_ch = 2 if d12 == 2
	replace aguadist_ch = 3 if d12 == 3
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch != .

	********************
	*** aguadisp1_ch ***
	********************
	gen byte aguadisp1_ch = 9

	********************
	*** aguadisp2_ch ***
	********************
	gen byte aguadisp2_ch = 9

	********************
	*** aguadisp3_ch ***
	********************
	gen byte aguatrat_ch  = 9

	*******************
	*** aguamala_ch ***
	*******************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	*******************
	*** aguamejorada_ch ***
	*******************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	**********
	*** aguamide_ch ***
	**********
	gen byte aguamide_ch = .

	*******
	*** bano_ch ***
	*******
	/* d16 = evacuación: 1=red, 2=fosa/pozo, 3=entubado arroyo, 4=otro */
	gen byte bano_ch = 0
	replace bano_ch = 1 if d16 == 1
	replace bano_ch = 2 if d16 == 2
	replace bano_ch = 4 if d16 == 3
	replace bano_ch = 6 if d16 == 4

	*********
	*** banoex_ch ***
	*********
	gen byte banoex_ch = .
	replace banoex_ch = 1 if d15 == 1
	replace banoex_ch = 0 if d15 == 2

	**********
	*** sinbano_ch ***
	**********
	gen byte sinbano_ch = .
	replace sinbano_ch = 0 if d14 > 0 & d14 != .
	replace sinbano_ch = 3 if d13 == 3

	***************
	*** banomejorado_ch ***
	***************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6


****************************
***VARIABLES DE MIGRACIÓN***
****************************

	***********
	*** migrante_ci ***
	***********
	gen byte migrante_ci = 0
	replace migrante_ci = 1 if e37 == 4

	*****************
	*** migrantiguo5_ci ***
	*****************
	gen byte migrantiguo5_ci = .
	replace migrantiguo5_ci = 1 if migrante_ci == 1 & e38_1 >= 5 & e38_1 != .
	replace migrantiguo5_ci = 1 if migrante_ci == 1 & (e236 == 1 | e236 == 2 | e236 == 3)
	replace migrantiguo5_ci = 0 if migrante_ci == 1 & e236 == 4

	*********
	*** miglac_ci ***
	*********
	gen byte miglac_ci = .
	replace miglac_ci = 0 if migrante_ci == 1
	replace miglac_ci = 1 if migrante_ci == 1 & inlist(e234_2, 660, 28, 32, 533, 44, 52, 84, 68, 76, 152, 170, 188, 192, 531, 212, ///
	                                                     218, 222, 320, 254, 328, 332, 340, 136, 796, 92, 388, 484, 558, 591, ///
	                                                     600, 604, 214, 659, 658, 534, 670, 662, 740, 780, 862)


****************************
***VARIABLES EXTERNAS***
****************************

	*****************
	*** tipo_bienestar ***
	*****************
	gen byte tipo_bienestar = 1

	***************
	*** pobre_ine_ci ***
	***************
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci = 0 if pobre17 == 0
	replace pobre_ine_ci = 1 if pobre17 == 1

	**********************
	*** bienestar_agregado ***
	**********************
	/* ht11 eliminado en 2025, yda_svl_rraa corresponde a ingreso disponible ajustado https://www5.ine.gub.uy/documents/Demograf%C3%ADayEESS/HTML/ECH/Pobreza/2025/Informe%20distribuci%C3%B3n%20del%20ingreso%20A%C3%B1o%202025.html*/
	gen double bienestar_agregado = yda_svl_rraa

	**************
	*** lpe_ci ***
	**************
	gen double lpe_ci = li_17

	*************
	*** ln_ci ***
	*************
	gen double ln_ci  = lp_17

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
	  /// Agregar aquí: ISO3pais_dis_ci (renombrar con código del país, ej. COL_dis_ci)
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	/// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci /// Ingresos individuo
     ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




save "`base_out'", replace

cap log close
