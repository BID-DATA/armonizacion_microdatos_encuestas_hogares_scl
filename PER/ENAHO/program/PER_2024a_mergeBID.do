
/***************************************************************************
                 BASES DE DATOS DE ENCUESTA DE HOGARES 
Pais: Peru
Encuesta: ENAHO
Round: a
Autores: 

							 IADB
****************************************************************************/
****************************************************************************/
global surveysFolder "D:\Dropbox\BID\BID2025_Pepe\Tarea1_Excel\8_Peru_2024"


clear all
set more off
global ruta = "${surveysFolder}\survey\PER\ENAHO\2024\a\data_orig"
global out ="${surveysFolder}\survey\PER\ENAHO\2024\a\data_merge"

*Equipamiento del hogar
use "$ruta\966-Modulo18\966-Modulo18\enaho01-2024-612.dta" , clear
keep conglome vivienda hogar p612 p612n
reshape wide p612, i(conglome vivienda hogar) j(p612n)

/*
1	radio
2	tv. a color
3	tv. blanco y negro
4	equipo de sonido
5	dvd
6	video grabadora
7	computadora
8	plancha
9	licuadora
10	cocina a gas
11	cocina a kerosene
12	refrigeradora/congeladora
13	lavadora
14	horno microondas
15	máquina de coser
16	bicicleta
17	auto, camioneta
18	motocicleta
19	triciclo
20	mototaxi
21	camión
22	otro
23	otro
24	otro
25	otro
26	otro
27	otro
28  tablet
*/

label var p6121 "Su hogar tiene: radio"
label var p6122 "Su hogar tiene: tv. a color"
label var p6123 "Su hogar tiene: tv. blanco y negro"
label var p6124 "Su hogar tiene: equipo de sonido"
label var p6125 "Su hogar tiene: dvd"
label var p6126 "Su hogar tiene: video grabadora"
label var p6127 "Su hogar tiene: computadora"
label var p6128 "Su hogar tiene: plancha"
label var p6129 "Su hogar tiene: licuadora"
label var p61210 "Su hogar tiene: cocina a gas"
label var p61211 "Su hogar tiene: cocina a kerosene"
label var p61212 "Su hogar tiene: refrigeradora/congeladora"
label var p61213 "Su hogar tiene: lavadora"
label var p61214 "Su hogar tiene: horno microondas"
label var p61215 "Su hogar tiene: máquina de coser"
label var p61216 "Su hogar tiene: bicicleta"
label var p61217 "Su hogar tiene: auto, camioneta"
label var p61218 "Su hogar tiene: motocicleta"
label var p61219 "Su hogar tiene: triciclo"
label var p61220 "Su hogar tiene: mototaxi"
label var p61221 "Su hogar tiene: camión"
label var p61222 "Su hogar tiene: otro"
label var p61223 "Su hogar tiene: otro"
label var p61224 "Su hogar tiene: otro"
label var p61225 "Su hogar tiene: otro"
label var p61226 "Su hogar tiene: otro"
label var p61227 "Su hogar tiene: otro"
label var p61228 "Su hogar tiene: tablet"

saveold "$ruta\966-Modulo18\966-Modulo18\enaho01-2024-612_1.dta", replace

* Merge de bases de datos

clear
use "$ruta\966-Modulo01\966-Modulo01\enaho01-2024-100.dta", clear // Características de la Vivienda y del Hogar 
keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	sort conglome vivienda hogar
	merge 1:m conglome vivienda hogar using "$ruta\966-Modulo04\966-Modulo04\enaho01a-2024-400.dta" // Salud 
	tab _merge
	tab result, m
	drop _merge

	sort conglome vivienda hogar codperso
	merge 1:1 conglome vivienda hogar codperso using "$ruta\966-Modulo02\966-Modulo02\enaho01-2024-200.dta" //  	Características de los Miembros del Hogar 
	tab _merge
	tab result, m
	tab _merge result, m
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	drop _merge

	sort conglome vivienda hogar codperso
	merge 1:1 conglome vivienda hogar codperso using "$ruta\966-Modulo03\966-Modulo03\enaho01a-2024-300.dta" //  	Educación - este módulo no le pregunta a personas con menos de 3 años - por lo que tiene menos observaciones
	tab _merge
	tab result, m
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	drop _merge

	sort conglome vivienda hogar codperso
	merge 1:1 conglome vivienda hogar codperso using "$ruta\966-Modulo05\966-Modulo05\enaho01a-2024-500.dta" //  	Empleo e Ingresos - este módulo no le pregunta a personas con menos de 14 años - por lo que tiene menos observaciones
	tab _merge
	tab result, m
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	drop _merge

	sort conglome vivienda hogar
	merge m:1 conglome vivienda hogar  using "$ruta\966-Modulo34\966-Modulo34\sumaria-2024.dta" //Sumarias ( Variables Calculadas ) 
	tab _merge
	tab result, m 
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	drop _merge

	sort conglome vivienda hogar
	merge m:1 conglome vivienda hogar using "$ruta\966-Modulo18\966-Modulo18\enaho01-2024-612_1.dta" //  	Equipamiento del Hogar 
	tab _merge
	tab result, m 
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/
	drop _merge
	
	keep if result==1 | result==2 /* Nos quedamos solo con Encuestas completas e incompletas*/

	capture drop if p203 ==0 /* p203:  	�cual es la relacion de parentesco con el jefe(a) del  hogar?	*/
    /* No hay valor cero - no hay p203 ==0 -- todas las personas identifican su relacion con el jefe del hogar - familiar o no */
	
saveold "$out\PER_2024a.dta", replace

 