*(Versión stata 17)

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

local PAIS CHL
local ENCUESTA CASEN
local ANO "2024"
local ronda m11_m12_m1

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: CHL
Encuesta: CASEN
Round: m11?m12
Autores: LMAP
Versión:
Nombre de autor (SCL/SCL) - Email: linarias8@gmail.com, Fecha: 01/13/2026

****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use "`base_in'", clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=.
	replace region_BID_c=4

	********************
	*** region_c ****
	********************
	gen byte region_c = region
	label define region_c ///
	1"Tarapacá"                               		///
	2"Antofagasta"							  		///
	3"Atacama"                                		///
	4"Coquimbo"                               		///
	5"Valparaíso"                             		///
	6"Libertador General Bernardo O'higgins"  		///
	7"Maule"                                  		///
	8"Bío bío"                               		///
	9"La Araucanía"                           		///
	10"Los Lagos"                             		///
	11"Aysén del General Carlos Ibañez del Campo"   ///
	12"Magallanes y de la Antártica Chilena"        ///
	13"Metropolitana de Santiago"                   ///
	14"Los Ríos"                                    /// 
	15"Arica y Parinacota"							/// 
	16 "Ñuble"
   label value region_c region_c

	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="..."

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=month(fecha_entrev)	

	******
	*zona*
	******
	gen zona_c=area
	recode zona_c (2=0)

	
	*********
	*estrato*
	*********
	gen estrato_ci=estrato
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=cod_upm
	
	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch=group(folio) 
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen idp_ci = id_persona
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=expr 
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=expr 
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=sexo

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=edad if edad!=.
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci=1     if pco1==1
	replace relacion_ci=2 if pco1==2 | pco1==3
	replace relacion_ci=3 if pco1==4 | pco1==5 | pco1==6
	replace relacion_ci=4 if pco1>=7 & pco1<=13
	replace relacion_ci=5 if pco1==14
	replace relacion_ci=6 if pco1==15
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=.
	
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci=1     if ecivil==8
	replace civil_ci=2 if ecivil==1 | ecivil==2 | ecivil==3
	replace civil_ci=3 if ecivil==6 | ecivil==4 | ecivil==5
	replace civil_ci=4 if ecivil==7

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
	*notropari_ch*
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
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	
	
	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.   // se queda como missing (.) si no existe la pregunta	

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci=1 if (r3 >=1 & r3 <=10 ) /* se incluyó "10. Chango" a la lista */
	replace afroind_ci=2 if r3==0
	replace afroind_ci=3 if r3==11  /* changed to "11. Otro" this year */
	
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
	replace disWG_ci=1 if disc_wg==1
	replace disWG_ci=0 if disc_wg==0
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte chl_dis_ci = disWG_ci
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	gen byte condocup_ci = .
	replace condocup_ci=1 if (o1==1 | o2==1 | o3==1)
	replace condocup_ci=2 if ((o1==2 | o2==2 | o3==2) & (o6==1))
	recode condocup_ci (.=3) if edad_ci>=12 
	replace condocup_ci=4 if edad<12
	
	

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (o7==12 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (o7==11 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (o7==10 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 | categoinac_ci != 2 | categoinac_ci != 3) & condocup_ci == 3)

	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if o4==1 & (o6==1 | o7<=2)
	replace cesante_ci=0 if o4==2 & (o6==1 | o7<=2)

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci=1 if (o10<=30) & o11==1

	****************
	***durades_ci***
	****************
	gen byte durades_ci=o8*(52/12)

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
	replace nempleos_ci = 1 if o29==2
	replace nempleos_ci=2 if o29==1
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = .
	*replace antiguedad_ci = 1 if ...
	*replace antiguedad_ci = ... if emp_ci == 1
	
	***************
	***desalent_ci***
	***************
	gen byte desalent_ci= .

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	replace horaspri_ci = o10 if emp_ci==1  & o10!=-88
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = .
	replace horastot_ci  = o10 if  emp_ci==1 & o10!=-88 
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci  = (o10>1 & o10<30) & (o11==2 | o11==3)
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if ...
	replace categopri_ci= 1 if o15==1
	replace categopri_ci=2 if o15==2
	replace categopri_ci=3 if o15>=3 & o15<=8
	replace categopri_ci=4 if o15==9
	replace categopri_ci=. if emp_ci!=1
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	*replace categosec_ci  = 0 if ...
	replace categosec_ci  = 1 if o30==1
	replace categosec_ci=2 if o30==2
	replace categosec_ci=3 if o30>=3 & o30<=8
	replace categosec_ci=4 if o30==9
	replace categosec_ci=. if emp_ci!=1	

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	replace rama_ci  = 0 if rama1==-66
	replace rama_ci  = 1 if (rama4>=100 & rama4<=599) & emp_ci==1
	replace rama_ci=2 if (rama4>=1000 & rama4<=1499) & emp_ci==1
	replace rama_ci=3 if (rama4>=1500 & rama4<=3799) & emp_ci==1
	replace rama_ci=4 if (rama4>=4000 & rama4<=4199) & emp_ci==1
	replace rama_ci=5 if (rama4>=4500 & rama4<=4599) & emp_ci==1
	replace rama_ci=6 if (rama4>=5000 & rama4<=5599) & emp_ci==1
	replace rama_ci=7 if (rama4>=6000 & rama4<=6499) & emp_ci==1
	replace rama_ci=8 if (rama4>=6500 & rama4<=7099) & emp_ci==1
	replace rama_ci=9 if (rama4>=7100 & rama4<=9990) & emp_ci==1

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 0 if (o15!=3 | o15!=4 | o15!=8) & emp_ci==1
	replace spublico_ci  = 1 if (o15==3 | o15==4 | o15==8) & emp_ci==1
	
	***************
	***tamemp_ci ***
	***************	
	gen  byte tamemp_ci = .
	*replace tamemp_ci  = 1 if ...
	*replace tamemp_ci  = 2 if ...
	*replace tamemp_ci  = 3 if ...
	
	
	***************
	***cotizando_ci***
	***************	
	gen  byte cotizando_ci = .
	replace cotizando_ci  = 0 if (condocup_ci==1 | condocup_ci==2)
	replace cotizando_ci  = 1 if o32>=1 & o32<=5
	
	
	***************
	***afiliado_ci***
	***************	
	gen  byte afiliado_ci = 1 if o31==1
	recode afiliado_ci .=0 
	
	***************
	***instcot_ci***
	***************	
	gen byte instcot_ci=. if cotizando_ci == 1	
	
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
	replace tipocontrato_ci = 0 if ( o19==1 | o19==2 ) & categopri_ci == 3
	replace tipocontrato_ci = 1 if o18==1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if (o18==2 | o18==3) & categopri_ci == 3
	replace tipocontrato_ci = 3 if o19==3 & categopri_ci == 3
		
	**************
	***ocupa_ci***
	**************
	gen byte ocupa_ci=.
	/*replace ocupa_ci=1 if … & emp_ci==1
	replace ocupa_ci=2 if  … & emp_ci==1
	replace ocupa_ci=3 if  … & emp_ci==1
	replace ocupa_ci=4 if  … & emp_ci==1
	replace ocupa_ci=5 if  … & emp_ci==1
	replace ocupa_ci=6 if  …  & emp_ci==1
	replace ocupa_ci=7 if  … & emp_ci==1
	replace ocupa_ci=8 if  …  & emp_ci==1
	replace ocupa_ci=9 if  …  & emp_ci==1
*/
	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	replace pension_ci=1 if y29_1b==1 | y29_5b==1 | y29_7b==1 | y29_1c==1 | y29_1d==1 | y29_1e==1 | y29_1f==1 | y29_1g==1 | y29_1h==1 | y29_1i==1
	replace pension_ci=0 if pension_ci==. & (y29_1b==2 | y29_5b==2| y29_7b==2 | y29_1c==2 | y29_1d==2 | y29_1e==2 | y29_1f==2 | y29_1g==2 | y29_1h==2 | y29_1i==2 )
	
	
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
	replace pensionsub_ci = 1 if  y29_5b==1 | y29_7b==1 | y29_1d ==1 | y29_1c==1 | y29_3f==1 | y29_1h==1 | y29_3h==1 | y29_m2_a1==1 
	replace pensionsub_ci = 0 if pension_ci==0 & pensionsub_ci==.
	
	***************
	**tipopen_ci**
	***************
	gen byte tipopen_ci = . 
	
	
gen vejez=1 if (y29_1b==1) | (y29_4b==1) | y29_5b==1  | y29_7b==1 | y29_3h==1 | y29_m2_a1==1 
gen invalidez=1 if (y29_1d==1) | (y29_1e==1)  
gen montepio=1 if y29_3f==1 | (y29_1f==1)
gen orfandad=1 if y29_1g==1
gen otros=1 if (y29_1h==1) | (y29_1i==1)


replace tipopen_ci = 1 if (vejez > 0 & vejez!= .)
replace tipopen_ci = 2 if (invalidez> 0 & invalidez!= .)
replace tipopen_ci = 3 if (montepio> 0 & montepio!= .)
replace tipopen_ci = 4 if (orfandad> 0 & orfandad != .)
replace tipopen_ci = 12 if (vejez > 0 & vejez!= .) | (invalidez> 0 & invalidez!= .)
replace tipopen_ci = 13 if (vejez > 0 & vejez!= .) | (montepio> 0 & montepio!= .)
replace tipopen_ci = 14 if (vejez > 0 & vejez!= .) | (orfandad> 0 & orfandad != .)
replace tipopen_ci = 23 if (invalidez> 0 & invalidez!= .)| (montepio> 0 & montepio!= .)
replace tipopen_ci = 24 if (invalidez> 0 & invalidez!= .) | (orfandad> 0 & orfandad != .)
replace tipopen_ci = 123 if (vejez > 0 & vejez!= .) | (invalidez> 0 & invalidez!= .) | (montepio> 0 & montepio!= .)
replace tipopen_ci = 1234 if (vejez > 0 & vejez!= .) | (invalidez> 0 & invalidez!= .) | (montepio> 0 & montepio!= .) | (orfandad> 0 & orfandad != .)
label define  t 1 "Jubilacion" 2 "Pension invalidez" 3 "Pension viudez" 4 "Orfandad" 12 " Jub y inv" 13 "Jub y viud" 14 "Jub y orfandad" 23 "Viud e inv" 24 "orfandad y inv"  123 "Jub inv viud" 1234 "Todas"
label value tipopen_ci t


	
	***************
	**instpen_ci **
	***************
	gen byte instpen_ci = . 
	
replace instpen_ci = y29_9b if vejez == 1
replace instpen_ci = y29_3e if invalidez == 1
replace instpen_ci = y29_6f if montepio == 1
replace instpen_ci = y29_3g if orfandad == 1

replace instpen_ci =. if instpen==-88
label define instpen_ci 1 "AFP" 2 "IPS ex-INP" 3 "CAPREDENA o DIPRECA" 4 "MUTUAL O ISL" 5 "COMPANIA DE SEGUROS" 6 "Otros"
label value instpen_ci instpen_ci
	
drop vejez invalidez montepio orfandad otros
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	generate double ylmpri_ci = yoprcor  if emp_ci==1

	************
	* ylmsec_ci *
	************
	gen  double ylmsec_ci3 = ytrabajocor-yoprcor   if emp_ci==1

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci = . if emp_ci==1
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	*egen double ylnmpri_ci = rowtotal(...) if emp_ci==1, mi
	gen double ylnmpri_ci = . if emp_ci==1
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
    gen double ylnmsec_ci =  . if emp_ci==1
    replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
    gen double ylnmotros_ci =  . if emp_ci==1
    replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	gen inglab =  ytrabajocor *-1
	egen double ynlm_ci = rowtotal(yautcor  inglab  ysub), mi
	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .
	
	drop inglab
	
	/* Nota:

ytotcorh = yautcorh yaimcorh ysubh

yautaj= ingresos autonomos (la suma de todos los pagos que reciben las 
personas, provenientes tanto del trabajo como de la propiedad de los activos)

ytrabaj = ingreso laboral (Corresponden a los ingresos que obtienen las 
personas en su ocupación por concepto de sueldos y salarios, monetarios y 
en especies ganancias provenientes del trabajo independiente la auto-provisión
de bienes producidos por el hogar)

ysubaj=todos los aportes en dinero que reciben las personas y los hogares del 
Estado a través de los programas sociales.

*/

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
    egen double ynlm_ch = rowtotal(ynlm_ci) if miembros_ci==1, mi
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci==1, mi

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
    generate double remesas_ch = .

	**********
	* ypen_ci *
	**********
	egen double ypen_ci =rowtotal(y29_2b y29_8b y29_2d y29_5d y29_2e y29_2f y29_2g y29_2h y29_5h y29_3i y29_m2_a2) if pension_ci==1, mi


	*************
	* ypensub_ci *
	*************
	egen double ypensub_ci =rowtotal(y29_6b y29_8b y29_2d y29_1cmonto y29_2f y29_2h y29_4h y29_m2_a2) if pensionsub_ci==1, mi
		
****************************
***VARIABLES DE EDUCACION***
****************************




	*********
	*aedu_ci*
	*********
	
	replace e6b = . if e6b == -88
	
	gen aedu_ci=.
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron
	replace aedu_ci=0 if (e6a >= 1 & e6a <= 4)  // Cero anios de educación para aquellos que no han asistido nunca a ninguna institucion y los menores de 2 anios
	replace aedu_ci = e6b      if inrange(e6a, 6, 7)  /*Preparatoria  (Sist. antiguo) y Básica (Sist. nuevo) */
	replace aedu_ci = e6b + 6 if inrange(e6a, 8, 10)   /*Humanidades (Sist. antiguo) Técnica, Comercial, Industrial o Normalista (Sist. antiguo) */
	replace aedu_ci = e6b + 8   if inrange(e6a, 9, 11)  /*Educación Media Científico Humanística (Sist. nuevo) Educación Media Técnica Profesional (Sist. nuevo)*/           
	replace aedu_ci = e6b + 12  if e6a >= 12 & e6a <= 13  /*Tecnico nivel superior completo o incompleto, profesional completo o incompleto*/
	replace aedu_ci = e6b + 16 - 1  if inrange(e6a, 14, 15)    /*Posgrado*/
		
			

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = (inrange(e6a_asiste, 12, 15) | (inrange(e6a_no_asiste, 12,15) & e6c_completo == 2))
	replace eduui_ci = . if aedu_ci == . 

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = (inrange(e6a_asiste, 14, 15)|(inrange(e6a_no_asiste, 12,13) & e6c_completo == 1) | inrange(e6a_no_asiste, 14, 15))
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci =.
	replace eduac_ci = 1 if  (inrange(e6a_asiste, 13, 15) | inrange(e6a_no_asiste, 13, 15))
	replace eduac_ci = 0 if  (e6a_asiste == 12 | e6a_no_asiste == 12)
	replace eduac_ci = . if aedu_ci == .
	
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.
	*replace edupre_ci = 1 if ....
	*replace edupre_ci = 0 if ....

	************
	*asispre_ci*
	************
	g asispre_ci=(e3==1 & e6a==4)


	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci=0 if (e3==2)
	replace asiste_ci=1 if (e3==1)


	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci=. 
	replace pqnoasis1_ci =  1 if e4a==6
	replace pqnoasis1_ci =  2 if e4a==9 
	replace pqnoasis1_ci =  3 if e4a==3 | e4a==4 | e4a==10 | e4a==12 | e4a==5
	replace pqnoasis1_ci =  4 if e4a==11 | e4a==8
	replace pqnoasis1_ci =  5 if e4a==13 | e4a==1 | e4a==2 | e4a==7
	
	
	***********
	*edupub_ci*
	***********
	gen edupub_ci =.
	*replace edupub_ci = 1 if ...
	*replace edupub_ci = 0 if ...
		

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=1 if v24>0 & v24<8
	replace luz_ch=0 if v24==8

	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	replace luzmide_ch=0 if v24>=3 & v24<8
	replace luzmide_ch=1 if v24>0 & v24<3		
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if  v34a==1 | v34a==2 | v34a==5 | v34a==6
	replace combust_ch=1 if  v34a==	3 | v34a==4 | v34a==7 | v34a==8	
	
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
	gen dorm_ch=.
	replace dorm_ch=v27a if v27a!=-88
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=.

	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.

	
	***********
	*telef_ch*
	***********
	gen telef_ch=.
	
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.

	
	***********
	*freez_ch*
	***********
	gen freez_ch=.

	
	***********
	*auto_ch*
	***********
	gen auto_ch=.

	
	***********
	*compu_ch*
	***********
	gen compu_ch=.

		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=1 if r17a==1 | r17b==1  | r17c==1 | r17d==1 | r17e==1
	replace internet_ch=0 if internet_ch==. & (r17a==2 | r17b==2 | r17c==2 | r17d==2 | r17e==2)
	
	
	***********
	*vivi1_ch*
	***********
	gen vivi1_ch=.
	*replace vivi1_ch=1 if ...	
	*replace vivi1_ch=2 if ...
	*replace vivi1_ch=3 if ...
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch=0 if v13==2 
	replace viviprop_ch=1 if v13==1	& (v13_propia==1 | v13_propia==3)
	replace viviprop_ch=2 if v13==1	& (v13_propia==2 | v13_propia==4)
	replace viviprop_ch=3 if v13>2 & v13<12
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	*replace vivitit_ch=0 if ...
	*replace vivitit_ch=1 if ...	
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=.
	replace vivialq_ch=v18 if v18!=-88
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=.
	replace vivialqimp_ch=v19 if v19!=-88
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.
	replace aguared_ch = 1 if v20==1
	replace aguared_ch = 0 if v20>1 & v20<8

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =.
	/*replace aguafconsumo _ch = 0 if …
	replace aguafconsumo _ch = 1 if …
	replace aguafconsumo _ch = 2 if …
	replace aguafconsumo _ch = 3 if …
	replace aguafconsumo _ch = 4 if …
	replace aguafconsumo _ch = 5 if …
	replace aguafconsumo _ch = 6 if …
	replace aguafconsumo _ch = 7 if …
	replace aguafconsumo _ch = 8 if …
	replace aguafconsumo _ch = 9 if …
	replace aguafconsumo _ch = 10 if …
*/
	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	/*replace aguafuente_ch = 1 if …
	replace aguafuente_ch = 2 if …
	replace aguafuente_ch = 3 if …
	replace aguafuente_ch = 4 if …
	replace aguafuente_ch = 5 if …
	replace aguafuente_ch = 6 if …
	replace aguafuente_ch = 7 if …
	replace aguafuente_ch = 8 if …
	replace aguafuente_ch = 9 if …
	replace aguafuente_ch = 10 if …
	*/
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if v22==1
	replace aguadist_ch = 2 if v22==2
	replace aguadist_ch = 3 if v22==3
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =.
	*replace aguadisp1_ch = 1 if …
	*replace aguadisp1_ch = 2 if …
	replace aguadisp1_ch = 9 
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =.
	/* replace aguadisp2_ch = 1 if …
	replace aguadisp2_ch = 2 if …
	replace aguadisp2_ch = 3 if … */
	replace aguadisp2_ch = 9 
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	*replace aguatrat_ch = 0 if …
	*replace aguatrat_ch = 1 if …
	
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
	replace aguamide_ch = 0 if v20==1 & v20_red==3
	replace aguamide_ch = 1 if v20==1 & (v20_red==1 | v20_red==2)
	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
	replace bano_ch = 0 if v23==2
	replace bano_ch = 1 if v23==1 & v23_sistema==1
	replace bano_ch = 2 if v23==1 & v23_sistema==2
	replace bano_ch = 3 if v23==1 & v23_sistema==3 | v23_sistema==4
	*replace bano_ch = 4 if …
	replace bano_ch = 5 if v23==1 & v23_sistema==7
	*replace bano_ch = 6 if …
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	*replace banoex_ch = 0 if …
	*replace banoex_ch = 1 if …
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	*replace sinbano_ch = 0 if …
	*replace sinbano_ch = 1 if…
	*replace sinbano_ch = 2 if…
	*replace sinbano_ch = 3 if…
		
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
	gen byte migrante_ci= .
	replace migrante_ci=0 if (r1b==1 | r1b==2) 
	replace migrante_ci=1 if (r1b==3) 
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.
	replace migrantiguo5_ci=0 if migrante_ci==1 & (inlist(r1cp,1,2,3))
	replace migrantiguo5_ci=1 if migrante_ci==1 & (inlist(r1cp,4,5,6,7,8))
	

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = .
	replace miglac_ci = 0 if  migrante_ci==1
	replace miglac_ci = 1 if (inlist(r1b_pais_esp,32, 44, 52, 84, 68, 76, 170, 188, 218, 222, 320, 332, 340, 388, 484, 558, 591, 780, 858, 862) & migrante_ci==1)
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 
	*replace tipo_bienestar  = 2

	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if pobreza==3
	replace pobre_ine_ci= 1 if pobreza==1 | pobreza==2

	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 
	replace bienestar_agregado = yae

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci = li
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci = lp
	

	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
