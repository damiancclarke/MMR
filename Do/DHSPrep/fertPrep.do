/* fertPre.do    v0.00           damiancclarke             yyyy-mm-dd:2016-02-16
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8

*/

vers 11
clear all
set more off
cap log close
set maxvar 15000

********************************************************************************
*** (1) Globals and locals
********************************************************************************
global DAT "/media/damian/Impar1/database/DHS/DHS_Data"
global OUT "~/investigacion/Activa/MMR/Data/InputsToCreateBase"


********************************************************************************
*** (2) Generate fertility preferences
********************************************************************************
foreach file in 1 2 3 4 5 6 7 {
    dis "Working on file fertility `file'"
    use "$DAT/World_IR_p`file'", clear

    gen wifeNoMore  = v605 == 5 if v605<6
    gen husbandMore = v621 == 2 if v621<9
    gen husbandSame = v621 == 1 if v621<9
    gen husbandLess = v621 == 3 if v621<9

    rename v007 yearInterview
    replace yearInterview = yearInterview+1900 if yearInterview<114
    replace yearInterview = yearInterview+100  if yearInterview<1980
    replace yearInterview = yearInterview - 57 if _cou=="Nepal"

    replace v010 = v010 + 1900 if v010<100
    replace v010 = v010 - 57  if _cou=="Nepal"
    replace v010 = v010 + 100 if _cou=="Nepal" & v010<1900
    rename v010 birthYear

    keep wifeNoMore husband* yearInterview birthYear _cou _year
    tempfile f`file'
    save `f`file''
}

append using `f1' `f2' `f3' `f4' `f5' `f6'
gen age = yearInterview - birthYear

local files

foreach year of numlist 1980(1)2010 {
    preserve
    gen age`year' = `year' - birthYear
    keep if age`year'>=25&age`year'<=39
    collapse wifeNoMore husband*, by(_cou)
    gen year = `year'
    tempfile p`year'
    save `p`year''
    local files `files' `p`year''
    restore
}

clear
append using `files'
gen countryname = _cou
replace countryname = subinstr(countryname,"-"," ", .)
replace countryname = "Congo. Rep." if countryname == "Congo Brazzaville"
replace countryname = "Congo. Dem. Rep." if countryname == "Congo Democratic Republic"
replace countryname = "Cote d'Ivoire" if countryname == "Cote d Ivoire"
replace countryname = "Egypt. Arab Rep." if countryname == "Egypt"
replace countryname = "Yemen. Rep." if countryname == "Yemen"
	
preserve

********************************************************************************
*** (3) Merge in WB names
********************************************************************************
use "$OUT/control_GDPpc", clear
keep countryname countrycode
gen a = 1
collapse a, by(countryname countrycode)
drop a

tempfile countries
save `countries'
restore

merge m:1 countryname using `countries'
keep if _merge == 3
drop _merge

lab dat "Fertility Preferences calculated from all DHS surveys"
save "$OUT/control_fertilityPreferences", replace
