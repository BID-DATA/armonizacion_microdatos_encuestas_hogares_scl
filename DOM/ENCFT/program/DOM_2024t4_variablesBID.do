
* (Versión Stata 18)
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

local PAIS DOM
local ENCUESTA ENCFT
local ANO "2024"
local ronda t4 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   

capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES
				       Script de armonización
País: Republica Dominicana
Año: 2024
Encuesta: ENCFT
Ronda: t4
Última versión:23JUN2025
Autores: Olga Dulce EDU/SCL - IADB
****************************************************************************/

use `base_in', clear

		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************

**********
***anio***
**********
gen anio_c=2024
label variable anio_c "Anio de la encuesta"

*********
***mes***
*********
*se usa el cuarto trimestre porque la encuesta anterior, ENFT era representativa para el mes 10,
*la muestra mensual de esta encuesta no lo es
gen byte trimestre_c=4
label variable trimestre_c "trimestre de la encuesta"
gen mes_c=mes
label var mes_c "Mes de la encuesta"  
	
************
****pais****
************
gen str3 pais_c="DOM"
label variable pais_c "Pais"

****************
* region_BID_c *
****************
gen byte region_BID_c=1
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

***************
*** region_c **
***************
*Con el objeto de mantener la comparabilidad con años anteriores, se mantiene la variable original.
gen byte region_c=id_provincia
label define region_c 1 "Distrito Nacional" ///
2 "Azua" ///
3 "Bahoruco" ///
4 "Barahona" ///
5 "Dajabon" ///
6 "Duarte" ///
7 "Elias Piña" ///
8 "El Seibo" ///
9 "Espaillat" ///
10 "Independencia" ///
11 "La Altagracia" ///
12 "La Romana" ///
13 "La Vega" ///
14 "Maria Trinidad Sanchez" ///
15 "Monte Cristi" ///
16 "Pedernales" ///
17 "Peravia" ///
18 "Puerto Plata" ///
19 "Salcedo" ///
20 "Samana" ///
21 "San Cristobal" ///
22 "San Juan" ///
23 "San Pedro De Macoris" ///
24 "Sanchez Ramirez" ///
25 "Santiago" ///
26 "Santiago Rodriguez" ///
27 "Valverde" ///
28 "Monseñor Nouel" ///
29 "Monte Plata" ///
30 "Hato Mayor" ///
31 "San Jose De Ocoa" ///
32 "Santo Domingo" 
label value region_c region_c
label var region_c "Region - id_provincias"  

**********
***zona***
**********
gen byte zona_c=1 if zona==1
replace zona_c=0 if zona==2
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

***************
***estrato_ci***
***************
gen byte estrato_ci=estrato
label variable estrato_ci "Estrato"

***************
***upm_ci***
***************
gen int upm_ci=upm
label variable upm_ci "Unidad Primaria de Muestreo"

***************
****idh_ch*****
***************
sort vivienda hogar
egen idh_ch = concat(vivienda hogar)
label variable idh_ch "ID del hogar"
tostring idh_ch, replace


*************
****idp_ci****
**************
* string
egen idp_ci=concat(vivienda hogar miembro)
label variable idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace

duplicates report idp_ci

***************
***factor_ci***
***************
gen factor_ci= factor_expansion
label variable factor_ci "Factor de expansion del individuo"

***************
***factor_ch***
***************
gen factor_ch= factor_expansion
label variable factor_ch "Factor de expansion del hogar"



	****************************
	***VARIABLES DEMOGRAFICAS***
	****************************

**********
***sexo***
**********
gen sexo_ci=sexo
label var sexo_ci "Sexo del individuo" 
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********
gen edad_ci=edad
label variable edad_ci "Edad del individuo"

*****************
***relacion_ci***
*****************
* No hay manera de identificar a empleado doméstico
gen relacion_ci=1 if parentesco==1
replace relacion_ci=2 if parentesco==2
replace relacion_ci=3 if parentesco==3 | parentesco==4 
replace relacion_ci=4 if parentesco>=5 & parentesco<=11
replace relacion_ci=5 if parentesco==12
label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes"
label value relacion_ci relacion_ci

*****************
***civil_ci***
*****************
gen civil_ci=.
replace civil_ci=1 if estado_civil==6
replace civil_ci=2 if estado_civil==1 | estado_civil==2 
replace civil_ci=3 if estado_civil==3 | estado_civil==4
replace civil_ci=4 if estado_civil==5
label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci

**************
***jefe_ci***
*************
gen jefe_ci=(relacion_ci==1)
label variable jefe_ci "Jefe de hogar"

******************
***nconyuges_ch***
******************
egen byte nconyuges_ch=sum(relacion_ci==2), by(idh_ch)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************
egen byte nhijos_ch=sum(relacion_ci==3), by(idh_ch)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************
egen byte notropari_ch=sum(relacion_ci==4), by(idh_ch)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************
egen byte notronopari_ch=sum(relacion_ci==5), by(idh_ch)
label variable notronopari_ch "Numero de no familiares"

****************
***nempdom_ch***
****************
*NOTA: dentro de las relaciones de parentesco no es posible identificar a los empleados domésticos
gen byte nempdom_ch=.
label variable nempdom_ch "Numero de empleados domesticos"

*****************
***clasehog_ch***
*****************
gen byte clasehog_ch=0
**** unipersonal
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
**** nuclear   (child with or without spouse but without other relatives)
replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
**** ampliado
replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
**** compuesto  (some relatives plus non relative)
replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
**** corresidente
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
label variable clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
label value clasehog_ch clasehog_ch

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
label variable nmiembros_ch "Numero de familiares en el hogar"

****************
***miembros_ci***
****************
gen byte miembros_ci=(relacion_ci<5)
label variable miembros_ci "Miembro del hogar"

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"


		*******************************
		*** VARIABLES DE DIVERSIDAD ***
		*******************************			

*************
***afro_ci***
*************
gen byte afro_ci=. 

************
***ind_ci***
************
gen byte ind_ci=. 

***************
***afroind_ci**
***************
gen byte noafroind_ci=. 

***************
***afroind_ci**
***************
gen byte afroind_ci=. 

*************
***afro_ch***
*************
gen byte afro_ch=. 

*************
***ind_ch***
*************
gen byte ind_ch=. 

******************
***noafroind_ch***
******************
gen byte noafroind_ch=. 

***************
***afroind_ch***
***************
gen byte afroind_ch=. 

*******************
***afroind_ano_c***
*******************
gen byte afroind_ano_c=.		

************
***dis_ci***
************
gen byte dis_ci=. 

**************
***disWG_ci***
**************
gen byte disWG_ci=.

*****************
***DOM_dis_ci ***
*****************
gen byte DOM_dis_ci=.  

*******************
***dis_ch***
*******************
gen byte dis_ch=. 


		************************************
		*** VARIABLES DEL MERCADO LABORAL***
		************************************
		
****************
****condocup_ci*
****************
gen byte condocup_ci=.
replace condocup_ci=1 if trabajo_semana_pasada==1 | tenia_empleo_negocio==1 | (realizo_actividad!=8 & realizo_actividad!=.)
replace condocup_ci=2 if (trabajo_semana_pasada==2 | tenia_empleo_negocio==2 | realizo_actividad==8 ) & (busco_trabajo_establ_negocio==1)
recode condocup_ci (.=3) if edad_ci>=10
replace condocup_ci=4 if edad_ci<10
label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 10" 
label value condocup_ci condocup_ci

*******************
***categoinac_ci*** 
*******************
gen byte categoinac_ci = .
replace categoinac_ci = 1 if  (motivo_no_busca_trabajo==10 & condocup_ci==3)
replace categoinac_ci = 2 if  (motivo_no_busca_trabajo==7 & condocup_ci==3)
replace categoinac_ci = 3 if  (motivo_no_busca_trabajo==8 & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci !=1 & categoinac_ci !=2 & categoinac_ci !=3) & condocup_ci==3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 
label value categoinac_ci categoinac_ci

************
***emp_ci***
************
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
label var emp_ci "Ocupado (empleado)"
label define emp_ci 0"No" 1"Si", add
label value emp_ci emp_ci

*************
*cesante_ci* 
*************
gen cesante_ci=1 if trabajo_antes==1
replace cesante_ci=0 if trabajo_antes==2
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

***************
***subemp_ci***
***************    
*Modificacion MGD 06/20/2014: condiciona solo a horas en ocupacion primaria.
*Horas semanales trabajadas empleo principal
gen promhora=horas_trabaja_semana_principal if emp_ci==1 
gen subemp_ci=0  
replace  subemp_ci=1 if (promhora>=1 & promhora<=30) & emp_ci==1 & desea_trabajar_mas_horas==1
label var subemp_ci "Personas en subempleo por horas"

************
*durades_ci*
************
gen durades_ci=.
replace durades_ci=1 if que_tiempo_busca_trabajo==1
replace durades_ci=(1+6)/2 if que_tiempo_busca_trabajo==2
replace durades_ci=(6+12)/2 if que_tiempo_busca_trabajo==3
replace durades_ci=(12+12)/2 if que_tiempo_busca_trabajo==4
label variable durades_ci "Duracion del desempleo en meses"
label def durades_ci 1 "Menos de un mes" 2"Promedio 3 meses" 3"Promedio 9 meses" 4"Promedio 12 meses"
label val durades_ci durades1_ci

*************
***pea_ci***
*************
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1
label var pea_ci "Población Económicamente Activa"

*****************
***nempleos_ci***
*****************
gen nempleos_ci=.
replace nempleos_ci=1 if emp_ci==1 & cuantos_trabajos_tiene==1
replace nempleos_ci=cuantos_trabajos_tiene_cant if emp_ci==1 & cuantos_trabajos_tiene==2
replace nempleos_ci=. if emp_ci==0
label var nempleos_ci "Número de empleos" 

*******************
***antiguedad_ci***
*******************
gen temp1=tiempo_empleo_dias/365
gen temp2=tiempo_empleo_meses/12
egen antiguedad_ci= rsum(tiempo_empleo_anos temp1 temp2), missing  
replace antiguedad_ci=. if emp_ci==0
replace antiguedad_ci=. if tiempo_empleo_dias==. & tiempo_empleo_meses==. & tiempo_empleo_anos==.
label var antiguedad_ci "Antiguedad en la actividad actual en anios"
drop temp*

*****************
***desalent_ci***
*****************
***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
gen byte desalent_ci = .
replace desalent_ci = 1 if (busco_trabajo_establ_negocio == 2 & inlist(motivo_no_busca_trabajo, 4, 12) & condocup_ci == 3)
replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
label var desalent_ci "Desalentados"
label define desalent_ci 0"No" 1"Si", add
label value desalent_ci desalent_ci

*****************
***horaspri_ci***
*****************
gen horaspri_ci=horas_trabaja_semana_principal
replace horaspri_ci=. if emp_ci==0
label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"

*****************
***horastot_ci***
*****************
*Horas semanales trabajadas empleo secundario
gen promhora1=horas_trabajo_ocup_secun if emp_ci==1
egen tothoras=rowtotal(promhora promhora1)
replace tothoras=. if promhora==. & promhora1==. 
replace tothoras=. if tothoras>=168
gen horastot_ci=tothoras  if emp_ci==1 
label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"

*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci=(tothoras>=1 & horastot_ci<=30) &  emp_ci==1 & desea_trabajar_mas_horas==2
replace tiempoparc_ci=. if emp_ci==0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

******************
***categopri_ci***
******************
*clasificación cambió en relación la de las ENFTs (<-2016)
*Muchos trabajadores que la encuesta clasifica como no remunerados nuestra clasificación los clasifica commo inactivos.
*Para recuperar información del ingreso de estos trabajadores los reclasificamos como no remunerados si observan ingresos en categorías de no_remunerados
destring crianza_no_remun_monto, replace 
egen noremunerados = rowtotal(crianza_no_remun_monto pesca_no_remun_monto alimentos_no_remun_monto), missing
gen categopri_ci=.
replace categopri_ci=1 if categoria_principal==6
replace categopri_ci=2 if categoria_principal==7 & noremunerados==.
replace categopri_ci=3 if categoria_principal==1 | categoria_principal==2 | categoria_principal==3 | categoria_principal==4 | categoria_principal==5
replace categopri_ci=4 if categoria_principal==8 | grupo_categoria=="Familiar no remunerado" | noremunerados!=.
replace categopri_ci=. if emp_ci==0 & noremunerados==.
label define categopri_ci 1"Patron" 2"Cuenta propia" 0"Otro"
label define categopri_ci 3"Empleado" 4" No remunerado" , add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional"

******************
***categosec_ci***
******************
gen categosec_ci=.
replace categosec_ci=1 if categoria_secundaria==6
replace categosec_ci=2 if categoria_secundaria==7 
replace categosec_ci=3 if categoria_secundaria==1 | categoria_secundaria==2 | categoria_secundaria==3 | categoria_secundaria==4 | categoria_secundaria==5
replace categosec_ci=4 if categoria_secundaria==8
replace categosec_ci=. if emp_ci==0
label define categosec_ci 1"Patron" 2"Cuenta propia" 0"Otro" 
label define categosec_ci 3"Empleado" 4"No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"

*************
***rama_ci***
*************
*Nota: para esta nueva base, ENCFT se contruye la variable rama_ci siguiendo la CIUU revision4, y no la Rev3 como en bases anteriores
*esto resulta en saltos en el share de ramas en la serie SIMS
*AJAM, junio 2018
rename rama_principal_cod ramac
des ramac
ta ramac if emp_ci ==1,m 
destring ramac, replace 
ta ramac,m
gen rama_ci=.
replace rama_ci = 1 if (ramac>=111 & ramac<=322)  & emp_ci==1
replace rama_ci = 2 if (ramac>=510 & ramac<=990)  & emp_ci==1
replace rama_ci = 3 if (ramac>=1010 & ramac<=3320)  & emp_ci==1
replace rama_ci = 4 if (ramac>=3510 & ramac<=3900)  & emp_ci==1
replace rama_ci = 5 if (ramac>=4100 & ramac<=4390)  & emp_ci==1
replace rama_ci = 6 if (ramac>=4510 & ramac<=4799)  & emp_ci==1
replace rama_ci = 7 if (ramac>=4911 & ramac<=6399)  & emp_ci==1
replace rama_ci = 8 if (ramac>=6411 & ramac<=6820)  & emp_ci==1
replace rama_ci = 9 if (ramac>=6910 & ramac<=9990)  & emp_ci==1
label var rama_ci "Rama de actividad"
label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val rama_ci rama_ci
ta rama_ci if emp_ci ==1,m 

*****************
***spublico_ci***
*****************
gen spublico_ci=(categoria_principal==1 |categoria_principal==2) 
replace spublico_ci=. if emp_ci==0 
label var spublico_ci "Personas que trabajan en el sector público"

*************
*tamemp_ci***
*************
/*variable total_personas_trabajan_emp
1 1 a 10 personas
2 de 11 a 19 personas
3 de 20 a 30 personas
4 de 31 a 50 personas
5 de 51 a 99
6 de 100 a 99
7 No sabe
*/
gen tamemp_ci=1 if cantidad_personas_trabajan_emp>0 & cantidad_personas_trabajan_emp<=5
replace tamemp_ci=2 if (cantidad_personas_trabajan_emp>=6 & cantidad_personas_trabajan_emp<=10) | total_personas_trabajan_emp==2
replace tamemp_ci=3 if total_personas_trabajan_emp>=3 & total_personas_trabajan_emp!=. & total_personas_trabajan_emp!=98
/*
gen tamemp_ci=1 if cant_pers_trab>0 & cant_pers_trab<=5
replace tamemp_ci=2 if cant_pers_trab>5 & cant_pers_trab<=50
replace tamemp_ci=3 if cant_pers_trab>50 & cant_pers_trab!=.*/
label var tamemp_ci "# empleados en la empresa segun rangos"
label define tamemp_ci 1 "Pequena" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci

****************
*cotizando_ci***
****************
gen cotizando_ci=.
label var cotizando_ci "Cotizante a la Seguridad Social"

********************
*** instcot_ci *****
********************
gen instcot_ci=.
label var instcot_ci "institución a la cual cotiza"

****************
*afiliado_ci****
****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte afiliado_ci = .
replace afiliado_ci = 1 if (afiliado_afp_princ == 1 & emp_ci==1)
replace afiliado_ci = 0 if (afiliado_ci != 1 & inlist(condocup_ci, 1, 2))
label var afiliado_ci "Afiliado a la Seguridad Social"
label define afiliado_ci 0 "No"  1 "Si"
label value afiliado_ci afiliado_ci

***************
***formal_ci***
***************
gen formal_ci = (cotizando_ci == 1 | afiliado_ci == 1)
label var formal_ci "1=formal"

*****************
*tipocontrato_ci*
*****************
/*2018, Alvaro A. Obs. la tasa de respuesta de trabajadores con contrato es muy alta, 99%. Esto crea un salto en serie SIMS para esta variable
En encuestas anteriores se preguntaba si había firmado contrato, con una tasas de respuesta positiva de 61% de la muestra

*/
*Modificacion MGD 06/13/2014
gen tipocontrato_ci=. 
replace tipocontrato_ci=1 if (tiene_contrato==1 & tipo_contrato==1) & categopri_ci==3
replace tipocontrato_ci=2 if (tiene_contrato==1 & (tipo_contrato==2 | tipo_contrato==3)) & categopri_ci==3
replace tipocontrato_ci=3 if (tiene_contrato==2 | contrato_verbal_escrito==2 | tipocontrato_ci==.) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

**************
***ocupa_ci***
**************
*CIUO-08, base anterior usaba CIUO-88 a 3 dígitos, esto crea saltos en la distribución de ocupaciones ilustrada por el SIMS
generat ocupa_ci=.
** convert to numeric
des ocupacion_principal_cod
destring ocupacion_principal_cod, replace
replace ocupa_ci=1 if (ocupacion_principal_cod>=2111 & ocupacion_principal_cod<=3522) & emp_ci==1
replace ocupa_ci=2 if (ocupacion_principal_cod>=1111 & ocupacion_principal_cod<=1439) & emp_ci==1
replace ocupa_ci=3 if (ocupacion_principal_cod>=4110 & ocupacion_principal_cod<=4419) & emp_ci==1
replace ocupa_ci=4 if ((ocupacion_principal_cod>=5211 & ocupacion_principal_cod<=5249) | (ocupacion_principal_cod>=9510 & ocupacion_principal_cod<=9520)) & emp_ci==1
replace ocupa_ci=5 if ((ocupacion_principal_cod>=5110 & ocupacion_principal_cod<=5169) | (ocupacion_principal_cod>=5311 & ocupacion_principal_cod<=5419) | (ocupacion_principal_cod>=9111 & ocupacion_principal_cod<=9129) | (ocupacion_principal_cod>=9610 & ocupacion_principal_cod<=9624))  & emp_ci==1
replace ocupa_ci=6 if ((ocupacion_principal_cod>=6110 & ocupacion_principal_cod<=6340) | (ocupacion_principal_cod>=9210 & ocupacion_principal_cod<=9216)) & emp_ci==1
replace ocupa_ci=7 if ((ocupacion_principal_cod>=7111 & ocupacion_principal_cod<=8350) | (ocupacion_principal_cod>=9310 & ocupacion_principal_cod<=9412))  & emp_ci==1
replace ocupa_ci=8 if (ocupacion_principal_cod>=110 & ocupacion_principal_cod<=310) & emp_ci==1
replace ocupa_ci=9 if ocupacion_principal_cod>=9629 & ocupacion_principal_cod!=. & emp_ci==1
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral" 

*************
**pension_ci*
*************
gen pension_ci=1 if pension_nac_monto!=0 & pension_nac_monto!=.
recode pension_ci .=0 
label var pension_ci "1=Recibe pension contributiva"

***************
*pensionsub_ci*
***************
gen pensionsub_ci= (ps_apoyo_adultos_mayores==1)
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

****************
*tipopen_ci*****
****************
gen tipopen_ci=.
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

****************
*instpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais"


		****************************
		*** VARIABLES DE INGRESO ***
		****************************

***********************************************
* A.	Ingresos laborales a nivel individuo
***********************************************

*Asalariados
destring tiempo_recibe_pago_dias_ap, replace
gen ymensual= 	   sueldo_bruto_ap_monto*tiempo_recibe_pago_dias_ap*4.3 if tiempo_recibe_pago_ap==1
replace ymensual=  sueldo_bruto_ap_monto*4.3 if tiempo_recibe_pago_ap==2
replace ymensual=  sueldo_bruto_ap_monto*2   if tiempo_recibe_pago_ap==3
replace ymensual=  sueldo_bruto_ap_monto     if tiempo_recibe_pago_ap==4

*Independientes
gen ymensualindep= 	   ingreso_actividad_in_monto*ingreso_actividad_in_dias*4.3 if ingreso_actividad_in_periodo==1
replace ymensualindep=  ingreso_actividad_in_monto*4.3   if ingreso_actividad_in_periodo==2
replace ymensualindep=  ingreso_actividad_in_monto*2   if ingreso_actividad_in_periodo==3
replace ymensualindep=  ingreso_actividad_in_monto     if ingreso_actividad_in_periodo==4

*variables en la base con el mismo nombre
rename comisiones otrascomisionesoriginales
rename propinas otraspropinasoriginales
rename bonificaciones bonificacionesoriginales
gen comisiones=comisiones_ap_monto 
gen propinas=propinas_ap_monto 
gen horasextra=horas_extra_ap_monto 

gen vacaciones=vacaciones_ap_monto/12
destring dividendos_ap_monto, replace
gen dividendos=dividendos_ap_monto/12
gen bonificaciones=bonificacion_ap_monto/12
gen regalia=regalia_ap_monto/12
destring utilidad_empresarial_ap_monto, replace
gen utilidades=utilidad_empresarial_ap_monto/12 
destring beneficios_marginales_ap_monto, replace        
gen beneficios=beneficios_marginales_ap_monto/12                                             
gen bonoantiguedad=incentivo_antiguedad_ap_monto/12
gen otrosbeneficios=otros_beneficios_ap_monto/12

gen alimentos=alimentacion_especie_ap_monto if alimentacion_especie_ap==1
gen vivienda1=vivienda_especie_ap_monto if vivienda_especie_ap ==1
gen transporte=transporte_especie_ap_monto if transporte_especie_ap==1
gen gasolina=gasolina_especie_ap_monto if gasolina_especie_ap==1
gen cellular=celular_especie_ap_monto if celular_especie_ap==1
gen otros=otros_especie_ap_monto if otros_especie_ap==1

gen pension=pension_nac_monto  	    if pension_nac==1
gen intereses= intereses_nac_monto 	if intereses_nac==1 
gen alquiler= alquiler_nac_monto 	if alquiler_nac==1
gen remesasnales=remesas_nac_monto  if remesas_nac==1  
gen otrosing=ayuda_especie_nac_monto  if ayuda_especie_nac==1 
egen gobierno=rsum(alimentos_escuela_nac_monto gob_comer_primero_monto gob_inc_asis_escolar_monto gob_bono_luz_monto gob_bonogas_choferes_monto gob_bonogas_hogares_monto  ///
gob_proteccion_vejez_monto gob_bono_estudiante_prog_monto gob_inc_educacion_sup_monto gob_inc_policia_prev_monto gob_inc_marina_guerra_monto) if gobierno_nac==1, missing
recode ingreso_asalariado_secun (0=.)
recode ingreso_independientes_secun (0=.)
destring ganancia_secun_imp_monto, replace
egen ymensual2=rsum(ganancia_secun_imp_monto ingreso_asalariado_secun ingreso_independientes_secun), missing

*pension*
*Para República Dominicana hay dos módulos especiales: remesas e ingresos del exterior.
*Aquí se trabaja sobre esas variables:
*Módulo de ingresos del exterior
********************************
*Información cambiaria que viene en la base de excel
*Dado que se necesita la información en moneda local se calcula el factor de conversión a pesos
*Si la información está en pesos se deja como está
*Si la información está en dólares se multiplica por 58.73, Euros, luego de ser convertidos en dolares, por 0.9 (promedio para los meses del cuarto trimestre de 2024)
*Nota: Tasa de cambio a peso CHF=51.54 Para ultimo trimestre

*Modulo Ingresos del Exterior
gen pension_int=pension_ext_monto	 		    if  pension_ext_moneda=="DOP"
replace pension_int=pension_ext_monto*58.73   	if  pension_ext_moneda=="USD"
replace pension_int=(pension_ext_monto*0.9)*58.73  if  pension_ext_moneda=="EUR"
replace pension_int=pension_ext_monto*51.54   	if  pension_ext_moneda=="CHF"
replace pension_int=. if pension_ext==2
/*
gen interes_int=interes_ext_monto	 		    if interes_ext_moneda=="DOP" // Sin observaciones 2020
replace interes_int=interes_ext_monto*52.78 	    if interes_ext_moneda=="USD"
replace interes_int=(interes_ext_monto*0.9)*52.78  if interes_ext_moneda=="EUR"
replace interes_int=. if interes_ext==2
*/
*gen regalos_int= monto_equiv_regalo	if regalos_ext ==1


*Módulo de remesas
******************
*En este módulo se pregunta por el monto de remesas recibido durante los ultimos 6 meses, por ello se saca el promedio.

forvalues y=1/6  {
forvalues x=1/3  {
g remesasaux`y'_`x'=mes`y'_`x'_ext_monto if (mes1_1_ext_moneda=="DOP" | mes2_1_ext_moneda=="DOP" | mes3_1_ext_moneda=="DOP")
replace remesasaux`y'_`x'=mes`y'_`x'_ext_monto*52.78 if (mes1_1_ext_moneda=="USD" | mes2_1_ext_moneda=="USD" | mes3_1_ext_moneda=="USD")
replace remesasaux`y'_`x'=(mes`y'_`x'_ext_monto*.9)*52.78 if (mes1_1_ext_moneda=="EUR" | mes2_1_ext_moneda=="EUR" | mes3_1_ext_moneda=="EUR")
}
}
destring remesasaux1_2 remesasaux2_2 remesasaux3_2 remesasaux4_2 remesasaux5_2 remesasaux6_2, replace
egen remesas_mes=rsum(remesasaux*_*), missing 
destring recibio_remesa_ext3, replace
replace remesas_mes=. if recibio_remesa_ext1!=1 & recibio_remesa_ext2!=1 & recibio_remesa_ext3!=1
gen remesas_prom=remesas_mes/6

***************
***ylmpri_ci***
***************

*2018 AJAM, Obs. variable ymensual tiene muchos más missings que en bases anteriores (ENFT -<2016), para ver correr un: mdesc ymensual.
*Esto explica en parte porque se observa una media más baja en el ingreso laboral total
egen ylmpri_ci=rsum(ymensual comisiones propinas horasextra vacaciones bonificaciones regalia utilidades beneficios otrosbeneficios bonoantiguedad otros_pagos_ap_monto ymensualindep), missing 
replace ylmpri_ci=. if ymensual==. & comisiones==. & propinas==. & horasextra==. & vacaciones==. & bonificaciones==. & regalia==. & utilidades==. & beneficios==. & otrosbeneficios==. & bonoantiguedad==. & ymensualindep==.
replace ylmpri_ci=. if emp_ci==0
replace ylmpri_ci=0 if categopri_ci==4
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 

****************
***ylnmpri_ci***
****************
destring vivienda1 cellular otros, replace
egen ylnmpri_ci=rsum(alimentos vivienda1 transporte gasolina cellular otros), missing 
replace ylnmpri_ci=ylnmpri_ci+noremunerados if categopri_ci==4
replace ylnmpri_ci=. if alimentos==. & vivienda1==. & transporte==. & gasolina==. & cellular==. & otros==. & noremunerados==.
label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal"   

***************
***ylmsec_ci***
***************
*Modificación Mayra Sáenz - Febrero 2014.
gen ylmsec_ci=ymensual2 if emp_ci==1 & cuantos_trabajos_tiene==2
replace ylmsec_ci=. if (ymensual2==99999) & emp_ci==1 
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 

****************
***ylnmsec_ci***
****************
gen ylnmsec_ci=.
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

*****************
***ylmotros_ci***
*****************
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

******************
***ylnmotros_ci***
******************
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

************
***ylm_ci***
************
egen ylm_ci= rsum(ylmpri_ci ylmsec_ci), missing 
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso laboral monetario total"  

*************
***ylnm_ci***
*************
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci), missing 
replace ylnm_ci=. if ylnmpri_ci==. &  ylnmsec_ci==.
label var ylnm_ci "Ingreso laboral NO monetario total"  


***********************************************
* B. Ingresos no laborales a nivel individuo
***********************************************

******************
**ynlm_publico_ci
******************
destring intereses, replace
egen ynlm_publico_ci=rsum(pension gobierno), missing 
replace ynlm_publico_ci=. if pension==. & gobierno==. 
label var ynlm_publico_ci "Ingreso no laboral monetario publico del individuo"  

******************
**ynlm_privado_ci
******************

destring intereses, replace
egen ynlm_privado_ci=rsum(intereses alquiler remesasnales otrosing pension_int /*interes_int*/ remesas_prom dividendos), missing 
replace ynlm_privado_ci=. if intereses==. & alquiler==. & remesasnales==. & otrosing==. & pension_int==. /*& interes_int==.*/ & remesas_prom==.
label var ynlm_privado_ci "Ingreso no laboral monetario privado del individuo"  

*************
***ynlm_ci***
*************
*Se alimenta de módulo de ingresos del exterior, ver variables que no reportaron ingresos en este período
destring intereses, replace
egen ynlm_ci=rsum(pension intereses alquiler remesasnales otrosing gobierno pension_int /*interes_int*/ remesas_prom dividendos), missing 
replace ynlm_ci=. if pension==. & intereses==. & alquiler==. & remesasnales==. & otrosing==. & gobierno==. & pension_int==. /*& interes_int==.*/ & remesas_prom==.
label var ynlm_ci "Ingreso no laboral monetario"  

**************
***ynlnm_ci***
**************
destring regalos_ext_monto, replace
gen ynlnm_ci=regalos_ext_monto
replace ynlnm_ci=. if regalos_ext_monto==.
label var ynlnm_ci "Ingreso no laboral no monetario" 

***********************************************
* C. Ingresos total a nivel de individuo 
***********************************************

**************
* ytot_ci ****
**************

egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

*********************************************************
* D.  Ingresos laborales y no laborales a nivel hogar
*********************************************************

**************
*** ylm_ch ***
**************
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
label var ylm_ch "Ingreso laboral monetario del hogar"

***************
*** ylnm_ch ***
***************
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
label var ylnm_ch "Ingreso laboral no monetario del hogar"

**************
***ynlnm_ch***
**************
by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

*********************
***ynlm_publico_ch***
*********************
by idh_ch, sort: egen ynlm_publico_ch=sum(ynlm_publico_ci) if miembros_ci==1, missing
label var ynlm_publico_ch "Ingreso no laboral monetario publico del hogar"

*********************
***ynlm_privado_ch***
*********************
by idh_ch, sort: egen ynlm_privado_ch=sum(ynlm_privado_ci) if miembros_ci==1, missing
label var ynlm_privado_ch "Ingreso no laboral monetario privado del hogar"

***************
*** ynlm_ch ***
***************
egen double ynlm_ch = rowtotal(ynlm_privado_ch ynlm_publico_ch), mi
label var ynlm_ch "Ingreso no laboral monetario del hogar"


*********************************************************
* E.  Ingresos total a nivel de hogar
*********************************************************

**************
* ytot_ch ****
**************

egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi 


**************************
* F. Salario por hora
**************************

*****************
***ylmhopri_ci ***
*****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
label var ylmhopri_ci "Salario monetario de la actividad principal" 

***************
***ylmho_ci ***
***************
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario monetario de todas las actividades" 


***********************
* G.No respuesta
***********************

*****************
***nrylmpri_ci***
*****************
gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  

*******************
*** nrylmpri_ch ***
*******************
*Creating a Flag label for those households where someone has a ylmpri_ci as missing
by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.
label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

****************
*** ylmnr_ch ***
****************
by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1, missing
replace ylmnr_ch=. if nrylmpri_ch==1
label var ylmnr_ch "Ingreso laboral monetario del hogar"

************
*H.	Remesas
************

****************
***remesas_ci***
****************
*Aqui se toma el valor mensual de las remesas
gen remesas_ci=remesas_prom
label var remesas_ci "Remesas mensuales reportadas por el individuo" 

****************
***remesas_ch***
****************
*Aqui se toma el valor mensual de las remesas
by idh_ch, sort: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing
label var remesas_ch "Remesas mensuales del hogar" 

***************
* I.Pensiones
***************

*************
*ypen_ci*
*************
*Modificado Mayra Sáenz -Febrero 2014
/*
gen ypen_ci=pension_nac_monto
recode ypen_ci .=0
label var ypen_ci "Valor de la pension contributiva"
*/
*gen ypen_ci=pension_nac_monto if recibio_ing_pension_mes ==1
* 2014, 02 vuelvo a hacer modificacion sobre cambio de Mayra. MLO
gen ypen_ci=pension_nac_monto if pension_nac==1
label var ypen_ci "Valor de la pension contributiva"

*****************
**ypensub_ci*
*****************
*DZ Octubre 2017-Se crea la variable valor de la pension subsidiada*
gen ypensub_ci=gob_proteccion_vejez_monto
replace ypensub_ci=. if gob_proteccion_vejez_monto==0
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

 
		****************************
		***VARIABLES DE EDUCACION***
		****************************

*************
***aedu_ci*** 
*************
gen	 aedu_ci=.
replace aedu_ci= 0 if nivel_ultimo_ano_aprobado==1  
replace aedu_ci= 0 if nivel_ultimo_ano_aprobado==9
replace aedu_ci= 0 if nivel_ultimo_ano_aprobado==10
replace aedu_ci= . if nivel_ultimo_ano_aprobado==99
replace aedu_ci= ultimo_ano_aprobado if nivel_ultimo_ano_aprobado==2 
replace aedu_ci = ultimo_ano_aprobado+6 if nivel_ultimo_ano_aprobado == 3  
replace aedu_ci = ultimo_ano_aprobado+6 if nivel_ultimo_ano_aprobado == 4  
replace aedu_ci = ultimo_ano_aprobado+12 if nivel_ultimo_ano_aprobado == 5  
replace aedu_ci = ultimo_ano_aprobado+12+4 if nivel_ultimo_ano_aprobado==6 | nivel_ultimo_ano_aprobado==7 
replace aedu_ci = ultimo_ano_aprobado+12+4+2 if nivel_ultimo_ano_aprobado==8 
replace aedu_ci=.  if nivel_ultimo_ano_aprobado==.
label var aedu_ci "Anios de educacion aprobados" 
label define nivel 1 "Pre-escolar" 2 "Primario" 3 "Secundario" 4 "Secundario-técnico" 5 "Universitario" 6 "Post-grado" 7 "Maestria" 8 "Doctorado" 9 "Ninguno" 10 "Quisqueya Aprende" 99 "Otro"
label values nivel_ultimo_ano_aprobado nivel 
label values nivel_se_matriculo nivel

***************
***edupre_ci***
***************
gen byte edupre_ci=.
label variable edupre_ci "Educacion preescolar completa"

**************
***eduui_ci***
**************
gen byte eduui_ci=aedu_ci>12 & aedu_ci<16 
replace eduui_ci=. if aedu_ci==.
label variable eduui_ci "Universitaria incompleta"

***************
***eduuc_ci****
***************
gen byte eduuc_ci=aedu_ci>=16 // mas de 16 todos
replace eduuc_ci=. if aedu_ci==. 
label variable eduuc_ci "Universitaria completa o mas"

**************
***eduac_ci***
**************
gen byte eduac_ci=.  
label variable eduac_ci "Superior universitario vs superior no universitario"

***************
***asiste_ci***
***************
generat asiste_ci=1 if asiste_centro_educativo ==1 
replace asiste_ci=0 if asiste_centro_educativo ==2
replace asiste_ci=. if asiste_centro_educativo ==.
label variable asiste_ci "Asiste actualmente a la escuela"

***************
***edupub_ci***
***************
gen edupub_ci=.
replace edupub_ci=1 if tipo_centro_estudios==3 & asiste_centro_educativo==1 //publico
replace edupub_ci=0 if tipo_centro_estudios==1 & asiste_centro_educativo==1 // privado
replace edupub_ci=0 if tipo_centro_estudios==2 & asiste_centro_educativo==1 // semiprivado
label var edupub_ci "Asiste a un centro de enseñanza público"

****************
***asispre_ci***
****************
g asispre_ci= 1 if nivel_se_matriculo==1 & asiste_centro_educativo ==1
replace asispre_ci=0 if nivel_se_matriculo!=1 & asiste_centro_educativo ==1
label variable asispre_ci "Asistencia a Educacion preescolar"
	
**************
*pqnoasis1_ci*
**************
* pqnoasis1_ci was replaced by razonesnoasis_ci, June 2025 * 


**********************
***razonesnoasis_ci***
**********************
g razonesnoasis_ci = .						
replace razonesnoasis_ci = 1 if porque_no_estudia==8 | porque_no_estudia==7
replace razonesnoasis_ci = 2 if porque_no_estudia==4 | porque_no_estudia==12
replace razonesnoasis_ci = 3 if porque_no_estudia==11
replace razonesnoasis_ci = 4 if porque_no_estudia==3
replace razonesnoasis_ci = 5 if porque_no_estudia==2 | porque_no_estudia==5 | porque_no_estudia==6 | porque_no_estudia==9 | porque_no_estudia==10  |porque_no_estudia==13

label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
label value  razonesnoasis_ci razonesnoasis_ci


			**********************************
			**** VARIABLES DE LA VIVIENDA ****
			**********************************
			

************
***luz_ch***
************
gen luz_ch=0
replace luz_ch=1 if tipo_alumbrado==1 | tipo_alumbrado==2 | tipo_alumbrado==3 | tipo_alumbrado==6  //*2017, 6 es panel solar
* 2015, 05 modif LC se incorporó en valor cero opciones 4, y 5 que se refieren a gas, *2017, 7 a vela.
replace luz_ch=0 if tipo_alumbrado==99 | tipo_alumbrado==4 | tipo_alumbrado==5 | tipo_alumbrado==7
label var luz_ch  "La principal fuente de iluminación es electricidad"

****************
***luzmide_ch***
****************
gen luzmide_ch=.
label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

****************
***combust_ch***
****************
gen combust_ch=0
replace combust_ch=1 if combustible_para_cocinar==1 | combustible_para_cocinar==3 | combustible_para_cocinar==2
*2015, 5 se incorporó las opciones 4 (leña) y 5 (carbón)
replace combust_ch=0 if combustible_para_cocinar==99 | combustible_para_cocinar==4 | combustible_para_cocinar==5
label var combust_ch "Principal combustible gas o electricidad" 
	
************
**piso_ch***
************
gen piso_ch=1
replace piso_ch=0 if  material_piso==9 
replace piso_ch = 2 if material_piso==99
label var piso_ch "Materiales de construcción del material_piso"  
label def piso_ch 0"material_piso de tierra" 1"Materiales permanentes" 2"otros materiales"
label val piso_ch piso_ch


**************
***pared_ch***
**************
gen pared_ch=1 
replace pared_ch=0 if material_pared_exterior==3 | material_pared_exterior==11 | material_pared_exterior==12 | material_pared_exterior==13
replace pared_ch=2 if material_pared_exterior==99
label var pared_ch "Materiales de construcción de las paredes"
label def pared_ch 0"No permanentes" 1"Permanentes" 2"otros materiales"
label val pared_ch pared_ch

**************
***techo_ch***
**************
gen techo_ch=1
replace techo_ch=0 if material_techo==3 | material_techo==5
replace techo_ch=2 if material_techo==99
label var techo_ch "Materiales de construcción del material_techo"
label def techo_ch 0"No permanentes" 1"Permanentes" 2"otros materiales"
label val techo_ch techo_ch

**************
***resid_ch***
**************
gen resid_ch =0    if como_elimina_basura==1 | como_elimina_basura==2 | como_elimina_basura==3
replace resid_ch=1 if como_elimina_basura==4
replace resid_ch=2 if como_elimina_basura==5 | como_elimina_basura==6 | como_elimina_basura==7
replace resid_ch=3 if como_elimina_basura==99
label var resid_ch "Método de eliminación de residuos"
label def resid_ch 0"Recolección pública o privada" 1"Quemados o enterrados"
label def resid_ch 2"Tirados a un espacio abierto" 3"Otros", add
label val resid_ch resid_ch

*************
***dorm_ch***
*************
*Hay hogares que reportan no tener cuartos exclusivamente para dormir y cuentan con un solo espacio. Para estas 
*observaciones se cambia el 0 que tienen por 1. Porque aunque no sea exclusivo tienen un espacio para dormitorio
gen dorm_ch=cant_dormitorios_vivienda
replace dorm_ch=1 if cant_dormitorios_vivienda==0
label var dorm_ch "Habitaciones para dormir"

****************
***cuartos_ch***
****************
gen cuartos_ch=cant_cuartos_vivienda
label var cuartos_ch "Habitaciones en el hogar"
 
***************
***cocina_ch***
***************
gen cocina_ch=.
label var cocina_ch "Cuarto separado y exclusivo para cocinar"

**************
***telef_ch***
**************
gen telef_ch=0
replace telef_ch=1 if telefono==1
replace telef_ch=. if telefono==.
label var telef_ch "El hogar tiene servicio telefónico fijo"

***************
***refrig_ch***
***************
gen refrig_ch=0
replace refrig_ch=1 if  refrigerador==1
replace refrig_ch=. if  refrigerador==.
label var refrig_ch "El hogar posee refrigerador o heladera"

**************
***freez_ch***
**************
gen freez_ch=.
label var freez_ch "El hogar posee congelador"

*************
***auto_ch***
*************

gen auto_ch=0
replace auto_ch=1 if automovil==1
replace auto_ch=. if automovil==.
label var auto_ch "El hogar posee automovil particular"

**************
***compu_ch***
**************
gen compu_ch=0
replace compu_ch=1 if computador==1
replace compu_ch=. if computador==.
label var compu_ch "El hogar posee computador"

*****************
***internet_ch***
*****************
/* ¿Tiene usted o algún miembro de su hogar... internet?: 1-Sí, 2-No */
gen internet_ch=0
replace internet_ch=1 if internet==1
replace internet_ch=. if internet==.
label var internet_ch "El hogar posee conexión a Internet"

************
***cel_ch***
************
gen cel_ch=0
replace cel_ch=1 if celular==1
replace cel_ch=. if celular==.
label var cel_ch "El hogar tiene servicio telefonico celular"

**************
***vivi1_ch***
**************
gen vivi1_ch=1 if tipo_vivienda==1 | tipo_vivienda==2 | tipo_vivienda==3
replace vivi1_ch=2 if tipo_vivienda==4 | tipo_vivienda==5 
replace vivi1_ch=3 if tipo_vivienda==6 | tipo_vivienda==7 | tipo_vivienda==8 
replace vivi1_ch=. if tipo_vivienda==99
label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
label def vivi1_ch 1"Casa" 2"Departamento" 3"Otros"
label val vivi1_ch vivi1_ch

*************
***vivi2_ch***
*************
gen vivi2_ch=0
replace vivi2_ch=1 if vivi1_ch==1 | vivi1_ch==2
replace vivi2_ch=. if vivi1_ch==.
label var vivi2_ch "La vivienda es casa o departamento"

*****************
***viviprop_ch***
*****************
*2015, revisar herencia si no deberia ir como propia
gen viviprop_ch=0 if tenencia_vivienda==9
replace viviprop_ch=1 if tenencia_vivienda==1 | tenencia_vivienda==5
replace viviprop_ch=2 if tenencia_vivienda==2 | tenencia_vivienda==3
replace viviprop_ch=3 if tenencia_vivienda==4 | tenencia_vivienda==6 | tenencia_vivienda==7
replace viviprop_ch=. if tenencia_vivienda==8
label var viviprop_ch "Propiedad de la vivienda"
label def viviprop_ch 0"Alquilada" 1"Propia" 2"Propia en proceso de pago"
label def viviprop_ch 3"Ocupada (propia de facto)" 4"No se sabe la respuesta/ no hay respuesta", add
label val viviprop_ch viviprop_ch

****************
***vivitit_ch***
****************
gen vivitit_ch=.
label var vivitit_ch "El hogar posee un título de propiedad"

****************
***vivialq_ch***
****************
g monto_alquiler=(monto_alquiler_dolares_viv*49.58)+monto_alquiler_pesos_viv if tenencia_vivienda==9
gen vivialq_ch = . if tenencia_vivienda==9
replace vivialq_ch=monto_alquiler if periodo_pago_alquiler_viv==2
replace vivialq_ch=monto_alquiler*4.3   if periodo_pago_alq==1
replace vivialq_ch=monto_alquiler*2   if periodo_pago_alq==3
replace vivialq_ch=monto_alquiler/12  if periodo_pago_alq==4
replace vivialq_ch=. if monto_alquiler==0
label var vivialq_ch "Alquiler mensual"

*******************
***vivialqimp_ch***
*******************
gen vivialqimp_ch=monto_alquilaria_vivienda_mes
label var vivialqimp_ch "Alquiler mensual imputado"


		************************
		*** Variables de WASH **
		************************

****************
***aguared_ch***
****************
gen aguared_ch2 = (donde_proviene_agua==1 | donde_proviene_agua==2)
la var aguared_ch "Acceso a fuente de agua por red"

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0

*****************
*aguafuente_ch*
*****************
/*Del acueducto dentro de la vivienda........01
Del acueducto en el patio de la vivienda......02
De una llave de otra vivienda......................03 SIN DATOS EN LA BASE
De una llave pública.....................................04 SIN DATOS EN LA BASE
De un tubo de la calle...................................05
Manantial, río, arroyo.........06
Lluvia...............................07
Pozo.................................08
Camión tanque..................09
Otro.- (Especifique)..........99*/
gen aguafuente_ch = 1 if (donde_proviene_agua==1 | donde_proviene_agua==2)
replace aguafuente_ch = 2 if inlist(donde_proviene_agua,4,5)
replace aguafuente_ch = 5 if donde_proviene_agua==7
replace aguafuente_ch = 6 if donde_proviene_agua==9
replace aguafuente_ch = 8 if donde_proviene_agua==6
replace aguafuente_ch = 9 if donde_proviene_agua==3
replace aguafuente_ch = 10 if (donde_proviene_agua==8 | donde_proviene_agua==99 | missing(donde_proviene_agua))
*******
** nota
** Antes del 2023, se utilizaban las preguntas "donde_proviene_agua" por hogar para armonizar aguafuente_ch y "tiene_agua_red_publica" por vivienda para armonizar aguared_ch. Sin embargo, el proceso de calidad review-harmonization de los indicadores, revela que hay contradicciones. Por ejemplo, hay hogares que no tienen acceso a una fuente de agua por red (aguared_ch!=1), pero declaran que cuentan con red de distribución llave privada (aguafuente_ch ==1) .  La preguntas no se pensaron conjuntamente y eso trae dichas incosistencias. A partir del 2023, se decide armonizar aguared_ch y aguafuente_ch a partir de donde_proviene_agua.

*************
*aguadist_ch*
*************
gen aguadist_ch=0
replace aguadist_ch=1 if donde_proviene_agua==1
replace aguadist_ch=2 if donde_proviene_agua==2
replace aguadist_ch=3 if donde_proviene_agua==3|donde_proviene_agua== 4 

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =9

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9
*label var aguadisp2_ch "= 9 la encuesta no pregunta si el servicio de agua es constante"

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9
*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"

*************
*aguamala_ch* 
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10
*label var aguamala_ch "= 1 si la fuente de agua no es mejorada"

*****************
*aguamejorada_ch*  
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7
*label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"

*****************
***aguamide_ch***
*****************
gen aguamide_ch =.
label var aguamide_ch "Usan medidor para pagar consumo de agua"

*****************
*bano_ch         
*****************
gen bano_ch=.
replace bano_ch=0 if tipo_sanitario==5
replace bano_ch=1 if (tipo_sanitario==1 | tipo_sanitario==2) & se_encuentra_conectada_a==2
replace bano_ch=2 if (tipo_sanitario==1 | tipo_sanitario==2) & se_encuentra_conectada_a==1
replace bano_ch=6 if (tipo_sanitario==3 | tipo_sanitario==4)

***************
***banoex_ch***
***************
generate banoex_ch=9
replace banoex_ch= 1 if (tipo_sanitario==1 | tipo_sanitario==3)
replace banoex_ch= 0 if (tipo_sanitario==2 | tipo_sanitario==4)
la var banoex_ch "El servicio sanitario es exclusivo del hogar"

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if tipo_sanitario!=5

*****************
*banomejorado_ch*  
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6



		*****************************
		*** Variables de migración **
		*****************************

*******************
*** migrante_ci ***
*******************
gen migrante_ci=(pais_nacimiento!=647 & pais_nacimiento!=.)
label var migrante_ci "=1 si es migrante"
	
**********************
*** migrantiguo5_ci ***
**********************
gen migrantiguo5_ci=.
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
**********************
*** miglac_ci ***
**********************	
gen miglac_ci=(migrante_ci==1 & inlist(pais_nacimiento,63,77,83,88,97,105,169,196,211,239,242,317,325,341,345,391,493,580,586,589,770,810,845,850)) if migrante_ci!=.
replace miglac_ci = 0 if !inlist(pais_nacimiento,63,77,83,88,97,105,169,196,211,239,242,317,325,341,345,391,493,580,586,589,770,810,845,850) & migrante_ci==1
replace miglac_ci = . if migrante_ci==0 
label var miglac_ci "=1 si es migrante proveniente de un pais LAC"	
	
	
		**************************************
		*** Variables de protección social ***
		***** Variables SPH - PMTC y PNC *****
		**************************************

* PTMC:  Comer primero (ps_comer_es_p gob_comer_pri)
*		 Incentivo de asistencia escoalr (ps_incentivo_ gob_inc_asis_)
* 		 Bono de estudiante (bono_estudiante_progreso gob_bono_estu)
* PNC: 	 Apoyo de adultos mayores (gob_proteccio ps_apoyo_adul)
* 		 Bonos (ps_bono_luz ps_bono_gas gob_bono_luz_ gob_bonogas_h)

************************
*** nmienbros_sph_ch ***
************************

bys idh_ch: gen nmiembros_sph_ch=_N

********************
*** y_neto_pc_ch ***
********************

*ingreso neto mensualizado de transferencias publicas per capita
gen double yneto_pc_ch = (ytot_ch - ynlm_publico_ch) / nmiembros_sph_ch /*en validación SPL*/

********************
*** bene_cash_ch ***
********************

bys idh_ch: gen bene_cash_ch=1 if (gobierno!=0 & gobierno!=.) 
replace bene_cash_ch=0 if (gobierno==0 & gobierno!=.) 
label define bene_cash_ch 0"Hogar no beneficiario" 1"Hogar beneficiario" 

********************
*** pensionsub_ch ***
********************

bys idh_ch: egen pensionsub_ch= max(pensionsub_ci) 

/*

	
Esto no está en el manual de armonizaciones. como las variables de SPH aún están en construcción, no borro este contenido que figura en el 2022 y 2023. Puede que se usen los indicadores que aparecen acá en los nuevos indicadores
 
 
 
*************
*** y_hog ***
*************	
* Ingreso del hogar
egen ingreso_total = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
bys idh_ch: egen y_hog = sum(ingreso_total)

*************
*** y_pc  ***
*************	
gen y_pc     = y_hog / nmiembros_ch 

****************
*** ing_ptmc ***
****************
* Personas que reciben transferencias monetarias condicionadas
egen aux = rowtotal(gob_comer_primero_monto gob_inc_asis_escolar_monto ///
			gob_bono_estudiante_prog_monto),m
bys idh_ch: egen ing_ptmc = sum(aux)
replace ing_ptmc=. if y_hog==.
drop aux

*******************
*** ing_pension ***
*******************
bys idh_ch: egen ing_pension = sum(gob_proteccion_vejez_monto)
replace ing_pension=. if y_hog==.


***********************
*** percibe_ptmc_ci ***
***********************
* consultar a SPH. no está esta variable, la creé como missing
gen percibe_ptmc_ci =.

****************
*** ptmc_ch  ***
****************
gen ptmc_ci=(ps_comer_es_primero==1) | (ps_incentivo_asist_escolar==1) ///
| (bono_estudiante_progreso==1)
bys idh_ch: egen ptmc_ch=max(ptmc_ci)
lab def ptmc_ch 1 "Beneficiario PTMC" 0 "No beneficiario PTMC"
lab val ptmc_ch ptmc_ch

******************
*** mayor64_ci ***
******************
* Adultos mayores 
gen mayor64_ci=(edad>64 & edad!=.)

********************
*** pnc_elegible ***
********************
* consultar a SPH. no está esta variable, la creé como missing

**************
*** pnc_ci ***
**************
gen pnc_ci=(ps_apoyo_adultos_mayores==1 & mayor64_ci ==1)
lab def pnc_ci 1 "Beneficiario PNC" 0 "No beneficiario PNC"
lab val pnc_ci pnc_ci



*******************
*** benefdes_ci ***
*******************
g benefdes_ci=0 if desemp_ci==1
replace benefdes_ci=1 if  recibio_cesantia==1 & desemp_ci==1
label var benefdes_ci "=1 si tiene seguro de desempleo"

*******************
*** ybenefdes_ci***
*******************
*Encuesta no muestra monto de cesantía
*g ybenefdes_ci=monto_cesantia if benefdes_ci==1
*label var ybenefdes_ci "Monto de seguro de desempleo"

*  Pobres extremos, pobres moderados, vulnerables y no pobres 
* con base en ingreso neto (Sin transferencias)
* y líneas de pobreza internacionales
gen     grupo_int = 1 if (y_pc_net<lp31_2011)
replace grupo_int = 2 if (y_pc_net>=lp31_2011 & y_pc_net<(lp31_2011*1.6))
replace grupo_int = 3 if (y_pc_net>=(lp31_2011*1.6) & y_pc_net<(lp31_2011*4))
replace grupo_int = 4 if (y_pc_net>=(lp31_2011*4) & y_pc_net<.)

tab grupo_int, gen(gpo_ingneto)

* Crear interacción entre recibirla la PTMC y el gpo de ingreso
gen ptmc_ingneto1 = 0
replace ptmc_ingneto1 = 1 if ptmc_ch == 1 & gpo_ingneto1 == 1

gen ptmc_ingneto2 = 0
replace ptmc_ingneto2 = 1 if ptmc_ch == 1 & gpo_ingneto2 == 1

gen ptmc_ingneto3 = 0
replace ptmc_ingneto3 = 1 if ptmc_ch == 1 & gpo_ingneto3 == 1

gen ptmc_ingneto4 = 0
replace ptmc_ingneto4 = 1 if ptmc_ch == 1 & gpo_ingneto4 == 1

lab def grupo_int 1 "Pobre extremo" 2 "Pobre moderado" 3 "Vulnerable" 4 "No pobre"
lab val grupo_int grupo_int
*/


		***************************************
		*** Variables de referencia externa ***
		***************************************

*************
**salmm_ci***
*************
*2024: https://tss.gob.do/assets/reso01-2024.pdf
gen salmm_ci=19352.50
label var salmm_ci "Salario minimo legal"

*************************************
*lineas de pobreza internacionales***
*************************************
* se calculan luego en do. 

*********
*lp_ci***
*********
* 2024 : Líneas de pobreza monetaria general por persona https://mepyd.gob.do/publicaciones/boletin-de-estadisticas-oficiales-de-pobreza-monetaria-en-republica-dominicana-2024
gen lp_ci =.
replace lp_ci = 7890.9 
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********
* 2024 https://mepyd.gob.do/publicaciones/boletin-de-estadisticas-oficiales-de-pobreza-monetaria-en-republica-dominicana-2024
gen lpe_ci =.
replace lpe_ci =  3760.8
label var lpe_ci "Linea de pobreza extrema del pais"

************
** Otros ***
************
* se calculan luego en do. 


/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

*_____________________________________________________________________________________________________*

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
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci  /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch  ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  nmiembros_sph_ch yneto_pc_ch bene_cash_ch pensionsub_ch   /// Protección social 
          ynlm_publico_ch ynlm_privado_ch ynlm_privado_ci ynlm_publico_ci  /// Protección social ingresos
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa


compress
save "`base_out'", replace

log close

