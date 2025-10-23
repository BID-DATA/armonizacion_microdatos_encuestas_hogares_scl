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

local PAIS HND
local ENCUESTA EPHPM
local ANO "2024"
local ronda m6 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
cap log using "`log_file'", replace 



/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
Pais: ....
Encuesta: ...
Round: ...
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
/* 12 variables: region_BID_c , region_c , pais_c, anio_c, mes_c, zona_c, estrato_ci, 
 upm_ci, idh_ch, idp_ci, factor_ch , factor_ci */

	********************
	*** region_BID_c : país de residencia de hogares según agrupación BID  ****
	********************
	gen byte region_BID_c=1
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 ///
	"Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
	label value region_BID_c region_BID_c

	********************
	*** region_c:  Identifica  primera división político-administrativa del país****
	********************
	gen byte region_c = DEPMUESTRA
	label define region_c ///
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
	label value region_c region_c
	
	*************
	* pais_c : acrónimo ISO del nombre del país de residencia   *
	*************
	gen str3 pais_c="HND"

	******
	*anio_c: año de la entrevista de campo de la encuesta**
	******
	gen int anio_c=2024
	
	******
	*mes_c: mes de la entrevista de campo de la encuesta***
	******
	*En el cuestionario está el espacio para llenar el mes en el que se realizó cada entrevista, no obstante esta información no está en ninguna variable de la base de datos final. 
	
	*En el do file de variables del 2023 hicieron esta normalización para todas las entrevistas. 
	gen mes_c= 6
	label define mes_c 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" ///
	6 "Junio" 7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" ///
	12"Diciembre" 
	label value mes_c mes_c

	
	
	******
	*zona_c: dominio geográfico, área de residencia o zona *
	******
	/*
	DOMINIO: Variable de dominio geográfico de la EPHPM
			1 Distrito Central
			2 San Pedro Sula
			3 Ciudades Medianas
			4 Ciudades Pequeñas
			5 Rural
	*/
	gen zona_c=1 if DOMINIO==1 | DOMINIO==2 | DOMINIO==3 | DOMINIO==4 // Urbana
	replace zona_c=0 if DOMINIO==5 // Rural
	label define zona_c 0 "Rural" 1 "Urbana" 
	label value zona_c zona_c
	
	*********
	*estrato: No hay variable de estrato*
	*********
	gen estrato_ci=.
	label variable estrato_ci "Estrato"
	
	 *****************************
	*upm_ci: unidad primaria de muestreo*
	*****************************
	*Así se hizo en el 2023, no me hace mucho sentido
	gen upm_ci=DOMINIO
	label variable upm_ci "Unidad Primaria de Muestreo"
	
	******************
	*idh_ch: Identificador único de hogares *
	******************
	gen idh_ch=HOGAR // Indicador del Hogar	
	tostring idh_ch, replace
	
	***************
	****idp_ci: Identificador único del individiuo ***
	***************
	*Se concatena el indicador del hogar con el indicador de la persona //
	*dentro del hogar (ORDEN). 
	egen idp_ci = concat(HOGAR ORDEN)
	tostring idp_ci, replace format ("%20.0f") 
		
	***********
	*factor_ci: Factor de expansión del individuo* 
	***********
	gen factor_ci=FACTOR
	label var factor_ci "Factor de Expansion de los individuos"

	
	*******************************************
	*factor_ch: Factor de expansion del hogar*
	*******************************************
	gen factor_ch=FACTOR
	label var factor_ch "Factor de Expansion del Hogar" // Es el mismo que el factor del individiuo


********************************************************************************
***************   VARIABLES DEMOGRAFICAS   *************************************
********************************************************************************

	*********
	*sexo_ci: sexo del individuo*
	*********
	gen byte sexo_ci=SEXO	
	label var sexo_ci "Sexo del Individuo"
	label define sexo_ci 1 "Hombre" 2 "Mujer"
	label value sexo_ci sexo_ci

	*********
	*edad_ci: edad del individuo*
	*********
	gen int edad_ci=EDAD // Años cumplidos
	label var edad_ci "Edad del Individuo" 
	
	**************
	**relacion_ci: Variable que indica la relación o parentesco del individuo respecto al jefe de hogar**
	**************
	/*
	RELA_J: Variable de relación con el jefe del Hogar de la EPHPM
			1 Jefe(a) del Hogar
			2 Esposa (o) o compañera (o)
			3 Hijos(as) de mayor a menor
			4 Hijastros(as) de mayor a menor
			5 Padres
			6 Hermanos(as)
			7 Yernos y nueras
			8 Otros parientes   (nieto, abuelo, tío, primo, etc.)
			9 Otros no parientes  (suegro, cuñado, huésped, etc.)
			10 Servicio doméstico
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
	replace relacion_ci=1 if RELA_J==1 // Jefe del Hogar
	replace relacion_ci=2 if RELA_J==2 // Cónyugue/Pareja
	replace relacion_ci=3 if RELA_J==3 | RELA_J==4 // Hijo/a y Hijastro/a
	replace relacion_ci=4 if 5<=RELA_J & RELA_J<=8 // Otros parientes
	replace relacion_ci=5 if RELA_J==9 // No parientes
	replace relacion_ci=6 if RELA_J==10 // Empleado/a
	label var relacion_ci "Relacion con el Jefe de Hogar"
	label define relacion_ci 1 "Jefe/a de Hogar" 2 "Cónyuge/Pareja" 3 "Hijo/a" ///
	4 "Otros Parientes" 5 "No Parientes" 6 "Empleado/a domestico/a"
	label value relacion_ci relacion_ci

	*************
	*miembros_ci: Variable dicotómica que identifica a los miembros del hogar. *
	*************
	gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
	replace miembros_ci=. if relacion_ci==. 
	
	*************
	*miembros_one_ci: Variable dicotómica que identifica a los miembros del hogar según la definición disponible en cada encuesta. *
	*************
	gen miembros_one_ci=miembros_ci // No hay variable directa - usamos RELA_J
	
	**************
	*civil_ci: Estado Civil*
	**************
	
	/*CIVIL: Variable de relación con el jefe del Hogar de la EPHPM
			1 Casado(a)
			2 Viudo(a)
			3 Divorciado(a)
			4 Separado(a)
			5 Soltero(a)
			6 Unión libre
	*/
	
	/* Categorias del BID:
			1 Soltero
			2 Unión formal o informa
			3 Divorciado o separado
			4 Viudo
	*/
	
	gen civil_ci=.
	replace civil_ci=1 if CIVIL==5 // Soltero
	replace civil_ci=2 if CIVIL==1 | CIVIL==6 // Unión formal
	replace civil_ci=3 if CIVIL==3 | CIVIL==4 // Divorciado/Separado
	replace civil_ci=4 if CIVIL==2 // Viudo
	label var civil_ci "Estado Civil"
	label define civil_ci 1 "Soltero" 2 "Union Formal o Informal" ///
	3 "Divorciado o Separado" 4 "Viudo"
	label value civil_ci civil_ci
		
	*********
	*jefe_ci: Variable dicotómica que identifica al jefe del hogar.*
	*********
	gen byte jefe_ci=(relacion_ci==1)
	label variable jefe_ci "Jefe de hogar"
		
	**************
	*nconyuges_ch: Variable que indica el N° de cónyuges o esposos/as en el hogar*
	**************
	by idh_ch, sort: egen nconyuges_ch=sum(relacion_ci==2)
    replace nconyuges_ch =. if relacion_ci==.
	label variable nconyuges_ch "Numero de cónyuges"
	
	***********
	*nhijos_ch: Variable que indica el número de hijos/as en el hogar.*
	***********
	by idh_ch, sort: egen byte nhijos_ch=sum(relacion_ci==3)
	replace nhijos_ch =. if relacion_ci==.          
	label variable nhijos_ch "Numero de hijos"

	**************
	*notropari_ch: Variable que indica el número de otros parientes en el hogar.*
	**************
	by idh_ch, sort: egen byte notropari_ch=sum(relacion_ci==4)
	replace notropari_ch =. if relacion_ci==.
	label variable notropari_ch "Numero de otros parientes"

	**************
	*notronopari_ch: Variable que indica el número de "no" parientes en el hogar.*
	**************
	by idh_ch, sort: egen byte notronopari_ch=sum(relacion_ci==5) // Son "no" parientes pero miembros del hogar
	replace notronopari_ch=. if relacion_ci==.          
	label variable notronopari_ch "Numero de no familiares"
		
	****************
	*nempdom_ch: Número de empleados domésticos reportados en el hogar.*
	****************
	by idh_ch, sort: egen byte nempdom_ch=sum(relacion_ci==6) 
	replace nempdom_ch =. if relacion_ci==.
	label variable nempdom_ch "Numero de empleados domesticos" //no son miembros del hogar
        		
	*************
	*clasehog_ch: Identifica el tipo de hogar según la cantidad de individuos.*
	*************
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
	*nmiembros_ch: Indica el número total de miembros de categoría familiares en el hogar. *
	**************
	by idh_ch, sort: egen byte nmiembros_ch=sum(relacion_ci>0 & relacion_ci<=5)
		
	*************
	*nmayor21_ch: Indica el número total de miembros del hogar con 21 años o más de edad. *
	*************
	by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci!=.)) // la máxima edad en 2024 es de "106" años

	*************
	*nmenor21_ch: Indica el número total de miembros del hogar con menos de 21 años.*
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
	*nmenor1_ch: Indica el número total de miembros del hogar con menos de 1 año.*
	************
	by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))


********************************************************************************
***************   VARIABLES DE DIVERSIDAD   *************************************
********************************************************************************

	*********
	*afro_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial afrodescendiente. *
	*********
	/*
		1 autoidentificados como: negro, afrodescendiente o variaciones
		0 NO autoidentificados como: negro, afrodescendiente o variaciones
	*/
	
	/* CH038: Variable de autoidentificación de la EPHPM
			1	Garífuna
			2	Negro ingles
			3	Tolupán
			4	Pech (paya)
			5	Misquito
			6	Nahua
			7	Lenca
			8	Tawahka (Sumo)
			9	Maya Chortí
			10	Mestizo / ladino
			11	No sabe / ninguno
			12	Otro (especifique)
	*/
	
	gen afro_ci=(inlist(CH308,1,2)==1) if CH308!=. // 1 Garífuna y 2 Negro ingles
	
	*********
	*ind_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial indígena*
	*********	
	gen ind_ci=(inlist(CH308,1,3,4,5,6,7,8,9)==1) if CH308!=.

	**************
	*noafroind_ci: Identificar encuestados que NO son afrodescendientes NI indígenas según autoidentificación étnico-racial*
	**************
	gen byte noafroind_ci = . // esta variable puede tener missings
	replace noafroind_ci = 1 if afro_ci==0 & ind_ci==0
	replace noafroind_ci = 0 if afro_ci==1 | ind_ci==1	
	
	*********
	*afro_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente*
	*********
	gen  byte afro_jefe = afro_ci if relacion_ci==1 // Jefe
	egen afro_ch  = max(afro_jefe), by(idh_ch) // Si el hogar tiene un jefe definido afro
	drop afro_jefe
	
	********
	*ind_ch: Identifica si el jefe de hogar se autoidentifica como indígena.*
	********	
	gen byte ind_jefe = ind_ci if relacion_ci==1 // Jefe
	egen ind_ch = max(ind_jefe), by(idh_ch) // Si el hogar tiene un jefe definido indigena
	drop ind_jefe
	
	**************
	*noafroind_ch: Identifica si el jefe de hogar no se autoidentifica como parte de la población indígena ni afrodescendiente.
	**************
	gen byte noafroind_jefe = noafroind_ci if relacion_ci==1 // Jefe
	egen noafroind_ch = max(noafroind_jefe), by(idh_ch) // Hogar
	drop noafroind_jefe
	
	*******************
	***afroind_ano_c: Variable continua identifica el año en que se comenzó a utilizar en cada encuesta la metodología de medición de raza/etnicidad. ***
	*******************
	gen afroind_ano_c=2023 // por confirmar
	
	************
	*afroind_ci: Identifica a los encuestados en función de su autoidentificación étnica o racial.*
	************
	gen byte afroind_ci=.
	replace afroind_ci = 1 if ind_ci==1 // Indígena
	replace afroind_ci = 2 if afro_ci==1 // Afrodescendiente
	replace afroind_ci = 3 if ind_ci==0 & afro_ci==0 // otros
	
	************
	*afroind_ch: Identifica si el jefe de hogar se autoidentifica como afrodescendiente, indigena o como no afrodescendiente u indígena*
	************
 	gen byte afroind_jefe = afroind_ci if jefe_ci==1
	egen afroind_ch = min(afroind_jefe), by(idh_ch) 
	drop afroind_jefe 

	
	
* 2.3.2 Situación de discapacidad	
	********
	*dis_ci: Identifica a los individuos con discapacidad siguiendo de forma flexible el criterio del WG.*
	********
	/* CH037: Tiene algun tipo de dificultad para:
			1 Caminar, moverse, subir o bajar
			2 Ver aun usando lentes
			3 Hablar comunicarse conversar
			4 Oir aun usando aparato auditivo
			5 Vestirse, bañarse o comer
			6 Poner atencion, aprender cosas
			7 Tiene alguna limitacion mental
			8 Psicosocial
			9 Ninguna
	*/
	
*Pregunta CH307 se hace a personas de 5 años y mas	

	gen byte dis_ci=.
	replace  dis_ci = 1 if CH307 != 7 & CH307 != 8 & CH307 != 9  // Todas menos las dificultades piscologicas listadas en la variable CH037
	replace  dis_ci = 0 if CH307 == 7 | CH307 == 8 | CH307 == 9  

	**********
	*disWG_ci: Identifica a individuos con discapacidad siguiendo de manera estricta el criterio del WG -- individuo como persona con discapacidad si reporta "mucha dificultad" o "no puede hacerlo.*
	**********
	gen byte disWG_ci=. // Solo existe una pregunta sobre la existencia de dificultad - por es missing
	
	******************
	*ISO3pais_dis_ci: Variable dicotomica generada para todos los países que incluyan cualquier tipo de pregunta sobre estado de discapacidad*
	******************
	gen byte HND_dis_ci = dis_ci

	********
	*dis_ch: Dicotómica Identifica si un hogar tiene uno o más miembros con discapacidad*
	********
	egen byte dis_ch = max(dis_ci), by(idh_ch) 
	replace dis_ch =1 if dis_ch>=1 & dis_ch!=. // añadido por seguridad

********************************************************************************
***************   VARIABLES DE MERCADO LABORAL   *******************************
********************************************************************************

	*************
	*condocup_ci: Identifica la condición de ocupación del individuo. *
	*************
	/* Variable de condición de ocupación de la encuesta - CONDACT:
			1	Ocupados
			2	Desocupados
			3	Poblacion fuera de la fuerza de trabajo
	
	A los que son población fuera de la fuerza de trabajo se les hace la siguiente pregunta por su tipo de inactividad TIPINAC:	
			1	Potencialmente Activos
			2	Desalentados
			3	Inactivos

	Categorias de condocup_ci:
			1	Ocupado
			2	Desocupado
			3	Inactivo
			4	Menor que la edad límite de los entrevistados
	*/	
	gen byte condocup_ci = .
	replace condocup_ci = 1 if CONDACT==1 //Ocupados
	replace condocup_ci = 2 if CONDACT==2 //Desocupados
	replace condocup_ci = 3 if CONDACT==3 & TIPINAC==3 //Inactivos
	replace condocup_ci = 4 if edad_ci<5 //Según la encuesta, las preguntas sobre ocupación se hacen a personas de 5 años en adelante

	*******************
	***categoinac_ci: Identifica la condición de inactividad de los individuos.***
	*******************
	/*
	A los que son población fuera de la fuerza de trabajo (CONDACT==3) se les hace la siguiente pregunta por su condición actual - CA514:
			1	Está jubilado?
			2	Está pensionado?
			3	Es rentista?
			4	Se dedica solo a estudiar?
			5	Se dedica a los quehaceres del hogar?
			6	Por su edad no puede trabajar (menor o mayor)?
			7	Está enfermo de gravedad?
			8	Está discapacitado?
			9	No hace nada?
			97	Otra
	
	Categorias de categoinac_ci:
			1	Jubilados o pensionados
			2	Estudiantes
			3	Quehaceres domésticos
			4	Otros inactivos
	*/
	gen byte categoinac_ci = .
	replace categoinac_ci = 1 if (inlist(CA514,1,2) & condocup_ci == 3) //Jubilado o Pensionado
	replace categoinac_ci = 2 if  (CA514 == 4 & condocup_ci == 3) //Estudiante
	replace categoinac_ci = 3 if  (CA514 == 5 & condocup_ci == 3) //Quehaceres domesticos
	replace categoinac_ci = 4 if  (!inlist(CA514,1,2,4,5) & condocup_ci == 3) //Otros Inactivos
	replace categoinac_ci = . if condocup_ci==. | CA514==. //Missings
	
	**********
	***emp_ci: Variable dicotómica que identifica con valor 1 a los ocupados y 0 a los no ocupados y mantiene con valores perdidos a los que se muestran en la encuesta con valores perdidos*
	**********
	*Codigo Extraido del Manual
	gen byte emp_ci = .
	replace emp_ci = (condocup_ci == 1) if condocup_ci != .

	**************
	***cesante_ci: Identifica a las personas que actualmente se encuentran desempleadas pero que habían trabajado anteriormente. Toma valor de 1 cuando la persona es cesante; 0 para el resto de los desocupados y con missing value al resto de la población.*** 
	**************
	/*¿Ha trabajado antes? - CA517:
			1	Si
			2	No
	*/
	gen byte cesante_ci = .
	replace cesante_ci = 1 if CA517 == 1 & condocup_ci == 2 //Ha trabajado antes (CA517==1) y ahora está desocupado (condocup_ci==2) 
	replace cesante_ci = 0 if cesante_ci != 1 & condocup_ci ==2 //Se quedan con 0 las observaciones que son desocupados y no son cesantes 

	***************
	***desemp_ci: Variable dicotómica que identifica con valor 1 a los desocupados, 0 a los individuos que son parte del grupo de referencia y missing para el resto de la población.***
	***************	
	*Codigo estraído del manual
	gen byte desemp_ci = .
	replace desemp_ci = (condocup_ci == 2) if condocup_ci! = .
	
	***************
	***subemp_ci: Variable dicotómica que indica con valor 1 si la persona trabaja 30 o menos horas a la semana en la actividad principal, está disponible para trabajar más horas y quiere/desea/está dispuesto a trabajar más horas (subempleo visible); y con valor 0 al resto de la población ocupada. ***
	***************
	*Total de horas laboradas en ocupación principal - TOTHRSOP
	*Durante la semana pasada, ¿hubiera querido trabajar más horas (en su mismo trabajo o en otro)? - CA522 
	*No existe pregunta referente a si la persona está disponible para trabajar más horas. No se crea la variable, pues la voluntad a trabajar (CA522) no implica disponibilidad de hacerlo. La variable queda como missing.
	gen byte subemp_ci = .

	****************
	***durades_ci: Indica la duración del desempleo en meses o el número de meses –no necesariamente consecutivos– que un individuo desempleado ha estado buscando empleo. Para los no desempleados la variable toma missing values.***
	****************
	*MESEST: Meses buscando trabajo
	gen byte durades_ci=MESEST 

	***********
	***pea_ci: Variable dicotómica que indica la población económicamente activa (PEA).***
	***********
	*Codigo extraido del manual
	gen byte pea_ci = .
	replace pea_ci = 1 if inlist(condocup_ci,1,2) //Ocupados y Desocupados
	replace pea_ci = 0 if inlist(condocup_ci,3,4) //Inactivos y menores de 5 años
	
	****************
	*** nempleos_ci: Variable que indica el número de empleos que tiene la persona.**
	****************
	gen byte nempleos_ci = . //No existe la variable en la encuesta

	******************
	***antiguedad_ci: Años de trabajo en la actividad principal actual de la persona ocupada. Cualquier  duración menor a 12 meses se programa a 0 años.***
	******************
	gen byte antiguedad_ci = . //No hay variable de antiguedad en la ocupación actual
	
	***************
	***desalent_ci: Variable dicotómica que indica con el valor de 1 si las personas que se clasifican como inactivas declaran que no buscan trabajo por desanimo, cansancio o sentimiento de incapacidad. y con valor 0 al resto de los individuos de la población de referencia.***
	***************
	/*¿Por qué no buscó trabajo ni trató de establecer su propio negocio o finca en las últimas cuatro semanas? - CA513:
			1	Ya encontró trabajo (iniciará antes de un mes)
			2	Abrirá o reabrirá negocio antes de un mes
			3	Se irá a trabajar a otro país
			4	Espera respuesta a gestiones anteriores
			5	Está esperando la próxima temporada / proyecto
			6	Cree que no encontrará o no le darán trabajo
			7	No tiene tierra, capital o materia prima
			8	En esta zona no hay trabajo del que necesita
			9	Dejo de buscar momentaneamente
			10	No quiere / no puede / no necesita trabajar
	*/
	gen byte desalent_ci=.
	replace desalent_ci=1 if CA513==6 & condocup_ci==3 //Se consideran los que creen que no les darán trabajo como desanimados
	replace desalent_ci=0 if CA513!=6 & condocup_ci==3 //Se pone como 0 al resto 
	
	***************
	***horaspri_ci: Variable continua que indica el número de horas totales trabajadas en la actividad principal en la semana de referencia.***
	***************
	*TOTHRSOP: Total de horas laboradas en ocupación principal
	gen  byte horaspri_ci = TOTHRSOP
	
	***************
	***horastot_ci: Variable continua que indica el número de horas totales trabajadas en todas las actividades económicas en una semana.***
	***************	
	*THORAS:Total de horas laboradas
	gen  byte horastot_ci  = THORAS
	
	
	***************
	***tiempoparc_ci: Variable dicotómica que indica con valor 1 si la persona trabaja menos de 30 horas a la semana en la actividad principal y no desea trabajar más***
	***************
	*CA522 - Durante la semana pasada, ¿hubiera querido trabajar más horas?:
	*		1	Sí
	*		2	No
	*		9	No sabe
	gen  byte tiempoparc_ci = .
	replace tiempoparc_ci=(horaspri_ci<=30 & CA522==2) if condocup_ci==1 //Si la  persona es ocupada (condocup_ci==1), trabaja menos de 30 horas (horaspri_ci<=30) y durante la semana pasada NO hubiese querido trabajar más (CA522) se asigna 1. Al resto de personas ocupadas se les asigna 0. La variable queda con missings para las personas no ocupadas (condocup_ci!=1).
	
	***************
	***categopri_ci: Indica la categoría ocupacional de la actividad principal para los ocupados. (Solo aplica para los trabajadores ocupados emp_ci=1) ***
	***************	
	
	/*OC609 - En esta ocupacion, trabaja como:
			1	Empleado u obrero en el sector público
			2	Empleado u obrero en el sectorprivado
			3	Empleado doméstico
			4	Pasante / aprendiz / practicante remunerado en el sector público
			5	Pasante / aprendiz / practicante remunerado en el sector privado
			6	Empleador, patrón o socio activo
			7	Trabajador independiente o por cuenta propia
			8	Trabajador familiar auxiliar
			9	Contratista dependiente en el sector público
			10	Contratista dependiente en el sector privado
			11	Contratista dependiente en el sector de los hogares
	
	Categorias de categopri_ci: 
			0	Otra clasificación
			1	Patrón o empleador
			2	Cuenta Propia o independiente
			3	Empleado o asalariado
			4	Trabajador no remunerado
	*/
	gen categopri_ci=.
	replace categopri_ci=1 if inlist(OC609,6) & condocup_ci==1 //Patrón o Empleador
	replace categopri_ci=2 if inlist(OC609,7) & condocup_ci==1 //Independiente
	replace categopri_ci=3 if inlist(OC609,1,2,3,4,5,9,10,11) & condocup_ci==1 //Empleado o asalariado
	replace categopri_ci=4 if inlist(OC609,8) & condocup_ci==1 //Trabajador Familiar - No remunerado
	label var categopri_ci "Categoria ocupacional actividad principal"
	label define categopri_ci 1 "Patrón o Empleador" 2 "Cuenta Propia" 3 "Empleado" 4 "Trabajador no remunerado"
	label value categopri_ci categopri_ci
	
	***************
	***categosec_ci: Indica la categoría ocupacional de la actividad secundaria. (Solo aplica para los trabajadores ocupados emp_ci=1)***
	***************	
	gen  byte categosec_ci = . //No hay variable de categoría ocupacional de la actividad secundaria

	***************
	***rama_ci: Indica la actividad laboral de la ocupación principal según la Clasificación industrial Uniforme a un dígito con las que fueron codificadas las bases originales para su armonización (Para ver un detalle de los criterios originales utilizados por cada país ver anexo A4_rama_ci). La mayoría de los países usan la clasificación CIIU pero en diferentes revisiones. Si la base de datos ya incluye esta variable es importante hacer un control de calidad y cerciorarse de la revisión que se está armonizando. Solo para los ocupados emp_ci=1.***
	***************	
	/*RAMAOP - Rama de ocupación principal:
			1	Agricultura, ganadería, silvicultura y pesca
			2	Explotacion de minas y canteras
			3	Manufacturera
			4	Suministro de electricidad, gas, vapor y aire acondicionado
			5	Suministro de agua evacuación de aguas residuales, ///
				gestión de desechos y descontaminación
			6	Construcción
			7	Comercio al por mayor y al por menor reparación ///
				de vehículos automotores y motocicletas
			8	Transporte y almacenamiento
			9	Actividades de alojamiento y de servicio de comidas
			10	Información y comunicaciones
			11	Actividades financieras y de seguros
			12	Actividades inmobiliarias
			13	Actividades profesionales, científicas y técnicas
			14	Actividades de servicios administrativos y de apoyo
			15	Administración pública y defensa planes de seguridad ///
				social de afiliación obligatoria
			16	Enseñanza
			17	Actividades de atención de la salud humana y de asistencia social
			18	Actividades artísticas, de entretenimiento y recreativas
			19	Otras actividades de servicios
			20	Actividades de los hogares como empleadores actividades ///
				no diferenciadas de los hogares como productores de bienes y ser
			21	Actividades de organizaciones y órganos extraterritoriales
			22	Rama sin especificar
			23	Busca trabajo por primera vez
			99	No Responde
	
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
			10	Gobierno
	*/
	gen rama_ci=.
	replace  rama_ci=1 if RAMAOP==1 & emp_ci==1 
	replace  rama_ci=2 if RAMAOP==2 & emp_ci==1 
	replace  rama_ci=3 if RAMAOP==3 & emp_ci==1
	replace  rama_ci=4 if RAMAOP==4 | RAMAOP==5  & emp_ci==1
	replace  rama_ci=5 if RAMAOP==6 & emp_ci==1
	replace  rama_ci=6 if RAMAOP==7 | RAMAOP==9  & emp_ci==1
	replace  rama_ci=7 if RAMAOP==8 | RAMAOP==10 & emp_ci==1
	replace  rama_ci=8 if inrange(RAMAOP,11,14)  & emp_ci==1
	replace  rama_ci=9 if inrange(RAMAOP,15,21)  & emp_ci==1
	label var rama_ci "Rama de actividad"
	label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras" 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento" 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
	label val rama_ci rama_ci 
	
	
	***************
	***spublico_ci: Variable dicotómica que indica con valor 1 si la persona lleva a cabo su actividad laboral principal en el sector público y con valor 0 al resto de la población. Solo para los ocupados emp_ci=1.***
	***************	
	*Codigo Extraído del manual
	gen byte spublico_ci = .
	replace spublico_ci = 1 if emp_ci == 1 & rama_ci == 10
	replace spublico_ci = 0 if emp_ci == 1 & rama_ci != 10 & rama_ci != .

	***************
	***tamemp_ci: Indica la categoría del tamaño de la empresa donde el individuo realiza su actividad laboral principal.***
	***************	
	/*N° de trabajadores de la empresa - OC_608_CUANTAS: 
	
	Categorias de tamemp_ci:
			1	Pequeña: de 1-5 personas en la empresa.
			2	Mediana: de 6-50 personas en la empresa.
			3	Grande: más de 50 personas en la empresa.
			.   no se cuenta con información
	
	Para Honduras, de acuerdo a la cantidad de Trabajadores:
			1-5		Pequeña Empresa
			6-50	Mediana Empresa
			51-∞ 	Gran Empresa
	*/
	gen tamemp_ci = 1 if (OC_608_CUANTAS>=1 & OC_608_CUANTAS<=5) & emp_ci==1 //Pequeña
	replace tamemp_ci = 2 if (OC_608_CUANTAS>=6 & OC_608_CUANTAS<=50) & emp_ci==1 //Mediana
	replace tamemp_ci = 3 if (OC_608_CUANTAS>50) & OC_608_CUANTAS!=. & emp_ci==1 //Grande
	replace tamemp_ci=. if  OC_608_CUANTAS>=99999 //Missings
	label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
	label value tamemp_ci tamemp_ci
	label var tamemp_ci "Tamaño de empresa"
	
	***************
	***cotizando_ci: Variable dicotómica que indica con valor 1 si el asalariado o independiente cotiza a la seguridad social, de forma voluntaria o por medio de su empleador, en el periodo de referencia, con 0 a los desocupados o independientes que no responden si la encuesta no les pregunta y con valores perdidos si la variable original lo tiene. ***
	***************	
	gen  byte cotizando_ci = . //No existe la pregunta en la encuesta
	
	***************
	***instcot_ci: Variable categórica que indica la institución de la Seguridad Social a la cual cotiza o está afiliado. Contiene la información de la variable original de la base de datos. ***
	***************	
	*gen  byte instcot_ci = . //No existe la pregunta en la encuesta
	
	***************
	***afiliado_ci: Variable dicotómica que indica con valor 1 si el trabajador está afiliado a la Seguridad Social (independientemente que haya o no cotizado en el mes de referencia), con 0 al resto del grupo de referencia y mantenemos con valores perdidos si la encuesta los tiene como perdidos. ***
	***************	
	gen  byte afiliado_ci = . //No existe la pregunta en la encuesta
	
	**************
	***formal_ci: Variable dicotómica que indica con valor 1 si el trabajador es formal y con 0 al resto. Un individuo se califica como formal si está afiliado o cotiza a la Seguridad Social. ***
	**************
	gen byte formal_ci = . //No existe la pregunta en la encuesta**
	
	*******************
	***tipocontrato_ci: Variable categórica que indica el tipo de contrato laboral de los empleados/asalariados en la actividad principal según su duración (los trabajadores no asalariados deberían identificarse con valor perdido).***
	*******************
	gen byte tipocontrato_ci = . //No existe la pregunta en la encuesta
	
	**************
	***ocupa_ci: Variable categórica que indica la ocupación laboral de los ocupados en la actividad principal***
	**************
	/* Vaariable de tipo de ocupación de la encuesta - OCUPAOP:
			1	Directores y gerentes
			2	Profesionales cientificos e intelectuales
			3	Tecnicos y profesionales de nivel medio
			4	Personal de apoyo administrativo
			5	Trabajadores de los servicios y vendedores de ///
				comercios y mercados
			6	Agricultores y trabajadores calificados ///
				agropecuarios forestales y pesqueros
			7	Oficiales, operarios y artesanos de artes ///
				mecanicas y de otros oficios
			8	Operadores de instalaciones y maquinas y ensambladores
			9	Ocupaciones elementales
			10	Ocupaciones militares
			23	Busca trabajo por primera vez
			99	NS/NR
	
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
	gen ocupa_ci=.
	replace ocupa_ci=1 if OCUPAOP==2 & emp_ci==1
	replace ocupa_ci=2 if OCUPAOP==1 & emp_ci==1
	replace ocupa_ci=3 if (OCUPAOP==3 | OCUPAOP==4) & emp_ci==1
	replace ocupa_ci=4 if OCUPAOP==5 & emp_ci==1
	replace ocupa_ci=5 if OCUPAOP==7 & emp_ci==1
	replace ocupa_ci=6 if OCUPAOP==6 & emp_ci==1
	replace ocupa_ci=7 if OCUPAOP==8 & emp_ci==1
	replace ocupa_ci=8 if OCUPAOP==10 & emp_ci==1
	replace ocupa_ci=9 if OCUPAOP==9 & emp_ci==1

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


	**************
	**pension_ci: Variable dicotómica que indica con valor 1 si la persona recibe una pensión o jubilación contributiva y con 0 al resto. ***
	**************
	gen byte pension_ci=. //No hay pregunta que distinga si la pensión o jubilación es contributiva 
	
	***************
	**pensionsub_ci**
	***************
	gen byte pensionsub_ci = . //No hay pregunta que distinga si la pensión o jubilación es subsidiada o no
	
	***************
	**tipopen_ci: Variable categórica que indica el tipo de pensión contributiva o no contributiva según el país. Puede estar asociado a algún programa del gobierno o al sistema de seguridad social**
	***************
	gen byte tipopen_ci = . // No existe esta pregunta en la encuesta
	
	***************
	**instpen_ci: Variable categórica que indica la institución que otorga la prestación previsional. Es la misma variable original de la base de datos, por lo que difiere en cada país y no está disponible en todos los casos.  **
	***************
	gen byte instpen_ci = . //No existe esta pregunta en la encuesta
	
	
********************************************************************************
***************   VARIABLES DE EDUCACION   *************************************
********************************************************************************

	*********	
	*aedu_ci: Variable numérica que indica el número de años de educación culminados de las personas encuestadas.*
	*********	
	*Este grupo de variables es para quienes "ya no se siguen educando":
	*Variable ED08 - ¿Cuál es su último grado o año aprobado? 
	*Variable ED05 - ¿Cuál es el nivel educativo más alto alcanzado?
	gen aedu_ci=.
	replace aedu_ci=0 if (ED05>=1 & ED05<=3) // Hasta educación pre-básica
	replace aedu_ci=ED08 if ED05==4  & ED08<99 // Educación básica
	replace aedu_ci=9+ED08 if ED05==5 & ED08<99 //9 años de basica - ciclo comun
	replace aedu_ci=9+ED08 if ED05==6 & ED08<99 //9 años de basica - ciclo div
	replace aedu_ci=11+ED08 if (ED05==7 |ED05==8 |ED05==9) & ED08<99 // Terciario 
	replace aedu_ci=15+ED08 if (ED05==10) & ED08<99 //Post

	*Este grupo de variables es para quienes "sí siguen educando	actualmente"
	*Variable ED13 - ¿Cuál es el año o grado que cursa actualmente 2024? 
	*Variable ED10 - ¿Cuál es el nivel educativo en el que estudia actualmente?
	replace aedu_ci=0 if (ED10>=1 & ED10<=3) // Hasta educación pre-básica
	replace aedu_ci=ED13 - 1 if ED10==4 & ED13<99 // Educación básica
	replace aedu_ci=9+ED13 - 1 if ED10==5 //9 años de basica - ciclo comun
	replace aedu_ci=9+ED13 - 1 if ED10==6 //9 años de basica- ciclo div
	replace aedu_ci=11+ED13 - 1 if (ED10==7 | ED10==8 | ED10==9) //Terciario
	replace aedu_ci=15+ED13 - 1 if (ED10==10) & ED13<99 //Post

	label var aedu_ci "Años de educación aprobados"	

	
	
	***********
	*edupre_ci: Variable dicotómica que indica con valor 1 si la persona cursó la educación preescolar completa y con 0 si no lo hizo (lo cual es distinto a si asiste o no a la educación preescolar).*
	***********
	gen byte edupre_ci=.
	replace edupre_ci = 1 if 4<=ED05 & ED05!=. & ED05!=99 // Educación prescolar completa (ya no estudia)
	replace edupre_ci = 1 if 5<=ED10 & ED10!=. & ED10!=99 // Educación prescolar completa (sigue estudiando)
	replace edupre_ci = 0 if edupre_ci!=1
	replace edupre_ci =. if ED05==. & ED10==.
	replace edupre_ci =. if ED05==99 | ED10==99 // 99 = No sabe / No responde	
	
	label var edupre_ci "Educación prescolar completa"
	
	**********
	*eduui_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica o universitaria incompleta y con 0 el resto.*
	**********
	gen byte eduui_ci=(ED07==2 & inrange(ED05,6,8)) // no finalizó estudios
	replace eduui_ci=1 if inrange(ED10,6,8) & eduui_ci==0
	replace eduui_ci=. if aedu_ci==. 
	la var eduui_ci "Universitaria o Terciaria Incompleta"
	label var eduui_ci "Educación superior completa o en curso"

	**********
	*eduuc_ci: Variable dicotómica que indica con valor 1 si el mayor nivel educativo alcanzado corresponde a educación técnica, universitaria completa, o posgrado (completa o incompleta), y con 0 el resto.*
	**********
	gen byte eduuc_ci=(ED07==1 & inrange(ED05,6,8))
	replace eduuc_ci=1 if inrange(ED05,9,11) 
	replace eduuc_ci=1 if inrange(ED10,9,10)  & eduuc_ci==0
	replace eduuc_ci=. if aedu_ci==.
	label var eduuc_ci "Universitaria o Terciaria Completa"
	
	**********
	*eduac_ci: Variable dicotómica que indica con valor 1 si la persona tiene educación superior universitaria o posgrado (completa o incompleta), con 0 si tiene educación superior no universitaria o posgrado (completa o incompleta) y con missing el resto. 
	**********
	gen byte eduac_ci=.
	replace eduac_ci= 1 if eduui_ci+eduuc_ci==1
	replace eduac_ci= 0 if eduui_ci+eduuc_ci==0
	label variable eduac_ci "Superior universitario vs superior no universitario"
	
	***********
	*asiste_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza o institución de educación superior al momento de ser encuestado, con 0 si no asiste y con perdido el resto.*
	***********
	gen	asiste_ci=. 
	replace asiste_ci=1 if ED03==1 //Asiste a centro de enseñanza
	replace asiste_ci=0 if ED03==2 //No Asiste
	label var asiste_ci "Personas que actualmente asisten a centros de enseñanza"
	*  4.7% de missings
	
	***********
	*edupub_ci: Variable dicotómica que indica con valor 1 si la persona asiste a algún centro de enseñanza pública al momento de la encuesta, con 0 si asiste a un centro de enseñanza privada, y con perdido si no asiste o no responde a la pregunta. *
	***********
	gen edupub_ci=.
	replace edupub_ci=1 if inrange(ED14,1,3) & asiste_ci==1
	replace edupub_ci=0 if inrange(ED14,4,9) & asiste_ci==1
	label var edupub_ci "1 = personas que asisten a centros de enseñanza publicos"
	* 74.7% missings
	
	************
	*asispre_ci: Asistencia a preescolar. Variable dicotómica que indica con valor 1 si la persona asiste actualmente a educación preescolar, y con 0 al resto (no tiene valores perdidos).*
	************
	gen byte asispre_ci=(ED10==3) if asiste_ci==1   // Asiste a pre-básica - es dummy solo dentro de la población de referencia
	label var asispre_ci "Asiste a educacion prescolar"	

	*************
	*pqnoasis1_ci: Variable categórica que indica las razones por las cuales un individuo no asiste a la escuela.*
	**************
	/* ED04: Razones para no estudiar
			1	Está de vacaciones
			2	Finalizó sus estudios
			3	No quiere seguir estudiando
			4	Realiza o ayuda en quehaceres del hogar
			5	No hay centro que imparta su nivel/queda lejos
			6	Por problemas familiares
			7	Por problemas de salud
			8	Falta de recursos económicos
			9	Está muy mayor para estudiar
			10	Es muy pequeño todavía
			11	Se casó
			12	Quedó embarazada
			13	Por trabajo
			14	Otra
			99	No sabe/No responde
	*/
	
	gen pqnoasis1_ci = .
	replace pqnoasis1_ci = 1 if inlist(ED04,7,11) // Problemas Económicos - Trabajo
	replace pqnoasis1_ci = 2 if inlist(ED04,3) // Falta de Interés 
	replace pqnoasis1_ci = 3 if inlist(ED04,4,6,10) // Problemas familiares o de salud
	replace pqnoasis1_ci = 4 if inlist(ED04,5) // Problemas de acceso
	replace pqnoasis1_ci = 5 if inlist(ED04,2,8,9,12,13) //Otros problemas
	
	replace pqnoasis1_ci = . if asiste_ci==1 // Consistencia: No se debe contar con razones de no asistencia si la variable de asiste_ci==1. 

	label define pqnoasis1_ci 1 "Problemas económicos/Por trabajo" 2 "Falta de interés/Problemas de rendimiento" 3 "Cuidados/ Problemas familiares o de salud" 4 "Problemas de acceso"  5 "Otros"
	label value  pqnoasis1_ci pqnoasis1_ci


****************************
***VARIABLES DE VIVIENDA***
****************************
		
	************
	***luz_ch: Indica si la principal fuente de iluminación del hogar es electricidad* 
	************
	/* V07: Fuentes de ilumincación:
			1	Servicio Público de electricidad
			2	Servicio privado colectivo de electricidad
			3	Planta propiad de electricidad
			4	Energía solar
			5	Vela
			6	Candil o lámpara de gas
			7	Ocote
			8	Otro
	*/
	
	gen luz_ch=1 if inrange(V07,1,4) 
	replace luz_ch=0 if inrange(V07,5,8)
	label define luz_ch 0 "La principal fuente no es la electricidad" 1 "La principal fuente sí es la electricidad"
	label values luz_ch luz_ch
	* Missing si no responde -   0.77% 
	
	
	***********
	*luzmide_ch: Indica si el hogar usa un medidor para pagar por su consumo *
	***********
	gen luzmide_ch=.	
	
	***********
	*combust_ch: Indica si el combustible principal usado en el hogar para cocinar es gas o electricidad.*
	***********
	/* H04: Principal combustible usado en el hogar pa cocinar
			1	Leña
			2	Gas (Kerosene)
			3	Gas propano (Chimbo)
			4	Electricidad
			5	Otro	
	*/
	
	gen     combust_ch=1 if inlist(H04,2,3,4) // Electricidad o Gas
	replace combust_ch=0 if inlist(H04,1,5) // Leña u Otro 
	* 0.51%  missings

	***********
	*piso_ch: material predominante del piso*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen piso_ch=.	
	
	/*
	gen pared_ch=V03
	
	V03: material predominante en el piso
			1	Ceramica
			2	Ladrillo de cemento
			3	Ladrillo de granito
			4	Ladrillo de barro
			5	Plancha de cemento
			6	Madera
			7	Tierra
			8	Otro	
	*/
	
	***********
	*pared_ch: material predominante de la pared*
	***********
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	gen pared_ch=.	
	
	/*
	gen pared_ch=V02
	
	V02: material predominante en la pared
			1	Ladrillo, piedra o bloque
			2	Adobe
			3	Material prefabricado
			4	Madera aserrada
			5	Madera al natural
			6	Bahareque, vara o caña
			7	Desechos
			8	Otro
	*/
	
	***********
	*techo_ch: material predominante del techo*
	***********
	gen techo_ch=.
	* NOTA: REVISANDO METODOLÓGIA AÚN NO CREAR
	
	/*
	gen techo_ch=V04
	
	V04: Material predominante del techo
			1	Teja de barro/cemento
			2	Asbesto
			3	Lamina de zinc en buen estado
			4	Lamina de zinc en mal estado
			5	Concreto
			6	Madera
			7	Paja, palmar o similar
			8	Material de desecho
			9	Lamina de aluzinc
			10	Shingle
			11	Otro	
	*/
	
	***********
	*resid_ch: : método de eliminación de residuos utilizado por el hogar.*
	***********
	/*
	V08: ¿Como elimina la basura el hogar?
			1	Recolección domiciliaria pública
			2	La deposita en contenedores
			3	Recolección domiciliaria privada
			4	La entierra
			5	La prepara para abono
			6	La quema
			7	La tira en cualquier lugar
			8	Otro
	*/	
	
	gen resid_ch=.
	replace resid_ch=0 if inlist(V08,1,2,3) // Recolección pública o privada
	replace resid_ch=1 if inlist(V08,4,6) // Quemados o enterrados
	replace resid_ch=2 if inlist(V08,7) // Tirados a un espacio abierto
	replace resid_ch=3 if inlist(V08,5,8) // Otros (prepara abono y otros)
	
	label define resid_ch 		0 "Recoleccion publica o privada" ///
								1 "Quemados o enterrados" ///
								2 "Tirados en un espacio abierto" ///
								3 "Otros"
	
	label value resid_ch resid_ch
	* 0.77% missings
	
	***********
	*dorm_ch: cantidad de habitación que se destinan exclusivamente para dormir*
	***********
	gen dorm_ch=H09 if 0<=H09 // Variable que menciona cuantas piezas se usan para dormir*
	replace dorm_ch=0  if dorm_ch==. // 2 observaciones con missings
	* Se restrige la variable para los valores positivos de H09 dado que la variable tiene valores de -1
	
	***********
	*cuartos_ch: cantidad de habitaciones en el hogar*
	***********
	gen cuartos_ch=. // En la encuesta esta la pregunta v09 : Sin incluir baños y cocina, ¿cuántas piezas tiene esta vivienda? y la variable no incluye baños y cocina. Pero no podemos asumir el # de cocinas y baños.
	* Según el manual no se puede crear la variable
	
	***********
	*cocina_ch: existe un cuarto separado y exclusivo para cocinar*
	***********
	/* H02: En qué pieza ó sitio de la vivienda cocina los alimentos este hogar:
			1	En una pieza dedicada solo para cocinar
			2	En una pieza utilizada también para dormir
			3	En la sala, comedor
			4	En el patio, corredor u otro sitio
			5	No cocina
	*/
	gen cocina_ch=.
	replace cocina_ch=1 if H02==1 // Tienen un cuarto solo para cocinar 
	replace cocina_ch=0 if inrange(H02,2,5) //Cocinan en un cuarto compartido o no cocinan
 	
	***********
	*telef_ch: el hogar tiene servicio telefónico fijo ***
	***********
	gen telef_ch2=(H01_7>=1 & H01_7!=.) //Tiene telefonos fijos y respondió la pregunta
	replace telef_ch2=. if H01_7==.
	
	***********
	*refrig_ch: si el hogar posee heladera o refrigerador*
	***********
	gen refrig_ch=(H01_1>=1 & H01_1!=.) // Tiene al menos una refrigeradora y respondió la pregunta
	replace refrig_ch=. if H01_1==.

	***********
	*freez_ch: si el hogar posee freezer o congelador*
	***********
	gen freez_ch=. // No hay una variable con esta pregunta
	
	***********
	*auto_ch: si el hogar posee (tiene propiedad) al menos un automóvil particular*
	***********
	gen auto_ch=(H01_8>=1 & H01_8!=.) // Tiene al menos un automóvil y respondió la pregunta
	replace auto_ch=. if H01_8==. // Missing si no responden
	
	***********
	*compu_ch: si el hogar posee computadora*
	***********
	gen compu_ch=(H01_11>=1 & H01_11!=.) // Tiene al menos una computadora y respondió la pregunta
	replace compu_ch=. if H01_11==. // Missing si no responden

	***********
	*internet_ch: si el hogar posee conexión a internet*
	***********
	
	/*TIC03: Durante los últimos 3 meses, ¿tuvo acceso a internet?	
			1	Si
			2	No
			3	No sabe / no responde

	  AT05: ¿En qué sitios tuvo acceso a Internet? 
			1	En su casa
			2	En un cyber-café o negocio de Internet
			3	En su trabajo
			4	En la escuela, colegio o universidad
			5	Casa de un familiar / amigo/ casa de otra persona
			6	Hotel, restaurante o negocio con Red Inalámbrica
			7	Red pública (Parques u otro lugar Comunitario)
			8	Otro sitio
	*/
	
	gen internet_ch=(TIC03==1 & AT05_1==1) // Tuvo acceso durante los últimos 3 meses a internet (TIC03)-- en su casa  (AT05_1)
 	replace internet_ch=. if (TIC03==. | TIC03==3) & AT05_1==.
	
	***********
	*cel_ch: si al menos un integrante del hogar tiene servicio telefónico celular activa*
	***********
	gen cel_ch=(TIC09==1)
	replace cel_ch=. if TIC09==.

	**************
	***vivi1_ch: Tipo de vivienda en la que reside el hogar***
	**************
	
	/*V01: Tipo de vivienda:
			1	Casa individual
			2	Casa de material natural (rancho)
			3	Casa improvisada
			4	Apartamento
			5	Cuarto en meson o cuarteria
			6	Barracon
			7	Local no construido para habitacion pero usado como vivienda
	*/	
	
	gen vivi1_ch=.
	replace vivi1_ch=1 if inlist(V01,1,2,3) // Casa individual, rancho o improvisada
	replace vivi1_ch=2 if inlist(V01,4) // Apartamento / Departamento
	replace vivi1_ch=3 if inlist(V01,5,6,7) // Otros
	
	label define vivi1_ch 		1 "Casa" ///
								2 "Departamento" ///
								3 "Otros tipos"
	
	label value vivi1_ch vivi1_ch
	
	**************
	***vivi2_ch: vivienda en la que reside el hogar es una casa o un departamento***
	**************
	*Se construye a partir de vivi1_ch creada antes de esta variable.	
	
	gen vivi2_ch=1 if inlist(vivi1_ch,1,2) // Casa o Departamento 
	replace vivi2_ch=0 if vivi1_ch==3 // Otros

	***********
	*viviprop_ch: Propiedad de la vivienda en la que reside el hogar*
	***********
	/*V10: Proviedad de la vivienda en la que reside 
			1	Alquilada?
			2	Propietario y la está pagando?
			3	Propietario y completamente pagada?
			4	Invasión (propia recuperada legalizada)?
			5	Invasion (propia recuperada sin legalizar)?
			6	Prestada (cedida sin pago)?
			7	Recibida por servicios de trabajo?
	*/	
	
	gen viviprop_ch=.
	replace viviprop_ch=0 if V10==1 // Alquilada
	replace viviprop_ch=1 if V10==3 // Propia y totalmente pagada
	replace viviprop_ch=2 if V10==2 // Propia y pagandola
	replace viviprop_ch=3 if inlist(V10,4,5,6,7) // Ocupada
	replace viviprop_ch=. if V10==.
	
	label define viviprop_ch 		0 "Alquilada" ///
									1 "Propia y totalmente pagada" ///
									2 "Propia y en proceso de pago" ///
									3 "Ocupada (propia de facto)"
	
	label value viviprop_ch viviprop_ch
	
	***********
	*vivitit_ch: si el hogar posee un título de propiedad*
	***********
	gen vivitit_ch=. // No hay pregunta al respecto 
	
	***********
	*vivialq_ch: Monto mensual pagado por el alquiler de la vivienda*
	***********
	gen vivialq_ch=. // No hay pregunta al respecto 
	
	***********
	*vivialqimp_ch: Monto mensual del valor que el informante cree que le pagarían por su vivienda propia que ocupa*
	***********
	gen vivialqimp_ch=V11 // Misma variable que en la encuesta 
	replace vivialqimp_ch=. if V11==99999 // 99999 es la codificación para missings
	
	*No se cumple la regla de consistencia. Aparentemente, a todas las personas cuya vivienda es alquilada se le puso missing en esta sección. 

	
********************************************************************************
***************   VARIABLES DE WASH        *************************************
********************************************************************************

	***********
	*aguared_ch: Si la vivienda tiene acceso a agua mediante una red*
	***********
	/* V05: Fuentes de acceso al agua
			1	Servicio público por tubería
			2	Servicio privado por tubería
			3	Pozo con bomba
			4	Pozo malacate
			5	Llave publica o comunitaria
			6	Rio, riachuelo, manantial, ojo de agua
			7	Carro cisterna/SANAA/Alcaldia
			8	Vendedor ambulante/Pick-up con drones o barriles
			9	Del vecino / otra vivienda
			99	Otro
	*/
	
	generate  aguared_ch =.
	replace   aguared_ch = 1 if inlist(V05,1)  // agua por red pública
	replace   aguared_ch = 0 if inrange(V05,2,9) // agua por red privada o del vecino
	la var    aguared_ch "Acceso a fuente de agua por red"

	***********
	*aguafconsumo _ch: : Principal fuente de agua utilizada por el hogar para beber*
	***********
	gen aguafconsumo_ch = 0 // La encuesta no pregunta sobre agua para beber: No existe pregunta para conocer la fuente de agua de consumo.  

	***********
	*aguafuente_ch: Principal fuente de agua utilizada por el hogar para todos los usos*
	***********	
	/* V05: Fuentes de acceso al agua
			1	Servicio público por tubería
			2	Servicio privado por tubería
			3	Pozo con bomba
			4	Pozo malacate
			5	Llave publica o comunitaria
			6	Rio, riachuelo, manantial, ojo de agua
			7	Carro cisterna/SANAA/Alcaldia
			8	Vendedor ambulante/Pick-up con drones o barriles
			9	Del vecino / otra vivienda
			99	Otro
	*/
	
	/* V06: ¿Dónde obtiene el agua?
			1	Dentro de la vivienda
			2	Fuera de la vivienda y dentro de la propiedad
			3	Fuera de la propiedad a menos de 100 metros
			4	Fuera de la propiedad a más de 100 metros	
	*/
	
    gen aguafuente_ch =.
	replace aguafuente_ch = 1 if inlist(V05,1) & V06<=2
	replace aguafuente_ch = 2 if inlist(V05,4)  | (inlist(V05,1)  &V06>2) 
	replace aguafuente_ch = 6 if inlist(V05,6) 
	replace aguafuente_ch = 7 if inlist(V05,7)
	replace aguafuente_ch = 8 if inlist(V05,5)
	replace aguafuente_ch = 10 if inlist(V05,2,3,8,9) 

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
	
	******************
	** aguadist_ch: Ubicación de la principal fuente de agua*  
	*****************	
	/* V06: ¿Dónde obtiene el agua?
			1	Dentro de la vivienda
			2	Fuera de la vivienda y dentro de la propiedad
			3	Fuera de la propiedad a menos de 100 metros
			4	Fuera de la propiedad a más de 100 metros	
	*/
	
	gen aguadist_ch=.
	replace aguadist_ch= 1 if V06==1 // Adentro de la vivienda
	replace aguadist_ch= 2 if V06==2 //Fuera de la vivienda, pero adentro de la propiedad
	replace aguadist_ch= 3 if V06==3 & V06==4 //Fuera de la propiedad
	
	label define aguadist_ch 		1 "Adentro de la vivienda" ///
									2 "Afuera de la vivienda, pero adentro del terreno" ///
									3 "Afuera de la vivienda y afuera del terreno"
	
	label value aguadist_ch aguadist_ch
	
	******************
	** aguadisp1_ch: si el hogar tiene continuidad de disponibilidad de agua* 
	*****************
	gen aguadisp1_ch = 9 //No existe la pregunta. Ver Manual
	
	**************
	*aguadisp2_ch: continuidad de disponibilidad de agua*
	**************
	gen aguadisp2_ch = 9 //No existe la pregunta. Ver Manual
	
	*************
	*aguatrat_ch: si el hogar trata el agua de su fuente antes de consumirla*
	*************
	gen aguatrat_ch =. //No existe la pregunta. Ver Manual
	
	******************
	** aguamala_ch: si la principal fuente de agua es "Unimproved" según JMP ** 
	*****************
	gen byte aguamala_ch = 2
	replace aguamala_ch = 0 if aguafuente_ch<=7
	replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10 & aguafuente_ch!=.

	******************
	** aguamejorada_ch: acceso a agua potable de fuente mejorada ** 
	*****************
	gen byte aguamejorada_ch = 2
	replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
	replace aguamejorada_ch = 1 if aguafuente_ch<=7
	
	******************
	** aguamide_ch: si el hogar usa un medidor para pagar por su consumo de agua * 
	*****************
	gen aguamide_ch =. // No existe la pregunta
	label var aguamide_ch "Usan medidor para pagar consumo de agua"
	
	******************
	** bano_ch: Tipo de instalación sanitaria que tiene el hogar **
	*****************
	
	/*H06: ¿Tiene algún tipo de servicio sanitario letrina?
			1 	Si
			2	No
	*/
	
	/* H07: Tipo de acceso a saneamiento
			1	Inodoro conectado a alcantarilla
			2	Inodoro conectado a pozo séptico
			3	Inodoro con desagüe a río, laguna, mar
			4	Letrina con descarga a río, laguna, mar
			5	Taza campesina/letrina con cierre hidráulico
			6	Letrina con pozo séptico
			7	Letrina con pozo negro
			8	Otro tipo
			9	No tiene
	*/
	
	gen bano_ch=.
	replace bano_ch=0 if inlist(H06,2) //No tiene acceso a servicios sanitarios
 	replace bano_ch=1 if inlist(H07,1) //Inodoro conectado a alcantarilla
	replace bano_ch=2 if inlist(H07,2) //Inodoro a pozo séptico
	replace bano_ch=3 if inlist(H07,5) // Letrina
	replace bano_ch=4 if inlist(H07,3) // Inodoro con desague a río/laguna/mar
	replace bano_ch=5 if inlist(H07,4,6,7) // Instalaciones no mejoradas
	replace bano_ch=6 if inlist(H07,8) // Instalaciones no clasificada

	label define bano_ch 			0 "Sin instalaciones" ///
									1 "Inodoro a red de desagüe" ///
									2 "Inodoro a fosa séptica" ///
									3 "Letrina mejorada / otra instalación mejorada" ///
									4 "Inodoro/letrina a cuerpo de agua superficial o suelo" ///
									5 "Instalación no mejorada" ///
									6 "Instalación que no se puede clasificar"
	
	label value bano_ch bano_ch
	
	******************
	** banoex_ch: Instalaciones del hogar son de uso exclusivo ** 
	*****************
	gen banoex_ch=.
	replace banoex_ch = 1 if H08==1
	replace banoex_ch = 0 if H08==2
	la var banoex_ch "El servicio sanitario es exclusivo del hogar"

	******************
	** sinbano_ch: que hace los hogares sin acceso a instalaciones propias*
	*****************
	/*
	H06: ¿Tiene algún tipo de servicio sanitario letrina?
			1 	Si
			2	No
			
	H08: ¿El uso del servicio sanitario es:
			1	Exclusivo del hogar?
			2	Compartido con otros hogares?	
	*/
	
	gen sinbano_ch = .
	replace sinbano_ch = 0 if H06==1 & H08==1 //Tiene instalaciones propias
	replace sinbano_ch = 1 if H06==2 & H08==2 //Tiene instalaciones compartidas
	replace sinbano_ch = 3 if H06==2 & (H07==. | H08==.) // El hogar no tiene baño pero no especifica cuáles alternativas se usa
	
		label define sinbano_ch 	0 "El hogar tiene baño propio" ///
									1 "El hogar no tiene baño y usa instalaciones públicas/compartidas" ///
									2 "No tiene baño y practica defecación al aire libre" ///
									3 "El hogar no tiene baño pero no especifica cuáles alternativas usa"
	label value bano_ch sinbano_ch
		
	******************
    ** banomejorado_ch: el hogar tiene acceso a saneamiento de fuente mejorado* 
    *****************
	gen byte banomejorado_ch= 2
	replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
	replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

********************************************************************************
***************   VARIABLES DE MIGRACION   *************************************
********************************************************************************	

	*******************
	*** migrante_ci: Si el individuo nació en otro país  ***
	*******************
	gen migrante_ci=.
	label var migrante_ci "=1 si es migrante"

	***********************
	*** migrantiguo5_ci: si el migrante ha estado viviendo 5 años o más en el país de la encuesta***
	**********************
	gen migrantiguo5_ci=.
	label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"

	*****************
	*** miglac_ci: si el individuo es migrante latino o del caribe***
	*****************
	gen miglac_ci=.
	label var miglac_ci "=1 si es migrante proveniente de un pais LAC"

	

****************************
***VARIABLES DE EXTERNAS***
****************************	
	
	****************
	 *tipo_bienestar: como mide la probreza la encuesta, mediante el ingreso o el consumo*
	****************
	/*
		1 Ingreso
		2 Consumo
	*/	
	gen byte tipo_bienestar = . 
	replace tipo_bienestar  = 1 //Ingreso
	
	****************
	 * pobre_ine_ci:  como se identifica pobreza -- pero es para el jefe de hogar*
	****************	
	/*
	Se identifica mediante la variable POBREZA que tiene las siguientes categorias:
			1	Extrema
			2	Relativa
			3	No pobres
	*/
		
	gen byte pobre_ine_ci= . 
	replace pobre_ine_ci= 1 if POBREZA==1 | POBREZA==2 //Pobres extremos y relativos
	replace pobre_ine_ci= 0 if POBREZA==3 //No pobres

	****************
	 * bienestar_agregado: Variable continua que indica los valores de bienestar que ocupa la encuesta en ingreso o consumo totales por individuo, usualmente esta variable contendrá valores imputados o limpiados por el instituto estadístico de cada país.*
	****************	
	*YPERHG: Ingreso percapita de los hogares
	* El valor del Ingreso percapita YPERHG, "solo se asigna al jefe del hogar" - el resto es missing *
	* Al parecer se calcula la pobreza por hogar - no por individuos*
	gen bienestar_agregado = YPERHG

	****************
	* lpe_ci: Linea de pobreza extrema*
	****************	
	*En Honduras la linea de pobreza extrema se identifica como el costo de la canasta básica de alimentos. A junio del 2024 es de 2,457.16 lempiras para zonas urbanas y  1,895.23 lempiras para zonas rurales
	
	gen lpe_ci =.
	replace lpe_ci = 2457.16 if zona_c==1 //Zona urbana -cuadro excel de pobreza - INE
	replace lpe_ci = 1895.23 if zona_c==0 //Zona rural	-cuadro excel de pobreza - INE
	
	****************
	 * ln_ci: linea de pobreza*
	****************
	*En Honduras la linea de pobreza se identifica como el costo de la canasta básica de productos. A junio del 2024 es de 5,131.84 lempiras para zonas urbanas y 2,604.48 lempiras para zonas rurales
	
	gen ln_ci = . 
	replace ln_ci = 5131.84 if zona_c==1 //Zona urbana
	replace ln_ci = 2604.48 if zona_c==0 //Zona rural	
	
********************************************************************************
/* ¿Cómo replicamos el indicador de pobreza ?

preserve
keep if jefe_ci==1

* Pobreza
gen p = (bienestar_agregado<=ln_ci)
tab p POBREZA


           |         Nivel de pobreza
         p |   Extrema   Relativa  No pobres |     Total
-----------+---------------------------------+----------
         0 |         0          0      2,325 |     2,325 
         1 |     2,646      1,285          0 |     3,931 
-----------+---------------------------------+----------
     Total |     2,646      1,285      2,325 |     6,256 




* Pobreza extrema
gen p_ext = (bienestar_agregado<=lpe_ci)
tab p_ext POBREZA

           |         Nivel de pobreza
     p_ext |   Extrema   Relativa  No pobres |     Total
-----------+---------------------------------+----------
         0 |        87      1,285      2,325 |     3,697 
         1 |     2,559          0          0 |     2,559 
-----------+---------------------------------+----------
     Total |     2,646      1,285      2,325 |     6,256 
* Hay 87 observaciones que no puedo identificar de pobreza extrema / solo 87*




restore
*/	

	
********************************************************************************
********************************************************************************	
	
	
	
	
	
local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
saveold "`base_out'", version(12) replace

cap log close
