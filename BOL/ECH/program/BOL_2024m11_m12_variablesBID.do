* (Versión Stata 19)
clear
set more off
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.`'
 *________________________________________________________________________________________________________________*
 

global ruta = "${surveysFolder}"

local PAIS BOL
local ENCUESTA ECH
local ANO "2024"
local ronda m11_m12

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close
log using "`log_file'", replace

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Bolivia
Encuesta: ECH
Round: m11
Autores: 
Version: 27/02/2026
Mayte Ysique (LMK/SCL) - Email: maytes@iadb.org, 27 de febrero de 2026
	
							SCL/GDI - IADB							
***************************************************************************
***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************
*/

use `base_in', clear

**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	********************
	*** region_BID_c ****
	********************
	gen byte region_BID_c=3
	
	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	********************
	*** region_c ****
	********************
	gen byte region_c = depto
	label define region_c ///
			1"Chuquisaca"         ///     
			2"La Paz"             ///
			3"Cochabamba"         ///
			4"Oruro"              ///
			5"Potosí"             ///
			6"Tarija"             ///
			7"Santa Cruz"         ///
			8"Beni"               ///
			9"Pando" 
			
	label value region_c region_c
	label var region_c "division politica, estados"
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c="BOL"
	label variable pais_c "Pais"
	
	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=11	
	label variable mes_c "Mes de la encuesta"

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c=(area == 1)
	label variable zona_c "Zona del país"
	label define zona_c 0 "Rural" 1 "Urbana"
	label value zona_c zona_c
	
	*********
	*estrato*
	*********
	gen estrato_ci=estrato
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=upm
	
	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch=group(folio)
	tostring idh_ch, replace
	replace idh_ch= substr("00000" + idh_ch, -5, 5)
	label variable idh_ch "ID del hogar"

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(idh_ch nro)
	tostring idp_ci, replace format ("%20.0f") 

	* Regla de consistencia del manual: la llave hogar-persona no debe duplicarse
	duplicates report idh_ch idp_ci
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=factor
	label variable factor_ci "Factor de expansion del individuo"

	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=factor_ci
	label variable factor_ch "Factor de expansion del hogar"
	
****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*************
	***sexo_ci***
	*************
	gen byte sexo_ci = s01a_02
	label var sexo_ci "Sexo del individuo" 
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci

	*************
	***edad_ci***
	*************
	gen edad_ci = s01a_03
	label variable edad_ci "Edad del individuo"

	*****************
	***relacion_ci***
	*****************
	gen relacion_ci = .
	replace relacion_ci = 1 if s01a_05 == 1
	replace relacion_ci = 2 if s01a_05 == 2
	replace relacion_ci = 3 if inlist(s01a_05,3,4) 
	replace relacion_ci = 4 if inrange(s01a_05, 5, 12)
	replace relacion_ci = 5 if inlist(s01a_05, 13)
	replace relacion_ci = 6 if s01a_05 == 14

	label variable relacion_ci "Relación con el jefe del hogar"

	label define relacion_ci ///
		1 "Jefe/a" ///
		2 "Esposo/a" ///
		3 "Hijo/a" ///
		4 "Otros parientes" ///
		5 "Otros no parientes" ///
		6 "Empleado/a doméstico/a"

	label value relacion_ci relacion_ci


	*************
	*miembros_ci*
	*************
	gen byte miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*****************
	***civil_ci***
	*****************
	gen civil_ci = .
	replace civil_ci = 1 if s01a_10 == 1
	replace civil_ci = 2 if inlist(s01a_10, 2, 3)
	replace civil_ci = 3 if inlist(s01a_10, 4, 5)
	replace civil_ci = 4 if s01a_10 == 6

	label variable civil_ci "Estado civil"

	label define civil_ci ///
		1 "Soltero" ///
		2 "Unión formal o informal" ///
		3 "Divorciado o separado" ///
		4 "Viudo", add

	label value civil_ci civil_ci

	tab civil_ci, m

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

	label variable clasehog_ch "Tipo de hogar"
	label define clasehog_ch ///
		1 "Unipersonal" ///
		2 "Nuclear" ///
		3 "Ampliado" ///
		4 "Compuesto" ///
		5 "Corresidente"
	label value clasehog_ch clasehog_ch
	
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

	******************************
	***DIVERSIDAD ÉTNICO-RACIAL***
	******************************
		
	***************
	****afro_ci****
	***************
	gen afro_ci = .
	replace afro_ci = 1 if s01a_09npioc == 1
	replace afro_ci = 0 if inrange(s01a_09npioc,2,993) | s01a_09 == 2
	
	label variable afro_ci "se autoidentifican como negras, afrodescendientes o variaciones de estas identidades"

	***************
	****ind_ci*****
	***************
	gen byte ind_ci = .
	replace ind_ci = 1 if inrange(s01a_09npioc,2,993)
	replace ind_ci = 0 if s01a_09npioc == 1 | s01a_09 == 2
	label variable ind_ci "se autoidentifican como indígena o variaciones de estas identidades"

	******************
	***noafroind_ci***
	******************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci == 0 & ind_ci == 0
	replace noafroind_ci = 0 if afro_ci == 1 | ind_ci == 1
	label variable noafroind_ci "No se autoidentifican como indígena, negro, afrodescendiente o variaciones de estas identidades"

	****************
	****afro_ch*****
	****************
	gen byte afro_jefe = afro_ci if relacion_ci == 1
	egen byte afro_ch = min(afro_jefe), by(idh_ch)
	drop afro_jefe
	label variable afro_ch "Jefe del hogar se autoidentifica como negro, afrodescendiento o variaciones"

	****************
	****afro_ch*****
	****************
	gen byte ind_jefe = ind_ci if relacion_ci == 1
	egen byte ind_ch = min(ind_jefe), by(idh_ch)
	drop ind_jefe
	label variable ind_ch "Jefe del hogar se autoidentifica como indígena o variaciones"

	******************
	***noafroind_ch***
	******************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci == 1
	egen byte noafroind_ch = min(noafroind_jefe), by(idh_ch)
	drop noafroind_jefe
	label variable noafroind_ch "Jefe del hogar no se autoidentifica como indígena, negro, afrodescendiente o variaciones"

	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c = 2012

	***************
	***afroind_ci***
	***************
	gen afroind_ci = . 
	replace afroind_ci = 1 if ind_ci == 1 
	replace afroind_ci = 2 if afro_ci == 1
	replace afroind_ci = 3 if noafroind_ci == 1

	***************
	***afroind_ch***
	***************
	gen byte afroind_jefe = afroind_ci if relacion_ci == 1
	egen byte afroind_ch = min(afroind_jefe), by(idh_ch)
	drop afroind_jefe


	*******************************
	***SITUACIÓN DE DISCAPACIDAD***
	*******************************

	********
	*dis_ci*
	********
	gen byte dis_ci = .
	replace dis_ci=1 if inrange(s02a_04a,2,4) | inrange(s02a_04b,2,4) | inrange( s02a_04c,2,4) | inrange(s02a_04d,2,4)
	replace dis_ci=0 if inrange(s02a_04a,1,1) & inrange(s02a_04b,1,1) & inrange( s02a_04c,1,1) & inrange(s02a_04d,1,1)
	
	**********
	*disWG_ci*
	**********
	gen byte disWG_ci = .
	replace disWG_ci=1 if inrange(s02a_04a,3,4) | inrange(s02a_04b,3,4) | inrange( s02a_04c,3,4) | inrange(s02a_04d,3,4)
	replace disWG_ci=0 if inrange(s02a_04a,1,2) & inrange(s02a_04b,1,2) & inrange( s02a_04c,1,2) & inrange(s02a_04d,1,2)
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte BOL_dis_ci = dis_ci


	************************************
	*** VARIABLES DEL MERCADO LABORAL***
	************************************
	
	****************
	****condocup_ci*
	****************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if s04a_01==1 | inrange(s04a_02,1,8) | inrange(s04a_03,1,9) 
	replace condocup_ci = 2 if s04a_04 == 1 &  s04a_05 == 1
	replace condocup_ci = 3 if condocup_ci==. & (s04a_04 == 2 |  (s04a_04==1 & s04a_05 == 2))
	replace condocup_ci = 4 if edad_ci < 7

	label define condocup_ci ///
		1 "Ocupado" ///
		2 "Desocupado" ///
		3 "Inactivo" ///
		4 "Menor que 7"

	label value condocup_ci condocup_ci

	*******************
	***categoinac_ci***
	*******************
	gen categoinac_ci = .
	replace categoinac_ci = 1 if s04a_06 == 2 & condocup_ci == 3  // Jubilados o pensionados
	replace categoinac_ci = 2 if s04a_06 == 1 & condocup_ci == 3  // Estudiantes
	replace categoinac_ci = 3 if s04a_06 == 4 & condocup_ci == 3  // Quehaceres domésticos
	replace categoinac_ci = 4 if inlist(s04a_06,3,5,6) & condocup_ci == 3  // Otros

	label variable categoinac_ci "Categoría de inactividad"

	label define categoinac_ci ///
		1 "Jubilados o pensionados" ///
		2 "Estudiantes" ///
		3 "Quehaceres domésticos" ///
		4 "Otros"

	label value categoinac_ci categoinac_ci

	************
	***emp_ci***
	************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de 	referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	*************
	*cesante_ci* 
	*************
	gen cesante_ci = .
	replace cesante_ci = 1 if condocup_ci == 2 & s04a_08 == 1
	replace cesante_ci = 0 if condocup_ci == 2 & s04a_08 == 2
	label var cesante_ci "Desocupado - definicion oficial del pais"	

	****************
	***desemp_ci***
	****************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci
	
	label var desemp_ci "Desempleado que buscó empleo en el periodo de referencia"

	***************
	***subemp_ci***
	***************    
	* Se considera subempleo visible: quiere trabajar mas horas y esta disponible. 
	gen subemp_ci=.

	****************
	***durades_ci***
	****************
	gen durades_ci = .
	label variable durades_ci "Duracion del desempleo en meses"

	*************
	***pea_ci***
	*************
	gen pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2) 
	replace pea_ci = 0 if inlist(condocup_ci,3,4)
	
	label variable pea_ci "Población Económicamente Activa"

	*****************
	***nempleos_ci***
	*****************
	gen nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1
	replace nempleos_ci = 2 if emp_ci == 1 & s04e_25 == 1

	label variable nempleos_ci "Número de empleos"

	label define nempleos_ci ///
		1 "Un empleo" ///
		2 "Más de un empleo"

	label value nempleos_ci nempleos_ci

	*******************
	***antiguedad_ci***
	*******************
	gen antiguedad_ci = .

	replace antiguedad_ci = s04b_11ba / 52.14 if s04b_11bb == 2 & emp_ci == 1  // Semanas
	replace antiguedad_ci = s04b_11ba / 12    if s04b_11bb == 4 & emp_ci == 1  // Meses
	replace antiguedad_ci = s04b_11ba         if s04b_11bb == 8 & emp_ci == 1  // Años

	label variable antiguedad_ci "Antigüedad en la actividad actual en años"

	*****************
	***desalent_ci***
	*****************
	***** El código mantiene como población de referencia  a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (s04a_05 == 2 & s04a_07 == 3 & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	*****************
	***horaspri_ci***
	*****************
	gen horaspri_ci = phrs
	

	*****************
	***horastot_ci***
	*****************
	gen horastot_ci = tothrs

	*******************
	***tiempoparc_ci***
	*******************
	gen tiempoparc_ci = .


	******************
	***categopri_ci***
	******************
	destring s04b_12 s04e_29, ignore("NA") replace

	gen categopri_ci = .

	replace categopri_ci = 1 if inlist(s04b_12, 4)              // Patrón
	replace categopri_ci = 2 if s04b_12 == 3                    // Cuenta propia
	replace categopri_ci = 3 if inlist(s04b_12, 1, 2)           // Empleado
	replace categopri_ci = 4 if inlist(s04b_12, 6, 7)           // No remunerado
	replace categopri_ci = 0 if s04b_12 == 8 | s04b_12==5       // Otro

	replace categopri_ci = . if inlist(emp_ci,.,0)  // Solo personas ocupadas

	label define categopri_ci ///
		0 "Otro" ///
		1 "Patrón" ///
		2 "Cuenta propia" ///
		3 "Empleado" ///
		4 "No remunerado"

	label value categopri_ci categopri_ci
	label variable categopri_ci "Categoría ocupacional - trabajo principal"

	******************
	***categosec_ci***
	******************
	gen categosec_ci = .

	replace categosec_ci = 1 if inlist(s04e_27, 4)             // Patrón
	replace categosec_ci = 2 if s04e_27 == 3                   // Cuenta propia
	replace categosec_ci = 3 if inlist(s04e_27, 1, 2)          // Empleado
	replace categosec_ci = 4 if inlist(s04b_12, 6, 7)          // No remunerado

	label define categosec_ci ///
		1 "Patrón" ///
		2 "Cuenta propia" ///
		3 "Empleado" ///
		4 "No remunerado"

	label value categosec_ci categosec_ci
	label variable categosec_ci "Categoría ocupacional - trabajo secundario"

	*************
	***rama_ci***
	*************
	/*
	caeb_op:
	0 Agricultura,Ganadería,Caza,Pesca y Silv
	1 Explotación de Minas y Canteras
	2 Industria Manufacturera
	3 Suministro de electricidad,gas,vapor y
	4 Suministro de agua, evac. de aguas res,
	5 Construcción
	6 Venta por mayor y menor,reparación de a
	7 Transporte y Almacenamiento
	8 Actividades de alojamiento y servicio d
	9 Informaciones y Comunicaciones
	10 Intermediación Financiera y Seguros
	11 Actividades inmobiliarias
	12 Servicios Profesionales y Técnicos
	13 Actividades de Servicios Administrativo
	14 Adm. Pública, Defensa y Seguridad Socia
	15 Servicios de Educación
	16 Servicios de Salud y Asistencia Social
	17 Actividades artisticas,entretenimiento
	18 Otras actividades de servicios
	19 Actividades de Hogares Privados
	20 Servicio de Organismos Extraterritorial
	99 NS/NR
	*/ 

	destring caeb_op, ignore("NA") replace

	gen rama_ci = .

	replace rama_ci = 1 if caeb_op == 0 & emp_ci == 1                                             // Agricultura, caza, silvicultura y pesca
	replace rama_ci = 2 if caeb_op == 1 & emp_ci == 1                                             // Explotación de minas y canteras
	replace rama_ci = 3 if caeb_op == 2 & emp_ci == 1                                             // Industrias manufactureras
	replace rama_ci = 4 if inlist(caeb_op, 3, 4) & emp_ci == 1                                    // Electricidad, gas y agua
	replace rama_ci = 5 if caeb_op == 5 & emp_ci == 1                                             // Construcción
	replace rama_ci = 6 if inrange(caeb_op, 6, 8) & emp_ci == 1                                   // Comercio, restaurantes y hoteles
	replace rama_ci = 7 if caeb_op == 7 & emp_ci == 1                                             // Transporte y almacenamiento
	replace rama_ci = 8 if inrange(caeb_op, 10, 11) & emp_ci == 1                                 // Establecimientos financieros, seguros e inmuebles
	replace rama_ci = 9 if (caeb_op == 9 | inrange(caeb_op, 12, 20)) & emp_ci == 1                // Servicios sociales y comunales

	label variable rama_ci "Rama de actividad de la ocupación principal"

	label define rama_ci ///
		1 "Agricultura, caza, silvicultura y pesca" ///
		2 "Explotación de minas y canteras" ///
		3 "Industrias manufactureras" ///
		4 "Electricidad, gas y agua" ///
		5 "Construcción" ///
		6 "Comercio, restaurantes y hoteles" ///
		7 "Transporte y almacenamiento" ///
		8 "Establecimientos financieros, seguros e inmuebles" ///
		9 "Servicios sociales y comunales"

		label value rama_ci rama_ci

	*****************
	***spublico_ci***
	*****************
	gen spublico_ci = .

	replace spublico_ci = 1 if inlist(s04b_13, 1, 2)                     // Sector público
	replace spublico_ci = 0 if inrange(s04b_13, 3, 6)                    // Sector privado u otros

	replace spublico_ci = . if emp_ci != 1                               // Solo personas ocupadas

	label variable spublico_ci "Personas que trabajan en el sector público"

	*************
	*tamemp_ci
	*************
	gen tamemp_ci = .

	replace tamemp_ci = 1 if inrange(s04b_14, 1, 5)                // Pequeña empresa
	replace tamemp_ci = 2 if inrange(s04b_14, 6, 49)               // Mediana empresa
	replace tamemp_ci = 3 if s04b_14 > 49 & !missing(s04b_14)      // Grande empresa

	label variable tamemp_ci "# empleados en la empresa según rangos"

	label define tamemp_ci ///
		1 "Pequeña" ///
		2 "Mediana" ///
		3 "Grande"

	label value tamemp_ci tamemp_ci

	****************
	*cotizando_ci***
	****************
	gen cotizando_ci = .
	label var cotizando_ci "Cotizante a la Seguridad Social"

	****************
	***instcot_ci***
	****************
	gen instcot_ci = . 

	****************
	*afiliado_ci****
	****************
	destring s04f_35, ignore("NA") replace
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if (s04f_35 == 1 & emp_ci==1)
	replace afiliado_ci = 0 if (afiliado_ci != 1 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci

	*******************
	*****formal_ci*****
	*******************
	gen formal_ci = (cotizando_ci == 1 | afiliado_ci == 1)

	label var formal_ci "1=afiliado o cotizante / PEA"

	*****************
	*tipocontrato_ci*
	*****************
	gen tipocontrato_ci = .
	label var tipocontrato_ci "Tipo de contrato segun su duracion"

	**************
	***ocupa_ci***
	**************

	tostring s04b_09a_cod, replace


	gen new_cod = real(substr(s04b_09a_cod, 1, 2))

	gen ocupa_ci = .

	* 1. Profesional y técnico
	replace ocupa_ci = 1 if inlist(new_cod, 2, 21, 22, 23, 24, 25, 26, 27) & emp_ci == 1

	* 2. Director o funcionario superior
	replace ocupa_ci = 2 if inlist(new_cod, 1, 11, 12, 13, 14) & emp_ci == 1

	* 3. Administrativo y nivel intermedio
	replace ocupa_ci = 3 if inlist(new_cod, 31, 32, 33, 34, 35, 41, 42, 43, 44) & emp_ci == 1

	* 4. Comerciantes y vendedores
	replace ocupa_ci = 4 if inlist(new_cod, 52, 95) & emp_ci == 1

	* 5. En servicios
	replace ocupa_ci = 5 if inlist(new_cod, 51, 53, 54, 91, 94) & emp_ci == 1

	* 6. Trabajadores agrícolas
	replace ocupa_ci = 6 if inlist(new_cod, 61, 62, 92) & emp_ci == 1

	* 7. Obreros no agrícolas, conductores, transporte
	replace ocupa_ci = 7 if inlist(new_cod, 71, 72, 73, 74, 75, 81, 82, 83, 93, 96) & emp_ci == 1

	* 8. FFAA
	replace ocupa_ci = 8 if inlist(new_cod, 0) & emp_ci == 1

	label define ocupa_ci ///
		1 "Profesional y técnico" ///
		2 "Director o funcionario sup" ///
		3 "Administrativo y nivel intermedio" ///
		4 "Comerciantes y vendedores" ///
		5 "En servicios" ///
		6 "Trabajadores agrícolas" ///
		7 "Obreros no agrícolas, conductores de maq y SS de transporte" ///
		8 "FFAA" ///
		9 "Otras"

	label value ocupa_ci ocupa_ci
	label variable ocupa_ci "Ocupación laboral"

	*************
	**pension_ci*
	*************
	egen aux_p = rsum(s05a_01a s05a_01b s05a_01c s05a_01d), missing

	gen pension_ci = 1 if aux_p > 0 & aux_p! = .
	recode pension_ci . = 0 
	label var pension_ci "1=Recibe pension contributiva"

	***************
	*pensionsub_ci*
	***************
	gen pensionsub_ci = 0
	replace pensionsub_ci = 1 if ///
		s02b_12a1 == 1 | ///  Bono Juana Azurduy por controles
		s02b_12b  == 1 | /// Bono Juana Azurduy por parto
		s02d_17   == 1 | /// Bono Juana Azurduy por control
		s04c_20b  == 1 | /// Bono de natalidad
		s03a_08   == 1   /// Bono Juancito Pinto

	label variable pensionsub_ci "1 = recibe pensión subsidiada / no contributiva"

	****************
	*tipopen_ci*****
	****************
	destring s05a_01*, i("NA") replace

	gen tipopen_ci = .

	replace tipopen_ci = 1    if s05a_01a > 0 & s05a_01a != .
	replace tipopen_ci = 2    if s05a_01d > 0 & s05a_01d != .
	replace tipopen_ci = 3    if s05a_01b > 0 & s05a_01b != .
	replace tipopen_ci = 4    if s05a_01c > 0 & s05a_01c != .
	replace tipopen_ci = 12   if s05a_01a > 0 & s05a_01d > 0 & s05a_01a != . & s05a_01d != .
	replace tipopen_ci = 13   if s05a_01a > 0 & s05a_01b > 0 & s05a_01a != . & s05a_01b != .
	replace tipopen_ci = 23   if s05a_01d > 0 & s05a_01b > 0 & s05a_01d != . & s05a_01b != .
	replace tipopen_ci = 123  if s05a_01a > 0 & s05a_01b > 0 & s05a_01c > 0 & s05a_01a != . & s05a_01b != . & s05a_01c != .

	label define tipopen_ci ///
		1 "Jubilacion" ///
		2 "Viudez/orfandad" ///
		3 "Benemerito" ///
		4 "Invalidez" ///
		12 "Jub y viudez" ///
		13 "Jub y benem" ///
		23 "Viudez y benem" ///
		123 "Todas"

	label value tipopen_ci tipopen_ci
	label variable tipopen_ci "Tipo de pension - variable original de cada pais"

	****************
	***instpen_ci***
	****************
	gen instpen_ci = .
	label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 




	***************************
	*** VARIABLES DE INGRESO***
	***************************

	*******************
	* salario líquido *
	*******************
	gen yliquido = .
	replace yliquido= s04c_17a*30	if s04c_17b==1
	replace yliquido= s04c_17a*4.3	if s04c_17b==2
	replace yliquido= s04c_17a*2	if s04c_17b==3
	replace yliquido= s04c_17a		if s04c_17b==4
	replace yliquido= s04c_17a/2	if s04c_17b==5
	replace yliquido= s04c_17a/3	if s04c_17b==6
	replace yliquido= s04c_17a/6	if s04c_17b==7
	replace yliquido= s04c_17a/12	if s04c_17b==8

	**************
	* comisiones *
	**************
	gen ycomisio = .
	replace ycomisio= s04c_19aa*30	if s04c_19ab==1
	replace ycomisio= s04c_19aa*4.3	if s04c_19ab==2
	replace ycomisio= s04c_19aa*2	if s04c_19ab==3
	replace ycomisio= s04c_19aa		if s04c_19ab==4
	replace ycomisio= s04c_19aa/2	if s04c_19ab==5
	replace ycomisio= s04c_19aa/3	if s04c_19ab==6
	replace ycomisio= s04c_19aa/6 	if s04c_19ab==7
	replace ycomisio= s04c_19aa/12 	if s04c_19ab==8
	replace ycomisio= . if s04c_19aa==999999

	****************
	* horas extras *
	****************
	gen yhrsextr= .
	replace yhrsextr= s04c_19ba *30	    if s04c_19bb==1
	replace yhrsextr= s04c_19ba *4.3  	if s04c_19bb==2
	replace yhrsextr= s04c_19ba *2		if s04c_19bb==3
	replace yhrsextr= s04c_19ba 		if s04c_19bb==4
	replace yhrsextr= s04c_19ba /2		if s04c_19bb==5
	replace yhrsextr= s04c_19ba /3		if s04c_19bb==6
	replace yhrsextr= s04c_19ba /6	    if s04c_19bb==7
	replace yhrsextr= s04c_19ba /12	    if s04c_19bb==8

	*********
	* prima *
	*********

	* Pago por Bono o prima de producción

	gen yprima = .
	replace yprima = s04c_18a/12

	*************
	* aguinaldo *
	*************

	* Pago por Aguinaldo

	gen yaguina = .
	replace yaguina = s04c_18b/12


	*************
	* alimentos *
	*************
	gen yalimen = .
	replace yalimen= s04c_21a2 *30		if s04c_21a1 ==1 & s04c_21a==1
	replace yalimen= s04c_21a2 *4.3 	if s04c_21a1 ==2 & s04c_21a==1
	replace yalimen= s04c_21a2 *2		if s04c_21a1 ==3 & s04c_21a==1
	replace yalimen= s04c_21a2 		    if s04c_21a1 ==4 & s04c_21a==1
	replace yalimen= s04c_21a2 /2		if s04c_21a1 ==5 & s04c_21a==1
	replace yalimen= s04c_21a2 /3		if s04c_21a1 ==6 & s04c_21a==1
	replace yalimen= s04c_21a2 /6		if s04c_21a1 ==7 & s04c_21a==1
	replace yalimen= s04c_21a2 /12		if s04c_21a1 ==8 & s04c_21a==1

	**************
	* transporte *
	**************
	gen ytranspo = .
	replace ytranspo= s04c_21b2*30	    if s04c_21b1==1 & s04c_21b==1
	replace ytranspo= s04c_21b2*4.3	    if s04c_21b1==2 & s04c_21b==1
	replace ytranspo= s04c_21b2*2		if s04c_21b1==3 & s04c_21b==1
	replace ytranspo= s04c_21b2 	    if s04c_21b1==4 & s04c_21b==1
	replace ytranspo= s04c_21b2/2		if s04c_21b1==5 & s04c_21b==1
	replace ytranspo= s04c_21b2/3		if s04c_21b1==6 & s04c_21b==1
	replace ytranspo= s04c_21b2/6		if s04c_21b1==7 & s04c_21b==1
	replace ytranspo= s04c_21b2/12	    if s04c_21b1==8 & s04c_21b==1

	**************
	* vestimenta *
	**************

	gen yvesti = .
	replace yvesti= s04c_21c*30			if s04c_21c1==1 & s04c_21c==1
	replace yvesti= s04c_21c*4.3		if s04c_21c1==2 & s04c_21c==1
	replace yvesti= s04c_21c*2		    if s04c_21c1==3 & s04c_21c==1
	replace yvesti= s04c_21c			if s04c_21c1==4 & s04c_21c==1
	replace yvesti= s04c_21c/2		    if s04c_21c1==5 & s04c_21c==1
	replace yvesti= s04c_21c/3		    if s04c_21c1==6 & s04c_21c==1
	replace yvesti= s04c_21c/6		    if s04c_21c1==7 & s04c_21c==1
	replace yvesti= s04c_21c/12		    if s04c_21c1==8 & s04c_21c==1

	************
	* vivienda *
	************

	gen yvivien = .
	replace yvivien= s04c_21d2*30		if s04c_21d1==1 & s04c_21d==1
	replace yvivien= s04c_21d2*4.3	    if s04c_21d1==2 & s04c_21d==1
	replace yvivien= s04c_21d2*2		if s04c_21d1==3 & s04c_21d==1
	replace yvivien= s04c_21d2		    if s04c_21d1==4 & s04c_21d==1
	replace yvivien= s04c_21d2/2		if s04c_21d1==5 & s04c_21d==1
	replace yvivien= s04c_21d2/3		if s04c_21d1==6 & s04c_21d==1
	replace yvivien= s04c_21d2/6		if s04c_21d1==7 & s04c_21d==1
	replace yvivien= s04c_21d2/12		if s04c_21d1==8 & s04c_21d==1

	*************
	* otros *
	*************

	gen yotros = .
	replace yotros= s04c_21e2*30	if s04c_21e1==1 & s04c_21e==1
	replace yotros= s04c_21e2*4.3	if s04c_21e1==2 & s04c_21e==1
	replace yotros= s04c_21e2*2	    if s04c_21e1==3 & s04c_21e==1
	replace yotros= s04c_21e2		if s04c_21e1==4 & s04c_21e==1
	replace yotros= s04c_21e2/2	    if s04c_21e1==5 & s04c_21e==1
	replace yotros= s04c_21e2/3		if s04c_21e1==6 & s04c_21e==1
	replace yotros= s04c_21e2/6		if s04c_21e1==7 & s04c_21e==1
	replace yotros= s04c_21e2/12	if s04c_21e1==8 & s04c_21e==1

	**********************************
	* ingreso act. pr independientes *
	**********************************
	*Aquí se tiene en cuenta el monto de dinero que les queda a los independientes para el uso del hogar
	gen yactpri = .
	replace yactpri= s04d_24a*30	if s04d_24b==1
	replace yactpri= s04d_24a*4.3	if s04d_24b==2
	replace yactpri= s04d_24a*2		if s04d_24b==3
	replace yactpri= s04d_24a		if s04d_24b==4
	replace yactpri= s04d_24a/2		if s04d_24b==5
	replace yactpri= s04d_24a/3		if s04d_24b==6
	replace yactpri= s04d_24a/6		if s04d_24b==7
	replace yactpri= s04d_24a/12	if s04d_24b==8

	*********************
	* salario liquido 2 *
	*********************
	gen yliquido2 = .
	replace yliquido2= s04f_31a*30		if s04f_31b==1
	replace yliquido2= s04f_31a*4.3		if s04f_31b==2
	replace yliquido2= s04f_31a*2		if s04f_31b==3
	replace yliquido2= s04f_31a			if s04f_31b==4
	replace yliquido2= s04f_31a/2		if s04f_31b==5
	replace yliquido2= s04f_31a/3		if s04f_31b==6
	replace yliquido2= s04f_31a/6		if s04f_31b==7
	replace yliquido2= s04f_31a/12		if s04f_31b==8

	*****************
	* Horas extra 2 *
	*****************
	gen yhrsextr2 = .
	replace yhrsextr2 = s04f_32a1/12 if s04f_32a==1

	***************************************
	* alimentos, transporte y vestimenta2 *
	***************************************
	gen yalimen2 = .
	replace yalimen2=s04f_32b1/12	if s04f_32b==1

	**************
	* vivienda 2 *
	**************
	gen yvivien2= .
	replace yvivien2=s04f_32c1/12	if s04f_32c==1

	*************************
	******NO-LABORAL*********
	*************************
	destring s05a_* s05b_*, i("NA") replace

	*************
	* intereses *
	*************
	gen yinteres = .
	replace yinteres = s05a_02a	

	**************
	* alquileres *
	**************
	gen yalqui = .
	replace yalqui = s05a_02b	

	****************
	* otras rentas *
	****************
	gen yotren = .
	replace yotren = s05a_02c

	**************
	* jubilacion *
	**************
	gen yjubi = .
	replace yjubi = s05a_01a 

	**************
	* benemerito *
	**************
	gen ybene = .
	replace ybene = s05a_01b 

	*************
	* invalidez *
	*************
	gen yinvali = .
	replace yinvali = s05a_01c

	**********
	* viudez *
	**********
	gen yviudez = .
	replace yviudez = s05a_01d  


	************************
	* alquileres agricolas *
	************************
	gen yalqagri = .
	replace yalqagri =  s05a_03a/12		


	**************
	* dividendos *
	**************
	gen ydivi = .
	replace ydivi =  s05a_03b/12


	*************************
	* alquileres maquinaria *
	*************************
	gen yalqmaqui = .
	replace yalqmaqui = s05a_03c/12

	
	******************
	* indem. trabajo *
	******************
	gen yindtr = .
	replace yindtr =  s05a_04a/12


	******************
	* indem. seguros *
	******************
	gen yindseg = .
	replace yindseg = s05a_04b/12


	******************
	* renta dignidad *
	******************
	gen ybono = .
	replace ybono = s05a_01e0 

	******************
	* otros ingresos *
	******************
	gen yotring = .
	replace yotring = s05a_04d/12

	*******************
	* asist. familiar *
	*******************
	gen yasistfam = .
	replace yasistfam= s05b_05aa*4.3	if s05b_05ab==2
	replace yasistfam= s05b_05aa*2		if s05b_05ab==3
	replace yasistfam= s05b_05aa		if s05b_05ab==4
	replace yasistfam= s05b_05aa/2		if s05b_05ab==5
	replace yasistfam= s05b_05aa/3		if s05b_05ab==6
	replace yasistfam= s05b_05aa/6		if s05b_05ab==7
	replace yasistfam= s05b_05aa/12		if s05b_05ab==8

	*********************
	* Trans. monetarias *
	*********************
	gen ydinero = .
	replace ydinero = s05b_05ba*4.3		if s05b_05bb==2
	replace ydinero= s05b_05ba*2		if s05b_05bb==3
	replace ydinero= s05b_05ba	    	if s05b_05bb==4
	replace ydinero= s05b_05ba/2		if s05b_05bb==5
	replace ydinero= s05b_05ba/3		if s05b_05bb==6
	replace ydinero= s05b_05ba/6		if s05b_05bb==7
	replace ydinero= s05b_05ba/12		if s05b_05bb==8

	gen yalimento= .
	replace yalimento = s05b_05ca*4.3	    if s05b_05cb==2
	replace yalimento= s05b_05ca*2			if s05b_05cb==3
	replace yalimento= s05b_05ca	        if s05b_05cb==4
	replace yalimento= s05b_05ca/2			if s05b_05cb==5
	replace yalimento= s05b_05ca/3			if s05b_05cb==6
	replace yalimento= s05b_05ca/6			if s05b_05cb==7
	replace yalimento= s05b_05ca/12			if s05b_05cb==8


	gen yotro_bono= .
	replace yotro_bono= s05b_06ba	        if s05b_06bb==4
	replace yotro_bono= s05b_06ba/12		if s05b_06bb==8

	gen yotro_bono2= .
	replace yotro_bono2= s05b_06ca	    	if s05b_06cb==4
	replace yotro_bono2= s05b_06ca/12		if s05b_06cb==8

	egen ytransmon=rsum(ydinero yotro_bono), missing

	***********
	* remesas *
	***********
	/*
		MONEDA
	A. BOLIVIANOS 
	B. EUROS
	C. DÓLARES
	D. PESOS ARGENTINOS
	E. REALES
	F. PESOS CHILENOS
	G. OTRO

	https://www.bcb.gob.bo/?q=cotizaciones_tc
	SE uso la cotizacion del 31 de diciembre del 2024
	*/
	destring s05c_*, replace i("NA")
	gen s6_112= .
	replace s6_112 =  s05c_09a 			 if s05c_09b==1 /*bolivianos*/
	replace s6_112 =  s05c_09a*7.13372   if s05c_09b==2 /*euro*/
	replace s6_112 =  s05c_09a*6.86		 if s05c_09b==3 /*dolar*/
	replace s6_112 =  s05c_09a*0.00666   if s05c_09b==4 /*peso argentino*/
	replace s6_112 =  s05c_09a*1.10975   if s05c_09b==5 /*real*/
	replace s6_112 =  s05c_09a*0.00688	 if s05c_09b==6 /*peso chileno*/

	* se suman remesas monetarias y en especie
	egen rem = rsum(s05c_10 s6_112), m

	gen yremesas = .
	replace yremesas= rem*4.3		if s05c_08==2
	replace yremesas= rem*2		    if s05c_08==3
	replace yremesas= rem			if s05c_08==4
	replace yremesas= rem/2			if s05c_08==5
	replace yremesas= rem/3			if s05c_08==6
	replace yremesas= rem/6			if s05c_08==7
	replace yremesas= rem/12		if s05c_08==8

	***************
	***ylmpri_ci***
	***************
	egen ylmpri_ci = rsum(yliquido ycomisio yhrsextr yprima yaguina yactpri), missing

	replace ylmpri_ci = . if ///
		yliquido == . & ycomisio == . & yhrsextr == . & ///
		yprima == . & yaguina == . & yactpri == .

	replace ylmpri_ci = . if emp_ci != 1
	replace ylmpri_ci = 0 if categopri_ci == 4

	label variable ylmpri_ci "Ingreso laboral monetario actividad principal"


	******************
	*** ylnmpri_ci ***
	******************
	* Ingreso laboral no monetario de los dependientes
	egen ylnmprid = rsum(yalimen ytranspo yvesti yvivien yotros), missing
	replace ylnmprid = . if yalimen == . & ytranspo == . & yvesti == . & yvivien == . & yotros == .
	replace ylnmprid = 0 if categopri_ci == 4

	* Ingreso laboral no monetario de los independientes (autoconsumo)
	gen ylnmprii = .

	* Ingreso laboral no monetario total (actividad principal)
	egen ylnmpri_ci = rsum(ylnmprid ylnmprii), missing
	replace ylnmpri_ci = . if ylnmprid == . & ylnmprii == .
	replace ylnmpri_ci = . if emp_ci != 1

	label variable ylnmpri_ci "Ingreso laboral NO monetario actividad principal"

	***************
	***ylmsec_ci***
	***************
	egen ylmsec_ci = rsum(yliquido2 yhrsextr2), missing

	replace ylmsec_ci = . if emp_ci != 1 & yliquido2 == . & yhrsextr2 == .
	replace ylmsec_ci = 0 if categosec_ci == 4

	label variable ylmsec_ci "Ingreso laboral monetario segunda actividad"

	******************
	****ylnmsec_ci****
	******************
	egen ylnmsec_ci = rsum(yalimen2 yvivien2), missing

	replace ylnmsec_ci = . if yalimen2 == . & yvivien2 == .
	replace ylnmsec_ci = 0 if categosec_ci == 4
	replace ylnmsec_ci = . if emp_ci == 0

	label variable ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

	*****************
	***ylmotros_ci***
	*****************
	gen ylmotros_ci = .
	label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

	******************
	***ylnmotros_ci***
	******************
	gen ylnmotros_ci = .
	label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

	************
	***ylm_ci***
	************
	egen ylm_ci = rsum(ylmpri_ci ylmsec_ci), missing
	replace ylm_ci = . if ylmpri_ci == . & ylmsec_ci == .
	label var ylm_ci "Ingreso laboral monetario total"  

	*************
	***ylnm_ci***
	*************
	egen ylnm_ci = rsum(ylnmpri_ci ylnmsec_ci), missing
	replace ylnm_ci = . if ylnmpri_ci == . & ylnmsec_ci == .
	label var ylnm_ci "Ingreso laboral NO monetario total"  

	*************
	***ynlm_ci***
	*************
	egen ynlm_ci = rsum( ///
		yinteres yalqui yjubi ybene yinvali yviudez yotren yalqagri ydivi ///
		yalqmaqui yindtr yindseg ybono yotring yasistfam ytransmon yremesas ///
	), missing

		replace ynlm_ci = . if ///
			yinteres == . & yalqui == . & yjubi == . & ybene == . & yinvali == . & ///
			yviudez == . & yotren == . & yalqagri == . & ydivi == . & yalqmaqui == . & ///
			yindtr == . & yindseg == . & ybono == . & yotring == . & yasistfam == . & ///
			ytransmon == . & yremesas == .

		label variable ynlm_ci "Ingreso no laboral monetario"

		*******************
		***ynlm_publico_ci***
		*******************
		gen double ynlm_publico_ci = ybono
		replace ynlm_publico_ci = . if ybono == .
		label var ynlm_publico_ci "Ingreso no laboral monetario publico"

		*******************
		***ynlm_privado_ci***
		*******************
		gen double ynlm_privado_ci = ynlm_ci - ynlm_publico_ci if ynlm_ci < .
		replace ynlm_privado_ci = . if ynlm_ci == .
		label var ynlm_privado_ci "Ingreso no laboral monetario privado"

	**************
	***ynlnm_ci***
	**************
	*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
	egen ynlnm_ci = rsum(yalimento yotro_bono2), missing
	replace ynlnm_ci = . if yalimento == . & yotro_bono2 == .

	label variable ynlnm_ci "Ingreso no laboral no monetario"

		egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
		label var ytot_ci "Ingreso total del individuo"

	**************
	*** ylm_ch ***
	**************
	by idh_ch, sort: egen ylm_ch = sum(ylm_ci) if miembros_ci == 1, missing
	label var ylm_ch "Ingreso laboral monetario del hogar"

	***************
	*** ylnm_ch ***
	***************
	by idh_ch, sort: egen ylnm_ch = sum(ylnm_ci) if miembros_ci == 1, missing
	label var ylnm_ch "Ingreso laboral no monetario del hogar"

	****************
	*** ynlnm_ch ***
	****************
	*Modificación SGR Julio 2019: En esta encuesta se pregunta por transferencia en alimentos u otras especies.
	by idh_ch, sort: egen ynlnm_ch = sum(ynlnm_ci) if miembros_ci == 1, missing
	label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

	****************
	*** ynlm_ch ***
	****************
	by idh_ch, sort: egen ynlm_ch = sum(ynlm_ci) if miembros_ci == 1, missing

	***********************
	*** ynlm_publico_ch ***
	***********************
	by idh_ch, sort: egen ynlm_publico_ch = sum(ynlm_publico_ci) if miembros_ci == 1, missing

	***********************
	*** ynlm_privado_ch ***
	***********************
	by idh_ch, sort: egen ynlm_privado_ch = sum(ynlm_privado_ci) if miembros_ci == 1, missing

	**************
	*** ytot_ch ***
	**************
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), missing
	label var ytot_ch "Ingreso total del hogar"
 
	*****************
	***ylhopri_ci ***
	*****************
	gen ylmhopri_ci = ylmpri_ci / (horaspri_ci * 4.3)
	label var ylmhopri_ci "Salario monetario de la actividad principal" 

	***************
	***ylmho_ci ***
	****************
	gen ylmho_ci = ylm_ci / (horastot_ci * 4.3)
	label var ylmho_ci "Salario monetario de todas las actividades" 

	*******************
	*** nrylmpri_ci ***
	*******************
	gen nrylmpri_ci = (ylmpri_ci == . & emp_ci == 1)
	label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  

	*******************
	*** nrylmpri_ch ***
	*******************
	by idh_ch, sort: egen nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci == 1, missing
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .
	label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

	* Reglas generales del manual de armonizacion de ingresos
	foreach v of varlist ylmpri_ci ylmsec_ci ylmotros_ci ylm_ci ynlm_ci ynlm_publico_ci ynlm_privado_ci ytot_ci ylm_ch ynlm_ch ynlm_publico_ch ynlm_privado_ch ytot_ch {
		replace `v' = 0 if `v' < 0 & `v' != .
	}
	foreach v of varlist ylnmpri_ci ylnmsec_ci ylnmotros_ci ylnm_ci ynlnm_ci ylnm_ch ynlnm_ch {
		replace `v' = . if `v' < 0
	}

	****************
	*** ylmnr_ch ***
	****************
	by idh_ch, sort: egen ylmnr_ch = sum(ylm_ci) if miembros_ci == 1, missing
	replace ylmnr_ch = . if nrylmpri_ch == 1
	label var ylmnr_ch "Ingreso laboral monetario del hogar"

	*****************
	***remesas_ci***
	*****************
	gen remesas_ci = yremesas
	label var remesas_ci "Remesas mensuales reportadas por el individuo" 

	*******************
	*** remesas_ch ***
	*******************
	by idh_ch, sort: egen remesas_ch = sum(remesas_ci) if miembros_ci == 1, missing
	label var remesas_ch "Remesas mensuales del hogar" 

	*************
	**ypen_ci*
	*************
	*11/4/2015 MGD: no considerar ceros. En el SIMS se reemplazan los 0 en missings. 
	gen ypen_ci = aux_p 
	*recode ypen_ci .=0 
	label var ypen_ci "Valor de la pension contributiva"

	*****************
	**ypensub_ci*
	*****************
	gen  ypensub_ci = s05a_01e0 
	label var ypensub_ci "Valor de la pension subsidiada / no contributiva"


	****************************
	***VARIABLES DE EDUCACION***
	****************************

	****************
	****aedu_ci****
	***************

	gen aedu_ci = .

	* Ninguno o preescolar
	replace aedu_ci = 0 if s03a_02a == 11 | s03a_02a == 12 | s03a_02a == 13 

	*Primaria & Secundaria
	replace aedu_ci = s03a_02c if s03a_02a == 21 | s03a_02a == 31 | s03a_02a == 41 | s03a_02a == 51

	* Secundaria  sistema escolar antiguo 
	replace aedu_ci = s03a_02c + 5   if  s03a_02a == 22 // Intermedio
	replace aedu_ci = s03a_02c + 5 + 3 if    s03a_02a == 23 // Medio

	* Secundaria sistema escolar anterior
	replace aedu_ci = s03a_02c + 8     if (s03a_02a == 32) 

	* Secundaria sistema escolar actual 
	replace aedu_ci = s03a_02c + 6     if (s03a_02a == 42)

	* Educacion para adultos 
	replace aedu_ci = s03a_02c + 6     if (s03a_02a == 52) // 

	** La educación Alternativa para jóvenes y adultos no hace parte de la educación formal (es preparatiorio para ello)
	replace aedu_ci = . if (s03a_02a >= 61 & s03a_02a <= 65) // Missing y no 0

	* Superior
	replace aedu_ci = s03a_02c + 12     	if s03a_02c <= 5 & (s03a_02a == 71 | s03a_02a == 72 | s03a_02a == 73 | s03a_02a >=77) // Tecnica media, superior, licenciatura y otros cursos <--
	replace aedu_ci = s03a_02c + 12 + 5 	if s03a_02c <= 5 & (s03a_02a == 74 | s03a_02a == 75) // diplomado, maestria
	replace aedu_ci = s03a_02c + 12 + 5 + 2 if s03a_02c <= 5 & (s03a_02a == 76) // doctorado

	* Terminación nivel
	replace aedu_ci = 12+2   if (s03a_02a == 71 |s03a_02a == 77 |s03a_02a == 78 ) & s03a_02c == 8 //Terminó técnico medio, educ tecnica de adultos y otros cursos
	replace aedu_ci = 12+3   if (s03a_02a == 72) & s03a_02c == 8 //Terminó técnico superior
	replace aedu_ci = 12+5   if (s03a_02a == 73) & s03a_02c == 8 // Termino licenciatura
	replace aedu_ci = 12+5+1 if s03a_02a == 74 & s03a_02c == 8 //Terminó diplomado
	replace aedu_ci = 12+5+2 if s03a_02a == 75 & s03a_02c == 8 //Terminó maestria
	replace aedu_ci = 12+5+4 if s03a_02a == 76 & s03a_02c == 8 //Terminó doctorado

	***************
	***edupre_ci***
	***************
	gen byte edupre_ci = .
	label variable edupre_ci "Educacion preescolar"

	**************
	***eduui_ci***
	**************
	gen byte eduui_ci = 0 
	replace eduui_ci = 1 if (s03a_04==1 & inlist(s03a_06a,72,73)) | /// esta estudiando tecnico superior y licenciatura este año
							(inlist(s03a_02a,72,73) & s03a_04==2 & inrange(s03a_05,2,8))  //estudio tecnico superior y licenciatura anteriormente y dejo de estudiar
	replace eduui_ci = . if aedu_ci == .

	label variable eduui_ci "Superior incompleto"

	***************
	***eduuc_ci****
	***************
	gen byte eduuc_ci = 0
	replace eduuc_ci  = 1 if (inrange(s03a_02a,72,73) & s03a_04==2 & s03a_05==1) | /// Técnica superior, universitaria o posgrado completa
							 (inlist(s03a_02a,74,75,76)) | /// Posgrado aprobado (completo o incompleto)
							 (s03a_04 == 1 & inlist(s03a_06a,74,75,76)) // Actualmente estudiando posgrado
	replace eduuc_ci  = . if aedu_ci == .

	label variable eduuc_ci "Superior completo o posgrado"

	**************
	***eduac_ci***
	**************
	gen byte eduac_ci = .
	replace eduac_ci = 1 if inrange(s03a_02a, 73, 76) | (s03a_04==1 & inrange(s03a_06a, 73, 76)) // Superior universitario o posgrado
 	replace eduac_ci = 0 if inlist(s03a_02a, 72) | (s03a_04==1 & s03a_06a==72)  // Superior no universitario 

	label variable eduac_ci "Superior universitario vs superior no universitario"


	***************
	***asiste_ci***
	***************
	* Se usa matriculación como proxy de asistencia.
	gen asiste_ci = . 
	replace asiste_ci = 1 if s03a_04 == 1
	replace asiste_ci = 0 if s03a_04 == 2
	label variable asiste_ci "Asiste actualmente a la escuela"

	***************
	***edupub_ci***
	***************
	*Esta variable solo corresponde a las personas que estudian primaria o secundaria
	gen edupub_ci = . 
	replace edupub_ci = 1 if (s03a_07a == 1 & asiste_ci == 1)
	replace edupub_ci = 0 if (s03a_07a == 2)
	label var edupub_ci "Asiste a un centro de ensenanza público"

	***************
	***asispre_ci***
	***************
	gen asispre_ci = .

	**************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci = .

	**********************************
	**** VARIABLES DE LA VIVIENDA ****
	**********************************
		
	************
	***luz_ch***
	************
	gen luz_ch = . 
	replace luz_ch = 1 if (s06a_12 == 1)
	replace luz_ch = 0 if (s06a_12 == 2)
	label var luz_ch  "La principal fuente de iluminación es electricidad"

	****************
	***luzmide_ch***
	****************
	gen luzmide_ch = .
	label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

	****************
	***combust_ch***
	****************
	gen combust_ch = (s06a_15 == 3 | s06a_15 == 4 |  s06a_15 == 6)
	replace combust_ch = . if s06a_15 == .
	label var combust_ch "Principal combustible gas o electricidad" 

/* SEGUN EL MANUAL, ESTA EN CONSTRUCCION
*************
***piso_ch***
*************
gen piso_ch = 0 if s06a_06 == 1 
replace piso_ch = 1 if  s06a_06 >= 2 &  s06a_06 <= 7 
replace piso_ch = 2 if  s06a_06 == 8
label var piso_ch "Materiales de construcción del piso"  
label def piso_ch 0"Piso de tierra" 1"Materiales permanentes" 2 "Otros materiales"
label val piso_ch piso_ch

**************
***pared_ch***
**************
gen pared_ch = 0 if s06a_03 == 6
replace pared_ch = 1 if s06a_03 >= 1 & s06a_03 <= 5
replace pared_ch = 2 if s06a_03 == 7
label var pared_ch "Materiales de construcción de las paredes"
label def pared_ch 0"No permanentes" 1"Permanentes" 2 "Otros materiales"
label val pared_ch pared_ch

**************
***techo_ch***
**************
gen techo_ch = 0 if s06a_05 == 4
replace techo_ch = 1 if s06a_05 >= 1 & s06a_05 <= 3
replace techo_ch = 2 if s06a_05 == 5
label var techo_ch "Materiales de construcción del techo"
label def techo_ch 0"No permanentes" 1"Permanentes" 2 "Otros materiales"
label val techo_ch techo_ch
*/ 
	gen piso_ch  = . 
	gen pared_ch = . 
	gen techo_ch = . 
	
	**************
	***resid_ch***
	**************
	gen resid_ch = 0 if s06a_13 == 5 | s06a_13 == 6
	replace resid_ch = 1 if s06a_13 == 2 | s06a_13 == 4
	replace resid_ch = 2 if s06a_13 == 1 | s06a_13 == 3
	replace resid_ch = 3 if s06a_13 == 7
	replace resid_ch = . if s06a_13 == .
	label var resid_ch "Método de eliminación de residuos"
	label def resid_ch 0"Recolección pública o privada" 1"Quemados o enterrados"
	label def resid_ch 2"Tirados a un espacio abierto" 3"Otros", add
	label val resid_ch resid_ch
			
	*************
	***dorm_ch***
	*************
	gen dorm_ch = s06a_17
	label var dorm_ch "Habitaciones para dormir"

	****************
	***cuartos_ch***
	****************
	*Esta pregunta no incluye baño, cocina, lavandería, garage, depósito o negocio 
	gen cuartos_ch = s06a_16
	label var cuartos_ch "Habitaciones en el hogar"

	***************
	***cocina_ch***
	***************
	gen cocina_ch = .
	replace cocina_ch = 1 if s06a_14==1
	replace cocina_ch = 0 if s06a_14==2
	label var cocina_ch "Cuarto separado y exclusivo para cocinar"

	**************
	***telef_ch***
	**************
	gen telef_ch = (s06a_18 == 1)
	replace telef_ch = . if s06a_18 == .
	label var telef_ch "El hogar tiene servicio telefónico fijo"

	*************
	**refrig_ch**
	*************
	gen refrig_ch = (posee_4 == 1)
	label var refrig_ch "El hogar posee refrigerador o heladera"

	************
	**freez_ch**
	************
	*No hay freezer separado en la encuesta, se usa el de refri
	gen freez_ch = (posee_4 == 1)
	label var freez_ch "El hogar posee congelador"

	*************
	***auto_ch***
	*************
	gen auto_ch = (posee_17 == 1)
	label var auto_ch "El hogar posee automovil particular"

	**************
	***compu_ch***
	**************
	gen compu_ch = (posee_6 == 1)
	label var compu_ch "El hogar posee computador"

	*****************
	***internet_ch***
	*****************
	gen internet_ch = (s06a_19 == 1)
	replace internet_ch = .   if  s06a_19 == .
	label var internet_ch "El hogar posee conexión a Internet"

	************
	***cel_ch***
	************
	gen cel_ch = (posee_8 == 1)
	label var cel_ch "El hogar tiene servicio telefonico celular"

	**************
	***vivi1_ch***
	**************
	gen vivi1_ch = 1 if s06a_01 == 1
	replace vivi1_ch = 2 if s06a_01 == 3
	replace vivi1_ch = 3 if s06a_01 == 2 | (s06a_01 >= 4 & s06a_01 <= 6)
	replace vivi1_ch = . if s06a_01 == .
	label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
	label def vivi1_ch 1"Casa" 2"Departamento" 3"Otros"
	label val vivi1_ch vivi1_ch

	*************
	***vivi2_ch**
	*************
	gen vivi2_ch = (vivi1_ch == 1 | vivi1_ch == 2)
	replace vivi2_ch = . if vivi1_ch == .
	label var vivi2_ch "La vivienda es casa o departamento"

	*****************
	***viviprop_ch***
	*****************
	gen viviprop_ch = 0 if s06a_02 == 3
	replace viviprop_ch = 1 if s06a_02 == 1
	replace viviprop_ch = 2 if s06a_02 == 2
	replace viviprop_ch = 3 if inlist(s06a_02, 5, 6, 7)
	replace viviprop_ch = 4 if inlist(s06a_02, 4, 8)

	label variable viviprop_ch "Propiedad de la vivienda"

	label define viviprop_ch ///
		0 "Alquilada" ///
		1 "Propia y totalmente pagada" ///
		2 "Propia y en proceso de pago" ///
		3 "Ocupada (propia de facto)" ///
		4 "Otra", add

	label values viviprop_ch viviprop_ch

	****************
	***vivitit_ch***
	****************
	gen vivitit_ch = .
	label var vivitit_ch "El hogar posee un título de propiedad"

	****************
	***vivialq_ch***
	****************
	gen vivialq_ch = .
	label var vivialq_ch "Alquiler mensual"

	*******************
	***vivialqimp_ch***
	*******************
	gen vivialqimp_ch = .
	label var vivialqimp_ch "Alquiler mensual imputado"



	***************************
	**** VARIABLES DE WASH ****
	***************************
	
	****************
	***aguared_ch***
	****************
	gen aguared_ch = 0
	replace aguared_ch = 1 if (s06a_07 == 1 | s06a_07 == 2)
	replace aguared_ch = . if s06a_07 == .
	label var aguared_ch "Acceso a fuente de agua por red"

	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = .
	replace aguafconsumo_ch = 1 if s06a_07 == 1 | s06a_07 == 2
	replace aguafconsumo_ch = 2 if s06a_07 == 3
	replace aguafconsumo_ch = 4 if (s06a_07 == 5 | s06a_07 == 6)
	replace aguafconsumo_ch = 5 if s06a_07 == 4
	replace aguafconsumo_ch = 6 if s06a_07 == 10
	replace aguafconsumo_ch = 7 if s06a_07 == 8
	replace aguafconsumo_ch = 8 if s06a_07 == 9
	replace aguafconsumo_ch = 9 if s06a_07 == 7
	replace aguafconsumo_ch = 10 if s06a_07 == 11

	*****************
	*aguafuente_ch*
	*****************
	gen aguafuente_ch = .
	replace aguafuente_ch = 1 if inlist(s06a_07, 1, 2)
	replace aguafuente_ch = 2 if s06a_07 == 3
	replace aguafuente_ch = 4 if inlist(s06a_07, 5, 6)
	replace aguafuente_ch = 5 if s06a_07 == 4
	replace aguafuente_ch = 6 if s06a_07 == 10
	replace aguafuente_ch = 7 if s06a_07 == 8
	replace aguafuente_ch = 8 if s06a_07 == 9
	replace aguafuente_ch = 9 if s06a_07 == 7
	replace aguafuente_ch = 10 if s06a_07 == 11

	*************
	*aguadist_ch*
	*************
	gen aguadist_ch = 0
	replace aguadist_ch = 1 if s06a_07 == 1
	replace aguadist_ch = 2 if s06a_07 == 2
	replace aguadist_ch = 3 if s06a_07 == 3

	**************
	*aguadisp1_ch*
	**************
	gen aguadisp1_ch = 9 

	**************
	*aguadisp2_ch*
	**************
	gen aguadisp2_ch = 1 if (s06a_08a <= 3 | s06a_08b < 12)
	replace aguadisp2_ch = 2 if (s06a_08a >= 4 & s06a_08b >= 12)
	replace aguadisp2_ch = 3 if (s06a_08a == 7 & s06a_08b == 24)

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
	*label var aguamala_ch "= 1 si la fuente de agua no es mejorada"

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
	label var aguamide_ch "Usan medidor para pagar consumo de agua"

	*************
	***bano_ch***
	*************
	gen bano_ch = 6
	replace bano_ch = 0 if s06a_09 == 5
	replace bano_ch = 1 if s06a_09 == 1 & s06a_10 == 1
	replace bano_ch = 2 if s06a_09 == 1 & s06a_10 == 2
	replace bano_ch = 3 if (inlist(s06a_09, 2, 4) & s06a_10 != 4) | (s06a_09 == 1 & s06a_10 == 3)
	replace bano_ch = 4 if inlist(s06a_09, 1, 2, 3) & s06a_10 == 4
	replace bano_ch = 5 if s06a_09 == 3 & s06a_10 != 4

	label define bano_ch_lbl ///
		0 "Sin instalaciones" ///
		1 "Inodoro a red de desagüe" ///
		2 "Inodoro a fosa séptica" ///
		3 "Letrina mejorada / otra instalación mejorada" ///
		4 "Inodoro/letrina a cuerpo de agua superficial o suelo" ///
		5 "Instalación no mejorada" ///
		6 "Instalación que no se puede clasificar"

	label values bano_ch bano_ch_lbl
	label variable bano_ch "Tipo de instalación sanitaria"

	***************
	***banoex_ch***
	***************
	gen banoex_ch = .
	replace banoex_ch = 0 if s06a_11 == 2
	replace banoex_ch = 1 if s06a_11 == 1

	************
	*sinbano_ch*
	************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if inlist(s06a_09,1,2,3,4) & s06a_11==1
	replace sinbano_ch = 1 if inlist(s06a_09,1,2,3,4) & s06a_11==2
	replace sinbano_ch = 2 if s06a_09==5
	replace sinbano_ch = 3 if missing(s06a_09)

	*****************
	*banomejorado_ch*
	*****************
	gen byte banomejorado_ch = .
	replace banomejorado_ch = 1 if (s06a_09 == 1 & inlist(s06a_10,1,2,3)) | inlist(s06a_09,2,4)
	replace banomejorado_ch = 0 if s06a_09 == 3 | s06a_09 == 5
	replace banomejorado_ch = 0 if s06a_09 == 1 & inlist(s06a_10,4,5)

	*****************************
	**** VARIABLES MIGRACIÓN ****
	*****************************

	*******************
	*** migrante_ci ***
	*******************
	gen migrante_ci = .
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	gen migrantiguo5_ci = .
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"

	*****************
	*** miglac_ci ***
	*****************
	gen miglac_ci = .
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"


	************************************
	**VARIABLES DE REFERENCIA EXTERNA***
	************************************
	
	****************
	*tipo_bienestar*
	****************
	gen byte tipo_bienestar = 1
	
	
	****************
	* pobre_ine_ci*
	****************
	gen byte pobre_ine_ci= .
	replace pobre_ine_ci= 0 if p0==0
	replace pobre_ine_ci= 1 if p0==1

	****************
	* bienestar_agregado *
	****************
	gen bienestar_agregado = yhogpc

	**************
	***salmm_ci***
	**************
	*https://www.ine.gob.bo/index.php/estadisticas-economicas/salario-minimo-nacional-cuadros-estadisticos/
	gen salmm_ci= 2500
	label var salmm_ci "Salario minimo legal"

	************
	***lp_ci***
	************
	gen ln_ci = z
	label var ln_ci "Linea de pobreza del pais"

	************
	***lpe_ci***
	************
	gen lpe_ci = zext
	label var lpe_ci "Linea de pobreza extrema del pais"



/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


capture confirm file "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\Labels&ExternalVars_Harmonized_DataBank.do"
if _rc == 0 {
	do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\Labels&ExternalVars_Harmonized_DataBank.do"
}
else {
	foreach v in lp19_2011 lp31_2011 lp5_2011 lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 ppp_c ppp_2011 ppp_2017 {
		capture confirm variable `v'
		if _rc != 0 gen `v' = .
	}
}

*_____________________________________________________________________________________________________*

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

foreach v in ynlm_publico_ci ynlm_privado_ci ynlm_publico_ch ynlm_privado_ch ytot_ch yneto_pc_ch bene_cash_ch pensionsub_ch {
	capture confirm variable `v'
	if _rc != 0 gen `v' = .
}

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch idp_ci factor_ci factor_ch /// Identificacion
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demograficas
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demograficas
  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci afiliado_ci /// Empleo
  formal_ci tipocontrato_ci ocupa_ci pension_ci pensionsub_ci tipopen_ci instpen_ci ylmpri_ci /// Empleo
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci /// Ingresos individuo
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educacion
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamiento
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch /// Agua y saneamiento
  migrante_ci migrantiguo5_ci miglac_ci, first  /// Migracion
 
  
/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo) 
BOLIVIA usaba para las EIHs usaba como referencia el CIUO -88 */


compress


save "`base_out'", replace 


log close


