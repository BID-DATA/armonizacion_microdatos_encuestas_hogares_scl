/***************************************************************************
							Encuesta Haiti
			 Script de merge - Unión de módulos en una sola base 
País: Haiti
Año: 2012
Autores: Alvaro Altamirano 24OCT2017
Midificación: varios de SCL 27MAY2025
División: SCL/SCL- IADB
****************************************************************************/

clear all
set more off

/****************************************************************************
   I. Definir rutas y log file
****************************************************************************/

global ruta = "${surveysFolder}"

local PAIS HTI
local ENCUESTA ECVMAS
local ANO "2012"
local ronda m8_m12

local log_file = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\log\\`PAIS'_`ANO'`ronda'_mergeBID.log"
local base_in  = "$ruta\survey\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig\"
local base_out = "$ruta\harmonized\\`PAIS'\\`ENCUESTA'\data_arm\\`PAIS'_`ANO'`ronda'_BID.dta"
   
capture log close
log using "`log_file'", replace 

set more off

***************************************
***II. Preparar módulos de ingresos****
***************************************

cd "`base_in'\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\"

*** módulo 70_mod_j3_ok Remuneracion especies
*********************************************
import spss using "Z:\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\70_mod_j3_ok", clear

** I_J24G Pour le mois dernier, à combien estimez-vous la valeur en gourdes de ce que vou
** I_J24G Para el mes pasado, ¿a cuánto estima usted el valor en gourdes de lo que usted...?"
gen _I_J24G = I_J24G
replace _I_J24G =. if I_J24G<0 // quito negativos que no responden: "Refus de réponse"  y "Ne sait pas (no sabe)"
replace _I_J24G = 749.5 if I_J24G==-8 & I_J24H ==2   //rango de ingreso: De 500 à 999 gourdes
replace _I_J24G = 2499.5 if I_J24G==-8 & I_J24H ==4   //rango de ingreso: De 2,000 à 2,999 gourdes
replace _I_J24G = 500 if I_J24G==-9 & I_J24H ==1   // Moins de 500 gourdes Menos de 500

collapse(sum) ylnm_gourdres =_I_J24G, by(i_id1new  I_ID3)
rename I_ID3 i_id3
save _ylnm_gourdres_individuo.dta, replace

*** módulo 69_mod_j2_ok Remuneracion efectivo
*********************************************
import spss using "Z:\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\69_mod_j2_ok", clear
gen _I_J24D = I_J24D
replace _I_J24D =. if I_J24D<0 // quito negativos que no responden: "Refus de réponse"  y "Ne sait pas (no sabe)"

replace _I_J24D  = I_J24D*160 if I_J24D>0 &  I_J24B== 1  //hora (8h*5dias*4sem)
replace _I_J24D  = I_J24D*365/12 if I_J24D>0 &  I_J24B == 2  //dia
replace _I_J24D  = I_J24D*52/12 if I_J24D>0 &  I_J24B == 3  //semana
replace _I_J24D  = I_J24D*2 if I_J24D>0 &  I_J24B == 4  //cada quincena
replace _I_J24D  = I_J24D/12 if I_J24D>0 &  I_J24B == 6  //año

replace _I_J24D  = 1499.5 if I_J24D<0 &  I_J24E == 3  //De 1,000 à 1,999 gourdes
replace _I_J24D  = 2499.5 if I_J24D<0 &  I_J24E == 4  //De 2,000 à 2,999 gourdes
replace _I_J24D  = 3999.5 if I_J24D<0 &  I_J24E == 5  //De 3,000 à 4,999 gourdes
replace _I_J24D  = 6249.5 if I_J24D<0 &  I_J24E == 6  //De 5,000 à 7,499 gourdes
replace _I_J24D  = 8749.5 if I_J24D<0 &  I_J24E == 7  //De 7,500 à 9,999 gourdes
replace _I_J24D  = 12499.5 if I_J24D<0 &  I_J24E == 8  //De 10,000 à 14,999 gourdes
replace _I_J24D  = 17499.5 if I_J24D<0 &  I_J24E == 9  //De 15,000 à 19,999 gourdes
replace _I_J24D  = 39999.5 if I_J24D<0 &  I_J24E == 11 //De 30,000 à 49,999 gourdes
replace _I_J24D  = 50000*1.2 if I_J24D<0 &  I_J24E == 12  //50,000 gourdes ou plus
sort I_J24D

collapse(sum) ylnm_gourdres =_I_J24D, by(i_id1new  I_ID3)
rename I_ID3 i_id3
save _ylm_gourdres_individuo.dta, replace

******módulo 24_mod_r2_ok 
*************************
import spss using "Z:\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\24_mod_r2_ok.sav", clear

replace HH_R03A = . if HH_R03A<0

gen ynlnm_ch_0=.
replace ynlnm_ch_0 = HH_R03A*52/12 if HH_R04==1
replace ynlnm_ch_0 = HH_R03A*2 if HH_R04==2
replace ynlnm_ch_0 = HH_R03A*1 if HH_R04==3
replace ynlnm_ch_0 = HH_R03A/2 if HH_R04==4
replace ynlnm_ch_0 = HH_R03A/3 if HH_R04==5
replace ynlnm_ch_0 = HH_R03A/12 if HH_R04>=6 & HH_R04<=10

gen ynlnm_ch_0_gourdres = ynlnm_ch_0*41.63 if HH_R03B==3 
replace ynlnm_ch_0_gourdres = ynlnm_ch_0*5 if HH_R03B==2
replace ynlnm_ch_0_gourdres = ynlnm_ch_0*41.63*1.29 if HH_R03B==4

collapse(sum) ynlnm_ch_0_gourdres, by(hh_id2new)
save _ynlnm_ch_0_gourdres.dta, replace

* módulo 25_mod_r3_ok trabjanado con transferencias en especies
***************************************************************
import spss using "Z:\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\25_mod_r3_ok.sav", clear

gen ynlnm_ch_1=.
replace ynlnm_ch_1 = HH_R09B/12 if HH_R09B>0

gen ynlnm_ch_1_gourdres = ynlnm_ch_1*41.63 if HH_R09C==3 
replace ynlnm_ch_1_gourdres = ynlnm_ch_1*5 if HH_R09C==2
replace ynlnm_ch_1_gourdres = ynlnm_ch_1*41.63*1.29 if HH_R09C==4

collapse(sum) ynlnm_ch_1_gourdres, by(hh_id2new)
save _ynlnm_ch_1_gourdres.dta, replace


* 75_mod_O1_ok.sav
***************************************************************
import spss using "Z:\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\75_mod_O1_ok.sav", clear

gen ynlnm_ch_2=.
replace ynlnm_ch_2 = I_O01C*365/12 if I_O01C>0 & I_O01B == 1
replace ynlnm_ch_2 = I_O01C*52/12 if I_O01C>0 & I_O01B == 2
replace ynlnm_ch_2 = I_O01C*2 if I_O01C>0 & I_O01B == 3
replace ynlnm_ch_2 = I_O01C*1 if I_O01C>0 & I_O01B == 4
replace ynlnm_ch_2 = I_O01C/3 if I_O01C>0 & I_O01B == 5
replace ynlnm_ch_2 = I_O01C/12 if I_O01C>0 & I_O01B == 6

gen ynlnm_ch_2_gourdres = ynlnm_ch_2
gen hh_id2new = i_id2new  //id_hogar?
collapse(sum) ynlnm_ch_2_gourdres, by(hh_id2new)

save _ynlnm_ch_2_gourdres.dta, replace

***********************
******III. merge ******
***********************

use "`base_in'\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\Hogares2012.dta", clear
sort hh_id2new
merge 1:1 hh_id2new using _ynlnm_ch_0_gourdres.dta
drop _merge
merge 1:1 hh_id2new using _ynlnm_ch_2_gourdres.dta
drop _merge
merge 1:1 hh_id2new using _ynlnm_ch_1_gourdres.dta
drop _merge

merge 1:m hh_id2new using "${surveysFolder}\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\Individuos2012.dta"
drop _merge
merge m:1 hh_id2new using "${surveysFolder}\survey\HTI\ECVMAS\2012\m8_m12\data_orig\ECVMAS 2012\2_ECVMAS_BASE DE DONNEES\pesos2012.dta", gen(mergepesos)
merge m:1 i_id1new  i_id3 using _ylm_gourdres_individuo.dta
/*
tab _merge
    Result                      Number of obs
    -----------------------------------------
    Not matched                        13,603
        from master                    13,602  (_merge==1)
        from using                          1  (_merge==2)

    Matched                            10,173  (_merge==3)
    -----------------------------------------
*/
drop if _merge ==2   //1 obs se borra
drop _merge

merge m:1 i_id1new i_id3 using _ylnm_gourdres_individuo.dta
/*

    Result                      Number of obs
    -----------------------------------------
    Not matched                        13,645
        from master                    13,644  (_merge==1)
        from using                          1  (_merge==2)

    Matched                            10,131  (_merge==3)
    ----------------------------------------- */

drop if _merge ==2   //1 obs se borra
drop _merge

compress
save "${surveysFolder}\survey\HTI\ECVMAS\2012\m8_m12\data_merge\HTI_2012m8_m12.dta", replace

log close







