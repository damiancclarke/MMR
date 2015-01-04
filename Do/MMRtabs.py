# MMRtabs.py v0.00               damiancclarke             yyyy-mm-dd:2014-12-30
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This script takes summary statistics and regressions results sent out from the 
# scripts analysisMMR.do and naturalExperiments.do and formats them as tables f-
# or inclusion in the paper "Maternal Education and Maternal Mortality: Evidence 
# from a Large Panel and Various Natural Experiments".
# 
# The script is written for Python version 2.x, and its usage is:
#
#    python MMRtabs.py tex
#    python MMRtabs.py csv
#
# depending upon whether tables should be output in LaTeX format, or as csv form-
# for inclusion in excel/word documents.
#
# contact mailto:damian.clarke@economics.ox.ac.uk

from sys import argv
import re, os
#import locale
#locale.setlocale(locale.LC_ALL, 'en_US')

script, ftype = argv
print '\n The script %s is making %s files \n' %(script, ftype)

#-------------------------------------------------------------------------------
# --- (1) File names
#-------------------------------------------------------------------------------
result = '/home/damiancclarke/investigacion/Activa/MMR/Results/tables/'
tables = '/home/damiancclarke/investigacion/Activa/MMR/Paper/tables/'

sums = 'SumStats.xls'
mmra = 'CrossCountry_female.txt'
regn = 'CrossCountry_region.txt'
incm = 'CrossCountry_income.txt'
corr = 'Zscores_female.txt'
gend = 'CrossCountry_gender.txt'
mmry = 'CrossCountry_female_yrs.txt'
mmrs = 'CrossCountry_female_yrssq.txt'
gens = 'CrossCountry_gender_yrssq.txt'
ngra = 'Nigeria.txt'
ngaP = 'NigeriaPlacebo.txt'

#-------------------------------------------------------------------------------
# --- (2) csv or tex options
#-------------------------------------------------------------------------------
if ftype=='tex':
    dd = '&'
    dd1  = "&\\begin{footnotesize}"
    dd2  = "\\end{footnotesize}&"
    dd3  = "\\end{footnotesize}"
    end  = "tex"
    foot = "$^{*}$p$<$0.1; $^{**}$p$<$0.05; $^{***}$p$<$0.01"
    ls   = "\\\\"
    mr   = '\\midrule'
    hr   = '\\hline'
    tr   = '\\toprule'
    br   = '\\bottomrule'
    mc1  = '\\multicolumn{'
    mcsc = '}{l}{\\textsc{'
    mcbf = '}{l}{\\textbf{'
    mc2  = '}}'
    mc3  = '{\\begin{footnotesize}\\textsc{Notes:} '
    cadd = ['6','9','9','9','8','5','6','5','5']
    ccm  = ['}{p{12.5cm}}','}{p{20cm}}','}{p{17.2cm}}','}{p{18.8cm}}',
    '}{p{20cm}}','}{p{12.5cm}}','}{p{17.7cm}}','}{p{12.7cm}}','}{p{12cm}}']

elif ftyoe=='csv':
    dd = ';'
    dd1  = ";"
    dd2  = ";"
    dd3  = ";"
    end  = "csv"
    foot = "* p<0.1, ** p<0.05, *** p<0.01"
    ls   = ""
    mr   = ""
    hr   = ""
    br   = ""
    tr   = ""
    mc1  = ''
    mcsc = ''
    mcbf = ''
    mc2  = ''
    mc3  = 'NOTES: '
    cadd = ['','','','','','','','','','','','','','']
    ccm  = ['','','','','','','','','','','','','','']

#-------------------------------------------------------------------------------
# --- (3) Sum stats
#-------------------------------------------------------------------------------
summi = open(result + sums, 'r')
summo = open(tables + 'sumStats.' + end, 'w')

def is_number(s):
    try:
        float(s)
        return True
    except ValueError:
        return False

if ftype=='tex':
    summo.write('\\begin{table}[htpb!]\\begin{center}\n'
    '\\caption{Summary Statistics - Cross Country}\\label{MMRtab:sumstats}\n'
    '\\begin{tabular}{lccccc}\n'
    '&&&&& \\\\ \\toprule Variable&Obs&Mean&Std. Dev.&Min&Max\\\\\\midrule \n')
elif ftype=='csv':
    summo.write('Variable;Obs;Mean;Std. Dev.;Min;Max \n')

for i,line in enumerate(summi):
    if i>2 and i<20:
        newline= []
        words = line.split()
        for word in words:
            if is_number(word):
                word = str(float('%.3E' % float(word)))
                newline.append(word)
            else:
                newline.append(word)

        newline.append('\n')
        spl = '\t'
        line = spl.join(newline)
        
        line = re.sub(r"\s+",dd,line)
        line=re.sub(r"&$", ls+ls, line)

        line=line.replace('ln_MMR'       ,'ln(Maternal Mortality)'      )
        line=line.replace('MMR'          ,'Maternal Mortality'          )
        line=line.replace('ln_GDPpc'     ,'ln(GDP per capita)'          )
        line=line.replace('GDPpc'        ,'GDP per capita'              )
        line=line.replace('TeenBirths'   ,'Teen Births'                 )
        line=line.replace('percentattend','Percent Attended Births'     )
        line=line.replace('population'   ,'Population (Millions) '      )
        line=line.replace('fertility'    ,'Fertility'                   )
        line=line.replace('yr_sch_pri'   ,'Years of Primary Education'  )
        line=line.replace('yr_sch_sec'   ,'Years of Secondary Education')
        line=line.replace('yr_sch_ter'   ,'Years of Tertiary Education' )
        line=line.replace('yr_sch'       ,'Total Years of Education'    )
        line=line.replace('lp'           ,'Percent Primary'             )
        line=line.replace('ls'           ,'Percent Secondary'           )
        line=line.replace('lh'           ,'Percent Tertiary'            )
        line=line.replace('lu'           ,'Percent No Education'        )

        if ftype=='tex':
            line=re.sub('Total','\\midrule\\multicolumn{6}{l}{\\\\textsc{'+
            'Education - Female}} \\\\\\ \n Total',line)

        summo.write(line+'\n')

summo.write(
mr+'\n'+mc1+cadd[0]+ccm[0]+mc3+'Maternal mortality is expressed in terms of ' 
'deaths per 100,000 live births. Immunization is expressed as the percent of '
'children of ages 12-23 months who are immunized against diphtheria, pertussis'
' and tetanus (DPT). Fertility represents births per woman, and teen births are'
' expressed as the number of births per 1000 women between the ages of 15--19.')
if ftype=='tex':
    summo.write('\\end{footnotesize}} \\\\ \\bottomrule '
    '\\end{tabular}\\end{center}\\end{table}')

summo.close()

#-------------------------------------------------------------------------------
# --- (4) MMR tables
#-------------------------------------------------------------------------------
mmri = open(result + mmra, 'r')
mmro = open(tables + 'MMRpercent.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{landscape}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results of MMR and Female Educational Attainment}'
    '\\label{MMRtab:MMRpercent}\\begin{tabular}{lcccccccc}\\toprule')
for i,line in enumerate(mmri):
    if i<=32:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)

        line = line.replace('&LABELS','')
        line = line.replace('Percent ever enrolled in','')
        line = line.replace('ls& secondary','Secondary Education (\\% Population) ')
        line = line.replace('lp& primary','Primary Education (\\% Population) ')
        line = line.replace('lh& tertiary','Tertiary Education (\\% Population) ')
        line = line.replace('_year2&year==  1995.0000'  ,'year==1995')
        line = line.replace('_year3&year==  2000.0000'  ,'year==2000')
        line = line.replace('_year4&year==  2005.0000'  ,'year==2005')
        line = line.replace('_year5&year==  2010.0000'  ,'year==2010')
        line = line.replace('ln_GDPpc&'                 ,'')
        line = line.replace('Immunization&'             ,'')
        line = line.replace('(DPT)'                     ,'(DPT) ')
        line = line.replace('percentattend&'            ,'')
        line = line.replace('fertility&(mean) fertility','Fertility')
        line = line.replace('TeenBirths&'               ,'')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')

mmro.write(
mr+'\n'+mc1+cadd[1]+ccm[1]+mc3+'All regressions include fixed-effects by '  
'country. For the full list of countries by year see table \\ref{MMRtab:survey}.' 
'  Results are for the percent of the female population between the ages of '
' 15 and 39 with each level of education in each country.  A full description'
' of control variables is available in section \\ref{scn:data}, and as the note'  
' to table \\ref{MMRtab:sumstats}.  Standard errors clustered at the level of'
' the country are diplayed.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{landscape}')

mmro.close()


## Gender tables
mmri = open(result + gend, 'r')
mmro = open(tables + 'MMRpercentGender.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{landscape}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results: MMR and Female versus Male Education}'
    '\\label{MMRtab:MMRgender}\\begin{tabular}{lcccccccc}\\toprule')
for i,line in enumerate(mmri):
    if i<=14 or i>=36 and i<39:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)

        line = line.replace('&LABELS','')
        line = line.replace('Percent ever enrolled in','')
        line = line.replace('ls& secondary','Secondary Education (\\% Females) ')
        line = line.replace('lp& primary','Primary Education (\\% Females) ')
        line = line.replace('lh& tertiary','Tertiary Education (\\% Females) ')
        line = line.replace('M_lp&(mean) M_lp','Primary Education (\\% Males) ')
        line = line.replace('M_ls&(mean) M_ls','Secondary Education (\\% Males) ')
        line = line.replace('M_lh&(mean) M_lh','Tertiary Education (\\% Males) ')
        line = line.replace('_year2&year==  1995.0000'  ,'year==1995')
        line = line.replace('_year3&year==  2000.0000'  ,'year==2000')
        line = line.replace('_year4&year==  2005.0000'  ,'year==2005')
        line = line.replace('_year5&year==  2010.0000'  ,'year==2010')
        line = line.replace('ln_GDPpc&'                 ,'')
        line = line.replace('Immunization&'             ,'')
        line = line.replace('(DPT)'                     ,'(DPT) ')
        line = line.replace('percentattend&'            ,'')
        line = line.replace('fertility&(mean) fertility','Fertility')
        line = line.replace('TeenBirths&'               ,'')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'&&&&&&&&\\\\Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')


mmro.write(
mr+'\n'+mc1+cadd[1]+ccm[1]+mc3+'All regressions include fixed-effects by '  
'country. For the full list of countries by year see table \\ref{MMRtab:survey}.' 
' Educational variables are the same as those in table \\ref{MMRtab:MMRpercent}'
' however include both female and male figures for each variable (ages 15-39).'
' A full description'
' of control variables is available in section \\ref{scn:data}, and as the note'  
' to table \\ref{MMRtab:sumstats}.  Standard errors clustered at the level of'
' the country are diplayed.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{landscape}')

mmro.close()




## Linear education
mmri = open(result + mmry, 'r')
mmro = open(tables + 'MMRyear.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{landscape}\\begin{subtables}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results of MMR and Female Educational Attainment (years)}'
    '\\label{MMRtab:MMRyrs}\\begin{tabular}{lcccccccc}\\toprule')
for i,line in enumerate(mmri):
    if i<=28:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)
        line = line.replace('&LABELS','')
        line = line.replace('yr_sch&(mean) yr_sch'      ,'Years of Education')
        line = line.replace('_year2&year==  1995.0000'  ,'year==1995')
        line = line.replace('_year3&year==  2000.0000'  ,'year==2000')
        line = line.replace('_year4&year==  2005.0000'  ,'year==2005')
        line = line.replace('_year5&year==  2010.0000'  ,'year==2010')
        line = line.replace('ln_GDPpc&'                 ,'')
        line = line.replace('Immunization&'             ,'')
        line = line.replace('(DPT)'                     ,'(DPT) ')
        line = line.replace('percentattend&'            ,'')
        line = line.replace('fertility&(mean) fertility','Fertility')
        line = line.replace('TeenBirths&'               ,'')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'('        )
        line = line.replace(')&'                        ,')'+dd2        )
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')

mmro.write(
mr+'\n'+mc1+cadd[2]+ccm[2]+mc3+'All regressions include fixed-effects by '
'country.  For the full list of countries by year see table \\ref{MMRtab:survey}.'
'  Results are for average years of education of females between the ages of 15'
' and 39 in each country.  A full description of control variables is available'
' in section \\ref{scn:data}, and as the note to table \\ref{MMRtab:sumstats}.  '
'Standar errors clustered at the level of the country are shown.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}')

mmro.close()


## Quadratic education
mmri = open(result + mmrs, 'r')
mmro = open(tables + 'MMRyearSq.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results of MMR and Female Educational Attainment (years squared)}'
    '\\label{MMRtab:MMRyrssq}\\begin{tabular}{lcccccccc}\\toprule')
for i,line in enumerate(mmri):
    if i<=30:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)
        line = line.replace('&LABELS'                   ,'')
        line = line.replace('yr_sch_sq&'       ,'Years of Education Squared')
        line = line.replace('yr_sch&(mean) yr_sch'      ,'Years of Education')
        line = line.replace('_year2&year==  1995.0000'  ,'year==1995')
        line = line.replace('_year3&year==  2000.0000'  ,'year==2000')
        line = line.replace('_year4&year==  2005.0000'  ,'year==2005')
        line = line.replace('_year5&year==  2010.0000'  ,'year==2010')
        line = line.replace('ln_GDPpc&'                 ,'')
        line = line.replace('Immunization&'             ,'')
        line = line.replace('(DPT)'                     ,'(DPT) ')
        line = line.replace('percentattend&'            ,'')
        line = line.replace('fertility&(mean) fertility','Fertility')
        line = line.replace('TeenBirths&'               ,'')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')

mmro.write(
mr+'\n'+mc1+cadd[3]+ccm[3]+mc3+'All regressions include fixed-effects by '
'country.  For the full list of countries by year see table \\ref{MMRtab:survey}.'
'  Results are for average years of education of females between the ages of 15'
' and 39 in each country.  A full description of control variables is available'
' in section \\ref{scn:data}, and as the note to table \\ref{MMRtab:sumstats}.  '
'Standard errors clustered at the level of the country are shown.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{subtables}\\end{landscape}')

mmro.close()



## Gender quadratic tables
mmri = open(result + gens, 'r')
mmro = open(tables + 'MMRyrssqGender.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{landscape}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results: MMR and Female versus Male Education (years squared)}'
    '\\label{MMRtab:MMRgenderSq}\\begin{tabular}{lcccccccc}\\toprule')
for i,line in enumerate(mmri):
    if i<=10 or i>=32 and i<35:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        line = line.replace('&LABELS','')
        line = line.replace('M_yr_sch_sq&'       ,'Years of Education Squared (Male) ')
        line = line.replace('M_yr_sch&(mean) M_yr_sch'  ,'Years of Education (Male) ')
        line = line.replace('yr_sch_sq&'       ,'Years of Education Squared (Female) ')
        line = line.replace('yr_sch&(mean) yr_sch'      ,'Years of Education (Female) ')
        line = line.replace('_year2&year==  1995.0000'  ,'year==1995')
        line = line.replace('_year3&year==  2000.0000'  ,'year==2000')
        line = line.replace('_year4&year==  2005.0000'  ,'year==2005')
        line = line.replace('_year5&year==  2010.0000'  ,'year==2010')
        line = line.replace('ln_GDPpc&'                 ,'')
        line = line.replace('Immunization&'             ,'')
        line = line.replace('(DPT)'                     ,'(DPT) ')
        line = line.replace('percentattend&'            ,'')
        line = line.replace('fertility&(mean) fertility','Fertility')
        line = line.replace('TeenBirths&'               ,'')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'&&&&&&&&\\\\Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')


mmro.write(
mr+'\n'+mc1+cadd[1]+ccm[1]+mc3+'All regressions include fixed-effects by '  
'country. For the full list of countries by year see table \\ref{MMRtab:survey}.' 
' Educational variables are the same as those in table \\ref{MMRtab:MMRpercent}'
' however include both female and male figures for each variable (ages 15-39).'
' A full description'
' of control variables is available in section \\ref{scn:data}, and as the note'  
' to table \\ref{MMRtab:sumstats}.  Standard errors clustered at the level of'
' the country are diplayed.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{landscape}')

mmro.close()



#-------------------------------------------------------------------------------
# --- (5) MMR grouped tables
#-------------------------------------------------------------------------------
mmri = open(result + regn, 'r')
mmro = open(tables + 'MMRregion.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{subtables}\\begin{landscape}\\begin{table}[htpb!]'
    '\\begin{center}'
    '\\caption{Cross-Country Results of MMR and Female Educational Attainment By Region}'
    '\\label{MMRtab:MMRregion}\\begin{tabular}{lccccccc}\\toprule'
    '&(1)&(2)&(3)&(4)&(5)&(6)&(7)\\\\'
    '&Advanced&East Asia&Europe and&Latin Amer-&Middle East&South&Sub-Saharan\\\\'
    'VARIABLES&Economies&and the&Central &ica and the&and North&Asia&Africa\\\\'
    '&&Pacific&Asia&Caribbean&Africa&&\\\\ \\midrule \n \\vspace{4pt}&')
    mmro.write('\\begin{footnotesize}\\end{footnotesize}&'*6+
    '\\begin{footnotesize}\\end{footnotesize}\\\\')



for i,line in enumerate(mmri):
    if i>2 and i<=14:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)

        line = line.replace('Percent ever enrolled in','')
        line = line.replace('ls& secondary','Secondary Education (\\% Population) ')
        line = line.replace('lp& primary','Primary Education (\\% Population) ')
        line = line.replace('lh& tertiary','Tertiary Education (\\% Population) ')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')

mmro.write(
mr+'\n'+mc1+cadd[4]+ccm[4]+mc3+'All regressions include fixed-effects by country.  '
'Results are for average years of education of females between the ages of 15 and 39'
' in each country.  Results are reported for specification (2) from table '
'\\ref{MMRtab:MMRpercent} which includes country and year fixed effects.  Standard '
'errors are clustered by country.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{landscape}')

mmro.close()


## INCOME
mmri = open(result + incm, 'r')
mmro = open(tables + 'MMRincome.' + end, 'w')

if ftype=='tex':
    mmro.write('\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Cross-Country Results of MMR and Female Educational Attainment By Income Group}'
    '\\label{MMRtab:MMRincome}\\begin{tabular}{lcccc}'
    '\\toprule \n &(1)&(2)&(3)&(4)\\\\' 
    'VARIABLES&Low&Lower&Upper&High\\\\'
    '&&Middle&Middle&\\\\ \\midrule\n \\vspace{4pt}&')
    mmro.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
    '\\begin{footnotesize}\\end{footnotesize}\\\\')

for i,line in enumerate(mmri):
    if i>2 and i<=14:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        #line=re.sub(r"&$", ls+ls, line)

        line = line.replace('Percent ever enrolled in','')
        line = line.replace('ls& secondary','Secondary Education (\\% Population) ')
        line = line.replace('lp& primary','Primary Education (\\% Population) ')
        line = line.replace('lh& tertiary','Tertiary Education (\\% Population) ')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('BLcode&'                   ,'countries')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        line = line.replace('MMR\\\\'                   ,'MMR\\\\ \\midrule')
        line = line.replace('Observations&'             ,'Observations')
        line = line.replace('R-squared&'                ,'R-squared')
        mmro.write(line+'\n')

mmro.write(
mr+'\n'+mc1+cadd[5]+ccm[5]+mc3+'All regressions include fixed-effects by country.  '
'Results are for average years of education of females between the ages of 15 and 39'
' in each country.  Results are reported for specification (2) from table '
'\\ref{MMRtab:MMRpercent} which includes country and year fixed effects.  Countries '
'are classified according to World Bank income groups, and standard errors are '
'clustered by country.\n'+foot)
if ftype=='tex':
    mmro.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{subtables}')

mmro.close()


#-------------------------------------------------------------------------------
# --- (6) Z-score table
#-------------------------------------------------------------------------------
zsci = open(result + corr, 'r')
zsco = open(tables + 'correlatedEffects.' + end, 'w')

if ftype=='tex':
    zsco.write('\\begin{landscape}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Correlations between Education and Health/Development Outcomes}'
    '\\label{MMRtab:Zscore}\\begin{tabular}{lccccc}'
    '\\toprule \n &(1)&(2)&(3)&(4)&(5)\\\\' 
    'VARIABLES&Fertility&Immunization&Percent Attend&ln(GDP pc)& Teen Births\\\\'
    '\\midrule\n \\vspace{4pt}&')
    zsco.write('\\begin{footnotesize}\\end{footnotesize}&'*4+
    '\\begin{footnotesize}\\end{footnotesize}\\\\')

for i,line in enumerate(zsci):
    if i>2 and i<14:
        line = re.sub(r"\t",dd,line)
        line = re.sub(r"^&&","&",line)

        line = line.replace('ls','Secondary Education (\\% Population) ')
        line = line.replace('lp','Primary Education (\\% Population) ')
        line = line.replace('lh','Tertiary Education (\\% Population) ')
        line = line.replace('Constant&Constant'         ,'Constant')
        line = line.replace('\n'                        ,'\\\\')
        line = line.replace(')\\\\'                     ,')'+dd3+'\\\\')
        line = line.replace('(8)'                       ,'(8) ')
        line = line.replace('&('                        ,dd1+'(')
        line = line.replace(')&'                        ,')'+dd2)
        zsco.write(line+'\n')

zsco.write(
mr+'\n'+mc1+cadd[6]+ccm[6]+mc3+'Each regression includes fixed effects by '
'country, and heteroscedasticity robust standard errors.  Each dependent '
'variable has been transformed to a z-score by subtracting its global mean'
' and dividing by its standard deviation.  Education measures are for the '
'female population between 15 and 39. For discussion of the effect size, see'
' section \\ref{ssscn:effects}.\n'+foot)
if ftype=='tex':
    zsco.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
    '\\end{tabular}\\end{center}\\end{table}\\end{landscape}')

zsco.close()

#-------------------------------------------------------------------------------
# --- (7) Nigeria tables
#-------------------------------------------------------------------------------
ngai = open(result + ngra, 'r')
ngao = open(tables + 'Nigeria.' + end, 'w')

if ftype=='tex':
    ngao.write('\\begin{subtables}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{Effect of 1976 Educational Expansion: Nigeria}'
    '\\label{MMRtab:Nigeria}\\begin{tabular}{p{5cm}cccc}\\toprule'
    '&(1)&(2)&(3)&(4)\\\\ \\midrule'
    '\\multicolumn{5}{l}{\\textsc{Panel A: Outcome -- Education}}\\\\')
    ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
    '\\begin{footnotesize}\\end{footnotesize}\\\\ \n')

edB  = []
MMB  = []
MM2B = []
edS  = []
MMS  = []
MM2S = []
nums = [[2, 9],[8,13],[12,17],[16,21]]
for i,line in enumerate(ngai):
    for n in range(0,4):
        if i>nums[n][0] and i<nums[n][1] and i%2==1:
            s=line.split()
            edB.append(s[1])
            MMB.append(s[2])
            MM2B.append(s[3])
        if i>nums[n][0] and i<nums[n][1] and i%2==0:
            s=line.split()
            edS.append(s[0])
            MMS.append(s[1])
            MM2S.append(s[2])

    if i==24:
        obs = line.split()
    if i==25:
        R   = line.split()

ngao.write('Intensity 70-75&'+edB[0]+'&'+edB[3]+'&'+edB[5]+'&'+edB[7]+'\\\\ \n')
ngao.write('               &'+edS[0]+'&'+edS[3]+'&'+edS[5]+'&'+edS[7]+'\\\\ \n')
ngao.write('Intensity 65-69&'+edB[1]+'&'+edB[4]+'&'+edB[6]+'&'+edB[8]+'\\\\ \n')
ngao.write('               &'+edS[1]+'&'+edS[4]+'&'+edS[6]+'&'+edS[8]+'\\\\ \n')
ngao.write('Intensity      &'+edB[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+edS[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[1]+'&'+obs[2]+'&'+obs[3]+'&'+obs[4]+'\\\\ \n')
ngao.write('R-squared&'+R[1]+'&'+R[2]+'&'+R[3]+'&'+R[4]+'\\\\ \\midrule \n')

ngao.write('\\multicolumn{5}{l}{\\textsc{Panel B: Outcome -- MMR}}\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Intensity 70-75&'+MMB[0]+'&'+MMB[3]+'&'+MMB[5]+'&'+MMB[7]+'\\\\ \n')
ngao.write('               &'+MMS[0]+'&'+MMS[3]+'&'+MMS[5]+'&'+MMS[7]+'\\\\ \n')
ngao.write('Intensity 65-69&'+MMB[1]+'&'+MMB[4]+'&'+MMB[6]+'&'+MMB[8]+'\\\\ \n')
ngao.write('               &'+MMS[1]+'&'+MMS[4]+'&'+MMS[6]+'&'+MMS[8]+'\\\\ \n')
ngao.write('Intensity      &'+MMB[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+MMS[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[5]+'&'+obs[6]+'&'+obs[7]+'&'+obs[8]+'\\\\ \n')
ngao.write('R-squared&'+R[5]+'&'+R[6]+'&'+R[7]+'&'+R[8]+'\\\\ \\midrule \n')

ngao.write('\\multicolumn{5}{l}{\\textsc{Panel C: Outcome -- MMR (Under 25)}}\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Intensity 70-75&'+MM2B[0]+'&'+MM2B[3]+'&'+MM2B[5]+'&'+MM2B[7]+'\\\\ \n')
ngao.write('               &'+MM2S[0]+'&'+MM2S[3]+'&'+MM2S[5]+'&'+MM2S[7]+'\\\\ \n')
ngao.write('Intensity 65-69&'+MM2B[1]+'&'+MM2B[4]+'&'+MM2B[6]+'&'+MM2B[8]+'\\\\ \n')
ngao.write('               &'+MM2S[1]+'&'+MM2S[4]+'&'+MM2S[6]+'&'+MM2S[8]+'\\\\ \n')
ngao.write('Intensity      &'+MM2B[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+MM2S[2]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[9]+'&'+obs[10]+'&'+obs[11]+'&'+obs[12]+'\\\\ \n')
ngao.write('R-squared&'+R[9]+'&'+R[10]+'&'+R[11]+'&'+R[12]+'\\\\ \n')


ngao.write(mr+'\n'+mc1+cadd[7]+ccm[7]+mc3+'Columns (1)-(4) represent '
'different measures of treatment intensity. Column (1) uses capital '
'expenditure on school construction in 1976 in each individual\'s state'
' as their treatment intensity, column (2) uses a dummy for residence in'
' non-West (high-intensity) states, column (3) uses the number of years '
'exposed to the reform interacted with the high-intensity state dummy as'
' the intensity measure, and column (4) uses capital expenditure '
'interacted with the high-intensity state dummy.  The effect of the '
'reform is identified for 1970-1975 birth cohorts (who are fully affected)'
', and 1965-1969 cohorts, who are affected partially via over-age '
'enrollments. Panel A shows the effect of the education reforms on '
'educational attainment, panel B shows the effect on life-time maternal '
'mortality, and panel C the effect on maternal mortality under the age of'
' 25.  All regressions are double-differences, however in columns (2)-(4)'
' the intensity dummy is captured by state of residence fixed effects. '
'Additional controls include religion, ethnicity and year of birth fixed '
'effects, plus time trends by state, and controls for the length of '
'exposure to the civil war in Biafra \\citep{Akreshetal2012}.  Standard '
'errors are clustered by state and birth cohort.\n'+foot)
if ftype=='tex':
    ngao.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
   '\\end{tabular}\\end{center}\\end{table}')

ngao.close()


##PLACEBO
ngai = open(result + ngaP, 'r')
ngao = open(tables + 'NigeriaPlacebo.' + end, 'w')

if ftype=='tex':
    ngao.write('\\begin{subtables}\\begin{table}[htpb!]\\begin{center}'
    '\\caption{1976 Educational Expansion Placebo: Nigeria}'
    '\\label{MMRtab:NigeriaPlacebo}\\begin{tabular}{p{5cm}cccc}\\toprule'
    '&(1)&(2)&(3)&(4)\\\\ \\midrule'
    '\\multicolumn{5}{l}{\\textsc{Panel A: Outcome -- Education}}\\\\')
    ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
    '\\begin{footnotesize}\\end{footnotesize}\\\\ \n')

edB  = []
MMB  = []
MM2B = []
edS  = []
MMS  = []
MM2S = []
nums = [[2, 7],[6,9],[8,11],[10,13]]
for i,line in enumerate(ngai):
    for n in range(0,4):
        if i>nums[n][0] and i<nums[n][1] and i%2==1:
            s=line.split()
            edB.append(s[1])
            MMB.append(s[2])
            MM2B.append(s[3])
        if i>nums[n][0] and i<nums[n][1] and i%2==0:
            s=line.split()
            edS.append(s[0])
            MMS.append(s[1])
            MM2S.append(s[2])

    if i==16:
        obs = line.split()
    if i==17:
        R   = line.split()

ngao.write('Intensity 56-60&'+edB[0]+'&'+edB[2]+'&'+edB[3]+'&'+edB[4]+'\\\\ \n')
ngao.write('               &'+edS[0]+'&'+edS[2]+'&'+edS[3]+'&'+edS[4]+'\\\\ \n')
ngao.write('Intensity      &'+edB[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+edS[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[1]+'&'+obs[2]+'&'+obs[3]+'&'+obs[4]+'\\\\ \n')
ngao.write('R-squared&'+R[1]+'&'+R[2]+'&'+R[3]+'&'+R[4]+'\\\\ \\midrule \n')

ngao.write('\\multicolumn{5}{l}{\\textsc{Panel B: Outcome -- MMR}}\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Intensity 56-60&'+MMB[0]+'&'+MMB[2]+'&'+MMB[3]+'&'+MMB[4]+'\\\\ \n')
ngao.write('               &'+MMS[0]+'&'+MMS[2]+'&'+MMS[3]+'&'+MMS[4]+'\\\\ \n')
ngao.write('Intensity      &'+MMB[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+MMS[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[5]+'&'+obs[6]+'&'+obs[7]+'&'+obs[8]+'\\\\ \n')
ngao.write('R-squared&'+R[5]+'&'+R[6]+'&'+R[7]+'&'+R[8]+'\\\\ \\midrule \n')

ngao.write('\\multicolumn{5}{l}{\\textsc{Panel C: Outcome -- MMR (Under 25)}}\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Intensity 56-60&'+MM2B[0]+'&'+MM2B[2]+'&'+MM2B[3]+'&'+MM2B[4]+'\\\\ \n')
ngao.write('               &'+MM2S[0]+'&'+MM2S[2]+'&'+MM2S[3]+'&'+MM2S[4]+'\\\\ \n')
ngao.write('Intensity      &'+MM2B[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('               &'+MM2S[1]+'&'+       '&'+       '&'+       '\\\\ \n')
ngao.write('\\begin{footnotesize}\\end{footnotesize}&'*3+
'\\begin{footnotesize}\\end{footnotesize}\\\\ \n')
ngao.write('Observations&'+obs[9]+'&'+obs[10]+'&'+obs[11]+'&'+obs[12]+'\\\\ \n')
ngao.write('R-squared&'+R[9]+'&'+R[10]+'&'+R[11]+'&'+R[12]+'\\\\ \n')


ngao.write(mr+'\n'+mc1+cadd[8]+ccm[8]+mc3+'For a full description '
'of outcomes and treatments see Table \\ref{MMRtab:Nigeria}. A '
'placebo treatment here is defined by comparing two groups who had '
'already left primary school by the time of the reform.  The birth '
'cohorts from 1956-1961 were defined as the placebo `treatment\' '
'and the cohorts from 1950-1955 were defined as controls.\n'+foot)
if ftype=='tex':
    ngao.write('\\end{footnotesize}} \\\\ \\bottomrule \n'
   '\\end{tabular}\\end{center}\\end{table}')

ngao.close()
