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
global DAT "/media/ubuntu/Impar/investigacion/Activa/MMR/Data"
global COD "/media/ubuntu/Impar/investigacion/Activa/MMR/Do"
global OUT "/media/ubuntu/Impar/investigacion/Activa/MMR/Results"
global LOG "/media/ubuntu/Impar/investigacion/Activa/MMR/Log"

log using "$LOG/analysisMMR.txt", text replace
cap mkdir "$OUT/tables"
cap mkdir "$OUT/graphs"

********************************************************************************
**** (1b) Locals (variables and sections)
********************************************************************************
**VARIABLES
local mmr MMR ln_MMR
local cov GDPpc ln_GDPpc ln_GDPcu Immuniz fertil percentattend population /*
*/              TeenB
*husbandMore husbandLess
local edu ln_yrsch yr_sch yr_sch_pr yr_sch_se yr_sch_te lpc lsc lhc lu lp ls lh
local reg BLcode region_code region_UNESCO income2
local xv1 lp ls lh
local xv2 yr_sch
local xv3 yr_sch yr_sch_sq
local dxv Dlp Dls Dlh
*local dxv Dyr_sch Dyr_sch_sq


foreach a in outreg2 arrowplot unique estout {
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

twoway scatter MMR year if age_all || lfit MMR year if age_all,          ///
title(Maternal Mortality by Year) subtitle(Points represent country average)
graph export "$OUT/graphs/trends/timetrend_MMR.eps", replace as(eps)

foreach educ of varlist lu- yr_sch_ter { 
    twoway scatter `educ' year if age_all || lfit `educ' year if         ///
    age_all, title("Educational Achievement (F) by Year")                ///
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

preserve
replace lu=-lu
keep if age_fert==1
collapse MMR GDPpc lu lp, by(country year)
gsort country -year

reg MMR GDPpc
predict MMRresid, resid
reg lu GDPpc
predict luresid, resid
reg lp GDPpc
predict lpresid, resid


by country: gen FDMMR   = MMR[_n-1]- MMR[_n]
by country: gen FDeducN = lu[_n-1] - lu[_n]
by country: gen FDeducP = lp[_n-1] - lp[_n]

by country: gen FDMMRr   = MMRresid[_n-1]- MMRresid[_n]
by country: gen FDeducNr = luresid[_n-1] - luresid[_n]
by country: gen FDeducPr = lpresid[_n-1] - lpresid[_n]


collapse FDMMR FDeducN FDeducP FDMMRr FDeducNr FDeducPr, by(country)

lab var FDMMR   "Change in Maternal Mortality Ratio"
lab var FDeducN "Change in Proportion out of School"
lab var FDeducP "Change in Proportion in Primary School"

lab var FDMMRr   "Change in Maternal Mortality Ratio"
lab var FDeducNr "Change in Proportion out of School"
lab var FDeducPr "Change in Proportion in Primary School"

foreach g in N P {
    local gname "reduction in the proportion of women with no"
    if `"`g'"'=="N" local gname "increase in the proportion of women with primary"
    reg FDMMR FDeduc`g'

    local Pcoef = _b[FDeduc`g']
    local Ptsta = _b[FDeduc`g']/_se[FDeduc`g']
    local Ppval = 1-ttail(e(N),`Ptsta')
    local Ppval = round(`Ppval'*1000)/1000
    local Pcval = round((`Pcoef')*1000)/1000
    if `Ppval'< 0.001 local Ppval "0.000"
    if `"`g'"'=="N" local Pcval -9.172
    
    local n1 "A 1 unit `gname' education is associated with a"
    local n2 " change in MMR (p-value = "
    dis `Ppval'
    
    #delimit ;
    scatter FDMMR FDeduc`g', mlabel(country) mlabsize(vsmall) mlabpos(9) m(i)||
        lfit FDMMR FDeduc`g', lcolor(red) lwidth(thick) lpattern(---) scheme(s1mono)
    xline(0, lwidth(thin)) yline(0, lwidth(thin))
    note("Slope =  `Pcval' (p-value = `Ppval' )");
    *note("`n1' `Pcval' `n2' `Ppval' )");
    graph export "$OUT/graphs/MMReduc`g'Deltas.eps", as(eps) replace;
    #delimit cr

    reg FDMMRr FDeduc`g'r

    local Pcoef = _b[FDeduc`g'r]
    local Ptsta = _b[FDeduc`g'r]/_se[FDeduc`g'r]
    local Ppval = 1-ttail(e(N),`Ptsta')
    local Ppval = round(`Ppval'*1000)/1000
    local Pcval = round((`Pcoef')*1000)/1000
    if `Ppval'< 0.001 local Ppval "0.000"
    
    local n1 "A 1 unit `gname' education is associated with a"
    local n2 " change in MMR (p-value = "
    dis `Ppval'
    
    #delimit ;
    scatter FDMMR FDeduc`g'r, mlabel(country) mlabsize(vsmall) mlabpos(9) m(i)||
        lfit FDMMR FDeduc`g'r, lcolor(red) lwidth(thick) lpattern(---)
    scheme(s1mono) xline(0, lwidth(thin)) yline(0, lwidth(thin))
    note("Slope =  `Pcval' (p-value = `Ppval' )");
    *note("`n1' `Pcval' `n2' `Ppval' )");
    graph export "$OUT/graphs/MMReduc`g'Deltas_conditional.eps", as(eps) replace;
    #delimit cr

}
restore

preserve

foreach num of numlist 1(1)12 {
    local from = 10+`num'*5
    local to   = 14+`num'*5
    dis "From=`from' To=`to'"
    gen age`from'`to' = agefrom ==`from' & ageto==`to'
}
gen age75pl = agefrom==75&ageto==999
keep if age1519==1|age2024==1|age2529==1|age3034==1|age3539==1|age4044==1|/*
*/      age4549==1|age5054==1|age5559==1|age6064==1|age6569==1|age7074==1|/*
*/      age75pl==1

local agevars
local cvs ln_GDPpc Immunization percentattend fertility TeenBirths
local se  cluster(BLcode)
foreach edt in lp ls lh {
    gen pointEst`edt' = .
    gen UBound`edt'   = .
    gen LBound`edt'   = .
    gen agegroup`edt' = ""
    gen aGroup`edt'   = .
}

local jj = 1
foreach age in 2024 2529 3034 3539 4044 4549 5054 5559 6064 6569 7074 75pl {
    dis "`var'"
    areg MMR lp ls lh i.year `cvs' if age`age'==1, abs(BLcode) `se'

    foreach edt in lp ls lh {
        replace pointEst`edt' = _b[`edt']                 in `jj'
        replace UBound`edt'   = _b[`edt']+1.65*_se[`edt'] in `jj'
        replace LBound`edt'   = _b[`edt']-1.65*_se[`edt'] in `jj'
        replace agegroup`edt' = "`age'"                   in `jj'
        replace aGroup`edt'   = `jj' in `jj'
    }
    local ++jj
}
lab def ages 1 "20-24" 2 "25-29" 3 "30-34" 4  "35-39" 5  "40-44" 6 "45-49"/*
*/           7 "50-54" 8 "55-59" 9 "60-64" 10 "65-69" 11 "70-74" 12 "75 plus"
lab val aGrouplp aGroupls ages

format pointEstlp %5.1f
format pointEstls %5.1f

#delimit ;
twoway line pointEstlp aGrouplp in 1/12, lcolor(black) lwidth(thick) ||
rcap UBoundlp LBoundlp aGrouplp in 1/12, lcolor(black) lpattern(dash)
scheme(s1mono) yline(0, lcolor(red))
xlabel(1(1)12, valuelabels angle(45)) xtitle("Age Group") ytitle("MMR")
legend(lab(1 "Point Estimate") lab(2 "95% CI"));
graph export "$OUT/graphs/PrimaryAge.eps", as(eps) replace;

twoway line pointEstls aGroupls in 1/12, lcolor(black) lwidth(thick) ||
rcap UBoundls LBoundls aGroupls in 1/12,  lcolor(black) lpattern(dash)
scheme(s1mono) yline(0, lcolor(red))
xlabel(1(1)12, valuelabels angle(45)) xtitle("Age Group") ytitle("MMR")
legend(lab(1 "Point Estimate") lab(2 "95% CI"));
graph export "$OUT/graphs/SecondaryAge.eps", as(eps) replace;
#delimit cr
restore


********************************************************************************
*** (4) Create macro dataset
********************************************************************************
keep if age_fert==1

collapse `mmr' `cov' GDPgrowth `edu' M_*, by(country year `reg')

lab var MMR           "MMR"
lab var yr_sch_pri    "Primary Education (yrs)"
lab var yr_sch_sec    "Seconday Education (yrs)"	
lab var yr_sch_ter    "Tertiary Education (yrs)"
lab var year          "Year"
lab var ln_GDPpc      "log GDP per capita"
lab var ln_GDPcur     "log GDP per capita"
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
bys country: gen trend=_n

bys BLcode (year): gen DMMR=MMR[_n]-MMR[_n-1]
bys BLcode (year): gen Dln_MMR=ln_MMR[_n]-ln_MMR[_n-1]
foreach var of varlist `xv1' `xv3' ln_GDPpc ln_GDPcur Immuniz percentatt fertil TeenBirths population{
    bys BLcode (year): gen D`var'=`var'[_n]-`var'[_n-1]    
}

********************************************************************************
***(5) Summary stats
********************************************************************************
gen MFyr_sch = M_yr_sch/yr_sch
local opts cells("count mean sd min max")
local educsum yr_sch yr_sch_pr yr_sch_se yr_sch_te lp ls lh lu MFyr_sch
local title "Summary Stats for All Countries"

*lab var husbandMore "Husband wants more births than wife"
*lab var husbandLess "Husband wants less births than wife"

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
lab var MMR "MMR"

tab region_code, gen(region)
foreach outcome in yr_sch MMR {
    if `"`outcome'"'=="yr_sch" {
        local title "Years of Schooling by Region"
        local ylab ylabel(4 "4" 6 "6" 8 "8" 10 "10" 12 "12")
        local ytit ytitle("Years of Education")
        local save SchoolingRegion
    }
    else if `"`outcome'"'=="MMR" {
        local title "Maternal Mortality Ratio by Region"
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
***(6a) MMR versus schooling regressions (tables 3 and 8)
********************************************************************************
tab year, gen(_year)
local trend
local opts  fe vce(cluster BLcode)
local n1    
local n2    

local cont1
local cont2 _year2 _year3 _year4 _year5
local cont3 `cont2' ln_GDPcur
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
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "$OUT/tables/`n1'", excel append label keep(``x'' `cont`num'')
    }

    if `iter'==1 local n1 CrossCountry_ln_female.xls
    if `iter'==2 local n1 CrossCountry_ln_female_yrs.xls
    if `iter'==3 local n1 CrossCountry_ln_female_yrssq.xls
    xi: xtreg ln_MMR `trend' ``x'', `options'
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')
    qui xi: xtreg ln_MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg ln_MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "$OUT/tables/`n1'", excel append label keep(``x'' `cont`num'')
    }
    local ++iter
}
gen msamp = e(sample)

********************************************************************************
***(6b) MMR versus schooling regressions with trends
********************************************************************************
local trend i.BLcode*trend
local opts  fe vce(cluster BLcode)
local n1    
local n2

local iter = 1
foreach x in xv1 xv2 xv3 {
    if `iter'==1 local n1 CrossCountry_female_trend.xls
    if `iter'==2 local n1 CrossCountry_female_yrs_trend.xls
    if `iter'==3 local n1 CrossCountry_female_yrssq_trend.xls

    xi: xtreg MMR `trend' ``x'', `opts'
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "$OUT/tables/`n1'", excel append label keep(``x'' `cont`num'')
    }

    if `iter'==1 local n1 CrossCountry_ln_female.xls
    if `iter'==2 local n1 CrossCountry_ln_female_yrs.xls
    if `iter'==3 local n1 CrossCountry_ln_female_yrssq.xls
    xi: xtreg ln_MMR `trend' ``x'', `options'
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')
    qui xi: xtreg ln_MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg ln_MMR `trend' ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "$OUT/tables/`n1'", excel append label keep(``x'' `cont`num'')
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
    outreg2 using "`name'", excel append label ctitle("`r`num''") keep(`xv1')
    
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
    outreg2 using "`name'", excel append label ctitle("`i'") keep(`xv1')
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
local dcont3 `dcont2' Dln_GDPcur
local dcont4 `dcont3' DImmunization
local dcont5 `dcont4' Dpercentattend
local dcont6 `dcont5' Dfertility
local dcont7 `dcont6' DTeenBirths
local dtrend
local dopts   vce(cluster BLcode)
    
local name "$OUT/tables/deltaEducation.xls"
  
reg DMMR `dxv' `dtrend', `dopts'
outreg2 using "`name'", excel replace label keep(`dxv')
qui reg DMMR `dxv' `dcont7', `dopts'

foreach num of numlist 1(1)7 {
    reg DMMR `dxv' `dtrend' `dcont`num'' if e(sample), `dopts'
    outreg2 using "`name'", excel append label keep(`dxv' `dcont`num'')
}


********************************************************************************
*** (9b) Full specification comparison
********************************************************************************
local ct ln_GDPpc Immuniz fertil percentattend population TeenBirths i.year
local Dct Dln_GDPpc DImmuniz Dfertil Dpercentattend Dpopulation DTeenBirths

    
xi: xtreg MMR `xv3' `ct', fe vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel replace keep(`xv3' ln_GDPpc)
xi: xtreg MMR `trend' `xv3' `ct', fe vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel append keep(`xv3' ln_GDPpc)

    
xi: xtreg MMR `xv3' ln_GDPpc  if e(sample), fe vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel replace keep(`xv3' ln_GDPpc)
xi: xtreg MMR `trend' `xv3' ln_GDPpc if e(sample), fe vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel append keep(`xv3' ln_GDPpc)

reg DMMR `dxv' `Dct', vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel append keep(`dxv' Dln_GDPpc )
reg DMMR `dxv' `Dct' i.BLcode, vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel append keep(`dxv' Dln_GDPpc )

reg DMMR `dxv' Dln_GDPpc if e(sample), vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel append keep(`dxv' Dln_GDPpc )
reg DMMR `dxv' Dln_GDPpc i.BLcode if e(sample), vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel append keep(`dxv' Dln_GDPpc )

reg Dln_MMR `dxv' `Dct', vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel append keep(`dxv' Dln_GDPpc )
reg Dln_MMR `dxv' `Dct' i.BLcode, vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison2.xls", excel append keep(`dxv' Dln_GDPpc )

reg Dln_MMR `dxv' Dln_GDPpc if e(sample), vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel append keep(`dxv' Dln_GDPpc )
reg Dln_MMR `dxv' Dln_GDPpc i.BLcode if e(sample), vce(cluster BLcode)
outreg2 using "$OUT/tables/comparison1.xls", excel append keep(`dxv' Dln_GDPpc )

********************************************************************************
*** (10) Correlations between health and development outcomes (Zscores)
********************************************************************************
local name $OUT/tables/Zscores_female.xls

cap rm "`name'"
cap rm "$OUT/tables/Zscores_female.txt"

foreach v in fertility Immunization percentattend ln_GDPcur TeenBirths {
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
local trend i.BLcode*trend
local xv1G lp ls lh M_lp M_ls M_lh 
local xv2G yr_sch M_yr_sch
local xv3G yr_sch yr_sch_sq M_yr_sch M_yr_sch_sq
local trend
local cont1
local cont2 _year2 _year3 _year4 _year5
local cont3 `cont2' ln_GDPcur
local cont4 `cont3' Immunization
local cont5 `cont4' percentattend
local cont6 `cont5' fertility
local cont7 `cont6' TeenBirths


local iter = 1
foreach x in xv1G xv2G xv3G {
    if `iter'==1 local n1 CrossCountry_gender.xls
    if `iter'==2 local n1 CrossCountry_gender_yrs.xls
    if `iter'==3 local n1 CrossCountry_gender_yrssq.xls
    
    xi: xtreg MMR `trend' ``x'', `opts'
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `trend' ``x'' `cont`num'' if msamp==1, `opts'
        outreg2 using "$OUT/tables/`n1'", excel label keep(``x'' `cont`num'')
    }

    if `iter'==1 local n1 CrossCountry_ln_gender.xls
    if `iter'==2 local n1 CrossCountry_ln_gender_yrs.xls
    if `iter'==3 local n1 CrossCountry_ln_gender_yrssq.xls
    xi: xtreg ln_MMR `trend' ``x'', `options'
    outreg2 using "$OUT/tables/`n1'", excel replace label keep(``x'')

    foreach num of numlist 1(1)7 {
        xi: xtreg ln_MMR `trend' ``x'' `cont`num'' if msamp==1, `opts'
        outreg2 using "$OUT/tables/`n1'", excel label keep(``x'' `cont`num'')
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
    outreg2 using "`out'.xls", excel append label keep(``x'')
    qui xi: xtreg mmratio ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg mmratio ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "`out'.xls", excel append label keep(``x'' `cont`num'')
    }

    xi: xtreg MMR ``x'', `opts'
    outreg2 using "`out'.xls", excel append label keep(``x'')
    qui xi: xtreg MMR ``x'' `cont7', `opts'

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR ``x'' `cont`num'' if e(sample), `opts'
        outreg2 using "`out'.xls", excel append label keep(``x'' `cont`num'')
    }
}

exit
********************************************************************************
*** (15) Fertility Preferences
********************************************************************************
local trend
local xv1G lp ls lh M_lp M_ls M_lh
local xv2G yr_sch M_yr_sch
local xv3G yr_sch yr_sch_sq M_yr_sch M_yr_sch_sq
local n1   "relEduc_fertPrefs.xls"
local n2   "relEduc_fert.xls"
local n3   "relEduc_MMR.xls"


gen MFlp     = M_lp/lp
gen MFls     = M_ls/ls
gen MFlh     = M_lh/lh
gen MFprim   = (1-M_lu)/(1-lu)
gen Fprim    = 1-lu

egen Avelp     = rowmean(M_lp lp)
egen Avels     = rowmean(M_ls ls)
egen Avelh     = rowmean(M_lh lh)
egen Aveyr_sch = rowmean(M_yr_sch yr_sch)
local edrat MFyr_sch
local edcon yr_sch


xi: xtreg husbandMore `edrat' `edcon', fe robust
outreg2 using "$OUT/tables/`n1'", excel replace label keep(`edrat' `edcon')
xi: xtreg fertility `edrat' `edcon' if e(sample), fe robust
outreg2 using "$OUT/tables/`n2'", excel replace label keep(`edrat' `edcon')
xi: xtreg MMR `edrat' `edcon', fe robust
outreg2 using "$OUT/tables/`n3'", excel replace label keep(`edrat' `edcon')
qui xi: xtreg husbandMore `edrat' `edcon' `cont7', fe robust
gen Mp = e(sample)

foreach num of numlist 1(1)7 {
    xi: xtreg husbandMore `trend'  `edrat' `edcon' `cont`num'' if Mp==1, fe robust
    outreg2 using "$OUT/tables/`n1'", excel label keep(`edrat' `edcon' `cont`num'')
    xi: xtreg fertility `trend'  `edrat' `edcon' `cont`num'' if Mp==1, fe robust
    outreg2 using "$OUT/tables/`n2'", excel label keep(`edrat' `edcon' `cont`num'')
    xi: xtreg MMR `trend' `edrat' `edcon' `cont`num'' if Mp==1, fe robust
    outreg2 using "$OUT/tables/`n3'", excel label keep(`edrat' `edcon' `cont`num'')
}

********************************************************************************
*** (X) close
********************************************************************************
log close
