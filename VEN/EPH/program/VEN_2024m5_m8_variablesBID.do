* (Versión Stata 18)
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES -  
País: VEN
Encuesta: EPH
Round: m5_m8
Autores: Jillie Chang - jilliechangkcomt@gmail.com
Fecha última modificación: 27MAR2025

							SCL/SCL - IADB
****************************************************************************/
****************************************************************************/


******************************************************************
*****************  Definir rutas y abrir base ********************
******************************************************************

clear
set more off
 
global ruta = "${surveysFolderRestricted}"
local PAIS VEN
local ENCUESTA EPH
local ANO "2024"
local ronda m5_m8
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
                        
capture log close
log using "`log_file'", replace 

use "`base_in'", clear

******************************************************************
*****************  Armonización de variables  ********************
******************************************************************

	**************************
	***** Identificación *****
	**************************

************************
*** region según BID ***
************************
gen byte region_BID_c=3 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

************
* region_c *
************
*Decisión:la encuesta no se hizo en todos los estados. Es representativa a nivel Nacional, AMC y resto de país 
gen byte region_c= 1 if estado ==5 
replace region_c=3 if estado ==1
replace region_c=5 if estado ==2
replace region_c=7 if estado ==3
replace region_c=8 if estado ==4
replace region_c=12 if estado ==6
replace region_c=13 if estado ==7
replace region_c=14 if estado ==8
replace region_c=15 if estado ==9
replace region_c=16 if estado ==10
replace region_c=17 if estado ==11
replace region_c=18 if estado ==12
replace region_c=20 if estado ==13
replace region_c=21 if estado ==14
replace region_c=23 if estado ==16
replace region_c=24 if estado ==15

label define region_c  ///
1	"Distrito Federal"  ///
2	"Amazonas " ///
3	"Anzoategui"  ///
4	"Apure " ///
5	"Aragua " ///
6	"Barinas " ///
7	"Bolívar " ///
8	"Carabobo " ///
9	"Cojedes " ///
10	"Delta Amacuro"  ///
11	"Falcón"  ///
12	"Guárico"  ///
13	"Lara"  ///
14	"Mérida"  ///
15	"Miranda"  ///
16	"Monagas"  ///
17	"Nueva Esparta"  /// 
18	"Portuguesa"  ///
19	"Sucre"  ///
20	"Táchira"  ///
21	"Trujillo"  ///
22	"Yaracuy"  ///
23	"Zulia"  ///
24	"Vargas" 
	    
label value region_c region_c
label var region_c " Primera División política - Entidades Federativas"

************
****pais****
************
gen str pais_c="VEN"

**********
***anio***
**********
gen byte anio_c=2024

*********
***mes***
*********
gen byte mes_c=.

**********
***zona***
**********
gen byte zona_c=.

***************
***estrato_ci**
***************
gen byte estrato_ci=.

***************
***upm_ci***
***************
gen byte upm_ci=.

**************
*** idh_ch ***
**************
tostring id_hogar, gen(idh_ch) format("%20.0f")
egen unique_tag = tag(idh_ch)
count if unique_tag == 1 //se verifica que son 2000 hogares

**************
*** idp_ci ***
**************
tostring id_miembro, gen(idp_ci) format("%20.0f")
duplicates report idp_ci

***************
***factor_ci***
***************
gen factor_ci=peso_indiv_ajustado_24

***************
***factor_ch***
***************
gen factor_ch=peso_ajustado_24


	**********************
	***** Demografía *****
	**********************

**********
***sexo***
**********
gen byte sexo_ci=.
replace sexo_ci=1 if p36_s3==1
replace sexo_ci=2 if p36_s3==2

**********
***edad***
**********
gen byte edad_ci=p38_s3
replace edad_ci =. if p38_s3==9899
label variable edad_ci "Edad del individuo"
*nota no se utiliza variable p39_s3. Preguntar por factor
/*
                      |  ¿Cuál es  la edad del
                      |  miembro Indicó 9899   
      edad, por favor |  en años
     seleccione según | cumplidos?
         corresponda. |      9899 |     Total
----------------------+-----------+----------
El menos 5 años       |        12 |        12 
El miembro 10 años +  |         1 |         1 
El miembro 5-10 años  |         9 |         9 
----------------------+-----------+----------
                Total |        22 |        22 */
				
*****************
***relacion_ci***
*****************
gen byte relacion_ci=1 if p35_s3==1
replace relacion_ci=2 if p35_s3==2
replace relacion_ci=3 if p35_s3==3 
replace relacion_ci=4 if p35_s3>=4 & p35_s3<=11
replace relacion_ci=5 if p35_s3==12

*****************
***civil_ci***
*****************
gen byte civil_ci=.
replace civil_ci=1 if p40_s3==6   //"Soltero"
replace civil_ci=2 if p40_s3==1 | p40_s3==2    //"Union formal o informal"
replace civil_ci=3 if p40_s3==3 | p40_s3==4    // "Divorciado o separado"
replace civil_ci=4 if p40_s3==5    //"Viudo" 

**************
***jefe_ci***
*************
gen byte jefe_ci=(relacion_ci==1)

******************
***nconyuges_ch***
******************
egen byte nconyuges_ch=sum(relacion_ci==2), by(idh_ch)

***************
***nhijos_ch***
***************
egen byte nhijos_ch=sum(relacion_ci==3), by(idh_ch)

******************
***notropari_ch***
******************
egen byte notropari_ch=sum(relacion_ci==4), by(idh_ch)

********************
***notronopari_ch***
********************
egen byte notronopari_ch=sum(relacion_ci==5), by(idh_ch)

****************
***nempdom_ch***
****************
*NOTA: dentro de las relaciones de parentesco no es posible identificar a los empleados domésticos
gen byte nempdom_ch=.

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

****************
***miembros_ci***
****************
gen byte miembros_ci=(relacion_ci<5)

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


	**********************
	***** Diversidad *****
	**********************

************
* afro_ci  *
************
gen byte afro_ci=. 
replace afro_ci =1 if  inlist(p62_s3,1,2,3)
replace afro_ci =0 if inlist(p62_s3,4,5,6)

***********
* ind_ci  *
***********
gen byte ind_ci=. 
replace ind_ci =1 if  inlist(p62_s3,5)
replace ind_ci =0 if inlist(p62_s3,1,2,3,4,6)

*****************
* noafroind_ci  *
*****************
gen byte noafroind_ci =.  
replace noafroind_ci =1 if afro_ci==0 & ind_ci==0
replace noafroind_ci =0 if afro_ci==1 | ind_ci==1
replace noafroind_ci =. if afro_ci==. | ind_ci==. 

************
* afro_ch  *
************
gen byte afro_jefe = afro_ci if relacion_ci==1
egen afro_ch  = max(afro_jefe), by(idh_ch) 
drop afro_jefe

***********
* ind_ch  *
***********
gen byte ind_jefe = ind_ci if relacion_ci==1
egen ind_ch = max(ind_jefe), by(idh_ch) 
drop ind_jefe 

*****************
* noafroind_ch  *
*****************
gen byte noafroind_jefe = noafroind_ci if relacion_ci==1
egen noafroind_ch = max(noafroind_jefe), by(idh_ch) 
drop noafroind_jefe

*****************
* afroind_ano_c *
*****************
gen byte afroind_ano_c = 2023

***************
***afroind_ci***
***************
gen byte afroind_ci=. 
replace afroind_ci=1 if ind_ci==1 
replace afroind_ci=2 if afro_ci==1
replace afroind_ci=3 if noafroind_ci== 1

***************
* afroind_ch  *
***************
gen byte afroind_jefe = afroind_ci if jefe_ci==1
egen afroind_ch = min(afroind_jefe), by(idh_ch) 
drop afroind_jefe 

**********
* dis_ci *
**********
gen byte dis_ci =.
egen discapacidad=rowtotal(p55a_s3 p55b_s3  p55c_s3  p55e_s3  p55f_s3  p55g_s3  p55k_s3), mi
replace dis_ci = 1 if discapacidad >7 & discapacidad!=.
replace dis_ci =0 if discapacidad ==7
drop discapacidad

*br dis_ci disWG_ci p55a_s3 p55b_s3  p55c_s3  p55e_s3  p55f_s3  p55g_s3  p55k_s3

************
* disWG_ci *
************
gen byte disWG_ci = .
replace disWG_ci = 0 if (( p55a_s3>= 1 & p55a_s3 <=2 )| ///
                      ( p55b_s3>= 1 &  p55b_s3 <=2 )| ///
					  ( p55c_s3>= 1 &  p55c_s3 <=2 )| ///
					  ( p55e_s3>= 1 &  p55e_s3 <=2 )| ///
					  ( p55f_s3>= 1 &  p55f_s3 <=2 )| ///
					  ( p55g_s3>= 1 &  p55g_s3 <=2 )| ///
					  ( p55k_s3>= 1 &  p55k_s3 <=2 ))					 
replace disWG_ci = 1 if (( p55a_s3>= 3 &  p55a_s3 <=4 )| ///
                      ( p55b_s3>= 3 &  p55b_s3 <=4 )| ///
					  ( p55c_s3>= 3 &  p55c_s3 <=4 )| ///
					  ( p55e_s3>= 3 &  p55e_s3 <=4 )| ///
					  ( p55f_s3>= 3 &  p55f_s3 <=4 )| ///
					  ( p55g_s3>= 3 &  p55g_s3 <=4 )| ///
					  ( p55k_s3>= 3 &  p55k_s3 <=4 ))

************
* VEN_dis_ci *
************
gen byte VEN_dis_ci =dis_ci

**********
* dis_ch *
**********		
egen byte dis_ch  = sum(dis_ci), by(idh_ch) 
replace dis_ch=1 if dis_ch>=1 & dis_ch!=. 


	***************************
	***** Mercado laboral *****
	***************************

****************
****condocup_ci*
****************
/*p105_s5 Indica la situación laboral del miembro encuestado para la semana pasada al inicio de la encuesta.
1 Trabajó por lo menos una hora en una actividad que le generó ingresos
2 No trabajó, pero tiene un empleo o trabajo por el que recibe ingresos
4 Buscando trabajo habiendo trabajado antes
5 En quehaceres del hogar
6 Estudiando sin trabajar
7 Pensionado sin trabajar
8 Jubilado sin trabajar
9 Incapacitado
10 Otro
*/	  
gen byte condocup_ci=.
replace condocup_ci=1 if (p105_s5==1 | p105_s5==2)  //ocupados
replace condocup_ci=2 if (p105_s5==3 | p105_s5==4)   // desocupados
replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2 & edad_ci!=.     //inactivos
replace condocup_ci=4 if edad_ci<15 & edad_ci!=.    //menor edad

/*verificar tasa ocupados y desocupados (ocupados y desocupados con relacion a PET)
gen pet = 1 if (edad_ci>=15 & edad_ci<=64)
gen pea = 1 if (condocup_ci == 1 | condocup_ci == 2 ) & pet == 1
tab condocup_ci if pet==1  [iw=factor_ci]

condocup_ci |      Freq.     Percent        Cum.
------------+-----------------------------------
          1 | 10762664.2       56.57       56.57
          2 |  1,267,498        6.66       63.23
          3 |  6,994,989       36.77      100.00
------------+-----------------------------------
      Total | 19025150.9      100.00

6.66 tasa desocupacion (desocupados/pet) y 56.75 tasa de ocupacion (ocupados/pet) 
Decisión: se utilizó la edad de 15 años en lugar de */

*****************
*categoinac_ci***
*****************
gen byte categoinac_ci = .
replace categoinac_ci = 1 if ((p105_s5==7 | p105_s5==8) & condocup_ci==3)  //jubilados o pensionados
replace categoinac_ci = 2 if (p105_s5==6 & condocup_ci==3)   //estudiante
replace categoinac_ci = 3 if (p105_s5==5 & condocup_ci==3)  //3 "Quehaceres domésticos"
replace categoinac_ci = 4 if ((categoinac_ci !=1 & categoinac_ci !=2 & categoinac_ci !=3) & condocup_ci==3)  //otros
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "Jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"
label values categoinac_ci categoinac_ci

************
***emp_ci***
************
gen byte emp_ci=(condocup_ci==1)

*************
*cesante_ci* 
*************
generat byte cesante_ci=.

****************
***desemp_ci***
****************
gen byte desemp_ci=(condocup_ci==2)

***************
***subemp_ci***
***************
gen byte subemp_ci=.

****************
***durades_ci***
****************
gen byte durades_ci = .

*************
***pea_ci***
*************
gen byte pea_ci=(emp_ci==1 | desemp_ci==1)

*****************
***nempleos_ci***
*****************
gen byte nempleos_ci=.

*******************
***antiguedad_ci***
*******************
gen byte antiguedad_ci= p126_s6

*****************
***desalent_ci***
*****************
gen byte desalent_ci=.

*****************
***horaspri_ci***
*****************
gen byte horaspri_ci=.

*****************
***horastot_ci ***
*****************
gen byte horastot_ci = .

*******************
***tiempoparc_ci***
*******************
gen byte tiempoparc_ci=.

******************
***categopri_ci***
******************
/* Se clasificó la variable p112_s5 de la siguiente forma:
    otro 7 
	       Trabajador en sociedades de personas            
	asalariado		
           1 Empleado del sector público
           3 Empleado en empresa privada
           2 Obrero en el sector público
           4 Obrero en empresa privada
    Trabajador No Remunerado"
           8 Ayudante familiar no remunerado
   	patrono
		   5 Patrono o empleador
	cuenta propia
		   10 Trabajador por cuenta propia
		   6 Miembro de cooperativa
		   9 Servicio doméstico       
		  xxxx 
         preg 7 
Decisión: Se consultó a SPL sobre la categoría 7. Se colocó en otra clasificación		   
		   */
gen byte categopri_ci=.
replace categopri_ci=0 if p112_s5==7 & condocup_ci==1   //otra
replace categopri_ci=1 if p112_s5==5 & condocup_ci==1   //patron empleador
replace categopri_ci=2 if (p112_s5==10 | p112_s5==6 | p112_s5==9)  & condocup_ci==1  //cuenta propia
replace categopri_ci=3 if (p112_s5>=1 & p112_s5<=4)   & condocup_ci==1   //empleado asalariado
replace categopri_ci=4 if p112_s5==8 & condocup_ci==1	

******************
***categosec_ci***
******************
gen byte categosec_ci=.

*************
***rama_ci***
*************
gen byte rama_ci=.
replace rama_ci=1 if p111_s5==1 & emp_ci==1 
replace rama_ci=2 if p111_s5==2 & emp_ci==1 
replace rama_ci=3 if p111_s5==3 & emp_ci==1 
replace rama_ci=4 if p111_s5==4 & emp_ci==1 
replace rama_ci=5 if p111_s5==5 & emp_ci==1 
replace rama_ci=6 if inlist(p111_s5,6,8) & emp_ci==1 
replace rama_ci=7 if p111_s5==7 & emp_ci==1 
replace rama_ci=8 if inlist(p111_s5,10,11,12) & emp_ci==1 
replace rama_ci=9 if inlist(p111_s5,9,13,14,15,16,17,18,19) & emp_ci==1 

*****************
***spublico_ci***
*****************
gen byte spublico_ci=.
replace spublico_ci=0 if emp_ci==1 
replace spublico_ci=1 if emp_ci==1 & (p112_s5 ==1 | p112_s5 ==2  )

*************
*tamemp_ci***
*************
*Decisión: se consideró el tamaño en función a lo encontrado en la armonización 2018 VEN.
gen byte tamemp_ci=.
replace tamemp_ci=1 if p130_s6>=1 & p130_s6<=3   //1 a 5 
replace tamemp_ci=2 if p130_s6>=4 & p130_s6<=5   //6 a 20
replace tamemp_ci=3 if p130_s6>=6 & p130_s6<=7   //21 +100
label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
label values tamemp_ci tamaño
tab tamemp_ci [iw=factor_ci]
	
****************
*cotizando_ci***
****************
*pensión
gen byte cotizando_ci=.
replace cotizando_ci=1 if p132_s6 ==1 
replace cotizando_ci=0 if p132_s6 ==2

********************
*** instcot_ci *****
********************
gen byte instcot_ci=.
	
****************
*afiliado_ci****
****************
gen byte afiliado_ci=.
replace afiliado_ci=0   if condocup_ci==1 | condocup_ci==2 
replace afiliado_ci=1 if p131_s6 ==1 

*************
***formal_ci***
*************
gen byte formal_ci=(cotizando_ci==1)

*****************
*tipocontrato_ci*
*****************
gen byte tipocontrato_ci=.
replace tipocontrato_ci =0 if p128_s6 ==5  // 0 con contrato
replace tipocontrato_ci =1 if p128_s6  ==1    //1	Permanente/indefinido.
replace tipocontrato_ci =2 if p128_s6  ==2     // 2 Temporal/tiempo definido.
replace tipocontrato_ci =3 if p128_s6  ==3 | p128_s6 ==4    //3	Sin contrato/verbal

**************
***ocupa_ci***
**************
gen byte ocupa_ci=.

*************
**pension_ci*
*************
gen byte pension_ci=.

***************
*pensionsub_ci*
***************
gen byte pensionsub_ci=.

****************
*tipopen_ci*****
****************
gen byte tipopen_ci=.

****************
*instpen_ci*****
****************
gen byte instpen_ci=.


	********************
	***** Ingresos *****
	********************

local variables ing_salario ing_act_rem ing_act_sec  ing_otros ing_exterior  ing_bonos remesas_total
foreach v of local variables {
	gen `v'_bol = `v'_usd_imp*ves_usd_mensual
	replace `v'_bol =. if `v'_bol<0
	}	 
local agregados ing_lab ing_no_lab  ing_total
foreach v of local agregados {
	gen `v'_bol = `v'_usd_ci*ves_usd_mensual
	replace `v'_bol =. if `v'_bol<0
	}

****************
***ylmpri_ci ***
****************
*"Ingreso Laboral Monetario de la Act.Principal"
egen ylmpri_ci= rowtotal(ing_salario_bol ing_act_rem_bol), mi // 

*****************
*** ylnmpri_ci***
*****************
*"Ingreso Laboral NO Monetario de la Actividad Principal"
gen ylnmpri_ci=.

*****************
*** ylmsec_ci ***
*****************
*"Ingreso Laboral Monetario de la Act.Secundaria"
gen ylmsec_ci = ing_act_sec_bol   
 
***************
***ylnmsec_ci***
***************
* "Ingreso Laboral NO Monetario de la Actividad Secundaria"
gen ylnmsec_ci=.

******************
*** ylmotros_ci***
******************
* "Ingreso Laboral Monetario Otros Trabajos"
gen ylmotros_ci=.

******************
***ylnmotros_ci***
******************
* "Ingreso Laboral NO Monetario Otros Trabajos"
gen ylnmotros_ci=.

************
***ylm_ci***
************
* "Ingreso laboral monetario total"  
egen ylm_ci= rowtotal(ylmpri_ci ylmsec_ci),mi

*************
***ylnm_ci***
*************
* "Ingreso Laboral NO Monetario Total"
egen ylnm_ci=rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi

*************
***ynlm_ci***
*************
*"Ingreso NO Laboral Monetario"
local variables ing_otros_bol ing_exterior_bol  ing_bonos_bol 
foreach v of local variables {
	replace `v' =. if `v'<0 
}
egen ynlm_ci= rowtotal(ing_otros_bol ing_exterior_bol  ing_bonos_bol remesas_total_bol), mi
*Decisión: se suman las remesas que están por hogar (por jefe) a los ingresos del jefe de hogar.


*************
***ynlnm_ci***
*************
*"Ingreso NO Laboral NO Monetario"
gen ynlnm_ci= .

****************
*** ytot_ci  ***
****************
* Ingreso total monetario y no monetario del individuo
egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

*************
*** ylm_ch***
*************
*"Ingreso Laboral Monetario del Hogar"
egen ylm_ch=sum(ylm_ci) if miembros_ci==1, by(idh_ch)

***************
*** ylnm_ch ***
***************
*"Ingreso Laboral No Monetario del Hogar"
egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, by(idh_ch)

***************
*** ynlm_ch ***
***************
*"Ingreso No Laboral Monetario del Hogar"
egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, by(idh_ch)

****************
*** ynlnm_ch ***
****************
* "Ingreso No Laboral No Monetario del Hogar"
egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, by(idh_ch)

*******************
*** ylmhopri_ci ***
*******************
gen ylmhopri_ci=.

***************
***ylmho_ci ***
***************
gen ylmho_ci=.

*******************
*** nrylmpri_ci ***
*******************
g nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)
replace nrylmpri_ci=. if emp_ci!=1 | categopri_ci==4   

******************
*** nrylmpri_ch***
******************
sort idh
egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, by(idh)
replace nrylmpri_ch=1 if nrylmpri_ch>1 & nrylmpri_ch~=. & miembros_ci==1

****************
*** ylmnr_ch ***
****************
egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1 & nrylmpri_ch==0, by(idh_ch)

*****************
***remesas_ci***
*****************
gen remesas_ci=remesas_total_bol if jefe_ci ==1

******************
*** remesas_ch ***
******************
egen remesas_ch=sum(remesas_ci), by(idh_ch)

*********
*ypen_ci*
*********
gen ypen_ci =.

*****************
**  ypensub_ci  *
*****************
gen ypensub_ci=.


	********************
	***** Educación ****
	********************
 
*************
***aedu_ci***
*************
/* no se puede armonizar esta variable. Para hacerlo, se necesitaría
- Último nivel educativo aprobado (ésta es p149_s7 en el EPH)
- Último año o grado aprobado dentro de ese nivel (esta no está en la EPH)
*/
gen byte aedu_ci =.

***************
***edupre_ci***
***************
*"Tiene Educacion preescolar"
* p149_s7 ¿Cuál fue el último nivel educativo aprobado?  2 Inicial (preescolar)
* p136_s7 En caso de asistir a un centro educativo actualmente, ¿qué nivel/grado/semestre/año fue el último que aprobó? 2 Inicial (preescolar)
gen byte edupre_ci = (p149_s7 ==2)    // |p136_s7==2
replace edupre_ci=. if (p149_s7 ==.)     //&p136_s7==.

**************
***eduui_ci***
**************
* "Universitaria incompleta"
gen byte eduui_ci = .

***************
***eduuc_ci***
***************
* "educación técnica, universitaria completa, o posgrado (completa o incompleta)"
gen byte eduuc_ci = (inlist(p149_s7, 5, 6, 7) | inlist(p136_s7, 5,6, 7))
replace eduuc_ci = . if (p149_s7 ==.&p136_s7==.)   

**************
***eduac_ci***
**************
*"Superior universitario vs superior no universitario"
gen byte eduac_ci = 1 if inlist(p149_s7,  6, 7) | inlist(p136_s7, 6, 7) 
replace eduac_ci = 0 if inlist(p149_s7,  5) | inlist(p136_s7, 5) 
replace eduac_ci = . if (p149_s7 ==.&p136_s7==.)   

***************
***asiste_ci***
***************
* "Asiste actualmente a la escuela"
gen byte asiste_ci=.  
replace asiste_ci = 1 if p135_s7==1
replace asiste_ci = 0 if p135_s7==2

***************
***edupub_ci***
***************
* Decisión: se colocó "otra Especifique" que son semiprivadas(11 obs) en privada
gen byte edupub_ci=.
replace edupub_ci=1 if p138_s7==2 & asiste_ci==1
replace edupub_ci=0 if p138_s7!=2 & asiste_ci==1
replace edupub_ci=. if p138_s7==4 & asiste_ci==1

****************
***asispre_ci***
****************
* "Asiste a educacion prescolar"
gen byte asispre_ci= (p136_s7==2 & asiste_ci==1)  // matriculado en nivel inicial (sin edad)
replace asispre_ci = . if asiste_ci==.

**************
*pqnoasis1_ci*
**************
gen byte pqnoasis1_ci = 1 if inlist(p141_s7,4,5,8)
replace pqnoasis1_ci = 3 if p141_s7==6
replace pqnoasis1_ci = 4 if p141_s7==13
replace pqnoasis1_ci = 5 if inlist(p141_s7,7,12)
replace pqnoasis1_ci = 8 if inlist(p141_s7,1,2,3)
replace pqnoasis1_ci = 9 if inlist(p141_s7,9,10,11,14,15)



	********************
	***** Vivienda  ****
	********************
 		
************
***luz_ch***
************
gen luz_ch=.
replace luz_ch=1 if p9_s1==1 
replace luz_ch=0 if p9_s1==2 

****************
***luzmide_ch***
****************
gen luzmide_ch=.
replace luzmide_ch=1 if p10_s1==1 
replace luzmide_ch=0 if p10_s1==2 

****************
***combust_ch***
****************
gen combust_ch=.

*************
***piso_ch***
*************
gen piso_ch=.
replace piso_ch=0 if p4_s1==3
replace piso_ch=1 if p4_s1==1 | p4_s1==2 
replace piso_ch=2 if p4_s1==4  | p4_s1==5
  
**************
***pared_ch***
**************
gen pared_ch=.
replace pared_ch=0 if  p3_s1== 8
replace pared_ch=1 if  inlist(p3_s1,1,2,3,4)
replace pared_ch=2 if  inlist(p3_s1,5,6,7)

**************
***techo_ch***
**************
gen techo_ch=.

**************
***resid_ch***
**************
gen resid_ch=.
*Decisión: En la pregunta de recolección de basura, la opción "Se desecha en cualquier lugar"  no permite distinguir si se desecha en "2 Tirados a un espacio abierto", se coloca en "otros". Para las otras categorías "Se deposita en contenedor colectivo" y "Se deposita en vertedero", se siguió lo utilizando en el encovi 2021
replace resid_ch=0 if p12_s1==1 
replace resid_ch=1 if p12_s1==4
replace resid_ch=3 if inlist(p12_s1,2,3,5)   
tab resid_ch [iw=factor_ci]

*************
***dorm_ch***
*************
gen dorm_ch=p19_s2

****************
***cuartos_ch***
****************
gen cuartos_ch=.
	
***************
***cocina_ch***
***************
gen cocina_ch=.
*replace cocina_ch=1 if p22_s2==1
*replace cocina_ch=0 if p22_s2==2

**************
***telef_ch***
**************
gen telef_ch=.

***************
***refrig_ch***
***************
* En venezuela se conoce como nevera
* Decisión: La opción "Sí tiene acceso, pero no funciona" se colocó dentro de la categoría "0 el resto"
gen refrig_ch=.
replace refrig_ch=1 if p29a_s2==1
replace refrig_ch=0 if p29a_s2==3|p29a_s2==2

**************
***freez_ch***
**************
gen freez_ch=.

*************
***auto_ch***
*************
gen auto_ch=. 
replace auto_ch=1 if  p30c_s2==1 
replace auto_ch=0 if  p30c_s2==0

**************
***compu_ch***
**************
*Nota: la variable p29c_s2 contiene Computadora o Tablet. No se puede distinguir
gen compu_ch=.

*****************
***internet_ch***
*****************
*Nota: no está la variable p29d_s2 en el dta (d, e, f ...)
gen internet_ch=.

************
***cel_ch***
************
*Nota: no está la variable p29f_s2 p29e_s2 en el dta (d, e, f ...)
gen cel_ch=.

**************
***vivi1_ch***
**************
gen vivi1_ch=. 
replace vivi1_ch=1 if inlist(p2_s1,2,6)
replace vivi1_ch=2 if inlist(p2_s1,3,4)
replace vivi1_ch=3 if inlist(p2_s1,1,5,7,8,9)

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
*Nota: a qué se refiere 7 vivienda indígena. no se incluye en clasificación
gen viviprop_ch=.
replace viviprop_ch=0 if p17_s2== 3
replace viviprop_ch=1 if p17_s2== 1
replace viviprop_ch=2 if p17_s2== 2
replace viviprop_ch=3 if p17_s2== 4 | p17_s2== 5

****************
***vivitit_ch***
****************
gen vivitit_ch=.

****************
***vivialq_ch***
****************
gen vivialq_ch=.

*******************
***vivialqimp_ch***
*******************
gen vivialqimp_ch=.


	*****************
	*****  WASH  ****
	*****************

****************
***aguared_ch***
****************
gen byte aguared_ch =0
replace aguared_ch = 1 if p6_s1==1
replace aguared_ch = . if p6_s1==.
	
*****************
*aguafconsumo_ch*
*****************
gen byte aguafconsumo_ch = 0

*****************
*aguafuente_ch*
*****************
gen byte aguafuente_ch=.
replace aguafuente_ch = 1 if p6_s1==1
replace aguafuente_ch= 2 if p6_s1==2
replace aguafuente_ch = 6 if p6_s1==3
replace aguafuente_ch = 10 if p6_s1 ==4 |p6_s1 ==5

*************
*aguadist_ch*
*************
gen byte aguadist_ch=0

**************
*aguadisp1_ch*
**************
gen byte aguadisp1_ch=9

**************
*aguadisp2_ch*
**************
*Nota:  abrir categoria "2 Algunos días de la semana"  para poder clasificar 
gen byte aguadisp2_ch =.

*************
*aguatrat_ch*
*************
gen byte aguatrat_ch =.
replace aguatrat_ch = 1 if p21_s2>=1 & p21_s2<=5
replace aguatrat_ch = 0 if p21_s2==6

*************
*aguamala_ch* 
*************
gen byte aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*
*****************
gen byte aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7 

*****************
***aguamide_ch***
*****************
gen byte aguamide_ch = .

*****************
*bano_ch        *
*****************
gen byte bano_ch=.
replace bano_ch=0 if p8_s1==4
replace bano_ch=1 if p8_s1==1
replace bano_ch=6 if p8_s1==2|p8_s1==3

***************
***banoex_ch***
***************
gen byte banoex_ch=9

************
*sinbano_ch*
************
gen byte sinbano_ch = 3
replace sinbano_ch = 3 if p8_s1!=4
replace sinbano_ch = 1 if p8_s1==5
replace sinbano_ch = . if p8_s1==.

*****************
*banomejorado_ch* 
*****************
gen byte banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
replace banomejorado_ch=. if bano_ch==.

	********************
	***** Migración ****
	********************
 		
*******************
*** migrante_ci ***
*******************
gen byte migrante_ci= 0
replace migrante_ci=1 if p41_s3!=1 & (p41_s3 !=. | p41_s3 !=16)
replace migrante_ci=. if p41_s3==. | p41_s3 == 16 
	
**********************
*** migrantiguo5_ci ***
**********************
* p48_s3 En los últimos 5 años ¿migró a otro país y luego regresó? 1 Sí 2 No
gen byte migrantiguo5_ci=.
/*	replace migrantiguo5_ci=1 if migrante_ci==1 & p48_s3 ==2
	replace migrantiguo5_ci=0 if migrante_ci==1 & p48_s3 ==1*/

**********************
***   miglac_ci    ***
**********************
* Decisión:  5 respuestas de  otro país se colocan no latinos
* no está la variable p42_s3 en la base dta: Especificación de otro país de nacimiento (campo abierto).
gen byte miglac_ci  =.
/*
replace  miglac_ci = 1 if (migrante_ci==1 & (p41_s3 >1 & p41_s3<9))
replace  miglac_ci = 0 if (migrante_ci==1 & (p41_s3 >=9 & p41_s3!=.))
 tab p41_s3
2024 
   ¿En qué país |
         nació? |      Freq.     Percent        Cum.
----------------+-----------------------------------
      Venezuela |        354       96.99       96.99
       Colombia |          9        2.47       99.45
       Portugal |          1        0.27       99.73
          Siria |          1        0.27      100.00
----------------+-----------------------------------
          Total |        365      100.00
2023
   ¿En qué país |
         nació? |      Freq.     Percent        Cum.
----------------+-----------------------------------
      Venezuela |      1,958       97.90       97.90
       Colombia |         37        1.85       99.75
        Ecuador |          1        0.05       99.80
           Perú |          2        0.10       99.90
      Otro país |          2        0.10      100.00
----------------+-----------------------------------
          Total |      2,000      100.00
*/

	****************************
	***** Protección social ****
	****************************

**************************
***  nmiembros_sph_ch  ***
**************************
gen x = 1
bys idh_ch: egen nmiembros_sph_ch= sum(x)	
	
*****************
**** y_hog_ci ***
*****************
egen y_hog_ci  = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi	

*****************
**** y_hog_ci ***
*****************
bys idh_ch: egen y_hog_ch = sum(y_hog_ci)

********************
*** y_pc_net_ch  ***
********************
gen  y_pc_net_ch = ytot_ci - ing_bonos_bol
replace  y_pc_net_ch = ytot_ci if ing_bonos_bol==.

********************
*** ptmc_ci      ***
********************
gen byte  ptmc_ci  =.
replace  ptmc_ci  = 1 if p196_s10 ==1
replace  ptmc_ci  = 0 if p196_s10 ==2

********************
***   ptmc_ch    ***
********************
bys idh_ch: egen ptmc_ch = max(ptmc_ci)

********************
***  ing_ptmc_ci ***
********************
gen ing_ptmc_ci = ing_bonos_bol

********************
***  ing_ptmc_ch ***
********************
bys idh_ch: egen ing_ptmc_ch = sum(ing_ptmc_ci)

************************
*** pnc_elegible_ci  ***
************************
gen     pnc_elegible_ci = 0
replace pnc_elegible_ci = 1 if edad_ci > 54 & sexo_ci == 2
replace pnc_elegible_ci = 1 if edad_ci > 59 & sexo_ci == 1
* ver tema de missing

**************
*** pnc_ci ***
**************
*  Gran Misión Hogares de la Patria
gen byte  pnc_ci = .
replace pnc_ci = 1 if p197_1_s10 ==1
replace pnc_ci = 0 if p197_1_s10 ==0

**************
*** pnc_ch ***
**************
bys idh_ch: egen pnc_ch = max(pnc_ci)

*******************
*** ing_pnc_ci  ***
*******************
gen  ing_pnc_ci = .

*******************
*** ing_pnc_ch  ***
*******************
gen ing_pnc_ch =.

*******************
*** potrot_ci   ***
*******************
gen potrot_ci =.
/* 
* los que se benefician de bolsas cajas CLAP y no reciben benficios de eso por estar en patria roja
no se están contando
replace potrot_ci= 1 if p200_s10 ==1 
replace potrot_ci= 0 if p200_s10 ==2
tab p200_s10 p196_s10, mi
    En los |
 últimos 6 |
    meses, |
       ¿ha |   Sobre los programas sociales
 adquirido |     promovidos por el estado
Bolsas-Caj |    venezolano, ¿usted ha reci
  as CLAP? |        Sí         No          . |     Total
-----------+---------------------------------+----------
        Sí |     1,570      1,175          0 |     2,745 
        No |       399      1,931          0 |     2,330 
         . |         0          0      1,438 |     1,438 
-----------+---------------------------------+----------
     Total |     1,969      3,106      1,438 |     6,513 */
	
*******************
*** potrot_ch  ***
*******************
bys idh_ch: egen potrot_ch = max(potrot_ci)

*******************
*** ing_otrot_ci***
*******************
gen ing_otrot_ci = .

*******************
*** ing_otrot_ch***
*******************
bys idh_ch: egen ing_otrot_ch = sum(ing_otrot_ci)

*****************
*** pcasht_ch ***
*****************
bys idh_ch: gen pcasht_ch = (ptmc_ch==1|pnc_ch==1| potrot_ch==1)

	*************************
	***** Fuente externa ****
	*************************

*************
**salmm_ci***
*************
gen salmm_ci=130

*************
** lp_ci  ***
*************
gen byte lp_ci = .

*************
** lpe_ci ***
*************
gen byte lpe_ci = .


*https://datosmacro.expansion.com/smi/venezuela
*https://www.moore-venezuela.com/noticias/marzo-2022/aumenta-el-salario-minimo-mensual-a-130,00-desde-e
* En Gaceta Oficial Nº 6.691 Extraordinario de fecha 15/03/2022	
/*_______________________
______________________________________________________________________________*/
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
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad 
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci ytot_ci /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración
	  nmiembros_sph_ch  y_hog_ci y_hog_ch y_pc_net_ch ptmc_ci ptmc_ch ing_ptmc_ci /// Protección social
	  ing_ptmc_ch pnc_elegible_ci  pnc_ci pnc_ch ing_pnc_ci ing_pnc_ch potrot_ci  /// Protección social 
	  potrot_ch ing_otrot_ci  ing_otrot_ch pcasht_ch  /// Protección social
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa


save "`base_out'", replace

log close



