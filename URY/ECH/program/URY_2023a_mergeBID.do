
global ruta "${surveysFolder}\survey\URY\ECH\2023\a\data_orig"
global out "${surveysFolder}\survey\URY\ECH\2023\a\data_merge"
set more off


import delimited "$ruta\ECH_implantacion_2023.csv", encoding(UTF-8) 
save "$out\URY_2023a.dta", replace