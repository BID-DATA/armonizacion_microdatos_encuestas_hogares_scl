
* (Versión Stata 12)
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

local PAIS ARG
local ENCUESTA EPHC
local ANO "2006"
local ronda s1 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   



capture log close
log using "`log_file'", replace 

log off
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Argentina
Encuesta: EPHC
Round: ISem-2006
Autores: 
Version 2010: Yanira
Versión 2012: Yessenia Loaysa
Última versión: María Laura Oliveri (MLO) - Email: mloliveri@iadb.org, lauraoliveri@yahoo.com
Fecha última modificación: 26 de Marzo de 2013

							SCL/LMK - IADB
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/


use `base_in', clear


		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************
		
	****************
	* region_BID_c *
	****************
	
gen region_BID_c=4



	************
	* region_c *
	************
	
gen region_c=.
replace region_c=1  if (aglomerado>=2 & aglomerado<=3) | (aglomerado>=33 & aglomerado<=34) | (aglomerado==38) /*Buenos Aires */
replace region_c=2  if aglomerado==22                          /*Catamarca*/
replace region_c=3  if aglomerado==8                           /*Chaco*/
replace region_c=4  if aglomerado==9 | aglomerado==91          /*Chubut*/
replace region_c=5  if aglomerado==32                          /*Ciudad de Buenos Aires*/
replace region_c=6  if aglomerado==13 | aglomerado==36         /*Córdova*/
replace region_c=7  if aglomerado==12                          /*Corrientes*/
replace region_c=8  if aglomerado==6 | aglomerado==14          /*Entre Ríos*/
replace region_c=9  if aglomerado==15                          /*Formosa*/
replace region_c=10 if aglomerado==19                          /*Jujuy*/
replace region_c=11 if aglomerado==30                          /*La pampa*/
replace region_c=12 if aglomerado==25                          /*La Rioja*/
replace region_c=13 if aglomerado==10                          /*Mendoza*/
replace region_c=14 if aglomerado==7                           /*Misiones*/
replace region_c=15 if aglomerado==17                          /*Neuquen*/
replace region_c=16 if aglomerado==93                          /*Río Negro*/ 
replace region_c=17 if aglomerado==23                          /*Salta*/
replace region_c=18 if aglomerado==27                          /*San Juan*/ 
replace region_c=19 if aglomerado==26                          /*San Luis*/
replace region_c=20 if aglomerado==20                          /*Santa Cruz*/
replace region_c=21 if aglomerado>=4 & aglomerado<=5           /*Santa Fe*/
replace region_c=22 if aglomerado==18                          /*Santiago de Estero*/
replace region_c=23 if aglomerado==31                          /*Tierra del Fuego*/
replace region_c=24 if aglomerado==29                          /*Tucuman*/

	label define region_c     ///
	1"Buenos Aires"           ///	
	2"Catamarca"              ///
	3"Chaco"                  /// 
	4"Chubut"                 ///
	5"Ciudad de Buenos Aires" ///
	6"Córdoba"                ///
	7"Corrientes"             ///
	8"Entre Ríos"             ///
	9"Formosa"                ///
	10"Jujuy"                 ///
	11"La Pampa"              ///
	12"La Rioja"              ///
	13"Mendoza"               ///
	14"Misiones"              ///
	15"Neuquon"               ///
	16"Río Negro"             ///
	17"Salta"                 ///
	18"San Juan"              ///
	19"San Luis"              ///
	20"Santa Cruz"            ///
	21"Santa Fe"              ///
	22"Santiago del Estero"   ///
	23"Tierra del Fuego"      ///
	24"Tucumán"               
   label value region_c region_c
   label var region_c "division politico-administrativa, provincia"
   
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	*capture rename pond_sem pondera if ano4==2003

	gen factor_ch=pondera
	label var factor_ch "Factor de expansion del hogar"

		*************************
		***VARIABLES DEL HOGAR***
		*************************
		
	******************
	*idh_ch (idhogar)*
	******************
	
	sort codusu aglomerado nro_hogar
	egen idh_ch=group(codusu aglomerado nro_hogar)
	label variable idh_ch "ID del hogar"
	
	********
	*idp_ci*
	********
	
	gen idp_ci=componente
	label variable idp_ci "ID de la persona en el hogar"
	

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	
	gen zona_c=1
	label variable zona_c "Zona del pais"
	label define zona_c 1 "Urbana" 0 "Rural"
	label value zona_c zona_c


	******
	*pais*
	******

	gen str3 pais_c="ARG"
	label variable pais_c "Pais"


	******
	*anio*
	******
	
	gen anio_c=ano4
	label variable anio_c "Anio de la encuesta" 


	**********
	*semestre*
	**********

	gen semestre_c=1
	label var semestre_c "Semestre de la encuesta" 
	
	
	*************
	*relacion_ci*
	*************
	
	gen relacion_ci=1 if ch03==1
	replace relacion_ci=2 if ch03==2
	replace relacion_ci=3 if ch03==3
	replace relacion_ci=4 if ch03>=4 & ch03<=9
	replace relacion_ci=5 if ch03==10 
	label variable relacion_ci "Relacion con el jefe del hogar"
	label define relacion_ci 1 "Jefe" 2 "Conyuge" 3 "Hijo" 4 "Otros Parientes" 
	label define relacion_ci  5 "Otros no Parientes", add 
	label values relacion_ci relacion_ci
	


			****************************
			***VARIABLES DEMOGRAFICAS***
			****************************

	***********
	*factor_ci* 
	***********

	gen factor_ci=pondera

	*********
	*sexo_ci*
	*********
	
	capture gen sexo_ci=ch04
	drop if sexo_ci>2 | sexo_ci<1 
	label var sexo_ci "Sexo del individuo" 


	*********
	*edad_ci*
	*********
	
	capture gen edad_ci=ch06
	replace edad_ci=0 if edad_ci==-1
	replace edad_ci=98 if edad_ci>=98
	label variable edad_ci "Edad del individuo"


	**************
	*Estado Civil*
	**************
	
	recode ch07 (1=2) (2=2) (3=3) (4=4) (5=1) (9=.), gen(civil_ci) 
	label variable civil_ci "Estado civil"
	label define civil_ci 1 "Soltero" 2 "Union formal o informal"
	label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
	label value civil_ci civil_ci

	
	*********
	*jefe_ci*
	*********

	gen jefe_ci=(relacion_ci==1)
	label variable jefe_ci "Jefe de hogar"


	**************
	*nconyuges_ch*
	**************

	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
	label variable nconyuges_ch "Numero de conyuges"


	***********
	*nhijos_ch*
	***********
	
	by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
	label variable nhijos_ch "Numero de hijos"

	**************
	*notropari_ch*
	**************

	by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
	label variable notropari_ch "Numero de otros familiares"	

	****************
	*notronopari_ch*
	****************
	
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	label variable notronopari_ch "Numero de no familiares"


	************
	*nempdom_ch*
	************

	*NOTA: a traves de la relacion de parentesco no es posible identificar a los empleados domesticos
	*Se pregunta a parte si el individuo presta servicios domesticos. No obstante, no se sabe si pertenecen
	*al hogar encuestado directamente, por ello se aproxima a esta medida usando la relacion de parentesco
	gen empldom_ci=0
	replace empldom_ci=1 if pp04b1==1
	label var empldom_ci "El individuo es empleado domestico" 

	by idh_ch, sort: egen nempdom_ch=sum(empldom_ci==1) if relacion_ci==5	  
	label variable nempdom_ch "Numero de empleados domesticos"


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

	label variable clasehog_ch "Tipo de hogar"
	label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
	label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
	label value clasehog_ch clasehog_ch


	**************
	*nmiembros_ch*
	**************

	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<5)
	label variable nmiembros_ch "Numero de familiares en el hogar"


	*************
	*nmayor21_ch*
	*************

	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci>=21 & edad_ci<=98))
	label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

	*************
	*nmenor21_ch*
	*************

	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<21))
	label variable nmenor21_ch "Numero de familiares menores a 21 anios"

	*************
	*nmayor65_ch*
	*************

	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci>=65 & edad_ci!=.))
	label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

	************
	*nmenor6_ch*
	************

	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<6))
	label variable nmenor6_ch "Numero de familiares menores a 6 anios"

	************
	*nmenor1_ch*
	************

	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<5) & (edad_ci<1))
	label variable nmenor1_ch "Numero de familiares menores a 1 anio"

	************
	*miembros_ci
	************
	
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<5) 
	label variable miembros_ci "Miembro del hogar"


				
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************				
* Maria Antonella Pereira & Nathalia Maya - Marzo 2021	

			
	***************
	***afroind_ci***
	***************
gen afroind_ci=. 

	***************
	***afroind_ch***
	***************
gen afroind_ch=. 

	*******************
	***afroind_ano_c***
	*******************
gen afroind_ano_c=.		

	*******************
	***dis_ci***
	*******************
gen dis_ci=. 

	*******************
	***dis_ch***
	*******************
gen dis_ch=. 
	
			***********************************
			***VARIABLES DEL MERCADO LABORAL***
			***********************************

****************
****condocup_ci*
****************

gen condocup_ci=.
replace condocup_ci=1 if estado==1
replace condocup_ci=2 if estado==2
replace condocup_ci=3 if estado==3 & edad_ci>=10
replace condocup_ci=. if estado == 0
replace condocup_ci=4 if estado == 4
label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de PET" 
label value condocup_ci condocup_ci

************
***emp_ci***
************
gen emp_ci=(condocup_ci==1)

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)

*************
***pea_ci***
*************
gen pea_ci=(emp_ci==1 | desemp_ci==1)

/*
	********
	*emp_ci*
	********

	gen emp_ci =(estado==1)
    label var emp_ci "Ocupado (empleado)"


	************
	*desemp1_ci*
	************
	*Ya no se puede discriminar quienes buscaron trabajo en la semana de referencia
	*Pues aunque se pregunta esta informacion no esta en la base de datos. Todo se resume 
	*en la variable estado
	
	gen desemp1_ci=(estado==2)
	label var desemp1_ci "Desempleado que buscó empleo en el periodo de referencia"

*Note: Aunque la definición de desempleado a través de la variable estado (la busqueda de empleo 
*es el mes)encaja más en la variable desemp3, se decide ponerla en desemp1_ci para cuando toque hacer agregaciones de 
*America Latina, Argentina no tenga missing en el desempleo. 

	************
	*desemp2_ci*
	************
	*Tampoco se puede distinguir quienes estan esperando una respuesta de un empleo. No obstante, es posible
	*saber quienes esta esperando la temporada alta, pero no esta la variable en la base de datos.
		
	gen desemp2_ci=.
	label var desemp2_ci "desemp1_ci + personas que esperan respuesta a solicitud o temporada alta"


	************
	*desemp3_ci*
	************ 
		
	gen desemp3_ci=.
	label var desemp3_ci "desemp2_ci + personas que buscaron antes del periodo de referencia"


	*********
	*pea1_ci* 
	*********
	
	gen pea1_ci=(emp_ci==1 | desemp1_ci==1)
	label var pea1_ci "Población Económicamente Activa con desemp1_ci"


	*********
	*pea2_ci*
	*********
	
	gen pea2_ci=.
	label var pea2_ci "Población Económicamente Activa con desemp2_ci"	


	*********
	*pea3_ci* 
	*********
	
	gen pea3_ci=.
	label var pea3_ci "Población Económicamente Activa con desemp3_ci"
*/

	*************
	*desalent_ci*
	*************
	*ANTERIOR: gen desalent_ci=(pea1_ci~=1 & (p01==2 & p07==2) & p08==4) 
	*p08==4 razon de no busqueda es que cree que no encontrara trabajo
	***********/
	*Se toman las personas que reportan haberse cansado de buscar y que pertenecen a la PET

	gen desalent_ci=.
	label var desalent_ci "Trabajadores desalentados"
	
*Note: Se debería incrementar la categoria 4 "hay poco trabajo en esta epoca de año"

	*************	
	*horaspri_ci*
	*************

	gen horaspri_ci=pp3e_tot
	replace horaspri_ci=. if pp3e_tot==999
	label var horaspri_ci "Horas trabajadas en la actividad principal"

	
	************* 
	*horastot_ci*
	*************

	gen otrashoras=pp3f_tot if pp3f_tot!=999
	
	egen horastot_ci=rsum(horaspri_ci otrashoras) 
	replace horastot_ci=. if horaspri_ci==. & otrashoras==.
	label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"
	

	***********
	*subemp_ci*
	***********

	gen subemp_ci=0
	replace subemp_ci=1 if pp03g==1 & (horastot_ci>=1 & horastot_ci<=30) & emp_ci==1
	replace subemp_ci =. if emp_ci ==.
	/*replace subemp_ci=1 if intensi==1 
recode subemp_ci .=0 if intensi==3 | intensi==4 | intensi==5 | intensi==2
tab subemp_ci
*/
	label var subemp_ci "Personas en subempleo por horas"
*Note: Se corrige y se consideran las horas totales

	***************
	*tiempoparc_ci*
	***************
	
	gen tiempoparc_ci=(horastot_ci>=1 & horastot_ci<=30) & (pp03g==2 & emp_ci==1)
	replace tiempoparc_ci=. if emp_ci==0
	label var tiempoparc_ci "Personas que trabajan medio tiempo" 

	
	**************
	*categopri_ci*
	**************
	
	gen categopri_ci=cat_ocup if emp_ci==1
	replace categopri_ci=. if categopri_ci<1 | categopri_ci>4
	label define categopri_ci 1"Patron" 2"Cuenta propia" 0"Otro"
	label define categopri_ci 3"Empleado" 4" No remunerado" , add
	label value categopri_ci categopri_ci
	label variable categopri_ci "Categoria ocupacional"


	**************
	*categosec_ci*
	**************

	gen categosec_ci=.
	label variable categosec_ci "Categoria ocupacional trabajo secundario"


	*************
	*contrato_ci*
	*************
	
	*gen contrato_ci=.
	*label var contrato_ci "Ocupados que tienen contrato firmado de trabajo"


	***********
	*segsoc_ci* 
	***********

	
	*ANTERIOR: We don't consider the people that declare to have 
	*aguinaldo (4), vacaciones (8), Vacaciones y Aguinaldo (12), Indemnizacion (32),
	*Indemnizacion y Aguinaldo (36)	indemnización y Vacaciones (40) and Indemnización, 
	*vacaciones y aguinaldo (44).
	*AHORA:
	*Sigue siendo solo para empleados (categopri_ci==3) solo se incluyen jubilaciones PERO LO QUE SE QUIERE VER ES 
	*AFILIACION A SALUD!!! 
	***********/
	
	*gen segsoc_ci=(categopri_ci==3 & pp07h==1) 
	*replace segsoc_ci=. if emp_ci~=1
	*label var segsoc_ci "Personas que tienen seguridad social en PENSIONES por su trabajo"

*Note: se debe considerar pp07i tambien?

	*************
	*nempleos_ci*
	*************
	
	gen nempleos_ci=pp03d
	replace nempleos_ci=1 if pp03c==1
	replace nempleos_ci=. if emp_ci!=1
	label var nempleos_ci "Número de empleos" 


	*************
	*firmapeq_ci* 
	*************
	
	*gen firmapeq_ci=0 if emp_ci==1
	*replace firmapeq_ci=1 if pp04c>=1 & pp04c<=5 & emp_ci==1
	*label var firmapeq_ci "Trabajadores informales"


	*************
	*spublico_ci* 
	*************
	
	gen spublico_ci=(pp04a==1 & emp_ci==1)
	replace spublico_ci=. if pp04a==0 
	label var spublico_ci "Personas que trabajan en el sector público"


	**********
	*Ocupa_ci*
	**********
	*NOTA: desde 2001 hay otra clasificacion, pero debe estudiarse como hacer las agrupaciones para la 
	*construccion de la variable tal como esta propuesta para la armonizacion.

*************
***ocup1-4***
*************

gen ocup1=substr(pp04d_cod,1,2)
gen ocup2=substr(pp04d_cod,3,1)
gen ocup3=substr(pp04d_cod,4,1)
gen ocup4=substr(pp04d_cod,5,1)

destring ocup1 ocup2 ocup3 ocup4, replace

lab var ocup1 "patron"
lab var ocup2 "asalariados"
lab var ocup2 "cuenta_propia"
lab var ocup2 "sin_salario"

*************
***ocupa_ci**
*************

capture drop ocupa_ci	
gen ocupa_ci=1 if ocup4>=1 & ocup4<=2
replace ocupa_ci=2 if ocup1>=0 & ocup1<=7 & ocupa_ci !=1
replace ocupa_ci=3 if (ocup1==10 | ocup1==11 | ocup1==20) & ocupa_ci !=1
replace ocupa_ci=4 if ocup1>=30 & ocup1<=33 & ocupa_ci !=1
replace ocupa_ci=5 if (ocup1>=36 & ocup1<=47 | ocup1>=52 & ocup1<=58) & ocupa_ci !=1
replace ocupa_ci=6 if ocup1>=60 & ocup1<=65 & ocupa_ci !=1
replace ocupa_ci=7 if ocup1>=70 & ocup1<=92 & ocupa_ci !=1
replace ocupa_ci=8 if ocup1>=48 & ocup1<=49 & ocupa_ci !=1
replace ocupa_ci=9 if (ocup1==34 | ocup1==35 | ocup1==50 | ocup1==51)  & ocupa_ci !=1
replace ocupa_ci=. if estado !=1 & ocup1==99
label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio" ///
4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas"    ///
7 "obreros no agricolas, conductores de maq y ss de transporte" 8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci

	*********
	*rama_ci*
	*********
	*2014, 02 modificacion MLO para que quede en sintonia con nueva codificacion a partir de 2011.
	destring pp04b_cod, replace
	gen rama_ci=.
	replace rama_ci = 1 if (pp04b_cod==1)|(pp04b_cod>=101 &  pp04b_cod<=500)
	replace rama_ci = 2 if (pp04b_cod>=10 & pp04b_cod<=14) |(pp04b_cod>=1000 &  pp04b_cod<=1400)
	replace rama_ci = 3 if (pp04b_cod>=15 & pp04b_cod<=36) |(pp04b_cod>=1501 &  pp04b_cod<=3609)
	replace rama_ci = 4 if (pp04b_cod>=37 & pp04b_cod<=41) |(pp04b_cod>=3700 &  pp04b_cod<=4100)
	replace rama_ci = 5 if (pp04b_cod==45) |(pp04b_cod==4500)
	replace rama_ci = 6 if (pp04b_cod>=50 & pp04b_cod<=55) |(pp04b_cod>=5001 &  pp04b_cod<=5503) &  pp04b_cod!=5311 & pp04b_cod!=5311
	replace rama_ci = 7 if (pp04b_cod>=60 & pp04b_cod<=64) |(pp04b_cod>=6001 &  pp04b_cod<=6402) & pp04b_cod!=6303 &  pp04b_cod!=6402
	replace rama_ci = 8 if (pp04b_cod>=65 & pp04b_cod<=70) |(pp04b_cod>=6500 &  pp04b_cod<=7000)
	replace rama_ci = 9 if (pp04b_cod>=71 & pp04b_cod<=95) |(pp04b_cod>=7100 &  pp04b_cod<=9900) | pp04b_cod==5311 | pp04b_cod==6303 | pp04b_cod==6402 | pp04b_cod==5311

	
/*	destring pp04b_cod, replace
	
capture drop rama_ci
gen rama_ci = .
replace rama_ci = 1 if (pp04b_cod==1)|(pp04b_cod>=101 &  pp04b_cod<=500)
replace rama_ci = 2 if (pp04b_cod>=10 & pp04b_cod<=14) |(pp04b_cod>=1000 &  pp04b_cod<=1400)
replace rama_ci = 3 if (pp04b_cod>=15 & pp04b_cod<=37) |(pp04b_cod>=1501 &  pp04b_cod<=3700)
replace rama_ci = 4 if (pp04b_cod>=40 & pp04b_cod<=41) |(pp04b_cod>=4001 &  pp04b_cod<=4100)
replace rama_ci = 5 if (pp04b_cod==45) |(pp04b_cod==4500)
replace rama_ci = 6 if (pp04b_cod>=50 & pp04b_cod<=55) |(pp04b_cod>=5001 &  pp04b_cod<=5503)
replace rama_ci = 7 if (pp04b_cod>=60 & pp04b_cod<=64) |(pp04b_cod>=6001 &  pp04b_cod<=6402)
replace rama_ci = 8 if (pp04b_cod>=65 & pp04b_cod<=74) |(pp04b_cod>=6500 &  pp04b_cod<=7409)
replace rama_ci = 9 if (pp04b_cod>=75 & pp04b_cod<=95) |(pp04b_cod>=7501 &  pp04b_cod<=9900)
*//*
	capture drop rama_ci
	gen rama_ci = .
	replace rama_ci = 1 if (pp04b_cod==1)|(pp04b_cod>=101 &  pp04b_cod<=500)
	replace rama_ci = 2 if (pp04b_cod>=10 & pp04b_cod<=14) |(pp04b_cod>=1000 &  pp04b_cod<=1400)
	replace rama_ci = 3 if (pp04b_cod>=15 & pp04b_cod<=37) |(pp04b_cod>=1501 &  pp04b_cod<=3700)
	replace rama_ci = 4 if (pp04b_cod>=40 & pp04b_cod<=41) |(pp04b_cod>=4001 &  pp04b_cod<=4100)
	replace rama_ci = 5 if (pp04b_cod==45) |(pp04b_cod==4500)
	replace rama_ci = 6 if (pp04b_cod>=50 & pp04b_cod<=55) |(pp04b_cod>=5001 &  pp04b_cod<=5503)
	replace rama_ci = 7 if (pp04b_cod>=60 & pp04b_cod<=64) |(pp04b_cod>=6001 &  pp04b_cod<=6402)
	replace rama_ci = 8 if (pp04b_cod>=65 & pp04b_cod<=67) |(pp04b_cod>=6500 &  pp04b_cod<=6702)
	replace rama_ci = 9 if (pp04b_cod>=70 & pp04b_cod<=95) |(pp04b_cod>=7000 &  pp04b_cod<=9900)*/
	label var rama_ci "Rama de actividad"
	label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
	label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
	label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
	label val rama_ci rama_ci



	************
	*durades_ci*
	************
	*Esta variable se capturo como categorica por ello se crea como missing. Sin embargo, se 
	*guarda la informacion en una nueva variable durades1_ci
	
	gen durades_ci=.
	label variable durades_ci "Duracion del desempleo en meses"

	gen durades1_ci=pp10a
	replace durades1_ci=. if pp10a==0 | pp10a==9
	label variable durades1_ci "Duracion del desempleo - categorica"
	label define durades1_ci 1 "menos de 1 mes"
	label define durades1_ci 2 "de 1 a 3 meses", add
	label define durades1_ci 3 "más de 3 a 6 meses", add
	label define durades1_ci 4 "más de 6 a 12 meses", add
	label define durades1_ci 5 "más de 1 año", add
	label values durades1_ci durades1_ci
 
	
	***************
	*antiguedad_ci*
	***************
	*NOTA: antes la variable era continua, ahora esta en intervalos

	*Para emp domesticos (continua)
	gen ant_m=pp04b3_mes
	replace ant_m=. if pp04b3_mes==-1 | pp04b3_mes==99 |pp04b3_mes<0
	gen ant_a=pp04b3_ano 
	replace ant_a=. if pp04b3_ano==-1 | pp04b3_ano==99 |pp04b3_ano<0 
	replace ant_m=ant_m/12
	egen antiguedad1=rsum(ant_a ant_m)
	replace antiguedad1=. if pp04b3_mes==0 & pp04b3_ano==0 	

	*Para trabajadores familiares (continua)
	gen ant_mc=pp05b2_mes
	replace ant_mc=. if pp05b2_mes==-1 | pp05b2_mes==99 |pp05b2_mes<0
	gen ant_ac=pp05b2_ano
	replace ant_ac=. if pp05b2_ano==-1 | pp05b2_ano==99 |pp05b2_ano<0 
	replace ant_mc=ant_mc/12
	egen antiguedad2=rsum(ant_a ant_m)
	replace antiguedad2=. if pp05b2_mes==0 & pp05b2_ano==0 	

	*Para Empleados y obreros
	*CREO QUE NO ES POSIBLE CONSTRUIR LA VARIABLE ANTIGUEDAD, PERO A CONTINUACIÓN LA MEJOR MANERA DE APROXIMARLA
	*Para empleados USO EL VALOR MEDIO DE CADA RANGO DE ANIOS, LA ESTOY CREANDO TRUNCADA,
	* HAY QUE REVISAR ESTO!!!!
	* Yanira: no estoy de acuerdo con esto.  Posiblemente sea mejor convertir a discretas las 
	* antiguedades de independientes y empleados domesticos. No obstante lo dejo asi hasta consultar
	gen antiguedad3=0 if pp07a==1
	replace antiguedad3=0.17 if pp07a==2
	*[1-3 meses---2/12=0.17]*
	replace antiguedad3=0.33 if pp07a==3
	*[3-6 meses---4/12=0.33]*
	replace antiguedad3=0.75 if pp07a==4
	*[6m- 1a---9/12=0.75]*
	replace antiguedad3=3 if pp07a==5
	*[1-5---3=0.33]*
	replace antiguedad3=5 if pp07a==6
	*[mas de 5]*
	replace antiguedad3=. if pp07a==0 | pp07a==9
	
	
	*Para trabajadores Independientes
	gen antiguedad4     = 0    if pp05h==1
	replace antiguedad4 = 2/12 if pp05h==2
	replace antiguedad4 = 4/12 if pp05h==3
	replace antiguedad4 = 9/12 if pp05h==4
	replace antiguedad4 = 3    if pp05h==5
	replace antiguedad4 = 5    if pp05h==6
	replace antiguedad4 = .    if pp05h==0 | pp05h==9
	
	*Agregando
	gen antiguedad_ci=	antiguedad1 if antiguedad1!=.
	replace antiguedad_ci= antiguedad2 if antiguedad2!=.
	replace antiguedad_ci= antiguedad3 if antiguedad3!=.
	replace antiguedad_ci= antiguedad4 if antiguedad4!=.
	label var antiguedad_ci "antiguedad laboral (anios) - aproximacion"	
*Note: A los empleados e independientes se les esta dejando un máximo de 5 años de antiguedad.
	


**************************
***VARIABLES DE INGRESO***
**************************
*ipcf: Monto de ingreso per cápita familiar
destring ipcf, dpcomma replace 
*Se convierte a número la variable ipcf en númerica. Se usa la opción dpcomma, pues la variable usa coma decimal.

***********
*ylmpri_ci: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia).*
***********
*p21: Monto de ingreso de la ocupación principal
gen ylmpri_ci=.
replace ylmpri_ci=p21 if emp_ci==1 //Se iguala a la variable
replace ylmpri_ci=0 if p21<0 & emp_ci==1 //Se reemplazan por ceros los ingresos negativos
replace ylmpri_ci=. if p21==. | p21==-9 //Se reemplazan los missings
		
***************
***ylmsec_ci: Ingreso laboral monetario de actividad secundaria: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria. **
***************
gen ylmsec_ci=.	//No hay una variable que aisle el ingreso laboral monetario de la actividad secundaria. Existe la variable tot_p12: Monto de ingreso de otras ocupaciones (incluye ocupación secundaria, ocupación previa a la semana de referencia, deudas/retroactivos por ocupaciones anteriores al mes de referencia, etc. Por tanto, la variable queda como missing

*************
*ylmotros_ci: Ingreso laboral monetario de otras actividades: Variable continua que indica el monto mensual de ingresos monetarios provenientes de actividades distintas de la principal y secundaria. Incluye ingresos percibidos por desocupados o inactivos derivados de trabajos previos al cese. *
*************
gen ylmotros_ci=. //Por lo explicado en la variable "ylm_sec", esta variable queda como missing.

********
*ylm_ci:Ingreso laboral monetario total: Variable continua que indica el monto mensual total de ingresos laborales monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylmpri_ci, ymsec_ci e ylnmotros_ci.*
********
*Codigo extraído del manual	
egen ylm_ci=rsum(ylmpri_ci ylmotros_ci), missing
replace ylm_ci=. if ylmpri_ci==. &  ylmotros_ci==. 	 

************
*ylnmpri_ci: Ingreso laboral no monetario de actividad principal: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad principal de cada miembro del hogar. *
************
/*En esta encuesta se pregunta hay preguntas sobre si se recibió un pago monetario, como por ejemplo con la variable pp07f1 - ¿En este trabajo le dan... (no excluyentes)
 ...de comer gratis en el lugar de trabajo?
			1 = Sí
			2 = No
No obstante, no hay una variable que estime el valor de dichos ingresos no monetarios. 
*/		
gen ylnmpri_ci=.

****************
***ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar.***
****************
gen ylnmsec_ci=. //No hay una variable referente a ingresos de actividad secundaria, aparte de la variable tot_p12, que hace referencia a un ingreso monetario que se compone de los ingresos de la actividad secundaria + otras actividades.

******************
***ylnmotros_ci: Ingresos laboral no monetario de otras actividades: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de actividades distintas de la principal y/o secundaria de cada miembro del hogar.***
******************
gen ylnmotros_ci=. //No hay variables que estimen el valor de pagos no monetarios recibidos por los trabajadores.

*********
*ylnm_ci: Ingreso laboral no monetario: Variable continua que indica el monto mensual total de ingresos laborales no monetarios provenientes de todas las actividades.*
*********
gen ylnm_ci=. //No hay variables que estimen el valor de pagos no monetarios recibidos por los trabajadores.
label var ylnm_ci "Ingreso laboral NO monetario total"  

*********
*ynlm_ci:  Ingreso no laboral monetario público del individuo. Variable continua que indica el monto mensual del ingreso no laboral MONETARIO proveniente de otras fuentes no laborales. *
*********
*t_vi: Monto total de ingresos no laborales
gen ynlm_ci= t_vi
replace ynlm_ci=0 if ynlm_ci<0 //Se reemplazan los negativos por cero
replace ynlm_ci=. if t_vi==. | t_vi==-9 //Missings

**********
*ynlnm_ci: Ingreso no laboral no monetario. Variable continua que indica el monto mensual del ingreso no laboral no monetario (otras fuentes). En esta categoría se encuentran otros beneficios y transferencias no monetarias como las donaciones en alimentos, útiles escolares, becas, entre otros.*
**********
gen ynlnm_ci=. //No hay variables de ingresos no monetarios

**********
*ytot_ci: Ingreso mensual total del individuo que incluye las variables ylm_ci ylnm_ci ynlm_ci ynlnm_ci. *
**********
*Código extraído del manual
egen double ytot_ci= rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

********
*ylm_ch: Ingreso laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso laboral monetario del hogar, ignora las `No respuesta'.*
********
*Código extraído del manual
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing

*************
*ylnm_ch: Ingreso laboral no monetario del hogar. Variable continua que indica el monto del ingreso laboral no monetario del hogar.*
*************
gen ylnm_ch=. //No hay variables de ingresos no monetarios

**********
*ynlnm_ch: Ingreso no laboral no monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral no monetario del hogar (otras fuentes).*
**********
gen double ynlnm_ch= . //No hay variables de ingresos no monetarios

*********
*ynlm_ch: Ingreso no laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral monetario del hogar (otras fuentes). Es la suma de ynlm_publico_ch y ynlm_privado_ch.*
*********
*Código extraído del manual 
by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing

**********
*ytot_ch: Ingreso mensual total del hogar *
**********
*itf: Monto del ingreso total familiar en el mes de referencia
gen ytot_ch=itf
replace ytot_ch=. if itf==-9 //Missings
*Se prefiere este ajuste al codigo del manual:
*egen double ytot_ch_b= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi  

*************
*ylmhopri_ci: Variable continua que indica el monto del salario horario monetario de la actividad principal.*
*************
*Código extraído del manual
gen ylmhopri_ci=ylmpri_ci/(4.3*horaspri_ci)
replace ylmhopri_ci=. if ylmhopri_ci<=0

**********
*ylmho_ci: Variable continua que indica el monto del salario horario monetario de todas las actividades.*
**********
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
replace ylmho_ci = . if ylmho_ci <= 0

*************
*nrylmpri_ci: No respuesta a nivel individuo. Indica la no respuesta ingreso de la actividad principal. Para construir esta variable, se tiene en cuenta que no reporte ingresos laborales (ylmpri_ci==. ) y además la persona reporte estar ocupado (emp_ci==1)*
*************
*	1	Indica que tiene empleo, pero no reporta el ingreso 
*	0	Caso contrario

gen byte nrylmpri_ci = .
replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1 //Tiene empleo y no reporta ingreso 
replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1 //Tiene empleo y reporta ingreso

*************
*nrylmpri_ch: No respuesta a nivel hogar. Hogares con algún miembro que no respondió por ingresos*
*************
*	1	Indica que tiene empleo, pero no reporta el ingreso 
*	0	De lo contrario
*Código extraído del manual
by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.

************
*remesas_ci: Variable continua que indica el monto mensual por remesas reportadas por el individuo en moneda local corriente. *
************
gen remesas_ci=. //No hay variable de remesas

************
*remesas_ch: Variable continua que indica el monto mensual por remesas del hogar. Esta variable se genera a partir de la variable remesas_ci.*
************
gen remesas_ch=. //No hay variable de remesas

*********
*ypen_ci: Ingreso por pensión contributiva: Variable continua que indica el monto mensual en moneda local corriente efectivamente recibido por el individuo por pensiones contributivas en sus distintas modalidades (jubilación, vejez, pensión, etc).*
*********
*v2_m : Monto del ingreso por jubilación o pensión
*v21_m: Monto del ingreso por aguinaldo

gen aguinpen=v21_m/12 if v2_m>0 & v2_m!=. //Se guardan los ingresos por aguinaldos     

egen ypen_ci=rsum(v2_m aguinpen), missing //Se suman los ingresos de aguinaldo + los de jubilación
replace ypen_ci=0 if ypen_ci<0 //Se cambian los negativos por ceros
replace ypen_ci=. if v21_m==. & aguinpen==. //Missings
label var ypen_ci "Valor de la pension contributiva"
	
************
*ypensub_ci: Ingreso por pensión no contributiva: Variable continua que indica el monto mensual en moneda local corriente recibido por la persona por pensiones no contributivas (adultos mayores). *
************
gen byte ypensub_ci=. //No hay variable que se refiera a una pensión NO contributiva 
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"	
