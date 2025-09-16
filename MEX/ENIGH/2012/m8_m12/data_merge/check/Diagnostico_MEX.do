********************************************************************************
* ENIGH MEX 2012 m8–m12 — Diagnóstico de factores y agregados (ANTES vs DESPUÉS)
********************************************************************************

version 12
clear all
set more off

* === RUTAS (las que pediste) ===
global ruta   "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl\MEX\ENIGH\2012\m8_m12\data_merge"
local base_in  "$ruta\MEX_2012m8_m12_BID_original.dta"
local base_out "$ruta\MEX_2012m8_m12_BID.dta"
local audit    "$ruta\check\audit_ENIGH2012_m8m12.csv"

* === VARIABLES DE INTERÉS ===
local vnum  peso factor_hog factor_ch factor_ci edad edad_ci
local vagg  autocons pago_esp reg_esp est_alq redan reg_espn
* Unir todo en un solo macro para evitar el r(100)
local allvars `vnum' `vagg'

********************************************************************************
* A) DIAGNÓSTICO EN BASE ORIGINAL
********************************************************************************
display as text "=== A) DIAGNÓSTICO EN BASE ORIGINAL ========================"
capture noisily use "`base_in'", clear
if _rc {
    di as error "No pude abrir: `base_in'  (rc=_rc). Revisa la ruta."
    exit _rc
}

display as text "Variables presentes en la base original:"
foreach v of local allvars {
    capture confirm variable `v'
    if _rc {
        display as error " - FALTA: `v'"
    }
    else {
        display as result " - OK: `v'"
    }
}

* A2) Faltantes y tipo (string/num) en la ORIGINAL
tempfile A_before
tempname mem_before
postfile `mem_before' str32 varname long miss_before byte str_before using `A_before', replace

foreach v of local allvars {
    capture confirm variable `v'
    if !_rc {
        quietly count if missing(`v')
        local miss = r(N)
        capture confirm string variable `v'
        local isstr = cond(_rc==0, 1, 0)   // 1=string, 0=numérico
        post `mem_before' ("`v'") (`miss') (`isstr')
    }
}
postclose `mem_before'

********************************************************************************
* B) PRUEBA EN BASE FIXED (SOLUCIÓN)
********************************************************************************
display as text "=== B) PRUEBA EN BASE FIXED ================================"
capture noisily use "`base_out'", clear
if _rc {
    di as error "No pude abrir: `base_out'  (rc=_rc). Revisa la ruta."
    exit _rc
}

* B1) Ninguna de estas debe ser string (autocons/pago_esp/reg_esp/est_alq/redan/reg_espn)
ds `vagg', has(type string)
local str_list_after `r(varlist)'
if "`str_list_after'" != "" {
    display as error "ERROR: aún hay strings en FIXED: `str_list_after'"
}
else {
    display as result "Tipos OK en FIXED: autocons, pago_esp, reg_esp, est_alq, redan, reg_espn son numéricas."
}

* B2) Faltantes (reporte)
foreach v of local allvars {
    capture confirm variable `v'
    if !_rc {
        quietly count if missing(`v')
        display as text "Missing `v' (FIXED): " %12.0g r(N)
    }
}

* B3) Medición en la FIXED
tempfile B_after
tempname mem_after
postfile `mem_after' str32 varname long miss_after byte str_after using `B_after', replace

foreach v of local allvars {
    capture confirm variable `v'
    if !_rc {
        quietly count if missing(`v')
        local miss = r(N)
        capture confirm string variable `v'
        local isstr = cond(_rc==0, 1, 0)
        post `mem_after' ("`v'") (`miss') (`isstr')
    }
}
postclose `mem_after'

********************************************************************************
* C) TABLA COMPARATIVA (ANTES vs DESPUÉS) Y RESUMEN
********************************************************************************
* C1) Guardar “antes” y “después” como datasets temporales
preserve
    use `A_before', clear
    tempfile A
    save `A'
restore

preserve
    use `B_after', clear
    tempfile B
    save `B'
restore

* C2) Unir y exportar a CSV
use `A', clear
sort varname
merge 1:1 varname using `B', nogen keep(match)

order varname miss_before miss_after str_before str_after
export delimited using "`audit'", replace
display as result "Archivo de auditoría creado: `audit'"

* C3) Resumen visible en consola para variables clave
display as text "=== RESUMEN RÁPIDO =========================================="

list varname miss_before miss_after str_before str_after ///
    if varname=="peso"        | varname=="factor_hog"  | varname=="factor_ch" ///
    | varname=="factor_ci"    | varname=="edad"        | varname=="autocons"   ///
    | varname=="pago_esp"     | varname=="reg_esp"     | varname=="est_alq"    ///
    | varname=="redan"        | varname=="reg_espn", ///
    noobs abbreviate(16)


	
display as text "Si miss_after==0 para factores/peso/edad y str_after==0 para agregados, el problema está resuelto."
display as text "=============================================================="
