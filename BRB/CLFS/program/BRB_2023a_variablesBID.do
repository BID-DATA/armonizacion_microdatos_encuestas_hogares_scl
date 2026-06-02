clear
set more off

*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*
 
global ruta = "\\sapidbshares.file.core.windows.net\\idbrestrictedshares\\SCL_DATAFILES_RESTRICTED"

local PAIS BRB
local ENCUESTA LFS
local ANO "2023"
local ronda a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES
País: Barbados
Encuesta: BSLC 2023
Round: 
Autores: Ricardo Sierra  ricardo.sierra@gmail.com
Modificación 2026: Oscar Jaramillo oscarj@iadb.org
Última modificación:

****************************************************************************/
***************************************************************************
****************************************************************************/

use `base_in', clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=2

	***************
	* REGION PAIS *
	***************
	g region_c=PARNO
	label define region_c 201 "St Michael" 202 "Christ Church" 203 "St George" 204 "St Philip" 205 "St John" 206 "St James" 207 "St Thomas" 208 "St Joseph" 209 "St Andrew" 210 "sS Peter" 211 "St Lucy"
	label values region_c region_c

	***********
	*  PAIS   *
	***********
	gen pais_c="BRB"

	***********
	*  ANIO   *
	***********
	gen anio_c = 2023

	**********************
	* MES DE LA ENCUESTA *
	**********************
	gen mes_c = MONTH

	***************
	*    ZONA     *
	***************
	gen byte zona_c=.

	***************
	* estrato_ci  *
	***************
	gen byte estrato_ci = STRATUM

	**********************
	******** UPM  ********
	**********************
	gen upm_ci = .

******************************
*  IDENTIFICADOR DEL HOGAR   *
******************************
*tostring hhno, replace
*gen hh_id = string(real(hhno),"%03.0f")
*egen idh_ch= concat(edno hh_id rndno)
egen idh_ch = concat(RNDNO EDNO PARNO STRATUM HHNO)
tostring idh_ch, replace

*******************************
* IDENTIFICADOR DEL INDIVIDUO *
*******************************
egen idp_ci = concat(RNDNO EDNO PARNO STRATUM HHNO INDIVNO)
tostring idp_ci, replace

*************************
* factor_ch *
*************************
gen factor_ch = Wtfactor

/*sum Wtfactor
scalar pob=r(sum)
gen pop=Wtfactor*(282335/pob) // población BRB 2023
sum pop
ret list
gen factor_ch=pop 
drop pop*/


	*************************
	* factor_ci *
	*************************
	gen factor_ci = factor_ch



****************************
***VARIABLES DEMOGRAFICAS***
****************************

	***********
	*  SEXO   *
	***********
	gen sexo_ci = LSEX

	***********
	*  EDAD   *
	***********
	*1896 valores perdidos.
	gen edad_ci=LAGE

	************************************
	*  RELACION CON EL JEFE DE HOGAR   *
	************************************
	gen relacion_ci = .
	replace relacion_ci = 1 if RELHD == 0  // Head
	replace relacion_ci = 2 if RELHD == 1  // Spouse/partner
	replace relacion_ci = 3 if inlist(RELHD, 2, 3)  // Son/daughter
	replace relacion_ci = 4 if RELHD == 4  // Other relatives
	replace relacion_ci = 5 if inlist(RELHD, 5, 6, 8)     // Other non-relatives


	******************
	** miembros_ci ** 
	***************** 
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci=1 if (relacion_ci>=1 & relacion_ci<=4)
		
	*************
	*miembros_one_ci*
	*************
    gen byte miembros_one_ci=.

	*******************
	*  ESTADO CIVIL   *
	*******************
	gen civil_ci = .
	replace civil_ci = 1 if MARSTAT == 5                // Soltero (Never Married)
	replace civil_ci = 2 if inlist(MARSTAT, 1, 2)       // Unión formal (Married) o informal (Common-law)
	replace civil_ci = 3 if inlist(MARSTAT, 3, 4)       // Divorciado o Separado
	replace civil_ci = 4 if MARSTAT == 6                // Viudo

	*********
	*jefe_ci*
	*********
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

	*************
	*clasehog_ch*
	*************
    gen byte clasehog_ch=0
    **** unipersonal
    replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
    **** nuclear   
    replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
    **** ampliado
    replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
    **** compuesto  
    replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
    **** corresidente
    replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch*
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci!=.))
	
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


			
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	*********
	*afro_ci*
	*********
	gen byte afro_ci = .
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 	

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =. 
	
	
	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	
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
 	gen byte afroind_jefe = afroind_ci if relacion_ci==1
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
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISO3pais_dis_ci*
	******************
	gen byte BRB_dis_ci = .



	**********************************
	***VARIABLES DE MERCADO LABORAL***
	****************************


	**************************
	* CONDICION DE OCUPACION *
	**************************
	gen condocup_ci = .
	replace condocup_ci = 1 if actvstat == 10
	replace condocup_ci = 2 if actvstat == 20
	replace condocup_ci = 3 if inlist(actvstat, 31, 32 33)
	replace condocup_ci = 4 if edad_ci < 15


	**************************
	* CATEGORIA DE INACTIVIDAD  *
	**************************
	*Jubilados, pensionados
	gen categoinac_ci = .
	replace categoinac_ci = 1 if (actvstat == 33 & condocup_ci == 3)
	replace categoinac_ci = 2 if (actvstat == 32 & condocup_ci == 3)
	replace categoinac_ci = 3 if (actvstat == 31 & condocup_ci == 3)
	replace categoinac_ci = 4 if inlist(actvstat, 34, 35) 

	************
	* OCUPADO  *
	************
	gen emp_ci = (condocup_ci == 1)

	***********
	* CESANTE *
	***********
	gen cesante_ci = .
	replace cesante_ci = 1 if condocup_ci == 2 & EVERWKD == 1
	replace cesante_ci = 0 if condocup_ci == 2 & EVERWKD == 2


	***************
	* DESOCUPADO  *
	***************
	gen desemp_ci = . 
	replace desemp_ci = 1 if condocup_ci == 2

	*****************************
	* TRABAJA MENOS DE 30 HORAS *
	*****************************
	gen subemp_ci = .
	replace subemp_ci = 1 if condocup_ci == 1 & HRSWRKD <= 8 & WILLING == 1 & ABLE == 1
	replace subemp_ci = 0 if condocup_ci == 1 & subemp_ci == .


	***********************************
	* DURACION DEL DESEMPLEO EN MESES *
	***********************************		
	gen durades_ci = .
	replace durades_ci = 0    if condocup_ci == 2 & LSTLOOK == 1  // Never looked → 0
	replace durades_ci = 0.5  if condocup_ci == 2 & LSTLOOK == 2  // 1 month or less → 0.5
	replace durades_ci = 2.5  if condocup_ci == 2 & LSTLOOK == 3  // 2-3 months → midpoint
	replace durades_ci = 6    if condocup_ci == 2 & LSTLOOK == 4  // 4 months or more → 6 


	***********************************
	* POBLACION ECONOMICAMENTE ACTIVA *
	***********************************
	gen pea_ci = .
	replace pea_ci=1 if inlist(condocup_ci, 1, 2)
	replace pea_ci=1 if inlist(condocup_ci, 3, 4)


	**********************
	*  NÚMERO DE EMPLEOS *
	**********************
	gen nempleos_ci = .
	replace nempleos_ci = 1 if condocup_ci == 1 & TWOJOBS == 2
	replace nempleos_ci = 2 if condocup_ci == 1 & TWOJOBS == 1


	*****************************************
	* ANTIGUEDAD EN LA ACTIVIDAD PRINCIPAL  *
	*****************************************
	* NO EXISTE LA PREGUNTA
	gen antiguedad_ci = .

	****************
	* DESALENTADOS *
	****************
	gen desalent_ci = .
	replace desalent_ci = 1 if condocup_ci == 3 & REASNSK == 2
	replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .


	**********************************************
	* HORAS TRABAJADAS EN LA ACTIVIDAD PRINCIPAL *
	**********************************************
	gen horaspri_ci = .

	replace horaspri_ci = 0    if condocup_ci == 1 & HRSWRKD == 1   // None
	replace horaspri_ci = 2.5  if condocup_ci == 1 & HRSWRKD == 2   // Under 5
	replace horaspri_ci = 7    if condocup_ci == 1 & HRSWRKD == 3   // 5-9
	replace horaspri_ci = 12   if condocup_ci == 1 & HRSWRKD == 4   // 10-14
	replace horaspri_ci = 17   if condocup_ci == 1 & HRSWRKD == 5   // 15-19
	replace horaspri_ci = 22   if condocup_ci == 1 & HRSWRKD == 6   // 20-24
	replace horaspri_ci = 27   if condocup_ci == 1 & HRSWRKD == 7   // 25-29
	replace horaspri_ci = 32   if condocup_ci == 1 & HRSWRKD == 8   // 30-34
	replace horaspri_ci = 37   if condocup_ci == 1 & HRSWRKD == 9   // 35-39
	replace horaspri_ci = 42   if condocup_ci == 1 & HRSWRKD == 10  // 40-44
	replace horaspri_ci = 48   if condocup_ci == 1 & HRSWRKD == 11  // 45+ (conservative)
	* HRSWRKD == 99 (Not stated) → remains missing

	**************************
	* TOTAL HORAS TRABAJADAS *
	**************************
	gen horastot_ci = horaspri_ci

	****************************************************
	* TRABAJA MENOS DE 30 HORAS Y NO DESEA TRABAJAR MAS*
	****************************************************
	gen tiempoparc_ci = .

	* 1. Voluntary Part-time: < 30 hours AND does NOT want more work
	* Note: WILLING == 2 means "No" (not willing/wanting more hours)
	replace tiempoparc_ci = 1 if condocup_ci == 1 & horaspri_ci < 30 & WILLING == 2

	* 0. Rest of the employed population
	replace tiempoparc_ci = 0 if condocup_ci == 1 & tiempoparc_ci == .

	replace tiempoparc_ci=. if emp_ci==0
	* NOTA. SE CALCULA SOLO PARA LA ACTIVIDAD PRINCIPAL

	*********************************
	* CATEGORIA OCUPACION PRINCIPAL *
	*********************************
	gen categopri_ci = .
	replace categopri_ci = 1 if condocup_ci == 1 & EMPLSTAT == 1
	replace categopri_ci = 2 if condocup_ci == 1 & EMPLSTAT == 4
	replace categopri_ci = 3 if condocup_ci == 1 & inlist(EMPLSTAT, 2, 3, 6)
	replace categopri_ci = 0 if condocup_ci == 1 & EMPLSTAT == 7

	*********************************
	* CATEGORIA OCUPACION SECUNDARIA*
	*********************************
	gen byte categosec_ci = .
	replace categosec_ci = 1 if condocup_ci == 1 & EMPL2STAT == 1 //Employer
	replace categosec_ci = 2 if condocup_ci == 1 & EMPL2STAT == 4 //Self-employed / Own-account
	replace categosec_ci = 3 if condocup_ci == 1 & inlist(EMPL2STAT, 2, 3, 6) //Government + Private + Apprentice
	replace categosec_ci = 0 if condocup_ci == 1 & EMPL2STAT == 7


	*********************************
	*  RAMA DE ACTIVIDAD PRINCIPAL  *
	*********************************
	gen rama_ci = .
	replace rama_ci = 1 if condocup_ci == 1 & inrange(INDUS, 1, 3)
	replace rama_ci = 2 if condocup_ci == 1 & inrange(INDUS, 5, 9)
	replace rama_ci = 3 if condocup_ci == 1 & inrange(INDUS, 10, 33)
	replace rama_ci = 4 if condocup_ci == 1 & inrange(INDUS, 35, 39)
	replace rama_ci = 5 if condocup_ci == 1 & inrange(INDUS, 41, 43)
	replace rama_ci = 6 if condocup_ci == 1 & inrange(INDUS, 45, 47) | inrange(INDUS, 55, 56)
	replace rama_ci = 7 if condocup_ci == 1 & inrange(INDUS, 49, 53)
	replace rama_ci = 8 if condocup_ci == 1 & inrange(INDUS, 64, 82)
	replace rama_ci = 9 if condocup_ci == 1 & inrange(INDUS, 84, 99)


	*********************************
	*  TRABAJA EN EL SECTOR PUBLICO *
	*********************************
	gen spublico_ci = .
	replace spublico_ci = 1 if condocup_ci == 1 & EMPLSTAT == 2
	replace spublico_ci = 0 if condocup_ci == 1 & inlist(EMPLSTAT, 1, 3, 4, 6, 7)

	*************
	* tamemp_ci *
	*************
	gen tamemp_ci = .

	*********************************
	*  COTIZA A LA SEGURIDAD SOCIAL *
	*********************************
	gen cotizando_ci = .

	**********************************
	* AFILIADO A LA SEGURIDAD SOCIAL *
	**********************************
	gen afiliado_ci = .

	**************
	* instcot_ci *
	**************
	gen instcot_ci = .

	*********************
	* TRABAJADOR FORMAL *
	*********************
	gen byte formal_ci = .
	replace formal_ci = 1 if (cotizando_ci==1|afiliado_ci==1) & condocup_ci==1
	replace formal_ci = 0 if cotizando_ci==0 & (condocup_ci==1 | condocup_ci==2)

	********************
	* TIPO DE CONTRATO *
	********************
	gen tipocontrato_ci = .

	*****************************
	* TIPO DE OCUPACION LABORAL *
	*****************************
	gen ocupa_ci = .

	* Auxiliars
	gen occ1d = floor(OCCUP/1000)
	gen occ2d = floor(OCCUP/100)

	replace ocupa_ci = 1 if condocup_ci == 1 & inlist(occ1d, 2, 3)
	replace ocupa_ci = 2 if condocup_ci == 1 & occ1d == 1
	replace ocupa_ci = 3 if condocup_ci == 1 & occ1d == 4
	replace ocupa_ci = 4 if condocup_ci == 1 & inlist(occ2d, 52)
	replace ocupa_ci = 5 if condocup_ci == 1 & occ1d == 5 & ocupa_ci == .
	replace ocupa_ci = 6 if condocup_ci == 1 & occ1d == 6
	replace ocupa_ci = 7 if condocup_ci == 1 & inlist(occ1d, 7, 8, 9)
	replace ocupa_ci = 8 if condocup_ci == 1 & occ1d == 0
	replace ocupa_ci = 9 if condocup_ci == 1 & OCCUP == 9999


	********************************************
	* RECIBE PENSION O JUBILACION CONTRIBUTIVA *
	********************************************
	gen pension_ci = .
	replace pension_ci = 1 if SCINCOME == 1 | USINCOME == 1 //Main source of livelihood is Pension
	replace pension_ci = 0 if (inrange(SCINCOME, 2, 7) | inrange(USINCOME, 2, 7)) & pension_ci == . //Other sources reported


	***********************************************
	* RECIBE PENSION O JUBILACION NO CONTRIBUTIVA *
	***********************************************
	gen pensionsub_ci = .
	* 1. Non-contributory pension (proxy: public assistance)
	replace pensionsub_ci = 1 if SCINCOME == 7 | USINCOME == 7
	* 0. Rest of the population
	replace pensionsub_ci = 0 if (inrange(SCINCOME,1,6) | inrange(USINCOME,1,6)) & pensionsub_ci == .

	**************
	* tipopen_ci *
	**************
	g tipopen_ci = .

	************************************************
	*INSTITUCION QUE OTORGA LA PENSION O JUBILACION*
	************************************************
	gen instpen_ci = .


****************************
***VARIABLES DE INGRESO***
****************************

	*************************************
	* INGRESO MONETARIO MENSUAL LABORAL *
	*************************************
	gen double ylmpri_ci = .

	* Weekly bracket midpoint, then monthlyize
	replace ylmpri_ci = 140    *(52/12) if condocup_ci == 1 & EARNGS == 1
	replace ylmpri_ci = 249.5  *(52/12) if condocup_ci == 1 & EARNGS == 2
	replace ylmpri_ci = 349.5  *(52/12) if condocup_ci == 1 & EARNGS == 3
	replace ylmpri_ci = 449.5  *(52/12) if condocup_ci == 1 & EARNGS == 4
	replace ylmpri_ci = 549.5  *(52/12) if condocup_ci == 1 & EARNGS == 5
	replace ylmpri_ci = 649.5  *(52/12) if condocup_ci == 1 & EARNGS == 6
	replace ylmpri_ci = 749.5  *(52/12) if condocup_ci == 1 & EARNGS == 7
	replace ylmpri_ci = 849.5  *(52/12) if condocup_ci == 1 & EARNGS == 8
	replace ylmpri_ci = 949.5  *(52/12) if condocup_ci == 1 & EARNGS == 9
	replace ylmpri_ci = 1150   *(52/12) if condocup_ci == 1 & EARNGS == 10
	replace ylmpri_ci = 1625   *(52/12) if condocup_ci == 1 & EARNGS == 11

	* Missing for not stated
	replace ylmpri_ci = . if condocup_ci == 1 & EARNGS == 99

	* Non-remunerated workers
	replace ylmpri_ci = 0 if categopri_ci == 4

	* Non-employed PET
	replace ylmpri_ci = 0 if condocup_ci != 1 & condocup_ci != .

	*************************************************
	* INGRESO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
	*************************************************
	gen ylmsec_ci = .

	************************************
	* INGRESO MENSUAL OTRAS ACTIVIDADES*
	************************************
	gen ylmotros_ci=.

	************************************
	* INGRESO MENSUAL TODAS ACTIVIDADES*
	************************************
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	*******************************
	* INGRESO MENSUAL NO MONETARIO*
	*******************************
	gen ylnmpri_ci = .

	****************************************************
	* INGRESO NO MONETARIO MENSUAL ACTIVIDAD SECUNDARIA*
	****************************************************
	gen ylnmsec_ci=.

	*************************************************
	* INGRESO MENSUAL NO MONETARIO OTRAS ACTIVIDADES*
	*************************************************
	gen ylnmotros_ci=.

	*************************************************
	* INGRESO MENSUAL NO MONETARIO TODAS ACTIVIDADES*
	*************************************************
	gen ylnm_ci = ylnmpri_ci + ylnmsec_ci + ylnmotros_ci

	*************************************************
	* INGRESO MENSUAL NO LABORAL OTRAS ACTIVIDADES  *
	*************************************************
	gen ynlm_ci = . 

	**************************************************************
	* INGRESO MENSUAL NO LABORAL NO MONETARIO OTRAS ACTIVIDADES  *
	**************************************************************
	gen ynlnm_ci= .

	***********
	* ytot_ci *
	***********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi
	
	************************************
	* INGRESO MENSUAL LABORAL DEL HOGAR*
	************************************
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1

	**************************************************
	* INGRESO MENSUAL LABORAL NO MONETARIO DEL HOGAR *
	**************************************************
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi 
	
	*****************************************************
	* INGRESO MENSUAL NO LABORAL NO MONETARIO DEL HOGAR *
	*****************************************************
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci == 1, mi 

	**************************************************
	* INGRESO MENSUAL NO LABORAL MONETARIO DEL HOGAR *
	**************************************************
	gen ynlm_ch = .

	***********************************
	* INGRESO MENSUAL TOTAL DEL HOGAR *
	***********************************
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	*****************************************************
	* INGRESO LABORAL POR HORA EN LA ACTIVIDAD PRINCIPA *
	*****************************************************
	gen double ylmhopri_ci = .
	replace ylmhopri_ci = ylmpri_ci / (horaspri_ci * (52/12)) if condocup_ci == 1 & ylmpri_ci != . & horaspri_ci > 0 & horaspri_ci < .
	replace ylmhopri_ci = . if horaspri_ci == 0
	replace ylmhopri_ci = 0 if categopri_ci == 4


	*****************************************************
	* INGRESO LABORAL POR HORA EN TODAS LAS ACTIVIDADES *
	*****************************************************
	gen byte ylmho_ci = ylm_ci / (4.3 * horastot_ci) 
	replace ylmho_ci = . if ylmho_ci <= 0 


	*******************
	*** nrylmpri_ci ***
	*******************
	gen byte nrylmpri_ci = . 
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1 
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1

	*******************
	*** nrylmpri_ch ***
	*******************
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1 
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < . 
	replace nrylmpri_ch = . if nrylmpri_ch == .

	***************************
	* REMESAS EN MONEDA LOCAL *
	***************************
	gen remesas_ci = .

	************************************
	* REMESES EN MONEDA LOCAL DEL HOGAR*
	************************************
	by idh_ch, sort: egen byte remesas_ch = sum(remesas_ci) if miembros_ci == 1 


	************************************
	* INGRESO POR PENSION CONTRIBUTIVA *
	************************************
	gen ypen_ci=.

	***************************************
	* INGRESO POR PENSION NO CONTRIBUTIVA *
	***************************************
	gen ypensub_ci=.



****************************
***VARIABLES DE EDUCACION***
****************************

	*************
	***aedu_ci*** 
	*************
	gen aedu_ci = .
	replace aedu_ci = 0 if EDUCLEV == 0
	replace aedu_ci = 3 if EDUCLEV == 1
	replace aedu_ci = 9 if EDUCLEV == 2
	replace aedu_ci = 13 if EDUCLEV == 3
	replace aedu_ci = 14 if EDUCLEV == 4
	replace aedu_ci = . if EDUCLEV == 5
	replace aedu_ci = . if EDUCLEV == 9

	**************
	***eduui_ci***
	**************
	gen eduui_ci = .

	**************
	***eduuc_ci***
	**************
	* proxy
	gen byte eduuc_ci = .
	replace eduuc_ci = 1 if inlist(EDUCLEV, 3, 4)
	replace eduuc_ci = 0 if inrange(EDUCLEV, 0, 2)
	replace eduuc_ci = . if EDUCLEV == 5 | EDUCLEV == 9

	***************
	***edupre_ci***
	***************
	gen edupre_ci=.	 

	**************
	***eduac_ci***
	**************
	gen byte eduac_ci = .
	replace eduac_ci = 1 if EDUCLEV == 4
	replace eduac_ci = 0 if EDUCLEV == 3


	***************
	***asiste_ci***
	***************
	gen asiste_ci = .
	replace asiste_ci = 1 if CTRAINING == 1

	***************
	***edupub_ci***
	***************
	* proxt
	gen byte edupub_ci = .
	replace edupub_ci = 1 if inlist(PLACETR,12,13,14,15,16)
	replace edupub_ci = . if inlist(PLACETR,11,21,31,41,51,81)
	replace edupub_ci = . if inlist(PLACETR,19,22,32,42,52)

	****************
	***asispre_ci***
	****************
	gen asispre_ci = .

	**********************
	***razonesnoasis_ci***
	**********************
	gen razonesnoasis_ci = .


****************************
***VARIABLES DE VIVIENDA***
****************************	

	************
	** luz_ch **
	************
	gen luz_ch = .

	****************
	** luzmide_ch **
	****************
	gen byte luzmide_ch = .

	****************
	** combust_ch **
	****************
	gen byte combust_ch = .

	*************
	** piso_ch **
	*************
	gen byte piso_ch = .

	**************
	** pared_ch **
	**************
	gen byte pared_ch = .

	**************
	** techo_ch **
	**************
	gen byte techo_ch = .

	**************
	** resid_ch **
	**************
	gen byte resid_ch = .

	**************
	** dorm_ch ***
	**************
	gen dorm_ch = .

	****************
	** cuartos_ch **
	****************
	gen cuartos_ch = .

	***************
	** cocina_ch **
	***************
	gen byte cocina_ch = .

	***************
	** telef_ch **
	***************
	gen byte telef_ch = .

	***************
	** refrig_ch **
	***************
	gen byte refrig_ch = .

	**************
	** freez_ch **
	**************
	gen byte freez_ch = .

	*************
	** auto_ch **
	*************
	gen byte auto_ch = .

	**************
	** compu_ch **
	**************
	gen byte compu_ch = .

	*****************
	** internet_ch **
	*****************
	gen byte internet_ch = .

	************
	** cel_ch **
	************
	gen byte cel_ch = .

	*************
	** vivi1_ch **
	*************
	gen byte vivi1_ch = .

	**************
	** vivi2_ch **
	**************
	gen byte vivi2_ch = .

	*****************
	** viviprop_ch **
	*****************
	gen byte viviprop_ch = .
	replace viviprop_ch = 1 if LNDTNURE == 1
	replace viviprop_ch = 0 if inlist(LNDTNURE, 2, 3, 4, 5)
	replace viviprop_ch = . if LNDTNURE == 9

	*****************
	** vivitit_ch **
	*****************
	gen byte vivitit_ch = .
	replace vivitit_ch = 1 if LNDTNURE == 1
	replace vivitit_ch = 0 if inlist(LNDTNURE, 2, 3, 4, 5)
	replace vivitit_ch = . if LNDTNURE == 9

	****************
	** vivialq_ch **
	****************
	gen byte vivialq_ch = .
	replace vivialq_ch = 1 if LNDTNURE == 3
	replace vivialq_ch = 0 if inlist(LNDTNURE, 1, 2, 4, 5)
	replace vivialq_ch = . if LNDTNURE == 9

	*******************
	** vivialqimp_ch **
	*******************
	gen byte vivialqimp_ch = .


*************************
*** VARIABLES DE WASH ***
*************************
	**************
	** aguared_ch **
	**************
	gen byte aguared_ch = .

	*******************
	** aguafconsumo_ch **
	*******************
	gen double aguafconsumo_ch = .

	*******************
	** aguafuente_ch **
	*******************
	gen byte aguafuente_ch = .

	*******************
	** aguadist_ch **
	*******************
	gen byte aguadist_ch = .

	*******************
	** aguadisp1_ch **
	*******************
	gen byte aguadisp1_ch = .

	*******************
	** aguadisp2_ch **
	*******************
	gen byte aguadisp2_ch = .

	*******************
	** aguatrat_ch **
	*******************
	gen byte aguatrat_ch = .

	*******************
	** aguamala_ch **
	*******************
	gen byte aguamala_ch = 2 
	replace aguamala_ch = 0 if aguafuente_ch<=7 
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=. 

	*******************
	** aguamejorada_ch **
	*******************
	gen byte aguamejorada_ch = 2 
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10 
	replace aguamejorada_ch = 1 if aguafuente_ch<=7 

	*******************
	** aguamide_ch **
	*******************
	gen byte aguamide_ch = .

	***********
	** bano_ch **
	***********
	gen byte bano_ch = .

	*************
	** banoex_ch **
	*************
	gen byte banoex_ch = .

	**************
	** sinbano_ch **
	**************
	gen byte sinbano_ch = .

	******************
	** banomejorado_ch **
	******************
	gen byte banomejorado_ch= 2 
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0 
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6 


****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci= .
	replace migrante_ci=1 if Ntlty!=0 & Ntlty!=9
	replace migrante_ci=0 if Ntlty==0
	replace migrante_ci= . if Ntlty==. 
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = .
	replace miglac_ci=1 if migrante_ci==1 & (Ntlty==1 |Ntlty==2) 
	replace miglac_ci=0 if migrante_ci==1 & Ntlty>2
	replace miglac_ci=. if migrante_ci!=1 

	

****************************
***VARIABLES DE EXTERNAS***
****************************	

	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 

	****************
	 * pobre_ine_ci*
	****************	
	gen byte pobre_ine_ci= . 

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 


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
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch   ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
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

