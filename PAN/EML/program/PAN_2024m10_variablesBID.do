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

local PAIS PAN
local ENCUESTA EML
local ANO "2024"
local ronda m10

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   

capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Panama
Encuesta: EML
Round: Agosto
Autores: 
Versión 2018:Daniela Zuluaga (DZG) - Email: danielazu@iadb.org, da.zuluaga@hotmail.com
Última versión: Cecilia Giambruno (SCL/EDU) - Enero 2024

							SCL/LMK - IADB
****************************************************************************/
/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:

****************************************************************************/


use `base_in', clear

		**********************************
		***VARIABLES DEL IDENTIFICACION***
		**********************************
		
	****************
	* region_BID_c *
	****************

	gen region_BID_c=1
	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" ///
		3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	************
	* region_c *
	************

	destring prov, replace
	gen region_c=  prov

	label define region_c  ///
	1	"Bocas del Toro" ///
	2	"Coclé" ///
	3	"Colón" ///
	4	"Chiriquí" ///
	5	"Darién" ///
	6	"Herrera" ///
	7	"Los Santos" ///
	8	"Panamá" ///
	9	"Veraguas" ///
	10	"Kuna Yala" ///
	11	"Emberá" ///
	12	"Ngäbe-Buglé"		  
	label value region_c region_c
	label var region_c "División política, provincias (excluye Panamá Oeste)"

	******************************
	*	pais_c
	******************************
	gen str3 pais_c="PAN"
	label var pais_c "Pais"

	******************************
	*	anio_c
	******************************
	gen anio_c=2024
	label var anio_c "Año de la encuesta"

	******************************
	*	mes_c
	******************************
	gen mes_c=10
	label var mes_c "Mes de la encuesta"
	label value mes_c mes_c
	
	******************************
	*	zona_c
	******************************
	encode areareco, gen(area_)
	gen zona_c=0 if area_==1
	replace zona_c=1 if area_==2
	label var zona_c "Zona del pais"
	label define zona_c 1 "Urban" 0 "Rural"
	label value zona_c zona_c

	***************
	***estrato_ci***
	***************
	gen estrato_ci=estra

	***************
	***upm_ci***
	***************
	gen upm_ci=unidad
	
	******************************
	*	idh_ch
	******************************
	sort llave_sec hogar nper
	egen idh_ch = group(llave_sec hogar)
	label var idh_ch "ID del hogar"

	******************************
	*	idp_ci
	******************************

	destring nper, gen (idp_ci)
	label var idp_ci "ID de la persona en el hogar"

	******************************
	*	factor_ci
	******************************

	gen factor_ci= fac15_e   
	label var factor_ci "Factor de expansion del individuo"
	
	******************************
	*	factor_ch
	******************************
	gen factor_ch=fac15_e
	label var factor_ch "Factor de expansion del hogar"
	
		**********************************
		***VARIABLES DEMOGRÁFICAS***
		**********************************
		
	******************************
	*	sexo_ci
	******************************
	destring p2, replace
	gen sexo_ci=p2
	label var sexo_ci "Sexo"
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci

	******************************
	*	edad_ci
	******************************
	gen edad_ci=p3
	label var edad_ci "Edad del individuo"	

	******************************
	*	relacion_ci
	******************************
	gen relacion_ci=.
	replace relacion_ci=1 if p1==1
	replace relacion_ci=2 if p1==2
	replace relacion_ci=3 if p1==3
	replace relacion_ci=4 if p1==4 
	replace relacion_ci=5 if p1==6
	replace relacion_ci=6 if p1==5
	label var relacion_ci "Relacion con el jefe del hogar"
	label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes" 6 "Empleado/a domestico/a"
	label value relacion_ci relacion_ci

	******************************
	*	civil_ci
	******************************

	gen civil_ci=.
	destring p5_conyuga, replace
	replace civil_ci=1 if p5_conyuga==7
	replace civil_ci=2 if p5_conyuga==1 | p5_conyuga==4
	replace civil_ci=3 if p5_conyuga==2 | p5_conyuga==3 | p5_conyuga==5
	replace civil_ci=4 if p5_conyuga==6
	label var civil_ci "Estado civil"
	label define civil_ci 1 "Soltero" 2 "Union formal o informal" 3 "Divorciado o separado" 4 "Viudo"
	label value civil_ci estcivil_ci


	******************************
	*	jefe_ci
	******************************
	gen jefe_ci=(relacion_ci==1)
	label var jefe_ci "Jefe de hogar"
	
	***************************************************************************
	*	nconyuges_ch & nhijos_ch & notropari_ch & notronopari_ch & nempdom_ch
	****************************************************************************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
	
	
	******************************
	*	nhijos_ch
	******************************
	by idh_ch, sort: egen nhijos_ch=sum(relacion_ci==3)
	
	******************************
	*	notropari_ch
	******************************	
	by idh_ch, sort: egen notropari_ch=sum(relacion_ci==4)
	
	******************************
	*	notronopari_ch
	******************************
	by idh_ch, sort: egen notronopari_ch=sum(relacion_ci==5)
	
	******************************
	*	notronopari_ch
	******************************
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
	replace clasehog_ch=2 if nhijos_ch>0 & notropari_ch==0 & notronopari_ch==0 
	replace clasehog_ch=2 if nconyuges_ch>0 & notropari_ch==0 & notronopari_ch==0 
	replace clasehog_ch=3 if ((clasehog_ch ==2 & notropari_ch>0) & notronopari_ch==0) |(notropari_ch>0 & notronopari_ch==0)   
	replace clasehog_ch=4 if (nconyuges_ch>0 | nhijos_ch>0 | (notropari_ch>0 & notropari_ch<.)) & (notronopari_ch>0 & notronopari_ch<.)
	replace clasehog_ch=5 if nhijos_ch==0 & nconyuges_ch==0 & notropari_ch==0 & notronopari_ch>0 & notronopari_ch<.
	label var clasehog_ch "Tipo de hogar"
	label define clasehog_ch 1 "Unipersonal" 2 "Nuclear" 3 "Ampliado" 4 "Compuesto" 5 "Corresidente"
	label value clasehog_ch clasehog_ch	
	
	***************************************************************************************
	*	nmiembros_ch & nmayor21_ch & nmenor21_ch & nmayor65_ch & nmenor6_ch & nmenor1_ch  
	***************************************************************************************
	by idh_ch, sort: egen nmiembros_ch=sum(relacion_ci>=1 & relacion_ci<=4)
	label var nmiembros_ch "Numero de familiares en el hogar"

	by idh_ch, sort: egen nmayor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=21)
	label var nmayor21_ch "Numero de familiares mayores a 21 anios"

	by idh_ch, sort: egen nmenor21_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<21)
	label var nmenor21_ch "Numero de familiares menores a 21 anios"

	by idh_ch, sort: egen nmayor65_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci>=65)
	label var nmayor65_ch "Numero de familiares mayores a 65 anios"

	by idh_ch, sort: egen nmenor6_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<6)
	label var nmenor6_ch "Numero de familiares menores a 6 anios"

	by idh_ch, sort: egen nmenor1_ch=sum((relacion_ci>=1 & relacion_ci<=4) & edad_ci<1)
	label var nmenor1_ch "Numero de familiares menores a 1 anio"
	
	******************************
	*	miembros_ci
	******************************
	gen miembros_ci=(relacion_ci<5)
	label var miembros_ci "Miembro del hogar"	

		**********************************
		***VARIABLES DEL DIVERSIDAD***
		**********************************
	
	******************************
	*	afro_ci
	******************************
	gen afro_ci=.
	destring p4f_afrod, replace
	replace afro_ci=1 if p4f_afrod<8
	replace afro_ci=0 if p4f_afrod==8

	******************************
	*	ind_ci
	******************************
	gen ind_ci=.
	destring p4d_indige, replace
	replace ind_ci=1 if p4d_indige<11
	replace ind_ci=0 if p4d_indige==11

	******************************
	*	noafroind_ci
	******************************
	gen noafroind_ci=.
	replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)	 // Personas que NO se identifican como afro o indígenas
	replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)  // Personas que se identifican como afro o indígenas
	replace noafroind_ci =. if (afro_ci==. & ind_ci==.)
	
	******************************
	*	afro_jefe
	******************************
	gen afro_jefe=afro_ci  if relacion_ci==1
	egen afro_ch  = min(afro_jefe), by(idh_ch) 
	drop afro_jefe

	******************************
	*	ind_jefe
	******************************
	gen ind_jefe= ind_ci  if relacion_ci==1
	egen ind_ch  = min(ind_jefe), by(idh_ch) 
	drop ind_jefe

	******************************
	*	afroind_ano_c
	******************************
	gen afroind_ano_c=2019
** cambia la encuesta pero la pregunta es la misma 


	***************
	*** afroind_ci ***
	***************
	** Para casos que reportan ambas autoidentificaciones, se pondera la afrodesendiente siguendo la forma de reportar en armonizaciones pasadas

	gen afroind_ci=. 
	replace afroind_ci=1 if ind_ci==1 
	replace afroind_ci=2 if afro_ci==1
	replace afroind_ci=3 if noafroind_ci == 1


	***************
	*** afroind_ch ***
	***************
	gen afroind_jefe= afroind_ci if relacion_ci==1
	egen afroind_ch  = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe

	***************
	*** noafroind_ch ***
	***************
	gen noafroind_jefe= noafroind_ci if relacion_ci==1
	egen noafroind_ch  = min(noafroind_jefe), by(idh_ch) 
	drop noafroind_jefe

	*******************
	*** dis_ci ***
	*******************
	destring  p4z1_cami p4z2_usarb p4z3_habl p4z4_enten p4z5_cuid p4z6_ver p4z7_oir, replace
	gen dis_ci= 1 if ((p4z1_cami>1 & p4z1_cami!=.) | (p4z2_usarb>1 & p4z2_usarb!=.) | (p4z3_habl>1 & p4z3_habl!=.) | (p4z4_enten>1 & p4z4_enten!=.) | (p4z5_cuid>1 & p4z5_cuid!=.) | (p4z6_ver>1 & p4z6_ver!=.) | (p4z7_oir>1 & p4z7_oir!=.))
	replace dis_ci=0 if p4z1_cami==1 & p4z2_usarb==1 & p4z3_habl==1 & p4z4_enten==1 & p4z5_cuid==1 & p4z6_ver==1 & p4z7_oir==1

**disWG_ci 
	gen disWG_ci = .  // Inicializa con missing
	replace disWG_ci = 1 if (p4z1_cami > 2 & p4z1_cami != .) | ///
						  (p4z2_usarb > 2 & p4z2_usarb != .) | ///
						  (p4z3_habl > 2 & p4z3_habl != .) | ///
						  (p4z4_enten > 2 & p4z4_enten != .) | ///
						  (p4z5_cuid > 2 & p4z5_cuid != .) | ///
						  (p4z6_ver > 2 & p4z6_ver != .) | ///
						  (p4z7_oir > 2 & p4z7_oir != .)  
	replace disWG_ci = 0 if (p4z1_cami <= 2 & p4z1_cami != .) & ///
						  (p4z2_usarb <= 2 & p4z2_usarb != .) & ///
						  (p4z3_habl <= 2 & p4z3_habl != .) & ///
						  (p4z4_enten <= 2 & p4z4_enten != .) & ///
						  (p4z5_cuid <= 2 & p4z5_cuid != .) & ///
						  (p4z6_ver <= 2 & p4z6_ver != .) & ///
						  (p4z7_oir <= 2 & p4z7_oir != .)  


	*******************
	*** dis_ch ***
	*******************
	egen dis_ch = max(dis_ci), by(idh_ch)
	
	*******************
	*** pan_dis_ci ***
	*******************
	gen pan_dis_ci = dis_ch
	
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***
*******************************************************				

******************************************************************************
*	LABOR MARKET
******************************************************************************

	*************
	*condocup_ci
	*************

	encode desagreg, gen (ocu_desagreg)
	gen condocup_ci=.
	replace condocup_ci=1 if ocu_desagreg==4
	replace condocup_ci=2 if ocu_desagreg==1 
	replace condocup_ci=3 if ocu_desagreg==3 | ocu_desagreg==2    
	replace condocup_ci=4 if edad_ci<10
	label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
	label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor de PET" 
	label value condocup_ci condocup_ci

	*************
	*categoinac_ci
	*************
	gen categoinac_ci= . 
	replace categoinac_ci=1 if (p10_18==11 | p10_18==12) & condocup_ci==3
	replace categoinac_ci=2 if p10_18==13 & condocup_ci==3
	replace categoinac_ci=3 if p10_18==14 & condocup_ci==3
	replace categoinac_ci=4 if (categoinac_ci!=1 & categoinac_ci!=2 & categoinac_ci!=3) & condocup_ci==3

	label var  categoinac_ci "Condición de Inactividad" 
	label define inactivo 1"Pensionado y otros" 2"Estudiante" 3"Hogar" 4"Otros"
	label values categoinac_ci inactivo

	************
	***emp_ci***
	************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	*************
	*cesante_ci* 
	*************
	gen cesante_ci=1 if p26==999 & condocup_ci==2
	replace cesante_ci=0 if p26<999 & condocup_ci==2
	label var cesante_ci "Desocupado - definicion oficial del pais"		

	****************
	***desemp_ci***
	****************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci

	******************************
	*	subemp_ci
	******************************
	gen subemp_ci=.

	******************************
	*	durades_ci
	******************************
	destring p21, replace
	recode p21 298=. 299=.
	gen durades_ci=. 
	replace durades_ci=0 if p21==100
	replace durades_ci=p21-200 if p21<298
	label var durades_ci "Duracion del desempleo en meses"

	*************
	***pea_ci***
	*************
	gen pea_ci=(emp_ci==1 | desemp_ci==1)

	******************************
	*	nempleos_ci
	******************************
	destring p44, replace
	gen nempleos_ci=1     if p44==3
	replace nempleos_ci=2 if p44==1 | p44==2
	label var nempleos_ci "Número de empleos"

	******************************
	*	antiguedad_ci
	******************************
	destring p40_tiempo, replace force

	gen antiguedad_ci = cond(p40_tiempo >= 201 & p40_tiempo <= 299, p40_tiempo - 200, ///
						 cond(p40_tiempo >= 100 & p40_tiempo <= 111, (p40_tiempo - 100) / 12, .))

	******************************
	*	desalent_ci
	******************************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (p10_18 == 10 & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	******************************
	*	horaspri_ci
	******************************
	destring p43, replace
	gen horaspri_ci=p43 if p43>0 & p43<99
	replace horaspri_ci=. if emp_ci==0
	label var horaspri_ci "Hs totales (semanales) trabajadas en act. principal"

	******************************
	*	horastot_ci
	******************************
	destring p48_horas, replace
	egen horastot_ci=rsum(p43 p48_horas) if p48_horas>0 & p48_horas<99, missing
	replace horastot_ci=horaspri_ci if p48_horas==99 | p48_horas==.
	replace horastot_ci=. if (p43==99 | p48_horas==99)| emp_ci==0
	label var horastot_ci "Hs totales (semanales)trabajadas en toda actividad"

	******************************
	*	tiempoparc_ci
	******************************
	gen tiempoparc_ci=.
	label var tiempoparc_ci "Trabajan menos de 30 hs semanales y no quieren trabajar mas"

	******************************
	*	categopri_ci
	******************************
	gen categopri_ci=0     if                      emp_ci==1
	replace categopri_ci=1 if p33==8             & emp_ci==1
	replace categopri_ci=2 if (p33==7 | p33==9)  & emp_ci==1
	replace categopri_ci=3 if (p33>=1 & p33<=6 ) & emp_ci==1
	replace categopri_ci=4 if p33==10            & emp_ci==1
	label var categopri_ci "Categoria ocupacional en la actividad principal"
	label define categopri_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
	label value categopri_ci categopri_ci

	******************************
	*	categosec_ci
	******************************
	destring p46a_otro, replace
	gen categosec_ci=.
	replace categosec_ci=1 if p46a_otro==8             & emp_ci==1
	replace categosec_ci=2 if (p46a_otro==7 | p46a_otro==9)  & emp_ci==1
	replace categosec_ci=3 if (p46a_otro>=1 & p46a_otro<=5 ) & emp_ci==1
	*puse Miembro de una cooperativa de produccion (p33==9)dentro de cuenta propia
	replace categosec_ci=4 if p46a_otro==10            & emp_ci==1
	label define categosec_ci 1 "Patron" 2 "Cuenta Propia" 3 "Empleado" 4 "Familiar no remunerado" 
	label value categosec_ci categosec_ci
	label var categosec_ci "Categoria ocupacional en la actividad secundaria"

	******************************
	*	rama_ci
	******************************

	destring p30reco, replace
	gen rama_ci=. 
	replace rama_ci=1 if (p30reco==1)  & emp_ci==1
	replace rama_ci=2 if (p30reco==2) & emp_ci==1
	replace rama_ci=3 if (p30reco==3) & emp_ci==1 
	replace rama_ci=4 if (p30reco==4 | p30reco==5) & emp_ci==1
	replace rama_ci=5 if (p30reco==6) & emp_ci==1
	replace rama_ci=6 if (p30reco==7 | p30reco==9)& emp_ci==1
	replace rama_ci=7 if (p30reco==8) & p30reco==1
	replace rama_ci=8 if (p30reco==11 | p30reco==12) & emp_ci==1
	replace rama_ci=9 if (p30reco==10 | (p30reco>=13 & p30reco<=21)) & emp_ci==1

	label var rama_ci "Rama actividad principal"
	label define rama_ci 1 "Agricultura, caza, silvicultura y pesca" 2 "Explotación de minas y canteras" 3 "Industrias manufactureras" 4 "Electricidad, gas y agua" 5 "Construcción" 6 "Comercio al por mayor y menor, restaurantes, hoteles" 7 "Transporte y almacenamiento" 8 "Establecimientos financieros, seguros, bienes inmuebles" 9 "Servicios sociales, comunales y personales"
	label values rama_ci rama_ci

	******************************
	*	spublico_ci
	******************************
	gen spublico_ci=0 if emp_ci==1
	replace spublico_ci=1 if p33==1 & emp_ci==1
	replace spublico_ci=. if emp_ci==0
	label var spublico_ci "Trabaja en sector publico"

	*************
	*tamemp_ci
	*************
	destring p31, replace
	gen tamemp_ci=1 if p31==1 & emp_ci==1
	label var  tamemp_ci "Tamaño de Empresa" 
	*Empresas medianas
	replace tamemp_ci=2 if (p31==2 | p31==3 | p31==4  )& emp_ci==1
	*Empresas grandes
	replace tamemp_ci=3 if p31==5  & emp_ci==1
	label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
	label values tamemp_ci tamaño

	****************
	*cotizando_ci***
	****************
	gen cotizando_ci=.
	label var cotizando_ci "Cotizante a la Seguridad Social"

	****************
	*instcot_ci*****
	****************
	gen instcot_ci=.
	label var instcot_ci "Institucion proveedora de la pension - variable original de cada pais" 

	****************
	*afiliado_ci****
	****************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if (inlist(p4, 1, 2) & emp_ci==1)
	replace afiliado_ci = 0 if (p4 > 2 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci

	*******************
	***formal***
	*******************
	gen formal=1 if cotizando_ci==1
	replace formal=1 if afiliado_ci==1 & (cotizando_ci!=1 | cotizando_ci!=0) & condocup_ci==1 & pais_c=="PAN"
	gen byte formal_ci=.
	replace formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
	replace formal_ci=0 if formal_ci==. & (condocup_ci==1 | condocup_ci==2) 
	label var formal_ci "1=afiliado o cotizante / PEA"

	*****************
	*tipocontrato_ci*
	*****************

	gen tipocontrato_ci=.
	replace tipocontrato_ci=1 if (p34==1 | p34==4) & categopri_ci==3
	replace tipocontrato_ci=2 if (p34==2 | p34==3) & categopri_ci==3
	replace tipocontrato_ci=3 if (p34==5 | tipocontrato_ci==.) & categopri_ci==3
	label var tipocontrato_ci "Tipo de contrato segun su duracion"
	label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
	label value tipocontrato_ci tipocontrato_ci

	******************************
	*	ocupa_ci
	******************************
	destring p28reco, replace
	g ocupa_ci=.
	replace ocupa_ci=1 if (p28reco==2 | p28reco==3) & emp_ci==1
	replace ocupa_ci=2 if (p28reco==1) & emp_ci==1
	replace ocupa_ci=3 if (p28reco==4) & emp_ci==1
	replace ocupa_ci=4 if (p28reco==5) & emp_ci==1
	*replace ocupa_ci=5 if (p26reco==5) & emp_ci==1 /*trabajadores de servicios y vendedores están en la misma categoría por lo que lo incluyo en la 4*/
	replace ocupa_ci=6 if (p28reco==6) & emp_ci==1
	replace ocupa_ci=7 if (p28reco==8) & emp_ci==1
	*replace ocupa_ci=8  /*pregunta no incluye categoría de "Fuerzas armadas"*/
	replace ocupa_ci=9 if (p28reco==7 | p28reco==9) & emp_ci==1

	*************
	**pension_ci*
	*************
	egen aux_p=rsum(p56_a p56_b), missing
	destring aux_p, replace
	gen pension_ci=1 if aux_p>0 & aux_p!=. & aux_p!=99999
	recode pension_ci .=0
	label var pension_ci "1=Recibe pension contributiva"

	***************
	*pensionsub_ci*
	***************

	gen pensionsub_ci=.
	label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

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


	******************************************************************************
	*		INCOME
	******************************************************************************
	replace salario="." if salario=="ND"
	replace ingreso="." if ingreso=="ND"

	foreach var of varlist _all {
	qui destring `var', replace
	qui capture recode `var' (99999=.) (999=.) (9999=.) (99998=.) (999998=.) (999999=.) (99999.99 =.) (9999.99=.) (9999999=.)
	}
	******************************
	*	ylmpri_ci 
	******************************
	generat ylmpri_ci=p421 if p421>0 & p421<999998 & categopri_ci==3
	replace ylmpri_ci=p423 if p423>0 & p423<999998 & (categopri_ci==1 | categopri_ci==2) 
	replace ylmpri_ci=0    if categopri==4
	replace ylmpri_ci=.    if emp_ci==0
	label var ylmpri_ci "Ingreso laboral monetario act. principal (mes)"

	******************************
	*	ylnmpri_ci
	******************************
	generat ylnmpri_ci=p422 if p422>0 & p422<999998 & categopri_ci==3
	replace ylnmpri_ci=p424 if p424>0 & p424<999998 & (categopri_ci==1 | categopri_ci==2) 
	replace ylnmpri_ci=0    if categopri==4
	replace ylnmpri_ci=.    if emp_ci==0
	label var ylnmpri_ci "Ingreso laboral no monetario total"

	******************************
	*	ylmsec_ci
	******************************
	gen ylmsec_ci=p49_salari if p49_salari>0 & p49_salari<99999  
	replace ylmsec_ci=. if emp_ci==0
	label var ylmsec_ci "Ingreso laboral monetario act secundaria (mes)"

	****************
	***ylnmsec_ci***
	****************
	g ylnmsec_ci=.
	label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"

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


	******************************
	*	ylm_ci & ylm_ci
	******************************
	egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing
	label var ylm_ci "Ingreso laboral monetario total"

	egen ylnm_ci= rsum(ylnmpri_ci ylnmsec_ci), missing

	* INGRESOS NO LABORALES
	******************************
	*	ynlm_ci
	******************************

	gen jub=p56_a if p56_a>0 & p56_a<999999
	replace p56_c1=. if p56_c1>=99999
	replace p56_c2=. if p56_c2>=99999
	egen ayfam=rsum(p56_c1 p56_c2), missing
	replace ayfam=. if p56_c1==999999 & p56_c2 ==999999 

	gen pension=p56_b if p56_b>0 & p56_b <9999999
	gen alqui=p56_d if p56_d>0 & p56_d<9999999
	gen loter=p56_e if p56_e>0 & p56_e<9999999
	egen becas=rsum(p56_f1 p56_f2 p56_f3 p56_f4), missing

	egen subsidios=rsum(p56_g1 p56_g2 p56_g3 p56_g4 p56_g5 p56_g6), missing
	gen agro_aux=p56_i if p56_i>0 & p56_i<999999
	gen otroy=p56_l if p56_l>0 & p56_l<999999
	gen habit=p56_k if p56_k>0 & p56_k<999999

	egen ynlm_ci=rsum(jub pension ayfam alqui loter becas agro_aux subsidios habit otroy) 
	label var ynlm_ci "Ingreso no laboral monetario(mes)"

	*******************************************************
	*** Ingreso no laboral no monetario (otras fuentes).***
	*******************************************************

	egen ynlnm_ci=rsum(p56_c3 p56_c4 p56_c5 p56_c6 p56_c7 p56_c8), missing
	replace ynlnm_ci=. if  p56_c3==999999 & p56_c4==999999 & p56_c5==999999 & p56_c6==99999 & p56_c7==99999 & p56_c8==99999
	label var ynlnm_ci "Ingreso no laboral no monetario"

	******************************
	*	ylm_ch 
	******************************
	by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
	label var ylm_ch "Ingreso laboral monetario del Hogar-ignora NR"

	******************************
	*	ylnm_ch  
	******************************
	by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
	label var ylnm_ch "Ing laboral no monetario del Hogar - ignora NR" 

	***********************************************************
	*** Ingreso no laboral del Hogar.
	************************************************************
	******************************
	*	ynlm_ch 
	******************************
	by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci
	label var ynlm_ch "Ingreso no laboral monetario del Hogar" 

	by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1, missing
	label var ynlnm_ch "Ingreso no laboral no monetario del Hogar" 

	******************************
	*	ylmhopri_ci 
	******************************
	gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
	label var ylmhopri_ci "Salario monetario de la actividad principal"

	******************************
	*	ylmho_ci 
	******************************
	gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
	label var ylmho_ci "Salario monetario de todas las actividades"


	******************************
	*	nrylmpri_ch
	******************************
	gen nrylmpri_ci=1 if ylmpri_ci==. & emp_ci==1
	replace nrylmpri_ci=. if emp_ci==0
	label var nrylmpri_ci "Identificador de NR de ingreso"

	by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
	replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
	label var nrylmpri_ch "Identificador de hogares donde miembro NS/NR ingreso"

	by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1 & nrylmpri_ch==0, missing

	******************************
	*	remesas_ci & remesas_ch 
	******************************
	gen remesas_ci=.
	gen remesas_ch=.

	*************
	*ypen_ci*
	*************
	gen ypen_ci=aux_p

	label var ypen_ci "Valor de la pension contributiva"

	*****************
	**ypensub_ci*
	*****************
	gen ypensub_ci=p56_g5 if p56_g5>0 & p56_g5<=99999
	label var ypensub_ci "Valor de la pension subsidiada / no contributiva"


		******************************************************************************
		*	EDUCATION
		******************************************************************************

	******************************
	*	aedu_ci
	******************************
	* La pregunta P8 de grado educativo alcanzado se aplica únicamente a mayores de 3 años. La clasificación corresponde al nivel educativo alcanzado (primer dígito) y años aprobados (segundo dígito)

	* Clasificación de nivel educativo
	gen nivel = .
	gen añosaprobados = .

	* Establecemos el nivel y los años aprobados en una sola operación
	replace nivel = floor(p8 / 10) if p8 >= 0 & p8 <= 84
	replace añosaprobados = mod(p8, 10) if p8 >= 10 & p8 <= 84

	* Etiquetas de nivel educativo
	label define nivel 1 "Primaria" 2 "Vocacional" 3 "Secundaria" 4 "Superior no universitaria" 5 "Superior universitaria" 6 "Especialidad (Postgrado)" 7 "Maestría" 8 "Doctorado"
	label values nivel nivel

	* Calculamos aedu_ci basado en las condiciones previas
	gen aedu_ci = .
	replace aedu_ci = 0 if añosaprobados == 0
	replace aedu_ci = añosaprobados + 0 if nivel == 1
	replace aedu_ci = añosaprobados + 6 if nivel == 2 | nivel == 3
	replace aedu_ci = añosaprobados + 12 if nivel == 4 | nivel == 5
	replace aedu_ci = añosaprobados + 16 if nivel == 6 | nivel == 7
	replace aedu_ci = añosaprobados + 18 if nivel == 8

	******************************
	*	eduui_ci
	******************************
	gen eduui_ci = (aedu_ci > 12 & aedu_ci < 16) & nivel == 5
	replace eduui_ci = 1 if (aedu_ci > 12 & aedu_ci < 14) & nivel == 4
	replace eduui_ci = . if aedu_ci == .
	label var eduui_ci "Universitaria o Terciaria Incompleta"

	******************************
	*	eduuc_ci
	******************************
	gen eduuc_ci = 0
	replace eduuc_ci = 1 if (inlist(nivel, 6, 7, 8) | (aedu_ci >= 16 & nivel == 5) | (aedu_ci >= 14 & nivel == 4))
	replace eduuc_ci = . if aedu_ci == .
	label var eduuc_ci "Universitaria o Terciaria Completa"

	******************************
	*	eduac_ci
	******************************
	gen eduac_ci = .
	replace eduac_ci = 1 if inlist(nivel, 5, 6, 7, 8) 
	replace eduac_ci = 0 if nivel == 4
	label var eduac_ci "Educ terciaria academica vs Educ terciaria no academica"

	******************************
	*	edupre_ci
	******************************
	gen edupre_ci=.
	label var edupre_ci "Educacion preescolar"

	******************************
	*	asispre_ci
	******************************
	gen asispre_ci=.
	label var asispre_ci "Asistencia a Educacion preescolar"


	******************************
	*	asiste_ci
	******************************
	gen asiste_ci=(p7==1)
	replace asiste_ci=. if p7==.
	label var asiste "Personas que actualmente asisten a centros de enseñanza"

	******************************
	*	edupub_ci
	******************************
	destring p7_tipo, replace
	gen edupub_ci=.
	replace edupub_ci=1 if p7_tipo==3
	replace edupub_ci=0 if p7_tipo==4
	label var edupub_ci "Personas que asisten a centros de ensenanza publicos"

	**************
	*pqnoasis1_ci*
	**************
	destring p7a_motivo, replace
	gen pqnoasis1_ci = 1 if p7a_motivo==3
	replace pqnoasis1_ci = 2 if p7a_motivo==2
	replace pqnoasis1_ci = 3 if p7a_motivo==7
	replace pqnoasis1_ci = 4 if p7a_motivo==5
	replace pqnoasis1_ci = 5 if p7a_motivo==6 | p7a_motivo==4 | p7a_motivo==11
	replace pqnoasis1_ci = 6 if p7a_motivo==10
	replace pqnoasis1_ci = 7 if p7a_motivo==8
	replace pqnoasis1_ci = 8 if p7a_motivo==1 | p7a_motivo==9
	replace pqnoasis1_ci = 9 if p7a_motivo==12

	label define pqnoasis1 1 "Problemas económicos" 2 "Por trabajo" 3 "Problemas familiares o de salud" 4 "Falta de interés" 5	"Quehaceres domésticos/embarazo/cuidado de niños/as" 6 "Terminó sus estudios" 7	"Edad" 8 "Problemas de acceso"  9 "Otros"
	label value  pqnoasis1_ci pqnoasis1

	drop nivel añosaprobados

******************************************************************************
*	VARIABLES OF HOUSEHOLD INFRAESTRUCTURE 
*****************************************************************************
* NO hay informacion sobre la vivienda 
	gen luz_ch=.

	gen luzmide_ch=.

	gen combust_ch=.

	gen piso_ch=.

	gen pared_ch=.

	gen techo_ch=.

	gen resid_ch=. 

	gen dorm_ch=.

	gen cuartos_ch=.

	gen cocina_ch=.

	gen telef_ch=.

	gen refrig_ch=.

	gen freez_ch=.

	gen auto_ch=.

	gen compu_ch=.

	gen internet_ch=.

	gen cel_ch=.

	gen vivi1_ch=.

	gen vivi2_ch=.

	destring v1_tenenci, replace
	gen viviprop_ch=.
	/*
	0 Alquilada 
	1  Propia y totalmente pagada        
	2  Propia y en proceso de pago
	3  Ocupada (propia de facto)
	*/
	replace viviprop_ch=0 if v1_tenenci==1     //1 alquilada
	replace viviprop_ch=1 if v1_tenenci==3     //3 propia
	replace viviprop_ch=2 if v1_tenenci==2   // 2 hipoteca
	replace viviprop_ch=3 if v1_tenenci==4  // 4 cedida

	gen vivitit_ch=.

	gen vivialq_ch=v1a_pago_m

	gen vivialqimp_ch=.

	*** WASH

	****************
	***aguared_ch***
	****************
	gen aguared_ch=.
	label var aguared_ch "Acceso a una fuente de agua por red"


	*****************
	*aguafconsumo_ch*
	*****************
	gen aguafconsumo_ch =.

	*****************
	*aguafuente_ch*
	*****************
	gen aguafuente_ch =.

	*************
	*aguadist_ch*
	*************
	gen aguadist_ch=.


	**************
	*aguadisp1_ch*
	**************
	gen aguadisp1_ch =9

	**************
	*aguadisp2_ch*
	**************
	gen aguadisp2_ch = .


	*************
	*aguamala_ch*  
	*************
	gen aguamala_ch =.

	*****************
	*aguamejorada_ch*  
	*****************
	gen aguamejorada_ch =.

	*****************
	***aguamide_ch***
	*****************
	gen aguamide_ch=.
	label var aguamide_ch "Usan medidor para pagar consumo de agua"

	*****************
	*bano_ch         *  
	*****************
	gen bano_ch=.

	***************
	***banoex_ch***
	***************
	gen banoex_ch=.

	*****************
	*banomejorado_ch*
	*****************
	gen banomejorado_ch=. 

	************
	*sinbano_ch*
	************
	gen sinbano_ch =.

	*************
	*aguatrat_ch*
	*************
	gen aguatrat_ch =.

	******************************
	*** VARIABLES DE MIGRACION ***
	******************************

	*******************
	*** migrante_ci ***
	*******************
	
	destring p5a_codigo, replace
	gen migrante_ci=0 if p5a_codigo==001
	replace migrante_ci=1 if p5a_codigo!=001
	
	label var migrante_ci "=1 si es migrante"
	
	**********************
	*** migrantiguo5_ci ***
	**********************
	destring p5b_anio, replace
	gen migrantiguo5_ci=1 if migrante_ci==1 & p5b_anio>=2018
	replace migrantiguo5_ci=0 if migrante_ci==1 & p5b_anio<2018
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
		
	**********************
	*** miglac_ci ***
	**********************
	
	gen miglac_ci = inlist(p5a_codigo, 107, 211, 212, 213, 214, 217, 218, 232, 233, 234, 235, 242, 243, 244, 249, 311, 312, 313, 314, 321, 331, 333, 341, 343, 351, 353, 361, 381)  
	replace miglac_ci = 0 if miglac_ci ==. & migrante_ci == 1  
	replace miglac_ci = . if p5a_codigo ==1
	label var miglac_ci "=1 si es migrante proveniente de un país LAC"  

	******************************
	*** VARIABLES DE PROTECCIÓN SOCIAL ***
	******************************

*****Miembros del hogar (incluyendo los no parientes - para cálculos SPH)******
** Se eliminan 3 hogares sin ID
	**********************
	*** nmiembros_sph_ch ***
	**********************
	drop if missing(idh_ch) | missing(idp_ci)
	isid idh_ch idp_ci
	gen x=1
	bys idh_ch: egen nmiembros_sph_ch = sum(x)

	**********************
	*** y_hog_ci ***
	**********************
******Ingreso del hogar******
	egen y_hog_ci  = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
	**********************
	*** y_hog_ch ***
	**********************
	bys idh_ch: egen y_hog_ch  = sum(y_hog_ci)

**Programas Seleccionados: Transferencia monetaria condicionada; SENAPAN; Beca Universal
	**********************
	*** ptmc_ci ***
	**********************
	gen ptmc_ci = (p56_g1 != . | p56_g2 != . | p56_f1 != .| p56_f2 != .)
	bys idh_ch: egen ptmc_ch = max(ptmc_ci)

		**********************
	*** ing_ptmc_ci ***
	**********************
	egen ing_ptmc_ci= rowtotal(p56_g1 p56_g2 p56_f1 p56_f2), m
	bys idh_ch: egen ing_ptmc_ch= sum(ing_ptmc_ci)

		**********************
	*** y_pc_net_ch ***
	**********************
	gen y_pc_net_ch = (y_hog_ch - ing_ptmc_ch) / nmiembros_sph_ch
	replace y_pc_net_ch = y_hog_ch / nmiembros_sph_ch if missing(ing_ptmc_ch)

			**********************
	*** pnc_elegible_ci ***
	**********************
	gen pnc_elegible_ci =(edad_ci>64 & edad_ci!=.)

				**********************
	*** pnc_ci ***
	**********************
	gen pnc_ci = (p56_g5==120 & pnc_elegible_ci==1)
	**********************
	*** pnc_ch ***
	**********************
	bys idh_ch: egen pnc_ch = max(pnc_ci)

				**********************
	*** ing_pnc_ci ***
	**********************
	gen ing_pnc_ci= p56_g5 
	**********************
	*** ing_pnc_ch ***
	**********************	
	bys idh_ch: egen ing_pnc_ch= sum(ing_pnc_ci)


** Angel guardian (discapacidad)
	**********************
	*** potrot_ci ***
	**********************	
	gen potrot_ci = (p56_g6==80)
	
	**********************
	*** potrot_ch ***
	**********************	
	bys idh_ch: egen potrot_ch = max(potrot_ci)
	
	**********************
	*** ing_otrot_ci ***
	**********************	
	gen ing_otrot_ci= p56_g6
	
	**********************
	*** ing_otrot_ch ***
	**********************	
	bys idh_ch: egen ing_otrot_ch= sum(ing_otrot_ci)

	**********************
	*** pcasht_ch ***
	**********************
	gen pcasht_ch = (ptmc_ch==1 | pnc_ch==1 | potrot_ch==1)


	******************************
	*** VARIABLES DE REFERENCIA EXTERNA ***
	******************************
* Fuente oficial desagrega a multiples niveles https://www.gacetaoficial.gob.pa/pdfTemp/29446_C/89257.pdf
** LMK sugiere tomar de referencia valor nacional en prensa:https://ndmarketingdigital.com/cuanto-es-el-salario-minimo-en-panama-en-el-2023/
	*********
	*salmm_ci***
	*********
	gen salmm_ci= 850 
	label var salmm_ci "Salario minimo legal"


	*********
	*lp_ci***
	*********
	*** https://www.mef.gob.pa/wp-content/uploads/2024/10/Pobreza-y-distribucion-del-ingreso-de-los-hogares-Anos-2022-y-2023.pdf

	gen lp_ci = 113.03 if zona_c==0
	replace lp_ci =149.96 if zona_c==1

	label var lp_ci "Linea de pobreza oficial del pais (mensual)"

	*********
	*lpe_ci***
	*********
	gen lpe_ci =64.54 if zona_c==0
	replace lpe_ci =75.84 if zona_c==1
	label var lpe_ci "Linea de indigencia oficial del pais (mensual)"
	
	*********
	*ytot_ci***
	*********	
	egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi	

/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

*_____________________________________________________________________________________________________*


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
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch   /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa

compress

foreach i of varlist _all {
local longlabel: var label `i'
local shortlabel = substr("`longlabel'",1,79)
label var `i' "`shortlabel'"
}

saveold "`base_out'", replace v(12)


log close



