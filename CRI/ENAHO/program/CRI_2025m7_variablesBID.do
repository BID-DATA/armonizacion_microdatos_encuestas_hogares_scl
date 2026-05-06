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

local PAIS CRI
local ENCUESTA ENAHO
local ANO "2025"
local ronda m7 

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_variablesBID.log"
*local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\\`PAIS'_`ANO'`ronda'.dta"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"

capture log close 
log using "log_file", replace


/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Costa Rica
Encuesta: ENAHO
Ronda: m7
Creación: 21 de enero 2026
Última versión: 21 de enero 2026
Fecha última modificación: 21 de enero 2026
SCL/SCL - IADB
****************************************************************************/

use `base_in', clear

rename *, lower

	*********************
	* I. identificación *
	*********************

**********
* anio_c *
**********
gen anio_c=2025
label variable anio_c "Anio de la encuesta"

*********
* mes_c *
*********
gen mes_c=7
label variable mes_c "Mes de la encuesta"
label define mes_c 7 "Julio" 
label value mes_c mes_c

**********
* pais_c *
**********
gen str3 pais_c="CRI"
label variable pais_c "Pais"

****************
* region_BID_c *
****************
gen region_BID_c=.
replace region_BID_c=1 
label var region_BID_c "Regiones BID"
label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)"
label value region_BID_c region_BID_c

************
* region_c *
************
*la región Huetar Atlántica y Huetar Caribe es la misma. La llamen de ambas maneras en documentos del gobierno  https://www.mag.go.cr/regiones/huetar_caribe.html. Se conserva Huetar Atlántica aunque en la base figura como Huetar Caribe para ser consistentes con las armonizaciones de años anteriores.
gen region_c=region
label define region_c  ///
	       1 "Central" ///
           2 "Chorotega" ///
           3 "Pacífico central" ///
           4 "Brunca" ///
           5 "Huetar Atlántica" ///
           6 "Huetar Norte"
label value region_c region_c
label var region_c "División política, region de planificacion"

**********
* zona_c *
**********
gen zona_c=0 if zona==2
replace zona_c=1 if zona==1
label variable zona_c "Zona del pais"
label define zona_c 1 "Urbana" 0 "Rural"
label value zona_c zona_c

**************
* estrato_ci *
**************
gen estrato_ci =.
label variable estrato_ci "estrato"

*******
* upm *
*******
gen upm =.
label variable upm "unidad primaria de muestreo"

**********
* idh_ch *
**********
* en 2023 no está la variable upm ni cuestionario disponibles
sort nro_vivienda hogar
egen idh_ch = concat(nro_vivienda hogar)
label var idh_ch "ID del hogar"
tostring idh_ch, replace


**********
* idp_ci *
**********
sort nro_vivienda hogar linea
egen idp_ci = concat(nro_vivienda hogar linea) 
label var idp_ci "ID de la persona en el hogar"
tostring idp_ci, replace


duplicates report idh_ch idp_ci
*br idp_ci nro_vivienda hogar linea

*************
* factor_ch *
*************
gen factor_ch=factor
label var factor_ch "Factor de expansion del hogar"

*************
* factor_ci *
*************
gen factor_ci=factor
label variable factor_ci "Factor de expansion del individuo"

	*********************
	* II. demográficas  *
	*********************

***********
* sexo_ci *
***********
gen sexo_ci=a4
label define sexo_ci 1 "Hombre" 2 "Mujer"
label value sexo_ci sexo_ci

***********
* edad_ci *
***********
*variable censurada en la última categoría (97 o más)
gen edad_ci=a5
label variable edad_ci "Edad del individuo"

***************
* relacion_ci *
***************
gen relacion_ci=1 		if a3==1
replace relacion_ci=2 	if a3==2
replace relacion_ci=3 	if a3==3 | a3==4
replace relacion_ci=4 	if a3>=5 & a3<=11
replace relacion_ci=5 	if a3==12 | a3==14
replace relacion_ci=6 	if a3==13
label variable relacion_ci "Relacion con el jefe del hogar"
label define relacion_ci 1 "Jefe/a" 2 "Esposo/a" 3 "Hijo/a" 4 "Otros parientes" 5 "Otros no parientes" 6 "Empleado/a domestico/a"
label value relacion_ci relacion_ci
tab a3
tab relacion_ci

************
* civil_ci *
************
/*
a6:
           0 menor de 10 años
           1 en unión libre o juntado(a)
           2 casado(a)
           3 divorciado(a)
           4 separado(a)
           5 viudo(a)
           6 soltero(a)
           9 ignorado

*/

gen civil_ci=.
replace civil_ci=1 if a6==6
replace civil_ci=2 if a6==1 | a6==2
replace civil_ci=3 if a6==3 | a6==4
replace civil_ci=4 if a6==5
label variable civil_ci "Estado civil"
label define civil_ci 1 "Soltero" 2 "Union formal o informal"
label define civil_ci 3 "Divorciado o separado" 4 "Viudo" , add
label value civil_ci civil_ci

***********
* jefe_ci *
***********
gen jefe_ci=(relacion_ci==1)
label variable jefe_ci "Jefe de hogar"

****************
* nconyuges_ch *
****************
egen nconyuges_ch=sum(relacion_ci==2), by(idh_ch)
label variable nconyuges_ch "Numero de conyuges"

*************
* nhijos_ch *
*************
egen nhijos_ch=sum(relacion_ci==3), by(idh_ch)
label variable nhijos_ch "Numero de hijos"

****************
* notropari_ch *
****************
egen notropari_ch=sum(relacion_ci==4), by(idh_ch)
label variable notropari_ch "Numero de otros familiares"

******************
* notronopari_ch *
******************
egen notronopari_ch=sum(relacion_ci==5), by(idh_ch)
label variable notronopari_ch "Numero de no familiares"

**************
* nempdom_ch *
**************
egen nempdom_ch=sum(relacion_ci==6), by(idh_ch)
label variable nempdom_ch "Numero de empleados domesticos"

***************
* clasehog_ch *
***************
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

****************
* nmiembros_ch *
****************
egen nmiembros_ch=sum(relacion_ci>=1 & relacion_ci<=4), by(idh_ch)
label variable nmiembros_ch "Numero de familiares en el hogar"

***************
* miembros_ci *
***************
gen miembros_ci=(relacion_ci>=1 & relacion_ci<=5)
label variable miembros_ci "Miembro del hogar"

***************
* nmayor21_ch *
***************
by idh_ch, sort: egen byte nmayor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=21 & edad_ci<=98))
label variable nmayor21_ch "Numero de familiares mayores a 21 anios"

***************
* nmenor21_ch *
***************
by idh_ch, sort: egen byte nmenor21_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<21))
label variable nmenor21_ch "Numero de familiares menores a 21 anios"

***************
* nmayor65_ch *
***************
by idh_ch, sort: egen byte nmayor65_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci>=65 & edad_ci!=.))
label variable nmayor65_ch "Numero de familiares mayores a 65 anios"

**************
* nmenor6_ch *
**************
by idh_ch, sort: egen byte nmenor6_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<6))
label variable nmenor6_ch "Numero de familiares menores a 6 anios"

**************
* nmenor1_ch *
**************
by idh_ch, sort: egen byte nmenor1_ch=sum((relacion_ci>0 & relacion_ci<=5) & (edad_ci<1))
label variable nmenor1_ch "Numero de familiares menores a 1 anio"

	*******************
	* III. diversidad *
	*******************

************
* afro_ci  *
************
gen afro_ci=. 

***********
* ind_ci  *
***********
gen ind_ci=. 

*****************
* noafroind_ci  *
*****************
gen noafroind_ci=. 

***************
***afroind_ci***
***************
gen afroind_ci=. 

************
* afro_ch  *
************
gen afro_ch=. 

***********
* ind_ch  *
***********
gen ind_ch=. 

*****************
* noafroind_ch  *
*****************
gen noafroind_ch=. 

***************
* afroind_ch  *
***************
gen afroind_ch=. 

*****************
* afroind_ano_c * 
*****************
gen afroind_ano_c=.		

**********
* dis_ci *
**********
/* ¿(Nombre) presenta alguna limitación que le dificulte o impida permanentemente...
a8a	
           0 No tiene ninguna
           1 Ver aún con los anteojos o lentes puestos
           2 Oír
           3 Hablar
           4 Caminar o subir gradas
           5 Utilizar brazos y manos
           6 De tipo intelectual (Síndrome de Down, otros)
           7 De tipo mental (bipolar, esquizofrenia, otros)
           9 Ignorado
a8b
           0 No tiene segunda discapacidad
           1 Ver aún con los anteojos o lentes puestos
           2 Oír
           3 Hablar
           4 Caminar o subir gradas
           5 Utilizar brazos y manos
           6 De tipo intelectual (Síndrome de Down, otros)
           7 De tipo mental (bipolar, esquizofrenia, otros)
           9 Ignorado

*/	   
	* No considerar respuestas 6 y 7
gen dis_ci =.
replace dis_ci = 1 if (a8a >= 1 & a8a <= 5) | (a8b >= 1 & a8b <= 5)
replace dis_ci = 0 if (a8a == 0 | a8a == 6 | a8a == 7)

************
* disWG_ci *
************
gen disWG_ci =.

************
* CRI_dis_ci *
************
gen CRI_dis_ci =dis_ci

**********
* dis_ch *
**********		
egen dis_ch  = sum(dis_ci), by(idh_ch) 
replace dis_ch=1 if dis_ch>=1 & dis_ch!=. 

	*****************
	* IV. laborales *
	*****************

***************
* condocup_ci *
***************
gen condocup_ci=.
replace condocup_ci=1 if b1==1 | (b2 >= 1 & b2 <= 8) | b3==1 | (b5 >= 1 & b5 <= 5) & estabili != 30 /*ocupado frecuente*/
replace condocup_ci=1 if b1==1 | (b2 >= 1 & b2 <= 8) | b3==1 | (b5 >= 1 & b5 <= 5) & estabili == 30 /*ocupado estacional*/
replace condocup_ci=2 if (b6== 8 | b6== 9) & ((b7a== 1 | b7b== 2 | b7c== 3 | b7d== 4 | b7e== 5 | b7f==6 | b7g == 7 | b7h ==8 | b7i ==9 | b7j == 10 | b7k== 11) | (b8==1 | b8==2 | b8==3)) & g6==1 /*desempleado cesante*/
replace condocup_ci=2 if (b6== 8 | b6==9 ) & ((b7a== 1 | b7b== 2 | b7c== 3 | b7d== 4 | b7e== 5 | b7f== 6 | b7g== 7 | b7h ==8 | b7i ==9 | b7j== 10 | b7k== 11) | (b8==1 | b8==2 | b8==3)) & g6==2 /*desempleado primera vez*/
recode condocup_ci .=3 if  edad_ci>=12 /*Modificado de 10 a 12 aÃ±os SGR 05/2017*/
replace condocup_ci=4 if  edad_ci<12
label var condocup_ci "Condicion de ocupación de acuerdo a def de cada pais"
label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "Menor que 12" 
label value condocup_ci condocup_ci

*******************
***categoinac_ci***
*******************
/*
raznoacteco:
           1 pensionado o jubilado
           2 rentista
           3 asistencia a centro de estudios
           4 obligaciones del propio hogar
           5 con discapacidad o enfermedad
           6 otro motivo
*/
gen categoinac_ci = .
replace categoinac_ci = 1 if (raznoacteco == 1 & condocup_ci==3)
replace categoinac_ci = 2 if (raznoacteco == 3 & condocup_ci==3)
replace categoinac_ci = 3 if (raznoacteco == 4 & condocup_ci==3)
replace categoinac_ci = 4 if  ((categoinac_ci ~=1 & categoinac_ci ~=2 & categoinac_ci ~=3) & condocup_ci==3)
label var categoinac_ci "Categoría de inactividad"
label define categoinac_ci 1 "jubilados o pensionados" 2 "Estudiantes" 3 "Quehaceres domésticos" 4 "Otros"

************
***emp_ci***
************
gen byte emp_ci=(condocup_ci==1)
label var emp_ci "Ocupado (empleado)"

***************
* nempleos_ci *
***************
gen nempleos_ci=.
replace nempleos_ci=1 if emp_ci==1 & c1==1
replace nempleos_ci=2 if emp_ci==1 & c1==2
replace nempleos_ci=. if emp_ci==0
label var nempleos_ci "Número de empleos" 

*****************
* antiguedad_ci *
*****************
* Independientes
g aux0=d4a
g aux1=d4b*30 if d4b!=99
g aux2=d4c*365 if d4c!=99
egen ind=rsum(aux0 aux1 aux2), m
replace ind=ind/365
* Asalariados
g aux3=e3a
g aux4=e3b*30 if e3b!=99
g aux5=e3c*365 if e3c!=99
egen asal=rsum(aux3 aux4 aux5), m
replace asal=asal/365
* antiguedad
egen antiguedad_ci=rsum(ind asal), m
replace antiguedad_ci=. if antiguedad_ci>edad_ci
label var antiguedad_ci "Antiguedad en la actividad actual en anios"

****************
***desemp_ci***
****************
gen desemp_ci=(condocup_ci==2)
label var desemp_ci "Desempleado que buscó empleo en el periodo de referencia"
  
*************
*cesante_ci* 
*************
* MGD 12/4/2015: condicionado a que este desocupado
gen cesante_ci=1 if g6==1 & condocup_ci==2
recode cesante_ci .=0 if condocup_ci==2
* No todos los desempleados respondieron si han trabajado antes
label var cesante_ci "Desocupado - definicion oficial del pais"

************
*durades_ci* 
************
/*
           1 un mes o menos
           2 más de un mes a tres meses
           3 más de tres meses a seis meses
           4 más de seis meses a un año
           5 más de un año a tres años
           6 más de tres años
           9 ignorado
Obs. Unidad de medida: promedio de meses (por eso se divide entre 2)
*/
gen durades_ci=.
*un mes o menos
replace durades_ci=(1+4.3)/2/4.3 if g2==1
*MÁS de 1 a 3 meses
replace durades_ci=(1+3)/2 if g2==2
*MÁS de 3 a 6 meses
replace durades_ci=(3+6)/2 if g2==3
*MÁS de 6 a 12 meses
replace durades_ci=(6+12)/2 if g2==4
*MÁS de 1 año a 3 años
replace durades_ci=(12+36)/2 if g2==5
*MÁS de 3 años
replace durades_ci=(36+48)/2 if g2==6
label variable durades_ci "Duracion del desempleo en meses"
 
**********
* pea_ci *
**********
gen pea_ci=0
replace pea_ci=1 if emp_ci==1 |desemp_ci==1
label var pea_ci "Población Económicamente Activa"

***************
* desalent_ci *
***************
*personas que creen que por alguna razon no conseguiran trabajo
gen desalent_ci=(emp_ci==0 & (b8==5 | b8==6 |b8==7 |b8==8))
replace desalent_ci=. if condact==.
label var desalent_ci "Trabajadores desalentados"

***************
* horaspri_ci *
***************
*Horas totales trabajadas en la actividad principal
*c2a1=horas normales empleo principal por semana
gen horaspri_ci=c2a1 
replace horaspri_ci=. if c2a1==999
replace horaspri_ci=. if emp_ci==0
label var horaspri_ci "Horas trabajadas semanalmente en el trabajo principal"

***************
* horastot_ci *
***************
* Horas totales trabajadas en la actividad secundaria
* c2b1 = horas normales empleo secundario por semana
gen horassec_ci=c2b1 
replace horassec_ci=. if c2b1==999
replace horassec_ci=. if emp_ci==0
label var horassec_ci "Horas trabajadas semanalmente en el trabajo secundario"
* Horas totales trabajadas en todas las actividades
egen horastot_ci=rsum(horaspri_ci horassec_ci), missing 
replace horastot_ci=. if horaspri_ci==. & horassec_ci==.
replace horastot_ci=. if emp_ci==0
label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"

*************
* subemp_ci *
*************
* Modificacion MLO 12/18/2015: mal generada la variable, se corrije con las variables desea trabajar mas horas y disponibilidad.
*c3 = hubiera querido trabajar más horas
gen subemp_ci=0
replace subemp_ci=1 if (horaspri_ci<=30 & c3==1 & (c4a==1 | c4a==2)) & emp_ci==1
replace subemp_ci=. if emp_ci==0
label var subemp_ci "Personas en subempleo por horas"

*****************
* tiempoparc_ci *
*****************
*Trabajadores a medio tiempo: personas que trabajan menos de 30 horas a la semana y no quieren trabajar mas.
gen tiempoparc_ci=(horastot_ci<=30 & c3==2)
replace tiempoparc_ci=. if emp_ci==0
label var tiempoparc_c "Personas que trabajan medio tiempo" 

****************
* categopri_ci *
****************
* Categoria ocupacional en la actividad principal
gen categopri_ci=.
replace categopri_ci=1 if c12==1 & (d1==1 | d1==2)
replace categopri_ci=2 if c12==1 & d1==3
replace categopri_ci=3 if c12==2 | c12==3 | (c12==5 & c13a==1)
replace categopri_ci=4 if (c12==4 | c12==5) & c13a==2
replace categopri_ci=. if emp_ci==0
label define categopri_ci 1 "Patron" 2"Cuenta propia" 
label define categopri_ci 3 "Empleado" 4" No remunerado" , add
label value categopri_ci categopri_ci
label variable categopri_ci "Categoria ocupacional"

****************
* categosec_ci *
****************
* Categoria ocupacional en la actividad secundaria.
gen categosec_ci=.
replace categosec_ci=1 if f7==1
replace categosec_ci=2 if f7==2
replace categosec_ci=3 if f7==3 | f7==4
replace categosec_ci=4 if f7==5
replace categosec_ci=. if emp_ci==0
label define categosec_ci 1"Patron" 2"Cuenta propia" 
label define categosec_ci 3"Empleado" 4"No remunerado" , add
label value categosec_ci categosec_ci
label variable categosec_ci "Categoria ocupacional trabajo secundario"


***********
* rama_ci *
***********
*Rama laboral actividad principal. En base a grandes Divisiones (ISIC Rev. 2)***
* MGR Aug, 2015: no es necesario condicionar por ocupados ya que los que contestan esta pregunta son ocupados
gen rama_ci=.
replace rama_ci=1 if ramaemppri==1
replace rama_ci=2 if ramaemppri==2
replace rama_ci=3 if ramaemppri==3
replace rama_ci=4 if ramaemppri==4 | ramaemppri==5
replace rama_ci=5 if ramaemppri==6
replace rama_ci=6 if ramaemppri==7 | ramaemppri==9
replace rama_ci=7 if ramaemppri==8
replace rama_ci=8 if ramaemppri==11 | ramaemppri==12
replace rama_ci=9 if ramaemppri>=13  & ramaemppri<=21 | ramaemppri==10
label var rama_ci "Rama de actividad"
label def rama_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def rama_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def rama_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val rama_ci rama_ci

* rama secundaria
gen ramasec_ci=.
replace ramasec_ci=1 if ramaempsec==1
replace ramasec_ci=2 if ramaempsec==2
replace ramasec_ci=3 if ramaempsec==3
replace ramasec_ci=4 if ramaempsec==4 | ramaempsec==5
replace ramasec_ci=5 if ramaempsec==6
replace ramasec_ci=6 if ramaempsec==7 | ramaempsec==9
replace ramasec_ci=7 if ramasec_ci==8
replace ramasec_ci=8 if ramaempsec==11 | ramaempsec==12
replace ramasec_ci=9 if ramaempsec>=13  & ramaempsec<=21 | ramaempsec==10
label var ramasec_ci "Rama de actividad"
label def ramasec_ci 1"Agricultura, caza, silvicultura y pesca" 2"Explotación de minas y canteras" 3"Industrias manufactureras"
label def ramasec_ci 4"Electricidad, gas y agua" 5"Construcción" 6"Comercio, restaurantes y hoteles" 7"Transporte y almacenamiento", add
label def ramasec_ci 8"Establecimientos financieros, seguros e inmuebles" 9"Servicios sociales y comunales", add
label val ramasec_ci ramasec_ci

***************
* spublico_ci *
***************
*Personas que trabajan en el sector publico.
* Esta varible no existía en el código de las armonizaciones anteriores. Se crea  a partir de claspubprivpri (clasificación público-privado del empleo principal) en 2023
gen spublico_ci=.
replace spublico_ci =1 if  claspubprivpri==1 &  emp_ci==1
label var spublico_ci "Personas que trabajan en el sector público"

*************
* tamemp_ci *
*************
*Costa Rica Pequeña 1 a 5, Mediana 6 a 19, Grande Más de 19
/*
gen tamemp_ci = 1 if (c10>=1 & c10<=5)
replace tamemp_ci = 2 if (c10>=6 & c10<=19)
replace tamemp_ci = 3 if (c10>19)
*/
* MLO, según los codigos del formulario
gen tamemp_ci = 1 if (c10>=1 & c10<=5)
replace tamemp_ci = 2 if (c10>=6 & c10<=10)
replace tamemp_ci = 3 if (c10>10 & c10!=.)
replace tamemp_ci = . if c10==99 /*missing*/

label define tamemp_ci 1 "Pequeña" 2 "Mediana" 3 "Grande"
label value tamemp_ci tamemp_ci
label var tamemp_ci "Tamaño de empresa"

****************
*cotizando_ci***
****************
*Cambia respecto a la de 2015, ya que separaron las categorias cuenta propia o voluntario
*gen cotizando_ci=1 if (a11==1 | a11==2 | a11==3)
gen cotizando_ci=1 if (a11==1 | a11==2 | a11==13 | a11==14) 
recode cotizando_ci .=0 
label var cotizando_ci "Cotizante a la Seguridad Social"
label define cotizando_ci 0"No cotiza" 1"Cotiza a la SS" 
label value cotizando_ci cotizando_ci

**************
* instcot_ci *
**************
clonevar instcot_ci =  a12
label var instcot_ci "Institucion a la que cotiza - variable original de cada pais" 

***************
* afiliado_ci *	
***************
* esta variable no estaba creada en la armonización de años anteriores
gen afiliado_ci =.
replace afiliado_ci = 0 if a11==0
replace afiliado_ci =1 if a11>0 & a11<99

*************
* formal_ci *
*************
gen formal=1 if cotizando_ci==1 
gen byte formal_ci=1 if formal==1 & (condocup_ci==1 | condocup_ci==2)
recode formal_ci .=0 if (condocup_ci==1 | condocup_ci==2)
label var formal_ci "1=afiliado o cotizante / PEA"

*******************
* tipocontrato_ci *
*******************
/*
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if e1==1 & categopri_ci==3
replace tipocontrato_ci=2 if (e1>=2 & e1<=3) & categopri_ci==3
recode tipocontrato_ci .=0
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci
*/
* No hay pregunta de firma de contrato solo tipo de trabajo. 
gen tipocontrato_ci=.
replace tipocontrato_ci=1 if e1==1 & categopri_ci==3
replace tipocontrato_ci=2 if (e1>=2 & e1<=5) & categopri_ci==3
label var tipocontrato_ci "Tipo de contrato segun su duracion"
label define tipocontrato_ci 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin contrato/verbal" 
label value tipocontrato_ci tipocontrato_ci

************
* ocupa_ci *
************
*Ocupacion laboral actividad principal.
* Nota MGD 08/04/2014: se recodifico segun la clasificacion CIUO-08.
/*gen ocupa_ci=.
replace ocupa_ci=1 if c9a>=2111 & c9a<=3719 & emp_ci==1
replace ocupa_ci=2 if c9a>=1111 & c9a<=1439 & emp_ci==1
replace ocupa_ci=3 if c9a>=4110 & c9a<=4419 & emp_ci==1
replace ocupa_ci=4 if ((c9a>=5210 & c9a<=5249) | (c9a>=9510 & c9a<=9520)) & emp_ci==1
replace ocupa_ci=5 if ((c9a>=5110 & c9a<=5170) | (c9a>=5311 & c9a<=5419) | (c9a>=9111 & c9a<=9129) | (c9a>=9611 & c9a<=9624)) & emp_ci==1
replace ocupa_ci=6 if ((c9a>=6111 & c9a<=6340) | (c9a>=9211 & c9a<=9216)) & emp_ci==1
replace ocupa_ci=7 if ((c9a>=7111 & c9a<=8350) | (c9a>=9311 & c9a<=9412)) & emp_ci==1
replace ocupa_ci=9 if c9a>=9629 & c9a!=. & emp_ci==1
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral"
*/
* No es necesario condicionar por ocupados ya que los que contestan esta pregunta son ocupados
gen ocupa_ci=.
replace ocupa_ci=1 if ocupemppri==2 | ocupemppri==3
replace ocupa_ci=2 if ocupemppri==1
replace ocupa_ci=3 if ocupemppri==4
replace ocupa_ci=4 if ocupemppri==5
replace ocupa_ci=5 if ocupemppri==7
replace ocupa_ci=6 if ocupemppri==6
replace ocupa_ci=7 if ocupemppri==8

replace ocupa_ci=9 if ocupemppri==9 | ocupemppri==10
label define ocupa_ci 1"profesional y tecnico" 2"director o funcionario sup" 3"administrativo y nivel intermedio"
label define ocupa_ci  4 "comerciantes y vendedores" 5 "en servicios" 6 "trabajadores agricolas", add
label define ocupa_ci  7 "obreros no agricolas, conductores de maq y ss de transporte", add
label define ocupa_ci  8 "FFAA" 9 "Otras ", add
label value ocupa_ci ocupa_ci
label variable ocupa_ci "Ocupacion laboral"

***************
*pensionsub_ci*
***************
gen byte pensionsub_ci= 1 if h9e==1
replace pensionsub_ci =0 if h9e==2
label var pensionsub_ci "1=recibe pension subsidiada / no contributiva"

*************
**pension_ci*
*************
gen byte pension_ci=1 if h9h == 1 
replace pension_ci =0 if h9h == 2 
label var pension_ci "1=Recibe pension contributiva"
 
**************
* tipopen_ci *
**************
*No se encuentra esta variable en 2016
gen tipopen_ci=.
label var tipopen_ci "Tipo de pension - variable original de cada pais" 

**************
* instpen_ci *
**************
gen instpen_ci=.
label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais"  

****************
* V. ingresos  *
****************

*************
* ylmpri_ci *
*************
* Ingreso laboral monetario actividad principal
egen ylmpri_ci=  rsum(spif aif gpif dif gpina gpsfi gpia spmn ipsp asp sesp bsp oisp), missing
replace ylmpri_ci= . if ithn == 99999999 
replace ylmpri_ci= 0 if ithn == 0
replace ylmpri_ci= . if ithn == .
label var  ylmpri_ci "Ingreso laboral monetario actividad principal"

**************
* ylnmpri_ci *
**************
* Ingreso laboral no monetario actividad principal 
*Se da preferencia al agregado oficial 
egen ylnmpri_ci= rsum(inmpina inmpia spnma spnmv spnmt spnmvh spnmo), missing
replace ylnmpri_ci= . if ithn == 99999999 
replace ylnmpri_ci= 0 if ithn == 0
replace ylnmpri_ci= . if ithn == .
label var ylnmpri "Ingreso laboral no monetario act. principal"

**************
* ylmsec_ci  *
**************
*Ingreso laboral monetario actividad secundaria.
egen ylmsec_ci= rsum(gsi ssmn), missing
replace ylmsec_ci= . if ithn == 99999999 
replace ylmsec_ci= 0 if ithn == 0
replace ylmsec_ci= . if ithn == .
label var ylmsec_ci "Ingreso laboral monetario actividad secundaria"

**************
* ylnmsec_ci *
**************
*Ingreso laboral no monetario actividad secundaria
*Se da preferencia al agregado oficial 
egen ylnmsec_ci= rsum(inmsi ssnm), missing
replace ylnmsec_ci= . if ithn == 99999999 
replace ylnmsec_ci= 0 if ithn == 0
replace ylnmsec_ci= . if ithn == .
label var ylnmsec_ci "Ingreso laboral no monetario actividad secundaria"

***************
* ylmotros_ci *
***************
*Ingreso laboral monetario otros trabajos
gen ylmotros_ci=.
label var ylmotros_ci "Ingreso laboral monetario otros trabajos"

****************
* ylnmotros_ci *
****************
* Ingreso laboral no monetario otros trabajos
gen ylnmotros_ci=.
label var ylnmotros_ci "Ingreso laboral no monetario otros trabajos"

**********
* ylm_ci *
**********
*Ingreso laboral monetario total
egen ylm_ci=rsum(ylmpri_ci ylmsec_ci), missing
replace ylm_ci=. if ylmpri_ci==. & ylmsec_ci==.
label var ylm_ci "Ingreso laboral monetario total"

 
***********
* ylnm_ci *
***********
*Ingreso laboral no monetario total
egen ylnm_ci=rsum(ylnmpri_ci ylnmsec_ci), missing
replace ylnm_ci=. if ylnmpri_ci==. & ylnmsec_ci==.
label var ylnm_ci "Ingreso laboral no monetario total"

***********
* ynlm_ci *
***********
*Ingreso no laboral monetario (otras fuentes)
*Se da preferencia al agregado oficial 
*Ingreso por renta de la propiedad, transferencias monetarias
*egen ynlm_ci=rsum(ia ii id ib trnc timas ts tbc tpa tpn tpe tap te tdp ot), missing
*Modificación SCGR 05/02/2017 Se agregan las variables tapa tapn tape, y elinima la tap
egen ynlm_ci=rsum(ia ii id ib trnc timas ts tbc tpa tpn tpe tapa tapn tape taprnc te tdp ot), missing
replace ynlm_ci= . if ithn == 99999999 
replace ynlm_ci= 0 if ithn == 0
replace ynlm_ci= . if ithn == .
label var ynlm_ci "Ingreso no laboral monetario (otras fuentes)"

*****************
*ynlm_publico_ci*
*****************
egen ynlm_publico_ci=rsum(trnc timas ts), missing
replace ynlm_publico_ci= . if ithn == 99999999 
replace ynlm_publico_ci= 0 if ithn == 0
replace ynlm_publico_ci= . if ithn == .
label var ynlm_publico_ci "Ingreso no laboral monetario publico (otras fuentes)"

*****************
*ynlm_publico_ch*
*****************
* Ingreso no laboral monetario publico del Hogar
by idh_ch, sort: egen ynlm_publico_ch=sum(ynlm_publico_ci) if miembros_ci==1, missing
label var ynlm_publico_ch "Ingreso no laboral monetario publico del Hogar"

*****************
*ynlm_privado_ci*
*****************
egen ynlm_privado_ci=rsum(ia ii id ib tbc tpa tpn tpe tapa tapn tape taprnc te tdp ot), missing
replace ynlm_privado_ci= . if ithn == 99999999 
replace ynlm_privado_ci= 0 if ithn == 0
replace ynlm_privado_ci= . if ithn == .
label var ynlm_privado_ci "Ingreso no laboral monetario privado (otras fuentes)"

*****************
*ynlm_privado_ch*
*****************
* Ingreso no laboral monetario publico del Hogar
by idh_ch, sort: egen ynlm_privado_ch=sum(ynlm_privado_ci) if miembros_ci==1, missing
label var ynlm_privado_ch "Ingreso no laboral monetario privado del Hogar"

************
* ynlnm_ci *
************
*Ingreso no laboral no monetario (otras fuentes)
*Transferencias no monetarias.
gen ynlnm_ci=tnm
replace ynlnm_ci= . if ithn == 99999999 
replace ynlnm_ci= 0 if ithn == 0
replace ynlnm_ci= . if ithn == .
label var ynlnm_ci "Ingreso no laboral no monetario"

*********
*ytot_ci*
*********
*Ingreso total del individuo 
egen double ytot_ci = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), mi


**********
* ylm_ch *
**********
*Ingreso laboral monetario del Hogar
by idh_ch, sort: egen ylm_ch=sum(ylm_ci) if miembros_ci==1, missing
label var ylm_ch "Ingreso laboral monetario del Hogar"

***********
* ylnm_ch *
***********
*Ingreso laboral no monetario del Hogar
by idh_ch, sort: egen ylnm_ch=sum(ylnm_ci) if miembros_ci==1, missing
label var ylnm_ch  "Ingreso laboral no monetario del Hogar"

***************
* nrylmpri_ci *
***************
*Identificador de No Respuesta (NR) del ingreso de la actividad principal
gen nrylmpri_ci=.
label var nrylmpri_ci "Identificador de No Respuesta (NR) del ingreso de la actividad principal"

***************
* nrylmpri_ch *
***************
* Identificador de los hogares en donde alguno de los miembros
* No Sabe/No Responde el ingreso de la actividad principal
by idh_ch, sort: egen nrylmpri_ch=sum(nrylmpri_ci) if miembros_ci==1, missing
replace nrylmpri_ch=1 if nrylmpri_ch>0 & nrylmpri_ch<.
replace nrylmpri_ch=. if nrylmpri_ch==.
label var nrylmpri_ch "Id. hogar si algun miembro no sabe o no respond el ingreso act. principal"

************
* ylmnr_ch *
************
*Ingreso laboral monetario del Hogar
by idh_ch, sort: egen ylmnr_ch=sum(ylm_ci) if miembros_ci==1, missing
replace ylmnr_ch=. if nrylmpri_ch==1
label var ylmnr_ch "Ingreso laboral monetario del Hogar considera No respuesta"

***********
* ynlm_ch *
***********
* Ingreso no laboral monetario del Hogar
by idh_ch, sort: egen ynlm_ch=sum(ynlm_ci) if miembros_ci==1, missing
label var ynlm_ch "Ingreso no laboral monetario del Hogar"

************
* ynlnm_ch *
************
*Ingreso no laboral no monetario del Hogar
gen ynlnm_ch=.
label var ynlnm_ch "Ingreso no laboral no monetario del Hogar" 

***************
* ylmhopri_ci *
***************
*Salario monetario de la actividad principal
gen ylmhopri_ci=ylmpri_ci/(horaspri_ci*4.3)
label var ylmhopri_ci "Salario  monetario de la actividad principal"

************
* ylmho_ci *
************
*Salario  monetario de todas las actividades
gen ylmho_ci=ylm_ci/(horastot_ci*4.3)
label var ylmho_ci "Salario  monetario de todas las actividades"

**************
* remesas_ci *
**************
* Remesas reportadas por el individuo
*gen remesas_ci=ing_15
*drop ing_3-ing_15
*Modificación Mayra Sáenz - Abril 2014
*Transferencias del extranjero
g remesas_ci= te
replace remesas_ci= . if ithn == 99999999 
replace remesas_ci= 0 if ithn == 0
replace remesas_ci= . if ithn == .
label var remesas_ci "Remesas reportadas por el individuo"

**************
* remesas_ch *
**************
*Remesas del Hogar
by idh_ch, sort: egen remesas_ch=sum(remesas_ci) if miembros_ci==1, missing
label var remesas_ch "Remesas del Hogar"

***********
* ypen_ci *
***********
recode h9h1 (99999999=.)
/* para este año sólo hay opción mes
		   1 mes
           2 bimestre
           3 trimestre
           4 cuatrimestre
           6 semestre
           8 año
           9 ignorado
*/
gen ypen_ci=h9h1 if  h9h2 ==1
label var ypen_ci "Valor de la pension contributiva"

**************
* ypensub_ci *
**************
gen ypensub_ci= h9e1 if h9e2==1
label var ypensub_ci "Valor de la pension subsidiada / no contributiva"

*********
*ytot_ch*
*********
*nueva variable: ingresos totales del hogar
egen double ytot_ch= rowtotal(ylm_ch ylnm_ch ynlm_ch ynlnm_ch), mi 
 

	*****************
	* VI. EDUCACIÓN *
	*****************

********************************
***aedu_ci: Años de educacion***
********************************
gen aedu_ci=.
replace aedu_ci=0 if a14==0 | a14==1 
label var aedu_ci "Años de educación"

replace aedu_ci=. if a14==2 //Educacion Especial. Solo como check

*Primaria
replace aedu_ci=1 if a14==11 
replace aedu_ci=2 if a14==12
replace aedu_ci=3 if a14==13
replace aedu_ci=4 if a14==14
replace aedu_ci=5 if a14==15
replace aedu_ci=6 if a14==16

*Secundaria (académica y técnica)
replace aedu_ci=7 if a14==21 | a14==31
replace aedu_ci=8 if a14==22 | a14==32
replace aedu_ci=9 if a14==23 | a14==33
replace aedu_ci=10 if a14==24 | a14==34
replace aedu_ci=11 if a14==25 | a14==26 | a14==35| a14==36 | a14==37

*Superior (universitario o para-universitario)
replace aedu_ci=12 if a14==41 | a14==51
replace aedu_ci=13 if a14==42 | a14==52
replace aedu_ci=14 if a14==43 | a14==53
replace aedu_ci=15 if a14==54 
replace aedu_ci=16 if a14==55
replace aedu_ci=17 if a14==56

*Postgrado - Se asume 4 años de grado

replace aedu_ci=16 if a14==71 | a14==101 
replace aedu_ci=17 if a14==72 | a14==102 
replace aedu_ci=18 if a14==73 
replace aedu_ci=19 if a14==74  

* Se asume 4+2 de maestría para doctorado
replace aedu_ci=19 if a14==112 // dos años de doctorado
replace aedu_ci=21 if a14==114 // cuatro años de doctorado


// imputando valores perdidos

replace aedu_ci=0 if a14==19 // años de primeria ignorados
replace aedu_ci=6 if a14==29 // primaria completa si secundaria ignorada
replace aedu_ci=6 if a14==39 // primaria completa si secundaria ignorada
replace aedu_ci=11 if a14==49 // secundaria completa si parauniversitaria ignorada
replace aedu_ci=11 if a14==59 // secundaria completa si universitaria ignorada


************************************************************************************
***eduui_ci: Peronas que no han completado la educacion universitaria o terciaria***
************************************************************************************
gen eduui_ci=0
replace eduui_ci=1 if (a14>=41 & a14<=59) & inlist(a16b, 0, 3, 9)
replace eduui_ci=. if aedu_ci==. 
label variable eduui_ci "Superior incompleto"


**********************************************************************************
***EDUUC_CI: Personas que han completado la educacion universitaria o terciaria***
**********************************************************************************
gen byte eduuc_ci=0
replace eduuc_ci=1 if a16b ==43 // tres anios de parauniversitaria
replace eduuc_ci=1 if (a14==54 & a16b>3) // cuatro anios de universitaria y titulo de licenciatura o superior
replace eduuc_ci=1 if a14>=55  & a14<=56 // cinco anios o mas de universitaria,
replace eduuc_ci=1 if a14>=71  & a14<=114 // postgrados
replace eduuc_ci=. if aedu_ci==.
replace eduuc_ci=1 if inlist(a16b, 1, 2, 4, 5, 7, 8)
label variable eduuc_ci "Superior completo"



************************************************
***ASISPRE_CI: Asistencia a Educacion preescolar
************************************************
g asispre_ci=0
replace asispre_ci =1 if (a13==1 | a13==2)
la var asispre_ci "Asiste a educacion prescolar"

**********************************************************************************
***EDUAC_CI: Educación terciaria académica versus educación terciaria no-académica
**********************************************************************************
gen eduac_ci=.
replace eduac_ci=1 if (a14>=51 & a14<=114)  
replace eduac_ci=1 if inlist(a16b, 2, 4, 5, 7, 8)
replace eduac_ci=0 if a14>=41 & a14<=43
replace eduac_ci=0 if inlist(a16b, 1)

label variable eduac_ci "Superior universitario vs superior no universitario"

**********************************************************************
***ASISTE_CI: Personas que actualmente asisten a centros de enseñanza
**********************************************************************
gen asiste_ci=.
replace asiste_ci=1 if a13>=1 & a13<=9
replace asiste_ci=0 if a13==0
label variable asiste_ci "Asiste actualmente a la escuela"

************************************************************
***razonesnoasis_ci: Razones para no asistir a la escuela
***********************************************************

g razonesnoasis_ci = .
replace razonesnoasis_ci = 1 if inlist(a17, 1, 5)
replace razonesnoasis_ci = 2 if inlist(a17, 2, 7, 8)
replace razonesnoasis_ci = 3 if inlist(a17, 3, 4, 9, 10)
replace razonesnoasis_ci = 4 if inlist(a17, 6, 11)
replace razonesnoasis_ci = 5 if inlist(a17, 12, 13)

label define razonesnoasis_ci 1 "Problemas económicos/trabajo" 2 "Falta de interés/ problemas de rendimiento " 3 "Quehaceres domésticos/ embarazo/ cuidado de niños/as/ problemas familiares o de salud" 4 "Problemas de acceso" 5	"Otros" 
label value  razonesnoasis_ci razonesnoasis_ci

******************************************************************
***EDUPUB_CI: Personas que asisten a centros de enseñanza publicos
******************************************************************
gen edupub_ci=.
replace edupub_ci=1 if (a15a==1| a15a==2) & asiste_ci==1 // incluye los semi publicos
replace edupub_ci=0 if (a15a==3 | a15a==4) & asiste_ci==1 // incluye los extranjeros
label var edupub_ci "Personas asisten a centros de enseñanza públicos"


	*****************
	* VII. vivienda *
	*************^***

****************
***aguared_ch***
****************
* Acceso a una fuente de agua por red
/*
v11
           0 No tiene por tubería
           1 Tubería dentro de la vivienda
           2 Tubería fuera de la vivienda pero dentro del lote o edificio
           3 Tubería fuera del lote o edificio
           9 Ignorado
v12

           1 Acueducto del A y A
           2 Acueducto rural
           3 Acueducto municipal
           4 Empresa o cooperativa
           5 Pozo
           6 Río, quebrada o naciente
           7 Lluvia u otro
           9 Ignorado
*/
		   
gen aguared_ch=0
replace aguared_ch=1 if (v12 <= 4 & (v11>0 & v11 <3))
label var aguared_ch "Acceso a una fuente de agua por red"

*****************
*aguafconsumo_ch*
*****************
gen aguafconsumo_ch = 0
replace aguafconsumo_ch = 1 if (v11==1 | v11==2) & v12<=4
replace aguafconsumo_ch = 2 if (v11==3|v11==0) & v12<=4
replace aguafconsumo_ch = 5 if v12==7
replace aguafconsumo_ch = 8 if v12==6
replace aguafconsumo_ch = 10 if v12==5

*****************
*aguafuente_ch*
*****************
gen aguafuente_ch = .
replace aguafuente_ch = 1 if (v11==1 | v11==2) & v12<=4
replace aguafuente_ch = 2 if (v11==3|v11==0) & v12<=4
replace aguafuente_ch = 5 if v12==7
replace aguafuente_ch = 8 if v12==6
replace aguafuente_ch = 10 if v12==5
replace aguafuente_ch = 10 if aguafuente_ch ==. & jefe_ci==1


*************
*aguadist_ch*
*************
/*v11
           0 No tiene por tubería
           1 Tubería dentro de la vivienda
           2 Tubería fuera de la vivienda pero dentro del lote o edificio
           3 Tubería fuera del lote o edificio
           9 Ignorado
*/

gen aguadist_ch=.
replace aguadist_ch=1 if v11==1
replace aguadist_ch=2 if v11==2
replace aguadist_ch=3 if v11==3
replace aguadist_ch=0 if v11==0
label define aguadist_ch 1 "tubería dentro de la vivienda" 2 " tubería fuera de la vivienda pero dentro del lote o edificio" 3 "tubería fuera del lote o edificio"
label var aguadist_ch "Ubicación de la principal fuente de agua"

**************
*aguadisp1_ch*
**************
gen aguadisp1_ch =9

**************
*aguadisp2_ch*
**************
gen aguadisp2_ch =9

*************
*aguamala_ch*  Altered
*************
gen aguamala_ch = 2
replace aguamala_ch = 0 if aguafuente_ch<=7
replace aguamala_ch = 1 if aguafuente_ch>7 & aguafuente_ch!=10

*****************
*aguamejorada_ch*  Altered
*****************
gen aguamejorada_ch = 2
replace aguamejorada_ch = 0 if aguafuente_ch>7 & aguafuente_ch!=10
replace aguamejorada_ch = 1 if aguafuente_ch<=7 
*label var aguamejorada_ch "= 1 si la fuente de agua es mejorada"

***************
* aguamide_ch *
***************
gen aguamide_ch=.
label var aguamide_ch "Usan medidor para pagar consumo de agua"

**********
*bano_ch *  Altered
**********
gen bano_ch=.
replace bano_ch=0 if v13a==0 
replace bano_ch=1 if v13a==1
replace bano_ch=2 if v13a==2 | v13a==3
replace bano_ch=6 if v13a==5 | v13a==4
replace bano_ch=6 if bano_ch ==. & jefe_ci==1
label var bano_ch "Hogar tiene algún tipo de servicio higiénico"

*************
* banoex_ch *
*************
gen banoex_ch=.
replace banoex_ch=1 if v14b==1
replace banoex_ch=0 if v14b==2
label var banoex_ch "Servicio higiénico de uso exclusivo del hogar"

*****************
*banomejorado_ch*  Altered
*****************
gen banomejorado_ch= 2
replace banomejorado_ch =1 if bano_ch<=3 & bano_ch!=0
replace banomejorado_ch =0 if (bano_ch ==0 | bano_ch>=4) & bano_ch!=6

************
*sinbano_ch*
************
gen sinbano_ch = 0
replace sinbano_ch = 3 if v13a==0
*label var sinbano_ch "= 0 si tiene baño en la vivienda o dentro del terreno"

*************
*aguatrat_ch*
*************
gen aguatrat_ch =9

********
*luz_ch*
********
/*v15
           0 No hay luz eléctrica
           1 Del ICE
           2 De la CNFL
           3 De la ESPH / JASEC
           4 De Cooperativa
           5 De planta privada
           6 Otra fuente de energía
           9 Ignorado
*/
gen luz_ch=.
replace luz_ch=1 if v15>=1 & v15<=6
replace luz_ch=0 if v15==0
label var luz_ch "Principal fuente de iluminación es electricidad"

************
*luzmide_ch*
************
gen luzmide_ch=.
label var luzmide_ch  "Hogar usa un medidor para pagar por su consumo de electricidad"

************
*combust_ch*
************
/* v16

           0 Ninguno (no cocina)
           1 Electricidad
           2 Gas
           3 Leña o carbón
         
*/
gen combust_ch=.
replace combust_ch=1 if  v16==1 | v16==2
replace combust_ch=0 if  v16==3 
label var combust_ch "Combustible principal del hogar es gas o electricidad"

***********
* piso_ch *
***********
/*v6
           0 No tiene (piso de tierra)
           1 Mosaico, cerámica, terrazo
           2 Cemento (lujado o no)
           3 Madera
           4 Material natural (bambú, caña, chonta)
           5 Otro
           9 Ignorado
*/
gen piso_ch=.
replace piso_ch=0 if v6==0
replace piso_ch=1 if v6>=1 & v6<=3
replace piso_ch=2 if v6==4 | v6 ==5 
label define piso_ch 0 "Piso de tierra" 1 "Materiales permanentes" 2 "Otros materiales"
label value piso_ch piso_ch
label var piso_ch "Materiales de construcción del piso"

************
* pared_ch *
************
/*v3
           0 Material de desecho
           1 Block o ladrillo
           2 Zócalo (con madera, zinc o fibrocemento)
           3 Madera
           4 Prefabricado
           5 Zinc
           6 Fibrocemento (Fibrolit, Ricalit)
           7 Fibras naturales (bambú, caña, chonta)
           8 Otro
           9 Ignorado
*/
gen pared_ch=.
replace pared_ch=0 if v3==0
replace pared_ch=1 if v3>=1  & v3<=6
replace pared_ch=2 if v3==8 | v3==7 
label define pared_ch  0 "No permanentes" 1 "Materiales permanentes" 2 "Otros materiales"
label value pared_ch pared_ch
label var pared_ch "Materiales de construcción de las paredes"

************
* techo_ch *
************
/* v4
           0 Material de desecho
           1 Lámina de metal o zinc
           2 Fibrocemento
           3 Entrepiso
           4 Fibras naturales (bambú, caña, chonta)
           5 Otro
           9 Ignorado
*/
gen techo_ch=.
replace techo_ch=0 if v4==0 
replace techo_ch=1 if v4>=1 & v4<=3
replace techo_ch=2 if v4==5 | v4==4
label define techo_ch  0 "No permanentes" 1 "Materiales permanentes" 2 "Otros materiales"
label value techo_ch techo_ch
label var techo_ch "Materiales de construcción del techo"

************
* resid_ch *
************
/* v17a
           1 Camión recolector
           2 La botan en hueco o entierran
           3 La queman
           4 La botan en lote baldío
           5 La botan en río, quebrada o mar
           6 Otro
           9 Ignorado

*/
gen resid_ch=.
replace resid_ch=0 if v17a==1
replace resid_ch=1 if v17a==2 |v17a==3
replace resid_ch=2 if v17a==4 |v17a==5
replace resid_ch=3 if v17a==6
label define resid_ch 0 "Recolección pública" 1 "Quemados o enterrados" 2 "Tirados a un espacio abierto" 3 "Otros"
label value resid_ch resid_ch
label var resid_ch "Método de eliminación de residuos"

***********
* dorm_ch *
***********
gen dorm_ch=.
replace dorm_ch=v8 if v8>=0 & v8<=10
replace dorm_ch=1 if v8==0
label var dorm_ch "Cantidad de habitaciones que se destinan exclusivamente para dormir"

***********
* dorm_ch *
***********
gen cuartos_ch=.
replace cuartos_ch=v9 if v9>=1 & v9<=20
label var cuartos_ch "Cantidad de habitaciones en el hogar"

*************
* cocina_ch *
*************
gen cocina_ch=.
label var cocina_ch "Si existe un cuarto separado y exclusivo para cocinar"

************
* telef_ch *
************
gen telef_ch=.
replace telef_ch=1 if  v18b==3
replace telef_ch=0 if  v18b==4
label var telef_ch "El hogar tiene servicio telefónico"

*************
* refrig_ch *
*************
gen refrig_ch=.
replace refrig_ch=1 if  v18c==5
replace refrig_ch=0 if  v18c==6
label var refrig_ch "El hogar posee heladera o refrigerador"

************
* freez_ch *
************
gen freez_ch=.
label var freez_ch "El hogar posee freezer o congelador"

***********
* auto_ch *
***********
gen auto_ch=.
replace auto_ch=1 if  v18j==3
replace auto_ch=0 if  v18j==4
label var auto_ch "El hogar posee automóvil particular"

************
* compu_ch *
************
gen compu_ch= .
replace compu_ch = 0 if v18f==4 | v18g==6
replace compu_ch = 1 if v18f==3 | v18g==5
label var compu_ch "El hogar posee computadora"

***************
* internet_ch *
***************
gen internet_ch=.
replace internet_ch=1 if  v19==1
replace internet_ch=0 if  v19==0
label var internet_ch "El hogar posee conexión a Internet"

**********
* cel_ch *
**********
gen cel_ch=.
replace cel_ch=1 if  v18a==1
replace cel_ch=0 if  v18a==2
label var cel_ch "El hogar tiene servicio telefónico celular"

************
* vivi1_ch *
************
gen vivi1_ch=.
replace vivi1_ch=1 if  v1==1 |v1==2
replace vivi1_ch=2 if  v1==3 |v1==4
replace vivi1_ch=3 if  v1==5 |v1==6 | v1==7
label define vivi1_ch 1 "Casa" 2 "Departamento" 3 "Otros"
label value vivi1_ch vivi1_ch
label var vivi1_ch "Tipo de vivienda en la que reside el hogar"

************
* vivi2_ch *
************
gen vivi2_ch=.
replace vivi2_ch=1 if vivi1_ch==1 | vivi1_ch==2
replace vivi2_ch=0 if vivi1_ch==3
label var vivi2_ch "La vivienda en la que reside es una casa o departamento"

***************
* viviprop_ch *
***************
gen viviprop_ch=.
replace viviprop_ch=0 if v2a==3
replace viviprop_ch=1 if v2a==1
replace viviprop_ch=2 if v2a==2
replace viviprop_ch=3 if v2a==4 | v2a==5
label define viviprop_ch 0 "Alquilada" 1 " Propia y totalmente pagada" 2 "Propia y en proceso de pago"  3 "Ocupada (propia de facto)"
label value viviprop_ch viviprop_ch
label var viviprop_ch "Propiedad de la vivienda"

**************
* vivitit_ch *
**************
gen vivitit_ch=.
label var vivitit_ch "El hogar posee un título de propiedad"

**************
* vivialq_ch *
**************
gen vivialq_ch=.
replace vivialq_ch=v2a1 	if v2a == 3
replace vivialq_ch=. 		if v2a1==99999999
label var vivialq_ch "Alquiler mensual"

*****************
* vivialqimp_ch *
*****************
gen vivialqimp_ch=.
replace vivialqimp_ch=v2b 	
replace vivialqimp_ch=. 		if v2b==99999999
label var vivialqimp_ch " Alquiler mensual imputado"


	******************
	* VII. migración *
	******************

***************
* migrante_ci *
***************
gen migrante_ci=(lugnac>1) if lugnac!=.
label var migrante_ci "=1 si es migrante"
	
******************
* migantiguo5_ci *
******************
gen migrantiguo5_ci=.
label var migrantiguo5_ci "=1 si es migrante antiguo (5 anos o mas)"
/* La encuesta pregunta por la residencia de hace 2 años */

*************
* miglac_ci *
*************
gen miglac_ci_ci=.
label var miglac_ci "Migrante proveniente de LAC"

	***************************
	* VIII. protección social *
	***************************

	* PTMC: Avancemos (a partir de 2019 se añadió "Crecemos")
	* PNC:  Pensionado del régimen no contributivomonto básico

*Número total de personas en el hogar
*nueva variable
*(se consideran todos los individuos de la base de datos sean miembros o no del hogar) 
 
bys idh_ch: gen nmiembros_sph_ch=_N 
	
* Ingreso del hogar
egen ingreso_total = rowtotal(ylm_ci ylnm_ci ynlm_ci ynlnm_ci), missing
bys idh_ch: egen yhog = sum(ingreso_total)
drop ingreso_total

* Monto de PTMC
gen tmc = a9b if (a9a==1 | a9a==5)
bys idh_ch: egen ing_ptmc = sum(tmc)

* Beneficiarios PTMC
gen percibe_ptmc=(a9a==1 | a9a==5)
bys idh_ch: egen ptmc_ch=max(percibe_ptmc)

replace ing_ptmc=. if yhog==.
replace ptmc_ch  = 1 if (ing_ptmc>0 & ing_ptmc!=.)

* Beneficiarios PNC
gen pnc_ci=(a11==6)
gen ing_pnc = 0
replace ing_pnc=. if yhog==.

* Adultos mayores
gen mayor64_ci=(edad_ci>64 & edad_ci!=.)

* Ingreso neto del hogar
gen y_pc_net = (yhog - ing_ptmc -ing_pnc) / nmiembros_ch

* Etiquetas
lab def ptmc_ch 1 "Beneficiario PTMC" 0 "No beneficiario PTMC"
lab val ptmc_ch ptmc_ch

lab def pnc_ci 1 "Beneficiario PNC" 0 "No beneficiario PNC"
lab val pnc_ci pnc_ci

*Beneficiario PNC hogar
bys idh_ch: egen pensionsub_ch = max(pensionsub_ci) 

*Ingreso del hogar neto mensualizado de transferencias publicas per cápita 
gen double yneto_pc_ch = (ytot_ch - ynlm_publico_ch) / nmiembros_sph_ch

*Persona en el hogar beneficiaria de alguna transferencia publica monetaria
gen bene_cash_ci = (a9a==1 | a9a==2 | h9e==1 | h9f==1)
bys idh_ch: egen bene_cash_ch=max(bene_cash_ci)


	**************************
	* IX. referencia externa *
	**************************
	
************
* salmm_ci *
************
/*
En años anteriores se usaba el promedio de los 4 salarios genéricos + salarios agrícolas. En 2023 se realizó la consulta a LMK y se decidió colocar el salario mínimo genérico del "trabajador en ocupación no calificada"
del Departamento de Salarios Minimos de Costa Rica. Utilizar la información oficial del Gobierno, que suele ser publicada en un PDF como este
https://www.mtss.go.cr/temas-laborales/salarios/Documentos-Salarios/lista_salarios_2024.pdf. Se buscó una fuente externa para comparar el valor.*/
gen salmm_ci= 367108.6
label var salmm_ci "Salario minimo legal"

***********
*  lp_ci  *
***********
gen lp_ci = lp
label var lp_ci "Linea de pobreza oficial del pais"

************
* lpe_ci   *
************
gen lpe_ci = cba
label var lpe_ci "Linea de indigencia oficial del pais"


gen tcylmpri_ci =.
gen autocons_ci =.
gen  rentaimp_ch =.
gen autocons_ch =.
gen  des1_ch=.
gen  des2_ch=.

/*_____________________________________________________________________________________________________*/
* Asignación de etiquetas e inserción de variables externas: tipo de cambio, Indice de Precios al 
* Consumidor (2011=100), Paridad de Poder Adquisitivo (PPA 2011),  líneas de pobreza
/*_____________________________________________________________________________________________________*/


do "$gitFolder\armonizacion_microdatos_encuestas_hogares_scl\_DOCS\\Labels&ExternalVars_Harmonized_DataBank.do"

/*_____________________________________________________________________________________________________*/
* Verificación de que se encuentren todas las variables armonizadas 
/*_____________________________________________________________________________________________________*/

    order region_BID_c region_c pais_c anio_c mes_c zona_c factor_ch idh_ch	idp_ci factor_ci factor_ch /// Identificación 
  sexo_ci edad_ci relacion_ci civil_ci jefe_ci nconyuges_ch nhijos_ch notropari_ch notronopari_ch nempdom_ch /// Demográficas 
  clasehog_ch nmiembros_ch miembros_ci nmayor21_ch nmenor21_ch nmayor65_ch nmenor6_ch nmenor1_ch /// Demográficas 
  condocup_ci categoinac_ci emp_ci cesante_ci desemp_ci subemp_ci durades_ci pea_ci nempleos_ci antiguedad_ci desalent_ci  /// Empleo
  horaspri_ci horastot_ci tiempoparc_ci categopri_ci categosec_ci rama_ci spublico_ci tamemp_ci cotizando_ci instcot_ci	afiliado_ci /// Empleo 
  formal_ci tipocontrato_ci ocupa_ci pension_ci	pensionsub_ci tipopen_ci instpen_ci	ylmpri_ci /// Empleo 
  ylmpri_ci ylnmpri_ci ylmsec_ci ylnmsec_ci ylmotros_ci	ylnmotros_ci  ylm_ci ylnm_ci ynlm_ci ynlnm_ci nrylmpri_ci /// Ingresos individuo 
  ylm_ch ylnm_ch ylmnr_ch ynlm_ch ynlnm_ch ylmhopri_ci ylmho_ci /// Ingresos del hogar 
  nrylmpri_ci nrylmpri_ch /// No respuesta de ingresos  
  remesas_ci remesas_ch ypen_ci ypensub_ci /// Remesas y pensiones
  aedu_ci eduui_ci eduuc_ci eduac_ci asiste_ci edupub_ci razonesnoasis_ci asispre_ci /// Educación
  luz_ch luzmide_ch combust_ch piso_ch pared_ch techo_ch resid_ch dorm_ch cuartos_ch cocina_ch telef_ch refrig_ch /// Vivienda
  freez_ch auto_ch compu_ch internet_ch cel_ch vivi1_ch vivi2_ch viviprop_ch vivitit_ch vivialq_ch vivialqimp_ch /// Vivienda
  aguared_ch aguafconsumo_ch aguafuente_ch aguadist_ch aguadisp1_ch aguadisp2_ch /// Agua y saneamineto
  aguatrat_ch aguamala_ch aguamejorada_ch aguamide_ch bano_ch banoex_ch banomejorado_ch sinbano_ch  /// Agua y saneamineto
  migrante_ci migrantiguo5_ci miglac_ci /// Migración
  salmm_ci lp19_2011 lp31_2011 lp5_2011 lp_ci lpe_ci lp365_2017 lp685_2017 lp14_2017 lp81_2017 tc_c cpi_c cpi2011 cpi2017 ratio_cpi2011 ratio_cpi2017 /// Fuente externa
  ppp_c ppp_2011 ppp_2017 , first /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded /// Fuente externa 
  /// the order was created by regex functions, sph variables are excluded

compress

saveold "`base_out'", replace

log close







	



