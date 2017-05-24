// Import currency symbols
import delimited "$currency_codes/symbols.csv", ///
	delimiter("\t") clear encoding("utf8") varnames(1)

drop if currency == "(none)"
drop if isocode  == "(none)"
	
keep currency symbol isocode
	
replace symbol = "" if symbol == "(none)"
replace symbol = "" if ustrregexm(symbol, "\.svg$")

// Add Yugoslav dinar
local nobs = _N + 1
set obs `nobs'
replace currency = "1990 Yugoslav dinar" in l
replace symbol = "дин." in l
replace isocode = "YUN" in l

split symbol, parse(" or ")
drop symbol symbol2
rename symbol1 symbol
	
duplicates drop isocode, force

rename currency name
rename isocode currency

tempfile currencies
save "`currencies'"

use "$work_data/calibrate-dina-output.dta", clear

keep iso currency
drop if currency == ""
duplicates drop

sort iso currency

merge n:1 currency using "`currencies'", keep(master match) assert(match) nogenerate
rename currency currency_iso
rename symbol currency_symbol
rename name currency_name

// Expand for all types (variable first letter)
expand 12
sort iso
generate nobs = _n
generate type = ""
local i 0
foreach c in a b c f h i n s t m o w x {
	replace type = "`c'" if mod(nobs, 13) == `i'
	local i = `i' + 1
}
drop nobs

// Metadata
generate metadata = `""'
replace metadata = `"{"unit":""' + currency_iso + `"","unit_name":""' + currency_name + ///
	`"","unit_symbol":""' + currency_symbol + `""}"' if inlist(type, "a", "t", "m", "o")

// Special for France, Germany and Netherlands
replace metadata = `"{"unit":""' + currency_iso + `"","unit_name":""' + currency_name + ///
	`"","unit_symbol":""' + currency_symbol + `"","nominal_unit_name":{"1896-1950":"Old Francs","1951-":"euros"}}"' ///
	if inlist(type, "a", "t", "m", "o") & (iso == "FR")
replace metadata = `"{"unit":""' + currency_iso + `"","unit_name":""' + currency_name + ///
	`"","unit_symbol":""' + currency_symbol + `"","nominal_unit_name":{"1850-1923":"Papiermark","1924-1950":"Reichsmark/Deutsche Mark","1951-":"euros"}}"' ///
	if inlist(type, "a", "t", "m", "o") & (iso == "DE")
replace metadata = `"{"unit":""' + currency_iso + `"","unit_name":""' + currency_name + ///
	`"","unit_symbol":""' + currency_symbol + `"","nominal_unit_name":{"1914-1950":"Guilders","1951-":"euros"}}"' ///
	if inlist(type, "a", "t", "m", "o") & (iso == "NL")

// Yugoslavia: remove the year for the nominal serie
replace metadata = `"{"unit":""' + currency_iso + `"","unit_name":""' + currency_name + ///
	`"","unit_symbol":""' + currency_symbol + `"","nominal_unit_name":{"-1990":"Yugoslav dinars"}}"' ///
	if inlist(type, "a", "t", "m", "o") & (iso == "QY")

replace metadata = `"{"unit":""}"' if inlist(type, "b", "i")
replace metadata = `"{"unit":"% of national income"}"' if (type == "w")
replace metadata = `"{"unit":"population"}"' if inlist(type, "n", "h", "f")
replace metadata = `"{"unit":"share"}"' if inlist(type, "c", "s")
replace metadata = `"{"unit":"local currency per foreign currency"}"' if (type == "x")

keep iso type metadata

// Export results
sort iso type
rename iso country
rename type var_type
export delimited "$output_dir/$time/metadata/var-units.csv", replace delimiter(";")

label data "Generated by export-units.do"
save "$work_data/var-units.dta", replace