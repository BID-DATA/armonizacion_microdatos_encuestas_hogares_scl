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
local ANO "2024"
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
	g mes_c = trimestre // dejo el mismo nombre para no modificar dofile de Labels
	
	******
	*zona*
	******
	* PNADC: V1022 (1 urbana, 2 rural) -> estandar: 1 urbana, 0 rural
	gen zona_c = v1022
	replace zona_c = 0 if v1022 == 2
	
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
	format %14.0g upa
	sort trimestre upa v1008 v1014 // A chave de domicílio é composta pelas variáveis: UPA + V1008 + V1014 (PNAD CONTÍNUA – CHAVES)
	egen idh_ch = group(trimestre upa estrato v1008 v1014)
	
	******************
	*** idp_ci *******
	******************
	format %14.0g upa
	sort trimestre upa v1008 v1014 v2003 // A chave de pessoas é composta pelas variáveis: UPA + V1008 + V1014 + V2003 (PNAD CONTÍNUA – CHAVES)
	egen idp_ci = group(idh_ch v2003)

	***********
	*factor_ci* 
	***********
	* Ponderador de personas: V1032
	gen double factor_ci = v1032

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	* PNADC trae peso de hogar en V1030; si no está, usar V1032 como fallback
	gen double factor_ch = v1032

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
	gen int edad_ci = v2009

	**************
	**relacion_ci**
	**************
	* PNADC: V2005 condición no domicílio
	recode v2005                                            ///
		(1 = 1)                                             /// Jefe(a)
		(2/3 = 2)                                           /// Cónyuge/pareja
		(4/6 = 3)                                           /// Hijos / hijastros
		(7/14 = 4)                                          /// Otros parientes
		(15/17 = 5)                                         /// Otros no parientes
		(19 = 5)                                            /// Pariente del doméstico = NO pariente
		(18 = 6),                                           /// Servicio doméstico
		gen(relacion_ci)

	*************
	*miembros_ci*
	*************
	gen byte miembros_ci = (relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci = 0 if v2005==18 | v2005==19
	replace miembros_ci = . if relacion_ci==.	

	*************
	*miembros_one_ci*
	*************
	gen miembro_hogar = .

	* Miembros del hogar (01 a 17)
	replace miembro_hogar = 1 if inrange(v2005, 1, 17)

	* No miembros del hogar (18 y 19)
	replace miembro_hogar = 0 if inlist(v2005, 18, 19)

	* Si no hay información: asumir miembros del hogar
	replace miembro_hogar = 1 if missing(v2005)
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci = .

	*********
	*jefe_ci*
	*********
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
	
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

	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.   

	************
	*afroind_ci*
	************
	gen afroind_ci =. 
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1

	************
	*afroind_ch*
	************
 	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 

	********
	*dis_ci*
	********
	gen byte dis_ci=.
	
	**********
	*disWG_ci*
	**********
	gen byte disWG_ci=.

	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte `PAIS'_dis_ci = .
		
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen condocup_ci = .
	replace condocup_ci = 1 if (v4001 == 1 | v4002 == 1 | v4003 == 1 | v4004 == 1 | v4005 == 1)
	replace condocup_ci = 2 if  v4005 == 2 & (v4071 == 1 & v4072a! = 9) /*tomaron alguna providencia en la semana de referencia*/
	replace condocup_ci = 3 if condocup_ci == .
	replace condocup_ci = 4 if edad_ci < 10

	***********************
	*** categoinac_ci   ***
	***********************

	* Solo para inactivos
	gen byte categoinac_ci = .  

	* 1. Jubilados / pensionados (v5004a == 1)
	replace categoinac_ci = 1 if condocup_ci == 3 & v5004a == 1

	* 2. Estudiantes (asiste a la escuela)
	replace categoinac_ci = 2 if condocup_ci == 3 & v3002 == 1

	* 3. Quehaceres domésticos: motivo VD4030 == 1
	replace categoinac_ci = 3 if condocup_ci == 3 & vd4030 == 1

	* 4. Otros inactivos: todo el resto de inactivos sin categoría asignada
	replace categoinac_ci = 4 if condocup_ci == 3 & missing(categoinac_ci)
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = (condocup_ci == 1)

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .    // todos los no desocupados quedan en missing

	* 0 = desocupado que nunca trabajó
	replace cesante_ci = 0 if condocup_ci == 2

	* 1 = desocupado que sí trabajó antes (V4082 == 1)
	replace cesante_ci = 1 if condocup_ci == 2 & v4082 == 1

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = (condocup_ci == 2)
	
	*******************
	*** subemp_ci   ***
	*******************
	gen byte subemp_ci = .
	replace subemp_ci = 1 if vd4004a == 1
	replace subemp_ci = 0 if condocup_ci == 1 & subemp_ci == .

	*******************
	*** durades_ci   ***
	*******************
	gen durades_ci = .

	* 1) Duración < 1 año: V40761 = 1-11 meses
	replace durades_ci = v40761 if condocup_ci == 2 & v40761 < . 

	* 2) Duración entre 1 y < 2 años: V40762 = 1-11 meses adicionales
	replace durades_ci = 12 + v40762 if condocup_ci == 2 & v40762 < .

	* 3) Duración de 2 años o más: V40763 = años (entre 2 y 98)
	replace durades_ci = 12*v40763 if condocup_ci == 2 & v40763 < .

	***********
	***pea_ci***
	***********
	gen byte pea_ci = (vd4001 == 1)
		
	****************
	*** nempleos_ci***
	****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci==1 & v4009==1
	replace nempleos_ci = 2 if emp_ci==1 & inlist(v4009,2,3)
	replace nempleos_ci = . if emp_ci==0

	**********************
	*** antiguedad_ci  ***
	**********************

	gen double antiguedad_ci = .

	* < 1 año: v40401 = 1–11 meses
	replace antiguedad_ci = 0 if emp_ci==1 & v40401 < .

	* 1 a < 2 años: v40402 = 0–11 meses adicionales
	replace antiguedad_ci = 1 + v40402/12 if emp_ci==1 & v40402 < .

	* 2+ años: v40403 = años completos
	replace antiguedad_ci = v40403 if emp_ci==1 & v40403 < .

	*********************
	*** desalent_ci    ***
	*********************
	gen byte desalent_ci = .
	replace desalent_ci = 1 if vd4005 == 1
	replace desalent_ci = 0 if condocup_ci == 3 & vd4005 != 1

	***************
	***horaspri_ci***
	***************	
	gen byte horaspri_ci = v4039
	replace horaspri_ci = . if v4039 == .    // NA
	replace horaspri_ci = . if horaspri_ci > 168
	replace horaspri_ci = . if emp_ci == 0
		
	***************
	***horastot_ci ***
	***************	
	egen horastot_ci = rsum(v4039c v4056c v4062c) if edad_ci >= 14 & nempleos_ci! = .
	replace horastot_ci = . if emp_ci == 0 
	replace horastot_ci = . if (horaspri_ci == . & v4056 == . & v4062 == .) | horastot_ci > 150
		
	**************************
	***  tiempoparc_ci     ***
	**************************

	gen byte tiempoparc_ci = . 

	* Tiempo parcial voluntario
	replace tiempoparc_ci = 1 if emp_ci == 1 ///
		& horaspri_ci >= 1 & horaspri_ci < 30 ///
		& v4063a == 2

	* Todos los otros ocupados no son tiempo parcial voluntario
	replace tiempoparc_ci = 0 if emp_ci == 1 & tiempoparc_ci == .
	
	***************
	***categopri_ci ***
	***************	
	gen byte categopri_ci = .

	replace categopri_ci = 1 if emp_ci==1 & vd4008==4   // Empregador
	replace categopri_ci = 2 if emp_ci==1 & vd4008==5   // Conta própria
	replace categopri_ci = 3 if emp_ci==1 & inlist(vd4008,1,2,3)   // Asalariados y domésticos
	replace categopri_ci = 4 if emp_ci==1 & vd4008==6   // Não remunerado

	replace categopri_ci = . if emp_ci!=1
	
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

	replace rama_ci = 1 if vd4010==1
	replace rama_ci = 3 if vd4010==2
	replace rama_ci = 5 if vd4010==3
	replace rama_ci = 6 if inlist(vd4010,4,6)
	replace rama_ci = 7 if vd4010==5
	replace rama_ci = 8 if vd4010==7
	replace rama_ci = 10 if vd4010==8
	replace rama_ci = 9 if inlist(vd4010,9,10,11,12)

	replace rama_ci = . if emp_ci!=1

	***************
	***spublico_ci ***
	***************	
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & rama_ci == 10
	replace spublico_ci = 0 if emp_ci == 1 & rama_ci != 10 & rama_ci != .
		
	***************
	***tamemp_ci ***
	***************	
	gen byte tamemp_ci = .

	* 1. Cuenta propia → tamaño pequeño (1 trabajador)
	replace tamemp_ci = 1 if emp_ci==1 & v4012==6

	* 2. Trabajador no remunerado → también tamaño pequeño
	replace tamemp_ci = 1 if emp_ci==1 & v4012==7 & missing(tamemp_ci)

	* 3. Tamaño según total de personas V4018
	replace tamemp_ci = 1 if emp_ci==1 & v4018==1   & missing(tamemp_ci)   // 1–5 personas
	replace tamemp_ci = 2 if emp_ci==1 & inlist(v4018,2,3) & missing(tamemp_ci)   // 6–50
	replace tamemp_ci = 3 if emp_ci==1 & v4018==4   & missing(tamemp_ci)   // 51+

	* 4. Missing para no ocupados
	replace tamemp_ci = . if emp_ci==0
	
	***************
	***cotizando_ci***
	***************	
	gen cotizando_ci=0     if condocup_ci==1 | condocup_ci==2 
	replace cotizando_ci=1 if (vd4012==1) & cotizando_ci==0

	***************
	***afiliado_ci***
	***************	
		
	gen byte afiliado_ci = .

	***************
	***instcot_ci***
	***************	
	gen byte instcot_ci = .

	* 2 = RPPS: Servidor estatutário que cotiza
	replace instcot_ci = 2 if cotizando_ci==1 & v4028==1

	* 1 = INSS (RGPS): todos los demás cotizantes
	replace instcot_ci = 1 if cotizando_ci==1 & instcot_ci==.

	**************
	***formal_ci***
	**************
	gen formal_ci=(cotizando_ci==1)
	
	*******************
	***tipocontrato_ci***
	*******************
	gen byte tipocontrato_ci = .

	* Solo asalariados
	* (categopri_ci == 3)

	* 1 = Permanente (único tipo de contrato identificado en PNAD)
	replace tipocontrato_ci = 1 if categopri_ci == 3 & v4029 == 1

	* 3 = Sin contrato
	replace tipocontrato_ci = 3 if categopri_ci == 3 & v4029 == 2

	* No asalariados → missing
	replace tipocontrato_ci = . if categopri_ci != 3
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci = .

	replace ocupa_ci = 2 if vd4011==1
	replace ocupa_ci = 1 if inlist(vd4011,2,3)
	replace ocupa_ci = 3 if vd4011==4
	replace ocupa_ci = 5 if vd4011==5
	replace ocupa_ci = 6 if vd4011==6
	replace ocupa_ci = 7 if inlist(vd4011,7,8)
	replace ocupa_ci = 8 if vd4011==10
	replace ocupa_ci = 9 if inlist(vd4011,9,11)

	replace ocupa_ci = . if emp_ci!=1

	**************
	**pension_ci***
	**************
	gen byte pension_ci = .

	* Jubilación o pensión contributiva
	replace pension_ci = 1 if v5004a == 1

	* No recibe pensión contributiva
	replace pension_ci = 0 if v5004a == 2
		
	***********************
	*** pensionsub_ci   ***
	***********************
	gen byte pensionsub_ci = .

	* 1. Recibe BPC/LOAS (no contributiva)
	replace pensionsub_ci = 1 if v5005a == 1

	* 0. No recibe pensión no contributiva
	replace pensionsub_ci = 0 if v5005a == 2

	***********************
	*** tipopen_ci       ***
	***********************
	gen byte tipopen_ci = .

	* 1 = Pensión contributiva (INSS o RPPS)
	replace tipopen_ci = 1 if v5004a == 1

	* 2 = Pensión NO contributiva (BPC/LOAS)
	replace tipopen_ci = 2 if v5005a == 1

	* 0 = No recibe ningún tipo de pensión
	replace tipopen_ci = 0 if tipopen_ci == . & (v5004a == 2 & v5005a == 2)

	***********************
	*** instpen_ci       ***
	***********************
	gen byte instpen_ci = .

	* 3 = BPC/LOAS (pensión no contributiva asistencial)
	replace instpen_ci = 3 if v5005a == 1

	* 2 = RPPS (servidor estatutario jubilado)
	* Solo podemos identificarlo si la persona recibe pensión contributiva 
	* Y si es/era servidor estatutário (v4028==1)
	replace instpen_ci = 2 if v5004a == 1 & v4028 == 1

	* 1 = INSS (para todos los demás pensionados contributivos)
	replace instpen_ci = 1 if v5004a == 1 & instpen_ci == .

	* 0 = No recibe ninguna pensión
	replace instpen_ci = 0 if instpen_ci == . & (v5004a == 2 & v5005a == 2)
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	gen ylmpri_ci = v403312
	replace ylmpri_ci = . if v403312 < 0 | v403312 >= 999999 | emp_ci! = 1

	************
	* ylmsec_ci *
	************
	gen ylmsec_ci = v405012
	replace ylmsec_ci = . if v405012 < 0 | v405012 >= 999999 | emp_ci! = 1
  
	**************
	* ylmotros_ci *
	**************
	gen ylmotros_ci = v405812
	replace ylmotros_ci = . if v405812 < 0 | v405812 >= 999999 | emp_ci! = 1

	*********
	* ylm_ci *
	*********
	egen ylm_ci = rsum(ylmpri_ci ylmsec_ci ylmotros_ci)
	replace ylm_ci = . if ylmpri_ci == . & ylmsec_ci == . & ylmotros_ci == .
	
	**************
	* ylnmpri_ci *
	**************
	gen ylnmpri_ci = v403322 if v40332 == 2
	replace ylnmpri_ci = . if v403322 < 0 | v403322 >= 999999 | emp_ci! = 1
	
	**************
	* ylnmsec_ci *
	**************
	gen ylnmsec_ci = v405022
	replace ylnmsec_ci = . if v405022 < 0 | v405022 >= 999999 | emp_ci! = 1

	******************
	*** ylnmotros_ci ***
	******************
	gen ylnmotros_ci = v405822
	replace ylnmotros_ci = . if v405822 < 0 | v405822 >= 999999 | emp_ci! = 1

	**********
	* ylnm_ci *
	**********
	egen ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci)
	replace ylnm_ci = . if ylnmpri_ci == . & ylnmsec_ci == . & ylnmotros_ci == .
	
	**********
	* ynlm_ci *
	**********
	foreach var of varlist v5001a2 v5002a2 v5003a2 v5004a2 v5005a2 v5006a2 v5007a2 { 
	replace `var' = . if `var' >= 999999 | `var' < 0
	}
	egen ynlm_ci = rsum(v5001a2 v5002a2 v5003a2 v5004a2 v5005a2 v5006a2 v5007a2) if edad_ci >= 10
	replace ynlm_ci = . if (v5001a2 == . & v5002a2 == . & v5003a2 == . & v5004a2 == . & v5005a2 == . & v5006a2 == . & v5007a2 == .) | ynlm_ci < 0

	***********
	* ynlnm_ci *
	***********
    generate ynlnm_ci = . 
    
	**********
	* ytot_ci *
	**********
	egen double ytot_ci= rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), m 

	*********
	* ylm_ch *
	*********
	by idh_ch, sort: egen ylm_ch = sum(ylm_ci) if miembros_ci == 1
	
	**********
	* ylnm_ch *
	**********
	by idh_ch, sort: egen ylnm_ch = sum(ylnm_ci) if miembros_ci == 1

	***********
	* ynlnm_ch *
	***********
	gen ynlnm_ch = .

	*********
	* ynlm_ch *
	*********
	by idh_ch, sort: egen ynlm_ch = sum(ynlm_ci) if miembros_ci == 1
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
	gen ylmhopri_ci = ylmpri_ci / (horaspri_ci * 4.3)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0
 
	**********
	* ylmho_ci *
	**********
	gen ylmho_ci = ylm_ci / (horaspri_ci * 4.3)
	replace ylmho_ci = . if ylmho_ci <= 0
  
	**************
	* nrylmpri_ci *
	**************
	gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
	replace nrylmpri_ci = . if emp_ci! = 1

	**************
	* nrylmpri_ch *
	**************
	sort idh_ch 
	by idh_ch: egen nrylmpri_ch = max(nrylmpri_ci) if miembros_ci == 1

	*************
	* remesas_ci *
	*************
    generate remesas_ci = .

	*************
	* remesas_ch *
	*************
	gen remesas_ch = .

	**********
	* ypen_ci *
	**********
	gen ypen_ci = v5004a2
	replace ypen_ci = . if ypen_ci <= 0

	*************
	* ypensub_ci *
	*************
	egen ypensub_ci = rsum(v5001a2 v5002a2 v5003a2)
	replace ypensub_ci = . if v5001a2 == . & v5002a2 == . & v5003a2 == .
	
****************************
***VARIABLES DE EDUCACION***
****************************
	*********	
	*aedu_ci*
	*********
	gen aedu_ci = .

	/********************************************************
	  1. CASOS QUE NO ASISTEN ACTUALMENTE (v3002==2)
	********************************************************/

	* 1.1 Nunca asistió
	replace aedu_ci = 0 if v3002==2 & v3008==2

	* 1.2 Preescola, alfabetização, CA → 0 años
	replace aedu_ci = 0 if v3002==2 & inlist(v3009a,1,2,3,4)

	* 1.3 Antigo primário (elementar)
	replace aedu_ci = v3013 if v3002==2 & v3009a==5

	* 1.4 Antigo ginásio (médio 1º ciclo)
	replace aedu_ci = 4 + v3013 if v3002==2 & v3009a==6

	* 1.5 Ensino fundamental regular o EJA
	replace aedu_ci = v3013 if v3002==2 & inlist(v3009a,7,8)

	* 1.6 Antigo científico/clássico (2º ciclo)
	replace aedu_ci = 8 + v3013 if v3002==2 & v3009a==9

	* 1.7 Ensino médio regular / supletivo
	replace aedu_ci = 9 + v3013 if v3002==2 & inlist(v3009a,10,11)

	* 1.8 Superior – graduação (no preguntan grado → valor fijo)
	replace aedu_ci = 16 if v3002==2 & v3009a==12

	* 1.9 Pós-graduação (no asistiendo)
	replace aedu_ci = 16 if v3002==2 & v3009a==13
	replace aedu_ci = 18 if v3002==2 & v3009a==14
	replace aedu_ci = 22 if v3002==2 & v3009a==15


	/********************************************************
	  2. CASOS QUE ASISTEN ACTUALMENTE (v3002==1)
	********************************************************/

	* 2.1 Preescola / alfabetização
	replace aedu_ci = 0 if v3002==1 & inlist(v3003a,2,3)

	* 2.2 Ensino fundamental regular o EJA
	replace aedu_ci = v3006 - 1 if v3002==1 & inlist(v3003a,4,5)

	* 2.3 Ensino médio regular o EJA
	replace aedu_ci = 9 + (v3006 - 1) if v3002==1 & inlist(v3003a,6,7)

	* 2.4 Superior – graduação 
	replace v3006 = round(v3006/2) if v3005a==1 & v3003a==8   // semestres → años
	replace aedu_ci = 12 + (v3006 - 1) if v3002==1 & v3003a==8

	* 2.5 Pós-grado (no se reporta año)
	replace aedu_ci = 16 if v3002==1 & v3003a==9    // especialización
	replace aedu_ci = 18 if v3002==1 & v3003a==10   // maestría
	replace aedu_ci = 22 if v3002==1 & v3003a==11   // doctorado


	/********************************************************
	  3. FINAL
	********************************************************/

	* Cursos no clasificados
	replace aedu_ci = . if v3006==13 | v3013==13

	* Rango máximo ISCED
	replace aedu_ci = 0 if aedu_ci < 0
	replace aedu_ci = 22 if aedu_ci > 22

	*********** 
	*edupre_ci*
	***********
	gen byte edupre_ci = .

	**************
	*** eduui_ci ***
	**************
	gen byte eduui_ci = 0

	* A. Estudia actualmente educación superior → incompleta
	replace eduui_ci = 1 if v3002 == 1 ///
		& inlist(v3003a, 8, 9, 10, 11)

	* B. No estudia pero el máximo nivel es superior y NO concluyó
	replace eduui_ci = 1 if v3002 == 2 ///
		& inlist(v3009a, 12, 13, 14, 15) ///
		& v3014 != 1

	* Missing si no hay información
	replace eduui_ci = . if v3002 == . | v3003a == . & v3009a == .

	**************
	*** eduuc_ci ***
	**************
	gen byte eduuc_ci = .   

	* A. Estudia actualmente educación superior → cuenta (incompleta)
	replace eduuc_ci = 1 if v3002 == 1 ///
		& inlist(v3003a, 8, 9, 10, 11)

	* B. Último nivel alcanzado es superior (graduação ou pós)
	*    y CONCLUYÓ → completa
	replace eduuc_ci = 1 if v3002 == 2 ///
		& inlist(v3009a, 12, 13, 14, 15) ///
		& v3014 == 1

	* C. Último nivel alcanzado es superior (graduação ou pós)
	*    y NO CONCLUYÓ → igualmente cuenta según CIMA
	replace eduuc_ci = 1 if v3002 == 2 ///
		& inlist(v3009a, 12, 13, 14, 15) ///
		& v3014 != 1

	* D. Quienes NO están en ningún caso → 0
	replace eduuc_ci = 0 if eduuc_ci==. ///
		& v3002 != .   ///
		& v3009a != .

	**********
	*eduac_ci*
	**********
	gen byte eduac_ci = .

	***********
	*asiste_ci*
	***********
	gen byte asiste_ci = (v3002 == 1)
	replace asiste_ci = . if v3002 == .

	***********
	*edupub_ci*
	***********
	gen byte edupub_ci = .
	replace edupub_ci = 1 if asiste_ci == 1 & v3002a == 2   // red pública
	replace edupub_ci = 0 if asiste_ci == 1 & v3002a == 1   // red privada
	
	************
	*asispre_ci*
	************
	gen byte asispre_ci = 0
	replace asispre_ci = 1 if v3002==1 & v3003a==2
	
	
	*************
	*razonesnoasis_ci*
	**************
	gen byte razonesnoasis_ci = .

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	***luz_ch***
	***********
	* 1 = electricidad | 0 = no es electricidad | . = NR/NP o no está en la base
	gen luz_ch=(s01014==1)
	label var luz_ch  "La principal fuente de iluminación es electricidad"


	***************
	***luzmide_ch***
	***************
	* 1 = con medidor | 0 = sin medidor | . = NR/NP o no está en la base
	gen luzmide_ch=.
	label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

	***************
	***combust_ch***
	***************
	* 1 = gas/eléctrico | 0 = otro | . = NR/NP o no está en la base
	gen byte combust_ch = .

	***********
	***piso_ch***
	***********
	gen piso_ch= 0 	if s01004==4
	replace piso_ch=1	if s01004>=1 & s01004<=3
	replace piso_ch=. 	if s01004==.
	label var piso_ch "Materiales de construcción del piso"  
	label def piso_ch 0"Piso de tierra" 1"Materiales permanentes" 2"Otros materiales"
	label val piso_ch piso_ch


	************
	***pared_ch***
	************
	* pendiente metodología → missing si no está
	gen pared_ch=0 if s01002==5
	replace pared_ch=1 if s01002==1 | s01002==2 |s01002==4
	replace pared_ch=2 if s01002==6 | s01002==3
	replace pared_ch=. if s01002==.
	label var pared_ch "Materiales de construcción de las paredes"
	label def pared_ch 0"No permanentes" 1"Permanentes" 2"Otros materiales:otros"
	label val pared_ch pared_ch

	************
	***techo_ch***
	************
	* pendiente metodología → missing si no está
	gen techo_ch=0 if s01003==6
	replace techo_ch=1 if s01003<=5
	replace techo_ch=2 if s01003==6
	replace techo_ch=. if s01003==.
	label var techo_ch "Materiales de construcción del techo"
	label def techo_ch 0"No permanentes" 1"Permanentes" 2"Otros materiales:otros"
	label val techo_ch techo_ch

	************
	***resid_ch***
	************
	* 0 = recolección | 1 = quema/entierra | 2 = espacio abierto | 3 = otros | . = no está
	gen resid_ch=0 if s01013==1 | s01013==2
	replace resid_ch=1 if s01013==3 | s01013==4
	replace resid_ch=2 if s01013==5
	replace resid_ch=3 if s01013==6
	replace resid_ch=. if s01013==.
	label var resid_ch "Método de eliminación de residuos"
	label def resid_ch 0"Recolección pública o privada" 1"Quemados o enterrados"
	label def resid_ch 2"Tirados a un espacio abierto" 3"Otros", add
	label val resid_ch resid_ch

	***********
	***dorm_ch***
	***********
	* número de dormitorios | . = no está
	gen dorm_ch=s01006
	replace dorm_ch=. if s01006==99 
	label var dorm_ch "Habitaciones para dormir"


	****************
	***cuartos_ch***
	****************
	* número de cuartos totales | . = no está
	gen cuartos_ch=s01005
	replace cuartos_ch=. if s01005==99 
	label var cuartos_ch "Habitaciones en el hogar"

	*************
	***cocina_ch***
	*************
	gen cocina_ch=.
	label var cocina_ch "Cuarto separado y exclusivo para cocinar"

	************
	***telef_ch***
	************
	* 1 = teléfono fijo | 0 = no | . = no está
	gen telef_ch=(s01022==1)
	replace telef_ch=. if s01022==.
	label var telef_ch "El hogar tiene servicio telefónico fijo"

	***************
	***refrig_ch***
	***************
	gen refrig_ch=(s01023==1 |s01023==2)
	replace refrig_ch=. if s01023==.
	label var refrig_ch "El hogar posee refrigerador o heladera"
	**************
	***freez_ch***
	**************
	gen freez_ch=.
	label var freez_ch "El hogar posee congelador"

	*************
	***auto_ch***
	*************
	gen auto_ch=(s01031==1)
	replace auto_ch=. if s01031==.
	label var auto_ch "El hogar posee automovil particular"
	**************
	***compu_ch***
	**************
	gen compu_ch=(s01028==1)
	label var compu_ch "El hogar posee computador"
	*****************
	***internet_ch***
	*****************
	gen internet_ch=(s01029==1)
	label var internet_ch "El hogar posee conexión a Interne
	************
	***cel_ch***
	************
	gen cel_ch=(s01021>=1)
	label var cel_ch "El hogar tiene servicio telefonico celular"
	**************
	***vivi1_ch***
	**************
	gen vivi1_ch=1 if s01001==1
	replace vivi1_ch=2 if s01001==2
	replace vivi1_ch=3 if s01001==3
	label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
	label def vivi1_ch 1"Casa" 2"Departamento" 3"Otros"
	label val vivi1_ch vivi1_ch
	**************
	***vivi2_ch***
	**************
	gen vivi2_ch=(vivi1_ch==1 | vivi1_ch==2)
	replace vivi2_ch=. if vivi1_ch==.
	label var vivi2_ch "La vivienda es casa o departamento"
	*****************
	***viviprop_ch***
	*****************
	gen viviprop_ch=0 if s01017==3
	replace viviprop_ch=1 if s01017==1
	replace viviprop_ch=2 if s01017==2
	replace viviprop_ch=3 if s01017>=4 /*corrigo =3 no =4, revisar en anios anteriores */
	replace viviprop_ch=. if s01017==.
	label var viviprop_ch "Propiedad de la vivienda"
	label def viviprop_ch 0"Alquilada" 1"Propia y totalmente pagada" 2"Propia y en proceso de pago"
	label def viviprop_ch 3"Ocupada (propia de facto)", add
	label val viviprop_ch viviprop_ch
	****************
	***vivialq_ch***
	****************
	gen vivialq_ch=s01019
	replace vivialq_ch=. if s01019>=999999999 | vivialq_ch<0
	label var vivialq_ch "Alquiler mensual"
	*******************
	***vivialqimp_ch***
	*******************
	gen vivialqimp_ch=s01019 if s01017==3
	label var vivialqimp_ch "Alquiler mensual imputado"
	****************
	***vivitit_ch***
	****************
	gen vivitit_ch=.
	label var vivitit_ch "El hogar posee un título de propiedad"

****************************
***VARIABLES DE WASH***
****************************
	**************
	***aguared_ch***
	**************
	gen aguared_ch=(s01007==1) 
	label var aguared_ch "Acceso a fuente de agua por red"

	***********************
	***aguafconsumo _ch***
	***********************
	* 0 = la encuesta NO pregunta agua para beber
	* 1..10 = categorías JMP (si existiera la pregunta)
	* Aquí, como no está en la base → asignamos 0 (no pregunta)
	gen aguafconsumo_ch=0

	********************
	***aguafuente_ch***
	********************
	gen aguafuente_ch = .
	replace aguafuente_ch = 1 if s01007==1 & s01010 != 3
	replace aguafuente_ch = 2 if s01007==1 & s01010==3
	replace aguafuente_ch = 4 if s01007==2         
	replace aguafuente_ch = 5 if s01007==5 
	replace aguafuente_ch = 9 if s01007==3 
	replace aguafuente_ch = 10 if (s01007==4 | s01007==6)
	replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1
	******************
	***aguadist_ch***
	******************
	* 0 = no se especifica | 1 = dentro | 2 = en el lote | 3 = fuera del lote
	* Si no está la pregunta → 0
	gen aguadist_ch=.
	replace aguadist_ch=1 if s01010==1
	replace aguadist_ch=2 if s01010==2
	replace aguadist_ch=3 if s01010==3
	replace aguadist_ch=. if s01010==. 
	label var aguadist_ch "Ubicación de la principal fuente de agua"
	label def aguadist_ch 1"Adentro de la casa" 2"Afuera de la casa pero dentro del terreno" 3"Afuera de la casa y del terreno" 
	label val aguadist_ch aguadist_ch 

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
	gen aguadisp2_ch = 3 if s01008==1
	replace aguadisp2_ch = 2 if s01008==2
	replace aguadisp2_ch = 1 if (s01008==3 | s01008==4)
	******************
	***aguatrat_ch***
	******************
	gen aguatrat_ch =9

	******************
	***aguamala_ch***
	******************
	gen aguamala_ch= 2
	replace aguamala_ch= 1 if aguafuente_ch>7 & aguafuente_ch<10
	replace aguamala_ch= 0 if aguafuente_ch<=7
	label var aguamala_ch "Agua unimproved según MDG"


	**********************
	***aguamejorada_ch***
	**********************
	gen aguamejorada_ch= 2
	replace aguamejorada_ch= 0 if aguafuente_ch>7 & aguafuente_ch<10
	replace aguamejorada_ch= 1 if aguafuente_ch<=7

	******************
	***aguamide_ch***
	******************
	* 1 = con medidor | 0 = sin medidor | . = no está
	gen byte aguamide_ch = .
	label var aguamide_ch "Usan medidor para pagar consumo de agua"

	************
	***bano_ch***
	************
	* 0 = sin inst. | 1 = red | 2 = fosa | 3 = letrina mejorada | 4 = descarga a cuerpo de agua/suelo
	* 5 = no mejorada | 6 = no clasificable | . = no está
	gen bano_ch=.
	replace bano_ch = 1 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 1 | s01012a == 2)
	replace bano_ch = 2 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 3)
	replace bano_ch = 4 if (s01011a>0 | s01011b>0 | s01011c==1) & (s01012a == 5 | s01012a == 6 )
	replace bano_ch = 6 if  (s01011a>0 | s01011b>0 | s01011c==1) & s01012a==4
	replace bano_ch = 0 if (s01011a==0 & s01011b==0) | s01011c==2  | s01012a ==7
	replace bano_ch=6 if bano_ch ==. & jefe_ci==1 
	label var bano_ch "Tipo de instalación sanitaria del hogar"

	**************
	***banoex_ch***
	**************
	*Pregunta única, se pregunta si el banio es de uso exclusivo para moradores
	gen banoex_ch=(s01011a>=1)
	label var banoex_ch "El servicio sanitario es exclusivo del hogar"

	***************
	***sinbano_ch***
	***************
	* 0 = tiene baño | 1 = usa público/vecino | 2 = defecación al aire libre | 3 = no especifica | . = no está
	gen sinbano_ch = 3
    replace sinbano_ch = 0 if bano_ch>0
    replace sinbano_ch = 1 if (s01011a==0 & s01011b==0 & s01011c==1)

	**********************
	***banomejorado_ch***
	**********************
	* 1 = mejorado | 0 = no mejorado | 2 = no clasificable
	* Si no hay info de bano_ch → 2
	gen banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
		
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
		
		
/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/

do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch BRA_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  lp19_2011 lp31_2011 lp5_2011 lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/
rename v4010 codocupa
rename v4013 codindustria

compress

saveold "`base_out'", version(12) replace

log close


