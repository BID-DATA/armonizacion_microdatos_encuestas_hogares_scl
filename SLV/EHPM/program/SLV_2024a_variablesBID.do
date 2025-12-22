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

local PAIS SLV
local ENCUESTA EHPM
local ANO "2024"
local ronda a

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: El Salvador
Encuesta: EHPM
Round: a
Autores: Matias Rodriguez (SCL/SCL) - Email: mrodriguezm@iadb.org, 22 de diciembre de 2025
Versión: 1 
Matias Rodriguez (SCL/SCL) - Email: mrodriguezm@iadb.org, 22 de diciembre de 2025


****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/
use "`base_in'", clear

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
	*NOTA: En 2024 no hay región, el ultimo año con esta variable fue 2023
/*
	gen byte region_c = r004
	label define region_c   ///
	1 "Ahuachapán" ///
    2 "Santa Ana" ///
    3 "Sonsonate" ///
    4 "Chalatenango" ///
    5 "La Libertad" ///
    6 "San Salvador" ///
    7 "Cuscatlán" ///
    8 "La Paz" ///
    9 "Cabañas" ///
    10 "San Vicente" ///
    11 "Usulután" ///
    12 "San Miguel" ///
    13 "Morazán" ///
    14 "La Unión" 		
	label value region_c region_c
*/	    
	*************
	* pais_c    *
	*************
	gen str3 pais_c="SLV"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=r015

	******
	*zona*
	******
	*NOTA: En 2024 no hay zona (solo znorte), el ultimo año con esta variable fue 2023
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	*NOTA: En 2024 no hay estratoarea, el ultimo año con esta variable fue 2023
	*Revisar lote tipo folio viv 
	
	***************
	***upm_ci***
	***************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	gen idh_ch = idboleta
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	egen idp_ci = concat(idh_ch r101)
	tostring idp_ci, replace format ("%20.0f") 

	***********
	*factor_ci* 
	***********
	gen factor_ci=fac00
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=fac00 /*todos los factores 00-04 son los mismos*/


****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=.
	replace sexo_ci = 1 if r104==1
	replace sexo_ci = 2 if r104==2

	*********
	*edad_ci*
	*********
	gen int edad_ci=.
	replace edad_ci=r106 if r106>=0

	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if r103==1
	replace relacion_ci = 2 if r103==2
	replace relacion_ci = 3 if r103==3
	replace relacion_ci = 4 if r103>=4 & r103<=9
	replace relacion_ci = 5 if r103==11
	replace relacion_ci = 6 if r103==10

	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)

	*************
	*miembros_one_ci*
	*************
	*gen miembros_one_ci=.
	*No hay metodología de la encuesta y en los anteriores años no se lo hizo 
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci=1 if r107==6
	replace civil_ci=2 if r107==1 | r107==2 
	replace civil_ci=3 if r107==4 | r107==5
	replace civil_ci=4 if r107==3

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
	*notronopari_ch*
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

	*********
	*afro_ci*
	*********
	gen byte afro_ci = .
	
	*********
	*indi_ci*
	*********	
	gen byte ind_ci =.

	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.  
	
	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	
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
	gen byte SLV_dis_ci = .
	

*******************************************************
***          VARIABLES DE MERCADO LABORAL           ***
*******************************************************

	***************
	**condocup_ci**
	***************
	gen byte condocup_ci=.
	replace condocup_ci = 1 if inlist(1, r403, r4041, r4041_1, r4042, ///
		r4043, r4044, r4045, r4046, r4047, r4048, r4049, r405, r405b)| r406<5
	replace condocup_ci=2 if condocup_ci!=1 & r407==1
	replace condocup_ci=3 if (condocup_ci!=1 & condocup_ci!=2) & edad_ci>=15
	replace condocup_ci=4 if edad_ci<15
	*r403 Realizó algún trabajo la semana anterior para generar ingresos
	*r404 LA SEMANA ANTERIOR (…), REALIZÓ ALGUNA ACTIVIDAD PARA OBTENER INGRESOS EN DINERO
	*r405 Tiene algún empleo fijo al que próximamente volverá
	*r405b Tiene algún negocio, empresa o actividad propia a la que próximamente volverá
	*r406 Razón por la que no trabajó la semana anterior
	*r407 Buscó trabajo o trató de establecer su propia empresa o negocio
	
	*******************
	***categoinac_ci***
	*******************
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (r409==13 & condocup_ci == 3)
	replace categoinac_ci = 2 if  (r409==8 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (r409==12 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci != 1 | categoinac_ci != 2 | categoinac_ci != 3) & condocup_ci == 3)

	************
	***emp_ci***
	************
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	gen byte cesante_ci = .
	replace cesante_ci = 1 if (r410== 1 & condocup_ci == 2) 
	replace cesante_ci = 0 if (cesante_ci != 1 & condocup_ci ==2)

	****************
	***desemp_ci***
	****************
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	*****************
	***horaspri_ci***
	*****************
	egen byte horaspri_ci= rsum(r411a r411d) if emp_ci==1
	replace horaspri_ci = . if emp_ci == 0

	***************
	***subemp_ci***
	***************
	gen byte subemp_ci = 0
	replace subemp_ci=1 if horaspri_ci<=30  & emp_ci==1 & (r413==2 | r413==3)

	****************
	***durades_ci***
	****************
	gen byte durades_ci = floor(r407a_s/(52/12)) //redondeamos por consitencia y lo dividimos aunque en el manual lo multiplica

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)

	*****************
	***nempleos_ci***
	*****************
	gen byte nempleos_ci = .
	replace nempleos_ci=1 if emp_ci==1 & r432==2
	replace nempleos_ci=2 if emp_ci==1 & r432==1
	replace nempleos_ci=. if emp_ci==0

	*******************
	***antiguedad_ci***
	*******************
	gen byte antiguedad_ci=.

	*****************
	***desalent_ci***
	*****************
	gen byte desalent_ci=(r409==3)
	replace desalent_ci=. if r409==.

	*****************
	***horastot_ci***
	*****************
	egen byte horastot_ci=rsum(horaspri_ci r433) if emp_ci==1 
	replace horastot_ci = . if horaspri_ci == . & r433 == .
	replace horastot_ci = . if emp_ci == 0

	*******************
	***tiempoparc_ci***
	*******************
	gen byte tiempoparc_ci= ((horaspri_ci >= 1 & horaspri_ci < 30) & r413==1 & emp_ci == 1) 
	replace tiempoparc_ci = . if emp_ci == 0

	******************
	***categopri_ci***
	******************
	gen byte categopri_ci=.
	replace categopri_ci=0 if r418==8 & emp_ci==1
	replace categopri_ci=1 if r418==1 & emp_ci==1
	replace categopri_ci=2 if r418==2 | r418==3 & emp_ci==1
	replace categopri_ci=3 if r418==6 | r418==7 | r418==9 & emp_ci==1
	replace categopri_ci=4 if r418==5  & emp_ci==1

	******************
	***categosec_ci***
	******************
	gen byte categosec_ci=.

	*************
	***rama_ci***
	*************
	gen byte rama_ci=. 
	replace rama_ci=1 if (r416>=100 & r416<=322) & emp_ci==1 
	replace rama_ci=2 if (r416>=510 & r416<=990) & emp_ci==1 
	replace rama_ci=3 if (r416>=1010 & r416<=3320) & emp_ci==1 
	replace rama_ci=4 if (r416>=3510 & r416<=3900) & emp_ci==1 
	replace rama_ci=5 if (r416>=4100 & r416<=4390) & emp_ci==1 
	replace rama_ci=6 if ((r416>=4510 & r416<=4799) | (r416>=5510 & r416<=5630))& emp_ci==1 
	replace rama_ci=7 if ((r416>=4911 & r416<=5320) | (r416>=6110 & r416<=6190)) & emp_ci==1 
	replace rama_ci=8 if (r416>=6411 & r416<=8299) & emp_ci==1 
	replace rama_ci=9 if ((r416>=5811 & r416<=6022) | (r416>=6201 & r416<=6399) | (r416>=8411 & r416<=9900)) & emp_ci==1 

	*****************
	***spublico_ci***
	*****************
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & rama_ci == 10
	replace spublico_ci = 0 if emp_ci == 1 & rama_ci != 10 & rama_ci != .

	***************
	***tamemp_ci***
	***************
	gen tamemp_ci = .
	replace tamemp_ci = 1 if r421>=1 & r421<=5 | r421a==1
	replace tamemp_ci = 2 if r421>=6 & r421<=50 | inlist(r421a,2,3)
	replace tamemp_ci = 3 if r421>50 | r421a>3
	replace tamemp_ci = . if condocup_ci!=1
	
	****************
	**cotizando_ci**
	****************
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if inlist(categopri_ci,2,3) & r422a==2
	replace cotizando_ci = 0 if condocup_ci<=2 & r422a!=2 

	******************
	*** instcot_ci ***
	******************
	gen byte instcot_ci=.
	replace instcot_ci= 1 if cotizando_ci == 1 & r501<=3
	replace instcot_ci= 2 if cotizando_ci == 1 & r501==4
	replace instcot_ci= 3 if cotizando_ci == 1 & r501==5
	replace instcot_ci= 4 if cotizando_ci == 1 & r501==6
	replace instcot_ci= 5 if cotizando_ci == 1 & r501==7
	replace instcot_ci= 6 if cotizando_ci == 1 & r501==9
	label define instcot_ci  1 "ISSS" 2 "Bienestar Magisterial" 3 "Hospital Militar" 4 "Colectivo" 5 "Individual (Privado)" 6 "Otros"
	label value instcot_ci instcot_ci

	*****************
	***afiliado_ci***
	*****************
	gen byte afiliado_ci = .
	replace afiliado_ci= 1 if (r501>=1 & r501<=2) /*todas personas ISSS retirado(a) ? Bienestar Magisterial ? */
	replace afiliado_ci= 0 if r501>2

	*************
	**formal_ci**
	*************
	gen byte formal_ci = .
	replace formal_ci  =  1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)

	*******************
	**tipocontrato_ci**
	*******************
	gen byte tipocontrato_ci = .
	replace tipocontrato_ci = 1 if r419==1 & categopri_ci == 3
	replace tipocontrato_ci = 2 if inlist(r419,2,3,4,5) & categopri_ci == 3
	replace tipocontrato_ci = 3 if r419==6 & categopri_ci == 3
	replace tipocontrato_ci = 0 if r419<7 & categopri_ci == 3 & tipocontrato_ci!=1 & tipocontrato_ci!=2 & tipocontrato_ci!=3

	**************
	***ocupa_ci***
	**************
	gen ocupa_ci=.
	replace ocupa_ci=1 if (r414>=2111 & r414<=3522) & emp_ci==1
	replace ocupa_ci=2 if (r414>=1110 & r414<=1439) & emp_ci==1
	replace ocupa_ci=3 if (r414>=4110 & r414<=4419) & emp_ci==1
	replace ocupa_ci=4 if (r414>=9510 & r414<=9520)& emp_ci==1 | (r414>=5210 & r414<=5249)  & emp_ci==1
	replace ocupa_ci=5 if (r414>=5111 & r414<=5169) & emp_ci==1 | (r414>=9111 & r414<=9129) & emp_ci==1 | (r414>=5311 & r414<=5419) & emp_ci==1 | (r414>=9610 & r414<=9629) & emp_ci==1
	replace ocupa_ci=6 if (r414>=6110 & r414<=6340) & emp_ci==1| (r414>=9210 & r414<=9220) & emp_ci==1
	replace ocupa_ci=7 if (r414>=7111 & r414<=8350) & emp_ci==1| (r414>=9311 & r414<=9412) & emp_ci==1 
	replace ocupa_ci=8 if r414>=110 & r414<=310 & emp_ci==1
	replace ocupa_ci=9 if !inlist(ocupa_ci, 1, 2, 3, 4, 5, 6, 7, 8) & emp_ci==1

	**************
	**pension_ci***
	**************
	gen byte pension_ci=. 
	replace pension_ci=1 if (ingreso_pensiones>0 & ingreso_pensiones !=.) & cotizando_ci == 1
	replace pension_ci=0 if pension_ci!=1

	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
	replace pensionsub_ci=1 if r319a5==1 // pension universal
	replace pensionsub_ci=0 if pensionsub_ci!=1 
	*consideramos incluir  r44008a --  Monto que recibe pensión por sobrevivencia  y r319a4 / r319a3 Recibe el hogar bonos comunidades solidarias urbanas/ rurales

	**************
	**tipopen_ci***
	**************
	gen byte tipopen_ci = . 

	**************
	**instpen_ci***
	**************
	gen byte instpen_ci = . 


************************************************
***          VARIABLES DE INGRESO           ***
************************************************

		************************
		* INGRESO DEL INDIVIDUO*
		************************
*fre imeds imei imes imnl  ingneto  irefa oia oimed 	

***************
***ylmpri_ci***
***************
*Para asalariados
	gen yprid=imeds
	gen hrsextrasd=		r42501a*r42501b/12 
	gen vacacionesd=	r42502a*r42502b/12 
	gen aguinaldod=		r42503a*r42503b/12 
	gen bonificacionesd=r42504a*r42504b/12 
	gen propina=r42511a*r42511b/12 
	egen yprijbd=rsum(yprid hrsextrasd vacacionesd aguinaldod bonificacionesd propina), missing
	drop yprid-propina
	*Para trabajadores independientes
	gen yprijbi= imei
	egen ylmpri_ci=rsum(yprijbi yprijbd), missing
	drop yprijbi yprijbd
	replace ylmpri_ci = 0 if  inlist(condocup_ci,2,3) | categopri_ci==4 //PET con condición de inactivo/desocupado o categoría ocupacional no remunerado debe registrar ylmsec_ci = 0

	***************
	***ylmsec_ci***
	***************
	gen hrsextrasd1     =r43501a*r43501b/12 
	gen vacacionesd1    =r43502a*r43502b/12 
	gen aguinaldod1     =r43503a*r43503b/12 
	gen bonificacionesd1=r43504a*r43504b/12 
	gen propina1        =r43511a*r43511b/12 
	egen yprijbd1 =rsum(hrsextrasd1 vacacionesd1 aguinaldod1 bonificacionesd1 propina1), missing
	egen ylmsec_ci=rsum(r434 yprijbd1), missing //imes
	replace ylmsec_ci=. if emp_ci!=1
	drop  hrsextrasd1-yprijbd1
	replace ylmsec_ci = 0 if  inlist(condocup_ci,2,3) | categopri_ci==4 //PET con condición de inactivo/desocupado o categoría ocupacional no remunerado debe registrar ylmsec_ci = 0

	*****************
	***ylmotros_ci***
	*****************
	gen ylmotros_ci=.

	************
	***ylm_ci***
	************
	egen ylm_ci= rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	replace ylm_ci=. if ylmpri_ci==. &  ylmsec_ci==. & ylmotros_ci==. 

	****************
	***ylnmpri_ci***
	****************
	g food1=r42505a*r42505b/12 
	g ropa1=r42506a*r42506b/12 
	g merca1=r42507a*r42507b/12 
	g vivi1=r42508a*r42508b/12 
	g trans1=r42509a*r42509b/12 
	g segur1=r42510a*r42510b/12 
	g otross1=r42512a*r42512b/12 

	egen ylnmpri_ci=rsum(food1 ropa1 merca1 vivi1 trans1 segur1 otross1), missing
	replace ylnmpri_ci=. if emp_ci!=1
	drop food1-otross1

	****************
	***ylnmsec_ci***
	****************
	g food2=r43505a*r43505b/12 
	g ropa2=r43506a*r43506b/12 
	g merca2=r43507a*r43507b/12 
	g vivi2=r43508a*r43508b/12 
	g trans2=r43509a*r43509b/12 
	g segur2=r43510a*r43510b/12 
	g otross2=r43512a*r43512b/12 

	egen ylnmsec_ci=rsum(food2 ropa2 merca2 vivi2 trans2 segur2 otross2), missing
	replace ylnmsec_ci=. if emp_ci!=1 
	drop food2-otross2

	******************
	***ylnmotros_ci***
	******************
	gen ylnmotros_ci=.

	*************
	***ylnm_ci***
	*************
	egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	replace ylnm_ci=. if ylnmpri_ci==. &  ylnmsec_ci==. & ylnmotros_ci==.

	*************
	***ynlm_ci***
	*************
	gen remesas =r44001a*r44001b/12

	gen cuotalim=r44002a*r44002b/12
	gen alqui   =r44003a*r44003b/12
	gen alqneg  =r44004a*r44004b/12
	gen alqterr =r44005a*r44005b/12
	gen jubil   =ingreso_pensiones
	gen deveh   =r44007a*r44007b/12
	gen pension =r44008a*r44008b/12
	gen ahorros =r44009a*r44009b/12
	gen otros   =r44010a*r44010b/12

	gen utilidades   =r44101/12
	gen dividendos   =r44102/12
	gen intereses    =r44103/12
	gen herencias    =r44104/12
	gen indemnizacion=r44105/12
	gen ayudagob     =r44106/12
	gen acteventual  =r44107/12
	gen arrendamiento=r44108/12
	gen remesaevent1 =r44109/12
	gen aguinaldo    =r44110/12
	gen otrosy       =r44111/12

	egen ynlm_ci=rsum(remesas-otrosy), missing
	egen miss=rowmiss(remesas-otrosy)
	*replace ynlm_ci=. if miss==23
	drop ayuda-otrosy miss 

	*************
	***ynlnm_ci***
	*************
	gen ynlnm_ci=.

	**************
	*** ytot_ci **
	**************
	egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)

		************************
		*** INGRESO DEL HOGAR***
		************************

	**************
	*** ylm_ch ***
	**************
	by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1

	***************
	*** ylnm_ch ***
	***************
	by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1

	**************
	***ynlnm_ch***
	**************
	gen ynlnm_ch=.

	***************
	*** ynlm_ch ***
	***************
	by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1

	**************
	*** ytot_ch**
	**************
	egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi
	
	*****************
	***ylhopri_ci ***
	*****************
	gen byte ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0

	***************
	***ylmho_ci ***
	***************
	gen byte ylmho_ci = ylm_ci / (4.3 * horastot_ci)
	replace ylmho_ci = . if ylmho_ci <= 0
		
	******************
	****nrylmpri_ci***
	******************
	gen byte nrylmpri_ci = .
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci ==1

	*******************
	*** nrylmpri_ch ***
	*******************
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .
	
	****************
	*** ylmnr_ch ***
	****************
	by idh_ch, sort: egen byte ylmnr_ch = sum(ylm_ci) if miembros_ci == 1
	replace ylmnr_ch = . if nrylmpri_ch == 1

	****************
	***remesas_ci***
	****************
	gen byte remesas_ci=irefa

	****************
	***remesas_ch***
	****************
	by idh_ch, sort: egen remesas_ch=sum(remesas_ci) if miembros_ci==1

	*************
	***ypen_ci***
	*************
	gen ypen_ci=ingreso_pensiones if pension_ci==1

	****************
	***ypensub_ci***
	****************
	gen ypensub_ci = r319a5==1 if pensionsub_ci == 1

****************************
***VARIABLES DE EDUCACION***
****************************
 
    *********  
    *aedu_ci*
    *********
    gen aedu_ci=aproba1
 
    **********
    *eduui_ci*
    **********
    gen eduui_ci = (inlist(r204, 4, 5)) | (inlist(r214, 4, 5) & inlist(r217, 1, 2, 3))
    replace eduui_ci=. if aedu_ci==.
 
    **********
    *eduuc_ci*
    **********
    gen eduuc_ci = inlist(r214, 4, 5) & (inrange(r217, 4, 9))
    replace eduuc_ci=. if aedu_ci==.
 
    **********
    *eduac_ci*
    **********
    gen eduac_ci=.
    replace eduac_ci=1 if r214==4
    replace eduac_ci=0 if r214==5
    ***********
    *edupre_ci*
    ***********
    gen byte edupre_ci =.
    replace edupre_ci = 1 if r209==1
    replace edupre_ci = 0 if r209==0
 
    ************
    *asispre_ci*
    ************
    gen asispre_ci=(r203==1 & r204==1) // no consideramos menores de 3 años (r201a)
 
    ***********
    *asiste_ci*
    ***********
    gen asiste_ci=(r203==1)
    replace asiste_ci=. if r203==.

	*************
	*razonesnoasis_ci*
	**************
	gen razonesnoasis_ci=. 
	replace razonesnoasis_ci=1 if r219==3
	replace razonesnoasis_ci=2 if r219==1
	replace razonesnoasis_ci=3 if r219==4  | r219==5  | r219==6
	replace razonesnoasis_ci=4 if r219==10
	replace razonesnoasis_ci=5 if r219==2  | r219==12 | r219==15 | r219==16
	replace razonesnoasis_ci=6 if r219==8
	replace razonesnoasis_ci=7 if r219==7 
	replace razonesnoasis_ci=8 if r219==9  | r219==13 | r219==14 | r219==18
	replace razonesnoasis_ci=9 if r219==11 | r219==17 

	***********
	*edupub_ci*
	***********		
	gen edupub_ci=.
	replace edupub_ci=1 if r210a==1 & r203==1
	replace edupub_ci=0 if (r210a==2 | r210a==3) & r203==1


****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	replace luz_ch=0 if r311==3 | r311==4 | r311==7
	replace luz_ch=1 if r311==1 | r311==2 | r311==5 | r311==6
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.
	replace combust_ch=0 if r320==4 | r320==5 | r320==6
	replace combust_ch=1 if r320==1 | r320==2 | r320==3 
	
	***********
	*piso_ch*
	***********
	gen piso_ch=.
	replace piso_ch=0 	if r304==5
	replace piso_ch=1 	if r304>=1 & r304<=4
	replace piso_ch=2 	if r304==6
		
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	replace pared_ch=0 	if r303==2 | r303==3 |r303==5 |r303==6 |r303==7 
	replace pared_ch=1 	if r303==1 | r303==4
	replace pared_ch=2 	if r303==8
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	replace techo_ch=1 	if r302>=1 & r302<=4
	replace techo_ch=0 	if r302>=5 & r302<=6 
	replace techo_ch=2 	if r302==7
		
	***********
	*resid_ch*
	***********
	gen resid_ch=.
	replace resid_ch=0 if r322==1 | r322==2
	replace resid_ch=1 if r322==4 | r322==5
	replace resid_ch=2 if r322==6
	replace resid_ch=3 if r322==3 | r322==7

	***********
	*dorm_ch*
	***********
	gen dorm_ch=r306
	replace dorm_ch=. if r306==.

	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=r305
	replace cuartos_ch=. if r305==.
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
	
	***********
	*telef_ch*
	***********
	gen telef_ch=.
	replace telef_ch=0 if r3211a==2	
	replace telef_ch=1 if r3211a==1
		
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	replace refrig_ch=0 if r32305a==2
	replace refrig_ch=1 if r32305a==1
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	
	***********
	*auto_ch*
	***********
	gen auto_ch=.
	replace auto_ch=0 if r32312a==2
	replace auto_ch=1 if r32312a==1
	
	***********
	*compu_ch*
	***********
	gen compu_ch=.
	replace compu_ch=0 if r32309a==2
	replace compu_ch=1 if r32309a==1
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	replace internet_ch=0 if r3213a==2
	replace internet_ch=1 if r3213a==1
	
	***********
	*vivi1_ch*
	gen vivi1_ch=.
	replace vivi1_ch=1 if r301==1 
	replace vivi1_ch=2 if r301==2
	replace vivi1_ch=3 if r301>=3 & r301<=9

	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch=0 	if r308==1
	replace viviprop_ch=1 	if r308==3
	replace viviprop_ch=2 	if r308==2 
	replace viviprop_ch=3 	if r308 >=4 & r308<9
	replace viviprop_ch=. 	if r308==.

	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.

	***********
	*vivialq_ch*
	***********
	gen vivialq_ch= r308c  

	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=r310a 

****************************
***VARIABLES DE WASH***
****************************
*fre r312d r312h r313 R313otr r314 r312 r315 r316 r317a r317b r317c r317otr r318 r318otr
	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.
	replace aguared_ch = 0 if r312> 4
	replace aguared_ch = 1 if r312==1 | r312==2| r312==3| r312==4
	
	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = 0

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if inlist(r312,1,2,3,4)
	replace aguafuente_ch = 2 if r313==2
	replace aguafuente_ch = 4 if inlist(r313,5, 5.1)
	replace aguafuente_ch = 5 if r313==10
	replace aguafuente_ch = 6 if r313==3
	replace aguafuente_ch = 7 if r312==4.1 |inlist(r313,1,11)
	replace aguafuente_ch = 8 if r313==7
	replace aguafuente_ch = 9 if inlist(r313,6,6.1)
	replace aguafuente_ch = 10 if inlist(r313,4,4.1,8,9,12,13)

	******************
	** aguadist_ch ** 
	*****************
	gen byte aguadist_ch  = .
	replace aguadist_ch = 1 if inlist(r312,1,2) | inlist(r313,1,2,3,4,5,6)
	replace aguadist_ch= 2 if (r312==3| r312==4|r312 == 4.1)
	replace aguadist_ch=3 if r313==2 | r313==4.1| r313==5.1 | r313==6.1 | r313==12 | r313==11
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.

	******************
	** aguadisp1_ch ** 
	*****************
	gen aguadisp1_ch =9

	******************
	** aguadisp2_ch **
	*****************
	gen byte aguadisp2_ch =.
	replace aguadisp2_ch = 1 if r312d<=3 | r312h<=11 
	replace aguadisp2_ch = 2 if r312d>=4 & r312h>=12
	replace aguadisp2_ch = 3 if r312d==7 & r312h ==24

	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	
	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.

	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7

	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .

	******************
	** bano_ch **
	*****************
	gen byte bano_ch = .
	replace bano_ch=1 if (r316==1 | r316==3)
	replace bano_ch=2 if (r316==2 | r316==4)
	replace bano_ch=3 if (r316==7 | r316==8 | r316==9 | r316==10)
	replace bano_ch=4 if (r314==1 |r314==2) & (r317a==3 |r317a==4) 
	replace bano_ch=6 if (r316==5 | r316==6)
	replace bano_ch=0 if r314==4 |r314==3
		
	******************
	** banoex_ch ** - 
	*****************
	generate banoex_ch=9

	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if inlist(r314,1,2,3)
	replace sinbano_ch = 1 if r314==4 & r315==1
	replace sinbano_ch = 2 if r314==4 & r315==2 & (r317a==3|r317a==4) 
	replace sinbano_ch = 3 if r314==4 & r315==2 & (r317a==5|r317a==.)

	******************
    ** banomejorado_ch **
    *****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
****************************
***VARIABLES DE MIGRACIÓN***
****************************		

	*****************
    *migrante_ci****
    ****************
	gen byte migrante_ci=.
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.

	****************
	 *miglac_ci*
	****************	
	gen byte miglac_ci=.
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar*
	****************
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 
	replace tipo_bienestar  = 2

	****************
	 * pobre_ine_ci*
	****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if pobreza==3
	replace pobre_ine_ci= 1 if pobreza==1 |pobreza==2

	****************
	* bienestar_agregado*
	****************	
	gen bienestar_agregado = . 

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	replace lpe_ci= li
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	replace ln_ci= li*2


compress
save "`base_out'", replace
cap log close
