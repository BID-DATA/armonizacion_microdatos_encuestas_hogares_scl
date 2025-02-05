* (Versión Stata 13)
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

local PAIS COL
local ENCUESTA ENH-FT
local ANO "2000"
local ronda m9 
local log_file  = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out  = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Colombia
Encuesta: ENH-FT
Round: m9
Autores: 
Generación nuevas variables LMK: 
Última versión: Yessenia Loayza - Email: desloay@hotmail.com | yessenial@iadb.org
Fecha última modificación: noviembre 2013

							SCL/LMK - IADB
****************************************************************************/
****************************************************************************/
/* 
En el año 2000 el DANE realizó un profundo cambio en la metodología del sistema de
encuestas de hogares. se pasó de la ENH a la ECH.
Con la ECH no es posible realizar análisis comparativos con el periodo previo a 2001 pues
la caracterización de la fuerza de trabajo y la definición de los diferentes grupos poblacionales
tuvieron variaciones importantes, en especial en la definición de los desocupados, afectando
los niveles de los principales agregados del mercado laboral
https://www.banrep.gov.co/docum/ftp/borra410.pdf
*/

use `base_in', clear

 
***************
***region_c ***
***************
gen region_c=real(v_7_T10_2)
label define region_c       /// 
	5  "Antioquia"	        ///
	8  "Atlántico"	        ///
	11 "Bogotá, D.C"	    ///
	13 "Bolívar" 	        ///
	15 "Boyacá"	            ///
	17 "Caldas"	            ///
	18 "Caquetá"	        ///
	19 "Cauca"	            ///
	20 "Cesár"	            ///
	23 "Córdoba"	        ///
	25 "Cundinamarca"       ///
	27 "Chocó"	            ///
	41 "Huila"	            ///
	44 "La Guajira"	        ///
	47 "Magdalena"	        ///
	50 "Meta"	            ///
	52 "Nariño"	            ///
	54 "Norte de Santander"	///
	63 "Quindío"	        ///
	66 "Risaralda"	        ///
	68 "Santander"	        ///
	70 "Sucre"	            ///
	73 "Tolima"	            ///
	76 "Valle"              ///
	81 "Arauca"             /// 
	85 "Casanare"           ///
	86 "Putumayo"           ///
	88 "S-Andres-Pr"        ///
	91 "Amazonas"           ///
	94 "Guainia"            ///
	95 "Guaviare"           ///
	97 "Vaupes"             ///
	99 "Vichada"     
label value region_c region_c
label var region_c "division politico-administrativa, departamento"

***************
***  ine01  ***
***************
gen ine01=real(v_7_T10_2)
label define ine01          /// 
	5  "Antioquia"	        ///
	8  "Atlantico"	        ///
	11 "Bogota, D.C"	    ///
	13 "Bolivar" 	        ///
	15 "Boyacá"	            ///
	17 "Caldas"	            ///
	18 "Caquetá"	        ///
	19 "Cauca"	            ///
	20 "Cesar"	            ///
	23 "Córdoba"	        ///
	25 "Cundinamarca"       ///
	27 "Chocó"	            ///
	41 "Huila"	            ///
	44 "La Guajira"	        ///
	47 "Magdalena"	        ///
	50 "Meta"	            ///
	52 "Narino"	            ///
	54 "Norte de Santander"	///
	63 "Quindío"	        ///
	66 "Risaralda"	        ///
	68 "Santander"	        ///
	70 "Sucre"	            ///
	73 "Tolima"	            ///
	76 "Valle del Cauca"	///
	81 "Arauca"	            ///
	85 "Casanare"	        ///
	86 "Putumayo"	        ///
	88 "S-Andres-Pr"        ///	
	91 "Amazonas"	        ///
	94 "Guainía"	        ///	
	95 "Guaviare"	        ///	
	97 "Vaupés" 	        ///		
	99 "Vichada"
label value ine01 ine01
label var ine01 "division politico-administrativa, departamento"

************
* Region_BID *
************
gen region_BID_c=.
replace region_BID_c=3 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

***************
***factor_ch***
***************
gen factor_ch=real(FEXDANE)
label variable factor_ch "Factor de expansion del hogar"

***************
****idh_ch*****
***************
gen idh_ch=v_IDENT
sort idh_ch
label variable idh_ch "ID del hogar"

**************
****idp_ci****
**************
bysort idh_ch:gen idp_ci=_n 
label variable idp_ci "ID de la persona en el hogar"

**********
***zona***
**********
gen byte zona_c=1 if base =="ca"
replace  zona_c=0 if base =="re"
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_ci

************
****pais****
************
gen str3 pais_c="COL"
label variable pais_c "Pais"

**********
***anio***
**********
gen anio_c=2000
label variable anio_c "Anio de la encuesta"

*********
***mes***
*********
gen mes_c=9
label variable mes_c "Mes de la encuesta"
label define mes_c 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo"
label define mes_c 6 "Junio" 7 " Julio" 8 "Agosto",add
label define mes_c 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre", add
label value mes_c mes_c

***************
***factor_ci***
***************
gen factor_ci=real(FEXDANE)
label variable factor_ci "Factor de expansion del individuo"

***************
***upm_ci***
***************
gen upm_ci=.
label variable upm_ci "Unidad Primaria de Muestreo"

***************
***estrato_ci***
***************
gen estrato_ci=.
label variable estrato_ci "Estrato"



****************************
***VARIABLES DEMOGRAFICAS***
****************************

*****************
***relacion_ci***
*****************
gen paren=real(v_3_T10)
gen relacion_ci=.
replace relacion_ci=1 if paren==1
replace relacion_ci=2 if paren==2 
replace relacion_ci=3 if paren==3 | paren==4
replace relacion_ci=4 if paren==15 
replace relacion_ci=5 if paren==16 | paren==18| paren==19 | paren==20| paren==21
replace relacion_ci=6 if paren==17
label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes"
label define relacion_ci 6 "Empleado/a domestico/a", add
label value relacion_ci relacion_ci


**********
***sexo***
**********
gen sexo_ci=.
replace sexo_ci=1 if v_4_T10=="1"
replace sexo_ci=2 if v_4_T10=="2"
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********
gen edad_ci=real(v_5_T10)
label variable edad_ci "Edad del individuo"

*****************
***civil_ci***
*****************
gen civil_ci=.
replace civil_ci=1 if v_6_T10=="5"
replace civil_ci=2 if v_6_T10=="1" | v_6_T10=="2" 
replace civil_ci=3 if v_6_T10=="4"
replace civil_ci=4 if v_6_T10=="3" 
label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci


*************
***jefe_ci***
*************
gen jefe_ci=(relacion_ci==1)
label variable jefe_ci "Jefe de hogar"


******************
***nconyuges_ch***
******************
by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
label variable nconyuges_ch "Numero de conyuges"

***************
***nhijos_ch***
***************
by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
label variable nhijos_ch "Numero de hijos"

******************
***notropari_ch***
******************
by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
label variable notropari_ch "Numero de otros familiares"

********************
***notronopari_ch***
********************
by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
label variable notronopari_ch "Numero de no familiares"

****************
***nempdom_ch***
****************
by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)
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
replace clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0
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
* 2014, 01, MLO modificado segun documento metodologico
*by idh_ch, sort: egen nmiembros_ch=sum(paren>=1 & paren<=16)
by idh_ch, sort: egen nmiembros_ch=sum(relacion_ci>=1 & relacion_ci<=4)
label variable nmiembros_ch "Numero de miembros del hogar"

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen nmayor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad>=21)
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
****************
by idh_ch, sort: egen nmenor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad<21)
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen nmayor65_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad>=65)
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen nmenor6_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad<6)
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen nmenor1_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad<1)
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

****************
***miembros_ci***
****************
* 2014, 01, MLO modificado segun documento metodologico
*gen miembros_ci=(paren>=1 & paren<=16)
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=4)
label variable miembros_ci "Miembro del hogar"




		*******************************
		*** VARIABLES DE DIVERSIDAD ***
		*******************************

****************
***afroind_ci***
****************
gen afroind_ci=. 
label var afroind_ci "Raza o etnia del individuo"

***************
***afroind_ch***
***************
gen afroind_ch  = .
label var afroind_ch "Raza/etnia del hogar en base a raza/etnia del jefe de hogar"

*******************
***afroind_ano_c***
*******************
gen afroind_ano_c=.
label var afroind_ano_c "Año Cambio de Metodología Medición Raza/Etnicidad"

*******************
***dis_ci***
*******************
gen dis_ci=. 
label var dis_ci "Personas con discapacidad"

*******************
***dis_ch***
*******************
gen dis_ch=. 
lab var dis_ch "Hogares con miembros con discapacidad"


************************************
*** VARIABLES DEL MERCADO LABORAL***
************************************

*********
*lp_ci***
*********
gen lp_ci =.
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********
gen lpe_ci =.
label var lpe_ci "Linea de indigencia oficial del pais"

*************
**salmm_ci***
*************
* COL 2000
gen salmm_ci= 	260100.00 /* salario horario *30*/
label var salmm_ci "Salario minimo legal"

****************
****condocup_ci*
****************
destring  v_16_T50 v_17_T50 v_18_T50 v_19_T50  v_16_T50 v_17_T50 v_18_T50  v_19_T50  v_20_T502 v_20_T503 v_20_T504  v_20_T505 v_21_T50 v_22_T50 v_23_T501 v_28_T50, replace

* Modificacion MGD 06/25/2014: se corrigio la edad minima de la encuesta que es 12 años.
gen condocup_ci=.
replace condocup_ci=1 if  v_16_T50 == 1 | v_17_T50==1 | v_18_T50==1 | v_19_T50==1
replace condocup_ci=2 if condocup_ci!=1 & (v_16_T50==2 | v_22_T50==1 | v_23_T501==1 | v_23_T501==3) & v_28_T50==1
replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2 & edad>=10
replace condocup_ci=4 if edad_ci<10

label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "InacTivo" 4 "Menor que 10" 
label value condocup_ci condocup_ci


****************
*afiliado_ci****
****************
destring v_35_T601, replace
gen afiliado_ci=.
replace afiliado_ci=1 if v_35_T601 ==1 
recode afiliado_ci .=0 if condocup_ci==1 | condocup_ci==2 
label var afiliado_ci "Afiliado a la Seguridad Social"

****************
*cotizando_ci***
****************
gen cotizando_ci=.
label var cotizando_ci "1 CoTizanTe a la Seguridad Social"

********************
*** instcot_ci *****
********************
gen instcot_ci=.
label var instcot_ci "institución a la cual cotiza"

****************
*insTpen_ci*****
****************
gen instpen_ci=.
label var instpen_ci "InsTiTucion proveedora de la pension - variable original de cada pais" 
label define instpen_ci 1 "Fondo privado" 2 "ISS, Cajanal" 3 "Regímenes especiales (FFMM, EcopeTrol eTc)" 4 "Fondo Subsidiado (Prosperar,eTc.)" 
label value instpen_ci insTpen_ci


*****************
*Tipocontrato_ci*
*****************
gen tipocontrato_ci=.
label var tipocontrato_ci "Tipo de conTraTo segun su duracion"
label define tipocontrato_ci 1 "PermanenTe/indefinido" 2 "Temporal" 3 "Sin conTraTo/verbal" 
label value tipocontrato_ci tipocontrato_ci

*************
*cesante_ci* 
*************
destring v_60_T70, replace
gen cesante_ci=1 if v_60_T70==2 & condocup_ci==2
replace cesante_ci=0 if condocup_ci==2 & cesante_ci!=1
label var cesante_ci "Desocupado - definicion oficial del pais"	

*************
*tamemp_ci***
*************
gen tamemp_ci=.
label var tamemp_ci "# empleados en la empresa"

*************
**pension_ci*
*************
destring v_38_T602 v_65_T703 v_72_T803, replace
*MGD 11/30 2015: falto recodificar los missings
recode v_38_T602 (98=.) (99=.)
recode v_65_T703 (98=.) (99=.)
recode v_72_T803 (98=.) (99=.)

egen aux_p=rsum(v_38_T602 v_65_T703 v_72_T803), m
gen pension_ci=1 if aux_p>0 & aux_p<.
recode pension_ci .=0
label var pension_ci "1=Recibe pension conTribuTiva"

****************
*Tipopen_ci*****
****************
gen tipopen_ci=.
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

*************
*ypen_ci*
*************
gen ypen_ci=aux_p if aux_p>0 & aux_p<.
replace ypen_ci= . if aux_p==9999999999
replace ypen_ci=. if pension_ci==0
label var ypen_ci "Valor de la pension conTribuTiva"

***************
*pensionsub_ci*
***************
gen pensionsub_ci=.
label var pensionsub_ci "1=recibe pension subsidiada / no conTribuTiva"

*****************
**ypensub_ci*
*****************
gen ypensub_ci=.
label var ypensub_ci "Valor de la pension subsidiada / no conTribuTiva"

*************
*tecnica_ci**
*************
gen tecnica_ci=.
label var tecnica_ci "1=formacion Terciaria Tecnica"

****************
*categoinac_ci**
***************
gen categoinac_ci=. /*no encuentro diccionario */

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

*************
***formal_ci***
*************

* Modificaciones Marcela Rubio - Noviembre 2014: se genera como missing ya que la variable afiliado o cotizando han sido generadas como missing
/*
gen formal_ci=(cotizando_ci==1)
*/

gen formal_ci = .


*****************
***desalent_ci***
*****************
gen desalent_ci=((v_23_T501>=4 & v_23_T501<=11)|v_23_T501==2)
*Ver Country Specific Code Book: COLOMBIA *

***************
***subemp_ci***
***************
gen subemp_ci=0

*horas en el trabajo principal*
/*todas las horas estan truncadas en 120- 98*/
gen promhora=real(v_40_T60) if emp_ci==1 
replace promhora=120 if v_40_T60=="998"
replace promhora=. if v_40_T60=="999"

gen hora_no=real(v_41_T602) if v_41_T601=="1" & emp_ci==1 
replace hora_no=120 if v_41_T602=="998"
replace hora_no=. if v_41_T602=="999"

gen hora_ad=real(v_42_T602) if v_42_T601=="1" & emp_ci==1 
replace hora_ad=98 if v_42_T602=="998"
replace hora_ad=. if v_42_T602=="999"

*horas en la actividad secundaria*
gen promhora1=real(v_47_T611) if emp_ci==1 
replace promhora1=98 if v_47_T611=="98" /*acotado*/
replace promhora1=. if v_47_T611=="99"

*Horas en otras actividades*
gen promhora2=real(v_47_T614) if emp_ci==1 
replace promhora2=98 if v_47_T614=="98" /*acotado*/
replace promhora2=. if v_47_T614=="99"

*horas adicionales (disponibles) que podría trabajara a la semana*
gen promhora3=real(v_53_T61) if emp_ci==1 
replace promhora3=97 if v_53_T61=="98" /*acotado*/
replace promhora3=. if v_53_T61=="99"

egen tothoras=rowtotal(promhora promhora1 promhora2)
replace tothoras=. if promhora==. & promhora1==. & promhora2==.
replace tothoras=. if tothoras>=168
replace subemp_ci=1 if tothoras<=30  & emp_ci==1 & v_52_T61=="1"

*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci=0
replace tiempoparc_ci=1 if tothoras<30 & emp_ci==1 & v_52_T61=="2"

*****************
***horaspri_ci***
*****************
gen horaspri_ci=promhora

*****************
***horastot_ci***
*****************
gen horastot_ci=tothoras  if emp_ci==1 

******************
***categopri_ci***
******************
gen categ=real(v_33_T60)
gen categopri_ci=.
replace categopri_ci=1 if categ ==5
replace categopri_ci=2 if categ ==4
replace categopri_ci=3 if categ ==1 | categ ==2 | categ ==3 
replace categopri_ci=4 if categ ==6
replace categopri_ci=0 if categ ==7
*categ ==7 es "otros"*

label define categopri_ci 0 "Otros"  1"Patron" 2"Cuenta propia" 
label define categopri_ci 3"Empleado" 4" Familiar no remunerado" , add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional trabajo principal"

******************
***categosec_ci***
******************
******************
gen categs=real(v_44_T61)
gen categosec_ci=.

* Modificacion MLO: abr, 2015.

replace categosec_ci=1 if categs ==3 
replace categosec_ci=2 if categs ==2 
replace categosec_ci=3 if categs ==1  
replace categosec_ci=4 if categs ==4
/*
replace categosec_ci=1 if categs ==5
replace categosec_ci=2 if categs ==4
replace categosec_ci=3 if categs ==1 | categs ==2 | categs ==3  
replace categosec_ci=4 if categs ==6
replace categosec_ci=0 if categs ==7*/

label define categosec_ci 0 "Otros" 1"Patron" 2"Cuenta propia" 
label define categosec_ci 3"Empleado" 4"Familiar no remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"
drop categs


*****************
***nempleos_ci***
*****************

gen nempleos_ci=.
replace nempleos_ci=1 if v_43_T61=="2"
replace nempleos_ci=2 if v_43_T61=="1"

*****************
***firmapeq_ci***
*****************
*gen firmapeq_ci=.


*****************
***spublico_ci***
*****************
gen spublico_ci=(categ==2)


**************
***ocupa_ci***
**************
destring v_30_T60, replace
gen ocupa_ci=.
replace ocupa_ci=1 if (v_30_T60>=1 & v_30_T60<=19)  & emp_ci==1  
replace ocupa_ci=2 if (v_30_T60>=20 & v_30_T60<=21) & emp_ci==1
replace ocupa_ci=3 if (v_30_T60>=30 & v_30_T60<=39) & emp_ci==1
replace ocupa_ci=4 if (v_30_T60>=40 & v_30_T60<=49) & emp_ci==1
replace ocupa_ci=5 if (v_30_T60>=50 & v_30_T60<=59) & emp_ci==1
replace ocupa_ci=6 if (v_30_T60>=60 & v_30_T60<=64) & emp_ci==1
replace ocupa_ci=7 if (v_30_T60>=70 & v_30_T60<=98) & emp_ci==1
replace ocupa_ci=9 if (v_30_T60==0 |  v_30_T60==99) & emp_ci==1
replace ocupa_ci=. if emp_ci==0

*************
***rama_ci***
*************
* CIIU rev.2
gen rama1=real(v_32_T60)
gen rama_ci=.
replace rama_ci=1 if rama1>=11 & rama1<=13  
replace rama_ci=2 if rama1>=21 & rama1<=29 
replace rama_ci=3 if rama1>=31 & rama1<=39 
replace rama_ci=4 if rama1>=41 & rama1<=42  
replace rama_ci=5 if rama1==50 
replace rama_ci=6 if rama1>=61 & rama1<=63  
replace rama_ci=7 if rama1>=71 & rama1<=72  
replace rama_ci=8 if rama1>=81 & rama1<=83 
replace rama_ci=9 if rama1>=91 & rama1<=98
replace rama_ci=. if rama1==99
drop rama1

****************
***durades_ci***
****************
gen durades_ci=real(v_56_T70)/4.3
*replace durades_ci=61.9 if v_56_T70=="998"
/*está truncada en 260 semanas---> 61.9 meses*/
replace durades_ci=. if v_56_T70=="999" | v_56_T70=="998"

*ca_56_T70 es en semanas*
*durades_ci es en meses*

*******************
***antiguedad_ci***
*******************
gen antiguedad_ci=.


*************************************************************************************
*******************************INGRESOS**********************************************
*************************************************************************************

****************
***ylmpri_ci ***
****************

/*Remuneracion al empleo para dependientes*/
gen yprid=real(v_34_T60) if emp_ci==1 & (v_33_T60>="1" & v_33_T60<="3")

replace yprid=. if yprid==98 /*no sabe*/
replace yprid=. if yprid==99 /*no informa*/
gen nosabe_is1=(v_34_T60=="98")
gen nosabe_is2=(v_34_T60=="99")
gen nosabe_is3=(v_34_T60~=".")
/*Ganancia al trabajo: cuenta propia, patrones, otros*/
gen yprid1=real(v_37_T60) if emp_ci==1 & (v_33_T60=="4" | v_33_T60=="5"| v_33_T60=="7")

replace yprid1=. if yprid1==98 /*no sabe*/
replace yprid1=. if yprid1==99 /*no informa*/
gen nosabe_ig1=(v_37_T60=="98")
gen nosabe_ig2=(v_37_T60=="99")
gen nosabe_ig3=(v_37_T60~=".")

/* Se le pone ceros a los trabajadores no remunerados*/
replace yprid1=0 if emp_ci==1 & v_33_T60=="6"

egen ylmpri_ci=rsum(yprid yprid1)
replace ylmpri_ci=. if yprid==. & yprid1==.
replace ylmpri_ci=0 if categopri_ci==4

*****************
***nrylmpri_ci***
*****************

gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)

*****************
*** ylnmpri_ci***
*****************
destring v_36_T601, replace
gen ylnmpri1=real(v_35_T602) if emp_ci==1 & v_35_T601==1
replace ylnmpri1=. if ylnmpri1==98
gen ylnmpri2=real(v_36_T602) if emp_ci==1 & v_36_T601==1
replace ylnmpri2=. if ylnmpri2==98
egen ylnmpri_ci=rsum(ylnmpri1 ylnmpri2)
replace ylnmpri_ci=. if ylnmpri1==. & ylnmpri2==.  
gen nosabe_inma1=(v_35_T602=="98")
gen nosabe_inma2=(v_36_T602=="99")
gen nosabe_inmv1=(v_35_T602=="98")
gen nosabe_inmv2=(v_36_T602=="99")

***************
***ylmsec_ci***
***************
gen ylmsec_ci=real(v_45_T61) if emp_ci==1 
replace ylmsec_ci=. if ylmsec_ci==98 /*no sabe*/
replace ylmsec_ci=. if ylmsec_ci==99 /*no informa*/

gen nosabe_isec1=(v_45_T61=="98")
gen nosabe_isec2=(v_45_T61=="99")
gen nosabe_isec3=(v_45_T61==".")

******************
****ylnmsec_ci****
******************
gen ylnmsec_ci=.

************
***ylm_ci***
************
*para inactivos y desempleados VER COUNTRY SPECIFIC CODE BOOK
gen yprid2=real(v_72_T801) 
replace yprid2=. if yprid2==99
gen yprid3=real(v_65_T701) 
replace yprid3=. if yprid3==99

egen ylm_ci=rsum(ylmpri_ci ylmsec_ci yprid2 yprid3)
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==. & yprid2==. & yprid3==.


*************
***ylnm_ci***
*************
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci)
replace ylnm_ci=. if ylnmpri_ci==. &  ylnmsec_ci==.

*************
***ynlm_ci***
*************

*inactivos*  
gen arriendos=real(v_72_T802)
gen pensiones=v_72_T803
for var arriendos pensiones: replace X=. if X==99 | X==98

gen ayudas=real(v_73_T801)/12 if v_73_T801!="99" & v_73_T801!="98"
gen intereses=real(v_73_T801)/12 if v_73_T801!="99" & v_73_T801!="98"
gen otras=real(v_73_T801)/12 if v_73_T801!="99"& v_73_T801!="98"

egen temi=rsum(arriendos pensiones ayudas intereses otras )
replace temi=. if arriendos==. & pensiones==. & ayudas==. & intereses==. & otras==.
drop arriendos pensiones ayudas intereses otras 

*ocupados*  

gen arriendos=real(v_38_T601)
gen pensiones=v_38_T602
for var arriendos pensiones: replace X=. if X==99 | X==98

gen ayudas=real(v_39_T601)/12 if v_39_T601!="99" & v_39_T601!="98"
gen intereses=real(v_39_T602)/12  if v_39_T602!="99" & v_39_T602!="98"
gen otras=real(v_39_T603)/12 if v_39_T603!="99" & v_39_T603!="98"

egen temo=rsum(arriendos pensiones ayudas intereses otras )
replace temo=. if arriendos==. & pensiones==. & ayudas==. & intereses==. & otras==.
drop arriendos pensiones ayudas intereses otras 

*desocupados*  
gen arriendos=real(v_65_T702)
gen pensiones=v_65_T703
for var arriendos pensiones: replace X=. if X==99 | X==98

gen ayudas=real(v_66_T701)/12 if v_66_T701!="99" & v_66_T701!="98"
gen intereses=real(v_66_T702)/12 if v_66_T702!="99" & v_66_T702!="98"
gen otras=real(v_66_T703)/12 if v_66_T703!="99"& v_66_T703!="98"

egen temd=rsum(arriendos pensiones ayudas intereses otras )
replace temd=. if arriendos==. & pensiones==. & ayudas==. & intereses==. & otras==.
drop arriendos pensiones ayudas intereses otras 

*todos*
egen ynlm_ci=rsum(temi temo temd)
replace ynlm_ci=. if temi==. & temo==. & temd==.

*****************
***remesas_ci****
*****************
gen remesas_ci=.

****************
*** ynlnm_ci ***
****************
gen ynlnm_ci=.


************************
*** HOUSEHOLD INCOME ***
************************

/*Dado que el ingreso del hogar no tiene en cuenta el ingreso de las empleadas domésticas
voy a crear una flag que me identifique a las mismas como para que en este caso figure un missing
en el ingreso del hogar, las empleadas domésticas en este caso se identifican con un 9 en la variable parentco*/

******************
*** nrylmpri_ch***
******************
*Creating a Flag label for those households where someone has a ylmpri_ci as missing

by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.


*************
*** ylm_ch***
*************

by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1

****************
*** ylmnr_ch ***
****************

by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1
replace ylmnr_ch=. if nrylmpri_ch==1

***************
*** ylnm_ch ***
***************

by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1

**********************************
*** remesas_ch & remesasnm_ch ***
**********************************

gen remesash=.

by idh_ch, sort: egen remesasi=sum(remesas_ci) if miembros_ci==1
replace remesasi=. if remesasi==0
egen remesas_ch=rsum(remesasi remesash)
replace remesas_ch=. if remesasi==. 

gen remesasnm_ch=.


***************
*** ynlm_ch ***
***************

by idh_ch, sort: egen ynlm=sum(ynlm_ci) if miembros_ci==1
egen ynlm_ch=rsum(ynlm remesash)
replace ynlm_ch=. if ynlm==. 
drop ynlm

****************
*** ynlnm_ch ***
****************

gen ynlnm_ch=remesasnm_ch

*******************
*** autocons_ci ***
*******************

gen autocons_ci=.


*******************
*** autocons_ch ***
*******************

by idh_ch, sort: egen autocons_ch=sum(autocons_ci) if miembros_ci==1

*******************
*** rentaimp_ch ***
*******************

gen rentaimp_ch=.

*****************
***ylmhopri_ci ***
*****************

gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)


***************
***ylmho_ci ***
***************

gen ylmho_ci=ylm_ci/(horastot_ci*4.3)


****************************
***VARIABLES DE EDUCACION***
****************************
*Yessenia Loayza (may 2014) -> corrigo variable aedu_ci 

*** people who have missings
gen byte yedc=.
gen yedc1=real(v_15_T10) /*Todos*/
replace yedc=. if yedc1==999

** No education preescolar o jardin o pre-primaria
replace yedc=0 if yedc1<=300

*** primaria 
replace yedc=1 if yedc1==301 
replace yedc=2 if yedc1==302 
replace yedc=3 if yedc1==303 
replace yedc=4 if yedc1==304 
replace yedc=5 if yedc1==305 | yedc1==400

*** secundaria 
replace yedc=6  if yedc1==406 
replace yedc=7  if yedc1==407 
replace yedc=8  if yedc1==408 
replace yedc=9  if yedc1==409 
replace yedc=10 if yedc1==410
replace yedc=11 if yedc1==411 | yedc1==500
replace yedc=12 if yedc1==412
replace yedc=13 if yedc1==413

*** superior o universitario  *** 
replace yedc=12 if yedc1==501
replace yedc=13 if yedc1==502
replace yedc=14 if yedc1==503
replace yedc=15 if yedc1==504
replace yedc=16 if yedc1==505
replace yedc=17 if yedc1==506
replace yedc=18 if yedc1==507
replace yedc=19 if yedc1==508
replace yedc=20 if yedc1==509
replace yedc=21 if yedc1==510
replace yedc=22 if yedc1==511
replace yedc=22 if yedc1==512
replace yedc=23 if yedc1==513
replace yedc=24 if yedc1==514
replace yedc=25 if yedc1==515

gen byte aedu_ci=yedc


**************
***eduno_ci***
**************
g byte eduno_ci = aedu_ci == 0
replace eduno_ci=. if aedu_ci==.
la var eduno_ci "Sin educación"

**************
***edupi_ci***
**************
g byte edupi_ci = (aedu_ci >= 1 & aedu_ci < 5) 
replace edupi_ci=. if aedu_ci==.
la var edupi_ci "Primaria incompleta"
	
**************
***edupc_ci***
**************
	g byte edupc_ci = aedu_ci == 5 
	replace edupc_ci=. if aedu_ci==.
	la var edupc_ci "Primaria completa"

**************
***edusi_ci***
**************
	g byte edusi_ci = (aedu_ci >= 6 & aedu_ci < 11) 
	replace edusi_ci=. if aedu_ci==.
	la var edusi_ci "Secundaria incompleta"

**************
***edusc_ci***
**************
	g byte edusc_ci = (aedu_ci==11) 
	replace edusc_ci=. if aedu_ci==.
	la var edusc_ci "Secundaria completa"

	
**************
***eduui_ci***
**************
	g byte eduui_ci = (aedu_ci>11 & aedu_ci<16)
	replace eduui_ci=. if aedu_ci==.
	la var eduui_ci "Superior incompleto"

**************
***eduuc_ci***
**************
	g byte eduuc_ci = (aedu_ci>=16 & aedu_ci!=.)
	replace eduuc_ci=. if aedu_ci==.
	la var eduuc_ci "Superior completo"

***************
***edus1i_ci***
***************
	g byte edus1i_ci = (aedu_ci >= 6 & aedu_ci < 9)
	replace edus1i_ci=. if aedu_ci==.
	la var edus1i_ci "1er ciclo de la secundaria incompleto"

***************
***edus1c_ci***
***************
	g byte edus1c_ci = aedu_ci == 9
	replace edus1c_ci=. if aedu_ci==.
	la var edus1c_ci "1er ciclo de la secundaria completo"

***************
***edus2i_ci***
***************
	g byte edus2i_ci = aedu_ci == 10 
	replace edus2i_ci=. if aedu_ci==.
	la var edus2i_ci "2do ciclo de la secundaria incompleto"

***************
***edus2c_ci***
***************
	g byte edus2c_ci = (aedu_ci == 11)
	replace edus2c_ci=. if aedu_ci==.
	la var edus2c_ci "2do ciclo de la secundaria completo"


***************
***edupre_ci***
***************
	g byte edupre_ci =.
	la var edupre_ci "Educación preescolar"

**************
***eduac_ci***
**************
	gen byte eduac_ci=.
	label variable eduac_ci "Superior universitario vs superior no universitario"
	
***************
***asiste_ci***
***************
gen asiste_ci=.
replace asiste_ci=1 if v_13_T10=="1"
replace asiste_ci=0 if v_13_T10=="2"
label variable asiste_ci "Asiste actualmente a la escuela"

*****************
***pqnoasis_ci***
*****************
gen pqnoasis_ci=.

**************
*pqnoasis1_ci*
**************
**Daniela Zuluaga- Enero 2018: Se agrega la variable pqnoasis1_ci cuya sintaxis fue elaborada por Mayra Saenz**

g       pqnoasis1_ci = .

***************
***repite_ci***
***************

gen repite_ci=.
label variable repite_ci "Esta repitendo el grado o curso"

******************
***repiteult_ci***
******************

gen repiteult_ci=.
label variable repiteult_ci "Esta repitendo el ultimo grado o curso"

***************
***edupub_ci***
***************

gen edupub_ci=.
replace edupub_ci=1 if v_14_T10=="1"
replace edupub_ci=0 if v_14_T10=="2"
label variable edupub_ci "Asiste a centros publicos"

**********************************
**** VARIABLES DE LA VIVIENDA ****
**********************************

***************
**aguared_ch***
***************
destring v_4_T01_, replace
gen aguared_ch=(v_4_T01_==1 | v_4_T01_==2) // 1 De acueducto por tubería 2 De otra fuente por tubería
la var aguared_ch "Acceso a fuente de agua por red"

*****************
*aguafconsumo_ch*
*****************
*se clasificó sel 2000 sobre la base del 2021
gen aguafconsumo_ch = 0 //2021 0 La encuesta no pregunta sobre agua para beber
replace aguafconsumo_ch = 1 if v_4_T01_==1  //2021 1 De acueducto por tubería
replace aguafconsumo_ch = 2 if v_4_T01_==6 // 2021 7 De pila pública 
replace aguafconsumo_ch = 3 if v_4_T01_==0  //2021 10 Agua embotellada o en bolsa
replace aguafconsumo_ch = 5 if v_4_T01_==9  //2021 5 Aguas lluvias
replace aguafconsumo_ch = 6 if v_4_T01_==7 //2021 8 Carrotanque
replace aguafconsumo_ch = 7 if v_4_T01_==2 //2021 2 De otra fuente por tubería
replace aguafconsumo_ch = 8 if v_4_T01_==5  //2021 6 Río, quebrada, nacimiento o manantial
replace aguafconsumo_ch = 9 if (v_4_T01_==4 | v_4_T01_==8) //2021 4 De pozo sin bomba, aljibe, jagüey o barreno + 9 Aguatero
replace aguafconsumo_ch = 10 if (v_4_T01_==3) //2021 3 De pozo con bomba 

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.
replace aguafconsumo_ch = 1 if v_4_T01_==1  
replace aguafconsumo_ch = 2 if v_4_T01_==6 
replace aguafconsumo_ch = 3 if v_4_T01_==0 
replace aguafconsumo_ch = 5 if v_4_T01_==9
replace aguafconsumo_ch = 6 if v_4_T01_==7 
replace aguafconsumo_ch = 7 if v_4_T01_==2 
replace aguafconsumo_ch = 8 if v_4_T01_==5  
replace aguafconsumo_ch = 9 if (v_4_T01_==4 | v_4_T01_==8) 
replace aguafconsumo_ch = 10 if (v_4_T01_==3) 
replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1

****************
**aguadist_ch***
****************
gen aguadist_ch=.

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =9

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9
*label var aguadisp2_ch "= 9 la encuesta no pregunta si el servicio de agua es constante"

****************
**aguamala_ch***
****************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7
*label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"

****************
**aguamide_ch***
****************
gen aguamide_ch=.
label var aguamide_ch "Usan medidor para pagar consumo de agua"

****************
****bano_ch*****
****************
destring v_2_T01, replace
gen bano_ch=.
replace bano_ch=0 if v_2_T01==6
replace bano_ch=1 if v_2_T01==1
replace bano_ch=2 if v_2_T01==2
replace bano_ch=4 if v_2_T01==5
replace bano_ch=6 if v_2_T01==3 | v_2_T01 ==4
replace bano_ch=6 if bano_ch ==. & jefe_ci==1

***************
***banoex_ch***
***************
generate banoex_ch=.
la var banoex_ch "El servicio sanitario es exclusivo del hogar"

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
replace sinbano_ch = 0 if v_2_T01<6

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9
*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"

****************
*****luz_ch*****
****************
destring v_4i_T013, replace
gen luz_ch=(v_4i_T013==1)
replace luz_ch=. if v_4i_T013==.
la var luz_ch  "La principal fuente de iluminación es electricidad"

****************
***luzmide_ch***
****************
gen luzmide_ch=.
la var luzmide_ch "Usan medidor para pagar consumo de electricidad"

****************
***combust_ch***
****************
destring v_5_T01, replace
gen combust_ch=(v_5_T01==1|v_5_T01==3)
replace combust_ch =. if v_5_T01==.
la var combust_ch "Principal combustible gas o electricidad" 

****************
****des1_ch*****
****************
destring v_2_T01, replace
gen des1_ch=.
replace des1_ch=0 if v_2_T01==6 
replace des1_ch=1 if v_2_T01==1|v_2_T01==4
replace des1_ch=2 if v_2_T01==2
replace des1_ch=3 if v_2_T01==3|v_2_T01==5
	la var des1_ch "Tipo de desague inadecuado (unimproved) según MDG"
	la def des1_ch 	0 "No tiene servicio sanitario" 				///
					1 "Conectado a red general o cámara séptica" 	///
					2 "Letrina o conectado a pozo ciego" 			///
					3 "Desemboca en río o calle"

****************
****des2_ch*****
****************
g des2_ch = .
replace des2_ch = 0 if bano_ch == 0
replace des2_ch = 1 if v_2_T01 == 1 |v_2_T01 == 2 |v_2_T01 == 3 | v_2_T01 == 4
replace des2_ch = 2 if v_2_T01 == 5 
la var des2_ch "Tipo de desague sin incluir definición MDG"
la def des2_ch 	0 "No tiene servicio sanitario" 								///
					1 "Conectado a red general, cámara pséptica, pozo o letrina" 	///
					2 "Cualquier otro caso"
la val des2_ch des2_ch
	
****************
****piso_ch*****
****************}
destring v_3i_T01, replace
g piso_ch = (v_3i_T01 != 1 & v_3i_T01 != .)
replace piso_ch = . if v_3i_T01 == .
la var piso_ch "Materiales de construcción del piso"  
la def piso_ch 	0 "Piso de tierra" 			///
				1 "Materiales permanentes: cemento, cerámica, mosaico, madera"  ///
				2 "otros materiales: natural, otros"
la val piso_ch piso_ch
	
****************
****pared_ch****
****************
destring v_2i_T01, replace
gen pared_ch=. 
replace pared_ch = 0 if v_2i_T01 ==7
replace pared_ch = 1 if v_2i_T01==1| v_2i_T01==2|v_2i_T01==3
replace pared_ch = 2 if v_2i_T01==4| v_2i_T01==5|v_2i_T01==6
la var pared_ch "Materiales de la pared"  
la def pared_ch 0 "No permanentes: desechos, zinc, tela, cartón." 			///
				1 "Materiales permanentes: paredes de ladrillo, adobe revocado, cemento y hormigón." ///
				2 "Otros materiales: naturales, otros."
la val pared_ch pared_ch

****************
****techo_ch****
****************
gen techo_ch=.

****************
****resid_ch****
****************
gen basura=real(v_3_T01_)
g resid_ch = 0		 if basura == 4 //1 Por recolección pública o privada
replace resid_ch = 1 if basura == 3 //4 La queman o entierran
replace resid_ch = 2 if basura == 1 | basura== 2 //2 La tiran a un río, quebrada, caño o laguna + 3 La tiran a un patio, lote, zanja o baldío
replace resid_ch = . if basura == .
la var resid_ch "Método de eliminación de residuos"
la de resid_ch 	0 "Recolección pública o privada" 	///
				1 "Quemados o enterrados" 			///
				2 "Tirados a un espacio abierto" 	///
				3 "Otros"
la val resid_ch resid_ch

*************
***dorm_ch***
*************
g dorm_ch = .
la var dorm_ch "Habitaciones para dormir"
	
****************
***cuartos_ch***
****************
gen cuartos_ch=real(v_1_T01_)
replace cuartos_ch=. if cuartos_ch==99

****************
***cocina_ch****
****************
gen cocina_ch=.

****************
****telef_ch****
****************
destring v_8_T01_1, replace
gen telef_ch= 1 if v_8_T01_1==1
replace telef_ch = . if v_8_T01_1 == .
la var telef_ch "El hogar tiene servicio telefónico fijo"
	
***************
***refrig_ch***
***************
destring  v_8_T01_3, replace
g refrig_ch = 1 if v_8_T01_3 == 1
replace refrig_ch = . if v_8_T01_3 == .
la var refrig_ch "El hogar posee refrigerador o heladera"	

**************
***freez_ch***
**************
g freez_ch = .
la var freez_ch "El hogar posee congelador"

*************
***auto_ch***
*************
g auto_ch = .
la var auto_ch "El hogar posee automóvil particular"

****************
****compu_ch****
****************
gen compu_ch=.

****************
**internet_ch***
****************
gen internet_ch=.

****************
****cel_ch******
****************
gen cel_ch=.	
	
****************
****vivi1_ch****
****************
destring v_1i_T01, replace
g vivi1_ch = 1     	 if v_1i_T01 == 1
replace vivi1_ch = 2 if v_1i_T01 == 2
replace vivi1_ch = 3 if v_1i_T01 == 3 | v_1i_T01 == 4 | v_1i_T01 == 5 
replace vivi1_ch = . if v_1i_T01 == .
la var vivi1_ch "Tipo de vivienda en la que reside el hogar"
la de vivi1_ch 	1 "Casa" ///
				2 "Departamento" ///
				3 "Otros"
la val vivi1_ch vivi1_ch
	
**************
***vivi2_ch***
**************
g vivi2_ch = (v_1i_T01== 1 | v_1i_T01 == 2)
replace vivi2_ch = . if v_1i_T01 == .
la var vivi2_ch "La vivienda es casa o departamento"
	
*******************
****viviprop_ch****
*******************
destring v_6_T01_, replace
g viviprop_ch = 0 if v_6_T01_ == 3
replace viviprop_ch = 1 if v_6_T01_ == 1
replace viviprop_ch = 2 if v_6_T01_ == 2
replace viviprop_ch = 3 if v_6_T01_ == 4 | v_6_T01_ == 5 | v_6_T01_ == 6
replace viviprop_ch = . if v_6_T01_ == .
la var viviprop_ch "Propiedad de la vivienda"
la de viviprop_ch 	0 "Alquilada" 					///
					1 "Propia y totalmente pagada" 	///
					2 "Propia y en proceso de pago" ///
					3 "Ocupada (propia de facto)" 
la val viviprop_ch viviprop_ch
	

******************
****vivitit_ch****
******************
g vivitit_ch = .
la var vivitit_ch "El hogar posee un título de propiedad"

*******************
****vivialq_ch****
*******************
gen vivialq_ch=real(v_7_T01_)
replace vivialq_ch=. if vivialq_ch<999
la var vivialq_ch "Alquiler mensual"

*********************
****vivialqimp_ch****
*********************
gen vivialqimp_ch=.	
la var vivialqimp_ch "Alquiler mensual imputado"


gen tcylmpri_ci =.
gen ylmotros_ci=.
gen ylnmotros_ci=.
gen tcylmpri_ch=.

*******************
*** benefdes_ci ***
*******************
g benefdes_ci=.
label var benefdes_ci "=1 si tiene seguro de desempleo"
*******************
*** ybenefdes_ci **
*******************
g ybenefdes_ci=.
label var ybenefdes_ci "Monto de seguro de desempleo"


******************************
*** VARIABLES DE MIGRACION ***
******************************

*Variables incluidas por SCL/MIG Fernando Morales

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


*----------------------------------------------------------------------------------*
*----------------------------------------------------------------------------------*

*----------------------------------------------------------------------------------*
*----------------------------------------------------------------------------------*

do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/
destring idh_ch, replace

order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch	idh_ch	idp_ci	factor_ci sexo_ci edad_ci ///
afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch  relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch ///
clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch	nmenor1_ch	condocup_ci ///
categoinac_ci nempleos_ci emp_ci antiguedad_ci	desemp_ci cesante_ci durades_ci	pea_ci desalent_ci subemp_ci ///
tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci ///
formal_ci tipocontrato_ci ocupa_ci horaspri_ci horastot_ci	pensionsub_ci pension_ci tipopen_ci instpen_ci	ylmpri_ci nrylmpri_ci ///
tcylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci	ylmotros_ci	ylnmotros_ci ylm_ci	ylnm_ci	ynlm_ci	ynlnm_ci ylm_ch	ylnm_ch	ylmnr_ch  ///
ynlm_ch	ynlnm_ch ylmhopri_ci ylmho_ci rentaimp_ch autocons_ci autocons_ch nrylmpri_ch tcylmpri_ch remesas_ci remesas_ch	ypen_ci	ypensub_ci ///
salmm_ci tc_c ipc_c lp19_c lp31_c lp5_c lp_ci lpe_ci aedu_ci eduno_ci edupi_ci edupc_ci	edusi_ci edusc_ci eduui_ci eduuc_ci	edus1i_ci ///
edus1c_ci edus2i_ci edus2c_ci edupre_ci eduac_ci asiste_ci pqnoasis_ci pqnoasis1_ci	repite_ci repiteult_ci edupub_ci ///
aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch aguatrat_ch luz_ch luzmide_ch combust_ch des1_ch des2_ch piso_ch ///
pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch freez_ch auto_ch compu_ch internet_ch cel_ch ///
vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch	vivialqimp_ch, first


compress

saveold "`base_out'", replace

log close



