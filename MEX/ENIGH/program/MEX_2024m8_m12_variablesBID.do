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
	gen zona_c= 1      if tam_loc<="3"
	replace zona_c = 0 if tam_loc=="4"
	
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
	tostring idp_ci, replace format ("%20.0f") 
	duplicates report idh_ch idp_ci

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
	
	******************************
	*	miembros_one_ci
	******************************
	gen byte miembros_one_ci = .

	replace miembros_one_ci = 1 if inrange(relacion_ci,1,6)
	replace miembros_one_ci = 1 if miembros_one_ci == .	
	
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
	replace ind_ci = 1 if etnia  == 1
	replace ind_ci = 0 if etnia  == 2

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
	egen byte afro_ch = min(_afro_j), by(idh_ch)
	drop _afro_j

	********
	* ind_ch 
	********
	gen  byte _ind_j = ind_ci       if jefe_ci==1
	egen byte ind_ch  = min(_ind_j), by(idh_ch)
	drop _ind_j

	****************
	* noafroind_ch 
	****************
	gen  byte _noai_j = noafroind_ci if jefe_ci==1
	egen byte noafroind_ch = min(_noai_j), by(idh_ch)
	drop _noai_j
	
	****************
	* afroind_ano_c
	****************
	gen int afroind_ano_c = 2010

	************
	* afroind_ci 
	************
	gen afroind_ci =. 
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1

	************
	* afroind_ch 
	************
	gen  byte _aind_j = afroind_ci  if jefe_ci==1
	egen byte afroind_ch = min(_aind_j), by(idh_ch)
	drop _aind_j
	

	********
	* dis_ci 
	********
	gen byte dis_ci = 0
	local d disc_ver disc_oir disc_brazo disc_camin disc_apren disc_vest disc_habla disc_acti
	foreach v of local d {
		replace `v' = "" if `v'=="&"
		destring `v', replace
		replace dis_ci = 1 if inlist(`v',2,3,4)
		}

	egen nvalid = rownonmiss(disc_ver disc_oir disc_brazo disc_camin disc_apren disc_vest disc_habla disc_acti)
	replace dis_ci = . if nvalid==0
	
	**********
	* disWG_ci 
	**********
	gen byte disWG_ci = 0

	local d disc_ver disc_oir disc_brazo disc_camin disc_apren disc_vest disc_habla disc_acti
	foreach v of local d {
		replace disWG_ci = 1 if inlist(`v', 3, 4)
	}

	replace disWG_ci = . if nvalid == 0
	drop nvalid
				  
	********
	* dis_ch 
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch)

	******************
	* ISOalpha3_dis_ci 
	******************
	gen byte MEX_dis_ci = dis_ci
	
**********************************
***VARIABLES DE MERCADO LABORAL***
**********************************

	*************
	*condocup_ci*
	*************
	gen trabajon=real(trabajo_mp)
	gen mot_ausen=real(motivo_aus)

	gen condocup_ci=.
	replace condocup_ci=4 if edad<12
	replace condocup_ci=1 if (trabajon==1) | (mot_ausen <=6) & edad_ci>=12
	replace condocup_ci=2 if (act_pnea1=="1" | act_pnea2=="1" ) & edad_ci>=12
	replace condocup_ci=3 if trabajon!=. & condocup_ci==.
	
	*******************
	***categoinac_ci***
	*******************
	* Solo para inactivos
	gen categoinac_ci = .
	replace categoinac_ci = 1 if ((act_pnea1=="2" | act_pnea2=="2") & condocup_ci==3) 
	replace categoinac_ci = 2 if  ((act_pnea1=="4" | act_pnea2=="4") & condocup_ci==3) & categoinac_ci ==.
	replace categoinac_ci = 3 if  ((act_pnea1=="3" | act_pnea2=="3") & condocup_ci==3) & categoinac_ci ==.
	replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3) & categoinac_ci ==.
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	
	gen byte trabajo_antes = .
	destring ct_futuro, replace
	replace trabajo_antes = 1 if ct_futuro == 8
	replace trabajo_antes = 0 if ct_futuro != 8 & ct_futuro != .

	replace cesante_ci = 1 if (trabajo_antes == 1 & condocup_ci == 2) 
	replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .

	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = .

	****************
	***durades_ci***
	****************
	gen byte durades_ci= .

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)

	****************
	*** nempleos_ci***
	****************
	destring num_trabaj pea_ci, replace
	gen byte nempleos_ci = num_trabaj if pea_ci == 1

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .

	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .

	***************
	***horaspri_ci***
	***************	
	gen horaspri_ci=htrab1 if emp_ci==1 & htrab1<148
	replace horaspri_ci = . if emp_ci == 0		
	
	***************
	***horastot_ci ***
	***************	
	egen horastot_ci= rsum(htrab1 htrab2)  if emp_ci==1 
	replace horastot_ci = . if emp_ci == 0		

	***************
	***tiempoparc_ci ***
	***************	
	gen byte tiempoparc_ci = .
	
	***************
	***categopri_ci ***
	***************	
	gen categopri_ci=.
	replace categopri_ci=1 if personal1=="1" & condocup_ci==1
	replace categopri_ci=2 if  categopri_ci!=1 & indep1=="1" & condocup_ci==1
	replace categopri_ci=3 if subor1=="1" & condocup_ci==1
	replace categopri_ci=4 if pago1== "2"  & condocup_ci==1
	replace categopri_ci=. if emp_ci!=1	
	
	***************
	***categosec_ci ***
	***************	
	gen categosec_ci=. 
	replace categosec_ci=1 if personal2=="1"
	replace categosec_ci=2 if indep2=="1"
	replace categosec_ci=3 if subor2=="1"
	replace categosec_ci=4 if pago2== "2" 
	replace categosec_ci=. if emp_ci!=1
	
	***************
	***rama_ci ***
	***************	
	tostring scian1, replace
	gen ramat=real(substr(scian1,1,3))
	gen rama_ci=1 if ramat>=111 & ramat<=115
	replace rama_ci=2 if ramat>=211 & ramat<=213
	replace rama_ci=3 if ramat>=311 & ramat<=339
	replace rama_ci=4 if ramat>=221 & ramat<=222
	replace rama_ci=5 if ramat>=236 & ramat<=238
	replace rama_ci=6 if ramat>=400 & ramat<=469
	replace rama_ci=7 if ramat>=481 & ramat<=493
	replace rama_ci=9 if ramat>=511 & ramat<=932
	replace rama_ci=8 if ramat>=520 & ramat<=530
	
	***************
	***spublico_ci ***
	***************	
	destring clas_emp1, replace
	gen spublico_ci=(clas_emp1==3 & condocup_ci==1)		
	
	***************
	***tamemp_ci ***
	***************	
	destring tam_emp1, replace
	gen tamemp_ci = 1 if tam_emp1==1 | tam_emp1==2
	replace tamemp_ci = 2 if (tam_emp1>=3 & tam_emp1<=7)
	replace tamemp_ci = 3 if (tam_emp1>7 & tam_emp1<12)
	
	***************
	***cotizando_ci***
	***************	
	gen byte cotizando_ci = .

	replace cotizando_ci = 1 if condocup_ci==1 & inscr_1=="1"   // cotiza por el trabajo
	replace cotizando_ci = 0 if condocup_ci==1 & inscr_1!="1"   // no cotiza
	
	***************
	***instcot_ci***
	***************	
	gen str20 instcot_ci = ""

	replace instcot_ci = "IMSS"            if inst_1 == "1"
	replace instcot_ci = "ISSSTE"          if inst_2 == "1" | inst_3 == "1"
	replace instcot_ci = "PEMEX"           if inst_4 == "1"
	replace instcot_ci = "IMSS-Bienestar"  if inst_5 == "1"
	replace instcot_ci = "Otra pública"    if inst_6 == "1"
	replace instcot_ci = "Privada"         if inst_7 == "1"
	replace instcot_ci = "Otra"            if inst_8 == "1"
	replace instcot_ci = "Sin afiliación"  if inst_9 == "1"

	***************
	***afiliado_ci***
	***************	
	destring pres_* servmed* inscr_* inst_* atemed tam_emp1  contrato1, replace
	gen afiliado_ci=0 if condocup_ci==1 | condocup_ci==2  
	replace afiliado_ci=1 if (pres_81==8 | pres_82==8) /* inscrito en prestaciones de salud por trabajo*/
	
	**************
	***formal_ci***
	**************
	gen formal=1 if cotizando_ci==1

	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI"
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GUA" & anio_c>1998
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008

	gen byte formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)	
	recode formal_ci .=0 if (condocup_ci==1 | condocup_ci==2)
	
	*******************
	***tipocontrato_ci***
	*******************
	destring contrato1 tipocontr1, replace
	g tipocontrato_ci=.
	replace tipocontrato_ci=1 if (contrato1==1 & tipocontr1==2) & categopri_ci==3
	replace tipocontrato_ci=2 if (contrato1==1 & tipocontr1==1) & categopri_ci==3
	replace tipocontrato_ci=3 if (contrato1==2 | tipocontrato_ci==.) & categopri_ci==3      		
	
	**************
	***ocupa_ci***
	**************
	tostring sinco1, replace
	gen ocupa=real(substr(sinco1,1,2))
	gen ocupa_ci=.
	replace ocupa_ci=1 if (ocupa>=21 & ocupa<=29) & emp_ci==1
	replace ocupa_ci=2 if (ocupa>=9 & ocupa<=19) & emp_ci==1
	replace ocupa_ci=3 if (ocupa>=31 & ocupa<=39) & emp_ci==1
	replace ocupa_ci=4 if ((ocupa>=41 & ocupa<=49) | ocupa==95) & emp_ci==1
	replace ocupa_ci=5 if ((ocupa>=51 & ocupa<=53) | ocupa==59 | ocupa==96) & emp_ci==1
	replace ocupa_ci=6 if ((ocupa>=61 & ocupa<=69) | ocupa==91) & emp_ci==1
	replace ocupa_ci=7 if ((ocupa>=71 & ocupa<=79) | (ocupa>=81 & ocupa<=89) | (ocupa>=92 & ocupa<=94) | ocupa==97) & emp_ci==1
	replace ocupa_ci=8 if (ocupa==54) & emp_ci==1
	replace ocupa_ci=9 if (ocupa==98 | ocupa==99) & emp_ci==1
	
	**************
	**pension_ci***
	**************
	gen byte pension_ci = .
	replace pension_ci = 1 if jubilacion > 0					  // recibe
	replace pension_ci = 0 if jubilacion== 0 | jubilacion == . // no recibe
		
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = .
	replace pensionsub_ci = 1 if trat_pu > 0 & trat_pu < . & (edad >= 65 )
	replace pensionsub_ci = 0 if (trat_pu == 0 | trat_pu == .) & (edad >= 65 )
		
	***************
	**tipopen_ci**
	***************
	gen byte tipopen_ci = . 
	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci = .
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	egen ylmpri_ci=rsum(ing_trab1 ing_negp1)if emp_ci==1, missing
	replace ylmpri_ci = . if ylmpri_ci <= 0 | ylmpri_ci >= 999999999     //excluye valores fuera de rango
	replace ylmpri_ci = 0 if categopri_ci == 4     // se imputa ingreso 0 a los trabajadores no remunerados según categopri_ci.

	************
	* ylmsec_ci *
	************
	egen ylmsec_ci=rsum(ing_trab2 ing_negp2)if emp_ci==1, missing
	replace  ylmsec_ci = . if ylmsec_ci<= 0 | ylmsec_ci >= 999999999
	replace  ylmsec_ci = 0 if categopri_ci == 4

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci = .
    replace  ylmsec_ci = . if ylmotros_ci <= 0 | ylmotros_ci  >= 999999999
	replace  ylmsec_ci = 0 if categopri_ci == 4

	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	gen double ylnmpri_ci = .

	**************
	* ylnmsec_ci *
	**************
    gen double ylnmsec_ci = .

	****************
	* ylnmotros_ci *
	****************
    gen double ylnmotros_ci = .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi

	**********
	* ynlm_ci *
	**********
	egen ynlm_ci=rsum(ing_rent ing_tran otros), missing //CONEVAL no incluye otros

	***********
	* ynlnm_ci *
	***********
	*No se incluye el alquiler estimado
	egen ynlnm = rsum(pago_esp reg_esp), missing

	gen ynlnm_ci= ynlnm/nmiembros_ch
	
	**********
	* ytot_ci *
	**********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

	*********
	* ylm_ch *
	*********
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1, mi

	**********
	* ylnm_ch *
	**********
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1, mi

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1, mi

	*********
	* ynlm_ch *
	*********
	bys idh_ch: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
	gen byte ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0
 
	**********
	* ylmho_ci *
	**********
    generate double ylmho_ci = ylm_ci / (4.3 * horastot_ci) 
	replace ylmho_ci = . if ylmho_ci <= 0
  
	**************
	* nrylmpri_ci *
	**************
	gen byte nrylmpri_ci = .
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci ==1

	**************
	* nrylmpri_ch *
	**************
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .

	*************
	* remesas_ci *
	*************
    generate double remesas_ci = remesas

	*************
	* remesas_ch *
	*************
	bys idh_ch: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing

	**********
	* ypen_ci *
	**********
	generate double ypen_ci = jubilacion if pension_ci==1

	*************
	* ypensub_ci *
	*************
	gen ypensub_ci= trat_pu if pensionsub_ci==1
	
****************************
***VARIABLES DE EDUCACION***
****************************
	***********
	*aedu_ci*
	***********
	destring nivel nivelaprob gradoaprob antec_esc asis_esc no_asisb tipoesc, replace

	gen aedu_ci=.
	replace aedu_ci=0 if nivelaprob==0 |nivelaprob==1 
	replace aedu_ci=gradoaprob if nivelaprob==2
	replace aedu_ci= gradoaprob+6 if nivelaprob==3
	replace aedu_ci= gradoaprob+6 if nivelaprob==6 & antec_esc==1
	replace aedu_ci= gradoaprob+9 if nivelaprob==4
	replace aedu_ci= gradoaprob+9 if nivelaprob==6 & antec_esc==2
	replace aedu_ci= gradoaprob+12 if nivelaprob==5 | nivelaprob==7
	replace aedu_ci= gradoaprob+12 if nivelaprob==6 & antec_esc==3
	replace aedu_ci= gradoaprob+12+5 if nivelaprob==8
	replace aedu_ci= gradoaprob+12+5+2 if nivelaprob==9

	***********
	*edupre_ci*
	************
	gen byte edupre_ci = .
	
	**********
	*eduui_ci*
	**********
	gen byte eduui_ci=(aedu_ci>12 & aedu_ci<16) & (nivelaprob==5)
	replace eduui_ci = 1 if (aedu_ci>12 & aedu_ci<17) & (nivelaprob==7)
	replace eduui_ci=1 if (aedu_ci>12 & aedu_ci<15 & nivelaprob==6 & (antec_esc==2 | antec_esc==3)) 
	replace eduui_ci=. if aedu_ci==.

	**********
	*eduuc_ci*
	**********	
	gen byte eduuc_ci=(aedu_ci>=16) & (nivelaprob==5)
	replace eduuc_ci = 1 if (aedu_ci>=17) & (nivelaprob==7)
	replace eduuc_ci=1 if (aedu_ci>=15  & nivelaprob==6 & (antec_esc==2 | antec_esc==3)) 
	replace eduuc_ci=1 if nivelaprob==8 | nivelaprob==9
	replace eduuc_ci=. if aedu_ci==.
	
	**********
	*eduac_ci*
	**********
	gen byte eduac_ci=.
	replace eduac_ci=0 if nivelaprob==6 & antec_esc==3 | nivelaprob==5
	replace eduac_ci=1 if nivelaprob>=7 & nivelaprob<=9

	***********
	*asiste_ci*
	***********
	gen  asiste_ci = .
	replace asiste_ci = 1 if asis_esc==1
	replace asiste_ci = 0 if asis_esc==2

	***********
	*edupub_ci*
	***********
	gen byte edupub_ci = .
	replace edupub_ci = 1 if tipoesc==1 & asiste_ci==1
	replace edupub_ci = 0 if tipoesc==2 & asiste_ci==1
	replace edupub_ci = . if asiste_ci!=1
		
	************
	*asispre_ci*
	*************
	gen byte asispre_ci = .
	replace asispre_ci = 1 if asis_esc == 1 & nivel == 5
	replace asispre_ci = 0 if edad >= 3 & edad <= 5 ///
		& !(asis_esc == 1 & nivel == 5)
	replace asispre_ci = . if edad < 3 | edad > 5

	*************
	*pqnoasis1_ci*
	**************
	gen byte pqnoasis1_ci = .
	replace pqnoasis1_ci = 1 if inlist(no_asisb, 4, 9)          // económicos / trabajo
	replace pqnoasis1_ci = 2 if inlist(no_asisb, 5)             // desinterés / rendimiento
	replace pqnoasis1_ci = 3 if inlist(no_asisb, 6, 7, 12)      // cuidado/embarazo/salud
	replace pqnoasis1_ci = 4 if inlist(no_asisb, 10, 11, 3)     // acceso/infra/horarios
	replace pqnoasis1_ci = 5 if inlist(no_asisb, 1, 2, 8, 13)   // otros
	replace pqnoasis1_ci = . if no_asisb==99 | asiste_ci==1     // no aplica si asiste

	
****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	destring disp_elect, replace
	
	gen byte luz_ch = .
	replace luz_ch = 1 if inlist(disp_elect,1,2,3,4)
	replace luz_ch = 0 if disp_elect==5

	***********
	*luzmide_ch*
	***********
	destring medid_luz, replace force
	gen byte luzmide_ch = .
	replace luzmide_ch = 1 if medid_luz==1
	replace luzmide_ch = 0 if medid_luz==2 | luz_ch==0

	***********
	*combust_ch*
	***********
	destring combus, replace force
	gen byte combust_ch = .
	replace combust_ch = 1 if inlist(combus,3,4,5)
	replace combust_ch = 0 if inlist(combus,1,2,6)
	replace combust_ch = 0 if combus==7   // el hogar no cocina → no usa gas/electricidad -> 0
	
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
	gen byte dorm_ch = cuart_dorm
	replace dorm_ch = . if cuart_dorm>=999 | cuart_dorm==.

	******************************
	*	cuartos_ch
	******************************
	gen cuartos_ch=num_cuarto 
	replace cuartos_ch = . if num_cuarto>=999 | num_cuarto==.

	******************************
	*	cocina_ch
	******************************
	destring lugar_coc, replace force

	gen byte cocina_ch = .
	replace cocina_ch = 1 if lugar_coc == 2
	replace cocina_ch = 0 if inlist(lugar_coc,1,3,4,5,6)

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

	***********
	*vivi2_ch*
	***********
	destring tipo_viv, replace
	gen byte vivi2_ch = .
	replace vivi2_ch = 1 if inlist(real(tipo_viv),1,2)
	replace vivi2_ch = 0 if inlist(real(tipo_viv),3,4,5,6)

	******************************
	*	viviprop_ch
	******************************
	destring tenencia, replace
	gen byte viviprop_ch = .
	replace viviprop_ch = 0 if tenencia==1
	replace viviprop_ch = 1 if tenencia==4 | tenencia==5
	replace viviprop_ch = 2 if tenencia==3
	replace viviprop_ch = 3 if inlist(tenencia,2,6)


	******************************
	*	vivitit_ch
	******************************
	destring escrituras, replace
	gen byte vivitit_ch = .
	replace vivitit_ch = 1 if escrituras==1
	replace vivitit_ch = 0 if inlist(escrituras,2,3,4)

	******************************
	*	vivialq_ch
	******************************
	gen vivialq_ch= renta
	replace vivialq_ch    = renta           if renta<.

	******************************
	*	vivialqimp_ch
	******************************
	gen double vivialqimp_ch = .
	replace vivialqimp_ch = estim_pago if estim_pago>=0 & estim_pago<.

****************************
***VARIABLES DE WASH***
****************************
	****************
	***aguared_ch***
	****************
	destring agua_ent, replace ignore(" ,") force
	destring ab_agua,  replace ignore(" ,") force

	gen byte aguared_ch = .
	replace aguared_ch = 1 if ab_agua == 1
	replace aguared_ch = 0 if ab_agua > 1

	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = 0

	*****************
	*aguafuente_ch*
	*****************
	destring ab_agua, replace
	destring agua_noe, replace

	gen byte aguafuente_ch = .

	replace aguafuente_ch = 1  if ab_agua == 1 
	replace aguafuente_ch = 2 if agua_noe == 2 
	replace aguafuente_ch = 5  if ab_agua == 6 | agua_noe == 6     // lluvia
	replace aguafuente_ch = 6  if ab_agua == 4 | agua_noe ==5    // pipa/camión
	replace aguafuente_ch = 8 if agua_noe == 4
	replace aguafuente_ch = 10 if inlist(ab_agua,2,3,5,7) | inlist(agua_noe, 1,3)    // otro (sin clasificar)


	*************
	*aguadist_ch*
	*************
	destring agua_ent agua_noe, replace

	gen byte aguadist_ch = .

	replace aguadist_ch = 1 if agua_ent == 1
	replace aguadist_ch = 2 if agua_ent == 2
	replace aguadist_ch = 3 if agua_ent == 3 & (inlist(agua_noe,2,4))   // llave comunitaria o río
	replace aguadist_ch = 1 if agua_ent == 3 & (inlist(agua_noe, 5, 6))   // pipa → se recibe en vivienda o lluvia

	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch < .

	**************
	*aguadisp1_ch*
	**************
	destring dotac_agua, replace

	gen byte aguadisp1_ch = 9

	**************
	*aguadisp2_ch*
	**************
	gen byte aguadisp2_ch = .
	replace aguadisp2_ch = 3 if dotac_agua == 1
	replace aguadisp2_ch = 1 if inlist(dotac_agua,2,3,4,5)

	*************
	*aguatrat_ch*
	*************
	gen aguatrat_ch = 0

	*************
	*aguamala_ch*  
	*************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch <= 7
	replace aguamala_ch = 1 if aguafuente_ch > 7 & aguafuente_ch != 10 & aguafuente_ch != .

	*****************
	*aguamejorada_ch*  
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 1 if aguafuente_ch <= 7
	replace aguamejorada_ch = 0 if aguafuente_ch > 7 & aguafuente_ch != 10

	*****************
	***aguamide_ch***
	*****************
	gen aguamide_ch=.

	*****************
	*bano_ch         *
	*****************
	destring excusado drenaje, replace force

	gen byte bano_ch = .

	replace bano_ch = 0 if excusado == 3
	replace bano_ch = 1 if drenaje == 1
	replace bano_ch = 2 if drenaje == 2
	replace bano_ch = 4 if inlist(drenaje, 3, 4)
	replace bano_ch = 6 if drenaje == 5 & excusado != 3 | missing(bano_ch) & excusado < .
	replace bano_ch = . if excusado == .

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
	gen byte sinbano_ch = .

	replace sinbano_ch = 0 if bano_ch != 0 & bano_ch < .
	replace sinbano_ch = 3 if bano_ch == 0
	replace sinbano_ch = . if bano_ch == .

	*****************
	*banomejorado_ch*  Altered
	*****************
	gen byte banomejorado_ch = 2
	replace banomejorado_ch = 1 if bano_ch <= 3 & bano_ch != 0
	replace banomejorado_ch = 0 if (bano_ch == 0 | bano_ch >= 4) & bano_ch != 6
		
****************************
***VARIABLES DE MIGRACIÓN***
****************************		
	*******************
	*** migrante_ci ***
	*******************
	gen byte migrante_ci = .
	destring pais_nac, replace
	replace migrante_ci = 1 if inlist(pais_nac,3,4)
	replace migrante_ci = 0 if inlist(pais_nac,1,2)

	**********************
	*** migantiguo5_ci ***
	**********************
	gen byte migrantiguo5_ci = .
	
	**********************
	*** miglac_ci ***
	**********************
	gen byte miglac_ci = 0
	replace miglac_ci = 1 if inlist(pais_nac, 406,408,409,412,413,414,416,417,418,420,501,502,503,505,506,508,509,512,513) & migrante_ci == 1
	replace miglac_ci = . if migrante_ci == 0
	

****************************
***VARIABLES DE EXTERNAS***
****************************
	****************
	* bienestar_agregado *
	****************	
	gen bienestar_agregado = .

	* ENIGH México usa ingreso corriente trimestral per cápita
	replace bienestar_agregado = ing_cor / tot_integ  if ing_cor < .

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = .

	****************
	* ln_ci *
	****************	
	gen ln_ci = .
	
	****************
	* pobre_ine _ci*
	****************	
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci = 1 if bienestar_agregado < ln_ci   & bienestar_agregado < .
	replace pobre_ine_ci = 0 if bienestar_agregado >= ln_ci  & bienestar_agregado < .
	
	****************
	*tipo_bienestar*
	****************	
	gen byte tipo_bienestar = 1     // 1 = Ingreso (metodología oficial México)

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
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad 
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch   ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	        /// Protección social 
          /// Protección social ingresos
 	   lp19_2011 lp31_2011 lp5_2011  lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa


saveold "`base_out'", replace

cap log close
