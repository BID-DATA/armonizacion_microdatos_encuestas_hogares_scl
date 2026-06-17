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

local PAIS     PER
local ENCUESTA ENAHO
local ANO      2025
local ronda    a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: PER
Encuesta: ENAHO
Round: a
Autores: Matías Isla y Matias Rodriguez (SCL/SCL)
Version: 27/05/2026
Mail: matiasi@iadb.org/mrodriguezm@iadb.org, 27 de mayo de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use "`base_in'", clear

********************************************************************************
**************   VARIABLES DE IDENTIFICACIÓN   *********************************
********************************************************************************

	********************
	*** region_BID_c ***
	********************
	gen byte region_BID_c = 3

	********************
	*** region_c      ***
	********************
	gen byte region_c = real(substr(ubigeo, 1, 2))

	********************
	*** pais_c        ***
	********************
	gen str3 pais_c = "PER"

	********************
	*** anio_c        ***
	********************
	gen int anio_c = 2025

	********************
	*** mes_c         ***
	********************
	gen int mes_c = real(mes)
	assert inrange(mes_c, 1, 12) if mes_c != .

	********************
	*** zona_c        ***
	********************
	gen byte zona_c = 0 if estrato >= 6   /* Rural */
	replace  zona_c = 1 if estrato < 6   /* Urbano */

	********************
	*** estrato_ci    ***
	********************
	gen estrato_ci = estrato

	********************
	*** upm_ci        ***
	********************
	gen upm_ci = conglome

	********************
	*** idh_ch        ***
	********************
	sort conglome vivienda hogar
	cap egen idh_ch = group(conglome vivienda hogar)
	tostring idh_ch, replace

	********************
	*** idp_ci        ***
	********************
	gen idp_ci = codperso
	tostring idp_ci, replace format("%20.0f")

	********************
	*** factor_ch     ***
	********************
	gen factor_ch = factor07

	********************
	*** factor_ci     ***
	********************
	gen factor_ci = facpob07

********************************************************************************
**************   VARIABLES DEMOGRÁFICAS   **************************************
********************************************************************************

	********************
	*** sexo_ci       ***
	********************
	gen byte sexo_ci = p207 /* 1=hombre, 2=mujer */

	********************
	*** edad_ci       ***
	********************
	gen int edad_ci = p208a
	replace edad_ci = . if edad_ci == 99

	********************
	*** relacion_ci   ***
	********************
	/*
	p203: 0=panel, 1=jefe, 2=esposo/a, 3=hijo/a, 4=yerno/nuera, 5=nieto,
	      6=padres/suegros, 7=otros parientes, 8=trab.hogar, 9=pensionista,
	      10=otros no parientes, 11=hermano/a
	BID:  1=jefe, 2=cónyuge, 3=hijo, 4=otro pariente, 5=no pariente, 6=emp.doméstico
	*/
	gen byte relacion_ci = .
	replace relacion_ci = 1 if p203 == 1
	replace relacion_ci = 2 if p203 == 2
	replace relacion_ci = 3 if p203 == 3
	replace relacion_ci = 4 if inlist(p203, 4, 5, 6, 7, 11)
	replace relacion_ci = 5 if inlist(p203, 9, 10)
	replace relacion_ci = 6 if p203 == 8

	********************
	*** miembros_ci   ***
	********************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace  miembros_ci = . if relacion_ci == .

	********************
	*** miembros_one_ci ***
	********************
	gen byte miembros_one_ci = (p204 == 1)
	replace  miembros_one_ci = . if p204 == .

	********************
	*** civil_ci      ***
	********************
	/*
	p209: 1=conviviente, 2=casado, 3=viudo, 4=divorciado, 5=separado, 6=soltero
	BID:  1=soltero, 2=unión formal/informal, 3=divorciado/separado, 4=viudo
	*/
	gen byte civil_ci = .
	replace civil_ci = 1 if p209 == 6
	replace civil_ci = 2 if inlist(p209, 1, 2)
	replace civil_ci = 3 if inlist(p209, 4, 5)
	replace civil_ci = 4 if p209 == 3

	********************
	*** jefe_ci       ***
	********************
	gen byte jefe_ci = .
	replace jefe_ci = 1 if relacion_ci == 1
	replace jefe_ci = 0 if relacion_ci != 1 & relacion_ci != .

	by idh_ch, sort: egen byte nconyuges_ch = sum(relacion_ci == 2)
	replace nconyuges_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)
	replace nhijos_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)
	replace notropari_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	replace notronopari_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)
	replace nempdom_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci <= 5)
	replace nmiembros_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))
	by idh_ch, sort: egen byte nmenor6_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))
	by idh_ch, sort: egen byte nmenor1_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))

	********************
	*** clasehog_ch   ***
	********************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0


********************************************************************************
**************   VARIABLES DE DIVERSIDAD   *************************************
********************************************************************************

	********************
	*** afro_ci       ***
	********************
	/*
	p558c: autoidentificación étnico-racial
	  1=quechua, 2=aymara, 3=amazónico, 4=negro/afrodescendiente, 5=blanco,
	  6=mestizo, 7=otro, 8=no sabe, 9=otro indígena
	*/
	gen byte afro_ci = .
	replace afro_ci = 1 if p558c == 4
	replace afro_ci = 0 if inlist(p558c, 1, 2, 3, 5, 6, 7, 9)
	/* p558c==8 (no sabe) queda missing */

	********************
	*** ind_ci        ***
	********************
	gen byte ind_ci = .
	replace ind_ci = 1 if inlist(p558c, 1, 2, 3, 9)
	replace ind_ci = 0 if inlist(p558c, 4, 5, 6, 7)
	/* p558c==8 (no sabe) queda missing */

	********************
	*** noafroind_ci  ***
	********************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)

	********************
	*** afroind_ci    ***
	********************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	********************
	*** afroind_ano_c ***
	********************
	gen int afroind_ano_c = 2017
	
	***************
	*** afro_ch ***
	***************
	gen afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe
	
	**************
	*** ind_ch ***
	**************
	gen ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe
	
	********************
	*** noafroind_ch ***
	********************
	gen noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe
	
	******************
	*** afroind_ch ***
	******************
	gen afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	********************
	*** dis_ci        ***
	********************
	gen byte dis_ci = .
	replace dis_ci = 1 if (p401h1 == 1 | p401h2 == 1 | p401h3 == 1 | p401h4 == 1 | p401h5 == 1)
	replace dis_ci = 0 if (p401h1 == 2 & p401h2 == 2 & p401h3 == 2 & p401h4 == 2 & p401h5 == 2)

	********************
	*** disWG_ci      ***
	********************
	gen disWG_ci = . /* ENAHO solo tiene pregunta de limitación permanente binaria (no WG estricto) */

	********************
	*** dis_ch        ***
	********************
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	********************
	*** ISO3pais_dis_ci ***
	********************
	gen PER_dis_ci = dis_ci


********************************************************************************
**************   VARIABLES DE MERCADO LABORAL   ********************************
********************************************************************************

	********************
	*** condocup_ci   ***
	********************
	/*
	p501: ¿Tuvo algún trabajo la semana pasada?
	p502: ¿Tiene empleo fijo al que volverá?
	p503: ¿Tiene negocio propio al que volverá?
	p5041-p50411: actividades de búsqueda
	*/
	gen byte condocup_ci = .
	replace condocup_ci = 1 if p501 == 1 | p502 == 1 | p503 == 1   /* ocupado */
	replace condocup_ci = 2 if p501 == 2 & p502 == 2 & p503 == 2   /* desocupado si buscó trabajo */
	replace condocup_ci = 3 if condocup_ci == 2 & ///
		(p5041 == 2 & p5042 == 2 & p5043 == 2 & p5044 == 2 & p5045 == 2 & ///
		 p5046 == 2 & p5047 == 2 & p5048 == 2 & p5049 == 2 & p50410 == 2 & p50411 == 2)
	replace condocup_ci = 4 if edad_ci < 14   /* menores fuera de PET, encuesta aplica módulo 500 a 14+ */

	********************
	*** categoinac_ci ***
	********************
	/*
	p546: ¿qué hacía la semana pasada? 4=estudia, 5=quehaceres, 6=jubilado, otros
	BID: 1=jubilado/pensionado, 2=estudiante, 3=quehaceres, 4=otros
	*/
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if p546 == 6 & condocup_ci == 3
	replace categoinac_ci = 2 if p546 == 4 & condocup_ci == 3
	replace categoinac_ci = 3 if p546 == 5 & condocup_ci == 3
	replace categoinac_ci = 4 if (categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3

	********************
	*** emp_ci        ***
	********************
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)

	********************
	*** desemp_ci     ***
	********************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)

	********************
	*** pea_ci        ***
	********************
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	********************
	*** cesante_ci    ***
	********************
	/* p552: ¿Ha trabajado antes? 1=sí, 2=no */
	gen byte cesante_ci = .
	replace cesante_ci = 1 if p552 == 1 & condocup_ci == 2
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci == 2

	********************
	*** subemp_ci     ***
	********************
	gen byte _hpri_tmp = p513t
	replace  _hpri_tmp = . if emp_ci != 1
	gen byte subemp_ci = 0
	replace  subemp_ci = 1 if _hpri_tmp <= 30 & p521 == 1 & p521a == 1 & emp_ci == 1
	replace  subemp_ci = . if condocup_ci != 1
	drop _hpri_tmp

	********************
	*** durades_ci    ***
	********************
	gen durades_ci = p551 / 4.3
	replace durades_ci = . if condocup_ci == 1

	********************
	*** nempleos_ci   ***
	********************
	gen byte nempleos_ci = .
	replace  nempleos_ci = 1 if emp_ci == 1
	replace  nempleos_ci = 2 if emp_ci == 1 & p514 == 1
	replace  nempleos_ci = 2 if emp_ci == 1 & p514 == 2 & ///
		(p5151 == 1 | p5152 == 1 | p5153 == 1 | p5154 == 1 | p5155 == 1 | ///
		 p5156 == 1 | p5157 == 1 | p5158 == 1 | p5159 == 1 | p51510 == 1 | p51511 == 1)

	********************
	*** antiguedad_ci ***
	********************
	/* p513a1=años + p513a2=meses en ocupación principal, <12 meses - 0 años */
	gen _anios_a = p513a1
	gen _meses_a = p513a2 / 12
	egen byte antiguedad_ci = rsum(_anios_a _meses_a) if emp_ci == 1
	replace   antiguedad_ci = 0 if antiguedad_ci <= 1 & emp_ci == 1
	replace   antiguedad_ci = . if _anios_a == . & _meses_a == . & emp_ci == 1
	drop _anios_a _meses_a

	********************
	*** desalent_ci   ***
	********************
	/* p545: buscó trabajo, p549: razón no buscó (1=no hay, 2=cansado) */
	gen byte desalent_ci = .
	replace desalent_ci = 1 if condocup_ci == 3 & p545 == 2 & inlist(p549, 1, 2)
	replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .

	********************
	*** horaspri_ci   ***
	********************
	gen byte horaspri_ci = .
	replace  horaspri_ci = p513t if emp_ci == 1

	********************
	*** horastot_ci   ***
	********************
	/* p518: horas en ocupaciones secundarias */
	egen horastot_ci = rsum(horaspri_ci p518) if emp_ci == 1
	replace horastot_ci = . if emp_ci != 1

	********************
	*** tiempoparc_ci ***
	********************
	/* <30 horas y NO quería más (p521==2) */
	gen byte tiempoparc_ci = .
	replace tiempoparc_ci = (horaspri_ci < 30 & p521 == 2) if condocup_ci == 1

	********************
	*** categopri_ci  ***
	********************
	/*
	p507: 1=empleador, 2=independiente, 3=empleado, 4=obrero, 5=fam.no rem., 6=trab.hogar, 7=otro
	BID:  0=otra, 1=patrón, 2=cuenta propia, 3=asalariado, 4=no remunerado
	*/
	gen byte categopri_ci = .
	replace categopri_ci = 0 if condocup_ci == 1 & p507 == 7
	replace categopri_ci = 1 if condocup_ci == 1 & p507 == 1
	replace categopri_ci = 2 if condocup_ci == 1 & p507 == 2
	replace categopri_ci = 3 if condocup_ci == 1 & inlist(p507, 3, 4, 6)
	replace categopri_ci = 4 if condocup_ci == 1 & p507 == 5
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1

	********************
	*** categosec_ci  ***
	********************
	/*
	p517: misma estructura que p507 para ocupación secundaria
	*/
	gen byte categosec_ci = .
	replace categosec_ci = 0 if condocup_ci == 1 & p517 == 7
	replace categosec_ci = 1 if condocup_ci == 1 & p517 == 1
	replace categosec_ci = 2 if condocup_ci == 1 & p517 == 2
	replace categosec_ci = 3 if condocup_ci == 1 & inlist(p517, 3, 4, 6)
	replace categosec_ci = 4 if condocup_ci == 1 & p517 == 5

	********************
	*** rama_ci       ***
	********************
	/* p506: CIIU Rev. 3/4 a 4 dígitos */
	gen byte rama_ci = .
	replace rama_ci = 1 if (p506 >= 111 & p506 <= 502) & emp_ci == 1
	replace rama_ci = 2 if (p506 >= 1010 & p506 <= 1429) & emp_ci == 1
	replace rama_ci = 3 if (p506 >= 1511 & p506 <= 3720) & emp_ci == 1
	replace rama_ci = 4 if (p506 >= 4010 & p506 <= 4100) & emp_ci == 1
	replace rama_ci = 5 if (p506 >= 4510 & p506 <= 4550) & emp_ci == 1
	replace rama_ci = 6 if (p506 >= 5010 & p506 <= 5520) & emp_ci == 1
	replace rama_ci = 7 if (p506 >= 6010 & p506 <= 6420) & emp_ci == 1
	replace rama_ci = 8 if (p506 >= 6511 & p506 <= 7020) & emp_ci == 1
	replace rama_ci = 9 if (p506 >= 7111 & p506 <= 9900) & emp_ci == 1

	********************
	*** spublico_ci   ***
	********************
	/* p510: 1=FFAA/PNP, 2=Adm.pública, 3=empresa pública - sector público */
	gen byte spublico_ci = .
	replace spublico_ci = (p510 == 1 | p510 == 2 | p510 == 3) if emp_ci == 1

	********************
	*** tamemp_ci     ***
	********************
	/* p512b: número de personas en empresa */
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if p512b >= 1 & p512b <= 5 & p512b != .   /* pequeña */
	replace tamemp_ci = 2 if p512b >= 6 & p512b <= 50 & p512b != .   /* mediana */
	replace tamemp_ci = 3 if p512b >= 51 & p512b < 9998 & p512b != .   /* grande */
	replace tamemp_ci = . if categopri_ci == 4   /* trabajadores no remunerados */

	********************
	*** cotizando_ci  ***
	********************
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if (p558a1 == 1 | p558a2 == 2 | p558a3 == 3 | p558a4 == 4) & p558b2 == 2025 & emp_ci == 1
	replace cotizando_ci = 0 if inlist(condocup_ci, 1, 2) & cotizando_ci == .

	********************
	*** instcot_ci    ***
	********************
	/* AFP=1, ONP (Ley 19990=p558a2==2, Ley 20530=p558a3==3) instcot=2 */
	gen byte instcot_ci = .
	replace instcot_ci = 1 if p558a1 == 1
	replace instcot_ci = 2 if p558a2 == 2 | p558a3 == 3

	********************
	*** afiliado_ci   ***
	********************
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if (p558a1 == 1 | p558a2 == 2 | p558a3 == 3 | p558a4 == 4) & emp_ci == 1
	replace afiliado_ci = 0 if inlist(condocup_ci, 1, 2) & afiliado_ci == .

	********************
	*** formal_ci     ***
	********************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & inlist(condocup_ci, 1, 2)

	********************
	*** tipocontrato_ci ***
	********************
	/*
	p511a: 1=indefinido/nombrado, 2=plazo fijo, 3=prueba, 4=juvenil/prácticas,
	       5=honorarios, 6=CAS, 7=sin contrato, 8=otro
	BID: 1=permanente, 2=temporal, 3=sin contrato
	*/
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if p511a == 1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if inrange(p511a, 2, 6) & categopri_ci == 3
	replace tipocontrato_ci = 3 if (p511a == 7 | tipocontrato_ci == .) & categopri_ci == 3

	********************
	*** ocupa_ci      ***
	********************
	/* p505: CIUO-88 a 3 dígitos */
	gen byte ocupa_ci = .
	replace ocupa_ci = 1 if inrange(p505, 211, 396) & emp_ci == 1
	replace ocupa_ci = 2 if inrange(p505, 111, 148) & emp_ci == 1
	replace ocupa_ci = 3 if inrange(p505, 411, 462) & emp_ci == 1
	replace ocupa_ci = 4 if (inrange(p505, 571, 583) | inrange(p505, 911, 931)) & emp_ci == 1
	replace ocupa_ci = 5 if (inrange(p505, 511, 565) | inrange(p505, 941, 961)) & emp_ci == 1
	replace ocupa_ci = 6 if (inrange(p505, 611, 641) | inrange(p505, 971, 973)) & emp_ci == 1
	replace ocupa_ci = 7 if (inrange(p505, 711, 886) | inrange(p505, 981, 987)) & emp_ci == 1
	replace ocupa_ci = 8 if inrange(p505, 11, 24) & emp_ci == 1


********************************************************************************
**************   PENSIONES   ***************************************************
********************************************************************************

	********************
	*** ypen_ci       ***
	********************
	/*
	d5564c: pensión jubilación/cesantía (anual, moneda local) - /12
	p5565c: pensión viudez/orfandad (monto) — convertir a mensual por p5565b
	*/
	gen double _pjub = d5564c / 12

	gen double _pviudz = .
	replace _pviudz = p5565c * 30 if p5565b == 1   /* diario - mensual */
	replace _pviudz = p5565c * 4.3 if p5565b == 2   /* semanal - mensual */
	replace _pviudz = p5565c * 2 if p5565b == 3   /* quincenal - mensual */
	replace _pviudz = p5565c if p5565b == 4   /* mensual */
	replace _pviudz = p5565c / 2 if p5565b == 5   /* bimestral - mensual */
	replace _pviudz = p5565c / 3 if p5565b == 6   /* trimestral - mensual */
	replace _pviudz = p5565c / 6 if p5565b == 7   /* semestral - mensual */
	replace _pviudz = p5565c / 12 if p5565b == 8   /* anual - mensual */
	replace _pviudz = . if p5565c == 999999

	egen double ypen_ci = rsum(_pjub _pviudz), missing
	replace ypen_ci = . if _pjub == . & _pviudz == .
	drop _pjub _pviudz

	********************
	*** pension_ci    ***
	********************
	gen byte pension_ci = .
	replace pension_ci = 1 if ypen_ci > 0 & ypen_ci != .
	replace pension_ci = 0 if ypen_ci == . | ypen_ci == 0

	********************
	*** ypensub_ci    ***
	********************
	/* ingtpu03: Pensión 65 (anualizado) - /12 */
	gen double ypensub_ci = ingtpu03 / 12

	********************
	*** pensionsub_ci ***
	********************
	gen byte pensionsub_ci = (ingtpu03 > 0 & ingtpu03 != .)

	********************
	*** tipopen_ci    ***
	********************
	gen tipopen_ci = .   /* no existe pregunta directa en ENAHO */

	********************
	*** instpen_ci    ***
	********************
	gen instpen_ci = .   /* no existe variable original directa */


********************************************************************************
**************   INGRESOS   ****************************************************
********************************************************************************

	********************
	*** ylmpri_ci     ***
	********************
	/*
	i524e1: ingreso líquido empleo principal dependiente (anual) - /12
	i530a:  ganancia neta independiente (anualizado) - /12
	*/
	gen double _ylmprid = i524e1 / 12
	gen double _ylmprii = i530a / 12
	egen double ylmpri_ci = rsum(_ylmprid _ylmprii), missing
	drop _ylmprid _ylmprii

	********************
	*** ylnmpri_ci    ***
	********************
	/*
	d529t: pago en especie empleo principal dependiente (anual) - /12
	d536:  autoconsumo independiente - /12
	*/
	gen double _ylnmprid = d529t / 12
	gen double _ylnmprii = d536 / 12
	egen double ylnmpri_ci = rsum(_ylnmprid _ylnmprii), missing
	drop _ylnmprid _ylnmprii

	********************
	*** ylmsec_ci     ***
	********************
	/*
	i538e1: ingreso líquido empleo secundario dependiente (anual) - /12
	i541a:  ganancia neta secundaria independiente (anualizado) - /12
	*/
	gen double _ylmsecd = i538e1 / 12
	gen double _ylmseci = i541a / 12
	egen double ylmsec_ci = rsum(_ylmsecd _ylmseci), missing
	drop _ylmsecd _ylmseci

	********************
	*** ylnmsec_ci    ***
	********************
	/*
	d540t: pago en especie secundaria (anual) - /12
	d543:  autoconsumo secundaria - /12
	*/
	gen double _ylnmsecd = d540t / 12
	gen double _ylnmseci = d543 / 12
	egen double ylnmsec_ci = rsum(_ylnmsecd _ylnmseci), missing
	drop _ylnmsecd _ylnmseci

	********************
	*** ylmotros_ci   ***
	********************
	/* d544t: ingresos extraordinarios (anual) - /12 */
	gen double ylmotros_ci = d544t / 12

	********************
	*** ylnmotros_ci  ***
	********************
	gen ylnmotros_ci = .   /* no disponible en ENAHO para otras actividades */

	*********
	*** ylm_ci ***
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	
	*********
	*** ylnm_ci ***
	*********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing

	********************
	*** ynlm_ci       ***
	********************
	/*
	d556t1: transferencias corrientes nacionales (6m, anualizado) - /12
	d556t2: transferencias corrientes extranjeras (6m, anualizado) - /12
	d557t:  rentas de propiedad (12m) - /12
	d558t:  otros ingresos extraordinarios (12m) - /12
	*/
	gen double _trans_loc = d556t1 / 12
	gen double _trans_ext = d556t2 / 12
	gen double _rentas = d557t / 12
	gen double _otros_ing = d558t / 12
	egen double ynlm_ci = rowtotal(_trans_loc _trans_ext _rentas _otros_ing), missing
	drop _trans_loc _trans_ext _rentas _otros_ing

	********************
	*** ynlnm_ci      ***
	********************
	/* bienes y servicios no monetarios del hogar — módulos 612 y afines, /12/nmiembros_ch */
	gen double ynlnm_ci = (ig06hd + ig08hd + sig24 + sig26 + ///
		gru13hd1 + gru13hd2 + gru13hd3 + ///
		gru23hd1 + gru23hd2 + gru23hd3 + gru24hd + ///
		gru33hd1 + gru33hd2 + gru33hd3 + (gru34hd - ga04hd) + ///
		gru43hd1 + gru43hd2 + gru43hd3 + gru44hd + ///
		gru53hd1 + gru53hd2 + gru53hd3 + gru54hd + ///
		gru63hd1 + gru63hd2 + gru63hd3 + gru64hd + ///
		gru73hd1 + gru73hd2 + gru73hd3 + gru74hd + ///
		gru83hd1 + gru83hd2 + gru83hd3 + gru84hd + ///
		gru14hd3 + gru14hd4 + gru14hd5 + ///
		sg42d + sg42d1 + sg42d2 + sg42d3) / (12 * nmiembros_ch)

	********************
	*** ytot_ci       ***
	********************
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, missing
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, missing
	bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, missing
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, missing
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), missing

	********************
	*** ylmhopri_ci   ***
	********************
	gen double ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci) if horaspri_ci > 0 & emp_ci == 1
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	********************
	*** ylmho_ci      ***
	********************
	gen double ylmho_ci = ylm_ci / (4.3 * horastot_ci) if horastot_ci > 0 & emp_ci == 1
	replace ylmho_ci = . if ylmho_ci <= 0

	********************
	*** nrylmpri_ci   ***
	********************
	gen byte nrylmpri_ci = .
	replace  nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace  nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1

	********************
	*** nrylmpri_ch   ***
	********************
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci == 1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .

	********************
	*** remesas_ci    ***
	********************
	/*
	d5563c: remesas nacionales (anualizado) - /12
	d5563e: remesas extranjeras (anualizado) - /12
	*/
	gen double _rem_loc = d5563c / 12
	gen double _rem_ext = d5563e / 12
	egen double remesas_ci = rowtotal(_rem_loc _rem_ext), missing
	drop _rem_loc _rem_ext

	********************
	*** remesas_ch    ***
	********************
	by idh_ch, sort: egen double remesas_ch = sum(remesas_ci) if miembros_ci == 1



********************************************************************************
**************   EDUCACIÓN   ***************************************************
********************************************************************************

	********************
	*** aedu_ci       ***
	********************
	/*
	p301a: nivel más alto alcanzado
	  1=sin nivel, 2=inicial, 3=prim.incomp, 4=prim.comp, 5=sec.incomp, 6=sec.comp,
	  7=sup.no.univ.incomp, 8=sup.no.univ.comp, 9=sup.univ.incomp, 10=sup.univ.comp,
	  11=maestría/doctorado, 12=básica especial (- missing)

    En el caso de superior no universitaria (8 y 9), los programas pueden durar entre 3 y 5 años. Se recomienda utilizar el total de básica (11) + la cantidad de años que reporta para ese nivel (grados)
	*/
	egen double grados = rowtotal(p301b p301c), missing

	gen byte aedu_ci = .
	replace aedu_ci = 0 if inlist(p301a, 1, 2)
	replace aedu_ci = grados if p301a == 3
	replace aedu_ci = 6 if p301a == 4
	replace aedu_ci = 6 + grados if p301a == 5
	replace aedu_ci = 11 if p301a == 6
	replace aedu_ci = 11 + grados if p301a == 7
	replace aedu_ci = 11 + grados if p301a == 8 
	replace aedu_ci = 11 + grados if p301a == 9
	replace aedu_ci = 16 if p301a == 10
	replace aedu_ci = 16 + grados if p301a == 11
	/* p301a==12 (básica especial), missing intencional */
	drop grados

	********************
	*** edupre_ci     ***
	********************
	gen edupre_ci = .   /* no puede distinguirse en ENAHO */

	********************
	*** eduui_ci      ***
	********************
	/* técnica o universitaria incompleta */
	gen byte eduui_ci = inlist(p301a, 7, 9)
	replace  eduui_ci = . if aedu_ci == .

	********************
	*** eduuc_ci      ***
	********************
	/* técnica o universitaria completa, o posgrado */
	gen byte eduuc_ci = inlist(p301a, 8, 10, 11)
	replace  eduuc_ci = . if aedu_ci == .

	********************
	*** eduac_ci      ***
	********************
	/* 1=univ o posgrado, 0=técnica */
	gen byte eduac_ci = .
	replace eduac_ci = 1 if inlist(p301a, 9, 10, 11)
	replace eduac_ci = 0 if inlist(p301a, 7, 8)

	********************
	*** asiste_ci     ***
	********************
	gen byte asiste_ci = (p306 == 1)
	replace  asiste_ci = 0 if p307 == 2 & p313 != 6

	********************
	*** edupub_ci     ***
	********************
	/* solo asistentes activos (asiste_ci==1) */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if p308d == 1 & asiste_ci == 1
	replace edupub_ci = 0 if p308d == 2 & asiste_ci == 1

	********************
	*** razonesnoasis_ci ***
	********************
	/*
	p313: 1=problemas eco, 2=trabajo, 4=edad, 5=familia, 7=sin centro, 9=no interés,
	      10=quehaceres, 11=otra
	BID: 1=económico/trabajo, 2=falta interés, 3=quehaceres/salud, 4=acceso, 5=otros
	*/
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(p313, 1, 2)
	replace razonesnoasis_ci = 2 if p313 == 9
	replace razonesnoasis_ci = 3 if inlist(p313, 5, 10)
	replace razonesnoasis_ci = 4 if inlist(p313, 4, 7)
	replace razonesnoasis_ci = 5 if p313 == 11
	replace razonesnoasis_ci = . if asiste_ci == 1

	********************
	*** asispre_ci    ***
	********************
	gen byte asispre_ci = (p308a == 1)
	replace  asispre_ci = 0 if p307 == 2 & p313 != 6


********************************************************************************
**************   VIVIENDA   ****************************************************
********************************************************************************

	********************
	*** luz_ch        ***
	********************
	gen byte luz_ch = p1121   /* fuente de iluminación principal */

	********************
	*** luzmide_ch    ***
	********************
	gen byte luzmide_ch = .
	replace  luzmide_ch = 1 if inlist(p112a, 1, 2)   /* con medidor */
	replace  luzmide_ch = 0 if p112a == 3             /* sin medidor */

	********************
	*** combust_ch    ***
	********************
	gen byte combust_ch = .
	replace  combust_ch = 1 if inlist(p113a, 1, 2, 3)   /* gas GLP/natural, electricidad */
	replace  combust_ch = 0 if inlist(p113a, 4, 5, 6, 7)   /* carbón, leña, bosta, otro */

	********************
	*** piso_ch       ***
	********************
	gen piso_ch = .   /* CREAR VACÍO, metodología en revisión (manual oct 2025) */

	********************
	*** pared_ch      ***
	********************
	gen pared_ch = .   /* CREAR VACÍO, metodología en revisión (manual oct 2025) */

	********************
	*** techo_ch      ***
	********************
	gen techo_ch = .   /* CREAR VACÍO, metodología en revisión (manual oct 2025) */

	********************
	*** resid_ch      ***
	********************
	gen resid_ch = .   /* no existe variable directa en ENAHO */

	********************
	*** dorm_ch       ***
	********************
	gen byte dorm_ch = p104a
	replace  dorm_ch = 1 if p104a == 0   /* hogares con 0 habitaciones para dormir, imputar 1 (consistencia histórica) */

	********************
	*** cuartos_ch    ***
	********************
	gen byte cuartos_ch = p104

	********************
	*** cocina_ch     ***
	********************
	gen cocina_ch = .   /* no existe pregunta directa en ENAHO */

	********************
	*** telef_ch      ***
	********************
	gen byte telef_ch = (p1141 == 1)

	********************
	*** refrig_ch     ***
	********************
	gen byte refrig_ch = (p61212 == 1)

	********************
	*** freez_ch      ***
	********************
	gen freez_ch = .   /* sin variable fuente directa en ENAHO */

	********************
	*** auto_ch       ***
	********************
	gen byte auto_ch = (p61217 == 1)

	********************
	*** compu_ch      ***
	********************
	gen byte compu_ch = (p6127 == 1)

	********************
	*** internet_ch   ***
	********************
	gen byte internet_ch = (p1144 == 1)

	********************
	*** cel_ch        ***
	********************
	gen byte cel_ch = (p1142 == 1)

	********************
	*** vivi1_ch      ***
	********************
	/* p101: 1=casa, 2=dpto, 3+=otro */
	gen byte vivi1_ch = .
	replace  vivi1_ch = 1 if p101 == 1
	replace  vivi1_ch = 2 if p101 == 2
	replace  vivi1_ch = 3 if p101 > 2 & p101 != .

	********************
	*** vivi2_ch      ***
	********************
	gen byte vivi2_ch = .
	replace  vivi2_ch = 1 if inlist(vivi1_ch, 1, 2)
	replace  vivi2_ch = 0 if vivi1_ch == 3

	********************
	*** viviprop_ch   ***
	********************
	/*
	p105a: 1=alquilada, 2=propia pagada, 3=propia invasión, 4=comprando,
	       5=cedida trabajo, 6=cedida otro, 7=otra
	BID: 0=alquilada, 1=propia pagada, 2=propia comprando, 3=ocupada (de facto)
	*/
	gen byte viviprop_ch = .
	replace  viviprop_ch = 0 if p105a == 1
	replace  viviprop_ch = 1 if p105a == 2
	replace  viviprop_ch = 2 if p105a == 4
	replace  viviprop_ch = 3 if p105a == 3 | (p105a > 4 & p105a != .)

	********************
	*** vivitit_ch    ***
	********************
	gen byte vivitit_ch = (p106a == 1)

	********************
	*** vivialq_ch    ***
	********************
	replace p105b = . if p105b == 99999
	gen double vivialq_ch = p105b if viviprop_ch == 0

	********************
	*** vivialqimp_ch ***
	********************
	/* ia01hd: alquiler imputado anual - /12 */
	gen double vivialqimp_ch = ia01hd / 12


********************************************************************************
**************   WASH   ********************************************************
********************************************************************************

	********************
	*** aguafuente_ch ***
	********************
	/*
	p110: 1=red dentro vivienda, 2=red fuera edificio, 3=pilón, 4=camión,
	      5=pozo, 6=manantial/puquio, 7=otra, 8=río/acequia/lago
	*/
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 7 if p110a1==1
	replace aguafuente_ch = 1 if inlist(p110, 1, 2)   /* red pública = conexión privada */
	replace aguafuente_ch = 2 if p110 == 3   /* pilón = punto de acceso público */
	replace aguafuente_ch = 6 if p110 == 4   /* camión cisterna */
	replace aguafuente_ch = 8 if p110 == 8   /* río, acequia, lago */
	replace aguafuente_ch = 10 if inlist(p110, 5, 6, 7) /* pozo, manantial, otra - sin clasificación */

	********************
	*** aguared_ch    ***
	********************
	gen byte aguared_ch = .
	replace aguared_ch = 1 if aguafuente_ch == 1
	replace aguared_ch = 0 if aguafuente_ch >= 2 & aguafuente_ch != .

	********************
	*** aguafconsumo_ch ***
	********************
	gen byte aguafconsumo_ch = 0
	replace aguafconsumo_ch = 0 if p110a1==2 // El agua "no" es potable 
	replace aguafconsumo_ch = 1 if inlist(p110, 1, 2) & p110a1==1  /* red pública = conexión privada y agua es potable */
	replace aguafconsumo_ch = 2 if p110 == 3 & p110a1==1 /* pilón = punto de acceso público y agua es potable */
	replace aguafconsumo_ch = 6 if p110 == 4   /* camión cisterna */
	replace aguafconsumo_ch = 8 if p110 == 8   /* río, acequia, lago */
	replace aguafconsumo_ch = 10 if inlist(p110, 5, 6, 7) /* pozo, manantial, otra - sin clasificación */

	********************
	*** aguadist_ch   ***
	********************
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if p110 == 1   /* dentro de la vivienda */
	replace aguadist_ch = 2 if p110 == 2   /* fuera vivienda pero en el edificio */
	replace aguadist_ch = 3 if inlist(p110, 3, 6)   /* fuera de la propiedad */
	replace aguadist_ch = 0 if inlist(p110, 4, 5)   /* fuente móvil o pozo */

	********************
	*** aguadisp1_ch  ***
	********************
	gen byte aguadisp1_ch = (p110c1 == 24 | p110c3 == 24)

	********************
	*** aguadisp2_ch  ***
	********************
	gen byte aguadisp2_ch = .
	replace aguadisp2_ch = 1 if p110c2 < 4 | p110c1 < 12 | p110c3 < 12
	replace aguadisp2_ch = 2 if p110c2 >= 4 & (p110c1 >= 12 | p110c3 < 12)
	replace aguadisp2_ch = 3 if p110c == 1 & p110c1 == 24

	********************
	*** aguatrat_ch   ***
	********************
	gen aguatrat_ch = .   /* no existe pregunta de tratamiento del agua en ENAHO */

	********************
	*** aguamala_ch   ***
	********************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	********************
	*** aguamejorada_ch ***
	********************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	********************
	*** aguamide_ch   ***
	********************
	gen aguamide_ch = .   /* no existe medidor de agua individual en ENAHO */

	********************
	*** bano_ch       ***
	********************
	/*
	p111a 2025: 1=red dentro, 2=red fuera edificio, 3=letrina c/tratamiento,
	            4=pozo séptico/biodigestor, 5=pozo ciego, 6=río/acequia, 7=otra, 9=campo abierto
	BID: 0=sin inst., 1=inodoro a red, 2=inodoro a fosa, 3=letrina mejorada,
	     4=inst. a cuerpo agua/suelo, 5=no mejorada, 6=no clasificable
	*/
	gen byte bano_ch = 0   /* default: sin instalación */
	replace bano_ch = 1 if inlist(p111a, 1, 2)   /* inodoro conectado a red */
	replace bano_ch = 2 if p111a == 4   /* inodoro a fosa séptica/biodigestor */
	replace bano_ch = 3 if inlist(p111a, 3, 5)   /* letrina con tratamiento = mejorada */
	replace bano_ch = 4 if p111a == 6   /* descarga a río/acequia = cuerpo de agua */
	replace bano_ch = 6 if p111a == 7   /* otra = no clasificable */
	/* p111a==9 (campo abierto) bano_ch permanece 0 (sin instalación) */

	********************
	*** banoex_ch     ***
	********************
	gen banoex_ch = .   /* no existe pregunta de uso exclusivo en ENAHO */

	********************
	*** sinbano_ch    ***
	********************
	gen byte sinbano_ch = 0   /* default: tiene baño */
	replace  sinbano_ch = 2 if bano_ch == 0 & p111a == 9   /* campo abierto o al aire libre */
	replace  sinbano_ch = 3 if bano_ch == 0 & p111a != 9   /* sin inst., sin alternativa especificada */

	********************
	*** banomejorado_ch ***
	********************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6 & bano_ch != .


********************************************************************************
**************   MIGRACIÓN   ***************************************************
********************************************************************************

	********************
	*** migrante_ci   ***
	********************
	/* p401g2: país de nacimiento de la madre — proxy; <10000=extranjero, ≥10000=Perú */
	gen byte migrante_ci = (p401g2 < 10000) if p401g2 != . & p401g2 != 999999

	********************
	*** migrantiguo5_ci ***
	********************
	/* p401f: ¿vivía en este distrito hace 5 años? (1=sí); p401g: código lugar hace 5 años */
	gen byte migrantiguo5_ci = (migrante_ci == 1 & (p401f == 1 | (p401g > 10000 & p401g != .))) ///
		if migrante_ci != . & p401f != 3 & p401g != 999999 & p401f != . & !inrange(edad_ci, 0, 4)

	********************
	*** miglac_ci     ***
	********************
	gen miglac_ci = .

********************************************************************************
**************   VARIABLES EXTERNAS / POBREZA INE   ***************************
********************************************************************************

	********************
	*** tipo_bienestar ***
	********************
	gen byte tipo_bienestar = .
	replace  tipo_bienestar = 2   /* medida de consumo */

	********************
	*** pobre_ine_ci  ***
	********************
	/* pobreza INEI: 1=pobre extremo, 2=pobre no extremo, 3=no pobre */
	gen byte pobre_ine_ci = .
	replace  pobre_ine_ci = 0 if pobreza == 3
	replace  pobre_ine_ci = 1 if inlist(pobreza, 1, 2)

	********************
	*** bienestar_agregado ***
	********************
	/* gashog2d: gasto total bruto anual; mieperho: miembros - mensual per cápita */
	gen double bienestar_agregado = gashog2d / (12 * mieperho)

	********************
	*** lpe_ci        ***
	********************
	gen double lpe_ci = linpe   /* línea de pobreza extrema (INE) */

	********************
	*** ln_ci         ***
	********************
	gen double ln_ci = linea   /* línea de pobreza total (INE) */

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
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




saveold "`base_out'", version(12) replace

cap log close
