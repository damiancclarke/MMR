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
