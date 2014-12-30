README.txt FOR "Maternal Education and Maternal Mortality: Evidence from a 
Large Panel and Various Natural Experiments"

This paper is created using a number of input files.  These are:
	- MMReduc_BASE_MF (created in the do file MMREduc_Setup.do)
	- The Nigeria IR DHS files (1999 and 2008)
	- The Zimbabwe IR DHS files (1994, 1999, 2005 and 2010)
	- The Kenya IR DHS files (1993, 1998, 2003, 2008)

Rather than access the original IR DHS files, the intermediate files mmr.dta, 
and educ.dta could be used for each country.  These are created in the do file
MMR_CountrySpecific.do.  [Add note about DHS setup and other repository].

Once these bases have been created (or accessed), the following do files are
run to create output tables:
	- MMR_Analysis.do (cross-country analysis)
	- MMR_CountrySpecific_Regs.do (for natural experiments)

Finally, the paper itself is compiled from the following .tex files:
	- MMREducation_BhalotraClarke_August2013.tex
	- Appendix_Tables.tex
	- Figures.tex
	- Tables.tex
	- BibTeX.bib
and the file Figures.tex requires the figures described in the following list.
	- Educ_region.eps
	-	Schooling_region.eps
	- MMR_2010.eps
	- Schooling_MMR_F.eps
	- Nigeria_educ.eps
	- Nigeria_mmr.eps
	- Zimbabwe_educ.eps
	- Zimbabwe_mmr.eps
	- Kenya_educ.eps
	- Kenya_mmr.eps

