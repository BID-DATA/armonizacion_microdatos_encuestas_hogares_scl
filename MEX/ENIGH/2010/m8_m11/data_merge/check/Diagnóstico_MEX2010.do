*============================================*
* ENIGH 2010 (MEX m8_m11) - Diagnóstico factores y edad

   global ruta "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"

   local  base_out  "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"

* Si no los tienes aún, descomenta y ajusta:
 global survey_folder "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"
 local  PAIS MEX
 local  ENCUESTA ENIGH
 local  ANO "2010"
 local  ronda m8_m11
 global ruta "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_orig"
 local  base_out  "$survey_folder\\`PAIS'\\`ENCUESTA'\\`ANO'\\`ronda'\data_merge\\`PAIS'_`ANO'`ronda'.dta"
*============================================*

version 12
clear all
set more off

capture log close
log using "$survey_folder\\log\\`PAIS'\\`ENCUESTA'\\`PAIS'_`ANO'`ronda'_diag_factores.log", replace text

di as txt "=========== DIAGNOSTICO ENIGH 2010 MEX m8_m11 ==========="

*------------------------------------------------------------*
* 0) Comprobación de archivos necesarios
*------------------------------------------------------------*
local need "Concen.dta Hogares.dta Pobla10.dta trabajos.dta"
foreach f of local need {
    capture confirm file "$ruta\\`f'"
    if _rc {
        di as error "FALTA archivo: $ruta\\`f'"
    }
    else di as result "OK: `f' encontrado."
}

*------------------------------------------------------------*
* 1) Verificación del ponderador en HOGARES/CONCEN
*    y llaves mínimas
*------------------------------------------------------------*
preserve
    use "$ruta\\Concen.dta", clear
    * llaves y ponderador
    capture confirm variable folioviv
    if _rc {
        di as error "Concen.dta: falta variable folioviv"
    }
    capture confirm variable foliohog
    if _rc {
        di as error "Concen.dta: falta variable foliohog"
    }
    capture confirm variable factor
    if _rc {
        di as error "Concen.dta: falta variable factor"
    }

    * Chequeos rápidos
    egen __folio = concat(folioviv foliohog)
    count if missing(factor)
    di as text "Concen.dta -> hogares con factor missing: " %12.0g r(N)
    quietly duplicates report __folio
    di as text "Concen.dta -> hogares duplicados por (folioviv foliohog): " %9.0g r(N)

    * Muestra de casos con factor faltante (si existiesen)
    if r(N)>0 | r(N)==. {
        list folioviv foliohog factor in 1/10 if missing(factor), noobs abbreviate(12)
    }
restore

*------------------------------------------------------------*
* 2) Verifica que el producto de mergeBID (base_out) exista
*    y contenga factor correctamente propagado al nivel persona
*------------------------------------------------------------*
capture confirm file "`base_out'"
if _rc {
    di as error "No se encuentra base_out: `base_out'"
    di as error "Corre primero tu do de MERGE (mergeBID.do) para crearla."
    * Continuamos con chequeos de rescate de todos modos
}

if !_rc {
    use "`base_out'", clear
    di as txt "Cargado base_out: `base_out'"

    * Esperado: variables de hogar (tam_hog, factor, etc.) replicadas a nivel persona
    capture confirm variable factor
    if _rc {
        di as error "En base_out NO aparece 'factor'. Intentaremos un rescate."
    }
    else {
        count if missing(factor)
        di as result "base_out -> personas con factor missing: " %12.0g r(N)
        quietly summarize factor if !missing(factor)
        di as text "base_out -> resumen factor (no missing): N=" %9.0g r(N) " min=" %9.0g r(min) " max=" %9.0g r(max)
    }

    * Chequear llaves mínimas a nivel persona
    capture confirm variable folioviv
    capture confirm variable foliohog
    capture confirm variable numren
    if _rc di as error "base_out: faltan algunas llaves (folioviv, foliohog, numren)."

    * Conteo total de personas
    quietly count
    di as text "base_out -> total personas: " %12.0g r(N)
}

*------------------------------------------------------------*
* 3) RESCATE OPCIONAL DEL FACTOR (si hiciera falta en memoria)
*    Úsalo si factor está ausente en la base cargada.
*------------------------------------------------------------*
capture confirm variable factor
if _rc {
    di as txt "Intentando traer 'factor' directo desde Concen + Hogares..."
    preserve
        use "$ruta\\Concen.dta", clear
        keep folioviv foliohog factor est_dis upm tam_loc tam_hog
        tempfile hhkeys
        save `hhkeys'
    restore

    * Si no están folioviv/foliohog en memoria, intenta crearlos desde folio
    capture confirm variable folioviv
    if _rc {
        capture confirm variable folio
        if !_rc {
            di as txt "No veo folioviv/foliohog; intentaré separarlos desde 'folio' (si posible)."
            * Si 'folio' es concatenación simple, el siguiente paso puede no ser exacto.
            * Ajusta a tu formato si sabes los anchos fijos;
            * aqui sólo informamos si no existen llaves directas.
            di as error "Sugerencia: vuelve a cargar una base que sí tenga folioviv y foliohog."
        }
    }

    * Hacer merge m:1 por llaves de hogar
    capture noisily merge m:1 folioviv foliohog using `hhkeys'
    if _rc {
        di as error "No se pudo hacer el merge de rescate. Revisa que la base en memoria tenga folioviv y foliohog."
    }
    else {
        tab _merge
        drop _merge
        count if missing(factor)
        di as result "Tras rescate -> personas con factor missing: " %12.0g r(N)
    }
}

*------------------------------------------------------------*
* 4) Simulación de creación de factor_ci / factor_ch
*    y chequeo de faltantes (para anticipar errores en variablesBID.do)
*------------------------------------------------------------*
capture drop factor_ci factor_ch
capture confirm variable factor
if _rc {
    di as error "Aún no tenemos 'factor' en memoria; no se puede simular factor_ci/ch."
}
else {
    gen double factor_ci = factor
    gen double factor_ch = factor
    label var factor_ci "Factor expansion individuo (copia de factor)"
    label var factor_ch "Factor expansion hogar (copia de factor)"

    count if missing(factor_ci)
    di as result "Diagnóstico -> missing(factor_ci): " %12.0g r(N)
    count if missing(factor_ch)
    di as result "Diagnóstico -> missing(factor_ch): " %12.0g r(N)
}

*------------------------------------------------------------*
* 5) Diagnóstico de edad vs edad_ci
*    - Si ya existe edad_ci, verificamos consistencia.
*    - Si no existe pero existe edad, creamos edad_ci de prueba.
*------------------------------------------------------------*
capture confirm variable edad_ci
if _rc {
    capture confirm variable edad
    if _rc {
        di as error "No existe 'edad' ni 'edad_ci' en la base actual. Carga una base a nivel persona."
    }
    else {
        gen edad_ci = edad
        label var edad_ci "Edad (copia diagnostico)"
        di as txt "Creada edad_ci (diagnóstico) copiando desde 'edad'."
    }
}

* Conteos comparados
capture confirm variable edad
if !_rc {
    count if missing(edad)
    local miss_edad = r(N)
    count if missing(edad_ci)
    local miss_edadci = r(N)
    di as text "Missing edad:    " %12.0g `miss_edad'
    di as text "Missing edad_ci: " %12.0g `miss_edadci'
    if (`miss_edad' == `miss_edadci') di as result "OK: faltantes de edad_ci coinciden con faltantes de edad."
    else di as error "Alerta: faltantes de edad_ci NO coinciden con los de edad (revisa transformaciones posteriores)."
}

*------------------------------------------------------------*
* 6) Chequeos de integridad de MERGEs críticos (opcional)
*    Útil si corres justo al final de mergeBID.do
*------------------------------------------------------------*
di as txt "Chequeos opcionales de integridad (si estás en post-merge):"
* Ejemplo: si tienes en memoria el resultado tras los m:1 por folio:
capture confirm variable gasmon
if !_rc {
    di as txt "Veo 'gasmon' -> parece que ya uniste gtOS y no-monetario."
}
capture confirm variable nomon
if !_rc {
    di as txt "Veo 'nomon' -> no-monetario presente."
}
capture confirm variable tam_hog
if !_rc {
    di as txt "Veo 'tam_hog' -> tamaño del hogar está disponible."
}

*------------------------------------------------------------*
* 7) Salida: Top 10 casos con factor_ci missing (si existieran)
*------------------------------------------------------------*
capture count if missing(factor_ci)
if !_rc & r(N)>0 {
    di as error "Casos ejemplo con factor_ci missing:"
    list folioviv foliohog numren factor factor_ci in 1/10 if missing(factor_ci), noobs abbreviate(12)
}

di as txt "================= FIN DIAGNOSTICO ================="
log close
