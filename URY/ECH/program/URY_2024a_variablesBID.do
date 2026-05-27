*(Versión stata 17)

**# Bookmark #1
clear
set more off

*________________________________________________________________________________________________________________*

* Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
* utilizar un loop)
* Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
* Se tiene acceso al servidor unicamente al interior del BID.
* El servidor contiene las bases de datos MECOVI.
*________________________________________________________________________________________________________________*
 
global ruta = "${surveysFolder}"

local PAIS URY
local ENCUESTA ECH
local ANO "2024"
local ronda a  


local log_file = "$ruta\\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\\harmonized\\`PAIS'\\`ENCUESTA'\\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: URY
Encuesta: ECH
Round: a
Autores: Lina Maria Arias (SCL/SCL) - Email: linarias8@gmail.com, 22 de sep de 2025
Versión ...: v1
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use `base_in', clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

*Replacing NAs
ds, has(type string)
foreach v in `r(varlist)' {
	replace `v' = "" if `v' == "NA"
	}

	********************
	*** region_BID_c ****
	********************
	gen region_BID_c=.
	replace region_BID_c = 4 


	********************
	*** region_BID_c ****
	********************
	gen ine01 = dpto
	gen region_c = dpto
	label define region_c  1 "Montevideo" ///
           2 "Artigas" /// 
           3 "Canelones" /// 
           4 "Cerro Largo" /// 
           5 "Colonia" /// 
           6 "Durazno" /// 
           7 "Flores" /// 
           8 "Florida" /// 
           9 "Lavalleja" /// 
          10 "Maldonado" /// 
          11 "Paysandú" /// 
          12 "Río Negro" /// 
          13 "Rivera" /// 
          14 "Rocha" /// 
          15 "Salto" /// 
          16 "San José" /// 
          17 "Soriano" /// 
          18 "Tacuarembó" ///
          19 "Treinta y Tres" 
label value region_c region_c

	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="URY"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=mes	

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=.
	replace zona_c=1 if (region_4 == 1 | region_4 == 2)
	replace zona_c=0 if (region_4 == 3 | region_4 == 4)
	label value zona_c zona_c
	
	*********
	*estrato*
	*********
	gen estrato_ci=estred13
	label define estrato 1 "Montevideo - Nivel económico bajo" ///
	2 "Montevideo - Nivel económico medio - bajo" ///
	3 "Montevideo - Nivel económico medio" ///
	4 "Montevideo - Nivel económico medio - alto" ///
	5 "Montevideo - Nivel económico alto" ///
	6 "Zona metropolitana" ///
	7 "Interior Norte (Artigas, Rivera, Cerro Largo, Treinta y Tres)" ///
	8 "Costa Este (Canelones, Maldonado, Rocha)" ///
	9 "Litoral Norte (Salto, Paysandú, Río Negro)" ///
	10 "Litoral Sur (Soriano, Colonia, San José)" ///
	11 "Centro Norte (Tacuarembó, Durazno)" ///
	12 "Centro Sur (Flores, Florida, Lavalleja)" 
	label value estrato_ci estrato
	
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	tostring id , gen(idh_ch)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(idh_ch nper)
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=w_ano
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=w_ano 
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=e26


	*********
	*edad_ci*
	*********
	gen int edad_ci=e27
	
	**************
	**relacion_ci**
	**************
	gen relacion_ci =.
	replace relacion_ci = 1 if (e30 == 1)
	replace relacion_ci = 2 if (e30 == 2)
	replace relacion_ci = 3 if (e30 >= 3 & e30 <= 5)
	replace relacion_ci = 4 if (e30 >= 6 & e30 <= 12)
	replace relacion_ci = 5 if (e30 == 13)
	replace relacion_ci = 6 if (e30 == 14)
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if (e36 == 5 & e33 ==2) 
	replace civil_ci = 2 if (e33 == 1)
	replace civil_ci = 2 if (e36 == 3 & e33 ==2) 
	replace civil_ci = 3 if (e36 == 1 & e33 ==2) | (e36 == 2 & e33 ==2) 
	replace civil_ci = 4 if (e36 == 4 & e33 ==2) | (e36 == 6 & e33 ==2)
		
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

		
	****************
	*notronopari_ch*
	****************
	
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)


	****************
	***nempdom_ch***
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6)
	replace nempdom_ch =. if relacion_ci==.
         

		
	************
	*nempdom_ch*
	************

	gen empldom_ci=0
	replace empldom_ci=1 if e30==14
		  
		
	*************
	*clasehog_ch*
	*************
	gen byte clasehog_ch=0
	**** unipersonal
	replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (child with or without spouse but without other relatives)
	replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** nuclear (spouse with or without children but without other relatives)
	replace clasehog_ch=2 if nhijos_ch==0 & nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0
	**** ampliado
	replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
	**** compuesto (some relatives plus non relative)
	replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
	**** corresidente
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0

	**************
	*nmiembros_ch*
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	
	******************
	** miembros_ci **
	*****************
   gen byte miembros_ci=(relacion_ci>=1 & relacion_ci<=5) 
   replace miembros_ci=. if relacion_ci==.
   
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=1

		
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

	

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***

*******************************************************
	*********
	*afro_ci*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	replace afro_ci = 1 if e29_1 == 1 
	replace afro_ci = 0 if e29_1 == 2
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 	
	replace ind_ci = 1 if e29_4 == 1 
	replace ind_ci = 0 if e29_4 == 2 // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci = 1 if (afro_ci == 0 | ind_ci == 0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci = 0 if (afro_ci == 1 | ind_ci == 1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci = . if (afro_ci == . & ind_ci == .)

	************
	*afroind_ci*
	************
	gen byte afroind_ci=.
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1
	
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
	*ISOalpha3_dis_ci*
	******************
	gen byte ARG_dis_ci = .
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if (pobpcoac == 2)
	replace condocup_ci = 2 if (pobpcoac == 3 | pobpcoac == 4 | pobpcoac == 5)
	replace condocup_ci = 3 if (pobpcoac >= 6 & pobpcoac <= 11)
	replace condocup_ci = 4 if (pobpcoac == 1)

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if ((pobpcoac == 9 | pobpcoac == 10) & condocup_ci == 3) // Jubilados o pensionistas
	replace categoinac_ci = 2 if  (pobpcoac == 7 & condocup_ci == 3) // Estudiantes
	replace categoinac_ci = 3 if  (pobpcoac == 6 & condocup_ci == 3) // Quehaceres del hogar
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3) // Otros inactivos

	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if (pobpcoac == 4 | pobpcoac == 5)
	replace cesante_ci=0 if pobpcoac == 3


	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if f85<31 & (f102 == 1 & f103 == 1)

	****************
	***durades_ci***
	****************
	gen byte durades_ci=f113/4.3 if f113>0
	replace durades_ci=. if pobpcoac!=3 & pobpcoac!=4 & pobpcoac!=5

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
	replace nempleos_ci = 1 if f70==1
	replace nempleos_ci = 2 if f70>1
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .
	
	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .
	replace desalent_ci = 1 if f108==4 & condocup_ci==3
	replace desalent_ci=0 if f108!=4 & condocup_ci==3
	replace desalent_ci =. if emp_ci ==.

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	replace horaspri_ci =f85 if f85!=98 | emp_ci==1 
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci= (f85 + f98)
	replace horastot_ci=. if f85==98 | emp_ci==0
	replace horastot_ci=. if f98==98 | emp_ci==0

	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci  = (horaspri_ci >= 1 & horaspri_ci < 30 & f102 == 2) 
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if 
	replace categopri_ci  = 1 if (f73 == 4)
	replace categopri_ci  = 2 if (f73 == 3 | f73 == 9)
	replace categopri_ci  = 3 if (f73 == 1 | f73 == 2 | f73 == 8)
	replace categopri_ci  = 4 if (f73 == 7) 
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	*replace categosec_ci  = 0 if ...
	replace categosec_ci  = 1 if (f92 == 4)
	replace categosec_ci = 2 if (f92 == 9 | f92 == 3)
	replace categosec_ci = 3 if (f92 == 1 | f92 == 2 | f92 == 8)
	replace categosec_ci = 4 if (f92 == 7) 	

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	*replace rama_ci  = 0 if ...
	replace rama_ci  = 1 if (f72_2>0 & f72_2<=400) & emp_ci==1
	replace rama_ci=2 if (f72_2>=500 & f72_2<=1000) & emp_ci==1
	replace rama_ci=3 if (f72_2>=1010 & f72_2<=3400) & emp_ci==1
	replace rama_ci=4 if (f72_2>=3500 & f72_2<=4000) & emp_ci==1
	replace rama_ci=5 if (f72_2>=4100 & f72_2<=4400) & emp_ci==1
	replace rama_ci=6 if ((f72_2>=4500 & f72_2<=4800) | (f72_2>=5500 & f72_2<=5700))& emp_ci==1
	replace rama_ci=7 if ((f72_2>=4900 & f72_2<=5400) | (f72_2>=6100 & f72_2<=6199)) & emp_ci==1
	replace rama_ci=8 if (f72_2>=6400 & f72_2<=8300) & emp_ci==1
	replace rama_ci=9 if ((f72_2>=5800 & f72_2<=6090) | (f72_2>=6200 & f72_2<=6399) | (f72_2>=8400 & f72_2<=9900))& emp_ci==1


	***************
	***spublico_ci ***
	***************	

	gen byte spublico_ci = 0
	replace spublico_ci  = 1 if (f73 == 2) & emp_ci==1
	replace spublico_ci  = 0 if (f73 != 2) & emp_ci==1
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	replace tamemp_ci  =1 if (f77 == 1 | f77 == 2) // 1 a 4 personas
	replace tamemp_ci = 2 if (f77 >= 3 & f77 <= 5) // 5 a 49 personas
	replace tamemp_ci = 3 if (f77 >= 7 & f77 <= 9) // 50 o más personas
	
	***************
	***cotizando_ci***
	***************	
	gen  byte cotizando_ci = .
	replace cotizando_ci  = 0 if (f82==2 | f96==2)
	replace cotizando_ci  = 1 if (f82==1 | f96==1)
	
	
	***************
	***afiliado_ci***
	***************	
	gen  byte afiliado_ci = .
	replace afiliado_ci  = 0 if (f82==2 | f96==2)
	replace afiliado_ci  = 1 if (f82==1 | f96==1)	
	
	***************
	***instcot_ci***
	***************	
	gen byte instcot_ci=f83 if cotizando_ci == 1
	replace instcot_ci=. if instcot_ci==0
	
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
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci=.
	replace ocupa_ci=1 if (f71_2>=2111 & f71_2<=3522) & emp_ci==1
	replace ocupa_ci=2 if (f71_2>=1111 & f71_2<=1439) & emp_ci==1
	replace ocupa_ci=3 if (f71_2>=4110 & f71_2<=4419 | f71_2>=410 & f71_2<=430) & emp_ci==1
	replace ocupa_ci=4 if ((f71_2>=5211 & f71_2<=5249) | (f71_2>=9510 & f71_2<=9520)) & emp_ci==1
	replace ocupa_ci=5 if ((f71_2>=5111 & f71_2<=5169) | (f71_2>=5311 & f71_2<=5419) | (f71_2>=9111 & f71_2<=9129) | (f71_2>=9611 & f71_2<=9624) ) & emp_ci==1 /*Aunque no esta desagregado en la base, esta es la desagregación a tres digitos de la CIUO-88*/
	replace ocupa_ci=6 if ((f71_2>=6111 & f71_2<=6340) | (f71_2>=9211 & f71_2<=9216)) & emp_ci==1
	replace ocupa_ci=7 if ((f71_2>=7111 & f71_2<=8350) | (f71_2>=9311 & f71_2<=9412)) & emp_ci==1 /*Incluye artesanos y operarios en hilanderias*/
	replace ocupa_ci=8 if (f71_2>=110 & f71_2<=310) & emp_ci==1
	replace ocupa_ci=9 if (f71_2==9629) & emp_ci==1
	
	*************
	**pension_ci*
	*************
	gen pension_ci=1 if g_it_1==1 |g_it_2==1

	***************
	*pensionsub_ci*
	***************
	destring f124_2, replace force
	gen pensionsub_ci= 1 if f124_2==1
	label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

	****************
	*tipopen_ci*****
	****************
	gen tipopen_ci = f125
	replace tipopen_ci =. if f125 == 0
	label define tipopen_ci 1"vejez" 2"fallecimiento" 3"invalidez" 4"extranjero" 5"victima" 6"hijos de fallecidos por violencia doméstica" 7"pensión especial reparatoria" 8"pensión reparatoria personas trans"
	label var tipopen_ci "Tipo de pension - variable original de cada pais" 
	label value tipopen_ci tipopen_ci
	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci=.
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	egen double ylmpri_ci =rowtotal(g126_1 g126_2  g126_3  g126_4  g126_5  g126_6  g126_7 g142 g143 g133_2) if emp_ci==1, mi

	************
	* ylmsec_ci *
	************
	egen double ylmsec_ci =rowtotal(g134_1 g134_2  g134_3  g134_4  g134_5  g134_6  g134_7 g141_2) if emp_ci==1, mi

	**************
	* ylmotros_ci *
	**************
    egen double ylmotros_ci =rowtotal(g134_1 g134_2  g134_3  g134_4  g134_5  g134_6  g134_7 g141_2) if emp_ci==1, mi
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	gen desay = (g127_1*mto_desay)
	gen almue = (g127_2*mto_almue)
	gen vacas = (g132_1*mto_vacas)
	gen oveja = (g132_2*mto_oveja)
	gen caballo = (g132_3*mto_caball)
	destring g144_1, replace 
	
	egen double ylnmpri_ci = rowtotal(desay almue vacas oveja caballo g126_8 g127_3 g128_1 g129_2 g130_1 g131_1 g133_1 g144_1 g144_2_1 g144_2_2 g144_2_3 g144_2_4 g144_2_5) if emp_ci==1, mi
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .
	
	drop desay almue vacas oveja caballo

	**************
	* ylnmsec_ci *
	**************
	
	destring g135_1, replace
	destring g135_2, replace

	gen desaysec = (g135_1*mto_desay)
	gen almuesec = (g135_2*mto_almue)
	gen vacassec = (g140_1*mto_vacas)
	gen ovejasec = (g140_2*mto_oveja)
	gen caballosec = (g140_3*mto_caball)

	destring g135_3, replace
	destring g136_1, replace
	destring g137_2, replace
	destring g138_1, replace
	destring g139_1, replace

    egen double ylnmsec_ci = rowtotal(desaysec almuesec vacassec ovejasec caballosec g134_8 g135_3 g136_1 g137_2 g138_1 g139_1 g141_1) if emp_ci==1, mi
    replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .
	
	drop desaysec almuesec vacassec ovejasec caballosec

	****************
	* ylnmotros_ci *
	****************
    gen double ylnmotros_ci = . if emp_ci==1
    replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	***********************
	* ynlm_ci 
	***********************

	foreach i in h160_1 h160_2 h163_1 h163_2 h164 h165 h166 ///
	             h167_1_3 h167_2_3 h167_3_3 h167_4_3 ///
	             h170_3 h171_1 h172_1 h173_1 {
		capture gen `i'm = `i'/12
	}
	bys idh_ch: egen numper = sum(miembros_ci)
	bys idh_ch: egen npermax = max(numper)
	drop numper

	capture egen inghog1 = rsum(h155_1 h160_1m h160_2m h163_1m h163_2m h164m ///
	    h165m h166m h167_1_3m h167_2_3m h167_3_3m h167_4_3m ///
	    h170_3m h171_1m h172_1m h173_1m), missing
	capture gen inghog = inghog1 / npermax
	capture confirm variable inghog
	if _rc gen inghog = .

	capture gen canasta_2 = (e247 * indaceliac) if e246 == 7
	capture gen canasta_3 = (e247 * indaemer)   if e246 == 14
	capture gen hogcosnt  = mto_hogcon if g149 == 1 & g149_1 == 2
	capture egen transf   = rsum(canasta_2 canasta_3 hogcosnt), missing
	capture confirm variable transf
	if _rc gen transf = .

	egen double ynlm_ci = rsum(inghog transf ///
		g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 ///
		g148_1_8 g148_1_9 g148_1_12 g148_1_10 g148_1_11 ///
		g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 ///
		g148_2_8 g148_2_9 g148_2_12 g148_2_10 g148_2_11 ///
		g148_3 g148_4 g148_5_1 g148_5_2 g153_1 g153_2 g154_1)
	replace ynlm_ci = . if ynlm_ci < 0

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci =.
	replace ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .

	**********
	* ytot_ci *
	**********
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
    gen double ynlm_ch =.
 
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
    generate double remesas_ci =.

	*************
	* remesas_ch *
	*************
    generate double remesas_ch =h172_1

	*************
	*ypen_ci*
	*************
	* Jubilaciones
	egen aux1 = rowtotal(g148_1_1 g148_1_2 g148_1_3 g148_1_5 g148_1_6 g148_1_7 g148_1_8 g148_1_9 g148_1_12 g148_1_10), mis /*Se excluyen pensiones recibidas del exterior (g148_1_11)*/
	* Missing g148_1_4 *

	* Pensiones
	egen aux2 = rowtotal(g148_2_1 g148_2_2 g148_2_3 g148_2_5 g148_2_6 g148_2_7 g148_2_8 g148_2_9 g148_2_12 g148_2_10), mis /*Se excluyen pensiones recibidas del exterior (g148_2_11)*/
	* Missing g148_2_4 *

	* MGR, Aug 2015: correción en sintáxis, se generaba como el 100%
	egen 	ypen_ci=rsum(aux1 aux2),m
	replace ypen_ci=. if pension_ci==0
	label var ypen_ci "Valor de la pension contributiva"


	*************
	* ypensub_ci *
	*************
	generate double ypensub_ci =.
	
	
****************************
***VARIABLES DE EDUCACION***
****************************


	*********	
	*aedu_ci*
	*********

	// Reemplazar 9 con 0 - es inicio de ese año escolar 
	foreach v of varlist e51_2 e51_4_a e51_4_b e51_5 e51_6 e51_8 e51_9 e51_10 e51_11 {
		replace `v' = 0 if `v' == 9
	}	

	replace e51_2=0 if e51_2==12

	** Se generan años aprobados para los niveles ** 	
	egen mb_añostc = rowmax(e51_4_a e51_4_b) /*computa el maximo de Media Básica Liceo o tecnico (CETP-UTU)*/	
	egen ms_añostc = rowmax(e51_5 e51_6) /*computa el maximo de Media Superior Liceo o tecnico (CETP-UTU)*/		
	egen sup_años = rowmax(e51_8 e51_9 e51_10) /*computa el maximo de superior: magisterio, universitario o terciario no universitario */

	gen años_prim = e51_2
	gen años_cb_mb = mb_añostc
	gen años_cb_ms = ms_añostc
	gen años_sup = sup_años
	gen años_post = e51_11

	foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
		destring `v', replace force
	}

	gen aedu_ci = 0
	qui foreach v of varlist años_prim años_cb_mb años_cb_ms años_sup años_post {
		replace aedu_ci = aedu_ci + `v' if !missing(`v')
	}

	replace aedu_ci =. if (años_prim==. & años_cb_mb==. & años_cb_ms==. & años_sup==. & años_post==.)

	** eliminamos variables temporales
	drop años_prim años_cb_mb años_cb_ms años_sup años_post


	**********
	*eduui_ci*
	**********
	gen byte eduui_ci =0
	replace eduui_ci=1 if e215_1==2 & (e218_1!=1 & e221_1!=1)  
	replace eduui_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)
	replace eduui_ci=1 if e221_1==2 & (e215_1!=1 & e218_1!=1)
	

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci =0
	replace eduuc_ci=1 if e215_1==1 | e218_1==1 | e221_1==1  

	**********
	*eduac_ci*
	**********
	gen eduac_ci =.
	replace eduac_ci=0 if e215_1==1 | e221_1==1 & (e218_1!=1)   
	replace eduac_ci=0 if (e215_1==2 | e221_1==2) & (e218_1==0)  
	replace eduac_ci=1 if e218_1==1 
	replace eduac_ci=1 if e218_1==2 & (e215_1!=1 & e221_1!=1)  
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.

	************
	*asispre_ci*
	************
	g asispre_ci=.
	replace asispre_ci =1 if e579==13 | e579==14

	***********
	*asiste_ci*
	***********
	gen asiste_ci=(e49 == 3)


	******************
	*razonesnoasis_ci*
	******************
	gen razonesnoasis_ci=. 
	replace razonesnoasis_ci =  1 if inlist(e202, 7, 9)
	replace razonesnoasis_ci =  2 if inlist(e202, 1, 2, 5)
	replace razonesnoasis_ci =  3 if inlist(e202, 8, 10, 11)
	replace razonesnoasis_ci =  4 if inlist(e202, 3, 4, 6)
	
	replace razonesnoasis_ci = . if asiste_ci==1 // Consistencia: No se debe contar con razones de no asistencia si la variable de asiste_ci==1. 

	***********
	*edupub_ci*
	***********
	
	/*  e581: TIPO DE INSTITUCIÓN DE NIVEL AL QUE ASISTE
		1 Pública
		2 Privada
		3 CAIF - CAPI - Nuestros niños
		
		e581a: TIPO DE INSTITUCIÓN DE OTRO NIVEL EDUCATIVO
		1 Pública
		2 Privada */
		

	gen edupub_ci =. if (asiste_ci != 1)
	replace edupub_ci = 1 if (e581 == 1 | e581a == 1) & (asiste_ci == 1)
	replace edupub_ci = 0 if (e581 == 2 | e581 == 3 | e581a == 2) & (asiste_ci == 1)
	
	
****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=0 if d18>1 & d18<5
	replace luz_ch=1 if (d18 == 1)
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch = 1 if (d20 == 1 | d20 == 2 | d20 == 3 | d20 == 4)
	replace combust_ch = 0 if combust_ch ==.
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen piso_ch=.	
	
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*resid_ch*
	***********
	gen resid_ch=.
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch= d10
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=d9
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
	replace cocina_ch = 1 if (d19 == 1 | d19 == 2)
	replace cocina_ch = 0 if (d19 == 3)
	
	***********
	*telef_ch*
	***********
	gen telef_ch=(d21_17 == 1)
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=(d21_3 == 1)
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	
	***********
	*auto_ch*
	***********
	gen auto_ch=(d21_18 == 1)
	
	***********
	*compu_ch*
	***********
	gen compu_ch=(d21_15 == 1)
		
	***********
	*internet_ch*
	***********
	gen internet_ch=(d21_16 == 1)
	
	***********
	*vivi1_ch*
	***********
	gen vivi1_ch=.
	replace vivi1_ch=1 if (c1 == 1)	
	replace vivi1_ch = 2 if (c1 == 3 | c1 == 4)
	replace vivi1_ch = 3 if (c1 == 2 | c1 == 5)
	
	**************
	***vivi2_ch***
	**************
	gen byte vivi2_ch=(vivi1_ch<3)
	replace vivi2_ch=. if vivi1==.
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch = 0 if (d8_1 == 5)
	replace viviprop_ch = 1 if (d8_1 == 2 | d8_1 == 4)
	replace viviprop_ch = 2 if (d8_1 == 1 | d8_1 == 3)
	replace viviprop_ch = 3 if (d8_1 >= 6 & d8_1 <= 9)	
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	replace vivitit_ch=0 if .
	replace vivitit_ch=1 if .	
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch= d8_3 if (viviprop_ch == 0)
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=d8_3 if (viviprop_ch != 0)



	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch = (d11 == 1)
	replace aguared_ch =. if d11 ==.

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =.
	replace aguafconsumo_ch = 1 if d11==1 & d12==1
	replace aguafconsumo_ch = 2 if d11==1 & d12>1
	replace aguafconsumo_ch = 4 if d11==3
	replace aguafconsumo_ch = 6 if d11==4
	replace aguafconsumo_ch = 8 if d11==5
	replace aguafconsumo_ch = 9 if d11==2 
	replace aguafconsumo_ch = 10 if d11==6
	

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if d11==1 & d12==1
	replace aguafuente_ch = 2 if d11==1 & d12>1
	replace aguafuente_ch = 4 if d11==3
	replace aguafuente_ch = 6 if d11==4
	replace aguafuente_ch = 8 if d11==5
	replace aguafuente_ch = 9 if d11==2 
	replace aguafuente_ch = 10 if d11==6
	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if d12==1
	replace aguadist_ch = 2 if d12==2
	replace aguadist_ch = 3 if d12==3
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch = 9 
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch = 9
	
	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.


	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7
	
	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .
	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch =0
	replace bano_ch=1 if d16==1 
	replace bano_ch=2 if d16==2 
	replace bano_ch=6 if d16==4
	replace bano_ch=4 if d16==3 

		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = 1 if (d15 == 1)
	replace banoex_ch = 0 if (d15 == 2)
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = 3
	replace sinbano_ch = 0 if d14>0
		
	******************
    ** banomejorado_ch ** - 
    *****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci= 0
	replace migrante_ci=1 if (e37 == 4)
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.
	replace migrantiguo5_ci=1 if migrante_ci == 1 & e38_1>=5
	replace migrantiguo5_ci = 1 if migrante_ci == 1 & (e236==1| e236==2 |e236==3 )
	replace migrantiguo5_ci = 0 if migrante_ci == 1 & e236==4
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
	
	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = 0
	replace miglac_ci = 1 if inlist(e234_2, 660, 28, 32, 533, 44, 52, 84, 68, 76, 152, 170, 188, 192, 531, 212, 218, 222, 320, 254, 328, 332, 340, 136, 796, 92, 388, 484, 558, 591, 600, 604, 214, 659, 658, 534, 670, 662, 740, 780, 862)
	replace miglac_ci=. if migrante_ci==0
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 


	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine_ci = .
	replace pobre_ine_ci= 0 if pobre17==0
	replace pobre_ine_ci= 1 if pobre17==1

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = ht11

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci = li_17
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = lp_17
	
		
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
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  lp19_2011 lp31_2011 lp5_2011 lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded


compress

local PAIS URY
local ENCUESTA ECH
local ANO "2024"
local ronda a  
local base_out = "$ruta\\harmonized\\`PAIS'\\`ENCUESTA'\\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
saveold "`base_out'", version(12) replace

log close


