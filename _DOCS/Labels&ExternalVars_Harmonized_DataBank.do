

* labels de variables
*====================================================================================================================================*
*                                                     INCLUSIóN DE VARIABLES EXTERNAS                                                *
*====================================================================================================================================*
global ruta = "${surveysFolder}"
capture drop _merge
merge m:1 pais_c anio_c using "$ruta\general_documentation\data_externa\poverty\International_Poverty_Lines\5_International_Poverty_Lines_LAC_long_PPP17", keepusing (lp19_2011 lp31_2011 lp5_2011 lp365_2017 lp685_2017 lp14_2017 lp81_2017 ppp_2011 ppp_2017 cpi cpi2011 cpi2017 cpi_2011 cpi_2017 tc_wdi ppp_wdi)

drop if _merge ==2

g tc_c     = tc_wdi
g ppp_c    = ppp_wdi

g cpi_c    = cpi
g ratio_cpi2011 = cpi_2011
g ratio_cpi2017 = cpi_2017

drop tc_wdi ppp_wdi cpi_2011 cpi_2017 _merge

*====================================================================================================================================*
*                                                         VARIABLES DE LÍNEAS DE POBREZA                                              *
*====================================================================================================================================*
label var tc_c     "Tipo de cambio oficial (año de la encuesta)"
label var ppp_c    "Poder de paridad adquisitivo (año de la encuesta)"
label var ppp_2011 "Poder de paridad adquisitivo (PPP) 2011"
label var ppp_2017 "Poder de paridad adquisitivo (PPP) 2017"

label var cpi_c   "Índice de precios al consumidor (año de la encuesta)"
label var cpi2011 "Índice de precios al consumidor (2011)"
label var cpi2017 "Índice de precios al consumidor (2017)"

label var ratio_cpi2011 "Tasa de índice de precios al consumidor (CPI_actual/CPI_2011)"
label var ratio_cpi2017 "Tasa de índice de precios al consumidor (CPI_actual/CPI_2017)"

label var lp19_2011 "Línea de pobreza extrema (WB) USD 1.9 per capita, PPP 2011"
label var lp31_2011 "Línea de pobreza extrema USD 3.1 per capita, PPP 2011"
label var lp5_2011  "Línea de pobreza moderada USD 5 per capita, PPP 2011"

label var lp365_2017 "Línea de pobreza extrema USD 3.1 per capita, moneda local PPP 2017"
label var lp685_2017 "Línea de pobreza moderada USD 6.85 per capita, moneda local PPP 2017"
label var lp14_2017  "Línea de vulnerabilidad USD 14.15 per capita, moneda local PPP 2017"
label var lp81_2017  "Línea de clase media USD 81.22 per capita, moneda local PPP 2017"

*====================================================================================================================================*
*                                                         VARIABLES DE IDENTIFICACION                                                *
*====================================================================================================================================*
label var region_BID_c "Regiones BID"
	label define region_BID_c 1 "Centroamérica_(CID)" 2 "Caribe_(CCB)" 3 "Andinos_(CAN)" 4 "Cono_Sur_(CSC)", add modify
	label value region_BID_c region_BID_c

label var factor_ci "Factor de expansion del individuo"
label var factor_ch "Factor de expansion del hogar"

label var idh_ch "ID del hogar"
label var idp_ci "ID de la persona en el hogar"

*label var region_c "Regiones especifica de cada país"

label var zona_c "Zona del pais"
	label define zona_c 1 "urbana" 0 "rural", add modify
	label value zona_c zona_c

	
label var pais_c "Nombre del País"
label var anio_c "Anio de la encuesta" 
*label var semestre_c "Semestre de la encuesta" /* No existe en todas las encuestas*/
label var mes_c "Mes de la encuesta" 
label define mes_c 1 "Enero" 2 "Febrero" 3 "Marzo" 4 "Abril" 5 "Mayo" 6 "Junio" 7 "Julio" 8 "Agosto" 9 "Septiembre" 10 "Octubre" 11 "Noviembre" 12 "Diciembre", add modify 
label value mes_c mes_c

*====================================================================================================================================*
*                                                          VARIABLES DEMOGRAFICAS                                                    *
*====================================================================================================================================*
cap label var relacion_ci "Relacion o parentesco con el jefe del hogar"
cap label define relacion_ci 1 "Jefe/a" 2 "Conyuge/esposo/compañero" 3 "Hijo/a" 4 "Otros_parientes" 5 "Otros_no_Parientes" 6 "Empleado/a_domestico/a", add modify 
cap label values relacion_ci relacion_ci
	
cap label var sexo_ci "Sexo del individuo" 
cap label define sexo_ci 1 "Hombre" 2 "Mujer", add modify
cap label value sexo_ci sexo_ci

cap label var edad_ci "Edad del individuo en años"
cap label var civil_ci "Estado civil"
cap label define civil_ci 1 "soltero/a" 2 "union_formal/informal" 3 "divorciado/a_o_separado/a" 4 "Viudo/a" , add modify
cap label value civil_ci civil_ci
	
cap label var dis_ci "Personas con discapacidad"
	cap label define dis_ci 1 "Con Discapacidad" 0 "Sin Discapacidad"
	cap label val dis_ci dis_ci
	
cap label var dis_ch "Hogares con miembros con discapacidad"
	cap label define dis_ch 0 "Hogares sin miembros con discapacidad"1 "Hogares con al menos un miembro con discapacidad" 
	cap label val dis_ch dis_ch 

cap label var afroind_ci "Raza o etnia del individuo"
	cap label define afroind_ci 1 "Indígena" 2 "Afro-descendiente" 3 "Otros" 9 "No se le pregunta"
	cap label val afroind_ci afroind_ci 

cap label var afroind_ch "Raza/etnia del hogar en base a raza/etnia del jefe de hogar"
	cap label define afroind_ch 1 "Hogares con Jefatura Indígena" 2 "Hogares con Jefatura Afro-descendiente" 3 "Hogares con Jefatura Otra" 9 "Hogares sin Información étnico/racial"
	cap label val afroind_ch afroind_ch 

cap label var afroind_ano_c "Año Cambio de Metodología Medición Raza/Etnicidad"
	
cap label var jefe_ci "Jefe/a de hogar"
cap label var nconyuges_ch "# de conyuges en el hogar"
cap label var nhijos_ch "# de hijos en el hogar"
cap label var notropari_ch "# de otros familiares en el hogar"	
cap label var notronopari_ch "# de no familiares en el hogar"
cap label var nempdom_ch "# de empleados domesticos"
cap label var clasehog_ch "Tipo de hogar"
cap label define clasehog_ch 1 "unipersonal" 2 "nuclear" 3 "ampliado" 4 "compuesto" 5 "corresidente", add modify
cap label value clasehog_ch clasehog_ch
	

cap label var nmayor21_ch "# de familiares mayores a 21 anios en el hogar"
cap label var nmenor21_ch "# de familiares menores a 21 anios en el hogar"
cap label var nmayor65_ch "# de familiares mayores a 65 anios en el hogar"
cap label var nmenor6_ch "# de familiares menores a 6 anios en el hogar"
cap label var nmenor1_ch "# de familiares menores a 1 anio en el hogar"
cap label var miembros_ci "=1: es miembro del hogar"
cap label var nmiembros_ch "# de miembros en el hogar"

*====================================================================================================================================*
*                                                          VARIABLES DEL MERCADO LABORAL                                              *
*====================================================================================================================================*
cap label var condocup_ci "Condicion de ocupación de acuerdo a def armonizada para cada pais"
cap label define condocup_ci 1 "Ocupado" 2 "Desocupado" 3 "Inactivo" 4 "No_responde_por_menor_edad", add modify
cap label value condocup_ci condocup_ci
	
cap label var categoinac_ci "Condición de inactividad"
cap label define categoinac_ci 1 "jubilado/pensionado" 2 "estudiante" 3 "quehaceres_domesticos" 4 "otros_inactivos", add modify
cap label value categoinac_ci categoinac_ci

cap label var cesante_ci "Desocupado cesante-trabajo anteriormente"	

cap label var ocupa_ci "Ocupacion laboral en la actividad principal"  
cap label define ocupa_ci 1"profesional_y_tecnico" 2"director_o_funcionario_sup" 3"administrativo_y_nivel_intermedio", add modify
cap label define ocupa_ci  4 "comerciantes_y_vendedores" 5 "en_servicios" 6 "trabajadores_agricolas", add modify
cap label define ocupa_ci  7 "obreros_no_agricolas,_conductores_de_maq_y_ss_de_transporte", add modify
cap label define ocupa_ci  8 "FFAA" 9 "otras", add modify
cap label value ocupa_ci ocupa_ci

cap label var emp_ci "=1: si ocupado (empleado)"

cap label var desemp_ci "Desempleado que buscó empleo en el periodo de referencia"

cap label var pea_ci "Población Económicamente Activa"

cap label var desalent_ci "Trabajadores desalentados: creen q no conseguiran trabajo"
cap label var antiguedad_ci "Antiguedad en la actividad actual"
cap label var formal_ci "Formalidad Laboral"


cap label var horaspri_ci "Horas trabajadas en la actividad principal"
cap label var horastot_ci "Horas trabajadas semanalmente en todos los empleos"

cap label var subemp_ci "Personas en subempleo por horas (<30 horas y dispuestas a trabajar +)"
cap label var tiempoparc_ci "Personas que trabajan medio tiempo (<30 horas y NO dispuestas a trabajar +)" 
	cap label define categopri_ci 1"Patron" 2"Cuenta propia" 3"Empleado" 4" No_remunerado" 0 "Otro" , add modify
	cap label value categopri_ci categopri_ci
cap label var categopri_ci "Categoria ocupacional en la actividad principal"
cap label var categosec_ci "Categoria ocupacional en la actividad secundaria"
	cap label define categosec_ci 1"Patron" 2"Cuenta_propia" 3"Empleado" 4" No_remunerado" 0 "Otro" , add modify
	cap label value categosec_ci categosec_ci
	
*label var contrato_ci "Ocupados que tienen contrato firmado de trabajo"
cap label var tipocontrato_ci "Tipo de contrato segun su duracion"
cap label define tipocontrato_ci 0 "Con contrato" 1 "Permanente/indefinido" 2 "Temporal" 3 "Sin_contrato/verbal", add modify
cap label value tipocontrato_ci tipocontrato_ci

*label var segsoc_ci "Personas que tienen seguridad social en SALUD por su trabajo" - ver si se incluye
cap label var nempleos_ci "# de empleos" 
	capture label define nempleos_ci 1 "Un empleo" 2 "Mas de un empleo"
	capture label value nempleos_ci nempleos_ci
*label var firmapeq_ci "=1: Trabajadores en empresas de <5 personas ~informales" /*esta variable se reemplaza por tamemp_ci*/
cap label var tamemp_ci "# empleados en la empresa segun rangos"
	cap label define tamemp_ci 1 "Pequena" 2 "Mediana" 3 "Grande", add modify
	cap label value tamemp_ci tamemp_ci
	
cap label var spublico_ci "=1: Personas que trabajan en el sector público"

cap label var rama_ci "Rama de actividad laboral de la ocupacion principal-Grandes Divisiones (ISIC Rev. 2)"
	cap label def rama_ci 1"Agricultura,_caza,_silvicultura_y_pesca" 2"Explotación_de_minas_y_canteras" 3"Industrias_manufactureras", add modify
	cap label def rama_ci 4"Electricidad,_gas_y_agua" 5"Construcción" 6"Comercio,_restaurantes_y_hoteles" 7"Transporte_y_almacenamiento", add modify
	cap label def rama_ci 8"Establecimientos_financieros,_seguros_e_inmuebles" 9"Servicios_sociales_y_comunales", add modify
	cap label val rama_ci rama_ci
	
	
cap label var durades_ci "Duracion del desempleo en meses"
	
	* Ingresos
	*Actividad Principal
cap label var ylmpri_ci "Ingreso laboral monetario actividad principal" 
cap label var nrylmpri_ci "ID de no respuesta ingreso de la actividad principal"  
cap label var ylnmpri_ci "Ingreso laboral NO monetario actividad principal"  
*label var tcylmpri_ci "Identificador de top-code del ingreso de la actividad principal" 
	* Actividad secundaria
cap label var ylmsec_ci "Ingreso laboral monetario segunda actividad" 
cap label var ylnmsec_ci "Ingreso laboral NO monetario actividad secundaria"
	* Otros ingresos laborales
cap label var ylmotros_ci "Ingreso laboral monetario de otros trabajos"
cap label var ylnmotros_ci "Ingreso laboral NO monetario de otros trabajos" 
	* Ingresos no laborales
*label var autocons_ci "Autoconsumo reportado por el individuo"
cap label var remesas_ci "Remesas mensuales reportadas por el individuo" 
cap label var ylmhopri_ci "Salario monetario horario de la actividad principal" 
cap label var ylmho_ci "Salario monetario horario de todas las actividades" 

			* Totales individuales
cap label var ylnm_ci "Ingreso laboral NO monetario total individual"  	
cap label var ylm_ci "Ingreso laboral monetario total individual"  
cap label var ynlm_ci "Ingreso no laboral monetario total individual"  
cap label var ynlnm_ci "Ingreso no laboral no monetario total individual" 
			
			* Totales a nivel de hogar
cap label var nrylmpri_ch "Hogares con algún miembro que no respondió por ingresos"
cap label var ylm_ch "Ingreso laboral monetario del hogar"
cap label var ylnm_ch "Ingreso laboral no monetario del hogar"
cap label var ylmnr_ch "Ingreso laboral monetario del hogar con missing en NR"
cap label var ynlm_ch "Ingreso no laboral monetario del hogar"
cap label var ynlnm_ch "Ingreso no laboral no monetario del hogar"
*label var rentaimp_ch "Rentas imputadas del hogar"

*label var autocons_ch "Autoconsumo reportado por el hogar"
cap label var remesas_ch "Remesas mensuales del hogar"	
cap label var ypen_ci "Monto de ingreso por pension contributiva"
cap label var ypensub_ci "Monto de ingreso por pension subsidiada / no contributiva"

* LINEAS DE POBREZA y OTRAS VARIABLES EXTERNAS DE REFERENCIA
cap label var lp_ci "Linea de pobreza oficial del pais en moneda local a precios corrientes"
cap label var lpe_ci "Linea de indigencia oficial del pais en moneda local a precios corrientes"
cap label var salmm_ci "Salario minimo legal a precios corrientes"


*====================================================================================================================================*
*                                                          VARIABLES DE SEGURIDAD SOCIAL                                             *
*====================================================================================================================================*
cap label var cotizando_ci "Cotizante a la Seguridad Social (SS)"
	cap label define cotizando_ci 0"No_cotiza" 1"Cotiza_a_SS", add modify 
	cap label value cotizando_ci cotizando_ci
cap label var afiliado_ci "Afiliado a la Seguridad Social"
	cap label define afiliado_ci 0"No_afiliado" 1"Afiliado_a_SS", add modify 
	cap label value afiliado_ci afiliado_ci
	
cap label var tipopen_ci "Tipo de pension - variable original de cada pais" 
cap label var instpen_ci "Institucion proveedora de la pension - variable original de cada pais" 
cap label var instcot_ci "Institucion a la cual cotiza o es afiliado - variable original de cada pais" 
cap label var pension_ci "=1: Recibe pension contributiva"
cap label var pensionsub_ci "=1: recibe pension subsidiada / no contributiva"



*====================================================================================================================================*
*                                                          VARIABLES DE EDUCACION                                             *
*====================================================================================================================================*
cap label var aedu_ci "Anios de educacion aprobados"	
cap label var eduui_ci "Superior incompleto"
cap label var eduuc_ci "Superior completo"
cap label var edupre_ci "Educacion preescolar"
cap label var eduac_ci "Superior universitario vs superior no universitario"	

cap label var asiste_ci "=1 si asiste actualmente a la escuela"						

cap label var edupub_ci "Asiste a un centro de ensenanza público"
*label var asispre_ci "=1 si asiste actualmente a educación preescolar"	
cap label var pqnoasis1_ci "Razones para no asistir a la escuela-variable armonizada"	

*====================================================================================================================================*
*                                                          VARIABLES DE INFRAESTRUCTURA DEL HOGAR                                    *
*====================================================================================================================================*

cap label var aguared_ch "Acceso a fuente de agua por red"
cap label var aguadist_ch "Ubicación de la principal fuente de agua"
	cap label def aguadist_ch 1"Dentro_de_la_vivienda" 2"Fuera_de_la_vivienda_pero_en_el_terreno", add modify
	cap label def aguadist_ch 3"Fuera_de_la_vivienda_y_del_terreno", add modify
	cap label val aguadist_ch aguadist_ch
cap label var aguamala_ch "Agua unimproved según MDG" 
cap label var aguamide_ch "Usan medidor para pagar consumo de agua"
cap label var luz_ch  "La principal fuente de iluminación es electricidad"
cap label var luzmide_ch "Usan medidor para pagar consumo de electricidad"
cap label var combust_ch "Principal combustible gas o electricidad" 
cap label var bano_ch "El hogar tiene servicio sanitario"
cap label var banoex_ch "El servicio sanitario es exclusivo del hogar"
cap label var piso_ch "Materiales de construcción del piso"  
	cap label def piso_ch 0"Piso_de_tierra" 1"Materiales_permanentes", add modify
	cap label val piso_ch piso_ch
cap label var pared_ch "Materiales de construcción de las paredes"
cap label var techo_ch "Materiales de construcción del techo" 
	cap label def techo_ch 1"Materiales_permanentes"  0"Materiales_no_permanentes" 2 "Otros_materiales", add modify
cap label var techo_ch techo_ch 
cap label var resid_ch "Método de eliminación de residuos"
cap label var dorm_ch "# de habitaciones exclusivas para dormir"
cap label var cuartos_ch "# Habitaciones en el hogar"
cap label var cocina_ch "Cuarto separado y exclusivo para cocinar"
cap label var telef_ch "El hogar tiene servicio telefónico fijo"
cap label var refrig_ch "El hogar posee refrigerador o heladera"
cap label var freez_ch "El hogar posee freezer o congelador"
cap label var auto_ch "El hogar posee automovil particular"
cap label var compu_ch "El hogar posee computador"
cap label var internet_ch "El hogar posee conexión a internet"
cap label var cel_ch "El hogar tiene servicio telefonico celular"
cap label var vivi1_ch "Tipo de vivienda en la que reside el hogar"
	cap label def vivi1_ch 1 "Casa" 2 "Departamento" 3 "Otros", add modify
	cap label val vivi1_ch vivi1_ch
cap label var vivi2_ch "=1: la vivienda es casa o departamento"
		
cap label var viviprop_ch "Propiedad de la vivienda" 
	cap label def viviprop_ch 0"Alquilada" 1"Propia" 3"Ocupada_(propia_de_facto)", add modify
	cap label val viviprop_ch viviprop_ch
	
cap label var vivitit_ch "El hogar posee un título de propiedad"
cap label var vivialq_ch "Alquiler mensual"
cap label var vivialqimp_ch "Alquiler mensual imputado"
cap label var aguamejorada_ch "El hogar tiene acceso a agua potable de fuente mejorada"
cap label var banomejorado_ch "El hogar tiene acceso a saneamiento de fuente mejorada"





