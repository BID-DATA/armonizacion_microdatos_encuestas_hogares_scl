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
	9 "Distrito Federal" ///
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

	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	******************************
	*	anio_c
	******************************
	gen int anio_c=2022
	label var anio_c "Year of the survey"

	******************************
	*	mes_c
	******************************
	gen int mes_c= .

	******************************
	*	zona_c
	******************************
	gen zona_c= 1      if tam_loc<="3"
	replace zona_c = 0 if tam_loc=="4"
	label variable zona_c "Zona del pais"
	label define zona_c 1 "Urbana" 0 "Rural", add modify
	label value zona_c zona_c

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
	label var idh_ch "ID del hogar"
	tostring idh_ch, replace

	******************************
	*	idp_ci
	******************************
	destring numren, replace
	gen idp_ci=numren
	label var idp_ci "ID de la persona en el hogar"
	tostring idp_ci, replace

	******************************
	*	factor_ci
	******************************
	gen factor_ci=factor
	label var factor_ci "Individual Expansion Factor"

	******************************
	*	factor_ch
	******************************
	gen factor_ch=factor
	label var factor_ch "Household Expansion Factor"

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
	label var relacion_ci "Relacion con el jefe del hogar"
	label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes" 6 "Empleado/a domestico/a"
	label value relacion_ci relacion_ci

	******************************
	*	civil_ci
	******************************
	gen civil_ci=.
	replace civil_ci=1 if edo_cony=="6"
	replace civil_ci=2 if edo_cony=="1"|edo_cony=="2"
	replace civil_ci=3 if edo_cony=="3"|edo_cony=="4"
	replace civil_ci=4 if edo_cony=="5"
	label var civil_ci "Estado civil"
	label define civil_ci 1 "Soltero" 2 "Union formal o informal" 3 "Divorciado o separado" 4 "Viudo"
	label value civil_ci civil_ci

	******************************
	*	jefe_ci
	******************************
	gen jefe_ci=(relacion_ci==1)
	label var jefe_ci "Jefe de hogar"

	***************************************************************************
	*	nconyuges_ch & nhijos_ch & notropari_ch & notronopari_ch & nempdom_ch
	****************************************************************************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
	by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
	by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
	label var nconyuges_ch "Numero de conyuges"
	label var nhijos_ch "Numero de hijos"
	label var notropari_ch "Numero de otros familiares"
	label var notronopari_ch "Numero de no familiares"
	label var nempdom_ch "Numero de empleados domesticos"

	******************************
	*	clasehog_ch
	******************************
	gen clasehog_ch=.
	replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
	replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
	replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
	label var clasehog_ch "Tipo de hogar"
	label define clasehog_ch 1 "Unipersonal" 2 "Nuclear" 3 "Ampliado" 4 "Compuesto" 5 "Corresidente"
	label value clasehog_ch clasehog_ch

	***************************************************************************************
	*	nmiembros_ch & nmayor21_ch & nmenor21_ch & nmayor65_ch & nmenor6_ch & nmenor1_ch  
	***************************************************************************************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	label var nmiembros_ch "Numero de familiares en el hogar"

	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
	label var nmayor21_ch "Numero de familiares mayores a 21 anios"

	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
	label var nmenor21_ch "Numero de familiares menores a 21 anios"

	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
	label var nmayor65_ch "Numero de familiares mayores a 65 anios"

	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
	label var nmenor6_ch "Numero de familiares menores a 6 anios"

	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
	label var nmenor1_ch "Numero de familiares menores a 1 anio"

	******************************
	*	miembros_ci
	******************************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	label var miembros_ci "Miembro del hogar"

*****************************
***VARIABLES DE DIVERSIDAD***
*****************************
	*********
	* afro_ci
	*********
	capture confirm variable afro_ci
	if _rc gen byte afro_ci = .     
	label var afro_ci "Autoidentificación afrodescendiente (1 sí, 0 no, . ns/nr)"

	********
	* ind_ci   
	********
	capture confirm variable ind_ci
	if _rc gen byte ind_ci = .     
	label var ind_ci "Autoidentificación indígena (1 sí, 0 no, . ns/nr)"

	****************
	* noafroind_ci  
	****************
	capture confirm variable noafroind_ci
	if _rc gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if inlist(afro_ci,1) | inlist(ind_ci,1)
	label var noafroind_ci "No afro ni indígena (1 sí, 0 no, . ns/nr)"

	************
	* afroind_ci 
	************
	capture confirm variable afroind_ci
	if _rc gen byte afroind_ci = .
	replace afroind_ci = 1 if inlist(afro_ci,1) | inlist(ind_ci,1)
	replace afroind_ci = 0 if afro_ci==0 & ind_ci==0
	label var afroind_ci "Afro o indígena (1 sí, 0 no, . ns/nr)"

	* Alias opcional si tu diccionario espera 'indi_ci' además de 'ind_ci'
	capture confirm variable indi_ci
	if _rc {
		gen byte indi_ci = ind_ci
		label var indi_ci "Autoidentificación indígena (alias de ind_ci)"
	}
	*********
	* afro_ch (característica del/la jefe/a)
	*********
	gen byte afro_jefe = afro_ci if jefe_ci==1
	egen byte afro_ch  = max(afro_jefe), by(idh_ch)
	drop afro_jefe
	label var afro_ch "Jefe/a afro (1 sí, 0 no, . ns/nr)"

	********
	* ind_ch (característica del/la jefe/a)
	********
	gen byte ind_jefe = ind_ci if jefe_ci==1
	egen byte ind_ch  = max(ind_jefe), by(idh_ch)
	drop ind_jefe
	label var ind_ch "Jefe/a indígena (1 sí, 0 no, . ns/nr)"

	****************
	* noafroind_ch (característica del/la jefe/a)
	****************
	gen byte noafroind_jefe = noafroind_ci if jefe_ci==1
	egen byte noafroind_ch  = max(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe
	label var noafroind_ch "Jefe/a no afro ni indígena (1 sí, 0 no, . ns/nr)"

	************
	* afroind_ch (característica del/la jefe/a)
	************
	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen byte afroind_ch  = max(afroind_jefe), by(idh_ch)
	drop afroind_jefe
	label var afroind_ch "Jefe/a afro o indígena (1 sí, 0 no, . ns/nr)"

	********
	* dis_ci 
	********
	capture confirm variable dis_ci
	if _rc gen byte dis_ci = . 
	label var dis_ci "Tiene discapacidad (1 sí, 0 no, . ns/nr)"

	**********
	* disWG_ci 
	**********
	capture confirm variable disWG_ci
	if _rc gen byte disWG_ci = .
	label var disWG_ci "Discapacidad (WG-SS derivada; 1 sí, 0 no, . ns/nr)"

	********
	* dis_ch 
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch)
	label var dis_ch "Algún miembro con discapacidad en el hogar (1 sí, 0 no)"

	******************
	* ISOalpha3_dis_ci 
	******************
	capture confirm variable MEX_dis_ci
	if _rc gen byte MEX_dis_ci = dis_ci
	label var MEX_dis_ci "Discapacidad (dic.) — ISO3=MEX (alias país-específico)"

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
	label var asiste_ci "Asiste actualmente a centro educativo (=1)"

	***********
	*aedu_ci*
	***********
	tempvar lev use_grd term_use
	gen double aedu_ci = .
	label var aedu_ci "Años de educación aprobados (armonizado)"

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
	label var eduui_ci "Educación superior universitaria incompleta (criterio MEX)"

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
	label var eduuc_ci "Educación superior universitaria completa (criterio MEX)"
	
	**********
	*eduac_ci*
	**********
	gen byte eduac_ci = .
	capture drop eduac_ci
	gen byte eduac_ci = .
	replace eduac_ci = 1 if inlist(nivelaprob, `LAP_GRAD', `LAP_MAEST', `LAP_DOCT', `LAP_POSDOC')
	replace eduac_ci = 0 if inlist(nivelaprob, `LAP_SUPT', `LAP_PROF')
	replace eduac_ci = . if aedu_ci==.
	label var eduac_ci "Máx. nivel: universitario(=1) vs técnico(=0)"

	***********
	*edupre_ci*
	************
	gen byte edupre_ci = .
	replace edupre_ci = 1 if nivelaprob==`LAP_PRE' & gradoaprob>=1
	replace edupre_ci = 0 if edupre_ci==. & (asiste_ci<.|nivelaprob<.)
	label var edupre_ci  "Preescolar completo (=1)"
	
	************
	*asispre_ci*
	************
	capture drop asispre_ci edupre_ci
	gen byte asispre_ci = .
	replace asispre_ci = 1 if asiste_ci==1 & nivel==`L_PRE'
	replace asispre_ci = 0 if asiste_ci==1 & nivel!=`L_PRE'
	replace asispre_ci = . if asiste_ci==0
	label var asispre_ci "Asiste actualmente a preescolar (=1)"
	
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
	label var edupub_ci "Tipo de institución: pública (=1) / privada (=0)"	

	
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
	label var combust_ch "Principal combustible usado es gas o electric"
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	*gen byte piso_ch  = .
		
	***********
	*pared_ch*
	***********
	*gen pared_ch=.	
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*techo_ch*
	***********
	*gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
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
	label var dorm_ch "#Habitaciones exclusivamente para dormir" 

	******************************
	*	cuartos_ch
	******************************
	gen cuartos_ch=num_cuarto 
	label var cuartos_ch "#Habitaciones en el hogar"
	notes: cuartos_ch esta indicando cuartos, contando cocina pero no bano 

	******************************
	*	cocina_ch
	******************************
	destring cocina, replace
	gen cocina_ch=.
	replace cocina_ch=1 if cocina==1
	replace cocina_ch=0 if cocina==2
	label var cocina_ch "Si existe un cuarto separado y exclusivo para cocinar"


	******************************
	*	telef_ch
	******************************
	gen telef_ch=(telefono=="1")
	label var telef_ch "Hogar con sc telefonico fijo"

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
	*NA

	******************************
	*	auto_ch
	******************************
	destring num_auto num_van num_pic, replace 
	gen auto_ch=.
	replace auto_ch = 0 if  num_auto==0 & num_van==0 & num_pic==0
	replace auto_ch = 1 if num_auto>=1 | num_van>=1 | num_pic>=1
	label var auto_ch "El hogar posee automovil prticular"

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
	label var vivi1_ch "Tipo vivienda"
	label define vivi1_ch 1"Casa" 2"Dpto" 3"Otr"

	******************************
	*	viviprop_ch
	******************************
	destring tenencia, replace
	gen viviprop_ch=.
	replace viviprop_ch = 1 if tenencia==1   // propia
	replace viviprop_ch = 2 if tenencia==2   // alquilada
	replace viviprop_ch = 0 if tenencia==3   // cedida/otra
	replace viviprop_ch = 3 if !inlist(tenencia,1,2,3) & tenencia<.
	label var viviprop_ch "Propiedad de la vivienda" 

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
	label var vivialq_ch "Alquiler mensual"

	******************************
	*	vivialqimp_ch
	******************************
	gen vivialqimp_ch=estim_pago
	replace vivialqimp=0 if estim_pago<0
	replace vivialqimp_ch = estim_pago      if estim_pago<.   
	label var vivialqimp_ch "Alquiler mensual imputado"

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
	label var aguared_ch "Acceso a una fuente de agua por red"

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
	label var aguadist_ch "Ubicacion de la principal fuente de agua"

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
	label var aguamide_ch "Usan medidor para pagar consumo de agua"

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
	label var banoex_ch "Servicio higiénico de uso exclusivo del hogar"

	************
	*sinbano_ch*
	************
	gen sinbano_ch = 3
	replace sinbano_ch = 0 if excusado == 1
	replace sinbano_ch = 1 if excusado == 2 & drenaje <=4
	replace sinbano_ch = 3 if excusado == 2 & drenaje ==5
	*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

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
	gen migrante_ci=.
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migantiguo5_ci ***
	**********************
	gen migantiguo5_ci=.
	label var migantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** migrantelac_ci ***
	**********************
	gen migrantelac_ci=.
	label var migrantelac_ci "=1 si es migrante proveniente de un pais LAC"	
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"	

****************************
***VARIABLES DE EXTERNAS***
****************************
	/*Falta 
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 
	replace tipo_bienestar  = 2

	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine _ci= . 
	replace pobre_ine _ci= 0 if …
	replace pobre_ine _ci= 1 if …

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = …

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci = …
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = …
	*/
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

  
saveold "`base_out'", version(12) replace

cap log close























