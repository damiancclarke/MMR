/* setupMMR v1.00                damiancclarke             yyyy-mm-dd:2014-12-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file generates country-level observations for maternal mortality rates and
educational attainment, along with a number of other time-varying covariates re-
lated to health, income and access.  It generates the following two files:
  > MMReduc_BASE_F
  > MMReduc_BASE_M
where one is for male education and the other for female education.

It requires the following data sources:
  > BL2013_F_v2.0.dta: Barro-Lee education data (female)
  > BL2013_M_v2.0.dta: Barro-Lee education data (male)
  > MM_Base          : WHO MMR database


*/

clear all
version 11
set more off
cap log close

********************************************************************************
*** (1) globals
********************************************************************************
global DAT "~/investigacion/Activa/MMR/Data"
global COD "~/investigacion/Activa/MMR/Do"
global LOG "~/investigacion/Activa/MMR/Log"
    
log using "$LOG/setupMMR.txt", text replace


********************************************************************************
*** (2) Create Barro-Lee data set with male and female results
********************************************************************************
use "$DAT/BL2013_M_v2.0.dta"
foreach var of varlist lu lp lpc ls lsc lh lhc yr_sch yr_sch_* {
    rename `var' M`var'
}
keep M* country year agefrom ageto 
merge 1:1 country year agefrom ageto using "$DAT/BL2013_F_v2.0.dta", gen(_mMF)
drop _mMF


********************************************************************************
*** (3) Merge Barro-Lee with MMR
********************************************************************************
replace country="Bolivia (Plurinational State of)" if country=="Bolivia"
replace country="Cote d'Ivoire" if country=="Cote dIvoire"
replace country="Dominican Republic" if country=="Dominican Rep."
replace country="Libya" if country=="Libyan Arab Jamahiriya"
replace country="United States of America" if country=="USA"
replace country="Venezuela (Bolivarian Republic of)" if country=="Venezuela"
replace country="Lao People's Democratic Repblic" if country=="Lao People's Democratic Republic"

keep if year > 1985
merge m:1 country year using "$DAT/MM_base", gen(_mergeBLMMR)

save "$DAT/MMReduc_BASE_F", replace

********************************************************************************
*** (4) Merge Barro-Lee with covariates (saved per sheet)
********************************************************************************
foreach var in GDPpc Immunization fertility population TeenBirths_temp IMR {
    use "$DAT/InputsToCreateBase/control_`var'", clear
    reshape long v, i(countryname countrycode) j(year)
    rename v `var'
    replace year=year+1957

    do "$COD/WHO_Countrynaming.do"
		keep if year==1990|year==1995|year==2000|year==2005|year==2010

    rename countryname country
    merge m:m country year using "$DAT/MMReduc_BASE_F", gen(_merge`var')
    save "$DAT/MMReduc_BASE_F", replace
}

use "$DAT/InputsToCreateBase/control_birthphysician", clear
do "$COD/WHO_Countrynaming.do"
rename countryname country
merge m:m country year using "$DAT/MMReduc_BASE_F", gen(_merge`var')
save "$DAT/MMReduc_BASE_F", replace

********************************************************************************
*** (5) Variable creation
********************************************************************************
gen age_all=(agefrom==15&ageto==999)
gen age_25plus=(agefrom==25&ageto==999)
gen age_fert=(agefrom==15&ageto==19|agefrom==20&ageto==24|agefrom==25&ageto==29|/*
*/agefrom==30&ageto==34|agefrom==35&ageto==39)

label var age_all    "Average educational attainment of all age groups"
label var age_25plus "Average educational attainment, all individuals over 25"
label var age_fert   "Dummmy indicating fertile age (15-39)"

gen ln_yrsch=log(yr_sch)
gen ln_MMR=log(MMR)
gen ln_GDPpc=log(GDPpc)

********************************************************************************
*** (6) Save, clean
********************************************************************************
lab dat "Education and Maternal Mortality by country 1990-2010 (Bhalotra Clarke)"
save "$DAT/MMReduc_BASE_F", replace

log close
