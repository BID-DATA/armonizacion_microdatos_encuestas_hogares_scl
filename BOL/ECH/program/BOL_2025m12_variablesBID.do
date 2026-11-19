* (Versión Stata 19)
clear all
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: \\Sdssrv03\surveys
 * Se tiene acceso al servidor técnicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 
local PAIS BOL
local ENCUESTA ECH
local ANO "2025"
local RONDA m12

global tag = "`PAIS'_`ANO'_`ENCUESTA'-`RONDA'"
global ruta = "$datalibweb_IDB\\`PAIS'\\$tag"
global harmonized = "$ruta\\${tag}_V01_M_V01_A_IADB\Data\Harmonized"

local base_in  = "$ruta\\${tag}_V01_M\Data\Stata\\`PAIS'_`ANO'`RONDA'.dta"
local merge_out = "$harmonized\\${tag}_V01_M_V01_A_merge_IADB_SCLData.dta"
local harmonized_out = "$harmonized\\${tag}_V01_M_V01_A_IADB_SCLData.dta"

local log_file = "$harmonized\log\\${tag}.log"
capture log close
cap log using "`log_file'", replace 
cap log off 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO
Pais: Bolivia
Encuesta: ECH (Encuesta de Hogares)
Round: m12 (2025)
Autores: Matias Rodriguez - SCL/SCL 
Version: 09/11/2026
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones respecto a 2024:
- Equipamiento del hogar: la numeracion de posee_* cambio en 2025
  (posee_5=refrigerador/freezer, 7=computadora, 9=celular, 18=automovil).
- edupub_ci: usa s03a_09 (tipo de establecimiento). s03a_07a ahora es desayuno escolar.
- Agua: s06a_07 tiene 10 categorias en 2025 (11 en 2024).
- Migracion: la encuesta 2025 incluye lugar de nacimiento (s01b_10a) y de residencia hace 5 anios (s01b_11a).
- vivialq_ch / vivialqimp_ch: s06a_02b / s06a_02a.
- Tipos de cambio de remesas (locals tc_*): PENDIENTE actualizar (valores 2024).
- QUIEBRES DE SERIE 2024 -> 2025 :
  * eduui_ci/eduuc_ci: la conclusion del nivel superior se toma del curso 8 (s03a_02c), no de s03a_05 (eduuc +10.6 pp
    frente al criterio de 2024). aedu_ci: tecnico con curso 5 se topa en el nivel completo (14 / 15 anios).
  * formal_ci = afiliado_ci (afiliacion a la Gestora), no cotizacion (+3.8 pp frente a la cotizacion); desviacion del canon §B.
  * asiste_ci: matricula (s03a_04) menos los matriculados con s03b_10 == 4 y s03b_11 en 3-5; "culmino" y "vacacion" asisten.
  * cuartos_ch = . (s06a_16 excluye bano y cocina); viviprop_ch sin codigo 4 (mixto -> 0); aguadisp2_ch = 9 si no se pregunta.
  * spublico_ci usa s04b_13 (21.7% de asalariados; el canon por rama_ci==10 daba 6.3%).
****************************************************************************/

use `base_in', clear 

* Programa auxiliar: convierte un monto reportado con frecuencia (codigos ECH 1-8) a mensual.
*  diario = dias/semana x 4.33, semanal x 4.33,
* quincenal x 2.165 (= 4.33/2), bimestral /2, trimestral /3, semestral /6, anual /12.
capture program drop _mens
program define _mens
	args new amt frq dias
	gen double `new' = .
	replace `new' = `amt' * `dias' * 4.33 if `frq' == 1
	replace `new' = `amt' * 4.33          if `frq' == 2
	replace `new' = `amt' * 2.165         if `frq' == 3
	replace `new' = `amt'                 if `frq' == 4
	replace `new' = `amt' / 2             if `frq' == 5
	replace `new' = `amt' / 3             if `frq' == 6
	replace `new' = `amt' / 6             if `frq' == 7
	replace `new' = `amt' / 12            if `frq' == 8
end

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c = 3


	********************
	*** region_c ****
	********************
	gen byte region_c = depto /* 1 Chuquisaca ... 9 Pando */

	*************
	* pais_c    *
	*************
	gen str3 pais_c = "BOL"

	******
	*anio*
	******
	gen int anio_c = 2025

	******
	*mes_c*
	******
	gen int mes_c = 12	/* ronda m12 */

	******
	*zona*
	******
	gen byte zona_c = (area == 1) /* area: 1 urbano, 2 rural */

	*********
	*estrato*
	*********
	gen estrato_ci = real(estrato) /* estrato es string en 2025 */

	*****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci = upm

	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch = group(folio)
	tostring idh_ch, replace
	replace idh_ch = substr("00000" + idh_ch, -5, 5)

	***************
	****idp_ci*****
	***************
	gen idp_ci = idh_ch + string(nro, "%02.0f") 
	duplicates report idh_ch idp_ci

	***********
	*factor_ci*
	***********
	gen factor_ci = factor 

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch = factor_ci


****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci = s01a_02 /* 1 hombre, 2 mujer */

	*********
	*edad_ci*
	*********
	gen int edad_ci = s01a_03

	**************
	**relacion_ci**
	**************
	gen byte relacion_ci = .
	replace relacion_ci = 1 if s01a_05 == 1
	replace relacion_ci = 2 if s01a_05 == 2
	replace relacion_ci = 3 if inlist(s01a_05, 3, 4)
	replace relacion_ci = 4 if inrange(s01a_05, 5, 12)
	replace relacion_ci = 5 if s01a_05 == 13
	replace relacion_ci = 6 if s01a_05 == 14

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = (relacion_ci >= 1 & relacion_ci <= 5)
	replace miembros_ci = . if relacion_ci == .

	***************
	*miembros_one_ci*
	***************
	gen byte miembros_one_ci = miembros_ci 

	**************
	*Estado Civil*
	**************
	gen byte civil_ci = .
	replace civil_ci = 1 if s01a_10 == 6              /* soltero */
	replace civil_ci = 2 if inlist(s01a_10, 1, 2)     /* casado o conviviente */
	replace civil_ci = 3 if inlist(s01a_10, 3, 4)     /* separado o divorciado */
	replace civil_ci = 4 if s01a_10 == 5              /* viudo */

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci = (relacion_ci == 1)
	replace jefe_ci = . if relacion_ci == .

	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen byte nconyuges_ch = sum(relacion_ci == 2)

	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch = sum(relacion_ci == 3)

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch = sum(relacion_ci == 4)

	****************
	*notronopari_ch*
	****************
	by idh_ch, sort: egen byte notronopari_ch = sum(relacion_ci == 5)

	************
	*nempdom_ch*
	************
	by idh_ch, sort: egen byte nempdom_ch = sum(relacion_ci == 6)

	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	**** unipersonal
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	**** nuclear
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	**** ampliado
	replace clasehog_ch = 3 if notropari_ch > 0 & notronopari_ch == 0
	**** compuesto
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	**** corresidente
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

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 6))

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch = sum((relacion_ci > 0 & relacion_ci <= 5) & (edad_ci < 1))


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************
	*********
	*afro_ci*
	*********
	/* s01a_09: 1 si / 2 no se autoidentifica con pueblo indigena originario campesino o afroboliviano
	   s01a_09npioc: pueblo (1 = Afroboliviano, 2-500 = pueblos indigenas) */
	gen byte afro_ci = .
	replace afro_ci = 1 if s01a_09npioc == 1
	replace afro_ci = 0 if inrange(s01a_09npioc, 2, 993) | s01a_09 == 2

	*********
	*indi_ci*
	*********
	gen byte ind_ci = .
	replace ind_ci = 1 if inrange(s01a_09npioc, 2, 993)
	replace ind_ci = 0 if s01a_09npioc == 1 | s01a_09 == 2

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci == 0 & ind_ci == 0
	replace noafroind_ci = 0 if afro_ci == 1 | ind_ci == 1

	**************
	*afroind_ano_c*
	**************
	gen int afroind_ano_c = 2012   /* manual oct 2025, Tabla 2: BOL EH = 2012 */

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
	gen afro_jefe = afro_ci if relacion_ci == 1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	********
	*ind_ch*
	********
	gen ind_jefe = ind_ci if relacion_ci == 1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	**************
	*noafroind_ch*
	**************
	gen noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	************
	*afroind_ch*
	************
 	gen afroind_jefe = afroind_ci if relacion_ci == 1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

	********
	*dis_ci*
	********
	/* s02a_04a-d: dificultad para ver, oir, caminar, comunicarse (1 ninguna, 2 algo, 3 mucha, 4 no puede).*/
	gen byte dis_ci = .
	replace dis_ci = 1 if inrange(s02a_04a, 2, 4) | inrange(s02a_04b, 2, 4) | inrange(s02a_04c, 2, 4) | inrange(s02a_04d, 2, 4)
	replace dis_ci = 0 if s02a_04a == 1 & s02a_04b == 1 & s02a_04c == 1 & s02a_04d == 1

	**********
	*disWG_ci*
	**********
	gen byte disWG_ci = .
	replace disWG_ci = 1 if inrange(s02a_04a, 3, 4) | inrange(s02a_04b, 3, 4) | inrange(s02a_04c, 3, 4) | inrange(s02a_04d, 3, 4)
	replace disWG_ci = 0 if inrange(s02a_04a, 1, 2) & inrange(s02a_04b, 1, 2) & inrange(s02a_04c, 1, 2) & inrange(s02a_04d, 1, 2)

	********
	*dis_ch*
	********
	egen dis_ch = max(dis_ci), by(idh_ch)

	******************
	*ISO3pais_dis_ci*
	******************
	gen byte BOL_dis_ci = .

****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	/* La seccion laboral aplica desde los 7 anios (menores de 7 = missing en s04a_01) */
	*los productores para autoconsumo (s04a_02 in 1,2; 343 casos, 2.4% de los ocupados)
	* y "temporada baja" (s04a_03==5) cuentan como ocupados, igual que el INE (condact), no segun la 19.a CIET.
	* Se documenta; no se cambia sin directiva de SCL.
	gen byte condocup_ci = .
	replace condocup_ci = 1 if s04a_01 == 1 | inrange(s04a_02, 1, 8) | inrange(s04a_03, 1, 9)
	replace condocup_ci = 2 if condocup_ci == . & s04a_04 == 1 & (s04a_05 == 1 | (s04a_05 == 2 & s04a_07 == 1)) /* busca, o tiene trabajo asegurado a comenzar en <4 semanas */
	replace condocup_ci = 3 if condocup_ci == . & (s04a_04 == 2 | (s04a_04 == 1 & s04a_05 == 2))
	replace condocup_ci = 4 if edad_ci < 7

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (s04a_06 == 2 & condocup_ci == 3)           /* jubilado, pensionista o rentista */
	replace categoinac_ci = 2 if (s04a_06 == 1 & condocup_ci == 3)           /* estudiante */
	replace categoinac_ci = 3 if (s04a_06 == 4 & condocup_ci == 3)           /* quehaceres domesticos */
	replace categoinac_ci = 4 if (categoinac_ci == . & condocup_ci == 3)     /* otros */

	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci***
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if s04a_08 == 1 & condocup_ci == 2   /* ha trabajado antes */
	replace cesante_ci = 0 if s04a_08 == 2 & condocup_ci == 2

	***************
	***desemp_ci***
	***************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci != .

	***************
	***subemp_ci***
	***************
	* La encuesta no pregunta si desea trabajar mas horas
	gen byte subemp_ci = .

	****************
	***durades_ci***
	****************
	* La encuesta no pregunta duracion de la busqueda
	gen byte durades_ci = .

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
	replace nempleos_ci = 1 if emp_ci == 1
	replace nempleos_ci = 2 if emp_ci == 1 & s04e_25 == 1  /* realizo otro trabajo */

	******************
	***antiguedad_ci***
	******************
	*Años en la ocupacion actual (s04b_11ba/bb: tiempo que desempena esta ocupacion; 2 sem, 4 mes, 8 anio)
	gen antiguedad_ci = .
	replace antiguedad_ci = s04b_11ba / 52.14 if s04b_11bb == 2 & emp_ci == 1
	replace antiguedad_ci = s04b_11ba / 12    if s04b_11bb == 4 & emp_ci == 1
	replace antiguedad_ci = s04b_11ba         if s04b_11bb == 8 & emp_ci == 1
	replace antiguedad_ci = floor(antiguedad_ci) if emp_ci == 1

	***************
	***desalent_ci***
	***************
	* no se exige disponibilidad (s04a_04==1) para el desalentado; afecta ~36 casos.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (s04a_05 == 2 & s04a_07 == 3 & condocup_ci == 3) /* no busco: cree que no encontrara trabajo */
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)

	***************
	***horaspri_ci***
	***************
	*  phrs/tothrs vienen precalculadas por el INE y llegan hasta 173.25 h/semana
	gen double horaspri_ci = phrs if emp_ci == 1  /* horas semanales ocupacion principal */

	***************
	***horastot_ci ***
	***************
	gen double horastot_ci = tothrs if emp_ci == 1  /* horas semanales totales */

	***************
	***tiempoparc_ci ***
	***************
	* La encuesta no pregunta si desea trabajar mas horas (voluntariedad)
	gen byte tiempoparc_ci = .

	***************
	***categopri_ci ***
	***************
	/* s04b_12: 1 obrero/empleado, 2 empleador-socio que recibe salario, 3 cuenta propia,
	   4 empleador-socio que no recibe salario, 5 cooperativista, 6 familiar sin remuneracion,
	   7 aprendiz sin remuneracion, 8 empleado del hogar */
	* "2. Empleador/socio que SI recibe salario" (33 obs) se clasifica como asalariado
	* (CISE-93: gerente-propietario de sociedad), consistente con 2024.
	gen byte categopri_ci = .
	replace categopri_ci = 1 if s04b_12 == 4 & emp_ci == 1
	replace categopri_ci = 2 if inlist(s04b_12, 3, 5) & emp_ci == 1       /* cooperativistas -> cuenta propia (manual) */
	replace categopri_ci = 3 if inlist(s04b_12, 1, 2, 8) & emp_ci == 1    /* empleados domesticos -> 3 (manual) */
	replace categopri_ci = 4 if inlist(s04b_12, 6, 7) & emp_ci == 1
	replace categopri_ci = 0 if categopri_ci == . & emp_ci == 1

	***************
	***categosec_ci ***
	***************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if s04e_27 == 4 & emp_ci == 1 & s04e_25 == 1
	replace categosec_ci = 2 if inlist(s04e_27, 3, 5) & emp_ci == 1 & s04e_25 == 1
	replace categosec_ci = 3 if inlist(s04e_27, 1, 2, 8) & emp_ci == 1 & s04e_25 == 1
	replace categosec_ci = 4 if inlist(s04e_27, 6, 7) & emp_ci == 1 & s04e_25 == 1

	***************
	***rama_ci ***
	***************
	/* caeb_op (precalculada): 0 agric, 1 minas, 2 manuf, 3-4 elec/agua, 5 construccion, 6 comercio,
	   7 transporte, 8 alojamiento/comidas, 9 informacion y comunicaciones, 10-11 financieras/inmobiliarias,
	   12-13 serv. profesionales y administrativos, 14 Adm. Publica, 15-20 otros servicios */
	gen byte rama_ci = .
	replace rama_ci = 1  if caeb_op == 0 & emp_ci == 1
	replace rama_ci = 2  if caeb_op == 1 & emp_ci == 1
	replace rama_ci = 3  if caeb_op == 2 & emp_ci == 1
	replace rama_ci = 4  if inlist(caeb_op, 3, 4) & emp_ci == 1
	replace rama_ci = 5  if caeb_op == 5 & emp_ci == 1
	replace rama_ci = 6  if inlist(caeb_op, 6, 8) & emp_ci == 1
	replace rama_ci = 7  if caeb_op == 7 & emp_ci == 1
	replace rama_ci = 8  if inrange(caeb_op, 10, 11) & emp_ci == 1
	replace rama_ci = 9  if (caeb_op == 9 | inrange(caeb_op, 12, 13) | inrange(caeb_op, 15, 20)) & emp_ci == 1
	replace rama_ci = 10 if caeb_op == 14 & emp_ci == 1   /* Gobierno: Adm. Publica, Defensa y Seguridad Social */

	***************
	***tamemp_ci ***
	***************
	*  s04b_14 == 9999 (idp_ci 0488901 y 0489001) probablemente es "no sabe"
	* y queda clasificado como empresa grande; 10000 y 20000 se consideran plausibles. Se mantiene igual que 2024.
	gen byte tamemp_ci = .
	replace tamemp_ci = 1 if inrange(s04b_14, 1, 5) & emp_ci == 1
	replace tamemp_ci = 2 if inrange(s04b_14, 6, 49) & emp_ci == 1
	replace tamemp_ci = 3 if s04b_14 > 49 & s04b_14 != . & emp_ci == 1

	***************
	***spublico_ci ***
	***************
	/* Cambios
	     (A) ´pasado  rama_ci==10 (caeb_op 14, Adm. Publica)  -> 531 publicos (6.3% de los asalariados).
	         Solo capta la rama "Adm. Publica": el 49.8% de los que declaran trabajar en la
	         Administracion Publica (s04b_13==1) quedan en la rama 9 (educacion, salud) y se clasificarian como privados.
	     (B) s04b_13 in (1,2) "Administracion Publica" o "Empresa Publica" -> 1,871 publicos (22.8% de los asalariados).
	         Consistente con tamanio de empresa (50.5% de los asalariados de empresas >49 personas y 5.4% de las <=5).
	   Se usa (B): es la pregunta directa de la encuesta y la usada en BOL 2024. s04b_13 solo se pregunta
	   a dependientes; patrones y cuenta propia se clasifican como 0 (no publico). */
	gen byte spublico_ci = .
	replace spublico_ci = 1 if inlist(s04b_13, 1, 2) & emp_ci == 1
	replace spublico_ci = 0 if emp_ci == 1 & spublico_ci != 1

	***************
	***cotizando_ci***
	***************
	/* s04f_35: afiliado a la Gestora (AFP); s04f_36: actualmente aporta (solo afiliados) */
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if s04f_36 == 1 & emp_ci == 1
	replace cotizando_ci = 0 if (s04f_36 == 2 | s04f_35 == 2) & emp_ci == 1

	***************
	***afiliado_ci***
	***************
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if s04f_35 == 1 & emp_ci == 1
	replace afiliado_ci = 0 if afiliado_ci != 1 & inlist(condocup_ci, 1, 2)

	***************
	***instcot_ci***
	***************
	gen str10 instcot_ci = "Gestora" if cotizando_ci == 1

	**************
	***formal_ci***
	**************
	gen byte formal_ci = .
	replace formal_ci = 1 if afiliado_ci == 1 & condocup_ci == 1
	replace formal_ci = 0 if afiliado_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	*******************
	***tipocontrato_ci***
	*******************
	* La encuesta no pregunta el tipo de contrato
	gen byte tipocontrato_ci = .

	**************
	***ocupa_ci***
	**************
	/* s04b_09a_cod: codigo COB 2023 (string, longitud variable); se usan los 2 primeros digitos.
	   Fuerzas Armadas = grupo 0 (cob_op==0; codigos 01xxx-03xxx) */
	gen cod2 = real(substr(s04b_09a_cod, 1, 2))   /* numerico; 01-03 = FFAA no colisionan con los otros grupos */
	* los tecnicos de nivel medio (COB grupo 3, 1,085 ocupados) van a ocupa_ci=3
	* (administrativo y nivel intermedio), igual que en 2024; verificar convencion de SCL (categoria 1 = profesionales y tecnicos).
	gen byte ocupa_ci = .
	* 1. Profesionales y tecnicos
	replace ocupa_ci = 1 if inlist(cod2, 21, 22, 23, 24, 25, 26, 27) & emp_ci == 1
	* 2. Directores y funcionarios superiores
	replace ocupa_ci = 2 if inlist(cod2, 11, 12, 13, 14) & emp_ci == 1
	* 3. Personal administrativo y nivel intermedio
	replace ocupa_ci = 3 if inlist(cod2, 31, 32, 33, 34, 35, 41, 42, 43, 44) & emp_ci == 1
	* 4. Comerciantes y vendedores
	replace ocupa_ci = 4 if inlist(cod2, 52, 95) & emp_ci == 1
	* 5. Trabajadores en servicios
	replace ocupa_ci = 5 if inlist(cod2, 51, 53, 54, 91, 94) & emp_ci == 1
	* 6. Trabajadores agricolas
	replace ocupa_ci = 6 if inlist(cod2, 61, 62, 63, 92) & emp_ci == 1
	* 7. Obreros no agricolas, conductores y operadores
	replace ocupa_ci = 7 if inlist(cod2, 71, 72, 73, 74, 75, 81, 82, 83, 93, 96) & emp_ci == 1
	* 8. Fuerzas armadas
	replace ocupa_ci = 8 if cob_op == 0 & emp_ci == 1
	* 9. Otros / no clasificables
	replace ocupa_ci = 9 if ocupa_ci == . & emp_ci == 1 & s04b_09a_cod != ""
	drop cod2

	**************
	**pension_ci***
	**************
	/* s05a_01a jubilacion, b benemerito, c invalidez, d viudez/orfandad (todos mensuales) */
	egen aux_pc = rowtotal(s05a_01a s05a_01b s05a_01c s05a_01d), missing
	gen byte pension_ci = (aux_pc > 0) if !missing(aux_pc)

	***************
	**pensionsub_ci**
	***************
	/* s05a_01e: Renta Dignidad */
	/* s05a_01e (Renta Dignidad) solo se pregunta a personas de 60+ anios,
	   por lo que pensionsub_ci queda en missing para los 34,034 menores de 60. Decision del armonizador: se
	   deja asi (el manual pide 0 al resto; ver reporte adversarial 1). */
	gen byte pensionsub_ci = (s05a_01e == 1) if !missing(s05a_01e)

	***************
	**tipopen_ci**
	***************
	/* Variable original: letras de los items s05a_01 recibidos (a jubilacion, b benemerito, c invalidez, d viudez) */
	gen str10 tipopen_ci = ""
	replace tipopen_ci = tipopen_ci + "a" if s05a_01a > 0 & s05a_01a != .
	replace tipopen_ci = tipopen_ci + "b" if s05a_01b > 0 & s05a_01b != .
	replace tipopen_ci = tipopen_ci + "c" if s05a_01c > 0 & s05a_01c != .
	replace tipopen_ci = tipopen_ci + "d" if s05a_01d > 0 & s05a_01d != .
	replace tipopen_ci = "" if pension_ci != 1

	***************
	**instpen_ci **
	***************
	gen str10 instpen_ci = ""

****************************
***VARIABLES DE INGRESO***
****************************

	* Valores especiales (999999 = no responde) en montos de la seccion laboral
	foreach v in s04c_17a s04c_18a s04c_18b s04c_19aa s04c_19ba s04c_21a2 s04c_21b2 s04c_21c2 s04c_21d2 s04c_21e2 ///
		s04d_24a s04d_24bc s04f_31a s04f_32a1 s04f_32b1 s04f_32c1 s04f_34a s04f_34bc {
		qui count if `v' == 999999
		if r(N) > 0 di as txt "AVISO: `v' tiene " r(N) " valores 999999 -> missing"
		replace `v' = . if `v' == 999999
	}

	* Dias a la semana trabajados (para convertir pagos diarios a mensual)
	gen double d_dias_pri = s04b_15
	gen double d_dias_sec = s04e_29
	qui count if s04c_17b == 1 & missing(d_dias_pri)
	di as txt "AVISO: `r(N)' con pago diario en la ocupacion principal sin dias declarados; se asume 6."
	replace d_dias_pri = 6 if missing(d_dias_pri)
	replace d_dias_sec = 6 if missing(d_dias_sec)

	*************
	* ylmpri_ci *
	*************
	_mens d_yliquido  s04c_17a  s04c_17b  d_dias_pri
	_mens d_ycomisio  s04c_19aa s04c_19ab d_dias_pri
	_mens d_yhrsextr  s04c_19ba s04c_19bb d_dias_pri
	gen double d_yprima  = s04c_18a / 12   /* bonos laborales (anual) */
	gen double d_yaguina = s04c_18b / 12   /* aguinaldo (anual) */
	_mens d_yactpri   s04d_24a  s04d_24b  d_dias_pri  /* ingreso neto independientes */

	/* INGRESO ATIPICO: el idp_ci 1071401 (empleador, categopri_ci==1) declara s04d_24a = 369,897 Bs
	   mensuales (s04d_24b==4), ~135 veces el salario minimo y 4.7 veces el segundo valor mas alto
	   de ylmpri_ci (77,940 Bs; el tercero es 60,000). El valor coincide con el ingreso laboral oficial del
	   INE (yprilab = 369,897), por lo que NO es un error de la armonizacion y se conserva sin modificar.
	   Revisar en analisis de desigualdad / medias: afecta ylm_ci, ytot_ci y los agregados de su hogar
	   (ylm_ch, ytot_ch). */
	egen double ylmpri_ci = rowtotal(d_yliquido d_ycomisio d_yhrsextr d_yprima d_yaguina d_yactpri), missing
	replace ylmpri_ci = . if emp_ci != 1
	replace ylmpri_ci = . if ylmpri_ci < 0
	replace ylmpri_ci = 0 if categopri_ci == 4  /* trabajador no remunerado */

	**************
	* ylnmpri_ci *
	**************
	* Pagos en especie de dependientes (21a alimentos, 21b transporte, 21c vestimenta, 21d vivienda, 21e otros)
	foreach x in a b c d e {
		gen double _am_`x' = s04c_21`x'2 if s04c_21`x' == 1
		_mens d_yesp_`x' _am_`x' s04c_21`x'1 d_dias_pri
		drop _am_`x'
	}
	* Autoconsumo de independientes
	gen double _am_i = s04d_24bc if s04d_24ba == 1
	_mens d_yespind _am_i s04d_24bb d_dias_pri
	drop _am_i

	egen double ylnmpri_ci = rowtotal(d_yesp_a d_yesp_b d_yesp_c d_yesp_d d_yesp_e d_yespind), missing
	replace ylnmpri_ci = . if emp_ci != 1
	replace ylnmpri_ci = . if ylnmpri_ci < 0
	replace ylnmpri_ci = 0 if categopri_ci == 4

	************
	* ylmsec_ci *
	************
	_mens d_yliquido2 s04f_31a s04f_31b d_dias_sec
	gen double d_yhrsextr2 = s04f_32a1 / 12 if s04f_32a == 1
	_mens d_yactsec   s04f_34a s04f_34b d_dias_sec

	egen double ylmsec_ci = rowtotal(d_yliquido2 d_yhrsextr2 d_yactsec), missing
	replace ylmsec_ci = . if emp_ci != 1
	replace ylmsec_ci = . if ylmsec_ci < 0
	replace ylmsec_ci = 0 if categosec_ci == 4

	**************
	* ylnmsec_ci *
	**************
	gen double d_yalimen2 = s04f_32b1 / 12 if s04f_32b == 1
	gen double d_yvivien2 = s04f_32c1 / 12 if s04f_32c == 1
	gen double _am_s = s04f_34bc if s04f_34ba == 1
	_mens d_yespsec _am_s s04f_34bb d_dias_sec
	drop _am_s

	egen double ylnmsec_ci = rowtotal(d_yalimen2 d_yvivien2 d_yespsec), missing
	replace ylnmsec_ci = . if emp_ci != 1
	replace ylnmsec_ci = . if ylnmsec_ci < 0
	replace ylnmsec_ci = 0 if categosec_ci == 4

	**************
	* ylmotros_ci *
	**************
	gen double ylmotros_ci = .

	****************
	* ylnmotros_ci *
	****************
	gen double ylnmotros_ci = .

	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi

	***************
	* nrylmpri_ci *
	***************
	gen byte nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)

	***************
	* nrylmpri_ch *
	***************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1

	***************
	* ypen_ci / ypensub_ci *
	***************
	generate double ypen_ci = aux_pc if pension_ci == 1                 /* pension contributiva mensual */
	generate double ypensub_ci = s05a_01e0 if pensionsub_ci == 1        /* Renta Dignidad mensual */

	*************
	* remesas_ci *
	*************
	* TIPOS DE CAMBIO (PENDIENTE actualizar a 2025): valores 2024 (BCB 31-dic-2024)
	local tc_eur 7.13372
	local tc_usd 6.86
	local tc_ars 0.00666
	local tc_brl 1.10975
	local tc_clp 0.00688
	gen double s6_112 = .
	replace s6_112 = s05c_09a            if s05c_09b == 1
	replace s6_112 = s05c_09a * `tc_eur' if s05c_09b == 2
	replace s6_112 = s05c_09a * `tc_usd' if s05c_09b == 3
	replace s6_112 = s05c_09a * `tc_ars' if s05c_09b == 4
	replace s6_112 = s05c_09a * `tc_brl' if s05c_09b == 5
	replace s6_112 = s05c_09a * `tc_clp' if s05c_09b == 6
	egen double rem = rowtotal(s05c_10 s6_112), missing   /* dinero + especie valorada en Bs */
	_mens remesas_ci rem s05c_08 d_dias_pri

	* Transferencias privadas y otros ingresos no laborales
	_mens d_yasistfam s05b_05aa s05b_05ab d_dias_pri
	_mens d_ydinero   s05b_05ba s05b_05bb d_dias_pri
	_mens d_yotro_bono s05b_06ba s05b_06bb d_dias_pri
	egen double d_ytransmon = rowtotal(d_ydinero d_yotro_bono), missing

	*********************************
	* Proteccion social (beneficiarios y montos) *
	*********************************
	* PNC: Renta Dignidad
	gen byte pnc_ci = (s05a_01e == 1) if !missing(s05a_01e)
	* PTMC: Juancito Pinto, Juana Azurduy, Subsidio Universal Prenatal
	gen byte juancito_ci = (s03a_08 == 1) if !missing(s03a_08)
	gen byte juana_ci = (s02b_12a1 == 1 | s02b_12b == 1 | s02d_17 == 1)
	replace juana_ci = . if s02b_12a1 == . & s02b_12b == . & s02d_17 == .
	gen byte subpre_ci = (s02b_14 == 1) if !missing(s02b_14)
	gen byte ptmc_ci = (juancito_ci == 1 | juana_ci == 1 | subpre_ci == 1)
	replace ptmc_ci = . if juancito_ci == . & juana_ci == . & subpre_ci == .
	* POTROT: Bono de indigencia/discapacidad (s05b_06aa) y Bono de natalidad (s04c_20b)
	gen byte discap_ci = (s05b_06aa > 0) if !missing(s05b_06aa)
	gen byte natal_ci = (s04c_20b == 1) if !missing(s04c_20b)
	gen byte potrot_ci = (discap_ci == 1 | natal_ci == 1)
	replace potrot_ci = . if discap_ci == . & natal_ci == .

	* Montos
	generate double ypnc_ci = s05a_01e0 if pnc_ci == 1
	generate double yptmc_ci = .   /* la encuesta no reporta montos de PTMC */
	gen double ydiscap_ci = s05b_06aa if s05b_06ab == 4
	replace ydiscap_ci = s05b_06aa / 12 if s05b_06ab == 8
	generate double yotrot_ci = ydiscap_ci
	egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi

	*********
	* ynlm_ci *
	*********
	* Pensiones (ypen_ci), transferencias (ytransf_ci) y remesas (remesas_ci) entran una sola vez
	gen double _yinteres = s05a_02a
	gen double _yalqui   = s05a_02b
	gen double _yotren   = s05a_02c
	gen double _yalqagri = s05a_03a / 12
	gen double _ydivi    = s05a_03b / 12
	gen double _yalqmaq  = s05a_03c / 12
	egen double ynlm_ci = rowtotal(_yinteres _yalqui _yotren _yalqagri _ydivi _yalqmaq d_yasistfam d_ytransmon ypen_ci ytransf_ci remesas_ci), mi
	drop _yinteres _yalqui _yotren _yalqagri _ydivi _yalqmaq

	**********
	* ynlnm_ci *
	**********
	_mens d_yalimento s05b_05ca s05b_05cb d_dias_pri
	_mens d_yotro_bono2 s05b_06ca s05b_06cb d_dias_pri
	egen double ynlnm_ci = rowtotal(d_yalimento d_yotro_bono2), missing

	*********
	*ytot_ci*
	********
	foreach v in ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci ylnmotros_ci {
		capture confirm variable `v'
		if _rc gen double `v' = .
		replace `v' = . if emp_ci != 1
		replace `v' = . if `v' < 0
		replace `v' = 0 if categopri_ci == 4 & emp_ci == 1 & missing(`v')
	}

	* Ingreso laboral primario (monetario + no monetario)
	egen double yl_pri = rowtotal(ylmpri_ci ylnmpri_ci), missing
	replace yl_pri = . if yl_pri < 0
	* Ingreso laboral secundario y laboral otro (monetario + no monetario)
	egen double yl_sec = rowtotal(ylmsec_ci ylnmsec_ci ylmotros_ci ylnmotros_ci), missing
	replace yl_sec = . if yl_sec < 0
	* Ingreso laboral total (primario + secundario)
	egen double yl_ci = rowtotal(yl_pri yl_sec), missing
	replace yl_ci = . if missing(yl_pri)
	* Ingreso no Laboral total (monetario + no monetario)
	egen double ynl_ci = rowtotal(ynlm_ci ynlnm_ci), missing
	replace ynl_ci = . if ynl_ci < 0
	* Ingreso total
	egen double ytot_ci = rowtotal(yl_ci ynl_ci), missing
	replace ytot_ci = . if condocup_ci == 1 & (missing(yl_pri) | (yl_pri <= 0 & categopri_ci != 4))
	replace ytot_ci = . if condocup_ci != 1 & (missing(ynl_ci) | ynl_ci <= 0)

	*********
	* ylm_ch *
	*********
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi

	**********
	* ylnm_ch *
	**********
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi

	***********
	* ylmnr_ch *
	***********
	bysort idh_ch: egen double ylmnr_ch = total(ylm_ci) if miembros_ci == 1, mi
	replace ylmnr_ch = . if nrylmpri_ch == 1

	*********
	* ynlm_ch *
	*********
	bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci == 1, mi

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, mi

	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
	* horas semanales -> mensuales (x 4.3)
	generate double ylmhopri_ci = ylmpri_ci / (horaspri_ci * 4.3) if emp_ci == 1 & horaspri_ci > 0

	**********
	* ylmho_ci *
	**********
	generate double ylmho_ci = ylm_ci / (horastot_ci * 4.3) if emp_ci == 1 & horastot_ci > 0

	****************************
	***VARIABLES DE PROTECCION SOCIAL***
	****************************
	*********
	*pnc_ch*
	*********
	bysort idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1

	**********
	*ptmc_ch*
	**********
	bysort idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1

	************
	*potrot_ch*
	************
	bysort idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1

	**********
	*ypnc_ch*
	**********
	bysort idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi

	***********
	*yptmc_ch*
	***********
	bysort idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi

	************
	*yotrot_ch*
	************
	bysort idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

	*************
	*ytransf_ch*
	*************
	bysort idh_ch: egen double ytransf_ch = total(ytransf_ci) if miembros_ci == 1, mi

	**********
	*ynet_ci*
	**********
	gen double aux_ytransf_ci = ytransf_ci * (-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
	drop aux_ytransf_ci

	**********
	*ynet_ch*
	**********
	gen double aux_ytransf_ch = ytransf_ch * (-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	drop aux_ytransf_ch

	*************
	*ynet_ch_pc*
	*************
	generate double ynet_ch_pc = ynet_ch / nmiembros_ch if nmiembros_ch > 0 & !missing(nmiembros_ch)

	*************
	* remesas_ch *
	*************
	bysort idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, mi

	* Limpieza de variables auxiliares de ingresos
	drop d_* aux_pc s6_112 rem juancito_ci juana_ci subpre_ci discap_ci natal_ci ydiscap_ci

****************************
***VARIABLES DE EDUCACION***
****************************

	*********
	*aedu_ci*
	*********
	/* s03a_02a: nivel mas alto aprobado; s03a_02c: curso. Curso 8 en superior = nivel terminado */
	* para tecnico/ETA/otros cursos (71, 72, 77, 78) se suma 12 anios + curso,
	* presumiendo bachillerato; 64 casos no lo tienen segun s03a_03a/c (impacto despreciable en la media).
	gen aedu_ci = .

	* Ninguno, alfabetizacion o preescolar
	replace aedu_ci = 0 if inlist(s03a_02a, 11, 12, 13)

	* Primaria y secundaria (sistema actual y regimen anterior)
	replace aedu_ci = s03a_02c if inlist(s03a_02a, 21, 31, 41, 51)
	replace aedu_ci = s03a_02c + 5     if s03a_02a == 22  /* intermedio */
	replace aedu_ci = s03a_02c + 5 + 3 if s03a_02a == 23  /* medio */
	replace aedu_ci = s03a_02c + 8     if s03a_02a == 32  /* secundaria sistema anterior (4 anios) */
	replace aedu_ci = s03a_02c + 6     if s03a_02a == 42  /* secundaria sistema actual (6 anios) */
	replace aedu_ci = s03a_02c + 6     if s03a_02a == 52  /* CEMA */

	* La educacion alternativa (61-65) no es educacion formal: missing.
	*  impacto = 110 personas (96 ocupadas) sin aedu_ci/eduui/eduuc, aunque el aestudio del INE
	* les asigna 1-12 anios (63 = Secundaria de Personas Jovenes y Adultas, 93 casos). Se mantiene en missing (criterio heredado
	* de 2024); 36 hogares tienen top_edu_ocp asignado sobre aedu_ci missing. Pendiente de definir con SCL una equivalencia.
	replace aedu_ci = . if inrange(s03a_02a, 61, 65)

	* Superior
	replace aedu_ci = s03a_02c + 12         if s03a_02c <= 5 & (inlist(s03a_02a, 71, 72, 73) | s03a_02a >= 77)
	replace aedu_ci = s03a_02c + 12 + 5     if s03a_02c <= 5 & inlist(s03a_02a, 74, 75)
	replace aedu_ci = s03a_02c + 12 + 5 + 2 if s03a_02c <= 5 & s03a_02a == 76

	* Terminacion de nivel superior (curso = 8)
	replace aedu_ci = 12 + 2     if inlist(s03a_02a, 71, 77, 78) & s03a_02c == 8
	replace aedu_ci = 12 + 3     if s03a_02a == 72 & s03a_02c == 8
	replace aedu_ci = 12 + 5     if s03a_02a == 73 & s03a_02c == 8
	replace aedu_ci = 12 + 5 + 1 if s03a_02a == 74 & s03a_02c == 8
	replace aedu_ci = 12 + 5 + 2 if s03a_02a == 75 & s03a_02c == 8
	replace aedu_ci = 12 + 5 + 4 if s03a_02a == 76 & s03a_02c == 8

	*en tecnico medio (71, dura 2 anios) y superior (72, dura 3) el curso 5
	* no es un anio de estudio sino un codigo especial (egresado): sumarlo daba 17 anios (127 casos), mas que un titulado.
	* Se topa en el nivel completo, igual que el aestudio del INE (14 y 15).
	replace aedu_ci = 12 + 2 if s03a_02a == 71 & s03a_02c == 5
	replace aedu_ci = 12 + 3 if s03a_02a == 72 & s03a_02c == 5

	**********
	*eduui_ci*
	**********
	/* la conclusion del nivel superior se toma del curso aprobado
	   (s03a_02c == 8 = nivel terminado, igual que en aedu_ci) y no de s03a_05 (por que no se matriculo este anio),
	   que clasificaba como "incompleta" a 2,904 titulados de tecnico superior/licenciatura que hoy trabajan.
	   La serie BOL 2024 tiene el mismo error (heredado): recomputar si se publica la serie. */
	gen byte eduuc_ci = 0
	replace eduuc_ci = 1 if inlist(s03a_02a, 72, 73) & s03a_02c == 8
	replace eduuc_ci = 1 if inlist(s03a_02a, 74, 75, 76) | (s03a_04 == 1 & inlist(s03a_06a, 74, 75, 76))
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = 0
	replace eduui_ci = 1 if (inlist(s03a_02a, 72, 73) & s03a_02c < 8) | (s03a_04 == 1 & inlist(s03a_06a, 72, 73))
	* Quien ya completo el nivel superior (p.ej. posgrado) y cursa otra licenciatura es eduuc_ci=1, no eduui_ci
	replace eduui_ci = 0 if eduuc_ci == 1
	replace eduui_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	/* CORRECCION (adversarial 2, MENOR-6): el 0 (tecnico superior) se asigna primero y el 1 (universitario, por nivel aprobado
	   o por inscripcion actual) despues, para que prevalezca (40 casos quedaban con eduac_ci=0). */
	gen byte eduac_ci = .
	replace eduac_ci = 0 if s03a_02a == 72 | (s03a_04 == 1 & s03a_06a == 72)
	replace eduac_ci = 1 if inrange(s03a_02a, 73, 76) | (s03a_04 == 1 & inrange(s03a_06a, 73, 76))
	replace eduac_ci = . if aedu_ci == .

	***********
	*edupre_ci*
	***********
	gen byte edupre_ci = .

	************
	*asispre_ci*
	************
	gen byte asispre_ci = .

	***********
	*asiste_ci*
	***********
	/*asistencia = matricula
	   (s03a_04), salvo los matriculados que hoy no pasan clases por una razon distinta a vacaciones o fin de ciclo
	   (s03b_10 == 4 "No" y s03b_11 en 3-5: trabajo, traslado, otro; 58 casos). Segun el DDI, s03b_11 == 2 "culmino sus
	   estudios" es haber concluido el anio/ciclo escolar y el cuestionario lo agrupa con "vacacion" (s03b_11 == 1):
	   esos 213 matriculados se tratan como asistentes (la ronda 1 los clasificaba como no asistentes y bajaba la
	   asistencia de 17-18 anios 4.1 pp). La encuesta se levanta en diciembre: los 6,011 matriculados de vacacion/receso
	   (s03b_11 == 1) tambien son asistentes (criterio del manual). */
	gen byte asiste_ci = .
	replace asiste_ci = 0 if s03a_04 == 2
	replace asiste_ci = 1 if s03a_04 == 1
	replace asiste_ci = 0 if s03a_04 == 1 & s03b_10 == 4 & inrange(s03b_11, 3, 5)

	*************
	*razonesnoasis_ci*
	**************
	/* s03a_05: por que no se inscribio. 1 culmino -> 2 falta de interes/termino; 2 enfermedad, 3 embarazo,
	   4 labores de casa -> 3; 5 falto dinero, 6 trabajo -> 1; 7 no le corresponde por edad -> 4; 8 otro -> 5 */
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(s03a_05, 5, 6) & asiste_ci == 0
	replace razonesnoasis_ci = 2 if s03a_05 == 1 & asiste_ci == 0
	replace razonesnoasis_ci = 3 if inlist(s03a_05, 2, 3, 4) & asiste_ci == 0
	replace razonesnoasis_ci = 4 if s03a_05 == 7 & asiste_ci == 0
	replace razonesnoasis_ci = 5 if s03a_05 == 8 & asiste_ci == 0
	* Matriculados que no asisten (s03b_11): 3 trabajo -> 1; 4 traslado de la familia -> 3; 5 otro -> 5
	* (s03b_11 == 2 "culmino" ya no es no asistencia: adversarial 2, IMPORTANTE-1)
	replace razonesnoasis_ci = 1 if s03a_04 == 1 & s03b_10 == 4 & s03b_11 == 3
	replace razonesnoasis_ci = 3 if s03a_04 == 1 & s03b_10 == 4 & s03b_11 == 4
	replace razonesnoasis_ci = 5 if s03a_04 == 1 & s03b_10 == 4 & s03b_11 == 5

	***********
	*edupub_ci*
	***********
	/* s03a_09: establecimiento donde se matriculo: 1 fiscal/publico/convenio, 2 particular */
	gen byte edupub_ci = .
	replace edupub_ci = 1 if s03a_09 == 1 & asiste_ci == 1
	replace edupub_ci = 0 if s03a_09 == 2 & asiste_ci == 1


****************************
***VARIABLES DE VIVIENDA***
****************************
	***********
	*luz_ch*
	***********
	gen byte luz_ch = .
	replace luz_ch = 0 if s06a_12 == 2
	replace luz_ch = 1 if s06a_12 == 1

	***********
	*luzmide_ch*
	***********
	gen byte luzmide_ch = .

	***********
	*combust_ch*
	***********

	gen byte combust_ch = .
	replace combust_ch = 0 if inlist(s06a_15, 1, 2, 5, 7)
	replace combust_ch = 1 if inlist(s06a_15, 3, 4, 6)	/* gas licuado, gas por canieria, electricidad */

	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLOGIA AUN NO CREAR
	gen piso_ch = .

	***********
	*pared_ch*
	***********
	* NOTA: REVISANDO METODOLOGIA AUN NO CREAR
	gen pared_ch = .

	***********
	*techo_ch*
	***********
	* NOTA: REVISANDO METODOLOGIA AUN NO CREAR
	gen techo_ch = .

	***********
	*resid_ch*
	***********
	gen byte resid_ch = .
	replace resid_ch = 0 if inlist(s06a_13, 5, 6)   /* basurero publico o servicio de recoleccion */
	replace resid_ch = 1 if inlist(s06a_13, 2, 4)   /* quemada o enterrada */
	replace resid_ch = 2 if inlist(s06a_13, 1, 3)   /* tirada al rio, terreno baldio o calle */
	replace resid_ch = 3 if s06a_13 == 7            /* otro */

	***********
	*dorm_ch*
	***********
	gen dorm_ch = s06a_17	 /* cuartos exclusivamente para dormir */

	***********
	*cuartos_ch*
	***********

	gen cuartos_ch = .

	***********
	*cocina_ch*
	***********
	gen byte cocina_ch = .
	replace cocina_ch = 0 if s06a_14 == 2
	replace cocina_ch = 1 if s06a_14 == 1

	***********
	*telef_ch*
	***********
	gen byte telef_ch = .
	replace telef_ch = 0 if s06a_18 == 2
	replace telef_ch = 1 if s06a_18 == 1

	***********
	*refrig_ch*
	***********
	/* posee_5 = refrigerador o freezer (2025) */
	gen byte refrig_ch = .
	replace refrig_ch = 0 if posee_5 == 2
	replace refrig_ch = 1 if posee_5 == 1

	***********
	*freez_ch*
	***********
	/* La encuesta no separa freezer de refrigerador: posee_5 */
	gen byte freez_ch = .
	replace freez_ch = 0 if posee_5 == 2
	replace freez_ch = 1 if posee_5 == 1

	***********
	*auto_ch*
	***********
	/* posee_18 = automovil (posee_17 = motocicleta, no se incluye) */
	gen byte auto_ch = .
	replace auto_ch = 0 if posee_18 == 2
	replace auto_ch = 1 if posee_18 == 1

	***********
	*compu_ch*
	***********
	/* posee_7 = computadora (laptop o tablet pc); posee_8 = tablet (no se incluye) */
	gen byte compu_ch = .
	replace compu_ch = 0 if posee_7 == 2
	replace compu_ch = 1 if posee_7 == 1

	***********
	*internet_ch*
	***********
	gen byte internet_ch = .
	replace internet_ch = 0 if s06a_19 == 2
	replace internet_ch = 1 if s06a_19 == 1

	***********
	*cel_ch*
	***********
	/* posee_9 = telefono celular */
	gen byte cel_ch = .
	replace cel_ch = 0 if posee_9 == 2
	replace cel_ch = 1 if posee_9 == 1

	***********
	*vivi1_ch*
	***********
	gen byte vivi1_ch = .
	replace vivi1_ch = 1 if s06a_01 == 1                          /* casa */
	replace vivi1_ch = 2 if s06a_01 == 3                          /* departamento */
	replace vivi1_ch = 3 if inlist(s06a_01, 2, 4, 5, 6)           /* choza, cuartos sueltos, improvisada, local */

	***********
	*vivi2_ch*
	***********
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if vivi1_ch == 1 | vivi1_ch == 2
	replace vivi2_ch = 0 if vivi1_ch == 3

	***********
	*viviprop_ch*
	***********
	gen byte viviprop_ch = .
	replace viviprop_ch = 0 if s06a_02 == 3                       /* alquilada */
	replace viviprop_ch = 1 if s06a_02 == 1                       /* propia y totalmente pagada */
	replace viviprop_ch = 2 if s06a_02 == 2                       /* propia y la estan pagando */
	replace viviprop_ch = 0 if s06a_02 == 4                       /* contrato mixto (alquiler y anticretico) */
	replace viviprop_ch = 3 if inlist(s06a_02, 5, 6, 7, 8)        /* anticretico, cedida, prestada, otra */

	***********
	*vivitit_ch*
	***********
	gen byte vivitit_ch = .

	***********
	*vivialq_ch*
	***********
	/* alquiler mensual pagado, solo hogares con vivienda alquilada (viviprop_ch==0), que ahora incluye
	   los contratos mixtos (alquiler + anticretico), que tambien reportan s06a_02b (cumple rul_viv2). */
	gen vivialq_ch = s06a_02b if viviprop_ch == 0

	***********
	*vivialqimp_ch*
	***********
	/* s06a_02a solo se pregunta a propietarios; vivialqimp_ch queda en missing para
	   viviprop_ch == 3 (2,865 hogares). Es una limitacion del cuestionario (el manual pide valor para viviprop 1, 2 y 3): no se imputa. */
	gen vivialqimp_ch = s06a_02a   /* alquiler mensual imputado (hogares propietarios) */

****************************
***VARIABLES DE WASH***
****************************
	* Las variables de vivienda (s06a_*) se repiten en todos los miembros del hogar

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch = .
	replace aguared_ch = 1 if inlist(s06a_07, 1, 2)         /* canieria de red dentro de la vivienda o del lote */
	replace aguared_ch = 0 if s06a_07 >= 3 & s06a_07 != .

	***********
	*aguafconsumo_ch*
	***********
	/* La encuesta pregunta por el agua que usan en la vivienda (no distingue agua para beber) */
	gen byte aguafconsumo_ch = 0

	***********
	*aguafuente_ch*
	***********
	gen byte aguafuente_ch = .
	replace aguafuente_ch = 1  if inlist(s06a_07, 1, 2)    /* red, conexion privada */
	replace aguafuente_ch = 2  if s06a_07 == 3             /* pileta publica */
	replace aguafuente_ch = 4  if s06a_07 == 5             /* pozo excavado o perforado con bomba */
	replace aguafuente_ch = 5  if s06a_07 == 4             /* cosecha de agua de lluvia */
	replace aguafuente_ch = 6  if s06a_07 == 9             /* carro repartidor (aguatero) */
	replace aguafuente_ch = 7  if s06a_07 == 7             /* manantial o vertiente protegida */
	replace aguafuente_ch = 8  if s06a_07 == 8             /* rio, acequia, vertiente no protegida */
	replace aguafuente_ch = 9  if s06a_07 == 6             /* pozo no protegido o sin bomba */
	replace aguafuente_ch = 10 if s06a_07 == 10            /* otro */

	******************
	** aguadist_ch **
	*****************
	* pozo con bomba (964 hogares), lluvia (37) y aguatero (373) quedan en 0
	gen byte aguadist_ch = .
	replace aguadist_ch = 1 if s06a_07 == 1               /* dentro de la vivienda */
	replace aguadist_ch = 2 if s06a_07 == 2                /* fuera de la vivienda, dentro del lote */
	replace aguadist_ch = 3 if s06a_07 == 3                /* pileta publica (fuera de la propiedad) */
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch != .

	******************
	** aguadisp1_ch **
	*****************
	gen byte aguadisp1_ch = 9   /* la encuesta no pregunta disponibilidad en formato si/no */

	******************
	** aguadisp2_ch **
	*****************
	/* s06a_08a: dias por semana con agua; s06a_08b: horas por dia */
	gen byte aguadisp2_ch = .
	replace aguadisp2_ch = 1 if (s06a_08a <= 3 | s06a_08b < 12)
	replace aguadisp2_ch = 2 if (s06a_08a >= 4 & s06a_08a != . & s06a_08b >= 12 & s06a_08b != .)
	replace aguadisp2_ch = 3 if (s06a_08a == 7 & s06a_08b == 24)
	*  s06a_08a/b solo se preguntan con fuente 1-3; resto de hogares = 9 (no se pregunta)
	replace aguadisp2_ch = 9 if missing(aguadisp2_ch) & !missing(s06a_07)

	******************
	** aguatrat_ch **
	*****************
	gen byte aguatrat_ch = 9   /* la encuesta no pregunta tratamiento del agua */

	******************
	** aguamala_ch **
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	******************
	** aguamejorada_ch **
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7

	******************
	** aguamide_ch **
	*****************
	gen byte aguamide_ch = .   /* la encuesta no pregunta por medidor de agua */

	******************
	** bano_ch **
	*****************
	/* s06a_09: 1 bano con descarga, 2 letrina pozo ciego con piso, 3 pozo abierto, 4 bano ecologico, 5 ninguno
	   s06a_10 (solo si s06a_09==1): 1 alcantarillado, 2 camara septica, 3 pozo de absorcion, 4 superficie, 5 no sabe */
	gen byte bano_ch = 6
	replace bano_ch = 0 if s06a_09 == 5
	replace bano_ch = 1 if s06a_09 == 1 & s06a_10 == 1
	replace bano_ch = 2 if s06a_09 == 1 & s06a_10 == 2
	replace bano_ch = 3 if (inlist(s06a_09, 2, 4)) | (s06a_09 == 1 & s06a_10 == 3)
	replace bano_ch = 4 if s06a_09 == 1 & s06a_10 == 4
	replace bano_ch = 5 if s06a_09 == 3
	replace bano_ch = . if missing(s06a_09)

	******************
	** banoex_ch **
	*****************
	gen byte banoex_ch = .
	replace banoex_ch = 0 if s06a_11 == 2
	replace banoex_ch = 1 if s06a_11 == 1

	******************
	** sinbano_ch **
	*****************
	gen byte sinbano_ch = .
	replace sinbano_ch = 0 if bano_ch != 0 & bano_ch != .
	replace sinbano_ch = 2 if s06a_09 == 5    /* ninguno: arbusto/campo */

	******************
    ** banomejorado_ch **
    *****************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6

	****************************
	***VARIABLES DE MIGRACIÓN***
	****************************

	*****************
    *migrante_ci****
    ****************
	/* s01b_10a: donde nacio (1 en este lugar, 2 en otro lugar del pais, 3 en el exterior) */
	gen byte migrante_ci = .
	replace migrante_ci = 0 if inlist(s01b_10a, 1, 2)
	replace migrante_ci = 1 if s01b_10a == 3

	****************
	 *migrantiguo5_ci*
	****************
	/* s01b_11a: donde vivia hace 5 anios (1 aqui, 2 otro lugar del pais, 3 exterior, 4 aun no habia nacido).
	   Migrante nacido en el exterior: antiguo (>=5 anios) si hace 5 anios ya vivia en el pais (1,2);
	   reciente si hace 5 anios vivia en el exterior o no habia nacido (3,4). */
	gen byte migrantiguo5_ci = .
	replace migrantiguo5_ci = 0 if migrante_ci == 1 & inlist(s01b_11a, 3, 4)
	replace migrantiguo5_ci = 1 if migrante_ci == 1 & inlist(s01b_11a, 1, 2)

	****************
	 *miglac_ci*
	****************
	* La encuesta no pregunta el pais de nacimiento
	gen byte miglac_ci = .


	****************************
	*** VARIABLES DE POBREZA ***
	****************************

	*****************************************
	*CPI, IPC, Flag si tiene renta imputada*
	****************************************
	*merge m:1 pais_c anio_c using "$datalibweb_IDB\SUPPORT\support_0926.dta", keepusing(cpi icp flag_renta_imp) keep(3) nogen TODAVIa no hay los datos
	gen flag_renta_imp = 0
	gen cpi =.
	gen icp=.


	**************
	*top_edu_ocup*
	**************
	bysort idh_ch: egen max_edu_ocp = max(cond(condocup_ci==1 & miembros_ci==1, aedu_ci, .))
	gen byte top_edu_ocp = condocup_ci==1 & miembros_ci==1 & aedu_ci==max_edu_ocp
	bysort idh_ch top_edu_ocp (idp_ci): gen rank = _n
	replace top_edu_ocp = 0 if rank > 1
	drop max_edu_ocp rank

	bysort idh_ch: egen byte jefe_ocup_ch = max(jefe_ci==1 & condocup_ci==1)
	* Ingreso invalido = missing o <= 0
	bysort idh_ch: egen byte _jefe_inv  = max(jefe_ci==1 & (missing(ytot_ci) | ytot_ci<=0))
	bysort idh_ch: egen byte _topedu_ok = max(top_edu_ocp==1 & !missing(ytot_ci) & ytot_ci>0)
	* Jefe ocupado: el hogar sigue la regla del jefe
	* Jefe no ocupado: manda top_edu_ocp; si no tiene ingreso valido (o no hay ocupados), vuelve a la regla del jefe
	gen byte flag_ref_ch = cond(jefe_ocup_ch==1, _jefe_inv, _jefe_inv & !_topedu_ok)

	*********
	*ynivhog*
	*********
	gen ynivhog = 0 // replace if var exists

	*************
	*rentaimp_ch*
	*************
	local var_ri
	capture confirm numeric variable `var_ri'
	if _rc & "`var_ri'" != "" di as err "`var_ri' no existe: renta imputada = 10% del ITF"
	if _rc local var_ri "."
	bysort idh_ch: egen double renta_imp_ch = max(cond(jefe_ci==1 & inlist(viviprop_ch,1,2,4), `var_ri', .))

	*******************
	*welfare_income_ch*
	*******************
	bysort idh_ch: egen double welfare_income_ch = total(cond(miembros_ci==1, ytot_ci, .)), missing
	replace welfare_income_ch = welfare_income_ch + ynivhog
	replace welfare_income_ch = . if flag_ref_ch==1
	replace renta_imp_ch = 0.10 * welfare_income_ch if missing(renta_imp_ch) & inlist(viviprop_ch,1,2,4) & !missing(welfare_income_ch) & flag_renta_imp == 0
	replace welfare_income_ch = (welfare_income_ch + cond(missing(renta_imp_ch), 0, renta_imp_ch)) * cond(zona_c==0, 1.15, 1)
	replace welfare_income_ch = welfare_income_ch/ ((365/12) * cpi * icp)

	***********************
	*welfare_income_ci*
	***********************
	gen double welfare_income_ci = welfare_income_ch / nmiembros_ch
	replace    welfare_income_ci = . if nmiembros_ch == 0 | missing(nmiembros_ch)
	replace    welfare_income_ci = . if welfare_income_ci < 0

	***********
	*pobre_umi*
	***********
	gen byte pobre_umi = (welfare_income_ci < 8.3) if !missing(welfare_income_ci)

	***********
	*pobre_lmi*
	***********
	gen byte pobre_lmi = (welfare_income_ci < 4.2) if !missing(welfare_income_ci)

	****************
	*tipo_bienestar*
	****************
	gen byte tipo_bienestar = 1  

	****************
	* pobre_ine_ci*
	****************
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci = 0 if p0 == 0
	replace pobre_ine_ci = 1 if p0 == 1

	*******************
	* pobre_ine_ext_ci*
	*******************
	gen pobre_ine_ext_ci = .
	replace pobre_ine_ext_ci = 0 if pext0 == 0
	replace pobre_ine_ext_ci = 1 if pext0 == 1

	****************
	* bienestar_agregado *
	****************
	gen bienestar_agregado = yhogpc  

	**************
	***salmm_ci***
	**************
	* Salario minimo nacional mensual 2025 (Bs). VERIFICAR con INE/Decreto Supremo
	gen salmm_ci = 2750

	************
	***ln_ci***
	************
	gen ln_ci = z

	************
	***lpe_ci***
	************
	gen lpe_ci = zext

	****************************
	*** VARIABLES EXTERNAS ***
	****************************
	do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas
/*_____________________________________________________________________________________________________*/


	local vars ///
	region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci welfare_income_ch /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  top_edu_ocp ynivhog renta_imp_ch welfare_income_ch welfare_income_ci flag_ref_ch pobre_umi pobre_lmi yl_pri yl_sec yl_ci ynl_ci ///
  tipo_bienestar bienestar_agregado lpe_ci ln_ci pobre_ine_ci pobre_ine_ext_ci cpi icp flag_renta_imp salmm_ci /// Pobreza

order `vars'
compress
save "`merge_out'", replace
keep `vars'
save "`harmonized_out'", replace
log close

