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

local PAIS     SLV
local ENCUESTA EHPM
local ANO      2025
local ronda    a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: El Salvador
Encuesta: EHPM
Round: a
Autores: Matías Isla y David Cornejo (SCL/SCL)
Version: 27/02/2026
Mail: matiasi@iadb.org/dcor@iadb.org, 15 de abril de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use `base_in', clear


**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c = .
	replace region_BID_c = 1

	********************
	*** region_c ****
	********************
	/* r004 vuelve en 2025 (ausente en 2024) */
	gen byte region_c = r004
	label define region_c   ///
	1  "Ahuachapán"      ///
	2  "Santa Ana"       ///
	3  "Sonsonate"       ///
	4  "Chalatenango"    ///
	5  "La Libertad"     ///
	6  "San Salvador"    ///
	7  "Cuscatlán"       ///
	8  "La Paz"          ///
	9  "Cabañas"         ///
	10 "San Vicente"     ///
	11 "Usulután"        ///
	12 "San Miguel"      ///
	13 "Morazán"         ///
	14 "La Unión"
	label value region_c region_c

	*************
	* pais_c    *
	*************
	gen str3 pais_c = "SLV"

	******
	*anio*
	******
	gen int anio_c = 2025

	******
	*mes_c*
	******
	gen int mes_c = r015

	******
	*zona*
	******
	/* area vuelve en 2025 (ausente en 2024) */
	gen byte zona_c = .
	replace zona_c = 1 if area == 1   /* Urbano (área==1) */
	replace zona_c = 0 if area == 0   /* Rural  (área==0) */

	*********
	*estrato*
	*********
	/* estratoarea vuelve en 2025 (ausente en 2024) */
	gen estrato_ci = estratoarea

	***************
	***upm_ci***
	***************
	gen upm_ci = .

	******************
	*idh_ch (idhogar)*
	******************
	gen idh_ch = idboleta
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(idh_ch r101)
	tostring idp_ci, replace format("%20.0f")

	***********
	*factor_ci*
	***********
	gen factor_ci = fac00

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch = fac00


****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci = .
	replace sexo_ci = 1 if r104 == 1
	replace sexo_ci = 2 if r104 == 2

	*********
	*edad_ci*
	*********
	gen int edad_ci = .
	replace edad_ci = r106 if r106 >= 0

	**************
	**relacion_ci**
	**************
	/* r103: 1=Jefe, 2=Cónyuge, 3=Hijo, 4–9=Otros parientes, 10=Empleada dom., 11=No pariente */
	gen byte relacion_ci = .
	replace relacion_ci = 1 if r103 == 1
	replace relacion_ci = 2 if r103 == 2
	replace relacion_ci = 3 if r103 == 3
	replace relacion_ci = 4 if r103 >= 4 & r103 <= 9
	replace relacion_ci = 5 if r103 == 11
	replace relacion_ci = 6 if r103 == 10

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	*****************
	*miembros_one_ci* 
	*****************
	/* EHPM no tiene metodología propia de "miembros del hogar" alternativa */
	gen byte miembros_one_ci = miembros_ci

	**************
	*Estado Civil* (civil_ci)
	**************
	/* r107: 1=casado, 2=unión libre, 3=soltero, 4=divorciado/separado, 5=separado(a), 6=viudo */
	gen byte civil_ci = .
	replace civil_ci = 1 if r107 == 6           /* viudo(a)          */
	replace civil_ci = 2 if r107 == 1 | r107 == 2   /* casado/unión      */
	replace civil_ci = 3 if r107 == 4 | r107 == 5   /* divorciado/separ. */
	replace civil_ci = 4 if r107 == 3           /* soltero(a)        */

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

	***************
	*notronopari_ch*
	***************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	replace notronopari_ch = . if relacion_ci == .

	***********
	*nempdom_ch*
	***********
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)
	replace nempdom_ch = . if relacion_ci == .

	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci <= 5)
	replace nmiembros_ch = . if relacion_ci == .

	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))

	**********
	*nmenor6_ch*
	**********
	by idh_ch, sort: egen byte nmenor6_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))

	**********
	*nmenor1_ch*
	**********
	by idh_ch, sort: egen byte nmenor1_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
/* EHPM 2025 no incluye preguntas de autoidentificación étnica ni
   discapacidad Washington Group, todas las variables de diversidad se crean vacías */

	*********
	*afro_ci*
	*********
	gen byte afro_ci = .

	*********
	*ind_ci*
	*********
	gen byte ind_ci = .

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .

	************
	*afroind_ci*
	************
	gen byte afroind_ci = .

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

	***************
	*afroind_ano_c*
	***************
	gen int afroind_ano_c = .

	********
	*dis_ci*
	********
	gen byte dis_ci = .
	/* EHPM 2025 no incluye preguntas Washington Group de discapacidad */

	**********
	*disWG_ci*
	**********
	gen byte disWG_ci = .

	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	*****************
	*SLV_dis_ci*
	*****************
	gen byte SLV_dis_ci = dis_ci

*******************************************************
***          VARIABLES DE MERCADO LABORAL           ***
*******************************************************

	***************
	**condocup_ci**
	***************
	/* r403: realizó trabajo la semana anterior
	   r404x: preguntas de actividad específicas (agricultura, pesca, etc.)
	   r405/r405b: tiene empleo/negocio al que volverá
	   r406: razón por la que no trabajó (<5 = vuelve al trabajo = ocupado)
	   r407: buscó trabajo */
	gen byte condocup_ci = .
	replace condocup_ci = 1 if inlist(1, r403, r4041, r4041_1, r4042, ///
		r4043, r4044, r4045, r4046, r4047, r4048, r4049, r405, r405b) | r406 < 5
	replace condocup_ci = 2 if condocup_ci != 1 & r407 == 1
	replace condocup_ci = 3 if condocup_ci != 1 & condocup_ci != 2 & edad_ci >= 15
	replace condocup_ci = 4 if edad_ci < 15

	*******************
	***categoinac_ci***
	*******************
	/* r409: razón por la que no buscó trabajo
	   13=jubilado/pensionado, 8=estudiante, 12=ama de casa, 3=desalentado */
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if r409 == 13 & condocup_ci == 3
	replace categoinac_ci = 2 if r409 == 8  & condocup_ci == 3
	replace categoinac_ci = 3 if r409 == 12 & condocup_ci == 3
	replace categoinac_ci = 4 if (categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3

	***********
	**emp_ci***
	***********
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No " 1"Si", add
	label value emp_ci emp_ci

	*************
	**cesante_ci**
	*************
	/* r410: ha trabajado antes (1=Sí) */
	gen byte cesante_ci = .
	replace cesante_ci = 1 if r410 == 1 & condocup_ci == 2
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci == 2

	*************
	**desemp_ci***
	*************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci

	***************
	**horaspri_ci**
	***************
	/* r411a: horas lun-vie; r411d: horas sáb-dom semana anterior
	   h411a (pre-calculado INE) = rsum(r411a, r411d) se mantiene la fórmula explícita
	   para trazabilidad y comparabilidad interanual */
	egen byte horaspri_ci = rsum(r411a r411d) if emp_ci == 1
	replace horaspri_ci = . if emp_ci == 0

	*************
	**subemp_ci***
	*************
	/* r413: razón por la que trabaja <40 horas (2,3 = no quiere más horas) */
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if horaspri_ci <= 30 & emp_ci == 1 & (r413 == 2 | r413 == 3)

	*************
	**durades_ci**
	*************
	/* r407a_s: semanas buscando trabajo - convertir a meses */
	gen byte durades_ci = floor(r407a_s / (52/12))

	**********
	**pea_ci**
	**********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	***************
	**nempleos_ci**
	***************
	/* r432: tiene ocupación secundaria (1=No, 2=Sí) */
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1 & r432 == 2
	replace nempleos_ci = 2 if emp_ci == 1 & r432 == 1
	replace nempleos_ci = . if emp_ci == 0

	***************
	**antiguedad_ci**
	***************
	/* EHPM 2025 no tiene pregunta directa de antigüedad en el empleo */
	gen byte antiguedad_ci = .

	*************
	**desalent_ci**
	*************
	/* r409==3: desalentado (no buscó porque cree que no hay trabajo) */
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if ((r407 == 2 & (r409 == 2 | r409 == 3) & condocup_ci == 3))
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	*************
	**horastot_ci**
	*************
	/* Total horas trabajadas en todos los empleos */
	egen byte horastot_ci = rsum(horaspri_ci r433) if emp_ci == 1
	replace horastot_ci = . if horaspri_ci == . & r433 == .
	replace horastot_ci = . if emp_ci == 0

	****************
	**tiempoparc_ci**
	****************
	/* Empleo a tiempo parcial voluntario: <30 horas y quisiera más */
	gen byte tiempoparc_ci = ((horaspri_ci >= 1 & horaspri_ci < 30) & r413 == 1 & emp_ci == 1)
	replace tiempoparc_ci = . if emp_ci == 0

	****************
	**categopri_ci**
	****************
	/* r418 en 2025 (etiquetas verificadas en data):
	   1 = Empleador(a) o patrono(a)      - 1 (patrón)
	   2 = Cuenta propia con local        - 2 (cuenta propia)
	   3 = Cuenta propia sin local        - 2 (cuenta propia)
	   5 = Familiar no remunerado         - 4 (no remunerado)
	   6 = Asalariado(a) permanente       - 3 (asalariado)
	   7 = Asalariado(a) temporal         - 3 (asalariado)
	   8 = Aprendiz                       - 0 (otra clasificación)
	   9 = Servicio doméstico             - 3 (asalariado doméstico) */
	gen byte categopri_ci = .
	replace categopri_ci = 1 if r418 == 1 & emp_ci == 1                    /* patrón/empleador  */
	replace categopri_ci = 2 if inlist(r418, 2, 3) & emp_ci == 1           /* cuenta propia     */
	replace categopri_ci = 3 if inlist(r418, 6, 7, 9) & emp_ci == 1        /* asalariado        */
	replace categopri_ci = 4 if r418 == 5 & emp_ci == 1                    /* no remunerado     */
	replace categopri_ci = 0 if r418 == 8 & emp_ci == 1                    /* aprendiz (otra)   */
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1            /* residual          */

	****************
	**categosec_ci**
	****************
	gen byte categosec_ci = .

	***********
	**rama_ci**
	***********
	gen byte rama_ci = .
	replace rama_ci = 1 if (r416 >= 100  & r416 <= 322) & emp_ci == 1   /* Agric/pesca/forest */
	replace rama_ci = 2 if (r416 >= 510  & r416 <= 990) & emp_ci == 1   /* Minería            */
	replace rama_ci = 3 if (r416 >= 1010 & r416 <= 3320) & emp_ci == 1  /* Manufactura        */
	replace rama_ci = 4 if (r416 >= 3510 & r416 <= 3900) & emp_ci == 1  /* Electricidad/agua  */
	replace rama_ci = 5 if (r416 >= 4100 & r416 <= 4390) & emp_ci == 1  /* Construcción       */
	replace rama_ci = 6 if ((r416 >= 4510 & r416 <= 4799) | (r416 >= 5510 & r416 <= 5630)) & emp_ci == 1  /* Comercio */
	replace rama_ci = 7 if ((r416 >= 4911 & r416 <= 5320) | (r416 >= 6110 & r416 <= 6190)) & emp_ci == 1  /* Transporte/telecom */
	replace rama_ci = 8 if (r416 >= 6411 & r416 <= 8299) & emp_ci == 1  /* Financiero/inmob.  */
	replace rama_ci = 9 if ((r416 >= 5811 & r416 <= 6022) | (r416 >= 6201 & r416 <= 6399) | (r416 >= 8411 & r416 <= 9900)) & emp_ci == 1  /* Servicios comunales */
	replace rama_ci = 9 if emp_ci == 1 & rama_ci == .

	***************
	**spublico_ci**
	***************
	/* rama_ci solo llega a 9 en esta encuesta.
	   Se usa r420 (sector) que existe en el dataset: 1=público, 2=privado */
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & r420 == 2
	replace spublico_ci = 0 if emp_ci == 1 & r420 == 1

	*************
	**tamemp_ci**
	*************
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if (r421 >= 1  & r421 <= 5  & r421 != .)  | r421a == 1
	replace tamemp_ci = 2 if (r421 >= 6  & r421 <= 50 & r421 != .)  | inlist(r421a, 2, 3)
	replace tamemp_ci = 3 if (r421 > 50 & r421 != .) | (r421a > 3 & r421a != .)
	replace tamemp_ci = . if condocup_ci != 1

	**************
	**cotizando_ci**
	**************
	/* r422a en 2025 tiene 3 categorías: 1=Sí afiliado, 2=Sí cotizante, 3=No
	   r422f = Cobertura AFP
	   r422g = Cobertura INPEP
	   trabajadores sector público cotizan INPEP; privados cotizan AFP */
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****. 
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((r422a == 2 | r422f == 2 | r422g == 2) & emp_ci==1)
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	*****************
	*** instcot_ci ***
	*****************
	/* r501: tipo de seguro médico (1=ISSS activo, 2=BM Bienestar Magisterial, etc.) */
	gen byte instcot_ci = .
	replace instcot_ci = 1 if cotizando_ci == 1 & r501 <= 3   /* ISSS         */
	replace instcot_ci = 2 if cotizando_ci == 1 & r501 == 4   /* BM           */
	replace instcot_ci = 3 if cotizando_ci == 1 & r501 == 5   /* Hosp. Militar*/
	replace instcot_ci = 4 if cotizando_ci == 1 & r501 == 6   /* Colectivo    */
	replace instcot_ci = 5 if cotizando_ci == 1 & r501 == 7   /* Individual   */
	replace instcot_ci = 6 if cotizando_ci == 1 & r501 == 9   /* Otros        */
	label define instcot_ci 1 "ISSS" 2 "Bienestar Magisterial" 3 "Hospital Militar" ///
		4 "Colectivo" 5 "Individual (Privado)" 6 "Otros"
	label value instcot_ci instcot_ci

	*************
	**afiliado_ci**
	*************
	/* r501: 1=ISSS retirado/jubilado, 2=BM retirado - afiliado sin cotizar */
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if ((r501 >= 1 & r501 <= 2) & emp_ci==1)
	replace afiliado_ci = 0 if (r501 > 2 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci

	***********
	**formal_ci**
	***********
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	******************
	**tipocontrato_ci**
	******************
	/* r419:
	   1 = Sí, duración indefinida       - 1 (indefinido)
	   2 = Sí, por un plazo fijo         - 2 (temporal)
	   3 = Sí, contrato de prueba        - 2 (temporal)
	   4 = Sí, para realizar un servicio - 2 (temporal)
	   6 = Sí, otro tipo de contrato     - 2 (temporal/otro)
	   7 = No (sin contrato)             - 3 (sin contrato)
	   8 = No sabe/No responde           - 0 (NS/NR) */
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if r419 == 1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if inlist(r419, 2, 3, 4, 6) & categopri_ci == 3
	replace tipocontrato_ci = 3 if r419 == 7 & categopri_ci == 3
	replace tipocontrato_ci = 0 if r419 == 8 & categopri_ci == 3

	***********
	**ocupa_ci**
	***********
	gen byte ocupa_ci = .
	replace ocupa_ci = 1 if emp_ci == 1 & inrange(r414, 2111, 3522)                                          /* Técnicos/profesionales */
	replace ocupa_ci = 2 if emp_ci == 1 & inrange(r414, 1110, 1439)                                          /* Directivos             */
	replace ocupa_ci = 3 if emp_ci == 1 & inrange(r414, 4110, 4419)                                          /* Empleados de oficina   */
	replace ocupa_ci = 4 if emp_ci == 1 & (inrange(r414, 9510, 9520) | inrange(r414, 5210, 5249))            /* Vendedores             */
	replace ocupa_ci = 5 if emp_ci == 1 & (inrange(r414, 5111, 5169) | inrange(r414, 9111, 9129) | ///
		inrange(r414, 5311, 5419) | inrange(r414, 9610, 9629))                                                /* Servicios              */
	replace ocupa_ci = 6 if emp_ci == 1 & (inrange(r414, 6110, 6340) | inrange(r414, 9210, 9220))            /* Agropecuarios          */
	replace ocupa_ci = 7 if emp_ci == 1 & (inrange(r414, 7111, 8350) | inrange(r414, 9311, 9412))            /* Artesanos/operadores   */
	replace ocupa_ci = 8 if emp_ci == 1 & inrange(r414, 110, 310)                                            /* Fuerzas Armadas        */
	replace ocupa_ci = 9 if emp_ci == 1 & !inlist(ocupa_ci, 1, 2, 3, 4, 5, 6, 7, 8)                         /* Otros                  */


*******************************************************
***             VARIABLES DE PENSIONES              ***
*******************************************************

	***********
	**pension_ci**
	***********
	gen byte pension_ci = .
	replace pension_ci = 1 if ingreso_pensiones > 0 & ingreso_pensiones != .
	replace pension_ci = 0 if pension_ci != 1 & condocup_ci != .

	***************
	**pensionsub_ci**
	***************
	/* r319a5: recibe pensión básica universal */
	gen byte pensionsub_ci = .
	replace pensionsub_ci = 1 if r319a5 == 1
	replace pensionsub_ci = 0 if pensionsub_ci != 1 & r319a5 != .

	***********
	**tipopen_ci**
	***********
	gen byte tipopen_ci = .

	***********
	**instpen_ci**
	***********
	gen byte instpen_ci = .


*******************************************************
*** 	VARIABLES DE INGRESO & PROTECCION SOCIAL    ***
*******************************************************

	**************************
	*** INGRESO INDIVIDUAL ***
	**************************

*A. INGRESOS LABORALES A NIVEL DE INDIVIDUO	

	***************
	***ylmpri_ci***
	***************
	/* Para asalariados: imeds (salario mensual neto)
	   Bonos anuales: horas extra, vacaciones, aguinaldo, bonificación, propinas - /12 */
	gen double yprid          = imeds
	gen double hrsextrasd     = r42501a * r42501b / 12
	gen double vacacionesd    = r42502a * r42502b / 12
	gen double aguinaldod     = r42503a * r42503b / 12
	gen double bonificacionesd= r42504a * r42504b / 12
	gen double propina        = r42511a * r42511b / 12
	egen double yprijbd       = rsum(yprid hrsextrasd vacacionesd aguinaldod bonificacionesd propina), missing
	drop yprid hrsextrasd vacacionesd aguinaldod bonificacionesd propina

	/* Para independientes: imei (ingreso empleo independiente) */
	gen double yprijbi = imei

	egen double ylmpri_ci = rsum(yprijbi yprijbd), missing
	drop yprijbi yprijbd

	***************
	***ylnmpri_ci***
	***************
	/* Ingresos en especie del empleo principal */
	gen double food1   = r42505a * r42505b / 12
	gen double ropa1   = r42506a * r42506b / 12
	gen double merca1  = r42507a * r42507b / 12
	gen double vivi1   = r42508a * r42508b / 12
	gen double trans1  = r42509a * r42509b / 12
	gen double segur1  = r42510a * r42510b / 12
	gen double otross1 = r42512a * r42512b / 12
	egen double ylnmpri_ci = rsum(food1 ropa1 merca1 vivi1 trans1 segur1 otross1), missing
	replace ylnmpri_ci = . if emp_ci != 1
	drop food1 ropa1 merca1 vivi1 trans1 segur1 otross1

	***************
	***ylmsec_ci***
	***************
	/* r434: ingreso empleo secundario + bonos anuales /12 */
	gen double hrsextrasd1      = r43501a * r43501b / 12
	gen double vacacionesd1     = r43502a * r43502b / 12
	gen double aguinaldod1      = r43503a * r43503b / 12
	gen double bonificacionesd1 = r43504a * r43504b / 12
	gen double propina1         = r43511a * r43511b / 12
	egen double yprijbd1        = rsum(hrsextrasd1 vacacionesd1 aguinaldod1 bonificacionesd1 propina1), missing
	egen double ylmsec_ci       = rsum(r434 yprijbd1), missing
	replace ylmsec_ci = . if emp_ci != 1
	drop hrsextrasd1 vacacionesd1 aguinaldod1 bonificacionesd1 propina1 yprijbd1

	*****************
	***ylnmsec_ci***
	*****************
	/* Ingresos en especie del empleo secundario */
	gen double food2   = r43505a * r43505b / 12
	gen double ropa2   = r43506a * r43506b / 12
	gen double merca2  = r43507a * r43507b / 12
	gen double vivi2   = r43508a * r43508b / 12
	gen double trans2  = r43509a * r43509b / 12
	gen double segur2  = r43510a * r43510b / 12
	gen double otross2 = r43512a * r43512b / 12
	egen double ylnmsec_ci = rsum(food2 ropa2 merca2 vivi2 trans2 segur2 otross2), missing
	replace ylnmsec_ci = . if emp_ci != 1
	drop food2 ropa2 merca2 vivi2 trans2 segur2 otross2

	*****************
	***ylmotros_ci***
	*****************
	gen double ylmotros_ci = .

	*****************
	***ylnmotros_ci***
	*****************
	gen double ylnmotros_ci = .

	***********
	**ylm_ci***
	***********
	egen double ylm_ci = rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	replace ylm_ci = . if ylmpri_ci == . & ylmsec_ci == . & ylmotros_ci == .

	***********
	**ylnm_ci***
	***********
	egen double ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci = . if ylnmpri_ci == . & ylnmsec_ci == . & ylnmotros_ci == .


*B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO	

	********************************************************
	*** ytransf_ci: Transferencias de programas sociales ***
	********************************************************
	// No está disponible la Sección 7: Subsidios al hogar de parte del gobierno (r7*)
		
		* PNC - Pensiones sociales no contributivas:
			* 1 Pensión Básica Universal del Adulto Mayor r319a5==1 // nivel hogar (Sin monto)
		* PTMC - Programas de transferencias monetarias condicionadas:
			* 2 Becas: Beca de cuota escolar y Beca para matrícula  r211d== 1 | r211e==1 (Sin monto)
			* 3 Bono para Comunidades Solidarias (rurales y urbanas) r319a3== 1| r319a4== 1 // nivel hogar (Sin monto)
		* POTROT - Programas de otras transferencias monetarias no condicionadas
			* 4 Otras ayudas del gobierno en efectivo (r44106)
		
	*** Beneficiarios a nivel individual:
		
		// PNC
		gen byte pnc_ci = .		// Información solo a nivel hogar
	
		// PTMC
		gen byte becaesc_ci = (r211d == 1 | r211e == 1)
		replace becaesc_ci = . if r211d == . & r211e == .
		gen byte solidario_ci = . 	// Información solo a nivel hogar
		gen byte ptmc_ci = (becaesc_ci == 1 | solidario_ci == 1)
		replace ptmc_ci = . if becaesc_ci == . & solidario_ci == .
		
		// POTROT
		gen byte potrot_ci = (r44106 > 0) if !missing(r44106)
		
	*** Montos de transferencias a nivel individual: (No hay montos disponibles para este año)
	
		gen ypnc_ci = .		// Transferencias PNC
		gen yptmc_ci = . 	// Transferencias PTMC 
		gen yotrot_ci = r44106/12 if potrot_ci == 1 	// Otras transferencias POTROT
	
	*** Ingreso individual por transferencias no contributivas
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi
	
	****************
	***remesas_ci***
	****************
	/* Desde el 2022 se incluye la variable remesas monetarias habituales individuales (irefa a nivel hogar) */
	gen double remesa_nm = irefb if relacion_ci == 1 & irefb > 0 & irefb != .
	gen double remesa_esp = ires if relacion_ci == 1 & ires > 0 & ires != .
	
	egen double remesas_ci = rowtotal(ingreso_remesas remesa_nm remesa_esp), mi
		
	*************
	*ypen_ci*
	*************
	gen double ypen_ci = ingreso_pensiones if (ingreso_pensiones > 0 & ingreso_pensiones != .) 
	
	*****************
	**  ypensub_ci  *
	*****************
	* No se puede determinar el monto de la pension basica universal (sólo existe el filtro r319a5)
	gen ypensub_ci = .
	
	***************
	*** ynlm_ci ***
	***************
	/* Ingresos no laborales monetarios: remesas (r44001), cuota alimenticia, alquileres, pensiones, ahorros, etc.
	   + utilidades, dividendos, herencias, ayudas gubernamentales, etc. (anuales /12) */
		gen double remesas_temp   = r44001a * r44001b / 12  /* "remesas" Nacionales (transferencias desde otros hogares del país) */
		gen double cuotalim       = r44002a * r44002b / 12
		gen double alqui          = r44003a * r44003b / 12
		gen double alqneg         = r44004a * r44004b / 12
		gen double alqterr        = r44005a * r44005b / 12
		gen double jubil          = ingreso_pensiones		 // ypen_ci
		gen double deveh          = r44007a * r44007b / 12
		gen double pension_temp   = r44008a * r44008b / 12   /* pensión por sobrevivencia */
		gen double ahorros        = r44009a * r44009b / 12
		gen double otros_nl       = r44010a * r44010b / 12
		
		gen double utilidades     = r44101 / 12
		gen double dividendos     = r44102 / 12
		gen double intereses      = r44103 / 12
		gen double herencias      = r44104 / 12
		gen double indemnizacion  = r44105 / 12
		gen double ayudagob       = r44106 / 12		// ytransf_ci
		gen double acteventual    = r44107 / 12
		gen double arrendamiento  = r44108 / 12
		*gen double remesaevent1   = r44109 / 12	// Se excluyen porque son ingresos excepcionales de "remesas" Nacionales
		gen double aguinaldo_nl   = r44110 / 12
		gen double otrosy         = r44111 / 12
	
	egen double ynlm_ci = rowtotal(remesas_temp cuotalim alqui alqneg alqterr ypen_ci deveh pension_temp ahorros otros_nl utilidades dividendos intereses herencias indemnizacion acteventual arrendamiento aguinaldo_nl otrosy ytransf_ci remesas_ci), mi
	drop remesas_temp cuotalim alqui alqneg alqterr jubil deveh pension_temp ahorros otros_nl utilidades dividendos intereses herencias indemnizacion ayudagob acteventual arrendamiento aguinaldo_nl otrosy

	************
	**ynlnm_ci**
	************
	gen double ynlnm_ci = .

	***********
	**ytot_ci**
	***********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi
	
	***************
	*** ynet_ci ***
	***************
	gen double aux_ytransf_ci = ytransf_ci*(-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
	drop aux_ytransf_ci
	

	*************************
	*** INGRESO DEL HOGAR ***
	*************************

	**************
	*** ylm_ch ***
	**************
	by idh_ch, sort: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi

	***************
	*** ylnm_ch ***
	***************
	by idh_ch, sort: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi
	
	******************
	*** ytransf_ch ***
	****************** 
	
	*** Beneficiarios a nivel hogar:
		gen byte pnc_ch = (r319a5 == 1) if !missing(r319a5) & miembros_ci == 1
		
		bys idh_ch: egen byte becaesc_ch = max(becaesc_ci)	
		gen byte solidario_ch = (r319a3 == 1 | r319a4 == 1)	
		replace solidario_ch = . if r319a3 == . & r319a4 == .
	
		gen byte ptmc_ch = (becaesc_ch == 1 | solidario_ch == 1) if miembros_ci == 1
		replace ptmc_ch = (becaesc_ch == . & solidario_ch == .)
		
		bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
		
		gen byte pcasht_ch = (pnc_ch == 1 | ptmc_ch == 1 | potrot_ch == 1)
		replace pcasht_ch = . if pnc_ch == . & ptmc_ch == . & potrot_ch == .
		
	*** Montos de transferencias a nivel hogar:  (No hay montos disponibles para este año)
	
		gen ypnc_ch = .	 
		gen yptmc_ch = .
		bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi
	
	*** Ingreso del Hogar por transferencias no contributivas
	egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi
	
	******************
	*** remesas_ch ***
	******************
	/* A nivel de hogar: totayuda = remesas habituales (irefa) + remesas eventuales (irefb) + remesas especie (ires) 
	Son equivalentes a la variable "totayuda" */
	bys idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, mi
	
	***************
	*** ynlm_ch ***
	***************
	bys idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, mi

	***********
	**ynlnm_ch**
	***********
	gen double ynlnm_ch = .

	***********
	**ytot_ch**
	***********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
	
	***************
	*** ynet_ch ***
	***************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	***************
	**ylmhopri_ci**
	***************
	gen double ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	***********
	**ylmho_ci**
	***********
	gen double ylmho_ci = ylm_ci / (4.3 * horastot_ci)
	replace ylmho_ci = . if ylmho_ci <= 0

	**************
	**nrylmpri_ci**
	**************
	gen byte nrylmpri_ci = .
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1

	**************
	**nrylmpri_ch**
	**************
	by idh_ch, sort: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1

	***************
	**rentaimp_ch**
	***************
	/* r310a: valor imputado de alquiler para propietarios */
	gen double rentaimp_ch = r310a

	***************
	**autocons_ci**
	***************
	gen double autocons_ci = .

	***************
	**autocons_ch**
	***************
	gen double autocons_ch = .

	***************
	**tcylmpri_ci**
	***************
	gen double tcylmpri_ci = .

	***************
	**tcylmpri_ch**
	***************
	gen double tcylmpri_ch = .


****************************
***VARIABLES DE EDUCACION***
****************************

	*********
	*aedu_ci*
	*********
	/* aproba1: número de grados aprobados */
	gen byte aedu_ci = aproba1

	**********
	*eduui_ci*
	**********
	/* Ingresó a universidad o técnico superior
	   r204: nivel que cursa actualmente (4=bachillerato, 5=universitario)
	   r214: último nivel que cursó y aprobó (4=bachillerato, 5=universitario) */
	gen byte eduui_ci = (inlist(r204, 4, 5)) | (inlist(r214, 4, 5) & inlist(r217, 1, 2, 3))
	replace eduui_ci = . if aedu_ci == .

	**********
	*eduuc_ci*
	**********
	/* Completó universidad/técnico superior
	   r217: título o diploma (4–9 = tiene título) */
	gen byte eduuc_ci = (inlist(r214, 4, 5) & inrange(r217, 4, 9))
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	/* 1=bachillerato, 0=universitario (máximo nivel completado)
	   r204∈{4,5} = cursando bachillerato/universidad actualmente.
	   Si r204=4 (cursando bach.) pero r214 < 4 (no completado aún) */
	gen byte eduac_ci = .
	replace eduac_ci = 1 if r214 == 4
	replace eduac_ci = 0 if r214 == 5
	replace eduac_ci = 0 if r204 == 4 & eduac_ci == .   /* cursando bach., aún no completado */
	replace eduac_ci = 1 if r204 == 5 & eduac_ci == .   /* cursando univ. - bach. completado (prerequisito) */

	***********
	*edupre_ci*
	***********
	/* r209: asistió a la parvularia (1=Sí, 0=No) */
	gen byte edupre_ci = .
	replace edupre_ci = 1 if r209 == 1
	replace edupre_ci = 0 if r209 == 0

	************
	*asispre_ci*
	************
	/* r203==1: asiste actualmente; r204==1: nivel parvularia */
	gen byte asispre_ci = (r203 == 1 & r204 == 1)

	***********
	*asiste_ci*
	***********
	gen byte asiste_ci = (r203 == 1)
	replace asiste_ci = . if r203 == .

	***************
	*razonesnoasis_ci*
	***************
	/* r219: razón por la que no estudia */
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if r219 == 3                                         /* No tiene edad   */
	replace razonesnoasis_ci = 2 if r219 == 1                                         /* Costo/economía  */
	replace razonesnoasis_ci = 3 if inlist(r219, 4, 5, 6)                            /* Trabajo         */
	replace razonesnoasis_ci = 4 if r219 == 10                                        /* No le interesa  */
	replace razonesnoasis_ci = 5 if inlist(r219, 2, 12, 15, 16)                      /* Embarazo/familia*/
	replace razonesnoasis_ci = 6 if r219 == 8                                         /* Enfermedad/disc.*/
	replace razonesnoasis_ci = 7 if r219 == 7                                         /* Distancia/acceso*/
	replace razonesnoasis_ci = 8 if inlist(r219, 9, 13, 14, 18)                      /* Terminó         */
	replace razonesnoasis_ci = 9 if inlist(r219, 11, 17)                              /* Otros           */

	***********
	*edupub_ci*
	***********
	/* r210a: tipo de centro (1=público, 2–3=privado) - solo para quienes asisten */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if r210a == 1 & r203 == 1
	replace edupub_ci = 0 if (r210a == 2 | r210a == 3) & r203 == 1


****************************
***VARIABLES DE VIVIENDA***
****************************

	*********
	*luz_ch*
	*********
	/* r311: tipo de alumbrado (1,2=elec. público/privado, 5,6=elec. c/prepago; 3,4,7=otros) */
	gen byte luz_ch = .
	replace luz_ch = 1 if inlist(r311, 1, 2, 5, 6)
	replace luz_ch = 0 if inlist(r311, 3, 4, 7)

	***********
	*luzmide_ch*
	***********
	gen byte luzmide_ch = .

	***********
	*combust_ch*
	***********
	/* r320: combustible principal para cocinar (1–3=gas/elec/otro limpio; 4–6=leña/carbón/otro) */
	gen byte combust_ch = .
	replace combust_ch = 1 if inlist(r320, 1, 2, 3)
	replace combust_ch = 0 if inlist(r320, 4, 5, 6)

	*********
	*piso_ch*
	*********
	/* metodología en revisión */
	gen piso_ch = .

	**********
	*pared_ch*
	**********
	/* metodología en revisión */
	gen pared_ch = .

	**********
	*techo_ch*
	**********
	/* metodología en revisión */
	gen techo_ch = .

	*********
	*resid_ch*
	*********
	/* r322: forma de deshacerse de la basura */
	gen byte resid_ch = .
	replace resid_ch = 0 if inlist(r322, 1, 2)   /* recolección municipal/privada = aceptable */
	replace resid_ch = 1 if inlist(r322, 4, 5)   /* quema/entierra */
	replace resid_ch = 2 if r322 == 6             /* arroja a cuerpo de agua */
	replace resid_ch = 3 if inlist(r322, 3, 7)   /* bota a la calle/terreno baldío/otro */

	*********
	*dorm_ch*
	*********
	gen byte dorm_ch = r306
	replace dorm_ch = . if r306 == .

	***********
	*cuartos_ch*
	***********
	gen byte cuartos_ch = r305
	replace cuartos_ch = . if r305 == .

	*********
	*cocina_ch*
	*********
	gen byte cocina_ch = .

	*********
	*telef_ch*
	*********
	/* r3211a: tiene teléfono fijo (1=Sí, 2=No) */
	gen byte telef_ch = .
	replace telef_ch = 1 if r3211a == 1
	replace telef_ch = 0 if r3211a == 2

	*********
	*refrig_ch*
	*********
	/* r32305a: tiene refrigeradora (1=Sí, 2=No) */
	gen byte refrig_ch = .
	replace refrig_ch = 1 if r32305a == 1
	replace refrig_ch = 0 if r32305a == 2

	*******
	*freez_ch*
	*******
	gen byte freez_ch = .

	*******
	*auto_ch*
	*******
	/* r32312a: tiene vehículo (1=Sí, 2=No) */
	gen byte auto_ch = .
	replace auto_ch = 1 if r32312a == 1
	replace auto_ch = 0 if r32312a == 2

	*******
	*compu_ch*
	*******
	/* r32309a: tiene computadora (1=Sí, 2=No) */
	gen byte compu_ch = .
	replace compu_ch = 1 if r32309a == 1
	replace compu_ch = 0 if r32309a == 2

	**********
	*internet_ch*
	**********
	/* r3213a: tiene internet (1=Sí, 2=No) */
	gen byte internet_ch = .
	replace internet_ch = 1 if r3213a == 1
	replace internet_ch = 0 if r3213a == 2

	*******
	*cel_ch*
	*******
	/* r3212a: tiene teléfono celular (1=Sí, 2=No) */
	gen byte cel_ch = .
	replace cel_ch = 1 if r3212a == 1
	replace cel_ch = 0 if r3212a == 2

	*******
	*vivi1_ch*
	*******
	/* r301: tipo de vivienda (1=casa, 2=apartamento, 3–9=otros) */
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if r301 == 1
	replace vivi1_ch = 2 if r301 == 2
	replace vivi1_ch = 3 if r301 >= 3 & r301 <= 9

	*******
	*vivi2_ch*
	*******
	gen byte vivi2_ch = .

	**********
	*viviprop_ch*
	**********
	gen byte viviprop_ch = .
	replace viviprop_ch = 0 if r308 == 2   /* alquilada                  */
	replace viviprop_ch = 1 if r308 == 1   /* propia totalmente pagada    */
	replace viviprop_ch = 2 if r308 == 3   /* propia pagando a plazos     */
	replace viviprop_ch = 3 if r308 >= 4 & r308 < 9  /* cedida/otra       */
	replace viviprop_ch = . if r308 == .

	**********
	*vivitit_ch*
	**********
	gen byte vivitit_ch = .

	**********
	*vivialq_ch*
	**********
	gen double vivialq_ch = r308c if r308 == 2

	**************
	*vivialqimp_ch*
	**************
	/* r310a: valor que pagaría mensualmente si alquilara (imputado) */
	gen int vivialqimp_ch = r310a


****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch = .
	replace aguared_ch = 1 if r312 >= 1 & r312 <= 4
	replace aguared_ch = 1 if r312 == 6   /* tiene cañería pero sin servicio activo */
	replace aguared_ch = 0 if r312 == 5   /* no tiene cañería */

	*****************
	*aguafconsumo_ch*
	*****************
	gen byte aguafconsumo_ch = 0   /* se asume que el agua disponible se consume */

	***************
	*aguafuente_ch*
	***************
/* r312 ¿Tiene la vivienda servicio de agua por cañería?
           1 Dentro de la vivienda con abastecimiento público (ANDA)
           2 Dentro de la vivienda con otro tipo de abastecimiento
           3 Fuera de la vivienda pero dentro de la propiedad con abastecimiento público (ANDA)
           4 Fuera de la vivienda pero dentro de la propiedad con otro tipo de abastecimiento
		 4.1 Tubería por poliducto (buen estado)
           5 No tiene
           6 Tiene pero no le cae (por más de un mes)

r313 ¿Forma de abastecimiento de agua de la vivienda
           1 Cañería del vecino(a)
           2 Pila, chorro público o cantarera
           3 Camión, carreta o pipa
           4 Pozo con tubería privado
		 4.1 Pozo con tubería público
           5 Pozo protegido privado
		 5.1 Pozo protegido público
           6 Pozo no protegido privado
		 6.1 Pozo no protegido público
           7 Ojo de agua, río o quebrada
           8 Manantial protegido
           9 Manantial no protegido
          10 Colecta agua lluvia
          11 Acarreo de cañería del vecino(a)
          12 Chorro común
          13 Otros medios */

gen byte aguafuente_ch = .
replace aguafuente_ch = 1 if inlist(r312, 1, 2, 3, 4)	// Cañería (piped), red de distribución 
replace aguafuente_ch = 2  if inlist(r313, 2, 12)		// Llave pública, pila, standpipe
*replace aguafuente_ch = 3 if....						// Agua embotellada
replace aguafuente_ch = 4  if inlist(r313, 4, 4.1, 5, 5.1)	// Pozo protegido
replace aguafuente_ch = 5  if r313 == 10				// Agua de lluvia
replace aguafuente_ch = 6  if r313 == 3					// Camión, cisterna, aljibe
replace aguafuente_ch = 7  if r312 == 4.1				// Otra fuente mejorada
replace aguafuente_ch = 7  if inlist(r313, 1, 8, 11)	// Otra fuente mejorada
replace aguafuente_ch = 8  if r313 == 7					// Rio, vertiente, lago
replace aguafuente_ch = 9  if inlist(r313, 6, 6.1, 9)	// Otra fuente no mejorada  
replace aguafuente_ch = 10 if r313 == 13				// Otra fuente sin clasificación

	*************
	*aguadist_ch*
	*************
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if inlist(r312, 1, 2) | inlist(r313, 1, 2, 3, 4, 5, 6)  /* dentro/patio */
	replace aguadist_ch = 2 if inlist(r312, 3, 4, 6)                                  /* fuera predio */
	replace aguadist_ch = 3 if inlist(r313, 11, 12)                                   /* acarreo      */
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch != .              /* no clasif.   */

	**************
	*aguadisp1_ch*
	**************
	gen byte aguadisp1_ch = 9   /* no disponible en EHPM 2025 */

	**************
	*aguadisp2_ch*
	**************
	/* r312d: días/semana que cayó agua; r312h: horas/día
	   r312==6: tiene cañería pero sin agua - disp2=1 (menos de la mitad del tiempo) */
	gen byte aguadisp2_ch = .
	replace aguadisp2_ch = 1 if (r312d <= 3 | r312h <= 11) & r312d != . & r312h != .
	replace aguadisp2_ch = 2 if (r312d >= 4 & r312d != .) & (r312h >= 12 & r312h != .)
	replace aguadisp2_ch = 3 if r312d == 7 & r312h == 24
	replace aguadisp2_ch = 1 if r312 == 6   /* sin servicio activo - baja disponibilidad */

	***********
	*aguatrat_ch*
	***********
	gen byte aguatrat_ch = .

	***********
	*aguamala_ch*
	***********
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	**************
	*aguamejorada_ch*
	**************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	***********
	*aguamide_ch*
	***********
	gen byte aguamide_ch = .

	*******
	*bano_ch*
	*******
	/* r314: tiene servicio sanitario (1–2=sí, 3–4=no)
	   r316: tipo de servicio (si r314=1,2)
	   r317a: forma de desecho de excretas (si r314=1,2)
	   r316 en 2025:
	     1=Inodoro alcantarillado        - bano_ch=1 (mejorado)
	     2=Inodoro fosa séptica          - bano_ch=2 (mejorado)
	     3=Inodoro común alcantarillado  - bano_ch=1 (mejorado, compartido)
	     4=Inodoro común fosa séptica    - bano_ch=2 (mejorado, compartido)
	     5=Letrina privada               - bano_ch=6 (no clasificable)
	     6=Letrina común                 - bano_ch=6 (no clasificable)
	     7=Letrina abonera privada       - bano_ch=3 (mejorado per JMP)
	     8=Letrina abonera común         - bano_ch=3 (mejorado per JMP)
	     9=Letrina solar privada         - bano_ch=3 (mejorado per JMP) */
	gen byte bano_ch = .
	replace bano_ch = 1 if inlist(r316, 1, 3) & inlist(r314,1,2)  /* inodoro alcantarillado */
	replace bano_ch = 2 if inlist(r316, 2, 4)& inlist(r314,1,2)  /* inodoro fosa séptica   */
	replace bano_ch = 3 if inlist(r316, 7, 8, 9,10)& inlist(r314,1,2) /* letrina mejorada (JMP) */
	replace bano_ch = 6 if inlist(r316, 5, 6)                          /* letrina sin piso/común */
	replace bano_ch = 0 if inlist(r314, 3, 4)  

	*******
	*banoex_ch*
	*******
	gen byte banoex_ch = 9

	**********
	*sinbano_ch*
	**********
	gen byte sinbano_ch = 3
	replace sinbano_ch = 0 if bano_ch > 0 & bano_ch != .
	replace sinbano_ch = 1 if inlist(r314,3,4) & r315 == 1
	replace sinbano_ch = 1 if inlist(r314,3,4) & r315 == 2 & inlist(r317a, 1, 2)
	replace sinbano_ch = 2 if inlist(r314,3,4) & r315 == 2 & inlist(r317a, 3, 4)
	replace sinbano_ch =3 if inlist(r314,3,4) & r315 == 2 & r317a == 5

	**************
	*banomejorado_ch*
	**************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6


****************************
***VARIABLES DE MIGRACIÓN***
****************************
/* EHPM 2025 no tiene pregunta de lugar de nacimiento individual.
   r01a (miembro en el extranjero) es nivel hogar - no aplica para migrante_ci individual */

	*************
	*migrante_ci*
	*************
	gen byte migrante_ci = .

	***************
	*migrantiguo5_ci*
	***************
	gen byte migrantiguo5_ci = .

	**********
	*miglac_ci*
	**********
	gen byte miglac_ci = .

****************************
***VARIABLES EXTERNAS***
****************************

	****************
	 *tipo_bienestar*
	****************
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 

	***************
	*pobre_ine_ci*
	***************
	/* pobreza: 1=extrema, 2=moderada, 3=no pobre */
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci = 0 if pobreza == 3
	replace pobre_ine_ci = 1 if inlist(pobreza, 1, 2)

	*************
	*bienestar_agregado*
	*************
	gen double bienestar_agregado = .

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . //
	*zona urbana 67.06
	replace lpe_ci= li if zona_c == 1
	*zona rural 43.30
	replace lpe_ci= li if  zona_c == 0
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . //
	*zona urbana 67.06
	replace ln_ci= li*2 if  zona_c == 1
	*zona rural 43.30
	replace ln_ci= li*2 if  zona_c == 0

	
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
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




saveold "`base_out'", version(12) replace

cap log close
