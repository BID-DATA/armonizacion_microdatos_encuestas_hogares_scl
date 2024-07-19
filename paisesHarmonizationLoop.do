capture program drop open_harmonization                                                        
program open_harmonization
  args pais ano
 
	global ruta = "${surveysFolder}"
 
	local mydir "${gitFolder}/calculo_indicadores_encuestas_hogares_scl"
 
	* Directory containing do-Files used as input
	global input	"`mydir'/Input"
	include "${input}/Directorio HS LAC.do"
 
	local base_in = "$ruta\harmonized\\`pais'\\$encuestas\data_arm\\`pais'_`ano'${rondas}_BID.dta"
	use `base_in', clear
end

capture program drop run_harmonization                                                        
program run_harmonization
  args pais ano
 
	
	
 
	* Directory containing do-Files used as input
	include "${gitFolder}/calculo_indicadores_encuestas_hogares_scl/Input/Directorio HS LAC.do"
	global github = "${gitFolder}"
	do "$github\armonizacion_microdatos_encuestas_hogares_scl\\`pais'\\$encuestas\program\\`pais'_`ano'${rondas}_variablesBID.do"
	

end


global paises  BOL DOM GTM HND MEX NIC VEN
global anos  2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022
* ARG BHS BLZ BOL BRA BRB CHL COL CRI DOM ECU GTM GUY HND HTI JAM MEX NIC PAN PER PRY SLV SUR TTO URY VEN
* MISSING: ARG BHS BLZ BRA BRB CHL COL CRI ECU GUY HTI JAM PER PRY URY VEN

foreach x of global paises {
	foreach y of global anos {
		
	cap 	run_harmonization `x' `y'
		
	}
	
}