****************************************************
* Diagnóstico de Factores de Expansión y Variables
* ENIGH MEX 2012 (m8–m12)
****************************************************

* --- 0) Definir rutas
global ruta   "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl\MEX\ENIGH\2012\m8_m12\data_merge"
local base_in  "$ruta\MEX_2012m8_m12_BID_original.dta"
local base_out "$ruta\MEX_2012m8_m12_BID.dta"
local audit    "$ruta\check\audit_ENIGH2012_m8m12.csv"

* --- 1) Variables a diagnosticar
local vagg peso factor_hog factor_ch factor_ci edad autocons pago_esp reg_esp est_alq redan reg_espn

****************************************************
* A) DIAGNÓSTICO EN BASE ORIGINAL
****************************************************
display as text "=== A) Diagnóstico en la base ORIGINAL ==="
use "`base_in'", clear

* A1. Chequeo de existencia de variables
foreach v of local vagg {
    capture confirm variable `v'
    if _rc {
        display as error " - FALTA: `v'"
    }
    else {
        display as result " - OK: `v'"
    }
}

* A2. Contar faltantes y verificar si son string
tempfile before
postfile mem_before str32 varname int miss_before byte str_before using "`before'", replace
foreach v of local vagg {
    capture confirm variable `v'
    if !_rc {
        quietly count if missing(`v')
        local miss = r(N)
        capture confirm string variable `v'
        local isstr = cond(_rc==0,1,0)
        post mem_before ("`v'") (`miss') (`isstr')
    }
}
postclose mem_before

****************************************************
* B) DIAGNÓSTICO EN BASE FIXED
****************************************************
display as text "=== B) Diagnóstico en la base FIXED ==="
use "`base_out'", clear

tempfile after
postfile mem_after str32 varname int miss_after byte str_after using "`after'", replace
foreach v of local vagg {
    capture confirm variable `v'
    if !_rc {
        quietly count if missing(`v')
        local miss = r(N)
        capture confirm string variable `v'
        local isstr = cond(_rc==0,1,0)
        post mem_after ("`v'") (`miss') (`isstr')
    }
}
postclose mem_after

****************************************************
* C) COMPARACIÓN ANTES / DESPUÉS
****************************************************
use "`before'", clear
merge 1:1 varname using "`after'"
drop _merge

* Exportar CSV con evidencia
export delimited using "`audit'", replace

* Mostrar tabla principal en pantalla
list varname miss_before miss_after str_before str_after, noobs abbreviate(16)
