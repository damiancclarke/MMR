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
regn = 'CrossCountry_region.xls'
incm = 'CrossCountry_income.xls'
corr = 'Zscores_female.xls'
gend = 'CrossCountry_gender.txt'
mmry = 'CrossCountry_female_yrs.txt'
mmrs = 'CrossCountry_female_yrssq.txt'
gens = 'CrossCountry_gender_yrssq.txt'

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
    cadd = ['6','9','9','9']
    ccm  = ['}{p{12.5cm}}','}{p{20cm}}','}{p{17.2cm}}','}{p{18.8cm}}']

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
        line=line.replace('population'   ,'Population'                  )
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
'country. For the full list of countries by year see table \\ref{tab:survey}.' 
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
'country. For the full list of countries by year see table \\ref{tab:survey}.' 
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

        print line
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
'country. For the full list of countries by year see table \\ref{tab:survey}.' 
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
