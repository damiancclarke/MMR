PAPER   = MMREducation_BhalotraClarke
OBJECTS = setupMMR.do setupExperiments.do \
					analysisMMR.do naturalExperiments.do

$(PAPER).pdf: $(PAPER).tex
	pdflatex -shell-escape $(PAPER).tex
	bibtex $(PAPER).aux
	pdflatex $(PAPER).tex
	pdflatex $(PAPER).tex
