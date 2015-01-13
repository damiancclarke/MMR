PAPER   = ./Paper/MMREducation_BhalotraClarke
OBJECTS = setupMMR.do setupExperiments.do \
					analysisMMR.do naturalExperiments.do

$(PAPER).pdf: $(PAPER).tex
	pdflatex -shell-escape $(PAPER).tex
	bibtex $(PAPER).aux
	pdflatex $(PAPER).tex
	pdflatex $(PAPER).tex


.PHONY : clean
clean: 
	rm $(PAPER).aux $(PAPER).out $(PAPER).log $(PAPER).blg \
		$(PAPER).blg $(PAPER).pdf 