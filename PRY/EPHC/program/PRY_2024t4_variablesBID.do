*(Versión stata 18)

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

local PAIS PRY
local ENCUESTA EPHC
local ANO "2024"
local ronda t4

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
        
capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: Paraguay
Encuesta: EPHC
Round: t4
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
	gen byte region_BID_c=4 
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c


	********************
	*** region_c: Identifica  primera división político-administrativa del país****
	********************
	*En Paraguay de divide clasifica cada región de 2 formas, la zona rural y urbana
	*La codificación que sigue la encuesta de Paraguay es la siguiente
	/* Categorias de la variable estgeo (Estrato geográfico):
		Asunción 			1
		Concepción urbano 	11       Concepción rural 	16
		San Pedro urbano 	21       San Pedro rural 	26
		Cordillera urbano 	31       Cordillera rural 	36
		Guairá urbano 		41       Guairá rural 		46
		Caaguazú urbano 	51       Caaguazú rural 	56
		Caazapá urbano 		61       Caazapá rural 		66
		Itapúa urbano 		71       Itapúa rural 		76
		Misiones urbano 	81       Misiones rural 	86
		Paraguarí urbano 	91       Paraguarí rural 	96
		Alto Paraná urbano 	101      Alto Paraná rural 	106
		Central urbano 		111      Central rural 		116
		Ñeembucú urbano 	121      Ñeembucú rural 	126
		Amambay urbano 		131      Amambay rural 		136
		Canindeyú urbano 	141      Canindeyú rural 	146
		Pdte Hayes urbano 	151      Pdte Hayes rural 	156
	*/	
	gen region_c    = 1 if estgeo 	== 1 						// Asunción
	replace region_c= 2 if (estgeo 	== 21 	| estgeo==26)		// San Pedro		  
	replace region_c= 3 if (estgeo 	== 51 	| estgeo==56) 		// Caaguazú			  
	replace region_c= 4 if (estgeo 	== 71 	| estgeo==76) 		// Itapúta		
	replace region_c= 5 if (estgeo 	== 101 	| estgeo==106) 		// Alto Paraná
	replace region_c= 6 if (estgeo 	== 111 	| estgeo==116) 		// Central		
	replace region_c= 7 if (estgeo 	== 11 	| estgeo==16) 		// Concepción
	replace region_c= 8 if 	(estgeo 	== 31 	| estgeo==36)	// Cordillera	
	replace region_c= 9 if 	(estgeo 	== 41 	| estgeo==46)	// Guarirá
	replace region_c= 10 if (estgeo 	== 61 	| estgeo==66)	// Caazapá
	replace region_c= 11 if (estgeo 	== 81 	| estgeo==86)	// Misiones	
	replace region_c= 12 if (estgeo 	== 91 	| estgeo==96)	// Paraguarí
	replace region_c= 13 if (estgeo 	== 121 	| estgeo==126)	// Neembucú	
	replace region_c= 14 if (estgeo 	== 131 	| estgeo==136)	// Amambay	
	replace region_c= 15 if (estgeo 	== 141 	| estgeo==146)	// Canindeyú	
	replace region_c= 16 if (estgeo 	== 151 	| estgeo==156)	// Pdte Hayes	

	label define region_c ///
	1 "Asunción" ///
	2 "San Pedro" ///
	3 "Caaguazú" ///
	4 "Itapúa" ///
	5 "Alto Paraná" ///
	6 "Central" ///
	7 "Concepcion" ///
	8 "Cordillera" ///
	9 "Guairá" ///
	10 "Caazapá" ///
	11 "Misiones" ///
	12 "Paraguarí" ///
	13 "Neembucú" ///
	14 "Amambay" ///
	15 "Canindeyú" ///
	16 "Pdte Hayes"
	label value region_c region_c
	label var region_c "División política"
	
	************************************************************
	* pais_c: acrónimo ISO del nombre del país de residencia   *
	************************************************************
	gen str3 pais_c="PRY"

	******
	*anio_c : año de la entrevista de campo de la encuesta*
	******
	gen int anio_c = 2024	
	
	******
	*mes_c: al mes en el que se realizó cada entrevista*
	******
	gen int mes_c=.	// No hay variable de mes en la encuesta
	
	******
	*trimestre_c: trimestre en el que se realizó cada entrevista*
	******
	*Como la ronda de la encuesta es por trimestre se crea esta variable 
	*(ver el manual)
	gen trimestre_c=4	

	******
	*zona_c: dominio geográfico, área de residencia o zona *
	******
	/*La variable de zona en la encuesta de paraguay es area y codifica como: 
			1	Urbano
			6	Rural
	*/
	gen zona_c=.
	replace zona_c=1 if area==1 	// Urbana
	replace zona_c=0 if area==6		// Rural
	replace zona_c=. if zona_c==.	// Missings
	label variable zona_c "Zona del país" 
	label define zona_c 1 "Urbana" 0 "Rural" 
	label value zona_c zona_c 
	
	*********
	*estrato : Conjunto de s viviendas particulares y sus ocupantes en un area geografica*
	*********
	gen estrato_ci=. // No hay variable de estrato
	
	 *****************************
	*unidad primaria de muestreo*
	*****************************
	gen upm_ci=upm // Variable de Unidad Primaria de Muestreo de la encuesta (upm)
	
	******************
	*idh_ch: Identificador único de hogares*
	******************
	*De acuerdo con el diccionario de la encuesta, identificador unico de hogares se construye con las variables unidad primaria de muestreo (upm), número de vivienda (nvivi) y número de hogar (nhoga)
	sort upm nvivi nhoga
	egen idh_ch=group(upm nvivi nhoga)
	tostring idh_ch, replace

	***************
	****idp_ci*****
	***************
	*De acuerdo con el diccionario de la encuesta, identificador unico del individuo se construye con el identificador de hogares (construido arriba) y la variable línea de la persona (l02)
	egen idp_ci = concat(idh_ch l02)
	tostring idp_ci, replace format ("%20.0f") 
	
	*******************************************
	*Factor de expansion del hogar (factor_ch) : factor de ponderación de los hogares*
	*******************************************
	gen factor_ch=facpob //Igual al del individiuo 
	
	***********
	*factor_ci: factor de ponderación a la población total * 
	***********
	gen factor_ci=facpob //Igual al de los hogares
	

****************************
***VARIABLES DEMOGRAFICAS***
****************************

	*********
	*sexo_ci: sexo del individuo*
	*********
	/*Variable de sexo de la encuesta - p06:
			Hombres		1
			Mujeres		6
	*/
	gen byte sexo_ci=.
	replace sexo_ci = 1 if p06==1	//Hombres
	replace sexo_ci = 2 if p06==6	//Mujeres
	replace sexo_ci =. 	if p06==. 	//Missings

	*********
	*edad_ci: Edad del individuo expresada en número de años*
	*********
	gen int edad_ci=.
	replace edad_ci=p02 //Variable de edad de la encuesta (p02)
	
	**************
	**relacion_ci: Variable que indica la relación o parentesco del individuo respecto al jefe de hogar
	**************
	*La variable de relación de parentesco con el jefe del hogar de la encuesta es p03
	/* Categorias de p03: 
			1	Jefe/a								
			2	Esposo/a, compañero/a				
			3	Hijo/a								
			4	Hijastro/a							
			5	Nieto/a								
			6	Yerno/Nuera							
			7	Padre/Madre							
			8	Suegro/a							
			9	Otro pariente						
			10	No pariente							
			11	Trabajador/a doméstico/a			
			12	Familiar del trabajador doméstico	
	*/
	
	/* Categorías de relación de parentesco del BID:
			1	Jefe/a del hogar
			2	Cónyuge/pareja (casados, unión libre, mismo sexo)
			3	Hijo/a (biológico, adoptado, hijastro, pareja no casada)
			4	Otros parientes (abuelos, nietos, hermanos, tíos, sobrinos, primos,
				suegros, yernos/nueras, etc.)
			5	No parientes (amigos, inquilinos, visitantes, ex-cónyuges, 
				padrinos/ahijados)
			6	Empleado/a doméstico/a
			.	Desconocido/No responde/Indeterminado
	*/

	gen relacion_ci=.
	replace relacion_ci=1 if p03==1 //Jefe del Hogar
	replace relacion_ci=2 if p03==2  //Cónyuge/pareja
	replace relacion_ci=3 if p03==3 | p03==4 //Hijos o Hijastros
	replace relacion_ci=4 if p03==5 | p03==6 | p03==7 | p03==8 | p03==9 // Otros Parientes
	replace relacion_ci=5 if p03==10 // No parientes
	replace relacion_ci=6 if p03>=11 //Trabajador Doméstico

	label variable relacion_ci "Relacion con el jefe del hogar"
	label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" ///
	5 "Otros no parientes"
	label define relacion_ci 6 "Empleado/a domestico/a", add
	label value relacion_ci relacion_ci	
	
	*************
	*miembros_ci: Variable dicotómica que identifica a los miembros del hogar.
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	
	******************
    ** miembros_one_ci: Variable dicotómica que identifica a los miembros del hogar según la definición disponible en cada encuesta **
    *****************
	/*Variable p04 ¿Es miembro del hogar?
			1 Sí
			6 No
	*/	
	gen miembros_one_ci=.
	replace miembros_one_ci=1 if p04==1	//Miembro del Hogar
	replace miembros_one_ci=0 if p04==6	//NO es Miembro del Hogar
	replace miembros_one_ci=. if p04==. //Missings
	
	**************
	*civil_ci: Estado Civil*
	**************
	/*Categorias de la variable de estado civil de la encuesta - p09:
			1	Casado
			2	Unido
			3	Separado
			4	Viudo
			5	Soltero
			6	Divorciado
			9	NR
	*/
	
	/*Categorias del BID:
			1 Soltero
			2 Unión formal o informa
			3 Divorciado o separado
			4 Viudo
	*/
	gen civil_ci=.
	replace civil_ci=1 if p09==5			//Soltero
	replace civil_ci=2 if p09==1 | p09==2 	//Casado o Unido
	replace civil_ci=3 if p09==3 | p09==6 	//Divorciado o Separado
	replace civil_ci=4 if p09==4			//Viudo 
	label variable civil_ci "Estado civil"
	label define civil_ci 1 "Soltero" 2 "Union formal o informal"
	label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
	label value civil_ci civil_ci
		
	**********
	*jefe_ci:Variable dicotómica que identifica al jefe del hogar.
	**********
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	gen byte jefe_ci=.
	replace jefe_ci = 1 if (relacion_ci==1) // Jefe del Hogar
	replace jefe_ci = 0 if (relacion_ci!=1) & (relacion_ci!=.)
	label variable jefe_ci "Jefe de hogar"	
	
	****************
	*nconyuges_ch: Variable que indica el N° de cónyuges o esposos/as en el hogar*
	**************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2) // Suma de N° Cónyugues
    replace nconyuges_ch =. if relacion_ci==.
	label variable nconyuges_ch "Numero de conyuges"
	
	***********
	*nhijos_ch: Variable que indica el número de hijos/as en el hogar.
	***********
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3) //Suma de N° de Hijos
	replace nhijos_ch =. if relacion_ci==.          
	label variable nhijos_ch "Numero de hijos"
	
	**************
	*notropari_ch: Variable que indica el número de otros parientes en el hogar.
	**************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4) //Suma de N° de otros Parientes
	replace notropari_ch =. if relacion_ci==.
	
	****************
	*notronopari_ch: Variable que indica el número de "no" parientes en el hogar.
	****************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5) //Suma de N° de no parientes
	replace notronopari_ch=. if relacion_ci==.          
		
	************
	*nempdom_ch: Número de empleados domésticos reportados en el hogar.*
	************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6) // la categoria 6 dice "Empleado/a domestico/a"
	replace nempdom_ch =. if relacion_ci==.
         
	*************
	*clasehog_ch: Identifica el tipo de hogar según la cantidad de individuos.
	*************
* Se construye a partir de la clasificación de la variable de relacion_ci (ver el manual)

	/*
		1 	Unipersonal: hogares formados por un solo miembro.
		
		2 	Nuclear: hogares con o sin cónyuge formados por un jefe(a) y sus 
			hijos u hogares que están formados por el jefe y su cónyuge, aunque no
			reporten hijos. En este hogar no residen otros 
			parientes o no parientes.
		
		3 	Ampliado: hogares nucleares con al menos un pariente o integrados 
			por un jefe y al menos otro 
			pariente.
		
		4 	Compuesto: hogar nuclear o ampliado y al menos un integrante no 
			pariente.
		
		5 	Corresidente: Hogar sin hijos, cónyuge ni otros parientes, pero 
			con jefe y al menos un integrante 
			no pariente. 
	*/

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
	*nmiembros_ch: Indica el número total de miembros de categoría familiares en el hogar.
	**************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch: Indica el número total de miembros del hogar con 21 años o más de edad. *
	*************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))

	*************
	*nmenor21_ch: Indica el número total de miembros del hogar con menos de 
	*21 años.
	*************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual
	by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))

	*************
	*nmayor65_ch: Indica el número total de miembros del hogar con 65 años o más de edad.*
	*************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual	
	by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))

	************
	*nmenor6_ch: Indica el número total de miembros del hogar con menos de 6 años.*
	************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual	
	by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))

	************
	*nmenor1_ch: Indica el número total de miembros del hogar con menos de 1 año.
	************
	*Se construye a partir de la clasificación de la variable de relacion_ci
	*Codigo extraido del manual	
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))

	
********************************************************************************
***************   VARIABLES DE DIVERSIDAD   ************************************
********************************************************************************
*En toda la encuesta no hay preguntas relacionadas a la diversidad. Las variables de diversidad se toman en una encuesta aparte, la encuesta más reciente es el IV Censo Nacional Indígena realizado en el 2022.

	*********
	*afro_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial afrodescendiente*
	*********
	gen byte afro_ci = . 	  // se queda como missing (.) no existe la pregunta
	
	*********
	*indi_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial indígena - p558c: ¿Cómo se autoidentifica el encuestado?
	*********	
	gen byte ind_ci =. 		  // se queda como missing (.) no existe la pregunta

	**************
	*noafroind_ci: Identificar encuestados que NO son afrodescendientes NI indígenas según autoidentificación étnico-racial*
	**************
	gen byte noafroind_ci =.   // se queda como missing (.) no existe la pregunta

	*********
	*afro_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente*
	*********
	gen byte afro_jefe =.   //se queda como missing (.) no existe la pregunta
		
	********
	*ind_ch: Identifica si el jefe de hogar se autoidentifica como indígena.
	********		
	gen byte ind_jefe =.   // se queda como missing (.) no existe la pregunta

	**************
	*noafroind_ch: identifica si el jefe de hogar no se autoidentifica como parte de la población indígena ni afrodescendiente:*
	**************
	gen byte noafroind_jefe =.	// se queda como missing (.) no existe la pregunta
	
	*******************
	***afroind_ano_c: Año en el que se empezó a usar la metodología actual para las variables de diversidad***
	*******************
	gen afroind_ano_c=.	 // se queda como missing (.) no existe la pregunta

		************
	*afroind_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial.
	************
	gen byte afroind_ci=. // se queda como missing (.) no existe la pregunta

	************
	*afroind_ch*
	************
 	gen byte afroind_jefe =. // se queda como missing (.) no existe la pregunta
	
	
* 2.3.2 Situación de discapacidad	

	********
	*dis_ci: Identifica a los individuos con discapacidad siguiendo de forma flexible el criterio del WG.
	********
	gen byte dis_ci=. // se queda como missing (.) no existe la pregunta
	
	*******************
	***disWG_ci: Identifica a individuos con discapacidad siguiendo de manera estricta el criterio del WG -- individuo como persona con discapacidad si reporta "mucha dificultad" o "no puede hacerlo" ***
	*******************
	gen byte disWG_ci=. // se queda como missing (.) no existe la pregunta
	
		*******************
	*** ISO3pais_dis_ci - PER_dis_ci -- Variable dicotomica generada para todos los países que incluyan cualquier tipo de pregunta sobre estado de discapacidad*
	*******************
	gen byte ARG_dis_ci = . // se queda como missing (.) no existe la pregunta
	
	********
	*dis_ch*
	********
	gen byte dis_ch =. // se queda como missing (.) no existe la pregunta
	

	
********************************************************************************
***************   VARIABLES DE MERCADO LABORAL   *******************************
********************************************************************************

	*************
	*condocup_ci: Identifica la condición de ocupación del individuo. *
	*************
	/* Variable de condición de acrividad económica de la encuesta - peaa:
			1	Ocupados
			2	Desocupados
			3	Inactivos
			9	No responde
			0	NA
	
	Categorias de condocup_ci:
			1	Ocupado
			2	Desocupado
			3	Inactivo
			4	Menor que la edad límite de los entrevistados
	*/	
	gen byte condocup_ci = peaa //Las 3 primeras categorias son las mismas para ambas variables
	replace condocup_ci = . if peaa==9 | peaa==0 | peaa==. //Reemplazando los missings o no responden
	replace condocup_ci = 4 if edad_ci<10 //La edad límite de los entrevistados es es de 10 años, los de 9 años o menos no responden la pregunta

	*******************
	***categoinac_ci: Identifica la condición de inactividad de los individuos.***
	*******************
	/*Variable de razón de inactividad de la encuesta - ra06ya09:
			1	Estudiante
			2	Labores del Hogar
			3	No consigue trabajo
			4	Enfermo
			5	Anciano
			6	Discapacitado
			7	Jubilado o Pensionado
			8	Motivos familiares
			9	Otra situación
			.	NA
	
	Categorias de categoinac_ci:
			1	Jubilados o pensionados
			2	Estudiantes
			3	Quehaceres domésticos
			4	Otros inactivos
	*/
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (ra06ya09 == 7 & condocup_ci == 3) //Jubilado o Pensionado
	replace categoinac_ci = 2 if  (ra06ya09 == 1 & condocup_ci == 3) //Estudiante
	replace categoinac_ci = 3 if  (ra06ya09 == 2 & condocup_ci == 3) //Labores del Hogar
	replace categoinac_ci = 4 if (categoinac_ci!=1 & categoinac_ci!=2 & categoinac_ci!=3) & condocup_ci == 3 //Otros Inactivos

	**********
	***emp_ci: Variable dicotómica que identifica con valor 1 a los ocupados y 0 a los no ocupados y mantiene con valores perdidos a los que se muestran en la encuesta con valores perdidos*
	**********
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de 	referencia de la sección laboral de la Encuesta *****.
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if (condocup_ci != . & condocup_ci != 4)
	label var emp_ci "Ocupado (empleado)"
	label define emp_ci 0"No" 1"Si", add
	label value emp_ci emp_ci

	**************
	***cesante_ci: Identifica a las personas que actualmente se encuentran desempleadas pero que habían trabajado anteriormente. Toma valor de 1 cuando la persona es cesante; 0 para el resto de los desocupados y con missing value al resto de la población.*** 
	**************
	/*¿Ha trabajado anteriormente? - a12:
			1	Sí
			6	No
			9	No responde
	*/
	gen byte cesante_ci = .
	replace cesante_ci = 1 if a12==1 & condocup_ci==2 //Ha trabajado anteriormente (a12==1) y ahora está desocupado (condocup_ci==2)
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci ==2 //Toma el valor de 0 para el resto de desocupados y lo que queda de la población son missing values

	***************
	***desemp_ci: Variable dicotómica que identifica con valor 1 a los desocupados, 0 a los individuos que son parte del grupo de referencia y missing para el resto de la población.***
	***************	
	*Codigo extraído del manual
	***** El código mantiene como missing values a la poblacion menor de la edad limite de la PET que no forman parte de la población de referencia de la sección laboral de la Encuesta *****.
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if (condocup_ci != . & condocup_ci != 4)
	label var desemp_ci "Desocupado (desempleado)"
	label define desemp_ci 0"No " 1"Si", add
	label value desemp_ci desemp_ci
	
	***************
	***subemp_ci: Variable dicotómica que indica con valor 1 si la persona trabaja 30 o menos horas a la semana en la actividad principal, está disponible para trabajar más horas y quiere/desea/está dispuesto a trabajar más horas (subempleo visible); y con valor 0 al resto de la población ocupada. ***
	***************
	/*¿Cuál es la razón principal por al que desea mejorar o cambiar o adicionar su empleo actual? - d05:
			6	Desea trabajar más horas y ganar más

	Horas semanales trabajas en la actividad principal habitualmente - horab
	
	En los últimos 7 días ¿estuvo disponible para trabajar más horas? - d01
			1	Sí
			6	No
			9	No Responde
	*/

	gen byte subemp_ci = 0
	replace subemp_ci = 1 if horab<30 & d05==6 & d01==1 //Según el manual, se toma en cuenta a los individuos que trabajan menos de 30 horas (horab<30), desean trabajar más horas (d05==6) y tienen la disponibilidad de tiempo para hacerlo (d01==1)
	replace subemp_ci = . if condocup_ci!=1 //Se reemplaza como missing al resto de la población no ocupada

	****************
	***durades_ci: Indica la duración del desempleo en meses o el número de meses –no necesariamente consecutivos– que un individuo desempleado ha estado buscando empleo. Para los no desempleados la variable toma missing values.***
	****************
	*Años, hasta la fecha, que ha estado buscando trabajo		a11a
	*Meses, hasta la fecha, que ha estado buscando trabajo		a11m
	*Semanas, hasta la fecha, que ha estado buscando trabajo	a11s
	
	/*Si una de estas variables es distinta de 0, las otras 2 son cero. Por ejemplo, si una persona lleva 6 meses buscando trabajo, el valor de las variables sería el siguiente:
			a11a	a11m	a11s
			0		6		0
	Si una persona lleva 2 años buscando trabajo, el valor de las variable sería:
			a11a	a11m	a11s
			2		0		0
	Si una persona lleva 5 semanas buscando trabajo, el valor de las variables sería:
			a11a	a11m	a11s
			0		0		5
	*/
	
	gen a11s_c=a11s*(52/12) //Conversión a frecuencia mensual según el manual
	gen a11a_c=a11a/12		//Conversión a frecuencia mensual según el manual
	
	*Dada la estructura de las variables mostrada anteriormente, se puede crear la siguiente variable:
	gen durades_ci = a11a_c + a11m + a11s_c
	replace durades_ci=. if condocup_ci==1
	drop a11s_c a11a_c
	
	***********
	***pea_ci: Variable dicotómica que indica la población económicamente activa (PEA).***
	***********
	*Codigo extraido del manual
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2) //Ocupados y Desocupados
	replace pea_ci = 0 if inlist(condocup_ci,3,4) //Inactivos y menores de 10 años
		
	****************
	*** nempleos_ci: Variable que indica el número de empleos que tiene la persona.**
	****************
	*¿Cuántos trabajos/empleos tenía en los últimos 7 días?	- a04a
	gen byte nempleos_ci=.
	replace nempleos_ci=a04a if emp_ci==1 //Se toman en cuenta solo a los ocupados

	******************
	***antiguedad_ci: Años de trabajo en la actividad principal actual de la persona ocupada. Cualquier  duración menor a 12 meses se programa a 0 años.***
	******************
	*Años de su vida que ha trabajado en la ocupación principal - b07a
	gen byte antiguedad_ci = b07a if emp_ci == 1 //Se toman en cuenta solo a los ocupados
	
	***************
	***desalent_ci: Variable dicotómica que indica con el valor de 1 si las personas que se clasifican como inactivas declaran que no buscan trabajo por desanimo, cansancio o sentimiento de incapacidad. y con valor 0 al resto de los individuos de la población de referencia.***
	***************
	***** El código mantiene como población de referencia a las personas inactivas (condocup_ci == 3) *****.
*destring s04a_07, ignore("NA") replace
	gen byte desalent_ci = .
	replace desalent_ci = 1 if (a08 == 6 & inlist(a09, 2, 3) & condocup_ci == 3)
	replace desalent_ci = 0 if (desalent_ci != 1 & condocup_ci==3)
	label var desalent_ci "Desalentados"
	label define desalent_ci 0"No" 1"Si", add
	label value desalent_ci desalent_ci

	***************
	***horaspri_ci: Variable continua que indica el número de horas totales trabajadas en la actividad principal en la semana de referencia.***
	***************
	*Horas trabajadas en la actividad principal - horab:
	*	999	. (codificación de missings)
	gen  byte horaspri_ci = horab 
	replace horaspri_ci=. if horab==999 | emp_ci==0 //Reemplazando los missings  y los que no trabajan
	
	***************
	***horastot_ci: Variable continua que indica el número de horas totales trabajadas en todas las actividades económicas en una semana.***
	***************	

	* Horas trabajadas en todas las actividades	- horabco:
	*	999	. (codificación de missings)
	gen  byte horastot_ci = horabco
	replace horastot_ci  = . if horab==999 | emp_ci==0 //Reemplazando los missings  y los que no trabajan
	
	***************
	***tiempoparc_ci: Variable dicotómica que indica con valor 1 si la persona trabaja menos de 30 horas a la semana en la actividad principal y no desea trabajar más***
	***************	
	/*¿Cuál es la razón principal por al que desea mejorar o cambiar o adicionar su empleo actual? - d05:
			3	Desea trabajar menos horas sin ganar menos
			4	Desea trabajar menos horas aunque gane menos
			5	Desea trabajar igual cantidad de horas y ganar igual
	*/
	gen byte tiempoparc_ci= ((horaspri_ci >= 1 & horaspri_ci < 30) & inlist(d05,3,4,5) & emp_ci == 1) 

		
	***************
	***categopri_ci: Indica la categoría ocupacional de la actividad principal para los ocupados. (Solo aplica para los trabajadores ocupados emp_ci=1)***
	***************	
	/* cate_pea:
			1	Empleado / obrero público
			2	Empleado / obrero privado
			3	Empleador o patrón
			4	Trabajador por cuenta propia
			5	Trabajador familiar no remunerado
			6	Empleado doméstico
			9	NR
			.	NA

	Categorias de categopri_ci: 
			0	Otra clasificación
			1	Patrón o empleador
			2	Cuenta Propia o independiente
			3	Empleado o asalariado
			4	Trabajador no remunerado

	*/
	
	gen  byte categopri_ci = .
	replace categopri_ci  = 1 if cate_pea==3 & emp_ci==1 //Patrón o Empleador
	replace categopri_ci  = 2 if cate_pea==4 & emp_ci==1 //Trabajador Independiente
	replace categopri_ci  = 3 if inlist(cate_pea,1,2,6) & emp_ci==1 //Empleado
	replace categopri_ci  = 4 if cate_pea==5 & emp_ci==1 //Trabajador no remunerado
	
	
	***************
	***categosec_ci: Indica la categoría ocupacional de la actividad secundaria. (Solo aplica para los trabajadores ocupados emp_ci=1).***
	***************
	/*c09 - En la ocupación secundaria era... :
			1	Empleado / obrero público
			2	Empleado / obrero privado
			3	Empleador o patrón
			4	Trabajador por cuenta propia
			5	Trabajador familiar no remunerado
			6	Empleado doméstico
			7	Empleado/obrero/empleado domèstico en el extranjero
			8	Empleador/patròn/cuenta propia en el extranjero
			9	NR
			.	NA

	Categorias de categopri_ci: 
			0	Otra clasificación
			1	Patrón o empleador
			2	Cuenta Propia o independiente
			3	Empleado o asalariado
			4	Trabajador no remunerado
	*/	
	gen categosec_ci=.
	replace categosec_ci=1 if c09==3 & emp_ci==1 //Patrón o Empleador
	replace categosec_ci=2 if c09==4 & emp_ci==1 //Trabajador Independiente
	replace categosec_ci=3 if c09==1 | c09==2 | c09==6 //Empleado
	replace categosec_ci=4 if c09==5 & emp_ci==1 //Trabajador Familiar No Remunerado
	replace categosec_ci=0 if c09==7 | c09==9 //Otra Clasificación
	replace categosec_ci=. if emp_ci!=1 | c09==. | c09==9 //Remplazando por missings a los no ocupados (emp_ci!=!) , a los missings y los que no responden (c09==. | c09==9).

	label define categosec_ci 1"Patron" 2 "Cuenta propia" 
	label define categosec_ci 3"Empleado" 4"Familiar no remunerado" , add
	label value categosec_ci categosec_ci
	label variable categosec_ci "Categoria ocupacional trabajo secundario"

	***************
	***rama_ci:Indica la actividad laboral de la ocupación principal según la Clasificación industrial Uniforme a un dígito con las que fueron codificadas las bases originales para su armonización. La mayoría de los países usan la clasificación CIIU pero en diferentes revisiones. Si la base de datos ya incluye esta variable es importante hacer un control de calidad y cerciorarse de la revisión que se está armonizando. Solo para los ocupados emp_ci=1.
	***************	
	/*Código rama de actividad ocupación principal - b02rec
			1	Agricultura, ganadería, caza, silvicultura y pesca
			2	Industrias manufactureras
			3	Electricidad, gas y agua
			4	Construcciones
			5	Comercio al por mayor y menor, restaurantes y hoteles
			6	Transporte, almacenamiento y comunicaciones
			7	Establecimientos financieros, seguros, bienes ///
				inmuebles y servicios prestados a las empresas
			8	Servicios comunales, sociales y personales
			99	NR
			.	NA
	
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
	g rama_ci=.
	replace rama_ci=1 if (b02rec==1) & emp_ci==1 //Agricultura, caza y pesca
	replace rama_ci=3 if (b02rec==2) & emp_ci==1 //Industrias manufactureras
	replace rama_ci=4 if (b02rec==3) & emp_ci==1 //Electricidad, gas y agua
	replace rama_ci=5 if (b02rec==4) & emp_ci==1 //Construcción
	replace rama_ci=6 if (b02rec==5) & emp_ci==1 //Comercio al por Mayor
	replace rama_ci=7 if (b02rec==6) & emp_ci==1 //Transporte y almacenamiento
	replace rama_ci=8 if (b02rec==7) & emp_ci==1 //Establecimientos dinancieros
	replace rama_ci=9 if (b02rec==8) & emp_ci==1 //Servicios sociales

	label variable rama_ci "Rama de actividad laboral de la ocupacion principal"
	label define rama_ci	1 "Agricultura,_caza,_silvicultura_y_pesca" ///
							2 "Explotación_de_minas_y_canteras" ///
							3 "Industrias_manufactureras" ///
							4 "Electricidad,_gas_y_agua" ///
							5 "Construcción" ///
							6 "Comercio,_restaurantes_y_hoteles" ///
							7 "Transporte_y_almacenamiento" ///
							8 "Establecimientos_financieros,_seguros_e" ///
							9 "Servicios_sociales_y_comunales"
	label value rama_ci rama_ci

	***************
	***spublico_ci: Variable dicotómica que indica con valor 1 si la persona lleva a cabo su actividad laboral principal en el sector público y con valor 0 al resto de la población. Solo para los ocupados emp_ci=1.***
	***************	
	
	gen spublico_ci=0 if emp_ci==1
	replace spublico_ci=1 if cate_pea==1 & emp_ci==1
	***************
	***tamemp_ci: Indica la categoría del tamaño de la empresa donde el individuo realiza su actividad laboral principal. ***
	***************	
	/*¿Cuantas personas trabajan en la empresa donde trabaja? - b08:
			1	Solo
			2	2 a 5 personas
			3	6 a 10 personas
			4	11 a 20 personas
			5	21 a 30 personas
			6	31 a 50 personas
			7	51 a 100  personas
			8	101 a 500 personas 
			9	Más de 500 personas
			10	Empleado doméstico
			11	No sabe
			99	NR
			Blanco	NA

	
	Categorias de la variable tamemp_ci:
			1	Pequeña: de 1-5 personas en la empresa.
			2	Mediana: de 6-50 personas en la empresa.
			3	Grande: más de 50 personas en la empresa.
			.   no se cuenta con información

	*/
	gen byte tamemp_ci = .
	replace tamemp_ci  = 1 if b08==1 | b08==2  //Pequeña Empresa
	replace tamemp_ci  = 2 if inrange(b08,3,6) //Mediana Empresa
	replace tamemp_ci  = 3 if inrange(b08,7,9) //Gran Empresa
	replace tamemp_ci  = . if inlist(b08,10,11,99,.) //Missings a los trabajadores del hogar 
	label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
	label value tamemp_ci tamemp_ci
	label var tamemp_ci "Tamaño de empresa"
	
	***************
	***cotizando_ci: Variable dicotómica que indica con valor 1 si el asalariado o independiente cotiza a la seguridad social, de forma voluntaria o por medio de su empleador, en el periodo de referencia, con 0 a los desocupados o independientes que no responden si la encuesta no les pregunta y con valores perdidos si la variable original lo tiene. ***
	***************	
	/*¿Aporta a una caja de jubilación por esta ocupación? b10:
			1	Sí
			6	No
			9	No Responde	
	
	¿Aporta a una caja de jubilación por este trabajo? - c07:
			1	Sí
			6	No
			9	No Responde	
	*/
	***** El código mantiene a la poblacion inactiva y a los menores de la edad límite de la PET como missing values en congruencia con la variable formal_ci *****.
	gen byte cotizando_ci = .
	replace cotizando_ci = 1 if ((b10 == 1 | c07 == 1 ) & emp_ci==1) //Si aporta
	replace cotizando_ci = 0 if (cotizando_ci != 1 & inlist(condocup_ci, 1, 2)) // No aporta
	label var cotizando_ci "Cotizante a la Seguridad Social"
	label define cotizando_ci 0 "No"  1 "Si"
	label value cotizando_ci cotizando_ci

	***************
	***instcot_ci: Variable categórica que indica la institución de la Seguridad Social a la cual cotiza o está afiliado. Contiene la información de la variable original de la base de datos. ***
	***************	
	gen  byte instcot_ci = b11
	label var instcot_ci "Institucion a la que cotiza Seguridad social" 
	
	***************
	***afiliado_ci: Variable dicotómica que indica con valor 1 si el trabajador está afiliado a la Seguridad Social (independientemente que haya o no cotizado en el mes de referencia), con 0 al resto del grupo de referencia y mantenemos con valores perdidos si la encuesta los tiene como perdidos***
	***************	
	gen  byte afiliado_ci = . //No existe esta pregunta 
		
	**************
	***formal_ci: Variable dicotómica que indica con valor 1 si el trabajador es formal y con 0 al resto. ***
	**************
	gen formal=1 if cotizando_ci==1 //Todos los que cotizan son formales

	gen byte formal_ci=.
	replace formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
	replace formal_ci=0 if formal_ci==. & (condocup_ci==1 | condocup_ci==2) 
	label var formal_ci "1=afiliado o cotizante / PEA"
	
	
	*******************
	***tipocontrato_ci: Variable categórica que indica el tipo de contrato laboral de los empleados/asalariados en la actividad principal según su duración (los trabajadores no asalariados deberían identificarse con valor perdido).***
	*******************
	/* Tipo de contrato - b26:
			1	Contrato indefinido/nombrado
			2	Contrato definido temporal con emisión de factura legal
			3	Contrato definido temporal sin emisión de factura legal
			4	Contrato verbal
			9	NR
			Blanco	NA
	
	Categorias de tipocontrato_ci:
			0	Con contrato
			1	Permanente/indefinido.
			2	Temporal/tiempo definido.
			3	Sin contrato/verbal
	*/
	
	gen tipocontrato_ci=. /* Solo asalariados*/
	replace tipocontrato_ci=1 if b26==1 & categopri_ci==3 //Indefinido
	replace tipocontrato_ci=2 if (b26==2 | b26==3) & categopri_ci==3 //Temporal
	replace tipocontrato_ci=3 if (b26==4 | tipocontrato_ci==.) & categopri_ci==3 //Contrato Verbal
	label var tipocontrato_ci "Tipo de contrato segun su duracion"
	label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
	label value tipocontrato_ci tipocontrato_ci
			
	**************
	***ocupa_ci: Variable categórica que indica la ocupación laboral de los ocupados en la actividad principal. Usa el clasificador internacional de ocupaciones CIUO, verificar con el clasificador que efectivamente los códigos de cada grupo estén bien.***
	**************
	gen ocupa_ci=.
	/* Esta variable no es posible crearla debido a que la codificación de la variable b01rec en la EPHC no es compatible con la codificación que se utiliza en los manuales de armonización del BID
	
	b012rec:
			1	Miembros del Poder Ejecutivo, Legislativo y Judicial,///
				personal directivo de la Administración pública y de empresa
			2	Profesionales científicos e intelectuales
			3	Técnicos y profesionales de nivel medio
			4	Empleados de oficina
			5	Trabajadores de los servicios y vendedores de comercios y mercados
			6	Agricultores y trabajadores Agropecuarios y Pesqueros
			7	Oficiales, operarios y artesanos de artes mecánicas ///
				y de otros oficios
			8	Operadores de instalaciones y máquinas y montadores
			9	Trabajadores no calificados
			10	Fuerzas armadas
			99	NR
	
	ocupa_ci:
			1	Profesionales y técnicos.
			2	Directores y funcionarios superiores.
			3	Personal administrativo y nivel intermedio.
			4	Comerciantes y vendedores.
			5	Trabajadores en servicios.
			6	Trabajadores agrícolas y afines.
			7	Obreros no agrícolas, conductores de máquinas ///
				y vehículos de transporte y similares.
			8	Fuerzas Armadas.
			9	Otras ocupaciones no clasificadas en las anteriores.
	*/

	***************
	**tipopen_ci: Variable categórica que indica el tipo de pensión contributiva o no contributiva según el país. Puede estar asociado a algún programa del gobierno o al sistema de seguridad social.**
	***************
	gen tipopen_ci=. //No existe una pregunta como tal
	label var tipopen_ci "Tipo de pension - variable original de cada pais" 

	***************
	**instpen_ci: Variable categórica que indica la institución que otorga la prestación previsional. Es la misma variable original de la base de datos, por lo que difiere en cada país y no está disponible en todos los casos. **
	***************
	gen instpen_ci=. //No existe esta variable en la base de datos
	label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 


********************************************************************************
*****************   VARIABLES DE INGRESO  & PROTECCION SOCIAL  *****************
********************************************************************************

*A. INGRESOS LABORALES A NIVEL DE INDIVIDUO	

	*************
	* ylmpri_ci: Ingreso laboral monetario de actividad principal: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad principal. Incluye: sueldos, salarios, jornales, trabajos a destajo, comisiones, propinas, horas extras, aguinaldos (empleados) y ganancia neta (patrones y cuenta propia). *
	*************
*e01aimde: Ingreso mensual que habitualmente recibe de la actividad principal
	
	gen ylmpri_ci=e01aimde if emp_ci==1 //Se suman los ingresos principales solo para los individuos ocupados (emp_ci==1)
	replace ylmpri_ci=0 if inlist(condocup_ci,2,3) //Inactivos o Desocupados registran ingresos de 0
	replace ylmpri_ci=0 if categopri_ci==4 //Aquellos trabajadores con categoría ocupacional no remunerado (categopri_ci==4) registran ingresos de 0
	replace ylmpri_ci=0 if ylmpri_ci<0 //Se reemplazan los valores negativos por 0
	replace ylmpri_ci=. if e01aimde==99999999999 | e01aimde==. //Se reeemplazan las codificaciones para missings por missings
	label var ylmpri_ci "Ingreso Laboral Monetario de la Actividad Principal"

	************
	* ylmsec_ci: Ingreso laboral monetario de actividad secundaria: Variable continua que indica el monto mensual de ingresos monetarios provenientes de la actividad secundaria. *
	************
*e01bimde: Ingreso mensual que habitualmente recibe de la actividad secundaria

	gen ylmsec_ci=e01bimde if emp_ci==1 //Se suman los ingresos secundarios solo para los individuos ocupados (emp_ci==1)
	replace ylmsec_ci=0 if inlist(condocup_ci,2,3) //Inactivos o Desocupados registran ingresos de 0
	replace ylmsec_ci=0 if categopri_ci==4 //Aquellos trabajadores con categoría ocupacional no remunerado (categopri_ci==4) registran ingresos de 0
	replace ylmsec_ci=0 if ylmsec_ci<0 //Se reemplazan los valores negativos por 0
	replace ylmsec_ci=. if e01bimde==99999999999 | e01bimde==. //Se reeemplazan las codificaciones para missings por missings
	label var ylmsec_ci "Ingreso Laboral Monetario de la Actividad Secundaria"
	
	**************
	* ylmotros_ci: Ingreso laboral monetario de otras actividades: Variable continua que indica el monto mensual de ingresos monetarios provenientes de actividades distintas de la principal y secundaria. Incluye ingresos percibidos por desocupados o inactivos derivados de trabajos previos al cese. *
	**************
*e01cimde: Ingreso mensual que habitualmente recibe de todas las otras actividades

    gen double ylmotros_ci=e01cimde if emp_ci==1 
	replace ylmotros_ci=0 if inlist(condocup_ci,2,3) //Inactivos o Desocupados registran ingresos de 0
	replace ylmotros_ci=0 if categopri_ci==4 //Aquellos trabajadores con categoría ocupacional no remunerado (categopri_ci==4) registran ingresos de 0
	replace ylmotros_ci=0 if ylmotros_ci<0 //Se reemplazan los valores negativos por 0
	replace ylmotros_ci=. if e01cimde==99999999999 | e01cimde==. //Se reeemplazan las codificaciones para missings por missings
	
	*********
	* ylm_ci:Ingreso laboral monetario total: Variable continua que indica el monto mensual total de ingresos laborales monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylmpri_ci, ymsec_ci e ylnmotros_ci.*
	*********
	*Codigo extraído del manual
	egen double ylm_ci = rowtotal(ylmpri_ci ylmsec_ci ylmotros_ci), mi

	**************
	* ylnmpri_ci: Ingreso laboral no monetario de actividad principal: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad principal de cada miembro del hogar.*
	*************
/*
	La variable final de ylnmpri_ci se debe presentar en frecuencia mensual, por lo que se convierte cada estimación según la siguiente tabla:

	Cambio de frecuencia		Transformación
	Anual		-> mensual		Monto anual/12
	Bimestral 	-> mensual		Monto bimestral/2
	Quincenal 	-> mensual		Monto quincenal*2
	Semanal 	-> mensual		Monto semanal*52/12
	Diario 		-> mensual		Monto diario*30	
*/	
	
*INGRESO NO MONETARIO EN COMIDA	
/*	b19 - ¿Recibió comidas y/o bebidas gratis del patrón o empleador en el último mes?:
			1		Si
			6		No
			9		NR
			
	b20g - ¿Cuánto estima el valor (de la comida) en Guaraníes?	
	Esta variable se mide según la unidad de tiempo. Sí una persona recibió comida su estimación del valor de la comida lo hace en alguna de las siguientes unidades de tiempo.

	b20u - Unidad de tiempo:
			2	Día
			3	Semana
			4	Quincena
			5	Mes
			6	Año
			9	NR
*/	
	gen comida=.
	replace comida=b20g*30	if b19==1 & b20u==2 //Conversión de monto diario a mensual
	replace comida=b20g*4.3 if b19==1 & b20u==3 //Conversión de monto semanal a mensual
	replace comida=b20g*2	if b19==1 & b20u==4 //Conversión de monto quincenal a mensual
	replace comida=b20g 	if b19==1 & b20u==5 //Monto mensual
	replace comida=b20g/12	if b19==1 & b20u==6 //Conversión de monto anual a mensual
	replace comida=.		if b19==9 | b19==. | b20g==99999999999 | b20g==. //Missings

*INGRESO NO MONETARIO EN VIVIENDA
/* Estas variables ya están en monto mensual.
	b21 - ¿Ocupa o alquila una casa, pieza o departamento de la empresa?: 
			1	Si, ocupa
			2	Si, alquila
			6	No
			9	NR
	
	b23 - ¿Cuánto tendría que pagar por si alquilara de otro?
*/
	gen alquiler=.
	replace alquiler=b23 if b21==1 //Monto estimado que el encuestado pagaría sino tuviera la vivienda de la empresa
	replace alquiler=.	 if b21==9 | b21==. | b23==99999999999 | b23==. //Missings

*INGRESO NO MONETARIO EN UNIFORMES
/*
b24 - ¿Recibe en el año uniforme o ropa gratis del patrón o empleador?	
			1	Si
			6	No
			9	NR

b25 - ¿En cuánto estima su valor por año?
Este valor es anual así que se convierte a mensual			
*/	
	gen unifor=b25/12 //Conversión de frecuencia anual a mensual
	replace unifor =. if b25==99999999999 | b25==.

*GENERANDO LA VARIABLE DE INGRESOS NO MONETARIOS
	egen double ylnmpri_ci=rowtotal(comida unifor alquiler) if emp_ci==1, missing
	replace ylnmpri_ci=. if comida==. & unifor==. & alquiler==. 
	label var ylnmpri_ci "Ingreso Laboral No Monetario de la Actividad Principal"
	
	**************
	* ylnmsec_ci: Ingreso laboral no monetario de actividad secundaria: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de la actividad secundaria de cada miembro del hogar.*
	**************
   	gen ylnmsec_ci=. //No hay variables no monetarias sobre ingresos laorales de la actividad secundaria
	label var ylnmsec_ci "Ingreso laboral NO monetario de actividad secundaria" 
	
	****************
	* ylnmotros_ci: Ingresos laboral no monetario de otras actividades: Variable continua que representa el monto mensual del ingreso laboral no monetario derivado de actividades distintas de la principal y/o secundaria de cada miembro del hogar.*
	****************
	gen ylnmotros_ci=. //No hay una variable de ingresos LABORALES no monetarios que haga referencia a otra ocupación que no sea ni la principal ni la secundaria. 
	label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 
	
	**********
	* ylnm_ci: Ingreso laboral no monetario: Variable continua que indica el monto mensual total de ingresos laborales no monetarios provenientes de todas las actividades. Esta variable equivale a la suma de las variables ylnmpri_ci, ylnmsec_ci e ylnmotros_ci.*
	**********
	*Codigo extraído del manual
	egen double ylnm_ci = rowtotal(ylnmpri_ci ylnmsec_ci ylnmotros_ci), mi
	replace ylnm_ci = . if ylnm_ci < 0 & ylnm_ci != .
	label var ylnm_ci "Ingreso laboral NO monetario total"  


*B. INGRESOS NO LABORALES A NIVEL DE INDIVIDUO	

******************
*** ytransf_ci ***
******************
	* PNC - Pensiones sociales no contributivas:
			* Ingreso del Estado $ Adulto Mayor (e01kde)
	* PTMC - Programas de transferencias monetarias condicionadas:
			* Ingreso del Estado $ Tekoporã (e01ide)
	* POTROT - Programas de otras transferencias monetarias no condicionadas
	
	*** Beneficiarios a nivel individual:
		gen byte pnc_ci = (e01kde > 0) if !missing(e01kde)
		gen byte ptmc_ci = (e01ide > 0) if !missing(e01ide)
		gen byte potrot_ci = .
	
	*** Montos de transferencias a nivel individual:
		gen double ypnc_ci = e01kde	if e01kde > 0 & e01kde != 999999999	// Transferencias PNC
		gen double yptmc_ci = e01ide if e01ide > 0 & e01ide != 999999999		// Transferencias PTMC
		gen double yotrot_ci = .		// Otras transferencias POTROT

*** Ingreso individual por transferencias no contributivas
egen double ytransf_ci = rowtotal(ypnc_ci yptmc_ci yotrot_ci), mi

	**********
	* ypen_ci: Ingreso por pensión contributiva: Variable continua que indica el monto mensual en moneda local corriente efectivamente recibido por el individuo por pensiones contributivas en sus distintas modalidades (jubilación, vejez, pensión, etc).*
	**********
	*e01hde: Ingreso mensual por jubilacion
	*e01jde: Ingreso mensual Pensión (ex combatiente,viudas,etc)
	foreach x in e01hde e01jde {
		gen double `x'1 = `x'
		replace `x'1 = . if `x' == 0 | `x' == 999999999 
	}
	egen double ypen_ci = rowtotal(e01hde1 e01jde1), mi
	label var ypen_ci "Valor de la pension contributiva"

	*************
	* ypensub_ci: Ingreso por pensión no contributiva: Variable continua que indica el monto mensual en moneda local corriente recibido por la persona por pensiones no contributivas (adultos mayores).*
	*************
	*e01kde: Ingreso mensual del Estado (Monetario: Adulto Mayor)
	gen double ypensub_ci = ypnc_ci
	replace ypensub_ci=. if e01kde==. | e01kde==99999999999

	*************
	* remesas_ci: Variable continua que indica el monto mensual por remesas reportadas por el individuo en moneda local corriente. *
	*************
	*e02bde: ingresos por ayuda familiar del exterior (individual)
	gen double remesas_ci = e02bde if e02bde > 0 & e02bde != 999999999
	label var remesas_ci "Remesas Individuales"
	
	**********
	* ynlm_ci:  Ingreso no laboral monetario del individuo. Variable continua que indica el monto mensual del ingreso no laboral MONETARIO proveniente de otras fuentes no laborales.*
	**********
	/* VARIABLES DE INGRESOS MONETARIOS NO LABORALES
	e01dde  Ingreso mensual por alquileres o rentas netas
	e01ede  Ingreso mensual Por intereses o dividendos
	e01fde  Ingreso mensual por ayuda familiar del país
	e01gde  Ingreso mensual por divorcio / Asistencia alimentaria
	e01hde  Ingreso mensual por jubilación > ypen_ci
	e01ide  Ingreso mensual del Estado Monetario Tekopora > ytransf_ci
	e01jde  Ingreso mensual por pensión > ypen_ci
	e01kde  Ingreso mensual del Estado Monetario Adulto Mayor > ytransf_ci
	e01mde  Otros ingresos no laborales mensuales
	e01kjde Otros ingresos mensuales agro asignados al jefe de hogar
	e02bde  Ingreso mensual por ayuda familiar del exterior (individual) > remesas_ci */

	local var = "e01dde e01ede e01fde e01gde e01mde e01kjde"
		foreach x of local var {
		gen `x'1 = `x'
		replace `x'1 = . if `x' == 0 | `x' == 999999999 /*No aplicable*/
	}
	egen double ynlm_ci = rowtotal(e01dde1 e01ede1 e01fde1 e01gde1 ypen_ci ytransf_ci e01mde1 e01kjde1 remesas_ci), missing
	drop e01dde1 e01ede1 e01fde1 e01gde1 e01hde1 e01jde1 e01mde1 e01kjde1
	label var ynlm_ci "Ingreso No Laboral Monetario"	
	
	***********
	* ynlnm_ci:Ingreso no laboral no monetario. Variable continua que indica el monto mensual del ingreso no laboral no monetario (otras fuentes) *
	***********
	* e01lde Ing por víveres de alguna institución pública
	gen double ynlnm_ci = e01lde if e01lde > 0 & e01lde != 999999999
	label var ynlnm_ci "Ingreso No Laboral No Monetario" 

	**********
	* ytot_ci: Ingreso mensual total del individuo que incluye las variables ylm_ci ylnm_ci ynlm_ci ynlnm_ci*
	**********
	*Codigo extraído del manual
	egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi
	label var ytot_ci "Ingreso mensual total del individuo"

	***************
	*** ynet_ci ***
	***************
	gen double aux_ytransf_ci = ytransf_ci*(-1)
	egen double ynet_ci = rowtotal(ytot_ci aux_ytransf_ci), mi	
	drop aux_ytransf_ci


*C. INGRESOS A NIVEL DE HOGAR

	*********
	* ylm_ch: Ingreso laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso laboral monetario del hogar, ignora las `No respuesta'.  *
	*********
	*Codigo extraido del manual
	bysort idh_ch: egen double ylm_ch = total(ylm_ci) if miembros_ci == 1, mi
	label var ylm_ch "Ingreso laboral monetario del hogar"

	**********
	* ylnm_ch: Ingreso laboral no monetario del hogar. Variable continua que indica el monto del ingreso laboral no monetario del hogar.*
	**********
	*Codigo extraído del manual
	bysort idh_ch: egen double ylnm_ch = total(ylnm_ci) if miembros_ci == 1, mi
	label var ylnm_ch "Ingreso laboral no monetario del hogar"
	
	******************
	*** ytransf_ch ***
	******************

	*** Beneficiarios a nivel hogar:
		bys idh_ch: egen byte pnc_ch = max(pnc_ci) if miembros_ci == 1
		bys idh_ch: egen byte ptmc_ch = max(ptmc_ci) if miembros_ci == 1
		bys idh_ch: egen byte potrot_ch = max(potrot_ci) if miembros_ci == 1
		
		gen byte pcasht_ch = (pnc_ch == 1 | ptmc_ch == 1 | potrot_ch == 1)
		replace pcasht_ch = . if pnc_ch == . & ptmc_ch == . & potrot_ch == .
		
	*** Montos de transferencias a nivel hogar:
		bys idh_ch: egen double ypnc_ch = total(ypnc_ci) if miembros_ci == 1, mi
		bys idh_ch: egen double yptmc_ch = total(yptmc_ci) if miembros_ci == 1, mi
		bys idh_ch: egen double yotrot_ch = total(yotrot_ci) if miembros_ci == 1, mi

	*** Ingreso del Hogar por transferencias no contributivas
	egen double ytransf_ch = rowtotal(ypnc_ch yptmc_ch yotrot_ch) if miembros_ci == 1, mi
	
	*************
	* remesas_ch: Variable continua que indica el monto mensual por remesas del hogar. Esta variable se genera a partir de la variable remesas_ci.*
	*************
	*Codigo extraído del manual 
	bys idh_ch: egen double remesas_ch = total(remesas_ci) if miembros_ci == 1, mi

	*********
	* ynlm_ch: Ingreso no laboral monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral monetario del hogar (otras fuentes). Es la suma de ynlm_publico_ch y ynlm_privado_ch.*
	*********
	*Suma de los ingresos laborales no monetarios de todos los miembros del hogar
	by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing 
	label var ynlm_ch "Ingreso no laboral monetario del hogar"
	
	***********
	* ynlnm_ch: Ingreso no laboral no monetario del hogar. Variable continua que indica el monto mensual del ingreso no laboral no monetario del hogar (otras fuentes).*
	***********
	* En esta categoría se encuentran otros beneficios y transferencias no monetarias como las donaciones en alimentos, útiles escolares, becas, entre otros:
		* ingrevasode: Ing por vaso de leche imputado (A nivel hogar)
		* ingrealmuerzode: Ing por almuerzo o cena escolar imputado (A nivel hogar)
	bys idh_ch: egen double ing_nm1 = total(ynlnm_ci) if miembros_ci == 1, mi // Ingresos individuales
	egen double ynlnm_ch = rowtotal(ing_nm1 ingrevasode ingrealmuerzode) if miembros_ci == 1, mi

	**********
	* ytot_ch: Ingreso mensual total del hogar*
	**********
	*Codigo extraído del manual
	egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch) if miembros_ci == 1, mi
	
	***************
	*** ynet_ch ***
	***************
	gen double aux_ytransf_ch = ytransf_ch*(-1)
	egen double ynet_ch = rowtotal(ytot_ch aux_ytransf_ch) if miembros_ci == 1, mi
	gen double ynet_ch_pc = (ynet_ch)/nmiembros_ch if miembros_ci == 1
	drop aux_ytransf_ch

	***************
	* ylmhopri_ci: Variable continua que indica el monto del salario horario monetario de la actividad principal.*
	***************
	*Codigo extraído del manual
    gen byte ylmhopri_ci = ylmpri_ci / (4.3 * horaspri_ci)
	replace ylmhopri_ci = . if ylmhopri_ci <= 0
	label var ylmhopri_ci "Salario monetario de la actividad principal" 
 
	**********
	* ylmho_ci: Variable continua que indica el monto del salario horario monetario de todas las actividades.*
	**********
	*Codigo extraído del manual
	gen byte ylmho_ci = ylm_ci / (4.3 * horastot_ci)
	replace ylmho_ci = . if ylmho_ci <= 0
  
	**************
	* nrylmpri_ci: No respuesta a nivel individuo. Indica la no respuesta ingreso de la actividad principal. Para construir esta variable, se tiene en cuenta que no reporte ingresos laborales (ylmpri_ci==. ) y además la persona reporte estar ocupado (emp_ci==1)*
	**************
/*		1: Indica que tiene empleo, pero no reporta el ingreso 
		0: Caso contrario
*/
	*Codigo extraído del manual
	gen byte nrylmpri_ci = .
	replace nrylmpri_ci = 1 if ylmpri_ci == . & emp_ci == 1
	replace nrylmpri_ci = 0 if ylmpri_ci != . & emp_ci == 1

	**************
	* nrylmpri_ch: No respuesta a nivel hogar. Hogares con algún miembro que no respondió por ingresos*
	**************
/*		1: Indica que tiene empleo, pero no reporta el ingreso 
		0: De lo contrario
*/	
	*Codigo extraído del manual
	by idh_ch, sort: egen byte nrylmpri_ch = sum(nrylmpri_ci) if miembros_ci==1
	replace nrylmpri_ch = 1 if nrylmpri_ch > 0 & nrylmpri_ch < .
	replace nrylmpri_ch = . if nrylmpri_ch == .
	
	*************
	* pension_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación contributiva y con 0 al resto. 
	*************
	gen byte pension_ci = (e01hde > 0 | e01jde > 0 )  // Tiene componentes no contributivos pero al no poder desagregar se deja como contributivo
	replace pension_ci = . if e01hde == 99999999999 & e01jde == 99999999999
	replace pension_ci = . if e01hde == . & e01jde == . 
	label var pension_ci "1=Recibe pension contributiva"

	****************
	* pensionsub_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación NO contributiva (adultos mayores) y con 0 al resto. *
	****************
	gen byte pensionsub_ci = (e01kde > 0) if !missing(e01kde)
	replace pensionsub_ci = . if e01kde == 99999999999 
	label var pensionsub_ci "1=Recibe pension No contributiva"	


****************************
***VARIABLES DE EDUCACION***
****************************

	***************
	*** aedu_ci: Variable numérica que indica el número de años de educación culminados de las personas encuestadas.
	***************
	/* La variable de años de educación de la encuesta es ed0504 y está codificada de la siguiente forma: 
			0			Sin instrucción
			101-112		Educación especial
			210-212		Educación Inicial
			301-306		EEB 1ª al 6ª (Primaria)
			407-409		EEB 7º al 9º
			501-503		Secundario Básico
			604-607		Bachiller Humanístico/Científico
			704-706		Bachiller Técnico/Comercial
			803			Bachillerato a distancia
			901-903		Educación Media Científica
			1001-1003	Educación Media Técnica
			1101-1103	Educación Media Abierta
			1201-1204	Educ. Básica Bilingüe para personas Jóvenes y Adultas
			1301-1304	Educ. Media a Distancia para Jóvenes y Adultos
			1401-1403	Educ. Básica Alternativa de Jóvenes y Adultos
			1501-1504	Educ. Media Alternativa de Jóvenes y Adultos
			1601-1604	Educ. Media para Jóvenes y Adultos
			1701-1703	Formación profesional no Bachillerato de la Media
			1801		Programa de Alfabetización
			1900		Grado especial/Programas especiales
			2001-2004	Técnica Superior
			2101-2104	Formación Docente
			2201-2206	Profesionalización Docente
			2301-2304	Formación Militar/Policial
			2401-2406	Universitario
			9999		NR
			8888		NA
	*/
		
	gen nivgra=ed0504
	tostring nivgra, gen(nivgra_str)
	gen aedu_temp=substr(nivgra_str,-1,1)
	destring aedu_temp, replace
	replace aedu_temp=. if nivgra==8888 | nivgra==9999 // Se reemplazan los missings y los que no responden
	replace aedu_temp=0 if (nivgra>=1200 & nivgra<=1299) | (nivgra>=1300 & nivgra<=1399) | (nivgra>=1400 & nivgra<=1499) | (nivgra>=1500 & nivgra<=1599) | (nivgra>=1600 & nivgra<=1699) | (nivgra>=1800 & nivgra<=1899)  // La educación para adultos cuenta como 0 (ver el manual)
	replace aedu_temp=. if (nivgra>=100 & nivgra<=199) | (nivgra>=1900 & nivgra<=1999)  // educación especial

	gen aedu_ci=aedu_temp
	replace aedu_ci=0 if nivgra==0 // sin instruccion
	replace aedu_ci=0 if nivgra>=200 & nivgra<=299 // inicial prejardin, inicial jardin, preescolar
	replace aedu_ci=aedu_temp if nivgra>=300 & nivgra<=399 // escolar basica: 1 a 6
	replace aedu_ci=aedu_temp if nivgra>=400 & nivgra<=499 // escolar basica: 7 a 9
	replace aedu_ci=aedu_temp+9 if nivgra>=900 & nivgra<=999 // media cientifica
	replace aedu_ci=aedu_temp+9 if nivgra>=1000 & nivgra<=1099 // media tecnica
	replace aedu_ci=aedu_temp+9 if nivgra>=1100 & nivgra<=1199 // media abierta
	replace aedu_ci=aedu_temp+9 if nivgra>=500 & nivgra<=599 // ciclo básico de sencudaria antiguo
	replace aedu_ci=aedu_temp+6 if nivgra>=600 & nivgra<=699 // educación secundaria y bachillerato
	replace aedu_ci=aedu_temp+6 if nivgra>=700 & nivgra<=799 // educación secundaria y bachillerato
	replace aedu_ci=aedu_temp+6 if nivgra>=800 & nivgra<=899 // educación secundaria y bachillerato
	replace aedu_ci=aedu_temp+6 if nivgra>=1700 & nivgra<=1799 // programa de formación profesional
	replace aedu_ci=aedu_temp+12 if nivgra>=2000 & nivgra<=2099 // tecnica superior
	replace aedu_ci=aedu_temp+12 if nivgra>=2100 & nivgra<=2199 // formación docente
	replace aedu_ci=aedu_temp+12 if nivgra>=2200 & nivgra<=2299 // profesionalización docente
	replace aedu_ci=aedu_temp+12 if nivgra>=2300 & nivgra<=2399 // militar/policial
	replace aedu_ci=aedu_temp+12 if nivgra>=2400 & nivgra<=2499 // superior universitario
	
	/* Titulo o diploma más alto que obtuvo - ed06c:
			1	Superior Universitario
			2	Educación Inicial
			3	EEB (1º y 2º ciclo)
			4	EEB (3er ciclo)
			5	Educación Media
			6	Militar/Policial
			7	Técnica Superior
			8	Doctorado (Post universitario)
			9	Maestría (Post universitario)
			10	Especialización (Post universitario)
			11	Formación Docente (Post no universitario)
			12	Militar/Policial (Post no universitario)
			13	Técnico Superior (Post no universitario)
			14	No obtuvo
			15	Otro (especificar)
			99	NR
			.	NA
	*/
	*Como la variable de años de educación no considera los estudios de posgrado, se realiza el siguiente ajuste
	
	replace aedu_ci=aedu_temp+12+5+2 if ed06c==8 // doctorado
	replace aedu_ci=aedu_temp+12+5 if ed06c==9 // maestria
	replace aedu_ci=aedu_temp+12+5 if ed06c==10 // especialización

	***************
	***edupre_ci: Variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo (lo cual es distinto a si asiste o no a la educación preescolar). 
	***************
		/* Titulo o diploma más alto que obtuvo - ed06c:
			1	Superior Universitario
			2	Educación Inicial
			3	EEB (1º y 2º ciclo)
			4	EEB (3er ciclo)
			5	Educación Media
			6	Militar/Policial
			7	Técnica Superior
			8	Doctorado (Post universitario)
			9	Maestría (Post universitario)
			10	Especialización (Post universitario)
			11	Formación Docente (Post no universitario)
			12	Militar/Policial (Post no universitario)
			13	Técnico Superior (Post no universitario)
			14	No obtuvo
			15	Otro (especificar)
			99	No Responde
			.	NA
	*/
	
	* No se puede distinguir 
	gen byte edupre_ci=.
	
	**************
	***eduui_ci***
	**************
	gen eduui_ci = (inrange(ed0504, 2001, 2406) & ed06c == 14)
	replace eduui_ci = . if aedu_ci == .
		
	**************
	***eduuc_ci***
	**************
	gen eduuc_ci = (inrange(ed06c, 1, 13))
	replace eduuc_ci = . if aedu_ci == .
	lab var eduuc_ci "Superior Completo"
	
	**************
	***eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto. 
	**************
	/* La variable de años de educación de la encuesta es ed0504 y está codificada de la siguiente forma: 
			0			Sin instrucción
			101-112		Educación especial
			210-212		Educación Inicial
			301-306		EEB 1ª al 6ª (Primaria)
			407-409		EEB 7º al 9º
			501-503		Secundario Básico
			604-607		Bachiller Humanístico/Científico
			704-706		Bachiller Técnico/Comercial
			803			Bachillerato a distancia
			901-903		Educación Media Científica
			1001-1003	Educación Media Técnica
			1101-1103	Educación Media Abierta
			1201-1204	Educ. Básica Bilingüe para personas Jóvenes y Adultas
			1301-1304	Educ. Media a Distancia para Jóvenes y Adultos
			1401-1403	Educ. Básica Alternativa de Jóvenes y Adultos
			1501-1504	Educ. Media Alternativa de Jóvenes y Adultos
			1601-1604	Educ. Media para Jóvenes y Adultos
			1701-1703	Formación profesional no Bachillerato de la Media
			1801		Programa de Alfabetización
			1900		Grado especial/Programas especiales
			2001-2004	Técnica Superior
			2101-2104	Formación Docente
			2201-2206	Profesionalización Docente
			2301-2304	Formación Militar/Policial
			2401-2406	Universitario
			9999		NR
			.			NA
	*/
	
	gen eduac_ci = .
	replace eduac_ci = 1 if inrange(ed0504, 2101, 2406) // Individuos que reportan como último nivel y grado más alto aprobado, superior no universitario o superior universitaria o que se encuentren estudiando en dichos niveles 
	replace eduac_ci = 0 if inrange(ed0504, 2001, 2004) // Individuos que declaran técnico superior como nivel más alto aprobado o inscripción actual.
	replace eduac_ci=. if ed0504==9999 // Se reemplazan los missings
	
	***************
	***asiste_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza o institución de educación superior al momento de ser encuestado, con 0 si no asiste y con perdido el resto. 
	***************
	/* ¿Asiste actualmente a una institución de enseñanza formal? - ed08:
			1	Sí, Educ. Inicial
			2	Sí, Educ. Escolar BáSíca
			3	Sí, Educación Media Científica
			4	Sí, Educación Media Técnica
			5	Sí, Educación Media Abierta
			6	Sí, Educ. Básíca Bilingüe para personas Jóvenes y Adultas
			7	Sí, Educación Media para Jóvenes y Adultas
			8	Sí, Formación Profesíonal no Bachillerato de la Media
			9	Sí, Programas de Alfabetización
			10	Sí, Educ. Especial
			11	Sí, Grado Especial / Programas Especiales
			12	Sí, Técnica Superior
			13	Sí, Formación Docente
			14	Sí, Profesionalización Docente
			15	Sí, Formación Militar / Policial
			16	Sí, Superior Universítario
			17	Sí, Post Superior no Universítario
			18	Sí, Post Superior Universítario
			19	No asiste 
			99	NR
			.	NA
	*/
	
	gen asiste_ci=.
	replace asiste_ci=1 if inrange(ed08, 1,18) //Asiste actualmente a un centro educativo
	replace asiste_ci=0 if ed08==19 // No asiste
	replace asiste_ci=. if ed08==99 | ed08==. // Se reemplazan los missings

	***************
	***edupub_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza pública al momento de la encuesta, con 0 si asiste a un centro de enseñanza privada, y con perdido si no asiste o no responde a la pregunta. 
	***************
	/* Sector al que pertenece la institución a la que asiste actualmente - ed09: 
		1	Público
		2	Privado
		3	Privado subvencionado
		9	No Responde (NR)
	*/
	gen edupub_ci=.
	replace edupub_ci = 1 if ed09==1 //Instiución Pública
	replace edupub_ci = 0 if ed09==2 | ed09==3 //Institución Privada
	replace edupub_ci =.  if ed09==9 //Missings 
		
	***************
	***asis_pre***
	***************
	gen byte asispre_ci=(ed08==1)
	
	*************
	*razonesnoasis_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela.*
	**************
	//pqnoasis1_ci fue sustituida por razonesnoasis_ci en junio 2025
	
	/*¿Por qué no asiste o dejó de asistir? - ed10:
			1	Sin recursos en el hogar
			2	Necesidad de trabajar
			3	Muy costosos los materiales y matriculas
			4	No tiene edad adecuada 
			5	Considera que terminó los estudios
			6	No existe institución cercana
			7	Institución cercana muy mala
			8	El centro educativo cerró
			9	El docente no asiste con regularidad 
			10	Institución no ofrece escolaridad completa
			11	Requiere educación especial
			12	Por enfermedad
			13	Debe hacer labores en el hogar
			14	Motivos familiares
			15	No quiere estudiar
			16	Asiste a enseñanza vocacional o formación profesional
			17	Servicio militar
			18	Otra razón
			99	NR
			.	NA
	
	Categorias de razonesnoasis_ci:  
		1	problemas económicos/ por trabajo
		2	falta de interés/ problemas de 
			rendimiento
		3	quehaceres domésticos/ embarazo/ 
			cuidado de niños/as/ problemas 
			familiares o de salud
		4	problemas de acceso
		5	otros
	*/
	gen razonesnoasis_ci=.
	replace razonesnoasis_ci = 1 if inlist(ed10,1,2,3) //Problemas económicos o trabajo
	replace razonesnoasis_ci = 2 if inlist(ed10, 5, 15) // No quiere estudiar ≡ Falta de Interés
	replace razonesnoasis_ci = 3 if inlist(ed10,12,13,14) //Enfermedad, Quehaceres domésticos o motivos familiares
	replace razonesnoasis_ci = 4 if inlist(ed10,4, 6, 7, 8, 9, 10, 11) //Problemas de acceso
	replace razonesnoasis_ci = 5 if inlist(ed10,5,17,18) //Otra razón
	replace razonesnoasis_ci = . if ed10==99 | ed10==. //Missings
	
	replace razonesnoasis_ci = . if asiste_ci==1 // Consistencia: No se debe contar con razones de no asistencia si la variable de asiste_ci==1. 

	label define razonesnoasis_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
	label value  razonesnoasis_ci razonesnoasis_ci


********************************************************************************
***************   VARIABLES DE VIVIENDA    *************************************
********************************************************************************		
	************
	***luz_ch: Indica si la principal fuente de iluminación del hogar es electricidad* 
	************
	*La variable de la encuesta v10 responde a la pregunta "¿Dispone de luz eléctrica?". No es exactamente si la principal fuente de ilumación es electricidad. En el 2023 se consideró a luz_ch=v10. Se hace lo mismo para crear la variable.
	gen luz_ch=.
	replace luz_ch=1 if v10==1 //Tiene luz electrica
	replace luz_ch=6 if v10==6 //No tiene luz electric 
	replace luz_ch=. if v10==. //Missings
	
	****************
	***luzmide_ch: Indica si el hogar usa un medidor para pagar por su consumo ***
	****************
	gen luzmide_ch=. //No existe la pregunta en la encuesta
	
	****************
	***combust_ch: Indica si el combustible principal usado en el hogar para cocinar es gas o electricidad  ***
	****************
	/*Para cocinar usa principalmente… - v14b:
			1	Leña
			2	Gas
			3	Carbón
			4	Electricidad
			5	Kerosene, alcohol
			6	Otro (especificar)
			7	Ninguno, no cocina
			9	NR
	*/
	gen combust_ch=.
	replace combust_ch=1 if v14b==2 | v14b==4	 //Utiliza gas o electricidad
	replace combust_ch=0 if inlist(v14b,1,3,5,6) //Utiliza otro combustible
	replace combust_ch=. if v14b==7 | v14b==9 | v14b==. //No cocina o no responde
	
	***********
	*piso_ch*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen piso_ch=.	
	
	***********
	*pared_ch*
	***********
	gen pared_ch=.	
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	***********
	*techo_ch*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
   	**************
	***resid_ch: método de eliminación de residuos utilizado por el hogar.***
	**************
	/*¿Cómo elimina habitualmente la basura? - v15:
			1	Quema
			2	Recolección pública
			3	Recolección privada
			4	Tira en el hoyo
			5	Tira en el patio, baldío, zanja o calle
			6	Tira en el vertedero municipal
			7	Tira en la chacra
			8	Tira en arroyo, río o laguna
			9	Otro (especificar)
			99	NR
			
	Las categorias de resid_ch son:
			0	recolección pública o privada. 
			1	quemados o enterrados. 
			2	tirados a un espacio abierto. 
			3	Otros 
	*/
	
	gen resid_ch=.
	replace resid_ch=0 if v15==2 | v15==3 //Recolección Pública o Privada
	replace resid_ch=1 if v15==1		  //Quemados
	replace resid_ch=2 if inrange(v15,4,8) //Tirados en un espacio abierto
	replace resid_ch=3 if v15==9 		  //Otro método
	replace resid_ch=. if v15==.		  //Missings
	
	*************
	***dorm_ch: cantidad de habitación que se destinan exclusivamente para dormir***
	*************
	*Variable v02b - N° de dormitorios
	gen dorm_ch=v02b
	
	****************
	***cuartos_ch: cantidad de habitaciones en el hogar ***
	****************
	*Variable v02a - N° de piezas (habitaciones)
	gen cuartos_ch=v02a	
	
	***************
	***cocina_ch: existe un cuarto separado y exclusivo para cocinar ***
	***************
	*¿Tiene pieza para cocinar? - v14a
	*		1	Sí
	*		2	No
	gen cocina_ch=.
	replace cocina_ch=1 if v14a==1	//Sí hay habitación para cocinar 
	replace cocina_ch=0 if v14a==6 //No hay habitación para cocinar
	
	**************
	***telef_ch: el hogar tiene servicio telefónico fijo ***
	**************
	*¿Tiene línea fija? - v11a
	*		1	Sí
	*		6	No
	gen telef_ch=.
	replace telef_ch=1 if v11a==1 //Sí cuentan con línea fija
	replace telef_ch=0 if v11a==6 //No cuentan con línea fija
	
	***************
	***refrig_ch: si el hogar posee heladera o refrigerador ***
	***************
	/*¿Tiene heladera? - v2403
			1	Sí tiene
			6	No tiene
			9	No responde
	*/
	
	gen refrig_ch=.
	replace refrig_ch=1 if v2403==1 		   //Sí tiene heladera
	replace refrig_ch=0 if v2403==6 		   //No tiene heladera
	replace refrig_ch=. if v2403==. | v2403==9 //Missing o No responde
	
	**************
	***freez_ch:  si el hogar posee freezer o congelador ***
	**************
	gen freez_ch=. //No existe la pregunta en lal encuesta 
	
	*************
	***auto_ch: si el hogar posee (tiene propiedad) al menos un automóvil particular**
	*************
	/*Este hogar tiene Automóvil, camión o camioneta - v2413
			1	Si tiene
			6	No tiene
			9	No responde
	*/
	gen auto_ch=.
	replace auto_ch=1 if v2413==1				//Si tiene auto
	replace auto_ch=0 if v2413==6				//No tiene auto
	replace auto_ch=. if v2413==. | v2403==9	//Missing o No responde
	
	**************
	***compu_ch: si el hogar posee computadora ***
	**************
	/*¿El hogar cuenta con computador/notebook? - v23a1
			1	Si 
			6	No 
			9	No responde
	
	*/
	gen compu_ch=.
	replace compu_ch=1 if v23a1==1				//Sí tienen computadora
	replace compu_ch=0 if v23a1==6				//No tienen computadora
	replace compu_ch=9 if v23a1==. | v23a1==9	//Missing o No responde
		
	*****************
	***internet_ch: si el hogar posee conexión a internet ***
	*****************
	/*¿Tiene el hogar internet? - v23b
			1	Si 
			6	No 
			9	No responde
	*/
	gen internet_ch=.
	replace internet_ch=1 if v23b==1 //Si tienen internet
	replace internet_ch=0 if v23b==6 //No tienen internet
	replace internet_ch=. if v23b==. | v23b==9 //Missing o No responde
	
	************
	***cel_ch: si al menos un integrante del hogar tiene servicio telefónico celular activa***
	************
	*En la encuesta existe la pregunta ¿Algún miembro del hogar tiene celular? - v11b, más no la pregunta de sí tienen línea activa. No se puede asumir que una persona que tenga telefono tenga línea activa (puede tener el telefono sin línea) Por tanto, la variable queda como missing.
	gen cel_ch=. 
	
	
	**************
	***vivi1_ch: Tipo de vivienda en la que reside el hogar***
	**************
	/*Tipo de vivienda - v01: 
			1	Casa, rancho
			2	Departamento o piso
			3	Pieza de inquilinato
			4	Vivienda improvisada
			5	Otro (especificar)
			9	No Responde
	*/

	/* Categorias de vivi1_ch:
			1	Casa 
			2	Departamento 
			3	Otros tipos 
	*/
	gen vivi1_ch=.
	replace vivi1_ch=1 if v01==1			//Casa
	replace vivi1_ch=2 if v01==2			//Departamento
	replace vivi1_ch=3 if inrange(v01,3,5)	//Otros Tipos
	replace vivi1_ch=. if v01==. | v01==9	//Missing o No Responde
	
	**************
	***vivi2_ch: vivienda en la que reside el hogar es una casa o un departamento***
	**************
	gen vivi2_ch=.
	replace vivi2_ch=1 if vivi1_ch==1 | vivi1_ch==2 //Casa o Departamento
	replace vivi2_ch=0 if vivi1_ch==3 				//Otros Tipos
	replace vivi2_ch=. if vivi1_ch==.
	
	*****************
	***viviprop_ch: Propiedad de la vivienda en la que reside el hogar***
	*****************
	/* Esta vivienda… - v16:
			1	Es propia
			2	La están pagando en cuotas
			3	Es en condominio
			4	Es alquilada
			5	Es ocupada de hecho
			6	Es cedida
			7	Otra situación (especificar)
			9	No responde

	Las categorias de viviprop_ch:
			0 Alquilada  
			1 Propia y totalmente pagada         
			2 Propia y en proceso de pago 
			3 Ocupada (propia de facto). Incluye propiedades cedidas o prestadas
			. No se sabe la respuesta / No hay respuesta
	*/
	gen viviprop_ch=.
	replace viviprop_ch=0 if v16==4				//Vivienda alquilada
	replace viviprop_ch=1 if v16==1 | v16==3	//Vivienda Propia	
	replace viviprop_ch=2 if v16==2				//En proceso de pago
	replace viviprop_ch=3 if inlist(v16,5,6,7)	//Ocupada	
	replace viviprop_ch=. if v16==. | v16==9	//Missing o No responde
	
	****************
	***vivitit_ch: si el hogar posee un título de propiedad ***
	****************
	gen vivitit_ch=. //No existe la pregunta
	
	****************
	***vivialq_ch: Monto mensual pagado por el alquiler de la vivienda***
	****************
	*El mes pasado. ¿Cuánto pagó el hogar por el alquiler? - v18: 
	gen vivialq_ch=v18
	replace vivialq_ch=. if v18==99999999999 //Codificación para los missings
	
	*******************
	***vivialqimp_ch: Monto mensual del valor que el informante cree que le pagarían por su vivienda propia que ocupa***
	*******************	
	*Si tuviera que alquilar esta vivienda, ¿cuánto estima que le pagarían por mes? - variable v19
	gen vivialqimp_ch=v19
	replace vivialqimp_ch=. if v19==99999999999 //Codificación para los missings

	
********************************************************************************
***************   VARIABLES DE WASH        *************************************
********************************************************************************	
	***********
	*aguared_ch*
	***********
	/*El agua que más utiliza el hogar proviene de…	- v06:
			1	ESSAP (red pública) 
			2	Junta de Saneamiento (SENASA) (red pública)
			3	Red comunitaria
			4	Red o prestador privado
			5	Pozo artesiano
			6	Pozo con bomba
			7	Pozo sin bomba
			8	Manantial o naciente
			9	Tajamar, río, arroyo
			10	Agua de lluvia
			11	Aguatero
			12	Otra fuente
			99	No responde 
	*/
	generate aguared_ch =.
	replace aguared_ch = 1 if (v06==1 | v06==2 | v06==3| v06==4) //Acceso a agua por red
	replace aguared_ch = 0 if v06>4 & v06<=12 //Acceso a agua por otro medio
	replace aguared_ch =. if v06==. | v06==99 //Missing o No responde
	label var aguared_ch "Acceso a fuente de agua por red"

	*****************
	*aguafconsumo_ch: Principal fuente de agua utilizada por el hogar para beber*
	*****************
	/*Agua que beben en el hogar proviene de... - v08:
			1	ESSAP (ex CORPOSANA)
			2	Junta de Saneamiento (SENASA)
			3	Red comunitaria
			4	Red o prestador privado
			5	Pozo artesiano
			6	Pozo excavado protegido (brocal y tapa)
			7	Pozo excavado sin protección (sin brocal y/o sin tapa)
			8	Manantial protegido
			9	Manantial sin protección
			10	Agua de lluvia
			11	Agua embotellada (mineral)
			12	Aguatero
			13	Agua superficial (río, represa, lago, estanque, ///
				arroyo, canal, canales de riego)
			14	Otro (especificar)
			99	No responde
			
	Categorias de aguafconsumo_ch:
			0	La encuesta no pregunta sobre agua para beber: ///
				No existe pregunta para conocer la fuente de agua de consumo.  
			1	Red de distribución, llave privada. 
			2	Llave pública, standpipe 
			3	Agua embotellada 
			4	Pozo protegido 
			5	Agua de lluvia 
			6	Camión, cisterna, pipa 
			7	Otra fuente mejorada no listada 
			8	Cuerpo de agua superficial 
			9	Otra fuente no mejorada 
			10 	Pozo, manantial, u otra fuente sin clasificación clara 
	*/
	
	gen aguafconsumo_ch = .
	replace aguafconsumo_ch = 1  if (v08==4 | v08==1 | v08==2 |v08==3) & v09<=2
	replace aguafconsumo_ch = 2  if (v08==4 | v08==1 | v08==2 |v08==3) & v09==3
	replace aguafconsumo_ch = 3  if v08==11
	replace aguafconsumo_ch = 4  if (v08==5 | v08==6)
	replace aguafconsumo_ch = 5  if v08==10
	replace aguafconsumo_ch = 6  if v08==12
	replace aguafconsumo_ch = 7  if v08==8 | ((v08==1 | v08==2 |v08==3| v08==4 |v08==5|v08==6|v08==8|v08==10|v08==11|v08==12) & v09==5 | v09==8) | (v08 == 8)
	replace aguafconsumo_ch = 8  if v08==13
	replace aguafconsumo_ch = 9  if v08==9 | v08==7
	replace aguafconsumo_ch = 10 if v08==14| v08==99


	*****************
	*aguafuente_ch: Principal fuente de agua utilizada por el hogar para todos los usos*
	*****************
	gen aguafuente_ch=1      if (v06==4 | v06==1 | v06==2 |v06==3) & v07a<=2
	replace aguafuente_ch=2  if (v06==4 | v06==1 | v06==2 |v06==3) & v07a==3
	replace aguafuente_ch=4  if (v06==5 | v06==6)
	replace aguafuente_ch=5  if v06==10
	replace aguafuente_ch=6  if v06==11
	replace aguafuente_ch=7  if (v06==1 | v06==2 |v06==3 |v06==4 |v06==5|v06==10|v06==11) & (v07a ==5 | v07a ==7)
	replace aguafuente_ch=8  if v06==9
	replace aguafuente_ch=10 if (v06==99|v06==12 | v06==8 |v06==7|(v06==.& jefe_ci!=.))
	
	*****************
	*aguadist_ch: Ubicación de la principal fuente de agua*
	*****************
	/*El agua que llega a su vivienda viene de... - v07a:
			1	Cañería dentro del terreno pero fuera de la vivienda
			2	Cañería dentro de la vivienda
			3	Canilla pública
			4	Pozo dentro del terreno
			5	Vecino
			6	Aguatero
			7	Otros medios (especificar)
			9	No responde
	
	Categorias de aguadisp1_ch:
			0	No se especifica 
			1	Adentro de la vivienda: por cañería o llave dentro ///
				de la vivienda o agua entubada dentro de la vivienda.  
			2	Afuera de la vivienda, pero adentro del terreno ///
				(o a menos de 100mts de distancia): agua entubada ///
				o por cañeria o llave fuera de la vivienda, pero dentro del terreno. 
			3	Afuera de la vivienda y afuera del terreno ///
				(o a más de 100mts de distancia): no tiene ///
				sistema lo acarrea, agua entubada de llave ///
				pública o por tubería fuera del edificio.  
	*/
	gen aguadist_ch=.
	replace aguadist_ch= 1 if v07a==2
	replace aguadist_ch= 2 if v07a==1 | v07a ==4 
	replace aguadist_ch= 3 if v07a==3 
	replace aguadist_ch= . if v07a==9 | v07a==.
	
	**************
	*aguadisp1_ch: si el hogar tiene continuidad de disponibilidad de agua *
	**************
	/*Normalmente ¿le provee agua al hogar las 24 horas ? - v07:
			1	Si
			6	No
			9	No responde
			.	NA
	*/
	gen aguadisp1_ch =.
	replace aguadisp1_ch=1 if v07==1
	replace aguadisp1_ch=0 if v07==6
	replace aguadisp1_ch=. if v07==. | v07==9
	
	**************
	*aguadisp2_ch: continuidad de disponibilidad de agua *
	**************
	gen aguadisp2_ch = 9 // La encuesta no hace esta se pregunta (el valor de esta variable es 9 según el manual)
	
	*************
	*aguatrat_ch: si el hogar trata el agua de su fuente antes de consumirla *
	*************
	gen byte aguatrat_ch =. //La encuesta no hace esta pregunta
	
	*************
	*aguamala_ch si la principal fuente de agua es "Unimproved" según JMP *  
	*************
	*Codigo extraído del manual
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.

	*****************
	*aguamejorada_ch: acceso a agua potable de fuente mejorada*  
	*****************
	*Codigo extraído del manual
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7
	
	*****************
	***aguamide_ch: si el hogar usa un medidor para pagar por su consumo de agua ***
	*****************
	gen aguamide_ch =. //La encuesta no hace esta pregunta

	
	*****************
	*bano_ch: Tipo de instalación sanitaria que tiene el hogar  *  
	*****************
	/*¿Tiene baño? - v12:
			1	Si
			6	No
			9	No responde
			
	El baño se desagüa en…	v13
			1	Red de alcantarillado sanitario (cloaca)
			2	Cámara séptica y pozo ciego
			3	Pozo ciego, sin cámara séptica
			4	En la superficie de la tierra, hoyo abierto, zanja, arroyo, río
			5	Letrina ventilada de hoyo seco (común con tubo de ventilación)
			6	Letrina común de hoyo seco (con losa, techo, paredes y puertas)
			7	Letrina común sin techo o puerta
			8	Otro (especificar)
			9	No informado
			.	NA
	
	Categorias de bano_ch: 
			0	Sin instalaciones, ejemplo: No dispone de sistema ///
				de eliminación de excretas o no tiene 
				excusado.  
			1	Indoro a red de desagüe: inodoro conectado a red ///
				pública, alcantarillado o cloaca.  
			2	Indoro a fosa séptica: inodoro a cámara séptica ///
				y pozo ciego o pozo o fosa séptica.  
			3	Letrina mejorada / otra instalación mejorada: ///
				Letrina conectada a pozo negro cajón.  
			4	Indoro/letrina a cuerpo de agua superficial o ///
				suelo: tubería que va a dar a un río, lago o 
				mar. 
			5	Instalación no mejorada: Baño químico dentro del sitio. 
			6	Instalación que no se puede clasificar. Letrina sin arrastre de agua. 
	*/
	gen bano_ch=.
	replace bano_ch=0 if v12==6 //No tiene baño
	replace bano_ch=1 if v13==1 //Inodoro a desagüe
	replace bano_ch=2 if v13==2 // Inodoro a pozo séptico
	replace bano_ch=3 if (v13==5 | v13==6) //Letrina mejorada
	replace bano_ch=4 if v13==4 //Letrina a cuerpo superficial
	replace bano_ch=5 if v13==7 //Instalación no mejorada
	replace bano_ch=6 if (v13==9 |v13==8 | v13==3) | (v13 ==. & jefe_ci!=.)  //Instalación que no se puede clasificar
			
	*****************
	*banoex_ch: Instalaciones del hogar son de uso exclusivo      *  
	*****************
	gen banoex_ch=. //No existe la pregunta en la encuesta
	
	************
	*sinbano_ch: que hace los hogares sin acceso a instalaciones propias *
	************
	gen sinbano_ch = .
	replace sinbano_ch = 0 if v12==1 //El hogar tiene baño
	replace sinbano_ch = 3 if v12==2 //El hogar no tiene baño pero no especifica cuáles alternativas ysa
		
	*****************
	*banomejorado_ch: el hogar tiene acceso a saneamiento de fuente mejorado
	*****************
	*Codigo extraído del manual 
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6
	
********************************************************************************
***************   VARIABLES DE MIGRACION   *************************************
********************************************************************************	
*No hay variables de migración en la encuesta 

	*******************
	*** migrante_ci: Si el individuo nació en otro país ***
	*******************	
	gen byte migrante_ci= .
	
	**********************
	*** migantiguo5_ci: si el migrante ha estado viviendo 5 años o más en el país de la encuesta***
	**********************
	gen byte migrantiguo5_ci=.
	
	**********************
	*** miglac_ci: si el individuo es migrante latino o del caribe***
	**********************
	gen byte miglac_ci = .
	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar: Como mide el bienestar la encuesta*
	****************
	/*
		1 Ingreso
		2 Consumo
	*/	
	gen byte tipo_bienestar = 1 //El bienestar se mide mediante el ingreso

	****************
	 * pobre_ine_ci*
	****************
	/*Variable de condición de pobreza de la encuesta - pobnopoi: 
		0	No pobre
		1	Pobre
		.	NA
	*/
	gen byte pobre_ine_ci= pobnopoi
	label define pobre_ine_ci 1 "Pobre" 0 "No pobre"
	label value pobre_ine_ci pobre_ine_ci
	
	****************
	 * bienestar_agregado *
	****************
	*Ingreso per cápita mensual - ipcm
	gen bienestar_agregado = ipcm

	****************
	* lpe_ci:  Variable continua que indica el umbral de pobreza utilizada por el país para identificar a los individuos en nivel de pobreza extrema. *
	****************
	*La variable linpobex captura la línea de pobreza extrema para las zonas rurales y urbanas. Hay 2 valores en la variable, el valor más pequeño corresponde a la zona rural y el más grande a la zona urbana.
	sum linpobex
	gen 	lpe_ci = `r(min)' if zona_c==0 //Linea de pobreza de la zona rural
	replace lpe_ci = `r(max)' if zona_c==1 //Linea de pobreza de la zona urbana

	****************
	 * ln_ci: Variable continua que indica el umbral de pobreza oficial del país para identificar a los individuos en nivel de pobreza.  *
	****************	
	*La variable linpobto captura la línea de pobreza extrema para las zonas rurales y urbanas. Hay 2 valores en la variable, el valor más pequeño corresponde a la zona rural y el más grande a la zona urbana.
	sum linpobto
	gen 	ln_ci = `r(min)' if zona_c==0 //Linea de pobreza de la zona rural
	replace ln_ci = `r(max)' if zona_c==1 //Linea de pobreza de la zona urbana
	

/*________________________________________________________________________________________________*/

/* Asignación de etiquetas e insercion de variables externas: tipo de cambio, Indice de Precios al*/
/* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  lineas de pobreza             */
/*________________________________________________________________________________________________*/
 



do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"
/*________________________________________________________________________________________________*/

/* Verificación ¤e que se encuentren todas las variables armonizadas                              */
/*________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci ytot_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch  ynlm_ch ynlnm_ch ytot_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  pnc_ci ptmc_ci potrot_ci ypnc_ci yptmc_ci yotrot_ci ytransf_ci ynet_ci pnc_ch ptmc_ch potrot_ch ypnc_ch yptmc_ch yotrot_ch ytransf_ch ynet_ch ynet_ch_pc /// Protección social
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci edupre_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  lp19_2011 lp31_2011 lp5_2011 lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

/*Homologar nombre del identificador de ocupaciones (isco, ciuo, etc.) y dejarlo en base armonizada 
para analisis de trends (en el marco de estudios sobre el futuro del trabajo)*/

compress

foreach i of varlist _all {
local longlabel: var label `i'
local shortlabel = substr(`"`longlabel'"',1,79)
label var `i' `"`shortlabel'"'
}

   
saveold "`base_out'", version(12) replace

cap log close
