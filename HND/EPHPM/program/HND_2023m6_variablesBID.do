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

local PAIS HND
local ENCUESTA EPHPM
local ANO "2023"
local ronda m6 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
  
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Honduras
Encuesta: EPHPM
Round: m6
Autores: 
*************************************************************************** */
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
* no disponible base septiembre hasta el momento
*************************************************************************** */


use "`base_in'", clear


**********************************
***VARIABLES DEL IDENTIFICACION***
**********************************
	
	********
	*anio_c*
	********
	gen anio_c=2023

	*******
	*mes_c*
	*******
	gen mes_c= 6
	label define mes_c 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre" 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto"
	label value mes_c mes_c

	********
	*pais_c*
	********
	gen pais_c="HND"	
		
	****************
	* region_BID_c *
	****************
	gen region_BID_c=1

	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	************
	** ine01  ** 
	************
	gen ine01= .
	*replace ine01 =  substr(cor_pre,1,2) // Puede que esta variable contenga la variable de departamento en sus dos primeros digitos

	label define ine01  ///
			   1 "Atlantida" ///
			   2 "Colon" ///
			   3 "Comayagua" ///
			   4 "Copan" ///
			   5 "Cortes" ///
			   6 "Choluteca" ///
			   7 "El Paraiso" ///
			   8 "Francisco Morazan" ///
			   9 "Gracias a Dios" ///
			  10 "Intibuca" ///
			  11 "Islas de la bahia" ///
			  12 "La paz" ///
			  13 "Lempira" ///
			  14 "Ocotepeque" ///
			  15 "Olancho" ///
			  16 "Santa Barbara " ///
			  17 "Valle" ///
			  18 "Yoro"
	 
	label value ine01 ine01
	label var ine01 "Division administrativa, departamentos"

	***************
	** region_c  ** 
	***************	
	gen region_c= ine01
	
	********
	*zona_c*
	********
	gen zona_c=1 if dominio==1 | dominio==2 | dominio==3 | dominio==4
	replace zona_c=0 if dominio==5
	label define zona_c 0 "Rural" 1 "Urbana" 
	label value zona_c zona_c
	
	***************
	***estrato_ci***
	***************
	gen estrato_ci=.
	label variable estrato_ci "Estrato"
	
	***************
	***upm_ci***
	***************
	gen upm_ci=dominio
	label variable upm_ci "Unidad Primaria de Muestreo"

	********
	*idh_ch*
	********
	gen idh_ch = id

	********
	*idp_ci*
	********
	gen idp_ci=orden 
	
	***********
	*factor_ch*
	***********
	gen factor_ch=factor
	label var factor_ch "Factor de Expansion del Hogar"
	
	***********
	*factor_ci*
	***********
	gen factor_ci=factor
	label var factor_ci "Factor de Expansion de los individuos"
		

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci*
	*********
	gen sexo_ci=sexo
	label var sexo "Sexo del Individuo"
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci
	
	*********
	*edad_ci*
	*********
	gen edad_ci=edad 
	label var edad_ci "Edad del Individuo"
	drop edad

	*************
	*relacion_ci*
	*************
	gen relacion_ci=.
	replace relacion_ci=1 if rela_j==1
	replace relacion_ci=2 if rela_j==2
	replace relacion_ci=3 if rela_j==3 | rela_j==4
	replace relacion_ci=4 if rela_j>=5 & rela_j<=8 
	replace relacion_ci=5 if rela_j==9
	replace relacion_ci=6 if rela_j==10
	label var relacion_ci "Relacion con el Jefe de Hogar"
	label define relacion_ci 1 "Jefe de Hogar" 2 "conyuge" 3 "Hijos" 4 "Otros Parientes" 5 "Otros no Parientes" 6 "Servicio Domestico"
	label value relacion_ci relacion_ci

	**********
	*civil_ci*
	**********
	gen civil_ci=.
	replace civil_ci=1 if civil==5
	replace civil_ci=2 if civil==1 | civil==6
	replace civil_ci=3 if civil==3 | civil==4
	replace civil_ci=4 if civil==2
	label var civil_ci "Estado Civil"
	label define civil_ci 1 "Soltero" 2 "Union Formal o Informal" 3 "Divorciado o Separado" 4 "Viudo"
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
	replace clasehog_ch=2 if (nhijos_ch>0 | nconyuges_ch>0) & (notropari_ch==0 & notronopari_ch==0)
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
	by idh_ch, sort: egen nmiembros_ch=sum(relacion_ci>=1 & relacion_ci<=4)
	label variable nmiembros_ch "Numero de familiares en el hogar"

	*****************
	***nmayor21_ch***
	*****************
	by idh_ch, sort: egen nmayor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=21)
	label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

	*****************
	***nmenor21_ch***
	*****************
	by idh_ch, sort: egen nmenor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<21)
	label variable nmenor21_ch "Numero de familiares menores a 21 anios"

	*****************
	***nmayor65_ch***
	*****************
	by idh_ch, sort: egen nmayor65_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=65)
	label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

	****************
	***nmenor6_ch***
	****************
	by idh_ch, sort: egen nmenor6_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<6)
	label variable nmenor6_ch "Numero de familiares menores a 6 anios"

	****************
	***nmenor1_ch***
	****************
	by idh_ch, sort: egen nmenor1_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<1)
	label variable nmenor1_ch "Numero de familiares menores a 1 anio"

	****************
	***miembros_ci***
	****************
	gen miembros_ci=(relacion_ci<5)
	label variable miembros_ci "Numero de miembros del hogar"


*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************

	***************
	****afro_ci****
	***************
	gen afro_ci=(inlist(ch308,1,2)==1) if ch308!=.

	
	***************
	*****ind_ci****
	***************
	gen ind_ci=(inlist(ch308,1,3,4,5,6,7,8,9)==1) if ch308!=.
	
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
	replace dis_ci = 1 if ch307 != 7 & ch307 != 8 & ch307 != 9 
	replace dis_ci = 0 if ch307 == 7 | ch307 == 8 | ch307 == 9 
	
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
	gen byte HND_dis_ci = dis_ci



************************************
*** VARIABLES DEL MERCADO LABORAL***
************************************

****************
****condocup_ci*
****************
/*
gen condocup_ci=condact
replace condocup_ci=4 if edad_ci<10
label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 10" 
label value condocup_ci condocup_ci
*/
* Comprobacion con variables originales.  Se considera ocupado a quienes estan en trabajos no remunerados. 5/28/2014 MGD
* La edad minima de la encuesta se cambia a 5 anios.

g condocup_ci=.
replace condocup_ci=1 if condact==1
replace condocup_ci=2 if condact==2
replace condocup_ci=3 if condact==3
replace condocup_ci=4 if edad_ci<15

label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci  1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 10" 
label value condocup_ci condocup_ci

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

	*******************
	***categoinac_ci***
	*******************
	gen categoinac_ci =1 if ((ca514 ==1 | ca514==2) & condocup_ci==3)
	replace categoinac_ci = 2 if  (ca514==4 & condocup_ci==3)
	replace categoinac_ci = 3 if  (ca514==5 & condocup_ci==3)
	replace categoinac_ci = 4 if  ((inlist(ca514,3,6,7,8,9,97)) & condocup_ci==3)
	label var categoinac_ci "Categoría de inactividad"
	label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros" 
	label value categoinac_ci categoinac_ci

	*************
	*nempleos_ci*
	*************
	gen nempleos_ci= .
	replace nempleos_ci = 1 if ca519==1 & emp_ci ==1
	replace nempleos_ci = 2 if ca519>1 & emp_ci ==1 & ca519 != . 
	replace nempleos_ci=. if emp_ci==0

	***************
	*antiguedad_ci*
	***************
	generat antiguedad_ci=.
	label var antiguedad_ci "Antiguedad en la Ocupacion Actual (en anios)"

	*************
	*cesante_ci* 
	*************
	gen cesante_ci=1 if ca517==1 & condocup_ci==2
	replace cesante_ci=0 if ca517==2 & condocup_ci==2
	label var cesante_ci "Desocupado - definicion oficial del pais"	

	************
	*durades_ci*
	************
	gen durades_ci=.
	replace durades_ci=ca516tiempo/30   if ca516dsm==1
	replace durades_ci=ca516tiempo/4.3  if ca516dsm==2
	replace durades_ci=ca516tiempo      if ca516dsm==3
	label var durades "Duracion del Desempleo (en meses)


	/**************************
					  COPIAR DESDE AQUI
					  ***********************************/ 
				
	*************
	*horaspri_ci*
	*************
	egen horas_trabpri=rowtotal(oc_605_lunes oc_605_martes oc_605_miercoles oc_605_jueves oc_605_viernes oc_605_sabado oc_605_domingo) if condocup_ci==1, m
	
	gen horaspri_ci=horas_trabpri if oc606==3
	replace horaspri_ci=horas_trabpri+oc607 if oc606==1
	replace horaspri_ci=horas_trabpri-oc607 if oc606==2
	replace horaspri_ci=0 if oc606==4
	replace horaspri_ci=0 if horaspri_ci<0 //Reemplazamos algunos valores 
	replace horaspri_ci = . if horaspri_ci>168
	
	************
	*horastot_ci
	************
	egen horas_trabsec=rowtotal(oc_605_lunes1 oc_605_martes1 oc_605_miercoles1 oc_605_jueves1 oc_605_viernes1 oc_605_sabado1 oc_605_domingo1) if condocup_ci==1 & nempleos_ci>1, m
	
	gen horassec_ci=horas_trabsec if oc6061==3
	replace horassec_ci=horas_trabsec+oc6071 if oc6061==1
	replace horassec_ci=horas_trabsec-oc6071 if oc6061==2
	replace horassec_ci=0 if oc6061==4
	replace horassec_ci=0 if horassec_ci<0	
	
	egen horastot_ci = rsum(horaspri_ci horassec_ci), missing
	replace horastot_ci = . if horastot_ci>168
	
	***********
	*subemp_ci*
	***********
	gen subemp_ci=.
	replace subemp_ci=(horaspri_ci<=30 & ca522==1 & ca523==1) if condocup_ci==1
	label var subemp_ci "Trabajadores subempleados"

	***************
	*tiempoparc_ci*
	***************
	gen tiempoparc_ci=.
	replace tiempoparc_ci=(horaspri_ci<=30 & ca522==2) if condocup_ci==1
	label var tiempoparc_ci "Trabajadores a medio tiempo"

	**************
	*categopri_ci*
	**************
	gen categopri_ci=.
	replace categopri_ci=1 if inlist(oc609,6) & condocup_ci==1
	replace categopri_ci=2 if inlist(oc609,7) & condocup_ci==1
	replace categopri_ci=3 if inlist(oc609,1,2,3,4,5,9,10,11) & condocup_ci==1
	replace categopri_ci=4 if inlist(oc609,8) & condocup_ci==1
	label var categopri_ci "Categoria ocupacional actividad principal"
	label define categopri_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
	label value categopri_ci categopri_ci

	****************
	* categosec_ci *
	****************
	gen categosec_ci=.
	replace categosec_ci=1 if inlist(oc6091,6) & condocup_ci==1
	replace categosec_ci=2 if inlist(oc6091,7) & condocup_ci==1
	replace categosec_ci=3 if inlist(oc6091,1,2,3,4,5,9,10,11) & condocup_ci==1
	replace categosec_ci=4 if inlist(oc6091,8) & condocup_ci==1
	label var categosec_ci "Categoria ocupacional actividad secundaria"
	label define categosec_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
	label value categosec_ci categosec_ci

	*********
	*rama_ci*
	*********
	*Se toma como referencia: https://ine.gob.hn/v4/wp-content/uploads/2023/04/Clasificador-de-Actividades-Economicas-Honduras-2018_PDF-1.pdf
	gen rama_ci=.
	replace  rama_ci=1 if ramaop==1 & emp_ci==1
	replace  rama_ci=2 if ramaop==2 & emp_ci==1
	replace  rama_ci=3 if ramaop==3 & emp_ci==1
	replace  rama_ci=4 if ramaop==4 | ramaop==5  & emp_ci==1
	replace  rama_ci=5 if ramaop==6 & emp_ci==1
	replace  rama_ci=6 if ramaop==7 | ramaop==9  & emp_ci==1
	replace  rama_ci=7 if ramaop==8 | ramaop==10 & emp_ci==1
	replace  rama_ci=8 if inrange(ramaop,11,14)  & emp_ci==1
	replace  rama_ci=9 if inrange(ramaop,15,21)  & emp_ci==1
	label var rama_ci "Rama de actividad"
	label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras" 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento" 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
	label val rama_ci rama_ci

	*************
	*spublico_ci*
	*************
	gen spublico_ci=1 if inlist(oc609,1,4,9) & emp_ci==1
	replace spublico_ci=0 if inlist(oc609,2,3,5,6,7,8,10,11) & emp_ci==1

	*************
	*tamemp_ci
	*************
	* Honduras. Pequeña 1-5, Mediana 6-50, Grande Más de 50.
	gen tamemp_ci = 1 if (oc_608_cuantas>=1 & oc_608_cuantas<=5) & emp_ci==1
	replace tamemp_ci = 2 if (oc_608_cuantas>=6 & oc_608_cuantas<=50) & emp_ci==1
	replace tamemp_ci = 3 if (oc_608_cuantas>50) & oc_608_cuantas!=. & emp_ci==1
	replace tamemp_ci=. if  oc_608_cuantas>=99999
	label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
	label value tamemp_ci tamemp_ci
	label var tamemp_ci "Tamaño de empresa"

	****************
	*cotizando_ci***
	****************
	gen cotizando_ci=.
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0"No cotiza" 1"Cotiza a la SS" 
	label value cotizando_ci cotizando_ci

	****************
	*instcot_ci*****
	****************
	gen instcot_ci=.

	****************
	*afiliado_ci****
	****************
	gen afiliado_ci=.
	label var afiliado_ci "Afiliado a la Seguridad Social"

	*******************
	**** formal_ci ****
	*******************
	gen byte formal_ci=.

	*************
	*desalent_ci*
	*************
	gen desalent_ci=.
	replace desalent_ci=1 if ca513==6 & condocup_ci==3
	replace desalent_ci=0 if ca513!=6 & condocup_ci==3

	*****************
	*tipocontrato_ci*
	*****************
	gen tipocontrato_ci=.
	label var tipocontrato_ci "Tipo de contrato segun su duracion"
	label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
	label value tipocontrato_ci tipocontrato_ci

	**********
	*ocupa_ci*
	**********
		gen ocupa_ci=.
		replace ocupa_ci=1 if ocupaop==2 & emp_ci==1
		replace ocupa_ci=2 if ocupaop==1 & emp_ci==1
		replace ocupa_ci=3 if (ocupaop==3 | ocupaop==4) & emp_ci==1
		replace ocupa_ci=4 if ocupaop==5 & emp_ci==1
		replace ocupa_ci=5 if ocupaop==7 & emp_ci==1
		replace ocupa_ci=6 if ocupaop==6 & emp_ci==1
		replace ocupa_ci=7 if ocupaop==8 & emp_ci==1
		replace ocupa_ci=8 if ocupaop==10 & emp_ci==1
		replace ocupa_ci=9 if ocupaop==9 & emp_ci==1

		label variable ocupa_ci "Ocupacion laboral"
		label define ocupa_ci 	1"Profesionales y técnicos" ///
								2"Directores y funcionarios superiores" ///
								3"Personal administrativo y nivel intermedio"  ///
								4"Comerciantes y vendedores" ///
								5"Trabajadores en servicios" ///
								6"Trabajadores agrícolas y afines" ///
								7"Obreros no agrícolas, conductores de máquinas y vehículos de transporte y similares" ///
								8"Fuerzas Armadas" ///
								9"Otras ocupaciones no clasificadas en las anteriores"
		label value ocupa_ci ocupa_ci

	
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


************************************
******* VARIABLES DE INGRESO *******
************************************

	***************
	***ylmpri_ci***
	***************
	egen ylmpri_ci=rowtotal(ysmop ycmop), missing
	label var ylmpri_ci "Ingreso Laboral Monetario de la Actividad Principal"

	************
	*ylnmpri_ci*
	************
	egen ylnmpri_ci=rowtotal(yseop yceop), missing
	label var ylnmpri_ci "Ingreso Laboral No Monetario de la Actividad Principal"
		
	***********
	*ylmsec_ci*
	***********
	egen ylmsec_ci=rowtotal(ysmos ycmos), missing
	label var ylmsec_ci "Ingreso Laboral Monetario de la Actividad Secundaria"

	************
	*ylnmsec_ci*
	************
	egen ylnmsec_ci=rowtotal(yseos yceos), missing
	label var ylnmsec_ci "Ingreso Laboral No Monetario de la Actividad Secundaria"

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
	egen ylm_ci= rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
	replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==. & ylmotros_ci==.
	label var ylm_ci "Ingreso laboral monetario total"
	

	*************
	***ylnm_ci***
	*************
	egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
	label var ylnm_ci "Ingreso laboral NO monetario total"  
	
	*************
	***ynlm_ci***
	*************
	gen tc_c1=24.7285 ///24.4859
	
	*1	Pensión  yhpens 
	gen jubi = oih01_lps/3
	gen jubid = (oih01_us*tc_c1)/3     
	*2	Jubilación yhjubi 
	gen pens = oih02_lps/3
	gen pensd = (oih02_us*tc_c1)/3  
	*3	Alquileres yhalqu  
	gen alqui = oih03_lps/3   
	gen alquid = (oih03_us*tc_c1)/3
	*4	Descuentos por la 3a edad 
	gen desc3ed = oih04/3                                    
	*5	Pensión por divorcio 
	gen pendiv= oih05_lps/3 
	gen pendivd= (oih05_us*tc_c1)/3                                               
	*6	Ayudas familiares yhayuf  
	gen ayuf=oih06_lps/3 
	gen ayufd=(oih06_us*tc_c1)/3 
	*especies
	gen ayufes=oih06_lps_esp/3
	gen ayufesd= (oih06_us_esp*tc_c1)/3                                           
	*7	Ayudas particulares  yhayup
	gen ayup= oih07_lps/3
	gen ayupd=(oih07_us*tc_c1)/3
	*especies
	gen ayupes=oih07_lps_esp/3
	gen ayupesd=(oih07_us_esp*tc_c1)/3    
	*8 Alimentacion escolar
	gen alimes=oih08/3
	*9	Bolsón utiles escolares
	gen bolspra=oih09/3
	*10	Uniformes escolares
	gen meresc=oih10/3
	*11	Becas  
	gen beca= oih11/3 
	*12	Remesas del exterior yhreme 
	gen remesa= oih12_lps/3 
	gen remesad=(oih12_us*tc_c1)/3
	*especies
	gen remesp=oih12_lps_esp/3
	gen remespd= (oih12_us_esp*tc_c)/3
	*13 Bono esperanza - discapacidad
	gen bondis= oih13/3
	*14 Bono oro
	gen bonoro=oih14/3 
	*15	Bono tecnologico
	gen bonotec= oih15/3 
	*16	Bono Rosa  
	gen bonorosa= oih16/3 
	*17 y 18: Subsidios de energia y combustible
	egen subsidio_= rowtotal(oih17 oih18), missing
	gen subsidio=subsidio_/3
	drop subsidio_
	*19	Otros programas del gobierno:  
	gen otrospro= oih19_lps/3 
	gen otrosproesp=oih19_lps_esp/3                                                              
	*20 otros       
	gen otros= oih20_lps/3 
	gen otrosesp=oih20_lps_esp/3                                                              

	egen ynlm_ci=rsum(jubi jubid pens pensd alqui alquid desc3ed pendiv pendivd ayuf ayufd ayup ayupd  beca remesa remesad bondis  bonoro bonotec bonorosa subsidio otrospro otros), missing
	label var ynlm_ci "Ingreso No Laboral Monetario"	
	
	**************
	***ynlnm_ci***
	**************
	egen ynlnm_ci=rsum(ayufes ayufesd ayupes ayupesd alimes bolspra meresc remesp remespd otrosproesp otrosesp), missing
	label var ynlnm_ci "Ingreso No Laboral No Monetario" 
	
	**************
	***ytot_ci***
	**************	
	egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), m

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
	
	*****************
	***nrylmpri_ci***
	*****************
	gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1) if emp_ci==1 & categopri_ci<4
	label var nrylmpri_ci "Id no respuesta ingreso de la actividad principal"  

	*******************
	*** nrylmpri_ch ***
	*******************
	bysort idh_ch : egen nrylmpri_ch=max(nrylmpri_ci) if miembros_ci==1, missing 
	label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"

	****************
	*** ylmnr_ch ***
	****************
	by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1, missing 
	replace ylmnr_ch=. if nrylmpri_ch==1
	label var ylmnr_ch "Ingreso laboral monetario del hogar"
	
	***************
	*** ynlm_ch ***
	***************
	by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing 
	label var ynlm_ch "Ingreso no laboral monetario del hogar"

	**************
	***ynlnm_ch***
	**************
	by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing 
	label var ynlnm_ch "Ingreso no laboral no monetario del hogar"

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
	

	****************
	***remesas_ci***
	****************
	egen remesas_ci=rsum(remesa remesad remesp remespd), missing
	label var remesas_ci "Remesas Individuales"

	****************
	***remesas_ch***
	****************
	bys idh_ch: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing
	label var remesas_ch "Remesas mensuales del hogar" 

	*************
	** ypen_ci **
	*************
	egen ypen_ci=rowtotal(jubi jubid pens pensd), missing
	label var ypen_ci "Valor de la pension contributiva"

	*************
	**pension_ci*
	*************
	gen pension_ci=(ypen_ci!=0 & ypen_ci!=.)
	label var pension_ci "1=Recibe pension contributiva"

	*****************
	*** ypensub_ci **
	*****************
	gen ypensub_ci=.
	label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

	***************
	*pensionsub_ci*
	***************
	gen pensionsub_ci=.
	label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

	*************
	**salmm_ci***
	*************
	* HON 2023 Fuente: https://nearshoreamericas.com/honduras-raises-minimum-wage-by-7/
	gen salmm_ci= 12377.73 
	label var salmm_ci "Salario minimo legal"


************************************
****** VARIABLES DE EDUCACION ******
************************************

	*************
	***aedu_ci***
	*************

	*Para quienes no asisten:
	gen aedu_ci=.
	replace aedu_ci=0 if (ed05>=1 & ed05<=3)
	replace aedu_ci=ed08 if ed05==4  & ed08<99
	replace aedu_ci=9+ed08 if ed05==5 & ed08<99 //9 años de basica - ciclo comun
	replace aedu_ci=9+ed08 if ed05==6 & ed08<99 //9 años de basica - ciclo div
	replace aedu_ci=11+ed08 if (ed05==7 |ed05==8 |ed05==9) & ed08<99 // Terciario 
	replace aedu_ci=15+ed08 if (ed05==10) & ed08<99 //Post

	*Para quienes asisten actualmente:
	replace aedu_ci=0 if (ed10>=1 & ed10<=3)
	replace aedu_ci=ed13 - 1 if ed10==4 & ed13<99
	replace aedu_ci=9+ed13 - 1 if ed10==5 //9 años de basica - ciclo comun
	replace aedu_ci=9+ed13 - 1 if ed10==6 //9 años de basica- ciclo div
	replace aedu_ci=11+ed13 - 1 if (ed10==7 | ed10==8 | ed10==9) //Terciario
	replace aedu_ci=15+ed13 - 1 if (ed10==10) & ed13<99 //Post
	
	label var aedu_ci "Años de educacion aprobados"	
		
	***************
	***edupre_ci***
	***************
	g byte edupre_ci=.
	la var edupre_ci "Tiene Educacion preescolar"
	
	**************
	***eduui_ci*** 
	**************
	g byte eduui_ci=(ed07==2 & inrange(ed05,6,8)) // no finalizó estudios
	replace eduui_ci=1 if inrange(ed10,6,8) & eduui_ci==0
	replace eduui_ci=. if aedu_ci==. 
	la var eduui_ci "Universitaria o Terciaria Incompleta"

	**************
	***eduuc_ci*** 
	**************
	g byte eduuc_ci=(ed07==1 & inrange(ed05,6,8))
	replace eduuc_ci=1 if inrange(ed05,9,11) 
	replace eduuc_ci=1 if inrange(ed10,9,10)  & eduuc_ci==0
	replace eduuc_ci=. if aedu_ci==.
	la var eduuc_ci "Universitaria o Terciaria Completa"

	**************
	***eduac_ci***
	**************
	gen byte eduac_ci=.
	replace eduac_ci= 1 if eduui_ci+eduuc_ci==1
	replace eduac_ci= 0 if eduui_ci+eduuc_ci==0
	label variable eduac_ci "Superior universitario vs superior no universitario"

	***************
	***asiste_ci***
	***************
	ge		asiste_ci=.
	replace asiste_ci=1 if ed03==1
	replace asiste_ci=0 if ed03==2
	label var asiste "Personas que actualmente asisten a centros de enseñanza"

	***************
	***edupub_ci*** 
	***************
	gen edupub_ci=.
	replace edupub_ci=1 if inrange(ed14,1,3) & asiste_ci==1
	replace edupub_ci=0 if inrange(ed14,4,9) & asiste_ci==1
	label var edupub_ci "1 = personas que asisten a centros de enseñanza publicos"
	
	***************
	***asipre_ci***
	***************
	gen byte asispre_ci=(ed10==3) if asiste_ci==1 // Asiste a pre-básica
	la var asispre_ci "Asiste a educacion prescolar"	
	

	******************
	***pqnoasis1_ci***
	******************
* pqnoasis1_ci was replaced by razonesnoasis_ci, June 2025 * 

**********************
***razonesnoasis_ci***
**********************
	gen razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(ed04,7,11)
	replace razonesnoasis_ci = 2 if inlist(ed04,3)
	replace razonesnoasis_ci = 3 if inlist(ed04,4,6,10)
	replace razonesnoasis_ci = 4 if inlist(ed04,5)
	replace razonesnoasis_ci = 5 if inlist(ed04,2,8,9,12,13)


	label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
	label value  razonesnoasis_ci razonesnoasis_ci

	***************
	***repite_ci*** 
	***************
	gen repite_ci=.
	label var repite_ci "Personas que han repetido al menos un año o grado"

	******************
	***repiteult_ci*** 
	******************
	gen repiteult_ci=.
	replace repiteult_ci=1 if ed11==1
	replace repiteult_ci=0 if ed11==2
	label var repiteult_ci "Personas que están repetiendo el ultimo grado"



************************************
****** VARIABLES DE VIVIENDA  ******
************************************

	********
	*luz_ch*
	********
	gen luz_ch=1 if inrange(v07,1,2)
	replace luz_ch=0 if inrange(v07,3,8)

	************
	*luzmide_ch*
	************
	gen luzmide_ch=.

	************
	*combust_ch*
	************
	gen combust_ch=1 if inlist(h04,2,3,4)
	replace combust_ch=0 if inlist(h04,1,5,6)

	*************
	** piso_ch **
	*************
	gen piso_ch=.
	replace piso_ch=0 if inlist(v03,7)
	replace piso_ch=1 if inlist(v03,1,2,3,4,5)
	replace piso_ch=2 if inlist(v03,6,8)
	
	label define piso_ch 		0 "No permanentes" ///
								1 "Materiales permanentes" ///
								2 "Otros materiales"
	
	label value piso_ch piso_ch
	
	**************
	** pared_ch **
	**************
	gen pared_ch=.
	replace pared_ch=0 if inlist(v02,7)
	replace pared_ch=1 if inlist(v02,1,2,3,4,5)
	replace pared_ch=2 if inlist(v02,6,8)
	
	label define pared_ch 		0 "No permanentes" ///
								1 "Materiales permanentes" ///
								2 "Otros materiales"
	
	label value pared_ch pared_ch
	
	**************
	** techo_ch **
	**************
	gen techo_ch=.
	replace techo_ch=0 if inlist(v04,8)
	replace techo_ch=1 if inlist(v04,3,4,1,5,9,10)
	replace techo_ch=2 if inlist(v04,6,7,11)
	
	label define techo_ch 		0 "No permanentes" ///
								1 "Materiales permanentes" ///
								2 "Otros materiales"
	
	label value techo_ch techo_ch
	
	**************
	** resid_ch **
	**************
	gen resid_ch=.
	replace resid_ch=0 if inlist(v08,1,2,3)
	replace resid_ch=1 if inlist(v08,4,5,6)
	replace resid_ch=2 if inlist(v08,7)
	
	label define resid_ch 		0 "Recoleccion publica o privada" ///
								1 "Quemados o enterrados" ///
								2 "Tirados en un espacio abierto"
	
	label value resid_ch resid_ch
	
	**************
	** dorm_ch **
	**************
	gen dorm_ch=h09
	replace dorm_ch=. if h09==-2

	**************
	** cuartos_ch **
	**************
	gen cuartos_ch=. // En la encuesta esta la pregunta v09 : Sin incluir baños y cocina, ¿cuántas piezas tiene esta vivienda? y la variable no incluye baños y cocina. Pero no podemos asumir el # de cocinas y baños.  

	**************
	** cocina_ch **
	**************
	gen cocina_ch=.
	replace cocina_ch=1 if h02==1
	replace cocina_ch=0 if inrange(h02,2,5)
	
	**************
	** telef_ch **
	**************
	gen telef_ch2=(h01_7>=1&h01_7!=.)

	**************
	** refrig_ch **
	**************
	gen refrig_ch=(h01_1>=1)

	**************
	** freez_ch **
	**************
	gen freez_ch=.

	**************
	** auto_ch **
	**************
	gen auto_ch=(h01_8>=1)

	**************
	** compu_ch **
	**************
	gen compu_ch=(h01_11>=1&h01_11!=.)

	**************
	** internet_ch **
	**************
	gen internet_ch=(tic03==1 & at05_1==1)
	replace internet_ch=. if (tic03==.|tic03==9) & at05_1==.


	**************
	** cel_ch **
	**************
	gen cel_ch=(tic09==1)

	**************
	** vivi1_ch **
	**************
	gen vivi1_ch=.
	replace vivi1_ch=1 if inlist(v01,1,2,3)
	replace vivi1_ch=2 if inlist(v01,4)
	replace vivi1_ch=3 if inlist(v01,5,6,7)
	
	label define vivi1_ch 		1 "Casa" ///
								2 "Departamento" ///
								3 "Otros tipos"
	
	label value vivi1_ch vivi1_ch
	
	**************
	** vivi2_ch **
	**************
	gen vivi2_ch=1 if inlist(vivi1_ch,1,2)
	replace vivi2_ch=0 if vivi1_ch==3

	**************
	** viviprop_ch **
	**************
	gen viviprop_ch=.
	replace viviprop_ch=1 if inlist(v10,1,6,7)
	replace viviprop_ch=2 if inlist(v10,3)
	replace viviprop_ch=3 if inlist(v10,2)
	replace viviprop_ch=4 if inlist(v10,4,5)
	
	label define viviprop_ch 		1 "Alquilada" ///
									2 "Propia y totalmente pagada" ///
									3 "Propia y en proceso de pago" ///
									4 "Ocupada (propia de facto)"
	
	label value viviprop_ch viviprop_ch
	
	**************
	** vivitit_ch **
	**************
	gen vivitit_ch=.

	**************
	** vivialq_ch **
	**************
	gen vivialq_ch=.

	**************
	** vivialqimp_ch **
	**************
	gen vivialqimp_ch=v11
	replace vivialqimp_ch=. if v11==99999

	
************************************
******   VARIABLES DE WASH    ******
************************************

	****************
	***aguared_ch***
	****************
	generate aguared_ch =.
	replace aguared_ch = 1 if inlist(v05,1) 
	replace aguared_ch = 0 if inrange(v05,2,9) 
	la var aguared_ch "Acceso a fuente de agua por red"

	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch = 0

	*****************
	*aguafuente_ch*
	*****************
    gen aguafuente_ch =.
	replace aguafuente_ch = 1 if inlist(v05,1) & v06<=2
	replace aguafuente_ch = 2 if inlist(v05,4)  | (inlist(v05,1)  &v06>2) 
	replace aguafuente_ch = 6 if inlist(v05,6) 
	replace aguafuente_ch = 7 if inlist(v05,7)
	replace aguafuente_ch = 8 if inlist(v05,5)
	replace aguafuente_ch = 10 if inlist(v05,2,3,8,9) | missing(v05)

	label define aguafuente_ch 		1 "Red de distribución, llave privada" ///
									2 "Llave pública, standpipe" ///
									3 "Agua embotellada" ///
									4 "Pozo protegido" ///
									5 "Agua de lluvia" ///
									6 "Camión, cisterna, pipa" ///
									7 "Otra fuente mejorada no listada" ///
									8 "Cuerpo de agua superficial" ///
									9 "Otra fuente no mejorada" ///
									10 "Pozo, manantial, u otra fuente sin clasificación clara"
	
	label value aguafuente_ch aguafuente_ch
	
	*************
	*aguadist_ch*
	*************
	gen aguadist_ch=.
	replace aguadist_ch= 1 if v06==1
	replace aguadist_ch= 2 if v06==2 | v06==3 
	replace aguadist_ch= 3 if v06 ==4
	
	label define aguadist_ch 		1 "Adentro de la vivienda" ///
									2 "Afuera de la vivienda, pero adentro del terreno" ///
									3 "Afuera de la vivienda y afuera del terreno"
	
	label value aguadist_ch aguadist_ch
	
	**************
	*aguadisp1_ch*
	**************
	gen aguadisp1_ch =9

	**************
	*aguadisp2_ch*
	**************
	gen aguadisp2_ch = 9
	
	*************
	*aguatrat_ch*
	*************
	gen aguatrat_ch = 9

	*************
	*aguamala_ch*  
	*************
	gen aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

	*****************
	*aguamejorada_ch* 
	*****************
	gen aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7

	*****************
	***aguamide_ch***
	*****************
	gen aguamide_ch =.
	label var aguamide_ch "Usan medidor para pagar consumo de agua"

	***********
	* bano_ch *  
	***********
	gen bano_ch=.
	replace bano_ch=0 if inlist(h06,2)
	replace bano_ch=1 if inlist(h07,1)
	replace bano_ch=2 if inlist(h07,2)
	replace bano_ch=3 if inlist(h07,5)
	replace bano_ch=4 if inlist(h07,3)
	replace bano_ch=5 if inlist(h07,4,6,7)
	replace bano_ch=6 if inlist(h07,8)

	label define bano_ch 			0 "Sin instalaciones" ///
									1 "Inodoro a red de desagüe" ///
									2 "Inodoro a fosa séptica" ///
									3 "Letrina mejorada / otra instalación mejorada" ///
									4 "Inodoro/letrina a cuerpo de agua superficial o suelo" ///
									5 "Instalación no mejorada" ///
									6 "Instalación que no se puede clasificar"
	
	label value bano_ch bano_ch
	
	***************
	***banoex_ch***
	***************
	generate banoex_ch=.
	replace banoex_ch = 9 if h06==2
	replace banoex_ch = 1 if h08==1
	replace banoex_ch = 0 if h08==2
	la var banoex_ch "El servicio sanitario es exclusivo del hogar"

	************
	*sinbano_ch*
	************
    gen sinbano_ch =3
	replace sinbano_ch = 0 if bano_ch>0
	label var sinbano_ch "hogares sin acceso a instalaciones propias."

	label define sinbano_ch 		0 "El hogar tiene baño" ///
									1 "No tiene baño y principalmente utiliza instalaciones públicas o las de un vecino o amigo" ///
									2 "No tiene baño y practica defecación al aire libre" ///
									3 "El hogar no tiene baño pero no especifica cuáles alternativas se usa" 
	label value sinbano_ch sinbano_ch
	
	*******************
	* banomejorado_ch *
	*******************
	gen banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

*************************************
****** VARIABLES DE MIGRACION  ******
*************************************

	*******************
	*** migrante_ci ***
	*******************
	gen migrante_ci=.
	label var migrante_ci "=1 si es migrante"

	***********************
	*** migrantiguo5_ci ****
	**********************
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"

	*****************
	*** miglac_ci ***
	*****************
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"


***************************************
*** VARIABLES DE PROTECCION SOCIAL  ***
***************************************

	*************
	*** y_hog ***
	*************
	egen y_hog_ci=rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
	bysort idh_ch : egen y_hog = total(y_hog_ci) if miembros_ci==1
	label var y_hog "Ingreso monetario del hogar"
	
	************
	*** y_pc ***
	************
	gen y_pc=y_hog/nmiembros_ch
	label var y_hog "Ingreso monetario del hogar per capita"	

	****************
	*** y_pc_net ***
	****************
	*Se tomaron en cuenta los bonos de discapacidad, bono oro, bono tecnologico, bono rosa, otros programas del gobierno (efectivo y en especies)
	egen transf_ci = rowtotal(bondis  bonoro  bonotec bonorosa otrospro otrosproesp), missing
	bysort idh_ch : egen ing_ptmc = total(transf_ci)
	gen y_pc_net =  (y_hog - ing_ptmc)/nmiembros_ch
	
	*********************
	** percibe_ptmc_ci **
	*********************
	gen percibe_ptmc_ci = (transf_ci>0)
	
	*********************
	** ptmc_ch **
	*********************
	gen ptmc_ch = (ing_ptmc>0)
	
	********************
	**** mayor64_ci ****
	********************
	gen mayor64_ci=(edad>64 & edad!=.)


	gen pnc_ci = . 
	gen ing_pension = . 

* Fuente externa	
	
*************
** lp_ci ***
*************

gen lp_ci=4931.9 if zona_c==1
replace lp_ci=2538.8 if zona_c==0

*************
**lpe_ci***
*************

gen lpe_ci=.
	
	
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
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch HND_dis_ci /// Diversidad
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
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

compress

saveold "`base_out'", version(12) replace

log close





