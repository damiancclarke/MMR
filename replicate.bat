REM |----1----|----2----|----3----|----4----|----5----|----6----|----7----|----8
REM This batch file runs the entire set of scripts to replicate the paper Matern
REM al Mortality and Maternal Education by Bhalotra and Clarke.  Full instructio
REM ns can be found on the wiki page: https://github.com/damiancclarke/MMR/wiki
REM
REM You may need to change the location of the Stata directory below. I assume t
REM hat Stata is located in "C:\Program Files\Stata13", and a StataSE.exe exists


"C:\Program Files\Stata13\StataSE" /e do "%~dp0\Do\setupMMR.do"
"C:\Program Files\Stata13\StataSE" /e do "%~dp0\Do\setupExperiments.do"
"C:\Program Files\Stata13\StataSE" /e do "%~dp0\Do\analysisMMR.do"
"C:\Program Files\Stata13\StataSE" /e do "%~dp0\Do\naturalExperiments.do"

python "%~dp0\Do\MMRtabs.py"

pdflatex -shell-escape -output-director="%~dp0\Paper" "%~dp0\Paper\MMREducation_BhalotraClarke.tex"
bibtex "%~dp0\Paper\MMREducation_BhalotraClarke"
pdflatex -shell-escape -output-director="%~dp0\Paper" "%~dp0\Paper\MMREducation_BhalotraClarke.tex"
pdflatex -shell-escape -output-director="%~dp0\Paper" "%~dp0\Paper\MMREducation_BhalotraClarke.tex"