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
	

	
* 2.3.2 Situación de discapacidad	

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
	gen disWG_ci =dis_ci // Solo existe una pregunta  sobre limitación o dificultad PERMANENTE
	
	
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
 * pobre_ine _ci* // como se identifica pobreza extrema
****************	
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 0 if pobrezav==0
	replace pobre_ine_ci= 1 if pobrezav==1


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
