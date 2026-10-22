
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

local PAIS PRY
local ENCUESTA EPH
local ANO "2008"
local ronda m10_m12

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
*local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                                                    
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Paraguay
Encuesta: EPH
Round: Octubre-Diciembre
Autores:
Versión 2013: Mayra Sáenz
Última versión: Mayra Sáenz - Email: mayras@iadb.org, saenzmayra.a@gmail.com
Fecha última modificación: 4 de Septiembre de 2013

							SCL/LMK - IADB
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/
use `base_in', clear
cap drop idh_ch
cap drop idp_c


************
* Region_c *
************
*Inclusión Mayra Sáenz - Abril 2014

/*gen region_c=  dpto
label define region_c ///
           0 "Asunción" ///    
           1 "Concepción" ///  
           2 "San pedro" ///   
           3 "Cordillera" ///  
           4 "Guairá" ///      
           5 "Caaguazú" ///    
           6 "Caazapá" ///     
           7 "Itapúa" ///      
           8 "Misiones" ///    
           9 "Paraguarí" ///   
          10 "Alto paraná" /// 
          11 "Central" ///     
          12 "Ñeembucú" ///    
          13 "Amambay" ///     
          14 "Canindeyú" ///   
          15 "Pdte. Hayes" ///
		  20 "Resto"
label value region_c region_c

label var region_c "División política"*/
*Modificación Mayra Sáenz - Septiembre 2014		  
gen region_c    = 1 if dpto == 0
replace region_c= 2 if dpto == 2		  
replace region_c= 3 if dpto == 5		  
replace region_c= 4 if dpto == 7
replace region_c= 5 if dpto == 10
replace region_c= 6 if dpto == 11
replace region_c= 7 if dpto == 20  
label define region_c ///
1 "Asunción" ///
2 "San Pedro" ///
3 "Caaguazú" ///
4 "Itapúa" ///
5 "Alto Paraná" ///
6 "Central" ///
7 "Resto" 
label value region_c region_c
label var region_c "División política"

***************
***factor_ch***
***************

gen factor_ch=fex 
label variable factor_ch "Factor de expansion del hogar"


***************
****idh_ch*****
***************
gen upms=string(upm)
gen nvivis=string(nvivi)
gen nhogas=string(nhoga)
gen idh_ch=upms+nvivis+nhogas
sort idh_ch
label variable idh_ch "ID del hogar"
tostring idh_ch, replace

drop upms nvivis nhogas

**************
****idp_ci****
**************

cap bysort idh_ch:gen idp_ci=_n 
label variable idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


**********
***zona***
**********

gen byte zona_c=(area==1)

label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_ci

************
****pais****
************

gen str3 pais_c="PRY"
label variable pais_c "Pais"

**********
***anio***
**********

gen anio_c=2008
label variable anio_c "Anio de la encuesta"
*****************
*** region según BID ***
*****************
gen region_BID_c=.
replace region_BID_c=4 if pais=="PRY" 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

***************
****muestra****
***************
*1995 y 1997-2006 es nacional (N)

gen muestra_AMA=0
replace muestra_AMA=1 if dpto==0
label variable muestra_AMA "Asuncion Metropolitana"
	 	
gen muestra_N=1
label variable muestra_N "Muestra Nacional"

gen muestra_U=0
replace muestra_U=1 if zona_c==1
label variable muestra_U "Muestra Urbana"

*********
***mes***
*********

tostring f1, gen(fecha)
gen mes=substr(fecha,3,2)
destring mes, replace
ren mes mes_c
label variable mes_c "Mes de la encuesta"
label define mes_c 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo"
label define mes_c 6 "Junio" 7 " Julio" 8 "Agosto",add
label define mes_c 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre", add
label value mes_c mes_c


*****************
***relacion_ci***
*****************

gen relacion_ci=.
replace relacion_ci=1 if p03==1
replace relacion_ci=2 if p03==2 
replace relacion_ci=3 if p03==3 | p03==4
replace relacion_ci=4 if p03==5 | p03==6 | p03==7 | p03==8 | p03==9
replace relacion_ci=5 if p03==10
replace relacion_ci=6 if p03==11


label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes"
label define relacion_ci 6 "Empleado/a domestico/a", add

label value relacion_ci relacion_ci


****************************
***VARIABLES DEMOGRAFICAS***
****************************

***************
***factor_ci***
***************

gen factor_ci=fex 
label variable factor_ci "Factor de expansion del individuo"

**********
***sexo***
**********

gen sexo_ci=.
replace sexo_ci=1 if p06==1
replace sexo_ci=2 if p06==6

label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

**********
***edad***
**********

gen edad_ci=p02
label variable edad_ci "Edad del individuo"


*****************
***civil_ci***
*****************
/*
      estado |
       civil |  
 ------------+
 1casado     | 
 2unido      | 
 3separado   | 
 4viudo      | 
 5soltero    | 
 6divorciado | 
 ------------+
       Total |  
*/

gen estcivil=p09
gen civil_ci=.
replace civil_ci=1 if estcivil==5
replace civil_ci=2 if estcivil==1 | estcivil==2 
replace civil_ci=3 if estcivil==3 | estcivil==6 
replace civil_ci=4 if estcivil==4 

label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci
drop estcivil

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

*****************
***nmayor21_ch***
*****************

* Modificaciones Marcela Rubio Septiembre 2014: se habia utilizado la variable edad que contiene error, mejor utilizar edad_ci que viene de var p02
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

*****************
***nmenor21_ch***
*****************

* Modificaciones Marcela Rubio Septiembre 2014: se habia utilizado la variable edad que contiene error, mejor utilizar edad_ci que viene de var p02
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

*****************
***nmayor65_ch***
*****************

* Modificaciones Marcela Rubio Septiembre 2014: se habia utilizado la variable edad que contiene error, mejor utilizar edad_ci que viene de var p02
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

****************
***nmenor6_ch***
****************

* Modificaciones Marcela Rubio Septiembre 2014: se habia utilizado la variable edad que contiene error, mejor utilizar edad_ci que viene de var p02
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

****************
***nmenor1_ch***
****************

* Modificaciones Marcela Rubio Septiembre 2014: se habia utilizado la variable edad que contiene error, mejor utilizar edad_ci que viene de var p02
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

****************
***miembros_ci***
****************

gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"

******************************************************************************
*	VARIABLES DE DIVERSIDAD
******************************************************************************
**María Antonella Pereira & Nathalia Maya - Marzo 2021 

	*********
	*afro_ci*
	*********
gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	
	*********
	*ind_ci*
	*********	
gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta

	**************
	*noafroind_ci*
	**************
gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta

	***************
	***afroind_ci***
	***************
gen afroind_ci=. 

	*********
	*afro_ch*
	*********
gen afro_ch  = .
	
	********
	*ind_ch*
	********	
gen ind_ch = .

	**************
	*noafroind_ch*
	**************
gen noafroind_ch = .

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

************************************************************************************************************
* 3. Creación de nuevas variables de SS and LMK a incorporar en Armonizadas
************************************************************************************************************/	
	
*********
*lp_ci***
*********

gen lp_ci =.
replace lp_ci= 474703  if dominio2==1 | dominio2==2   /*area metropolitana*/
replace lp_ci= 291948 if dominio2==3 | dominio2==5   /*rural*/
replace lp_ci= 338902 if dominio2==4  /*resto urbano*/
label var lp_ci "Linea de pobreza oficial del pais"

*********
*lpe_ci***
*********

gen lpe_ci =.
replace lpe_ci= 277766  if dominio2==1 | dominio2==2   /*area metropolitana*/
replace lpe_ci= 197247 if dominio2==3 | dominio2==5   /*rural*/
replace lpe_ci= 213162 if dominio2==4  /*resto urbano*/
label var lpe_ci "Linea de indigencia oficial del pais"

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

****************
*instcot_ci*****
****************
gen instcot_ci=.
replace instcot_ci=1 if b11==1 
replace instcot_ci=2 if b11==2 
replace instcot_ci=3 if b11==3 
replace instcot_ci=4 if b11==4 
replace instcot_ci=5 if b11==5 
replace instcot_ci=6 if b11==6 
replace instcot_ci=9 if b11==9 
label var instpen_ci "Institucion a la que cotiza - variable original de cada pais" 

****************
****condocup_ci*
****************
/*
gen condocup_ci=.
replace condocup_ci=1 if peaa==1
replace condocup_ci=2 if peaa==2
replace condocup_ci=3 if peaa==3 & edad_ci>=10
replace condocup_ci=. if peaa == 0
replace condocup_ci=4 if edad_ci<10 

label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de PET" 
label value condocup_ci condocup_ci
*/

* Comprobacion que no se toma en cuenta el desempleo oculto. MGD 05/27/2014
* No coincide con la variable creada pead ya que se condiciona por busqueda de trabajo y disponibilidad para trabajar.
gen condocup_ci=.
replace condocup_ci=1 if (pead==1 | pead==4 | pead==5)
replace condocup_ci=2 if (pead==2 | pead==7) & edad_ci >=10
recode condocup_ci .=3 if (pead==3 | pead==6 ) | (condocup_ci==. & edad_ci >=10) 
recode condocup_ci .=4 if edad_ci<10

label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de PET" 
label value condocup_ci condocup_ci

*************
*cesante_ci* 
*************

gen cesante_ci=1 if a12==1 &  peaa==2 & edad_ci>=10
replace cesante_ci=0 if a12==6 &  peaa==2 & edad_ci>=10
label var cesante_ci "Desocupado - definicion oficial del pais"	

*************
**pension_ci*
*************

gen pension_ci=1 if (e01hde>0 & e01hde!=. & e01hde<=999999999) | (e01ide>0 & e01ide!=. & e01ide<=999999999)
replace pension_ci=0 if  e01hde==0 & e01ide==0
label var pension_ci "1=Recibe pension contributiva"


*************
*ypen_ci*
*************
replace e01hde=. if (e01hde >= 999999999 & e01hde!=.)
replace e01ide=. if (e01ide >= 999999999 & e01ide!=.)
egen ypen_ci=rowtotal(e01hde e01ide)
replace ypen_ci=. if edad_ci<65 | pension_ci==0 
label var ypen_ci "Valor de la pension contributiva"

***************
*pensionsub_ci*
***************

gen pensionsub_ci=.
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*****************
**ypensub_ci*
*****************

gen ypensub_ci=.
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

**********
**tc_ci***
**********
gen tc_ci=4796.666667
label var tc_ci "Tipo de cambio LCU/USD"

*************
**salmm_ci***
*************

* PRY 2008
gen salmm_ci= 	1341775
label var salmm_ci "Salario minimo legal"

************
***emp_ci***
************
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de 	referencia de la sección laboral de la Encuesta *****.
gen byte emp_ci = .
replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
label var emp_ci "Ocupado (empleado)"
label define emp_ci 0"No" 1"Si", add
label value emp_ci emp_ci

***************
***desemp_ci***
***************
***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
gen byte desemp_ci = .
replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
label var desemp_ci "Desocupado (desempleado)"
label define desemp_ci 0"No " 1"Si", add
label value desemp_ci desemp_ci

*************
***pea_ci***
*************
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1

*****************
***desalent_ci***
*****************
***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
gen byte desalent_ci = .
replace desalent_ci = 1 if (a08 == 6 & inlist(a09, 2, 3) & condocup_ci == 3)
replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
label var desalent_ci "Desalentados"
label define desalent_ci 0"No" 1"Si", add
label value desalent_ci desalent_ci

****************
*cotizando_ci***
****************
***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
gen byte cotizando_ci = .
replace cotizando_ci = 1 if ((b10 == 1 | c07 == 1 ) & emp_ci==1)
replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0 "No"  1 "Si"
label value cotizando_ci cotizando_ci

****************
*cotizapri_ci***
****************
gen cotizapri_ci=.
replace cotizapri_ci=1 if b10==1 
replace cotizapri_ci=0 if (b10==6 | b10==.) 
recode cotizapri_ci .= 0 if peaa != 3  & peaa != 0
label var cotizapri_ci "Cotizante a la Seguridad Social en actividad ppal."

****************
*cotizasec_ci***
****************
gen cotizasec_ci=.
replace cotizasec_ci=1 if  c07==1
replace cotizasec_ci=0 if (c07==6 | c07==.)
recode cotizasec_ci .= 0 if peaa != 3  & peaa != 0
label var cotizasec_ci "Cotizante a la Seguridad Social en actividad sec."

****************
*afiliado_ci****
****************
gen afiliado_ci=.	
label var afiliado_ci "Afiliado a la Seguridad Social"

***************
***subemp_ci***
***************

gen subemp_ci=0
egen tothoras=rsum(b03lu b03ma b03mi b03ju b03vi b03sa b03do), missing
replace subemp_ci=1 if tothoras>=1 & tothoras<=30 & d01==1 & emp_ci==1



*****************
***horaspri_ci***
*****************

egen hr_seman=rsum(b03lu b03ma b03mi b03ju b03vi b03sa b03do), missing
gen hr_sem_s=tothoras
gen horaspri_ci=hr_seman if emp_ci==1 

*****************
***horastot_ci***
*****************

gen horastot_ci=hr_sem_s  if emp_ci==1 

*******************
***tiempoparc_ci***
*******************
/*
gen tiempoparc_ci=0
replace tiempoparc_ci=1 if tothoras>30 & d01==1 & emp_ci==1 /* d01 for 2006 */ 
*/
*10/21/15 MGD: corrección de sintaxis
gen tiempoparc_ci=0
replace tiempoparc_ci=1 if horaspri_ci>=1 & horaspri_ci<30 & emp_ci==1 & d03==6


******************
***categopri_ci***
******************
/*
           categoria de |
        ocupacion (act. |
             principal) |
  ----------------------+
0 na                      |     11,257       53.47       53.47
1 empleado/obrero público |        807        3.83       57.30
2 empleado/obrero privado |      3,037       14.43       71.73
3 empleador o patrón      |        467        2.22       73.95
4 cuenta propia           |      3,678       17.47       91.42
5 famil. no remunerado    |      1,054        5.01       96.42
6 empleado doméstico      |        750        3.56       99.99
9 nr                      |          3        0.01      100.00
  ----------------------+
                  Total |

*/
	gen categopri_ci=.
	replace categopri_ci=1 if cate==3 /* cate for 2007 */
	replace categopri_ci=2 if cate==4 
	replace categopri_ci=3 if cate==1 | cate==2 | cate==6 
	replace categopri_ci=4 if cate==5 
	replace categopri_ci=. if emp_ci~=1

	label define categopri_ci 1 "Patron" 2 "Cuenta propia" 
	label define categopri_ci 3 "Empleado" 4 " Familiar no remunerado" , add
	label value categopri_ci categopri_ci
	label variable categopri_ci "Categoria ocupacional"


******************
***categosec_ci***
******************

gen categosec_ci=.
replace categosec_ci=1 if c09==3
replace categosec_ci=2 if c09==4 
replace categosec_ci=3 if c09==1 | c09==2 | c09==6
replace categosec_ci=4 if c09==7 
replace categosec_ci=. if emp_ci~=1 

label define categosec_ci 1"Patron" 2 "Cuenta propia" 
label define categosec_ci 3"Empleado" 4"Familiar no remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"

*****************
*tipocontrato_ci*
*****************

gen tipocontrato_ci=. /* Solo asalariados*/
replace tipocontrato_ci=1 if b23==1 & categopri_ci==3
replace tipocontrato_ci=2 if (b23==2 | b23==4) & categopri_ci==3
replace tipocontrato_ci=3 if (b23==3 | tipocontrato_ci==.) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

*****************
***nempleos_ci***
*****************

gen nempleos_ci=0
replace nempleos_ci=1 if b27==6 /* b31 for 2007 */
replace nempleos_ci=2 if b27==1
replace nempleos_ci=. if pea_ci==0

/*
*************
*firmapeq_ci*
*************
capture drop firmapeq_ci
recode b08 (1/2=1) (3/8=0), gen(firmapeq_ci)
replace firmapeq_ci=. if b08>8
*/

*****************
***spublico_ci***
*****************

* 10/21/2015 MGD: corrección pequeña para que se tomen en cuenta a todos los ocupados.
gen spublico_ci=0 if emp_ci==1
replace spublico_ci=1 if cate==1 & emp_ci==1
/*replace spublico_ci=0 if cate!=1 & cate!=9
replace spublico_ci=. if emp_ci==.*/

**************
***ocupa_ci***
**************
/*no habra categoria 5 porque servicios y comerciantes estan en la misma codificacion
OCUP: 5112 a 5230: Trabajadores de los servicios y vendedores de comercios y mercados
*/	
gen ocupa_ci=.
replace ocupa_ci=1 if (ocup>=2113 & ocup<=3480)  & emp_ci==1
replace ocupa_ci=2 if (ocup>=1110 & ocup<=1236) & emp_ci==1
replace ocupa_ci=3 if (ocup>=4111 & ocup<=4223) & emp_ci==1
replace ocupa_ci=4 if ((ocup>=5210 & ocup<=5230) | (ocup>=9111 & ocup<=9113)) & emp_ci==1
replace ocupa_ci=5 if ((ocup>=5111 & ocup<=5169) | (ocup>=9120 & ocup<=9170)) & emp_ci==1
replace ocupa_ci=6 if ((ocup>=6111 & ocup<=6153) | (ocup>=9211 & ocup<=9212)) & emp_ci==1
replace ocupa_ci=7 if ((ocup>=7111 & ocup<=8340) | (ocup>=9311 & ocup<=9339))& emp_ci==1
replace ocupa_ci=8 if ocup==110 & emp_ci==1
replace ocupa_ci=9 if (ocup>9339 & ocup<=9999) & emp_ci==1


*************
***rama_ci***
*************
g rama_ci=.
replace rama_ci=1 if (b02>=111 & b02<=500) & emp_ci==1
replace rama_ci=2 if (b02>=1010 & b02<=1429) & emp_ci==1
replace rama_ci=3 if (b02>=1511 & b02<=3720) & emp_ci==1
replace rama_ci=4 if (b02>=4010 & b02<=4100) & emp_ci==1
replace rama_ci=5 if (b02>=4510 & b02<=4550) & emp_ci==1
replace rama_ci=6 if (b02>=5010 & b02<=5520) & emp_ci==1
replace rama_ci=7 if (b02>=6010 & b02<=6420) & emp_ci==1
replace rama_ci=8 if (b02>=6511 & b02<=7020) & emp_ci==1
replace rama_ci=9 if (b02>=7111 & b02<=9999) & emp_ci==1


/*
gen rama1=string(b02)
gen rama_ci=real(substr(rama1,1,1))  
replace rama_ci=. if rama_ci==0 | emp_ci~=1
drop rama1
*/
****************
***durades_ci***
****************
recode a11a (9=.)
recode a11m (99=.)
recode a11s (9=.)
gen durades_ci=(a11a*12)+a11m+(a11s/4.3 )
replace durades_ci=. if durades_ci==0

*******************
***antiguedad_ci***
*******************

*b07 es cuanto tiempo de su vida ha trabajado en esta ocupacion 
*b09 es cuanto lleva trabajando en la empresa
recode b09a b09m b09s (99=.)
gen antiguedad_ci=.
replace antiguedad_ci=b09a+(b09m/12)+(b09s/52) if emp_ci==1 

*************
*tamemp_ci
*************
/*
na               
solo               
2 a 5 personas      
6 a 10 personas     
11 a 20 personas    
21 a 50 personas    
51 a 100 personas   
101 a 500 personas  
más de 500 personas 
empleado doméstico 
no sabe             
nr         
               

*/
*Paraguay Pequeña 1 a 5, Mediana 6 a 50, Grande Más de 50

gen tamemp_ci = 1 if b08>=1 & b08<=2
replace tamemp_ci = 2 if (b08>=3 & b08<=5)
replace tamemp_ci = 3 if (b08>=6 & b08<=8)

label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci
label var tamemp_ci "Tamaño de empresa"

*******************
***categoinac_ci*** 
*******************
/* Variable de inactividad:
a06: razon por la que no habria podido trabajar (a diferencia de a09, a06 la responden inactivos)
           0 na                     
           1 no quiere trabajar m�s 
           2 demasiado joven        
           3 labores del hogar      
           4 estudiante             
           5 enfermo                
           6 anciano, discapacitado 
           7 rentista               
           8 jubilado               
           9 pensionado             
          10 motivos familiares     
          11 otra raz�n             
          99 nr */		  
gen categoinac_ci = .
replace categoinac_ci = 1 if ((a06==8 | a06==9) & condocup_ci==3)
replace categoinac_ci = 2 if  (a06==4 & condocup_ci==3)
replace categoinac_ci = 3 if  (a06==3 & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 

*******************
***formal***
*******************
gen formal=1 if cotizando_ci==1

replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="BOL"   /* si se usa afiliado, se restringiendo a ocupados solamente*/
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="CRI"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="GTM" & anio_c>1998
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PRY" & anio_c<=2006
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="DOM"
replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="MEX" & anio_c>=2008

gen byte formal_ci=.
replace formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
replace formal_ci=0 if formal_ci==. & (condocup_ci==1 | condocup_ci==2) 
label var formal_ci "1=afiliado o cotizante / PEA"

*************************************************************************************
*******************************INGRESOS**********************************************
*************************************************************************************

****************
***ylmpri_ci ***
****************

/*Ingresos netos por remuneracion al trabajo*/
gen ylmpri_ci=e01aimde if emp_ci==1 
replace ylmpri_ci=. if e01aimde<=0 | e01aimde>=999999999
replace ylmpri_ci=0 if categopri_ci==4


*****************
***nrylmpri_ci***
*****************

gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)


*****************
*** ylnmpri_ci***
*****************

gen ylnmpri_ci=.

***************
***ylmsec_ci***
***************

gen ysec1=e01bimde
replace ysec1=. if ysec==0 | ysec>=999999999 /*No aplicable*/

gen ylmsec_ci=ysec1
replace ylmsec_ci=. if emp_ci~=1
replace ylmsec_ci=. if ysec1==. 

drop ysec1 
******************
****ylnmsec_ci****
******************
gen ylnmsec_ci=.

*************
*ylmotros_ci*
*************

gen yocasio1=e01cimde
replace yocasio1=. if yocasio==0 | yocasio>=999999999 /*No aplicable*/

gen ylmotros_ci= yocasio1
replace ylmotros_ci=. if emp_ci~=1
replace ylmotros_ci=. if yocasio1==.
drop yocasio1

************
***ylm_ci***
************


egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.

*****************************************************************
*identificador de top-code del ingreso de la actividad principal*
*****************************************************************

gen tcylmpri_ci=.

*************
***ylnm_ci***
*************

gen ylnm_ci=.

*************
***ynlm_ci***
*************
/*
local var="e01dde e01ede e01fde e01gde e01hde e01ide e01jde"
foreach x of local var {
gen `x'1=`x'
replace `x'1=. if `x'==0 | `x'>=999999999 /*No aplicable*/
}


egen ynlm_ci=rsum(e01dde1 e01ede1 e01fde1 e01gde1 e01hde1 e01ide1 e01jde1)
replace ynlm_ci=. if e01dde1==. & e01ede1==. & e01fde1==. & e01gde1==. & e01hde1==. & e01ide1==. & e01jde1==. 

drop e01dde1 e01ede1 e01fde1 e01gde1 e01hde1 e01ide1 e01jde1 

*/
*Modificación Mayra Sáenz - Septiembre 2013
* Se elimina las remesas del cálculo del ingreso no laboral monetario del individuo (ynlm_ci), porque se està duplicando 
* al momento de generar el ingreso no laboral monetario del hogar (ynlm_ch), en donde se suma ynlm_ci y remesas_ci.
* Además se incluye "otros ingresos" (e01kde) en ynlm_ci.

local var="e01dde e01ede e01fde e01hde e01ide e01jde e01kde e01gde"
foreach x of local var {
gen `x'1=`x'
replace `x'1=. if `x'==0 | `x'>=999999999 /*No aplicable*/
}


egen ynlm_ci=rsum(e01dde1 e01ede1 e01fde1 e01hde1 e01ide1 e01jde1 e01kde1 e01gde1), missing
replace ynlm_ci=. if e01dde1==. & e01ede1==. & e01fde1==. & e01hde1==. & e01ide1==. & e01jde1==. & e01kde1==.

drop e01dde1 e01ede1 e01fde1 e01hde1 e01ide1 e01jde1 e01kde1

*********************************************
*Ingreso laboral no monetario otros trabajos*
*********************************************

gen ylnmotros_ci=.

*****************
***remesas_ci***
*****************

gen remesas_ci=e01gde
replace remesas_ci=. if e01gde>=999999999
gen ynlnm_ci=.
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)


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

by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.


*************
*** ylm_ch***
*************

by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing

**************************************************
*Identificador de los hogares en donde (top code)*
**************************************************

gen tcylmpri_ch=.

****************
*** ylmnr_ch ***
****************

by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1, missing
replace ylmnr_ch=. if nrylmpri_ch==1

***************
*** ylnm_ch ***
***************

by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing

**********************************
*** remesas_ch & remesasnm_ch ***
**********************************

gen remesash=.

by idh_ch, sort: egen remesasi=sum(remesas_ci) if miembros_ci==1, missing
replace remesasi=. if remesasi==0
egen remesas_ch=rsum(remesasi remesash), missing
replace remesas_ch=. if remesasi==. 

gen remesasnm_ch=.


***************
*** ynlm_ch ***
***************

by idh_ch, sort: egen ynlm=sum(ynlm_ci) if miembros_ci==1, missing
egen ynlm_ch=rsum(ynlm remesash), missing
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

by idh_ch, sort: egen autocons_ch=sum(autocons_ci) if miembros_ci==1, missing

*******************
*** rentaimp_ch ***
*******************

gen rentaimp_ch=v23ede /*v21ede for 2006; Si tuviera que alquilar esta vivienda cuanto estimaría que le Pag.. por mes*/
replace rentaimp_ch=. if v23ede>=15000000 /*v21ede for 2006 */

*****************
***ylhopri_ci ***
*****************

gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)


***************
***ylmho_ci ***
***************

gen ylmho_ci=ylm_ci/(horastot_ci*4.3)


****************************
***VARIABLES DE EDUCACION***
****************************


**************
***aedu_ci****
**************

/*
Ninguno                                                  0
Educ. Especial                                           1
Educ. Inicial                                            2
Educ. Escolar Básica 1º al 6º (Primaria)                 3
Educ. Escolar Básica 7º al 9º                            4
Secundaria - Ciclo Básico                                5
Bachillerato Humanístico /Científico                     6
Bachillerato Técnico /Comercial                          7
Bachillerato a Distancia                                 8
Educ. Media Científica                                   9
Educ. Media Técnica                                      10
Educ. Básica Bilingüe para personas Jóvenes y Adultas    11
Educ. Media a Distancia para Jóvenes y Adultos           12
Educ. Básica Alternativa de Jóvenes y Adultos            13
Educ. Media Alternativa de Jóvenes y Adultos             14
Formación Profesional no Bachillerato de la Media        15
Programas de Alfabetización                              16
Grado Especial/Programas Especiales                      17
Técnica Superior                                         18
Formación Docente                                        19
Profesionalización Docente                               20
Form. Militar/Policial                                   21
Superior Universitario                                   22
*/

capture drop nivgra // si la variable existe previamente se dropea
gen nivgra = ed54 
tostring nivgra, gen(nivgra_str) // convertimos nivgra en string para hacerla mutable
gen aedu_temp = substr(nivgra_str, -1, 1) // Tomamos el último char para usar de anio de c/nivel
destring aedu_temp, replace 

gen aedu_ci = .
replace aedu_ci = 0 if (nivgra == 0 | (nivgra >= 200 & nivgra <= 299)) /// 
					| (nivgra>=1100 & nivgra<=1499) | (nivgra>=1600 & nivgra<=1699)  // sin instruccion, Educ. Inicial, educacion adultos. 
replace aedu_ci = aedu_temp if (nivgra >= 300 & nivgra <= 399) // Escolar Básica 1º al 6º (Primaria)
replace aedu_ci = aedu_temp if (nivgra >= 400 & nivgra <= 499) // Escolar Básica 7º al 9º    
replace aedu_ci = aedu_temp + 9 if (nivgra >= 900 & nivgra <= 999) // Media científica
replace aedu_ci = aedu_temp + 9 if (nivgra >= 1000 & nivgra <= 1099) // Media técnica
replace aedu_ci = aedu_temp + 9 if (nivgra >= 500 & nivgra <= 599) // Secundaria - Ciclo Básico (Antiguo)
replace aedu_ci = aedu_temp + 6 if (nivgra >= 600 & nivgra <= 699) // Bachillerato Humanístico /Científico  
replace aedu_ci = aedu_temp + 6 if (nivgra >= 700 & nivgra <= 799) // Bachillerato Técnico /Comercial 
replace aedu_ci = aedu_temp + 6 if (nivgra >= 800 & nivgra <= 899) // Bachillerato a Distancia 
replace aedu_ci = aedu_temp + 6 if (nivgra >= 1500 & nivgra <= 1599) // Formación Profesional no Bachillerato de la Media 
replace aedu_ci = aedu_temp + 12 if (nivgra >= 1800 & nivgra <= 1899) // Técnica Superior  
replace aedu_ci = aedu_temp + 12 if (nivgra >= 1900 & nivgra <= 1999) // Formación Docente 
replace aedu_ci = aedu_temp + 12 if (nivgra >= 2000 & nivgra <= 2099) // Profesionalización Docente     
replace aedu_ci = aedu_temp + 12 if (nivgra >= 2100 & nivgra <= 2199) // Form. Militar/Policial 
replace aedu_ci = aedu_temp + 12 if (nivgra >= 2200 & nivgra <= 2299) // Superior Universitario  

* Post-grado
replace aedu_ci = aedu_temp + 12 + 5 + 2 if ed06 == 8 // Doctorado
replace aedu_ci = aedu_temp + 12 + 5 if ed06 == 9 // Maestría 
replace aedu_ci = aedu_temp + 12 + 5 if ed06 == 10 // Especialización

lab var aedu_ci "Anios de educación aprobados"

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
**************
***eduui_ci***
**************
gen eduui_ci = (inrange(ed54, 1801, 2206) & ed06 == 14)
replace eduui_ci = . if aedu_ci == .
lab var eduui_ci "Superior Incompleto"

**************
***eduuc_ci***
**************
gen eduuc_ci = (inrange(ed06, 1, 13))
replace eduuc_ci = . if aedu_ci == .
lab var eduuc_ci "Superior Completo"

**************
***eduac_ci***
**************
gen eduac_ci = .
replace eduac_ci = 1 if inrange(ed54, 2002, 2206)
replace eduac_ci = 0 if inrange(ed54, 1801, 1904)
label variable eduac_ci "Superior universitario vs superior no universitario"

***************
***edupre_ci***
***************
gen byte edupre_ci=. 
label variable edupre_ci "Educacion preescolar"

***************
***asis_pre***
***************
gen byte asispre_ci = (ed10 == 1)
label variable asispre_ci "Asistencia a Educacion preescolar" 
		
***************
***asiste_ci***
***************
gen asiste_ci = .
replace asiste_ci = 1 if ed10 >= 1 & ed10 <= 19
replace asiste_ci = 0 if ed10 == 20
label variable asiste_ci "Asiste actualmente a la escuela"

*****************
* Line of code with indicator pqnoasis_ci was deleted*****************
* Line of code with indicator pqnoasis_ci was deleted* Line of code with indicator pqnoasis_ci was deleted* Line of code with indicator pqnoasis_ci was deleted* Line of code with indicator pqnoasis_ci was deleted
**************
*pqnoasis1_ci*
**************
**Daniela Zuluaga- Enero 2018: Se agrega la variable pqnoasis1_ci cuya sintaxis fue elaborada por Mayra Saenz**

g       pqnoasis1_ci = 1 if ed12 == 1 | ed12 == 3
replace pqnoasis1_ci = 2 if ed12 == 2
replace pqnoasis1_ci = 3 if ed12 == 11 | ed12 == 12 | ed12 == 14
replace pqnoasis1_ci = 4 if ed12 == 15
replace pqnoasis1_ci = 5 if ed12 == 13
replace pqnoasis1_ci = 6 if ed12 == 5
replace pqnoasis1_ci = 7 if ed12 == 4
replace pqnoasis1_ci = 8 if ed12 == 6  | ed12 == 7  | ed12 == 8  | ed12 == 9 | ed12 == 10 
replace pqnoasis1_ci = 9 if ed12 == 16 | ed12 == 17 | ed12 == 18
replace pqnoasis1_ci = . if ed12 == 99

label define pqnoasis1_ci 1 "Problemas económicos" 2 "Por trabajo" 3 "Problemas familiares o de salud" 4 "Falta de interés" 5	"Quehaceres domésticos/embarazo/cuidado de niños/as" 6 "Terminó sus estudios" 7	"Edad" 8 "Problemas de acceso"  9 "Otros"
label value  pqnoasis1_ci pqnoasis1_ci

***************
* Line of code with indicator repite_ci was deleted***************
* Line of code with indicator repite_ci was deleted* Line of code with indicator repite_ci was deleted
******************
* Line of code with indicator repiteult was deleted* Line of code with indicator repiteult was deleted***************
***edupub_ci***
***************
gen edupub_ci = 1 if ed11 == 1 
replace edupub_ci = 0 if (ed11 == 2 | ed11 == 3)
replace edupub_ci = . if ed11 == .

drop nivgra aedu_temp


********************************************
***Variables de Infraestructura del hogar***
********************************************

****************
***aguared_ch***
****************
generate aguared_ch =.
replace aguared_ch = 1 if (v06==1 | v06==2 | v06==3| v06==4)
replace aguared_ch = 0 if v06>4
la var aguared_ch "Acceso a fuente de agua por red"
	
*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0
replace aguafconsumo_ch = 1 if (v10==4 | v10==1 | v10==2 |v10==3) & v11<=2
replace aguafconsumo_ch = 2 if (v10==4 | v10==1 | v10==2 |v10==3) & v11==3
replace aguafconsumo_ch = 3 if v10==11
replace aguafconsumo_ch= 4 if (v10==5 | v10==6)
replace aguafconsumo_ch = 5 if v10==10
replace aguafconsumo_ch = 6 if v10==12
replace aguafconsumo_ch = 7 if v10==8| ((v10==1 | v10==2 |v10==3| v10==4 |v10==5|v10==6|v10==8|v10==10|v10==11|v10==12) & v11==4)
replace aguafconsumo_ch = 8 if v10==13
replace aguafconsumo_ch = 9 if v10==9 | v10==7
replace aguafconsumo_ch = 10 if v10==14 | v10==99


*****************
*aguafuente_ch*
*****************
gen aguafuente_ch =.
replace aguafuente_ch = 1 if (v06==4 | v06==1 | v06==2 |v06==3) & v11<=2
replace aguafuente_ch = 2 if (v06==4 | v06==1 | v06==2 |v06==3) & v11>2
replace aguafuente_ch= 4 if (v06==5 | v06==6)
replace aguafuente_ch = 5 if v06==10
replace aguafuente_ch = 8 if v06==9
replace aguafuente_ch = 10 if (v06==11 | v06==8 |v06==7|v06==99)

*************
*aguadist_ch*
*************
gen aguadist_ch=0
replace aguadist_ch= 1 if v11==2
replace aguadist_ch= 2 if v11==1
replace aguadist_ch= 3 if v11>2 

**************
*aguadisp1_ch*
**************
destring v07, replace
gen aguadisp1_ch =0
replace aguadisp1_ch =1 if v07==1

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch = 9



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
gen aguamide_ch =.
label var aguamide_ch "Usan medidor para pagar consumo de agua"


*****************
*bano_ch         *  Altered
*****************
destring v16, replace
gen bano_ch=.
replace bano_ch=0 if v15==6
replace bano_ch=1 if v16==1
replace bano_ch=2 if v16==2
replace bano_ch=3 if (v16==5 | v16==6)
replace bano_ch=4 if v16==4
replace bano_ch=5 if v16==7
replace bano_ch=6 if (v16==8 | v16==3| v16==9) 

***************
***banoex_ch***
***************
generate banoex_ch=9
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
replace sinbano_ch = 0 if v15==1

*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

*************
*aguatrat_ch*
*************
gen aguatrat_ch = 9
*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"




****************
*****luz_ch*****
****************

* Modificaciones Marcela Rubio - Noviembre 2014
/*
ren v12 luz_ch
replace luz_ch=0 if luz_ch==2
*/

gen luz_ch = (v12==1)
replace luz_ch = . if v12==.

****************
***luzmide_ch***
****************

gen luzmide_ch=.

****************
***combust_ch***
****************

gen combust_ch=1 if v18b==4 | v18b==2/* v14b for 2006 */
replace combust_ch=0 if v18b==1 | v18b==3 |v18b==5 | v18b==6 
 



****************
****des1_ch*****
****************

gen des1_ch=.
replace des1_ch=0 if v16==0/* v16 for 2008 */
replace des1_ch=1 if v16==1 | v16==2
replace des1_ch=2 if v16==5 |v16==6 |v16==7 | v16==3
replace des1_ch=3 if v16==4 


****************
****des2_ch*****
****************

gen des2_ch=.
replace des2_ch=1 if des1_ch==1| des1_ch==2
replace des2_ch=0 if des1_ch==0
 
****************
****piso_ch*****
****************

gen piso_ch=.
replace piso_ch=0 if v04==1
replace piso_ch=1 if v04>=2 & v04<=8
replace piso_ch=2 if v04==9


****************
****pared_ch****
****************


gen muros1=v03
gen pared_ch=.
replace pared_ch=0 if muros1>=1
replace pared_ch=1 if muros1>=3 & muros1<=5
replace pared_ch=2 if muros1==6
drop muros1


****************
****techo_ch****
****************
gen techo1=v05
gen techo_ch=.
replace techo_ch=0 if techo1>=6 & techo1<=8
replace techo_ch=1 if techo1>=1 & techo1<=5
replace techo_ch=2 if techo1==9
drop techo1
****************
****resid_ch****
****************

gen basura=v19 /* v19 for 2008 */
gen resid_ch=0 if basura==2
replace resid_ch=1 if basura==1 
replace resid_ch=2 if basura>=3 & basura<=7 /* >=3 & <=7 for 2006 */
replace resid_ch=3 if basura==8 /* v16==8 for 2006 */
drop basura


****************
****dorm_ch*****
****************

gen dorm_ch=.
replace dorm_ch=v02b
replace dorm_ch=. if dorm_ch==99

****************
***cuartos_ch***
****************

gen cuartos_ch=v02a

****************
***cocina_ch****
****************

gen cocina_ch=v18a /* v14a for 2006 */
 replace cocina_ch=0 if cocina==6 /* chequear, el codigo 6 es para especificar cuando no se tiene cocina */


****************
****telef_ch****
****************

gen telef_ch=v14a /* v11a for 2007 */

****************
****refrig_ch***
****************

gen refrig1=v2803 
gen refrig_ch=.
replace refrig_ch=1 if refrig1==3
replace refrig_ch=0 if refrig1==0
drop refrig1

****************
****freez_ch****
****************

gen freez_ch=.


****************
****auto_ch*****
****************
gen automovil=v2812
gen auto_ch=.
replace auto_ch=1 if automovil==12
replace auto_ch=0 if automovil==0
drop automovil 

****************
****compu_ch****
****************

gen compu_ch=v27a/* v27a for 2006 */
replace compu_ch=1 if v27a==1
replace compu_ch= 0 if v27a ==6

****************
**internet_ch***
****************

gen internet_ch=v27b /* v27b for 2006 */
replace internet_ch=1 if v27b==1
replace internet_ch= . if v27b == 0
replace internet_ch= 0 if v27b == 6


****************
****cel_ch******
****************

gen cel_ch=v14c /* v11c for 2006 */
replace cel_ch=0 if v14c==6


****************
****vivi1_ch****
****************

gen vivi1_ch=.
replace vivi1_ch=3 if v01>0
replace vivi1_ch=1 if v01==1
replace vivi1_ch=2 if v01==3


****************
****vivi2_ch****
****************

gen vivi2_ch=0
replace vivi2_ch=0 if v01>0
replace vivi2_ch=1 if v01==1 | v01==3


*******************
****viviprop_ch****
*******************

gen viviprop_ch=.
replace viviprop_ch=0 if v20==4
replace viviprop_ch=1 if v20==1 | v20==3
replace viviprop_ch=2 if v20==2
replace viviprop_ch=3 if v20==5 | v20==6 | v20==7

******************
****vivitit_ch****
******************

gen vivitit_ch=.

*******************
****vivialq_ch****
*******************

gen vivialq_ch=v21

*********************
****vivialqimp_ch****
*********************

gen vivialqimp_ch=v23 /* v20ede for 2007 */

ren ocup ocup_old


******************************
*** VARIABLES DE MIGRACION ***
******************************

* Variables incluidas por SCL/MIG Fernando Morales

	*******************
	*** migrante_ci ***
	*******************
	
	gen migrante_ci=(p10a>19) if p10a!=99 & p10a!=.
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migantiguo5_ci ***
	**********************
	
	gen migantiguo5_ci=(migrante_ci==1 & p11a<20) if migrante_ci!=. & p11a!=. & p11a!=99 & !inrange(edad_ci,0,4)
	label var migantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** migrantelac_ci ***
	**********************
	
	gen migrantelac_ci=(migrante_ci==1 & inlist(p10a,20,21,22,23,24,28,31,32)) if migrante_ci!=.
	label var migrantelac_ci "=1 si es migrante proveniente de un pais LAC"
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	
	gen migrantiguo5_ci=(migrante_ci==1 & p11a<20) if migrante_ci!=. & p11a!=. & p11a!=99 & !inrange(edad_ci,0,4)
	replace migrantiguo5_ci= 0 if migrantiguo5_ci != 1 & migrante_ci == 1
	replace migrantiguo5_ci= . if migrante_ci == 0
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci=(migrante_ci==1 & inlist(p10a,20,21,22,23,24,28,31,32)) if migrante_ci!=.
	replace miglac_ci = 0 if miglac_ci != 1 & migrante_ci == 1
	replace miglac_ci = . if migrante_ci == 0
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"

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
  /// the order was created by regex functions, sph variables are excluded

/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/
rename b01 codocupa
rename rama codindustria

compress


saveold "`base_out'", replace


log close


