* 0) Open the dataset produced by variablesBID.do (the _BID one)
use "C:\Users\maria\OneDrive\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl\MEX\ENIGH\2008\m8_m11\data_merge\MEX_2008m8_m11_BID.dta", clear

* 1) Quick peek: do these variables exist?
ds factor_ch factor_ci edad_ci sexo_ci zona_c

* 2) If they don't exist (first-time run or naming-case drift), create them robustly:
capture confirm variable factor_ch
if _rc {

    * normalize possible case drift (bring required inputs to lower)
    foreach v in factor sexo edad estrato {
        capture confirm variable `v'
        if _rc {
            local up = upper("`v'")
            capture confirm variable `up'
            if !_rc rename `up' `v'
        }
    }

    * generate harmonized variables
    gen factor_ch = factor
    gen factor_ci = factor
    gen sexo_ci   = sexo
    gen edad_ci   = edad

    gen byte zona_c = .
    replace zona_c = 1 if estrato<=2
    replace zona_c = 0 if estrato>2 & estrato!=.
    label define zona_c 1 "Urbana" 0 "Rural"
    label value  zona_c zona_c
}

* 3) Now the check:
count if missing(factor_ch) | missing(factor_ci) | missing(edad_ci) | missing(sexo_ci) | missing(zona_c)
