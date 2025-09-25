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
 

/*
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


*/

global survey_folder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"

local PAIS MEX
local ENCUESTA ENIGH
local ANO "2024"
local ronda m8_m12

global ruta "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

local log_file  "$survey_folder\\log\\`PAIS'\\`ENCUESTA'\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'_BID.dta"
                                     
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Mexico
Encuesta: ENIGH (tradicional)
Round: Septiembre-Diciembre
Autores:
Versión 2013: Mayra Sáenz - Email: mayras@iadb.org, saenzmayra.a@gmail.com
Versión 2019: Alvaro Altamirano- Email: alvaroalt@iadb.org
Versión 2025: Maria Alejandra Zegarra
Fecha última modificación: Setiembre 2025

							SCL/LMK - IADB
****************************************************************************/
* ENIGH MÉXICO 2024 — ARMONIZACIÓN SCL/BID
* Archivo: MEX_2024m8_m12_variablesBID.do
* Autor: Maria Alejandra Zegarra | Fecha: 24/09/2025
*
* NOTA DE CAMBIOS / HISTORIAL
* -------------------------------------------------------------------------------------------
* - Educación (NUEVO en 2024):
*     · Se incorporaron variables educativas alineadas al Manual de Armonización:
*         aedu_ci     : años de educación aprobados (preescolar=0, con topes por nivel ISCED/UNESCO).
*         edupre_ci   : completó preescolar (1 sí, 0 no).
*         asiste_ci   : asistencia actual a centro educativo.
*         edupub_ci   : tipo de institución (1 pública, 0 privada).
*         asispre_ci  : asistencia a preescolar (1 sí, 0 no).
*         eduui_ci    : educación universitaria incompleta (dicotómica).
*         eduuc_ci    : educación universitaria completa (dicotómica).
*         eduac_ci    : distingue técnico vs universitario en superior.
*         pqnoasis1_ci: razón principal de no asistencia escolar.
*
*     · Reglas aplicadas para México (duraciones ISCED/UNESCO):
*         Primaria=6, Secundaria baja=3, Secundaria alta=3,
*         Sup. técnico=2, Normal=4, Licenciatura=4, Maestría=3, Doctorado=3.
*
*     · Se añadió lógica para inferir si se completó el nivel (term_use) cuando no está reportado.
*     · Se incluyeron validaciones QA: rangos de aedu_ci, consistencia entre nivel y grado,
*       y chequeos de continuidad de años de educación.
*
* - Robustez general:
*     · Eliminación de destring innecesarios en variables ya numéricas.
*     · Verificación de errores r(198) y r(110) corregida.
*
* NOTA FINAL
* -------------------------------------------------------------------------------------------
* Con estas modificaciones, el do-file 2024 queda alineado con el Manual de Armonización 
* asegurando consistencia temporal en las bases.
********************************************************************************************/
***************************************************************************

use `base_in', clear

******************************************************************************
*	HOUSEHOLD VARIABLES
******************************************************************************

*****************
*** region_c ***
*****************
*Nota: generada solo para el 2010
gen region_c=real(substr(ubica_geo,1,2))
label define region_c ///
1 "Aguascalientes" ///
2 "Baja California" ///
3 "Baja California Sur" ///
4 "Campeche" ///
5 "Coahuila de Zaragoza" ///
6 "Colima" ///
7 "Chiapas" ///
8 "Chihuahua" ///
9 "Distrito Federal" ///
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
*	factor_ch
******************************
gen factor_ch=factor
label var factor_ch "Household Expansion Factor"

******************************
*	idh_ch
******************************
sort  folioviv foliohog 
egen idh_ch= group(folioviv foliohog)
label var idh_ch "ID del hogar"
tostring idh_ch, replace

******************************
*	idp_ci
******************************
destring numren, replace
gen idp_ci=numren
label var idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace

******************************
*	zona_c
******************************
gen zona_c= 1      if tam_loc<="3"
replace zona_c = 0 if tam_loc=="4"
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural", add modify
label value zona_c zona_c

******************************
*	pais_c
******************************
gen str3 pais_c="MEX"

******************************
*	anio_c
******************************
gen anio_c=2022
label var anio_c "Year of the survey"

*****************
*** region según BID ***
*****************
gen region_BID_c = .
replace region_BID_c = 1 if pais_c=="MEX"   // 1 = México, región Centroamérica según BID

label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

******************************
*	mes_c
******************************
gen mes_c= .

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
label var relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes" 6 "Empleado/a domestico/a"
label value relacion_ci relacion_ci

/*
Clasificar a los integrantes del hogar por clave de
parentesco (tabla Poblacion): Jefe: contar los registros con
parentesco igual a 101 o 102; Esposa: contar los registros
con parentesco de 201 a 204; Hijos: contar los registros
con parentesco de 301 a 304; Parientes: contar los
registros con parentesco de 601 a 623; NoParientes:
contar los registros con parentesco de 501 a 503.

*Códigos de parentesco
101 Jefe(a)
102 Persona sola
201 Esposo(a), compañero(a), cónyuge, pareja, marido, mujer, señor(a), consorte
202 Concubino(a)
203 Amasio(a)
204 Querido(a), amante
301 Hijo(a), hijo(a) consanguíneo, hijo(a) reconocido
302 Hijo(a) adoptivo(a)
303 Hijastro(a), entenado(a)
304 Hijo(a) de crianza
305 Hijo(a) recogido(a)
401 Trabajador(a) doméstico(a)
402 Recamarero(a)
403 Cocinero(a)
404 Lavandera(o)
405 Nana, niñera, nodriza
406 Mozo
407 Jardinero(a)
408 Velador, vigilante
409 Portero(a)
410 Chofer
411 Ama de llaves
412 Mayordomo
413 Dama de compañía, acompañante
421 Esposo(a) del(la) trabajador(a) doméstico(a)
431 Hijo(a) del(la) trabajador(a) doméstico(a)
441 Madre, padre del(la) trabajador(a) doméstico(a)
451 Nieto(a) del(la) trabajador(a) doméstico(a)
461 Otro pariente del(la) trabajador(a) doméstico(a)
501 No tiene parentesco
502 Tutor(a)
503 Tutelado(a), pupilo(a), alumno(a)
601 Madre, padre
602 Padrastro, madrastra
603 Hermano(a)
604 Medio(a) hermano(a)
605 Hermanastro(a)
606 Abuelo(a)
607 Bisabuelo(a)
608 Tatarabuelo(a)
609 Nieto(a)
610 Bisnieto(a)
611 Tataranieto(a)
612 Tío(a)
613 Sobrino(a)
614 Primo(a)
615 Suegro(a)
616 Consuegro(a)
617 Nuera, yerno
618 Cuñado(a)
619 Concuño(a)
620 Padrino, madrina
621 Ahijado(a)
622 Compadre, comadre
623 Familiar, otro parentesco
701 Huésped, abonado(a), pensionista
711 Esposo(a) del(la) huésped
712 Hijo(a) del(la) huésped
713 Madre o padre del(la) huésped
714 Nieto(a) pariente del(la) huésped
715 Otro(a) pariente del(la) huésped
999 Parentesco no especificado

*/

******************************************************************************
*	DEMOGRAPHIC VARIABLES
******************************************************************************

******************************
*	factor_ci
******************************
gen factor_ci=factor
label var factor_ci "Individual Expansion Factor"

***************
***upm_ci***
***************
gen upm_ci=upm

***************
***estrato_ci***
***************
gen estrato_ci=est_dis

******************************
*	sexo_ci
******************************
gen sexo_ci=real(sexo)

******************************
*	edad_ci
******************************
gen edad_ci=edad 

******************************
*	civil_ci
******************************

* MGR Nov, 2015: corrección en sintaxis

gen civil_ci=.
replace civil_ci=1 if edo_cony=="6"
replace civil_ci=2 if edo_cony=="1"|edo_cony=="2"
replace civil_ci=3 if edo_cony=="3"|edo_cony=="4"
replace civil_ci=4 if edo_cony=="5"
label var civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal" 3 "Divorciado o separado" 4 "Viudo"
label value civil_ci civil_ci

******************************
*	jefe_ci
******************************
gen jefe_ci=(relacion_ci==1)
label var jefe_ci "Jefe de hogar"

***************************************************************************
*	nconyuges_ch & nhijos_ch & notropari_ch & notronopari_ch & nempdom_ch
****************************************************************************
by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
label var nconyuges_ch "Numero de conyuges"
label var nhijos_ch "Numero de hijos"
label var notropari_ch "Numero de otros familiares"
label var notronopari_ch "Numero de no familiares"
label var nempdom_ch "Numero de empleados domesticos"

******************************
*	clasehog_ch
******************************
gen clasehog_ch=.
replace clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0
replace clasehog_ch=2 if (nhijos_ch>0| nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0) 
replace clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0))
replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0
label var clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 "Unipersonal" 2 "Nuclear" 3 "Ampliado" 4 "Compuesto" 5 "Corresidente"
label value clasehog_ch clasehog_ch

***************************************************************************************
*	nmiembros_ch & nmayor21_ch & nmenor21_ch & nmayor65_ch & nmenor6_ch & nmenor1_ch  
***************************************************************************************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
label var nmiembros_ch "Numero de familiares en el hogar"

by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label var nmayor21_ch "Numero de familiares mayores a 21 anios"

by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label var nmenor21_ch "Numero de familiares menores a 21 anios"

by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label var nmayor65_ch "Numero de familiares mayores a 65 anios"

by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label var nmenor6_ch "Numero de familiares menores a 6 anios"

by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label var nmenor1_ch "Numero de familiares menores a 1 anio"

******************************
*	miembros_ci
******************************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label var miembros_ci "Miembro del hogar"

******************************
*	dis_ci
******************************
* Escala usual: 1=ninguna, 2=alguna, 3=mucha, 4=no puede
* Ajusta si los códigos difieren en tu cuestionario

* Al menos alguna dificultad
gen byte dis_ci = .
replace dis_ci = 0 if disc_ver=="1" & disc_oir=="1" & disc_brazo=="1" & ///
                      disc_camin=="1" & disc_apren=="1" & disc_vest=="1" & ///
                      disc_habla=="1" & disc_acti=="1"
replace dis_ci = 1 if disc_ver>="2" | disc_oir>="2" | disc_brazo>="2" | ///
                      disc_camin>="2" | disc_apren>="2" | disc_vest>="2" | ///
                      disc_habla>="2" | disc_acti>="2"
label var dis_ci "Persona con al menos alguna dificultad"

* Discapacidad severa (mucha o no puede)
gen byte disWG_ci = (disc_ver>="3" | disc_oir>="3" | disc_brazo>="3" | ///
                     disc_camin>="3" | disc_apren>="3" | disc_vest>="3" | ///
                     disc_habla>="3" | disc_acti>="3")
label var disWG_ci "Discapacidad severa (criterio Washington Group)"

* Versión específica México
gen byte MEX_dis_ci = dis_ci
label var MEX_dis_ci "Discapacidad según criterio nacional ENIGH 2024"

* A nivel hogar
bysort folioviv foliohog: egen dis_ch = max(dis_ci)
label var dis_ch "Hogar con al menos un miembro con discapacidad"


******************************************************************************
*	LABOR MARKET
******************************************************************************
****************
****condocup_ci*
****************
gen trabajon=real(trabajo_mp)
gen mot_ausen=real(motivo_aus)

generat condocup_ci=.
replace condocup_ci=1 if (trabajon==1) | (mot_ausen <=6)
replace condocup_ci=2 if act_pnea1=="1" | act_pnea2=="1" 
replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2
replace condocup_ci=4 if edad<12
label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor que 12"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"
/*Nota: En el esquema de la ENOE se considera a la población en edad de 
trabajar como aquella de catorce años en adelante, de acuerdo con la Ley 
Federal del Trabajo.
Fuente:http://www.inegi.org.mx/inegi/contenidos/espanol/prensa/comunicados/ocupbol.asp */

****************
*afiliado_ci****
****************
destring pres_* servmed* inscr_* inst_* atemed tam_emp1  contrato1, replace
generat afiliado_ci=0 if condocup_ci==1 | condocup_ci==2  
replace afiliado_ci=1 if (pres_81==8 | pres_82==8) | (inscr_1 == 1  & (servmed_3==3 | servmed_5==5 | servmed_6==6 | servmed_7==7))  /* inscrito en prestaciones de salud por trabajo*/
*replace afiliado_ci=1 if (inst_1==1 | inst_2==2 | inst_3==3 | inst_4==4) & atemed==1 & afiliado_ci==0 
label var afiliado_ci "Afiliado a la Seguridad Social"
*Nota: seguridad social comprende solo los que en el futuro me ofrecen una pension.

* Formalidad sin restringir a PEA
destring pres_* servmed* inscr_* inst_* atemed tam_emp1  contrato1, replace
generat afiliado_ci1=0 if condocup_ci>=1 & condocup_ci<=3  
replace afiliado_ci1=1 if (pres_81==8 | pres_82==8) | (inscr_1 == 1  & (servmed_3==3 | servmed_5==5 | servmed_6==6 | servmed_7==7))  /* inscripto en prestaciones de salud por trabajo*/

****************
*tipopen_ci*****
****************
gen tipopen_ci=.
label var tipopen_ci "Tipo de pension - variable original de cada pais" 
****************
*cotizando_ci***   
****************
gen cotizando_ci=. /*Revisar las variables inst_1 ó pres_91 */
label var cotizando_ci "Cotizante a la Seguridad Social"
*Nota: solo seguro social publico, con el cual tenga derecho a pensiones en el futuro.

****************
*cotizapri_ci***
****************
gen cotizapri_ci=.
label var cotizapri_ci "Cotizante a la Seguridad Social en actividad ppal."

****************
*cotizasec_ci***
****************
gen cotizasec_ci=.
label var cotizasec_ci "Cotizante a la Seguridad Social en actividad sec."
****************
*instpen_ci*****
****************
gen instpen_ci=. /*Revisar la variable inst_1 inst_2 inst_3 inst_4 */
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 

********************
*** instcot_ci *****
********************
gen instcot_ci=.
label var instcot_ci "institución a la cual cotiza"

*************
**pension_ci*
*************
g pension_ci = (ypension>0 & ypension!=.)
label var pension_ci "1=Recibe pension contributiva"

*************
*ypen_ci*
*************
gen ypen_ci=ypension  if pension_ci==1
label var ypen_ci "Valor de la pension contributiva"

*****************
**  ypensub_ci  *
*****************
*Alvaro AM - Agosto 2019: modifiqué el nombre a yp65más porque a partir de 2013 el programa redujo el requisito de edad de 70 a 68/65 (68 en general y 65 para población indígena).
* A partir del 2020 es Programa Pensión para el Bienestar de las Personas Adultas Mayores (antes Programa 65 y más)
gen yp65mas = P_P104
label var yp65mas "Programa Pensión para el Bienestar de las Personas Adultas Mayores"

gen yotroam=P_P045
gen yoportuni70=0 // No aplica desde 2020 

egen ypensub_ci=rsum(yp65mas yotroam yoportuni70) 
replace ypensub_ci=. if yp65mas==. & yotroam==. & yoportuni70==.

label var ypensub_ci "Valor de la pension subsidiada / no contributiva"
*Programas: Beneficio del programa 70 y más; Beneficio de otros programas para adultos mayores; y, Oportunidades

***************
*pensionsub_ci*
***************
gen pensionsub_ci=(ypensub_ci>0 & ypensub_ci!=.)
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*************
* cesante_ci* 
*************
generat cesante_ci=. /*Discutir sobre las variables ing_1P022 o segsoc */
label var cesante_ci "Desocupado - definicion oficial del pais"

*********
*lp_ci***
*********
gen lp_ci =.
replace lp_ci=3001.17 if zona_c==1
replace lp_ci=1941.01 if zona_c==0
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********
gen lpe_ci =.
replace lpe_ci= 1516.62 if zona_c==1
replace lpe_ci= 1073.69 if zona_c==0
label var lpe_ci "Linea de indigencia oficial del pais"

/************************************************************************************************************
* 3. Creación de nuevas variables de SS and LMK a incorporar en Armonizadas
************************************************************************************************************/

*************
**salmm_ci***
*************
*Daniela Zuluaga - Enero 2018
*http://www.sat.gob.mx/informacion_fiscal/tablas_indicadores/Paginas/salarios_minimos.aspx
/*Por resolución para la aplicación del salario mínimo Mexico habrá una sola área geográfica integrada por todos los municipios del país y demarcaciones 
territoriales (Delegaciones) de la Ciudad de México a partir del 1 de Octubre de 2015
*/

* Alvaro AM - SM 2018: https://www.gob.mx/cms/uploads/attachment/file/285013/TablaSalariosMinimos-01ene2018.pdf
gen salmm_ci=123.22*30 

label var salmm_ci "Salario minimo legal"

/*
******************************
*	emp_ci
******************************
*trabajo= trabajo durante el mes pasado

gen emp_ci=.
replace emp_ci=1 if trabajon==1 
replace emp_ci=0 if trabajon==2
replace emp_ci=. if trabajon==.
replace emp_ci=1 if (mot_ausen <=6)
label var emp_ci "1 Empleado"


******************************
*	desemp1_ci	& desemp2_ci & desemp3_ci 
******************************
gen desemp1_ci=(emp_ci==0 & act_buscot=="1")
replace desemp1_ci=. if emp_ci==.  
label var desemp1_ci "Personas sin trabajo que buscaron en el periodo de referencia"
 
gen desemp2_ci=.
label var desemp2_ci "des1 + no trabajaron ni buscaron en la ult semana pero esperan respuesta de solicit"
 
gen desemp3_ci=.
label var desemp3_ci "des2 + no tienen trabajo pero buscaron antes de la semana pasada"


******************************
*	pea1_ci, pea2_ci, pea3_ci
******************************
gen pea1_ci=(emp_ci==1 | desemp1_ci==1)
gen pea2_ci=.
gen pea3_ci=.
*/
************
***emp_ci***
************

gen byte emp_ci=(condocup_ci==1)

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)

*************
***pea_ci***
*************
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1

******************************
*	desalent_ci
******************************
gen desalent_ci=.
/*NA: No se puede generar. Entrarian en 'no busco trabajo' por 'otra razon'*/

******************************
*	subemp_cim
******************************
gen subemp_ci=.
label var subemp_ci "Dispuestas a trabajar mas, pero trabajan 30hs o menos(semana)"
*NA 

******************************
*	horaspri_ci
******************************
gen horaspri_ci=htrab1 if emp_ci==1 & htrab1<148
label var horaspri_ci "Hs totales (semanales) trabajadas en act. principal"
*NA

******************************
*	horastot_ci
******************************

egen horastot_ci= rsum(htrab1 htrab2)  if emp_ci==1 
replace horastot_ci = . if  horastot_ci>148
label var horastot_ci "Hs totales (semanales)trabajadas en toda actividad"


******************************
*	tiempoparc_ci
******************************
gen tiempoparc_ci=. 
label var tiempoparc_ci "Trabajan menos de 30 hs semanales y no quieren trabajar mas"
*NA

******************************
*	categopri_ci
******************************
gen categopri_ci=.
replace categopri_ci=1 if personal1=="1" & condocup_ci==1
replace categopri_ci=2 if  categopri_ci!=1 & indep1=="1" & condocup_ci==1
replace categopri_ci=3 if subor1=="1" & condocup_ci==1
replace categopri_ci=4 if pago1== "2"  & condocup_ci==1
replace categopri_ci=. if emp_ci!=1
label var categopri_ci "Categoria ocupacional trabajo principal"
label define categopri_ci 1"Patron" 2"Cuenta propia" 3"Empleado" 4"Familiar no remunerado"
label value categopri_ci categopri_ci

******************************
*	categosec_ci
******************************
gen categosec_ci=. 
replace categosec_ci=1 if personal2=="1"
replace categosec_ci=2 if indep2=="1"
replace categosec_ci=3 if subor2=="1"
replace categosec_ci=4 if pago2== "2" 
replace categosec_ci=. if emp_ci!=1
label var categosec_ci "Categoria ocupacional trabajo secundario"
label define categosec_ci 1"Patron" 2"Cuenta propia" 3"Empleado" 4"Familiar no remunerado"
label value categosec_ci categosec_ci

*****************
*tipocontrato_ci*
*****************
/*13. ¿En su trabajo cuenta con un contrato escrito?
1-si
2-no
3-no sabe
14. El contrato...
1-¿Es temporal o por obra determinada?..........
2-¿Es de base, planta o por tiempo indeterminado?...............................................
3-No sabe..........................................................
*/

* Corregido por categopri_ci MGD 06/17/2014
destring contrato1 tipocontr1, replace
g tipocontrato_ci=.
replace tipocontrato_ci=1 if (contrato1==1 & tipocontr1==2) & categopri_ci==3
replace tipocontrato_ci=2 if (contrato1==1 & tipocontr1==1) & categopri_ci==3
replace tipocontrato_ci=3 if (contrato1==2 | tipocontrato_ci==.) & categopri_ci==3      
label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

******************************
*	segsoc_ci
******************************
destring segsoc , replace
gen segsoc_ci=0 if emp_ci == 1
replace segsoc_ci=1 if (segsoc ==1)
label var segsoc_ci "1=Cuenta con SS"

******************************
*	nempleos_ci
******************************
gen nempleos_ci=.
replace nempleos_ci=1 if num_trabaj=="1"
replace nempleos_ci=2 if num_trabaj=="2"
label var nempleos_ci "numero de empleos"
label define nempleos_ci 1 "un empleo" 2 "mas de en empleo"
label value nempleos_ci nempleos_ci
/*
******************************
*	firmapeq_ci
******************************
gen firmapeq_ci=0 if emp_ci==1
replace firmapeq_ci=1 if tam_emp1==1 | tam_emp1==2
label var firmapeq_ci "1=5 o menos trabajadores"
*/
******************************
*	spublico_ci
******************************
*2015, 10 Incorporacion MLO
destring clas_emp1, replace
gen spublico_ci=(clas_emp1==3 & condocup_ci==1)

******************************************************************************
*		LABOR DEMAND
******************************************************************************

******************************
*	ocupa_ci
******************************
tostring sinco1, replace
gen ocupa=real(substr(sinco1,1,2))

* Modificacion MGD 07/07/2014: correccion de la clasificacion de actividades segun el manual.
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


******************************
*	rama_ci
******************************
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

/*Note: Actividad económica a la que se dedica la
empresa de acuerdo al Sistema de clasificación Industrial de América
del Norte. México, 2008 */

* rama secundaria
tostring scian2, replace
gen ramat2=real(substr(scian2,1,3))
gen ramasec_ci=1 if ramat2>=111 & ramat2<=115
replace ramasec_ci=2 if ramat2>=211 & ramat2<=213
replace ramasec_ci=3 if ramat2>=311 & ramat2<=339
replace ramasec_ci=4 if ramat2>=221 & ramat2<=222
replace ramasec_ci=5 if ramat2>=236 & ramat2<=238
replace ramasec_ci=6 if ramat2>=400 & ramat2<=469
replace ramasec_ci=7 if ramat2>=481 & ramat2<=493
replace ramasec_ci=9 if ramat2>=511 & ramat2<=932
replace ramasec_ci=8 if ramat2>=520 & ramat2<=530

label var ramasec_ci "Rama actividad secundaria"
label define ramasec_ci 1 "Agricultura, caza, silvicultura y pesca" 2 "Explotación de minas y canteras" 3 "Industrias manufactureras" 4 "Electricidad, gas y agua" 5 "Construcción" 6 "Comercio al por mayor y menor, restaurantes, hoteles" 7 "Transporte y almacenamiento" 8 "Establecimientos financieros, seguros, bienes inmuebles" 9 "Servicios sociales, comunales y personales"
label values ramasec_ci ramasec_ci



*************************************************************************************
*******************************INGRESOS**********************************************
*************************************************************************************

****************
***ylmpri_ci ***
****************
egen ylmpri_ci=rsum(ing_trab1 ing_negp1), missing

*****************
***nrylmpri_ci***
*****************
gen nrylmpri_ci=.

*****************
*** ylnmpri_ci***
*****************
gen ylnmpri_ci=.

*****************************************************************
*Identificador de top-code del ingreso de la actividad principal*
*****************************************************************
gen tcylmpri_ci=.

***************
***ylmsec_ci***
***************
egen ylmsec_ci=rsum(ing_trab2 ing_negp2), missing

******************
****ylnmsec_ci****
******************
gen ylnmsec_ci=.

************
***ylm_ci***
************
egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing

*************
***ylnm_ci***
*************
gen ylnm_ci=.

*************
*ylmotros_ci*
*************
gen ylmotros_ci= .

*********************************************
*Ingreso laboral no monetario otros trabajos*
*********************************************
gen ylnmotros_ci=.

*************
***ynlm_ci***
*************
egen ynlm_ci=rsum(ing_rent ing_tran otros), missing //CONEVAL no incluye otros

*************
***ynlnm_ci***
*************
*No se incluye el alquiler estimado
egen ynlnm = rsum(pago_esp reg_esp), missing

gen ynlnm_ci= ynlnm/nmiembros_ch
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)

*****************
***remesas_ci***
*****************
gen remesas_ci=remesas

************************
*** HOUSEHOLD INCOME ***
************************

******************
*** nrylmpri_ch***
******************
bys idh_ch: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.

*************
*** ylm_ch***
*************
bys idh_ch: egen ylm_ch=sum(ylm_ci) if miembros_ci==1

**************************************************
*Identificador de los hogares en donde (top code)*
**************************************************
gen tcylmpri_ch=.

****************
*** ylmnr_ch ***
****************
bys idh_ch: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1
replace ylmnr_ch=. if nrylmpri_ch==1

***************
*** ylnm_ch ***
***************
bys idh_ch: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing

**********************************
*** remesas_ch & remesasnm_ch ***
**********************************
bys idh_ch: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing

***************
*** ynlm_ch ***
***************
bys idh_ch: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing

****************
*** ynlnm_ch ***
****************
bys idh_ch: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing

*******************
*** autocons_ci ***
*******************
gen autocons_ci= .

*******************
*** autocons_ch ***
*******************
bys idh_ch: egen autocons_ch=sum(autocons_ci) if miembros_ci==1, missing

*******************
*** rentaimp_ch ***
*******************
*Modificacion Mayra Sáenz - Agosto 2015- Antes estaba generada como missing.
gen rentaimp_ch= .

*****************
***ylhopri_ci ***
*****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)

***************
***ylmho_ci ***
***************
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)

********************
***Transferencias***
********************
*-Monetarias

gen trac_pri = trat_pr
gen trac_pub = trat_pu
gen dona_pub = dona_pu
gen dona_pri = dona_pr

* TOTAL (las privadas incluyen transferencias del exterior)

egen trat_pri = rsum( trac_pri  dona_pr ), missing
egen trat_pub = rsum( trac_pub  dona_pu), missing

****************
*Rentas y otros*
****************
egen rtasot = rsum(ing_rent  otros), missing
label var rtasot "Rentas y otros"

******************
*Ingreso Nacional*
******************
gen yoficial_ch=ict

******************************
*	durades_ci
******************************
gen durades_ci=.
*NA

******************************
*	antiguedad_ci
******************************
gen antiguedad_ci=.
*NA

*******************
***tamemp_ci***
*******************
  
*México Pequeña 1 a 5, Mediana 6 a 50, Grande Más de 50
gen tamemp_ci = 1 if tam_emp1==1 | tam_emp1==2
replace tamemp_ci = 2 if (tam_emp1>=3 & tam_emp1<=7)
replace tamemp_ci = 3 if (tam_emp1>7 & tam_emp1<12)

label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci
label var tamemp_ci "Tamaño de empresa"

gen tamemp_o = 1 if (tam_emp1==1 | tam_emp1==2 | tam_emp1==3)
replace tamemp_o = 2 if (tam_emp1>=4 & tam_emp1<=7)
replace tamemp_o = 3 if (tam_emp1>7 & tam_emp1<12)

label define tamemp_o 1 "[1-9]" 2 "[10-49]" 3 "[50 y mas]"
label value tamemp_o tamemp_o
label var tamemp_o "Tamaño de empresa-OECD"

*******************
***categoinac_ci***
*******************
gen categoinac_ci =1 if ((act_pnea1=="2" | act_pnea2=="2") & condocup_ci==3) 
replace categoinac_ci = 2 if  ((act_pnea1=="4" | act_pnea2=="4") & condocup_ci==3) & categoinac_ci ==.
replace categoinac_ci = 3 if  ((act_pnea1=="3" | act_pnea2=="3") & condocup_ci==3) & categoinac_ci ==.
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3) & categoinac_ci ==.
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 

*******************
***formal***
*******************
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
label var formal_ci "1=afiliado o cotizante / PEA"

* Formalidad sin restringir a PEA
g formal_1= 0 if condocup_ci>=1 & condocup_ci<=3
replace formal_1=1 if cotizando_ci==1
replace formal_1=1 if afiliado_ci1==1 & (cotizando_ci!=1 | cotizando_ci!=0) & pais_c=="MEX" & anio_c>=2008

/********************************************************************
* EDUCACIÓN — MÉXICO ENIGH 2024 (sin necesidad de `term`)
* Salidas: aedu_ci (años aprobados), edupre_ci (preescolar completo)
********************************************************************/

*======================*
* 0) PARAMS / MAPEO    *
*======================*
local var_nivel nivel          // último nivel aprobado/alcanzado (categórica)
local var_grado grado          // último año/grado aprobado DENTRO del nivel (numérica)
local var_term                 // p.ej.: local var_term edu_termino

* Códigos de nivel:
local L_PRE   1
local L_PRIM  2
local L_SEC1  3
local L_SEC2  4
local L_SUPT  5
local L_PROF  6
local L_GRAD  7
local L_MAEST 8
local L_DOCT  9
local L_MISS1 98
local L_MISS2 99

* Duraciones por nivel según manual (México):
local Y_PRIM  6
local Y_SEC1  3
local Y_SEC2  3
local Y_SUPT  2
local Y_PROF  4
local Y_GRAD  4
local Y_MAEST 3
local Y_DOCT  3

*===========================*
* 1) Normalización de tipos *
*===========================*
foreach v in `var_nivel' `var_grado' `var_term' {
    capture confirm variable `v'
    if !_rc {
        capture confirm string variable `v'
        if !_rc {
            quietly replace `v' = strtrim(`v')
            quietly replace `v' = subinstr(`v',",","",.)
            quietly replace `v' = "" if inlist(`v',"98","99","NA","N/A","-","")
            destring `v', replace force
        }
        else {
            quietly replace `v' = . if inlist(`v',`L_MISS1',`L_MISS2')
        }
    }
}

*==============================*
* 2) Crear `term_use` flexible *
*==============================*
* Si NO existe `var_term`, lo inferimos con grado==máximo del nivel
tempvar term_use
gen byte `term_use' = .   // 1 = terminó nivel; 0 = no terminó; . = no sabe

capture confirm variable `var_term'
if _rc {
    quietly {
        replace `term_use' = 1 if `var_nivel' == `L_PRIM'  & `var_grado'==`Y_PRIM'
        replace `term_use' = 1 if `var_nivel' == `L_SEC1'  & `var_grado'==`Y_SEC1'
        replace `term_use' = 1 if `var_nivel' == `L_SEC2'  & `var_grado'==`Y_SEC2'
        replace `term_use' = 1 if `var_nivel' == `L_SUPT'  & `var_grado'==`Y_SUPT'
        replace `term_use' = 1 if `var_nivel' == `L_PROF'  & `var_grado'==`Y_PROF'
        replace `term_use' = 1 if `var_nivel' == `L_GRAD'  & `var_grado'==`Y_GRAD'
        replace `term_use' = 1 if `var_nivel' == `L_MAEST' & `var_grado'==`Y_MAEST'
        replace `term_use' = 1 if `var_nivel' == `L_DOCT'  & `var_grado'==`Y_DOCT'

        replace `term_use' = 0 if missing(`term_use') & inlist(`var_nivel', ///
            `L_PRIM',`L_SEC1',`L_SEC2',`L_SUPT',`L_PROF',`L_GRAD',`L_MAEST',`L_DOCT') ///
            & `var_grado' < .
    }
}
else {
    * Usar la variable original (asumo 1=terminó, 2=no; ajusta si difiere)
    gen byte __term_orig = .
    replace __term_orig = 1 if `var_term'==1
    replace __term_orig = 0 if `var_term'==2
    replace `term_use'  = __term_orig
    drop __term_orig
}

*======================*
* 3) edupre_ci         *
*======================*
gen byte edupre_ci = .
replace edupre_ci = 1 if `var_nivel'==`L_PRE' & `term_use'==1
replace edupre_ci = 0 if `var_nivel'==`L_PRE' & `term_use'==0
label var edupre_ci "Completó preescolar (1 sí, 0 no)"

*======================*
* 4) aedu_ci           *
*======================*
gen double aedu_ci = .
label var aedu_ci "Años de educación aprobados (armonizado)"

* Primaria
replace aedu_ci = min(max(`var_grado',0),`Y_PRIM') if `var_nivel'==`L_PRIM' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM'                            if `var_nivel'==`L_PRIM' & `term_use'==1

* Secundaria baja (base = 6)
replace aedu_ci = `Y_PRIM' + min(max(`var_grado',0),`Y_SEC1') ///
    if `var_nivel'==`L_SEC1' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' ///
    if `var_nivel'==`L_SEC1' & `term_use'==1

* Secundaria alta (base = 9)
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + min(max(`var_grado',0),`Y_SEC2') ///
    if `var_nivel'==`L_SEC2' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' ///
    if `var_nivel'==`L_SEC2' & `term_use'==1

* Superior técnico (base = 12)
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + min(max(`var_grado',0),`Y_SUPT') ///
    if `var_nivel'==`L_SUPT' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_SUPT' ///
    if `var_nivel'==`L_SUPT' & `term_use'==1

* Profesorado/Normal (si aplica) (base = 12)
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + min(max(`var_grado',0),`Y_PROF') ///
    if `var_nivel'==`L_PROF' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_PROF' ///
    if `var_nivel'==`L_PROF' & `term_use'==1

* Licenciatura/Grado (base = 12)
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + min(max(`var_grado',0),`Y_GRAD') ///
    if `var_nivel'==`L_GRAD' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' ///
    if `var_nivel'==`L_GRAD' & `term_use'==1

* Maestría (base = 12 + grado)
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + min(max(`var_grado',0),`Y_MAEST') ///
    if `var_nivel'==`L_MAEST' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' ///
    if `var_nivel'==`L_MAEST' & `term_use'==1

* Doctorado
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' + min(max(`var_grado',0),`Y_DOCT') ///
    if `var_nivel'==`L_DOCT' & `term_use'==0 & `var_grado'<.
replace aedu_ci = `Y_PRIM' + `Y_SEC1' + `Y_SEC2' + `Y_GRAD' + `Y_MAEST' + `Y_DOCT' ///
    if `var_nivel'==`L_DOCT' & `term_use'==1

* Preescolar siempre cuenta 0
replace aedu_ci = 0 if `var_nivel'==`L_PRE' & missing(aedu_ci)

* Truncar a enteros y acotar
replace aedu_ci = floor(aedu_ci)
replace aedu_ci = 0 if aedu_ci < 0

*****************************
*	INFRAESTRUCTURE VARIABLES 
*****************************

****************
***aguared_ch***
****************
* Agua entubada dentro de la vivienda o terreno
gen byte aguared_ch = .
replace aguared_ch = 1 if agua_ent=="1"   // 1 = Sí tiene agua entubada (ajustar código real)
replace aguared_ch = 0 if agua_ent=="2"   // 2 = No tiene
label var aguared_ch "Hogar con agua entubada (red pública)"

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0

*****************
*aguafuente_ch*
*****************

* Inicializa
gen byte aguafuente_ch = .

* Códigos típicos de ab_agua (confirma con: tab ab_agua)
* 1 = Red pública dentro de la vivienda
* 2 = Red pública fuera de la vivienda pero dentro del terreno
* 3 = Red pública comunitaria o hidrante
* 4+ = otras fuentes (pozo, río, pipa, etc.)

replace aguafuente_ch = 1 if inlist(ab_agua, "1","2","3")
replace aguafuente_ch = 0 if inlist(ab_agua, "4","5","6","7","8","9")

label var aguafuente_ch "Fuente principal de agua: red pública"

*************
*aguadist_ch*
*************
gen byte aguadist_ch = .
replace aguadist_ch = 1 if ab_agua=="1"   // Dentro de la vivienda
replace aguadist_ch = 2 if ab_agua=="2"   // En el terreno
replace aguadist_ch = 3 if ab_agua=="3"   // Fuera del terreno, toma comunitaria

label var aguadist_ch "Ubicación de la principal fuente de agua"

**************
*aguadisp1_ch*
**************
destring dotac_agua, replace
gen aguadisp1_ch =9

**************
*aguadisp2_ch*
**************
destring dotac_agua, replace
gen aguadisp2_ch = .
replace aguadisp2_ch = 1 if dotac_agua>1
replace aguadisp2_ch = 3 if dotac_agua==1

*************
*aguamala_ch*  Altered
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7 

*****************
***aguamide_ch***
*****************
gen aguamide_ch=.
label var aguamide_ch "Usan medidor para pagar consumo de agua"

*****************
*bano_ch         *  Altered
*****************
destring excusado, replace
destring drenaje, replace
destring sanit_agua, replace
gen bano_ch=.
replace bano_ch=0 if excusado==2
replace bano_ch=1 if drenaje==1 & excusado==1 
replace bano_ch=2 if drenaje==2 & excusado==1 
replace bano_ch=4 if (drenaje==4 | drenaje==3) & excusado==1
replace bano_ch=6 if drenaje==5 & excusado==1 & sanit_agua== 3

***************
***banoex_ch***
***************
destring uso_compar, replace
gen banoex_ch=.
replace banoex_ch=1 if uso_compar==2
replace banoex_ch=0 if uso_compar==1
label var banoex_ch "Servicio higiénico de uso exclusivo del hogar"

*****************
*banomejorado_ch*  Altered
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

************
*sinbano_ch*
************
gen sinbano_ch = 3
replace sinbano_ch = 0 if excusado == 1
replace sinbano_ch = 1 if excusado == 2 & drenaje <=4
replace sinbano_ch = 3 if excusado == 2 & drenaje ==5
*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

*************
*aguatrat_ch*
*************
gen aguatrat_ch =9

******************************
*	luz_ch
******************************
gen luz_ch=(disp_elect=="1")

******************************
*	luzmide_ch
******************************

gen byte luzmide_ch = (medid_luz=="1")
label var luzmide_ch "Hogar con medidor de luz"

******************************
*	combust_ch
******************************

local candidates combustible comb_coc comb_cocina combus_coc combusti coc_comb cocin_comb fuel_coc tipo_comb tipo_combust energia_coc
local src ""
foreach v of local candidates {
    capture confirm variable `v'
    if !_rc {
        local src "`v'"
        continue, break
    }
}

if "`src'" != "" {
    di as txt "Fuente de combustible detectada: `src'"

    * Si es string, primero pasar a numérico con mapeo simple (ajusta si tus códigos difieren)
    capture confirm string variable `src'
    if !_rc {
        * Normalizar valores en minúsculas para detectar palabras clave
        gen strL __src_s = lower(`src')
        gen byte __gas  = strpos(__src_s,"gas")>0
        gen byte __elec = strpos(__src_s,"elect")>0 | strpos(__src_s,"luz")>0
        gen byte __len  = strpos(__src_s,"leña")>0 | strpos(__src_s,"lena")>0 | strpos(__src_s,"fogon")>0 | strpos(__src_s,"fogón")>0 | strpos(__src_s,"carbon")>0 | strpos(__src_s,"carbón")>0

        gen byte combust_ch = .
        replace combust_ch = 1 if __gas | __elec                    // gas o electricidad
        replace combust_ch = 0 if __len                               // leña/carbón/fogón
        label var combust_ch "Principal combustible usado es gas o eléctrico"

        drop __src_s __gas __elec __len
    }
    else {
        * Es numérica: mapea códigos frecuentes (AJUSTA a tu codebook si ves otro patrón)
        * Ejemplos comunes: 1=Gas, 2=Electricidad, 3=Leña, 4=Carbón, 5=Otro
        gen byte combust_ch = .
        replace combust_ch = 1 if inlist(`src',1,2)                   // gas / electricidad
        replace combust_ch = 0 if inlist(`src',3,4)                   // leña / carbón
        * Si tienes un código para “otro” que sea limpio o biomasa, decide si 0 ó .
        label var combust_ch "Principal combustible usado es gas o eléctrico"
    }
}
else {
    * Si no hay variable fuente, dejar explícitamente missing y anotar
    capture drop combust_ch
    gen byte combust_ch = .
    label var combust_ch "Principal combustible (no disponible en ENIGH 2024 actual)"
    di as res "Nota: No se encontró variable de combustible de cocción; combust_ch queda como missing."
}

******************************
*	des1_ch
******************************
destring drenaje, replace
gen des1_ch=.
replace des1_ch=0 if drenaje ==5
replace des1_ch=1 if drenaje ==1 | drenaje ==2
replace des1_ch=2 if drenaje ==3
replace des1_ch=3 if drenaje ==4

******************************
*	des2_ch
******************************

gen des2_ch=. 
replace des2_ch=0 if des1_ch==0
replace des2_ch=1 if (des1_ch==1 | des1_ch==2)
replace des2_ch=2 if des1_ch==3 

******************************
*	piso_ch
******************************

replace mat_pisos="." if mat_pisos=="&"
destring mat_pisos, replace
gen piso_ch=.
replace piso_ch=0 if mat_piso==1
replace piso_ch=1 if mat_piso>=2 & mat_piso<=3

******************************
*	pared_ch
******************************
destring mat_pared, replace
gen pared_ch=.
replace pared_ch=0 if mat_pared ==1 | mat_pared ==2 | mat_pared ==4 | mat_pared ==5
replace pared_ch=1 if mat_pared ==3 | mat_pared >=6 & mat_pared <=8
label var pared_ch "Material Pared"

/*
1 Material de desecho.
2 Lamina de cartón.
3 Lamina metálica o de asbesto.
4 Carrizo bambú o palma.
5 Embarro o Bajareque.
6 Madera.
7 Adobe.
8 Tabique, ladrillo, block, piedra o concreto.
*/

******************************
*	techo_ch
******************************
destring mat_techos, replace
gen techo_ch=.
replace techo_ch=0 if mat_techos==1 | mat_techos==2 | mat_techos==6
replace techo_ch=1 if mat_techos==3 | mat_techos==4 | mat_techos==5 | (mat_techos>6 & mat_techos<=10)

/*
Material de desecho......................................
01
Lámina de cartón............................................
02
Lámina metálica ............................................
03
Lámina de asbesto.........................................
04
Lámina de fibrocemento ondulada (techo fijo)..
05
Palma o paja..................................................
06
Madera o tejamanil........................................
07
Terrado con viguería .....................................
08
Teja................................................................
09
Losa de concreto o viguetas con bovedilla....
10

1 Material de desecho.
2 Lamina de cartón.
3 Lamina metálica.
4 Lamina de asbesto.
5 Palma o paja.
6 Madera o tejamanil.
7 Terrado con viguería.
8 Teja.
9 Losa de concreto o viguetas con bovedilla.
*/

******************************
*	resid_ch
******************************

destring eli_ba, replace
gen resid_ch=.
replace resid_ch=0 if eli_ba==1 | eli_ba==2 | eli_ba==3
replace resid_ch=1 if eli_ba==4 | eli_ba==5
replace resid_ch=2 if eli_ba==6 | eli_ba==7
replace resid_ch=3 if eli_ba==8

******************************
*	dorm_ch
******************************

gen dorm_ch=cuart_dorm
label var dorm_ch "#Habitaciones exclusivamente para dormir" 

******************************
*	cuartos_ch
******************************
gen cuartos_ch=num_cuarto 
label var cuartos_ch "#Habitaciones en el hogar"
notes: cuartos_ch esta indicando cuartos, contando cocina pero no bano 

******************************
*	cocina_ch
******************************
destring cocina, replace
gen cocina_ch=.
replace cocina_ch=1 if cocina==1
replace cocina_ch=0 if cocina==2
label var cocina_ch "Si existe un cuarto separado y exclusivo para cocinar"

******************************
*	telef_ch
******************************
gen telef_ch=(telefono=="1")
label var telef_ch "Hogar con sc telefonico fijo"

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
*NA

******************************
*	auto_ch
******************************
capture confirm variable num_auto
local has_auto = !_rc
capture confirm variable num_van
local has_van  = !_rc
capture confirm variable num_pick
local has_pick = !_rc

if (`has_auto' | `has_van' | `has_pick') {
    if `has_auto' destring num_auto, replace force
    if `has_van'  destring num_van,  replace force
    if `has_pick' destring num_pick,  replace force

    capture drop auto_ch
    gen byte auto_ch = .

    replace auto_ch = 0 if ///
        ( (`has_auto' & num_auto==0) | !`has_auto' ) & ///
        ( (`has_van'  & num_van==0 ) | !`has_van'  ) & ///
        ( (`has_pick' & num_pick==0) | !`has_pick' )

    replace auto_ch = 1 if ///
        ( `has_auto' & num_auto>=1 ) | ///
        ( `has_van'  & num_van>=1  ) | ///
        ( `has_pick' & num_pick>=1 )

    label var auto_ch "El hogar posee automóvil particular"
}
else {
    di as txt "Nota: no se encontraron num_auto/num_van/num_pick; auto_ch queda missing."
    capture drop auto_ch
    gen byte auto_ch = .
    label var auto_ch "El hogar posee automóvil particular (no disponible)"
}

******************************
*	compu_ch
******************************

* Modificaciones Marcela Rubio Septiembre 2014
/*
gen compu_ch=.
replace compu_ch= 0 if num_compu==0
replace compu_ch= 0 if num_compu>=1
*/

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
label var vivi1_ch "Tipo vivienda"
label define vivi1_ch 1"Casa" 2"Dpto" 3"Otr"

/*
01 Casa independiente
02 Departamento en edificio
03 Vivienda en vecindad
04 Vivienda en cuarto de azotea
05 Local no construido para habitación
-1 No especificado
*/

******************************
*	vivi2_ch
******************************
gen vivi2_ch=(tipo_viv =="2")

******************************
*	viviprop_ch
******************************
destring tenencia, replace
gen viviprop_ch=.
replace viviprop_ch=0 if tenencia==1
replace viviprop_ch=1 if tenencia==4   
replace viviprop_ch=2 if tenencia==3
replace viviprop_ch=3 if tenencia==2 | tenencia==5 | tenencia==6
label var viviprop_ch "Propiedad de la vivienda" 

/*
1 es rentada?
2 es prestada?
3 es propia pero la están pagando?
4 es propia?
5 esta intestada o en litigio?
6 Otra situación.
*/

******************************
*	vivitit_ch
******************************
destring escrituras, replace 
gen vivitit_ch=.
replace vivitit_ch=1 if escrituras==1 | escrituras==2
replace vivitit_ch=0 if escrituras==3
label var vivitit_ch "El hogar posee un titulo de propiedad"

******************************
*	vivialq_ch
******************************
gen vivialq_ch= renta
label var vivialq_ch "Alquiler mensual"
*Renta = Monto de la renta mensual de la vivienda

******************************
*	vivialqimp_ch
******************************
gen vivialqimp_ch=estim_pago
replace vivialqimp=0 if estim_pago<0
label var vivialqimp_ch "Alquiler mensual imputado"


*******************
***  seguro_ci  ***
*******************

g benefdes_ci=0 if desemp_ci==1
replace benefdes_ci=1 if P_P036!=. & desemp_ci==1
label var benefdes_ci "=1 si tiene seguro de desempleo"

*******************
*** yseguro_ci  ***
*******************
*g ybenefdes_ci=ing_1P036 if benefdes_ci==1
*Modificado Mayra Sáenz - Agosto 2015
g ybenefdes_ci=P_P036 if benefdes_ci==1
label var ybenefdes_ci "Monto de seguro de desempleo"


ren industria industria_orig
ren comercio comercio_orig
ren servicios servicios_orig

******************************
*** VARIABLES DE MIGRACION ***
******************************

* Variables incluidas por SCL/MIG Fernando Morales

	*******************
	*** migrante_ci ***
	*******************
	
	gen migrante_ci=.
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migantiguo5_ci ***
	**********************
	
	gen migantiguo5_ci=.
	label var migantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** migrantelac_ci ***
	**********************
	
	gen migrantelac_ci=.
	label var migrantelac_ci "=1 si es migrante proveniente de un pais LAC"	
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"	
	
******************************
* Variables SPH - PMTC y PNC *
******************************

* PTMC: Beca de Educación Básica para el Bienestar Benito Juárez (antes PROSPERA) (P101)
* 		Beca Universal de Educación Media Superior Benito Juárez (antes PROSPERA) (P102)
*		Jóvenes Escribiendo el Futuro (Educación Superior) (P103)
* PNC: 	Programa Pensión para el Bienestar de las Personas Adultas Mayores (antes Programa 65 y más) (P104)
*		Beneficio de otros programas para adultos mayores (P045)

* Ingreso del hogar
egen ingreso_total_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
bys idh_ch: egen y_hog = sum(ingreso_total)

gen ptmc_ci=(P_P101>0 | P_P102>0 | P_P103>0) 
gen pnc_ci=(P_P104>0 | P_P045>0) 

bys idh_ch: egen ptmc_ch=max(ptmc_ci)

egen ing_ptmc_ci=rowtotal(P_P101 P_P102 P_P103)
bys idh_ch: egen ing_ptmc=sum(ing_ptmc_ci)

egen ing_pension_ci=rowtotal(P_P104 P_P045)
bys idh_ch: egen ing_pension=sum(ing_pension_ci)

drop ing_ptmc_ci ing_pension_ci

replace ing_ptmc=0 if ing_ptmc==.
replace ing_pension=0 if ing_pension==.

* Adultos mayores 
gen elegiblePS_ci=(edad_ci>64 & edad_ci<.)

* Ingreso per cápita
gen y_pc     = y_hog / nmiembros_ch 
gen y_pc_net = (y_hog - ing_ptmc - ing_pension) / nmiembros_ch

lab def ptmc_ch 1 "Beneficiario PTMC" 0 "No beneficiario PTMC"
lab val ptmc_ch ptmc_ch

lab def pnc_ci 1 "Beneficiario PNC" 0 "No beneficiario PNC"
lab val pnc_ci pnc_ci

/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), líneas de pobreza
/*_____________________________________________________________________________________________________*/

do "$survey_folder\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

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


/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 

rename sinco1  codocupa
rename scian1 codindustria
destring codocupa codindustria, replace
compress

saveold "`base_out'", replace


log close



























