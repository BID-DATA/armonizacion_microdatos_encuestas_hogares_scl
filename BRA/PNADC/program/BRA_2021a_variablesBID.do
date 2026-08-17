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

local PAIS BRA
local ENCUESTA PNADC
local ANO "2021"
local ronda a 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
          
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES 
País: Brasil
Encuesta: PNADC
Round: anual 2021
*************************************************************************** */
*************************************************************************** */

use `base_in', clear

**********************************
**** ARMONIZACIÓN PNAD_C 2020 **** 
**********************************
rename *, lower
				
*************************
***VARIABLES DEL HOGAR***
*************************

***************
***region_ci***
***************
*generacion "region_c" proyecto maps America.	

gen region_c = uf
destring region_c, replace
label define region_c ///
11 "Rondônia" ///
12 "Acre" ///
13 "Amazonas" ///
14 "Roraima" ///
15 "Pará" ///
16 "Amapá" ///
17 "Tocantins" ///
21 "Maranhão" ///
22 "Piauí" ///
23 "Ceará" ///
24 "Rio Grande do Norte" ///
25 "Paraíba" ///
26 "Pernambuco" ///
27 "Alagoas" ///
28 "Sergipe" ///
29 "Bahia" ///
31 "Minas Gerais" ///
32 "Espírito Santo" ///
33 "Rio de Janeiro" ///
35 "São Paulo" ///
41 "Paraná" ///
42 "Santa Catarina" ///
43 "Rio Grande do Sul" ///
50 "Mato Grosso do Sul" ///
51 "Mato Grosso" ///
52 "Goiás" ///
53 "Distrito Federal"
label value region_c region_c
label var region_c "division politico-administrativa"

**********************
***region según BID***
**********************
gen region_BID_c=4 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c


************************
*** ine01 ***
************************
gen ine01=uf
label define ine01 11 "Rondônia" 12 "Acre" 13 "Amazonas" 14 "Roraima" 15 "Pará" 16 "Amapá" 17 "Tocantins" 21 "Maranhão" 22 "Piauí" 23 "Ceará" 24 "Rio Grande do Norte" 25 "Paraíba" 26 "Pernambuco" 27 "Alagoas" 28 "Sergipe" 29 "Bahia" 31 "Minas Gerais" 32 "Espírito Santo" 33 "Rio de Janeiro" 35 "São Paulo" 41 "Paraná" 42 "Santa Catarina" 43 "Rio Grande do Sul" 50 "Mato Grosso do Sul" 51 "Mato Grosso" 52 "Goiás" 53 "Distrito Federal"
label value ine01 ine01 
   
***************
***factor_ch***
***************
gen factor_ch=v1032
label variable factor_ch "Factor de expansión del hogar"

*************
***idh_ch****
*************
format %14.0g upa
sort trimestre upa v1008 v1014 // A chave de domicílio é composta pelas variáveis: UPA + V1008 + V1014 (PNAD CONTÍNUA – CHAVES)
egen idh_ch=group(trimestre upa estrato v1008 v1014)
label variable idh_ch "ID del hogar"
tostring idh_ch, replace


************
***idp_ci***
************ 
format %14.0g upa
sort trimestre upa v1008 v1014 v2003 // A chave de pessoas é composta pelas variáveis: UPA + V1008 + V1014 + V2003 (PNAD CONTÍNUA – CHAVES)
gen idp_ci=v2003
label variable idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


**********
***zona***
**********
gen zona_c=1 if v1022==1
replace zona_c=0 if v1022==2
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

**********
***pais***
**********
gen str3 pais_c="BRA"
label variable pais_c "País"

**********
***anio***
**********
gen anio_c=2021
label variable anio_c "Anio de la encuesta"

*********************
***mes(trimmestre)***
*********************
g mes_c=trimestre // dejo el mismo nombre para no modificar dofile de Labels
label variable mes_c "trimestre de la encuesta"

*****************
***relacion_ci***
*****************
*variable cambia a v2005 - AL

recode v2005 (1=1) (2/3=2) (4/6=3) (7/14=4) (15/17 19=5) (18=6), g(relacion_ci)
label var relacion_ci "Relación de parentesco con el  jefe de hogar"
label define relacion_ci 1 "Jefe" 2 "Conyuge" 3 "Hijo" 4 "Otros Parientes" 5 "Otros no Parientes" 6 "Servicio Domestico"
label values relacion_ci relacion_ci

****************************
***VARIABLES DEMOGRÁFICAS***
****************************
				
***************
***factor_ci***
***************

gen factor_ci=v1032
label variable factor_ci "Factor de expansión de personas"

************
***upm_ci***
************
gen upm_ci=upa

****************
***estrato_ci***
****************
gen estrato_ci=estrato

**********
***sexo***
**********
gen sexo_ci=v2007
label var sexo_ci "Sexo del individuo" 
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********
gen edad_ci=v2009
label variable edad_ci "Edad del individuo"

**************
***civil_ci***
**************
gen civil_ci=. // la variable v4011 no está incluída.
/*
replace civil_ci=1 if v4011==0
replace civil_ci=2 if v4111==1 | v4011==1
replace civil_ci=3 if v4011==3 | v4011==5
replace civil_ci=4 if v4011==7
label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci
*/

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
replace  clasehog_ch=1 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch==0   /*Unipersonal*/
replace  clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0                      /*Nuclear (child with or without spouse but without other relatives)*/
replace  clasehog_ch=2 if nhijos_ch==0 & nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0    /*Nuclear (spouse with or without children but without other relatives)*/
replace  clasehog_ch=3 if notropari_ch>0 & notronopari_ch==0                                     /*Ampliado*/
replace  clasehog_ch=4 if ((nconyuges_ch>0 | nhijos_ch>0 | notropari_ch>0) & (notronopari_ch>0)) /*Compuesto (some relatives plus non relative)*/
replace  clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0    /*Corresidente*/
label variable clasehog_ch "Tipo de hogar"
label define clasehog_ch 1 " Unipersonal" 2 "Nuclear" 3 "Ampliado" 
label define clasehog_ch 4 "Compuesto" 5 " Corresidente", add
label value clasehog_ch clasehog_ch

*****************
***miembros_ci***
*****************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
label variable nmiembros_ch "Numero de familiares en el hogar"

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

*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	*********
	*afro_ci*
	*********
	**Pregunta: COR OU RACA? (v2010) (BRANCA 1, PRETA 2, AMARELA 3, PARDA 4, INDIGENA 5, IGNORADA 9) 
	tab v2010, m
	
	gen byte afro_ci = . 
	replace afro_ci = 1 if v2010 == 2 | v2010 == 4
	replace afro_ci = 0 if v2010 != 2 & v2010 != 4 & v2010 != 9
	tab afro_ci, m
	
	*********
	*ind_ci*
	*********	
	gen byte ind_ci = .
	replace ind_ci = 1 if v2010 == 5
	replace ind_ci = 0 if v2010 != 5 & v2010 != 9
	
	tab ind_ci, m

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci =1 if (afro_ci==0 & ind_ci==0)
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)
	replace noafroind_ci =. if (afro_ci==. | ind_ci==.) //Esto solo en el caso que se tenga ambas opciones no disponibles. 
	ta noafroind_ci,m

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1
	ta afroind_ci,m
	
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
	gen byte BRA_dis_ci = .

************************************
*** VARIABLES DEL MERCADO LABORAL***
************************************

*****************
***condocup_ci***
*****************
gen condocup_ci=.
replace condocup_ci=1 if (v4001==1 | v4002==1 | v4003==1 | v4004==1 | v4005==1)
replace condocup_ci=2 if (v4001==2 | v4002==2 | v4003==2 | v4004==2 | v4005==2) & (v4071==1 & v4072a!=9) /*tomaron alguna providencia en la semana de referencia*/
replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2 & edad_ci >= 14
replace condocup_ci=4 if edad_ci<14 // Edad que aparece en el cuestionario
label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4 "menor 10 años"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"

/*
Definiciones:
* População ocupada: Aquelas pessoas que, num determinado período de referência,
trabalharam ou tinham trabalho mas não trabalharam (por exemplo, pessoas em férias).

* População Desocupada: aquelas pessoas que não tinham trababalho, num determinado 
período de referência, mas estavam dispostas a trabalhar, e que, para isso, tomaram
alguma providência efetiva (consultando pessoas, jornais, etc.).

População Não Economicamente Ativa: pessoas não classificadas como ocupadas ou 
desocupadas

PET: >=10 años de edad
*/

*****************
***afiliado_ci***
*****************
gen afiliado_ci=.
label var afiliado_ci "Afiliado a la Seguridad Social"

******************
***cotizando_ci***
******************
*corrección de la variable vd4012, hay un error en 2021
gen vd4012_fixed=.
replace vd4012_fixed=1 if  v2009>=14 & v4009!=. & ((v4012==3 & v4029==1) | (v4012==1 & v4029==1) | (v4012==4 & v4029==1) | (v4012==2 | (v4012==4 & v4028==1)) | (v4032==1 & v4012==3 & v4029==2) | (v4032==1 & v4012==1 & v4029==2) | (v4032==1 & v4012==4 & v4029==2) | (v4032==1 & v4012==5) | (v4032==1 & v4012==6) | ((v4009==2 | v4009==3) & (v4043==1 | v4043==3) & v4048==1 ) | ((v4009==2 | v4009==3) & (v4043==1 | v4043==3) & v4048==2 & v4049==1) | ((v4009==2 | v4009==3) & v4043==2) | ((v4009==2 | v4009==3) & v4043==4 & v4047==1) | ((v4009==2 | v4009==3) & v4043==4 & v4047==2 & v4048==1) | ((v4009==2 | v4009==3) & v4043==4 & v4047==2 & v4048==2 & v4049==1) | ((v4009==2 | v4009==3) & (v4043==5 | v4043==6) & v4049==1) | (v4009==3 & v4057==1))
replace vd4012_fixed=2 if v2009>=14 & v4009!=. & ((v4012!=3 & v4012!=1 & v4012!=4) | v4029!=1) & (v4012!=2 & (v4012!=4 | v4028!=1)) & (v4032!=1 | (v4012==1 | v4012==2 | v4012==4 | v4012==5 | v4012==6) | v4029!=2) & (v4032!=1 | (v4012==2 | v4012==3 | v4012==4 | v4012==5 | v4012==6) | v4029!=2) & (v4032!=1 | (v4012==1 | v4012==2 | v4012==3 | v4012==5 | v4012==6) | v4029!=2) & (v4032!=1 | (v4012==1 | v4012==2 | v4012==3 | v4012==4 | v4012==6)) & (v4032!=1 | (v4012==1 | v4012==2 | v4012==3 | v4012==4 | v4012==5)) & (v4009==1 | (v4043!=1 & v4043!=3) | v4048 !=1) & (v4009==1 | (v4043!=1 & v4043!=3) | v4048!= 2 | v4049!=1) & (v4009==1 | v4043!=2) & (v4009==1 | v4043!=4 | v4047!= 1) & (v4009==1 | v4043!=4 | v4047!= 2 | v4048!= 1) & (v4009==1 | v4043!=4 | v4047!=2 | v4048!=2 | v4049!=1) & (v4009==1 | (v4043!=5 & v4043!=6) | v4049!=1) & (v4009!= 3 | v4057!=1) 

gen cotizando_ci=0       if condocup_ci==1 | condocup_ci==2 
replace cotizando_ci=1   if (vd4012_fixed==1) & cotizando_ci==0
label var cotizando_ci "Cotizante a la Seguridad Social"

gen cotizapri_ci=0       if condocup_ci==1 | condocup_ci==2 
replace cotizapri_ci=1   if (v4032==1) & cotizando_ci==0 
label var cotizapri_ci "Cotizante a la Seguridad Social por su trabajo principal"

gen cotizasec_ci=0       if condocup_ci==1 | condocup_ci==2 
replace cotizasec_ci=1   if (v4049==1) & cotizando_ci==0 
label var cotizasec_ci "Cotizante a la Seguridad Social por su trabajo secundario"

gen cotizaotros_ci=0     if condocup_ci==1 | condocup_ci==2 
replace cotizaotros_ci=1 if (v4057==1) & cotizando_ci==0 
label var cotizaotros_ci "Cotizante a la Seguridad Social por otro trabajos o por aporte privado"

*Cotizando sin restringir a PEA
gen cotizando_ci1=0      if condocup_ci==1 | condocup_ci==2 | condocup_ci==3
replace cotizando_ci1=1  if (vd4012_fixed==1) & cotizando_ci1==0
label var cotizando_ci "Cotizante a la Seguridad Social"

****************
***instpen_ci***
****************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 

****************
***instcot_ci***
****************
gen instcot_ci=.
label var instcot_ci "institución a la cual cotiza"

*********************
***tipocontrato_ci***
*********************
gen tipocontrato_ci=. /*solo se pregunta si era contratado como empleado temporario o no*/
label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

****************
***pension_ci***
**************** 
gen pension_ci=0 
replace pension_ci=1 if (v5004a2>0 & v5004a2!=.) /*Se les pregunta a todas las personas (jubilados, sobrevivientes, etc.)*/
label var pension_ci "1=Recibe pension contributiva"
 
*************
***ypen_ci***
*************
gen ypen_ci=v5004a2
replace ypen_ci=. if ypen_ci<=0
label var ypen_ci "Valor de la pension contributiva"

*******************
***pensionsub_ci***
*******************
/*AJAM, nuevo módulo de programas sociales especifica BPC -y BF-, Parte 5*/
gen pensionsub_ci=(v5001a==1)
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

****************
***ypensub_ci***
****************
gen ypensub_ci=v5001a2 if v5001a2!=.
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

************
*cesante_ci* 
************
generat cesante_ci=0 if condocup_ci==2
replace cesante_ci=1 if (v4082==1) & condocup_ci==2  // encuesta no trae consulta sobre si trabajo el anio pasado
label var cesante_ci "Desocupado - definicion oficial del pais"

*****************
***region/area***
*****************
gen region=.	
replace region=1	if region_c>=11 & region_c<=17
replace region=2	if region_c>=21 & region_c<=29
replace region=3	if region_c>=31 & region_c<=35
replace region=4	if region_c>=41 & region_c<=43
replace region=5	if region_c>=50 & region_c<=53
label define region 1 "Norte" 2 "Nordeste" 3 "Sudeste/leste" 4 "Sul" 5 "Centro Oeste"
label value region region
label var region "Distribución regional del país"

**Região Metropolitana e Região Administrativa Integrada de Desenvolvimento
gen area=.
replace area=1 if zona_c==1 & (v1023!=1 | v1023!=2)
replace area=2 if zona_c==0 & (v1023!=1 | v1023!=2)
replace area=3 if v1023==1 | v1023==2
label define area 1 "Urbana" 2 "Rural" 3 "Metropolitana" 
label value area area
label var area "Area del pais"

***********
***lp_ci***
***********
*AJAM: En Brasil se consideran pobres aquellas familias con una renta familiar per capita mensual menor a la mitad de un salario mínimo
gen lp_ci=.	
/*
gen lp_ci=.			
replace lp_ci= 281.41 	if region_c==33	& area==3                /*Rio de janeiro-metropolitano*/	
replace lp_ci= 238.77 	if region_c==33	& area==1	             /*Rio de janeiro-urbano*/
replace lp_ci= 214.89 	if region_c==33	& area==2	             /*Rio de janeiro-rural*/
replace lp_ci= 283.11 	if region_c==35	& area==3	             /*Sao Paulo-metropolitano*/
replace lp_ci= 250.71 	if region_c==35	& area==1	             /*Sao paulo-urbano*/
replace lp_ci= 204.66 	if region_c==35	& area==2	             /*Sao paulo-rural*/
replace lp_ci= 313.81 	if region==4	& area==3	& region_c==43 /*Porto alegre: sur-metropolitana-rio grande de sul*/
replace lp_ci= 259.24 	if region==4	& area==3	& region_c==41 /*curitiba:     sur-metropolitana-paraná*/
replace lp_ci= 247.30 	if region==4	& area==1            /*sur-urbana*/	
replace lp_ci= 225.13 	if region==4	& area==2            /*sur-rural */	
replace lp_ci= 223.42  	if region==2	& area==3	& region_c==23 /*Fortaleza:    noreste-metropolitana-ceará*/
replace lp_ci= 293.35 	if region==2	& area==3	& region_c==26 /*recife:       noreste-metropolitana-pernambuco*/
replace lp_ci= 276.29 	if region==2	& area==3	& region_c==29 /*salvador:     noreste-metropolitana-bahia*/
replace lp_ci= 252.41 	if region==2	& area==1            /*noreste-urbana*/	
replace lp_ci= 225.13 	if region==2	& area==2            /*noreste-rural*/	
replace lp_ci= 220.01 	if region==3	& area==3	& region_c==31 /*belo horizonte:sureste-metropolitana-minas gerais*/
replace lp_ci= 197.84 	if region==3	& area==1            /*sudeste-urbano*/	
replace lp_ci= 168.84 	if region==3	& area==2            /*sudeste-rural*/	
replace lp_ci= 250.71 	if region==1	& area==3	& region_c==15 /*belem: noreste-metropolitana-pará*/
replace lp_ci= 259.24 	if region==1	& area==1            /*norte-urbano*/	
replace lp_ci= 226.83 	if region==1	& area==2            /*norte-rural */	
replace lp_ci= 243.89 	if region_c==53	& area==3	             /*Distrito federal-metropolitana*/
replace lp_ci= 209.78 	if region==5	& area==1            /*centro oeste-urbano*/	
replace lp_ci= 184.19 	if region==5	& area==2            /*centro oeste-rural */	
label var lp_ci "Linea de pobreza oficial del pais"
*/

***********
*lpe_ci ***
***********
gen lpe_ci=.
/*
replace lpe_ci= 140.70 	if region_c==33	& area==3		    /*Rio de janeiro-metropolitano*/
replace lpe_ci= 119.38 	if region_c==33	& area==1		    /*Rio de janeiro-urbano*/
replace lpe_ci= 107.45 	if region_c==33	& area==2		    /*Rio de janeiro-rural*/
replace lpe_ci= 141.56 	if region_c==35	& area==3		    /*Sao Paulo-metropolitano*/
replace lpe_ci= 125.35 	if region_c==35	& area==1		    /*Sao paulo-urbano*/
replace lpe_ci= 102.33 	if region_c==35	& area==2		    /*Sao paulo-rural*/
replace lpe_ci= 156.91 	if region==4	& area==3	& region_c==43	/*Porto alegre: sur-metropolitana-rio grande de sul*/
replace lpe_ci= 129.62 	if region==4	& area==3	& region_c==41	/*curitiba:     sur-metropolitana-paraná*/
replace lpe_ci= 123.65 	if region==4	& area==1		/*sur-urbana*/
replace lpe_ci= 112.56 	if region==4	& area==2		/*sur-rural */
replace lpe_ci= 111.71 	if region==2	& area==3	& region_c==23	/*Fortaleza:    noreste-metropolitana-ceará*/
replace lpe_ci= 146.67 	if region==2	& area==3	& region_c==26	/*recife:       noreste-metropolitana-pernambuco*/
replace lpe_ci= 138.15 	if region==2	& area==3	& region_c==29	/*salvador:     noreste-metropolitana-bahia*/
replace lpe_ci= 126.21 	if region==2	& area==1		/*noreste-urbana*/
replace lpe_ci= 112.56 	if region==2	& area==2		/*noreste-rural*/
replace lpe_ci= 110.00 	if region==3	& area==3	& region_c==31	/*belo horizonte:sureste-metropolitana-minas gerais*/
replace lpe_ci= 98.92 	if region==3	& area==1		/*sudeste-urbano*/
replace lpe_ci= 84.42 	if region==3	& area==2		/*sudeste-rural*/
replace lpe_ci= 125.35 	if region==1	& area==3	& region_c==15	/*belem: noreste-metropolitana-pará*/
replace lpe_ci= 129.62 	if region==1	& area==1		/*norte-urbano*/
replace lpe_ci= 113.42 	if region==1	& area==2		/*norte-rural */
replace lpe_ci= 121.94 	if region_c==53	& area==3		    /*Distrito federal-metropolitana*/				
replace lpe_ci= 104.89 	if region==5	& area==1		/*centro oeste-urbano*/
replace lpe_ci= 92.10 	if region==5	& area==2		/*centro oeste-rural */
label var lpe_ci "Linea de indigencia oficial del pais"
*/

*************
**salmm_ci***
*************
gen salmm_ci=1100 //https://www.dmtemdebate.com.br/nota-tecnica-dieese-n-249-salario-minimo-em-2021-sera-de-r-1-10000/
label var salmm_ci "Salario minimo legal"


************
***emp_ci***
************
gen emp_ci=(condocup_ci==1)

***************
***desemp_ci***
***************
gen desemp_ci=(condocup_ci==2)

************
***pea_ci***
************
gen pea_ci=(emp_ci==1 | desemp_ci==1)

***************
***formal_ci***
***************
gen formal_ci=(cotizando_ci==1)

*Formalidad sin restringir a PEA.
gen formal_1=(cotizando_ci1==1)

*****************
***desalent_ci***
*****************
*Definición nacional (variable derivada)
gen desalent_ci=.
label var desalent_ci "Trabajadores desalentados"

*****************
***horaspri_ci***
*****************
*Pregunta se hace para mayores de 14 años, solo por actividad principal, información de trabajo infantil se publica en módulo separado de la base anual
gen horaspri_ci=v4039
replace horaspri_ci=. if emp_ci==0
label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"

*****************
***horastot_ci***
*****************
*Variable derivada por IBGE, para personas de 14 o más, por todos los trabajos 
*Horas efectivas
*corregir variable derivada vd4035 en 2021
egen vd4035_fixed= rsum(v4039c v4056c v4062c) if v2009>=14 & v4009!=.
gen horastot_ci=vd4035_fixed
replace horastot_ci=. if emp_ci==0 
replace horastot_ci=. if (horaspri_ci==. & v4056==. & v4062==.) | horastot_ci>150
label var horastot_ci "Horas efectivas trabajadas semana referencia en todos los empleos"

***************
***subemp_ci***
***************
gen subemp_ci=(horastot_ci<30 & v4063a==1 & v4064a==1)
label var subemp_ci "Personas en subempleo por horas"

*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci=((horaspri_ci>=1 & horaspri_ci<30) & v4063a==2 & emp_ci==1)
replace tiempoparc_ci=. if emp_ci==0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

******************
***categopri_ci***
******************
* Corregir variables derivadas vd4008 y vd4009 en 2021
gen vd4008_fixed=.
replace vd4008_fixed=1 if v2009>=14 & v4009!=. & v4012==3
replace vd4008_fixed=2 if v2009>=14 & v4009!=. & v4012==1
replace vd4008_fixed=3 if v2009>=14 & v4009!=. & (v4012==2 | v4012==4)
replace vd4008_fixed=4 if v2009>=14 & v4009!=. & v4012==5
replace vd4008_fixed=5 if v2009>=14 & v4009!=. & v4012==6
replace vd4008_fixed=6 if v2009>=14 & v4009!=. & v4012==7

gen vd4009_fixed=.
replace vd4009_fixed=1 if v2009 >= 14 & v4009 !=. & v4012==3 & v4029==1
replace vd4009_fixed=2 if v2009 >= 14 & v4009 !=. & v4012==3 & v4029==2
replace vd4009_fixed=3 if v2009 >= 14 & v4009 !=. & v4012==1 & v4029==1
replace vd4009_fixed=4 if v2009 >= 14 & v4009 !=. & v4012==1 & v4029==2
replace vd4009_fixed=5 if v2009 >= 14 & v4009 !=. & v4012==4 & v4029==1
replace vd4009_fixed=6 if v2009 >= 14 & v4009 !=. & v4012==4 & v4029==2
replace vd4009_fixed=7 if v2009 >= 14 & v4009 !=. & (v4012==2 | (v4012==4 & v4028==1))
replace vd4009_fixed=8 if v2009 >= 14 & v4009 !=. & v4012==5
replace vd4009_fixed=9 if v2009 >= 14 & v4009 !=. & v4012==6
replace vd4009_fixed=10 if v2009>= 14 & v4009 !=. & v4012==7

*Ahora usamos las variables fixed
generate aux08 =.
replace  aux08 = 1 if vd4009_fixed>=1 & vd4009_fixed<=7
replace  aux08 = 2 if vd4009_fixed==9
replace  aux08 = 3 if vd4009_fixed==8
replace  aux08 = 4 if vd4009_fixed==10 | v40121!=.
*AJAM-18. Se usan las variables derivadas, principalmente porque vd4009 está más desagregada, pero podría usarse la v4012. 
*También, base no divide más entre agrícolas/no agrícolas
gen categopri_ci=.
replace categopri_ci=1 if  vd4008_fixed==4 | aux08==3
replace categopri_ci=2 if  vd4008_fixed==5 | aux08==2
replace categopri_ci=3 if (vd4008_fixed>=1 & vd4008_fixed<=3) | aux08==1
replace categopri_ci=4 if vd4008_fixed==6 | aux08==4
replace categopri_ci=. if emp_ci!=1
label define categopri_ci 1"Patron" 2"Cuenta propia" 0"Otro"
label define categopri_ci 3"Empleado" 4" No remunerado" , add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional"
drop aux08 
 
******************
***categosec_ci***
******************
generat categosec_ci=1 if v4043==5
replace categosec_ci=2 if v4043==6
replace categosec_ci=3 if v4043>=1 & v4043<=4
replace categosec_ci=4 if v4043==7
replace categosec_ci=. if emp_ci!=1 
label define categosec_ci 1 "Patron" 2 "Cuenta propia" 0 "Otro" 
label define categosec_ci 3 "Empleado" 4 "No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"

*****************
***nempleos_ci***
*****************
generat nempleos_ci=1 if v4009==1
replace nempleos_ci=2 if v4009==2 | v4009==3
replace nempleos_ci=. if v4009==.
label var nempleos_ci "Número de empleos"

*****************
***spublico_ci***
*****************
gen spublico_ci=(vd4008_fixed==3)
replace spublico_ci=. if emp_ci!=1
label var spublico_ci "Personas que trabajan en el sector público"

**************
***ocupa_ci***
**************
*Base usa la 'Classificação de Ocupações para as Pesquisas Domiciliares – COD'
gen ocupa_ci=.
replace ocupa_ci=1 if vd4011==2 | vd4011==3 & emp_ci==1
replace ocupa_ci=2 if vd4011==1 & emp_ci==1
replace ocupa_ci=3 if vd4011==4 & emp_ci==1
replace ocupa_ci=4 if (v4010>=5211 & v4010<=5249) & emp_ci==1 //COD agrega comerciantes y de servicios, por eso usamos variable original para estas dos categorías
replace ocupa_ci=5 if ((v4010>=5111 & v4010<=5169) | (v4010>=5311 & v4010<=5419) | (v4010>=9111 & v4010<=9129) | (v4010>=9411 & v4010<=9510)) & emp_ci==1  //Idem al comentario anterior
replace ocupa_ci=6 if (vd4011==6 | (v4010>=9211 & v4010<=9216)) & emp_ci==1
replace ocupa_ci=7 if (vd4011==7 | vd4011==8 | (v4010>=9311 & v4010<=9329)) & emp_ci==1
replace ocupa_ci=8 if vd4011==10 & emp_ci==1 
replace ocupa_ci=9 if ((vd4011==9 & ocupa_ci!=5 & ocupa_ci!=6 & ocupa_ci!=7)| vd4011==11) & emp_ci==1
label variable ocupa_ci "Ocupacion laboral"
label define ocupa_ci 1 "profesional y tecnico" 2"director o funcionario sup" 3 "administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci

*************
***rama_ci***
*************
*Base usa la 'CNAE-Domiciliar' 2.0, ver http://www.cnaedom.ibge.gov.br/estrutura.asp?TabelaBusca=CNAE_200@CNAE%20Domiciliar%20%202.0
gen rama_ci=.
replace rama_ci=1 if v4013>1101 & v4013<3002
replace rama_ci=2 if v4013>=5000 & v4013<=9000 
replace rama_ci=3 if v4013>=10010 & v4013<=33002 
replace rama_ci=4 if v4013>=35010 & v4013<=35022
replace rama_ci=5 if v4013>=41000 & v4013<=43000 
replace rama_ci=6 if v4013>=45010 & v4013<=48100
replace rama_ci=7 if v4013>=49010 & v4013<=56020
replace rama_ci=8 if v4013>=64000 & v4013<=68000
replace rama_ci=9 if (v4013>=69000 & v4013<=99000) |  (v4013>=58000 & v4013<=63000)
replace rama_ci=. if emp_ci==0
label var rama_ci "Rama de actividad"
label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val rama_ci rama_ci


* rama secundaria
gen ramasec_ci=.
replace ramasec_ci=1 if v4044>1101 & v4044<3002
replace ramasec_ci=2 if v4044>=5000 & v4044<=9000 
replace ramasec_ci=3 if v4044>=10010 & v4044<=33002 
replace ramasec_ci=4 if v4044>=35010 & v4044<=35022
replace ramasec_ci=5 if v4044>=41000 & v4044<=43000 
replace ramasec_ci=6 if v4044>=45010 & v4044<=48100
replace ramasec_ci=7 if v4044>=49010 & v4044<=56020
replace ramasec_ci=8 if v4044>=64000 & v4044<=68000
replace ramasec_ci=9 if (v4044>=69000 & v4044<=99000) |  (v4044>=58000 & v4044<=63000)
replace ramasec_ci=. if emp_ci==0
label var ramasec_ci "Rama de actividad laboral de la ocupación secundaria"
label def ramasec_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def ramasec_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def ramasec_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val ramasec_ci ramasec_ci

****************
***durades_ci***
****************
*AJAM, 06-18, base nueva permite construir la variable en número de meses, debido a mayor detalle de variables	
gen durades_ci=.
replace durades_ci=v40761 if v4071==1 & condocup_ci==2 & v40761!=. //buscando empleo durante menos de un anio
replace durades_ci=v40762+12 if v4071==1 & condocup_ci==2 & v40762!=.  //buscando empleo durante 1 a 2 anios
replace durades_ci=v40763+24 if v4071==1 & condocup_ci==2 & v40763!=. //buscando empleo durante más de 2 anios
label val durades_ci durades1_ci
label variable durades_ci "Duracion del desempleo en meses"

*******************
***antiguedad_ci***
*******************
gen aux2=v40401/12
gen aux3=(v40402/12)+12
egen antiguedad_ci=rsum(v40403 aux2 aux3) if emp_ci==1
replace antiguedad_ci=. if v40403==. & v40401==. & v40402==.
drop aux*
label var antiguedad_ci "Antiguedad en la actividad actual en anios"

**************
***INGRESOS***
**************
*Base restringe respuestas para mayores de 14 anios de edad
*AJAM 2018, no se imputan valores de beneficios (vivienda, alimentación, ropa),
*siguiendo los guidelines de la nota metodológica al respecto, 
*ver p.36: file:///Y:/survey/BRA/PNADC/2016/a/docs/liv101561_notas_tecnicas.pdf

***************
***ylmpri_ci***
***************
gen ylmpri_ci=v403312 
replace ylmpri_ci=. if v403312<0 | v403312>=999999 | emp_ci!=1
label var ylmpri_ci "Ingreso laboral monetario actividad principal" 

*****************
***nrylmpri_ci***
*****************
gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)
replace nrylmpri_ci=. if emp_ci!=1
label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  

****************
***ylnmpri_ci***
****************
gen ylnmpri_ci=v403322 if v40332==2
replace ylnmpri_ci=. if v403322<0 | v403322>=999999 | emp_ci!=1
label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal"  

***************
***ylmsec_ci***  
***************
gen ylmsec_ci=v405012
replace ylmsec_ci=. if v405012<0 | v405012>=999999 | emp_ci!=1
label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 

****************
***ylnmsec_ci***
****************
gen ylnmsec_ci=v405022
replace ylnmsec_ci=. if v405022<0 | v405022>=999999 | emp_ci!=1
label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

*****************
***ylmotros_ci***
*****************
gen ylmotros_ci=v405812
replace ylmotros_ci=. if v405812<0 | v405812>=999999 | emp_ci!=1
label var ylmotros_ci "Ingreso laboral monetario de otros trabajos" 

******************
***ylnmotros_ci***
******************
gen ylnmotros_ci=v405822 if edad_ci>=10
replace ylnmotros_ci=. if v405822<0 | v405822>=20000 | emp_ci!=1
label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 

************
***ylm_ci***
************
egen ylm_ci=rsum(ylmpri_ci ylmsec_ci ylmotros_ci)
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==. & ylmotros_ci==.
label var ylm_ci "Ingreso laboral monetario total"  

*************
***ylnm_ci***
*************
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci)
replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==. & ylnmotros_ci==.
label var ylnm_ci "Ingreso laboral NO monetario total"  

*************
***ynlm_ci*** // sale modulo de caracteristicas de la vivienda y otros rendimientos 
*************
foreach var of varlist v5004a2 v5006a2 v5007a2 v5001a2 v5002a2 v5003a2 { 
replace `var'=. if `var'>=999999 | `var'<0
}

egen ynlm_ci=rsum(v5004a2 v5006a2 v5007a2 v5001a2 v5002a2 v5003a2 v5001a2) if edad_ci>=10
replace ynlm_ci=. if (v5004a2==. &  v5006a2==. &  v5007a2==. &  v5001a2==. &  v5002a2==. &  v5003a2==. & v5001a2==.) | ynlm_ci<0
label var ynlm_ci "Ingreso no laboral monetario"

*************
***ylnm_ci***
*************
gen ynlnm_ci=.
label var ynlnm_ci "Ingreso no laboral no monetario" 
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)


************
***ylm_ch***
************
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1
label var ylm_ch "Ingreso laboral monetario del hogar"

*************
***ylnm_ch***
*************
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1
label var ylnm_ch "Ingreso laboral no monetario del hogar"

****************
*** ylmnr_ch ***
****************
sort idh_ch 
by idh_ch: egen nrylmpri_ch=max(nrylmpri_ci) if miembros_ci==1
by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1
replace ylmnr_ch=. if nrylmpri_ch==1
label var ylmnr_ch "Ingreso laboral monetario del hogar"

***************
*** ynlm_ch ***
***************
by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1
label var ynlm_ch "Ingreso no laboral monetario del hogar"

**************
***ynlnm_ch***
**************
gen ynlnm_ch=.
label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

****************
***ylhopri_ci***
****************
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
replace ylmhopri_ci=. if ylmhopri_ci<=0
label var ylmhopri_ci "Salario monetario de la actividad principal"

**************
***ylmho_ci***
**************
gen ylmho_ci=ylm_ci/(horaspri_ci*4.3)
replace ylmho_ci=. if ylmho_ci<=0
label var ylmho_ci "Salario monetario de todas las actividades" 

********
***NA***
********
*gen rentaimp_ch=s01019 if s01017==3
gen rentaimp_ch= . 
label var rentaimp_ch "Rentas imputadas del hogar"

gen autocons_ci=.
label var autocons_ci "Autoconsumo reportado por el individuo"

gen autocons_ch=.
label var autocons_ch "Autoconsumo reportado por el hogar"

****************
***remesas_ci***
****************
gen remesas_ci=.
label var remesas_ci "Remesas mensuales reportadas por el individuo" 

****************
***remesas_ch***
****************
gen remesas_ch=.
label var remesas_ch "Remesas mensuales del hogar" 

****************************
***	VARIABLES EDUCATIVAS ***
****************************

/*

# Historial de modificaciones #
#=============================#

*Modificado por Agustina Thailinger y Pia Iocco (SCL/EDU) 3-28-2020
*Modificado por Manuel Marcos(SCL/EDU) 2026-8-10

# Variables insumos consideradas #
#================================#

v2009: Idade do morador na data de referência
v3002: ... frequenta escola?
v3002a: A escola que ... frequenta é de
v3003a: Qual é o curso que ... frequenta?
v3005a: Esse curso que .... frequenta é organizado em
v3006: Qual é o ano/série/semestre que ... frequenta?
V3008: Anteriormente ... frequentou escola?
v3009a: Qual foi o curso mais elevado que ... frequentou anteriormente?
v3011a: Esse curso que .... frequentou era organizado em:
v3013: Qual foi o último ano/série/semestre que ... concluiu com aprovação, neste curso que frequentou anteriormente
v3012: ... concluiu com aprovação, pelo menos a primeira série deste curso que frequentou anteriormente?
v3014: ... concluiu este curso que frequentou anteriormente

# Indicadores a construir #
#=========================#

1. aedu_ci: número de años de educación culminados
2. edupre_ci: variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo
3. eduui_ci: variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica o universitaria incompleta y con 0 el resto
4. eduuc_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica, universitaria completa, o posgrado (completa o incompleta), y con 0 el resto
5. eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto
6. asiste_ci: Variable dicotómica que indica si la persona asiste actualmente a un centro educativo (de cualquier nivel educativo: preescolar, primaria, secundaria, y terciaria) de educación formal al momento de la encuesta.
7. edupub_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza pública al momento de la encuesta, con 0 si asiste a un centro de enseñanza privada, y con perdido si no asiste o no responde a la pregunta. 
8. asispre_ci: Asistencia a preescolar. Variable dicotómica que indica con valor 1 si la persona asiste actualmente a educación preescolar, y con 0 al resto (no tiene valores perdidos). 
9. razonesnoasis_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela

# Notas para la construcción de variables #
#=========================================#

- grado_asist: el valor de "13" es "Curso no clasificado por series o cursos"
- Ensino fundamental. Se resta uno porque preguntan el grado al que asisten, no el máximo alcanzado. Se infiere que el anterior es el completado
- Ensino medio. Tienen que haber completado los 9 anios de ensino fundamental (antes eran 8)
- Universitario. No incluye postgrados. Tienen que haber completado los 9 anios de ensinio fundamental y los 3 anios de ensinio medio, 12 en total
- Especializacion o diplomado. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están. Se imputa que completaron todo superior.
- Maestria. Se imputa pregrado completo. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están
- Doctorado. Se imputa maestría completa. Desde el nivel 9 y superior no se les pregunta en que anio o trimestre están
- grado_asist_sup: pasa de semestres a años para superior para el grupo de personas que están cursando
- grado_asist_sup_v2: pasa de semestres a años para superior para el grupo de personas que ya terminaron sus estudios

*/

*************
***aedu_ci***
*************

gen grado_asist = v3006
replace grado_asist = . if v3006 == 13 

* Para quienes asisten actualmente a superior en semestres se convierte a años
gen grado_asist_sup = round(grado_asist/2) if v3005a == 1 & v3003a == 8

* Para quienes ya no asisten pero cursaron superior en semestres se convierte a años
gen grado_asist_sup_v2 = round(v3013/2) if v3011a == 1 & v3009a == 12

gen aedu_ci = .

* Construcción para quienes están estudiando
replace aedu_ci = 0 if v3003a == 2 | v3003a == 3                   						// Sin años de educación
replace aedu_ci = grado_asist - 1 if v3003a == 4                   						// Ensinio fundamental 
replace aedu_ci = 9 + grado_asist - 1 if v3003a == 6               						// Ensinio medio
replace aedu_ci = grado_asist - 1 if v3003a == 5                   						// Ensinio fundamental jóvenes y adultos
replace aedu_ci = 9 + grado_asist - 1 if v3003a == 7               						// Ensinio medio    
replace aedu_ci = 12 + grado_asist_sup - 1 if v3003a == 8          						// Ensinio superior
replace aedu_ci = 12 + 4 if v3003a == 9                            						// Especialização de nível superior
replace aedu_ci = 12 + 4 if v3003a == 10                           						// Mestrado
replace aedu_ci = 12 + 4 + 2 if v3003a == 11                       						// Doutorado
						
* Construcción para quienes NO están estudiando						
replace aedu_ci=0 if v3008==2                                      						// Nunca asistieron 
replace aedu_ci = 0 if inlist(v3009a, 2, 3, 4)                     						// Creche, prescola, Alfabetizacion de jovenes y adultos, Classe de alfabetização - CA.
replace aedu_ci = v3013 if v3009a == 5                             						// Antigo primário. No se resta 1 porque la variable indica si lo concluyo o no
replace aedu_ci = v3013 + 4 if v3009a == 6                         						// Antigo ginásio. Despues de antigo primário (4 anios)
replace aedu_ci = v3013 if v3009a == 7                             						// Regular do ensino fundamental ou do 1º grau. No se resta 1 porque la variable indica si lo concluyo o no
replace aedu_ci = v3013 if v3009a == 8                             						// Nivelacion de primaria para adultos
replace aedu_ci = v3013 + 4 + 4 if v3009a == 9  & v3012 == 1       						// Antigo científico, clássico, etc. Despues de antigo primário y antigo ginásio (8 anios)
replace aedu_ci = v3013 + 9 if v3009a == 10                        						// Regular do ensino médio óu do 2º grau. Despues de ensinio fundamental (9 anios)
replace aedu_ci = v3013 + 9 if v3009a == 11                        						// Nivelacion de adultos secundaria
replace aedu_ci = grado_asist_sup_v2 + 12 if v3009a == 12          						// Universitario pregrado
replace aedu_ci = 12 + 4 if v3009a == 13 & (v3014 != 1 | missing(v3014)) 				// Especializacion o diplomado, no terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 13 & v3014 == 1          						// Especializacion o diplomado, terminado
replace aedu_ci = 12 + 4 if v3009a == 14 & (v3014 != 1 | missing(v3014))              	// Maestria, no terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 14 & v3014 == 1          						// Maestria, terminado
replace aedu_ci = 12 + 4 + 2 if v3009a == 15 & (v3014 != 1 | missing(v3014))  			// Doctorado, no terminado    
replace aedu_ci = 12 + 4 + 2 + 4 if v3009a == 15 & v3014 == 1      						// Doctorado, terminado 

* Reemplazo cuando el grado está missing pero el nivel se reporta (para quienes están estudiando)
replace aedu_ci = 0  if missing(aedu_ci) & v3003a >= 2 & v3003a <= 5
replace aedu_ci = 9  if missing(aedu_ci) & (v3003a == 6 | v3003a == 7)
replace aedu_ci = 12 if missing(aedu_ci) & v3003a == 8
replace aedu_ci = 16 if missing(aedu_ci) & (v3003a == 9 | v3003a == 10)
replace aedu_ci = 18 if missing(aedu_ci) & v3003a == 11

* Reemplazo cuando el grado está missing pero el nivel se reporta (para quienes NO están estudiando)
replace aedu_ci = 0  if missing(aedu_ci) & v3009a >= 2 & v3009a <= 5
replace aedu_ci = 4  if missing(aedu_ci) & v3009a == 6
replace aedu_ci = 4  if missing(aedu_ci) & (v3009a == 7 | v3009a == 8)
replace aedu_ci = 8  if missing(aedu_ci) & v3009a == 9
replace aedu_ci = 9  if missing(aedu_ci) & (v3009a == 10 | v3009a == 11)
replace aedu_ci = 12 if missing(aedu_ci) & v3009a == 12
replace aedu_ci = 16 if missing(aedu_ci) & (v3009a == 13 | v3009a == 14)
replace aedu_ci = 18 if missing(aedu_ci) & v3009a == 15

***************
***edupre_ci***
***************

* NOTA: No cuenta con preguntas para esta variable

gen byte edupre_ci=.

**************
***eduui_ci***
**************

gen eduui_ci = .
replace eduui_ci = 1 if !missing(aedu_ci) & (v3003a == 8 | (v3009a == 12 & v3014 == 2))
replace eduui_ci = 0 if !missing(aedu_ci) & !(v3003a == 8 | (v3009a == 12 & v3014 == 2))

**************
***eduuc_ci***
**************

gen eduuc_ci = .
replace eduuc_ci = 1 if !missing(aedu_ci) & ((v3009a == 12 & v3014 == 1) | inlist(v3003a, 9, 10, 11) | inlist(v3009a, 13, 14, 15))
replace eduuc_ci = 0 if !missing(aedu_ci) & !((v3009a == 12 & v3014 == 1) | inlist(v3003a, 9, 10, 11) | inlist(v3009a, 13, 14, 15))
                             

**************
***eduac_ci***
**************

* NOTA: No cuenta con preguntas para esta variable

gen byte eduac_ci=.

**************
**asiste_ci***
**************

gen asiste_ci = .
replace asiste_ci = 1 if !missing(v3002) & v3002 == 1
replace asiste_ci = 0 if !missing(v3002) & v3002 != 1

***************
***edupub_ci***
***************

gen edupub_ci = .
replace edupub_ci = 1 if !missing(v3002a) & v3002a == 2
replace edupub_ci = 0 if !missing(v3002a) & v3002a != 2

****************
***asispre_ci***
****************

*Creación de la variable asistencia a preescolar por Iván Bornacelly - 01/12/17

gen asispre_ci = 0
replace asispre_ci = 1 if v2009 >= 4 & v3003a == 2


******************
***razonesnoasis_ci***
******************

* NOTA: No cuenta con preguntas para esta variable

gen razonesnoasis_ci = .

**************
* Line of code with indicator eduno_ci was deleted**************
* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted
**************
* Line of code with indicator edupi_ci was deleted**************
* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
**************
* Line of code with indicator edupc_ci was deleted**************
* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
**************
* Line of code with indicator edusi_ci was deleted**************
* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted
**************
* Line of code with indicator edusc_ci was deleted**************
* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted
***************
* Line of code with indicator edus1i_ci was deleted***************
* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted
***************
* Line of code with indicator edus1c_ci was deleted***************
* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted
***************
* Line of code with indicator edus2i_ci was deleted***************
* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted
***************
* Line of code with indicator edus2c_ci was deleted***************
* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted
*****************
* Line of code with indicator pqnoasis_ci was deleted*****************
* Line of code with indicator pqnoasis_ci was deleted* Line of code with indicator pqnoasis_ci was deleted
***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted* Line of code with indicator repite_ci was deleted
******************
* Line of code with indicator repiteult was deleted* Line of code with indicator repiteult was deleted		

        
		**********************************
		**** VARIABLES DE LA VIVIENDA ****
		**********************************

		
****************
***aguared_ch***
****************
gen aguared_ch=.


*****************
*aguafconsumo_ch*
*****************

gen aguafconsumo_ch=0


*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.


*************
*aguadist_ch*
*************
gen aguadist_ch=0


**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =9


**************
*aguadisp2_ch*
**************
gen aguadisp2_ch =9


*************
*aguamala_ch*  Altered
*************
gen aguamala_ch=.



*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch=.


*****************
***aguamide_ch***
*****************
gen aguamide_ch=.

*****************
*bano_ch         *  Altered
*****************
gen bano_ch=.



***************
***banoex_ch***
***************
gen banoex_ch=9


*****************
*banomejorado_ch*  Altered
*****************
gen banomejorado_ch=.


************
*sinbano_ch*
************
gen sinbano_ch =.


*************
*aguatrat_ch*
*************
gen aguatrat_ch =9
		

************
***luz_ch***
************
gen luz_ch=.
label var luz_ch  "La principal fuente de iluminación es electricidad"

****************
***luzmide_ch***
****************
gen luzmide_ch=.
label var luzmide_ch "Usan medidor para pagar consumo de electricidad"

****************
***combust_ch***
****************
gen combust_ch=.
label var combust_ch "Principal combustible gas o electricidad" 


*************
***des1_ch***
*************
*En esta base no existe opción de fossa rudimentar, la cuál se clasificaba como 2"Letrina o conectado a pozo ciego"


gen des1_ch=.
label var des1_ch "Tipo de desague según unimproved de MDG"

*************
***des2_ch***
*************
*El indicador debería ser una reclasificación de des1_ch, por ello se cambia aquí: 


gen des2_ch=.
label var des2_ch "Tipo de desague sin incluir definición MDG"


*************
***piso_ch***
*************

gen piso_ch=.
label var piso_ch "Materiales de construcción del piso"  


**************
***pared_ch***
**************

gen pared_ch=.
label var pared_ch "Materiales de construcción de las paredes"


**************
***techo_ch***
**************
*No existe más opción de paja

gen techo_ch=.
label var techo_ch "Materiales de construcción del techo"


**************
***resid_ch***
**************

gen resid_ch=.
label var resid_ch "Método de eliminación de residuos"

				
*************
***dorm_ch***
*************


gen dorm_ch=.
label var dorm_ch "Habitaciones para dormir"

****************
***cuartos_ch***
****************

gen cuartos_ch=.
label var cuartos_ch "Habitaciones en el hogar"

***************
***cocina_ch***
***************
gen cocina_ch=.
label var cocina_ch "Cuarto separado y exclusivo para cocinar"

**************
***telef_ch***
**************

gen telef_ch=.
label var telef_ch "El hogar tiene servicio telefónico fijo"

***************
***refrig_ch***
***************

gen refrig_ch=.
label var refrig_ch "El hogar posee refrigerador o heladera"

**************
***freez_ch***
**************
gen freez_ch=.
label var freez_ch "El hogar posee congelador"

*************
***auto_ch***
*************

gen auto_ch=.
label var auto_ch "El hogar posee automovil particular"

**************
***compu_ch***
**************

gen compu_ch=.
label var compu_ch "El hogar posee computador"

*****************
***internet_ch***
*****************

gen internet_ch=.
label var internet_ch "El hogar posee conexión a Internet"

************
***cel_ch***
************

gen cel_ch=.
label var cel_ch "El hogar tiene servicio telefonico celular"

**************
***vivi1_ch***
**************

gen viv1_ch=.
label var viv1_ch "Tipo de vivienda en la que reside el hogar"


**************
***vivi2_ch***
**************

gen viv2_ch=.
label var viv2_ch "La vivienda es casa o departamento"

*****************
***viviprop_ch***
*****************

gen viviprop_ch=.
label var viviprop_ch "Propiedad de la vivienda"


****************
***vivitit_ch***
****************
gen vivitit_ch=.
label var vivitit_ch "El hogar posee un título de propiedad"

****************
***vivialq_ch***
****************


gen vivialq_ch=.
label var vivialq_ch "Alquiler mensual"

*******************
***vivialqimp_ch***
*******************

gen vivialqimp_ch=.
label var vivialqimp_ch "Alquiler mensual imputado"

***************
***tamemp_ci***
***************
gen tamemp_ci=1 if v4018==1
replace tamemp_ci=2 if v4018==2
replace tamemp_ci=3 if v4018==3 | v4018==4
label var  tamemp_ci "Tamaño de Empresa" 
label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
label values tamemp_ci tamaño

*******************
***categoinac_ci***
*******************
gen categoinac_ci=.
replace categoinac_ci=1 if v5004a==1 & condocup_ci==3
replace categoinac_ci=2 if vd4030==2 & condocup_ci==3
replace categoinac_ci=3 if vd4030==1 & condocup_ci==3
replace categoinac_ci=4 if condocup_ci==3 & (categoinac_ci!=1 & categoinac_ci!=2 & categoinac_ci!=3)
label var  categoinac_ci "Condición de Inactividad" 
label define inactivo 1"Pensionado" 2 "Estudiante" 3"Hogar" 4"Otros"
label values categoinac_ci inactivo

*****************
***benefdes_ci***
*****************
*Se le pregunta sobre monto de seguro desempleo, pero en conjunto con otros beneficios (becas, rendimientos financieros, ayuda a presos, etc.)
g benefdes_ci=(v5005a==1)
label var benefdes_ci "=1 si tiene seguro de desempleo"

*******************
*** ybenefdes_ci***
*******************
g ybenefdes_ci=v5005a2
label var ybenefdes_ci "Monto de seguro de desempleo"

*variables que faltan generar
gen tcylmpri_ci=.
gen tcylmpri_ch=.
gen vivi1_ch =.
gen vivi2_ch =.
gen tipopen_ci=.

****************************
***VARIABLES DE MIGRACION***
****************************
* Variables incluidas por SCL/MIG Fernando Morales

*****************
***migrante_ci***
******************
gen migrante_ci=.
label var migrante_ci "=1 si es migrante"
	
********************
***migantiguo5_ci***
********************
gen migantiguo5_ci=.
label var migantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
********************
***migrantelac_ci***
********************
gen migrantelac_ci=.
label var migrantelac_ci "=1 si es migrante proveniente de un pais LAC"

*********************
***migrantiguo5_ci***
*********************
gen migrantiguo5_ci=.
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
	
***************
***miglac_ci***
***************
gen miglac_ci=.
label var miglac_ci "=1 si es migrante proveniente de un pais LAC"

******************************
* Variables SPH - PMTC y PNC *
******************************

*PTMC: Recibió bolsa familia
*PNC: Benefício de Prestação Continuada (adultos mayores)
*Otros: Outros programas sociais do governo y Beneficio de Prestação Continuada (discapacidad)

duplicates re  idp_ci idh_ch // no identifican de manera unica
duplicates drop idh_ch idp_ci, force // se dropean porque en esta base, representan menos del 1% de la muestra (consultar protocolo D.1.1.2 Revisión de bases rax)

**Miembros del hogar (Incluyendo los no parientes)
gen x=1
bys idh_ch: egen nmiembros_sph_ch= sum(x)


*Ingreso del hogar
egen y_hog_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
bys idh_ch: egen y_hog_ch = sum(y_hog_ci)

******PTMC******
*ingreso por transferencias
egen ing_ptmc_ci=rowtotal(v5002a2) // valor mensual de bolsa familia
replace ing_ptmc_ci = . if v5002a2 == .
bys idh_ch:egen ing_ptmc_ch = sum(ing_ptmc_ci)

*Personas y hogares que reciben transferencias
gen ptmc_ci = 0
replace ptmc_ci = 1 if v5002a == 1
replace ptmc_ci = 1 if ing_ptmc_ci != . & ing_ptmc_ci > 0
bys idh_ch: egen ptmc_ch = max(ptmc_ci)

******PNC******
gen pnc_elegible_ci = 0
replace pnc_elegible_ci =1 if (edad>=65 & edad!=.)

*ingreso por pnc
egen ing_pnc_ci=rowtotal(v5001a2)
replace ing_pnc_ci = . if pnc_elegible_ci == 0
replace ing_pnc_ci = . if v5001a2 == .
bys idh_ch:egen ing_pnc_ch=sum(ing_pnc_ci)

*Personas y hogares que reciben pension no contributiva (PNC)
gen pnc_ci = (v5001a==1 & pnc_elegible_ci==1)
bys idh_ch:egen pnc_ch=max(pnc_ci)

******Otros programas sociales******
gen disc_elegible_ci = 0
replace disc_elegible_ci = 1 if (edad<65 & edad!=.)

*ingreso por otros programas
gen ing_disc_ci = v5001a2 if (v5001a==1 & disc_elegible_ci==1)
egen ing_otrot_ci = rowtotal(v5003a2 ing_disc_ci)
replace ing_otrot_ci = . if v5001a == .
bys idh_ch:egen ing_otrot_ch = sum(ing_otrot_ci)
drop ing_disc_ci

*Personas y hogares que reciben otros programas sociales
gen potrot_ci=(v5003a==1 | (v5001a==1 & disc_elegible_ci==1))
bys idh_ch:egen potrot_ch=max(potrot_ci)
drop disc_elegible_ci 

*Ingreso neto del hogar per cápita
gen y_pc_net_ch=(y_hog_ch - ing_ptmc_ch - ing_pnc_ch - ing_otrot_ch)/nmiembros_sph_ch
replace y_pc_net_ch=0 if y_pc_net_ch<0

*Beneficiario por PTMC PNC u Otros
bys idh_ch: gen pcasht_ch = (ptmc_ch==1|pnc_ch==1| potrot_ch==1)


/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/

do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

** Grupos de ingreso neto
gen 	grupo_int = 1 if (y_pc_net_ch<lp31_2011 		& y_pc_net_ch!=.) 								
replace grupo_int = 2 if (y_pc_net_ch>=lp31_2011 		& y_pc_net_ch<lp31_2011*1.6 	& y_pc_net_ch!=.) 	
replace grupo_int = 3 if (y_pc_net_ch>=lp31_2011*1.6 	& y_pc_net_ch<lp31_2011*4 	& y_pc_net_ch!=.) 
replace grupo_int = 4 if (y_pc_net_ch>=lp31_2011*4 	& y_pc_net_ch < .			& y_pc_net_ch!=.) 	

********************************
*********pcash_coverage_************
********************************
forval i =1/4 {
	gen pcasht_coverage`i' = .
	replace pcasht_coverage`i' = 0 if grupo_int == `i'
	replace pcasht_coverage`i' = 1 if grupo_int == `i' & pcasht_ch ==1
}

********************************
*********pcash_dist_************
********************************

forval i =1/4 {
	gen pcasht_dist`i' = .
	replace pcasht_dist`i' = 0 if pcasht_ch == 1
	replace pcasht_dist`i' = 1 if grupo_int == `i' & pcasht_ch ==1
}

sum nmiembros_sph_ch  y_hog_ci y_hog_ch y_pc_net_ch ptmc_ci ptmc_ch ing_ptmc_ci ing_ptmc_ch pnc_elegible_ci  pnc_ci pnc_ch ing_pnc_ci ing_pnc_ch potrot_ci  potrot_ch ing_otrot_ci  ing_otrot_ch pcasht_ch 

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/


    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch BRA_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

* afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci  /// Género y diversidad (Por agregar)


/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/
rename v4010 codocupa
rename v4013 codindustria

compress

save "`base_out'", replace

log close
