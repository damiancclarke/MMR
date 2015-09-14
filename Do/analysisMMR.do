/* analysisMMR v1.00             damiancclarke             yyyy-mm-dd:2014-12-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file runs cross-country regressions, analysing the effect of education on
maternal mortality.  Regressions of the following form are run:

     MMR_it = a + educ_it*B + W_it*g + d_t + u_it

where MMR_it refers to the rate of maternal mortality in region i in time t, and
educ_it refers to educational outcomes of women of fertile age in the same regi-
on at the same time.  Note that some regressions in this file require Wild boot-
strapping of standard errors.  A Stata program cgmwildboot is downloadable from
https://sites.google.com/site/judsoncaskey/data.

Data and source code used here comes from the following scripts:
   > setupMMR.do
   > UNESCO_naming.do

Note that the data file MMR_Country_Data is generated from source and stored in:
~/investigacion/2013/WorldMMR/Share/MMRTrends/MMR_Country_Data.dta 

contact mailto:damian.clarke@economics.ox.ac.uk
*/

clear all
version 11
set more off
cap log close

********************************************************************************
**** (1a) Globals
********************************************************************************
global DAT "~/investigacion/Activa/MMR/Data"
global COD "~/investigacion/Activa/MMR/Do"
global OUT "~/investigacion/Activa/MMR/Results"
global LOG "~/investigacion/Activa/MMR/Log"

log using "$LOG/MMR_Analysis.txt", text replace
cap mkdir "$OUT/tables"
cap mkdir "$OUT/graphs"

********************************************************************************
**** (1b) Locals (variables and sections)
********************************************************************************
**VARIABLES
local mmr MMR ln_MMR
local cov GDPpc ln_GDPpc Immuniz fertil percentattend population TeenBirths
local edu ln_yrsch yr_sch yr_sch_pr yr_sch_se yr_sch_te lpc lsc lhc lu lp ls lh
local reg BLcode region_code region_UNESCO income2
local xv1 lp ls lh
local xv2 yr_sch
local xv3 yr_sch yr_sch_sq
local dxv Dyr_sch Dyr_sch_sq


foreach a in outreg2 arrowplot unique {
    cap which `a'
    if _rc!=0 ssc install `a'
}
cap which cgmwildboot
if _rc !=0 display "No Wild Bootstrapping ado installed. Reverting to clusters"

********************************************************************************
**** (2) Use and rename
********************************************************************************
use "$DAT/MMReduc_BASE_F", clear
do "$COD/UNESCO_naming.do"

encode region_code, gen(region)
gen gender="F"
rename TeenBirths_t TeenBirths

********************************************************************************
*** (3) Full sample graphs
********************************************************************************
cap mkdir "$OUT/graphs/trends"

twoway scatter MMR year if age_all || lfit MMR year if age_all, ///
title(Maternal Mortality by Year) subtitle(Points represent country average)
graph export "$OUT/graphs/trends/timetrend_MMR.eps", replace as(eps)

foreach educ of varlist lu- yr_sch_ter { 
    twoway scatter `educ' year if age_all || lfit `educ' year if ///
    age_all, title("Educational Achievement (F) by Year") ///
    subtitle(Points represent country average)
    graph export "$OUT/graphs/trends/timetrend_`educ'_F.eps", replace as(eps)
}

local m  "maternal deaths per 100,000 live births."
local n1 "Notes to figure: Each point represents a country average of `m'"
local n2 "Education data is for women aged 15-39."
foreach MMR of varlist ln_MMR MMR {
    if "`MMR'"=="ln_MMR" {
        local title "Log Maternal Mortality"
        local legend1 "ln(MMR)"
    }
    else if "`MMR'"=="MMR" {
        local title "Maternal Mortality"
        local legend1 "MMR"
    }
    twoway scatter `MMR' yr_sch if age_fert || lfit `MMR' yr_sch if       ///
    age_fert, lcolor(black) range(0 12) || qfit `MMR' yr_sch if age_fert, ///
    lpattern(dash) lcolor(black) range(0 .)                               ///
    xlabel(0 "0" 5 "5" 10 "10" 15 "15") note("`n1'" "`n2'")               ///
    legend(lab(1 "`legend1'") lab(2 "Fitted Values (linear)")             ///
    lab(3 "Fitted Values (quadratic)")) scheme(s1color)
    graph export "$OUT/graphs/trends/Schooling_`MMR'_F.eps", replace as(eps)
}


********************************************************************************
*** (4) Create macro dataset (NB: age all is)
********************************************************************************
keep if age_fert==1
collapse `mmr' `cov' GDPgrowth `edu' M_*, by(country year `reg')

lab var yr_sch_pri    "Primary Education (yrs)"
lab var yr_sch_sec    "Seconday Education (yrs)"	
lab var yr_sch_ter    "Tertiary Education (yrs)"
lab var year          "Year"
lab var ln_GDPpc      "log GDP per capita"
lab var Immunization  "Immunization (DPT)"
lab var percentattend "Attended Births"
lab var TeenBirths    "Teen births"
lab var lp            "Percent ever enrolled in primary"
lab var ls            "Percent ever enrolled in secondary"
lab var lh            "Percent ever enrolled in tertiary"
lab var GDPgrowth     "Growth Rate in GDP"

gen yr_sch_sq=yr_sch*yr_sch
gen M_yr_sch_sq=M_yr_sch*M_yr_sch
gen yr_pri_sq=yr_sch_pri*yr_sch_pri
gen yr_sec_sq=yr_sch_sec*yr_sch_sec
gen yr_ter_sq=yr_sch_ter*yr_sch_ter
gen atleastprimary=lp+ls+lh

xtset BLcode year
bys year: gen trend=_n

bys BLcode (year): gen DMMR=MMR[_n]-MMR[_n-1]
bys BLcode (year): gen Dln_MMR=ln_MMR[_n]-ln_MMR[_n-1]
foreach var of varlist `xv1' `xv3' ln_GDPpc Immuniz percentatt fertil TeenBirths population{
    bys BLcode (year): gen D`var'=`var'[_n]-`var'[_n-1]    
}

********************************************************************************
***(5) Summary stats
********************************************************************************
local opts cells("count mean sd min max")
local educsum yr_sch yr_sch_pr yr_sch_se yr_sch_te lp ls lh lu
local title "Summary Stats for All Countries"

replace population=population/1000000    
estpost sum `mmr' `cov' `educsum'
estout using "$OUT/tables/SumStats.xls", replace `opts' title(`title')
replace population=population*1000000

foreach year of numlist 1990(5)2010 {
    local title "Summary Stats for All Countries (`year')"
    estpost sum `mmr' `cov' `educsum' if year==`year'
    estout using "$OUT/tables/SumStats.xls", append `opts' title(`title')
}


preserve
collapse yr_sch MMR, by(year region_code)
tab region_code, gen(region)
foreach outcome in yr_sch MMR {
    if `"`outcome'"'=="yr_sch" {
        local title "Years of Schooling by Region"
        local ylab ylabel(4 "4" 6 "6" 8 "8" 10 "10" 12 "12")
        local ytit ytitle("Years of Education")
        local save SchoolingRegion
    }
    else if `"`outcome'"'=="MMR" {
        local title "Maternal Mortalit|y Ratio by Region"
        local ylab ylabel(0 "0" 200 "200" 400 "400" 600 "600" 800 "800")
        local ytit ytitle("MMR")
        local save MMRRegion
    }

    twoway line `outcome' year if region1                       || ///
    line `outcome' year if region2, lpattern(dash)              || ///
    line `outcome' year if region3, lpattern(dot)               || ///
    line `outcome' year if region4, lpattern(dash_dot)          || ///
    line `outcome' year if region5, lpattern(longdash)          || ///
    line `outcome' year if region6, lpattern(longdash_dot)      || ///
    line `outcome' year if region7, lpattern(shortdash_dot)        ///
    graphregion(color(white)) bgcolor(white) `ytit' `ylab'         ///
    legend(lab(1 "Advanced Economies") lab(2 "East Asia")          ///
    lab(3 "Europe/Central Asia") lab(4 "LAC") lab(5 "MENA")        ///
    lab(6 "South Asia") lab(7 "SSA")) ///
    scheme(s1color)
    graph export "$OUT/graphs/trends/`save'.eps", as(eps) replace
}
restore


********************************************************************************
***(6) MMR versus schooling regressions (tables 3 and 8)
********************************************************************************
tab year, gen(_year)
local trend i.BLcode*trend
local opts  fe vce(cluster BLcode)
local n1    
local n2    

local cont1
local cont2 _year2 _year3 _year4 _year5
local cont3 `cont2' ln_GDPpc
local cont4 `cont3' Immunization
local cont5 `cont4' percentattend
local cont6 `cont5' fertility
local cont7 `cont6' TeenBirths


local iter = 1
foreach x in xv1 xv2 xv3 {
    if `iter'==1 local n1 CrossCountry_female.xls
    if `iter'==2 local n1 CrossCountry_female_yrs.xls
    if `iter'==3 local n1 CrossCountry_female_yrssq.xls

    xi: xtreg MMR `trend' ``x'', `opts'
    outreg2 ``x'' using "$OUT/tables/`n1'", excel replace label
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "$OUT/tables/`n1'", excel append label
    }

    if `iter'==1 local n1 CrossCountry_ln_female.xls
    if `iter'==2 local n1 CrossCountry_ln_female_yrs.xls
    if `iter'==3 local n1 CrossCountry_ln_female_yrssq.xls
    xi: xtreg ln_MMR `trend' ``x'', `options'
    outreg2 ``x'' using "$OUT/tables/`n1'", excel replace label
    qui xi: xtreg ln_MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg ln_MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "$OUT/tables/`n1'", excel append label
    }
    local ++iter
}



********************************************************************************
*** (7) MMR versus schooling by region
********************************************************************************
replace region_UNESCO=subinstr(region_UNESCO, " ", "", .)
replace region_UNESCO=subinstr(region_UNESCO, "-", "", .)
levelsof region_UNESCO, local(region)
local opt2 fe nonest dfadj vce(bootstrap, reps(100) seed(2727)) cluster(BLcode)
 
local r1 "Advanced Economies"
local r2 "East Asia and the Pacific"
local r3 "Europe and Central Asia"
local r4 "Latin America and the Caribbean"
local r5 "Middle East and North Africa"
local r6 "South Asia"
local r7 "Sub-Saharan Africa"

local name "$OUT/tables/CrossCountry_region.xls"

cap rm "`name'"
cap rm "$OUT/tables/CrossCountry_region.txt"

foreach num of numlist 1(1)7 {
    qui xi: xtreg MMR `xv1' `cont7' if region_code=="`r`num''", `opts'
    
    xi: xtreg MMR `xv1' `cont2' if region_c=="`r`num''"&e(sample), `opts'
    outreg2 `xv1' using "`name'", excel append label ctitle("`r`num''")
    
    dis "Wild Bootstrapped Standard Errors"
    *cgmwildboot MMR `xv1' `cont2' i.BLcode if region_c=="`r`num''"&/*  
    **/e(sample), cluster(country) bootcluster(BLcode) seed(2727) reps(50)
    xi: xtreg MMR `xv1' `cont2' if region_c=="`r`num''"&e(sample), `opt2'
    xi: xtreg MMR `xv1' `cont2' if region_c=="`r`num''"&e(sample), fe robust
}

foreach num of numlist 1(1)7 {
    xi: xtreg MMR `xv1' `cont7' if region_code=="`r`num''", `opts'
    *outreg2 using `name', excel append label ctitle("`r`num''")
}

********************************************************************************
*** (8) MMR versus schooling by income
********************************************************************************
replace income2="LM" if income2=="Lower middle"
replace income2="UM" if income2=="Upper middle"

local name $OUT/tables/CrossCountry_income.xls

cap rm "`name'"
cap rm "$OUT/tables/CrossCountry_income.txt"

foreach i in Low LM UM High {
    qui xi: xtreg MMR `xv1' `cont7' if income2=="`i'", `opts'

    xi: xtreg MMR `xv1' `cont2' if e(sample)&income2=="`i'", `opts'
    outreg2 `xv1' using "`name'", excel append label ctitle("`i'")
}

foreach i in Low LM UM High {
    xi: xtreg MMR `xv1' `cont7' if income2=="`i'", `opts'
    *outreg2 using "`name'", excel append label ctitle("`i'")
}


********************************************************************************
*** (9a) DeltaMMR versus Deltaschooling
********************************************************************************
local dcont1
local dcont2 _year2 _year3 _year4
local dcont3 `dcont2' Dln_GDPpc
local dcont4 `dcont3' DImmunization
local dcont5 `dcont4' Dpercentattend
local dcont6 `dcont5' Dfertility
local dcont7 `dcont6' DTeenBirths
local dtrend
local dopts   vce(cluster BLcode)
    
local name "$OUT/tables/deltaEducation.xls"
  
reg DMMR `dxv' `dtrend', `dopts'
outreg2 `dxv' using "`name'", excel replace label
qui reg DMMR `dxv' `dcont7', `dopts'

foreach num of numlist 1(1)7 {
    reg DMMR `dxv' `dtrend' `dcont`num'' if e(sample), `dopts'
    outreg2 `dxv' `dcont`num'' using "`name'", excel append label
}


********************************************************************************
*** (9b) Full specification comparison
********************************************************************************
local ct ln_GDPpc Immuniz fertil percentattend population TeenBirths i.year
local Dct Dln_GDPpc DImmuniz Dfertil Dpercentattend Dpopulation DTeenBirths

    
xi: xtreg MMR `xv3' `ct', fe vce(cluster BLcode)
outreg2 `xv3' ln_GDPpc using "$OUT/tables/comparison2.xls", excel replace
xi: xtreg MMR `trend' `xv3' `ct', fe vce(cluster BLcode)
outreg2 `xv3' ln_GDPpc using "$OUT/tables/comparison2.xls", excel append

    
xi: xtreg MMR `xv3' ln_GDPpc  if e(sample), fe vce(cluster BLcode)
outreg2 `xv3' ln_GDPpc using "$OUT/tables/comparison1.xls", excel replace
xi: xtreg MMR `trend' `xv3' ln_GDPpc if e(sample), fe vce(cluster BLcode)
outreg2 `xv3' ln_GDPpc using "$OUT/tables/comparison1.xls", excel append

reg DMMR `dxv' `Dct', vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison2.xls", excel append
reg DMMR `dxv' `Dct' i.BLcode, vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison2.xls", excel append

reg DMMR `dxv' Dln_GDPpc if e(sample), vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison1.xls", excel append
reg DMMR `dxv' Dln_GDPpc i.BLcode if e(sample), vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison1.xls", excel append

reg Dln_MMR `dxv' `Dct', vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison2.xls", excel append
reg Dln_MMR `dxv' `Dct' i.BLcode, vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison2.xls", excel append

reg Dln_MMR `dxv' Dln_GDPpc if e(sample), vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison1.xls", excel append
reg Dln_MMR `dxv' Dln_GDPpc i.BLcode if e(sample), vce(cluster BLcode)
outreg2 `dxv' Dln_GDPpc using "$OUT/tables/comparison1.xls", excel append

********************************************************************************
*** (10) Correlations between health and development outcomes (Zscores)
********************************************************************************
local name $OUT/tables/Zscores_female.xls

cap rm "`name'"
cap rm "$OUT/tables/Zscores_female.txt"

foreach v in fertility Immunization percentattend ln_GDPpc TeenBirths {
    egen z_`v'=std(`v')
    reg z_`v' `xv1', robust
    outreg2 using "`name'", excel append
}

********************************************************************************
*** (11) Country regressions
********************************************************************************
arrowplot ln_MMR yr_sch, group(country) scheme(s1color) gen(MMRcoefs)
preserve
collapse MMRcoefs, by(country)
count if MMRcoefs<0
local neg `=`r(N)''
count if MMRcoefs>=0
local pos `=`r(N)''
restore
arrowplot ln_MMR yr_sch, group(country) scheme(s1color)                 ///
 xtitle("Years of Schooling") ytitle("Log MMR") groupname("Country")    ///
 note("`neg' countries have a negative trend, `pos' have a positive trend.")

graph export "$OUT/graphs/countries.eps", as(eps) replace


********************************************************************************
*** (12) Female versus Male education
********************************************************************************
local xv1G lp ls lh M_lp M_ls M_lh
local xv2G yr_sch M_yr_sch
local xv3G yr_sch yr_sch_sq M_yr_sch M_yr_sch_sq


local iter = 1
foreach x in xv1G xv2G xv3G {
    if `iter'==1 local n1 CrossCountry_gender.xls
    if `iter'==2 local n1 CrossCountry_gender_yrs.xls
    if `iter'==3 local n1 CrossCountry_gender_yrssq.xls

    xi: xtreg MMR `trend' ``x'', `opts'
    outreg2 ``x'' using "$OUT/tables/`n1'", excel replace label
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "$OUT/tables/`n1'", excel label
    }

    if `iter'==1 local n1 CrossCountry_ln_gender.xls
    if `iter'==2 local n1 CrossCountry_ln_gender_yrs.xls
    if `iter'==3 local n1 CrossCountry_ln_gender_yrssq.xls
    xi: xtreg ln_MMR `trend' ``x'', `options'
    outreg2 ``x'' using "$OUT/tables/`n1'", excel replace label
    qui xi: xtreg ln_MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg ln_MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "$OUT/tables/`n1'", excel label
    }
    local ++iter
}

reg yr_sch M_yr_sch


********************************************************************************
*** (14) Run regressions using DHS MMR data
********************************************************************************
preserve
use "$DAT/MMR_Country_Data", clear
gen yearbin = .
foreach y of numlist 1990(5)2010 {
    local yup  = `y'+2
    local ydown= `y'-2
    dis "`y' is a bin from `ydown' to `yup' (inclusive)"
    replace yearbin = `y' if year>=`ydown'&year<=`yup'
}
drop if MMR==.
collapse birth MMR, by(_cou yearbin)
drop if yearbin==.
rename yearbin year
gen mmratio = MMR/birth * 100000
drop if mmratio==.
rename MMR MMRdhs
tempfile DHSDAT
replace _cou="Bolivia (Plurinational State of)" if  _cou== "Bolivia"
replace _cou="" if _cou == "Burkina-Faso"
replace _cou="Central African Republic" if _cou=="Central-African-Republic"
replace _cou="Democratic Republic of the Congo" if _cou=="Congo-Democratic-Republic"
replace _cou="Cote d'Ivoire" if _cou == "Cote-d-Ivoire"
replace _cou="Dominican Republic" if _cou == "Dominican-Republic"
replace _cou="Sierra Leone" if _cou == "Sierra-Leone"
replace _cou="South Africa" if _cou == "South-Africa"
replace _cou="United Republic of Tanzania" if _cou == "Tanzania"

rename _cou country

save `DHSDAT', replace
restore
merge 1:1 country year using `DHSDAT'
keep if _merge==3

local out "$OUT/tables/DHSsubset"
cap rm "$OUT/tables/DHSsubset.txt"
cap rm "$OUT/tables/DHSsubset.xls"

encode country, gen(ccode)
local opts  fe vce(cluster ccode)

xtset ccode year
foreach x in xv3 xv1 {
    xi: xtreg mmratio ``x'', `opts'
    outreg2 ``x'' using "`out'.xls", excel append label
    qui xi: xtreg mmratio ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg mmratio ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "`out'.xls", excel append label
    }

    xi: xtreg MMR ``x'', `opts'
    outreg2 ``x'' using "`out'.xls", excel append label
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR ``x'' `cont`num'' if e(sample), `opts'
        outreg2 ``x'' `cont`num'' using "`out'.xls", excel append label
    }
}

********************************************************************************
*** (X) close
********************************************************************************
log close
