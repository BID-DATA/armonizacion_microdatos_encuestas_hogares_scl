* (Versión Stata 19)
/*==============================================================================
						Armonización de encuestas
			Script de merge - Unión de módulos en una sola base 
País: Ecuador
Año: 
Autores: Matias Rodriguez SCL 
Última versión: 03/12/2026
División: SCL/SCL - IADB
*******************************************************************************/
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
* ________________________________________________________________________________________________________________*
 
 
global ruta = "${surveysFolder}"
global gitFolder = "${gitFolder}"

local PAIS ECU
local ENCUESTA ENEMDU
local ANO "2021"
local ronda m12 


local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace 
*/****************************************************************************/

use `base_in', clear
*destring *, replace
	
*/****************************************************************************/


	**********************************
	***VARIABLES DEL IDENTIFICACION***
	**********************************
	
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=3

	***************
	***region_c ***
	***************
	gen region_c=.
	replace region_c=int(ciudad/10000)
	label define region_c ///
	1 "Azuay" ///
	2 "Bolívar" ///
	3 "Cañar" ///
	4 "Carchi" /// 
	5 "Cotopaxi" ///
	6 "Chimborazo" ///
	7 "El Oro" ///
	8 "Esmeraldas" ///
	9 "Guayas" ///
	10 "Imbabura" ///
	11 "Loja" ///
	12 "Los Ríos" ///
	13 "Manabí" ///
	14 "Morona Santiago" ///
	15 "Napo" ///
	16 "Pastaza" ///
	17 "Pichincha" ///
	18 "Tungurahua" ///
	19 "Zamora Chinchipe" ///
	20 "Galápagos" ///
	21 "Sucumbíos" ///
	22 "Orellana" ///
	23 "Santo Domingo de los Tsáchilas" ///
	24 "Santa Elena" 
	label value region_c region_c
   
	*************
	****pais_c***
	*************
	gen str3 pais_c = "ECU"

	************
	***anio_c***
	************
	gen anio_c = 2021

	***********
	***mes_c***
	***********
	gen mes_c = 12

	*************
	****zona_c***
	*************
	gen zona_c = 1 		if area == 1
	replace zona_c = 0 	if area == 2

	***************
	***estrato_ci***
	***************
	clonevar estrato_ci = estrato

	***************
	***upm_ci***
	***************
	clonevar upm_ci = upm

	*************
	****idh_ch***
	*************
	duplicates report id_vivienda id_hogar id_persona
	gen idh_ch = id_vivienda+id_hogar

	*************
	****idp_ci***
	*************
	duplicates report id_vivienda id_hogar id_persona
	gen idp_ci =  id_vivienda+id_hogar+ id_persona

	***************
	***factor_ci***
	***************
	gen factor_ci = fexp

	***************
	***factor_ch***
	***************
	gen factor_ch = fexp


	
	
			****************************
			***VARIABLES DEMOGRAFICAS***
			****************************

	*************
	***sexo_ci***
	*************
	gen sexo_ci = p02

	*************
	***edad_ci***
	*************
	gen edad_ci = p03 if p03 < 98 // 98 = 98+, se pierden 28 obs
	replace edad_ci=. if p03>97
	
	*****************
	***relacion_ci***
	*****************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if p04 == 1
	replace relacion_ci = 2 if p04 == 2
	replace relacion_ci = 3 if p04 == 3
	replace relacion_ci = 4 if inrange(p04, 4, 7)
	replace relacion_ci = 5 if p04 == 9
	replace relacion_ci = 6 if p04 == 8
	
	*****************
	***miembros_ci***
	*****************
	gen miembros_ci = (relacion_ci >= 1 & relacion_ci < 5)
	replace miembros_ci=. if relacion_ci==.
	
	*******************
	**miembros_one_ci**
	*******************
	gen miembros_one_ci = .
	
	**************
	***civil_ci***
	**************
	*p06: para personas de 12 años o más
	gen byte civil_ci=. 
	replace civil_ci = 1 if p06 == 6
	replace civil_ci = 2 if inlist(p06, 1, 5)
	replace civil_ci = 3 if inlist(p06, 2, 3)
	replace civil_ci = 4 if p06 == 4

	*************
	***jefe_ci***
	*************
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)

	**************
	*nconyuges_ch*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	
	***********
	*nhijos_ch*
	***********
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          

	**************
	*notropari_ch*
	**************
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.
	
	**************
	*notronopari_ch*
	**************
	by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5)
	replace notronopari_ch=. if relacion_ci==.          
		
	****************
	*nempdom_ch*
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.
	
	*****************
	***clasehog_ch***
	*****************
	gen byte clasehog_ch = 0
	replace clasehog_ch = 1 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch == 0
	replace clasehog_ch = 2 if (nhijos_ch > 0 | nconyuges_ch > 0) & (notropari_ch == 0 & notronopari_ch == 0)
	replace clasehog_ch = 3 if ((clasehog_ch == 2 & notropari_ch > 0) & notronopari_ch == 0) | (notropari_ch > 0 & notronopari_ch == 0) 
	replace clasehog_ch = 4 if ((nconyuges_ch > 0 | nhijos_ch > 0 | notropari_ch > 0) & (notronopari_ch > 0))
	replace clasehog_ch = 5 if nhijos_ch == 0 & nconyuges_ch == 0 & notropari_ch == 0 & notronopari_ch > 0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

	*************
	*nmenor21_ch*
	*************
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch*
	*************
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch*
	************
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch*
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
	

         ******************************
         *** VARIABLES DE DIVERSIDAD **
         ******************************

	*************
	***afro_ci***
	*************
	gen afro_ci = . 
	replace afro_ci = 1 if inrange(p15, 2, 4)
	replace afro_ci = 0 if p15 != 2 & p15 != 3 & p15 != 4 & p15 != .

	************
	***ind_ci***
	************
	gen ind_ci = .
	replace ind_ci = 1 if (p15 == 1) 
	replace ind_ci = 0 if p15 != 1 & p15 != .

	******************
	***noafroind_ci***
	******************
	gen noafroind_ci = .
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)

	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c = 2010

	***************
	***afroind_ci***
	***************
	**Pregunta: p15 (1 indígena, 2 afroecuatoriano, 3 negro, 4 mulato, 5 montuvio, 6 mestizo, 7 blanco, 8 otro) 
	gen afroind_ci =. 
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1

	*********
	*afro_ch*
	*********
	gen byte afro_jefe = afro_ci if relacion_ci==1
	egen afro_ch  = max(afro_jefe), by(idh_ch) 
	drop afro_jefe
	
	********
	*ind_ch*
	********	
	gen byte ind_jefe = ind_ci if relacion_ci==1
	egen ind_ch = max(ind_jefe), by(idh_ch) 
	drop ind_jefe

	**************
	*noafroind_ch*
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci==1
	egen noafroind_ch = max(noafroind_jefe), by(idh_ch) 
	drop noafroind_jefe

	************
	*afroind_ch*
	************
 	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 
	
	
         ********************************
         *** SITUACIÓN DE DISCAPACIDAD **
         ********************************
		 
	************
	***dis_ci***
	************
	gen dis_ci = .

	**************
	***disWG_ci***
	**************
	gen disWG_ci = .

	************
	***dis_ch***
	************
	gen dis_ch = . 

	*********************
	***ECU_dis_ci***
	*********************
	gen ECU_dis_ci = .

	
		***********************************
		***VARIABLES DEL MERCADO LABORAL***
		***********************************

	***************
	**condocup_ci**
	***************
	gen condocup_ci = .
	replace condocup_ci = 1 if p20 == 1 | p21 < 12 | p22 == 1 
	replace condocup_ci = 2 if (p20 == 2 | p21 == 12 | p22 == 2) & p32 < 11
	replace condocup_ci = 3 if condocup_ci != 1 & condocup_ci != 2 & edad_ci >= 5
	replace condocup_ci = 4 if edad_ci < 5

	*******************
	***categoinac_ci***
	*******************
	gen categoinac_ci = 1 if (p36 == 2 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (p36 == 3 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (p36 == 4 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3)

	**********
	***emp_ci*
	**********
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci
	
	*************
	**cesante_ci* 
	*************
	gen byte cesante_ci = .
	replace cesante_ci =1 if (p37 == 1 & condocup_ci == 2)
	replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

	***************
	***desemp_ci***
	***************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci
	
	***************
	***subemp_ci***
	***************
	gen subemp_ci = (p51a <= 30 & p27 < 4 & p30 < 7)

	****************
	***durades_ci***
	****************
	gen durades_ci= p33 / 4.33

	************
	***pea_ci***
	************
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)

	*****************
	***nempleos_ci***
	*****************
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1 & p50==1
	replace nempleos_ci = 2 if emp_ci ==1 & p50==2
	replace nempleos_ci = . if emp_ci == 0

	***************
	*antiguedad_ci*
	***************
	gen antiguedad_ci = p45 if emp_ci == 1 //no se puede distinguir menos de 1 año (indicados como 0)

	*****************
	***desalent_ci***
	*****************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if ((p32 == 11 & (p34 == 6 | p34 == 7)) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	*****************
	***horaspri_ci***
	*****************
	gen horaspri_ci = p51a
	replace horaspri_ci = . if p51a == 999
	replace horaspri_ci = . if emp_ci == 0

	*****************
	***horastot_ci***
	*****************
	egen horastot_ci = rsum(p51a p51b p51c) if emp_ci == 1
	replace horastot_ci = . if p51a == . & p51b == . & p51c == .
	replace horaspri_ci = . if p51a == 999 & p51b == 999 & p51c == 999
	replace horastot_ci = . if emp_ci == 0

	*******************
	***tiempoparc_ci***
	*******************
	gen tiempoparc_ci = (horaspri_ci < 30 & p27 == 4 & emp_ci == 1)
	replace tiempoparc_ci = . if emp_ci == 0

	******************
	***categopri_ci***
	******************
	gen categopri_ci = .
	replace categopri_ci = 1 if p42 == 5
	replace categopri_ci = 2 if p42 == 6
	replace categopri_ci = 3 if (p42 <= 4) | p42 == 10
	replace categopri_ci = 4 if (p42 >= 7 & p42 <= 9)
	replace categopri_ci = . if emp_ci == 0

	******************
	***categosec_ci***
	******************
	gen categosec_ci = .
	replace categosec_ci = 1 if p54 == 5
	replace categosec_ci = 2 if p54 == 6	
	replace categosec_ci = 3 if (p54 <= 4) | p54 == 10
	replace categosec_ci = 4 if (p54 >= 7 & p54 <= 9)

	*************
	***rama_ci***
	*************
	gen rama_ci = .
	replace rama_ci = 1 if (p40 >=  111 & p40 <=  322) & emp_ci == 1
	replace rama_ci = 2 if (p40 >=  510 & p40 <=  990) & emp_ci == 1
	replace rama_ci = 3 if (p40 >= 1010 & p40 <= 3320) & emp_ci == 1
	replace rama_ci = 4 if (p40 >= 3510 & p40 <= 3900) & emp_ci == 1
	replace rama_ci = 5 if (p40 >= 4100 & p40 <= 4390) & emp_ci == 1
	replace rama_ci = 6 if ((p40 >= 4510 & p40 <= 4799) | (p40 >= 5510 & p40 <= 5630)) & emp_ci == 1
	replace rama_ci = 7 if ((p40 >= 4911 & p40 <= 5320) | (p40 >= 6110 & p40 <= 6190)) & emp_ci == 1
	replace rama_ci = 8 if (p40 >= 6411 & p40 <= 8299) & emp_ci == 1
	replace rama_ci = 9 if ((p40 >= 5811 & p40 <= 6020) | (p40 >= 6201 & p40 <= 6399) | (p40 >= 8410 & p40 <= 9900)) & emp_ci == 1

	*****************
	***spublico_ci***
	*****************
	gen spublico_ci = (p42 == 1 & emp_ci == 1)
	replace spublico_ci = . if emp_ci == .

	*************
	**tamemp_ci**
	*************
	gen tamemp_ci = .
	replace tamemp_ci = 1 if p47a == 1 & (p47b >= 1 & p47b <= 5)
	replace tamemp_ci = 2 if p47a == 1 & p47b >= 6 & p47b <= 50
	replace tamemp_ci = 3 if (p47a == 2) | (p47b > 50 & p47b != .)

	****************
	*cotizando_ci***
	****************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((p44f == 1 | p61b1 <= 4) & emp_ci==1)  //¿(…) recibe por parte de su patrono o empleador:
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci
	
	********************
	*** instcot_ci *****
	********************
	gen instcot_ci = "IESS" if p61b1 < 2
	replace instcot_ci = "Seguro campesino" if p61b1 == 3
	replace instcot_ci = "ISSFA o ISSPOL" if p61b1 == 4

	****************
	***afiliado_ci**
	****************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if ((p05a <= 4) & emp_ci==1) /*IESS, ISSFA e ISSPOL requieren afiliación*/
	replace afiliado_ci = 0 if (p05a > 4 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci
	*Nota: seguridad social comprende solo los que en el futuro me ofrecen una pension.
	* p05b incluye a los cubiertos no necesariamente estan afiliados
	
	***************
	***formal_ci***
	***************
	gen byte formal_ci = .
	replace formal_ci  =  1 if cotizando_ci == 1 & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	*****************
	*tipocontrato_ci*
	*****************
	gen tipocontrato_ci = . /* Solo disponible para asalariados*/
	replace tipocontrato_ci = 1 if (p43 == 1 | p43 == 2) & categopri_ci == 3
	replace tipocontrato_ci = 2 if (p43 == 3) & categopri_ci == 3
	replace tipocontrato_ci = 3 if (p43 >= 4 & p43 <= 6) & categopri_ci == 3
	
	**************
	***ocupa_ci***
	**************
	generat ocupa_ci = .
	replace ocupa_ci = 1 if (p41 >= 2111 & p41 <= 3522) & emp_ci == 1
	replace ocupa_ci = 2 if (p41 >= 1111 & p41 <= 1439) & emp_ci == 1
	replace ocupa_ci = 3 if (p41 >= 4110 & p41 <= 4419) & emp_ci == 1
	replace ocupa_ci = 4 if ((p41 >= 5211 & p41 <= 5249) | (p41 >= 9510 & p41 <= 9520)) & emp_ci == 1
	replace ocupa_ci = 5 if ((p41 >= 5110 & p41 <= 5169) | (p41 >= 5311 & p41 <= 5419) | (p41 >= 9111 & p41 <= 9129) | (p41 >= 9610 & p41 <= 9624)) & emp_ci == 1
	replace ocupa_ci = 6 if ((p41 >= 6110 & p41 <= 6340) | (p41 >= 9210 & p41 <= 9216)) & emp_ci == 1
	replace ocupa_ci = 7 if ((p41 >= 7111 & p41 <= 8350) | (p41 >= 9310 & p41 <= 9412)) & emp_ci == 1
	replace ocupa_ci = 8 if (p41 >= 110 & p41 <= 310) & emp_ci == 1
	replace ocupa_ci = 9 if p41 >= 9629 & p41 != . & emp_ci == 1

	*************
	**pension_ci*
	*************
	gen pension_ci = (p72a == 1) /* A todas las per mayores de cinco*/
	replace pension_ci = . if p72a == .

	***************
	*pensionsub_ci*
	***************
	gen pensionsub_ci = (p75 == 1) // Bono de desarollo humano

	************
	*tipopen_ci*
	************
	gen tipopen_ci = .

	**************
	**instpen_ci**
	**************
	gen instpen_ci = .


		**************************
		***VARIABLES DE INGRESO***
		**************************
		*fre p63 p64b p65 p66 p67 p68b p69 p70b p71b p72b p73b p74b p76 p78
		foreach var of varlist p63 p64b p65 p66 p67  ///
		p68b p69 p70b p71b p72b p74b p76 {
		replace `var'=. if `var'==999999 
		}

    ***************
	***ylmpri_ci***
	***************
	gen p65b = p65*-1
	egen ylmpri_ci = rsum(p63 p64b p65b p66 p67) if emp_ci == 1, m
	replace ylmpri_ci =. if p63==. & p64b==. & p65b==. & p66==. & p67==.
	replace ylmpri_ci =. if ylmpri_ci<0
	*foreach var of varlist p63 p64b p65b p66 p67 ylmpri_ci {
	*	summarize `var', detail
	*}

	***************
	***ylmsec_ci***
	***************
	gen ylmsec_ci = p69 if emp_ci == 1

	*****************
	***ylmotros_ci***
	*****************
	gen ylmotros_ci = .

	************
	***ylm_ci***
	************
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	
	****************
	***ylnmpri_ci***
	****************
	gen ylnmpri_ci = p68b if emp_ci == 1

	****************
	***ylnmsec_ci***
	****************
	gen ylnmsec_ci = p70b if emp_ci == 1

	******************
	***ylnmotros_ci***
	******************
	gen ylnmotros_ci = .

	*************
	***ylnm_ci***
	*************
	egen double ylnm_ci =rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	
	*************
	***ynlm_ci***
	*************
	* MGR: agrego ingreso recibido por Bono de Discapacidad Joaquín Gallegos Lara
	egen ynlm_ci = rsum(p71b p72b p73b p74b p76 p78), m
	replace ynlm_ci = . if p71b == . & p72b == . & p73b == . & p74b == . & p76 == . & p78 == .
	replace ynlm_ci = . if ynlm_ci >= 999999

	**************
	***ynlnm_ci***
	**************
	gen ynlnm_ci = .

	*************
	***ytot_ci***
	*************
	egen ytot_ci = rsum(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), m

	************
	***ylm_ch***
	************
	by idh_ch, sort: egen ylm_ch = sum(ylm_ci) if miembros_ci == 1

	*************
	***ylnm_ch***
	*************
	by idh_ch, sort: egen ylnm_ch = sum(ylnm_ci) if miembros_ci == 1

	**************
	***ynlnm_ch***
	**************
	gen ynlnm_ch = .

	*************
	***ynlm_ch***
	*************
	by idh_ch, sort: egen ynlm_ch = sum(ynlm_ci) if miembros_ci==1

	*************
	***ytot_ch***
	*************
	by idh_ch, sort: egen ytot_ch = sum(ytot_ci) if miembros_ci==1

	*****************
	***ylmhopri_ci***
	*****************
	gen ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	**************
	***ylmho_ci***
	**************
	gen ylmho_ci = ylm_ci / (horastot_ci * 4.3)

	*****************
	***nrylmpri_ci***
	*****************
	gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)

	*****************
	***nrylmpri_ch***
	*****************
	by idh_ch, sort: egen nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .

	**************
	***ylmnr_ch***
	**************
	by idh_ch, sort: egen ylmnr_ch = sum(ylm_ci) if miembros_ci == 1
	replace ylmnr_ch = . if nrylmpri_ch == 1

	****************
	***remesas_ci***
	****************
	gen remesas_ci = p74b
	replace remesas_ci = . if p74b >= 999999

	****************
	***remesas_ch***
	****************
	by idh_ch, sort: egen double remesas_ch = sum(remesas_ci) if miembros_ci == 1, missing
	
	*************
	***ypen_ci***
	*************
	gen ypen_ci = p72b if pension_ci == 1
	replace ypen_ci = . if ypen_ci == 999999 

	****************
	***ypensub_ci***
	****************
	gen ypensub_ci = p76 if pensionsub_ci == 1
	replace ypensub_ci = . if ypensub_ci == 999999

		
		****************************
		***VARIABLES DE EDUCACION***
		****************************

	*************
	***aedu_ci***
	*************
	gen aedu_ci = .
	replace aedu_ci = 0 if p10a == 1 | p10a == 2 | p10a == 3
	replace aedu_ci = p10b if p10a == 4 // Años primaria
	replace aedu_ci = p10b - 1 if p10a ==5 // Años educacion básica 1 a 10 nuevos sistema - se resta uno porque considera un año de educacion inicial  
	replace aedu_ci = 0 if p10a == 5 & aedu_ci == -1 // para que no queden en -1 los de 0 años aprobados 
	replace aedu_ci = p10b + 6  if p10a == 6 // secundaria
	replace aedu_ci = p10b + 9  if p10a == 7 // bachillerato
	replace aedu_ci = p10b + 12 if p10a == 8 | p10a == 9 //superior
	replace aedu_ci = p10b + 16 if p10a == 10 // posgrado

	***************
	***edupre_ci***
	***************
	gen edupre_ci = .

	**************
	***eduui_ci***
	**************
	gen eduui_ci = (p12a == 2 & p10a == 9) | (p12a == 2 & p10a == 8)
	replace eduui_ci = . if aedu_ci == . 

	***************
	***eduuc_ci***
	***************
	gen byte eduuc_ci = (p12a == 1 & p10a == 9) | (p12a == 1 & p10a == 8) | (p10a == 10)	
	replace eduuc_ci = . if aedu_ci == . 

	**************
	***eduac_ci***
	**************
	gen eduac_ci = .	
	replace eduac_ci = 1 if p10a == 9 | p10a == 10 
	replace eduac_ci = 0 if p10a == 8

	***************
	***asiste_ci***
	***************
	gen asiste_ci = (p07 == 1)
	replace asiste_ci = . if p07 == .

	***************
	***edupub_ci***
	***************
	gen edupub_ci = .

	***************
	***asispre_ci**
	***************
	* No viene la preguntá pe01 en la base 2018-2025
	gen asispre_ci = .

	**********************
	***razonesnoasis_ci***
	**********************
	gen byte      razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if p09==3 | p09==5
	replace razonesnoasis_ci = 2 if p09==11 | p09==4
	replace razonesnoasis_ci = 3 if p09==7  | p09==8 | p09==9 | p09==12 | p09==15
	replace razonesnoasis_ci = 4 if p09==13 | p09==10
	replace razonesnoasis_ci = 5 if p09==1 | p09==2 | p09==6 | p09==14 | p09==16 | p09==17


		**********************************
		**** VARIABLES DE LA VIVIENDA ****
		**********************************

	************
	***luz_ch***
	************
	gen byte luz_ch = .
	replace luz_ch = 1 if (vi12 == 1 | vi12 == 2)
	replace luz_ch = 0 if (vi12 == 3 | vi12 == 4)

	****************
	***luzmide_ch***
	****************
	gen byte luzmide_ch = .

	****************
	***combust_ch***
	****************
	gen byte combust_ch = 0
	replace combust_ch = 1 if  vi08 == 1 | vi08 == 3 

	*************
	***piso_ch***
	*************
	gen byte piso_ch = .
	replace piso_ch = 0 if vi04a == 7
	replace piso_ch = 1	if vi04a == 1 |vi04a == 2 | vi04a == 3 | vi04a == 4 
	replace piso_ch = 2 if vi04a == 5 | vi04a == 6 | vi04a == 8 	

	**************
	***pared_ch***
	**************
	gen byte pared_ch = . 
	replace pared_ch = 0 if vi05a == 5 | vi05a == 6 | vi05a == 7
	replace pared_ch = 1 if vi05a >= 1 & vi05a <= 4

	**************
	***techo_ch***
	**************
	gen byte techo_ch = .
	replace techo_ch = 0 if vi03a == 5 | vi03a == 6
	replace techo_ch = 1 if vi03a >= 1 & vi03a <= 4

	**************
	***resid_ch***
	**************
	gen byte resid_ch = . 
	replace resid_ch = 0 if vi13 == 1 | vi13 == 2
	replace resid_ch = 1 if vi13 == 4
	replace resid_ch = 2 if vi13 == 3
	replace resid_ch = 3 if vi13 == 5

	*************
	***dorm_ch***
	*************
	*Dado que hay hogares que reportan 0 habitaciones exclusivas para dormir, pues la vivienda está constituída por
	*un sólo ambiente, a estos hogares se les imputa 1 habitación. A los hogares que dicen no tener cuartos exclusivos 
	*para dormir, pero que viven en viviendas de 2 o más habitaciones se les asigna missing
	gen byte dorm_ch = vi07
	replace dorm_ch = 1 if vi07 == 0 & vi06 == 1
	replace dorm_ch = . if vi07 == 0 & vi06 > 1

	****************
	***cuartos_ch***
	****************
	gen cuartos_ch = vi06 if vi06 < 99
		
	***************
	***cocina_ch***
	***************
	gen byte cocina_ch = 1 if vi07b == 1
	replace cocina_ch = 0 if vi07b == 2

	**************
	***telef_ch***
	**************
	gen telef_ch = .
		
	***************
	***refrig_ch***
	***************
	gen refrig_ch = .
			
	**************
	***freez_ch***
	**************
	gen freez_ch = .

	*************
	***auto_ch***
	*************
	gen auto_ch = .

	**************
	***compu_ch***
	**************
	gen compu_ch = .
		
	*****************
	***internet_ch***
	*****************
	gen internet_ch = .

	************
	***cel_ch***
	************
	gen cel_ch = .

	**************
	***vivi1_ch***
	**************
	gen vivi1_ch = 1 if vi02 == 1
	replace vivi1_ch = 2 if vi02 == 2
	replace vivi1_ch = 3 if vi02 >= 3 & vi02 <= 7
	replace vivi1_ch = . if vi02 == .
		
	**************
	***vivi2_ch***
	**************
	gen vivi2_ch = 0
	replace vivi2_ch = 1 if vi02 == 1 | vi02 == 2
	replace vivi2_ch = . if vi02 == .

	*****************
	***viviprop_ch***
	*****************
	gen viviprop_ch = .
	replace viviprop_ch = 0 if vi14 == 1 | vi14 == 2
	replace viviprop_ch = 1 if vi14 == 4
	replace viviprop_ch = 2 if vi14 == 3
	replace viviprop_ch = 3 if vi14 >= 5 & vi14 < .

	****************
	***vivitit_ch***
	****************
	gen vivitit_ch = .

	****************
	***vivialq_ch***
	****************
	gen vivialq_ch = .

	*******************
	***vivialqimp_ch***
	*******************
	gen vivialqimp_ch = .


		***************************
		**** VARIABLES DE WASH ****
		***************************

	****************
	***aguared_ch***
	****************
	gen aguared_ch = (vi10 == 1)
	replace aguared_ch = . if vi10 == .

	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = 0

	*****************
	*aguafuente_ch*
	*****************
	gen aguafuente_ch = 0
	replace aguafuente_ch = 1 if vi10 == 1
	replace aguafuente_ch = 2 if vi10 == 2
	replace aguafuente_ch = 6 if vi10 == 4
	replace aguafuente_ch = 8 if vi10 == 6
	replace aguafuente_ch = 10 if (vi10 == 3 | vi10 == 5 | vi10 == 7)

	*************
	*aguadist_ch*
	*************
	gen aguadist_ch = 0
	replace aguadist_ch = 1 if vi10a == 1
	replace aguadist_ch = 2 if vi10a == 2
	replace aguadist_ch = 3 if vi10a == 3

	**************
	*aguadisp1_ch*
	**************
	gen aguadisp1_ch = 9

	**************
	*aguadisp2_ch*
	**************
	gen aguadisp2_ch = 9

	*************
	*aguatrat_ch*
	*************
	gen aguatrat_ch = .

	*************
	*aguamala_ch*
	*************
	gen aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7 
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10

	*****************
	*aguamejorada_ch*
	*****************
	gen aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7 

	*****************
	***aguamide_ch***
	*****************
	gen aguamide_ch = .
	replace aguamide_ch = 1 if vi101 == 1 | vi10 == 1
	replace aguamide_ch = 0 if vi101 == 2 | (vi101 != 1 &  vi10 != 1)

	*************
	***bano_ch***
	*************
	gen bano_ch = 6
	replace bano_ch = 0 if vi09 == 5 & vi09a != 1
	replace bano_ch = 1 if vi09 == 1
	replace bano_ch = 2 if vi09 == 2
	replace bano_ch = 3 if vi09 == 3
	replace bano_ch = 4 if vi09 == 5 & vi09a == 1
	replace bano_ch = 6 if vi09 == 4

	***************
	***banoex_ch***
	***************
	gen banoex_ch = .

	************
	*sinbano_ch*
	************
	gen sinbano_ch = 3
	replace sinbano_ch = 0 if vi09! = 5 | vi09a == 1
	replace sinbano_ch = 1 if vi09a == 3
	replace sinbano_ch = 2 if vi09a == 2

	*****************
	*banomejorado_ch*
	*****************
	gen banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6


		*****************************
		**** VARIABLES MIGRACIÓN ****
		*****************************

	*****************
	*migrante_ci****
	****************
	gen byte migrante_ci= .
	replace migrante_ci=1 if p15aa == 3
	replace migrante_ci=0 if p15aa != 3

	****************
	*migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.

	****************
	*miglac_ci*
	****************	
	gen miglac_ci = (inlist(p15ab, 32, 44, 52, 68, 76, 84, 152, 170, 188, 214, 222, 320, 328, 332, 340, 388, 484, 558, 591, 600, 604, 740, 780, 858, 862) & migrante_ci == 1) if migrante_ci != .
	replace miglac_ci = 0 if !inlist(p15ab, 32, 44, 52, 68, 76, 84, 152, 170, 188, 214, 222, 320, 328, 332, 340, 388, 484, 558, 591, 600, 604, 740, 780, 858, 862) & migrante_ci == 1
	replace miglac_ci = . if migrante_ci == 0


		***************************
		***VARIABLES DE EXTERNAS***
		***************************	

	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 

	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if pobreza==0
	replace pobre_ine_ci= 1 if pobreza==1

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	
	***********
	***ln_ci***
	***********
	* https://www.ecuadorencifras.gob.ec/pobreza-por-ingresos/
	gen ln_ci = 85.6

	*************
	***lpe_ci ***
	*************
	* https://www.ecuadorencifras.gob.ec/pobreza-por-ingresos/
	gen lpe_ci = 48.24
	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
