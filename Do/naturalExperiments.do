/* naturalExperiments.do v1.00  damiancclarke              yyyy-mm-dd:2014-12-31
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

This file examines the effect of various educational reforms on rates of MMR ar-
ound the date of the reform.  There are three country reforms, listed below, al-
ong with the specifications followed in each case (which come from existing lit-
erature).
 (1) Nigeria 1976:
     Specification follows Osili and Long (2008), with additional controls as p-
     er Akresh et al. (2012)
 (2) Zimbabwe 1980
     Specification follows Aguero and Bharadwaj (2010)
 (3) Kenya 1985
     Specification as per Chicoine (2011)

In each case, data comes from DHS education (IR) and maternal mortality modules.
Full generating details of this data can be found in the files...


contact: mailto:damian.clarke@economics.ox.ac.uk

*/

vers 11
clear all
set more off
cap log close
set maxvar 20000
set matsize 4000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global OUT "~/investigacion/Activa/MMR/Results"
global DAT "~/investigacion/Activa/MMR/Data"
global LOG "~/investigacion/Activa/MMR/Log"

cap mkdir "$OUT/tables"
cap mkdir "$OUT/graphs"
log using "$LOG/naturalExperiments.txt", text replace

**switches
local Nig 0
local Zim 1
local Ken 0

local opts cells("count mean sd min max")
local linef lcolor(black) lpattern(dash)

********************************************************************************
*** (2a) Nigeria Estimates Education
********************************************************************************
local Ncont i.religion i.ethnicity i.stcode1967 i.yearbirth i.stcode1967*trend
local Biafra1 yr6769southeast yr6769nonwest_noSE 
local Biafra2 reg_mexp0 reg_mexp1 reg_mexp2 reg_mexp3 reg_mexp4 mexp0 mexp1 /*
*/ mexp2 mexp3 mexp4
local wt [pw=v005]
local sampT yr6575==1|yr5661==1
local sampP yr5055==1|yr5660==1

local se cluster(yearstate)

local treat1 yr7075nonwest yr6569nonwest
local treat2 yr7075capexp53 yr6569capexp53 capexp53
local treat3 nonwest_main_exposure nonwest_pre_exposure
local treat4 capexp53_main_exposure capexp53_pre_exposure

local placebo1 yr5660nonwest
local placebo2 yr5660capexp53 capexp53
local placebo3 nonwest_main_exposure_fake
local placebo4 capexp53_main_exposure_fake


if `Nig'==1 {
    use "$DAT/Nigeria/educ", clear
    replace educ=. if educ>25
    gen yearstate=yearbirth*100*stcode1967
    estpost sum educ capexp53 yearbirth if (yr6575==1|yr5661==1)
    estout using "$OUT/tables/sumStatsCountry.xls", replace `opts'

        
    **TREATMENT
    xi: reg educ `treat1' `Ncont' `Biafra1' `wt' if `sampT', robust `se'
    outreg2 `treat1' using "$OUT/tables/Nigeria.xls", excel replace
    xi: reg educ `treat2' `Ncont' `Biafra1' `wt' if `sampT', robust `se'
    outreg2 `treat2' using "$OUT/tables/Nigeria.xls", excel append
    xi: reg educ `treat3' `Ncont' `Biafra2' `wt' if `sampT', robust `se'
    outreg2 `treat3' using "$OUT/tables/Nigeria.xls", excel append
    xi: reg educ `treat4' `Ncont' `Biafra2' `wt' if `sampT', robust `se'
    outreg2 `treat4' using "$OUT/tables/Nigeria.xls", excel append

    **PLACEBO
    
    xi: reg educ `placebo1' `Ncont' `Biafra1' `wt' if `sampP', robust `se'
    outreg2 `placebo1' using "$OUT/tables/NigeriaPlacebo.xls", excel replace
    xi: reg educ `placebo2' `Ncont' `Biafra1' `wt' if `sampP', robust `se'
    outreg2 `placebo2' using "$OUT/tables/NigeriaPlacebo.xls", excel append
    xi: reg educ `placebo3' `Ncont' `Biafra2' `wt' if `sampP', robust `se'
    outreg2 `placebo3' using "$OUT/tables/NigeriaPlacebo.xls", excel append
    xi: reg educ `placebo4' `Ncont' `Biafra2' `wt' if `sampP', robust `se'
    outreg2 `placebo4' using "$OUT/tables/NigeriaPlacebo.xls", excel append

    **GRAPHICAL
    collapse educ, by(yearbirth)
    egen educ=ma(education)
    graph twoway line educ yearbir if yearbirth>=1955, scheme(s1color) ///
    ytitle("Years of Education") xline(1965, lcolor(black) lpattern(dot)) ///
    xline(1975, lcolor(black) lpattern(dot)) legend(off) ///
    || lfit educ yearbirth if yearbirth<=1965&yearbirth>=1955, `linef' ///
    || lfit educ yearbirth if yearbirth>=1975, `linef' ///
    || lfit educ yearbirth if yearbirth<=1975&yearbirth>=1965, `linef' ///
    note("Series is a 3 year moving average of educational attainment")
    graph export "$OUT/graphs/Nigeria_educ.eps", as(eps) replace
}

********************************************************************************
*** (2b) Nigeria Estimates MMR
********************************************************************************
if `Nig'==1 {
    use "$DAT/Nigeria/mmr", clear
    gen yearstate=yearbirth*100*stcode1967

    estpost sum mmr mmr_25 yearbirth if (yr6575==1|yr5661==1)
    estout using "$OUT/tables/sumStatsCountry.xls", append `opts'

    foreach m in mmr mmr_25 {

        ***TREATMENT
        xi: reg `m' `treat1' `Ncont' `Biafra1' `wt' if `sampT', `se'
        outreg2 `treat1' using "$OUT/tables/Nigeria.xls", excel appen
        xi: reg `m' `treat2' `Ncont' `Biafra1' `wt' if `sampT', `se'
        outreg2 `treat2' using "$OUT/tables/Nigeria.xls", excel append
        xi: reg `m' `treat3' `Ncont' `Biafra2' `wt' if `sampT', `se'
        outreg2 `treat3' using "$OUT/tables/Nigeria.xls", excel append
        xi: reg `m' `treat4' `Ncont' `Biafra2' `wt' if `sampT', `se'
        outreg2 `treat4' using "$OUT/tables/Nigeria.xls", excel append


        **PLACEBO
        xi: reg `m' `placebo1' `Ncont' `Biafra1' `wt' if `sampP', `se'
        outreg2 `placebo1' using "$OUT/tables/NigeriaPlacebo.xls", excel 
        xi: reg `m' `placebo2' `Ncont' `Biafra1' `wt' if `sampP', `se'
        outreg2 `placebo2' using "$OUT/tables/NigeriaPlacebo.xls", excel 
        xi: reg `m' `placebo3' `Ncont' `Biafra2' `wt' if `sampP', `se'
        outreg2 `placebo3' using "$OUT/tables/NigeriaPlacebo.xls", excel 
        xi: reg `m' `placebo4' `Ncont' `Biafra2' `wt' if `sampP', `se'
        outreg2 `placebo4' using "$OUT/tables/NigeriaPlacebo.xls", excel 

        **NOTE: ALSO HAVE A ROBUSTNESS CHECK FOR NO LAGOS
    }
    **GRAPHICAL
    collapse mmr [pw=v005], by(yearbirth)
    keep if year>1931
    egen mmr_ma=ma(mmr)

    graph twoway line mmr_m yearbirth if yearbir>=1955&yearbir<1990, ///
    scheme(s1color) ytitle("Maternal Mortality") legend(off)         ///
    xline(1965, lcolor(black) lpattern(dot))                         ///
    xline(1975, lcolor(black) lpattern(dot))                         ///
    || lfit mmr_ma yearbirth if yearbir<=1965&yearbir>=1955, `linef' ///
    || lfit mmr_ma yearbirth if yearbir>=1975&yearbir<1990,  `linef' ///
    || lfit mmr_ma yearbirth if yearbir<=1975&yearbir>=1965, `linef' ///
    note("Series is a 3 year moving average of maternal deaths per woman")
    graph export "$OUT/graphs/Nigeria_mmr.eps", as(eps) replace        
}

********************************************************************************
*** (3a) Zimbabwe Estimates Education
********************************************************************************
local Zcont   i.v024 age1980 rural i.DHSyear
local treat   dumage dumageXage1980less14 invdumageXage1980less14
local tcon2   dumage14sq invdumage14sq
local tcon3   dumage14sq invdumage14sq dumage14th invdumage14th
local tsamp   age1980>=6&age1980<=22

local se      cluster(v024)
local placebo dumage_alt dumageXage1980less20 invdumageXage1980less20
local pcon2   dumage20sq invdumage20sq
local pcon3   dumage20sq invdumage20sq dumage20th invdumage20th
local psamp   age1980>=12&age1980<=28

if `Zim'==1 {
    use "$DAT/Zimbabwe/educ", clear
    estpost sum education highschool dumage yearbirth if age1980>=6&age1980<=22
    estout using "$OUT/tables/sumStatsCountry.xls", append `opts'

    foreach o in Zimbabwe ZimbabwePlacebo {
        cap rm "$OUT/tables/`o'.xls"
        cap rm "$OUT/tables/`o'.txt"
    }
    
    **TREATMENT
    foreach y of varlist education highschool {
        reg `y' `treat' `Zcont' if `tsamp', `se'
        outreg2 `treat' using "$OUT/tables/Zimbabwe.xls", excel
        reg `y' `treat' `Zcont' `tcon2' if `tsamp', `se'
        outreg2 `treat' using "$OUT/tables/Zimbabwe.xls", excel
        reg `y' `treat' `Zcont' `tcon3' if `tsamp', `se'
        outreg2 `treat' using "$OUT/tables/Zimbabwe.xls", excel
    }

    **PLACEBO
    foreach y of varlist education highschool {
        reg `y' `placebo' `Zcont' if `psamp', `se'
        outreg2 `placebo' using "$OUT/tables/ZimbabwePlacebo.xls", excel
        reg `y' `placebo' `Zcont' `pcon2' if `psamp', `se'
        outreg2 `placebo' using "$OUT/tables/ZimbabwePlacebo.xls", excel
        reg `y' `placebo' `Zcont' `pcon3' if `psamp', `se'
        outreg2 `placebo' using "$OUT/tables/ZimbabwePlacebo.xls", excel
    }

    **GRAPHICAL
    collapse education, by(yearbirth)
    graph twoway line education yearbirth, scheme(s1color)            ///
    ytitle("Years of Education") xtitle("Respondent's Year of Birth") ///
    xline(1966, lcolor(black) lpattern(dot)) legend(off)              ///
    || lfit educ yearbirth if yearbirth<=1966, `linef'                ///
    || lfit educ yearbirth if yearbirth>=1966, `linef'
    graph export "$OUT/graphs/Zimbabwe_educ.eps", as(eps) replace
}
exit


if `"`Zimbabwe'"'=="yes" {
use "$DAT/Zimbabwe/educ", clear
if `"`regs'"'=="yes" {
reg education dumage dumageXage1980less14 invdumageXage1980less14 i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage dumageXage1980less14 invdumageXage1980less14 using "$RESULTS/Zimbabwe.xls", excel replace
reg highschool dumage dumageXage1980less14 invdumageXage1980less14 i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage dumageXage1980less14 invdumageXage1980less14 using "$RESULTS/Zimbabwe.xls", excel append

reg education dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt using "$RESULTS/Zimbabwe_check.xls", excel replace
reg highschool dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt using "$RESULTS/Zimbabwe_check.xls", excel append
}

if `"`graphs'"'=="yes" {
	collapse educ, by(yearbirth) 
	graph twoway line educ yearbir, scheme(s1color) ytitle("Years of Education") ///
	xtitle("Respondent's Year of Birth") xline(1966, lcolor(black) lpattern(dot)) ///
	|| lfit educ yearbirth if yearbirth<=1966, lcolor(black) lpattern(dash) legend(off) ///
	|| lfit educ yearbirth if yearbirth>=1966, lcolor(black) lpattern(dash)
	graph export $RESULTS/Zimbabwe_educ.eps, as(eps) replace
}

use "$DAT/Zimbabwe/mmr", clear
if `"`regs'"'=="yes" {
reg mmr dumage dumageXage1980less14 invdumageXage1980less14 i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage dumageXage1980less14 invdumageXage1980less14 using "$RESULTS/Zimbabwe.xls", excel append

reg mmr dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt i.v024 rural [pw=v005] if age1980>=6&age1980<=22, cluster(v024)
outreg2 dumage_alt dumageXage1980less7_alt invdumageXage1980less7_alt using "$RESULTS/Zimbabwe_check.xls", excel append
}

if `"`graphs'"'=="yes" {

}
	collapse mmr, by(yearbirth) 
	keep if year>1930
	egen mmr_ma=ma(mmr)
	graph twoway line mmr_ma yearbir if yearbirth>1952&yearbirth<1990, scheme(s1color) ytitle("Maternal Mortality") ///
	xline(1966, lcolor(black) lpattern(dot)) ///
	|| lfit mmr_ma yearbirth if yearbirth<=1966&yearbirth>1952, lcolor(black) lpattern(dash) legend(off) ///
	|| lfit mmr_ma yearbirth if yearbirth>=1966&yearbirth<1990, lcolor(black) lpattern(dash) ///
	note("Series is a 3 year moving average of maternal deaths per woman")
	graph export $RESULTS/Zimbabwe_mmr.eps, as(eps) replace
}


if `"`Kenya'"'=="yes" {
use "$DAT/Kenya/educ", clear
if `"`regs'"'=="yes" {
	reg educ treat age age2 age3 trend trend2 rural i.quarter [pw=v005], cluster(v024)
	outreg2 treat using "$RESULTS/Kenya.xls", excel replace
}
if `"`graphs'"'=="yes" {
	collapse educ, by(yearbirth) 
	graph twoway line educ yearbir, scheme(s1color) ytitle("Years of Education") ///
	xtitle("Respondent's Year of Birth") xline(1963, lcolor(black) lpattern(dot)) ///
	xline(1972, lcolor(black) lpattern(dot)) ///
	|| lfit educ yearbirth if yearbirth<=1963, lcolor(black) lpattern(dash) legend(off) ///
	|| lfit educ yearbirth if yearbirth>=1972, lcolor(black) lpattern(dash) ///
	|| lfit educ yearbirth if yearbirth<=1972&yearbirth>=1963, lcolor(black) lpattern(dash)
	graph export $RESULTS/Kenya_educ.eps, as(eps) replace
}

	use "$DAT/Kenya/mmr", clear
if `"`regs'"'=="yes" {
	reg mmr treat age age2 age3 trend trend2 rural i.quarter [pw=v005], cluster(v024)
	outreg2 treat using "$RESULTS/Kenya.xls", excel append
}
if `"`graphs'"'=="yes" {
	collapse mmr, by(yearbirth) 
	graph twoway line mmr yearbir, scheme(s1color) ytitle("Maternal Mortality") ///
	xline(1963, lcolor(black) lpattern(dot)) xline(1972, lcolor(black) lpattern(dot)) ///
	|| lfit mmr yearbirth if yearbirth<=1963, lcolor(black) lpattern(dash) legend(off) ///
	|| lfit mmr yearbirth if yearbirth>=1972, lcolor(black) lpattern(dash) ///
	|| lfit mmr yearbirth if yearbirth<=1972&yearbirth>=1963, lcolor(black) lpattern(dash)

	graph export $RESULTS/Kenya_mmr.eps, as(eps) replace
}
}
