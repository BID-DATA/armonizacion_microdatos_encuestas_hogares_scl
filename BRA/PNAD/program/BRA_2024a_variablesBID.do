* (Versión Stata 17)

clear
set more off

*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 
 /*
global ruta = "${surveysFolder}"

local PAIS BRA
local ENCUESTA PNADC
local ANO "2023"
local ronda a 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
          
capture log close
log using "`log_file'", replace 
*/

global survey_folder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"

local PAIS BRA
local ENCUESTA PNADC
local ANO "2024"
local ronda a

global ruta "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

local log_file  "$survey_folder\\log\\`PAIS'\\`ENCUESTA'\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'_BID.dta"
                                     
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES 
País: Brasil
Encuesta: PNADC
Round: anual 2024
Autores: Maria Alejandra Zegarra
Versión ...: Octubre 2025

/***************************************************************************/
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

**********************************
**** ARMONIZACIÓN PNAD_C 2024 **** 
**********************************
rename *, lower
				
**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	
	********************
	*** region_BID_c ****
	********************
	gen region_BID_c=4 

	********************
	*** region_BID_c ****
	********************
	gen region_c = uf
	destring region_c, replace
	label define region_c ///
	11 "Rondônia" ///
	12 "Acre" ///
	13 "Amazonas" ///
	14 "Roraima" ///
	15 "Pará" ///
	16 "Amapá" ///
	17 "Tocantins" ///
	21 "Maranhão" ///
	22 "Piauí" ///
	23 "Ceará" ///
	24 "Rio Grande do Norte" ///
	25 "Paraíba" ///
	26 "Pernambuco" ///
	27 "Alagoas" ///
	28 "Sergipe" ///
	29 "Bahia" ///
	31 "Minas Gerais" ///
	32 "Espírito Santo" ///
	33 "Rio de Janeiro" ///
	35 "São Paulo" ///
	41 "Paraná" ///
	42 "Santa Catarina" ///
	43 "Rio Grande do Sul" ///
	50 "Mato Grosso do Sul" ///
	51 "Mato Grosso" ///
	52 "Goiás" ///
	53 "Distrito Federal"
	label value region_c region_c
	label var region_c "division politico-administrativa"

	*************
	* pais_c    *
	*************
	gen str3 pais_c = "BRA"

	******
	*anio*
	******
	gen int anio_c = ano

	******
	*mes_c*
	******
	gen int mes_c = .
	
	******
	*zona*
	******
	* PNADC: V1022 (1 urbana, 2 rural) -> estandar: 1 urbana, 0 rural
	gen zona_c = v1022

	*********
	*estrato*
	*********
	gen estrato_ci = estrato

	 *****************************
	*unidad primaria de muestreo*
	*****************************
	* PNADC: UPA
	gen upm_ci = upa
	
	******************
	*** idh_ch ******
	******************
	* id hogar: UPA + V1008 + V1014
	egen long _idhnum = group(upa v1008 v1014)
	tostring _idhnum, gen(idh_ch)
	drop _idhnum
	
	******************
	*** idp_ci *******
	******************
	egen str idp_ci = concat(idh_ch v2003), punct("_")

	***********
	*factor_ci* 
	***********
	* Ponderador de personas: V1032
	gen double factor_ci = v1032

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	* PNADC trae peso de hogar en V1030; si no está, usar V1032 como fallback
	gen double factor_ch = v1030
	replace factor_ch = factor_ci if factor_ch==.

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	* PNADC: V2007 (1 hombre, 2 mujer)
	gen byte sexo_ci = v2007

	*********
	*edad_ci*
	*********
	* PNADC: V2009 (edad en años). 999 -> .
	gen int edad_ci = .
	capture confirm variable v2009
	if _rc==0 {
		replace edad_ci = v2009
		replace edad_ci = . if edad_ci==999
	}

	**************
	**relacion_ci**
	**************
	* PNADC: V2005 condición no domicílio
	* 1 Ref, 2 Cônjuge, 3 Filho, 4 Enteado, 5 Genro/Nora, 6 Pai/Mãe, 7 Sogro,
	* 8 Neto, 9 Outro parente, 10 Agregado, 11 Pensionista, 12 Empregado dom., 13 Parente do emp. dom.
	gen byte relacion_ci = .
	capture confirm variable v2005
	if !_rc {
		replace relacion_ci = 1 if v2005==1
		replace relacion_ci = 2 if v2005==2
		replace relacion_ci = 3 if inlist(v2005,3,4)
		replace relacion_ci = 4 if inlist(v2005,5,6,7,8,9)
		replace relacion_ci = 5 if inlist(v2005,10,11,13)   // no parientes (incluye parente do emp. dom.)
		replace relacion_ci = 6 if v2005==12                // emp. doméstico
	}
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci = .

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci = (relacion_ci==1)
	replace jefe_ci = . if relacion_ci==.

	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen nconyuges_ch = total(relacion_ci==2)
	replace nconyuges_ch = . if relacion_ci==.

	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch = total(relacion_ci==3)
	replace nhijos_ch = . if relacion_ci==.

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch = total(relacion_ci==4)
	replace notropari_ch = . if relacion_ci==.

	****************
	*notronopari_ch*
	****************
	by idh_ch, sort: egen byte notronopari_ch = total(relacion_ci==5)
	replace notronopari_ch = . if relacion_ci==.

	************
	*nempdom_ch*
	************
	by idh_ch, sort: egen byte nempdom_ch = total(relacion_ci==6)
	replace nempdom_ch = . if relacion_ci==.

	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch = 2 if (nhijos_ch>0 | nconyuges_ch>0) & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch = 3 if notropari_ch>0 & notronopari_ch==0
	replace clasehog_ch = 4 if ( (nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & notronopari_ch>0 )
	replace clasehog_ch = 5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch = total(relacion_ci>0 & relacion_ci<=5)

	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch  = total((relacion_ci>0 & relacion_ci<=5) & edad_ci>=21 & edad_ci!=.)

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch  = total((relacion_ci>0 & relacion_ci<=5) & edad_ci<21)

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch  = total((relacion_ci>0 & relacion_ci<=5) & edad_ci>=65 & edad_ci!=.)

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch   = total((relacion_ci>0 & relacion_ci<=5) & edad_ci<6)

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch   = total((relacion_ci>0 & relacion_ci<=5) & edad_ci<1)

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = (relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci = . if relacion_ci==.

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	*********
	*afro_ci*
	*********
	** PNADC: COR OU RAÇA (v2010): 1 Branca, 2 Preta, 3 Amarela, 4 Parda, 5 Indígena, 9 Ignorado
	gen byte afro_ci = .
    replace afro_ci = 1 if inlist(v2010,2,4)
    replace afro_ci = 0 if inlist(v2010,1,3,5)
    replace afro_ci = . if v2010==9

	*********
	*ind_ci*
	*********
	gen byte ind_ci = .
    replace ind_ci = 1 if v2010==5
    replace ind_ci = 0 if inlist(v2010,1,2,3,4)
    replace ind_ci = . if v2010==9

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1
	replace noafroind_ci = . if afro_ci==. | ind_ci==.

	************
	*afroind_ci*
	************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1

	*********
	*afro_ch*
	*********
	gen afro_jefe = afro_ci if relacion_ci==1
	egen afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe

	********
	*ind_ch*
	********
	gen ind_jefe = ind_ci if relacion_ci==1
	egen ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe

	**************
	*noafroind_ch*
	**************
	gen noafroind_jefe = noafroind_ci if relacion_ci==1
	egen noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe

	************
	*afroind_ch*
	************
	gen afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe

*******************************************************
***        VARIABLES DE DISCAPACIDAD (WG)           ***
*******************************************************

	********
	*dis_ci*
	********
	* Flexible WG: si PNADC trae el set corto WG con escala, clasificar; si no, dejar .
	gen byte dis_ci = .

	**********
	*disWG_ci*
	**********
	* Estricto WG: 1 si “mucha dificultad” o “no puede” en ≥1 dominio; si no existen preguntas → .
	gen byte disWG_ci = .

	********
	*dis_ch*
	********
	egen dis_ch = max(dis_ci), by(idh_ch)

	******************
	*ISOalpha3_dis_ci*
	******************
	* País: BRA → si usara WG corto, BRA_dis_ci = dis_ci; si no hay módulo, queda .
	gen bra_dis_ci = dis_ci

****************************
***VARIABLES DE EDUCACION***
****************************

	*********	
	*aedu_ci*
	*********
	gen aedu_ci = .
	replace aedu_ci = vd3005 if vd3005<.   // usa directamente años reportados

	**********
	*eduui_ci*
	**********
	* Superior INCOMPLETO (aprox. con años si no hay nivel detallado)
	gen byte eduui_ci = .
	replace eduui_ci = 1 if aedu_ci>12 & aedu_ci<16
	replace eduui_ci = 0 if aedu_ci<=12 | aedu_ci>=16
	replace eduui_ci = . if aedu_ci==.

	**********
	*eduuc_ci*
	**********
	* Superior COMPLETO o posgrado (aprox. con años)
	gen byte eduuc_ci = .
	replace eduuc_ci = 1 if aedu_ci>=16
	replace eduuc_ci = 0 if aedu_ci<16 & aedu_ci!=.
	replace eduuc_ci = . if aedu_ci==.

	**********
	*eduac_ci*
	**********
	* Univ vs técnico (BRA generalmente no distingue en PNADC núcleo) -> missing
	gen byte eduac_ci = .

	*********** 
	*edupre_ci*
	***********
	* Compleción de preescolar; si no identificable en PNADC → .
	gen byte edupre_ci = .

	************
	*asispre_ci*
	************
	* Asistencia actual a preescolar; si no hay nivel-curso actual, queda .
	gen byte asispre_ci = .

	***********
	*asiste_ci*
	***********
	* Asiste actualmente (PNADC escolarização atual). Si existe V3002: 1 frequenta, 2 não.
	gen byte asiste_ci = .
	replace asiste_ci = 1 if v3002==1
    replace asiste_ci = 0 if v3002==2
	
	*************
	*pqnoasis1_ci*
	**************
	* Razón no asistencia (armonizada 1..5). Si no existe en PNADC personas → .
	gen byte pqnoasis1_ci = .

	***********
	*edupub_ci*
	***********
	* Red del establecimiento actual (1 pública / 0 privada) solo si asiste.
	gen byte edupub_ci = .
    replace edupub_ci = 1 if v3002a==1 & asiste_ci==1
    replace edupub_ci = 0 if v3002a==2 & asiste_ci==1
	
****************************
***VARIABLES DE VIVIENDA***
****************************		

	***********
	***luz_ch***
	***********
	* 1 = electricidad | 0 = no es electricidad | . = NR/NP o no está en la base
	gen byte luz_ch = .

	***************
	***luzmide_ch***
	***************
	* 1 = con medidor | 0 = sin medidor | . = NR/NP o no está en la base
	gen byte luzmide_ch = .

	***************
	***combust_ch***
	***************
	* 1 = gas/eléctrico | 0 = otro | . = NR/NP o no está en la base
	gen byte combust_ch = .

	***********
	***piso_ch***
	***********
	* pendiente metodología → missing si no está
	gen piso_ch = .

	************
	***pared_ch***
	************
	* pendiente metodología → missing si no está
	gen pared_ch = .

	************
	***techo_ch***
	************
	* pendiente metodología → missing si no está
	gen techo_ch = .

	************
	***resid_ch***
	************
	* 0 = recolección | 1 = quema/entierra | 2 = espacio abierto | 3 = otros | . = no está
	gen byte resid_ch = .

	***********
	***dorm_ch***
	***********
	* número de dormitorios | . = no está
	gen dorm_ch = .

	****************
	***cuartos_ch***
	****************
	* número de cuartos totales | . = no está
	gen cuartos_ch = .

	*************
	***cocina_ch***
	*************
	* 1 = existe cuarto exclusivo para cocinar | 0 = no | . = no está
	gen byte cocina_ch = .

	************
	***telef_ch***
	************
	* 1 = teléfono fijo | 0 = no | . = no está
	gen byte telef_ch = .

	***************
	***refrig_ch***
	***************
	* 1 = tiene refrigerador | 0 = no | . = no está
	gen byte refrig_ch = .

	*************
	***freez_ch***
	*************
	* 1 = tiene freezer | 0 = no | . = no está
	gen byte freez_ch = .

	***********
	***auto_ch***
	***********
	* 1 = tiene automóvil | 0 = no | . = no está
	gen byte auto_ch = .

	************
	***compu_ch***
	************
	* 1 = tiene computadora | 0 = no | . = no está
	gen byte compu_ch = .

	*****************
	***internet_ch***
	*****************
	* 1 = tiene internet hogar | 0 = no | . = no está
	gen byte internet_ch = .

	************
	***vivi1_ch***
	************
	* 1 = casa | 2 = depto | 3 = otros | . = no está
	gen byte vivi1_ch = .

	*****************
	***viviprop_ch***
	*****************
	* 0 = alquilada | 1 = propia pagada | 2 = propia en pago | 3 = cedida/usufructo | . = no está
	gen byte viviprop_ch = .

	****************
	***vivitit_ch***
	****************
	* 1 = con título | 0 = sin título | . = no está
	gen byte vivitit_ch = .

	****************
	***vivialq_ch***
	****************
	* monto mensual de alquiler | . = no está
	gen double vivialq_ch = .

	*********************
	***vivialqimp_ch***
	*********************
	* monto mensual de alquiler imputado | . = no está
	gen double vivialqimp_ch = .

****************************
***VARIABLES DE WASH***
****************************

	**************
	***aguared_ch***
	**************
	* 1 = por red | 0 = fuera de red | . = no está
	gen byte aguared_ch = .

	***********************
	***aguafconsumo _ch***
	***********************
	* 0 = la encuesta NO pregunta agua para beber
	* 1..10 = categorías JMP (si existiera la pregunta)
	* Aquí, como no está en la base → asignamos 0 (no pregunta)
	gen byte aguafconsumo_ch = 0

	********************
	***aguafuente_ch***
	********************
	* 1..10 = categorías JMP para fuente general | . = no está
	gen byte aguafuente_ch = .

	******************
	***aguadist_ch***
	******************
	* 0 = no se especifica | 1 = dentro | 2 = en el lote | 3 = fuera del lote
	* Si no está la pregunta → 0
	gen byte aguadist_ch = 0

	*******************
	***aguadisp1_ch***
	*******************
	* 1 = suficiente | 2 = no suficiente | 9 = no existe la pregunta
	* Si no está la pregunta → 9
	gen byte aguadisp1_ch = 9

	*******************
	***aguadisp2_ch***
	*******************
	* 1 = < mitad del tiempo | 2 = > mitad | 3 = sin cortes | 9 = no existe la pregunta
	* Si no está la pregunta → 9
	gen byte aguadisp2_ch = 9

	******************
	***aguatrat_ch***
	******************
	* 1 = trata | 0 = no trata | . = no está
	gen byte aguatrat_ch = .

	******************
	***aguamala_ch***
	******************
	* 0 = mejorada | 1 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamala_ch = 2

	**********************
	***aguamejorada_ch***
	**********************
	* 1 = mejorada | 0 = no mejorada | 2 = no se puede especificar
	* Si no hay fuente → 2
	gen byte aguamejorada_ch = 2

	******************
	***aguamide_ch***
	******************
	* 1 = con medidor | 0 = sin medidor | . = no está
	gen byte aguamide_ch = .

	************
	***bano_ch***
	************
	* 0 = sin inst. | 1 = red | 2 = fosa | 3 = letrina mejorada | 4 = descarga a cuerpo de agua/suelo
	* 5 = no mejorada | 6 = no clasificable | . = no está
	gen byte bano_ch = .

	**************
	***banoex_ch***
	**************
	* 1 = uso exclusivo | 0 = compartido | . = no está
	gen byte banoex_ch = .

	***************
	***sinbano_ch***
	***************
	* 0 = tiene baño | 1 = usa público/vecino | 2 = defecación al aire libre | 3 = no especifica | . = no está
	gen sinbano_ch = .

	**********************
	***banomejorado_ch***
	**********************
	* 1 = mejorado | 0 = no mejorado | 2 = no clasificable
	* Si no hay info de bano_ch → 2
	gen byte banomejorado_ch = 2
	
		
****************************
*** VARIABLES DE MIGRACIÓN***
****************************

	*****************
	*** migrante_ci **
	*****************
	gen byte migrante_ci = .

	******************
	* migrantiguo5_ci *
	******************
	* Migrante en los últimos 5 años
	gen byte migrantiguo5_ci = .

	****************
	* miglac_ci *
	****************
	* Migrante internacional (fuera de LAC → 1)
	gen byte miglac_ci = .
	
****************************
*** VARIABLES EXTERNAS  ***
****************************

	****************
	* tipo_bienestar *
	****************
	* Tipo de medida de bienestar usada por INE/IBGE.
	* Para Brasil, PNADC reporta ingreso → tipo_bienestar = 1
	* (1 = Ingreso, 2 = Consumo)
	gen byte tipo_bienestar = 1

	****************
	* pobre_ine_ci *
	****************
	* Indicador oficial de pobreza según metodología del país.
	* Requiere el umbral oficial (ln_ci o lpe_ci) y la variable de ingreso.
	* Aquí va el criterio de corte (por ejemplo, ingreso per cápita < ln_ci).
	gen byte pobre_ine_ci = .

	****************
	* bienestar_agregado *
	****************
	* Variable continua con el ingreso per cápita mensual imputado/limpio
	* En PNADC: ingreso de todos los miembros dividido por nº de miembros
	gen bienestar_agregado = .

	****************
	* lpe_ci *
	****************
	* 2023: https://educa.ibge.gov.br/jovens/materias-especiais/22544-brasil-atinge-menor-nivel-de-pobreza-em-2023.html
	gen lpe_ci= 209 
	* Línea de pobreza extrema (Banco Mundial / IBGE).
	* 2023 = R$209 → ajustada por inflación 2024 (4,83%) ≈ R$220 mensuales
	*gen lpe_ci = 220

	****************
	* ln_ci *
	****************
	* Línea de pobreza nacional (½ salario mínimo per cápita).
	* Salario mínimo 2024 = R$1412 → ½ = R$706
	gen ln_ci = 706
		
	

	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
