
global ruta "${surveysFolder}/survey/URY/ECH/2024/a/data_orig"
global out "${surveysFolder}/survey/URY/ECH/2024/a/data_merge"
set more off


import delimited "$ruta/ECH_2024.csv", encoding(UTF-8) 
save "$out/URY_2024a.dta", replace
