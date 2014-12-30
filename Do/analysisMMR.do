/* analysisMMR v1.00             damiancclarke             yyyy-mm-dd:2014-12-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file runs cross-country regressions, analysing the effect of education on
maternal mortality.  Regressions of the following form are run:

     MMR_it = a + educ_it*B + W_it*g + d_t + u_it

where MMR_it refers to the rate of maternal mortality in region i in time t, and
educ_it refers to educational outcomes of women of fertile age in the same regi-
on at the same time.

Data used here comes from the following scripts:
   > setupMMR.do
   >

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


**SWITCHES (set 1 to run, else 0)
local full   1
local summ   0
local MMR    0
local MMRreg 0
local MMRinc 0
local Zsc    0
local cntry  0

foreach a in outreg2 arrowplot {
    cap which `a'
    if _rc!=0 ssc install `a'
}

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
if `full'==1 {
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


}

********************************************************************************
*** (4) Create macro dataset (NB: age all is)
********************************************************************************
keep if age_fert==1
collapse `mmr' `cov' `edu', by(country year `reg')

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

gen yr_sch_sq=yr_sch*yr_sch
gen yr_pri_sq=yr_sch_pri*yr_sch_pri
gen yr_sec_sq=yr_sch_sec*yr_sch_sec
gen yr_ter_sq=yr_sch_ter*yr_sch_ter
gen atleastprimary=lp+ls+lh

xtset BLcode year
bys year: gen trend=_n

********************************************************************************
***(5) Summary stats
********************************************************************************
if `summ'==1 {
    local opts cells("count mean sd min max")
    local educsum yr_sch yr_sch_pr yr_sch_se yr_sch_te lp ls lh lu
    local title "Summary Stats for All Countries"

    estpost sum `mmr' `cov' `educsum'
    estout using "$OUT/tables/SumStats.xls", replace `opts' title(`title')

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
}

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


if `MMR'==1 {
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
            outreg2 ``x'' `cont`num'' using "$OUT/tables/`n2'", excel append label
        }
        local ++iter
    }
}


********************************************************************************
***(6) MMR versus schooling by region
********************************************************************************
if `MMRreg'==1 {
    replace region_UNESCO=subinstr(region_UNESCO, " ", "", .)
    replace region_UNESCO=subinstr(region_UNESCO, "-", "", .)
    levelsof region_UNESCO, local(region)

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
        outreg2 using "`name'", excel append label ctitle("`r`num''")
    }

    foreach num of numlist 1(1)7 {
        xi: xtreg MMR `xv1' `cont7' if region_code=="`r`num''", `opts'
        outreg2 using `name', excel append label ctitle("`r`num''")
	}
}

********************************************************************************
***(7) MMR versus schooling by income
********************************************************************************
if `MMRinc'==1 {
    replace income2="LM" if income2=="Lower middle"
    replace income2="UM" if income2=="Upper middle"

    local name $OUT/tables/CrossCountry_income.xls
  
    cap rm "`name'"
    cap rm "$OUT/tables/CrossCountry_income.txt"

    foreach i in Low LM UM High {
        qui xi: xtreg MMR `xv1' `cont7' if income2=="`i'", `opts'
	
        xi: xtreg MMR `xv1' `cont2' if e(sample)&income2=="`i'", `opts'
        outreg2 using "`name'", excel append label ctitle("`i'")
    }

    foreach i in Low LM UM High {
        xi: xtreg MMR `xv1' `cont7' if income2=="`i'", `opts'
        outreg2 using "`name'", excel append label ctitle("`i'")
    }
}

********************************************************************************
***(8) Correlations between health and development outcomes (Zscores)
********************************************************************************
if `Zsc'==1 {
    local name $OUT/tables/Zscores_female.xls

    cap rm "`name'"
    cap rm "$OUT/tables/Zscores_female.txt"

    foreach v in fertility Immunization percentattend ln_GDPpc TeenBirths {
        egen z_`v'=std(`v')
        reg z_`v' `xv1', robust
        outreg2 using "`name'", excel append
    }
}

********************************************************************************
***(9) DHS Microdata subsample
********************************************************************************
if `"`DHSsample'"'=="yes" {
	use `DHS_MMR', clear
	merge 1:m _cou year using `DHS_Edu'
	encode _cou, gen(ccode)

	gen FEMALEyrs_sq=FEMALEyrseduc^2
	gen MALEyrs_sq=MALEyrseduc^2

	xtset ccode year
	xtreg MMR i.year FEMALEprimary FEMALEsecondary FEMALEpostsecondary /*
	*/ MALEprimary MALEsecondary MALEpostsecondary 
	*xtreg MMR i.year FEMALEyrs* MALEyrs*
	
}
