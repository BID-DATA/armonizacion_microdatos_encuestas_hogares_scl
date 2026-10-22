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

local PAIS DOM
local ENCUESTA ENCFT
local ANO 2025
local ronda t4


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: DOM
Encuesta: ENCFT
Round: t4
Autores: Matías Isla y Matias Rodriguez (SCL/SCL)
Version: 18/06/2026
Mail: matiasi@iadb.org/mrodriguezm@iadb.org, 18 de junio de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use "`base_in'", clear

	**********************************
	***VARIABLES DE IDENTIFICACIÓN ***
	**********************************

	********************
	*** region_BID_c ***
	********************
	gen byte region_BID_c = 1

	*****************
	*** region_c  ***×+
	*****************
	gen byte region_c = id_provincia

	*************
	*** pais_c ***
	*************
	gen str3 pais_c = "DOM"

	**************
	*** anio_c  ***
	**************
	gen int anio_c = 2025

	*************
	*** mes_c  ***
	*************
	gen int mes_c = mes

	*************
	*** zona_c ***
	*************
	gen byte zona_c = 1 if zona == 1
	replace  zona_c = 0 if zona == 2

	*****************
	*** estrato_ci ***
	*****************
	gen byte estrato_ci = estrato

	*************
	*** upm_ci ***
	*************
	gen int upm_ci = upm

	**************
	*** idh_ch  ***
	**************
	sort vivienda hogar
	egen idh_ch = concat(vivienda hogar)
	tostring idh_ch, replace

	**************
	*** idp_ci  ***
	**************
	sort vivienda hogar miembro
	egen idp_ci = concat(vivienda hogar miembro)
	tostring idp_ci, replace

	*****************
	*** factor_ci  ***
	*****************
	gen factor_ci = factor_expansion

	*****************
	*** factor_ch  ***
	*****************
	gen factor_ch = factor_expansion


	****************************
	***VARIABLES DEMOGRÁFICAS***
	****************************

	**************
	*** sexo_ci ***
	**************
	gen byte sexo_ci = sexo /* 1=hombre, 2=mujer */

	**************
	*** edad_ci ***
	**************
	gen byte edad_ci = edad

	*******************
	*** relacion_ci  ***
	*******************
	/* parentesco: 1=jefe, 2=cónyuge, 3=hijo, 4=hijastro, 5=nieto, 6=yerno/nuera,
	   7=padre/madre, 8=suegro, 9=hermano, 10=abuelo, 11=otro pariente, 12=no pariente
	   No hay categoría de empleado doméstico identificable en ENCFT */
	gen byte relacion_ci = 1 if parentesco == 1
	replace relacion_ci = 2 if parentesco == 2
	replace relacion_ci = 3 if parentesco == 3 | parentesco == 4
	replace relacion_ci = 4 if parentesco >= 5 & parentesco <= 11
	replace relacion_ci = 5 if parentesco == 12

	*****************
	*** civil_ci   ***
	*****************
	/* estado_civil: 1=unión libre, 2=casado, 3=divorciado, 4=separado, 5=viudo, 6=soltero */
	gen byte civil_ci = .
	replace civil_ci = 1 if estado_civil == 6
	replace civil_ci = 2 if estado_civil == 1 | estado_civil == 2
	replace civil_ci = 3 if estado_civil == 3 | estado_civil == 4
	replace civil_ci = 4 if estado_civil == 5

	***************
	*** jefe_ci  ***
	***************
	gen byte jefe_ci = (relacion_ci == 1)
	replace  jefe_ci = . if relacion_ci == .

	*******************
	*** miembros_ci  ***
	*******************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace  miembros_ci = . if relacion_ci == .

	**********************
	*** miembros_one_ci ***
	**********************
	gen byte miembros_one_ci = miembros_ci

	by idh_ch, sort: egen byte nconyuges_chv = sum(relacion_ci == 2)
	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)
	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)
	by idh_ch, sort: egen byte nmiembros_ch = sum(relacion_ci > 0 & relacion_ci <= 5)
	replace nmiembros_ch = . if relacion_ci == .

	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))
	by idh_ch, sort: egen byte nmenor6_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))
	by idh_ch, sort: egen byte nmenor1_ch  = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))

	*******************
	*** clasehog_ch  ***
	*******************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0


	*******************************
	*** VARIABLES DE DIVERSIDAD ***
	*******************************

	***************
	*** afro_ci  ***
	***************
	gen byte afro_ci = . /* ENCFT sin pregunta */

	**************
	*** ind_ci  ***
	**************
	gen byte ind_ci = . /* ENCFT sin pregunta */

	*******************
	*** noafroind_ci ***
	*******************
	gen byte noafroind_ci = . // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1) 
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)

	*******************
	*** afroind_ci   ***
	*******************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	gen afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	gen ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	gen noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	gen afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	********************
	*** afroind_ano_c ***
	********************
	gen byte afroind_ano_c = .

	***************
	*** dis_ci   ***
	***************
	gen byte dis_ci = . /* ENCFT sin módulo de discapacidad */

	****************
	*** disWG_ci  ***
	****************
	gen byte disWG_ci = .

	**********************
	*** ISO3pais_dis_ci ***
	**********************
	gen DOM_dis_ci = dis_ci

	***************
	*** dis_ch   ***
	***************
	egen dis_ch = max(dis_ci), by(idh_ch)

	************************************
	*** VARIABLES DEL MERCADO LABORAL***
	************************************

	*******************
	*** condocup_ci  ***
	*******************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if trabajo_semana_pasada == 1 | tenia_empleo_negocio == 1 | (realizo_actividad != 8 & realizo_actividad != .)
	replace condocup_ci = 2 if (trabajo_semana_pasada == 2 | tenia_empleo_negocio == 2 | realizo_actividad == 8) & (busco_trabajo_establ_negocio == 1)
	recode condocup_ci (. = 3) if edad_ci >= 10
	replace condocup_ci = 4 if edad_ci < 10

	**********************
	*** categoinac_ci   ***
	**********************
	/* motivo_no_busca_trabajo: 10=jubilado, 7=estudiante, 8=quehaceres */
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (motivo_no_busca_trabajo == 10 & condocup_ci == 3)
	replace categoinac_ci = 2 if (motivo_no_busca_trabajo == 7 & condocup_ci == 3)
	replace categoinac_ci = 3 if (motivo_no_busca_trabajo == 8 & condocup_ci == 3)
	replace categoinac_ci = 4 if (categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3

	***************
	*** emp_ci  ***
	***************
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)

	*****************
	*** cesante_ci ***
	*****************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if trabajo_antes == 1
	replace cesante_ci = 0 if trabajo_antes == 2

	****************
	*** desemp_ci ***
	****************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)

	****************
	*** subemp_ci ***
	****************
	gen promhora = horas_trabaja_semana_principal if emp_ci == 1
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if (promhora >= 1 & promhora <= 30) & emp_ci == 1 & desea_trabajar_mas_horas == 1

	*****************
	*** durades_ci ***
	*****************
	gen durades_ci = .
	replace durades_ci = 1 if que_tiempo_busca_trabajo == 1
	replace durades_ci = (1 + 6) / 2 if que_tiempo_busca_trabajo == 2
	replace durades_ci = (6 + 12) / 2 if que_tiempo_busca_trabajo == 3
	replace durades_ci = (12 + 12) / 2 if que_tiempo_busca_trabajo == 4

	***************
	*** pea_ci ***
	****************	
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	*****************
	*** nempleos_ci **
	*****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1 & cuantos_trabajos_tiene == 1
	replace nempleos_ci = cuantos_trabajos_tiene_cant if emp_ci == 1 & cuantos_trabajos_tiene == 2
	replace nempleos_ci = . if emp_ci == 0

	*******************
	*** antiguedad_ci ***
	*******************
	gen temp_dias  = tiempo_empleo_dias / 365
	gen temp_meses = tiempo_empleo_meses / 12
	egen antiguedad_ci = rsum(tiempo_empleo_anos temp_dias temp_meses), missing
	replace antiguedad_ci = . if emp_ci == 0
	replace antiguedad_ci = . if tiempo_empleo_dias == . & tiempo_empleo_meses == . & tiempo_empleo_anos == .
	drop temp_*

	*****************
	*** desalent_ci ***
	*****************
	/* motivo_no_busca_trabajo: 5=sin edu/exp, 6=edad - desalentado */
	gen byte desalent_ci = (motivo_no_busca_trabajo == 5 | motivo_no_busca_trabajo == 6) & condocup_ci == 3
	replace  desalent_ci = . if motivo_no_busca_trabajo == .

	*****************
	*** horaspri_ci ***
	*****************
	gen int horaspri_ci = horas_trabaja_semana_principal
	replace horaspri_ci = . if emp_ci == 0

	*****************
	*** horastot_ci ***
	*****************
	gen promhora1 = horas_trabajo_ocup_secun if emp_ci == 1
	egen tothoras = rowtotal(promhora promhora1)
	replace tothoras = . if promhora == . & promhora1 == .
	replace tothoras = . if tothoras >= 168
	gen int horastot_ci = tothoras if emp_ci == 1

	*******************
	*** tiempoparc_ci ***
	*******************
	gen byte tiempoparc_ci = (tothoras >= 1 & horastot_ci <= 30) & emp_ci == 1 & desea_trabajar_mas_horas == 2
	replace tiempoparc_ci = . if emp_ci == 0

	********************
	*** categopri_ci  ***
	********************
	/* categoria_principal: 1=gob.general, 2=emp.pública, 3=emp.privada, 4=zona franca,
	   5=hogar privado, 6=empleador/patrón, 7=cuenta propia, 8=familiar no remunerado
	   Trabajadores familiares con ingresos en noremunerados - reclasificar como categopri=4 */
	destring crianza_no_remun_monto, replace
	egen noremunerados = rowtotal(crianza_no_remun_monto pesca_no_remun_monto alimentos_no_remun_monto), missing
	gen byte categopri_ci = .
	replace categopri_ci = 1 if categoria_principal == 6
	replace categopri_ci = 2 if categoria_principal == 7 & noremunerados == .
	replace categopri_ci = 3 if inlist(categoria_principal, 1, 2, 3, 4, 5)
	replace categopri_ci = 4 if categoria_principal == 8 | grupo_categoria == "Familiar no remunerado" | noremunerados != .
	replace categopri_ci = . if emp_ci == 0 & noremunerados == .
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1  /* residual ocupados no clasificados */

	********************
	*** categosec_ci  ***
	********************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if categoria_secundaria == 6
	replace categosec_ci = 2 if categoria_secundaria == 7
	replace categosec_ci = 3 if inlist(categoria_secundaria, 1, 2, 3, 4, 5)
	replace categosec_ci = 4 if categoria_secundaria == 8
	replace categosec_ci = . if emp_ci == 0

	***************
	*** rama_ci  ***
	***************
	/* CIIU rev4 - rama_principal_cod es str4, requiere destring */
	rename rama_principal_cod ramac
	destring ramac, replace
	gen byte rama_ci = .
	replace rama_ci = 1 if (ramac >= 111   & ramac <= 322) & emp_ci == 1
	replace rama_ci = 2 if (ramac >= 510   & ramac <= 990) & emp_ci == 1
	replace rama_ci = 3 if (ramac >= 1010  & ramac <= 3320) & emp_ci == 1
	replace rama_ci = 4 if (ramac >= 3510  & ramac <= 3900) & emp_ci == 1
	replace rama_ci = 5 if (ramac >= 4100  & ramac <= 4390) & emp_ci == 1
	replace rama_ci = 6 if (ramac >= 4510  & ramac <= 4799) & emp_ci == 1
	replace rama_ci = 7 if (ramac >= 4911  & ramac <= 6399) & emp_ci == 1
	replace rama_ci = 8 if (ramac >= 6411  & ramac <= 6820) & emp_ci == 1
	replace rama_ci = 9 if (ramac >= 6910  & ramac <= 9990) & emp_ci == 1

	*******************
	*** spublico_ci  ***
	*******************
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & (categoria_principal == 1 | categoria_principal == 2)
	replace spublico_ci = 0 if emp_ci == 1 & !inlist(categoria_principal, 1, 2)

	*****************
	*** tamemp_ci  ***
	*****************
	/* cantidad_personas_trabajan_emp: conteo exacto 1-10
	   total_personas_trabajan_emp: 1=1-10, 2=11-19, 3=20-30, 4=31-50, 5=51-99, 6=100+, 98=NS */
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if cantidad_personas_trabajan_emp > 0 & cantidad_personas_trabajan_emp <= 5
	replace tamemp_ci = 2 if (cantidad_personas_trabajan_emp >= 6 & cantidad_personas_trabajan_emp <= 10 & cantidad_personas_trabajan_emp != .) | total_personas_trabajan_emp == 2
	replace tamemp_ci = 3 if total_personas_trabajan_emp >= 3 & total_personas_trabajan_emp != . & total_personas_trabajan_emp != 98

	*******************
	*** cotizando_ci ***
	*******************
	gen byte cotizando_ci = . /* ENCFT sin pregunta directa de cotización */

	*******************
	*** instcot_ci   ***
	*******************
	gen byte instcot_ci = .

	*******************
	*** afiliado_ci  ***
	*******************
	/* afiliado_afp_princ: 1=sí, 2=no, 98=NS */
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if afiliado_afp_princ == 1 & emp_ci == 1
	replace afiliado_ci = 0 if afiliado_afp_princ == 2 & inlist(condocup_ci, 1, 2)

	*******************
	*** formal_ci  ***
	*******************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	***********************
	*** tipocontrato_ci  ***
	***********************
	/* tiene_contrato: 1=sí, 2=no. tipo_contrato: 1=indefinido, 2=tiempo def., 3=trabajo específico.
	   contrato_verbal_escrito: 1=escrito, 2=verbal */
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if (tiene_contrato == 1 & tipo_contrato == 1) & categopri_ci == 3
	replace tipocontrato_ci = 2 if (tiene_contrato == 1 & (tipo_contrato == 2 | tipo_contrato == 3)) & categopri_ci == 3
	replace tipocontrato_ci = 3 if (tiene_contrato == 2 | contrato_verbal_escrito == 2 | tipocontrato_ci == .) & categopri_ci == 3

	***************
	*** ocupa_ci ***
	***************
	/* CIUO-08 4 dígitos — ocupacion_principal_cod es str4 */
	gen byte ocupa_ci = .
	destring ocupacion_principal_cod, replace
	replace ocupa_ci = 1 if (ocupacion_principal_cod >= 2111 & ocupacion_principal_cod <= 3522) & emp_ci == 1
	replace ocupa_ci = 2 if (ocupacion_principal_cod >= 1111 & ocupacion_principal_cod <= 1439) & emp_ci == 1
	replace ocupa_ci = 3 if (ocupacion_principal_cod >= 4110 & ocupacion_principal_cod <= 4419) & emp_ci == 1
	replace ocupa_ci = 4 if ((ocupacion_principal_cod >= 5211 & ocupacion_principal_cod <= 5249) | (ocupacion_principal_cod >= 9510 & ocupacion_principal_cod <= 9520)) & emp_ci == 1
	replace ocupa_ci = 5 if ((ocupacion_principal_cod >= 5110 & ocupacion_principal_cod <= 5169) | (ocupacion_principal_cod >= 5311 & ocupacion_principal_cod <= 5419) | (ocupacion_principal_cod >= 9111 & ocupacion_principal_cod <= 9129) | (ocupacion_principal_cod >= 9610 & ocupacion_principal_cod <= 9624)) & emp_ci == 1
	replace ocupa_ci = 6 if ((ocupacion_principal_cod >= 6110 & ocupacion_principal_cod <= 6340) | (ocupacion_principal_cod >= 9210 & ocupacion_principal_cod <= 9216)) & emp_ci == 1
	replace ocupa_ci = 7 if ((ocupacion_principal_cod >= 7111 & ocupacion_principal_cod <= 8350) | (ocupacion_principal_cod >= 9310 & ocupacion_principal_cod <= 9412)) & emp_ci == 1
	replace ocupa_ci = 8 if (ocupacion_principal_cod >= 110 & ocupacion_principal_cod <= 310) & emp_ci == 1
	replace ocupa_ci = 9 if ocupacion_principal_cod >= 9629 & ocupacion_principal_cod != . & emp_ci == 1


	*****************************
	*** VARIABLES DE PENSIONES ***
	*****************************

	***************
	*** pension_ci **
	***************
	gen byte pension_ci = (pension_nac == 1) if !missing(pension_nac)
	replace pension_ci = . if pension_nac == 3 // Se niega

	*******************
	*** pensionsub_ci ***
	*******************
	gen byte pensionsub_ci = (ps_apoyo_adultos_mayores == 1) if !missing(ps_apoyo_adultos_mayores)

	*****************
	*** tipopen_ci ***
	*****************
	gen byte tipopen_ci = .

	*****************
	*** instpen_ci ***
	*****************
	gen byte instpen_ci = .


	************************************************
	*** VARIABLES DE INGRESO & PROTECCION SOCIAL ***
	************************************************

*A. INGRESOS LABORALES A NIVEL DE INDIVIDUO	

	* Asalariados
	/* tiempo_recibe_pago_ap: 1=diario, 2=semanal, 3=quincenal, 4=mensual */
	gen double ymensual = sueldo_bruto_ap_monto * tiempo_recibe_pago_dias_ap * 4.3 if tiempo_recibe_pago_ap == 1
	replace ymensual = sueldo_bruto_ap_monto * 4.3 if tiempo_recibe_pago_ap == 2
	replace ymensual = sueldo_bruto_ap_monto * 2 if tiempo_recibe_pago_ap == 3
	replace ymensual = sueldo_bruto_ap_monto if tiempo_recibe_pago_ap == 4

	*independientes
	/* ingreso_actividad_in_periodo: 1=diario, 2=semanal, 3=quincenal, 4=mensual */
	gen double ymensualindep = ingreso_actividad_in_monto * ingreso_actividad_in_dias * 4.3 if ingreso_actividad_in_periodo == 1
	replace ymensualindep = ingreso_actividad_in_monto * 4.3 if ingreso_actividad_in_periodo == 2
	replace ymensualindep = ingreso_actividad_in_monto * 2   if ingreso_actividad_in_periodo == 3
	replace ymensualindep = ingreso_actividad_in_monto        if ingreso_actividad_in_periodo == 4
		* Renombrar variables con conflictos de nombre
		rename comisiones otrascomisionesoriginales
		rename propinas otraspropinasoriginales
		rename bonificaciones bonificacionesoriginales

	gen comisiones_pri = comisiones_ap_monto 
	gen propinas_pri = propinas_ap_monto 
	gen horasextra_pri = horas_extra_ap_monto 

	gen vacaciones_pri = vacaciones_ap_monto/12
	gen dividendos_pri = dividendos_ap_monto/12
	gen bonificaciones_pri = bonificacion_ap_monto/12
	gen regalia_pri = regalia_ap_monto/12
	gen utilidades_pri = utilidad_empresarial_ap_monto/12 
	gen beneficios_pri = beneficios_marginales_ap_monto/12
	gen bonoantiguedad_pri = incentivo_antiguedad_ap_monto/12
	gen otrosbeneficios_pri = otros_beneficios_ap_monto/12

	*especies (in-kind laboral)
	gen alimentos_pri = alimentacion_especie_ap_monto if alimentacion_especie_ap == 1
	gen vivienda1_pri = vivienda_especie_ap_monto if vivienda_especie_ap == 1
	gen transporte_pri = transporte_especie_ap_monto if transporte_especie_ap == 1
	gen gasolina_pri = gasolina_especie_ap_monto if gasolina_especie_ap == 1
	gen cellular_pri = celular_especie_ap_monto if celular_especie_ap == 1
	gen otros_pri = otros_especie_ap_monto if otros_especie_ap == 1
	
	*Ingresos secundarios
	recode ingreso_asalariado_secun (0 = .)
	recode ingreso_independientes_secun (0 = .)
	egen ymensual2 = rsum(ganancia_secun_imp_monto ingreso_asalariado_secun ingreso_independientes_secun), missing

	*ingresos no laborales
	gen double pension_nl = pension_nac_monto if pension_nac==1
	gen double intereses_nl = intereses_nac_monto if intereses_nac==1 
	gen double alquiler_nl = alquiler_nac_monto if alquiler_nac==1
	gen double remesasnac = remesas_nac_monto  if remesas_nac==1  
	gen double ayuda_nm = ayuda_especie_nac_monto  if ayuda_especie_nac==1	//nm 
	gen double alimento_esc = alimentos_escuela_nac_monto if alimentos_escuela_nac == 1	//nm
	gen double ayudaemp_nl = ayuda_empresas_nac_monto if ayuda_empresas_nac == 1
	gen double otrasayudas_nl = otros_ingresos_nac_monto if otros_ingresos_nac == 1

	egen double gobierno = rowtotal(gob_inc_asis_escolar_monto gob_bono_luz_monto gob_bonogas_choferes_monto gob_bonogas_hogares_monto gob_proteccion_vejez_monto gob_bono_estudiante_prog_monto gob_inc_educacion_sup_monto gob_inc_policia_prev_monto gob_inc_marina_guerra_monto gob_programa_superate gob_programa_pase) if gobierno_nac == 1, mi
	
	* Ingresos no laborales (en 12 meses)
	gen double intereses_12m = intereses_nac_ano_monto/12 if intereses_nac_ano == 1 
	gen double alquiler_12m = alquiler_nac_ano_monto/12 if alquiler_nac_ano == 1
	gen double remesasnac_12m = donacion_nac_ano_monto/12 if donacion_nac_ano == 1  
	gen double ayudanm_12m = ayuda_especie_nac_anio/12 if ayuda_especie_nac_anio > 0 	//nm
	gen double ayudaemp_12m = ayuda_empresas_nac_anio/12 if ayuda_empresas_nac_anio > 0
	gen double regalia_12m = regalia_pension_nac/12 if regalia_pension_nac > 0
	gen double otrasayudas_12m = otros_ingresos_nac_anio/12 if otros_ingresos_nac_anio > 0
	
	
	*Para República Dominicana hay dos módulos especiales: remesas e ingresos del exterior.
	*Aquí se trabaja sobre esas variables:
	
	* Módulo de Ingresos del Exterior
	*********************************
	*Información cambiaria que viene en la base de excel dentro de los datos raw pre-merge
	*Dado que se necesita la información en moneda local se calcula el factor de conversión a pesos
	*Si la información está en pesos se deja como está
	*Si la información está en dólares se multiplica por 60.99, Euros, luego de ser convertidos en dolares, por 0.87 (promedio para los meses del cuarto trimestre de 2025)
	
	* Tasa de cambio: Promedio anual 2023 
	gen tc_usd = 60.99
	gen tc_eur_usd = 0.87
	gen tc_cad = 44.07

	gen double pension_int = pension_ext_monto if pension_ext_moneda == "DOP"
	replace    pension_int = pension_ext_monto*tc_usd if pension_ext_moneda == "USD"
	replace    pension_int = (pension_ext_monto*tc_eur_usd)*tc_usd if pension_ext_moneda == "EUR"
	replace    pension_int = pension_ext_monto*tc_cad if pension_ext_moneda == "CAD"
	replace    pension_int = . if pension_ext == 2 | pension_ext == 3

	gen double interes_int = interes_ext_monto if interes_ext == 1

	gen double alquiler_int = alquiler_ext_monto if alquiler_ext == 1

	gen double regalos_int = regalos_ext_monto if regalos_ext == 1	//nm

	gen double otrosing_int = otros_ingresos_ext_monto if otros_ingresos_ext_moneda == "DOP"
	replace    otrosing_int = otros_ingresos_ext_monto*tc_usd if otros_ingresos_ext_moneda == "USD"
	
	// Remesas: promedio de 6 meses
	* Variable auxiliar de tipo de cambio creada en la sección anterior de Ingresos del Exterior
		
		forvalues y = 1/6  {	// Meses
		forvalues x = 1/3  {	// Cantidad de montos recibidos
			
			capture confirm string variable mes`y'_`x'_ext_moneda
			if !_rc {
				gen double remesasaux`y'_`x' = (mes`y'_`x'_ext_monto) 			 if mes`y'_`x'_ext_moneda == "DOP"
				replace remesasaux`y'_`x'    = (mes`y'_`x'_ext_monto)*tc_usd 	 if mes`y'_`x'_ext_moneda == "USD"
				replace remesasaux`y'_`x'    = (mes`y'_`x'_ext_monto*tc_eur_usd)*tc_usd if mes`y'_`x'_ext_moneda == "EUR"
			}
	
			else {
				gen double remesasaux`y'_`x' = mes`y'_`x'_ext_monto if mes`y'_`x'_ext_moneda == .
			}
		}
		}
		
	egen double remesas_mes = rowtotal(remesasaux*_*), mi
	replace remesas_mes = . if recibio_remesa_ext1 != 1 & recibio_remesa_ext2 != 1 & recibio_remesa_ext3 != 1
	gen double remesas_prom = remesas_mes/6
	drop tc_usd tc_eur_usd tc_cad 

	***************
	*** ylmpri_ci ***
	***************
	/* Ingreso laboral monetario principal = salario mensualizado + bonos anualizados + ingreso independiente */
	egen double ylmpri_ci = rowtotal(ymensual comisiones_pri propinas_pri horasextra_pri vacaciones_pri bonificaciones_pri regalia_pri utilidades_pri beneficios_pri otrosbeneficios_pri bonoantiguedad_pri otros_pagos_ap_monto ymensualindep), missing 
	replace ylmpri_ci = . if emp_ci == 0
	replace ylmpri_ci = 0 if categopri_ci == 4

	****************
	*** ylnmpri_ci ***
	****************
	/* Especies laborales en especie + no remunerados */
	egen double ing_mpri_ci = rowtotal(alimentos_pri vivienda1_pri transporte_pri gasolina_pri cellular_pri otros_pri), missing 
	egen double ylnmpri_ci = rowtotal(ing_mpri_ci noremunerados) if categopri_ci == 4, mi

	***************
	*** ylmsec_ci ***
	***************
	gen double ylmsec_ci = ymensual2 if emp_ci == 1 & cuantos_trabajos_tiene == 2
	replace ylmsec_ci = . if ymensual2 == 99999 & emp_ci == 1

	****************
	*** ylnmsec_ci ***
	****************
	gen double ylnmsec_ci = .

	*****************
	*** ylmotros_ci ***
	*****************
	gen double ylmotros_ci = .

	******************
	*** ylnmotros_ci ***
	******************
	gen double ylnmotros_ci = .

	***************
	*** ylm_ci   ***
	***************
	egen double ylm_ci = rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	replace ylm_ci = . if ylmpri_ci == . & ylmsec_ci == . & ylmotros_ci == .

	***************
	*** ylnm_ci  ***
	***************
	egen double ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci = . if ylnmpri_ci == . & ylnmsec_ci == . & ylnmotros_ci == .


*B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO

	******************
	*** ytransf_ci ***
	******************
		* PNC - Pensiones sociales no contributivas:
				* 1 Programa Solidaridad Protección a la vejez (seccion 3-b)
		* PTMC - Programas de transferencias monetarias condicionadas:
				* 2 Programa Solidaridad: Incentivo a la Asistencia Escolar (seccion 3-a)
				* 3 Incentivo a la Educación Superior, con la Tarjeta Solidaridad (seccion 3-g)
				* 4 Bono Escolar Estudiante en Progreso (seccion 3-h)
				* 5 Programa Solidaridad: Superate (seccion 3-k)
		* POTROT - Programas de otras transferencias monetarias no condicionadas
				* 6 Programa Solidaridad Bono-Luz Hogar (seccion 3-c)
				* 7 Programa Solidaridad Bono-Gas Hogar (seccion 3-d)

	*** Beneficiarios a nivel individual:
		gen byte pnc_ci = (ps_apoyo_adultos_mayores == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		
		gen byte ps_iae = (ps_incentivo_asist_escolar == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		gen byte inc_es = (incentivo_educacion_superior == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		gen byte bono_eep = (bono_escolar_estudiante_prog == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		gen byte ps_sup = (programa_solidaridad_superate == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		
		gen byte ptmc_ci = (ps_iae == 1 | inc_es == 1 | bono_eep == 1 | ps_sup == 1)
		replace ptmc_ci = . if (ps_iae == . & inc_es == . & bono_eep == . & ps_sup == .)
		
		gen byte ps_luz = (ps_bono_luz == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		gen byte ps_gas = (ps_bono_gas == 1 & gobierno_nac == 1) if !missing(gobierno_nac)
		
		gen byte potrot_ci = (ps_luz == 1 | ps_gas == 1)
		replace potrot_ci = . if ps_luz == . & ps_gas == .

	*** Montos de transferencias a nivel individual:
		// Transferencias PNC
		gen double ypnc_ci = gob_proteccion_vejez_monto	
		replace ypnc_ci = . if ypnc_ci == 0 & pnc_ci == 0
		
		// Transferencias PTMC
		egen double yptmc_ci = rowtotal(gob_inc_asis_escolar_monto gob_inc_educacion_sup_monto gob_bono_estudiante_prog_monto gob_programa_superate), mi
		replace yptmc_ci = . if yptmc_ci == 0 & ptmc_ci == 0
		
		// Otras transferencias POTROT
		egen double yotrot_ci = rowtotal(gob_bono_luz_monto gob_bonogas_hogares_monto), mi
		replace yotrot_ci = . if yotrot_ci == 0 & potrot_ci == 0
		
	*** Ingreso individual por transferencias no contributivas
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi

	*************
	*** ypen_ci ***
	*************
	gen double ypen_ci = pension_nac_monto if pension_ci == 1

	****************
	*** ypensub_ci ***
	****************
	gen double ypensub_ci = ypnc_ci
	replace ypensub_ci = . if gob_proteccion_vejez_monto == 0
	
	*****************
	*** remesas_ci ***
	*****************
	gen double remesas_ci = remesas_prom
	
	***************
	*** ynlm_ci  ***
	***************
	* Diferencia de ingresos del gobierno versus las transferencias no contributivas:
		gen double aux_ytransf_ci = ytransf_ci*(-1)
		egen double ydelta_gob = rowtotal(gobierno aux_ytransf_ci), mi

	egen double ynlm_ci = rowtotal(ypen_ci intereses_nl alquiler_nl remesasnac ayudaemp_nl otrasayudas_nl ytransf_ci ydelta_gob /// 
								   intereses_12m alquiler_12m remesasnac_12m ayudaemp_12m regalia_12m otrasayudas_12m ///
								   pension_int interes_int alquiler_int otrosing_int), missing 

	***************
	*** ynlnm_ci ***
	***************
	egen double ynlnm_ci = rowtotal(ayuda_nm alimento_esc ayudanm_12m regalos_int), mi

	***************
	*** ytot_ci  ***
	***************
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi
	
	***************
	*** ynet_ci ***
	***************
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi	
	drop aux_ytransf_ci


*C. INGRESOS A NIVEL DE HOGAR

	***************
	*** ylm_ch   ***
	***************
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi

	***************
	*** ylnm_ch  ***
	***************
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi

	******************
	*** ytransf_ch ***
	******************
	*** Beneficiarios a nivel hogar:
		bys idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1
		bys idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1
		bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
		
		gen byte pcasht_ch = (pnc_ch == 1 | ptmc_ch == 1 | potrot_ch == 1)
		replace pcasht_ch = . if pnc_ch == . & ptmc_ch == . & potrot_ch == .

	*** Montos de transferencias a nivel hogar:
		bys idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi
		bys idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi
		bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

	*** Ingreso del Hogar por transferencias no contributivas
	egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi

	*****************
	*** remesas_ch ***
	*****************
	bysort idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, mi

	***************
	*** ynlm_ch  ***
	***************
	bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, mi

	***************
	*** ynlnm_ch ***
	***************
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, mi

	***************
	*** ytot_ch  ***
	***************
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
	
	***************
	*** ynet_ch ***
	***************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	*****************
	*** ylmhopri_ci ***
	*****************
	gen double ylmhopri_ci = ylmpri_ci / (horaspri_ci * 4.3)

	***************
	*** ylmho_ci ***
	***************
	gen double ylmho_ci = ylm_ci / (horastot_ci * 4.3)

	*****************
	*** nrylmpri_ci ***
	*****************
	gen byte nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)

	*****************
	*** nrylmpri_ch ***
	*****************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1


	****************************
	***VARIABLES DE EDUCACIÓN***
	****************************

	***************
	*** aedu_ci  ***
	***************
	/* nivel_ultimo_ano_aprobado: 1=preescolar, 2=primario, 3=secundario, 4=sec-técnico,
	   5=universitario, 6=post-grado, 7=maestría, 8=doctorado, 9=ninguno, 10=Quisqueya Aprende
	   Bases: prim=0+grado, sec=6+grado, univ=12+grado, posgrado/maestría=16+grado, doctorado=18+grado */
	gen aedu_ci = .
	replace aedu_ci = 0 if nivel_ultimo_ano_aprobado == 1
	replace aedu_ci = 0 if nivel_ultimo_ano_aprobado == 9
	replace aedu_ci = 0 if nivel_ultimo_ano_aprobado == 10
	replace aedu_ci = . if nivel_ultimo_ano_aprobado == 99
	replace aedu_ci = ultimo_ano_aprobado if nivel_ultimo_ano_aprobado == 2
	replace aedu_ci = ultimo_ano_aprobado + 6 if nivel_ultimo_ano_aprobado == 3
	replace aedu_ci = ultimo_ano_aprobado + 6 if nivel_ultimo_ano_aprobado == 4
	replace aedu_ci = ultimo_ano_aprobado + 12 if nivel_ultimo_ano_aprobado == 5
	replace aedu_ci = ultimo_ano_aprobado + 16 if nivel_ultimo_ano_aprobado == 6 | nivel_ultimo_ano_aprobado == 7
	replace aedu_ci = ultimo_ano_aprobado + 18 if nivel_ultimo_ano_aprobado == 8
	replace aedu_ci = . if nivel_ultimo_ano_aprobado == .

	***************
	*** edupre_ci ***
	***************
	gen byte edupre_ci = .

	***************
	*** eduui_ci ***
	***************
	gen byte eduui_ci = aedu_ci > 12 & aedu_ci < 16
	replace eduui_ci = . if aedu_ci == .

	***************
	*** eduuc_ci ***
	***************
	gen byte eduuc_ci = aedu_ci >= 16
	replace eduuc_ci = . if aedu_ci == .

	***************
	*** eduac_ci ***
	***************
	gen byte eduac_ci = . /* no disponible */

	***************
	*** asiste_ci ***
	***************
	gen byte asiste_ci = 1 if asiste_centro_educativo == 1
	replace asiste_ci = 0 if asiste_centro_educativo == 2

	***************
	*** edupub_ci ***
	***************
	/* tipo_centro_estudios: 1=privado, 2=semi-privado, 3=público
	   Solo para quienes asisten actualmente (missing para no asistentes) */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if tipo_centro_estudios == 3 & asiste_ci == 1
	replace edupub_ci = 0 if tipo_centro_estudios == 1 & asiste_ci == 1
	replace edupub_ci = 0 if tipo_centro_estudios == 2 & asiste_ci == 1

	***********************
	*** razonesnoasis_ci ***
	***********************
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if porque_no_estudia == 8 | porque_no_estudia == 7
	replace razonesnoasis_ci = 2 if porque_no_estudia == 4 | porque_no_estudia == 12
	replace razonesnoasis_ci = 3 if porque_no_estudia == 11
	replace razonesnoasis_ci = 4 if porque_no_estudia == 3
	replace razonesnoasis_ci = 5 if inlist(porque_no_estudia, 2, 5, 6, 9, 10, 13)

	***************
	*** asispre_ci ***
	***************
	gen byte asispre_ci = 1 if nivel_se_matriculo == 1 & asiste_centro_educativo == 1
	replace asispre_ci = 0 if nivel_se_matriculo != 1 & asiste_centro_educativo == 1


	************************************
	**** VARIABLES DE LA VIVIENDA ****
	************************************

	*************
	*** luz_ch ***
	*************
	/* tipo_alumbrado: 1=eléct., 2=planta, 3=batería, 4=gas, 5=vela/kerosene, 6=solar, 7=vela, 99=otro */
	gen byte luz_ch = 0
	replace luz_ch = 1 if inlist(tipo_alumbrado, 1, 2, 3, 6)
	replace luz_ch = 0 if inlist(tipo_alumbrado, 4, 5, 7, 99)

	*****************
	*** luzmide_ch ***
	*****************
	gen byte luzmide_ch = . /* ENCFT sin pregunta de medidor */

	*****************
	*** combust_ch ***
	*****************
	/* combustible_para_cocinar: 1=gas cilindro, 2=gas kerosene, 3=electricidad, 4=leña, 5=carbón, 6=no cocina 99=otro */
	gen byte combust_ch = 0
	replace combust_ch = 1 if inlist(combustible_para_cocinar, 1, 2, 3)
	replace combust_ch = 0 if inlist(combustible_para_cocinar, 4, 5, 99)

	*************
	*** piso_ch ***
	*************
	/* CREAR VACÍO metodología en revisión (manual oct 2025) */
	gen piso_ch = .

	**************
	*** pared_ch ***
	**************
	/* CREAR VACÍO metodología en revisión (manual oct 2025) */
	gen pared_ch = .

	**************
	*** techo_ch ***
	**************
	/* CREAR VACÍO metodología en revisión (manual oct 2025) */
	gen techo_ch = .

	**************
	*** resid_ch ***
	**************
	/* como_elimina_basura: 1-3=recolección/0, 4=quema/1, 5-7=tirado/2, 99=otro/3 */
	gen byte resid_ch = 0 if inlist(como_elimina_basura, 1, 2, 3)
	replace resid_ch = 1 if como_elimina_basura == 4
	replace resid_ch = 2 if inlist(como_elimina_basura, 5, 6, 7)
	replace resid_ch = 3 if como_elimina_basura == 99

	*************
	*** dorm_ch ***
	*************
	gen byte dorm_ch = cant_dormitorios_vivienda
	replace dorm_ch = 1 if cant_dormitorios_vivienda == 0  /* sin dormitorio exclusivo / 1 */

	****************
	*** cuartos_ch ***
	****************
	gen byte cuartos_ch = cant_cuartos_vivienda

	****************
	*** cocina_ch ***
	****************
	gen byte cocina_ch = .

	**************
	*** telef_ch ***
	**************
	gen byte telef_ch = 0
	replace telef_ch = 1 if telefono == 1
	replace telef_ch = . if telefono == .

	***************
	*** refrig_ch ***
	***************
	gen byte refrig_ch = 0
	replace refrig_ch = 1 if refrigerador == 1
	replace refrig_ch = . if refrigerador == .

	**************
	*** freez_ch ***
	**************
	gen byte freez_ch = .

	*************
	*** auto_ch ***
	*************
	gen byte auto_ch = 0
	replace auto_ch = 1 if automovil == 1
	replace auto_ch = . if automovil == .

	**************
	*** compu_ch ***
	**************
	gen byte compu_ch = 0
	replace compu_ch = 1 if computador == 1
	replace compu_ch = . if computador == .

	*****************
	*** internet_ch ***
	*****************
	gen byte internet_ch = 0
	replace internet_ch = 1 if internet == 1
	replace internet_ch = . if internet == .

	************
	*** cel_ch ***
	************
	gen byte cel_ch = 0
	replace cel_ch = 1 if celular == 1
	replace cel_ch = . if celular == .

	**************
	*** vivi1_ch ***
	**************
	/* tipo_vivienda: 1-3=casa/1, 4-5=apto/2, 6-8+99=otros/3 */
	gen byte vivi1_ch = 1 if inlist(tipo_vivienda, 1, 2, 3)
	replace vivi1_ch = 2 if inlist(tipo_vivienda, 4, 5)
	replace vivi1_ch = 3 if inlist(tipo_vivienda, 6, 7, 8)
	replace vivi1_ch = . if tipo_vivienda == 99

	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if vivi1_ch == 1 | vivi1_ch == 2
	replace vivi2_ch = 0 if vivi1_ch == 3

	*****************
	*** viviprop_ch ***
	*****************
	/* tenencia_vivienda: 1=contado/1, 5=construida/1, 2-3=plazo/2, 4+6+7=donada/cedida/3, 9=alquilada/0, 8/. */
	gen byte viviprop_ch = 0 if tenencia_vivienda == 9
	replace viviprop_ch = 1 if inlist(tenencia_vivienda, 1, 5)
	replace viviprop_ch = 2 if inlist(tenencia_vivienda, 2, 3)
	replace viviprop_ch = 3 if inlist(tenencia_vivienda, 4, 6, 7)
	replace viviprop_ch = . if tenencia_vivienda == 8

	*****************
	*** vivitit_ch ***
	*****************
	gen byte vivitit_ch = . /* sin pregunta de título */

	****************
	*** vivialq_ch ***
	****************
	/* periodo_pago_alquiler_viv: 1=semana, 2=mes, 3=quincena, 4=año */
	gen double monto_alquiler = (monto_alquiler_dolares_viv * 60.99) + monto_alquiler_pesos_viv if tenencia_vivienda == 9
	gen double vivialq_ch = . if tenencia_vivienda == 9
	replace vivialq_ch = monto_alquiler * 4.3 if periodo_pago_alquiler_viv == 1
	replace vivialq_ch = monto_alquiler        if periodo_pago_alquiler_viv == 2
	replace vivialq_ch = monto_alquiler * 2    if periodo_pago_alquiler_viv == 3
	replace vivialq_ch = monto_alquiler / 12   if periodo_pago_alquiler_viv == 4
	replace vivialq_ch = . if monto_alquiler == 0

	*******************
	*** vivialqimp_ch ***
	*******************
	gen double vivialqimp_ch = monto_alquilaria_vivienda_mes


	************************
	*** VARIABLES DE WASH **
	************************

	***************
	*** aguared_ch ***
	***************
	/* donde_proviene_agua: 1=acueducto interior, 2=acueducto patio / red */
	gen byte aguared_ch = (donde_proviene_agua == 1 | donde_proviene_agua == 2)
	replace aguared_ch = . if donde_proviene_agua == .

	*******************
	*** aguafconsumo_ch ***
	*******************
	gen byte aguafconsumo_ch = 0 /* sin pregunta separada de fuente de consumo */

	*****************
	*** aguafuente_ch ***
	*****************
	/* 1=red privada, 2=llave pública/standpipe, 3=embotellada(no aplica DOM), 4=pozo mejorado,
	   5=lluvia, 6=camión, 7=otra mejorada, 8=superficial, 9=no mejorada, 10=sin clasificar

	   donde_proviene_agua:
	   1=acueducto interior / 1
	   2=acueducto patio / 1
	   3=llave otra vivienda / 7 (red de vecino = otra mejorada)
	   4=llave pública / 2
	   5=tubo de la calle / 2
	   6=manantial/río / 8
	   7=lluvia / 5
	   8=pozo / 10 (no distingue pozo protegido)
	   9=camión tanque / 6
	   99=otro / 10 */
	gen byte aguafuente_ch = 1  if inlist(donde_proviene_agua, 1, 2)
	replace aguafuente_ch = 7  if donde_proviene_agua == 3
	replace aguafuente_ch = 2  if inlist(donde_proviene_agua, 4, 5)
	replace aguafuente_ch = 8  if donde_proviene_agua == 6
	replace aguafuente_ch = 5  if donde_proviene_agua == 7
	replace aguafuente_ch = 10 if donde_proviene_agua == 8
	replace aguafuente_ch = 6  if donde_proviene_agua == 9
	replace aguafuente_ch = 10 if donde_proviene_agua == 99 | missing(donde_proviene_agua)

	*****************
	*** aguadist_ch ***
	*****************
	/* 0=no aplica, 1=dentro, 2=patio, 3=fuera (compartida) */
	gen byte aguadist_ch = 0
	replace aguadist_ch = 1 if donde_proviene_agua == 1
	replace aguadist_ch = 2 if donde_proviene_agua == 2
	replace aguadist_ch = 3 if inlist(donde_proviene_agua, 3, 4)

	*****************
	*** aguadisp1_ch ***
	*****************
	gen byte aguadisp1_ch = 9 /* ENCFT sin pregunta de disponibilidad */

	*****************
	*** aguadisp2_ch ***
	*****************
	gen byte aguadisp2_ch = 9

	***************
	*** aguatrat_ch ***
	***************
	gen byte aguatrat_ch = 9 /* ENCFT sin pregunta de tratamiento */

	***************
	*** aguamala_ch ***
	***************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	*****************
	*** aguamejorada_ch ***
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	***************
	*** aguamide_ch ***
	***************
	gen byte aguamide_ch = . /* sin medidor de agua */

	*************
	*** bano_ch ***
	*************
	/* tipo_sanitario: 1=inodoro privado, 2=inodoro compartido, 3=letrina privada,
	   4=letrina compartida, 5=sin baño
	   se_encuentra_conectada_a: 1=pozo séptico, 2=alcantarillado */
	gen byte bano_ch = .
	replace bano_ch = 0 if tipo_sanitario == 5
	replace bano_ch = 1 if inlist(tipo_sanitario, 1, 2) & se_encuentra_conectada_a == 2
	replace bano_ch = 2 if inlist(tipo_sanitario, 1, 2) & se_encuentra_conectada_a == 1
	replace bano_ch = 6 if inlist(tipo_sanitario, 3, 4)

	**************
	*** banoex_ch ***
	**************
	gen byte banoex_ch = 9
	replace banoex_ch = 1 if inlist(tipo_sanitario, 1, 3)
	replace banoex_ch = 0 if inlist(tipo_sanitario, 2, 4)

	**************
	*** banomejorado_ch ***
	**************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6 & bano_ch != .

	***************
	*** sinbano_ch ***
	***************
	gen byte sinbano_ch = 3
	replace sinbano_ch = 0 if tipo_sanitario != 5


	***************************************
	*** VARIABLES DE MIGRACIÓN           ***
	***************************************

	*****************
	*** migrante_ci ***
	*****************
	/* pais_nacimiento: 647 = República Dominicana */
	gen byte migrante_ci = (pais_nacimiento != 647 & pais_nacimiento != .)

	**********************
	*** migrantiguo5_ci ***
	**********************
	gen byte migrantiguo5_ci = . /* ENCFT sin pregunta de residencia hace 5 años */

	***************
	*** miglac_ci ***
	***************
	gen byte miglac_ci = .
	replace  miglac_ci = 0 if migrante_ci == 1
	replace  miglac_ci = 1 if migrante_ci == 1 & inlist(pais_nacimiento, ///
		63, 77, 83, 88, 97, 105, 169, 196, 211, 239, 242, 317, 325, ///
		341, 345, 391, 493, 580, 586, 589, 770, 810, 845, 850)
	replace  miglac_ci = . if migrante_ci == 0

	***************
	*** mig_pais_ci ***
	***************
	
	*pais de nacimiento (código)
gen mig_pais_code = pais_nacimiento
gen str40 mig_pais_ci = ""
* Rellenar según código (confirmar que se abarcan todos los países)
replace mig_pais_ci = "Afganistán" if mig_pais_code==13
replace mig_pais_ci = "Albania" if mig_pais_code==17
replace mig_pais_ci = "Alemania" if mig_pais_code==23
replace mig_pais_ci = "Armenia" if mig_pais_code==26
replace mig_pais_ci = "Aruba" if mig_pais_code==27
replace mig_pais_ci = "Bosnia-Herzegovina" if mig_pais_code==29
replace mig_pais_ci = "Burkina Faso" if mig_pais_code==31
replace mig_pais_ci = "Andorra" if mig_pais_code==37
replace mig_pais_ci = "Angola" if mig_pais_code==40
replace mig_pais_ci = "Anguilla" if mig_pais_code==41
replace mig_pais_ci = "Antigua y Barbuda" if mig_pais_code==43
replace mig_pais_ci = "Antillas Holandesas" if mig_pais_code==47
replace mig_pais_ci = "Arabia Saudita" if mig_pais_code==53
replace mig_pais_ci = "Argelia" if mig_pais_code==59
replace mig_pais_ci = "Argentina" if mig_pais_code==63
replace mig_pais_ci = "Australia" if mig_pais_code==69
replace mig_pais_ci = "Austria" if mig_pais_code==72
replace mig_pais_ci = "Azerbaiyán" if mig_pais_code==74
replace mig_pais_ci = "Bahamas" if mig_pais_code==77
replace mig_pais_ci = "Bahrein" if mig_pais_code==80
replace mig_pais_ci = "Bangladesh" if mig_pais_code==81
replace mig_pais_ci = "Barbados" if mig_pais_code==83
replace mig_pais_ci = "Bélgica" if mig_pais_code==87
replace mig_pais_ci = "Belice" if mig_pais_code==88
replace mig_pais_ci = "Bermudas" if mig_pais_code==90
replace mig_pais_ci = "Bielorrusia" if mig_pais_code==91
replace mig_pais_ci = "Birmania (Myanmar)" if mig_pais_code==93
replace mig_pais_ci = "Bolivia" if mig_pais_code==97
replace mig_pais_ci = "Botswana" if mig_pais_code==101
replace mig_pais_ci = "Brasil" if mig_pais_code==105
replace mig_pais_ci = "Brunei Darussalam" if mig_pais_code==108
replace mig_pais_ci = "Bulgaria" if mig_pais_code==111
replace mig_pais_ci = "Burundi" if mig_pais_code==115
replace mig_pais_ci = "Bután" if mig_pais_code==119
replace mig_pais_ci = "Cabo Verde" if mig_pais_code==127
replace mig_pais_ci = "Islas Caimán" if mig_pais_code==137
replace mig_pais_ci = "Camboya (Kampuchea)" if mig_pais_code==141
replace mig_pais_ci = "Camerún" if mig_pais_code==145
replace mig_pais_ci = "Canadá" if mig_pais_code==149
replace mig_pais_ci = "Santa Sede" if mig_pais_code==159
replace mig_pais_ci = "Islas Cocos (Keeling)" if mig_pais_code==165
replace mig_pais_ci = "Colombia" if mig_pais_code==169
replace mig_pais_ci = "Comoras" if mig_pais_code==173
replace mig_pais_ci = "Congo" if mig_pais_code==177
replace mig_pais_ci = "Islas Cook" if mig_pais_code==183
replace mig_pais_ci = "Corea del Norte" if mig_pais_code==187
replace mig_pais_ci = "Corea del Sur" if mig_pais_code==190
replace mig_pais_ci = "Costa de Marfil" if mig_pais_code==193
replace mig_pais_ci = "Costa Rica" if mig_pais_code==196
replace mig_pais_ci = "Croacia" if mig_pais_code==198
replace mig_pais_ci = "Cuba" if mig_pais_code==199
replace mig_pais_ci = "Chad" if mig_pais_code==203
replace mig_pais_ci = "Chile" if mig_pais_code==211
replace mig_pais_ci = "China" if mig_pais_code==215
replace mig_pais_ci = "Taiwán (Formosa)" if mig_pais_code==218
replace mig_pais_ci = "Chipre" if mig_pais_code==221
replace mig_pais_ci = "Benín" if mig_pais_code==229
replace mig_pais_ci = "Dinamarca" if mig_pais_code==232
replace mig_pais_ci = "Dominica" if mig_pais_code==235
replace mig_pais_ci = "Ecuador" if mig_pais_code==239
replace mig_pais_ci = "Egipto" if mig_pais_code==240
replace mig_pais_ci = "El Salvador" if mig_pais_code==242
replace mig_pais_ci = "Eritrea" if mig_pais_code==243
replace mig_pais_ci = "Emiratos Árabes Unidos" if mig_pais_code==244
replace mig_pais_ci = "España" if mig_pais_code==245
replace mig_pais_ci = "Eslovaquia" if mig_pais_code==246
replace mig_pais_ci = "Eslovenia" if mig_pais_code==247
replace mig_pais_ci = "Estados Unidos" if mig_pais_code==249
replace mig_pais_ci = "Estonia" if mig_pais_code==251
replace mig_pais_ci = "Etiopía" if mig_pais_code==253
replace mig_pais_ci = "Islas Feroe" if mig_pais_code==259
replace mig_pais_ci = "Filipinas" if mig_pais_code==267
replace mig_pais_ci = "Finlandia" if mig_pais_code==271
replace mig_pais_ci = "Francia" if mig_pais_code==275
replace mig_pais_ci = "Gabón" if mig_pais_code==281
replace mig_pais_ci = "Gambia" if mig_pais_code==285
replace mig_pais_ci = "Georgia" if mig_pais_code==287
replace mig_pais_ci = "Ghana" if mig_pais_code==289
replace mig_pais_ci = "Gibraltar" if mig_pais_code==293
replace mig_pais_ci = "Granada" if mig_pais_code==297
replace mig_pais_ci = "Grecia" if mig_pais_code==301
replace mig_pais_ci = "Groenlandia" if mig_pais_code==305
replace mig_pais_ci = "Guadalupe" if mig_pais_code==309
replace mig_pais_ci = "Guam" if mig_pais_code==313
replace mig_pais_ci = "Guatemala" if mig_pais_code==317
replace mig_pais_ci = "Guayana Francesa" if mig_pais_code==325
replace mig_pais_ci = "Guinea" if mig_pais_code==329
replace mig_pais_ci = "Guinea Ecuatorial" if mig_pais_code==331
replace mig_pais_ci = "Guinea-Bissau" if mig_pais_code==334
replace mig_pais_ci = "Guyana" if mig_pais_code==337
replace mig_pais_ci = "Haití" if mig_pais_code==341
replace mig_pais_ci = "Honduras" if mig_pais_code==345
replace mig_pais_ci = "Hong Kong" if mig_pais_code==351
replace mig_pais_ci = "Hungría" if mig_pais_code==355
replace mig_pais_ci = "India" if mig_pais_code==361
replace mig_pais_ci = "Indonesia" if mig_pais_code==365
replace mig_pais_ci = "Irak" if mig_pais_code==369
replace mig_pais_ci = "Irán" if mig_pais_code==372
replace mig_pais_ci = "Irlanda" if mig_pais_code==375
replace mig_pais_ci = "Islandia" if mig_pais_code==379
replace mig_pais_ci = "Israel" if mig_pais_code==383
replace mig_pais_ci = "Italia" if mig_pais_code==386
replace mig_pais_ci = "Jamaica" if mig_pais_code==391
replace mig_pais_ci = "Japón" if mig_pais_code==399
replace mig_pais_ci = "Jordania" if mig_pais_code==403
replace mig_pais_ci = "Kazajistán" if mig_pais_code==406
replace mig_pais_ci = "Kenia" if mig_pais_code==410
replace mig_pais_ci = "Kiribati" if mig_pais_code==411
replace mig_pais_ci = "Kirguistán" if mig_pais_code==412
replace mig_pais_ci = "Kuwait" if mig_pais_code==413
replace mig_pais_ci = "Laos" if mig_pais_code==420
replace mig_pais_ci = "Lesoto" if mig_pais_code==426
replace mig_pais_ci = "Letonia" if mig_pais_code==429
replace mig_pais_ci = "Líbano" if mig_pais_code==431
replace mig_pais_ci = "Liberia" if mig_pais_code==434
replace mig_pais_ci = "Libia" if mig_pais_code==438
replace mig_pais_ci = "Liechtenstein" if mig_pais_code==440
replace mig_pais_ci = "Lituania" if mig_pais_code==443
replace mig_pais_ci = "Luxemburgo" if mig_pais_code==445
replace mig_pais_ci = "Macao" if mig_pais_code==447
replace mig_pais_ci = "Macedonia" if mig_pais_code==448
replace mig_pais_ci = "Madagascar" if mig_pais_code==450
replace mig_pais_ci = "Malasia" if mig_pais_code==455
replace mig_pais_ci = "Malawi" if mig_pais_code==458
replace mig_pais_ci = "Maldivas" if mig_pais_code==461
replace mig_pais_ci = "Malí" if mig_pais_code==464
replace mig_pais_ci = "Malta" if mig_pais_code==467
replace mig_pais_ci = "Islas Marianas del Norte" if mig_pais_code==469
replace mig_pais_ci = "Islas Marshall" if mig_pais_code==472
replace mig_pais_ci = "Marruecos" if mig_pais_code==474
replace mig_pais_ci = "Martinica" if mig_pais_code==477
replace mig_pais_ci = "Mauricio" if mig_pais_code==485
replace mig_pais_ci = "Mauritania" if mig_pais_code==488
replace mig_pais_ci = "México" if mig_pais_code==493
replace mig_pais_ci = "Micronesia" if mig_pais_code==494
replace mig_pais_ci = "Moldavia" if mig_pais_code==496
replace mig_pais_ci = "Mongolia" if mig_pais_code==497
replace mig_pais_ci = "Mónaco" if mig_pais_code==498
replace mig_pais_ci = "Montserrat" if mig_pais_code==501
replace mig_pais_ci = "Mozambique" if mig_pais_code==505
replace mig_pais_ci = "Namibia" if mig_pais_code==507
replace mig_pais_ci = "Nauru" if mig_pais_code==508
replace mig_pais_ci = "Islas Navidad (Christmas)" if mig_pais_code==511
replace mig_pais_ci = "Nepal" if mig_pais_code==517
replace mig_pais_ci = "Nicaragua" if mig_pais_code==521
replace mig_pais_ci = "Níger" if mig_pais_code==525
replace mig_pais_ci = "Nigeria" if mig_pais_code==528
replace mig_pais_ci = "Niue" if mig_pais_code==531
replace mig_pais_ci = "Isla Norfolk" if mig_pais_code==535
replace mig_pais_ci = "Noruega" if mig_pais_code==538
replace mig_pais_ci = "Nueva Caledonia" if mig_pais_code==542
replace mig_pais_ci = "Papúa Nueva Guinea" if mig_pais_code==545
replace mig_pais_ci = "Nueva Zelandia" if mig_pais_code==548
replace mig_pais_ci = "Vanuatu" if mig_pais_code==551
replace mig_pais_ci = "Omán" if mig_pais_code==556
replace mig_pais_ci = "Islas del Pacífico (USA)" if mig_pais_code==566
replace mig_pais_ci = "Países Bajos (Holanda)" if mig_pais_code==573
replace mig_pais_ci = "Pakistán" if mig_pais_code==576
replace mig_pais_ci = "Islas Palau" if mig_pais_code==578
replace mig_pais_ci = "Panamá" if mig_pais_code==580
replace mig_pais_ci = "Paraguay" if mig_pais_code==586
replace mig_pais_ci = "Perú" if mig_pais_code==589
replace mig_pais_ci = "Isla Pitcairn" if mig_pais_code==593
replace mig_pais_ci = "Polinesia Francesa" if mig_pais_code==599
replace mig_pais_ci = "Polonia" if mig_pais_code==603
replace mig_pais_ci = "Portugal" if mig_pais_code==607
replace mig_pais_ci = "Puerto Rico" if mig_pais_code==611
replace mig_pais_ci = "Qatar" if mig_pais_code==618
replace mig_pais_ci = "Reino Unido" if mig_pais_code==628
replace mig_pais_ci = "República Centroafricana" if mig_pais_code==640
replace mig_pais_ci = "República Checa" if mig_pais_code==644
replace mig_pais_ci = "República Dominicana" if mig_pais_code==647
replace mig_pais_ci = "Reunión" if mig_pais_code==660
replace mig_pais_ci = "Zimbabue" if mig_pais_code==665
replace mig_pais_ci = "Rumania" if mig_pais_code==670
replace mig_pais_ci = "Ruanda" if mig_pais_code==675
replace mig_pais_ci = "Rusia" if mig_pais_code==676
replace mig_pais_ci = "Islas Salomón" if mig_pais_code==677
replace mig_pais_ci = "Sahara Occidental" if mig_pais_code==685
replace mig_pais_ci = "Samoa" if mig_pais_code==687
replace mig_pais_ci = "Samoa Norteamericana" if mig_pais_code==690
replace mig_pais_ci = "San Cristóbal y Nieves" if mig_pais_code==695
replace mig_pais_ci = "San Marino" if mig_pais_code==697
replace mig_pais_ci = "San Pedro y Miquelón" if mig_pais_code==700
replace mig_pais_ci = "San Vicente y las Granadinas" if mig_pais_code==705
replace mig_pais_ci = "Santa Elena" if mig_pais_code==710
replace mig_pais_ci = "Santa Lucía" if mig_pais_code==715
replace mig_pais_ci = "Santo Tomé y Príncipe" if mig_pais_code==720
replace mig_pais_ci = "Senegal" if mig_pais_code==728
replace mig_pais_ci = "Seychelles" if mig_pais_code==731
replace mig_pais_ci = "Sierra Leona" if mig_pais_code==735
replace mig_pais_ci = "Singapur" if mig_pais_code==741
replace mig_pais_ci = "Siria" if mig_pais_code==744
replace mig_pais_ci = "Somalia" if mig_pais_code==748
replace mig_pais_ci = "Sri Lanka" if mig_pais_code==750
replace mig_pais_ci = "Sudáfrica" if mig_pais_code==756
replace mig_pais_ci = "Sudán" if mig_pais_code==759
replace mig_pais_ci = "Suecia" if mig_pais_code==764
replace mig_pais_ci = "Suiza" if mig_pais_code==767
replace mig_pais_ci = "Surinam" if mig_pais_code==770
replace mig_pais_ci = "Suazilandia" if mig_pais_code==773
replace mig_pais_ci = "Tayikistán" if mig_pais_code==774
replace mig_pais_ci = "Tailandia" if mig_pais_code==776
replace mig_pais_ci = "Tanzania" if mig_pais_code==780
replace mig_pais_ci = "Yibuti" if mig_pais_code==783
replace mig_pais_ci = "Territorio Británico del Océano Índico" if mig_pais_code==787
replace mig_pais_ci = "Timor del Este" if mig_pais_code==788
replace mig_pais_ci = "Togo" if mig_pais_code==800
replace mig_pais_ci = "Tokelau" if mig_pais_code==805
replace mig_pais_ci = "Tonga" if mig_pais_code==810
replace mig_pais_ci = "Trinidad y Tobago" if mig_pais_code==815
replace mig_pais_ci = "Túnez" if mig_pais_code==820
replace mig_pais_ci = "Islas Turcas y Caicos" if mig_pais_code==823
replace mig_pais_ci = "Turkmenistán" if mig_pais_code==825
replace mig_pais_ci = "Turquía" if mig_pais_code==827
replace mig_pais_ci = "Tuvalu" if mig_pais_code==828
replace mig_pais_ci = "Ucrania" if mig_pais_code==830
replace mig_pais_ci = "Uganda" if mig_pais_code==833
replace mig_pais_ci = "Uruguay" if mig_pais_code==845
replace mig_pais_ci = "Uzbekistán" if mig_pais_code==847
replace mig_pais_ci = "Venezuela" if mig_pais_code==850
replace mig_pais_ci = "Vietnam" if mig_pais_code==855
replace mig_pais_ci = "Islas Vírgenes Británicas" if mig_pais_code==863
replace mig_pais_ci = "Islas Vírgenes Norteamericanas" if mig_pais_code==866
replace mig_pais_ci = "Fiyi" if mig_pais_code==870
replace mig_pais_ci = "Islas Wallis y Futuna" if mig_pais_code==875
replace mig_pais_ci = "Yemen" if mig_pais_code==880
replace mig_pais_ci = "Yugoslavia (ant.)" if mig_pais_code==885
replace mig_pais_ci = "Zaire (ant., hoy RD Congo)" if mig_pais_code==888
replace mig_pais_ci = "Zambia" if mig_pais_code==890
replace mig_pais_ci = "Zona Neutral Palestina" if mig_pais_code==897
* Códigos 777 y 970 no están en el catálogo DIAN estándar - confirmar en diccionario ENCFT
	
	
	***************************************
	*** VARIABLES DE REFERENCIA EXTERNA ***
	***************************************
	
	**********************
	*** tipo_bienestar ***
	**********************
	/* ENCFT mide bienestar por ingreso monetario. */
	gen byte tipo_bienestar = 1

	*********************
	*** pobre_ine_ci   ***
	*********************
	gen byte pobre_ine_ci = .

	*************************
	*** bienestar_agregado ***
	*************************
	gen double bienestar_agregado = .

	*******************
	*** ln_ci        ***
	*******************
	/* Línea de pobreza monetaria general (MEPYD). https://www.hacienda.gob.do/wp-content/uploads/2026/02/Boletin-Pobreza-Monetaria-2025.pdf. */
	gen double ln_ci = 8273.6 


	*******************
	*** lpe_ci       ***
	*******************
	/* Línea de pobreza extrema (MEPYD). https://www.hacienda.gob.do/wp-content/uploads/2026/02/Boletin-Pobreza-Monetaria-2025.pdf. */
	gen double lpe_ci = 3943.4

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
