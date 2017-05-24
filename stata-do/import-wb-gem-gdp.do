import excel "$wb_data/global-economic-monitor/GDP at market prices, current LCU, millions, seas. adj..xlsx", ///
	clear allstring
sxpose, clear

drop _var2
foreach v of varlist _var3-_var22 {
	local year = `v'[1]
	rename `v' value`year'
}
drop in 1
drop value2016
destring value*, replace force
rename _var1 country

countrycode country, generate(iso) from("wb gem")
drop country

// Identify problems in the data
replace value2015 = . if (iso == "AR")
replace value2015 = . if (iso == "IR")

assert abs(value2015 - value2014)/value2015 < 0.5 if (value2015 < .)

reshape long value, i(iso) j(year)
drop if value >= .
replace value = value*1e6
rename value gdp_lcu_gem

label data "Generated by import-wb-gem-gdp.do"
save "$work_data/wb-gem-gdp.dta", replace