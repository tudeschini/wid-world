
local countries US Germany UK Canada

local iter=1
foreach c in `countries'{
di "`c'..."
qui{
	preserve
	import excel "$wid_dir/Country-Updates/`c'/2017/August/`c'_WID.world.xlsx", clear

	// Clean
	dropmiss, force
	renvars, map(strtoname(@[3]))
	drop if _n<4
	destring _all, replace
	rename WID_code year
	dropmiss, force
	dropmiss, obs force

	// Reshape
	ds year, not
	renvars `r(varlist)', pref(value)
	reshape long value, i(year) j(widcode) string
	drop if mi(value)
	gen iso="`c'"
	tempfile `c'
	save "``c''"
	restore
if `iter'==1{
	use "``c''", clear
}
else{
	append using "``c''"
}
local iter=`iter'+1
}
}

// Currencies and countries
replace iso="GB" if iso=="UK"
replace iso="DE" if iso=="Germany"
replace iso="CA" if iso=="Canada"

gen currency = "GBP" if iso=="GB" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="EUR" if iso=="DE" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="CAD" if iso=="CA" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
replace currency="USD" if iso=="US" & inlist(substr(widcode, 1, 1), "a", "t", "m", "i")
gen p="pall"

drop if widcode=="inyixx999i"

tempfile macroupdates
save "`macroupdates'"

// Create metadata
generate sixlet = substr(widcode, 1, 6)
keep iso sixlet
duplicates drop
generate source = `"[URL][URL_LINK][/URL_LINK]"' ///
	+ `"[URL_TEXT]Piketty, Thomas; Zucman, Gabriel (2014)."' ///
	+ `"Capital is back: Wealth-Income ratios in Rich Countries 1700-2010. Series updated by Luis Bauluz.[/URL_TEXT][/URL]; "'
generate method = ""
tempfile meta
save "`meta'"

// Add data to WID
use "$work_data/add-france-macro-data-output.dta", clear
gen oldobs=1
append using "`macroupdates'"
duplicates tag iso year p widcode, gen(dup)
qui count if dup==1 & !inlist(iso,"DE","GB","US","CA")
assert r(N)==0
drop if oldobs==1 & dup==1
drop oldobs dup

label data "Generated by add-macro-updates.do"
save "$work_data/add-macro-updates-output.dta", replace

// Add metadata
use "$work_data/add-france-macro-data-metadata.dta", clear
merge 1:1 iso sixlet using "`meta'", nogenerate update replace

label data "Generated by add-macro-updates.do"
save "$work_data/add-macro-updates-metadata.dta", replace



