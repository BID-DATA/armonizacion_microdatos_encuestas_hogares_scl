*****************************************************
* ENIGH MEX 2012 (m8–m12) - Construcción + Diagnóstico (robusto)
* - Crea idh_ch si falta (egen, group())
* - Usa overrides para pesos (factor_hog para CI y CH)
* - Llave idh_ch numren, filtra no-persona, guarda y diagnostica
* Autor: María Alejandra
*****************************************************

clear all
set more off

* ====== RUTAS (ajusta si difieren) ======
global ROOT "C:\Users\maria\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"
global RAW  "$ROOT\MEX\ENIGH\data_raw\2012\MEX_2012m8_m12.dta"
global ARM  "$ROOT\MEX\ENIGH\data_arm\MEX_2012m8_m12_BID.dta"
global OUT  "$ROOT\output"

cap mkdir "$OUT"
log using "$OUT\build_and_check_MEX_2012.log", replace

* ====== OVERRIDES MANUALES (USAR ESTOS PARA 2012) ======
* En esta ronda usaremos el factor del hogar para ambos:
global OV_IND "factor_hog"   // peso individual (usamos factor del hogar)
global OV_HOG "factor_hog"   // peso del hogar

di as res "=== PASO A: Abrir CRUDO 2012 y detectar/crear IDs ==="
use "$RAW", clear

* ---- Verificar/asegurar numren (ID persona) ----
capture confirm variable numren
if _rc {
    di as error "FALTA 'numren' (ID persona) en CRUDO. Revisa el dataset."
    log close
    exit 459
}
capture confirm string variable numren
if !_rc destring numren, replace force

* ---- Verificar o CONSTRUIR idh_ch (ID hogar) ----
capture confirm variable idh_ch
if _rc {
    local built = 0

    * Opción A (ENIGH típico): folioviv + foliohog
    capture confirm variable folioviv
    if !_rc {
        capture confirm variable foliohog
        if !_rc {
            capture drop idh_ch
            egen long idh_ch = group(folioviv foliohog)
            label var idh_ch "ID hogar (folioviv+foliohog)"
            local built = 1
        }
    }

    * Opción B (alternativa ENIGH): folio + upm + ent + con + tam_loc + r_def
    if `built'==0 {
        capture confirm variable folio
        capture confirm variable upm
        capture confirm variable ent
        capture confirm variable con
        capture confirm variable tam_loc
        capture confirm variable r_def
        if (!_rc) {
            capture drop idh_ch
            egen long idh_ch = group(folio upm ent con tam_loc r_def)
            label var idh_ch "ID hogar (folio+upm+ent+con+tam_loc+r_def)"
            local built = 1
        }
    }

    if `built'==0 {
        di as error "No pude construir 'idh_ch'. Revisa nombres (p. ej. folioviv/foliohog)."
        log close
        exit 459
    }
}
capture confirm string variable idh_ch
if !_rc destring idh_ch, replace force

di as res "=== PASO B: Detectar ponderadores y edad (CRUDO) ==="
lookfor peso ponder factor fac wgt weight edad age

* ---------- Overrides: úsalos directamente ----------
local ind_weight = trim("`=lower("$OV_IND")'")
local hog_weight = trim("`=lower("$OV_HOG")'")

* Verifica que existan y sean numéricos
local missing_any 0
if "`ind_weight'"=="" {
    di as error "Override de IND vacío. Define global OV_IND."
    local missing_any 1
}
else {
    capture confirm numeric variable `ind_weight'
    if _rc {
        di as error "Override IND '`ind_weight'' no existe o no es numérico."
        local missing_any 1
    }
}
if "`hog_weight'"=="" {
    di as error "Override de HOG vacío. Define global OV_HOG."
    local missing_any 1
}
else {
    capture confirm numeric variable `hog_weight'
    if _rc {
        di as error "Override HOG '`hog_weight'' no existe o no es numérico."
        local missing_any 1
    }
}

* Detectar variable de EDAD numérica (auto)
local edad_var ""
foreach e in edad edad_ci eda age edadin edadtot {
    capture confirm numeric variable `e'
    if !_rc {
        local edad_var "`e'"
        continue, break
    }
}
if "`edad_var'"=="" {
    di as error "No se detectó variable de EDAD numérica en crudo."
    local missing_any 1
}

if `missing_any' {
    di as txt "==> Revisa el log y ajusta overrides si es necesario."
    log close
    exit 498
}

di as res "=== PASO C: Armonizar en memoria (llave idh_ch numren) ==="

* 1) Mantener SOLO PERSONAS
count if missing(numren)
di as txt "Filas sin numren (se eliminarán): " r(N)
drop if missing(numren)

* 2) Verificar unicidad de la llave persona-hogar; si no, quedarse con la primera
capture isid idh_ch numren
if _rc {
    di as txt "idh_ch numren NO es única; se conservará la primera observación por persona."
    sort idh_ch numren
    by idh_ch numren: gen __dup = _n
    drop if __dup > 1
    drop __dup
    capture isid idh_ch numren
    if _rc di as error "Aún no única; continúa pero revisa módulos crudos."
}
di as res "Llave persona-hogar lista: idh_ch numren"

* 3) Crear variables armonizadas (factores y edad)
capture drop factor_ci factor_ch edad_ci
gen double factor_ci = `ind_weight'
gen double factor_ch = `hog_weight'
gen int    edad_ci   = `edad_var'

* 4) Revisiones rápidas (info)
cap sum factor_ci
cap sum factor_ch
cap sum edad_ci

* 5) Guardar ARMONIZADA
order idh_ch numren factor_ci factor_ch edad_ci, first
compress
save "$ARM", replace
di as res "Guardada ARMONIZADA: $ARM"

di as res "=== PASO D: Diagnóstico final ==="
use "$ARM", clear

foreach v in factor_ci factor_ch edad_ci {
    capture confirm variable `v'
    if _rc di as error "`v' NO existe en ARMONIZADA."
    else {
        count if missing(`v')
        di as res "`v' -> " r(N) " missings de " _N
        cap tabstat `v', stats(n min p1 p5 p50 p95 p99 max)
    }
}

capture drop m_factor has_numr
gen byte m_factor = missing(factor_ci)
gen byte has_numr = !missing(numren)
tab m_factor has_numr, missing

capture isid idh_ch numren
if _rc di as txt "ARMO: idh_ch numren NO es única. Revisa merges."
else   di as res "ARMO: idh_ch numren es llave única (OK)."

log close
di as res "Proceso terminado. Revisa: $OUT\build_and_check_MEX_2012.log

