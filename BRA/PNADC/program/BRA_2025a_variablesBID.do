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

local PAIS BRA
local ENCUESTA PNADC
local ANO 2025
local ronda a


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: BRA
Encuesta: PNADC
Round: a
Autores: Matías Isla y Matias Rodriguez (SCL/SCL)
Version: 09/07/2026
Mail: matiasi@iadb.org/mrodriguezm@iadb.org, 09 de julio de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use "`base_in'", clear
rename *, lower

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c = 4

	********************
	*** region_c ****
	********************
	gen region_c = uf   /* UF: Unidade da Federação */
	destring region_c, replace

	*************
	* pais_c    *
	*************
	gen str3 pais_c = "BRA"

	******
	*anio_c*
	******
	gen int anio_c = ano

	******
	*mes_c*
	******
	gen mes_c = trimestre   /* trimestre de referencia */

	******
	*zona*
	******
	gen zona_c = v1022   /* 1 urbana, 2 rural -> estandar 1 urbano/0 rural */
	replace zona_c = 0 if v1022 == 2

	*********
	*estrato*
	*********
	gen estrato_ci = estrato

	******
	*upm*
	******
	gen upm_ci = upa

	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch = group(trimestre upa estrato v1008 v1014)
	egen idp_ci = group(idh_ch v2003)
	tostring idh_ch, replace
	tostring idp_ci, replace

	***********
	*factor_ci*
	***********
	gen double factor_ci = v1032   /* peso con calibración */

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen double factor_ch = v1032

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci = v2007   /* 1 hombre, 2 mujer */

	*********
	*edad_ci*
	*********
	gen int edad_ci = v2009   /* edad en años a la fecha de referencia */

	**************
	**relacion_ci**
	**************
	gen byte relacion_ci = .
	replace relacion_ci = 1 if v2005 == 1 /* Jefe(a) */
	replace relacion_ci = 2 if inrange(v2005, 2, 3) /* Cónyuge/pareja */
	replace relacion_ci = 3 if inrange(v2005, 4, 6) /* Hijos/hijastros */
	replace relacion_ci = 4 if inrange(v2005, 7, 14) /* Otros parientes */
	replace relacion_ci = 5 if inrange(v2005, 15, 17) /* Otros no parientes */
	replace relacion_ci = 5 if v2005 == 19 /* Pariente del empleado doméstico */
	replace relacion_ci = 6 if v2005 == 18 /* Empleado doméstico */

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	*************
	*miembros_one_ci*
	*************
	gen byte miembros_one_ci = .
	replace miembros_one_ci = 1 if inrange(v2005, 1, 17)
	replace miembros_one_ci = 0 if inlist(v2005, 18, 19)

	**************
	*Estado Civil*
	**************
	gen byte civil_ci = .

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci = .
	replace jefe_ci = 1 if relacion_ci == 1
	replace jefe_ci = 0 if relacion_ci != 1 & relacion_ci != .

	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen byte nconyuges_ch = sum(relacion_ci == 2)
	replace nconyuges_ch = . if relacion_ci == .

	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)
	replace nhijos_ch = . if relacion_ci == .

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)
	replace notropari_ch = . if relacion_ci == .

	**************
	*notronopari_ch*
	**************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	replace notronopari_ch = . if relacion_ci == .

	****************
	*nempdom_ch*
	****************
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)
	replace nempdom_ch = . if relacion_ci == .

	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch = 2 if (nhijos_ch>0 | nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
	replace clasehog_ch = 3 if notropari_ch>0 & notronopari_ch==0
	replace clasehog_ch = 4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	replace clasehog_ch = 5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci>0 & relacion_ci<=5)

	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci!=.))

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch = sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch = sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	*********
	*afro_ci*
	*********
	/* v2010: cor ou raça. 1 Branca 2 Preta 3 Amarela 4 Parda 5 Indígena 9 Ignorado */
	gen byte afro_ci = .
	replace afro_ci = 1 if inlist(v2010, 2, 4)
	replace afro_ci = 0 if inlist(v2010, 1, 3, 5)
	replace afro_ci = . if v2010 == 9

	*********
	*ind_ci*
	*********
	gen byte ind_ci = .
	replace ind_ci = 1 if v2010 == 5
	replace ind_ci = 0 if inlist(v2010, 1, 2, 3, 4)
	replace ind_ci = . if v2010 == 9

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if (afro_ci == 0 | ind_ci == 0)
	replace noafroind_ci = 0 if (afro_ci == 1 | ind_ci == 1)
	replace noafroind_ci = . if (afro_ci == . & ind_ci == .)

	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c = .

	************
	*afroind_ci*
	************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	*********
	*afro_ch*
	*********
	gen byte afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	********
	*ind_ch*
	********
	gen byte ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	**************
	*noafroind_ch*
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	************
	*afroind_ch*
	************
	gen byte afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	********
	*dis_ci*
	********
	gen byte dis_ci = . /* sin módulo Washington Group en PNADC */

	**********
	*disWG_ci*
	**********
	gen byte disWG_ci = .

	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	******************
	*BRA_dis_ci*
	******************
	gen byte BRA_dis_ci = .

****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if (v4001==1 | v4002==1 | v4003==1 | v4004==1 | v4005==1)
	replace condocup_ci = 2 if (v4001==2 | v4002==2 | v4003==2 | v4004==2 | v4005==2) & (v4071==1 & v4072a!=9)
	replace condocup_ci = 3 if condocup_ci != 1 & condocup_ci != 2 & edad_ci >= 14
	replace condocup_ci = 4 if edad_ci < 14

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if condocup_ci == 3 & v5004a == 1 /* Jubilados/pensionados */
	replace categoinac_ci = 2 if condocup_ci == 3 & vd4030 == 2 /* Estudiantes */
	replace categoinac_ci = 3 if condocup_ci == 3 & vd4030 == 1 /* Quehaceres domésticos */
	replace categoinac_ci = 4 if condocup_ci == 3 & (categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3)

	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)

	**************
	***cesante_ci***
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 0 if condocup_ci == 2
	replace cesante_ci = 1 if condocup_ci == 2 & v4082 == 1

	***************
	***desemp_ci***
	***************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)

	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = .
	replace subemp_ci = 1 if vd4004a == 1
	replace subemp_ci = 0 if condocup_ci == 1 & subemp_ci == .

	****************
	***durades_ci***
	****************
	gen durades_ci = .
	replace durades_ci = v40761 if condocup_ci == 2 & v40761 < .
	replace durades_ci = 12 + v40762 if condocup_ci == 2 & v40762 < .
	replace durades_ci = 12 * v40763 if condocup_ci == 2 & v40763 < .

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	****************
	*** nempleos_ci***
	****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1 & v4009 == 1
	replace nempleos_ci = 2 if emp_ci == 1 & inlist(v4009, 2, 3)
	replace nempleos_ci = . if emp_ci == 0

	**********************
	*** antiguedad_ci  ***
	**********************
	gen double antiguedad_ci = .
	replace antiguedad_ci = 0 if emp_ci == 1 & v40401 < . /* <1 año */
	replace antiguedad_ci = 1 + v40402/12 if emp_ci == 1 & v40402 < . /* 1 a <2 años */
	replace antiguedad_ci = v40403 if emp_ci == 1 & v40403 < . /* 2+ años */

	*********************
	*** desalent_ci    ***
	*********************
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (vd4005 == 1 & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)

	***************
	***horaspri_ci***
	***************
	gen byte horaspri_ci = v4039
	replace horaspri_ci = . if v4039 == .
	replace horaspri_ci = . if horaspri_ci > 168
	replace horaspri_ci = . if emp_ci == 0

	***************
	***horastot_ci ***
	***************
	egen horastot_ci = rsum(v4039c v4056c v4062c) if edad_ci >= 14 & nempleos_ci != .
	replace horastot_ci = . if emp_ci == 0
	replace horastot_ci = . if (horaspri_ci == . & v4056c == . & v4062c == .) | horastot_ci > 150

	**************************
	***  tiempoparc_ci     ***
	**************************
	gen byte tiempoparc_ci = .
	replace tiempoparc_ci = 1 if emp_ci == 1 & horaspri_ci >= 1 & horaspri_ci < 30 & v4063a == 2
	replace tiempoparc_ci = 0 if emp_ci == 1 & tiempoparc_ci == .

	***************
	***categopri_ci ***
	***************
	gen byte categopri_ci = .
	replace categopri_ci = 1 if emp_ci == 1 & vd4008 == 4 /* Empregador */
	replace categopri_ci = 2 if emp_ci == 1 & vd4008 == 5 /* Conta própria */
	replace categopri_ci = 3 if emp_ci == 1 & inlist(vd4008, 1, 2, 3) /* Asalariados y domésticos */
	replace categopri_ci = 4 if emp_ci == 1 & vd4008 == 6 /* Não remunerado */
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1

	***************
	***categosec_ci ***
	***************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if emp_ci == 1 & v4043 == 5 /* Empregador */
	replace categosec_ci = 2 if emp_ci == 1 & v4043 == 6 /* Conta própria */
	replace categosec_ci = 3 if emp_ci == 1 & inlist(v4043, 1, 2, 3, 4) /* Doméstico/militar/empregado priv-públ */
	replace categosec_ci = 4 if emp_ci == 1 & v4043 == 7 /* Não remunerado */
	replace categosec_ci = . if emp_ci == 0

	***************
	***rama_ci ***
	***************
	gen byte rama_ci = .
	replace rama_ci = 1 if vd4010 == 1
	replace rama_ci = 3 if vd4010 == 2
	replace rama_ci = 5 if vd4010 == 3
	replace rama_ci = 6 if inlist(vd4010, 4, 6)
	replace rama_ci = 7 if vd4010 == 5
	replace rama_ci = 8 if vd4010 == 7
	replace rama_ci = 10 if vd4010 == 8
	replace rama_ci = 9 if inlist(vd4010, 9, 10, 11, 12)
	replace rama_ci = . if emp_ci != 1

	***************
	***spublico_ci ***
	***************
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & inlist(v4012, 2, 4)
	replace spublico_ci = 0 if emp_ci == 1 & !inlist(v4012, 2, 4) & v4012 != .

	***************
	***tamemp_ci ***
	***************
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if emp_ci == 1 & v4012 == 6 /* Cuenta propia */
	replace tamemp_ci = 1 if emp_ci == 1 & v4012 == 7 & tamemp_ci == . /* No remunerado */
	replace tamemp_ci = 1 if emp_ci == 1 & v4018 == 1 & tamemp_ci == . /* 1-5 personas */
	replace tamemp_ci = 2 if emp_ci == 1 & inlist(v4018, 2, 3) & tamemp_ci == . /* 6-50 */
	replace tamemp_ci = 3 if emp_ci == 1 & v4018 == 4 & tamemp_ci == . /* 51+ */
	replace tamemp_ci = . if emp_ci == 0

	***************
	***cotizando_ci***
	***************
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if vd4012 == 1 & emp_ci == 1
	replace cotizando_ci = 0 if cotizando_ci != 1 & inlist(condocup_ci, 1, 2)

	***************
	***afiliado_ci***
	***************
	gen byte afiliado_ci = . /* sin fuente en PNADC */

	***************
	***instcot_ci***
	***************
	gen byte instcot_ci = .
	replace instcot_ci = 2 if cotizando_ci == 1 & v4028 == 1 /* RPPS: servidor estatutário */
	replace instcot_ci = 1 if cotizando_ci == 1 & instcot_ci == . /* INSS (RGPS) */

	**************
	***formal_ci***
	**************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	*******************
	***tipocontrato_ci***
	*******************
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if categopri_ci == 3 & v4029 == 1 /* con contrato firmado */
	replace tipocontrato_ci = 3 if categopri_ci == 3 & v4029 == 2 /* sin contrato */
	replace tipocontrato_ci = . if categopri_ci != 3

	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci = .
	replace ocupa_ci = 1 if inlist(vd4011, 2, 3) & emp_ci == 1 // Profesionales y técnicos
	replace ocupa_ci = 2 if vd4011 == 1 & emp_ci == 1 // Directores y funcionarios superiores
	replace ocupa_ci = 3 if vd4011 == 4 & emp_ci == 1 // Personal administrativo y nivel intermedio
	replace ocupa_ci = 4 if (v4010 >= 5211 & v4010 <= 5249) & emp_ci == 1 // Comerciantes y vendedores
	replace ocupa_ci = 5 if ((v4010 >= 5111 & v4010 <= 5169) | (v4010 >= 5311 & v4010 <= 5419) | (v4010 >= 9111 & v4010 <= 9129) | (v4010 >= 9411 & v4010 <= 9510)) & emp_ci == 1 // Trabajadores en servicios
	replace ocupa_ci = 6 if (vd4011 == 6 | (v4010 >= 9211 & v4010 <= 9216)) & emp_ci == 1 // Trabajadores agrícolas
	replace ocupa_ci = 7 if (inlist(vd4011, 7, 8) | (v4010 >= 9311 & v4010 <= 9329)) & emp_ci == 1 // Obreros no agrícolas, conductores
	replace ocupa_ci = 8 if vd4011 == 10 & emp_ci == 1 // Fuerzas Armadas
	replace ocupa_ci = 9 if ((vd4011 == 9 & !inlist(ocupa_ci, 5, 6, 7)) | vd4011 == 11) & emp_ci == 1 // Otras no clasificadas
	replace ocupa_ci = . if emp_ci != 1

****************************
***VARIABLES DE PENSIONES***
****************************

	**************
	**pension_ci***
	**************
	gen pension_ci = (v5004a == 1) if !missing(v5004a)  /* Jubilación/pensión contributiva (INSS/RPPS) */

	***********************
	*** pensionsub_ci   ***
	***********************
	gen pensionsub_ci = (v5001a == 1 & edad_ci >= 65) if !missing(v5001a)

	***********************
	*** tipopen_ci       ***
	***********************
	gen byte tipopen_ci = .

	***********************
	*** instpen_ci       ***
	***********************
	gen byte instpen_ci = .


************************************************
*** VARIABLES DE INGRESO & PROTECCION SOCIAL ***
************************************************

	foreach var of varlist v5001a2 v5002a2 v5003a2 v5004a2 v5005a2 v5006a2 v5007a2 v5008a2 {
		replace `var' = . if `var' >= 999999 | `var' < 0
	}

*A. INGRESOS LABORALES A NIVEL DE INDIVIDUO	

	*************
	* ylmpri_ci *
	*************
	gen ylmpri_ci = v403312
	replace ylmpri_ci = . if v403312 < 0 | v403312 >= 999999 | emp_ci != 1

	************
	* ylmsec_ci *
	************
	gen ylmsec_ci = v405012
	replace ylmsec_ci = . if v405012 < 0 | v405012 >= 999999 | emp_ci != 1

	**************
	* ylmotros_ci *
	**************
	gen ylmotros_ci = v405812
	replace ylmotros_ci = . if v405812 < 0 | v405812 >= 999999 | emp_ci != 1

	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing

	**************
	* ylnmpri_ci *
	**************
	gen ylnmpri_ci = v403322 if v40332 == 2
	replace ylnmpri_ci = . if v403322 < 0 | v403322 >= 999999 | emp_ci != 1

	**************
	* ylnmsec_ci *
	**************
	gen ylnmsec_ci = v405022
	replace ylnmsec_ci = . if v405022 < 0 | v405022 >= 999999 | emp_ci != 1

	****************
	* ylnmotros_ci *
	****************
	gen ylnmotros_ci = v405822
	replace ylnmotros_ci = . if v405822 < 0 | v405822 >= 999999 | emp_ci != 1

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing


*B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO	

	******************
	*** ytransf_ci ***
	******************
	* PNC - Pensiones sociales no contributivas:
			* Benefício Asistencial de Prestação Continuada (v5001a) + edad_ci >= 65
	* PTMC - Programas de transferencias monetarias condicionadas:
			* Bolsa Família (v5002a)
	* POTROT - Programas de otras transferencias monetarias no condicionadas
			* Outro programa social do governo (v5003a)
			* Benefício Asistencial de Prestação Continuada (v5001a) + edad_ci < 65
	
	*** Beneficiarios a nivel individual:
	
		gen byte pnc_ci = (v5001a == 1 & edad_ci >= 65) if !missing(v5001a)
		gen byte ptmc_ci = (v5002a == 1) if !missing(v5002a)
	
		gen byte otrogob_ci = (v5003a == 1) if !missing(v5003a)
		gen byte discap_ci = (v5001a == 1 & edad_ci < 65) if !missing(v5001a)
		gen byte potrot_ci = (otrogob_ci == 1 | discap_ci == 1)
		replace potrot_ci = . if otrogob_ci == . & discap_ci == .
	
	*** Montos de transferencias a nivel individual:
	
		// Transferencias PNC
		gen double ypnc_ci = v5001a2 if pnc_ci == 1
		
		// Transferencias PTMC
		gen double yptmc_ci = v5002a2		
		
		// Otras transferencias POTROT
		gen double yotrogob_ci = v5003a2		
		gen double ydis_ci = v5001a2 if discap_ci == 1		
		egen double yotrot_ci = rowtotal(yotrogob_ci ydis_ci), mi
		
	*** Ingreso individual por transferencias no contributivas
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi
	
	*************
	* remesas_ci *
	*************
    generate remesas_ci = .

	**********
	* ypen_ci *
	**********
	gen ypen_ci = v5004a2 if v5004a2 != .

	*************
	* ypensub_ci *
	*************
	gen ypensub_ci = ypnc_ci
	
	**********
	* ynlm_ci *
	**********
		* v5001a2 Rend Recebeu BPC-LOAS > ypnc_ci = ypensub_ci
		* v5002a2 Rend recebido de bolsa familia > yptmc_ci
		* v5003a2 Rend recebido de outro prog social > yotros_ci
		* v5004a2 Rend recebido de aposentadoria e pensão > ypen_ci
		* v5005a2 Rend de seguro-desemprego, seguro-defeso
		* v5006a2 Rend recebido por pensão alimentícia doação etc
		* v5007a2 Rend recebido aluguel e arrendamento
		* v5008a2 Rend recebido de outros rendimentos

	egen double ynlm_ci = rowtotal(ytransf_ci ypen_ci v5005a2 v5006a2 v5007a2 v5008a2 remesas_ci), mi
	replace ynlm_ci = . if (ytransf_ci == . &  ypen_ci==. & v5005a2 == . & v5006a2==. & v5007a2==. &  v5008a2==. &  remesas_ci == .)

	***********
	* ynlnm_ci *
	***********
	gen ynlnm_ci = .   /* sin captura de ingreso no laboral en especie */

	**********
	* ytot_ci *
	**********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
	
	***************
	*** ynet_ci ***
	***************
	gen double aux_ytransf_ci = ytransf_ci*(-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
	drop aux_ytransf_ci


*C. INGRESOS DEL HOGAR ***

	*********
	* ylm_ch *
	*********
	by idh_ch, sort: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi

	**********
	* ylnm_ch *
	**********
	by idh_ch, sort: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi
	
	******************
	*** ytransf_ch ***
	****************** 

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
	
	*************
	* remesas_ch *
	*************
	gen remesas_ch = .
	
	*********
	* ynlm_ch *
	*********
	by idh_ch, sort: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, mi

	***********
	* ynlnm_ch *
	***********
	gen ynlnm_ch = .

	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci == 1, missing
	
	***************
	*** ynet_ch ***
	***************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	***************
	* ylmhopri_ci *
	***************
	gen ylmhopri_ci = .
	replace ylmhopri_ci = ylmpri_ci / horaspri_ci if horaspri_ci > 0 & emp_ci == 1

	**********
	* ylmho_ci *
	**********
	gen ylmho_ci = .
	replace ylmho_ci = ylm_ci / horastot_ci if horastot_ci > 0 & emp_ci == 1

	**************
	* nrylmpri_ci *
	**************
	gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
	replace nrylmpri_ci = . if emp_ci != 1

	**************
	* nrylmpri_ch *
	**************
	sort idh_ch
	by idh_ch: egen nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1



****************************
***	VARIABLES EDUCATIVAS ***
****************************

/*

# Historial de modificaciones #
#=============================#

*Modificado por Agustina Thailinger y Pia Iocco (SCL/EDU) 3-28-2020
*Modificado por Manuel Marcos(SCL/EDU) 2026-8-10

# Variables insumos consideradas #
#================================#

v2009: Idade do morador na data de referência
v3002: ... frequenta escola?
v3002a: A escola que ... frequenta é de
v3003a: Qual é o curso que ... frequenta?
v3005a: Esse curso que .... frequenta é organizado em
v3006: Qual é o ano/série/semestre que ... frequenta?
V3008: Anteriormente ... frequentou escola?
v3009a: Qual foi o curso mais elevado que ... frequentou anteriormente?
v3011a: Esse curso que .... frequentou era organizado em:
v3013: Qual foi o último ano/série/semestre que ... concluiu com aprovação, neste curso que frequentou anteriormente
v3012: ... concluiu com aprovação, pelo menos a primeira série deste curso que frequentou anteriormente?
v3014: ... concluiu este curso que frequentou anteriormente

# Indicadores a construir #
#=========================#

1. aedu_ci: número de años de educación culminados
2. edupre_ci: variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo
3. eduui_ci: variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica o universitaria incompleta y con 0 el resto
4. eduuc_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica, universitaria completa, o posgrado (completa o incompleta), y con 0 el resto
5. eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto
6. asiste_ci: Variable dicotómica que indica si la persona asiste actualmente a un centro educativo (de cualquier nivel educativo: preescolar, primaria, secundaria, y terciaria) de educación formal al momento de la encuesta.
7. edupub_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza pública al momento de la encuesta, con 0 si asiste a un centro de enseñanza privada, y con perdido si no asiste o no responde a la pregunta. 
8. asispre_ci: Asistencia a preescolar. Variable dicotómica que indica con valor 1 si la persona asiste actualmente a educación preescolar, y con 0 al resto (no tiene valores perdidos). 
9. razonesnoasis_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela

# Notas para la construcción de variables #
#=========================================#

- grado_asist: el valor de "13" es "Curso no clasificado por series o cursos"
- Ensino fundamental. Se resta uno porque preguntan el grado al que asisten, no el máximo alcanzado. Se infiere que el anterior es el completado
- Ensino medio. Tienen que haber completado los 9 anios de ensino fundamental (antes eran 8)
- Universitario. No incluye postgrados. Tienen que haber completado los 9 anios de ensinio fundamental y los 3 anios de ensinio medio, 12 en total
- Especializacion o diplomado. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están. Se imputa que completaron todo superior.
- Maestria. Se imputa pregrado completo. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están
- Doctorado. Se imputa maestría completa. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están
- grado_asist_sup: pasa de semestres a años para superior para el grupo de personas que están cursando
- grado_asist_sup_v2: pasa de semestres a años para superior para el grupo de personas que ya terminaron sus estudios

*/

*************
***aedu_ci***
*************

gen grado_asist = v3006
replace grado_asist = . if v3006 == 13 

* Para quienes asisten actualmente a superior en semestres se convierte a años
gen grado_asist_sup = round(grado_asist/2) if v3005a == 1 & v3003a == 8

* Para quienes ya no asisten pero cursaron superior en semestres se convierte a años
gen grado_asist_sup_v2 = round(v3013/2) if v3011a == 1 & v3009a == 12

gen aedu_ci = .

* Construcción para quienes están estudiando
replace aedu_ci = 0 if v3003a == 2 | v3003a == 3                   						// Sin años de educación
replace aedu_ci = grado_asist - 1 if v3003a == 4                   						// Ensinio fundamental 
replace aedu_ci = 9 + grado_asist - 1 if v3003a == 6               						// Ensinio medio
replace aedu_ci = grado_asist - 1 if v3003a == 5                   						// Ensinio fundamental jóvenes y adultos
replace aedu_ci = 9 + grado_asist - 1 if v3003a == 7               						// Ensinio medio    
replace aedu_ci = 12 + grado_asist_sup - 1 if v3003a == 8          						// Ensinio superior
replace aedu_ci = 12 + 4 if v3003a == 9                            						// Especialização de nível superior
replace aedu_ci = 12 + 4 if v3003a == 10                           						// Mestrado
replace aedu_ci = 12 + 4 + 2 if v3003a == 11                       						// Doutorado
						
* Construcción para quienes NO están estudiando						
replace aedu_ci=0 if v3008==2                                      						// Nunca asistieron 
replace aedu_ci = 0 if inlist(v3009a, 2, 3, 4)                     						// Creche, prescola, Alfabetizacion de jovenes y adultos, Classe de alfabetização - CA.
replace aedu_ci = v3013 if v3009a == 5                             						// Antigo primário. No se resta 1 porque la variable indica si lo concluyo o no
replace aedu_ci = v3013 + 4 if v3009a == 6                         						// Antigo ginásio. Despues de antigo primário (4 anios)
replace aedu_ci = v3013 if v3009a == 7                             						// Regular do ensino fundamental ou do 1º grau. No se resta 1 porque la variable indica si lo concluyo o no
replace aedu_ci = v3013 if v3009a == 8                             						// Nivelacion de primaria para adultos
replace aedu_ci = v3013 + 4 + 4 if v3009a == 9  & v3012 == 1       						// Antigo científico, clássico, etc. Despues de antigo primário y antigo ginásio (8 anios)
replace aedu_ci = v3013 + 9 if v3009a == 10                        						// Regular do ensino médio óu do 2º grau. Despues de ensinio fundamental (9 anios)
replace aedu_ci = v3013 + 9 if v3009a == 11                        						// Nivelacion de adultos secundaria
replace aedu_ci = grado_asist_sup_v2 + 12 if v3009a == 12          						// Universitario pregrado
replace aedu_ci = 12 + 4 if v3009a == 13 & (v3014 != 1 | missing(v3014)) 				// Especializacion o diplomado, no terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 13 & v3014 == 1          						// Especializacion o diplomado, terminado
replace aedu_ci = 12 + 4 if v3009a == 14 & (v3014 != 1 | missing(v3014))              	// Maestria, no terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 14 & v3014 == 1          						// Maestria, terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 15 & (v3014 != 1 | missing(v3014))  			// Doctorado, no terminado    
replace aedu_ci = 12 + 4 + 2 + 4 if v3009a == 15 & v3014 == 1      						// Doctorado, terminado 

* Reemplazo cuando el grado está missing pero el nivel se reporta (para quienes están estudiando)
replace aedu_ci = 0  if missing(aedu_ci) & v3003a >= 2 & v3003a <= 5
replace aedu_ci = 9  if missing(aedu_ci) & (v3003a == 6 | v3003a == 7)
replace aedu_ci = 12 if missing(aedu_ci) & v3003a == 8
replace aedu_ci = 16 if missing(aedu_ci) & (v3003a == 9 | v3003a == 10)
replace aedu_ci = 18 if missing(aedu_ci) & v3003a == 11

* Reemplazo cuando el grado está missing pero el nivel se reporta (para quienes NO están estudiando)
replace aedu_ci = 0  if missing(aedu_ci) & v3009a >= 2 & v3009a <= 5
replace aedu_ci = 4  if missing(aedu_ci) & v3009a == 6
replace aedu_ci = 4  if missing(aedu_ci) & (v3009a == 7 | v3009a == 8)
replace aedu_ci = 8  if missing(aedu_ci) & v3009a == 9
replace aedu_ci = 9  if missing(aedu_ci) & (v3009a == 10 | v3009a == 11)
replace aedu_ci = 12 if missing(aedu_ci) & v3009a == 12
replace aedu_ci = 16 if missing(aedu_ci) & (v3009a == 13 | v3009a == 14)
replace aedu_ci = 18 if missing(aedu_ci) & v3009a == 15

***************
***edupre_ci***
***************

* NOTA: No cuenta con preguntas para esta variable

gen byte edupre_ci=.

**************
***eduui_ci***
**************

gen eduui_ci = .
replace eduui_ci = 1 if !missing(aedu_ci) & (v3003a == 8 | (v3009a == 12 & v3014 == 2))
replace eduui_ci = 0 if !missing(aedu_ci) & !(v3003a == 8 | (v3009a == 12 & v3014 == 2))

**************
***eduuc_ci***
**************

gen eduuc_ci = .
replace eduuc_ci = 1 if !missing(aedu_ci) & (                     ///      
                        (v3009a == 12 & v3014 == 1) |            ///                 
                        inlist(v3003a, 9, 10, 11) |              ///               
                        inlist(v3009a, 13, 14, 15)               ///                
                      )
replace eduuc_ci = 0 if !missing(aedu_ci) & !(                   ///                 
                        (v3009a == 12 & v3014 == 1) |            ///                
                        inlist(v3003a, 9, 10, 11) |              ///                
                        inlist(v3009a, 13, 14, 15)               ///               
                      )

**************
***eduac_ci***
**************

* NOTA: No cuenta con preguntas para esta variable

gen byte eduac_ci=.

**************
**asiste_ci***
**************

gen asiste_ci = .
replace asiste_ci = 1 if !missing(v3002) & v3002 == 1
replace asiste_ci = 0 if !missing(v3002) & v3002 != 1

***************
***edupub_ci***
***************

gen edupub_ci = .
replace edupub_ci = 1 if !missing(v3002a) & v3002a == 2
replace edupub_ci = 0 if !missing(v3002a) & v3002a != 2

****************
***asispre_ci***
****************

*Creación de la variable asistencia a preescolar por Iván Bornacelly - 01/12/17

gen asispre_ci = 0
replace asispre_ci = 1 if v2009 >= 4 & v3003a == 2


******************
***razonesnoasis_ci***
******************

* NOTA: No cuenta con preguntas para esta variable

gen razonesnoasis_ci = .

****************************
***VARIABLES DE VIVIENDA***
****************************

	***********
	*luz_ch*
	***********
	gen luz_ch = (s01014 == 1) /* 1=electricidad */

	***************
	*luzmide_ch*
	***************
	gen luzmide_ch = . /* sin fuente en PNADC */

	***************
	*combust_ch*
	***************
	gen byte combust_ch = .

	***********
	*piso_ch*
	***********
	gen piso_ch = .

	***********
	*pared_ch*
	***********
	gen pared_ch = .

	***********
	*techo_ch*
	***********
	gen techo_ch = .

	***********
	*resid_ch*
	***********
	gen resid_ch = 0 if s01013==1 | s01013==2
	replace resid_ch = 1 if s01013==3 | s01013==4
	replace resid_ch = 2 if s01013==5
	replace resid_ch = 3 if s01013==6
	replace resid_ch = . if s01013==.

	***********
	*dorm_ch*
	***********
	gen dorm_ch = s01006
	replace dorm_ch = . if s01006 == 99

	***********
	*cuartos_ch*
	***********
	gen cuartos_ch = s01005
	replace cuartos_ch = . if s01005 == 99

	***********
	*cocina_ch*
	***********
	gen cocina_ch = . /* sin fuente en PNADC */

	***********
	*telef_ch*
	***********
	gen telef_ch = (s01022 == 1)
	replace telef_ch = . if s01022 == .

	***********
	*refrig_ch*
	***********
	gen refrig_ch = (s01023 == 1 | s01023 == 2)
	replace refrig_ch = . if s01023 == .

	***********
	*freez_ch*
	***********
	gen freez_ch = . /* sin fuente en PNADC */

	***********
	*auto_ch*
	***********
	gen auto_ch = (s01031 == 1)
	replace auto_ch = . if s01031 == .

	***********
	*compu_ch*
	***********
	gen compu_ch = (s01028 == 1)

	***********
	*internet_ch*
	***********
	gen internet_ch = (s01029 == 1)

	***********
	*cel_ch*
	***********
	gen cel_ch = (s01021 >= 1)

	***********
	*vivi1_ch*
	***********
	gen vivi1_ch = 1 if s01001 == 1
	replace vivi1_ch = 2 if s01001 == 2
	replace vivi1_ch = 3 if s01001 == 3

	***********
	*vivi2_ch*
	***********
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if vivi1_ch == 1 | vivi1_ch == 2
	replace vivi2_ch = 0 if vivi1_ch == 3

	***********
	*viviprop_ch*
	***********
	gen viviprop_ch = 0 if s01017 == 3
	replace viviprop_ch = 1 if s01017 == 1
	replace viviprop_ch = 2 if s01017 == 2
	replace viviprop_ch = 3 if s01017 >= 4
	replace viviprop_ch = . if s01017 == .

	***********
	*vivitit_ch*
	***********
	/* s01020a — "tem documento que comprove propriedade?" */
	gen vivitit_ch = .
	replace vivitit_ch = 1 if s01020a == 1
	replace vivitit_ch = 0 if s01020a == 2

	***********
	*vivialq_ch*
	***********
	gen vivialq_ch = s01019
	replace vivialq_ch = . if s01019 >= 999999999 | vivialq_ch < 0

	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch = s01019 if s01017 == 3

****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen aguared_ch = (s01007 == 1)

	***********
	*aguafconsumo_ch*
	***********
	gen aguafconsumo_ch = 0

	***********
	*aguafuente_ch*
	***********
	gen aguafuente_ch = .
	replace aguafuente_ch = 1 if s01007==1 & s01010 != 3 /* red dentro de la propiedad */
	replace aguafuente_ch = 2 if s01007==1 & s01010 == 3 /* red, llega fuera del terreno */
	replace aguafuente_ch = 4 if s01007==2 /* poço profundo/artesiano a pozo protegido */
	replace aguafuente_ch = 5 if s01007==5 /* água da chuva armazenada a lluvia */
	replace aguafuente_ch = 9 if s01007==3 /* poço raso/cacimba a no mejorada */
	replace aguafuente_ch = 10 if (s01007==4 | s01007==6) /* fonte/nascente u outra a no clasificable */
	replace aguafuente_ch = 10 if aguafuente_ch==. & jefe_ci==1

	***********
	*aguadist_ch*
	***********
	gen aguadist_ch = .
	replace aguadist_ch = 1 if s01010 == 1
	replace aguadist_ch = 2 if s01010 == 2
	replace aguadist_ch = 3 if s01010 == 3
	replace aguadist_ch = . if s01010 == .

	***********
	*aguadisp1_ch*
	***********
	gen byte aguadisp1_ch = 9 /* PNADC no pregunta disponibilidad continua sí/no */

	***********
	*aguadisp2_ch*
	***********
	gen aguadisp2_ch = 3 if s01008 == 1
	replace aguadisp2_ch = 2 if s01008 == 2
	replace aguadisp2_ch = 1 if (s01008 == 3 | s01008 == 4)

	***********
	*aguatrat_ch*
	***********
	gen aguatrat_ch = 9 /* sin fuente en PNADC */

	***********
	*aguamala_ch*
	***********
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	***********
	*aguamejorada_ch*
	***********
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	***********
	*aguamide_ch*
	***********
	gen byte aguamide_ch = . /* sin fuente en PNADC */

	***********
	*bano_ch*
	***********
	gen bano_ch = .
	replace bano_ch = 1 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 1 | s01012a == 2)
	replace bano_ch = 2 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 3)
	replace bano_ch = 4 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 5 | s01012a == 6)
	replace bano_ch = 6 if (s01011a>0 | s01011b>0 | s01011c==1) & s01012a==4
	replace bano_ch = 0 if (s01011a==0 & s01011b==0) | s01011c==2 | s01012a==7
	replace bano_ch = 6 if bano_ch==. & jefe_ci==1

	***********
	*banoex_ch*
	***********
	gen banoex_ch = (s01011a >= 1)

	***********
	*sinbano_ch*
	***********
	gen sinbano_ch = 3
	replace sinbano_ch = 0 if bano_ch > 0
	replace sinbano_ch = 1 if (s01011a==0 & s01011b==0 & s01011c==1)

	***********
	*banomejorado_ch*
	***********
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch = 0 if (bano_ch==0 | bano_ch>=4) & bano_ch!=6 & bano_ch!=.

****************************
*** VARIABLES DE MIGRACIÓN***
****************************

	*****************
	*** migrante_ci **
	*****************
	gen byte migrante_ci = . /* sin módulo de migración en PNADC */

	******************
	* migrantiguo5_ci *
	******************
	gen byte migrantiguo5_ci = .

	****************
	* miglac_ci *
	****************
	gen byte miglac_ci = .

****************************
*** VARIABLES DE POBREZA ***
****************************

	****************
	* tipo_bienestar *
	****************
	gen byte tipo_bienestar = 1  /* PNADC reporta ingreso */


	****************
	* bienestar_agregado *
	****************
	gen bienestar_agregado = .

	*******************
	*** ln_ci        ***
	*******************
	/* Pendiente de publicación del IBGE, eventualmente se podrá extraer de https://agenciadenoticias.ibge.gov.br/agencia-noticias.html como en años anteriores (hasta ahora solo post sobre internet y condición laboral) */
	gen ln_ci =  .


	*******************
	*** lpe_ci       ***
	*******************
	/* Pendiente de publicación del IBGE, eventualmente se podrá extraer de https://agenciadenoticias.ibge.gov.br/agencia-noticias.html como en años anteriores (hasta ahora solo post sobre internet y condición laboral) */
	gen lpe_ci = .

	****************
	* pobre_ine_ci *
	****************
	gen byte pobre_ine_ci=.


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
horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	/// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci /// Ingresos individuo
     ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch  ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// Ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
	  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci  /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 ///
	  cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa


saveold "`base_out'", version(12) replace

cap log close
