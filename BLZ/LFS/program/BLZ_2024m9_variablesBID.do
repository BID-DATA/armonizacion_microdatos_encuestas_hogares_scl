*(Versión stata 19)

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

local PAIS BLZ
local ENCUESTA LFS
local ANO "2024"
local ronda m9

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Belize
Encuesta: LFS
Round: April
Autores: 
Modificación 2026: Manuel Marcos
Última modificación: Abril 2026
Versión:
Nombre de autor (SCL/SCL) - Email: ..., Fecha:...
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
	replace region_BID_c = 1

	********************
	*** region_c ****
	********************
	gen byte region_c = district
	label define region_c   ///
	1 "Corozal" 			///
	2 "Orange Walk"	 		///
	3 "Belize"				///
	4 "Cayo"				///
	5 "Stann Creek"			///
	6 "Toledo"
	label value region_c region_c
	
	*************
	* pais_c    *
	*************
	gen str3 pais_c = "BLZ"

	******
	*anio*
	******
	gen anio_c = 2024
	
	******
	*mes_c*
	******
	gen int mes_c = 4	

	******
	*zona*
	******
	*NOTA: sigue siendo Urbana: 29 aglomerados
	gen zona_c= (urban_rural == 1)
	replace zona_c = . if missing(urban_rural)
	
	*********
	*estrato*
	*********
	gen estrato_ci=.
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=.
	
	******************
	*idh_ch (idhogar)*
	******************
	egen idh_ch=group(_v1)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	*egen idp_ci = concat(...)

	sort interview__key _v1
	by interview__key: gen _seq = _n
	egen idp_ci = concat(idh_ch _seq)
	tostring idp_ci, replace format ("%20.0f") 
	drop _seq
	
	***********
	*factor_ci* 
	***********
	gen factor_ci = final_weight
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch = final_weight
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	* hl5: 1=Male, 2=Female, 3=DK/NS
	* DK/NS (3) se deja como missing
	gen byte sexo_ci = .
	replace sexo_ci = 1 if hl5 == 1
	replace sexo_ci = 2 if hl5 == 2

	*********
	*edad_ci*
	*********
	gen edad_ci = hl3 
	* gen int edad_ci=.
	* replace edad_ci=. if ...
	
	**************
	**relacion_ci**
	**************
	* hl4new: 1=Head, 2=Spouse/Partner, 3=Child, 4=Grandchild, 5=Other, 9=DK/NS
	* DK/NS (9) se deja como missing
	gen byte relacion_ci = .
	replace relacion_ci = 1 if hl4new == 1
	replace relacion_ci = 2 if hl4new == 2
	replace relacion_ci = 3 if hl4new == 3
	replace relacion_ci = 4 if hl4new == 4
	replace relacion_ci = 5 if hl4new == 5
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=.
	
	**************
	*Estado Civil*
	**************
	* Para 2024 sí hay la pregunta y una adicional de estado civil actualizado
	* hl8new: 1=Never Married, 2=Married, 3=Divorced, 4=Widowed, 5=Legally Separated, 9=DK/NS
	* hl9: 1=Married living w/spouse, 2=Married not living, 3=Common-law 5+yr,
	*      4=Living together <5yr, 5=Visiting partner, 7=Not in union
	
	gen byte civil_ci = .
	replace civil_ci = 1 if hl8new == 1
	replace civil_ci = 2 if hl8new == 2
	replace civil_ci = 2 if inlist(hl9, 3, 4, 5)
	replace civil_ci = 3 if hl8new == 3 | hl8new == 5
	replace civil_ci = 4 if hl8new == 4

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
         		
	************
	*nempdom_ch* * ME PARECE QUE ESTO NO APLICA
	************
	*NOTA: a traves de la relacion de parentesco no es posible identificar a los empleados domesticos
	*Se pregunta aparte si el individuo presta servicios domesticos. No obstante, no se sabe si pertenecen
	*al hogar encuestado directamente, por ello se aproxima a esta medida usando la relacion de parentesco
*	gen empldom_ci=0
*	replace empldom_ci=1 if pp04b1==1
		
*	by idh_ch, sort: egen nempdom_ch=sum(empldom_ci==1) if relacion_ci==5	  
		
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
	* hl6new: 1=Creole, 2=Garifuna, 3=Maya, 4=Mestizo/Hispanic, 5=Other, 9=DK/NS
	* Creole (1) y Garifuna (2) se consideran afrodescendientes en Belize
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta
	replace afro_ci = 1 if inlist(hl6new, 1, 2)
	replace afro_ci = 0 if inlist(hl6new, 3, 4, 5)
	
	*********
	*indi_ci*
	*********	
	* Maya (3) se considera indígena en Belize
	gen byte ind_ci =. 		  // se queda como missing (.) si no existe la pregunta
	replace ind_ci = 1 if hl6new == 3
	replace ind_ci = 0 if inlist(hl6new, 1, 2, 4, 5)
	
	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) si no existe la pregunta
	replace noafroind_ci = 1 if afro_ci == 0 & ind_ci == 0
	replace noafroind_ci = 0 if afro_ci == 1 | ind_ci == 1	
	
	**************
	*afroind_ano_c*
	**************
	gen byte afroind_ano_c =.   // se queda como missing (.) si no existe la pregunta	

	************
	*afroind_ci*
	************
	gen byte afroind_ci=. 
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1
	
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
	gen byte blz_dis_ci = .
	
****************************
***VARIABLES DE MERCADO LABORAL***
****************************

	*************
	*condocup_ci*
	*************
	* status: 1=Under 14, 2=Employed, 3=Unemployed, 4=PNLF, 5=DK/NS
	
	gen byte condocup_ci = .
	replace condocup_ci = 1 if status == 2 /* ocupado */
	replace condocup_ci = 2 if status == 3 /* desocupado */
	replace condocup_ci = 3 if status == 4 /* inactivo */
	replace condocup_ci = 4 if status == 1
	* DK/NS: clasificamos según edad
	replace condocup_ci = 3 if status == 5 & edad_ci >= 14
	replace condocup_ci = 4 if status == 5 & edad_ci < 14

	*******************
	***categoinac_ci***
	*******************
	* ea12: razón de inactividad
	* 7=Retired/Pensioner, 2=In school, 1=Personal/family, otros=4

	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (ea12 == 7 & condocup_ci == 3) /* Jubilados, pensionados */
	replace categoinac_ci = 2 if (ea12 == 2 & condocup_ci == 3) /* Estudiantes */
	replace categoinac_ci = 3 if (ea12 == 1 & condocup_ci == 3) /* Quehaceres del Hogar */
	replace categoinac_ci = 4 if ((categoinac_ci != 1 | categoinac_ci != 2 | categoinac_ci != 3) & condocup_ci == 3) /* Otra razon */
	
	**********
	***emp_ci*
	**********
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci*** 
	**************
	* Cesante = desocupado que trabajó antes
	* ea19new: 1=Yes, 2=No (¿trabajó antes?)
	gen byte cesante_ci = .
	replace cesante_ci = 1 if condocup_ci == 2 & ea19new == 1
	replace cesante_ci = 0 if condocup_ci == 2 & ea19new == 2

	***************
	***desemp_ci***
	***************	
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci***
	***************
	* Subempleo visible: trabaja 30 horas o menos y quiere trabajar más
	* ea32: 1=Yes, 2=No  (Pregunta ¿quiere trabajar más horas?)

	gen byte subemp_ci = 0
	replace subemp_ci = 1 if total_hrs_last_week <= 30 & total_hrs_last_week != . & ea32 == 1 & emp_ci == 1 
	replace subemp_ci = . if emp_ci != 1

	****************
	***durades_ci***
	****************+
	* Duración del desempleo en meses
	* ea18_yearsmerge tiene la duración en años (con decimales, variable numérica con labels)
	* Se necesita usar el valor numérico directamente
	gen byte durades_ci=.
	replace durades_ci = ea18_yearsmerge*12 if condocup_ci == 2 & ea18_yearsmerge < 999998

	***********
	***pea_ci***
	***********
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2)
	replace pea_ci = 0 if inlist(condocup_ci,3,4)
		
	****************
	*** nempleos_ci***
	****************
	* ea21: 1=Yes, 2=No (¿tiene trabajo adicional?)
	gen byte nempleos_ci = .
	replace nempleos_ci = 1 if emp_ci == 1 & ea21 == 2
	replace nempleos_ci = 2 if emp_ci == 1 & ea21 == 1
	replace nempleos_ci = . if emp_ci == 0

	******************
	***antiguedad_ci***
	******************
	* No hay variable de antigüedad en el empleo actual en 2024
	gen byte antiguedad_ci = .
*	replace antiguedad_ci = 1 if ...
*	replace antiguedad_ci = ... if emp_ci == 1
	
	***************
	***desalent_ci***
	***************
	* Desalentado: inactivo que no busca trabajo por razones de mercado
	* ea12: 13=No suitable work, 14=No resources, 16=Tired of looking
	gen byte desalent_ci= .
	replace desalent_ci = 1 if condocup_ci == 3 & inlist(ea12, 13, 14, 16)
	replace desalent_ci = 0 if condocup_ci == 3 & desalent_ci == .

	***************
	***horaspri_ci***
	***************	
	gen  byte horaspri_ci = .
	replace horaspri_ci = total_hrs_last_week if emp_ci == 1
	
	***************
	***horastot_ci ***
	***************	
	gen  byte horastot_ci  = .
	replace horastot_ci  = total_hrs_last_week if emp_ci == 1
	
	
	***************
	***tiempoparc_ci ***
	***************	
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci = 1 if total_hrs_last_week < 30 & total_hrs_last_week != . & emp_ci == 1
	replace tiempoparc_ci = 0 if total_hrs_last_week >= 30 & total_hrs_last_week != . & emp_ci == 1 
	
	***************
	***categopri_ci ***
	***************	
	* ea25: 1=Self-employed w/employees, 2=Self-employed w/o employees,
	*       3=Employee(Govt), 4=Employee(NGO), 5=Employee(Intl Org),
	*       6=Contributing family worker, 7=Domestic worker, 8=Employee(Private), 9=Apprentice
	gen  byte categopri_ci = .
	replace categopri_ci = 1 if ea25 == 1 & emp_ci == 1
	replace categopri_ci = 2 if ea25 == 2 & emp_ci == 1
	replace categopri_ci = 3 if inlist(ea25, 3, 4, 5, 7, 8, 9) & emp_ci == 1
	replace categopri_ci = 4 if ea25 == 6 & emp_ci == 1
	
	***************
	***categosec_ci ***
	***************	
	* No hay información detallada de empleo secundario en 2024
	gen  byte categosec_ci = .
*	replace categosec_ci  = 0 if ...
*	replace categosec_ci  = 1 if ...
*	replace categosec_ci  = 2 if ...
*	replace categosec_ci  = 3 if ...
*	replace categosec_ci  = 4 if ...	

	***************
	***rama_ci ***
	***************	
	*Para 2024:
	*bcea_main_industry: 1=Agriculture, 2=Aquaculture, 3=Forestry, 4=Mining,
	*   5=Manufacturing, 6=Electricity/Gas/Water, 7=Construction,
	*   8=Wholesale/Retail, 9=Tourism, 10=Transport, 11=Financial,
	*   12=Real Estate, 13=Govt Services, 14=Community/Social/Personal, 9999=DK
	gen byte rama_ci = .
	replace rama_ci = 1 if inlist(bcea_main_industry, 1, 2, 3) & emp_ci == 1
	replace rama_ci = 2 if bcea_main_industry == 4 & emp_ci == 1
	replace rama_ci = 3 if bcea_main_industry == 5 & emp_ci == 1
	replace rama_ci = 4 if bcea_main_industry == 6 & emp_ci == 1
	replace rama_ci = 5 if bcea_main_industry == 7 & emp_ci == 1
	replace rama_ci = 6 if inlist(bcea_main_industry, 8, 9) & emp_ci == 1
	replace rama_ci = 7 if bcea_main_industry == 10 & emp_ci == 1
	replace rama_ci = 8 if inlist(bcea_main_industry, 11, 12) & emp_ci == 1
	replace rama_ci = 9 if inlist(bcea_main_industry, 13, 14) & emp_ci == 1

	***************
	***spublico_ci ***
	***************	
	gen  byte spublico_ci = .
	replace spublico_ci = 1 if ea25 == 3 & emp_ci == 1
	replace spublico_ci = 0 if ea25 != 3 & ea25 != . & emp_ci == 1
	
	***************
	***tamemp_ci ***
	***************	
	* No hay variable de tamaño de empresa en 2024
	gen  byte tamemp_ci = .
*	replace tamemp_ci  = 1 if ...
*	replace tamemp_ci  = 2 if ...
*	replace tamemp_ci  = 3 if ...
	
	***************
	***cotizando_ci***
	***************	
	* No hay variable de de cotizacion en 2024
	gen  byte cotizando_ci = .
*	replace cotizando_ci  = 0 if ...
*	replace cotizando_ci  = 1 if ...
	
	
	***************
	***afiliado_ci***
	***************	
	* No hay información sobre afiliación a seguridad social en 2024
	gen  byte afiliado_ci = .
*	replace afiliado_ci  = 0 if ...
*	replace afiliado_ci  = 1 if ...	
	
	***************
	***instcot_ci***
	***************	
	* No hay información sobre afiliación a seguridad social en 2024
	gen  byte instcot_ci = .
*	replace instcot_ci  = ""	
	
	**************
	***formal_ci***
	**************
	* informalemp: 0=formal, 100=Informally employed
	
	gen byte formal_ci = .
	replace formal_ci = 1 if informalemp == 0 & condocup_ci == 1
	replace formal_ci = 0 if informalemp == 100 & condocup_ci == 1
	
*	replace formal_ci  =  1 if (cotizando_ci == 1 | afiliado_ci == 1) & condocup_ci == 1
*	replace formal_ci = 0 if cotizando_ci == 0 & (condocup_ci == 1 | condocup_ci == 2)
	
	*******************
	***tipocontrato_ci***
	*******************
	* No hay información sobre tipo de contrato en 2024
	gen byte tipocontrato_ci = .
*	replace tipocontrato_ci = 1 if … & categopri_ci == 3
*	replace tipocontrato_ci = 2 if … & categopri_ci == 3
*	replace tipocontrato_ci = 3 if … & categopri_ci == 3
		
	**************
	***ocupa_ci***
	**************
	* ea23main_occ: 0=Armed Forces, 1=Managers, 2=Professionals, 3=Technicians,
	*   4=Clerical, 5=Services/Sales, 6=Skilled Agri, 7=Craft, 8=Plant/Machine,
	*   9=Elementary, 99=DK/NS
	* IMPORTANTE: La clasificación ahora tiene 8 categorías y no 9 porque "5=Services/Sales" está agrupado en una sola

	gen byte ocupa_ci=.
	replace ocupa_ci = 1 if inlist(ea23main_occ, 2, 3) & emp_ci == 1
	replace ocupa_ci = 2 if ea23main_occ == 1 & emp_ci == 1
	replace ocupa_ci = 3 if ea23main_occ == 4 & emp_ci == 1
	replace ocupa_ci = 4 if ea23main_occ == 5 & emp_ci == 1
	replace ocupa_ci = 5 if ea23main_occ == 6 & emp_ci == 1
	replace ocupa_ci = 6 if inlist(ea23main_occ, 7, 8) & emp_ci == 1
	replace ocupa_ci = 7 if ea23main_occ == 0 & emp_ci == 1
	replace ocupa_ci = 8 if ea23main_occ == 9 & emp_ci == 1

	**************
	**pension_ci***
	**************
	* No hay información en 2024
	gen byte pension_ci=. 
*	replace pension_ci=1 if …
* 	replace pension_ci=0 if …
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . 
*	replace pensionsub_ci = 1 if …
*	replace pensionsub_ci = 0 if …
	
	***************
	**tipopen_ci**
	***************
	* No hay información en 2024
	gen byte tipopen_ci = . 
	
	***************
	**instpen_ci **
	***************
	* No hay información en 2024
	gen byte instpen_ci = .
	
	
****************************
***VARIABLES DE INGRESO***
****************************

	*************
	* ylmpri_ci *
	*************
	* income_month: ingreso mensual reportado (variable numérica continua)
	generate double ylmpri_ci = income_month if emp_ci == 1

	************
	* ylmsec_ci *
	************
	* No hay información de ingresos del empleo secundario
	generate double ylmsec_ci = .

	**************
	* ylmotros_ci *
	**************
    generate double ylmotros_ci=.
 
	*********
	* ylm_ci *
	*********
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci *
	**************
	gen double ylnmpri_ci =.
	replace ylnmpri_ci = . if ylnmpri_ci < 0 & ylnmpri_ci != .

	**************
	* ylnmsec_ci *
	**************
	gen double ylnmsec_ci = .
*   egen double ylnmsec_ci = rowtotal(...) if emp_ci==1, mi
*   replace ylnmsec_ci = . if ylnmsec_ci < 0 & ylnmsec_ci != .

	****************
	* ylnmotros_ci *
	****************
	gen double ylnmotros_ci=.
*   egen double ylnmotros_ci = rowtotal(...) if emp_ci==1, mi
*   replace ylnmotros_ci = . if ylnmotros_ci < 0 & ylnmotros_ci != .

	**********
	* ylnm_ci *
	**********
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .

	**********
	* ynlm_ci *
	**********
	gen double ynlm_ci = .
*	egen double ynlm_ci = rowtotal(...), mi
*	replace ynlm_ci = 0 if ynlm_ci < 0 & ynlm_ci != .

	***********
	* ynlnm_ci *
	***********
	gen double ynlnm_ci = .
*	replace ynlnm_ci = . if ynlnm_ci < 0 & ynlnm_ci != .

	**********
	* ytot_ci *
	**********
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

	*********
	* ylm_ch *
	*********
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci==1

	**********
	* ylnm_ch *
	**********
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1

	***********
	* ynlnm_ch *
	***********
	bysort idh_ch: egen double ynlnm_ch = total(ynlnm_ci) if miembros_ci==1

	*********
	* ynlm_ch *
	*********
	gen double ynlm_ch = .
 *   egen double ynlm_ch = rowtotal(...), mi
 
	**********
	* ytot_ch *
	**********
	egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi

	***************
	* ylmhopri_ci *
	***************
    generate double ylmhopri_ci = ylmpri_ci/horaspri_ci if emp_ci==1 & horaspri_ci>0
 
	**********
	* ylmho_ci *
	**********
    generate double ylmho_ci = ylm_ci/horastot_ci if emp_ci==1 & horastot_ci>0
  
	**************
	* nrylmpri_ci *
	**************
	generate byte nrylmpri_ci = (emp_ci==1 & ylmpri_ci==.)

	**************
	* nrylmpri_ch *
	**************
	bysort idh_ch: egen byte nrylmpri_ch = max(nrylmpri_ci) if miembros_ci==1

	*************
	* remesas_ci *
	*************
    generate double remesas_ci = .

	*************
	* remesas_ch *
	*************
    generate double remesas_ch = .

	*************
	* pension_ci *
	*************
	*Me sale una alerta de que esta variable ya está generada más arriba (línea 625)
	*generate byte pension_ci = .

	**********
	* ypen_ci *
	**********
	generate double ypen_ci =.

	****************
	* pensionsub_ci *
	****************
	*Me sale una alerta de que esta variable ya está generada más arriba (línea 632)
	*generate byte pensionsub_ci = .

	*************
	* ypensub_ci *
	*************
	generate double ypensub_ci = .
		
****************************
***VARIABLES DE EDUCACION***
****************************

	*********	
	*aedu_ci*
	*********
	/*
	MAMB 08/04/2026: 

	Para el nivel vocacional la equivalencia es entre secundaria y terciaria. Según años de escolaridad quedaría así: 

	Pre-vocational -> secundaria baja (9 años) - equivalente o preparatorio para el primer ciclo de secundaria
	Nivel 1 -> secundaria alta (10 años)
	Nivel 2 -> secundaria alta (11 años) - equivale a terminar la secundaria
	Nivel 3 -> Terciaria (12 años) - equivale a especialización técnica

	*/

/*
	gen aedu_ci=.
		
	*Para quienes no terminaron el ultimo nivel educativo al que asistieron
	replace aedu_ci=0 if ... // Cero anios de educación para aquellos que no han asistido nunca a ninguna institucion y los menores de 2 anios
	replace aedu_ci=0 if ... // Prescolar
	replace aedu_ci=... if ...
	replace aedu_ci=...+ ... if ...
	replace aedu_ci=...+ ... if...
	replace aedu_ci=...+ ... if ...
	replace aedu_ci=...+ ... if ...
	replace aedu_ci=...+ ... if ...
*/
	gen aedu_ci = .

	* Nunca asistió / None
	replace aedu_ci = 0 if ed5 == 22  // Never Attended
	replace aedu_ci = 0 if ed5 == 21  // None
	
	* Nivel Primario (Infant 1=1, Infant 2=2, Standard 1-6 = 3-8 años)
	replace aedu_ci = 1 if ed5 == 1   // Infant 1
	replace aedu_ci = 2 if ed5 == 2   // Infant 2
	replace aedu_ci = 3 if ed5 == 3   // Standard 1
	replace aedu_ci = 4 if ed5 == 4   // Standard 2
	replace aedu_ci = 5 if ed5 == 5   // Standard 3
	replace aedu_ci = 6 if ed5 == 6   // Standard 4
	replace aedu_ci = 7 if ed5 == 7   // Standard 5
	replace aedu_ci = 8 if ed5 == 8   // Standard 6
	
	* Nivel Secundario (1st-4th Form = 9-12 años)
	replace aedu_ci = 9  if ed5 == 9  // 1st Form
	replace aedu_ci = 10 if ed5 == 10 // 2nd Form
	replace aedu_ci = 11 if ed5 == 11 // 3rd Form
	replace aedu_ci = 12 if ed5 == 12 // 4th Form
	
	* Vocacional (se asimila a secundaria)
	replace aedu_ci = 9  if ed5 == 13 // Pre vocational
	replace aedu_ci = 10 if ed5 == 14 // Level 1 vocational
	replace aedu_ci = 11 if ed5 == 15 // Level 2 vocational
	
	* Nivel Terciario
	replace aedu_ci = 12 if ed5 == 16 // Level 3 vocational (Se asimila como terciaria)
	replace aedu_ci = 14 if ed5 == 17 // Associate/6th Form Junior College
	replace aedu_ci = 16 if ed5 == 18 // Bachelors
	replace aedu_ci = 18 if ed5 == 19 // Master's or Higher

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = .
	replace eduui_ci = 1 if aedu_ci >= 12 & aedu_ci < 16 & aedu_ci != .
	replace eduui_ci = 0 if (aedu_ci < 12 | aedu_ci >= 16) & aedu_ci != .
	replace eduui_ci = . if aedu_ci == .
	
	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = .
	replace eduuc_ci = 1 if aedu_ci >= 16 & aedu_ci != .
	replace eduuc_ci = 0 if aedu_ci < 16 & aedu_ci != .
	replace eduuc_ci = . if aedu_ci == .

	**********
	*eduac_ci*
	**********
	gen eduac_ci = .
*	replace eduac_ci = 0 if ...
*	replace eduac_ci = . if aedu_ci == .
	
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci=.
*	replace edupre_ci = 1 if ....
*	replace edupre_ci = 0 if ....

	************
	*asispre_ci*
	************
	g asispre_ci=.
*	replace asispre_ci = 1 if ....
*	replace asispre_ci = 0 if ....

	***********
	*asiste_ci*
	***********
	gen asiste_ci=.
	replace asiste_ci = 1 if ed3new == 1
	replace asiste_ci = 0 if ed3new == 2


	*************
	*razonesnoasis_ci*
	**************
	* ed6: razón de no asistencia
	* 1=Too young, 2=Financial, 3=Working, 4=Domestic, 6=Illness, 7=Not interested
	gen byte razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if ed6 == 2
	replace razonesnoasis_ci = 2 if ed6 == 7
	replace razonesnoasis_ci = 3 if ed6 == 3 | ed6 == 4
	replace razonesnoasis_ci = 4 if ed6 == 6
	replace razonesnoasis_ci = 5 if ed6 == 1 | ed6 == 888888

	***********
	*edupub_ci*
	***********
	* No hay información sobre tipo de institución educativa (pública/privada)
	gen edupub_ci =.
*	replace edupub_ci = 1 if ...
*	replace edupub_ci = 0 if ...
		
****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	* hh5: 1=BEL, 2=Other source, 5=Gas/Kerosene, 6=Candle, 8=None
	gen luz_ch=.
	replace luz_ch = 1 if inlist(hh5, 1, 2)
	replace luz_ch = 0 if inlist(hh5, 5, 6, 8)	
	
	***********
	*luzmide_ch*
	***********
	* BEL (Belize Electricity Limited) tiene medidores
	gen luzmide_ch=.
	replace luzmide_ch = 1 if hh5 == 1
	replace luzmide_ch = 0 if hh5 == 2 & luz_ch == 1		
	
	***********
	*combust_ch*
	***********
	* hh6: 1=Gas, 2=Wood/charcoal, 3=Kerosene, 4=Electricity, 5=Does not cook
	gen combust_ch=.
	replace combust_ch = 1 if inlist(hh6, 1, 4)
	replace combust_ch = 0 if inlist(hh6, 2, 3)		
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	* hh11: 1=Earth/Sand, 2=Wood planks, 3=Plywood, 4=Parquet, 5=Vinyl,
	*       6=Ceramic tiles, 7=Cement/Concrete, 8=Carpet
	gen byte piso_ch = .
	replace piso_ch = 0 if hh11 == 1
	replace piso_ch = 1 if inlist(hh11, 2, 3, 7)
	replace piso_ch = 2 if inlist(hh11, 4, 5, 6, 8)
	
	***********
	*pared_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	* hh10: 1=No Walls, 2=Cane/Palm, 3=Palmetto, 4=Bamboo, 5=Stone w/mud,
	*       6=Plywood, 7=Cardboard, 8=Reused wood, 9=Cement/Concrete,
	*       10=Stone w/lime, 11=Bricks, 12=Cement blocks, 13=Wood planks,
	*       14=Wood and concrete, 15=Stucco
	gen pared_ch=.	
	replace pared_ch = 0 if inlist(hh10, 1, 2, 3, 4, 7, 8)
	replace pared_ch = 1 if inlist(hh10, 9, 10, 11, 12, 13, 14, 15)
	replace pared_ch = 2 if inlist(hh10, 5, 6, 888888)
	
	***********
	*techo_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	* hh9: 1=Sheet Metal, 2=Shingle(asphalt), 3=Shingle(Wood), 5=Concrete,
	*      8=Thatch, 9=Makeshift
	gen techo_ch=.
	replace techo_ch = 0 if inlist(hh9, 8, 9)
	replace techo_ch = 1 if inlist(hh9, 1, 2, 3, 5)
	replace techo_ch = 2 if hh9 == 888888
	
	***********
	*resid_ch*
	***********
	gen resid_ch=.
*	replace resid_ch=0 if ...
*	replace resid_ch=1 if ...		
*	replace resid_ch=2 if ...	
*	replace resid_ch=3 if ...	
	
	***********
	*dorm_ch*
	***********
	* hh3: número de habitaciones para dormir (1-8, 999999=DK)
	gen dorm_ch = hh3
	replace dorm_ch = . if hh3 >= 999999
	label var dorm_ch "Cantidad de dormitorios en el hogar"
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=.
*	replace cuartos_ch=... if ...	
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
*	replace cocina_ch==0 if ...	
*	replace cocina_ch==1 if ...	
	
	***********
	*telef_ch*
	***********
	* hh13b: 1=Yes, 2=No (teléfono fijo)
	gen byte telef_ch = .
	replace telef_ch = 1 if hh13b == 1
	replace telef_ch = 0 if hh13b == 2
	
	***********
	*refrig_ch*
	***********
	* hh12b: 1=Yes, 2=No
	gen byte refrig_ch = .
	replace refrig_ch = 1 if hh12b == 1
	replace refrig_ch = 0 if hh12b == 2
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
*	replace freez_ch=0 if ...
*	replace freez_ch=1 if ...
	
	***********
	*auto_ch*
	***********
	* hh12q: 1=Yes, 2=No (vehículo a motor privado)
	gen auto_ch=.
	replace auto_ch = 1 if hh12q == 1
	replace auto_ch = 0 if hh12q == 2
	
	***********
	*compu_ch*
	***********
	* MAMB: la base de datos tiene un error de etiqueta. Las variables
	* hh12m y hh12n hacen referencia a tenencia de computadora, posiblemente
	* una de ellas sea laptop pero no se sabe
	gen compu_ch=.
*	replace compu_ch=0 if ...
*	replace compu_ch=1 if ...
		
	***********
	*internet_ch*
	***********
	* hh13c
	gen byte internet_ch = .
	replace internet_ch = 1 if hh13c == 1
	replace internet_ch = 0 if hh13c == 2
	
	*************
	*  cel_ch  *
	*************
	* hh12l: 1=Yes, 2=No (celular)
	gen byte cel_ch = .
	replace cel_ch = 1 if hh12l == 1
	replace cel_ch = 0 if hh12l == 2
	
	***********
	*vivi1_ch*
	***********
	* hh1: 1=Private house, 2=Apartment, 3=Duplex, 4=Barracks
	gen vivi1_ch=.
	replace vivi1_ch = 1 if hh1 == 1
	replace vivi1_ch = 2 if inlist(hh1, 2, 3)
	replace vivi1_ch = 3 if inlist(hh1, 4, 888888)
	
	***********
	*vivi2_ch*
	***********
	gen vivi2_ch=.
	replace vivi2_ch=0 if vivi1_ch ==3
	replace vivi2_ch=1 if vivi1_ch ==1 | vivi1_ch ==2
	
	***********
	*viviprop_ch*
	***********
	* hh2: 1=Own/hire-purchase, 2=Lease, 3=Rent-Private, 4=Rent-Government, 5=Rent-free, 6=Squat
	gen viviprop_ch=.
	replace viviprop_ch = 0 if inlist(hh2, 3, 4)
	replace viviprop_ch = 1 if hh2 == 1
	replace viviprop_ch = 2 if hh2 == 2
	replace viviprop_ch = 3 if inlist(hh2, 5, 6)	
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
*	replace vivitit_ch=0 if ...
*	replace vivitit_ch=1 if ...	
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=.
*	replace vivialq_ch=... if ...
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=.
*	replace vivialqimp_ch=... if ...
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	* hh7: 1=Public piped dwelling, 2=Public piped yard, 3=Private piped,
	*      4=Standpipe, 6=Protected well, 7=Unprotected well,
	*      8=Private catchment, 9=River/Creek
	gen byte aguared_ch =.
	replace aguared_ch = 1 if inlist(hh7, 1, 2, 3, 4)
	replace aguared_ch = 0 if inlist(hh7, 6, 7, 8, 9)

	***********
	*aguafconsumo _ch*
	***********
	* hh8: Household main source of drinking water
	*      1=Bottled/Purified water, 2=Public piped into dwelling or yard, 3=Private piped into dwelling or yard, 4=Public standpipe,
	*      5=Protected dug well, 6=Unprotected dug well, 7=Private catchment, not piped (vat, drum,, 8=River/Creek/Spring/Stream/Pond ,
	*	   888888 =Other
	gen byte aguafconsumo_ch = .
	replace aguafconsumo_ch = 1 if hh8 == 2 | hh8 == 3
	replace aguafconsumo_ch = 2 if hh8 == 4
	replace aguafconsumo_ch = 3 if hh8 == 1
	replace aguafconsumo_ch = 4 if hh8 == 5
	replace aguafconsumo_ch = 5 if hh8 == 7
*	replace aguafconsumo_ch = 6 if ... No hay esta categoría 
*	replace aguafconsumo_ch = 7 if ... No hay esta categoría 
	replace aguafconsumo_ch = 8 if hh8 == 8
	replace aguafconsumo_ch = 9 if hh8 == 6
	replace aguafconsumo_ch = 10 if hh8 == 888888

	***********
	*aguafuente_ch*
	***********	
	* hh7: Household main source of water supply  
	*      1=Public piped into dwelling, 2=Public piped into yard only , 3=Private piped into dwelling or yard , 4=Public standpipe,
	*      6= Protected dug well, 7=Unprotected dug well, 8=Private catchments, not piped (vat, drum ...), 9=River/Creek/Spring/Stream/Pond
	*      888888 = Other, 999999= DK/NS
	gen byte aguafuente_ch =.
	replace aguafuente_ch = 1 if hh7 == 1 | hh7 == 2 | hh7 == 3
	replace aguafuente_ch = 2 if hh7 == 4
*	replace aguafuente_ch = 3 if … No hay esta categoría (agua embotellada)
	replace aguafuente_ch = 4 if hh7 == 6
	replace aguafuente_ch = 5 if hh7 == 8
*	replace aguafuente_ch = 6 if …
*	replace aguafuente_ch = 7 if …
	replace aguafuente_ch = 8 if hh7 == 9
	replace aguafuente_ch = 9 if hh7 == 7
	replace aguafuente_ch = 10 if hh7 == 888888 

	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	replace aguadist_ch = 1 if aguafuente_ch == 1
	replace aguadist_ch = 2 if aguafuente_ch == 4 | aguafuente_ch == 5 | aguafuente_ch == 9 /* Pozo protegido, agua de lluvia, pozo no protegido (se asumen en el terreno) */
	replace aguadist_ch = 3 if aguafuente_ch == 2 | aguafuente_ch == 8
	replace aguadist_ch = 0 if missing(aguadist_ch) & aguafuente_ch!=.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
*	replace aguadisp1_ch = 1 if …
*	replace aguadisp1_ch = 2 if …
*	replace aguadisp1_ch = 9 if …
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =9
*	replace aguadisp2_ch = 1 if …
*	replace aguadisp2_ch = 2 if …
*	replace aguadisp2_ch = 3 if …
*	replace aguadisp2_ch = 9 if …
	
	******************
	** aguatrat_ch ** - 
	*****************
	* Si el agua de consumo es embotellada/purificada = tratamiento
	gen byte aguatrat_ch =.
	replace aguatrat_ch = 1 if hh8 == 1
	replace aguatrat_ch = 0 if hh8 != 1 & hh8 != . & hh8 < 999999
	
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
*	replace aguamide_ch = 0 if …
*	replace aguamide_ch = 1 if...
	
	******************
	** bano_ch ** - 
	*****************
	*  hh4a: 1 Water closet linked to BWS sewer system,
	*		 2 Water closet linked to septic tank 
	*        3 Pit latrine, ventilated and elevated 
	*        4 Pit latrine, ventilated and not elevated
	*        5 Pit latrine, elevated and not ventilated
	*        6 Pit latrine, not ventilated and not elev  
	*        7 None
	*        8 Other
	gen byte bano_ch = .
	replace bano_ch=0 if  hh4a == 7
	replace bano_ch=1 if  hh4a == 1
	replace bano_ch=2 if  hh4a == 2
	replace bano_ch=3 if  inlist(hh4a, 3, 4)
	replace bano_ch=5 if  inlist(hh4a, 5, 6)
	replace bano_ch=6 if  hh4a >= 888888 & hh4a < 999999
		
	******************
	** banoex_ch ** - 
	*****************
	* hh4b: 1=Yes (compartido), 2=No
	gen byte banoex_ch = .
	replace banoex_ch = 0 if hh4b == 2
	replace banoex_ch = 1 if hh4b == 1
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if bano_ch > 0 & bano_ch != .
	replace sinbano_ch = 1 if bano_ch == 0
	replace sinbano_ch = 3 if bano_ch == .
		
	******************
    ** banomejorado_ch ** - 
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
	* hl7new: 1=Belize, 3=Honduras, 9=DK/NS
	gen byte migrante_ci= .
	replace migrante_ci = 0 if hl7new == 1
	replace migrante_ci = 1 if hl7new != 1 & hl7new != . & hl7new != 9
	
	****************
	 *migrantiguo5_ci*
	****************	
	gen byte migrantiguo5_ci=.

	****************
	 *miglac_ci*
	****************	
	* Solo Honduras (3) disponible como país de origen LAC
	gen byte miglac_ci = .
	replace miglac_ci = 1 if hl7new == 3 & migrante_ci == 1
	replace miglac_ci = . if migrante_ci != 1
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar*
	****************	
	gen byte tipo_bienestar = . 

	****************
	 * pobre_ine _ci*
	****************	
	gen byte pobre_ine_ci= . 


	****************
	 * bienestar_agregado *
	****************	
	gen bienestar_agregado = . 

	****************
	* lpe_ci *
	****************	
	gen lpe_ci = . 
	
	****************
	 * ln_ci *
	****************	
	gen ln_ci = . 
	

	
	/*_____________________________________________________________________________________________________*/

	* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
    * Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza

	/*_____________________________________________________________________________________________________*/
	

	do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

	
	/*_____________________________________________________________________________________________________*/
	* Verificación de que se encuentren todas las variables armonizadas 
	/*_____________________________________________________________________________________________________*/
	
	
      order region_BID_c region_c pais_c anio_c mes_c zona_c idh_ch idp_ci factor_ci factor_ch estrato_ci upm_ci /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad
	  /// Agregar aquí: ISO3pais_dis_ci (renombrar con código del país, ej. COL_dis_ci)
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	/// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci /// Ingresos individuo
     ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci   /// Ingresos individuo
	  ylm_ch ylnm_ch ynlm_ch ynlnm_ch   ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  miembros_one_ci tipo_bienestar pobre_ine_ci bienestar_agregado lpe_ci  ln_ci /// Pobreza  
      lp19_2011 lp31_2011 lp5_2011  lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa




saveold "`base_out'", version(12) replace

cap log close
