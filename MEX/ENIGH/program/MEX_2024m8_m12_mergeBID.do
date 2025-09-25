* (Versión Stata 12)
clear
set more off
set trace on
*________________________________________________________________________________________________________________*

 * Activar si es necesario (dejar desactivado para evitar sobreescribir la base y dejar la posibilidad de 
 * utilizar un loop)
 * Los datos se obtienen de las carpetas que se encuentran en el servidor: ${surveysFolder}
 * Se tiene acceso al servidor únicamente al interior del BID.
 * El servidor contiene las bases de datos MECOVI.
 *________________________________________________________________________________________________________________*

 /*
global ruta = "${surveysFolder}\\survey\MEX\ENIGH\2024\m8_m12\data_orig"

local PAIS MEX
local ENCUESTA ENIGH
local ANO "2024"
local ronda m8_m12

local log_file = "${surveysFolder}\harmonized\\`PAIS'\\`ENCUESTA'\\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out = "${surveysFolder}\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\\data_merge\\`PAIS'_`ANO'`ronda'.dta"

capture log close
log using "`log_file'", replace 
*/


global survey_folder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"
                           
local PAIS MEX
local ENCUESTA ENIGH
local ANO "2024"
local ronda m8_m12


global ruta "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

local log_file  "$survey_folder\\log\\`PAIS'\\`ENCUESTA'\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_out  "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"

capture log close
log using "`log_file'", replace 

/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES - SOCIOMETRO 
País: Mexico
Encuesta: ENIGH 
Round: Septiembre-Diciembre
Autores: Olga y Ceci
Modificado Setiembre 2025: Maria Alejandra Zegarra
Fecha última modificación: Setiembre 2025

							SCL/LMK - IADB
****************************************************************************
 ENIGH MEX 2024 m8_m12 – Merge y preparación para armonización BID

 PRINCIPALES CAMBIOS RESPECTO A 2022
   1) Rutas / logs / guardados
      - Definir una sola vez: 
            global ruta "$survey_folder\`PAIS'\`ENCUESTA'\`ANO'\`ronda'\data_orig"
        y usar nombres reales 2024 (carpeta m8_m12). 
      - Un solo log coherente durante todo el script y saveold al final (evitar duplicados).
   2) Nomenclatura de ingresos
      - 2024 usa prefijo: P_P### (ej.: P_P008, P_P009, P_P104). 
        Reemplaza las referencias a P### (formato 2022) por P_P### en todo el código.
   3) Aguinaldo (banderas persona-nivel)
      - Generar aguinaldo1 (trabajo principal) y aguinaldo2 (secundario) con collapse a nivel persona,
        antes del merge con ingresos. 
      - Merge resultante: m:1 folioviv foliohog numren using "aguinaldo.dta".
      - Filtrar ingresos:
            drop if (clave=="P009" & aguinaldo1!=1)
            drop if (clave=="P016" & aguinaldo2!=1)
   4) Deflactores 2024 y utilidad de deflación
      - Fuente: **INEGI – Índice Nacional de Precios al Consumidor (INPC, base 2018=100)**,
        descargado en septiembre 2025 (archivo INP_INP20250923191540.XLS).
      - Se generaron escalares mensuales 2024 (ene24, feb24, …, ago24) anclados a ago24 (=1).
      - Programa utilitario `_defl_si`:
            program _defl_si
              syntax varname, mes(integer)
              // asigna escalar según mes y divide solo si existe
            end
        Evita errores cuando falte algún escalar y sustituye bloques con llaves tipo { } (no válidas en Stata).
   5) Tipos de datos y robustez
      - Muchas variables de 2024 son string (str1/str2). 
        Comparar por string ("1") o destring cuando se necesite operar numéricamente.
      - Usar capture confirm variable / capture program drop para evitar r(111)/r(110).
      - Evitar usar llaves de bloque (C-style); cada comando va en su línea.

 ORDEN LÓGICO DEL FLUJO (RESUMEN)
   (i)  Definir rutas, abrir log, cargar bases fuente.
   (ii) Construir aguinaldo persona-nivel (preserve/collapse/restore) y guardar aguinaldo.dta.
   (iii) Merge principal a nivel persona: m:1 folioviv foliohog numren usando aguinaldo.dta.
   (iv) Aplicar filtros de claves (P009/P016), deflactación 2024 con `_defl_si`.
   (v) Construir agregados/etiquetas mínimas para pasar a variablesBID.do.
**************************************************************************************************/

*********************************************************
*Parte VII 
*Bienestar (ingresos)
*********************************************************
/*Para la construcción del ingreso corriente del hogar es necesario utilizar
información sobre la condición de ocupación y los ingresos de los individuos.
Se utiliza la información contenida en la base "$ruta\trabajo.dta" para 
identificar a la población ocupada que declara tener como prestación laboral aguinaldo, 
ya sea por su trabajo principal o secundario, a fin de incorporar los ingresos por este 
concepto en la medición*/

*/ ============================================================
* Construcción de flags de aguinaldo a nivel persona (ENIGH 2024)
* Reemplaza el bloque antiguo de "trabajos -> aguinaldo"
* ============================================================

use "$ruta\trabajos.dta", clear

* 1) NO forzar destring si ya son numéricas.
capture confirm numeric variable pres_2
if _rc {
    destring pres_2, replace
}
capture confirm numeric variable id_trabajo
if _rc {
    destring id_trabajo, replace
}

* 2) Trabajo principal: una fila por persona con el máx. de pres_2
preserve
    keep folioviv foliohog numren id_trabajo pres_2
    keep if id_trabajo==1
    collapse (max) pres_2, by(folioviv foliohog numren)
    rename pres_2 pres_21
    tempfile agu1
    save `agu1'
restore


* 3) Trabajo secundario: una fila por persona con el máx. de pres_2
preserve
    keep folioviv foliohog numren id_trabajo pres_2
    keep if id_trabajo==2
    collapse (max) pres_2, by(folioviv foliohog numren)
    rename pres_2 pres_22
    tempfile agu2
    save `agu2'
restore

* 4) Unir en un solo archivo por persona (si falta alguno, póngalo en 0)
use `agu1', clear
merge 1:1 folioviv foliohog numren using `agu2', nogen

* En varios años pres_2 toma valores 1/2 (2 = sí aguinaldo). Ajusta según catálogo.
gen byte aguinaldo1 = (pres_21==2) if !missing(pres_21)
replace aguinaldo1 = 0 if missing(aguinaldo1)

gen byte aguinaldo2 = (pres_22==2) if !missing(pres_22)
replace aguinaldo2 = 0 if missing(aguinaldo2)

label define lbl_agu 0 "No dispone de aguinaldo" 1 "Dispone de aguinaldo", replace
label values aguinaldo1 lbl_agu
label values aguinaldo2 lbl_agu
label var aguinaldo1 "Aguinaldo trabajo principal"
label var aguinaldo2 "Aguinaldo trabajo secundario"

tempfile agu_per
save `agu_per', replace

* 5) Guardar versión final en ruta de trabajo
use `agu_per', clear
save "$ruta\aguinaldo.dta", replace

* ============================================================
* Ahora se incorpora a la base de ingresos
* ============================================================
use "$ruta\ingresos.dta", clear
sort folioviv foliohog numren

* Importante: como INGRESOS suele tener múltiples filas por persona (por clave),
* usa m:1 contra el archivo persona-level de aguinaldo.
merge m:1 folioviv foliohog numren using "$ruta\aguinaldo.dta"

* Si hay personas sin registro en trabajos (no matched), pon flags en 0
replace aguinaldo1 = 0 if missing(aguinaldo1)
replace aguinaldo2 = 0 if missing(aguinaldo2)

* Filtra P009/P016 sólo si NO tienen derecho
drop if (clave=="P009" & aguinaldo1!=1)
drop if (clave=="P016" & aguinaldo2!=1)

*--------------------------------------------------------------
* === DEFLACTORES: base agosto-2024 (ago24 = 100)
*     TODO: Reemplaza estos números por los oficiales (INPC o deflactores ENIGH)
*     Si aún no tienes dic-2024, deja dic24 comentado y usa dic23.
*--------------------------------------------------------------

* --- 2023 (fin de año, por si aguinaldo se pagó en dic-2023)
* scalar dic23 = 97.500   // <-- TODO: reemplazar por valor oficial

* --- 2024 (ene–jul confirmados; ago=100 base; dic24 opcional si ya está)
scalar ene24 = 98.100   // <-- TODO
scalar feb24 = 98.900   // <-- TODO
scalar mar24 = 99.300   // <-- TODO
scalar abr24 = 99.700   // <-- TODO
scalar may24 = 100.100  // <-- TODO
scalar jun24 = 100.400  // <-- TODO
scalar jul24 = 100.700  // <-- TODO
scalar ago24 = 100      // base

* Si ya tienes INPC/deflactor de dic-2024, descomenta y pon el valor:
* scalar dic24 = 103.100 // <-- TODO: reemplazar si está disponible

*--------------------------------------------------------------
* === Deflactación de ingresos mensuales (ing_1 ... ing_6)
*     Notas:
*     - El código asume que mes_k toma valores 2..10 (feb..oct) como en tu script.
*     - Dividimos cada ing_k por el deflactor del mes correspondiente para llevar a ago-2024.
*--------------------------------------------------------------
destring mes_*, replace

* Utilidad: divide por escalar sólo si existe
capture program drop _defl_si
program define _defl_si
    syntax varname, mes(integer)
    local e ""

    if (`mes'==2)  local e "feb24"
    else if (`mes'==3)  local e "mar24"
    else if (`mes'==4)  local e "abr24"
    else if (`mes'==5)  local e "may24"
    else if (`mes'==6)  local e "jun24"
    else if (`mes'==7)  local e "jul24"
    else if (`mes'==8)  local e "ago24"
    else if (`mes'==9)  local e "sep24"
    else if (`mes'==10) local e "oct24"

    capture confirm scalar `e'
    if !_rc {
        quietly replace `varlist' = `varlist' / `e'
    }
end

* Aplica a ing_6 ... ing_1 de acuerdo a tus reglas originales:
quietly {
    replace ing_6=ing_6 if mes_6>=.   // asegura missing si mes no válido
    _defl_si ing_6, mes(2)
    _defl_si ing_6, mes(3)
    _defl_si ing_6, mes(4)
    _defl_si ing_6, mes(5)

    _defl_si ing_5, mes(3)
    _defl_si ing_5, mes(4)
    _defl_si ing_5, mes(5)
    _defl_si ing_5, mes(6)

    _defl_si ing_4, mes(4)
    _defl_si ing_4, mes(5)
    _defl_si ing_4, mes(6)
    _defl_si ing_4, mes(7)

    _defl_si ing_3, mes(5)
    _defl_si ing_3, mes(6)
    _defl_si ing_3, mes(7)
    _defl_si ing_3, mes(8)

    _defl_si ing_2, mes(6)
    _defl_si ing_2, mes(7)
    _defl_si ing_2, mes(8)
    * si no tienes sep24/oct24 definidos, omite estas dos líneas:
    _defl_si ing_2, mes(9)
    _defl_si ing_2, mes(10)

    _defl_si ing_1, mes(7)
    _defl_si ing_1, mes(8)
    _defl_si ing_1, mes(9)
    _defl_si ing_1, mes(10)
}

*--------------------------------------------------------------
* === Tratamiento especial: utilidades y aguinaldo
*     Utilidades (P008, P015): dividir por may-2024 y prorratear a mensual/12
*     Aguinaldo (P009, P016): si existe dic24, úsalo; si no, usa dic23
*--------------------------------------------------------------
capture confirm scalar dic24
local have_dic24 = (c(rc)==0)

replace ing_1 = (ing_1/may24)/12 if inlist(clave,"P008","P015")

if `have_dic24' {
    replace ing_1 = (ing_1/dic24)/12 if inlist(clave,"P009","P016")
}
else {
    capture confirm scalar dic23
    if _rc==0 {
        replace ing_1 = (ing_1/dic23)/12 if inlist(clave,"P009","P016")
    }
    else {
        di as err "No hay dic24 ni dic23 definidos: se omite deflactación de aguinaldo."
    }
}

recode ing_2 ing_3 ing_4 ing_5 ing_6 (0=.) if inlist(clave,"P008","P009","P015","P016")

*--------------------------------------------------------------
* === Ingreso mensual promedio (últimos 6 meses) por persona-clave
*--------------------------------------------------------------
egen double ing_mens = rmean(ing_1 ing_2 ing_3 ing_4 ing_5 ing_6)

*--------------------------------------------------------------
* === Clasificaciones por tipo de ingreso (mantengo tus rangos)
*     Nota: si los rangos de clave cambiaron en 2024, revisa y ajusta.
*--------------------------------------------------------------
gen double ing_mon  = ing_mens if (clave>="P001" & clave<="P009") | (clave>="P011" & clave<="P016") ///
                                  | (clave>="P018" & clave<="P048") | (clave>="P067" & clave<="P081")

gen double ing_lab  = ing_mens if (clave>="P001" & clave<="P009") | (clave>="P011" & clave<="P016") ///
                                  | (clave>="P018" & clave<="P022") | (clave>="P067" & clave<="P081")

gen double ing_rent = ing_mens if (clave>="P023" & clave<="P031")
gen double ing_tran = ing_mens if (clave>="P032" & clave<="P048")

* Desagregados
gen double ing_trab1 = ing_mens if (clave>="P001" & clave<="P009") | (clave>="P011" & clave<="P013")
gen double ing_trab2 = ing_mens if ( (clave>="P014" & clave<="P016") | (clave>="P018" & clave<"P020") | (clave=="P067") )

gen double ing_negp1 = ing_mens if (clave>="P068" & clave<"P074")
gen double ing_negp2 = ing_mens if ( (clave>="P075" & clave<"P081") | (clave>="P021" & clave<="P022") )

g double ypension = ing_mens  if (clave=="P032")
g double trat_pr  = ing_mens  if ((clave>="P034" & clave<="P036") | clave=="P041")
g double trat_pu  = ing_mens  if (clave>="P042" & clave<="P048")
g double dona_pu  = ing_mens  if (clave=="P038")
g double dona_pr  = ing_mens  if (inlist(clave,"P037","P039","P040"))
g double otros    = ing_mens  if (clave>="P049" & clave<="P066")
g double remesas  = ing_mens  if (clave=="P041")
g double prospera = ing_mens  if (clave=="P042")

* Variables por clave (útil para diagnósticos)
levelsof clave, local(claves)
foreach k of local claves {
    gen double P_`k' = ing_mens if clave=="`k'"
}

*--------------------------------------------------------------
* === Identificador de hogar robusto y colapso
*     OJO: Mantengo el colapso persona (folio,numren) como en tu script.
*     Si quieres totales de HOGAR, colapsa por (folioviv foliohog).
*--------------------------------------------------------------
* folio = folioviv (10 chars) + foliohog (2 chars padded)
capture drop folio
gen str2 hog2 = substr("0"+string(real(foliohog),"%9.0f"), -2, 2)
gen str12 folio = folioviv + hog2

collapse (sum) ing_mens ing_mon ing_lab ing_trab* ing_negp* ing_rent ing_tran ///
                ypension trat_pr trat_pu dona_pu dona_pr otros remesas prospera ///
                P_*, by(folio numren)

label var folio     "Identificador del hogar (folioviv+foliohog padded)"
label var ing_mon   "Ingreso corriente monetario del individuo (sin otros ingresos)"
label var ing_lab   "Ingreso laboral act. princ. y sec"
label var ing_trab1 "Ingreso por remuneraciones al trabajo act. princ."
label var ing_negp1 "Ingresos por negocios propios act. princ."
label var ing_trab2 "Ingreso por remuneraciones al trabajo act. sec."
label var ing_negp2 "Ingresos por negocios propios act. sec."
label var ing_rent  "Ingresos por renta de la propiedad"
label var ing_tran  "Ingresos por transferencias"
label var ypension  "Ingresos por jubilación"
label var trat_pr   "Transferencias monetarias/no monetarias privadas"
label var trat_pu   "Transferencias monetarias/no monetarias públicas"
label var dona_pu   "Donaciones públicas"
label var dona_pr   "Donaciones privadas"
label var remesas   "Remesas"
label var otros     "Otros"

sort folio numren, stable

*--------------------------------------------------------------
* === Guardar
*     (opcional) usa otra ruta para no ensuciar data_orig
*--------------------------------------------------------------
* global ruta_out "$ruta\..\data_merge"
* saveold "$ruta_out\ingreso_deflactado24_per.dta", replace
saveold "$ruta\ingreso_deflactado24_per.dta", replace


*********************************************************

*Creación del ingreso no monetario deflactado a pesos de 
*agosto del 2024.

*********************************************************

*No Monetario

use "$ruta\gastoshogar.dta", clear
gen base=1
append using "$ruta\gastospersona.dta"
replace base =2 if base ==.

label var base "Origen del monto"
label define base 1 "Monto del hogar" 2 "Monto de personas"
label value base base

/*En el caso de la información de gasto no monetario, para 
deflactar se utiliza la decena de levantamiento de la 
encuesta, la cual se encuentra en la octava posición del 
folio de la vivienda. En primer lugar se obtiene una variable que 
identifique la decena de levantamiento*/

compress
gen decena=real(substr(folioviv,8,1))

*Definición de los deflactores;		
		
*Rubro 1.1 semanal, Alimentos;		
scalar d11w07 =	0.9869825057 
scalar d11w08 =	1.0000000000 
scalar d11w09 =	1.0130754464 
scalar d11w10 =	1.0178275200 
scalar d11w11 =	1.0207468579 
	
		
*Rubro 1.2 semanal, Bebidas alcohólicas y tabaco;		
scalar d12w07 =	0.9923340135 
scalar d12w08 =	1.0000000000 
scalar d12w09 =	1.0035071112 
scalar d12w10 =	1.0111808568 
scalar d12w11 =	1.0131982216 
	
		
*Rubro 2 trimestral, Vestido, calzado y accesorios;		
scalar d2t05 = 0.9899050815 
scalar d2t06 = 0.9941003723 
scalar d2t07 = 0.9997465345 
scalar d2t08 = 1.0083352270 	
		
*Rubro 3 mensual, Viviendas;	
scalar d3m07 = 0.9998142481 
scalar d3m08 = 1.0000000000 
scalar d3m09 = 0.9978682753 
scalar d3m10 = 1.0031577830 
scalar d3m11 = 1.0197073965 	
		
*Rubro 4.2 mensual, Accesorios y artículos de limpieza para el hogar;		
scalar d42m07=	0.9894769136
scalar d42m08=	1.0000000000
scalar d42m09=	1.0086286240
scalar d42m10=	1.0182083142
scalar d42m11=	1.0237613131	
		
*Rubro 4.2 trimestral, Accesorios y artículos de limpieza para el hogar;		
scalar d42t05=	0.9787953163
scalar d42t06=	0.9897197934
scalar d42t07=	0.9993685126
scalar d42t08=	1.0089456461
	
		
*Rubro 4.1 semestral, Muebles y aparatos domésticos;		
scalar d41s02=	1.0003069312
scalar d41s03=	0.9993861376
scalar d41s04=	0.9992122603
scalar d41s05=	0.9991442214	
		
*Rubro 5.1 trimestral, Salud;		
scalar d51t05=	0.9909917367
scalar d51t06=	0.9954834527
scalar d51t07=	0.9994564693
scalar d51t08=	1.0030487384	
		
*Rubro 6.1.1 semanal, Transporte público urbano;		
scalar d611w07=	0.9963207274
scalar d611w08=	1.0000000000
scalar d611w09=	1.0034865488
scalar d611w10=	1.0052385833
scalar d611w11=	1.0064912880	
		
*Rubro 6 mensual, Transporte;		
scalar d6m07=	0.9987845893
scalar d6m08=	1.0000000000
scalar d6m09=	1.0001664946
scalar d6m10=	1.0057274150
scalar d6m11=	1.0076837268	
		
*Rubro 6 semestral, Transporte;		
scalar d6s02=	0.9808628306
scalar d6s03=	0.9879901879
scalar d6s04=	0.9927380596
scalar d6s05=	0.9969378864
		
*Rubro 7 mensual, Educación y esparcimiento;		
scalar d7m07=	0.9961413091
scalar d7m08=	1.0000000000
scalar d7m09=	1.0095233900
scalar d7m10=	1.0144128271
scalar d7m11=	1.0174522069	
		
*Rubro 2.3 mensual, Accesorios y cuidados del vestido;		
scalar d23m07=	0.9952443607
scalar d23m08=	1.0000000000
scalar d23m09=	1.0081869233
scalar d23m10=	1.0108184343
scalar d23m11=	1.0072323555	
		
*Rubro 2.3 trimestral,  Accesorios y cuidados del vestido;		
scalar d23t05=	0.9914948875
scalar d23t06=	0.9956428139
scalar d23t07=	1.0011437613
scalar d23t08=	1.0063351192	
		
*INPC semestral;		
scalar	dINPCs02 =	0.9773093813
scalar	dINPCs03 =	0.9838008772
scalar	dINPCs04 =	0.9897404209
scalar	dINPCs05 =	0.9957540070
	

*Una vez definidos los deflactores, se seleccionan los rubros
/*
Valor Etiqueta
G1 Gasto monetario en bienes y servicios para el hogar
G2 Gasto monetario en bienes y servicios para otro hogar
G3 Gasto no monetario procedente de autoconsumo
G4 Gasto no monetario por remuneraciones en especie
G5 Gasto no monetario por regalos recibidos de otro hogar
G6 Gasto no monetario por transferencias de instituciones
G7 Gasto imputado por estimación del alquiler
*/
           
*Modificado Mayra Saenz- Abril 2017
gen double gasmon=gasto_tri/3
gen double gasnomon=gas_nm_tri/3

gen esp=1 if tipo_gasto=="G4"
gen reg=1 if tipo_gasto=="G5"
replace reg=1 if tipo_gasto=="G6"
drop if tipo_gasto=="G2" | tipo_gasto=="G3" | tipo_gasto=="G7"

*Control para la frecuencia de los regalos recibidos por el hogar
drop if ((frecu>="5" & frecu<="6") | frecu=="" | frecu=="0") & base==1 & tipo_gasto=="G5"

*Control para la frecuencia de los regalos recibidos por persona

drop if ((frecu>="11" & frecu<="12") | frecu=="") & base==2 & tipo_gasto=="G5"

*Gasto en Alimentos deflactado (semanal) 

gen ali_nm=gasnomon if (clave>="A001" & clave<="A222") | (clave>="A242" & clave<="A247")

replace ali_nm=ali_nm/d11w08 if decena==1
replace ali_nm=ali_nm/d11w08 if decena==2
replace ali_nm=ali_nm/d11w08 if decena==3
replace ali_nm=ali_nm/d11w09 if decena==4
replace ali_nm=ali_nm/d11w09 if decena==5
replace ali_nm=ali_nm/d11w09 if decena==6
replace ali_nm=ali_nm/d11w10 if decena==7
replace ali_nm=ali_nm/d11w10 if decena==8
replace ali_nm=ali_nm/d11w10 if decena==9
replace ali_nm=ali_nm/d11w11 if decena==0

*Gasto en Alcohol y tabaco deflactado (semanal);

gen alta_nm=gasnomon if (clave>="A223" & clave<="A241")

replace alta_nm=alta_nm/d12w08 if decena==1
replace alta_nm=alta_nm/d12w08 if decena==2
replace alta_nm=alta_nm/d12w08 if decena==3
replace alta_nm=alta_nm/d12w09 if decena==4
replace alta_nm=alta_nm/d12w09 if decena==5
replace alta_nm=alta_nm/d12w09 if decena==6
replace alta_nm=alta_nm/d12w10 if decena==7
replace alta_nm=alta_nm/d12w10 if decena==8
replace alta_nm=alta_nm/d12w10 if decena==9
replace alta_nm=alta_nm/d12w11 if decena==0

*Gasto en Vestido y calzado deflactado (trimestral)

gen veca_nm=gasnomon if (clave>="H001" & clave<="H122") | (clave=="H136")

replace veca_nm=veca_nm/d2t05 if decena==1
replace veca_nm=veca_nm/d2t05 if decena==2
replace veca_nm=veca_nm/d2t06 if decena==3
replace veca_nm=veca_nm/d2t06 if decena==4
replace veca_nm=veca_nm/d2t06 if decena==5
replace veca_nm=veca_nm/d2t07 if decena==6
replace veca_nm=veca_nm/d2t07 if decena==7
replace veca_nm=veca_nm/d2t07 if decena==8
replace veca_nm=veca_nm/d2t08 if decena==9
replace veca_nm=veca_nm/d2t08 if decena==0

*Gasto en viviendas y servicios de conservación deflactado (mensual)

gen viv_nm=gasnomon if (clave>="G001" & clave<="G016") | (clave>="R001" & clave<="R004") | clave=="R013"

replace viv_nm=viv_nm/d3m07 if decena==1
replace viv_nm=viv_nm/d3m07 if decena==2
replace viv_nm=viv_nm/d3m08 if decena==3
replace viv_nm=viv_nm/d3m08 if decena==4
replace viv_nm=viv_nm/d3m08 if decena==5
replace viv_nm=viv_nm/d3m09 if decena==6
replace viv_nm=viv_nm/d3m09 if decena==7
replace viv_nm=viv_nm/d3m09 if decena==8
replace viv_nm=viv_nm/d3m10 if decena==9
replace viv_nm=viv_nm/d3m10 if decena==0

*Gasto en Artículos de limpieza deflactado (mensual)

gen lim_nm=gasnomon if (clave>="C001" & clave<="C024")

replace lim_nm=lim_nm/d42m07 if decena==1
replace lim_nm=lim_nm/d42m07 if decena==2
replace lim_nm=lim_nm/d42m08 if decena==3
replace lim_nm=lim_nm/d42m08 if decena==4
replace lim_nm=lim_nm/d42m08 if decena==5
replace lim_nm=lim_nm/d42m09 if decena==6
replace lim_nm=lim_nm/d42m09 if decena==7
replace lim_nm=lim_nm/d42m09 if decena==8
replace lim_nm=lim_nm/d42m10 if decena==9
replace lim_nm=lim_nm/d42m10 if decena==0

*Gasto en Cristalería y blancos deflactado (trimestral)

gen cris_nm=gasnomon if (clave>="I001" & clave<="I026")

replace cris_nm=cris_nm/d42t05 if decena==1
replace cris_nm=cris_nm/d42t05 if decena==2
replace cris_nm=cris_nm/d42t06 if decena==3
replace cris_nm=cris_nm/d42t06 if decena==4
replace cris_nm=cris_nm/d42t06 if decena==5
replace cris_nm=cris_nm/d42t07 if decena==6
replace cris_nm=cris_nm/d42t07 if decena==7
replace cris_nm=cris_nm/d42t07 if decena==8
replace cris_nm=cris_nm/d42t08 if decena==9
replace cris_nm=cris_nm/d42t08 if decena==0

*Gasto en Enseres domésticos y muebles deflactado (semestral)

gen ens_nm=gasnomon if (clave>="K001" & clave<="K037")

replace ens_nm=ens_nm/d41s02 if decena==1
replace ens_nm=ens_nm/d41s02 if decena==2
replace ens_nm=ens_nm/d41s03 if decena==3
replace ens_nm=ens_nm/d41s03 if decena==4
replace ens_nm=ens_nm/d41s03 if decena==5
replace ens_nm=ens_nm/d41s04 if decena==6
replace ens_nm=ens_nm/d41s04 if decena==7
replace ens_nm=ens_nm/d41s04 if decena==8
replace ens_nm=ens_nm/d41s05 if decena==9
replace ens_nm=ens_nm/d41s05 if decena==0

*Gasto en Salud deflactado (trimestral);

gen sal_nm=gasnomon if (clave>="J001" & clave<="J072")

replace sal_nm=sal_nm/d51t05 if decena==1
replace sal_nm=sal_nm/d51t05 if decena==2
replace sal_nm=sal_nm/d51t06 if decena==3
replace sal_nm=sal_nm/d51t06 if decena==4
replace sal_nm=sal_nm/d51t06 if decena==5
replace sal_nm=sal_nm/d51t07 if decena==6
replace sal_nm=sal_nm/d51t07 if decena==7
replace sal_nm=sal_nm/d51t07 if decena==8
replace sal_nm=sal_nm/d51t08 if decena==9
replace sal_nm=sal_nm/d51t08 if decena==0

*Gasto en Transporte público deflactado (semanal)

gen tpub_nm=gasnomon if (clave>="B001" & clave<="B007")

replace tpub_nm=tpub_nm/d611w08 if decena==1
replace tpub_nm=tpub_nm/d611w08 if decena==2
replace tpub_nm=tpub_nm/d611w08 if decena==3
replace tpub_nm=tpub_nm/d611w09 if decena==4
replace tpub_nm=tpub_nm/d611w09 if decena==5
replace tpub_nm=tpub_nm/d611w09 if decena==6
replace tpub_nm=tpub_nm/d611w10 if decena==7
replace tpub_nm=tpub_nm/d611w10 if decena==8
replace tpub_nm=tpub_nm/d611w10 if decena==9
replace tpub_nm=tpub_nm/d611w11 if decena==0


*Gasto en Transporte foráneo deflactado (semestral)

gen tfor_nm=gasnomon if (clave>="M001" & clave<="M018") | (clave>="F007" & clave<="F014")

replace tfor_nm=tfor_nm/d6s02 if decena==1
replace tfor_nm=tfor_nm/d6s02 if decena==2
replace tfor_nm=tfor_nm/d6s03 if decena==3
replace tfor_nm=tfor_nm/d6s03 if decena==4
replace tfor_nm=tfor_nm/d6s03 if decena==5
replace tfor_nm=tfor_nm/d6s04 if decena==6
replace tfor_nm=tfor_nm/d6s04 if decena==7
replace tfor_nm=tfor_nm/d6s04 if decena==8
replace tfor_nm=tfor_nm/d6s05 if decena==9
replace tfor_nm=tfor_nm/d6s05 if decena==0

*Gasto en Comunicaciones deflactado (mensual)

gen com_nm=gasnomon if (clave>="F001" & clave<="F006") | (clave>="R005" & clave<="R008")| (clave>="R010" & clave<="R011")

replace com_nm=com_nm/d6m07 if decena==1
replace com_nm=com_nm/d6m07 if decena==2
replace com_nm=com_nm/d6m08 if decena==3
replace com_nm=com_nm/d6m08 if decena==4
replace com_nm=com_nm/d6m08 if decena==5
replace com_nm=com_nm/d6m09 if decena==6
replace com_nm=com_nm/d6m09 if decena==7
replace com_nm=com_nm/d6m09 if decena==8
replace com_nm=com_nm/d6m10 if decena==9
replace com_nm=com_nm/d6m10 if decena==0

*Modificado Mayra Sáenz Abril, 2017
*Gasto no monetario sólo educación

gen edu_gtosnm=gasnomon if (clave>="E001" & clave<="E021") | (clave>="H134" & clave<="H135") 

replace edu_gtosnm=edu_gtosnm/d7m07 if decena==0
replace edu_gtosnm=edu_gtosnm/d7m07 if decena==1
replace edu_gtosnm=edu_gtosnm/d7m08 if decena==2
replace edu_gtosnm=edu_gtosnm/d7m08 if decena==3
replace edu_gtosnm=edu_gtosnm/d7m08 if decena==4
replace edu_gtosnm=edu_gtosnm/d7m09 if decena==5
replace edu_gtosnm=edu_gtosnm/d7m09 if decena==6
replace edu_gtosnm=edu_gtosnm/d7m09 if decena==7
replace edu_gtosnm=edu_gtosnm/d7m10 if decena==8
replace edu_gtosnm=edu_gtosnm/d7m10 if decena==9

*Gasto en Educación y recreación deflactado (mensual)

gen edre_nm=gasnomon if (clave>="E001" & clave<="E034") | (clave>="H134" & clave<="H135") | (clave>="L001" & clave<="L029") | (clave>="N003" & clave<="N005") | clave=="R009"

replace edre_nm=edre_nm/d7m07 if decena==1
replace edre_nm=edre_nm/d7m07 if decena==2
replace edre_nm=edre_nm/d7m08 if decena==3
replace edre_nm=edre_nm/d7m08 if decena==4
replace edre_nm=edre_nm/d7m08 if decena==5
replace edre_nm=edre_nm/d7m09 if decena==6
replace edre_nm=edre_nm/d7m09 if decena==7
replace edre_nm=edre_nm/d7m09 if decena==8
replace edre_nm=edre_nm/d7m10 if decena==9
replace edre_nm=edre_nm/d7m10 if decena==0

*Gasto en Educación básica deflactado (mensual)

gen edba_nm=gasnomon if (clave>="E002" & clave<="E003") | (clave>="H134" & clave<="H135")

replace edba_nm=edba_nm/d7m07 if decena==1
replace edba_nm=edba_nm/d7m07 if decena==2
replace edba_nm=edba_nm/d7m08 if decena==3
replace edba_nm=edba_nm/d7m08 if decena==4
replace edba_nm=edba_nm/d7m08 if decena==5
replace edba_nm=edba_nm/d7m09 if decena==6
replace edba_nm=edba_nm/d7m09 if decena==7
replace edba_nm=edba_nm/d7m09 if decena==8
replace edba_nm=edba_nm/d7m10 if decena==9
replace edba_nm=edba_nm/d7m10 if decena==0

*Gasto en Cuidado personal deflactado (mensual)

gen cuip_nm=gasnomon if (clave>="D001" & clave<="D026") | (clave=="H132")

replace cuip_nm=cuip_nm/d23m07 if decena==1
replace cuip_nm=cuip_nm/d23m07 if decena==2
replace cuip_nm=cuip_nm/d23m08 if decena==3
replace cuip_nm=cuip_nm/d23m08 if decena==4
replace cuip_nm=cuip_nm/d23m08 if decena==5
replace cuip_nm=cuip_nm/d23m09 if decena==6
replace cuip_nm=cuip_nm/d23m09 if decena==7
replace cuip_nm=cuip_nm/d23m09 if decena==8
replace cuip_nm=cuip_nm/d23m10 if decena==9
replace cuip_nm=cuip_nm/d23m10 if decena==0

*Gasto en Accesorios personales deflactado (trimestral)

gen accp_nm=gasnomon if (clave>="H123" & clave<="H131") | (clave=="H133")

replace accp_nm=accp_nm/d23t05 if decena==1
replace accp_nm=accp_nm/d23t05 if decena==2
replace accp_nm=accp_nm/d23t06 if decena==3
replace accp_nm=accp_nm/d23t06 if decena==4
replace accp_nm=accp_nm/d23t06 if decena==5
replace accp_nm=accp_nm/d23t07 if decena==6
replace accp_nm=accp_nm/d23t07 if decena==7
replace accp_nm=accp_nm/d23t07 if decena==8
replace accp_nm=accp_nm/d23t08 if decena==9
replace accp_nm=accp_nm/d23t08 if decena==0

*Gasto en Otros gastos y transferencias deflactado (semestral)

gen otr_nm=gasnomon if (clave>="N001" & clave<="N002") | (clave>="N006" & clave<="N016") | (clave>="T901" & clave<="T915") | (clave=="R012")

replace otr_nm=otr_nm/dINPCs02 if decena==1
replace otr_nm=otr_nm/dINPCs02 if decena==2
replace otr_nm=otr_nm/dINPCs03 if decena==3
replace otr_nm=otr_nm/dINPCs03 if decena==4
replace otr_nm=otr_nm/dINPCs03 if decena==5
replace otr_nm=otr_nm/dINPCs04 if decena==6
replace otr_nm=otr_nm/dINPCs04 if decena==7
replace otr_nm=otr_nm/dINPCs04 if decena==8
replace otr_nm=otr_nm/dINPCs05 if decena==9
replace otr_nm=otr_nm/dINPCs05 if decena==0

*Gasto en Regalos Otorgados deflactado

gen reda_nm=gasnomon if (clave>="T901" & clave<="T915") | (clave=="N013")

replace reda_nm=reda_nm/dINPCs02 if decena==1
replace reda_nm=reda_nm/dINPCs02 if decena==2
replace reda_nm=reda_nm/dINPCs03 if decena==3
replace reda_nm=reda_nm/dINPCs03 if decena==4
replace reda_nm=reda_nm/dINPCs03 if decena==5
replace reda_nm=reda_nm/dINPCs04 if decena==6
replace reda_nm=reda_nm/dINPCs04 if decena==7
replace reda_nm=reda_nm/dINPCs04 if decena==8
replace reda_nm=reda_nm/dINPCs05 if decena==9
replace reda_nm=reda_nm/dINPCs05 if decena==0


save "$ruta\ingresonomonetario_def24.dta", replace

use "$ruta\ingresonomonetario_def24.dta", clear

*Construcción de la base de pagos en especie a partir de la base 
*de gasto no monetario

keep if esp==1

*collapse (sum) *_nm, by(proyecto folioviv foliohog)

collapse (sum) *_nm edu_gtosnm , by(folioviv foliohog)

rename  ali_nm ali_nme
rename  alta_nm alta_nme
rename  veca_nm veca_nme
rename  viv_nm viv_nme
rename  lim_nm lim_nme
rename  cris_nm cris_nme
rename  ens_nm ens_nme
rename  sal_nm sal_nme
rename  tpub_nm tpub_nme
rename  tfor_nm tfor_nme
rename  com_nm com_nme 
rename  edu_gtosnm edu_gtosnme
rename  edre_nm edre_nme
rename  edba_nm edba_nme
rename  cuip_nm cuip_nme
rename  accp_nm accp_nme
rename  otr_nm otr_nme
rename  reda_nm reda_nme

*sort proyecto folioviv foliohog
sort folioviv foliohog
save "$ruta\esp_def24.dta", replace


*Construcción de base de regalos a partir de la base no monetaria

use "$ruta\ingresonomonetario_def24.dta", clear

keep if reg==1

*collapse (sum) *_nm, by(proyecto folioviv foliohog)
collapse (sum) *_nm edu_gtosnm , by(folioviv foliohog)

rename  ali_nm ali_nmr
rename  alta_nm alta_nmr
rename  veca_nm veca_nmr
rename  viv_nm viv_nmr
rename  lim_nm lim_nmr
rename  cris_nm cris_nmr
rename  ens_nm ens_nmr
rename  sal_nm sal_nmr
rename  tpub_nm tpub_nmr
rename  tfor_nm tfor_nmr
rename  com_nm com_nmr 
rename  edu_gtosnm edu_gtosnmr
rename  edre_nm edre_nmr
rename  edba_nm edba_nmr
rename  cuip_nm cuip_nmr
rename  accp_nm accp_nmr
rename  otr_nm otr_nmr
rename  reda_nm reda_nmr

*sort proyecto folioviv foliohog
sort folioviv foliohog

save "$ruta\reg_def24.dta", replace


*Modificación Mayra Saenz, Abril 2017

*Construcción de base de gasto monetario en educación

use "$ruta\ingresonomonetario_def24.dta", clear

*********************************************************

/*Creación del gasto monetario deflactado a pesos de 
agosto del 2024.*/

*********************************************************
*Modificado Mayra Saenz- Abril 2017
*Gasto monetario en educación

use "$ruta\gastoshogar.dta", clear

/*En el caso de la información de gasto no monetario, para 
deflactar se utiliza la decena de levantamiento de la 
encuesta, la cual se encuentra en la octava posición del 
folio de la vivienda. En primer lugar se obtiene una variable que 
identifique la decena de levantamiento*/

gen decena=real(substr(folioviv,8,1))

*Rubro 7 mensual, Educación y esparcimiento		
scalar d7m07=	0.9961413091
scalar d7m08=	1.0000000000
scalar d7m09=	1.0095233900
scalar d7m10=	1.0144128271
scalar d7m11=	1.0174522069
	

*Una vez definidos los deflactores, se seleccionan los rubros
/*
Valor Etiqueta
G1 Gasto monetario en bienes y servicios para el hogar
G2 Gasto monetario en bienes y servicios para otro hogar
G3 Gasto no monetario procedente de autoconsumo
G4 Gasto no monetario por remuneraciones en especie
G5 Gasto no monetario por regalos recibidos de otro hogar
G6 Gasto no monetario por transferencias de instituciones
G7 Gasto imputado por estimación del alquiler
*/

gen double gasmon=gasto_tri/3


keep if tipo_gasto=="G1" // Sólo gasto dentro del hogar

*Gasto monetario sólo educación
gen edu_gtosm=gasmon if (clave>="E001" & clave<="E021") | (clave>="H134" & clave<="H135") 

replace edu_gtosm=edu_gtosm/d7m07 if decena==0
replace edu_gtosm=edu_gtosm/d7m07 if decena==1
replace edu_gtosm=edu_gtosm/d7m08 if decena==2
replace edu_gtosm=edu_gtosm/d7m08 if decena==3
replace edu_gtosm=edu_gtosm/d7m08 if decena==4
replace edu_gtosm=edu_gtosm/d7m09 if decena==5
replace edu_gtosm=edu_gtosm/d7m09 if decena==6
replace edu_gtosm=edu_gtosm/d7m09 if decena==7
replace edu_gtosm=edu_gtosm/d7m10 if decena==8
replace edu_gtosm=edu_gtosm/d7m10 if decena==9


collapse (sum) edu_gtosm  , by(folioviv foliohog)

rename  edu_gtosm edu_gtosmh

*sort proyecto folioviv foliohog
sort folioviv foliohog

save "$ruta\edu_gtosmh", replace


*Gasto personas

use "$ruta\gastospersona.dta", clear

/*En el caso de la información de gasto no monetario, para 
deflactar se utiliza la decena de levantamiento de la 
encuesta, la cual se encuentra en la octava posición del 
folio de la vivienda. En primer lugar se obtiene una variable que 
identifique la decena de levantamiento*/

gen decena=real(substr(folioviv,8,1))

*Definición de los deflactores

*Rubro 7 mensual, Educación y esparcimiento		
scalar d7m07=	0.9961413091
scalar d7m08=	1.0000000000
scalar d7m09=	1.0095233900
scalar d7m10=	1.0144128271
scalar d7m11=	1.0174522069


*Una vez definidos los deflactores, se seleccionan los rubros
/*
Valor Etiqueta
G1 Gasto monetario en bienes y servicios para el hogar
G2 Gasto monetario en bienes y servicios para otro hogar
G3 Gasto no monetario procedente de autoconsumo
G4 Gasto no monetario por remuneraciones en especie
G5 Gasto no monetario por regalos recibidos de otro hogar
G6 Gasto no monetario por transferencias de instituciones
G7 Gasto imputado por estimación del alquiler
*/


gen double gasmon=gasto_tri/3


keep if tipo_gasto=="G1" // Sólo gasto dentro del hogar



*Gasto monetario sólo educación
gen edu_gtosm=gasmon if (clave>="E001" & clave<="E021") | (clave>="H134" & clave<="H135") 

replace edu_gtosm=edu_gtosm/d7m07 if decena==0
replace edu_gtosm=edu_gtosm/d7m07 if decena==1
replace edu_gtosm=edu_gtosm/d7m08 if decena==2
replace edu_gtosm=edu_gtosm/d7m08 if decena==3
replace edu_gtosm=edu_gtosm/d7m08 if decena==4
replace edu_gtosm=edu_gtosm/d7m09 if decena==5
replace edu_gtosm=edu_gtosm/d7m09 if decena==6
replace edu_gtosm=edu_gtosm/d7m09 if decena==7
replace edu_gtosm=edu_gtosm/d7m10 if decena==8
replace edu_gtosm=edu_gtosm/d7m10 if decena==9

sort folioviv foliohog numren
collapse (sum) edu_gtosm  , by(folioviv foliohog numren)

rename  edu_gtosm edu_gtosmp

*sort proyecto folioviv foliohog
sort folioviv foliohog

save "$ruta\edu_gtosmp", replace


*********************************************************

*Construcción del ingreso corriente total

*********************************************************

use "$ruta\concentradohogar.dta", clear

*keep proyecto folioviv foliohog tam_loc factor tot_integ est_dis upm ubica_geo


*Incorporación de la base de ingreso monetario deflactado
/*
sort folioviv foliohog

merge folioviv foliohog using "$ruta\ingreso_deflactado20_per.dta"
tab _merge
drop _merge
*/

*Incorporación de la base de ingreso no monetario deflactado: pago en especie

*sort proyecto folioviv foliohog
sort folioviv foliohog

*Se incorpora la base de hogares

merge 1:1 folioviv foliohog using "$ruta\hogares.dta"
tab _merge
drop _merge


preserve
use "$ruta\viviendas.dta", clear
describe combus

capture confirm numeric variable combus
if _rc {
    quietly destring combus, replace force   // si hay algún no-numérico quedará missing
}


tempfile viv_ok
save `viv_ok', replace
restore

merge m:1 folioviv using `viv_ok'
tab _merge
drop _merge

merge 1:1 folioviv foliohog using "$ruta\esp_def24.dta"
tab _merge
drop _merge

*Incorporación de la base de ingreso no monetario deflactado: regalos en especie

sort folioviv foliohog

merge 1:1 folioviv foliohog using "$ruta\reg_def24.dta"
tab _merge
drop _merge

gen rururb=1 if tam_loc=="4"
replace rururb=0 if tam_loc<="3"
label define rururb 1 "Rural" 0 "Urbano"
label value rururb rururb


egen double pago_esp=rsum(ali_nme alta_nme veca_nme viv_nme lim_nme ens_nme cris_nme sal_nme tpub_nme tfor_nme com_nme edre_nme cuip_nme accp_nme otr_nme)

egen double reg_esp=rsum(ali_nmr alta_nmr veca_nmr viv_nmr lim_nmr ens_nmr cris_nmr sal_nmr tpub_nmr tfor_nmr com_nmr edre_nmr cuip_nmr accp_nmr otr_nmr)

egen double nomon=rsum(pago_esp reg_esp)

egen double gtos_edu =rsum(edu_gtosnme edu_gtosnmr)


label var nomon "Ingreso corriente no monetario"
label var pago_esp "Ingreso corriente no monetario pago especie"
label var reg_esp "Ingreso corriente no monetario regalos especie"
label var gtos_edu "Gastos en Educación - ya están incluidos en pago_esp y reg_esp"

sort  folioviv foliohog

save "$ruta\ingresotot24.dta", replace

saveold "$ruta\gtos_autoc24.dta", replace

*--------------------------------------------*
*Base de Trabajos
*--------------------------------------------*

*nivel de personas, (hacer reshape )
use "$ruta\trabajos.dta",clear
	*Alvaro AM 2019, lo que antes era pres_1/pres_6 ahora es medtrab_#
	keep folioviv foliohog numren id_trabajo  trapais subor indep personal pago contrato tipocontr htrab sinco scian clas_emp tam_emp no_ing tiene_suel pres_* medtrab_*
	egen per = concat(folioviv foliohog numren)
	rename pres_1 pres_0
	reshape wide trapais subor indep personal pago contrato tipocontr htrab sinco scian clas_emp tam_emp no_ing tiene_suel pres_* medtrab_*, i(per) j(id_trabajo) string
	rename pres_01 pres_11
	rename pres_02 pres_12
	
	foreach var of varlist trapais1 subor1 indep1 personal1 pago1 contrato1 tipocontr1 htrab1 sinco1 scian1 clas_emp1 tam_emp1 no_ing1 tiene_suel1 ///
	pres_11 pres_21 pres_31 pres_41 pres_51 pres_61 pres_71 pres_81 pres_91 pres_101 pres_111 pres_121 pres_131 pres_141 pres_151 pres_161 pres_171 pres_181 pres_191 pres_201 ///
	medtrab_11 medtrab_21 medtrab_31 medtrab_41 medtrab_51 medtrab_61 medtrab_71 {
	    label var `var' "`var' del primer trabajo"
	}
	foreach var of varlist trapais2 subor2 indep2 personal2 pago2 contrato2 tipocontr2 htrab2 sinco2 scian2 clas_emp2 tam_emp2 no_ing2 tiene_suel2 ///
	pres_12 pres_22 pres_32 pres_42 pres_52 pres_62 pres_72 pres_82 pres_92 pres_102 pres_112 pres_122 pres_132 pres_142 pres_152 pres_162 pres_172 pres_182 pres_192 pres_202 ///
	 medtrab_12 medtrab_22 medtrab_32 medtrab_42 medtrab_52 medtrab_62 medtrab_72  {
	    label var `var' "`var' del segundo trabajo"
	}
		
	drop per
	sort  folioviv foliohog numren
	saveold "$ruta\trabajos_reshape.dta", replace

*_________________________________________________________________________________________________________*
* Modificación Mayra Sáenz: Se unifica con la base de personas con la de ingresos, de vivienda y de gastos
*_________________________________________________________________________________________________________*


use "$ruta\poblacion.dta", clear //Base nueva
gen str folio= folioviv + foliohog
order folio, first
sort folio numren, stable

merge 1:1 folioviv foliohog numren using "$ruta\trabajos_reshape.dta", keep (match master)
drop _merge

merge 1:1 folio numren using "$ruta\ingreso_deflactado24_per.dta", keep (match master)
rename _merge _merge_inge
sort folio numren, stable

merge m:1 folioviv foliohog numren using "$ruta\edu_gtosmp.dta", keep (match master)
drop _merge

merge m:1 folioviv foliohog using "$ruta\gtos_autoc24.dta", keep (match master)
drop _merge

merge m:1 folioviv foliohog using "$ruta\edu_gtosmh.dta", keep (match master)
drop _merge

*Modificación Mayra Sáenz: Total Ingreso monetario del hogar
bys folio: egen ing_monh = sum(ing_mon)

egen double ict=rsum(ing_monh nomon)  if parentesco=="101" | parentesco=="102" //Mayra Sáenz Agosto 2015 - Aumento esta condición porque esta base está a nivel de personas

label var  ict "Ingreso corriente total"


 global survey_folder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"
                           
local PAIS MEX
local ENCUESTA ENIGH
local ANO "2024"
local ronda m8_m12

local base_out  "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"

saveold "`base_out'", replace

log close



