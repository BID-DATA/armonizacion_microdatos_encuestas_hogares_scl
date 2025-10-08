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

local PAIS GTM
local ENCUESTA ENEIC
local ANO "2024"
local ronda t1
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: GTM
Encuesta: ENEIC
Round: t1
Autores: 
Versión: Juan Camilo Perdomo (SCL/SCL) - Email: ..., Fecha: Octubre de 2025
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
	gen region_c=p02a05b
	label define region_c  ///
    1 "Guatemala"  ///
    2 "El Progreso"  ///
    3 "Sacatepéquez"  ///
    4 "Chimaltenango"  ///
    5 "Escuintla"  ///
    6 "Santa Rosa"  ///
    7 "Sololá" ///
	8 "Totonicapán" ///
	9 "Quetzaltenango" ///
	10 "Suchitepéquez" ///
	11 "Retalhuleu" ///
	12 "San Marcos" ///
	13 "Huehuetenango" ///
	14 "Quiché" ///
	15 "Baja Verapaz" ///
	16 "Alta Verapaz" ///
	17 "Petén" ///
	18 "Izabal" ///
	19 "Zacapa" ///
	20 "Chiquimula" ///
	21 "Jalapa" ///
	22 "Jutiapa"
   label values region_c region_c

	*************
	* pais_c    *
	*************
	gen str3 pais_c="GTM"

	******
	*anio*
	******
	gen int anio_c=2024
	
	******
	*mes_c*
	******
	gen int mes_c=.
	* La variable corresponde al trimestre y siempre toma el valor 1

	******
	*zona*
	******
	gen zona_c=(p00a10==1)
	
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
	gen idh_ch=num_hogar
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	gen new_id = string(num_hogar) + "_" + string(num_persona)
	gen idp_ci= new_id
	tostring idp_ci, replace format ("%20.0f") 
	
	***********
	*factor_ci* 
	***********
	gen factor_ci=factor_p
	
	*******************************************
	*Factor de expansion del hogar (factor_ch)*
	*******************************************
	gen factor_ch=factor_h
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen byte sexo_ci=p02a02

	*********
	*edad_ci*
	*********
	gen int edad_ci=p02a03
	replace edad_ci=. if p02a03==.
	
	**************
	**relacion_ci**
	**************
	gen byte relacion_ci=.
	replace relacion_ci = 1 if p02a07 == 1
	replace relacion_ci = 2 if p02a07 == 2
	replace relacion_ci = 3 if p02a07 == 3
	replace relacion_ci = 4 if inrange(p02a07,4,11)
	replace relacion_ci = 5 if inrange(p02a07,13,14)
	replace relacion_ci = 6 if p02a07 == 12
	
	*************
	*miembros_ci*
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	*************
	*miembros_one_ci*
	*************
	gen miembros_one_ci=(p02a07!=12)
	* Solo se exluyen los empleados domésticos, según instrucciones del manual
	
	**************
	*Estado Civil*
	**************
	gen byte civil_ci=. 
	replace civil_ci = 1 if p02a12==7
	replace civil_ci = 2 if p02a12==1 | p02a12==2
	replace civil_ci = 3 if inrange(p02a12,3,5)
	replace civil_ci = 4 if p02a12==6
		
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

	
	****************
	*notronopari_ch*
	****************
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
	
	
*****************************
***VARIABLES DE DIVERSIDAD***
*****************************

	*********
	*afro_ci*
	*********
	 gen byte afro_ci = .
     replace afro_ci = 1 if p02a08==4
	 replace afro_ci = 0 if p02a08!=4 & p02a08!=.
	
	*********
	*ind_ci*
	*********	
    gen byte ind_ci = .
    replace ind_ci = 1 if p02a08==1 | p02a08==2 | p02a08==6
	replace ind_ci = 0 if inlist(p02a08,3, 4, 5) & p02a08!=.
	
	**************
	*noafroind_ci*
	**************
	gen byte noafroind_ci = .
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1
	replace noafroind_ci = . if afro_ci==. | ind_ci==.

	************
	*afroind_ci*
	************
	gen byte afroind_ci=.
	replace afroind_ci = 1 if ind_ci==1
	replace afroind_ci = 2 if afro_ci==1
	replace afroind_ci = 3 if noafroind_ci==1
	
	***************
	*afroind_ano_c*
	***************
	gen afroind_ano_c=2022
	* Se genera con el año que está en el manual, pero hay que tener en cuenta el cambio de encuesta, no sé si modifique esta variable
	
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
	gen byte dis_ci = .
	egen dificultad = rowmax(p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f)
	replace dis_ci = (dificultad >= 2 & dificultad <= 4)
	foreach var in p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f {
    replace dis_ci = . if inlist(`var', 9, 99,.)
	}
	drop dificultad

	**********
	*disWG_ci*
	**********
	gen byte disWG_ci=.
	egen dificultad = rowmax(p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f)
	replace disWG_ci = (dificultad >= 3 & dificultad <= 4)
	foreach var in p02a11a p02a11b p02a11c p02a11d p02a11e p02a11f {
    replace disWG_ci = . if inlist(`var', 9, 99,.)
	}
	drop dificultad
	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	******************
	*ISOalpha3_dis_ci*
	******************
	gen byte GTM_dis_ci = dis_ci
	
****************************
***VARIABLES DE MERCADO LABORAL***
* NOTA: Actualmente se está revisando el manual
****************************

****************************
***VARIABLES DE INGRESO***
* NOTA: SE SIGUE REVISANDO EL MANUAL
****************************

****************************
***VARIABLES DE EDUCACION***
****************************

	*********	
	*aedu_ci*
	*********
	gen aedu_ci=.
	replace aedu_ci = 0            if p03a03a==1
    replace aedu_ci = p03a03b      if p03a03a==1 & inrange(p03a03b,1,6)
    replace aedu_ci = 6  + p03a03b if p03a03a==2 & inrange(p03a03b,1,3)
    replace aedu_ci = 9  + p03a03b if p03a03a==3 & inrange(p03a03b,1,4)
    replace aedu_ci = 13 + p03a03b if p03a03a==4 & inrange(p03a03b,1,6)
    replace aedu_ci = 19 + p03a03b if p03a03a==5 & inrange(p03a03b,1,3)
    replace aedu_ci = 22 + p03a03b if p03a03a==6 & inrange(p03a03b,1,4)

	**********
	*eduui_ci*
	**********
	gen byte eduui_ci = (aedu_ci >= 16 & aedu_ci <= 25) if aedu_ci < .

	**********
	*eduuc_ci*
	**********
	gen byte eduuc_ci = (aedu_ci >= 16 & aedu_ci <= 25) if aedu_ci < .
	

	**********
	*eduac_ci*
	**********
	
	gen byte eduac_ci = (aedu_ci >= 12) if aedu_ci < .
		
	***********
	*edupre_ci*
	***********
	gen byte edupre_ci = (p03a03a == 1) if p03a03a !=.

	************
	*asispre_ci*
	************
	gen byte asispre_ci = .
	
	***********
	*asiste_ci*
	***********
	gen byte asiste_ci = (p03a02 == 1) if p03a02 !=.

	*************
	*pqnoasis1_ci*
	**************
	gen pqnoasis1_ci = .
    
	***********
	*edupub_ci*
	***********
	gen edupub_ci =.
	

****************************
***VARIABLES DE VIVIENDA***
****************************		
	***********
	*luz_ch*
	***********
	gen luz_ch=.
	
	***********
	*luzmide_ch*
	***********
	gen luzmide_ch=.	
	
	***********
	*combust_ch*
	***********
	gen combust_ch=.	
	
	***********
	*piso_ch*
	***********
	gen piso_ch=.	
	
	***********
	*pared_ch*
	***********
	gen pared_ch=.
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	
	***********
	*resid_ch*
	***********
	gen resid_ch=.
	
	***********
	*dorm_ch*
	***********
	gen dorm_ch=.
	
	***********
	*cuartos_ch*
	***********
	gen cuartos_ch=.
	
	***********
	*cocina_ch*
	***********
	gen cocina_ch=.
	
	***********
	*telef_ch*
	***********
	gen telef_ch=.	
	
	***********
	*refrig_ch*
	***********
	gen refrig_ch=.
	
	***********
	*freez_ch*
	***********
	gen freez_ch=.
	
	***********
	*auto_ch*
	***********
	gen auto_ch=.
	
	***********
	*compu_ch*
	***********
	gen compu_ch=.
		
	***********
	*internet_ch*
	***********
	gen internet_ch=.
	
	***********
	*vivi1_ch**
	***********
	gen vivi1_ch=.
	
	***********
	*viviprop_ch*
	***********
	gen viviprop_ch=.
	replace viviprop_ch = 0 if p01a01==3
	replace viviprop_ch = 1 if p01a01==1
	replace viviprop_ch = 2 if p01a01==2
	replace viviprop_ch = 3 if p01a01==4
	
	***********
	*vivitit_ch*
	***********
	gen vivitit_ch=.
	
	***********
	*vivialq_ch*
	***********
	gen vivialq_ch=p01a03
	
	***********
	*vivialqimp_ch*
	***********
	gen vivialqimp_ch=p01a02
	
****************************
***VARIABLES DE WASH***
****************************

	***********
	*aguared_ch*
	***********
	gen byte aguared_ch =.

	***********
	*aguafconsumo _ch*
	***********
	gen byte aguafconsumo_ch =0

	***********
	*aguafuente_ch*
	***********	
	gen byte aguafuente_ch =.
	
	******************
	** aguadist_ch ** - 
	*****************
	gen byte aguadist_ch  =.
	
	******************
	** aguadisp1_ch ** - 
	*****************
	gen byte aguadisp1_ch =9
	
	******************
	** aguadisp2_ch ** - 
	*****************
	gen byte aguadisp2_ch =9
	
	******************
	** aguatrat_ch ** - 
	*****************
	gen byte aguatrat_ch =.
	
	******************
	** aguamala_ch ** - 
	*****************
	gen byte aguamala_ch = .

	******************
	** aguamejorada_ch ** - 
	*****************
	gen byte aguamejorada_ch = .
	
	******************
	** aguamide_ch ** - 
	*****************
	gen byte aguamide_ch = .
	
	******************
	** bano_ch ** - 
	*****************
	gen byte bano_ch = .
		
	******************
	** banoex_ch ** - 
	*****************
	gen byte banoex_ch = .
	
	******************
	** sinbano_ch ** - 
	*****************
	gen sinbano_ch = .
		
	******************
    ** banomejorado_ch ** - 
    *****************
	gen byte banomejorado_ch= .

	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
