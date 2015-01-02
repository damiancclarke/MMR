/* setupExperiments.do v1.00     damiancclarke             yyyy-mm-dd:2014-12-26
----|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8




*/

vers 11
clear all
set more off
cap log close
set maxvar 20000

*********************************************************************************
*** (1) Globals, locals, tempfiles
*********************************************************************************
global DAT "~/database/DHS/DHS_Data"
global OUT "~/investigacion/Activa/MMR/Data"
global LOG "~/investigacion/Activa/MMR/Log"

log using "$LOG/setupExperiments.txt", text replace

local Ken 0
local Nig 1
local Zim 0

*********************************************************************************
*** (2a) Nigeria Generate
*********************************************************************************
if `Nig'==1 {
    local sy 41 52
    tokenize `sy'

    **EDUC
    foreach year of numlist 1999 2008 {
        use "$DAT/Nigeria/`year'/NGIR`1'DT", clear

        rename v133 education
        rename v010 yearbirth
        replace yearbirth=yearbirth+1900 if yearbirth<100
        gen DHSyear=`year'
        cap rename sstate sstate1
        keep education yearbirth DHSyear v009 v005 sstate s119 v130

        tempfile e`year'
        save `e`year''
        macro shift
    }
    clear
    append using `e1999' `e2008'
    tempfile educ
    save `educ'

    **MMR
    tokenize `sy'
    foreach year of numlist 1999 2008 {
        use "$DAT/Nigeria/`year'/NGIR`1'DT"
        keep caseid v005 mm* sstate s119 v130 v007

        local Mvars1 mmidx_ mm1_ mm2_ mm3_ mm4_ mm5_ mm6_ mm7_ mm8_ mm9_ 
        local Mvars2 mm10_ mm11_ mm12_ mm13_ mm14_ mm15_
        local MMRvars `Mvars1' `Mvars2'

        foreach var of local MMRvars  { 
            foreach num of numlist 1(1)9 { 
                rename `var'0`num' `var'`num'
            }
        }
        cap drop  mmc1- mmc5

        reshape long `MMRvars', i(caseid) j(sister)
        drop if mmidx==.
 
        gen mmr=1 if (mm9_>1 & mm9_<7) & mm1_==2
        gen mmr_alt=1 if mm9_==2|mm9_==3
        replace mmr=0 if mmr!=1 & mm1_==2 & mm9_!=99
        replace mmr_alt=0 if mmr_alt!=1&mm9==.&mm1_==2&mm2_==1
        gen numkids=mm14_
        keep if mm1_==2
		
        gen yearbirth=int((mm4_-1)/12)
        gen v009=mm4_-(yearbirth*12)
        replace yearbirth=yearbirth+1900 if yearbirth<200
        sum yearbirth

        gen yearinterview=v007
        replace yearinterview=1900+yearinterview if yearinterview<120
        gen age=yearinterview-yearbirth
        gen mmr_25=1 if (mm9_>1 & mm9_<7)&mm1_==2&mm7_<=25
        replace mmr_25=0 if mmr_25!=1&mm1_==2&mm9_!=99

        label var mmr "Sibling death related to child birth"
        label var yearbirth "year of birth of sibling"

        replace v007=v007+1900 if v007<100&v007>1
        replace v007=v007+2000 if v007<2
        gen age_sib_atinterview=v007-yearbirth
		
        gen DHSyear=`year'
        cap rename sstate sstate1
		
        keep mmr* v005 sstate* yearbirth DHSyear s119 v009 v130 numkids /*
        */ mmr_alt yearinterview age

        tempfile mmr`year'
        save `mmr`year''
        macro shift
    }
    clear
    append using `mmr1999' `mmr2008'
    tempfile mmr
    save `mmr'
}


*********************************************************************************
*** (2b) Nigeria Controls (from Akresh et al 2012)
*********************************************************************************
#delimit ;
local s1976 Cross-River Cross-River Cross-River Cross-River Imo Imo Imo Imo
Anambra Anambra Anambra Anambra Anambra Anambra Rivers Rivers Rivers Rivers
Bendel Bendel Bendel Bendel Lagos Lagos Ogun Ogun Ondo Ondo Ondo Ondo Oyo Oyo
Oyo Oyo Benue Benue Plateau Plateau Plateau Plateau Kano Kano Kano Kano Kwara
Kwara Kwara Kwara Kaduna Kaduna Kaduna Kaduna Niger Niger Sokoto Sokoto Sokoto
Sokoto Sokoto Sokoto Bauchi Bauchi Bauchi Bauchi Borno Borno Borno Borno Gongola
Gongola Gongola Gongola;
local n1976 1 7 290 300 22 9 310 320 2 24 32 260 270 280 20 31 330 340 4 23 250
350 1 360 16 370 17 33 230 240 18 28 210 220 5 180 19 35 150 160 11 25 40 100 13
27 190 200 10 12 30 110 15 130 26 21 36 10 20 120 3 34 80 90 6 30 50 60 8 29 70
170;
local s1967 South-Eastern East-Central East-Central Rivers Mid-Western Lagos
Western Western Western Benue-Plateau Benue-Plateau Kano Kwaro North-Central
North-Western North-Western North-Eastern North-Eastern North-Eastern; 
local n1967 Cross-River Imo Anambra Rivers Bendel Lagos Ogun Ondo Oyo Benue
Plateau Kano Kwaro Kaduna Niger Sokoto Borno Gongola Bauchi;
#delimit cr

if `Nig'==1 {
    foreach file in mmr educ {
        use ``file''

        gen states1976=""
        tokenize `n1976'
        foreach state of local s1976 {
            dis "state `state', from `1'"
            replace states1976="`state'" if sstate==`1'
            macro shift
        }

        gen states1967=""
        tokenize `n1967'
        foreach state of local s1967 {
            dis "state `state', from `1'"
            replace states1967="`state'" if states1976=="`1'"
            macro shift
        }
        drop states1976 states1967
        gen states1976=""
        replace states1976="Cross-River" if sstate==1|sstate==7
        replace states1976="Imo" if sstate==22|sstate==9
        replace states1976="Anambra" if sstate==2|sstate==24|sstate==32
        replace states1976="Rivers" if sstate==20|sstate==31
        replace states1976="Bendel" if sstate==4|sstate==23
        replace states1976="Lagos" if sstate==1
        replace states1976="Ogun" if sstate==16
        replace states1976="Ondo" if sstate==17|sstate==33
        replace states1976="Oyo" if sstate==18|sstate==28
        replace states1976="Benue" if sstate==5
        replace states1976="Plateau" if sstate==19|sstate==35
        replace states1976="Kano" if sstate==11|sstate==25
        replace states1976="Kwara" if sstate==13|sstate==27
        replace states1976="Kaduna" if sstate==10|sstate==12
        replace states1976="Niger" if sstate==15
        replace states1976="Sokoto" if sstate==26|sstate==21|sstate==36
        replace states1976="Bauchi" if sstate==3|sstate==34
        replace states1976="Borno" if sstate==6|sstate==30
        replace states1976="Gongola" if sstate==8|sstate==29

        replace states1976="Cross-River" if sstate1==290|sstate1==300
        replace states1976="Imo" if sstate1==310|sstate1==320
        replace states1976="Anambra" if sstate1==260|sstate1==270|sstate1==280
        replace states1976="Rivers" if sstate1==330|sstate1==340
        replace states1976="Bendel" if sstate1==250|sstate1==350
        replace states1976="Lagos" if sstate1==360
        replace states1976="Ogun" if sstate1==370
        replace states1976="Ondo" if sstate1==230|sstate1==240
        replace states1976="Oyo" if sstate1==210|sstate1==220
        replace states1976="Benue" if sstate1==180
        replace states1976="Plateau" if sstate1==150|sstate1==160
        replace states1976="Kano" if sstate1==40|sstate1==100
        replace states1976="Kwara" if sstate1==190|sstate1==200
        replace states1976="Kaduna" if sstate1==30|sstate1==110
        replace states1976="Niger" if sstate1==130
        replace states1976="Sokoto" if sstate1==10|sstate1==20|sstate1==120
        replace states1976="Bauchi" if sstate1==80|sstate1==90
        replace states1976="Borno" if sstate1==50|sstate1==60
        replace states1976="Gongola" if sstate1==70|sstate1==170

        gen states1967=""
        replace states1967="South-Eastern" if states1976=="Cross-River"
        replace states1967="East Central" if states1976=="Imo" | states1976=="Anambra"
        replace states1967="Rivers" if states1976=="Rivers"
        replace states1967="Mid Western" if states1976=="Bendel"
        replace states1967="Lagos" if states1976=="Lagos"
        replace states1967="Western" if states1976=="Ogun" | states1976=="Ondo" |states1976=="Oyo"
        replace states1967="Benue-Plateau" if states1976=="Benue"|states1976=="Plateau"
        replace states1967="Kano" if states1976=="Kano"
        replace states1967="Kwaro" if states1976=="Kwara"
        replace states1967="North Central" if states1976=="Kaduna"
        replace states1967="North Western" if states1976=="Niger"|states1976=="Sokoto"
        replace states1967="North Eastern" if states1976=="Bauchi"|states1976=="Borno"|states1976=="Gongola"

        encode states1976, gen(stcode1976)
        encode states1967, gen(stcode1967)

        gen capexp53=.
        replace capexp53=0.014032 if states1976=="Oyo"
        replace capexp53=0.019337 if states1976=="Ogun"
        replace capexp53=0.0326675 if states1976=="Ondo"
        replace capexp53=0.3346587 if states1976=="Borno"
        replace capexp53=0.3906393 if states1976=="Anambra"
        replace capexp53=0.5194563 if states1976=="Lagos"
        replace capexp53=0.7643318 if states1976=="Kaduna"
        replace capexp53=0.8127252 if states1976=="Rivers"
        replace capexp53=0.8833631 if states1976=="Imo"
        replace capexp53=0.9319166 if states1976=="Kano"
        replace capexp53=0.9527855 if states1976=="Sokoto"
        replace capexp53=1.011883 if states1976=="Kwara"
        replace capexp53=1.022602 if states1976=="Bauchi"
        replace capexp53=1.050629 if states1976=="Gongola"
        replace capexp53=1.322434 if states1976=="Bendel"
        replace capexp53=1.580796 if states1976=="Niger"
        replace capexp53=1.631959 if states1976=="Plateau"
        replace capexp53=1.9002 if states1976=="Benue"
        replace capexp53=2.195955 if states1976=="Cross-River"

        gen capexp63=.
        replace capexp63=0.24 if states1976=="Oyo"
        replace capexp63=0.15 if states1976=="Ogun"
        replace capexp63=0.19 if states1976=="Ondo"
        replace capexp63=6.19 if states1976=="Borno"
        replace capexp63=1.64 if states1976=="Anambra"
        replace capexp63=0.76 if states1976=="Lagos"
        replace capexp63=2.15 if states1976=="Kaduna"
        replace capexp63=2.41 if states1976=="Rivers"
        replace capexp63=2.26 if states1976=="Imo"
        replace capexp63=1.49 if states1976=="Kano"
        replace capexp63=1.31 if states1976=="Sokoto"
        replace capexp63=3.95 if states1976=="Kwara"
        replace capexp63=0.87 if states1976=="Bauchi"
        replace capexp63=1.02 if states1976=="Gongola"
        replace capexp63=2.91 if states1976=="Bendel"
        replace capexp63=1.20 if states1976=="Niger"
        replace capexp63=2.20 if states1976=="Plateau"
        replace capexp63=0.92 if states1976=="Benue"
        replace capexp63=2.43 if states1976=="Cross-River"
	
gen ethnicity=1 if (s119==94&DHSyear==1999)|(s119==138&DHSyear==2008)
replace ethnicity=2 if ((s119==21|s119==85|s119==91|s119==133|s119==140|s119==153|s119==154|s119==241|s119==283)&DHSyear==2008)
replace ethnicity=2 if ((s119==1|s119==8|s119==55|s119==58|s119==90|s119==95|s119==96|s119==97|s119==175|s119==203)&DHSyear==1999)
replace ethnicity=3 if (s119==86&DHSyear==1999)|(s119==130&DHSyear==2008)
replace ethnicity=4 if (s119==218&DHSyear==1999)|(s119==298&DHSyear==2008)
replace ethnicity=5 if ethnicity==.

gen religion=1 if (v130==4&DHSyear==1999)|(v130==3&DHSyear==2008)
replace religion=2 if (v130==1&DHSyear==1999)|(v130==1&DHSyear==2008)
replace religion=3 if (v130==3&DHSyear==1999)|(v130==2&DHSyear==2008)
replace religion=4 if (v130==5&DHSyear==1999)|(v130==4&DHSyear==2008)
replace religion=5 if religion==.

gen west=(states1976=="Lagos"|states1976=="Ogun"|states1976=="Ondo"|states1976=="Oyo")
gen nonwest=west==0
gen SE=(states1976=="Cross-River"|states1976=="Anambra"|states1976=="Imo"|states1976=="Rivers")
gen SW=(states1976=="Lagos"|states1976=="Ogun"|states1976=="Oyo"|states1976=="Ondo"|states1976=="Bendel")
gen nonwest_noSE=(nonwest==1&SE==0)

gen yr5055=yearbirth>=1950&yearbirth<=1955
gen yr5664=yearbirth>=1956&yearbirth<=1964
gen yr5660=yearbirth>=1956&yearbirth<=1960
gen yr5661=yearbirth>=1956&yearbirth<=1961
gen yr6064=yearbirth>=1960&yearbirth<=1964
gen yr7075=yearbirth>=1970&yearbirth<=1975
gen yr7175=yearbirth>=1971&yearbirth<=1975
gen yr6575=yearbirth>=1965&yearbirth<=1975
gen yr6265=yearbirth>=1962&yearbirth<=1965
gen yr7072=yearbirth>=1970&yearbirth<=1972
gen yr7073=yearbirth>=1970&yearbirth<=1973
gen yr6569=yearbirth>=1965&yearbirth<=1969
gen yr6769=yearbirth>=1967&yearbirth<=1969

gen main_exposure=1 if yearbirth==1975
replace main_exposure=2 if yearbirth==1974
replace main_exposure=3 if yearbirth==1973
replace main_exposure=4 if yearbirth==1972
replace main_exposure=5 if yearbirth==1971
replace main_exposure=5 if yearbirth==1970
replace main_exposure=0 if main_exposure==.

gen main_exposure_fake=1 if yearbirth==1956
replace main_exposure_fake=2 if yearbirth==1957
replace main_exposure_fake=3 if yearbirth==1958
replace main_exposure_fake=4 if yearbirth==1959
replace main_exposure_fake=5 if yearbirth==1960
replace main_exposure_fake=0 if main_exposure_fake==.

gen pre_exposure=1 if yearbirth==1966
replace pre_exposure=2 if yearbirth==1967
replace pre_exposure=3 if yearbirth==1968
replace pre_exposure=4 if yearbirth==1969
replace pre_exposure=0 if pre_exposure==.

	dis "mexp0"
gen mexp0=1 if v009==8&yearbirth==1967
replace mexp0=2 if v009==9&yearbirth==1967
replace mexp0=3 if v009==10&yearbirth==1967
replace mexp0=4 if v009==11&yearbirth==1967
replace mexp0=5 if v009==12&yearbirth==1967
replace mexp0=6 if v009==1&yearbirth==1968
replace mexp0=7 if v009==2&yearbirth==1968
replace mexp0=8 if v009==3&yearbirth==1968
replace mexp0=9 if v009==4&yearbirth==1968
replace mexp0=9 if yearbirth==1968&mexp0==.
replace mexp0=9 if yearbirth==1969&v009<3
replace mexp0=8 if v009==3&yearbirth==1969
replace mexp0=7 if v009==4&yearbirth==1969
replace mexp0=6 if v009==5&yearbirth==1969
replace mexp0=5 if v009==6&yearbirth==1969
replace mexp0=4 if v009==7&yearbirth==1969
replace mexp0=3 if v009==8&yearbirth==1969
replace mexp0=2 if v009==9&yearbirth==1969
replace mexp0=1 if v009==10&yearbirth==1969
replace mexp0=0 if mexp0==.

	dis "mexp1"
gen mexp1=v009-7 if yearbirth==1964&v009>7
replace mexp1=v009+5 if yearbirth==1965
replace mexp1=v009+17 if yearbirth==1966
replace mexp1=30 if yearbirth==1967&(v009==1|v009==8)
replace mexp1=31 if yearbirth==1967&v009>1&v009<8
replace mexp1=38-v009 if yearbirth==1967&v009>9
replace mexp1=26-v009 if yearbirth==1968
replace mexp1=14-v009 if yearbirth==1969
replace mexp1=1 if yearbirth==1970&v009==1
replace mexp1=0 if mexp1==.

	dis "mexp2"
gen mexp2=v009-7 if yearbirth==1961&v009>7
replace mexp2=v009+5 if yearbirth==1962
replace mexp2=v009+17 if yearbirth==1963
replace mexp2=30 if yearbirth==1964&(v009==1|v009==8)
replace mexp2=31 if yearbirth==1964&v009>1&v009<8
replace mexp2=38-v009 if yearbirth==1964&v009>9
replace mexp2=26-v009 if yearbirth==1965
replace mexp2=14-v009 if yearbirth==1966
replace mexp2=1 if yearbirth==1967&v009==1
replace mexp2=0 if mexp2==.

	dis "mexp3"
gen mexp3=v009-7 if yearbirth==1955&v009>7
replace mexp3=v009+5 if yearbirth==1956
replace mexp3=v009+17 if yearbirth==1957
replace mexp3=30 if yearbirth==1958&v009==1
replace mexp3=31 if yearbirth==1958&v009>1
replace mexp3=31 if yearbirth==1959
replace mexp3=31 if yearbirth==1960
replace mexp3=31 if yearbirth==1961&v009<8
replace mexp3=38-v009 if yearbirth==1961&v009>7
replace mexp3=26-v009 if yearbirth==1962
replace mexp3=14-v009 if yearbirth==1963
replace mexp3=1 if yearbirth==1964&v009==1
replace mexp3=0 if mexp3==.

	dis "mexp4"
gen mexp4=v009-7 if yearbirth==1951&v009>7
replace mexp4=v009+5 if yearbirth==1952
replace mexp4=v009+17 if yearbirth==1953
replace mexp4=30 if yearbirth==1954&v009==1
replace mexp4=31 if yearbirth==1954&v009!=1
replace mexp4=31 if yearbirth==1955&v009<8
replace mexp4=38-v009 if yearbirth==1955&v009>7
replace mexp4=26-v009 if yearbirth==1956
replace mexp4=14-v009 if yearbirth==1957
replace mexp4=1 if yearbirth==1958&v009==1
replace mexp4=0 if mexp4==.

gen war_region=(states1976=="Cross-River"|states1976=="Anambra"|states1976=="Imo"|states1976=="Rivers")

gen yr5660nonwest=yr5660*nonwest
gen yr5661nonwest=yr5661*nonwest
gen yr6265nonwest=yr6265*nonwest
gen yr7075nonwest=yr7075*nonwest
gen yr6569nonwest=yr6569*nonwest
gen yr5660capexp53=yr5660*capexp53
gen yr5661capexp53=yr5661*capexp53
gen yr6265capexp53=yr6265*capexp53
gen yr7075capexp53=yr7075*capexp53
gen yr6569capexp53=yr6569*capexp53
gen yr5661capexp63=yr5661*capexp63
gen yr6265capexp63=yr6265*capexp63
gen yr7075capexp63=yr7075*capexp63
gen yr6569capexp63=yr6569*capexp63
gen nonwest_main_exposure=nonwest*main_exposure
gen nonwest_pre_exposure=nonwest*pre_exposure
gen nonwest_main_exposure_fake=nonwest*main_exposure_fake
gen capexp53_main_exposure=capexp53*main_exposure
gen capexp53_pre_exposure=capexp53*pre_exposure
gen capexp63_main_exposure=capexp63*main_exposure
gen capexp63_pre_exposure=capexp63*pre_exposure
gen capexp53_main_exposure_fake=capexp53*main_exposure_fake

gen yr6769southeast=yr6769*SE
gen yr6769nonwest_noSE=yr6769*nonwest_noSE
gen reg_mexp0=war_region*mexp0
gen reg_mexp1=war_region*mexp1
gen reg_mexp2=war_region*mexp2
gen reg_mexp3=war_region*mexp3
gen reg_mexp4=war_region*mexp4

qui sum yearbirth
gen trend=yearbirth-(r(min)-1)
	
save "$OUT/Nigeria/`file'", replace
    }
}
exit

*********************************************************************************
*** (3) Zimbabwe
*********************************************************************************
if `"`Zimbabwe'"'=="yes" {
	tempfile educ1994 educ1999 educ2005 educ2010
	tempfile mmr1994 mmr1999 mmr2005 mmr2010
	
	foreach y of numlist 1994 1999 2005 2010 {
	if `"`y'"'=="1994" local survey=31
	else if `"`y'"'=="1999" local survey=42
	else if `"`y'"'=="2005" local survey=51
	else if `"`y'"'=="2010" local survey=61		
		
	use "$DATA/Zimbabwe/`y'/ZWIR`survey'DT"

	if `"`y'"'=="1994" {
		replace v007=v007+1900
		replace v010=v010+1900	
	}
	rename v133 education
	rename v010 yearbirth
	rename v009 monthbirth
	rename v012 age
 	rename v007 yearinterview
	rename v006 monthinterview 
	gen highschool=(v106==2|v106==3)
	gen rural=v025==2

	keep education yearbirth monthbirth age yearinterview /*
	*/ monthinterview highschool rural v024 v005 mm* caseid
	gen age1980=age-((yearinterview-1980)+((monthinterview-1)/12))
	replace age1980=floor(age1980)

	gen dumage=age1980<=14
	gen age1980less14=age1980-14

	gen dumageXage1980less14=dumage*age1980less14
	gen invdumageXage1980less14=(1-dumage)*age1980less14
 	gen dumage14sq=dumageXage1980less14^2
	gen invdumage14sq=invdumageXage1980less14^2
 	gen dumage14th=dumageXage1980less14^3
	gen invdumage14th=invdumageXage1980less14^3

	gen dumage_alt=age1980<=20
	gen age1980less20=age1980-20

	gen dumageXage1980less20_alt=dumage_alt*age1980less20
	gen invdumageXage1980less20_alt=(1-dumage_alt)*age1980less20
 	gen dumage20sq=dumageXage1980less20^2
	gen invdumage20sq=invdumageXage1980less20^2
 	gen dumage20th=dumageXage1980less20^3
	gen invdumage20th=invdumageXage1980less20^3
		
	gen DHSyear=`y'	
	save `educ`y''	
		
 	keep caseid v005 mm* yearinterview monthinterview v024 rural
	local MMRvars mmidx_ mm1_ mm2_ mm3_ mm4_ mm5_ mm6_ mm7_ mm8_ mm9_ mm10_ /*
   */ mm11_ mm12_ mm13_ mm14_ mm15_
	foreach var of local MMRvars  { 
		foreach num of numlist 1(1)9 { 
			rename `var'0`num' `var'`num'
		}
	}
 	cap drop  mmc1- mmc5

	reshape long `MMRvars', i(caseid) j(sister)
	drop if mmidx==.
 
	gen mmr=1 if (mm9_>1 & mm9_<7) & mm1_==2
	replace mmr=0 if mmr!=1 & mm1_==2 & mm9_!=99
	gen numkids=mm14_
	keep if mm1_==2

	gen yearbirth=int((mm4_-1)/12)
	gen monthbirth=mm4_-(yearbirth*12)
	replace yearbirth=yearbirth+1900 if yearbirth<200
	
	label var mmr "Sibling death related to child birth"
	label var yearbirth "year of birth of sibling"

	replace yearinterview=1900+yearinterview if yearinterview<120
	gen age=(yearinterview-yearbirth)+((monthinterview-monthbirth)/12)
	gen mmr_25=1 if (mm9_>1 & mm9_<7)&mm1_==2&mm7_<=25
	replace mmr_25=0 if mmr_25!=1&mm1_==2&mm9_!=99

	gen age1980=age-((yearinterview-1980)+((monthinterview-1)/12))
	replace age1980=floor(age1980)

	gen dumage=age1980<=14
	gen age1980less14=age1980-14
	
	gen dumageXage1980less14=dumage*age1980less14
	gen invdumageXage1980less14=(1-dumage)*age1980less14
 	gen dumage14sq=dumageXage1980less14^2
	gen invdumage14sq=invdumageXage1980less14^2
 	gen dumage14th=dumageXage1980less14^3
	gen invdumage14th=invdumageXage1980less14^3
				
	gen dumage_alt=age1980<=20
	gen age1980less20=age1980-20

	gen dumageXage1980less20_alt=dumage_alt*age1980less20
	gen invdumageXage1980less20_alt=(1-dumage_alt)*age1980less20
 	gen dumage20sq=dumageXage1980less20^2
	gen invdumage20sq=invdumageXage1980less20^2
 	gen dumage20th=dumageXage1980less20^3
	gen invdumage20th=invdumageXage1980less20^3
		
	gen DHSyear=`y'

	save `mmr`y''
	}

	use `educ1994'
	append using `educ1999' `educ2005' `educ2010'
	save $PATH/Data/Zimbabwe/educ, replace

	use `mmr1994'
	append using `mmr1999' `mmr2005' `mmr2010'
	save $PATH/Data/Zimbabwe/mmr, replace
}

*********************************************************************************
*** (4) Kenya
*********************************************************************************
if `"`Kenya'"'=="yes" {
	tempfile educ1993 educ1998 educ2003 educ2008
	tempfile mmr1993 mmr1998 mmr2003 mmr2008
	foreach y of numlist 1998 2003 2008 {

		if `"`y'"'=="1993" local survey=33
		else if `"`y'"'=="1998" local survey 3A
		else if `"`y'"'=="2003" local survey=42
		else if `"`y'"'=="2008" local survey=52
		
		use $DATA/Kenya/`y'/KEIR`survey'DT

		rename v133 education
		rename v010 yearbirth
		rename v009 monthbirth
		rename v012 age
		rename v007 yearinterview
		rename v006 monthinterview
		gen highschool=(v106==2|v106==3)
		gen rural=v025==2
		rename v131 ethnicity
		replace ethnicity=. if ethnicity==99

		keep caseid education yearbirth monthbirth age yearinterview monthinterview /*
		*/ highschool rural ethnicity v005 v024 mm*
		gen birthquarter=1 if monthbirth<4
		replace birthquarter=2 if monthbirth>=4&monthbirth<7
		replace birthquarter=3 if monthbirth>=7&monthbirth<10
		replace birthquarter=4 if monthbirth>=10&monthbirth<13

		replace yearbirth=yearbirth+1900 if yearbirth<200
		keep if yearbirth>1949&yearbirth<1981
		gen quarter=(yearbirth-1950)*4+birthquarter
		gen treat=0 if yearbirth<=1963
		replace treat=(quarter-56)*(1/32) if yearbirth>1963&yearbirth<1972
		replace treat=1 if yearbirth>=1972
		gen treat_false=0 if yearbirth<=1955
 		replace treat_false=(quarter-24)*(1/32) if yearbirth>1955&yearbirth<1964
		replace treat_false=1 if yearbirth>=1964
		
		gen DHSyear=`y'
		gen age2=age^2
		gen age3=age^3
		gen trend=quarter
		gen trend2=trend^2
		save `educ`y''

		keep caseid v005 mm* yearinterview monthinterview v024 rural ethnicity
		local MMRvars mmidx_ mm1_ mm2_ mm3_ mm4_ mm5_ mm6_ mm7_ mm8_ mm9_ mm10_ /*
		*/ mm11_ mm12_ mm13_ mm14_ mm15_
		foreach var of local MMRvars  { 
			foreach num of numlist 1(1)9 { 
				rename `var'0`num' `var'`num'
			}
		}
		cap drop  mmc1- mmc5

		*NB: mm8 is age at death
		reshape long `MMRvars', i(caseid) j(sister)
		drop if mmidx==.
 
		gen mmr=1 if (mm9_>1 & mm9_<7) & mm1_==2
		replace mmr=0 if mmr!=1 & mm1_==2 & mm9_!=99
		gen numkids=mm14_
		keep if mm1_==2
		
		gen yearbirth=int((mm4_-1)/12)
		gen monthbirth=mm4_-(yearbirth*12)
		replace yearbirth=yearbirth+1900 if yearbirth<200

		replace yearinterview=1900+yearinterview if yearinterview<120
		gen age=yearinterview-yearbirth
		gen mmr_25=1 if (mm9_>1 & mm9_<7)&mm1_==2&mm7_<=25
		replace mmr_25=0 if mmr_25!=1&mm1_==2&mm9_!=99
	
		label var mmr "Sibling death related to child birth"
		label var yearbirth "year of birth of sibling"

		gen birthquarter=1 if monthbirth<4
		replace birthquarter=2 if monthbirth>=4&monthbirth<7
		replace birthquarter=3 if monthbirth>=7&monthbirth<10
		replace birthquarter=4 if monthbirth>=10&monthbirth<13

		replace yearbirth=yearbirth+1900 if yearbirth<200
		keep if yearbirth>1949&yearbirth<1981
		gen quarter=(yearbirth-1950)*4+birthquarter
		gen treat=0 if yearbirth<=1963
		replace treat=(quarter-56)*(1/32) if yearbirth>1963&yearbirth<1972
		replace treat=1 if yearbirth>=1972
		gen treat_false=0 if yearbirth<=1955
 		replace treat_false=(quarter-24)*(1/32) if yearbirth>1955&yearbirth<1964
		replace treat_false=1 if yearbirth>=1964
		
		gen age2=age^2
		gen age3=age^3
		gen trend=quarter
		gen trend2=trend^2
		save `mmr`y''
	}
	use `educ1998'
	append using `educ2003' `educ2008'
	save $PATH/Data/Kenya/educ, replace

	use `mmr1998'
	append using `mmr2003' `mmr2008'
	save $PATH/Data/Kenya/mmr, replace	
}
