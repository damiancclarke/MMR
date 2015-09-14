PAPER=./Paper/MMREducation_BhalotraClarke
TABLE=./Paper/tables
SOURC=./Do
DATAF=./Data
RESUL=./Results/tables
CODES = analysisMMR.do naturalExperiments.do

all: dat run tex
dat: $(DATAF)/MMReduc_BASE_F.dta $(DATAF)/Nigeria/educ.dta
run: $(RESUL)/CrossCountry_female.txt $(RESUL)/Zimbabwe.txt
tex: $(TABLE)/Tables.tex $(PAPER).pdf

$(DATAF)/MMReduc_BASE_F.dta: $(SOURC)/setupMMR.do
	/usr/local/stata12/stata-se -b do $(SOURC)/setupMMR.do

$(DATAF)/Nigeria/educ.dta: $(SOURC)/setupExperiments.do
	/usr/local/stata12/stata-se -b do $(SOURC)/setupExperiments.do

$(RESUL)/CrossCountry_female.txt: $(DATAF)/MMReduc_BASE_F.dta $(SOURC)/analysisMMR.do
	/usr/local/stata12/stata-se -b do $(SOURC)/analysisMMR.do

$(RESUL)/Zimbabwe.txt: $(DATAF)/Nigeria/educ.dta $(SOURC)/naturalExperiments.do
	/usr/local/stata12/stata-se -b do $(SOURC)/naturalExperiments.do

$(TABLE)/Tables.tex: $(SOURC)/MMRtabs.py $(RESUL)/CrossCountry_female.txt $(RESUL)/Zimbabwe.txt
	python $(SOURC)/MMRtabs.py tex

$(PAPER).pdf: $(PAPER).tex $(TABLE)/Tables.tex 
	pdflatex -shell-escape -output-director=./Paper $(PAPER).tex
	pdflatex -shell-escape -output-director=./Paper $(PAPER).tex
	bibtex $(PAPER)
	pdflatex -shell-escape -output-director=./Paper $(PAPER).tex






