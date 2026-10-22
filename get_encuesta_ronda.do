/*====================================================================
  Program:   get_encuesta_ronda
  Purpose:   Given pais and ano, return encuesta, rondas and
             restricted locals by looking them up in running_survey.csv

  Syntax:
      get_encuesta_ronda, pais(str) ano(str) csv(str)

  Arguments:
      pais(str)   3-letter country code, e.g. "CHL"
      ano(str)    4-digit year,          e.g. "2022"
      csv(str)    path to running_survey.csv

  Returns (r-class):
      r(encuesta)    survey name,               e.g. "CASEN"
      r(rondas)      space-separated ronda(s),  e.g. "m11_m12"
      r(restricted)  1 if any available row for pais/year has
                     access_right == "restricted", 0 otherwise

  Example:
      get_encuesta_ronda, pais("BHS") ano("2015") ///
          csv("running_survey.csv")
      display r(encuesta)     // LFS
      display r(rondas)       // a
      display r(restricted)   // 1

  Notes:
    - Only rows where availability == 1 are considered.
    - If multiple rondas exist they are returned space-separated.
    - restricted = 1 if ANY available row has access_right == "restricted".
    - If no match is found all three r() values are "".
====================================================================*/

capture program drop get_encuesta_ronda
program define get_encuesta_ronda, rclass

    syntax , pais(string) ano(string) csv(string)

    * ----------------------------------------------------------------
    * 1. Validate inputs
    * ----------------------------------------------------------------
    if "`pais'" == "" | "`ano'" == "" | "`csv'" == "" {
        display as error "get_encuesta_ronda: pais, ano, and csv are required."
        exit 198
    }

    * ----------------------------------------------------------------
    * 2. Load CSV and extract results
    * ----------------------------------------------------------------
    local enc_result        ""
    local ronda_result      ""
    local restricted_result ""

    capture frames
    if _rc == 0 {

        * --- Stata 16+ path: frames ---
        capture frame drop _gsr_lookup
        frame create _gsr_lookup
        frame _gsr_lookup {
            quietly import delimited using "`csv'", ///
                varnames(1) stringcols(_all) clear

            * Keep only available rows for this country-year
            quietly keep if pais         == "`pais'" ///
                          & year         == "`ano'"  ///
                          & availability == "1"

            quietly levelsof encuesta,           local(enc_result)   clean
            quietly levelsof rondaarmonizadabid, local(ronda_result) clean

            * restricted = 1 if any row has access_right == "restricted"
            quietly count if access_right == "restricted"
            if r(N) > 0 local restricted_result = 1
            else         local restricted_result = 0
        }
        frame drop _gsr_lookup

    }
    else {

        * --- Stata 15 and earlier: preserve/restore ---
        preserve
            quietly import delimited using "`csv'", ///
                varnames(1) stringcols(_all) clear

            quietly keep if pais         == "`pais'" ///
                          & year         == "`ano'"  ///
                          & availability == "1"

            quietly levelsof encuesta,           local(enc_result)   clean
            quietly levelsof rondaarmonizadabid, local(ronda_result) clean

            quietly count if access_right == "restricted"
            if r(N) > 0 local restricted_result = 1
            else         local restricted_result = 0
        restore

    }

    * ----------------------------------------------------------------
    * 3. Return results
    * ----------------------------------------------------------------
    if "`enc_result'" == "" {
        display as error ///
            "WARNING: no available survey for pais=`pais', ano=`ano'"
        return local encuesta    ""
        return local rondas      ""
        return local restricted  ""
    }
    else {
        return local encuesta   "`enc_result'"
        return local rondas     "`ronda_result'"
        return local restricted "`restricted_result'"
        display as text "encuesta   : `enc_result'"
        display as text "rondas     : `ronda_result'"
        display as text "restricted : `restricted_result'"
    }

end
