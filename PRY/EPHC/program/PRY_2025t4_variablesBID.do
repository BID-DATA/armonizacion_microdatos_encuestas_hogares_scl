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
 
local PAIS     "PRY"
local ENCUESTA "EPHC"
local ANO      "2025"
local ronda    "t4"

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Paraguay
Encuesta: EPHC
Round: t4
Autores: Matías Isla y Matias Rodriguez (SCL/SCL)
Version: 28/04/2026
Mail: matiasi@iadb.org/mrodriguezm@iadb.org, 13 de ,ayp de 2026
	
							SCL/SCL - IADB							
***************************************************************************/

use `base_in', clear


********************************************************************************
***************  VARIABLES DE IDENTIFICACIÓN  ***********************************
********************************************************************************

	********************
	*** region_BID_c ***
	********************
	gen byte region_BID_c = 4

	********************
	*** region_c ***
	********************
	/* estgeo: Asunción=1; deptos × urbano(X1)/rural(X6); Boquerón/Alto Paraguay = 0 obs (excluidos por diseño muestral) */
	gen region_c = .
	replace region_c = 1 if estgeo == 1                       /* Asunción */
	replace region_c = 2 if inlist(estgeo, 21, 26)            /* San Pedro */
	replace region_c = 3 if inlist(estgeo, 51, 56)            /* Caaguazú */
	replace region_c = 4 if inlist(estgeo, 71, 76)            /* Itapúa */
	replace region_c = 5 if inlist(estgeo, 101, 106)          /* Alto Paraná */
	replace region_c = 6 if inlist(estgeo, 111, 116)          /* Central */
	replace region_c = 7 if inlist(estgeo, 11, 16)            /* Concepción */
	replace region_c = 8 if inlist(estgeo, 31, 36)            /* Cordillera */
	replace region_c = 9 if inlist(estgeo, 41, 46)            /* Guairá */
	replace region_c = 10 if inlist(estgeo, 61, 66)            /* Caazapá */
	replace region_c = 11 if inlist(estgeo, 81, 86)            /* Misiones */
	replace region_c = 12 if inlist(estgeo, 91, 96)            /* Paraguarí */
	replace region_c = 13 if inlist(estgeo, 121, 126)          /* Ñeembucú */
	replace region_c = 14 if inlist(estgeo, 131, 136)          /* Amambay */
	replace region_c = 15 if inlist(estgeo, 141, 146)          /* Canindeyú */
	replace region_c = 16 if inlist(estgeo, 151, 156)          /* Pdte. Hayes */

	********************
	*** pais_c ***
	********************
	gen str3 pais_c = "PRY"

	********************
	*** anio_c ***
	********************
	gen int anio_c = 2025

	********************
	*** mes_c ***
	********************
	gen int mes_c = .   /* EPHC no tiene variable de mes */

	********************
	*** zona_c ***
	********************
	/* area: 1=Urbana, 6=Rural */
	gen byte zona_c = .
	replace zona_c = 1 if area == 1
	replace zona_c = 0 if area == 6

	********************
	*** estrato_ci ***
	********************
	gen estrato_ci = .   /* no existe en la encuesta */

	********************
	*** upm_ci ***
	********************
	gen upm_ci = upm

	********************
	*** idh_ch ***
	********************
	sort upm nvivi nhoga
	egen idh_ch = group(upm nvivi nhoga)
	tostring idh_ch, replace

	********************
	*** idp_ci ***
	********************
	egen idp_ci = concat(idh_ch l02)
	tostring idp_ci, replace format("%20.0f")

	********************
	*** factor_ch ***
	********************
	/* factor (revisión 2025) suma 6.184.688, similar a proyección DGEEC 2025, facpob suma 7.515.305 */
	gen factor_ch = factor

	********************
	*** factor_ci ***
	********************
	gen factor_ci = factor


********************************************************************************
***************  VARIABLES DEMOGRÁFICAS  ****************************************
********************************************************************************

	********************
	*** sexo_ci ***
	********************
	/* p06: 1=Hombre, 6=Mujer — CRÍTICO-7 confirmado */
	gen byte sexo_ci = .
	replace sexo_ci = 1 if p06 == 1
	replace sexo_ci = 2 if p06 == 6

	********************
	*** edad_ci ***
	********************
	gen int edad_ci = p02

	********************
	*** relacion_ci ***
	********************
	/* p03: 1=Jefe,2=Cónyuge,3=Hijo,4=Hijastro,5=Nieto,6=Yerno/Nuera,7=Padre/Madre,
	         8=Suegro,9=Otro pariente,10=No pariente,11=Empl.doméstico,12=Familiar empl.doméstico (missing)
	 */
	gen byte relacion_ci = .
	replace relacion_ci = 1 if p03 == 1
	replace relacion_ci = 2 if p03 == 2
	replace relacion_ci = 3 if inlist(p03, 3, 4, 5)   /* hijo, hijastro, nieto */
	replace relacion_ci = 4 if inlist(p03, 6, 7, 8, 9) /* yerno/nuera, padre/madre, suegro, otro pariente */
	replace relacion_ci = 5 if inlist(p03, 10, 12)    /* no pariente, familiar de empl.doméstico */
	replace relacion_ci = 6 if p03 == 11              /* empleado doméstico */

	********************
	*** miembros_ci ***
	********************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	********************
	*** miembros_one_ci ***
	********************
	/* p04: 1=Sí es miembro, 6=No es miembro */
	gen byte miembros_one_ci = .
	replace miembros_one_ci = 1 if p04 == 1
	replace miembros_one_ci = 0 if p04 == 6

	********************
	*** civil_ci ***
	********************
	/* p09: 1=Casado,2=Unido,3=Separado,4=Viudo,5=Soltero,6=Divorciado,9=NR */
	gen byte civil_ci = .
	replace civil_ci = 1 if p09 == 5             /* soltero */
	replace civil_ci = 2 if inlist(p09, 1, 2)   /* casado o unido */
	replace civil_ci = 3 if inlist(p09, 3, 6)   /* separado o divorciado */
	replace civil_ci = 4 if p09 == 4            /* viudo */

	********************
	*** jefe_ci ***
	********************
	gen byte jefe_ci = .
	replace jefe_ci = 1 if relacion_ci == 1
	replace jefe_ci = 0 if relacion_ci != 1 & relacion_ci != .

	********************
	*** nconyuges_ch ***
	********************
	by idh_ch, sort: egen byte nconyuges_ch = sum(relacion_ci == 2)
	replace nconyuges_ch = . if relacion_ci == .

	********************
	*** nhijos_ch ***
	********************
	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)
	replace nhijos_ch = . if relacion_ci == .

	********************
	*** notropari_ch ***
	********************
	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)
	replace notropari_ch = . if relacion_ci == .

	********************
	*** notronopari_ch ***
	********************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)
	replace notronopari_ch = . if relacion_ci == .

	********************
	*** nempdom_ch ***
	********************
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)
	replace nempdom_ch = . if relacion_ci == .

	********************
	*** clasehog_ch ***
	********************
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

	********************
	*** nmayor21_ch ***
	********************
	by idh_ch, sort: egen byte nmayor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 21 & edad_ci != .))

	********************
	*** nmenor21_ch ***
	********************
	by idh_ch, sort: egen byte nmenor21_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 21))

	********************
	*** nmayor65_ch ***
	********************
	by idh_ch, sort: egen byte nmayor65_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci >= 65 & edad_ci != .))

	********************
	*** nmenor6_ch ***
	********************
	by idh_ch, sort: egen byte nmenor6_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))

	********************
	*** nmenor1_ch ***
	********************
	by idh_ch, sort: egen byte nmenor1_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))


********************************************************************************
***************  VARIABLES DE DIVERSIDAD  ***************************************
********************************************************************************
/* EPHC no incluye preguntas de etnicidad ni discapacidad — todas en missing */

	********************
	*** afro_ci ***
	********************
	gen byte afro_ci = .

	********************
	*** ind_ci ***
	********************
	gen byte ind_ci = .

	********************
	*** noafroind_ci ***
	********************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci == 0 & ind_ci == 0
	replace noafroind_ci = 0 if afro_ci == 1 | ind_ci == 1

	********************
	*** afroind_ci ***
	********************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci == 1
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	********************
	*** afroind_ano_c ***
	********************
	gen afroind_ano_c = .

	********************
	*** afro_ch ***
	********************
	gen afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	********************
	*** ind_ch ***
	********************
	gen ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	********************
	*** noafroind_ch ***
	********************
	gen noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	********************
	*** afroind_ch ***
	********************
	gen afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	********************
	*** dis_ci ***
	********************
	gen byte dis_ci = .

	********************
	*** disWG_ci ***
	********************
	gen byte disWG_ci = .

	********************
	*** dis_ch ***
	********************
	egen dis_ch = max(dis_ci), by(idh_ch)

	********************
	*** PRY_dis_ci ***
	********************
	gen byte PRY_dis_ci = .


********************************************************************************
***************  VARIABLES DE MERCADO LABORAL  **********************************
********************************************************************************

	********************
	*** condocup_ci ***
	********************
	/* peaa: 1=Ocupado,2=Desocupado,3=Inactivo,9=NR,0=NA */
	gen byte condocup_ci = peaa
	replace condocup_ci = . if inlist(peaa, 9, 0) | peaa == .
	replace condocup_ci = 4 if edad_ci < 10

	********************
	*** categoinac_ci ***
	********************
	/* ra06ya09: 1=Estudiante,2=Labores hogar,3=No consigue,4=Enfermo,5=Anciano,
	             6=Discapacitado,7=Jubilado/Pensionado,8=Motivos familiares,9=Otra */
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if ra06ya09 == 7 & condocup_ci == 3   /* jubilado/pensionado */
	replace categoinac_ci = 2 if ra06ya09 == 1 & condocup_ci == 3   /* estudiante */
	replace categoinac_ci = 3 if ra06ya09 == 2 & condocup_ci == 3   /* labores del hogar */
	replace categoinac_ci = 4 if !inlist(ra06ya09, 1, 2, 7) & condocup_ci == 3   /* otros */
	replace categoinac_ci = . if ra06ya09 == .

	********************
	*** emp_ci ***
	********************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de 	referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	********************
	*** cesante_ci ***
	********************
	/* a12: 1=Sí ha trabajado, 6=No */
	gen byte cesante_ci = .
	replace cesante_ci = 1 if a12 == 1 & condocup_ci == 2
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci == 2

	********************
	*** desemp_ci ***
	********************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci

	********************
	*** subemp_ci ***
	********************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if horab < 30 & d05 == 6 & d01 == 1
	replace subemp_ci = . if condocup_ci != 1

	********************
	*** durades_ci ***
	********************
	gen a11s_c = a11s * (52/12)
	gen a11a_c = a11a / 12
	gen durades_ci = a11a_c + a11m + a11s_c
	replace durades_ci = . if condocup_ci == 1
	drop a11s_c a11a_c

	********************
	*** pea_ci ***
	********************
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci, 1, 2)
	replace pea_ci = 0 if inlist(condocup_ci, 3, 4)

	********************
	*** nempleos_ci ***
	********************
	gen byte nempleos_ci = .
	replace nempleos_ci = a04a if emp_ci == 1

	********************
	*** antiguedad_ci ***
	********************
	/* b07a: años trabajando en ocupación principal */
	gen byte antiguedad_ci = b07a if emp_ci == 1

	********************
	*** desalent_ci ***
	********************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
*destring s04a_07, ignore("NA") replace
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (a08 == 6 & inlist(a09, 2, 3) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci
	********************
	*** horaspri_ci ***
	********************
	/* horab: 999=missing */
	gen byte horaspri_ci = horab
	replace horaspri_ci = . if horab == 999 | emp_ci == 0

	********************
	*** horastot_ci ***
	********************
	gen byte horastot_ci = horabco
	replace horastot_ci = . if horab == 999 | emp_ci == 0

	********************
	*** tiempoparc_ci ***
	********************
	/* d03: 6=no desea cambiar */
	gen byte tiempoparc_ci = ((horaspri_ci >= 1 & horaspri_ci < 30) & d03 == 6 & emp_ci == 1)

	********************
	*** categopri_ci ***
	********************
	/* cate_pea: 1=emp/obrero público,2=emp/obrero privado,3=patrón,4=cuenta propia,
	             5=familiar no remunerado,6=empl.doméstico,9=NR
	   CRÍTICO-11: mapeo 2024 correcto + cierre canónico categopri_ci=0 */
	gen byte categopri_ci = .
	replace categopri_ci = 1 if cate_pea == 3 & emp_ci == 1 /* patrón */
	replace categopri_ci = 2 if cate_pea == 4 & emp_ci == 1 /* cuenta propia */
	replace categopri_ci = 3 if inlist(cate_pea, 1, 2, 6) & emp_ci == 1 /* asalariado + doméstico */
	replace categopri_ci = 4 if cate_pea == 5 & emp_ci == 1 /* familiar no remunerado */
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1 /* cierre canónico */

	********************
	*** categosec_ci ***
	********************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if c09 == 3 & emp_ci == 1
	replace categosec_ci = 2 if c09 == 4 & emp_ci == 1
	replace categosec_ci = 3 if inlist(c09, 1, 2, 6) & emp_ci == 1
	replace categosec_ci = 4 if c09 == 5 & emp_ci == 1
	replace categosec_ci = 0 if inlist(c09, 7, 8) & emp_ci == 1
	replace categosec_ci = . if emp_ci != 1 | inlist(c09, ., 9)

	********************
	*** rama_ci ***
	********************
	/* b02rec: 1=Agricultura,2=Manufactura,3=Electricidad/gas/agua,4=Construcción,
	           5=Comercio/hoteles,6=Transporte,7=Financiero,8=Servicios,99=NR */
	gen byte rama_ci = .
	replace rama_ci = 1 if b02rec == 1 & emp_ci == 1
	replace rama_ci = 3 if b02rec == 2 & emp_ci == 1
	replace rama_ci = 4 if b02rec == 3 & emp_ci == 1
	replace rama_ci = 5 if b02rec == 4 & emp_ci == 1
	replace rama_ci = 6 if b02rec == 5 & emp_ci == 1
	replace rama_ci = 7 if b02rec == 6 & emp_ci == 1
	replace rama_ci = 8 if b02rec == 7 & emp_ci == 1
	replace rama_ci = 9 if b02rec == 8 & emp_ci == 1

	********************
	*** spublico_ci ***
	********************
	/* b02rec no distingue admin pública (todo queda en rama_ci=9 "Servicios").
	   cate_pea==1 = "Empleado obrero público" */
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & cate_pea == 1
	replace spublico_ci = 0 if emp_ci == 1 & cate_pea != 1 & cate_pea != 9 & cate_pea != .

	********************
	*** tamemp_ci ***
	********************
	/* b08: 1=Solo,2=2-5,3=6-10,4=11-20,5=21-30,6=31-50,7=51-100,8=101-500,9=+500,10=Empl.dom,11=No sabe,99=NR */
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if inlist(b08, 1, 2)       /* pequeña: 1-5 */
	replace tamemp_ci = 2 if inrange(b08, 3, 6)      /* mediana: 6-50 */
	replace tamemp_ci = 3 if inrange(b08, 7, 9)      /* grande: >50 */
	replace tamemp_ci = . if inlist(b08, 10, 11, 99) | b08 == .

	********************
	*** cotizando_ci ***
	********************
	/* b10: aporta caja principal, c07: aporta caja secundaria */
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((b10 == 1 | c07 == 1 ) & emp_ci==1) //Si aporta
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2)) // No aporta
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	********************
	*** instcot_ci ***
	********************
	gen byte instcot_ci = b11

	********************
	*** afiliado_ci ***
	********************
	gen byte afiliado_ci = .

	********************
	*** formal_ci ***
	********************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & inlist(condocup_ci, 1, 2)

	********************
	*** tipocontrato_ci ***
	********************
	/* b26: 1=Indefinido,2=Temp+factura,3=Temp-factura,4=Verbal — solo asalariados */
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if b26 == 1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if inlist(b26, 2, 3) & categopri_ci == 3
	replace tipocontrato_ci = 3 if b26 == 4 & categopri_ci == 3
	replace tipocontrato_ci = 3 if tipocontrato_ci == . & categopri_ci == 3   /* contrato verbal residual */

	********************
	*** ocupa_ci ***
	********************
	gen byte ocupa_ci = .

	********************
	*** tipopen_ci ***
	********************
	gen byte tipopen_ci = . /* no existe pregunta */

	********************
	*** instpen_ci ***
	********************
	gen byte instpen_ci = . /* no existe variable */


********************************************************************************
***************  VARIABLES DE INGRESOS & PROTECCIÓN SOCIAL  ********************
********************************************************************************

	/* Limpia valores outlier en variables de ingreso antes de usarlas */
	local var_ing = "e01aimde e01bimde e01cimde e01dde e01ede e01fde e01gde e01hde e01ide e01jde e01kde e01lde  e01mde e01kjde e02bde ingrevasode ingrealmuerzode b20t b23 b25"
	foreach x of local var_ing {
		replace `x' = . if `x' == 99999999999 | `x' == 0
	}

*A. INGRESOS LABORALES A NIVEL DE INDIVIDUO	

	********************
	*** ylmpri_ci ***
	********************
	/* e01aimde: ingreso actividad principal corregido por imputación */
	gen double ylmpri_ci = e01aimde if emp_ci == 1
	replace ylmpri_ci = 0 if inlist(condocup_ci, 2, 3)
	replace ylmpri_ci = 0 if categopri_ci == 4   /* familiar no remunerado */
	replace ylmpri_ci = 0 if ylmpri_ci < 0
	replace ylmpri_ci = . if e01aimde == . & emp_ci == 1

	********************
	*** ylnmpri_ci ***
	********************
	gen double comida   = b20t if emp_ci == 1   /* b20t ya mensualizado */
	gen double alquiler = b23  if emp_ci == 1 & b21 == 1
	gen double unifor   = b25 / 12 if emp_ci == 1

	egen double ylnmpri_ci = rowtotal(comida alquiler unifor) if emp_ci == 1, missing
	replace ylnmpri_ci = . if comida == . & alquiler == . & unifor == .
	drop comida alquiler unifor

	********************
	*** ylmsec_ci ***
	********************
	gen double ylmsec_ci = e01bimde if emp_ci == 1
	replace ylmsec_ci = 0 if inlist(condocup_ci, 2, 3)
	replace ylmsec_ci = 0 if categopri_ci == 4
	replace ylmsec_ci = 0 if ylmsec_ci < 0
	replace ylmsec_ci = . if e01bimde == . & emp_ci == 1

	********************
	*** ylnmsec_ci ***
	********************
	gen double ylnmsec_ci = .   /* no existe */

	********************
	*** ylmotros_ci ***
	********************
	gen double ylmotros_ci = e01cimde if emp_ci == 1
	replace ylmotros_ci = 0 if inlist(condocup_ci, 2, 3)
	replace ylmotros_ci = 0 if categopri_ci == 4
	replace ylmotros_ci = 0 if ylmotros_ci < 0
	replace ylmotros_ci = . if e01cimde == . & emp_ci == 1

	********************
	*** ylnmotros_ci ***
	********************
	gen double ylnmotros_ci = .   /* no existe */

	********************
	*** ylm_ci ***
	********************
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing

	********************
	*** ylnm_ci ***
	********************
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .
	

	*B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO	

	******************
	*** ytransf_ci ***
	******************
		* PNC - Pensiones sociales no contributivas:
				* Ingreso del Estado $ Adulto Mayor (e01kde)
		* PTMC - Programas de transferencias monetarias condicionadas:
				* Ingreso del Estado $ Tekoporã (e01ide)
		* POTROT - Programas de otras transferencias monetarias no condicionadas

	*** Beneficiarios a nivel individual:
		gen byte pnc_ci = (e01kde > 0) if !missing(e01kde)
		gen byte ptmc_ci = (e01ide > 0) if !missing(e01ide)
		gen byte potrot_ci = .

	*** Montos de transferencias a nivel individual:
		gen double ypnc_ci = e01kde	if e01kde > 0 & e01kde != 999999999	// Transferencias PNC
		gen double yptmc_ci = e01ide if e01ide > 0 & e01ide != 999999999		// Transferencias PTMC
		gen double yotrot_ci = .		// Otras transferencias POTROT

	*** Ingreso individual por transferencias no contributivas
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi

	********************
	*** ypen_ci ***
	********************
	/* e01hde: jubilación, e01jde: pensión (ex combatiente, viudas) */
	egen double ypen_ci = rowtotal(e01hde e01jde), missing
	replace ypen_ci = . if e01hde == . & e01jde == .

	********************
	*** ypensub_ci ***
	********************
	/* e01kde: Adulto Mayor (pensión no contributiva del Estado) */
	gen double ypensub_ci = ypen_ci
	
	********************
	*** remesas_ci ***
	********************
	gen double remesas_ci = e02bde if e02bde > 0 & e02bde != 999999999

	********************
	*** ynlm_ci ***
	********************
	/* Variables de ingresos no laborales
	e01dde  Ingreso mensual por alquileres o rentas netas
	e01ede  Ingreso mensual Por intereses o dividendos
	e01fde  Ingreso mensual por ayuda familiar del país
	e01gde  Ingreso mensual por divorcio / Asistencia alimentaria
	e01hde  Ingreso mensual por jubilación > ypen_ci
	e01ide  Ingreso mensual del Estado Monetario Tekopora > ytransf_ci
	e01jde  Ingreso mensual por pensión > ypen_ci
	e01kde  Ingreso mensual del Estado Monetario Adulto Mayor > ytransf_ci
	e01mde  Otros ingresos no laborales mensuales
	e01kjde Otros ingresos mensuales agro asignados al jefe de hogar
	e02bde  Ingreso mensual por ayuda familiar del exterior (individual) > remesas_ci	*/
	
	egen double ynlm_ci = rowtotal(e01dde e01ede e01fde e01gde ypen_ci ytransf_ci e01mde e01kjde remesas_ci), missing

	********************
	*** ynlnm_ci ***
	********************
	* e01lde Ing por víveres de alguna institución pública
	gen double ynlnm_ci = e01lde if e01lde > 0 & e01lde != 999999999
	
	********************
	*** ytot_ci ***
	********************
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing

	********************
	*** ynet_ci ***
	********************
	gen double aux_ytransf_ci = ytransf_ci*(-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi	
	drop aux_ytransf_ci
	

*C. INGRESOS A NIVEL DE HOGAR
	
	********************
	*** ylm_ch ***
	********************
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, missing

	********************
	*** ylnm_ch ***
	********************
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, missing

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
	
	********************
	*** remesas_ch ***
	********************
	by idh_ch, sort: egen double remesas_ch = total (remesas_ci) if miembros_ci == 1, missing
	
	********************
	*** ynlm_ch ***
	********************
	by idh_ch, sort: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, missing

	********************
	*** ynlnm_ch ***
	********************
	/* A nivel hogar: ingrevasode: vaso de leche imputado; ingrealmuerzode: almuerzo escolar imputado */
	bys idh_ch: egen double ing_nm1 = total(ynlnm_ci) if miembros_ci == 1, mi // Ingresos individuales
	egen double ynlnm_ch = rowtotal(ing_nm1 ingrevasode ingrealmuerzod) if miembros_ci == 1, mi

	********************
	*** ytot_ch ***
	********************
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci == 1, missing
	
	********************
	*** ynet_ch ***
	********************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	********************
	*** ylmhopri_ci ***
	********************
	gen double ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	********************
	*** ylmho_ci ***
	********************
	gen double ylmho_ci = ylm_ci / (4.3 * horastot_ci)
	replace ylmho_ci = . if ylmho_ci <= 0

	********************
	*** nrylmpri_ci ***
	********************
	gen byte nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
	replace nrylmpri_ci = . if emp_ci == .

	********************
	*** nrylmpri_ch ***
	********************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .

	********************
	*** pension_ci ***
	********************
	gen byte pension_ci = .
	replace pension_ci = 1 if ypen_ci > 0 & ypen_ci != .
	replace pension_ci = 0 if ypen_ci == . | ypen_ci == 0

	********************
	*** pensionsub_ci ***
	********************
	gen byte pensionsub_ci = .
	replace pensionsub_ci = 1 if ypensub_ci > 0 & ypensub_ci != .
	replace pensionsub_ci = 0 if ypensub_ci == . | ypensub_ci == 0


********************************************************************************
***************  VARIABLES DE EDUCACIÓN  ****************************************
********************************************************************************

	********************
	*** aedu_ci ***
	********************
	gen nivgra = ed0504
	tostring nivgra, gen(nivgra_str)
	gen aedu_temp = substr(nivgra_str, -1, 1)
	destring aedu_temp, replace
	replace aedu_temp = . if nivgra == 8888 | nivgra == 9999
	replace aedu_temp = 0 if inrange(nivgra, 1200, 1299) | inrange(nivgra, 1300, 1399) | ///
	                          inrange(nivgra, 1400, 1499) | inrange(nivgra, 1500, 1599) | ///
	                          inrange(nivgra, 1600, 1699) | inrange(nivgra, 1800, 1899)
	replace aedu_temp = . if inrange(nivgra, 100, 199) | inrange(nivgra, 1900, 1999)

	gen aedu_ci = aedu_temp
	replace aedu_ci = 0 if nivgra == 0
	replace aedu_ci = 0 if inrange(nivgra, 200, 299)
	replace aedu_ci = aedu_temp      if inrange(nivgra, 300, 399)
	replace aedu_ci = aedu_temp      if inrange(nivgra, 400, 499)
	replace aedu_ci = aedu_temp + 9  if inrange(nivgra, 500, 599)
	replace aedu_ci = aedu_temp + 6  if inrange(nivgra, 600, 699)
	replace aedu_ci = aedu_temp + 6  if inrange(nivgra, 700, 799)
	replace aedu_ci = aedu_temp + 6  if inrange(nivgra, 800, 899)
	replace aedu_ci = aedu_temp + 9  if inrange(nivgra, 900, 999)
	replace aedu_ci = aedu_temp + 9  if inrange(nivgra, 1000, 1099)
	replace aedu_ci = aedu_temp + 9  if inrange(nivgra, 1100, 1199)
	replace aedu_ci = aedu_temp + 6  if inrange(nivgra, 1700, 1799)
	replace aedu_ci = aedu_temp + 12 if inrange(nivgra, 2000, 2099)
	replace aedu_ci = aedu_temp + 12 if inrange(nivgra, 2100, 2199)
	replace aedu_ci = aedu_temp + 12 if inrange(nivgra, 2200, 2299)
	replace aedu_ci = aedu_temp + 12 if inrange(nivgra, 2300, 2399)
	replace aedu_ci = aedu_temp + 12 if inrange(nivgra, 2400, 2499)
	/* ed06c: posgrados */
	replace aedu_ci = aedu_temp + 19 if ed06c == 8   /* doctorado */
	replace aedu_ci = aedu_temp + 17 if ed06c == 9   /* maestría */
	replace aedu_ci = aedu_temp + 17 if ed06c == 10  /* especialización */
	drop nivgra nivgra_str aedu_temp

	********************
	*** edupre_ci ***
	********************
	gen byte edupre_ci = .

	********************
	*** eduui_ci ***
	********************
	gen byte eduui_ci = .
	replace eduui_ci = 1 if inlist(ed08, 12, 13, 14, 15, 16, 17, 18)
	replace eduui_ci = 0 if eduui_ci == .
	replace eduui_ci = . if inlist(ed08, 99, .)

	********************
	*** eduuc_ci ***
	********************
	/* ed06c: 6=Militar/Policial,7=Técnica Superior,11=Formación Docente,
	          12=Militar/Policial post,13=Técnico Superior post, 8=Doctorado,9=Maestría */
	gen byte eduuc_ci = .
	replace eduuc_ci = 1 if inlist(ed06c, 6, 7, 11, 12, 13)
	replace eduuc_ci = 1 if inlist(ed06c, 8, 9) | ed08 == 18
	replace eduuc_ci = 0 if eduuc_ci == .
	replace eduuc_ci = . if inlist(ed06c, ., 99) | inlist(ed08, ., 99)
	replace eduui_ci = 0 if eduuc_ci == 1

	********************
	*** eduac_ci ***
	********************
	gen byte eduac_ci = .
	replace eduac_ci = 1 if inrange(ed0504, 2101, 2499)   /* superior universitario o posgrado */
	replace eduac_ci = 0 if inrange(ed0504, 2001, 2004)   /* técnico superior */
	replace eduac_ci = . if ed0504 == 9999
	/* Matriculados en superior sin grado completado aún (ed06c=.) por ed08 */
	replace eduac_ci = 0 if eduui_ci == 1 & ed08 == 12 & eduac_ci == .             /* Técnica Superior */
	replace eduac_ci = 1 if eduui_ci == 1 & inlist(ed08, 13, 14, 15, 16, 17, 18) & eduac_ci == .  /* Univ/Post */

	********************
	*** asiste_ci ***
	********************
	gen byte asiste_ci = .
	replace asiste_ci = 1 if inrange(ed08, 1, 18)
	replace asiste_ci = 0 if ed08 == 19
	replace asiste_ci = . if inlist(ed08, 99, .)

	********************
	*** edupub_ci ***
	********************
	/* ed09: 1=Público,2=Privado,3=Privado subvencionado, solo para asistentes */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if ed09 == 1 & asiste_ci == 1
	replace edupub_ci = 0 if inlist(ed09, 2, 3) & asiste_ci == 1
	replace edupub_ci = . if ed09 == 9 | asiste_ci != 1

	********************
	*** razonesnoasis_ci ***
	********************
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(ed10, 1, 2, 3)           /* problemas económicos/trabajo */
	replace razonesnoasis_ci = 2 if inlist(ed10, 5, 15)             /* falta de interés */
	replace razonesnoasis_ci = 3 if inlist(ed10, 12, 13, 14)        /* enfermedad/quehaceres/familiares */
	replace razonesnoasis_ci = 4 if inlist(ed10, 4, 6, 7, 8, 9, 10, 11)  /* problemas de acceso */
	replace razonesnoasis_ci = 5 if inlist(ed10, 16, 17, 18)        /* otros */
	replace razonesnoasis_ci = . if inlist(ed10, 99, .)
	replace razonesnoasis_ci = . if asiste_ci == 1

	********************
	*** asispre_ci ***
	********************
	gen byte asispre_ci = .
	replace asispre_ci = 1 if ed08 == 1
	replace asispre_ci = 0 if asispre_ci == .
	replace asispre_ci = . if inlist(ed08, 99, .)


********************************************************************************
***************  VARIABLES DE VIVIENDA  *****************************************
********************************************************************************

	********************
	*** luz_ch ***
	********************
	/* v10: 1=Sí,6=No */
	gen byte luz_ch = .
	replace luz_ch = 1 if v10 == 1
	replace luz_ch = 0 if v10 == 6

	********************
	*** luzmide_ch ***
	********************
	gen byte luzmide_ch = . /* no existe pregunta */

	********************
	*** combust_ch ***
	********************
	/* v14b: 1=Leña,2=Gas,3=Carbón,4=Electricidad,5=Kerosene/alcohol,6=Otro,7=No cocina,9=NR */
	gen byte combust_ch = .
	replace combust_ch = 1 if inlist(v14b, 2, 4) /* gas o electricidad */
	replace combust_ch = 0 if inlist(v14b, 1, 3, 5, 6) /* otro combustible */
	replace combust_ch = . if inlist(v14b, 7, 9, .)

	********************
	*** piso_ch ***
	********************
	gen piso_ch = .   /* CREAR VACÍO metodología en revisión (manual oct 2025) */

	********************
	*** pared_ch ***
	********************
	gen pared_ch = .   /* CREAR VACÍO metodología en revisión (manual oct 2025) */

	********************
	*** techo_ch ***
	********************
	gen techo_ch = .   /* CREAR VACÍO metodología en revisión (manual oct 2025) */

	********************
	*** resid_ch ***
	********************
	/* v15: 1=Quema,2=Recolección pública,3=Recolección privada,4=Hoyo,5=Patio/calle,
	        6=Vertedero municipal,7=Chacra,8=Arroyo/río/laguna,9=Otro,99=NR */
	gen byte resid_ch = .
	replace resid_ch = 0 if inlist(v15, 2, 3)          /* recolección pública o privada */
	replace resid_ch = 1 if v15 == 1                   /* quema */
	replace resid_ch = 2 if inrange(v15, 4, 8)         /* tirados en espacio abierto */
	replace resid_ch = 3 if v15 == 9                   /* otro método */
	replace resid_ch = . if inlist(v15, 99, .)

	********************
	*** dorm_ch ***
	********************
	gen byte dorm_ch = v02b

	********************
	*** cuartos_ch ***
	********************
	gen byte cuartos_ch = v02a

	********************
	*** cocina_ch ***
	********************
	gen byte cocina_ch = .
	replace cocina_ch = 1 if v14a == 1
	replace cocina_ch = 0 if v14a == 6

	********************
	*** telef_ch ***
	********************
	gen byte telef_ch = .
	replace telef_ch = 1 if v11a == 1
	replace telef_ch = 0 if v11a == 6

	********************
	*** refrig_ch ***
	********************
	/* v2403: 1=Sí,6=No,9=NR */
	gen byte refrig_ch = .
	replace refrig_ch = 1 if v2403 == 1
	replace refrig_ch = 0 if v2403 == 6
	replace refrig_ch = . if inlist(v2403, 9, .)

	********************
	*** freez_ch ***
	********************
	gen byte freez_ch = .   /* no existe pregunta */

	********************
	*** auto_ch ***
	********************
	/* v2413: 1=Sí,6=No,9=NR */
	gen byte auto_ch = .
	replace auto_ch = 1 if v2413 == 1
	replace auto_ch = 0 if v2413 == 6
	replace auto_ch = . if inlist(v2413, 9, .)

	********************
	*** compu_ch ***
	********************
	gen byte compu_ch = .
	replace compu_ch = 1 if v23a1 == 1
	replace compu_ch = 0 if v23a1 == 6
	replace compu_ch = . if inlist(v23a1, 9, .)

	********************
	*** internet_ch ***
	********************
	/* v23b: 1=Sí,6=No,9=NR */
	gen byte internet_ch = .
	replace internet_ch = 1 if v23b == 1
	replace internet_ch = 0 if v23b == 6
	replace internet_ch = . if inlist(v23b, 9, .)

	********************
	*** cel_ch ***
	********************
	gen byte cel_ch = .
	replace cel_ch = 1 if v11b == 1
	replace cel_ch = 0 if v11b == 6

	********************
	*** vivi1_ch ***
	********************
	/* v01: 1=Casa/rancho,2=Departamento,3=Pieza inquilinato,4=Improvisada,5=Otro,9=NR */
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if v01 == 1
	replace vivi1_ch = 2 if v01 == 2
	replace vivi1_ch = 3 if inrange(v01, 3, 5)
	replace vivi1_ch = . if inlist(v01, 9, .)

	********************
	*** vivi2_ch ***
	********************
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if inlist(vivi1_ch, 1, 2)
	replace vivi2_ch = 0 if vivi1_ch == 3

	********************
	*** viviprop_ch ***
	********************
	/* v16: 1=Propia,2=Pagando cuotas,3=Condominio,4=Alquilada,5=Ocupada de hecho,6=Cedida,7=Otra,9=NR */
	gen byte viviprop_ch = .
	replace viviprop_ch = 0 if v16 == 4 /* alquilada */
	replace viviprop_ch = 1 if inlist(v16, 1, 3) /* propia */
	replace viviprop_ch = 2 if v16 == 2 /* pagando cuotas */
	replace viviprop_ch = 3 if inlist(v16, 5, 6, 7) /* ocupada/cedida/otra */
	replace viviprop_ch = . if inlist(v16, 9, .)

	********************
	*** vivitit_ch ***
	********************
	gen byte vivitit_ch = .   /* no existe pregunta */

	********************
	*** vivialq_ch ***
	********************
	gen double vivialq_ch = v18
	replace vivialq_ch = . if v18 == 99999999999

	********************
	*** vivialqimp_ch ***
	********************
	gen double vivialqimp_ch = v19
	replace vivialqimp_ch = . if v19 == 99999999999


********************************************************************************
***************  VARIABLES DE WASH  ********************************************
********************************************************************************

	********************
	*** aguared_ch ***
	********************
	gen byte aguared_ch = .
	replace aguared_ch = 1 if inlist(v06, 1, 2, 3, 4)
	replace aguared_ch = 0 if v06 > 4 & v06 <= 12 & v06 != .
	replace aguared_ch = . if inlist(v06, 99, .)

	********************
	*** aguafconsumo_ch ***
	********************
	gen byte aguafconsumo_ch = .
	replace aguafconsumo_ch = 1  if inlist(v08, 1, 2, 3, 4) & inlist(v09, 1, 2)  // red, cañería privada/terreno
	replace aguafconsumo_ch = 2  if inlist(v08, 1, 2, 3, 4) & v09 == 3 		// llave pública
	replace aguafconsumo_ch = 3  if v08 == 11 | v09 == 7 					//agua embotellada
	replace aguafconsumo_ch = 4  if inlist(v08, 5, 6) 						// pozo protegido (dentro del terreno)
	replace aguafconsumo_ch = 5  if v08 == 10  								// lluvia
	replace aguafconsumo_ch = 6  if v08 == 12 | v09 == 6 					// camión cisterna (aguatero)
	replace aguafconsumo_ch = 7  if (v08 == 8 | ((inlist(v08, 1, 2, 3, 4) & (inlist(v09, 5, 8)))))  // otra mejorada
	replace aguafconsumo_ch = 8  if v08 == 13 								// agua superficial
	replace aguafconsumo_ch = 9  if inlist(v08, 7, 9) 						// pozo/manantial sin protección
	replace aguafconsumo_ch = 10 if (inlist(v08, 14, 99) | v09 == 99) 		// otros, no clasificable, NR

	********************
	*** aguafuente_ch ***
	********************
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1  if inlist(v06, 1, 2, 3, 4)  & inlist(v07a, 1, 2) 	//red (ESSAP/SENASA/comunitaria/privada)
	replace aguafuente_ch = 2  if inlist(v06, 1, 2, 3, 4) & v07a == 3  		// llave pública
	replace aguafuente_ch = 4  if inlist(v06, 5, 6) 						// pozo protegido (artesiano/con bomba)
	replace aguafuente_ch = 5  if v06 == 10 								// agua lluvia
	replace aguafuente_ch = 6  if v06 == 11 | v07a == 6  					// camión cisterna (aguatero)
	replace aguafuente_ch = 7  if (inlist(v06, 1, 2, 3, 4) & inlist(v07a, 4, 5, 7))  // otra mejorada
	replace aguafuente_ch = 8  if v06 == 9 									 // agua superficial (tajamar/río)
	replace aguafuente_ch = 10 if (inlist(v06, 7, 8, 12, 99) | v07a == 9)  // pozo, manantial, otra, NR

	********************
	*** aguadist_ch ***
	********************
	/* v07a: 1=Cañería terreno fuera vivienda,2=Cañería dentro vivienda,3=Canilla pública,
	         4=Pozo terreno,5=Vecino,6=Aguatero,7=Otros */
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if v07a == 2 /* dentro de la vivienda */
	replace aguadist_ch = 2 if inlist(v07a, 1, 4) /* fuera vivienda, dentro propiedad */
	replace aguadist_ch = 3 if inlist(v07a, 3, 5, 6, 7) /* fuera de la propiedad */
	replace aguadist_ch = . if inlist(v07a, 9, .)

	********************
	*** aguadisp1_ch ***
	********************
	gen byte aguadisp1_ch = .
	replace aguadisp1_ch = 1 if v07 == 1
	replace aguadisp1_ch = 2 if v07 == 6
	replace aguadisp1_ch = . if inlist(v07, 9, .)

	********************
	*** aguadisp2_ch ***
	********************
	gen byte aguadisp2_ch = 9

	********************
	*** aguatrat_ch ***
	********************
	gen byte aguatrat_ch = .   /* EPHC no hace esta pregunta */

	********************
	*** aguamala_ch ***
	********************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	********************
	*** aguamejorada_ch ***
	********************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	********************
	*** aguamide_ch ***
	********************
	gen byte aguamide_ch = .   /* EPHC no hace esta pregunta */

	********************
	*** bano_ch ***
	********************
	/* v12: 1=Tiene baño,6=No; v13: tipo desagüe (1-8,9=NR) */
	gen byte bano_ch = .
	replace bano_ch = 0 if v12 == 6 /* sin baño */
	replace bano_ch = 1 if v13 == 1 /* inodoro a red alcantarillado */
	replace bano_ch = 2 if v13 == 2 /* inodoro a cámara séptica+pozo ciego */
	replace bano_ch = 3 if inlist(v13, 5, 6) /* letrina mejorada */
	replace bano_ch = 4 if v13 == 4 /* inodoro/letrina a superficie */
	replace bano_ch = 5 if v13 == 7 /* letrina sin techo/puerta */
	replace bano_ch = 6 if inlist(v13, 3, 8, 9) | (v12 == . & jefe_ci != .) /* no clasificable */

	********************
	*** banoex_ch ***
	********************
	gen byte banoex_ch = . /* no existe pregunta */

	********************
	*** banomejorado_ch ***
	********************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6

	********************
	*** sinbano_ch ***
	********************
	gen byte sinbano_ch = .
	replace sinbano_ch = 0 if v12 == 1 /* hogar tiene baño */
	replace sinbano_ch = 3 if v12 == 6 /* hogar sin baño, alternativa no especificada */


********************************************************************************
***************  VARIABLES DE MIGRACIÓN  ***************************************
********************************************************************************
/* EPHC no incluye módulo de migración — todas en missing */

	********************
	*** migrante_ci ***
	********************
	gen byte migrante_ci = .

	********************
	*** migrantiguo5_ci ***
	********************
	gen byte migrantiguo5_ci = .

	********************
	*** miglac_ci ***
	********************
	gen byte miglac_ci = .


********************************************************************************
***************  VARIABLES EXTERNAS / POBREZA  **********************************
********************************************************************************

	********************
	*** tipo_bienestar ***
	********************
	gen byte tipo_bienestar = 1

	********************
	*** pobre_ine_ci ***
	********************
	/* pobnopoi: 0=No pobre, 1=Pobre */
	gen byte pobre_ine_ci = pobnopoi

	********************
	*** bienestar_agregado ***
	********************
	gen double bienestar_agregado = ipcm

	********************
	*** lpe_ci ***
	********************
	sum linpobex
	gen double lpe_ci = `r(min)' if zona_c == 0 /* rural */
	replace    lpe_ci = `r(max)' if zona_c == 1 /* urbana */

	********************
	*** ln_ci ***
	********************
	sum linpobto
	gen double ln_ci = `r(min)' if zona_c == 0 /* rural */
	replace    ln_ci = `r(max)' if zona_c == 1 /* urbana */

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
