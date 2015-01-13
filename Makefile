PAPER   = ./Paper/MMREducation_BhalotraClarke
OBJECTS = setupMMR.do setupExperiments.do \
					analysisMMR.do naturalExperiments.do

$(PAPER).pdf: $(PAPER).tex
	pdflatex -shell-escape $(PAPER).tex
	bibtex $(PAPER).aux
	pdflatex -shell-escape $(PAPER).tex
	pdflatex -shell-escape $(PAPER).tex

.PHONY : clean
clean: 
	rm ./Paper/*.aux ./Paper/*.log ./Paper/*.blg ./Paper/*.bbl
	rm $(PAPER).pdf 