*(Versión stata 18)

**# Bookmark #1
clear
set more off

*________________________________________________________________________________________________________________*

* Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
* utilizar un loop)
* Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
* Se tiene acceso al servidor unicamente al interior del BID.
* El servidor contiene las bases de datos MECOVI.
*________________________________________________________________________________________________________________*

global surveysFolder "C:\Users\j.torresgomez\Dropbox\BID\BID2025_Pepe\Tarea1_Excel\8_Peru_2024\survey\PER\ENAHO\2024\a"
global out ="${surveysFolder}\data_merge"
/*
global ruta = "${surveysFolder}"

local PAIS PER
local ENCUESTA ENAHO
local ANO "2024"
local ronda a 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 

cap log off
*/
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Peru
Encuesta: ENAHO
Round: a
Autores:  
Versión ...:
Nombre de autor (SCL/SCL) - Email: ..., Fecha:...
---------EXAMPLE---------: Alvaro Altamirano (LMK/SCL) - Email: alvaroalt@iadb.org, 24 de junio de 2020 PLEASE DELETE AFTER FILLING THIS PART
****************************************************************************/

/***************************************************************************
Detalle de procesamientos o modificaciones anteriores:
****************************************************************************/


use "$out\PER_2024a.dta", clear


********************************************************************************


********************  VARIABLES DEL IDENTIFICACION *****************************
********************************************************************************

/* 12 variables: region_BID_c , region_c , pais_c, anio_c, mes_c, zona_c, estrato_ci, */
/* upm_ci, idh_ch, idp_ci, factor_ch , factor_ci */


	********************
	*** region_BID_c : país de residencia de hogares según agrupación BID  ****
	********************
	gen byte region_BID_c=3 
	label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	
	********************
	*** region_c: Identifica  primera división político-administrativa del país****
	********************
	gen byte region_c=real(substr(ubigeo,1,2))
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

	
	************************************************************
	* pais_c: acrónimo ISO del nombre del país de residencia   *
	************************************************************
	gen str3 pais_c="PER"
	label variable pais_c "Pais"

	
	******
	*anio_c : año de la entrevista de campo de la encuesta*
	******
	gen int anio_c=2024
	label variable anio_c "Anio de la encuesta"
		
		
	******
	*mes_c: al mes en el que se realizó cada entrevista*
	******
	tostring fecent, replace 
	gen int mes_c=real(substr(fecent,5,2))
	label variable mes_c "Mes de la encuesta"
		
		
	******
	*zona_c: dominio geográfico, área de residencia o zona *
	******
	*Urbano desde 2 000 habitantes en adelante / estratos del 1 al 5 
	gen byte zona_c= 0 if estrato>=6 /* Rural */
	replace  zona_c= 1 if estrato<6  /* Urbano */

	label variable zona_c "Zona del pais"
	label define zona_c 1 "Urbana" 0 "Rural"
	label value zona_c zona_c
	* Con esta separación se obtiene alrededor de 80% de urbanidad - consistente con cifras oficiales
	
	
	*********
	*estrato : Conjunto de s viviendas particulares y sus ocupantes en un area geografica*
	*********
	gen estrato_ci=estrato
	
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=conglome
	
	
	******************
	*idh_ch (idhogar) : Identificador único de hogares *
	******************
	sort conglome vivienda hogar 
	cap egen idh_ch= group(conglome vivienda hogar)
	label variable idh_ch "ID del hogar"
	tostring idh_ch, replace


	***************
	****idp_ci (idindividuio) : Identificador único del individuo *****
	***************
	gen idp_ci = codperso
	label variable idp_ci "ID de la persona en el hogar"
	tostring idp_ci, replace format ("%20.0f") 

	
*factor07 (factor expansion anual cpv), y facpob07 (factor expansion anual de poblacion proyecciones)-son iguales *
	
	
	*******************************************
	*Factor de expansion del hogar (factor_ch) : factor de ponderación de los hogares*
	*******************************************
	gen factor_ch= factor07
	label variable factor_ch "Factor de expansion del hogar"
	
	
	***********
	*factor_ci: factor de ponderación a la población total * 
	***********
	gen factor_ci=facpob07
	label variable factor_ci "Factor de expansion del individuo"
	

	
	

********************************************************************************
***************   VARIABLES DEMOGRAFICAS   *************************************
********************************************************************************

	*********
	*sexo_ci: sexo del individuo*
	*********
	gen byte sexo_ci=p207
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci

	
	*********
	*edad_ci: Edad del individuo expresada en número de años*
	*********
	/* p208a:  �que edad tiene en a�os cumplidos?  (en a�os)
    Va de 0 a 98 años -- tab p208a, m
		*/
	gen int edad_ci=p208a
	replace edad_ci=. if edad_ci==99
	label variable edad_ci "Edad del individuo"	

	
	**************
	**relacion_ci: Variable que indica la relación o parentesco del individuo respecto al jefe de hogar
	**************

	/*
	p203: Variable de parentesco de la enaho
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
	
	/*
	Categorías de relación de parentesco del BID:
			1 Jefe/a del hogar
			2 Cónyuge/pareja (casados, unión libre, mismo sexo)
			3 Hijo/a (biológico, adoptado, hijastro, pareja no casada)
			4 Otros parientes (abuelos, nietos, hermanos, tíos, sobrinos, primos,
			  suegros, yernos/nueras, etc.)
			5 No parientes (amigos, inquilinos, visitantes, ex-cónyuges, 
				padrinos/ahijados)
			6 Empleado/a doméstico/a
			 . = Desconocido/No responde/Indeterminado
	*/
	
	gen byte relacion_ci=.
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
	
	
	**************
	*civil_ci: Estado Civil*
	**************
		/*
		p209: Categorias de estado civil la ENAHO
				   1 conviviente
				   2 casado (a)
				   3 viudo (a)
				   4 divorciado (a)
				   5 separado (a)
				   6 soltero (a)
		*/
		
		/*
		Categorias del BID:
				   1 Soltero
				   2 Unión formal o informa
				   3 Divorciado o separado
				   4 Viudo
		*/

	gen byte civil_ci=.
	replace civil_ci = 1 if p209 == 6
	replace civil_ci = 2 if p209 == 1 | p209 == 2
	replace civil_ci = 3 if p209 == 4 | p209 == 5
	replace civil_ci = 4 if p209 == 3

	label variable civil_ci "Estado civil"
	label define civil_ci 1 "Soltero" 2 "Union formal o informal"
	label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
	label value civil_ci civil_ci
		
		
	**********
	*jefe_ci:Variable dicotómica que identifica al jefe del hogar.
	**********
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
	label variable jefe_ci "Jefe de hogar"
		
		
	****************
	*nconyuges_ch: Variable que indica el N° de cónyuges o esposos/as en el hogar*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	label variable nconyuges_ch "Numero de conyuges"
	
	***********
	*nhijos_ch: Variable que indica el número de hijos/as en el hogar.
	***********
	* Se construye a partir de la clasificación de la variable de relacion_ci
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          
	label variable nhijos_ch "Numero de hijos"

	
	**************
	*notropari_ch: Variable que indica el número de otros parientes en el hogar.
	**************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.
	label variable notropari_ch "Numero de otros familiares"

		
	****************
	*notronopari_ch: Variable que indica el número deno parientes en el hogar.
	****************
	by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5)
	replace notronopari_ch =. if relacion_ci==.
	label variable notronopari_ch "Numero de no familiares"

		
	************
	*nempdom_ch: Número de empleados domésticos reportados en el hogar.*
	************
	*Se aproxima a esta medida usando la relacion de parentesco.
		by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6) // la categoria 6 dice "Empleado/a domestico/a"
	replace nempdom_ch =. if relacion_ci==.
	label variable nempdom_ch "Numero de empleados domesticos"  

	
	*************
	*clasehog_ch: Identifica el tipo de hogar según la cantidad de individuos.
	*************
* Se construye a partir de la clasificación de la variable de relacion_ci

	/*
		1 Unipersonal: hogares formados por un solo miembro.
		
		2 Nuclear: hogares con o sin cónyuge formados por un jefe(a) y sus 
		hijos u hogares que están 
		formados por el jefe y su cónyuge, aunque no reporten hijos. En 
		este hogar no residen otros 
		parientes o no parientes.
		
		3 Ampliado: hogares nucleares con al menos un pariente o integrados 
		por un jefe y al menos otro 
		pariente.
		
		4 Compuesto: hogar nuclear o ampliado y al menos un integrante no 
		pariente.
		
		5 Corresidente: Hogar sin hijos, cónyuge ni otros parientes, pero 
		con jefe y al menos un integrante 
		no pariente. 
	*/
	
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

	
	**************
	*nmiembros_ch: Indica el número total de miembros de categoría familiares en el hogar. *
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	replace nmiembros_ch=. if relacion_ci ==.
	label variable nmiembros_ch "Numero de familiares en el hogar"

	
	*************
	*miembros_ci: Variable dicotómica que identifica a los miembros del 
	*hogar.
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci=. if relacion_ci==.
	label variable miembros_ci "Miembro del hogar"

	
	*************
	*nmayor21_ch: Indica el número total de miembros del hogar con 21 años o más de edad. *
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
	label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

	*************
	*nmenor21_ch: Indica el número total de miembros del hogar con menos de 
	*21 años.
	*************
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
	label variable nmenor21_ch "Numero de familiares menores a 21 anios"

	*************
	*nmayor65_ch: Indica el número total de miembros del hogar con 65 años o más de edad.*
	*************
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
	label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

	************
	*nmenor6_ch: Indica el número total de miembros del hogar con menos de 6 años.*
	************
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
	label variable nmenor6_ch "Numero de familiares menores a 6 anios"

	************
	*nmenor1_ch: Indica el número total de miembros del hogar con menos de 1 año.
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
	label variable nmenor1_ch "Numero de familiares menores a 1 anio"




	
*******************************************************
***           VARIABLES DE DIVERSIDAD               ***

*******************************************************
	*********
	*afro_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial afrodescendiente*
	*********
	/*
		1 autoidentificados como: negro, afrodescendiente o variaciones
		0 NO autoidentificados como: negro, afrodescendiente o variaciones
	*/
	
	gen byte afro_ci = . 	  // se queda como missing (.) si no existe la pregunta o el individup responde como "no sabe"
	replace afro_ci = 1 if inlist(p558c,4)
	replace afro_ci = 0 if inlist(p558c,1,2,3,5,6,7,9)	

	
	*********
	*indi_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial indígena - p558c: ¿Cómo se autoidentifica el encuestado?
	*********	
	/*
		1 autoidentificados como: indígenas o variaciones
		0 NO autoidentificados como: indígenas o variaciones
	*/
	
	gen byte ind_ci =. 		  // se queda como missing (.) si responde que "no sabe"
	replace ind_ci = 1 if inlist(p558c,1,2,3,9)
	replace ind_ci = 0 if inlist(p558c,4,5,6,7) // la categoria 8 es la que queda como missing.
	
	**************
	*noafroind_ci: Identificar encuestados que NO son afrodescendientes ni indígenas según autoidentificación étnico-racial*
	**************
	gen byte noafroind_ci = . 
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1
	
		
	*********
	*afro_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente*
	*********
	gen  byte afro_jefe = afro_ci if relacion_ci==1 // Jefe
	egen afro_ch  = max(afro_jefe), by(idh_ch) // Si el hogar tiene un jefe definido afro
	drop afro_jefe
	
	********
	*ind_ch: Identifica si el jefe de hogar se autoidentifica como indígena.
	********	
	gen byte ind_jefe = ind_ci if relacion_ci==1 // Jefe
	egen ind_ch = max(ind_jefe), by(idh_ch) // Hogar
	drop ind_jefe
	

	**************
	*noafroind_ch: identifica si el jefe de hogar no se autoidentifica como parte de la población indígena ni afrodescendiente:*
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci==1 // Jefe
	
	egen noafroind_ch = max(noafroind_jefe), by(idh_ch) // Hogar
	drop noafroind_jefe	
	
	

	************
	*afroind_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial.
	************
	gen byte afroind_ci=.
	replace afroind_ci = 1 if ind_ci==1 // Indígena
	replace afroind_ci = 2 if afro_ci==1 // Afrodescendiente
	replace afroind_ci = 3 if ind_ci==0 & afro_ci==0 // otros
	label define grupoetnia 1 "Indígena" 2 "Afrodescendiente" 3 "Otros"
	label values afroind_ci grupoetnia	



	************
	*afroind_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente, indigena o como no afrodescendiente u indígena*
	************
 	gen  afroind_jefe = afroind_ci if jefe_ci==1 // Jefe
	
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 
	

	
	
	
	
	********
	*dis_ci: Identifica a los individuos con discapacidad siguiendo de forma flexible el criterio del WG.
	********
	*Las variables de discapacidad son solo de discapacidad fisica?
	gen byte dis_ci=.
	replace dis_ci = 1 if (p401h1 == 1 | p401h2 == 1 | p401h3 == 1 | p401h4 == 1 | p401h5 == 1) 
	replace dis_ci = 0 if (p401h1 == 2 & p401h2 == 2 & p401h3 == 2 & p401h4 == 2 & p401h5 == 2) 
		
	**********
	*disWG_ci: Identifica a los individuos con discapacidad siguiendo de forma estricta el criterio del WG.
	**********
	gen byte disWG_ci=.
	gen ISO3PER_dis_ci =dis_ci
	*Hay que añadir ISO como pre-fijo?

	
	********
	*dis_ch*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	
	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c=2017 //  confirmar
	
	
	
****************************
***VARIABLES LABORALES***
****************************

	****************
	****condocup_ci: Identifica la condición de ocupación del individuo. 
	****************
	/*
	ocu500: Indicador de PEA de la ENAHO
		1  ocupado
		2  desocupado abierto
		3  desocupado oculto
		4  no pea
	*/
	
	/*Categorias del BID
		1 Ocupado
		2 Desocupado
		3 Inactivo
		4 Menor que la edad límite de los entrevistados
	*/
	
	gen condocup_ci=.
	replace condocup_ci=1 if ocu500==1
	replace condocup_ci=2 if ocu500==2
	replace condocup_ci=3 if condocup_ci!=1 & condocup_ci!=2
	replace condocup_ci=4 if edad_ci<14
	label define condocup_ci 1"ocupados" 2"desocupados" 3"inactivos" 4"menor de PET"
	label value condocup_ci condocup_ci
	label var condocup_ci "Condicion de ocupacion utilizando definicion del pais"

		/*
		Alternativa 2: Revisar conceptos de ocupado de INEI Peru: https://www.inei.gob.pe/media/MenuRecursivo/publicaciones_digitales/Est/Lib1676/06.pdf

		g condocup_ci1=.
		replace condocup_ci1=1 if p501==1 | p502==1 | p503==1 | p5041==1 | p5042==1 | p5043==1 | p5044==1 | p5045==1 | p5046==1 | p5047==1 | p5048==1 | p5049==1 | p50410==1 | p50411==1 
		replace condocup_ci1=2 if condocup_ci1!=1 & (p545==1 |  p546<=2)
		recode condocup_ci1 .=3 if edad_ci>=14
		recode condocup_ci1 .=4 if edad_ci<14
		*/

	****************
	**categoinac_ci: Identifica la condición de inactividad de los individuos.
	****************
	*Aquí se define la condición de inactividad de los individuos en función de condocup_ci y p546 (que estuvo haciendo la semana pasada) de la ENAHO.
	
	gen categoinac_ci =1 if (p546==6 & condocup_ci==3)
	replace categoinac_ci = 2 if  (p546 == 4 & condocup_ci == 3)
	replace categoinac_ci = 3 if  (p546 == 5 & condocup_ci == 3)
	replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)
	label var categoinac_ci "Categoría de inactividad"
	label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"
	label value categoinac_ci categoinac_ci

	************
	***emp_ci: Variable dicotómica que identifica con valor 1 a los ocupados y 0 al resto de los individuo.
	************
	gen emp_ci=(condocup_ci==1)

	*************
	*cesante_ci: Identifica a las personas cesantes dentro de los desocupados. 
	*************
	gen cesante_ci=0 if condocup_ci==2
	replace cesante_ci=1 if p552==1 & condocup_ci==2
	label var cesante_ci "Desocupado - definicion oficial del pais"

	****************
	***desemp_ci: Variable dicotómica que identifica con valor 1 a los desocupados.
	****************
	gen desemp_ci=(condocup_ci==2)

	*****************
	***horaspri_ci: Variable continua que indica el número de horas totales trabajadas en la actividad principal en la semana de referencia
	*****************
	gen horaspri_ci=p513t 
	replace horaspri_ci=. if emp_ci~=1

	***************
	***subemp_ci:  Variable dicotómica que vale 1 si la persona trabaja ≤30 horas semanales en su actividad principal y desea o está disponible para trabajar más (subempleo visible), y 0 en caso contrario.
	***************
	gen subemp_ci=0
	replace subemp_ci=1 if horaspri_ci<=30 & p521==1 & p521a==1 & emp_ci==1 

	****************
	***durades_ci: Indica la duración del desempleo en meses o el número de meses –no necesariamente consecutivos– que el individuo desempleado ha estado buscando empleo.
	****************
	gen durades_ci=p551/4.3 if desemp_ci==1 /* calculo sin filtros if desemp_ci==1 -- cambio en manual*/

	*************
	***pea_ci: Variable dicotómica que indica la población económicamente activa (PEA).
	*************
	gen pea_ci=(emp_ci==1 | desemp_ci==1)


	*****************
	***nempleos_ci: Variable que indica el número de empleos que tiene la persona.
	*****************
	gen nempleos_ci=.
	replace nempleos_ci=1 if emp_ci==1
	replace nempleos_ci=2 if emp_ci==1 & p514==1
	replace nempleos_ci=2 if emp_ci==1 & p514==2 & (p5151==1 | p5152==1 | p5153==1 | ///
			p5154==1 | p5155==1 | p5156==1 | p5157==1 | p5158==1 | p5159==1 | p51510==1 | ///
			p51511==1)

	*******************
	***antiguedad_ci: Años de trabajo en la actividad principal actual de la persona ocupada.
	*******************
	gen anios_ant=p513a1
	gen meses_ant=p513a2/12

	egen antiguedad_ci = rsum(anios_ant meses_ant)
	replace antig=. if anios_ant==. & meses_ant==.

	*****************
	***desalent_ci: 1 para las personas clasifican como inactivas declaran que no buscan trabajo por desanimo, cansancio, sentimiento de incapacidad, etc, y 0 de otro modo.
	*****************
	gen desalent_ci=(emp_ci==0 & p545==2 & (p549==1 | p549==2))


	*****************
	***horastot_ci: Variable continua que indica el número de horas totales trabajadas en todas las actividades económicas en una semana. 
	*****************
	egen horastot_ci=rsum(horaspri_ci p518)
	replace horastot_ci=. if horaspri_ci==. & p518==.
	replace horastot_ci=. if emp_ci~=1

	*******************
	***tiempoparc_ci: Variable dicotómica que indica con valor 1 si la persona trabaja menos de 30 horas a la semana en la actividad principal y no desea trabajar más.
	*******************
	gen tiempoparc_ci=0
	replace tiempoparc_ci=1 if (horaspri_ci>0 & horaspri_ci<30) & p521==2 & emp_ci==1
	replace tiempoparc_ci=. if emp_ci==0

	******************
	***categopri_ci: Indica la categoría ocupacional de la actividad principal para los ocupados.
	******************
	/* p507 variable de posición en la ocupación principal de la ENAO
		 1  empleador o patrono
		 2  trabajador independiente
		 3  empleado
		 4  obrero
		 5  trabajador familiar no remunerado
		 6  trabajador del hogar
		 7  otro
	*/
	
	/* Categorias del BID
		0 Otra clasificación
		1 Patrón o empleador
		2 Cuenta Propia o independiente
		3 Empleado o asalariado
		4 Trabajador no remunerado
	*/
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
	***categosec_ci: Indica la categoría ocupacional de la actividad secundaria. 
	******************
	* Mismas categorias que en la variable anterior
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
	***rama_ci: Indica la actividad laboral de la ocupación principal según la Clasificacióntrial Uniforme a un dígito con las que fueron codificadas las bases originales para su armonización (Para ver un detalle de los criterios originales utilizados por cada país ver anexo A4_rama_ci). 
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
	***spublico_ci: Variable dicotómica que indica con valor 1 si la persona lleva a cabo su actividad laboral principal en el sector público y con valor 0 al resto de la población. Solo para los ocupados emp_ci=1
	*****************
	gen spublico_ci=(p510==1 | p510==2 | p510==3)
	replace spublico_ci=. if emp_ci~=1

	*************
	*tamemp_ci: Indica la categoría del tamaño de la empresa donde el individuo realiza su actividad laboral principal. 
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
	*cotizando_ci: Variable dicotómica que indica con valor 1 si el asalariado o independiente cotiza a la seguridad social, de forma voluntaria o por medio de su empleador, en el periodo de referencia, con 0 a los desocupados o independientes que no responden si la encuesta no les pregunta y con valores perdidos si la variable original lo tiene.
	****************
	gen cotizando_ci=0     if condocup_ci==1 | condocup_ci==2
	replace cotizando_ci=1 if ((p524b1>0 & p524b1!=.) | (p538b1>0 & p538b1!=.)) & cotizando_ci==0
	label var cotizando_ci "Cotizante a la Seguridad Social"

	********************
	*** instcot_ci: Variable categórica que indica la institución de la Seguridad Social a la cual cotiza o está afiliado.
	********************
	gen instcot_ci=. 
	label var instcot_ci "institución a la cual cotiza"


	****************
	*afiliado_ci: Variable dicotómica que indica con valor 1 si el trabajador está afiliado a la Seguridad Social (independientemente que haya o no cotizado en el mes de referencia) y con 0 al resto
	****************
	gen afiliado_ci=0
	replace afiliado_ci=1 if (p558a1==1 | p558a2==2 | p558a3==3 | p558a4==4) 
	label var afiliado_ci "Afiliado a la Seguridad Social"
		

	***************
	***formal_ci: Variable dicotómica que indica con valor 1 si el trabajador es formal y con 0 al resto. Un individuo se califica como formal si está afiliado o cotiza a la Seguridad Social.
	***************
	gen formal_ci=(cotizando_ci==1)

	*****************
	*tipocontrato_ci: tipocontrato_ci Variable categórica que indica el tipo de contrato laboral de los empleados/asalariados en la actividad principal según su duración (los trabajadores no asalariados deberían identificarse con valor perdido).
	*****************
	gen tipocontrato_ci=. /* Solo disponible para asalariados*/
	replace tipocontrato_ci=1 if (p511a==1) & categopri_ci==3
	replace tipocontrato_ci=2 if (p511a>=2 & p511a<=6) & categopri_ci==3
	replace tipocontrato_ci=3 if (p511a==7 | tipocontrato_ci==.) & categopri_ci==3
	label var tipocontrato_ci "Tipo de contrato segun su duracion en act principal"
	label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
	label value tipocontrato_ci tipocontrato_ci
		

	**************
	***ocupa_ci: Variable categórica que indica la ocupación laboral de los ocupados en la actividad principal. Usa el clasificador internacional de ocupaciones CIUO, verificar con el clasificador que efectivamente los códigos de cada grupo estén bien.
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
	   *ypen_ci: Pensiones*
	*************
	gen pjub=p5564c*30 if p5564b==1 
	replace pjub=p5564c*4.3  if p5564b==2 
	replace pjub=p5564c*2  if p5564b==3 
	replace pjub=p5564c    if p5564b==4 
	replace pjub=p5564c/2  if p5564b==5 
	replace pjub=p5564c/3  if p5564b==6 
	replace pjub=p5564c/6  if p5564b==7 
	replace pjub=p5564c/12 if p5564b==8 
	replace pjub=.         if p5564c==999999

	generat pviudz=p5565c*30 if p5565b==1 
	replace pviudz=p5565c*4.3 if p5565b==2 
	replace pviudz=p5565c*2  if p5565b==3 
	replace pviudz=p5565c    if p5565b==4 
	replace pviudz=p5565c/2  if p5565b==5 
	replace pviudz=p5565c/3  if p5565b==6 
	replace pviudz=p5565c/6  if p5565b==7 
	replace pviudz=p5565c/12 if p5565b==8 
	replace pviudz=.         if p5565c==999999

	egen ypen_ci= rsum(pjub pviudz), m
	replace ypen_ci=. if pjub==. & pviudz==.
	label var ypen_ci "Valor de la pension contributiva"

	*************
	**pension_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación contributiva y con 0 al resto.*
	*************
	gen pension_ci= (ypen_ci>0 & ypen_ci!=.)
	label var pension_ci "1=Recibe pension contributiva"

	*****************
	**  ypensub_ci: Variable continua que indica el monto mensual de ingreso expresado en moneda local corriente recibido por la persona en concepto de pensión no contributiva.
  *
	*****************
	*pensión no contributiva
	gen p_pension65 = p5566c/2 
	gen p_juntos = p5567c/2
		
	gen ypensub_ci    =  p5566c/2 
	label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

	***************
	*pensionsub_ci*
	***************
	gen pensionsub_ci = ypensub_ci>0 & ypensub_ci!=.
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

	
/****** Variables de ingreso ******/

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

*B.Ingresos no laborales a nivel individuo

	*************
	***ynlm_ci***
	*************
	gen trans_corr_loc = d556t1/12
	gen trans_corr_ext = d556t2/12

	gen rentas = d557t/12 
	gen otros_ing = d558t/12
		
	egen ynlm_ci  = rowtotal(trans_corr_loc trans_corr_ext rentas otros_ing), missing 

	
	**************
	***ynlnm_ci***
	**************
	gen ynlnm_ci = (ig06hd+ig08hd+sig24+sig26+gru13hd1+gru13hd2+gru13hd3+gru23hd1+gru23hd2+gru23hd3+gru24hd+gru33hd1+gru33hd2+gru33hd3+(gru34hd-ga04hd)+gru43hd1+gru43hd2+gru43hd3+gru44hd+gru53hd1+gru53hd2+gru53hd3+gru54hd+gru63hd1+gru63hd2+gru63hd3+gru64hd+gru73hd1+gru73hd2+gru73hd3+gru74hd+gru83hd1+gru83hd2+gru83hd3+gru84hd+gru14hd3+gru14hd4+gru14hd5+sg42d+sg42d1+sg42d2+sg42d3) /(12 * nmiembros_ch)
	egen ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci)


*C. Ingresos laborales y no laborales a nivel hogar

	**************
	*** ylm_ch ***
	**************
	by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1

	**************
	*** ylnm_ch ***
	**************
	by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1


	*******************
	*** nrylmpri_ci ***
	*******************
	gen nrylmpri_ci=(ylmpri_ci==. & emp_ci==1)


	*******************
	*** nrylmpri_ch ***
	*******************
	by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
	replace nrylmpri_ch=. if nrylmpri_ch==.

	****************
	*** ylmnr_ch ***
	****************
	by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1
	replace ylmnr_ch=. if nrylmpri_ch==1

	***************
	*** ynlm_ch ***
	***************
	by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1
		
	****************
	*** ynlnm_ch *** PREGUNTAR QUE INCLUYE EN LO NO MONETARIO NO LABORAL
	****************
	by idh_ch, sort: egen ynlnm_ch=sum(ynlnm_ci) if miembros_ci==1

*D. Salario por hora

	*****************
	***ylhopri_ci ***
	*****************
	gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)


	***************
	***ylmho_ci : ***
	***************
	gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
		
*F. Remesas
	******************
	*** remesas_ci ***
	******************
	gen remesas_loc = d5563c/12
	gen remesas_ext = d5563e/12
	egen remesas_ci=rowtotal(remesas_loc remesas_ext), missing
		
	******************
	*** remesas_ch ***
	******************
	by idh_ch, sort: egen remesas_ch=sum(remesas_ci) if miembros_ci==1
	
	
/****** Variables de educacion ******/

	***************
	*** aedu_ci: Variable numérica que indica el número de años de educación culminados de las personas encuestadas.
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

	***************
	***edupre_ci: Variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo (lo cual es distinto a si asiste o no a la educación preescolar). 
	***************
	gen byte edupre_ci=(p301a==2) //Individuos con educación inicial completa
	replace edupre_ci=. if aedu_ci==.
	label variable edupre_ci "Educacion preescolar"
	
	**************
* Line of code with indicator edupi_ci was deleted	**************
	**************
* Line of code with indicator edupc_ci was deleted	**************
	**************
* Line of code with indicator edusi_ci was deleted	**************
	**************
* Line of code with indicator edusc_ci was deleted	**************
	***************
* Line of code with indicator edus1i_ci was deleted	***************
	***************
* Line of code with indicator edus1c_ci was deleted	***************
	***************
* Line of code with indicator edus2i_ci was deleted	***************
	***************
* Line of code with indicator edus2c_ci was deleted	***************


	**************
	***eduui_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica o universitaria incompleta y con 0 el resto
	**************
	gen byte eduui_ci = inlist(p301a, 7, 9) //7=Técnica Incompleta y 9=Universitaria Incompleta
	replace eduui_ci = . if aedu_ci == .
	label variable eduui_ci "Universitaria incompleta"

	***************
	***eduuc_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica, universitaria completa, o posgrado (completa o incompleta), y con 0 el resto. 
	***************
	gen byte eduuc_ci = inlist(p301a, 8, 10, 11) //8 Técnica Completa, 10 Universitaria Completa y 11 Maestria/Doctorado
	replace eduuc_ci = . if aedu_ci == .
	label variable eduuc_ci "Universitaria completa"

	**************
	***eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto. 
	**************
	gen eduac_ci = .
	replace eduac_ci = 1 if inlist(p301a, 9, 10, 11) // 9 Universitaria Incompleta, 10 Universitaria Completa, 11 Maestria/Doctorado
	replace eduac_ci = 0 if inlist(p301a, 7, 8) // 7 Técnica Incompleta, 8 Técnica Completa
	label variable eduac_ci "Superior universitario vs superior no universitario"

	***************
	***asiste_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza o institución de educación superior al momento de ser encuestado, con 0 si no asiste y con perdido el resto. 
	***************
	/*Se considera la variable de matricula y de asistencia, codificando como 1 a los que estan matriculados y no asisten por vacaciones*/
	g asiste_ci = (p306==1) // matriculados 
	replace asiste_ci=0 if p307==2 & p313!=6
	label variable asiste_ci "Asiste actualmente a la escuela"


	***************
	***edupub_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza pública al momento de la encuesta, con 0 si asiste a un centro de enseñanza privada, y con perdido si no asiste o no responde a la pregunta. 
	***************
	gen edupub_ci=.
	replace edupub_ci=1 if (p308d==1) & asiste_ci==1 // Estudian en instituciones publicas (p308d==1) y están matriculados (asiste_ci==1)
	replace edupub_ci=0 if (p308d==2) & asiste_ci==1 //Estudian en instituciones NO públicas (p308d==2) y están matriculados (asiste_ci==1)

	****************
	***asispre_ci: Asistencia a preescolar. Variable dicotómica que indica con valor 1 si la persona asiste actualmente a educación preescolar, y con 0 al resto (no tiene valores perdidos). 
	****************
	g asispre_ci= p308a==1  // matriculado en nivel inicial (sin edad)
	replace asispre_ci=0 if p307==2 & p313!=6 // matriculado pero no asiste (y no por vacaciones)
	la var asispre_ci "Asiste a educacion prescolar"


	
	*****************
* Line of code with indicator pqnoasis_ci was deleted	*****************



	**************
	*pqnoasis1_ci*
	**************
        * pqnoasis1_ci was replaced by razonesnoasis_ci, June 2025 * 

**********************
***razonesnoasis_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela.
**********************
	/* Categorias de razonesnoasis_ci:  
		1	problemas económicos/ por trabajo
		2	falta de interés/ problemas de 
			rendimiento
		3	quehaceres domésticos/ embarazo/ 
			cuidado de niños/as/ problemas 
			familiares o de salud
		4	problemas de acceso
		5	otros
	*/

	g razonesnoasis_ci = .
	replace razonesnoasis_ci = 1 if inlist(p313, 1, 2) // 1 Problemas económicos, 2 trabajo
	replace razonesnoasis_ci = 2 if p313 == 9 // 9 No le interesa el estudio
	replace razonesnoasis_ci = 3 if inlist(p313, 5, 10) // 5 Problemas Familiares, 10 Dedicación a quehaceres domésticos
	replace razonesnoasis_ci = 4 if p313 == 7 // 7 No hay centro de educación en el centro poblado
	replace razonesnoasis_ci = 5 if inlist(p313, 3, 4, 11) // 3 Terminó sus estudios: secundarios/ superiores /asiste a academia preuniversitaria, 4 No tiene la edad suficiente (para el grupo 3-5 años), 11. Otra razón


	label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" ///
	2 "Falta de interés/Problemas de rendimiento" ///
	3 "Cuidados/ Problemas familiares o de salud" ///
	4 "Problemas de acceso"  ///
	5 "Otros"
	label value  razonesnoasis_ci razonesnoasis_ci

	
****************************************************************************************	
*******************************************************************************
	
	
compress

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close