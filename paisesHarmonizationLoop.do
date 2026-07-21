global running_survey_csv "C:\Users\DCOR\OneDrive - Inter-American Development Bank Group\Documents\GitHub\calculo_indicators_R\Inputs\running_survey.csv"
global paises_loop_dir "C:\Users\DCOR\OneDrive - Inter-American Development Bank Group\Documents\GitHub\armonizacion_microdatos_encuestas_hogares_scl"
include "get_encuesta_ronda.do"

capture program drop open_harmonization
program open_harmonization
  args pais ano

	get_encuesta_ronda, pais("`pais'") ano("`ano'") csv("$running_survey_csv")
	global encuestas "`r(encuesta)'"
	global rondas    "`r(rondas)'"
	if "`r(restricted)'" == "1" global ruta = "${surveysFolderRestricted}"
	else                        global ruta = "${surveysFolder}"

	local base_in = "$ruta\harmonized\\`pais'\\$encuestas\data_arm\\`pais'_`ano'${rondas}_BID.dta"
	use `base_in', clear
end

capture program drop run_harmonization
program run_harmonization
  args pais ano

	get_encuesta_ronda, pais("`pais'") ano("`ano'") csv("$running_survey_csv")
	global encuestas "`r(encuesta)'"
	global rondas    "`r(rondas)'"
	global github = "${gitFolder}"
	do "$github\armonizacion_microdatos_encuestas_hogares_scl\\`pais'\\$encuestas\program\\`pais'_`ano'${rondas}_variablesBID.do"


end

capture program drop _survey_loop
program define _survey_loop

	syntax , FUNCTION(string) [CSV(string) PERSON(string) PAIS(string) LOGDIR(string)]

	if "`csv'"    == "" local csv    "$running_survey_csv"
	if "`logdir'" == "" local logdir "$paises_loop_dir"

	preserve
		quietly import delimited using "`csv'", ///
			varnames(1) stringcols(_all) clear

		quietly drop if pais == "Total"
		quietly keep if availability == "1"
		if "`person'" != "" quietly keep if person == "`person'"
		if "`pais'"   != "" quietly keep if pais   == "`pais'"
		quietly duplicates drop pais year, force
		quietly sort pais year

		local nrows = _N
		tempfile survey_rows
		quietly save "`survey_rows'", replace
	restore

	* --- build a timestamped log path, e.g. run_harmonization_20260714_153000.log
	local ts = subinstr("`c(current_date)' `c(current_time)'", " ", "_", .)
	local ts = subinstr("`ts'", ":", "", .)
	local ts = subinstr("`ts'", "-", "", .)
	local logfile "`logdir'\\`function'_`ts'.log"

	tempname lf
	file open `lf' using "`logfile'", write replace text
	file write `lf' "pais,ano,status,rc" _n
	file close `lf'

	display as text "Starting loop over `nrows' country-years (`function')..."
	display as text "Log: `logfile'"

	local n_ok   = 0
	local n_fail = 0

	forvalues i = 1/`nrows' {

		preserve
			quietly use "`survey_rows'", clear
			local pais = pais[`i']
			local ano  = year[`i']
		restore

		display as text "Processing: `pais' `ano'"
		cap `function' `pais' `ano'
		local rc = _rc

		if `rc' == 0 {
			local n_ok = `n_ok' + 1
			local status "OK"
		}
		else {
			local n_fail = `n_fail' + 1
			display as error "  -> failed (`function' `pais' `ano'), rc=`rc'"
			local status "FAILED"
		}

		* close+reopen (append) after every row so the log is up to date on disk
		file open `lf' using "`logfile'", write append text
		file write `lf' "`pais',`ano',`status',`rc'" _n
		file close `lf'
	}

	display as text "Done. `n_ok' ok, `n_fail' failed. Log: `logfile'"

end

capture program drop run_harmonization_loop
program define run_harmonization_loop

	syntax [, CSV(string) PERSON(string) PAIS(string) LOGDIR(string)]

	local opts ""
	if "`csv'"    != "" local opts `"`opts' csv(`"`csv'"')"'
	if "`person'" != "" local opts `"`opts' person(`"`person'"')"'
	if "`pais'"   != "" local opts `"`opts' pais(`"`pais'"')"'
	if "`logdir'" != "" local opts `"`opts' logdir(`"`logdir'"')"'
	_survey_loop, function(run_harmonization) `opts'

end

capture program drop open_harmonization_loop
program define open_harmonization_loop

	syntax [, CSV(string) PERSON(string) PAIS(string) LOGDIR(string)]

	local opts ""
	if "`csv'"    != "" local opts `"`opts' csv(`"`csv'"')"'
	if "`person'" != "" local opts `"`opts' person(`"`person'"')"'
	if "`pais'"   != "" local opts `"`opts' pais(`"`pais'"')"'
	if "`logdir'" != "" local opts `"`opts' logdir(`"`logdir'"')"'
	_survey_loop, function(open_harmonization) `opts'

end


run_harmonization_loop, person("missing")