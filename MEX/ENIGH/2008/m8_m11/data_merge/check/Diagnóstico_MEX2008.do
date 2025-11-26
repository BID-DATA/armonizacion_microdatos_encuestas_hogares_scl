* --- 0) Validaciones (ya las hiciste, pero por si acaso)
use pobla08.dta, clear
isid folioviv foliohog numren

use trabajos.dta, clear
* Debe haber múltiples por numtrab:
tab numtrab

* --- 1) Construir versión "wide" con sufijos _1 y _2 por trabajo
use trabajos.dta, clear
keep folioviv foliohog numren numtrab /* + todas las vars de trabajos que quieras conservar */

* Lista de variables a expandir (excluye las llaves y numtrab):
local idvars folioviv foliohog numren numtrab
ds
local all `r(varlist)'
local jobvars
foreach v of local all {
    if strpos(" `idvars' "," `v' ")==0 {
        local jobvars `jobvars' `v'
    }
}

tempfile t1 t2 trab_wide

* Trabajo principal
preserve
keep if numtrab==1
drop numtrab
foreach v of local jobvars {
    capture rename `v' `v'_1
}
tempfile tp
save `tp', replace
restore

* Trabajo secundario
preserve
keep if numtrab==2
drop numtrab
foreach v of local jobvars {
    capture rename `v' `v'_2
}
tempfile ts
save `ts', replace
restore

* Unir principal + secundario a nivel persona
use `tp', clear
merge 1:1 folioviv foliohog numren using `ts', nogen
save `trab_wide', replace

* --- 2) Merges limpios en tu pipeline
use pobla08.dta, clear
merge m:1 folioviv foliohog using concen.dta, keepusing(factor estrato tam_hog)
drop _merge

merge 1:1 folioviv foliohog numren using `trab_wide'
drop _merge

* --- 3) Variables armonizadas
gen factor_ch = factor
gen factor_ci = factor
gen edad_ci   = edad

* --- 4) Chequeos
count if missing(factor_ch)
count if missing(factor_ci)
count if missing(edad_ci)
