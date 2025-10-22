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


use `base_in', clear


********************************************************************************


********************  VARIABLES DEL IDENTIFICACION *****************************
********************************************************************************

/* 12 variables: region_BID_c , region_c , pais_c, anio_c, mes_c, zona_c, estrato_ci, */
/* upm_ci, idh_ch, idp_ci, factor_ch , factor_ci */


	********************
	*** region_BID_c : país de residencia de hogares según agrupación BID  ****
	********************
	gen byte region_BID_c=3 
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

	
	************************************************************
	* pais_c: acrónimo ISO del nombre del país de residencia   *
	************************************************************
	gen str3 pais_c="PER"
	
	******
	*anio_c : año de la entrevista de campo de la encuesta*
	******
	gen int anio_c=2024
		
		
	******
	*mes_c: al mes en el que se realizó cada entrevista*
	******
	tostring fecent, replace 
	gen int mes_c=real(substr(fecent,5,2))
		
		
	******
	*zona_c: dominio geográfico, área de residencia o zona *
	******
	*Urbano desde 2 000 habitantes en adelante / estratos del 1 al 5 
	gen byte zona_c= 0 if estrato>=6 /* Rural */
	replace  zona_c= 1 if estrato<6  /* Urbano */

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
	tostring idh_ch, replace


	***************
	****idp_ci (idindividuio) : Identificador único del individuo *****
	***************
	gen idp_ci = codperso
	tostring idp_ci, replace format ("%20.0f") 

	
*factor07 (factor expansion anual cpv), y facpob07 (factor expansion anual de poblacion proyecciones)-son iguales *
	
	
	*******************************************
	*Factor de expansion del hogar (factor_ch) : factor de ponderación de los hogares*
	*******************************************
	gen factor_ch= factor07	
	
	***********
	*factor_ci: factor de ponderación a la población total * 
	***********
	gen factor_ci=facpob07
	
	* de nuevo factor07 y facpob07 -- son iguales
	

********************************************************************************
***************   VARIABLES DEMOGRAFICAS   *************************************
********************************************************************************

	*********
	*sexo_ci: sexo del individuo*
	*********
	gen byte sexo_ci=p207
	
	
	*********
	*edad_ci: Edad del individuo expresada en número de años*
	*********
	/* p208a:  �que edad tiene en a�os cumplidos?  (en a�os)
    Va de 0 a 98 años -- tab p208a, m
		*/
	gen int edad_ci=p208a
	replace edad_ci=. if edad_ci==99

	
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


	*************
	*miembros_ci: Variable dicotómica que identifica a los miembros del 
	*hogar.
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci=. if relacion_ci==.

	******************
    ** miembros_one_ci **
    *****************
    gen byte miembros_one_ci=(p204==1) 
	replace miembros_one_ci=. if p204==.

		   
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

		
		
	**********
	*jefe_ci:Variable dicotómica que identifica al jefe del hogar.
	**********
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1)
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
		
		
	****************
	*nconyuges_ch: Variable que indica el N° de cónyuges o esposos/as en el hogar*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	
	***********
	*nhijos_ch: Variable que indica el número de hijos/as en el hogar.
	***********
	* Se construye a partir de la clasificación de la variable de relacion_ci
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          

	
	**************
	*notropari_ch: Variable que indica el número de otros parientes en el hogar.
	**************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.

		
	****************
	*notronopari_ch: Variable que indica el número de "no" parientes en el hogar.
	****************
	by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5)
	replace notronopari_ch =. if relacion_ci==.

		
	************
	*nempdom_ch: Número de empleados domésticos reportados en el hogar.*
	************
	*Se aproxima a esta medida usando la relacion de parentesco.
		by idh_ch, sort: egen nempdom_ch=sum(relacion_ci==6) // la categoria 6 dice "Empleado/a domestico/a"
	replace nempdom_ch =. if relacion_ci==.

	
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


	
	**************
	*nmiembros_ch: Indica el número total de miembros de categoría familiares en el hogar. *
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
	replace nmiembros_ch=. if relacion_ci ==.
	
	*************
	*nmayor21_ch: Indica el número total de miembros del hogar con 21 años o más de edad. *
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

	*************
	*nmenor21_ch: Indica el número total de miembros del hogar con menos de 
	*21 años.
	*************
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch: Indica el número total de miembros del hogar con 65 años o más de edad.*
	*************
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch: Indica el número total de miembros del hogar con menos de 6 años.*
	************
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch: Indica el número total de miembros del hogar con menos de 1 año.
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


********************************************************************************
***************   VARIABLES DE DIVERSIDAD   *************************************
********************************************************************************
* Modulo 500 - empleo

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
	*noafroind_ci: Identificar encuestados que NO son afrodescendientes NI indígenas según autoidentificación étnico-racial*
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
	
	*******************
	***afroind_ano_c***
	*******************
	gen afroind_ano_c=2017	

	************
	*afroind_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial.
	************
	gen byte afroind_ci=.
	replace afroind_ci = 1 if ind_ci==1 // Indígena
	replace afroind_ci = 2 if afro_ci==1 // Afrodescendiente
	replace afroind_ci = 3 if ind_ci==0 & afro_ci==0 // otros




	************
	*afroind_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente, indigena o como no afrodescendiente u indígena*
	************
 	gen  afroind_jefe = afroind_ci if jefe_ci==1 // Jefe
	
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 
	

	
* 2.3.2 Situación de discapacidad - modulo de salud

	********
	*dis_ci: Identifica a los individuos con discapacidad siguiendo de forma flexible el criterio del WG.
	********
	*Las variables de discapacidad son solo de discapacidad fisica?
	gen byte dis_ci=.
	replace dis_ci = 1 if (p401h1 == 1 | p401h2 == 1 | p401h3 == 1 | p401h4 == 1 | p401h5 == 1) 
	replace dis_ci = 0 if (p401h1 == 2 & p401h2 == 2 & p401h3 == 2 & p401h4 == 2 & p401h5 == 2) 
    
	*******************
	***disWG_ci: Identifica a individuos con discapacidad siguiendo de manera estricta el criterio del WG -- individuo como persona con discapacidad si reporta "mucha dificultad" o "no puede hacerlo" ***
	*******************
	gen disWG_ci =. // Solo existe una pregunta  sobre limitación o dificultad PERMANENTE
	
	
	*******************
	*** ISO3pais_dis_ci - PER_dis_ci -- Variable dicotomica generada para todos los países que incluyan cualquier tipo de pregunta sobre estado de discapacidad*
	*******************
	gen PER_dis_ci =dis_ci
	
	********
	*dis_ch : Identifica si un hogar tiene uno o más miembros con discapacidad*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	replace dis_ch =1 if dis_ch>=1 & dis_ch!=. // añadido por seguridad
	

********************************************************************************
***************   VARIABLES DE MERCADO LABORAL   *******************************
********************************************************************************

*************
	*condocup_ci: Identifica la condición de ocupación del individuo. *
	*************
	/* Variable de condición de acrividad económica de la encuesta - p501, p502 y p503 
	
	p501:LA SEMANA PASADA, DEL……...........… AL……..…., ¿TUVO UD. ALGÚN TRABAJO? (Sin contar los quehaceres del hogar)
	p502: AUNQUE NO TRABAJÓ LA SEMANA PASADA, ¿TIENE ALGÚN EMPLEO FIJO AL QUE PRÓXIMAMENTE VOLVERÁ?
	p503: AUNQUE NO TRABAJÓ LA SEMANA PASADA, ¿TIENE ALGÚN NEGOCIO PROPIO AL QUE PRÓXIMAMENTE VOLVERÁ?
	
	Categorias de condocup_ci:
			1	Ocupado
			2	Desocupado
			3	Inactivo
			4	Menor que la edad límite de los entrevistados
	*/	

	gen byte condocup_ci = .
	replace condocup_ci = 1 if p501==1 | p502==1 | p503==1    //Ocupados
	replace condocup_ci = 2 if p501==2 & p502==2 & p503==2    //Desocupados
	replace condocup_ci = 3 if condocup_ci == 2 & ( p5041==2 & p5042==2 & p5043==2 & p5044==2 & p5045==2 & p5046==2 & p5047==2 & p5048==2 & p5049==2 & p50410==2 & p50411==2 ) //Inactivos
	replace condocup_ci = 4 if edad_ci<14 //Según la encuesta, las preguntas sobre ocupación se hacen a personas de 14 años y más de edad
	
	
	*******************
	***categoinac_ci: Identifica la condición de inactividad de los individuos.***
	*******************
	/*

	�que estuvo haciendo la semana pasada - p546
	
	
	Categorias de categoinac_ci:
			1	Jubilados o pensionados
			2	Estudiantes
			3	Quehaceres domésticos
			4	Otros inactivos
	*/

	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if  (p546==6   & condocup_ci==3) //Jubilado o Pensionado
	replace categoinac_ci = 2 if  (p546 == 4 & condocup_ci == 3) //Estudiante
	replace categoinac_ci = 3 if  (p546 == 5 & condocup_ci == 3) //Quehaceres domesticos
	replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3) //Otros Inactivos
* Notar que pueden haber missings


	**********
	***emp_ci: Variable dicotómica que identifica con valor 1 a los ocupados y 0 a los no ocupados y mantiene con valores perdidos a los que se muestran en la encuesta con valores perdidos*
	**********
	*Codigo Extraido del Manual
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .	
	* Notar de la manera como está definido - niños menores tendrían cero de valor -- no missing -- sino cero


	**************
	***cesante_ci: Identifica a las personas que actualmente se encuentran desempleadas pero que habían trabajado anteriormente. Toma valor de 1 cuando la persona es cesante; 0 para el resto de los desocupados y con missing value al resto de la población.*** 
	**************
	/*¿Ha trabajado antes? (Sólo para desocupados e inactivos) -  p552:
			1	Si
			2	No
	*/
	gen byte cesante_ci = .
	replace cesante_ci = 1 if p552 == 1 & condocup_ci == 2 //Ha trabajado antes (p552==1) y ahora está desocupado (condocup_ci==2) 
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci ==2 //Se quedan con 0 las observaciones que son desocupados (condocup_ci==2)  pero no son cesantes (cesante_ci != 1)

		
	***************
	***desemp_ci: Variable dicotómica que identifica con valor 1 a los desocupados, 0 a los individuos que son parte del grupo de referencia y missing para el resto de la población.***
	***************	
	*Codigo estraído del manual
	gen byte desemp_ci = .
	replace desemp_ci  = (condocup_ci == 2) if condocup_ci! = .
	
	
	***************
	***subemp_ci: Variable dicotómica que indica con valor 1 si la persona trabaja 30 o menos horas a la semana en la actividad principal, está disponible para trabajar más horas y quiere/desea/está dispuesto a trabajar más horas (subempleo visible); y con valor 0 al resto de la población ocupada. ***
	***************
	*�cuantas horas trabajo la semana pasada, en su ocupacion principal, el dia: total - p513t 
	* LA SEMANA PASADA, ¿QUERÍA TRABAJAR MÁS HORAS DE LAS QUE NORMALMENTE TRABAJA? - p521
	* LA SEMANA PASADA, ¿ESTUVO DISPONIBLE PARA TRABAJAR MÁS HORAS? - p521a
	*****************
	gen horaspri_ci     = p513t 
	replace horaspri_ci = . if emp_ci~=1 // lo creo temporalmente
	
	gen byte subemp_ci = 0
	replace  subemp_ci = 1 if horaspri_ci<=30 & p521==1 & p521a==1 & emp_ci==1 	
	replace  subemp_ci = . if condocup_ci!=1	
	
	drop horaspri_ci
	
	
	****************
	***durades_ci: Indica la duración del desempleo en meses o el número de meses –no necesariamente consecutivos– que un individuo desempleado ha estado buscando empleo. Para los no desempleados la variable toma missing values.***
	****************
	*p551: ¿CUÁNTAS SEMANAS HA ESTADO BUSCANDO TRABAJO, SIN INTERRUPCIONES?
	gen     durades_ci = p551/4.3
	replace durades_ci=. if condocup_ci==1 //missing si la persona está ocupado - condocup_ci==1

	***********
	***pea_ci: Variable dicotómica que indica la población económicamente activa (PEA).***
	***********
	*Codigo extraido del manual
	gen byte pea_ci = .
	replace  pea_ci = 1 if inlist(condocup_ci,1,2) //Ocupados y Desocupados
	replace  pea_ci = 0 if inlist(condocup_ci,3,4) //Inactivos y menores de 15 años -
	
	****************
	*** nempleos_ci: Variable que indica el número de empleos que tiene la persona.**
	****************
    * El máximo número de empleos identificados es 2 *
	* p514: ADEMÁS DE SU OCUPACIÓN PRINCIPAL LA SEMANA PASADA, ¿TUVO UD. OTRO TRABAJO PARA OBTENER INGRESOS?
	* p515: LA SEMANA PASADA, ¿REALIZÓ ALGUNA OTRA ACTIVIDAD AL MENOS UNA HORA PARA OBTENER INGRESOS EN DINERO OEN ESPECIE, COMO:
	
	gen byte nempleos_ci=.
	replace  nempleos_ci=1 if emp_ci==1 // Identificamos por lo menos 1 empleo
	replace  nempleos_ci=2 if emp_ci==1 & p514==1 // Identificamos por lo menos 2 empleos
	replace  nempleos_ci=2 if emp_ci==1 & p514==2 & (p5151==1 | p5152==1 | p5153==1 | ///
			p5154==1 | p5155==1 | p5156==1 | p5157==1 | p5158==1 | p5159==1 | p51510==1 | ///
			p51511==1) // Declara no tner un segundo empleo pero realizó otra actividad por ingresos o especie
			
	******************
	***antiguedad_ci: Años de trabajo en la actividad principal actual de la persona ocupada. Cualquier duración menor a 12 meses se programa a 0 años.***
	******************
	* p513a1: ¿CUÁNTO TIEMPO TRABAJA UD. EN ESTA OCUPACIÓN PRINCIPAL? - Años
	* p513a2: ¿CUÁNTO TIEMPO TRABAJA UD. EN ESTA OCUPACIÓN PRINCIPAL? - Meses
	
	gen anios_a =p513a1
	gen meses_a =p513a2/12 // lo transformo a años
	
	egen byte antiguedad_ci = rsum(anios_a meses_a) if emp_ci == 1 //Se toman en cuenta solo a los ocupados
	replace   antiguedad_ci = 0 if antiguedad_ci <=1 & emp_ci == 1 //Cualquier duración menor a 12 meses se programa a 0 años.
	replace   antiguedad_ci =. if anios_a==. & meses_a==. & emp_ci == 1 //Se toman en cuenta solo a los ocupados
	
	drop anios_a meses_a
	
	
	
	***************
	***desalent_ci: Variable dicotómica que indica con el valor de 1 si las personas que se clasifican como inactivas declaran que no buscan trabajo por desanimo, cansancio o sentimiento de incapacidad. y con valor 0 al resto de los individuos de la población de referencia.***
	***************
		/* LA SEMANA PASADA, ¿HIZO ALGO PARA CONSEGUIR TRABAJO? - p545
		Sí - 1
		No - 2
		
		¿POR QUÉ NO BUSCÓ TRABAJO? - p549
		No hay trabajo     					 1
		Se cansó de buscar 					 2
		Por su edad  						 3
		Falta de experiencia  				 4
		Sus estudios no le permiten 		 5
		Los quehaceres del hogar no le permiten  6
		Razones de salud  					 7
		Falta de capital  					 8
		Espera los resultados de una búsqueda anterior  12
		Otro  								 9
		Ya encontró trabajo  				10
		Si buscó trabajo  					11				
	*/
	
	* Recordar condocup_ci==3  -- Inactivo
	
	gen byte desalent_ci=.
	replace desalent_ci=1 if condocup_ci==3 &  p545==2 &  (p549==1 | p549==2) //Se consideran los que creen que no les darán trabajo como desanimados
	replace desalent_ci=0 if condocup_ci==3 & desalent_ci==.  //Se pone como 0 al resto 
	
	
	***************
	***horaspri_ci: Variable continua que indica el número de horas totales trabajadas en la actividad principal en la semana de referencia.***
	***************
	*Horas trabajadas en la actividad principal - p513t: ¿CUÁNTAS HORAS TRABAJÓ LA SEMANA PASADA, EN SU OCUPACIÓN PRINCIPAL
	gen byte horaspri_ci   = .
	replace  horaspri_ci   = p513t if emp_ci==1
	replace  horaspri_ci   = . if emp_ci~=1 //Reemplazando los missings  y los que no trabajan
	
	
	
	***************
	***horastot_ci: Variable continua que indica el número de horas totales trabajadas en todas las actividades económicas en una semana.***
	***************	
	* p518: ¿CUÁNTAS HORAS TRABAJÓ LA SEMANA PASADA EN SU(S) OCUPACIÓN(ES) SECUNDARIA(S)?
	
	
	egen  horastot_ci   = rsum(horaspri_ci p518) if emp_ci==1
	replace  horastot_ci   = . if emp_ci~=1 //Reemplazando los missings  y los que no trabajan


	***************
	***tiempoparc_ci: Variable dicotómica que indica con valor 1 si la persona trabaja menos de 30 horas a la semana en la actividad principal y no desea trabajar más***
	***************
	*p521- LA SEMANA PASADA, ¿QUERÍA TRABAJAR MÁS HORAS DE LAS QUE NORMALMENTE TRABAJA?
	*		1	Sí
	*		2	No
	
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci   = (horaspri_ci<30 & p521==2 ) if  condocup_ci==1 //Si la  persona es ocupada (condocup_ci==1), trabaja menos de 30 horas (horaspri_ci<=30) y durante la semana pasada NO hubiese querido trabajar más (p521) se asigna 1. Al resto de personas ocupadas se les asigna 0. La variable queda con missings para las personas no ocupadas (condocup_ci!=1).
	
	
	
	***************
	***categopri_ci: Indica la categoría ocupacional de la actividad principal para los ocupados. (Solo aplica para los trabajadores ocupados emp_ci=1) ***
	***************	
	
	/*p507 - UD. SE DESEMPEÑÓ EN SU OCUPACIÓN PRINCIPAL O NEGOCIO COMO:
		1 -  ¿Empleador o patrono? 
		2-   ¿Trabajador independiente? 
		3-   ¿Empleado? 
		4-   ¿Obrero? 
		5 -  ¿Trabajador familiar no remunerado? 
		6 -  ¿Trabajador del hogar? 
		7 -  ¿Otro? 
	
	Categorias de categopri_ci: 
			0	Otra clasificación
			1	Patrón o empleador
			2	Cuenta Propia o independiente
			3	Empleado o asalariado
			4	Trabajador no remunerado
	*/
	
		gen categopri_ci=.
		replace categopri_ci=0 if condocup_ci==1 & p507==7  // Otra clasificación
		replace categopri_ci=1 if condocup_ci==1 & p507==1  // Patron o empleador
		replace categopri_ci=2 if condocup_ci==1 & p507==2  // Cuenta propia
		replace categopri_ci=3 if condocup_ci==1 & (p507==3 | p507==4 | p507==6) //Empleado
		replace categopri_ci=4 if condocup_ci==1 & p507==5 // Trabajador no remunerado

		label var categopri_ci "Categoria ocupacional actividad principal"
		label define categopri_ci 0 "Otra clasificación" 1 "Patrón o Empleador" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
		label value categopri_ci categopri_ci

	
	
		
	
	***************
	***categosec_ci: Indica la categoría ocupacional de la actividad secundaria. (Solo aplica para los trabajadores ocupados emp_ci=1).***
	***************
	/*517. ¿UD. SE DESEMPEÑÓ EN SU OCUPACIÓN SECUNDARIA O NEGOCIO COMO:
			Empleador o patrono?        		1
			Trabajador independiente?   		2
			Empleado?  							3
			Obrero? 							4
			Trabajador familiar no remunerado?  5
			Trabajador del hogar?   			6
			Otro?  								7

	Categorias de categopri_ci: 
			0	Otra clasificación
			1	Patrón o empleador
			2	Cuenta Propia o independiente
			3	Empleado o asalariado
			4	Trabajador no remunerado
	*/	
	gen 	categosec_ci=.
	replace categosec_ci=0 if condocup_ci==1 & p517==7 //Otra clasificación
	replace categosec_ci=1 if condocup_ci==1 & p517==1 //Patrón o Empleador
	replace categosec_ci=2 if condocup_ci==1 & p517==2  //Cuenta Propia o independiente
	replace categosec_ci=3 if condocup_ci==1 & (p517==3 | p517==4 | p517==6) //Empleado
	replace categosec_ci=4 if condocup_ci==1 & p517==5  //Trabajador  No Remunerado
			
	label define categosec_ci 0 "Otra clasificación" 1"Patron" 2"Cuenta propia" 
	label define categosec_ci 3"Empleado" 4 "Familiar No remunerado" , add
	label value categosec_ci categosec_ci
	label variable categosec_ci "Categoria ocupacional trabajo secundario"

	
	
	***************
	***rama_ci:Indica la actividad laboral de la ocupación principal según la Clasificación industrial Uniforme a un dígito con las que fueron codificadas las bases originales para su armonización. La mayoría de los países usan la clasificación CIIU pero en diferentes revisiones. Si la base de datos ya incluye esta variable es importante hacer un control de calidad y cerciorarse de la revisión que se está armonizando. Solo para los ocupados emp_ci=1.
	***************	
	/*Código rama de actividad ocupación principal - p506
			1 "Agricultura, caza, silvicultura y pesca"
			2 "Explotación de minas y canteras" 
			3 "Industrias manufactureras"
			4 "Electricidad, gas y agua"
			5 "Construcción" 
			6 "Comercio, restaurantes y hoteles"
			7 "Transporte y almacenamiento"
		    8 "Establecimientos financieros, seguros e inmuebles" 
			9 "Servicios sociales y comunales"
	
	Categorias de rama_ci:
			1	Agricultura, caza, silvicultura y pesca.
			2	Explotación de minas y canteras.
			3	Industrias manufactureras.
			4	Electricidad, gas y agua.
			5	Construcción.
			6	Comercio al por mayor y menor, restaurantes, hoteles.
			7	Transporte y almacenamiento.
			8	Establecimientos financieros, seguros, bienes inmuebles.
			9	Servicios sociales, comunales y personales.
			10	 Gobierno
	*/
	
		*************
		gen rama_ci=.
		replace rama_ci=1 if (p506>=111 & p506<=502)   & emp_ci==1 // Agricultura, caza, silvicultura y pesca.
		replace rama_ci=2 if (p506>=1010 & p506<=1429) & emp_ci==1 // Explotación de minas y canteras.
		replace rama_ci=3 if (p506>=1511 & p506<=3720) & emp_ci==1 // Industrias manufactureras.
		replace rama_ci=4 if (p506>=4010 & p506<=4100) & emp_ci==1 // "Electricidad, gas y agua"
		replace rama_ci=5 if (p506>=4510 & p506<=4550) & emp_ci==1 // Construcción.
		replace rama_ci=6 if (p506>=5010 & p506<=5520) & emp_ci==1 // Comercio al por mayor y menor, restaurantes, hoteles.
		replace rama_ci=7 if (p506>=6010 & p506<=6420) & emp_ci==1 //Transporte y almacenamiento.
		replace rama_ci=8 if (p506>=6511 & p506<=7020) & emp_ci==1 // "Establecimientos financieros, seguros e inmuebles" 
		replace rama_ci=9 if (p506>=7111 & p506<=9900) & emp_ci==1 // Servicios sociales, comunales y personales.

		label var rama_ci "Rama de actividad"
		label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
		label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
		label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
		label val rama_ci rama_ci
	
	
	
	***************
	***spublico_ci: Variable dicotómica que indica con valor 1 si la persona lleva a cabo su actividad laboral principal en el sector público y con valor 0 al resto de la población. Solo para los ocupados emp_ci=1.***
	***************	

	*****************
	* p510. EN SU OCUPACIÓN PRINCIPAL, ¿UD. TRABAJÓ PARA:
	/*
	1 - Fuerzas Armadas, Policía Nacional del Perú (militares)? 
	2 - Administración pública? 
	3 - Empresa pública? 
	5 - Empresas especiales de servicios (SERVICE)? 
	6 - Empresa o patrono privado? 
	7 - Otra? 
	*/
	
	*Codigo adaptado 
	gen byte spublico_ci=.
	replace spublico_ci = (p510==1 | p510==2 | p510==3) if emp_ci == 1 
	
	
	***************
	***tamemp_ci: Indica la categoría del tamaño de la empresa donde el individuo realiza su actividad laboral principal. ***
	***************	
	/* p512a - EN SU TRABAJO, NEGOCIO O EMPRESA, INCLUYÉNDOSE UD., ¿LABORARON:
	
	1  Hasta 20 personas? 
	2  De 21 a 50 personas? 
	3  De 51 a 100 personas? 
	4  De 101 a 500 personas? 
	5  Más de 500 personas? 
	
	p512b -  numero de personas - 
		
	Categorias de la variable tamemp_ci:
			1	Pequeña: de 1-5 personas en la empresa.
			2	Mediana: de 6-50 personas en la empresa.
			3	Grande: más de 50 personas en la empresa.
			.   no se cuenta con información
	*/

	gen     tamemp_ci=1 if p512b>=1 &  p512b<=5  // pequeña
	replace tamemp_ci=2 if p512b>=6 &  p512b<=50 // mediana
	replace tamemp_ci=3 if p512b>=51 &  p512b<9998 // Grande 
	* Al no incluir el valor 9998 - no cuento con 5000 observaciones
	* Este es un cambio - No pongo el igual en la tercera línea 
	replace tamemp_ci  = . if  categopri_ci==4 //Missings a los trabajadores del hogar 
	* Algunas personas declaran tamaño de empresa-- pesé a que declaran no estar ocupados
		
	label var  tamemp_ci "Tamaño de Empresa" 
	label define tamaño 1"Pequeña" 2"Mediana" 3"Grande"
	label values tamemp_ci tamaño

	
	
	***************
	***cotizando_ci: Variable dicotómica que indica con valor 1 si el asalariado o independiente cotiza a la seguridad social, de forma voluntaria o por medio de su empleador, en el periodo de referencia, con 0 a los desocupados o independientes que no responden, si la encuesta no les pregunta y con valores perdidos si la variable original lo tiene. ***
	*Se considera únicamente el sistema de pensiones público o privado (no salud) de la ocupación principal o secundaria*
	***************	
	/* p558a ¿EL SISTEMA DE PENSIONES AL CUAL UD. ESTÁ AFILIADO ES:

	1  Sistema privado de pensiones (AFP)? 
	2  Sistema Nacional de Pensiones: Ley 19990? 
	3  Sistema Nacional de Pensiones: Ley 20530 (Cédula viva)? 
	4  Otro? 
	5   No está afiliado 
	*/
	
	****************
	gen cotizando_ci=.
	replace cotizando_ci=1 if p558a1==1 | p558a2==1 | p558a3==1 // Sí está afiliado a la AFP o ONP
	replace cotizando_ci=0 if p558a4==1 | p558a5==1  // No está afiliado 
	label var cotizando_ci "Cotizante a la Seguridad Social"
	
	
	***************
	***instcot_ci: Variable categórica que indica la institución de la Seguridad Social a la cual cotiza o está afiliado. Contiene la información de la variable original de la base de datos. ***
	***************	
	gen  byte instcot_ci = . 
		
	replace   instcot_ci = 1 if p558a1==1               // AFP 
	replace   instcot_ci = 2 if p558a2==1 | p558a3==1   // ONP
	label var instcot_ci "Institucion a la que cotiza Seguridad social" 
	label define inst 1 "AFP" 2"ONP"
	label values instcot_ci inst
	
	
	***************
	***afiliado_ci: Variable dicotómica que indica con valor 1 si el trabajador está afiliado a la Seguridad Social (independientemente que haya o no cotizado en el mes de referencia), con 0 al resto del grupo de referencia y mantenemos con valores perdidos si la encuesta los tiene como perdidos***
	***************	
	gen  byte afiliado_ci = cotizando_ci // este es un arreglo imperfecto
	
	
	**************
	***formal_ci: Variable dicotómica que indica con valor 1 si el trabajador es formal y con 0 al resto. Un individuo se califica como formal si está afiliado o cotiza a la Seguridad Social. ***
	**************
	gen formal=1 if cotizando_ci==1 //Todos los que cotizan son formales

	gen byte   formal_ci=.
	replace    formal_ci=1 if formal==1 	& (condocup_ci==1 | condocup_ci==2)  // condocup_ci - ocupados y desocupados
	replace    formal_ci=0 if formal_ci==.  & (condocup_ci==1 | condocup_ci==2) 
	label var  formal_ci "formal -- 1= (afiliado o cotizante) & PEA"
	drop formal
	
	
	*******************
	***tipocontrato_ci: Variable categórica que indica el tipo de contrato laboral de los empleados/asalariados en la actividad principal según su duración (los trabajadores no asalariados deberían identificarse con valor perdido).***
	*******************
	/* BAJO QUÉ TIPO DE CONTRATO - p511a:
		1 - ¿Contrato indefinido, nombrado, permanente? 
		2 - ¿Contrato a plazo fijo (sujeto a modalidad)? 
		3 - ¿Está en período de prueba? 
		4 - ¿Convenios de Formación Laboral Juvenil / Prácticas Pre-Profesionales? 
		5 - ¿Contrato por locación de servicios (Honorarios Profesionales, R.U.C.), SNP? 
		6 - ¿Régimen Especial de Contratación Administrativa (CAS)? 
		7 - ¿Sin Contrato? 
		8 - ¿Otro? 
	
	Categorias de tipocontrato_ci:
			0	Con contrato
			1	Permanente/indefinido.
			2	Temporal/tiempo definido.
			3	Sin contrato/verbal
	*/
	
	*****************
	gen 	tipocontrato_ci=. 
	replace tipocontrato_ci=1 if (p511a==1) & categopri_ci==3 // Permanente/indefinido. - categopri_ci-empleado
	replace tipocontrato_ci=2 if (p511a>=2 & p511a<=6) & categopri_ci==3 // Temporal/tiempo definido. - categopri_ci-empleado
	replace tipocontrato_ci=3 if (p511a==7 | tipocontrato_ci==.) & categopri_ci==3 // Sin contrato/verbal
	
	label var tipocontrato_ci "Tipo de contrato segun su duracion"
	label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
	label value tipocontrato_ci tipocontrato_ci
	
	
	
	**************
	***ocupa_ci: Variable categórica que indica la ocupación laboral de los ocupados en la actividad principal***
	* Usa el clasificador internacional de ocupaciones CIUO * 
	**************
	/* ¿CUÁL ES LA OCUPACIÓN PRINCIPAL QUE DESEMPEÑÓ? : p505 -- revisión CIOU-88
			
	Categorias de ocupa_ci:
			1	Profesionales y técnicos.
			2	Directores y funcionarios superiores.
			3	Personal administrativo y nivel intermedio.
			4	Comerciantes y vendedores.
			5	Trabajadores en servicios.
			6	Trabajadores agrícolas y afines.
			7	Obreros no agrícolas, conductores de máquinas y ///
				vehículos de transporte y similares.
			8	Fuerzas Armadas.
			9	Otras ocupaciones no clasificadas en las anteriores.
	*/
	
	
	**************
	gen ocupa_ci=.
	replace ocupa_ci=1 if (p505>=211 & p505<=396) & emp_ci==1 // Profesionales y técnicos.
	replace ocupa_ci=2 if (p505>=111 & p505<=148) & emp_ci==1 // Directores y funcionarios superiores.
	replace ocupa_ci=3 if (p505>=411 & p505<=462) & emp_ci==1 // Personal administrativo y nivel intermedio.
	replace ocupa_ci=4 if (p505>=571 & p505<=583) | (p505>=911 & p505<=931) & emp_ci==1  // Comerciantes y vendedores.
	replace ocupa_ci=5 if (p505>=511 & p505<=565) | (p505>=941 & p505<=961) & emp_ci==1  // Trabajadores en servicios.
	replace ocupa_ci=6 if (p505>=611 & p505<=641) | (p505>=971 & p505<=973) & emp_ci==1  // Trabajadores agrícolas y afines.
	replace ocupa_ci=7 if (p505>=711 & p505<=886) | (p505>=981 & p505<=987) & emp_ci==1  // Obreros no agrícolas
	replace ocupa_ci=8 if (p505>=11 & p505<=24) & emp_ci==1								 // Fuerzas Armadas.

	label variable ocupa_ci "Ocupacion laboral"
	label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"Pers. administrativo y nivel intermedio"
	label define ocupa_ci  4 "comerciantes y vendedores" 5 "Trab. en servicios" 6 "trabajadores agricolas", add
	label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
	label define ocupa_ci  8 "FFAA" 9 "Otras Ocupaciones", add
	label value ocupa_ci ocupa_ci
	
	/*
	gen check =1 if ocupa_ci!=.
	tab p505 check if emp_ci==1, m 
	Comprobado
	*/
	
	
	**************
	**pension_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación contributiva y con 0 al resto***
	* entiendo que no hay missings posibles
	**************
	/*
	556. EN LOS ÚLTIMOS 6 MESES, DE…..... A......…, ¿RECIBIÓ UD. INGRESOS POR CONCEPTO DE
	p5564 - 4. Pensión de jubilación /cesantía? ..................
	p5564a / define si es que recibe o no
	*/
	gen pension_ci = (p5564a == 1)
	label var pension_ci "1=Recibe pension contributiva"
	* tab cotizando_ci pension_ci, m // tal vez no estoy definiendo bien "cotizando_ci"
	
		
	***************
	**pensionsub_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación NO contributiva (adultos mayores) y con 0 al resto. **
	***************
	/*
	556. EN LOS ÚLTIMOS 6 MESES, DE…..... A......…, ¿RECIBIÓ UD. INGRESOS POR CONCEPTO DE
	p5567 - 7. Transferencia del Programa Pensión 65?....
	p5567a / define si es que recibe o no
	- Solo las personas de 65 o mas responden a esta pregunta // pues solo ellos pueden recibir el programa
	* tab edad_ci p5567a , m nol
	*/
	
	*Programa Adulto Mayor // Pension 65
	gen      pensionsub_ci= (p5567a == 1)
	label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"
	
	
	
	***************
	**tipopen_ci: Variable categórica que indica el tipo de pensión contributiva o no contributiva según el país. Puede estar asociado a algún programa del gobierno o al sistema de seguridad social.**
	***************
	gen tipopen_ci=. //No existe exactamente una pregunta directa.
	
	
	***************
	**instpen_ci: Variable categórica que indica la institución que otorga la prestación previsional. Es la misma variable original de la base de datos, por lo que difiere en cada país y no está disponible en todos los casos.  **
	***************
		gen instpen_ci=. // no existe una variable original - exactamente
		label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 



********************************************************************************
***************   VARIABLES DE EDUCACION   *************************************
********************************************************************************
	

	***************
	*** aedu_ci: Variable numérica que indica el número de años de educación culminados de las personas encuestadas.
	***************
	egen grados = rowtotal(p301b  p301c), missing // necesaria temporalmente
		
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
	
    drop grados

	***************
	***edupre_ci: Variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo (lo cual es distinto a si asiste o no a la educación preescolar). 
	***************
	gen byte edupre_ci=(p301a==2) //Individuos con educación inicial completa
	replace edupre_ci=. if aedu_ci==.
	
	**************
	***eduui_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica o universitaria incompleta y con 0 el resto
	**************
	gen byte eduui_ci = inlist(p301a, 7, 9) //7=Técnica Incompleta y 9=Universitaria Incompleta
	replace eduui_ci = . if aedu_ci == .

	***************
	***eduuc_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica, universitaria completa, o posgrado (completa o incompleta), y con 0 el resto. 
	***************
	gen byte eduuc_ci = inlist(p301a, 8, 10, 11) //8 Técnica Completa, 10 Universitaria Completa y 11 Maestria/Doctorado
	replace eduuc_ci = . if aedu_ci == .

	**************
	***eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto. 
	**************
	gen eduac_ci = .
	replace eduac_ci = 1 if inlist(p301a, 9, 10, 11) // 9 Universitaria Incompleta, 10 Universitaria Completa, 11 Maestria/Doctorado
	replace eduac_ci = 0 if inlist(p301a, 7, 8) // 7 Técnica Incompleta, 8 Técnica Completa

	***************
	***asiste_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza o institución de educación superior al momento de ser encuestado, con 0 si no asiste y con perdido el resto. 
	***************
	/*Se considera la variable de matricula y de asistencia, codificando como 1 a los que estan matriculados y no asisten por vacaciones*/
	gen asiste_ci = (p306==1) // matriculados 
	replace asiste_ci=0 if p307==2 & p313!=6
	
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



**********************
	***pqnoasis1_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela.
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

	gen pqnoasis1_ci = .
	replace pqnoasis1_ci = 1 if inlist(p313, 1, 2) // 1 Problemas económicos, 2 trabajo
	replace pqnoasis1_ci = 2 if p313 == 9 // 9 No le interesa el estudio
	replace pqnoasis1_ci = 3 if inlist(p313, 5, 10) // 5 Problemas Familiares, 10 Dedicación a quehaceres domésticos
	replace pqnoasis1_ci = 4 if p313 == 7 // 7 No hay centro de educación en el centro poblado
	replace pqnoasis1_ci = 5 if inlist(p313,  11) // 11. Otra razón


	*label define pqnoasis1_ci 1 "Problemas económicos/Por trabajo" ///
	*2 "Falta de interés/Problemas de rendimiento" ///
	*3 "Cuidados/ Problemas familiares o de salud" ///
	*4 "Problemas de acceso"  ///
	*5 "Otros"
	*label value  pqnoasis1_ci pqnoasis1_ci
	
	
	
********************************************************************************
***************   VARIABLES DE VIVIENDA    *************************************
********************************************************************************	

	************
	***luz_ch: Indica si la principal fuente de iluminación del hogar es electricidad* 
	************
	gen luz_ch=p1121

	****************
	***luzmide_ch: Indica si el hogar usa un medidor para pagar por su consumo ***
	****************
	gen luzmide_ch=1 if p112a ==1 | p112a ==2
	replace luzmide_ch=0 if p112a==3

	****************
	***combust_ch: Indica si el combustible principal usado en el hogar para cocinar es gas o electricidad  ***
	****************
	gen combust_ch=1 if p113a==1 | p113a==2 | p113a==3
	replace combust_ch=0 if p113a==5 | p113a==6 | p113a==7 | p113a==4

	*************
	***piso_ch***
	*************
	gen piso_ch=.
	/*gen piso_ch=0 if p103==6
	replace piso_ch=1 if p103>=1 & p103<=5
	replace piso_ch=2 if p103==7
	label def piso_ch 0"Piso de tierra" 1"Materiales permanentes" 2"Otros materiales"
	label val piso_ch piso_ch

		
		
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
	gen pared_ch=.
	
	/* 
	gen pared_ch=0 if p102==4
	replace pared_ch=1 if p102==1 | p102==2 | p102==5 | p102==6 | p102==7 | p102==3 
	replace pared_ch=2 if p102>=8
     */
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
	gen techo_ch=.
	/*
	gen techo_ch=0 if p103a>=5 & p103a<=7
	replace techo_ch=1 if p103a>=1 & p103a<=4
	replace techo_ch=2 if p103a==8
*/
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
	***resid_ch: método de eliminación de residuos utilizado por el hogar.***
	**************
	gen resid_ch=.
		
	*************
	***dorm_ch: cantidad de habitación que se destinan exclusivamente para dormir***
	*************
	* MGR: se imputa 1 a aquellos hogares que indican tener 0 habitaciones exclusivas para dormir
	gen dorm_ch=p104a //pregunta: cuantas habitaciones se usan para dormir
	replace dorm_ch=1 if p104a==0
	
	****************
	***cuartos_ch: cantidad de habitaciones en el hogar ***
	****************
	gen cuartos_ch=p104

	***************
	***cocina_ch: existe un cuarto separado y exclusivo para cocinar ***
	***************
	gen cocina_ch=. // no he encontrado una pregunta directa

	**************
	***telef_ch: el hogar tiene servicio telefónico fijo ***
	**************
	gen telef_ch=(p1141==1) // pero hay otra pregunta por telefono celular

	***************
	***refrig_ch: si el hogar posee heladera o refrigerador ***
	***************
	gen refrig_ch=(p61212==1)
		
	**************
	***freez_ch:  si el hogar posee freezer o congelador ***
	**************
	gen freez_ch=.

	*************
	***auto_ch: si el hogar posee (tiene propiedad) al menos un automóvil particular**
	*************
	gen auto_ch =(p61217==1)

	**************
	***compu_ch: si el hogar posee computadora ***
	**************
	gen compu_ch=(p6127==1)

	*****************
	***internet_ch: si el hogar posee conexión a internet ***
	*****************
	gen internet_ch=(p1144==1)

	************
	***cel_ch: si al menos un integrante del hogar tiene servicio telefónico celular activa***
	************
	gen cel_ch=(p1142==1)

	**************
	***vivi1_ch: Tipo de vivienda en la que reside el hogar***
	**************
	gen vivi1_ch=1 if p101==1 // casa
	replace vivi1_ch=2 if p101==2 // Departamento
	replace vivi1_ch=3 if p101>2 & p101!=. // otros

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
	***vivi2_ch: vivienda en la que reside el hogar es una casa o un departamento***
	**************
	gen vivi2_ch=(p101<=2)
	replace vivi2_ch=. if p101==. 
	
	*****************
	***viviprop_ch: Propiedad de la vivienda en la que reside el hogar***
	*****************
	gen viviprop_ch=0 if p105a==1 // Alquilada
	replace viviprop_ch=1 if p105a==2 // Propia y totalmente pagada
	replace viviprop_ch=2 if p105a==4 // Propia y en proceso de pago
	replace viviprop_ch=3 if p105a==3 | (p105a>4 & p105a!=.) // Ocupada (propia de facto)
	
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
	***vivitit_ch: si el hogar posee un título de propiedad ***
	****************
	gen vivitit_ch=(p106a==1)
	
	****************
	***vivialq_ch: Monto mensual pagado por el alquiler de la vivienda***
	****************
	replace p105b=. if p105b==99999
	gen vivialq_ch=p105b if viviprop_ch==0 // pago si la vivienda es alquilada
	
	
	
	
	*******************
	***vivialqimp_ch: Monto mensual del valor que el informante cree que le pagarían por su vivienda propia que ocupa***
	*******************	
	gen vivialqimp_ch= ia01hd /12

		
********************************************************************************
***************   VARIABLES DE WASH        *************************************
********************************************************************************		

	****************
	***aguared_ch: Si la vivienda tiene acceso a agua mediante una red ***
	****************
	gen aguared_ch=0
	replace aguared_ch=1 if (p110==1 | p110==2)
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
	*aguafconsumo_ch: Principal fuente de agua utilizada por el hogar para beber*
	*****************
	gen aguafconsumo_ch = 0
	replace aguafconsumo_ch = 0 if p110a1==2 // El agua "no" es potable 
	replace aguafconsumo_ch = 1 if (p110==1 |p110==2) & p110a1==1
	replace aguafconsumo_ch = 2 if p110==3 & p110a1==1
	replace aguafconsumo_ch = 6 if p110==4
	replace aguafconsumo_ch = 8 if p110==8
	replace aguafconsumo_ch = 10 if (p110==5|  p110==6 |p110==7)


	*****************
	*aguafuente_ch: Principal fuente de agua utilizada por el hogar para todos los usos*
	*****************
	gen aguafuente_ch =.
	replace aguafuente_ch = 7 if p110a1==1
	replace aguafuente_ch = 1 if (p110==1|p110==2) 
	replace aguafuente_ch = 2 if p110==3
	replace aguafuente_ch = 6 if p110==4
	replace aguafuente_ch = 8 if p110==8 
	replace aguafuente_ch = 10 if (p110==5 |p110==7| p110==6)

	*****************
	*aguadist_ch: Ubicación de la principal fuente de agua*
	*****************
	gen aguadist_ch=.
	replace aguadist_ch= 1 if p110==1 // Dentro de la vivienda
	replace aguadist_ch= 2 if p110==2 // Fuera de la vivienda pero en el terreno
	replace aguadist_ch= 3 if p110 == 3 | p110 == 6 //Fuera de la vivienda y del terreno
	replace aguadist_ch= 0 if p110==4 | p110==5
	

	**************
	*aguadisp1_ch: si el hogar tiene continuidad de disponibilidad de agua *
	**************
	*Se toma en cuenta si tiene agua continua por 24 horas 
	gen aguadisp1_ch = (p110c1==24 | p110c3==24)

	**************
	*aguadisp2_ch: continuidad de disponibilidad de agua *
	**************
	gen aguadisp2_ch =.
	replace aguadisp2_ch = 1 if (p110c2<4 | p110c1 < 12 | p110c3 <12) 
	replace aguadisp2_ch = 2 if p110c2>=4 & (p110c1>=12 | p110c3 <12)
	replace aguadisp2_ch = 3 if p110c==1 & p110c1 == 24
    * p110c2 y p110c1 - cuantos dias a la semana y cuantas horas la día

	*************
	*aguatrat_ch: si el hogar trata el agua de su fuente antes de consumirla *
	*************
	gen aguatrat_ch = .

	*************
	*aguamala_ch si la principal fuente de agua es "Unimproved" según JMP *  
	*************
	gen aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10
		
	*****************
	*aguamejorada_ch: acceso a agua potable de fuente mejorada*  
	*****************
	gen aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7


	*****************
	***aguamide_ch: si el hogar usa un medidor para pagar por su consumo de agua ***
	*****************
	gen aguamide_ch=.

	*****************
	*bano_ch: Tipo de instalación sanitaria que tiene el hogar  *  
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
	*banoex_ch: Instalaciones del hogar son de uso exclusivo      *  
	*****************
	gen banoex_ch=.

	************
	*sinbano_ch: que hace los hogares sin acceso a instalaciones propias *
	************
	gen sinbano_ch = .

	*****************
	*banomejorado_ch: el hogar tiene acceso a saneamiento de fuente mejorado
	*****************
	gen banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6


********************************************************************************
***************   VARIABLES DE MIGRACION   *************************************
********************************************************************************	
			
/* Variables de migracion */
* La información proviene del Modulo 400 de  SALUD **
	*******************
	*** migrante_ci: Si el individuo nació en otro país ***
	*******************	
	* p401g2 en que distrito y provincia vivia su madre?
	gen migrante_ci=(p401g2<10000) if p401g2!=. & p401g2!=999999
		
	**********************
	*** migantiguo5_ci: si el migrante ha estado viviendo 5 años o más en el país de la encuesta***
	**********************
	*p401f hace 5 aos,... vivia en este distrito?
	gen migrantiguo5_ci=(migrante_ci==1 & (p401f==1 | (p401g>10000 & p401g!=.))) if migrante_ci!=. & p401f!=3 & p401g!=999999 & p401f!=. & !inrange(edad_ci,0,4)		
	
	**********************
	*** miglac_ci: si el individuo es migrante latino o del caribe***
	**********************
	gen miglac_ci=(inlist(p401g2,4002,4003,4004,4005,4006,4007,4009,4010,4011,4014,4015,4018,4019,4021,4022,4023,4024,4025,4026,4027,4030,4034,4035,4036,4037) & migrante_ci==1) if migrante_ci!=.
	replace miglac_ci = . if migrante_ci == 0
	** Fuente: Los codigos de paises se obtiene del censo de peru (redatam)	
	
	
********************************************************************************
***************   VARIABLES EXTERNAS   *************************************
********************************************************************************		
****************
 *tipo_bienestar*
****************
	/*
	1 Ingreso
	2 Consumo
	*/	
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 2 // consumo

****************
 * pobre_ine _ci* // como se identifica pobreza 
****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if pobreza==0
	replace pobre_ine_ci= 1 if (pobreza==1 | pobreza==2) 
	
* Dos variables en la base pobreza y pobrezav
* pobreza : Identifica pobreza extrema (1), pobreza no extrema (2), y no pobreza (3)
* pobrezav: Identifica pobreza extrema (1), pobreza no extrema (2),   vulnerable no pobre (3), y no vulnerable no pobre (4)

****************
 * bienestar_agregado * 
****************	
* gashog2d: gasto total bruto
*mieperho: miembros del hogar 
* En terminos mensuales para ser comparado con las lineas de pobreza mensuales
	gen bienestar_agregado = (gashog2d/(12*mieperho))

****************
 * lpe_ci *
****************	
	gen lpe_ci = . 
	replace lpe_ci = linpe


****************
 * ln_ci *
****************	
	gen ln_ci = . 
	replace ln_ci = linea


/*
¿Cómo replicamos el indicador de pobreza ?

* Pobreza
gen p = (bienestar_agregado<=linea)
tab p pobreza

* Pobreza extrema
gen p_ext = (bienestar_agregado<=linpe)
tab p_ext pobreza

*/	



********************************************************************************
********************************************************************************
	
	
	
	
	
	
	
****************************************************************************************	
*******************************************************************************
	
* Check
 /*order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación
	  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas
	  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas
	  afroind_ci afroind_ch afroind_ano_c dis_ci dis_ch /// Género y diversidad 
	  afro_ci ind_ci noafroind_ci afro_ch ind_ch noafroind_ch disWG_ci /// Género y diversidad 
          condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
	  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo
	  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo
	  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci ynlm_publico_ci ynlm_privado_ci  /// Ingresos individuo
	  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ynlm_publico_ch ynlm_privado_ch  ytot_ch /// Ingresos del hogar
	  ylmhopri_ci ylmho_ci /// ingreso por hora
	  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos 
	  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
          aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci pqnoasis1_ci asispre_ci /// Educación 
	  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda 
	  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
	  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
	  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
	  migrante_ci migrantiguo5_ci miglac_ci /// Migración  
	  nmiembros_sph_ch yneto_pc_ch bene_cash_ch pensionsub_ch   /// Protección social 
          ynlm_publico_ch ynlm_privado_ch ynlm_privado_ci ynlm_publico_ci  /// Protección social ingresos
 	  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c ratio_cpi2011 ratio_cpi2017 cpi_c cpi2011 cpi2017 ppp_c ppp_2011 ppp_2017, first /// Fuente externa
	*/
	
	

compress

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
