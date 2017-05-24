import delimited "$oecd_data/ppp/SNA_TABLE4_20072016090738746.csv", ///
	clear encoding("utf8")
keep year country value unitcode
	
// Only keep the 2011 round
keep if year == 2011

tempfile ppp
save "`ppp'"

// Add some countries from the ICP benchmark file
import delimited "$oecd_data/ppp/PPP2011_29072016143049632.csv", ///
	clear encoding("utf8")
rename time year
keep year country value
merge 1:1 country year using "`ppp'", nogenerate update

// Identify countries
countrycode country, generate(iso) from("oecd")

// Housekeeping
keep iso unitcode year value
rename unitcode currency

rename value ppp_oecd

label data "Generated by import-ppp-oecd.do"
save "$work_data/ppp-oecd.dta", replace