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

local PAIS VEN
local ENCUESTA EHM
local ANO "2000"
local ronda s2 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: 
Encuesta: EHM
Round: s2
Autores: Mayra Sáenz - saenzmayra.a@gmail.com - mayras@iadb.org - Diciembre 2013
Versión 2006: Victoria
Generación nuevas variables LMK: Yessenia Loayza (desloay@hotmail.com | yessenial@iadb.org)
Última versión: Yessenia Loayza - Email: desloay@hotmail.com | yessenial@iadb.org
Fecha última modificación: octubre 2013

							SCL/LMK - IADB
****************************************************************************/
****************************************************************************/
use `base_in', clear

************
****pais****
************
gen str pais_c="VEN"

***************
****anio_c ****
***************
gen anio_c=2000

*********
***mes***
*********
gen mes_c=.
/* No se cuenta con informacion especifica sobre la semana de planificacion para esta encuesta */
replace mes_c= 7  if SEMAPLA>=1  & SEMAPLA<=4
replace mes_c= 8  if SEMAPLA>=5  & SEMAPLA<=8
replace mes_c= 9  if SEMAPLA>=9  & SEMAPLA<=12
replace mes_c= 10 if SEMAPLA>=13 & SEMAPLA<=16
replace mes_c= 11 if SEMAPLA>=17 & SEMAPLA<=20
replace mes_c= 12 if SEMAPLA>=21 & SEMAPLA<=24
*** average week of the survey is 11 which means mes==9
replace mes_c =9  if mes_c==.
label var mes_c "Mes de la Encuesta: Segundo Semestre de 2000"
label define mes_c 7 "JUL" 8 "AUG" 9 "SEP" 10 "OCT" 11 "NOV" 12 "DEC" 
label values mes_c mes_c

**********
***zona***
**********
gen zona_c=.
replace zona_c=1 if DOMINIO==1 | DOMINIO==2 | DOMINIO==3 | DOMINIO==4
recode zona_c .=0


****************
*** idh_ch ***
****************
sort ENTIDAD CONTROL AREA LINEA NROHOGSV SUBDOM LOCALI NROHOG
egen idh_ch=group( ENTIDAD CONTROL AREA LINEA NROHOGSV SUBDOM LOCALI NROHOG)
tostring idh_ch, replace

gen idp_ci=NROPER
tostring idp_ci, replace


***************
***factor_c***
***************
gen factor_ch=FACTORH
gen factor_ci=FACTORP

***************
***upm_ci***
***************
clonevar upm_ci=CONTROL

***************
***estrato_ci***
***************
gen estrato_ci=ESTRATO

***********
* Region_c *
************
* YL: En este año se considera la antigua division política administrativa (Que existía antes del 2001)
gen region_c=  ENTIDAD
label define region_c  ///
1	"Distrito Federal" ///
2	"Anzoategui" ///
3	"Apure" ///
4	"Aragua" ///
5	"Barinas" ///
6	"Bolivar" ///
7	"Carabobo" ///
8	"Cojedes" ///
9	"Falcon" ///
10	"Guarico" ///
11	"Lara" ///
12	"Merida" ///
13	"Miranda" ///
14	"Monagas" ///
15	"Nueva Esparta" ///
16	"Portuguesa" ///
17	"Sucre" ///
18	"Tachira" ///
19	"Trujillo" ///
20	"Yaracuy" ///
21	"Zulia" ///
22	"Amazonas" ///
23	"Delta Amacuro"
label value region_c region_c
label var region_c " Primera División política - Entidades Federativas"

*************
*** ine01 ***
*************
gen ine01=ENTIDAD
label define ine01 1 "Distrito Capital" 2 "Amazonas" 3 "Anzoategui" 4 "Apure" 5 "Aragua" 6 "Barinas" 7 "Bolivar" 8 "Carabobo" 9 "Cojedes" 10 "Delta Amacuro" 11 "Falcon" 12 "Guarico" 13 "Lara" 14 "Merida" 15 "Miranda" 16 "Monagas" 17 "Nueva Esparta" 18 "Portuguesa" 19 "Sucre" 20 "Tachira" 21 "Trujillo" 22 "Yaracuy" 23 "Zulia" 24 "Vargas"
label value ine01 ine01

************************
*** region según BID ***
************************
gen region_BID_c=3 

		****************************
		***VARIABLES DEMOGRAFICAS***
		****************************

*****************
***relacion_ci***
*****************
gen relacion_ci=.
replace relacion_ci=1 if PARENT==1
replace relacion_ci=2 if PARENT==2
replace relacion_ci=3 if PARENT==3
replace relacion_ci=4 if PARENT>=4 & PARENT<=14 /* Otros familiares */
replace relacion_ci=5 if PARENT==15  
replace relacion_ci=6 if PARENT==16 | PARENT==17 /*Es el sevicio domestico, Incluye a familiares del Serv. Domestico en PARENT==17 */

**********
***sexo***
**********
gen sexo_ci=SEXO

**********
***edad***
**********
gen edad_ci=EDAD
replace edad=. if EDAD==99

**************
***civil_ci***
**************
gen byte civil_ci=.
replace civil_ci=1 if SITCOYU==-1 | SITCOYU==7
replace civil_ci=2 if SITCOYU==1 | SITCOYU==2 | SITCOYU==3 | SITCOYU==4
replace civil_ci=3 if SITCOYU==5
replace civil_ci=4 if SITCOYU==6

************
***jefe_ci***
*************
gen jefe_ci=(relacion_ci==1)

******************
***nconyuges_ch***
******************
by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)

***************
***nhijos_ch***
***************
by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)

******************
***notropari_ch***
******************
by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)

********************
***notronopari_ch***
********************
by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)

****************
***nempdom_ch***
****************
by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6)

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

******************
***nmiembros_ch***
******************
by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)

*****************
***nmayor21_ch***
*****************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

*****************
***nmenor21_ch***
*****************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

*****************
***nmayor65_ch***
*****************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

****************
***nmenor6_ch***
****************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

****************
***nmenor1_ch***
****************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))

****************
***miembros_ci***
****************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)


		*******************************************************
		***           VARIABLES DE DIVERSIDAD               ***
		*******************************************************				
		* Maria Antonella Pereira & Nathalia Maya - Julio 2021	
		
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


		************************************
		*** VARIABLES DEL MERCADO LABORAL***
		************************************
		
**************
***ocupa_ci***
**************
capture drop ocupa_ci 
gen ocupa_ci=.
replace ocupa_ci=1 if OCUPP>=0 & OCUPP<=9
replace ocupa_ci=2 if OCUPP>=10 & OCUPP<=19
replace ocupa_ci=3 if OCUPP>=20 & OCUPP<=23
replace ocupa_ci=4 if OCUPP>=25 & OCUPP<=29
replace ocupa_ci=6 if OCUPP>=30 & OCUPP<=35
replace ocupa_ci=7 if OCUPP>=40 & OCUPP<=79
replace ocupa_ci=5 if OCUPP>=80 & OCUPP<=89
replace ocupa_ci=8 if OCUPP>=90 & OCUPP<=91
replace ocupa_ci=9 if OCUPP>=99

*****************
***horastot_ci***
*****************
gen byte horastot_ci=.
replace horastot_ci=HRSNORTP  if HRSNORTP<=110 & HRSNORTP>=0 & HRSNORTP>=HRSTOTP
replace horastot_ci=HRSTOTP if HRSTOTP>=HRSNORTP & HRSTOTP>=0

****************
****condocup_ci*
****************
/*
gen condocup_ci=.
replace condocup_ci=1 if (ACTVSUM>=1 & ACTVSUM <=3) 
replace condocup_ci=2 if ACTVSUM==4 | ACTVSUM==11 
replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2
replace condocup_ci=4 if edad_ci<15
label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor de PET"
label value condocup_ci condocup_ci
label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"
*/

* Cambio edad minima de la encuesta (10 años). MGD 06/10/2014
gen condocup_ci=.
replace condocup_ci=1 if (ACTVSUM>=1 & ACTVSUM <=3) 
replace condocup_ci=2 if ACTVSUM==4 | ACTVSUM==11 
replace condocup_ci=3 if (condocup_ci!=1 & condocup_ci!=2) & edad_ci>=10
replace condocup_ci=4 if edad_ci<10

******************
***categopri_ci***
******************
* Modificacion MGD 07/14/2014: Condicionado a que esten ocupados.
gen categopri_ci=.
replace categopri_ci=1 if CATEGP==7 & condocup_ci==1
replace categopri_ci=2 if CATEGP==6 | CATEGP==5 & condocup_ci==1
replace categopri_ci=3 if CATEGP>=1 & CATEGP<=4  & condocup_ci==1
replace categopri_ci=4 if CATEGP==8 & condocup_ci==1

****************
*instpen_ci*****
****************
gen instpen_ci=.

****************
*tipopen_ci*****
****************
gen tipopen_ci=.

********************
*** instcot_ci *****
********************
gen instcot_ci=.

*****************
*tipocontrato_ci*
*****************
gen tipocontrato_ci=.

*************
*tamemp_ci***
*************
/*
gen tamemp_ci=TAMESTP
label define tamemp_ci 1"menos de 5 personas" 2"5-10 personas" 3"11-20 personas" 4"Más de 20 personas"
label var tamemp_ci "# empleados en la empresa de la actividad principal"
*/
gen tamemp_ci=1 if TAMESTP==1 
*Empresas medianas
replace tamemp_ci=2 if TAMESTP==2 | TAMESTP==3
*Empresas grandes
replace tamemp_ci=3 if TAMESTP==4
tab tamemp_ci [iw=factor_ci]
/*
*Genera la variable para clasificar a los inactivos
*Jubilados, pensionados e incapacitados

gen categoinac_ci=1 if TRABAJA==7
label var  categoinac_ci "Condición de Inactividad" 
*Estudiantes
replace categoinac_ci=2 if TRABAJA==5
*Quehaceres del Hogar
replace categoinac_ci=3 if TRABAJA==6
*Otra razon
replace categoinac_ci=4 if TRABAJA==2 | TRABAJA==8 | TRABAJA==9 | TRABAJA==10
label define inactivo 1"Pensionado y otros" 2"Estudiante" 3"Hogar" 4"Otros"
label values categoinac_ci inactivo
tab categoinac_ci [iw=factor_ci]
*/

*****************
*categoinac_ci***
*****************
gen categoinac_ci = .
replace categoinac_ci = 1 if ((PQNOBUS==7) & condocup_ci==3)
replace categoinac_ci = 2 if ((PQNOBUS==5) & condocup_ci==3)
replace categoinac_ci = 3 if ((PQNOBUS==6) & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)

*************
**pension_ci*
*************
gen pension_ci=0 
foreach var of varlist YOTROSA YOTROSB YOTROSC YOTROSD YOTROSE YOTROSF YOTROSG YOTROSH YOTROSI {
replace pension_ci=1 if (`var'==1 | `var'==5 | `var'==6 ) /*A todas las per mayores de diez años */
}
 
*************
*  ypen_ci  *
*************
gen ypen_ci=YOTROS/1000 if pension_ci==1
replace ypen_ci=. if YOTROS<0

***************
*pensionsub_ci*
***************
gen pensionsub_ci=.

*****************
**  ypensub_ci  *
*****************
gen ypensub_ci=.

*************
*cesante_ci* 
*************
generat cesante_ci=0 if condocup_ci==2
replace cesante_ci=1 if (CESANTE==1) & condocup_ci==2

*********
*lp_ci***
*********
gen lp_ci=.
replace lp_ci=59405.2 if zona_c==1
replace lp_ci=47524.1 if zona_c==0

***********
*lpe_ci ***
***********
gen lpe_ci =.

*************
**salmm_ci***
*************
/*Yessenia Loayza/Nota:
"Con la firma del Decreto Ley de Reconversión Monetaria, 
el presidente Chávez autorizó la eliminación de tres ceros a
 la moneda nacional a partir del 1º de enero de 2008"
 Bs (Bolivares Actuales)
 Bsf (Bolivares Fuertes)
 
 conversion:
 *----------
 1 BsF= 1000Bs/1000
 */
* 2015 MGD: actualizados salarios
gen salmm_ci=.
replace salmm_ci=138000/1000 if zona_c==1 /*en Bs*/
replace salmm_ci=129600/1000 if zona_c==0 
*Y.L. divido al salmm_ci entre 1000 para hacerlo comparable a lo largo del tiempo

*************
***tecnica_ci**
*************
gen tecnica_ci=(NIVEL==5)

************
***emp_ci***
************
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
label var emp_ci "Ocupado (empleado)"
label define emp_ci 0"No" 1"Si", add
label value emp_ci emp_ci

****************
***desemp_ci***
****************
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte desemp_ci = .
replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
label var desemp_ci "Desocupado (desempleado)"
label define desemp_ci 0"No " 1"Si", add
label value desemp_ci desemp_ci

****************
*afiliado_ci****
****************
gen afiliado_ci=.

****************
*cotizando_ci***
****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte cotizando_ci = .
foreach var of varlist  BENEFA  BENEFB BENEFC {
replace cotizando_ci = 1 if (`var'==3) & emp_ci==1 /*solo a emplead@s y asalariad@s, difiere con los otros paises*/
}
replace cotizando_ci = 0 if (cotizando_ci1 != 1 & inlist(condocup_ci, 1, 2))
label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0 "No"  1 "Si"
label value cotizando_ci cotizando_ci

*************
***pea_ci***
*************
gen pea_ci=(emp_ci==1 | desemp_ci==1)

*************
***formal_ci***
*************
gen formal_ci=(cotizando_ci==1)

*****************
***horaspri_ci***
*****************
capture drop horaspri_ci
gen byte horaspri_ci=.
replace horaspri_ci=HRSTOTP if HRSTOTP<=110 & HRSTOTP>=0

****************
***durades_ci***
****************
* Modificacion MGD 07/11/2014: si hay la variable, para este anio es la pp41a/b.
g mesess=MESESINT if MESESINT>0
g anioss=ANOSINT*12 if ANOSINT>0
egen durades_ci = rsum(mesess anioss), missing
replace durades_ci=. if condocup_ci==3
*Se ponen como missing values las personas que llevan más tiempo desempleadas que tiempo de vida:
gen edad_meses=edad_ci*12
replace durades_ci=. if durades_ci>edad_meses
drop edad_meses

*****************
***desalent_ci***
*****************
capture drop desalent_ci
***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
gen byte desalent_ci = .
replace desalent_ci = 1 if (HECHODIL==2 & inlist(PQNOBUS, 1, 2) & condocup_ci == 3)
replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
label var desalent_ci "Desalentados"
label define desalent_ci 0"No" 1"Si", add
label value desalent_ci desalent_ci

***************
***subemp_ci***
***************
gen subemp_ci=.

*******************
***tiempoparc_ci***
*******************
gen tiempoparc_ci=.

*************
**rama_ci ***
*************
gen rama_ci=.
replace rama_ci=1 if (RAMAP>=111 & RAMAP<=141) & emp_ci==1
replace rama_ci=2 if (RAMAP>=210 & RAMAP<=290) & emp_ci==1
replace rama_ci=3 if (RAMAP>=311 & RAMAP<=390) & emp_ci==1
replace rama_ci=4 if (RAMAP>=410 & RAMAP<=420) & emp_ci==1
replace rama_ci=5 if RAMAP==500 & emp_ci==1
replace rama_ci=6 if (RAMAP>=610 & RAMAP<=632) & emp_ci==1
replace rama_ci=7 if (RAMAP>=711 & RAMAP<=720) & emp_ci==1
replace rama_ci=8 if (RAMAP>=810 & RAMAP<=833) & emp_ci==1
replace rama_ci=9 if (RAMAP>=910 & RAMAP<=960) & emp_ci==1

* rama secundaria
g ramasec_ci=. 

******************
***categosec_ci***
******************
gen categosec_ci=.

*****************
***nempleos_ci***
*****************
capture drop nempleos_ci
gen byte nempleos_ci=.
replace nempleos_ci=1 if emp==1 & OTRACTV==2
replace nempleos_ci=2 if emp==1 & OTRACTV==1 & NROACTV>=1 & NROACTV!=.

*****************
***spublico_ci***
*****************
capture drop spublico_ci
gen byte spublico_ci=.
replace spublico_ci=1 if emp==1 & (CATEGP==1 | CATEGP==2)
replace spublico_ci=0 if emp==1 & (CATEGP>2 & CATEGP<=8) 

*******************
***antiguedad_ci***
*******************
gen antiguedad_ci=.

*****************
*otras variables*
*****************
capture drop tamfirma_ci
gen byte tamfirma_ci=.
replace tamfirma_ci=1 if emp==1 & (TAMESTP>=2 & TAMESTP<=4)
replace tamfirma_ci=0 if emp==1 & TAMESTP==1


		************************************
		**************INGRESOS**************
		************************************

****************
***ylmpri_ci ***
****************
capture drop ylmpri_ci
gen ylmpri_ci=.
replace ylmpri_ci=YOCUPAPM if YOCUPAPM~=-1 & YOCUPAPM~=-2 & YOCUPAPM~=-3
* The values '-3': '-2' and '-1' are 'he/she doesn't remember'; 'he/she doesn't answer' and 'don't aply' respectively
replace ylmpri_ci=. if EDAD<10
replace ylmpri_ci=ylmpri_ci/1000
*Y.L. divido al ingreso entre 1000 para hacerlo comparable a lo largo del tiempo

*******************
*** ylmhopri_ci ***
*******************
gen ylmhopri_ci=.
replace ylmhopri_ci=ylmpri_ci/(horaspri*4.3)

*******************
*** nrylmpri_ci ***
*******************
g nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)
replace nrylmpri_ci=. if emp_ci!=1 | categopri_ci==4 /*excluding unpaid workers*/

***************
***ylmsec_ci***
***************
gen ylmsec_ci=.	

******************
*** ylmotros_ci***
******************
gen ylmotros_ci=.

*****************
*** ylnmpri_ci***
*****************
gen ylnmpri_ci=.

***************
***ylmsec_ci***
***************
gen ylnmsec_ci=.	

******************
***ylnmotros_ci***
******************
gen ylnmotros_ci=.

************
***ylm_ci***
************
gen ylm_ci=.
replace ylm_ci=YOCUPAM if (YOCUPAM~=-1 & YOCUPAM~=-2 & YOCUPAM~=-3) & /*
	*/(YOCUPAPM~=-1 & YOCUPAPM~=-2 & YOCUPAPM~=-3) & (YOCUPAPM<=YOCUPAM)
replace ylm_ci=YOCUPAPM if (YOCUPAPM~=-1 & YOCUPAPM~=-2 & YOCUPAPM~=-3) & (YOCUPAPM>YOCUPAM)
* The values '-3': '-2' and '-1' are 'he/she doesn't remember'; 'he/she doesn't answer' and 'don't aply' respectively
* The survey gives directly ylmpri_ci and ylm_ci through YOCUPAPM and YOCUPAM but for some observations YOCUPAPM > YOCUPAM;
replace ylm_ci=. if EDAD<10
replace ylm_ci=ylm_ci/1000
*Y.L. divido al ingreso entre 1000 para hacerlo comparable a lo largo del tiempo

*************
***ylnm_ci***
*************
gen ylnm_ci=.

*************
***ynlm_ci***
*************
gen ynlm_ci=.
replace ynlm_ci=YOTROS if YOTROS~=-1 & YOTROS~=-2 & YOTROS~=-3
replace ynlm_ci=. if EDAD<10
replace ynlm_ci=ynlm_ci/1000
*Y.L. divido al ingreso entre 1000 para hacerlo comparable a lo largo del tiempo

*************
***ynlnm_ci**
*************
gen ynlnm_ci=.
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)


******************
*** tcylmpri_ci***
******************
gen tcylmpri_ci=.

*******************
*** autocons_ci ***
*******************
gen autocons_ci=.

*****************
***remesas_ci***
*****************
gen remesas_ci=.

***************
***ylmho_ci ***
***************
gen ylmho_ci=.

******************
*** nrylmpri_ch***
******************
/*
capture drop nrylmpri_ci
gen nrylmpri_ci=.
replace nrylmpri_ci=0 if (YOCUPAPM~=-1 & YOCUPAPM~=-2 & YOCUPAPM~=-3)
replace nrylmpri_ci=1 if (YOCUPAPM==-2 | YOCUPAPM==-3) 
label var nrylmpri_ci "Identificador de No Respuesta del Ingreso Monetario de la Actividad Principal"*/
capture drop nrylmpri_ch
sort idh
egen nrylmpri_ch=sum(nrylmpri_ci) if miembro==1, by(idh) 
replace nrylmpri_ch=1 if nrylmpri_ch>1 & nrylmpri_ch~=. & miembro==1 

******************
*** tcylmpri_ch***
******************
gen tcylmpri_ch=.

*************
*** ylm_ch***
*************
egen ylm_ch=sum(ylm_ci) if miembros_ci==1, by(idh_ch)

****************
*** ylmnr_ch ***
****************
egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1 & nrylmpri_ch==0, by(idh_ch)

***************
*** ylnm_ch ***
***************
egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, by(idh_ch)

***************
*** ynlm_ch ***
***************
egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, by(idh_ch)

****************
*** ynlnm_ch ***
****************
egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, by(idh_ch)

*******************
*** rentaimp_ch ***
*******************
gen rentaimp_ch=.

*******************
*** autocons_ch ***
*******************
egen autocons_ch=sum(autocons_ci) if miembros_ci==1, by(idh_ch)

******************
*** remesas_ch ***
******************
egen remesas_ch=sum(remesas_ci) if miembros_ci==1, by(idh_ch)

replace ylnm_ch=. if ylnm_ci==.
replace ynlnm_ch=. if ynlnm_ci==.
replace autocons_ch=. if autocons_ci==.
replace remesas_ch=. if remesas_ci==.
replace ylm_ch =. if miembros_ci==0
replace ylmnr_ch =. if miembros_ci==0
replace ylnm_ch =. if miembros_ci==0
replace ynlnm_ch =. if miembros_ci==0
replace autocons_ch =. if miembros_ci==0
replace remesas_ch =. if miembros_ci==0
replace ynlm_ch =. if miembros_ci==0


		****************************
		***VARIABLES DE EDUCACION***
		****************************

gen pp25a = NIVEL
gen pp25b = GRADO
gen pp25c = ULTSEM
gen pp27 = ASIST

** Se eliminan los valores negativos
replace pp25a =. if pp25a < 0   //nivel
replace pp25b =. if pp25b < 0   //grado
replace pp25c =. if pp25c < 0   //ultimo sem
replace pp27 =. if pp27 < 0     // asistencia

***************
***asiste_ci***
***************
gen byte asiste_ci=.
replace asiste_ci=1 if pp27 == 1
replace asiste_ci=0 if pp27 == 2

*************
***aedu_ci***
*************
/*
capture drop aedu_ci
gen byte aedu_ci=.
replace aedu=0 if NIVEL==1 | NIVEL==2
replace aedu=GRADO if NIVEL==3 & GRADO>0
replace aedu=GRADO+9 if NIVEL==4 & GRADO>0 & GRADO<=2
replace aedu=11 if NIVEL==4 & GRADO>2
replace aedu=GRADO+11 if (NIVEL==5 | NIVEL==6) & GRADO>0 
replace aedu=int(ULTSEM/2)+11 if (NIVEL==5 | NIVEL==6) & ULTSEM>0 
label variable aedu_ci "Años de Educacion" */

cap drop aedu_ci 
gen byte aedu_ci= .
// Para aquellos que declaran anios solamente
replace aedu_ci = 0 if (pp25a == 1 | pp25a == 2) // Ninguno, Prescolar
replace aedu_ci = pp25b if pp25a == 3 & (pp25b !=. & pp25c ==.) // Primaria
replace aedu_ci = pp25b + 6 if pp25a == 4 & (pp25b !=. & pp25c ==.) // Secundaria
replace aedu_ci = pp25b + 11 if (pp25a == 5 & pp25b != . & pp25c ==.| pp25a == 6 & pp25b !=. & pp25c == .) // Tecnico, Universitario

// Para aquellos que declaran semestres solamente
replace aedu_ci = (0.5 * pp25c) if pp25a == 3 & (pp25b == . & pp25c != .) // Primaria
replace aedu_ci = ((0.5 * pp25c) + 6) if pp25a == 4 & (pp25b == . & pp25c != .) // Secundaria
replace aedu_ci = ((0.5 * pp25c) + 11) if (pp25a == 5 & pp25b == . & pp25c != .| pp25a == 6 & pp25b == . & pp25c != .) // Tecnico, Universitario

// Para aquellos que declaran anio y semestre a la vez
replace aedu_ci = max(pp25b , 0.5 * pp25c) if pp25a == 3 & (pp25b != . & pp25c != .) // Primaria
replace aedu_ci = (max(pp25b , 0.5 * pp25c) + 6) if pp25a == 4 & (pp25b != . & pp25c != .) // Secundaria
replace aedu_ci = (max(pp25b , 0.5 * pp25c) + 11) if (pp25a == 5 & pp25b != . & pp25c != .| pp25a == 6 & pp25b != . & pp25c != .) // Tecnico, Universitario

// Para aquellos que declaran nivel pero no anio o semestre
replace aedu_ci = 0 if pp25a == 3 & aedu_ci == . // Primaria
replace aedu_ci = 6 if pp25a == 4 & aedu_ci == . // Media
replace aedu_ci = 11 if (pp25a == 5 | pp25a == 6) & aedu_ci == . // Técnico (TSU),  Universitario
replace aedu_ci=floor(aedu_ci) // se redondea la variable

tab aedu if aedu>edad_ci

* Unfortunately, we found people with more years of education that years of life. 
* Then, assuming that everyone enters to school not before 5 years old. To correct this:
forvalues i=0(1)18 {
if `i'==0 {
replace aedu=`i' if (aedu>`i' & aedu~=.) & (edad_ci==3 | edad_ci==4 | edad_ci==5)
}
if `i'~=0 {
replace aedu=`i' if (aedu>`i' & aedu~=.) & edad_ci==(`i'+5)
}
}


**************
* Line of code with indicator eduno_ci was deleted**************
* Line of code with indicator eduno_ci was deletedreplace eduno=. if aedu_ci==.
* Line of code with indicator eduno_ci was deleted
***************
***edupre_ci***
***************
gen edupre_ci=.
replace edupre=1 if pp25a==2
replace edupre=0 if pp25a>2 | pp25a==1

**************
* Line of code with indicator edupi_ci was deleted**************
* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
**************
* Line of code with indicator edupc_ci was deleted**************
* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
**************
* Line of code with indicator edusi_ci was deleted**************
* Line of code with indicator edusi_ci was deletedreplace edusi=. if aedu_ci==.
* Line of code with indicator edusi_ci was deleted
**************
* Line of code with indicator edusc_ci was deleted**************
* Line of code with indicator edusc_ci was deletedreplace edusc=. if aedu_ci==.
* Line of code with indicator edusc_ci was deleted
**************
***eduui_ci***
**************
gen eduui_ci=(aedu_ci>11 & aedu_ci<14)
replace eduui_ci=. if aedu_ci==.

***************
***eduuc_ci***
***************
gen byte eduuc_ci=(aedu_ci>=14)
replace eduuc_ci=. if aedu_ci==.

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
**************
***eduac_ci***
**************
gen eduac_ci=.

***************
***asispre_ci**
***************
g asispre_ci = (asiste_ci == 1 & pp25a == 2)

***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted* Line of code with indicator repite_ci was deleted
******************
* Line of code with indicator repiteult was deleted* Line of code with indicator repiteult was deleted***************
***edupub_ci***
***************
gen edupub_ci=.

**************
*pqnoasis1_ci*
**************
g       pqnoasis1_ci = 1 if RZNOASIS ==4
replace pqnoasis1_ci = 2 if RZNOASIS ==5
replace pqnoasis1_ci = 3 if RZNOASIS ==8  | RZNOASIS ==9
replace pqnoasis1_ci = 4 if RZNOASIS ==7
replace pqnoasis1_ci = 5 if RZNOASIS ==12 | RZNOASIS ==14
replace pqnoasis1_ci = 6 if RZNOASIS ==1
replace pqnoasis1_ci = 7 if RZNOASIS ==11 | RZNOASIS ==13
replace pqnoasis1_ci = 8 if RZNOASIS ==2  | RZNOASIS ==3 
replace pqnoasis1_ci = 9 if RZNOASIS ==6  | RZNOASIS ==10 | RZNOASIS ==15


		********************************************
		***Variables de Infraestructura del hogar***
		********************************************

****************
***aguared_ch***
****************
/*pv7 =AGUA A esta vivienda llega el agua por:
01	Acueducto
02	Pila pública
03	Camión
04	Otros medios */
gen aguared_ch=0
replace aguared_ch=1 if (AGUA==1 | AGUA==2 | AGUA==3)

*****************
*aguafconsumo_ch*
*****************
*fuentes principales de agua para beber de los miembros de su hogar
gen aguafconsumo_ch =0

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch=.
replace aguafuente_ch=1 if AGUA==1
replace aguafuente_ch=2 if AGUA==2
replace aguafuente_ch=6 if AGUA==3
replace aguafuente_ch= 10 if AGUA==4 | AGUA==-1

*************
*aguadist_ch*
*************
gen aguadist_ch=0
replace aguadist_ch=1 if AGUA==1|AGUA==3
replace aguadist_ch=3 if AGUA==2

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch=9

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch=9

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
gen aguamide_ch = .

*****************
*bano_ch         *  Altered
*****************
*pv8 = SANITA
gen bano_ch=.
replace bano_ch=0 if SANITA==4
replace bano_ch=1 if SANITA==1
replace bano_ch=2 if SANITA==2
replace bano_ch=6 if SANITA==3|SANITA==-1

***************
***banoex_ch***
***************
generate banoex_ch=9

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
replace sinbano_ch = 0 if SANITA!=4

*************
*aguatrat_ch*
*************
gen aguatrat_ch =.

************
***luz_ch***
************
gen luz_ch=.

****************
***luzmide_ch***
****************
gen luzmide_ch=.

****************
***combust_ch***
****************
gen combust_ch=.

*************
***des1_ch***
*************
gen des1_ch=.
replace des1_ch=0 if SANITA==4
replace des1_ch=1 if SANITA==1 | SANITA==2 
replace des1_ch=2 if SANITA==3

*************
***des2_ch***
*************
gen des2_ch=.
replace des2_ch=0 if SANITA==4
replace des2_ch=1 if SANITA==1 | SANITA==2 | SANITA==3

*************
***piso_ch***
*************
* pv4=PISO
gen piso_ch=.
replace piso_ch=0 if PISO==3
replace piso_ch=1 if PISO==1 | PISO==2
replace piso_ch=2 if PISO==4 | PISO==-1

**************
***pared_ch***
**************
*PAREDES=pv2
*basado en 2021
gen pared_ch=.
replace pared_ch=0 if PAREDES==3 // no permanentes
replace pared_ch=1 if PAREDES==1 | PAREDES==2 | PAREDES==4 | PAREDES==5  // permanentes
replace pared_ch=2 if PAREDES==6 | PAREDES==-1 // otros

**************
***techo_ch***
**************
/* solo va de 01-05 
01	01	01	Platabanda
02	02	02	Teja
--	03	03	Láminas asfálticas (solo a partir de 2003) 
03	03	--	Fibrocemento, cemento, ligero y similares
04	04	04	Láminas métalicass (Zinc y similares)
--	05	05	Asbesto y Similares (solo a partir de 2003)  
05	06	06	Otros (Palmas, tabla y similares) */

*pv3=TECHO
gen techo_ch=.
replace techo_ch=0 if TECHO==5
replace techo_ch=1 if TECHO==1 | TECHO==2 | TECHO==3 | TECHO==4

**************
***resid_ch***
**************
/*
PV11B	BASURA  Recolección directa de basura
PV11C	CONTBAS Container de basura
*/
gen resid_ch=.
replace resid_ch=3 if CONTBAS==1|CONTBAS==2
replace resid_ch=0 if BASURA==1 //remplazo por 0 si es recolección directa aunque registre también container

*************
***dorm_ch***
*************
*pv6=NRODORMV
gen dorm_ch=.
replace dorm_ch=NRODORMV if NRODORMV>=0

****************
***cuartos_ch***
****************
*pv5=NROCUARV
gen cuartos_ch=.
replace cuartos_ch=NROCUARV if NROCUARV>=0

***************
***cocina_ch***
***************
gen cocina_ch=.

**************
***telef_ch***
**************
* TELEFONO = pv11d Servicio telefónico (Telefónico fijo, anexo 2003)
gen telef_ch=.
replace telef_ch=1 if TELEFONO==1
replace telef_ch=0 if TELEFONO==2 | TELEFONO==-1

***************
***refrig_ch***
***************
*ph14a=NEVERA
gen refrig_ch=.
replace refrig_ch=1 if NEVERA==1
replace refrig_ch=0 if NEVERA==2

**************
***freez_ch***
**************
gen freez_ch=.

*************
***auto_ch***
*************
*ph15=NROAUTO
gen auto_ch=.
replace auto_ch=1 if NROAUTO>=1
replace auto_ch=0 if NROAUTO<1

**************
***compu_ch***
**************
gen compu_ch=.

*****************
***internet_ch***
*****************
gen internet_ch=.

************	
***cel_ch***
************
gen cel_ch=.

**************
***vivi1_ch***
**************
gen vivi1_ch=.
replace vivi1_ch=1 if TIPOVIV==1 | TIPOVIV==2 | TIPOVIV==5
replace vivi1_ch=2 if TIPOVIV==3 | TIPOVIV==4
replace vivi1_ch=3 if TIPOVIV>5 & TIPOVIV<.

**************
***vivi2_ch***
**************
gen vivi2_ch=.
replace vivi2_ch=1 if vivi1_ch==1 | vivi1_ch==2
replace vivi2_ch=0 if vivi1_ch==3

*****************
***viviprop_ch***
*****************
gen viviprop_ch=.
replace viviprop_ch=0 if TENENVIV==3 | TENENVIV==4
replace viviprop_ch=1 if TENENVIV==1
replace viviprop_ch=2 if TENENVIV==2
replace viviprop_ch=3 if TENENVIV>4 & TENENVIV<=10

****************
***vivitit_ch***
****************
gen vivitit_ch=.

****************
***vivialq_ch***
****************
*Alquiler ph16b = MONTOBS
gen vivialq_ch=.
destring MONTOBS, replace
replace vivialq_ch=MONTOBS if MONTOBS>=0 &viviprop_ch==0 //solo para los que declararon que alquilan

*******************
***vivialqimp_ch***
*******************
gen vivialqimp_ch=.

*******************
***  benefdes_ci  *
*******************
g benefdes_ci=.

*******************
*** ybenefdes_ci  *
*******************
g ybenefdes_ci=.

		******************************
		*** VARIABLES DE MIGRACION ***
		******************************

*******************
*** migrante_ci ***
*******************
* la variable LUGAR_NAC está con puro 0
gen migrante_ci=.
	
**********************
*** migantiguo5_ci ***
**********************
gen migantiguo5_ci=.

**********************
*** migrantelac_ci ***
**********************
gen migrantelac_ci=.



/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/


    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci pqnoasis1_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded
 /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

compress

saveold "`base_out'", replace
log close







