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
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	* Ocupados: cualquier actividad ≥1h O alejado de trabajo remunerado
	replace condocup_ci = 1 if (v4001==1 | v4002==1 | v4003==1 | v4004==1 | v4005==1)

	* Desocupados: no tiene trabajo remunerado en la semana ref. y buscó activamente
	replace condocup_ci = 2 if condocup_ci==. & v4005==2 & v4071==1 & v4072a!=9

	* Inactivos (≥ edad mínima) sin condición previa
	replace condocup_ci = 3 if condocup_ci==. & edad_ci>=10

	* Menor a edad mínima del módulo laboral
	replace condocup_ci = 4 if edad_ci<10
	
	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	* 1) Jubilado/Pensionado
	replace categoinac_ci = 1 if condocup_ci==3 & v4074==2

	* 2) Estudiante
	replace categoinac_ci = 2 if condocup_ci==3 & v4074==3

	* 3) Quehaceres domésticos
	replace categoinac_ci = 3 if condocup_ci==3 & v4074==4

	* 4) Otros inactivos (cierre lógico)
	replace categoinac_ci = 4 if condocup_ci==3 & missing(categoinac_ci)
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci != .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if emp_ci==1 & v4039<30 & v4063a==1 & v4064a==1

	****************
	***durades_ci***
	****************
	gen byte durades_ci=.
	replace durades_ci = v4076 * (52/12) if condocup_ci == 2 & v4076 < .

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)
		
	****************
	*** nempleos_ci***
	****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci==1 & v4009==1
	replace nempleos_ci = 2 if emp_ci==1 & inlist(v4009,2,3)
	replace nempleos_ci = . if emp_ci==0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .
	/*** Fallback (categorías tipo Brasil): v40402 = 1–<2 años; v40403 = ≥2 años ***/
	capture confirm variable v40402
	if !_rc {
		replace antiguedad_ci = 1 if emp_ci==1 & v40402 < .
	}
	capture confirm variable v40403
	if !_rc {
		/* Si v40403 ya viene como años (numérica): */
		replace antiguedad_ci = v40403 if emp_ci==1 & v40403 < .
		/* Si v40403 fuera indicador (≥2 años), usar al menos 2:
		   replace antiguedad_ci = 2 if emp_ci==1 & v40403==1 & missing(antiguedad_ci)
		*/
	}

	
	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .
	replace desalent_ci = 1 if condocup_ci == 3 & inlist(v4074, 4, 5)
	replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .

	* Base: horas habituales del trabajo principal (PNADC)
	replace horaspri_ci = v4039 if emp_ci==1 & v4039<.

	* Tratamiento de códigos especiales/inconsistentes (si existieran)
	replace horaspri_ci = . if inlist(v4039, 999, 9999)

	* No ocupados -> missing
	replace horaspri_ci = . if emp_ci==0

	label var horaspri_ci "Horas semanales en la actividad principal"

	* Reglas de consistencia sugeridas por el manual:
	* - No superar 168 horas/semana (24*7)
	replace horaspri_ci = . if horaspri_ci>168 & horaspri_ci<.
		
	***************
	***horastot_ci ***
	***************	
	* Construir lista de variables de horas disponibles en la base
	local _HRS_CANDS v4039 v4041 v4043 v4045 v4047 v4115 v4116 p51a p51b p51c
	local _HRS_LIST
	foreach _v of local _HRS_CANDS {
		cap confirm variable `_v'
		if !_rc local _HRS_LIST `_HRS_LIST' `_v'
	}

	* Suma fila a fila de las horas disponibles (ignora las que no existan)
	egen double horastot_ci = rowtotal(`_HRS_LIST') if emp_ci==1

	* Si todas las componentes están perdidas, dejar como missing
	egen byte _hrs_n = rownonmiss(`_HRS_LIST') if emp_ci==1
	replace horastot_ci = . if emp_ci==1 & _hrs_n==0

	* No ocupados -> missing
	replace horastot_ci = . if emp_ci==0

	* Tratamiento de códigos especiales en componentes (si existieran)
	foreach _v of local _HRS_LIST {
		replace horastot_ci = . if inlist(`_v', 999, 9999)
	}	
		
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .

	* 1) Trabaja menos de 30 horas y NO desea trabajar más (v4063a == 2)
	replace tiempoparc_ci = 1 if emp_ci==1 & horaspri_ci>=1 & horaspri_ci<30 & v4063a==2

	* 0) Resto de ocupados (trabaja ≥30 horas o desea trabajar más)
	replace tiempoparc_ci = 0 if emp_ci==1 & tiempoparc_ci==.

	* Missing para no ocupados
	replace tiempoparc_ci = . if emp_ci==0
		
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	replace categopri_ci = 1 if emp_ci==1 & v4012==5                 // Empregador
	replace categopri_ci = 2 if emp_ci==1 & v4012==6                 // Conta própria
	replace categopri_ci = 3 if emp_ci==1 & inlist(v4012,1,2,3,4)    // Doméstico, Militar, Empregado privado/público
	replace categopri_ci = 4 if emp_ci==1 & v4012==7                 // Familiar no remunerado
	replace categopri_ci = 0 if emp_ci==1 & missing(categopri_ci)
	replace categopri_ci = . if emp_ci==0
	
	***************
	***categosec_ci ***
	***************	
	gen byte categosec_ci = .
	replace categosec_ci = 1 if emp_ci==1 & v4043==5                 // Empregador
	replace categosec_ci = 2 if emp_ci==1 & v4043==6                 // Conta própria
	replace categosec_ci = 3 if emp_ci==1 & inlist(v4043,1,2,3,4)    // Doméstico, Militar, Empregado privado/público
	replace categosec_ci = 4 if emp_ci==1 & v4043==7                 // Não remunerado
	replace categosec_ci = 0 if emp_ci==1 & missing(categosec_ci)
	replace categosec_ci = . if emp_ci==0

	***************
	***rama_ci ***
	***************	
	gen byte rama_ci = .
	replace rama_ci = 1 if emp_ci==1 & v40132a==1   // Agro, pesca, silvicultura…
	replace rama_ci = . if emp_ci==0                 // no ocupados

	***************
	***spublico_ci ***
	***************	
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & v4012 == 4     // Empregado do setor público
	replace spublico_ci = 0 if emp_ci == 1 & v4012 != 4 & v4012 != .
	replace spublico_ci = . if emp_ci == 0
		
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	replace tamemp_ci = 1 if emp_ci==1 & v4012==6
    replace tamemp_ci = 1 if emp_ci==1 & inlist(v4018,1) & (tamemp_ci==.)
    replace tamemp_ci = 2 if emp_ci==1 & inlist(v4018,2,3) & (tamemp_ci==.)
    replace tamemp_ci = 3 if emp_ci==1 & inlist(v4018,4) & (tamemp_ci==.)
	replace tamemp_ci = . if emp_ci==0
	
	***************
	***cotizando_ci***
	***************	
	gen  byte cotizando_ci = .
	replace cotizando_ci = 1 if emp_ci==1 & (v4032==1 | v4049==1 | v4057==1)
	replace cotizando_ci = 0 if emp_ci==1 & cotizando_ci==. & (v4032==2 | v4049==2 | v4057==2)
		
	***************
	***afiliado_ci***
	***************	
	gen  byte afiliado_ci = .
	* (A) Afiliado por declaración de cotización en cualquier trabajo
	replace afiliado_ci = 1 if inlist(1, v4032, v4049, v4057) & emp_ci==1

	* (B) Afiliado por vínculo formal aunque no haya declaración explícita de pago
	replace afiliado_ci = 1 if emp_ci==1 & (v4029==1 | v4048==1)                                  // INSS/RGPS por carteira
	replace afiliado_ci = 1 if emp_ci==1 & (v4012==4 & v4028==1)                                  // RPPS por estatutário

	* (C) No afiliado: ocupados con negativa expresa y sin indicios de afiliación
	replace afiliado_ci = 0 if emp_ci==1 & afiliado_ci==. & ( (v4032==2 | v4049==2 | v4057==2) | (v4029!=1 & v4048!=1 & !(v4012==4 & v4028==1)) )

	* No ocupados: PNADC usualmente no releva afiliación general -> dejar missing
	replace afiliado_ci = . if emp_ci==0
		
	***************
	***instcot_ci***
	***************	
	gen byte instcot_ci = . 
	* RPPS: trabajador del sector público ESTATUTARIO y cotiza
	replace instcot_ci = 2 if cotizando_ci==1 & v4012==4 & v4028==1

	* INSS (RGPS): resto de cotizantes sin evidencia de RPPS
	replace instcot_ci = 1 if cotizando_ci==1 & missing(instcot_ci)
	
	**************
	***formal_ci***
	**************
	gen byte formal_ci = .
	replace formal_ci  =  1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)
	
	*******************
	***tipocontrato_ci***
	*******************
	gen byte tipocontrato_ci = .
	* (1) Permanente / Indefinido:
	*    “Empregado com carteira assinada” o “servidor público estatutário”
	replace tipocontrato_ci = 1 if categopri_ci==3 & (v4029==1 | v4028==1)

	* (2) Temporal / Plazo definido:
	*    “Empregado sem carteira, mas com contrato temporário / prazo determinado”
	replace tipocontrato_ci = 2 if categopri_ci==3 & (v4029==2 & v4056==1)

	* (3) Sin contrato / Verbal:
	*    “Empregado sem carteira e sem contrato formal”
	replace tipocontrato_ci = 3 if categopri_ci==3 & (v4029==2 & (missing(v4056) | v4056==2))
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci = .

	tostring v4010, replace

	/* grupo mayor (primer dígito) y sub-mayor (dos primeros) */
	gen byte g1 = real(substr(v4010,1,1)) if strlen(v4010)>=1
	gen byte g2 = real(substr(v4010,1,2)) if strlen(v4010)>=2

	/* Asignación SCL */
	replace ocupa_ci = 8 if emp_ci==1 & g1==0                           // Fuerzas Armadas
	replace ocupa_ci = 2 if emp_ci==1 & g1==1                           // Directivos
	replace ocupa_ci = 1 if emp_ci==1 & inlist(g1,2,3)                  // Profesionales/técnicos
	replace ocupa_ci = 3 if emp_ci==1 & g1==4                           // Administrativo
	replace ocupa_ci = 4 if emp_ci==1 & g1==5 & g2==52                  // Ventas
	replace ocupa_ci = 5 if emp_ci==1 & g1==5 & g2==51                  // Servicios
	replace ocupa_ci = 5 if emp_ci==1 & g1==5 & missing(ocupa_ci)       // Resto de 5 → Servicios
	replace ocupa_ci = 6 if emp_ci==1 & g1==6                           // Agrícolas
	replace ocupa_ci = 7 if emp_ci==1 & inlist(g1,7,8)                  // Operarios/conductores
	replace ocupa_ci = 9 if emp_ci==1 & g1==9                           // Otras/elementales

	/* No ocupados → missing */
	replace ocupa_ci = . if emp_ci==0

	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	* Recibe pensión contributiva (marcador directo o monto > 0)
	replace pension_ci = 1 if v5004a == 1
	replace pension_ci = 1 if missing(pension_ci) & v5004a2 > 0 & v5004a2 < .

	* No recibe cuando hay negativa explícita o monto 0 con negativa
	replace pension_ci = 0 if v5004a == 2
	replace pension_ci = 0 if missing(pension_ci) & v5004a2 == 0 & v5004a == 2
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
	* Marca como no contributiva si declaró recibir BPC-LOAS o si el monto > 0
	replace pensionsub_ci = 1 if v5001a == 1
	replace pensionsub_ci = 1 if missing(pensionsub_ci) & v5001a2 > 0 & v5001a2 < .

	* No recibe cuando hay negativa explícita
	replace pensionsub_ci = 0 if v5001a == 2
	
	***************
	**tipopen_ci**
	***************
	gen byte tipopen_ci = . 
	replace tipopen_ci = 1 if pension_ci==1
    replace tipopen_ci = 2 if pensionsub_ci==1
	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci = .

	* BPC/LOAS → Assistência Social
	replace instpen_ci = 2 if v5001a==1

	* Previdência (INSS/RPPS) → sistema previdenciário
	replace instpen_ci = 1 if v5004a==1 & missing(instpen_ci)

	* No pensionados -> .
	replace instpen_ci = . if (v5001a!=1 & v5004a!=1) & (missing(pension_ci) & missing(pensionsub_ci))
		

****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
    * Ingreso laboral monetario del trabajo principal
    * PNADC: VD4019 ≈ rendimento efetivo do trabalho principal (R$ mensuales)
    capture drop ylmpri_ci
    generate double ylmpri_ci = . 
    replace  ylmpri_ci = vd4019 if emp_ci==1 & vd4019!=.
    replace  ylmpri_ci = .     if ylmpri_ci<0 & ylmpri_ci!=.

	************
	* ylmsec_ci *
	************
    * Ingreso laboral monetario del/los trabajo(s) secundario(s)
    * Aproximación PNADC: VD4020 (todos los trabajos) – VD4019 (principal)
    capture drop ylmsec_ci
    generate double ylmsec_ci = . 
    replace  ylmsec_ci = vd4020 - vd4019 if emp_ci==1 & vd4020!=. & vd4019!=.
    replace  ylmsec_ci = 0               if ylmsec_ci<0 & ylmsec_ci!=.

    **************
	**************
	* ylmotros_ci *
	**************
    * Otros ingresos laborales monetarios (bonos, comisiones no captadas arriba)
    * PNADC no separa explícitamente; por defecto 0 (ajusta si identificas fuentes)
	generate double ylmotros_ci = 0 if emp_ci==1
 
	*********
	* ylm_ci *
	*********
    * Total laboral monetario: principal + secundarios + otros
    egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
    **************
    * Ingreso laboral NO monetario (en especie) del trabajo principal
    * TODO (PNADC): mapear si hay variable de pagos en productos del trabajo principal
    generate double ylnmpri_ci = . 
    replace  ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
    * Ingreso laboral NO monetario (en especie) del/los trabajos secundarios
    * TODO (PNADC): mapear pagos en especie en trabajos adicionales
    capture drop ylnmsec_ci
    generate double ylnmsec_ci = . 
    replace  ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
    * Otros ingresos laborales NO monetarios (premios en especie, etc.)
    * TODO (PNADC): mapear si existiera
    capture drop ylnmotros_ci
    generate double ylnmotros_ci = . 
    replace  ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
    * Total laboral NO monetario
    capture drop ylnm_ci
    egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
    replace  ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	* Ingreso NO laboral monetario (transferencias, pensiones, capital, remesas en dinero)
    * TODO (PNADC): mapear fuentes individuales; por ahora como missing
    capture drop ynlm_ci
    generate double ynlm_ci = . 
    replace  ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	* Ingreso NO laboral NO monetario (donaciones en especie, remesas en especie)
    * TODO (PNADC): mapear si existiera a nivel individual
    capture drop ynlnm_ci
    generate double ynlnm_ci = . 
    replace  ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .

	**********
	* ytot_ci *
	**********
    * Ingreso total individual
    capture drop ytot_ci
    egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

	*********
	* ylm_ch *
	*********
    bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1

	**********
	* ylnm_ch *
	**********
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1

	*********
	* ynlm_ch *
	*********
    * TODO (PNADC): si mapeas ynlm_ci a nivel individuo, esta suma se activará
    capture drop ynlm_ch
    bysort idh_ch: egen double ynlm_ch = total(ynlm_ci) if miembros_ci==1
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
    generate double ylmhopri_ci = ylmpri_ci / horaspri_ci if emp_ci==1 & horaspri_ci>0
 
	**********
	* ylmho_ci *
	**********
    generate double ylmho_ci = ylm_ci / horastot_ci if emp_ci==1 & horastot_ci>0
  
	**************
	* nrylmpri_ci *
	**************
    generate byte nrylmpri_ci = (emp_ci==1 & ylmpri_ci==.)

	**************
	* nrylmpri_ch *
	**************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci==1

	*************
	* remesas_ci *
	*************
    * TODO (PNADC): mapear remesas monetarias individuales si existen (p.ej., “dinheiro do exterior” a nivel pessoa)
    capture drop remesas_ci
    generate double remesas_ci = .

	*************
	* remesas_ch *
	*************
    * TODO (PNADC): si remesas_ci se captura a nivel persona, sumar al hogar
    capture drop remesas_ch
    bysort idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci==1

	**********
	* ypen_ci *
	**********
    generate double ypen_ci = . if pension_ci==1

	*************
	* ypensub_ci *
	*************
    generate double ypensub_ci = . if pensionsub_ci==1
	
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
