/* analysisMMR v1.00             damiancclarke             yyyy-mm-dd:2014-12-30
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8




Cross-country regressions for MMR analysis.  Takes data created in the do file
MMREduc_Setup.do.

This is replacing MMR_Analysis.do 1.00 and is a partial refactorisation.
*/

clear all
version 11
cap log close
set more off

********************************************************************************
**** (1) Globals and Locals
********************************************************************************
global DAT "~/investigacion/Activa/MMR/Data"
global COD "~/investigacion/Activa/MMR/Do"
global OUT "~/investigacion/Activa/MMR/Results"
global LOG "~/investigacion/Activa/MMR/Log"


global RESULTS "~/investigacion/Activa/MMR/Results_aug2013/allages"
global TABLES "~/investigacion/Activa/MMR/Results_aug2013/allages/Tables"
global GRAPHS "~/investigacion/Activa/MMR/Results_aug2013/Graphs"




log using "$LOG/MMR_Analysis.txt", text replace

global mmr ln_MMR MMR
global covars GDPpc ln_GDPpc Immuniz fertil percentattend population TeenBirths
global educ ln_yrsch yr_sch yr_sch_pr yr_sch_se yr_sch_te lpc lsc lhc lu lp ls lh
global classify BLcode region_code region_UNESCO income2

local educvars yr_sch_pri yr_sch_sec yr_sch_ter yr_sch lu lp ls lc lh
*local xvars yr_sch yr_sch_sq
*local xvars yr_sch
local xvars  atleastprim
*local xvars lp ls lh


cap mkdir $TABLES
cap mkdir $GRAPHS

*TABLES
local table1
local table2 SummaryStats
local table3 CrossCountry_female
local table3a CrossCountry_all
local table3b CrossCountry_region
local table3c CrossCountry_income
local table4 Zscores_female
local table4a Zscores_all
local table5 CountrySpecific
local table7 CrossCountry_ln_female
local table7a CrossCountry_ln_all

*FIGURES
local figure1a SchoolingRegion
local figure1b MMRRegion
local figure2 MMRMap
local figure3a Educ_Nigeria
local figure3b MMR_Nigeria
local figure4a Educ_Zimbabwe
local figure4b MMR_Zimbabwe
local figure5a Educ_Kenya
local figure5b MMR_Kenya

*SWITCHES
local fullsample no
local sumstats no
local MMRregs no
local MMRregion no
local MMRincome no
local Zscores no
local DHSsample yes
local countryspecific no

********************************************************************************
**** (1) Use and rename (for now `gender' has been replaced with F after _BASE_)
********************************************************************************
use $PATH/Data/MMReduc_BASE_F, clear
do $DO/UNESCO_naming.do
encode region_code, gen(region)
gen gender="F"
rename TeenBirths_t TeenBirths

********************************************************************************
***(2) Full sample graphs
********************************************************************************
if `"`fullsample'"'=="yes" {
	twoway scatter MMR year if age_all || lfit MMR year if age_all, ///
	title(Maternal Mortality by Year) subtitle(Points represent country average)
	graph export $GRAPHS/timetrend_MMR.eps, replace as(eps)

	**** Education over time
*	foreach educ of varlist lu- yr_sch_ter { 
*		twoway scatter `educ' year if age_all || lfit `educ' year if ///
*		age_all, title("Educational Achievement (F) by Year") ///
*		subtitle(Points represent country average)
*		graph export $GRAPHS/timetrend_`educ'_F.png, replace as(png)
*	}

	**** MMR versus education graphs
	foreach MMR of varlist ln_MMR MMR {
		if "`MMR'"=="ln_MMR" {
			local title "Log Maternal Mortality"
			local legend1 "ln(MMR)"
		}
		else if "`MMR'"=="MMR" {
			local title "Maternal Mortality"
			local legend1 "MMR"
		}
		twoway scatter `MMR' yr_sch if age_fert || lfit `MMR' yr_sch if ///
		age_fert, lcolor(black) range(0 12) || qfit `MMR' yr_sch if age_fert, ///
		lpattern(dash) lcolor(black) range(0 .) ///
		xlabel(0 "0" 5 "5" 10 "10" 15 "15") ///  
		note("Notes to figure: Each point represents a country average of maternal deaths per 100,000 births."  "Education data is for women aged 15-39.") ///
		legend(lab(1 "`legend1'") lab(2 "Fitted Values (linear)") ///
		lab(3 "Fitted Values (quadratic)")) scheme(s1color)
		graph export $GRAPHS/Schooling_`MMR'_F.eps, replace as(eps)
	}
}

********************************************************************************
***(3) Create macro dataset
********************************************************************************
*preserve
keep if age_all==1
*keep if age_fert==1
collapse $mmr $covars $educ, by(country year $classify)

label var yr_sch_pri "Primary Education (yrs)"
label var yr_sch_sec "Seconday Education (yrs)"	
label var yr_sch_ter "Tertiary Education (yrs)"
label var year "Year"
label var ln_GDPpc "log GDP per capita"
label var Immunization "Immunization (DPT)"
label var percentattend "Attended Births"
label var TeenBirths "Teen births"
label var lp "Percent ever enrolled in primary"
label var ls "Percent ever enrolled in secondary"
label var lh "Percent ever enrolled in tertiary"

gen yr_sch_sq=yr_sch*yr_sch
gen yr_pri_sq=yr_sch_pri*yr_sch_pri
gen yr_sec_sq=yr_sch_sec*yr_sch_sec
gen yr_ter_sq=yr_sch_ter*yr_sch_ter
gen atleastprimary=lp+ls+lh

xtset BLcode year

bys year: gen trend=_n
********************************************************************************
***(4) Summary stats
********************************************************************************
if `"`sumstats'"'=="yes" {
	local opts cells("count mean sd min max")
	local educsum yr_sch yr_sch_pr yr_sch_se yr_sch_te lp ls lh lu
	local title "Summary Stats for All Countries"

 	estpost sum $mmr $covars `educsum'
	estout using "$TABLES/`table2'.xls", replace `opts' title(`title')

	foreach year of numlist 1990(5)2010 {
		local title "Summary Stats for All Countries (`year')"
		estpost sum $mmr $covars `educsum' if year==`year'
		estout using "$TABLES/`table2'.xls", append `opts' title(`title')
	}


	preserve
	collapse yr_sch MMR, by(year region_code)
	tab region_code, gen(region)
	foreach outcome in yr_sch MMR {
		if `"`outcome'"'=="yr_sch" {
			local title "Years of Schooling by Region"
			local ylab ylabel(4 "4" 6 "6" 8 "8" 10 "10" 12 "12")
			local ytit ytitle("Years of Education")
			local save `figure1a'
		}
		else if `"`outcome'"'=="MMR" {
			local title "Maternal Mortalit|y Ratio by Region"
			local ylab ylabel(0 "0" 200 "200" 400 "400" 600 "600" 800 "800")
			local ytit ytitle("MMR")
			local save `figure1b'
		}

		twoway line `outcome' year if region1 || ///
		line `outcome' year if region2, lpattern(dash) || ///
		line `outcome' year if region3, lpattern(dot) || ///
		line `outcome' year if region4, lpattern(dash_dot) || ///
		line `outcome' year if region5, lpattern(longdash) || ///
		line `outcome' year if region6, lpattern(longdash_dot) || ///
		line `outcome' year if region7, lpattern(shortdash_dot) ///
		graphregion(color(white)) bgcolor(white) `ytit' `ylab' ///
		legend(lab(1 "Advanced Economies") lab(2 "East Asia") ///
		lab(3 "Europe/Central Asia") lab(4 "LAC") lab(5 "MENA") ///
		lab(6 "South Asia") lab(7 "SSA")) ///
		scheme(s1color)

		graph export $GRAPHS/`save'.eps, as(eps) replace
	}
	restore
}

********************************************************************************
***(5) MMR versus schooling regressions (tables 3 and 7)
********************************************************************************
local control1
local trend i.BLcode*trend
*local trend
tab year, gen(_year)
local control2 _year2 _year3 _year4 _year5
local control3 `control2' ln_GDPpc
local control4 `control3' Immunization
local control5 `control4' percentattend
local control6 `control5' fertility
local control7 `control6' TeenBirths
local opts fe vce(cluster BLcode)

if `"`MMRregs'"'=="yes" {
	xi: xtreg MMR `trend' `xvars', `opts'
	outreg2 `xvars' using $TABLES/`table3'.xls, excel replace label
	qui xi: xtreg MMR `xvars' `control7', `opts'

	foreach num of numlist 1(1)7 {
		xi: xtreg MMR `trend' `xvars' `control`num'' if e(sample), `opts'
		outreg2 `xvars' `control`num'' using $TABLES/`table3'.xls, excel append label
	}

	xi: xtreg ln_MMR `trend' `xvars', `options'
	outreg2 `xvars' using $TABLES/`table7'.xls, excel replace label
	qui xi: xtreg ln_MMR `xvars' `control7', `opts'

	foreach num of numlist 1(1)7 {
		xi: xtreg ln_MMR `trend' `xvars' `control`num'' if e(sample), `opts'
		outreg2 `xvars' `control`num'' using $TABLES/`table7'.xls, excel append label
	}
}


********************************************************************************
***(6) MMR versus schooling by region
********************************************************************************
if `"`MMRregion'"'=="yes" {
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
	
	cap rm $TABLES/`table3b'.xls
	cap rm $TABLES/`table3b'.txt

	foreach num of numlist 1(1)7 {
		qui xi: xtreg MMR `xvars' `control7' if region_code=="`r`num''", `opts'
	
		xi: xtreg MMR `xvars' `control2' if region_c=="`r`num''"&e(sample), `opts'
		outreg2 using $TABLES/`table3b'.xls, excel append label ctitle("`r`num''")
	}

	foreach num of numlist 1(1)7 {
		xi: xtreg MMR `xvars' `control7' if region_code=="`r`num''", `opts'
		outreg2 using $TABLES/`table3b'.xls, excel append label ctitle("`r`num''")
	}
}

********************************************************************************
***(7) MMR versus schooling by income
********************************************************************************
if `"`MMRincome'"'=="yes" {
	replace income2="LM" if income2=="Lower middle"
	replace income2="UM" if income2=="Upper middle"

	cap rm "$TABLES/`table3c'.xls"
	cap rm "$TABLES/`table3c'.txt"

	foreach i in Low LM UM High {
		qui xi: xtreg MMR `xvars' `control7' if income2=="`i'", `opts'
	
		xi: xtreg MMR `xvars' `control2' if e(sample)&income2=="`i'", `opts'
		outreg2 using "$TABLES/`table3c'.xls", excel append label ctitle("`i'")
	}

	foreach i in Low LM UM High {
		xi: xtreg MMR `xvars' `control7' if income2=="`i'", `opts'
		outreg2 using "$TABLES/`table3c'.xls", excel append label ctitle("`i'")
	}
}

********************************************************************************
***(8) Correlations between health and development outcomes (Zscores)
********************************************************************************
if `"`Zscores'"'=="yes" {
	cap rm "$TABLES/`table4'.xls"

	foreach v in fertility Immunization percentattend ln_GDPpc TeenBirths {
		egen z_`v'=std(`v')
		reg z_`v' `xvars', robust
		outreg2 using "$TABLES/`table4'.xls", excel append
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
