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

local PAIS PER
local ENCUESTA ENAHO
local ANO "2023"
local ronda a 
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

*local base_in  = "C:\Users\maytes\OneDrive - Inter-American Development Bank Group\Documents\SCL Data\Armonizacion Peru 2023\\`PAIS'_`ANO'`ronda'.dta"
                        
capture log close
log using "`log_file'", replace 


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Perú
Encuesta: ENAHO
Round: a

****************************************************************************/

use `base_in', clear

/****** Variables de identificación  ******/

	**********
	***anio***
	**********
		gen anio_c=2023
		label variable anio_c "Anio de la encuesta"

	*********
	***mes***
	*********
		tostring fecent, replace 
		gen mes_c=real(substr(fecent,5,2))
		label variable mes_c "Mes de la encuesta"


	************
	****pais****
	************
		gen str3 pais_c="PER"
		label variable pais_c "Pais"

	************************
	*** region según BID ***
	************************
		gen region_BID_c=3 
		label var region_BID_c "Regiones BID"
		label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
		label value region_BID_c region_BID_c
		
	***************
	***region_c ***
	***************
		gen region_c=real(substr(ubigeo,1,2))
		label define region_c ///
		1"Amazonas"	          ///
		2"Ancash"	          ///
		3"Apurimac"	          ///
		4"Arequipa"	          ///
		5"Ayacucho"	          ///
		6"Cajamarca"	      ///
		7"Callao"	          ///
		8"Cusco"	          ///
		9"Huancavelica"	      ///
		10"Huanuco"	          ///
		11"Ica"	              ///
		12"Junin"	          ///
		13"La libertad"	      ///
		14"Lambayeque"	      ///
		15"Lima"	          ///
		16"Loreto"	          ///
		17"Madre de Dios"	  ///
		18"Moquegua"	      ///
		19"Pasco"	          ///
		20"Piura"	          ///
		21"Puno"	          ///
		22"San Martín"	      ///
		23"Tacna"	          ///
		24"Tumbes"	          ///
		25"Ucayali"	
		label value region_c region_c
		label var region_c "division politico-administrativa, departamento"

	**********
	***zona***
	**********
		* SGR comment: Cambió la clasificación.
		/*
		estrato:

		Área Urbana:	
			1	De 500 000 o más habitantes
			2	De 100 000 a 499 999 habitantes
			3	De 50 000 a 99 999 habitantes
			4	De 20 000 a 49 999 habitantes
			5	De 2 000 a 19 999 habitantes

		Area Rural:	 
			6	De 500 a 1 999 habitantes
			7	Área de empadronamiento rural	-	aer	compuesto
			8	Área de empadronamiento rural	-	aer	simple
		*/


		gen byte zona_c= 0 if estrato>=6
		replace  zona_c= 1 if estrato<6

		label variable zona_c "Zona del pais"
		label define zona_c 1 "Urbana" 0 "Rural"
		label value zona_c zona_c


	***************
	***estrato_ci***
	***************
		gen estrato_ci=estrato

	***************
	***upm_ci***
	***************
		gen upm_ci=conglome

	***************
	****idh_ch*****
	***************
		sort conglome vivienda hogar 
		cap egen idh_ch= group(conglome vivienda hogar)
		label variable idh_ch "ID del hogar"
tostring idh_ch, replace


	*************
	*****idp_ci****
	**************
		gen idp_ci = codperso
		label variable idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


	***************
	***factor_ch***
	***************
		gen factor_ch= factor07
		label variable factor_ch "Factor de expansion del hogar"

	***************
	***factor_ci***
	***************
		gen factor_ci=facpob07
		label variable factor_ci "Factor de expansion del individuo"

		

/****** Variables demográficas  ******/

	**********
	***sexo***
	**********
		gen sexo_ci=p207
		label define sexo_ci 1 "Hombre" 2 "Mujer"
		label value sexo_ci sexo_ci
	

	**********
	***edad***
	**********
		gen edad_ci=p208a
		*Add SGR Julio 2020
		replace edad_ci=. if edad_ci==99
		label variable edad_ci "Edad del individuo"
	
	*****************
	***relacion_ci***
	*****************

	/*
	p203:
			   0 panel
			   1 jefe/jefa
			   2 esposo/esposa
			   3 hijo/hija
			   4 yerno/nuera
			   5 nieto
			   6 padres/suegros
			   7 otros parientes
			   8 trabajador hogar
			   9 pensionista
			  10 otros no parientes
			  11 Hermano(a)
	*/

		gen relacion_ci=.
		replace relacion_ci = 1 if p203 == 1
		replace relacion_ci = 2 if p203 == 2
		replace relacion_ci = 3 if p203 == 3
		replace relacion_ci = 4 if p203 >= 4 & p203 <= 7 | p203 == 11
		replace relacion_ci = 5 if p203 == 9 | p203 == 10
		replace relacion_ci = 6 if p203 == 8

		label variable relacion_ci "Relacion con el jefe del hogar"
		label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes"
		label define relacion_ci 6 "Empleado/a domestico/a", add

		label value relacion_ci relacion_ci

	*****************
	***civil_ci***
	*****************
		/*
		p209:
				   1 conviviente
				   2 casado (a)
				   3 viudo (a)
				   4 divorciado (a)
				   5 separado (a)
				   6 soltero (a)
		*/

		gen civil_ci=.
		replace civil_ci = 1 if p209 == 6
		replace civil_ci = 2 if p209 == 1 | p209 == 2
		replace civil_ci = 3 if p209 == 4 | p209 == 5
		replace civil_ci = 4 if p209 == 3

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

	****************
	***miembros_ci***
	****************
		gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
		label variable miembros_ci "Miembro del hogar"


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

	***************
	*** afro_ci  **
	***************
		gen byte afro_ci = . 
		replace afro_ci = 1 if inlist(p558c,4)
		replace afro_ci = 0 if inlist(p558c,1,2,3,5,6,7,9)
	

	***************
	*** ind_ci  **
	***************
		gen byte ind_ci = . 
		replace ind_ci = 1 if inlist(p558c,1,2,3,9)
		replace ind_ci = 0 if inlist(p558c,4,5,6,7)
	
	***************
	*** noafroind_ci **
	***************
		gen byte noafroind_ci = . 
		replace noafroind_ci =1 if (afro_ci==0 | ind_ci==0)	 // Personas que NO se identifican como afro o indígenas
		replace noafroind_ci =0 if (afro_ci==1 | ind_ci==1)  // Personas que se identifican como afro o indígenas
		replace noafroind_ci =. if (afro_ci==. & ind_ci==.)
	
	***************
	***afro_ch***
	***************
		gen afro_jefe = afro_ci if relacion_ci == 1
		egen afro_ch = min(afro_jefe), by(idh_ch) 
		drop afro_jefe

	***************
	***ind_ch***
	***************
		gen ind_jefe = ind_ci if relacion_ci == 1
		egen ind_ch = min(ind_jefe), by(idh_ch) 
		drop ind_jefe
		
	***************
	***noafroind_ch***
	***************
		gen noafroind_jefe = noafroind_ci if relacion_ci == 1
		egen noafroind_ch = min(noafroind_jefe), by(idh_ch) 
		drop noafroind_jefe

	***************
	***afroind_ci**
	***************
		gen afroind_ci =. 
		replace afroind_ci = 1 if ind_ci==1
		replace afroind_ci = 2 if afro_ci==1
		replace afroind_ci = 3 if noafroind_ci==1


	***************
	***afroind_ch***
	***************
		gen afroind_jefe = afroind_ci if relacion_ci == 1
		egen afroind_ch = min(afroind_jefe), by(idh_ch) 
		drop afroind_jefe

	*******************
	***dis_ci***
	*******************
		gen dis_ci =.
		replace dis_ci = 1 if (p401h1 == 1 | p401h2 == 1 | p401h3 == 1 | p401h4 == 1 | p401h5 == 1) 
		replace dis_ci = 0 if (p401h1 == 2 & p401h2 == 2 & p401h3 == 2 & p401h4 == 2 & p401h5 == 2) 
		
	*******************
	***disWG_ci***
	*******************
		gen disWG_ci =.
	
	*******************
	***disWG_ci***
	*******************
		gen PER_dis_ci =dis_ci
		
	*******************
	***dis_ch***
	*******************
		bysort idh_ch : egen dis_ch = max(dis_ci)

	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c=2017


/****** Variables laborales ******/

	****************
	****condocup_ci*
	****************
	gen byte condocup_ci = .
	replace condocup_ci = 1 if p501==1 | p502==1 | p503==1    //Ocupados
	replace condocup_ci = 2 if p501==2 & p502==2 & p503==2    //Desocupados
	replace condocup_ci = 3 if condocup_ci == 2 & ( p5041==2 & p5042==2 & p5043==2 & p5044==2 & p5045==2 & p5046==2 & p5047==2 & p5048==2 & p5049==2 & p50410==2 & p50411==2 ) //Inactivos
	replace condocup_ci = 4 if edad_ci<14 //Según la encuesta, las preguntas sobre ocupación se hacen a personas de 14 años y más de edad
	label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"
	label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor de PET"
	label value condocup_ci condocup_ci

		/*
		Alternativa 2: Revisar conceptos de ocupado de INEI Peru: https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1676/06.pdf

		g condocup_ci1=.
		replace condocup_ci1=1 if p501==1 | p502==1 | p503==1 | p5041==1 | p5042==1 | p5043==1 | p5044==1 | p5045==1 | p5046==1 | p5047==1 | p5048==1 | p5049==1 | p50410==1 | p50411==1 
		replace condocup_ci1=2 if condocup_ci1!=1 & (p545==1 |  p546<=2)
		recode condocup_ci1 .=3 if edad_ci>=14
		recode condocup_ci1 .=4 if edad_ci<14
		*/

	****************
	**categoinac_ci*
	****************
		gen categoinac_ci = .
		replace categoinac_ci = 1 if (p546 == 6 & condocup_ci==3) //Jubilado o Pensionado
		replace categoinac_ci = 2 if (p546 == 4 & condocup_ci == 3) //Estudiante
		replace categoinac_ci = 3 if (p546 == 5 & condocup_ci == 3) //Quehaceres domesticos
		replace categoinac_ci = 4 if ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3) // Otros
		label var categoinac_ci "Categoría de inactividad"
		label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"
		label value categoinac_ci categoinac_ci

	************/
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
		gen cesante_ci=0 if condocup_ci==2
		replace cesante_ci=1 if p552==1 & condocup_ci==2
		label var cesante_ci "Desocupado - definicion oficial del pais"

	****************
	***desemp_ci***
	****************
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de 		la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci

	*****************
	***horaspri_ci***
	*****************
		gen horaspri_ci=p513t 
		replace horaspri_ci=. if emp_ci~=1

	***************
	***subemp_ci***
	***************
		gen subemp_ci=0
		replace subemp_ci=1 if horaspri_ci<=30 & p521==1 & p521a==1 & emp_ci==1 

	****************
	***durades_ci***
	****************
		gen durades_ci=p551/4.3 /* calculo sin filtros if desemp_ci==1*/


	*************
	***pea_ci***
	*************
		gen pea_ci=(emp_ci==1 | desemp_ci==1)


	*****************
	***nempleos_ci***
	*****************
	gen nempleos_ci=.
	replace nempleos_ci=1 if emp_ci==1
	replace nempleos_ci=2 if emp_ci==1 & p514==1
	replace nempleos_ci=2 if emp_ci==1 & p514==2 & (p5151==1 | p5152==1 | p5153==1 | ///
			p5154==1 | p5155==1 | p5156==1 | p5157==1 | p5158==1 | p5159==1 | p51510==1 | ///
			p51511==1)

	*******************
	***antiguedad_ci***
	*******************
		gen anios_ant=p513a1
		gen meses_ant=p513a2/12

		egen antiguedad_ci = rsum(anios_ant meses_ant)
		replace antig=. if anios_ant==. & meses_ant==.

	*****************
	***desalent_ci***
	*****************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (p545 == 2 & (p549 == 1 | p549 == 2) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci == 3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	*****************
	***horastot_ci***
	*****************
		egen horastot_ci=rsum(horaspri_ci p518)
		replace horastot_ci=. if horaspri_ci==. & p518==.
		replace horastot_ci=. if emp_ci~=1

	*******************
	***tiempoparc_ci***
	*******************
		gen tiempoparc_ci=0
		replace tiempoparc_ci=1 if (horaspri_ci>0 & horaspri_ci<30) & p521==2 & emp_ci==1
		replace tiempoparc_ci=. if emp_ci==0

	******************
	***categopri_ci***
	******************
		gen categopri_ci=.
		replace categopri_ci=0 if p507==7
		replace categopri_ci=1 if p507==1
		replace categopri_ci=2 if p507==2 
		replace categopri_ci=3 if p507==3 | p507==4 | p507==6 
		replace categopri_ci=4 if p507==5 

		label define categopri_ci 0 "Otra clasificación" 1"Patron" 2"Cuenta propia" 
		label define categopri_ci 3"Empleado" 4" No remunerado", add
		label value categopri_ci categopri_ci
		label variable categopri_ci "Categoria ocupacional trabajo principal"

	******************
	***categosec_ci***
	******************
		gen categosec_ci=.
		replace categosec_ci=0 if p517==7
		replace categosec_ci=1 if p517==1
		replace categosec_ci=2 if p517==2 
		replace categosec_ci=3 if p517==3 | p517==4 | p517==6
		replace categosec_ci=4 if p517==5 

		label define categosec_ci 0 "Otra clasificación" 1"Patron" 2"Cuenta propia" 
		label define categosec_ci 3"Empleado" 4 "No remunerado" , add
		label value categosec_ci categosec_ci
		label variable categosec_ci "Categoria ocupacional trabajo secundario"

	*************
	***rama_ci***
	*************
		gen rama_ci=.
		replace rama_ci=1 if (p506>=111 & p506<=502) & emp_ci==1
		replace rama_ci=2 if (p506>=1010 & p506<=1429) & emp_ci==1
		replace rama_ci=3 if (p506>=1511 & p506<=3720) & emp_ci==1
		replace rama_ci=4 if (p506>=4010 & p506<=4100) & emp_ci==1
		replace rama_ci=5 if (p506>=4510 & p506<=4550) & emp_ci==1
		replace rama_ci=6 if (p506>=5010 & p506<=5520) & emp_ci==1 
		replace rama_ci=7 if (p506>=6010 & p506<=6420) & emp_ci==1
		replace rama_ci=8 if (p506>=6511 & p506<=7020) & emp_ci==1
		replace rama_ci=9 if (p506>=7111 & p506<=9900) & emp_ci==1

		label var rama_ci "Rama de actividad"
		label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
		label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
		label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
		label val rama_ci rama_ci

	*****************
	***spublico_ci***
	*****************
		gen spublico_ci=(p510==1 | p510==2 | p510==3)
		replace spublico_ci=. if emp_ci~=1

	*************
	*tamemp_ci***
	*************
		gen tamemp_ci=1 if p512b>=1 &  p512b<=5 
		label var  tamemp_ci "Tamaño de Empresa" 
		*Empresas medianas
		replace tamemp_ci=2 if p512b>=6 &  p512b<=50
		*Empresas grandes
		replace tamemp_ci=3 if p512b>=51 &  p512b<=9998
		label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
		label values tamemp_ci tamaño


	****************
	*cotizando_ci***
	****************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if (((p524b1>0 & p524b1!=.) | (p538b1>0 & p538b1!=.)) & emp_ci==1)
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2))
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	********************
	*** instcot_ci *****
	********************
		gen instcot_ci=. 
		label var instcot_ci "institución a la cual cotiza"


	****************
	*afiliado_ci****
	****************
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte afiliado_ci = .
	replace afiliado_ci = 1 if(p558a1==1 | p558a2==2 | p558a3==3 | p558a4==4) & emp_ci==1
	replace afiliado_ci = 0 if (afiliado_ci != 1 & inlist(condocup_ci, 1, 2))
	label var afiliado_ci "Afiliado a la Seguridad Social"
	label define afiliado_ci 0 "No"  1 "Si"
	label value afiliado_ci afiliado_ci

	***************
	***formal_ci***
	***************
		gen formal_ci=(cotizando_ci==1)

	*****************
	*tipocontrato_ci*
	*****************
		gen tipocontrato_ci=. /* Solo disponible para asalariados*/
		replace tipocontrato_ci=1 if (p511a==1) & categopri_ci==3
		replace tipocontrato_ci=2 if (p511a>=2 & p511a<=6) & categopri_ci==3
		replace tipocontrato_ci=3 if (p511a==7 | tipocontrato_ci==.) & categopri_ci==3
		label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
		label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
		label value tipocontrato_ci tipocontrato_ci
		

	**************
	***ocupa_ci***
	**************
		gen ocupa_ci=.
		replace ocupa_ci=1 if (p505>=211 & p505<=396) & emp_ci==1
		replace ocupa_ci=2 if (p505>=111 & p505<=148) & emp_ci==1
		replace ocupa_ci=3 if (p505>=411 & p505<=462) & emp_ci==1
		replace ocupa_ci=4 if (p505>=571 & p505<=583) | (p505>=911 & p505<=931) & emp_ci==1
		replace ocupa_ci=5 if (p505>=511 & p505<=565) | (p505>=941 & p505<=961) & emp_ci==1
		replace ocupa_ci=6 if (p505>=611 & p505<=641) | (p505>=971 & p505<=973) & emp_ci==1
		replace ocupa_ci=7 if (p505>=711 & p505<=886) | (p505>=981 & p505<=987) & emp_ci==1
		replace ocupa_ci=8 if (p505>=11 & p505<=24) & emp_ci==1

		label variable ocupa_ci "Ocupacion laboral"
		label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
		label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
		label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
		label define ocupa_ci  8 "FFAA" 9 "Otras ", add
		label value ocupa_ci ocupa_ci


	*************
	**pension_ci*
	*************
		gen byte pension_ci = (d5564c > 0 | d5565c > 0)
		replace pension_ci = . if d5564c == . & d5565c == .
		label var pension_ci "1=Recibe pension contributiva"

	***************
	*pensionsub_ci*
	***************
		gen pensionsub_ci = (d5567c > 0) if !missing(d5567c)
		label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

	****************
	*tipopen_ci*****
	****************
		gen tipopen_ci=.

	****************
	*instpen_ci*****
	****************
		gen instpen_ci=.
		label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 


********************************************************************************
****************   VARIABLES DE INGRESO & PROTECCION SOCIAL   ******************
********************************************************************************

* A.Ingresos laborales a nivel individuo

	***************
	***ylmpri_ci***
	***************
	*Ingreso laboral monetario (actividad principal)	
	*Revisar pregunta d544 (beneficios )
		gen ylmprid = i524e1 /12 // Ocupacion principal dependiente
		gen ylmprii = i530a  /12 // Ocupacion principal independiente (ganancia)

		egen ylmpri_ci=rsum(ylmprid ylmprii), missing

	****************
	***ylnmpri_ci***
	****************
	*Ingreso laboral no monetario (actividad principal)		
		gen ylnmprid = d529t /12 // Pago en especie - Ocupacion principal dependiente
		gen ylnmprii = d536  /12 // Autoconsumo - Ocupacion principal independiente

		egen ylnmpri_ci=rsum(ylnmprid ylnmprii), missing

	***************
	***ylmsec_ci***
	***************
	*Ingreso laboral monetario (actividad secundaria)		
		gen ylmsecd = i538e1/12 // Ocupacion secundaria dependiente
		gen ylmseci = i541a/12 // Ocupacion secundaria independiente (ganancia)
		egen ylmsec_ci=rsum(ylmsecd ylmseci), missing
		
	****************
	***ylnmsec_ci***
	****************
	*Ingreso laboral no monetario (actividad secundaria)		
		gen ylnmsecd = d540t /12 // Pago en especie - Ocupacion secundaria dependiente
		gen ylnmseci = d543  /12 // Autoconsumo - Ocupacion secundaria independiente
		egen ylnmsec_ci=rsum(ylnmsecd ylnmseci), missing

	*****************
	***ylmotros_ci***
	*****************
	* Ingresos laboral monetario (otras actividades)
		gen ylmotros_ci = d544t/12


	****************
	**ylnmotros_ci**
	****************
	* Ingresos no laboral monetario (otras actividades)
		gen ylnmotros_ci=.

	************
	***ylm_ci***
	************
	* Ingreso laboral total monetario
		egen ylm_ci=rsum(ylmpri_ci ylmsec_ci ylmotros_ci), missing
		replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==. & ylmotros_ci==.

	
	*************
	***ylnm_ci***
	*************
		egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci ylnmotros_ci), missing
		replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==. & ylnmotros_ci==.


*B. Ingresos no laborales a nivel individuo

	******************
	*** ytransf_ci ***
	******************
* PNC: Pensiones sociales no contributivas: 
		* Pensión 65 (d5567)
* PTMC: Programas de transferencias monetarias condicionadas: 
		* Juntos (d5566)
		* Beca 18 (d55610)
* POTROT: Programas de otras transferencias monetarias no condicionadas: 
		* Bono gas (d55611)		
		* Bono Niño Universal (d55621)
		* Programa social Contigo (d55623)
		* Bono Yanapay (d55624)
		* Bono 600 (d55625)
		* Bono alimentario (d55626)			

*** Beneficiarios a nivel individual:

	// PNC	
	gen byte pnc_ci = (p5567a == 1) if ! missing(p5567a)

	// PTMC
	gen byte juntos_ci = (p5566a == 1) if ! missing(p5566a)
	gen byte beca_ci = (p55610a == 1) if ! missing(p55610a)
	gen byte ptmc_ci = (juntos_ci == 1 | beca_ci == 1)
	replace ptmc_ci = . if juntos_ci == . & beca_ci == .

	// POTROT
	gen byte gas_ci = (p55611a == 1) if ! missing(p55611a)
	gen byte ninouni_ci = (p55621a == 1) if ! missing(p55621a)
	gen byte contigo_ci = (p55623a == 1) if ! missing(p55623a)
	gen byte yanapay_ci = (p55624a == 1) if ! missing(p55624a)
	gen byte bonoseis_ci = (p55625a == 1) if ! missing(p55625a)
	gen byte alimentario_ci = (p55626a == 1) if ! missing(p55626a)
	
	gen byte potrot_ci = (gas_ci == 1 | ninouni_ci == 1 | contigo_ci == 1 | yanapay_ci == 1 | bonoseis_ci == 1 | alimentario_ci == 1)
	replace potrot_ci = . if gas_ci == . & ninouni_ci == . & contigo_ci == . & yanapay_ci == . & bonoseis_ci == . & alimentario_ci == .
	
*** Montos de transferencias a nivel individual:

	// Transferencias PNC
	gen double ypnc_ci = (d5567c/12) if d5567c != .
	
	// Transferencias PTMC 
	gen double yjuntos_ci = (d5566c/12) if d5566c !=.
	gen double ybeca_ci = (d55610c/12) if d55610c !=.
	egen double yptmc_ci = rowtotal(yjuntos_ci ybeca_ci), mi

	// Otras transferencias POTROT
	gen double ygas_ci = (d55611c/12) if d55611c !=.
	gen double yninouni_ci = (d55621c/12) if d55621c !=.
	gen double ycontigo_ci = (d55623c/12) if d55623c !=.
	gen double yyanapay_ci = (d55624c/12) if d55624c !=.
	gen double ybonoseis_ci = (d55625c/12) if d55625c !=.
	gen double yalimentario_ci = (d55626c/12) if d55626c !=.

	egen double yotrot_ci = rowtotal(ygas_ci yninouni_ci ycontigo_ci yyanapay_ci ybonoseis_ci yalimentario_ci), mi
		
*** Ingreso individual por transferencias no contributivas
egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi


	******************
	*** remesas_ci *** Transferencias desde el extranjero (hogares)
	******************
gen double remesas_ci = d5563e/12 if p5563a == 1 & d5563e != .


	***************
	*** ypen_ci ***
	***************
gen double jubil_ci = (d5564c/12) if d5564c !=.
gen double viudez_ci = (d5565c/12) if d5565c !=.
egen double ypen_ci = rowtotal(jubil_ci viudez_ci), mi
label var ypen_ci "Valor de la pension contributiva"


	*****************
	**  ypensub_ci  *
	*****************
gen double ypensub_ci = ypnc_ci
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"


	***************
	*** ynlm_ci ***
	***************

/* Ingresos deflactados y anualizados (c: nacional > d566t1; e: extranjero > d566t2)
d5561c ingresos pension de divorcio o separacion 
d5562c ingresos pension alimenticia
d5563c ingresos remesas de otros hogares (nacional)
d5564c ingresos pension de jubilacion/cesantía
d5565c ingresos pension de viudez, orfandad o sobrevivencia
d5566c transferencias programa juntos
d5567c transferencias programa pension65
d5568c otras transferencias de las Instituciones Públicas o Privadas
d5569c ingresos otras de transferencias de hogares
d55610c transferencias beca 18
d55611c transferencias bono gas
d55612c programa servicio militar ****
d55613c beneficio por profesor ****
d55614c propina de la escuela ****
d55620c Bono electricidad
d55621c Bono niño universal
d55622c Bono ONP para jubilados
d55623c Programa social contigo
d55624c Programa Yanapay
d55625c Bono 600
d55626c Bono alimentario
d55627c Otras transferencias especifique
d55628c Otras transferencias especifique
*/

gen double divorcio = (d5561c/12) if d5561c !=.
gen double pens_alim = (d5562c/12) if d5562c !=.
gen double transf_hog = (d5563c/12) if d5563c !=.
gen double otras_pp = (d5568c/12) if d5568c !=.
gen double otras_trans = (d5569c/12) if d5569c !=.
gen double smilitar = (d55612c/12) if d55612c !=.
gen double profesor = (d55613c/12) if d55613c !=.
gen double escuela = (d55614c/12) if d55614c !=.
gen double bono_elect = (d55620c/12) if d55620c !=.
gen double bono_onp = (d55622c/12) if d55622c !=.
gen double otras_e1 = (d55627c/12) if d55627c !=.
gen double otras_e2 = (d55628c/12) if d55628c !=.

gen double aux_ext = (d556t2/12) if d556t2 !=.
gen double rem1 = remesas_ci*(-1)
egen otrans_ext = rowtotal(aux_ext rem1), mi  // Otras transferencias del extranjero (excluye remesas de hogares)

gen double rentas = d557t/12 if d557t != . // Renta de propiedad 
gen double ing_extraord = d558t/12 if d558t != . // Ing extraordinario

*egen double ynlm_ci = rowtotal(transltot transetot d557t_1 d558t_1), missing 
egen double ynlm_ci = rowtotal(divorcio pens_alim transf_hog smilitar profesor escuela ypen_ci ytransf_ci bono_elect bono_onp otras_pp otras_trans otras_e1 otras_e2 remesas_ci otrans_ext rentas ing_extraord), mi

	
	****************
	*** ynlnm_ci *** (información nivel hogar)
	****************
	gen ynlnm_ci = .

	
	**************
	***ytot_ci***
	**************
egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi

	***************
	*** ynet_ci ***
	***************
gen double aux_ytransf_ci = ytransf_ci*(-1)
egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi
drop aux_ext rem1 aux_ytransf_ci


*C. Ingresos laborales y no laborales a nivel hogar

	**************
	*** ylm_ch ***
	**************
		by idh_ch, sort: egen double ylm_ch = total(ylm_ci) if miembros_ci==1, mi

	**************
	*** ylnm_ch ***
	**************
		by idh_ch, sort: egen double ylnm_ch = total(ylnm_ci) if miembros_ci==1, mi


	*******************
	*** nrylmpri_ci ***
	*******************
		gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)


	*******************
	*** nrylmpri_ch ***
	*******************
		by idh_ch, sort: egen nrylmpri_ch=total(nrylmpri_ci) if miembros_ci==1, mi
		replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
		replace nrylmpri_ch=. if nrylmpri_ch==.

	****************
	*** ylmnr_ch ***
	****************
		by idh_ch, sort: egen ylmnr_ch=total(ylm_ci) if miembros_ci==1, mi
		replace ylmnr_ch=. if nrylmpri_ch==1

	
	******************
	*** ytransf_ch ***
	****************** 

*** Beneficiarios a nivel hogar:
	bys idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1
	bys idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1
	bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
	gen byte pcasht_ch = (ptmc_ch == 1 | pnc_ch == 1 | potrot_ch == 1)
	replace pcasht_ch = . if ptmc_ch == . & pnc_ch == . & potrot_ch == .

*** Montos de transferencias a nivel hogar:
	bys idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi
	bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

*** Ingreso del Hogar por transferencias no contributivas
egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi


	***************
	*** ynlm_ch ***
	***************
by idh_ch, sort: egen double ynlm_ch = total(ynlm_ci) if miembros_ci==1, mi
		

	****************
	*** ynlnm_ch *** PREGUNTAR QUE INCLUYE EN LO NO MONETARIO NO LABORAL
	****************
	/* bienes y servicios no monetarios del hogar — módulos 612 y afines, /12 (mensual) */
	gen double ing_nm = (ig06hd + ig08hd + sig24 + sig26 + ///
		gru13hd1 + gru13hd2 + gru13hd3 + ///
		gru23hd1 + gru23hd2 + gru23hd3 + gru24hd + ///
		gru33hd1 + gru33hd2 + gru33hd3 + (gru34hd - ga04hd) + ///
		gru43hd1 + gru43hd2 + gru43hd3 + gru44hd + ///
		gru53hd1 + gru53hd2 + gru53hd3 + gru54hd + ///
		gru63hd1 + gru63hd2 + gru63hd3 + gru64hd + ///
		gru73hd1 + gru73hd2 + gru73hd3 + gru74hd + ///
		gru83hd1 + gru83hd2 + gru83hd3 + gru84hd + ///
		gru14hd3 + gru14hd4 + gru14hd5 + ///
		sg42d + sg42d1 + sg42d2 + sg42d3)
	gen double ynlnm_ch = ing_nm/12 if miembros_ci == 1


	***************
	*** ytot_ch ***
	***************

egen double ytot_ch = rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci==1, mi


	***************
	*** ynet_ch ***
	***************

gen double aux_ytransf_ch = ytransf_ch*(-1)
egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
drop aux_ytransf_ch


*D. Salario por hora

	*****************
	***ylhopri_ci ***
	*****************
		gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)


	***************
	***ylmho_ci ***
	***************
		gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
		
*F. Remesas
		
	******************
	*** remesas_ch ***
	******************
		by idh_ch, sort: egen double remesas_ch = total(remesas_ci) if miembros_ci==1, mi
		
	
/****** Variables de educacion ******/

	***************
	*** aedu_ci ***
	***************
		egen grados = rowtotal(p301b  p301c), missing
		
		gen byte aedu_ci=.
		replace aedu_ci=0  			if p301a==1 | p301a==2 // Sin nivel o educación inicial o prescolar
		replace aedu_ci=grados 		if p301a==3 // Primaria incompleta
		replace aedu_ci=6 			if p301a==4 // Primaria completa - 6 años
		replace aedu_ci=6 + grados 	if p301a==5 // Secundaria incompleta
		replace aedu_ci=11 			if p301a==6 // Secundaria completa - 11 años
		replace aedu_ci=11 + grados if p301a==7 // Superior no universitaria incompleta
		replace aedu_ci=13			if p301a==8 // Superior no universitaria completa
		replace aedu_ci=11 + grados if p301a==9 // Superior universitaria incompleta
		replace aedu_ci=16			if p301a==10 // Superior universitaria completa
		replace aedu_ci=16 + grados if p301a==11 // Maestria y/o Doctorador
		replace aedu_ci=0 			if p301a==12 // Basica Especial
	
	**************
* Line of code with indicator eduno_ci was deleted	**************
* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted* Line of code with indicator eduno_ci was deleted
	***************
	***edupre_ci***
	***************
		gen byte edupre_ci=(p301a==2)
		replace edupre_ci=. if aedu_ci==.
		label variable edupre_ci "Educacion preescolar"
	
	**************
* Line of code with indicator edupi_ci was deleted	**************
* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted* Line of code with indicator edupi_ci was deleted
	**************
* Line of code with indicator edupc_ci was deleted	**************
* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted* Line of code with indicator edupc_ci was deleted
	**************
* Line of code with indicator edusi_ci was deleted	**************
* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted* Line of code with indicator edusi_ci was deleted
	**************
* Line of code with indicator edusc_ci was deleted	**************
* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted* Line of code with indicator edusc_ci was deleted
	***************
* Line of code with indicator edus1i_ci was deleted	***************
* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted* Line of code with indicator edus1i_ci was deleted
	***************
* Line of code with indicator edus1c_ci was deleted	***************
* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted* Line of code with indicator edus1c_ci was deleted
	***************
* Line of code with indicator edus2i_ci was deleted	***************
* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted* Line of code with indicator edus2i_ci was deleted
	***************
* Line of code with indicator edus2c_ci was deleted	***************
* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted* Line of code with indicator edus2c_ci was deleted
	**************
	***eduui_ci***
	**************
		gen byte eduui_ci = inlist(p301a, 7, 9)
		replace eduui_ci = . if aedu_ci == .
		label variable eduui_ci "Universitaria incompleta"

	***************
	***eduuc_ci***
	***************
		gen byte eduuc_ci = inlist(p301a, 8, 10, 11)
		replace eduuc_ci = . if aedu_ci == .
		label variable eduuc_ci "Universitaria completa"

	**************
	***eduac_ci***
	**************
		gen eduac_ci = .
		replace eduac_ci = 1 if inlist(p301a, 9, 10, 11)
		replace eduac_ci = 0 if inlist(p301a, 7, 8)
		label variable eduac_ci "Superior universitario vs superior no universitario"

	***************
	***asiste_ci***
	***************
	/*Se considera la variable de matricula y de asistencia, codificando como 1 a los que estan matriculados y no asisten por vacaciones*/
		g asiste_ci = p306==1 // matriculados 
		replace asiste_ci=0 if p307==2 & p313!=6
		label variable asiste_ci "Asiste actualmente a la escuela"


	***************
	***edupub_ci***
	***************
		gen edupub_ci=.
		replace edupub_ci=1 if (p308d==1) & asiste_ci==1
		replace edupub_ci=0 if (p308d==2) & asiste_ci==1

	****************
	***asispre_ci***
	****************
		g asispre_ci= p308a==1  // matriculado en nivel inicial (sin edad)
		replace asispre_ci=0 if p307==2 & p313!=6 // matriculado pero no asiste (y no por vacaciones)
		la var asispre_ci "Asiste a educacion prescolar"


	*****************
* Line of code with indicator pqnoasis_ci was deleted	*****************
* Line of code with indicator pqnoasis_ci was deleted


	**************
	*pqnoasis1_ci*
	**************
        * pqnoasis1_ci was replaced by razonesnoasis_ci, June 2025 * 

**********************
***razonesnoasis_ci***
**********************
	g razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(p313, 1, 2)
	replace razonesnoasis_ci = 2 if p313 == 9
	replace razonesnoasis_ci = 3 if inlist(p313, 5, 10)
	replace razonesnoasis_ci = 4 if p313 == 7 
	replace razonesnoasis_ci = 5 if inlist(p313, 3, 4, 11)


label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
label value  razonesnoasis_ci razonesnoasis_ci


	***************
* Line of code with indicator repite_ci was deleted	***************
* Line of code with indicator repiteult was deleted/* Variables de vivienda */ 


	************
	***luz_ch***
	************
		gen luz_ch=p1121

	****************
	***luzmide_ch***
	****************
		gen luzmide_ch=1 if p112a ==1 | p112a ==2
		replace luzmide_ch=0 if p112a==3

	****************
	***combust_ch***
	****************
		gen combust_ch=1 if p113a==1 | p113a==2 | p113a==3
		replace combust_ch=0 if p113a==5 | p113a==6 | p113a==7 | p113a==4

	*************
	***piso_ch***
	*************
		gen piso_ch=0 if p103==6
		replace piso_ch=1 if p103>=1 & p103<=5
		replace piso_ch=2 if p103==7
		label var piso_ch "Materiales de construcción del piso"  
		label def piso_ch 0"Piso de tierra" 1"Materiales permanentes" 2"Otros materiales"
		label val piso_ch piso_ch

		/*
		p103:el material predominante en los pisos
				   1 parquet o madera pulida
				   2 láminas asfálticas, vinílicos o similares
				   3 losetas, terrazos o similares
				   4 madera (entablados)
				   5 cemento
				   6 tierra
				   7 otro material
		*/

	**************
	***pared_ch***
	**************
	
		gen pared_ch=0 if p102==4
		replace pared_ch=1 if p102==1 | p102==2 | p102==5 | p102==6 | p102==7 | p102==3 
		replace pared_ch=2 if p102>=8

		/*
		p102:el material predominante en las paredes

				   1 ladrillo o bloque de cemento
				   2 piedra o sillar con cal o cemento
				   3 adobe
				   4 tapia
				   5 quincha (caña con barro)
				   6 piedra con barro
				   7 madera
				   8 estera
				   9 otro material
		*/

	**************
	***techo_ch***
	**************
			
		gen techo_ch=0 if p103a>=5 & p103a<=7
		replace techo_ch=1 if p103a>=1 & p103a<=4
		replace techo_ch=2 if p103a==8

		/*p103a:el material predominante en los techos
				   1 concreto armado
				   2 madera
				   3 tejas
				   4 planchas de calamina, fibra de cemento o similares
				   5 caña o estera con torta de barro
				   6 estera
				   7 paja, hojas de palmera
				   8 otro material
		*/
   	**************
	***resid_ch***
	**************
		gen resid_ch=.
		
	*************
	***dorm_ch***
	*************
	* MGR: se imputa 1 a aquellos hogares que indican tener 0 habitaciones exclusivas para dormir
		gen dorm_ch=p104a
		replace dorm_ch=1 if p104a==0
	
	****************
	***cuartos_ch***
	****************
		gen cuartos_ch=p104

	***************
	***cocina_ch***
	***************
			gen cocina_ch=.
			label var cocina_ch "Cuarto separado y exclusivo para cocinar"

	**************
	***telef_ch***
	**************
		gen telef_ch=(p1141==1)
		label var telef_ch "El hogar tiene servicio telefónico fijo"

	***************
	***refrig_ch***
	***************
		gen refrig_ch=(p61212==1)
		
	**************
	***freez_ch***
	**************
		gen freez_ch=.

	*************
	***auto_ch***
	*************
		gen auto_ch =(p61217==1)

	**************
	***compu_ch***
	**************
		gen compu_ch=(p6127==1)

	*****************
	***internet_ch***
	*****************
		gen internet_ch=(p1144==1)

	************
	***cel_ch***
	************
		gen cel_ch=(p1142==1)

	**************
	***vivi1_ch***
	**************
		gen vivi1_ch=1 if p101==1
		replace vivi1_ch=2 if p101==2
		replace vivi1_ch=3 if p101>2 & p101!=.

		label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
		label def vivi1_ch 1"Casa" 2"Departamento" 3"Otros"
		label val vivi1_ch vivi1_ch

		/*p101:
				   1 casa independiente
				   2 departamento en edificio
				   3 vivienda en quinta
				   4 vivienda en casa de vecindad (callejón, solar o corralón)
				   5 choza o cabaña
				   6 vivienda improvisada
				   7 local no destinado para habitación humana
				   8 otro
		*/

	**************
	***vivi2_ch***
	**************
		gen vivi2_ch=(p101<=2)
		replace vivi2_ch=. if p101==. 
		label var vivi2_ch "La vivienda es casa o departamento"
	
	*****************
	***viviprop_ch***
	*****************
		gen viviprop_ch=0 if p105a==1
		replace viviprop_ch=1 if p105a==2
		replace viviprop_ch=2 if p105a==4
		replace viviprop_ch=3 if p105a==3 | (p105a>4 & p105a!=.) 
		label define viviprop_ch 0 "Alquilada" 1 "Propia y totalmente pagada" 2 "Propia y en proceso de pago" 3 "Ocupada (propia de facto)"
		label value viviprop_ch viviprop_ch

		/*
		p105a:
				   1 alquilada
				   2 propia, totalmente pagada
				   3 propia, por invasión
				   4 propia, comprándola a plazos
				   5 cedida por el centro de trabajo
				   6 cedida por otro hogar o institución
				   7 otra forma
		*/
	
	****************
	***vivitit_ch***
	****************
		gen vivitit_ch=(p106a==1)
		label var vivitit_ch "El hogar posee un título de propiedad"
	
	****************
	***vivialq_ch***
	****************
		replace p105b=. if p105b==99999
		gen vivialq_ch=p105b if viviprop_ch==0
		label var vivialq_ch "Alquiler mensual"

	*******************
	***vivialqimp_ch***
	*******************	
		gen vivialqimp_ch= ia01hd /12
		label var vivialqimp_ch "Alquiler mensual imputado"

/* Variables de WASH */ 

	****************
	***aguared_ch***
	****************
		gen aguared_ch=0
		replace aguared_ch=1 if (p110==1 | p110==2)
		label var aguared_ch "Acceso a fuente de agua por red"
		/*
		p110:
				   1 red pública, dentro de la vivienda
				   2 red pública, fuera de la vivienda pero dentro del edificio
				   3 pilón de uso público
				   4 camión - cisterna u otro similar
				   5 pozo
				   6 manantial o puquio 
				   7 otra
				   8 rio, acequia, lago, laguna
		*/

	*****************
	*aguafconsumo_ch*
	*****************
		gen aguafconsumo_ch = 0
		replace aguafconsumo_ch = 0 if p110a1==2
		replace aguafconsumo_ch = 1 if (p110==1 |p110==2) & p110a1==1
		replace aguafconsumo_ch = 2 if p110==3 & p110a1==1
		replace aguafconsumo_ch = 6 if p110==4
		replace aguafconsumo_ch = 8 if p110==8
		replace aguafconsumo_ch = 10 if (p110==5|  p110==6 |p110==7)


	*****************
	*aguafuente_ch*
	*****************
		gen aguafuente_ch =.
		replace aguafuente_ch = 7 if p110a1==1
		replace aguafuente_ch = 1 if (p110==1|p110==2) 
		replace aguafuente_ch = 2 if p110==3
		replace aguafuente_ch = 6 if p110==4
		replace aguafuente_ch = 8 if p110==8 
		replace aguafuente_ch = 10 if (p110==5 |p110==7| p110==6)

	*****************
	*aguadist_ch*
	*****************
		gen aguadist_ch=.
		replace aguadist_ch= 1 if p110==1 
		replace aguadist_ch= 2 if p110==2
		replace aguadist_ch= 3 if p110 == 3 | p110 == 6
		replace aguadist_ch= 0 if p110==4 | p110==5
		label var aguadist_ch "Ubicación de la principal fuente de agua"
		label def aguadist_ch 1"Dentro de la vivienda" 2"Fuera de la vivienda pero en el terreno"
		label def aguadist_ch 3"Fuera de la vivienda y del terreno", add
		label val aguadist_ch aguadist_ch


	**************
	*aguadisp1_ch*
	**************
	*Se toma en cuenta si tiene agua continua por 24 horas 
		gen aguadisp1_ch = (p110c1==24 | p110c3==24)
		label var aguadisp1 "continuidad de disponibilidad de agua considerado suficiente"

	**************
	*aguadisp2_ch*
	**************
		gen aguadisp2_ch =.
		replace aguadisp2_ch = 1 if (p110c2<4 | p110c1 < 12 | p110c3 <12) 
		replace aguadisp2_ch = 2 if p110c2>=4 & (p110c1>=12 | p110c3 <12)
		replace aguadisp2_ch = 3 if p110c==1 & p110c1 == 24


	*************
	*aguatrat_ch*
	*************
		gen aguatrat_ch = 9
		*label var aguatrat_ch "= 9 la encuesta no pregunta de si se trata el agua antes de consumirla"

	*************
	*aguamala_ch*  
	*************
		gen aguamala_ch = 2
		replace aguamala_ch = 0 if aguafuente_ch<=7
		replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10
		*label var aguamala_ch "= 1 si la fuente de agua no es mejorada"

	*****************
	*aguamejorada_ch*  
	*****************
		gen aguamejorada_ch = 2
		replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
		replace aguamejorada_ch = 1 if aguafuente_ch<=7


	*****************
	***aguamide_ch***
	*****************
		gen aguamide_ch=.

	*****************
	*bano_ch         *  
	*****************
		gen bano_ch=0
		replace bano_ch=1 if (p111a==1|p111a==2)
		replace bano_ch=2 if p111a==4
		replace bano_ch=3 if p111a==5
		replace bano_ch=4 if (p111a==6|p111a==8)
		replace bano_ch=6 if (p111a == 3 | p111a ==7)

		/*
		0 Sin instalaciones
		1 Indoro a red de desagüe
		2 Indoro a fosa séptica
		3 Letrina mejorada / otra instalación mejorada
		4 Indoro/letrina a cuerpo de agua superficial o suelo
		5 Instalación no mejorada
		6 Instalación que no se puede clasificar
		*/

	*****************
	*banoex_ch         *  
	*****************
		gen banoex_ch=9

	************
	*sinbano_ch*
	************
	gen sinbano_ch =3
	replace sinbano_ch = 0 if bano_ch>0
	label var sinbano_ch "hogares sin acceso a instalaciones propias."

	*****************
	*banomejorado_ch*  Altered
	*****************
	gen banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6


/* Variables de migracion */
	*******************
	*** migrante_ci ***
	*******************	
		gen migrante_ci=(p401g2<10000) if p401g2!=. & p401g2!=999999
		label var migrante_ci "=1 si es migrante"
		
	**********************
	*** migantiguo5_ci ***
	**********************
		gen migrantiguo5_ci=(migrante_ci==1 & (p401f==1 | (p401g>10000 & p401g!=.))) if migrante_ci!=. & p401f!=3 & p401g!=999999 & p401f!=. & !inrange(edad_ci,0,4)
		label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
		
	
	**********************
	*** miglac_ci ***
	**********************
		gen miglac_ci=(inlist(p401g2,4002,4003,4004,4005,4006,4007,4009,4010,4011,4014,4015,4018,4019,4021,4022,4023,4024,4025,4026,4027,4030,4034,4035,4036,4037) & migrante_ci==1) if migrante_ci!=.
		replace miglac_ci = . if migrante_ci == 0
		label var miglac_ci "=1 si es migrante proveniente de un pais LAC"
		** Fuente: Los codigos de paises se obtiene del censo de peru (redatam)


/* Variables de referencia externa */ 

	*************
	**salmm_ci***
	*************
		gen salmm_ci = 1025 /*se actualizó en mayo de 2022 - Permanece para el 2023*/
		* https://busquedas.elperuano.pe/normaslegales/decreto-supremo-que-incrementa-la-remuneracion-minima-vital-decreto-supremo-n-003-2022-tr-2054921-1/
		label var salmm_ci "Salario minimo legal"

	*********
	*lp_ci***
	*********
		gen lp_ci =linea
		label var lp_ci "Linea de pobreza oficial del pais"

	*********
	*li_ci***
	*********
		gen lpe_ci =linpe
		label var lpe_ci "Linea de indigencia oficial del pais"

**# Bookmark #1


	
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
  afro_ci ind_ci noafroind_ci afroind_ci afro_ch ind_ch noafroind_ch afroind_ch dis_ci disWG_ci dis_ch PER_dis_ci /// Diversidad
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
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

/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y de industrias y dejarlo en base armonizada 
para análisis de trends (en el marco de estudios sobre el futuro del trabajo)*/

compress

saveold "`base_out'", version(12) replace
