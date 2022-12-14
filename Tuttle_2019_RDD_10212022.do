/*	PROGRAM: Replication of Snapping Back: Food Stamp Bans and Criminal Recidivism - Tuttle (2019)
	DATE: Nov. 17, 2021
	
	BACKGROUND
	In 1996, Flordia adapted a national welfare reform to impose a lifetime ban on food stamps
	for drug trafficers who committed their crime on or after August 23, 1996. This sharp
	temporal cutoff creates a prime opportunity to examine the effects of welfare bans on a 
	host of possible outcomes. Tuttle (2019) finds that individuals subject to the ban are 
	more likely to commit another crime than those who are not subject to the ban and that
	these effects are largely driven by financially-motivated crimes.
	
	We'll try to recreate their results here in the following steps:
	(1) Load data, do some initial exploration, and prepare it for analysis
	(2) Test for gaming around the cutoff, heaping, and statistical power
	(3) Estimation via OLS and interpretation
	
	*/

// ----------------------------------------------------- (1) Loading data and initial exploration
use "https://github.com/andrewmcamp/MSER/raw/main/data/florida_offenders.dta", clear

* First thing to do is get a sense of our variables
summarize _all, sep(0)

* Next, we might make a simple graph to motivate our analysis
gen reldate = date - date("23Aug1996", "DMY") // Recentering running variable at cutoff
label variable reldate "Relative Date"
gen bin = floor(reldate/60) // Creating bins of 60 days before/after cutoff
replace bin = bin + 1 if bin >= 0 // Personal preference not to have a 0 bin
bysort bin: egen avg_finrecidany = mean(finrecidany) // Average recid. rate by bin
twoway scatter avg_finrecidany bin, xline(0) // Make a simple scatterplot




// --------------------------------------------------- (3a) Estimation via OLS and interpretation
gen treat = reldate > 0 // Define a treatment variable
label variable treat "Treatment"

reg finrecidany treat reldate if abs(reldate) <= 60, robust
	eststo simple

* Add in interaction term to allow different slopes on either side of the cutoff
reg finrecidany treat reldate treat#c.reldate if abs(reldate) <= 60, robust
	eststo bw_60
reg finrecidany treat reldate treat#c.reldate if abs(reldate) <= 120, robust
	eststo bw_120
reg finrecidany treat reldate treat#c.reldate if abs(reldate) <= 180, robust
	eststo bw_180
reg finrecidany treat reldate treat#c.reldate if abs(reldate) <= 240, robust
	eststo bw_240

* Compare these naive models
esttab simple bw*, p ar2 scalars(rmse) noomit label ///
	mtitles("Simple" "X BW=60" "X BW=120" "X BW=180" "X BW=240")
