# MMRtabs.py v0.00               damiancclarke             yyyy-mm-dd:2014-12-30
#---|----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
#
# This script takes summary statistics and regressions results sent out from the 
# scripts analysisMMR.do and XXXXXXXXX.do, and formats them as tables for inclu-
# sion in the paper Maternal Education and Maternal Mortality: Evidence from a
# Large Panel and Various Natural Experiments.
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
mmra = 'CrossCountry_female.xls'
regn = 'CrossCountry_region.xls'
incm = 'CrossCountry_income.xls'
corr = 'Zscores_female.xls'
gend = 'CrossCountry_gender.xls'
mmry = 'CrossCountry_female_yrs.xls'
mmrs = 'CrossCountry_female_yrssq.xls'
gens =  'CrossCountry_gender_yrssq.xls'

#-------------------------------------------------------------------------------
# --- (2) csv or tex options
#-------------------------------------------------------------------------------
if ftype=='tex':
    dd = '&'
    dd1  = "&\\begin{footnotesize}"
    dd2  = "\\end{footnotesize}&\\begin{footnotesize}"
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
    cadd = ['6']
    ccm  = ['}{p{12.5cm}}']

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
    cadd = ['']
    ccm  = ['']

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

        line=line.replace('ln_MMR','ln(Maternal Mortality)')
        line=line.replace('MMR','Maternal Mortality')
        line=line.replace('ln_GDPpc','ln(GDP per capita)')
        line=line.replace('GDPpc','GDP per capita')
        line=line.replace('TeenBirths','Teen Births')
        line=line.replace('percentattend','Percent Attended Births')
        line=line.replace('population','Population')
        line=line.replace('fertility','Fertility')
        line=line.replace('yr_sch_pri','Years of Primary Education')
        line=line.replace('yr_sch_sec','Years of Secondary Education')
        line=line.replace('yr_sch_ter','Years of Tertiary Education')
        line=line.replace('yr_sch','Total Years of Education')
        line=line.replace('lp','Percent Primary')
        line=line.replace('ls','Percent Secondary')
        line=line.replace('lh','Percent Tertiary')
        line=line.replace('lu','Percent No Education')

        if ftype=='tex':
            line=re.sub('Total','\\midrule\\multicolumn{6}{l}{\\\\textsc{'+
            'Education - Female}} \\\\\\ \n Total',line)

        summo.write(line+'\n')

summo.write(
mr+'\n'+mc1+cadd[0]+ccm[0]+mc3+'Maternal mortality is expressed in terms of deaths' 
' per 100,000 live births. Immunization is expressed as the percent of children of'
' ages 12-23 months who are immunized against diphtheria, pertussis and tetanus'
' (DPT). Fertility represents births per woman, and teen births are expressed as'
' the number of births per 1000 women between the ages of 15--19.')
if ftype=='tex':
    summo.write('\\end{footnotesize}} \\\\ \\bottomrule '
    '\\end{tabular}\\end{center}\\end{table}')

summo.close()
