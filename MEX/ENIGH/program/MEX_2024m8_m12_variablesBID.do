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

local PAIS MEX
local ENCUESTA ENIGH
local ANO "2024"
local ronda m8_m12

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Mexico
Encuesta: ENIGH (tradicional)
Round: Agosto-Diciembre
Autores: Maria Alejandra Zegarra (SCL) - Email: mariale.zegarra@gmail.com, 25 de setiembre de 2025
Versión: 25 de setiembre 2025 
****************************************************************************
							SCL/LMK - IADB
****************************************************************************/
use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_c=real(substr(ubica_geo,1,2))
	label define region_c ///
	1 "Aguascalientes" ///
	2 "Baja California" ///
	3 "Baja California Sur" ///
	4 "Campeche" ///
	5 "Coahuila de Zaragoza" ///
	6 "Colima" ///
	7 "Chiapas" ///
	8 "Chihuahua" ///
	9 "Ciudad de México" /// 
	10 "Durango" ///
	11 "Guanajuato" ///
	12 "Guerrero" ///
	13 "Hidalgo" ///
	14 "Jalisco" ///
	15 "México" ///
	16 "Michoacán de Ocampo" ///
	17 "Morelos" ///
	18 "Nayarit" ///
	19 "Nuevo León" ///
	20 "Oaxaca" ///
	21 "Puebla" ///
	22 "Querétaro" ///
	23 "Quintana Roo" ///
	24 "San Luis Potosí" ///
	25 "Sinaloa" ///
	26 "Sonora" ///
	27 "Tabasco" ///
	28 "Tamaulipas" ///
	29 "Tlaxcala" ///
	30 "Veracruz de Ignacio de la Llave" ///
	31 "Yucatán" ///
	32 "Zacatecas" 
	label value region_c region_c
	label var region_c "division politico-administrativa, estados"

	******************************
	*	pais_c
	******************************
	gen str3 pais_c="MEX"

	*****************
	*** region según BID ***
	*****************
	gen region_BID_c = .
	replace region_BID_c = 1 if pais_c=="MEX"   // 1 = México, región Centroamérica según BID

	******************************
	*	anio_c
	******************************
	gen int anio_c=2024

	******************************
	*	mes_c
	******************************
	gen int mes_c= .

	******************************
	*	zona_c
	******************************
	gen byte zona_c = .
	replace zona_c = 1 if substr(folioviv,3,1)!="6" & !missing(folioviv)
	replace zona_c = 0 if substr(folioviv,3,1)=="6"

	***************
	***estrato_ci***
	***************
	gen estrato_ci=est_dis

	***************
	***upm_ci***
	***************
	gen upm_ci=upm

	******************************
	*	idh_ch
	******************************
	sort  folioviv foliohog 
	egen idh_ch= group(folioviv foliohog)
	tostring idh_ch, replace

	******************************
	*	idp_ci
	******************************
	destring numren, replace
	gen idp_ci=numren
	tostring idp_ci, replace

	******************************
	*	factor_ch
	******************************
	gen factor_ch=factor

	******************************
	*	factor_ci
	******************************
	gen factor_ci=factor
	
******************************************************************************
*	DEMOGRAPHIC VARIABLES
******************************************************************************
	**************************
	*	sexo_ci
	******************************
	gen sexo_ci=real(sexo)

	******************************
	*	edad_ci
	******************************
	gen edad_ci=edad 

	******************************
	*	relacion_ci
	******************************
	gen relacion_ci=.
	replace relacion_ci=1 if parentesco=="101" | parentesco=="102"
	replace relacion_ci=2 if parentesco>="201" & parentesco<="205"
	replace relacion_ci=3 if parentesco>="301" & parentesco<="305"
	replace relacion_ci=4 if parentesco>="601" & parentesco<="623"
	replace relacion_ci=5 if (parentesco>="501" & parentesco <="503") | (parentesco>="701" & parentesco<="715")
	replace relacion_ci=6 if parentesco>="401" & parentesco<="461"
	replace relacion_ci=. if parentesco=="999" | parentesco=="."

	******************************
	*	miembros_ci
	******************************
	gen byte miembros_ci = (relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci = . if relacion_ci==.	
	
	******************************
	*	miembros_one_ci
	******************************
	gen byte miembros_one_ci = 1
    replace miembros_one_ci = inrange(relacion_ci,1,5) if relacion_ci<.
	
	******************************
	*	civil_ci
	******************************
	gen civil_ci=.
	replace civil_ci=1 if edo_cony=="6"
	replace civil_ci=2 if edo_cony=="1"|edo_cony=="2"
	replace civil_ci=3 if edo_cony=="3"|edo_cony=="4"
	replace civil_ci=4 if edo_cony=="5"

	******************************
	*	jefe_ci
	******************************
	gen jefe_ci=(relacion_ci==1)
	
	***************************************************************************
	*	nconyuges_ch & nhijos_ch & notropari_ch & notronopari_ch & nempdom_ch
	****************************************************************************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
	by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
	by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)

	******************************
	*	clasehog_ch
	******************************
	gen clasehog_ch=.
	replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
	replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
	replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	***************************************************************************************
	*	nmiembros_ch & nmayor21_ch & nmenor21_ch & nmayor65_ch & nmenor6_ch & nmenor1_ch  
	***************************************************************************************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))

*****************************
***VARIABLES DE DIVERSIDAD***
*****************************
	*********
	* afro_ci
	*********
	gen byte afro_ci = .
	destring afrod, replace
	replace afro_ci = 1 if afrod == 1
	replace afro_ci = 0 if afrod == 2

	********
	* ind_ci   
	********
	gen byte ind_ci = .
	destring etnia, replace
	replace ind_ci = 1 if etnia == 1
	replace ind_ci = 0 if etnia== 2

	************
	* afroind_ci 
	************
	gen byte afroind_ci = .
	replace afroind_ci = 1 if afro_ci==1 | ind_ci==1
	replace afroind_ci = 0 if afro_ci==0 & ind_ci==0
	
	****************
	* noafroind_ci  
	****************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1

	*********
	* afro_ch 
	*********
	gen  byte _afro_j = afro_ci     if jefe_ci==1
	egen byte afro_ch = max(_afro_j), by(idh_ch)
	drop _afro_j

	********
	* ind_ch 
	********
	gen  byte _ind_j = ind_ci       if jefe_ci==1
	egen byte ind_ch  = max(_ind_j), by(idh_ch)
	drop _ind_j

	****************
	* noafroind_ch 
	****************
	gen  byte _noai_j = noafroind_ci if jefe_ci==1
	egen byte noafroind_ch = max(_noai_j), by(idh_ch)
	drop _noai_j

	************
	* afroind_ch 
	************
	gen  byte _aind_j = afroind_ci  if jefe_ci==1
	egen byte afroind_ch = max(_aind_j), by(idh_ch)
	drop _aind_j
	
	****************
	* afroind_ano_c
	****************
	gen int afroind_ano_c = 2024

	********
	* dis_ci 
	********
	gen byte dis_ci = .
	local wg disc_ver disc_oir disc_brazo disc_camin disc_apren disc_vest disc_habla disc_acti
	foreach v of local wg {
		replace `v' = "" if `v' == "&"
		destring `v', replace
		}
		
	replace dis_ci = 1 if inlist(disc_ver,2,3,4)  | inlist(disc_oir,2,3,4)   | ///
						 inlist(disc_brazo,2,3,4) | inlist(disc_camin,2,3,4) | ///
						 inlist(disc_apren,2,3,4) | inlist(disc_vest,2,3,4)  | ///
						 inlist(disc_habla,2,3,4) | inlist(disc_acti,2,3,4)

	replace dis_ci = 0 if dis_ci==. & ///
		disc_ver==1 & disc_oir==1 & disc_brazo==1 & disc_camin==1 & ///
		disc_apren==1 & disc_vest==1 & disc_habla==1 & disc_acti==1

	
	**********
	* disWG_ci 
	**********
	gen byte disWG_ci = .
	replace disWG_ci = 1 if inlist(disc_ver,3,4)  | inlist(disc_oir,3,4)   | ///
							inlist(disc_brazo,3,4)| inlist(disc_camin,3,4) | ///
							inlist(disc_apren,3,4)| inlist(disc_vest,3,4)  | ///
							inlist(disc_habla,3,4)| inlist(disc_acti,3,4)

	replace disWG_ci = 0 if disWG_ci==. & ///
		inlist(disc_ver,1,2)   & inlist(disc_oir,1,2)   & inlist(disc_brazo,1,2) & ///
		inlist(disc_camin,1,2) & inlist(disc_apren,1,2) & inlist(disc_vest,1,2)  & ///
		inlist(disc_habla,1,2) & inlist(disc_acti,1,2)

						  
	********
	* dis_ch 
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	******************
	* ISOalpha3_dis_ci 
	******************
	gen byte MEX_dis_ci = dis_ci
	
****************************
***VARIABLES DE MERCADO LABORAL***
* NOTA: Actualmente se está revisando el manual
****************************

****************************
***VARIABLES DE INGRESO***
* NOTA: SE SIGUE REVISANDO EL MANUAL
****************************

****************************
***VARIABLES DE EDUCACION***
****************************
	* Matriculación actual (nivel/grado)
	local L_PRE    1   // Preescolar
	local L_PRIM   2   // Primaria
	local L_SEC1   3   // Secundaria
	local L_SEC2   4   // Preparatoria/Bachillerato
	local L_SUPT   5   // Técnico superior (terciario)
	local L_GRAD   6   // Licenciatura/Profesional
	local L_MAEST  7   // Maestría
	local L_DOCT   8   // Doctorado

	* Máximo nivel APROBADO (nivelaprob) — declara el catálogo que usas
	local LAP_PRE     1   // Preescolar aprobado
	local LAP_PRIM    2   // Primaria aprobada
	local LAP_SEC1    3   // Secundaria aprobada
	local LAP_SEC2    4   // Prepa/Bachi aprobado
	local LAP_SUPT    5   // Técnico superior aprobado
	local LAP_PROF    6   // Normal/Profesorado (si aplica) aprobado
	local LAP_GRAD    7   // Licenciatura/Profesional aprobada
	local LAP_MAEST   8   // Maestría aprobada
	local LAP_DOCT    9   // Doctorado aprobado
	local LAP_POSDOC  10  // Posdoc (si existe en tu catálogo)

	* Duraciones (ISCED para México)
	local Y_PRIM  6
	local Y_SEC1  3
	local Y_SEC2  3
	local Y_SUPT  2
	local Y_GRAD  4
	local Y_MAEST 3
	local Y_DOCT  3

	foreach v in nivel grado nivelaprob antec_esc gradoaprob asis_esc tipoesc no_asisb {
		capture confirm numeric variable `v'
		if _rc destring `v', replace force
	}

	***********
	*asiste_ci*
	***********
	capture drop asiste_ci
	gen byte asiste_ci = .
	replace asiste_ci = 1 if asis_esc==1
	replace asiste_ci = 0 if asis_esc==2

	***********
	*aedu_ci*
	***********
	tempvar lev use_grd term_use
	gen double aedu_ci = .

	* Si está estudiando: usa nivel/grado; si no: nivelaprob/gradoaprob
	gen byte `lev'    = cond(asiste_ci==1, nivel,     nivelaprob)
	gen      `use_grd'= cond(asiste_ci==1, grado,     gradoaprob)

	* 0 años: preescolar cuenta 0; (opcional: menores de 2 años=0)
	replace aedu_ci = 0 if `lev'==`L_PRE'
	* (opcional) replace aedu_ci = 0 if edad_ci<2 & edad_ci<.

	* “Terminó nivel” por tope de grados
	gen byte `term_use' = .
	replace `term_use' = 1 if (`lev'==`L_PRIM'  & `use_grd'>=`Y_PRIM')  | ///
							(`lev'==`L_SEC1'  & `use_grd'>=`Y_SEC1')  | ///
							(`lev'==`L_SEC2'  & `use_grd'>=`Y_SEC2')  | ///
							(`lev'==`L_SUPT'  & `use_grd'>=`Y_SUPT')  | ///
							(`lev'==`L_GRAD'  & `use_grd'>=`Y_GRAD')  | ///
							(`lev'==`L_MAEST' & `use_grd'>=`Y_MAEST') | ///
							(`lev'==`L_DOCT'  & `use_grd'>=`Y_DOCT')
	replace `term_use' = 0 if missing(`term_use') & `lev'<. & `use_grd'<.

	* Suma acumulada por tramo
	replace aedu_ci = 0                                               if `lev'==`L_PRE'
	replace aedu_ci = min(max(`use_grd',0),`Y_PRIM')                  if `lev'==`L_PRIM'  & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM'                                        if `lev'==`L_PRIM'  & `term_use'==1
	replace aedu_ci = `Y_PRIM' + min(max(`use_grd',0),`Y_SEC1')       if `lev'==`L_SEC1'  & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1'                             if `lev'==`L_SEC1'  & `term_use'==1
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + min(max(`use_grd',0),`Y_SEC2') if `lev'==`L_SEC2' & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2'                  if `lev'==`L_SEC2'  & `term_use'==1
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + min(max(`use_grd',0),`Y_SUPT') if `lev'==`L_SUPT' & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_SUPT'       if `lev'==`L_SUPT' & `term_use'==1
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + min(max(`use_grd',0),`Y_GRAD') if `lev'==`L_GRAD' & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD'       if `lev'==`L_GRAD' & `term_use'==1
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + min(max(`use_grd',0),`Y_MAEST') if `lev'==`L_MAEST' & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST'                    if `lev'==`L_MAEST' & `term_use'==1
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' + min(max(`use_grd',0),`Y_DOCT') if `lev'==`L_DOCT' & `term_use'==0 & `use_grd'<.
	replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' + `Y_DOCT'                       if `lev'==`L_DOCT' & `term_use'==1

	replace aedu_ci = floor(aedu_ci)
	replace aedu_ci = 0 if aedu_ci<0

	* QA manual
	local TOPE = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' + `Y_DOCT'
	assert inrange(aedu_ci,0,`TOPE') if aedu_ci<.
	assert aedu_ci==floor(aedu_ci)   if aedu_ci<.

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = .
	replace eduui_ci = ///
		  (aedu_ci>12 & aedu_ci<16 & nivelaprob==`LAP_SUPT')  | ///
		  (aedu_ci>12 & aedu_ci<17 & nivelaprob==`LAP_GRAD')  | ///
		  (aedu_ci>12 & aedu_ci<15 & nivelaprob==`LAP_PROF' & inlist(`antec_num',2,3))

	**********
	*eduuc_ci*
	**********	
	gen byte eduuc_ci = .
	replace eduuc_ci = ///
		((aedu_ci>=16) & nivelaprob==`LAP_SUPT')              | ///
		((aedu_ci>=17) & nivelaprob==`LAP_GRAD')              | ///
		((aedu_ci>=15) & nivelaprob==`LAP_PROF' & inlist(antec_esc,2,3))  | ///
		inlist(nivelaprob, `LAP_MAEST', `LAP_DOCT', `LAP_POSDOC')
	replace eduuc_ci = . if aedu_ci==.
	
	**********
	*eduac_ci*
	**********
	gen byte eduac_ci = .
	capture drop eduac_ci
	gen byte eduac_ci = .
	replace eduac_ci = 1 if inlist(nivelaprob, `LAP_GRAD', `LAP_MAEST', `LAP_DOCT', `LAP_POSDOC')
	replace eduac_ci = 0 if inlist(nivelaprob, `LAP_SUPT', `LAP_PROF')
	replace eduac_ci = . if aedu_ci==.

	***********
	*edupre_ci*
	************
	gen byte edupre_ci = .
	replace edupre_ci = 1 if nivelaprob==`LAP_PRE' & gradoaprob>=1
	replace edupre_ci = 0 if edupre_ci==. & (asiste_ci<.|nivelaprob<.)
	
	************
	*asispre_ci*
	************
	capture drop asispre_ci edupre_ci
	gen byte asispre_ci = .
	replace asispre_ci = 1 if asiste_ci==1 & nivel==`L_PRE'
	replace asispre_ci = 0 if asiste_ci==1 & nivel!=`L_PRE'
	replace asispre_ci = . if asiste_ci==0
	
	*************
	*pqnoasis1_ci*
	**************
	capture drop pqnoasis1_ci
	gen byte pqnoasis1_ci = .
	replace pqnoasis1_ci = 1 if inlist(no_asisb, 4, 9)          // económicos / trabajo
	replace pqnoasis1_ci = 2 if inlist(no_asisb, 5)             // desinterés / rendimiento
	replace pqnoasis1_ci = 3 if inlist(no_asisb, 6, 7, 12)      // cuidado/embarazo/salud
	replace pqnoasis1_ci = 4 if inlist(no_asisb, 10, 11, 3)     // acceso/infra/horarios
	replace pqnoasis1_ci = 5 if inlist(no_asisb, 1, 2, 8, 13)   // otros
	replace pqnoasis1_ci = . if no_asisb==99 | asiste_ci==1     // no aplica si asiste

	***********
	*edupub_ci*
	***********
	capture drop edupub_ci
	gen byte edupub_ci = .
	replace edupub_ci = 1 if tipoesc==1 & asiste_ci==1
	replace edupub_ci = 0 if tipoesc==2 & asiste_ci==1
	replace edupub_ci = . if asiste_ci!=1
	
****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	capture confirm numeric variable disp_elect
	if _rc destring disp_elect, replace force	
	
	gen byte luz_ch     = .
	replace luz_ch     = 1 if disp_elect==1
	replace luz_ch     = 0 if disp_elect==2
	
	***********
	*luzmide_ch*
	***********
	capture confirm numeric variable medid_luz
	if _rc destring medid_luz, replace force	
	
	gen byte luzmide_ch = .
	replace luzmide_ch = 1 if medid_luz==1
	replace luzmide_ch = 0 if medid_luz==2

	***********
	*combust_ch*
	***********
	destring combus, replace force
	gen combust_ch=.
	replace combust_ch=1 if combus==3 | combus==4 | combus==5
	replace combust_ch=0 if combus==1 | combus ==2 | combus==6
	
	***********
	*piso_ch*
	***********
	gen byte piso_ch  = .
		
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	
	***********
	*resid_ch*
	***********
	destring eli_ba, replace
	gen resid_ch=.
	replace resid_ch=0 if eli_ba==1 | eli_ba==2 | eli_ba==3
	replace resid_ch=1 if eli_ba==4 | eli_ba==5
	replace resid_ch=2 if eli_ba==6 | eli_ba==7
	replace resid_ch=3 if eli_ba==8

	******************************
	*	dorm_ch
	******************************
	gen dorm_ch=cuart_dorm

	******************************
	*	cuartos_ch
	******************************
	gen cuartos_ch=num_cuarto 

	******************************
	*	cocina_ch
	******************************
	destring cocina, replace
	gen cocina_ch=.
	replace cocina_ch=1 if cocina==1
	replace cocina_ch=0 if cocina==2

	******************************
	*	telef_ch
	******************************
	gen telef_ch=(telefono=="1")

	******************************
	*	refrig_ch
	******************************
	destring num_refri, replace
	gen refrig_ch= .
	replace refrig_ch= 0 if num_refri ==0
	replace refrig_ch= 1 if num_refri>=1

	******************************
	*	freez_ch
	******************************
	gen freez_ch=.

	******************************
	*	auto_ch
	******************************
	destring num_auto num_van num_pic, replace 
	gen auto_ch=.
	replace auto_ch = 0 if  num_auto==0 & num_van==0 & num_pic==0
	replace auto_ch = 1 if num_auto>=1 | num_van>=1 | num_pic>=1

	******************************
	*	compu_ch
	******************************
	gen compu_ch = (num_compu>0)

	******************************
	*	internet_ch
	******************************
	gen internet_ch=(conex_inte=="1")
	
	******************************
	*	cel_ch
	******************************
	gen cel_ch=(celular=="1") 

	******************************
	*	vivi1_ch
	******************************
	gen vivi1_ch=.
	replace vivi1_ch=1 if tipo_viv =="1"
	replace vivi1_ch=2 if tipo_viv =="2"
	replace vivi1_ch=3 if tipo_viv >="3"

	******************************
	*	viviprop_ch
	******************************
	destring tenencia, replace
	gen viviprop_ch=.
	replace viviprop_ch = 1 if tenencia==1   // propia
	replace viviprop_ch = 2 if tenencia==2   // alquilada
	replace viviprop_ch = 0 if tenencia==3   // cedida/otra
	replace viviprop_ch = 3 if !inlist(tenencia,1,2,3) & tenencia<.

	******************************
	*	vivitit_ch
	******************************
	destring escrituras, replace 
	gen vivitit_ch=.
	replace vivitit_ch  = 1 if escrituras==1
	replace vivitit_ch  = 0 if escrituras==2

	******************************
	*	vivialq_ch
	******************************
	gen vivialq_ch= renta
	replace vivialq_ch    = renta           if renta<.

	******************************
	*	vivialqimp_ch
	******************************
	gen vivialqimp_ch=estim_pago
	replace vivialqimp=0 if estim_pago<0
	replace vivialqimp_ch = estim_pago      if estim_pago<.   

****************************
***VARIABLES DE WASH***
****************************
	****************
	***aguared_ch***
	****************
	destring agua_ent , replace
	gen aguared_ch=.
	replace aguared_ch=1 if agua_ent ==1 | agua_ent ==2
	replace aguared_ch=0 if agua_ent >=3 & agua_ent <=6

	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = 0

	*****************
	*aguafuente_ch*
	*****************
	destring ab_agua , replace
	gen aguafuente_ch = 0
	replace aguafuente_ch = 1 if (ab_agua==1 | ab_agua==2)
	replace aguafuente_ch = 2 if ab_agua==3
	replace aguafuente_ch = 5 if ab_agua==4
	replace aguafuente_ch = 7 if ab_agua==5
	replace aguafuente_ch = 6 if ab_agua==6
	replace aguafuente_ch = 10 if ab_agua==7 

	*************
	*aguadist_ch*
	*************
	gen aguadist_ch=0
	replace aguadist_ch= 1 if aguafuente_ch==1
	replace aguadist_ch= 2 if aguafuente_ch==2
	replace aguadist_ch= 3 if inlist(aguafuente_ch, 3,4,5,6,7,9,10) 
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.

	**************
	*aguadisp1_ch*
	**************
	destring dotac_agua, replace
	gen aguadisp1_ch =9

	**************
	*aguadisp2_ch*
	**************
	destring dotac_agua, replace
	gen aguadisp2_ch = .
	replace aguadisp2_ch = 1 if dotac_agua>1
	replace aguadisp2_ch = 3 if dotac_agua==1

	*************
	*aguatrat_ch*
	*************
	gen aguatrat_ch =9

	*************
	*aguamala_ch*  
	*************
	gen aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

	*****************
	*aguamejorada_ch*  
	*****************
	gen aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7 

	*****************
	***aguamide_ch***
	*****************
	gen aguamide_ch=.

	*****************
	*bano_ch         *
	*****************
	destring excusado, replace
	destring drenaje, replace
	destring sanit_agua, replace
	gen bano_ch=.
	replace bano_ch=0 if excusado==2
	replace bano_ch=1 if drenaje==1 & excusado==1 
	replace bano_ch=2 if drenaje==2 & excusado==1 
	replace bano_ch=4 if (drenaje==4 | drenaje==3) & excusado==1
	replace bano_ch=6 if drenaje==5 & excusado==1 & sanit_agua== 3

	***************
	***banoex_ch***
	***************
	destring uso_compar, replace
	gen banoex_ch=.
	replace banoex_ch=1 if uso_compar==2
	replace banoex_ch=0 if uso_compar==1

	************
	*sinbano_ch*
	************
	gen sinbano_ch = 3
	replace sinbano_ch = 0 if excusado == 1
	replace sinbano_ch = 1 if excusado == 2 & drenaje <=4
	replace sinbano_ch = 3 if excusado == 2 & drenaje ==5

	*****************
	*banomejorado_ch*  Altered
	*****************
	gen banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
		
****************************
***VARIABLES DE MIGRACIÓN***
****************************		
	*******************
	*** migrante_ci ***
	*******************
	gen byte migrante_ci = .
	capture confirm numeric variable pais_nac
	if !_rc {
		replace migrante_ci = 1 if pais_nac!=484 & pais_nac<.
		replace migrante_ci = 0 if pais_nac==484
	}
	else {
		replace migrante_ci = 1 if lower(trim(pais_nac))!="mexico" & pais_nac!=""
		replace migrante_ci = 0 if lower(trim(pais_nac))=="mexico"	
		}
		
	**********************
	*** migantiguo5_ci ***
	**********************
	gen byte migrantiguo5_ci = .
	destring residencia, replace
    replace migrantiguo5_ci = 0 if inrange(residencia,1,32)
    replace migrantiguo5_ci = 1 if inlist(residencia,33,34)	
	
	**********************
	*** migrantelac_ci ***
	**********************
	local LAC "32 68 76 152 170 188 214 218 222 320 340 484 558 591 600 604 858 862 192 328 388 308 44 84 212 500 780 740 533"

	capture drop migrantelac_ci
	gen byte migrantelac_ci = .
	capture confirm numeric variable pais_nac
	if !_rc {
		replace migrantelac_ci = 1 if inlist(pais_nac, `LAC') & pais_nac!=484
		replace migrantelac_ci = 0 if pais_nac==484 | (!inlist(pais_nac, `LAC') & pais_nac<.)
	}
	
	**********************
	*** miglac_ci ***
	**********************
	gen byte miglac_ci = .
	capture confirm numeric variable pais5
	if !_rc {
		replace miglac_ci = 1 if inlist(pais5, `LAC') & pais5!=484
		replace miglac_ci = 0 if pais5==484 | (!inlist(pais5, `LAC') & pais5<.)
	}

****************************
***VARIABLES DE EXTERNAS***
****************************
	****************
	* bienestar_agregado *
	****************	
	tempvar ytri_h gtri_h ymon_h gmon_h
	gen double `ytri_h' = .
	foreach y in ing_cor ing_cor_tri ing_tri ingtot_tri {
		capture confirm variable `y'
		if !_rc replace `ytri_h' = `y' if missing(`ytri_h')
	}
	gen double `gtri_h' = .
	foreach g in gasto_mon_tri gasto_tri gtot_tri {
		capture confirm variable `g'
		if !_rc replace `gtri_h' = `g' if missing(`gtri_h')
	}
	gen double `gmon_h' = .
	foreach gm in gasto_mon gmon g_mensual {
		capture confirm variable `gm'
		if !_rc replace `gmon_h' = `gm' if missing(`gmon_h')
	}

	gen double `ymon_h' = .
	replace `ymon_h' = `ytri_h'/3 if `ytri_h'<.
	replace `ymon_h' = `gmon_h'   if missing(`ymon_h') & `gmon_h'<.
	replace `ymon_h' = `gtri_h'/3 if missing(`ymon_h') & `gtri_h'<.

	capture drop bienestar_agregado
	gen double bienestar_agregado = `ymon_h'/nmiembros_ch
	replace bienestar_agregado = . if nmiembros_ch<=0 | missing(nmiembros_ch)

	****************
	* lpe_ci *
	****************	
	* LÍNEAS CONEVAL 2024 (dic-2024, mensual pc) – embebidas por ZONA
	* Valores: LPE (U: 2363.67, R: 1799.71)
	gen double lpe_ci = .
	replace lpe_ci = 1799.71 if zona_c==0
	replace lpe_ci = 2363.67 if zona_c==1
	
	****************
	* ln_ci *
	****************	
	* Valores: LN (U: 4640.16, R: 3334.24)\
	gen double ln_ci  = .
	replace ln_ci  = 3334.24 if zona_c==0
	replace ln_ci  = 4640.16 if zona_c==1

	****************
	* pobre_ine _ci*
	****************	
	capture drop pobre_ine_ci tipo_bienestar
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci = 1 if bienestar_agregado < ln_ci  & bienestar_agregado<. & ln_ci<.
	replace pobre_ine_ci = 0 if bienestar_agregado >= ln_ci & bienestar_agregado<. & ln_ci<.

	****************
	*tipo_bienestar*
	****************	
	gen byte tipo_bienestar = .
	replace tipo_bienestar = 2 if pobre_ine_ci==1      // 2=Pobre
	replace tipo_bienestar = 1 if pobre_ine_ci==0      // 1=No pobre

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
     
   
saveold "`base_out'", version(12) replace

cap log close
