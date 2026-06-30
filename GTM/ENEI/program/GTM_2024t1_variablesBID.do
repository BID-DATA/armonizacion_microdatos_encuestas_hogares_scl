*(Versión stata 17)

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

local PAIS GTM
local ENCUESTA ENEIC
local ANO "2024"
local ronda t1
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: GTM
Encuesta: ENEIC
Round: t1
Autores: 
Versión: Juan Camilo Perdomo (SCL/SCL) - Email: ..., Fecha: Octubre de 2025
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/

use `base_in', clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************

	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=.
	replace region_BID_c=1


	********************
	*** region_c ****
	********************
	gen region_c=.

	*************
	* pais_c    *
	*************
	gen str3 pais_c="GTM"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=.
	* La variable corresponde al trimestre y siempre toma el valor 1

	******
	*zona*
	******
	gen zona_c=(p00a10==1)
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	*****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	gen idh_ch=num_hogar
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen new_id = string(num_hogar) + "_" + string(num_persona)
	gen idp_ci= new_id
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=factor_p
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=factor_h
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=p02a02

	*********
	*edad_ci*
	*********
	gen int edad_ci=p02a03
	replace edad_ci=. if p02a03==.
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if p02a07 == 1
	replace relacion_ci = 2 if p02a07 == 2
	replace relacion_ci = 3 if p02a07 == 3
	replace relacion_ci = 4 if inrange(p02a07,4,11)
	replace relacion_ci = 5 if inrange(p02a07,13,14)
	replace relacion_ci = 6 if p02a07 == 12
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=(p02a07!=12)
	* Solo se exluyen los empleados domésticos, según instrucciones del manual
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if p02a12==7
	replace civil_ci = 2 if p02a12==1 | p02a12==2
	replace civil_ci = 3 if inrange(p02a12,3,5)
	replace civil_ci = 4 if p02a12==6
		
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
	
	
*****************************
***VARIABLES DE DIVERSIDAD***
*****************************

	*********
	*afro_ci*
	*********
	 gen byte afro_ci = .
     replace afro_ci = 1 if p02a08==4 | p02a08 == 2
	 replace afro_ci = 0 if p02a08!=4 & p02a08 != 2 & p02a08!=.
	
	*********
	*ind_ci*
	*********	
    gen byte ind_ci = .
    replace ind_ci = 1 if p02a08==1 | p02a08==2 | p02a08==6
	replace ind_ci = 0 if inlist(p02a08,3, 4, 5) & p02a08!=.
	
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
	gen byte afroind_ci=.
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1
	
	***************
	*afroind_ano_c*
	***************
	gen afroind_ano_c=2022
	* Se genera con el año que está en el manual, pero hay que tener en cuenta el cambio de encuesta, no sé si modifique esta variable
	
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
	gen byte dis_ci = .
	egen dificultad = rowmax(p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f)
	replace dis_ci = (dificultad >= 2 & dificultad <= 4)
	foreach var in p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f {
    replace dis_ci = . if inlist(`var', 9, 99,.)
	}
	drop dificultad

	**********
	*disWG_ci*
	**********
	gen byte disWG_ci=.
	egen dificultad = rowmax(p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f)
	replace disWG_ci = (dificultad >= 3 & dificultad <= 4)
	foreach var in p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f {
    replace disWG_ci = . if inlist(`var', 9, 99,.)
	}
	drop dificultad
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte GTM_dis_ci = dis_ci
	

**********************************
***VARIABLES DE MERCADO LABORAL***
**********************************

	*************
	*condocup_ci*
	*************
	gen condocup_ci=.
	replace condocup_ci=1 if ocupados ==1 
	replace condocup_ci=2 if desocupados ==1
	replace condocup_ci=3 if inactivos ==1 & edad_ci>=7 & edad_ci!=.
	replace condocup_ci=4 if edad_ci<7

	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if  (p05a02==7 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (p05a02==5 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (p05a02==6 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 & categoinac_ci != 2 & categoinac_ci != 3) & condocup_ci == 3)
	
	**********
	***emp_ci*
	**********
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la 	sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci=1 if p05b09==1 & condocup_ci==2
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
	***horaspri_ci***
	***************	
	gen horaspri_ci=p05h01a if emp_ci==1
	replace horaspri_ci = . if p05h01a == 999 
	replace horaspri_ci=. if emp_ci==0
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = p05h01c
	replace horastot_ci = . if emp_ci == 0
	
	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci = 1 if horaspri_ci<30 & p05h02==1 & p05h07==1

	****************
	***durades_ci***
	****************
	gen byte durades_ci=p05b04*52/12

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
	replace nempleos_ci = 1 if emp_ci == 1 
	replace nempleos_ci = 2 if emp_ci == 1 & p05g01 == 1
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	gen byte antiguedad_ci = p05c03
	replace antiguedad_ci = 1 if p05c03 != . & emp_ci == 1 
	
	***************
	***desalent_ci***
	***************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (p05b01 == 2 & (p05b05 == 13 | p05b05 == 14) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci=.
	replace tiempoparc_ci  = (emp_ci==1 & p05h02==2 & (horaspri_ci>=1 & horaspri_ci<30))
	
	***************
	***categopri_ci ***
	***************	
	gen  byte categopri_ci = .
	*replace categopri_ci  = 0 if ... No hay categoría que corresponda a "otro"	
	replace categopri_ci  = 1 if (p05c16==6|p05c16==8)
	replace categopri_ci  = 2 if (p05c16==5|p05c16==7)
	replace categopri_ci  = 3 if inrange(p05c16, 1, 4)
	replace categopri_ci  = 4 if p05c16==9
	
	***************
	***categosec_ci ***
	***************	
	gen  byte categosec_ci = .
	*replace categosec_ci  = 0 if ... No hay categoría que corresponda a "otro"	
	replace categosec_ci  = 1 if (p05g08==6|p05g08==8)
	replace categosec_ci  = 2 if (p05g08==5|p05g08==7)
	replace categosec_ci  = 3 if inrange(p05g08, 1, 4)
	replace categosec_ci  = 4 if p05g08==9	

	***************
	***rama_ci ***
	***************	
	gen  byte rama_ci = .
	replace rama_ci=1 if p05c04_2d >=1 & p05c04_2d <=3
	replace rama_ci=2 if p05c04_2d >=5 & p05c04_2d <=9
	replace rama_ci=3 if p05c04_2d >=10 & p05c04_2d <=33
	replace rama_ci=4 if p05c04_2d >=35 & p05c04_2d <=39
	replace rama_ci=5 if p05c04_2d >=41 & p05c04_2d <=43
	replace rama_ci=6 if (p05c04_2d >=45 & p05c04_2d <=47) | (p05c04_2d >=55 & p05c04_2d <=56)
	replace rama_ci=7 if (p05c04_2d >=49 & p05c04_2d <=53) | p05c04_2d ==61 
	replace rama_ci=8 if p05c04_2d >=64 & p05c04_2d <=68
	replace rama_ci=9 if (p05c04_2d >=69 & p05c04_2d <=99) | (p05c04_2d >=58 & p05c04_2d <=60) | (p05c04_2d >=62 & p05c04_2d <=63)							

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci  = 0 if emp_ci==1 & p05c16 != 1
	replace spublico_ci  = 1 if emp_ci==1 & p05c16 == 1
	
	***************
	***tamemp_ci ***
	***************	
	gen tamemp_ci = 1 if p05c13>=1 & p05c13<=5
	replace tamemp_ci = 2 if (p05c13>=6 & p05c13<=7)
	replace tamemp_ci = 3 if (p05c13>7) & p05c13!=.
	
	***************
	***cotizando_ci***
	***************	
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((p05c08a==1 & (p05c08b>0 & p05c08b!=.)) | (p05g06a==1 & (p05g06b>0 & p05g06b!=.)) & emp_ci==1)
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	***************
	***afiliado_ci***
	***************	
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if((inrange(p05c08a,1,3) | inrange(p05g06a,1,3)) & emp_ci==1)
	replace afiliado_ci = 0 if (afiliado_ci != 1 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci
	
	***************
	***instcot_ci***
	***************	
	gen  byte instcot_ci = .
	
	**************
	***formal_ci***
	**************
	gen byte formal_ci = .
	replace formal_ci  =  1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)
	** Existe una variable de formalidad creaca por el ONE de GTM se llama formal_informal
	
	*******************
	***tipocontrato_ci***
	*******************
	gen tipocontrato_ci=.
	replace tipocontrato_ci=1 if (p05c21a==1 & p05c20==1) & categopri_ci==3
	replace tipocontrato_ci=2 if (p05c21a==2 & p05c20==1)  & categopri_ci==3
	replace tipocontrato_ci=3 if (p05c20==2 | tipocontrato_ci==.) & categopri_ci==3
		
	**************
	***ocupa_ci***
	**************
	gen ocupa_ci=.
	replace ocupa_ci=1 if (p05c02_2d >=21 & p05c02_2d <=35) & emp_ci==1
	replace ocupa_ci=2 if (p05c02_2d >=11 & p05c02_2d <=14) & emp_ci==1
	replace ocupa_ci=3 if (p05c02_2d >=41 & p05c02_2d <=44) & emp_ci==1
	replace ocupa_ci=4 if (p05c02_2d ==52 | p05c02_2d ==95) & emp_ci==1
	replace ocupa_ci=5 if (p05c02_2d ==51 | (p05c02_2d >=53 & p05c02_2d <=54) | p05c02_2d ==91) & emp_ci==1
	replace ocupa_ci=6 if ((p05c02_2d >=61 & p05c02_2d <=63) | p05c02_2d ==92) & emp_ci==1
	replace ocupa_ci=7 if ((p05c02_2d >=71 & p05c02_2d <=83) | p05c02_2d ==93) & emp_ci==1
	replace ocupa_ci=8 if (p05c02_2d >=0 & p05c02_2d <=3) & emp_ci==1
	replace ocupa_ci=9 if (p05c02_2d ==94 | p05c02_2d ==96) & emp_ci==1

	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	replace pension_ci=(p06a05a==1)
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = .
	
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
	
	***********************************************
	** AJUSTE A ENCUESTA ENEIC 2024.              *
	** JUAN CAMILO PERDOMO - FRONT SCL OCUBRE 2024*
	***********************************************
	/* 
	P04C13B	(p05d08b) CUÁNTO DINERO RECIBIÓ ¿Cuánto le pagaron por trabajar en su período vacacional? 
	P04C14B	(p05d09b) CUÁNTO DINERO RECIBIÓ bono 14
	P04C15B	(p05d10b) CUÁNTO DINERO RECIBIÓ aguinaldo
	P04C16B	(p05d11b) CUÁNTO DINERO RECIBIÓ bono vacacional
	P04C17B	(p05d12b) CUÁNTO DINERO RECIBIÓ algún quinceavo sueldo o diferido
	P04C21B	(p05d07b) CUÁNTO DINERO RECIBIÓ bonos de productividad, de desempeño o por estímulos laborales
	No incluye lo que recibió por alimentación/subsidio, vivienda, transporte recibidos en el trabajo
	*/
	
	foreach var of varlist p05d08b p05d09b p05d10b p05d11b p05d12b p05d07b{ 
	g `var'tdp=`var'/12 
	}
	
	/* 2024:
	p05d01: sueldo o salario mensual sin descuentos. No incluya: horas extras,comisiones, propinas, aguinaldo, bono 14, bono de productividad o desempeño 
	p05d02c: ¿Recibió dinero por trabajar horas extras? 
	p05d03b: Recibió dinero por conceptos de comisiones, dietas, propinas o víaticos?
	p05e10: ingreso neto o ganancia mensual de su empresa, negocio, actividad o profesión después de gastos (Ganancia actividad no agrícola)
	p05e11: ganancia o ingreso neto promedio mensual por ventas de cosechas, animales y/o venta de subproductos agropecuarios (Ganancia actividad agrícola)
	*/
		
	egen ylmpri_ci= rsum(p05d01 p05d02c p05d03b p05e10 p05e11 *tdp), missing

	************
	* ylmsec_ci *
	************
	
	/*
	2024

	***********************************************
	** AJUSTE A ENCUESTA ENEIC 2024.              *
	** JUAN CAMILO PERDOMO - FRONT SCL OCUBRE 2024*
	***********************************************
	
	p05g10: sueldo o salario mensual sin descuentos segundo trabajo 2da ocu
	p05g12b: Bonificaciones en efectivo
	p05g13b: bono 14 2da ocu
	p05g14b: aguinaldo 2da ocu
	p05g26: ingreso neto o ganancia mensual de su empresa, negocio, actividad o profesión, después de gastos 2da ocu
	
	** Horas extra lo incluyeron dentro de bonificaciones
	
	*/
	foreach var of varlist p05g12b p05g13b p05g14b{
	g `var'tdpsec=`var'/12
	}
	egen ylmsec_ci=rsum(p05g10 *tdpsec p05g26), missing
	label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 

	**************
	* ylmotros_ci *
	**************
	
	/*2024
	p06b02b: Igresos por Trabajos diferentes a los ya reportados
	p06b01b: Igresos por Venta de cosechas o de animales como: cerdos, pavos, gallinas, vacas u otros
	p06b03b: Igresos por Negocios no agropecuarios diferentes a los ya reportados
	*/
    egen ylmotros_ci = rowtotal(p06b01b p06b02b p06b03b) if emp_ci==1
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	
	/*2024
	p05d04b: Valoración de los alimentos recibidos en el trabajo
	p05d05b: Valoración del costo de la vivienda recibida en el trabajo
	p05d06b: Valoración del costo del transporte recibido en el trabajo
	*/
	egen ylnmpri_ci=rsum(p05d04b p05d05b p05d06b), missing
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
    gen double ylnmsec_ci = p05g11b if emp_ci==1
    replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
    gen ylnmotros_ci=.
	
	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	
	/*
	2024
	p06a01b: alquileres (últimos 3 meses)
	p06a02b: intereses (últimos 3 meses)
	p06a03b: donaciones (últimos 3 meses)
	p06a04b: pensión alimenticia (últimos 3 meses)
	p06a05b: jubilación (últimos 3 meses)
	p06a06b: becas y bonos (últimos 3 meses)
	p06a07b: seguro desempleo (últimos 3 meses)
	p06b04b: rentas de propiedad marca, patentes y derechos (12 meses)
	p05d13b: dinero por indemnización por accidente 
	p05d14b: dinero por indemnización por trabajo
	*/
	
	foreach var of varlist p06a01b p06a02b p06a03b p06a04b p06a05b p06a06b p06a07b {
	g `var'tdp3=`var'/3
	}

	foreach var of varlist p06b04b p05d13b p05d14b {
	g `var'tdp12=`var'/12
	}
	egen ynlm_ci=rsum(*tdp3*), missing

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci = p05g27b
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
	egen suma_rem = rowtotal(p06c02b p06c03b p06c04b)
    generate double remesas_ci = suma_rem/3

	*************
	* remesas_ch *
	*************
	by idh_ch, sort: egen byte remesas_ch = sum(remesas_ci) if miembros_ci == 1

	**********
	* ypen_ci *
	**********
	generate double ypen_ci = p06a05b if pension_ci==1

	*************
	* ypensub_ci *
	*************
	gen ypensub_ci = .

****************************
***VARIABLES DE EDUCACION***
****************************

	*********	
	*aedu_ci*
	*********
	gen aedu_ci=.
	replace aedu_ci = 0            if inlist(p03a03a, 0, 1) // ninguno, prep
    replace aedu_ci = p03a03b      if p03a03a==2  // primaria
    replace aedu_ci = 6  + p03a03b if p03a03a==3 // básico
    replace aedu_ci = 6  + p03a03b if p03a03a==4 // diversificado
    replace aedu_ci = 11 +  p03a03b if p03a03a==5 // superior
    replace aedu_ci = 16 + p03a03b if p03a03a==6 // maestría
    replace aedu_ci = 18 + p03a03b if p03a03a==7 // doctorado

	
	// no hay suficiente info para generar las variables de superior
	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = .

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = .
	

	**********
	*eduac_ci*
	**********
	
	gen byte eduac_ci = .
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci = .

	************
	*asispre_ci*
	************
	gen byte asispre_ci = .
	
	***********
	*asiste_ci*
	***********
	// Inscripción, no asistencia 
	gen byte asiste_ci = (p03a02 == 1) if p03a02 !=.

	*************
	*razonesnoasis_ci*
	**************
	gen razonesnoasis_ci = .
    
	***********
	*edupub_ci*
	***********
	gen edupub_ci =.
	

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.	
	
	***********
	*piso_ch*
	***********
	gen piso_ch=.	
	
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
	gen resid_ch=.
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.
	
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
	
	***********
	*vivi1_ch**
	***********
	gen vivi1_ch=.
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch = 0 if p01a01==3
	replace viviprop_ch = 1 if p01a01==1
	replace viviprop_ch = 2 if p01a01==2
	replace viviprop_ch = 3 if p01a01==4
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=p01a03
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=p01a02
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =0

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =9
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	
	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = .

	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = .
	
	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .
	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
		
	******************
    ** banomejorado_ch ** - 
    *****************
	gen byte banomejorado_ch= .
	
	
****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci=(p02a05a==3)
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci= (migrante_ci==1 & p02a06b>=5)
	replace migrantiguo5_ci = . if migrante_ci == 0

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci = inlist(p02a05f, 3003, 3004, 3005, 3006, 3007, 3008, 3010, 3011, 3012, 3013, 3014, 3015, 3016, 3020, 3021, 3022, 3023, 3030, 3035, 3040, 3043, 3044, 3098)
	replace miglac_ci = . if migrante_ci == 0


****************************
***VARIABLES DE EXTERNAS***
****************************	

** CON ESTA ENCUESTA NO MIDEN POBREZA, LO HACEN CON LA ENCOVI
	
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 

	****************
	 * pobre_ine _ci*
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
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
