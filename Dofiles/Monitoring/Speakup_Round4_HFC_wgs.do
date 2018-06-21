/******************************************************************************
			High Frequency Checks for Speakup Round 4 Data Collection
Author: Béatrice Leydier
Email: bl517@georgetown.edu
Date: 06/12/2018
Updated: 
*******************************************************************************/

	/*__________________
	|					|
	|	Preliminaries	|
	|___________________*/

clear all
set more off

*Usernames
if "`c(username)'" == "bl517" {
	cd "C:/Users/bl517/Box Sync/Data Analysis/SpeakUp"
	}
	/*TODO: insert interns file paths here*/
// Graham:
else if "`c(username)'" == "grahamstubbs" {
	cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp-HFCs"
	}

*File paths
global RawFolder "Data/Raw/Speakup Round4"
global TempFolder "Data/Temp"
global FinalFolder "Data/Final"
global OutputFolder "Monitoring/Round 4 monitoring"	
	
*Switches
global precleaning "on"
global enums "off"
global pairs "off"
global quality "on"
global debug "off"

*Date
global today = c(current_date)

/*******************************************************************************
********************************************************************************
	PRE-CLEANING
			Input: 
				$RawFolder/Speak Up Round 4 Survey.dta
			Output: 
				$TempFolder/Speakup_Round4_preclean.dta
********************************************************************************
*******************************************************************************/

if "$precleaning" == "on" {

use "$RawFolder/Speak Up Round 4 Survey.dta", clear



*Save
save "$TempFolder/Speakup_Round4_preclean.dta", replace

}
	

/*******************************************************************************
********************************************************************************
	ENUM PAIRS DASHBOARD
		Input:
			$TempFolder/Speakup_Round4_preclean.dta
		Output:
			$OutputFolder/....
			
		This generates a dashboard that looks at
			- # entries for each day, by pair of enum (2x2 table)
			- start and end time for each day, by pair of enum (graph)
		
*******************************************************************************
*******************************************************************************/	

if "$pairs" == "on" {	



}	
	
	
/*******************************************************************************
********************************************************************************
	ENUMERATORS DASHBOARD
		Input:
			$TempFolder/Speakup_Round4_preclean.dta
		Output:
			$OutputFolder/....
			
		This generates a dashboard that looks at, for each enum (one table):
			# entries total
			avg. duration of entries
			avg. start time, avg. end time
			for each variable that allows missing values (9999), % missing
			# and % of H+R
		
*******************************************************************************
*******************************************************************************/	

if "$enums" == "on" {	



}


/*******************************************************************************
********************************************************************************
	QUALITY DASHBOARD
		Input:
			$TempFolder/Speakup_Round4_preclean.dta
		Output:
			$OutputFolder/....
			
		This generates a dashboard that looks at
			- Survey Progress
				# accidents by station, subregion, region 
			- Potential Errors
				# and % of H+R total
					+export H+R record and manual check of pictures
				# of duplicate accidents (date+regnum)
					+export duplicate records and eye-ball them
				# potential issues from additional info (automatically flag)
					+export entries w potential issues
						
*******************************************************************************
*******************************************************************************/	

if "$quality" == "on" {	
	
	// Turn this global on to posthumously perform the HFC for previous dates,
	//   (may be slow)
	global fill_in_previous_dates "on"

	local loop_end = 1
	if ("$fill_in_previous_dates" == "on") {
		gen date_num = substr("$today", 1, 2)
		destring date_num, replace
		local loop_end = date_num - 13
		if ("$debug" == "on") {
			disp "Previous dates will be filled in"
			disp "Number of loops to be performed: `loop_end'"
		}
	}
	
	forvalues HFC_loop_num = 1/`loop_end' {
	
		use "$TempFolder/Speakup_Round4_preclean.dta", clear
		if (`HFC_loop_num' == 1) {
			preserve
		}
		
		if ("$fill_in_previous_dates" == "on") {
			gen sub_date_num = dofc(submissiondate)
			format sub_date_num %td
			gen sub_date_day = day(sub_date_num)
			gen sub_date_month = month(sub_date_num)
			
			// this is only valid for June and July with a start date of June 14
			// this should be changed if this code is used for another purpose
			if (`HFC_loop_num' <= 17) {
				drop if sub_date_day > `HFC_loop_num' + 13 | sub_date_month > 6
			}
			else {
				drop if sub_date_day > `HFC_loop_num' - 17 & sub_date_month == 7
			}
			
			drop sub_date_day sub_date_month sub_date_num
		}
	
		/* get Total records */
		count
		local total_records = r(N)
		
		local export_col = "A"
		
		if ("$fill_in_previous_dates" == "on") {
			local export_col = char(`HFC_loop_num' + 13 + 53)
		}
		else {
			gen date_num = substr("$today", 1, 2)
			destring date_num, replace
			local export_col = char(date_num)
			if (date_num + 53) <= 90 {
				local export_col = char(date_num + 53)
			}
			else {
				local export_col = char(date_num + 53 - 26)
				local export_col = "A" + "`export_col'"
			}
			drop date_num
		}
		
		// export to excel
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("Quality")
		if (`HFC_loop_num' == `loop_end') {
			putexcel A2 = "Summary of Potential Errors", bold
// 			putexcel C3 = "14 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel D3 = "15 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel E3 = "16 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel F3 = "17 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel G3 = "18 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel H3 = "19 June 2018", bold border(bottom, medium, black) overwritefmt
// 			putexcel I3 = "20 June 2018", bold border(bottom, medium, black) overwritefmt
			putexcel (B4:B13), border(right, medium, black)
		}
		if ("$debug" == "on") {
			disp "Today: $today"
			disp "Exporting summaries to column `export_col'"
		}
		local date_str = ""
		if ("$fill_in_previous_dates" == "on") {
			// this is only valid for June and July with a start date of June 14
			// this should be changed if this code is used for another purpose
			if (`HFC_loop_num' <= 17) {
				local temp_date = `HFC_loop_num' + 13
				local date_str = "`temp_date' June 2018"
			}
			else {
				local temp_date = `HFC_loop_num' -17
				local date_str = "`temp_date' July 2018"
			}
			
		}
		else {
			local date_str = "$today"
		}
		putexcel `export_col'3 = "`date_str'", bold border(bottom, medium, black) font("Calibri (Body)", 11, black) overwritefmt
		putexcel `export_col'4 = `total_records'
		
		
		/* get number and percent of hit&runs */
		count if hitandrun == 1
		local hitandrun_amt = r(N)
		local hitandrun_pct = `hitandrun_amt'/`total_records'
		
		// export to excel
		putexcel `export_col'6 = `hitandrun_amt'
		putexcel `export_col'7 = (`hitandrun_pct'), nformat(percent_d2)	
		
		if (`HFC_loop_num' == `loop_end') {
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" if hitandrun == 1, sheetreplace sheet("_export H+R ") firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("_export H+R ")
			local hr_highlight_length = `hitandrun_amt'+1
			putexcel (AA1:AA`hr_highlight_length'), fpattern(solid, lightpink, lightpink) overwritefmt
			putexcel (A1:GF1), bold border(bottom, thin, black)
		}
		
		/* Flag and export all entries with additional info (potential issues) */
		gen potential_issues = 0
		
		// generate a new variable that is equivalent to additionalinfo but 
		//   ensures all values are lowercase for easy comparison
		gen additionalinfo_lower = lower(additionalinfo)
		
		// remove punctuation
		replace additionalinfo_lower = subinstr(additionalinfo_lower, ".", "", .)
		
		// flag entries that may contain something worth checking
		replace potential_issues = 1 if (additionalinfo_lower != "" & additionalinfo_lower != "none" & additionalinfo_lower != "no" & additionalinfo_lower != "n/a" & additionalinfo_lower != "nothing")
		
		// drop uneeded var
		drop additionalinfo_lower
		
		// get counts
		count if potential_issues == 1
		local flags_count = r(N)
		local flags_pct = `flags_count'/`total_records'
		
		// export to excel
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("Quality")
		putexcel `export_col'12 = `flags_count'
		putexcel `export_col'13 = `flags_pct', nformat(percent_d2)
		
		if (`HFC_loop_num' == `loop_end') {
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" if potential_issues==1, sheetreplace sheet("_export flags") firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("_export flags")
			local flags_highlight_length = `flags_count' + 1
			putexcel (AM1:AM`flags_highlight_length'), fpattern(solid, lightpink, lightpink) overwritefmt
			putexcel (A1:GH1), bold border(bottom, thin, black)
		}
		
		drop potential_issues
		
		
		/* search and record duplicates */
		// find and group records with the same date
		duplicates tag date, gen(same_date)  
		sort date
		
		gen same_date_grouped = 0
		
		local amt_to_check = 0
		local counter = 0
		local i = 1
		
		// iterate through all records, giving each group of records on the 
		//   same date a distinct value for same_date grouped
		while `i' <= `total_records' {
			// if the record has another on the same date...
			if same_date[`i'] != 0 {  
				// get number of records on same date
				local amt_to_check = same_date[`i']  
				local counter = `counter' + 1
				
				local j = `i'
				// assign each record on the same date a matching value in
				//   same_date_grouped
				while `j' <= (`i' + `amt_to_check') {
					replace same_date_grouped = `counter' if _n == `j'
					local j = `j' + 1
				}
				
				local i = `i' + `amt_to_check' + 1
			}
			else {
				local i = `i' + 1
			}
		}
		
		gsort - same_date_grouped psvcount psvregistration1
		gen duplicates_grouped = 0
		local i = 1
		
		// iterate through records until reaching the records for which they have no
		//   duplicate dates
		while `i' <= `total_records' & same_date_grouped[`i'] != 0 {
		
			local amt_to_check = same_date[`i']	
			local psvlist
			local psvlist_size = 0
			local j = `i'
			
			// iterate through groups of records that were determined to have the 
			//   same date
			while `j' <= (`i' + `amt_to_check') {
			
				local k = 1
				
				// for each of these records, add their psv registration numbers 
				//   to a list. If one of their psv registration numbers is already
				//   on the list, mark the matching records as duplicates
				while `k' <= psvcount[`j'] {
				
					local psvregistration_k_j = psvregistration`k'[`j']
					if "$debug" == "on" {
							display "psvregistration`k'[`j']: `psvregistration_k_j'" 
					}
					
					if ("`psvregistration_k_j'" != "") {
					
						
						
						// if there is nothing in the list, add the first psv 
						//   registration number
						if (`psvlist_size' == 0) {
							local psvlist `psvregistration_k_j'
							local psvlist_size = `psvlist_size' + 1
							
							if ("$debug" == "on") {
								display "size of the list is 0, add `psvregistration_k_j' to list"
								display "list is now `psvlist'"
								display "size is now `psvlist_size'"
							}
						}
						
						// if the list is not empty but the psv registration number is
						//   not found on the list, add it to the list
						else if !(`: list psvregistration_k_j in psvlist') {
							local psvlist `psvlist' `psvregistration_k_j'
							local psvlist_size = `psvlist_size' + 1
							
							if ("$debug" == "on") {
								display "`psvregistration_k_j' is not on the list; add it"
								display "list is now `psvlist'"
								display "size is now `psvlist_size'"
							}
						}
						
						// if the psv registration number IS on the list, mark the 
						//   records as duplicates
						else {
							local group_ct = same_date_grouped[`i']
							
							if ("$debug" == "on") {
								display "`psvregistration_k_j' is already on the list!!"
								display "putting '`group_ct'' in record `j'"
							}
							
							replace duplicates_grouped = same_date_grouped[`i'] if _n == `j'
							local position : list posof "`psvregistration_k_j'" in psvlist
							local psv_counter = 0
							
							if "$debug" == "on" {
								display "position: `position'"
							}
							
							// search the list for the matching psv registration number
							//   and use its position to determine which of the other
							//   records with the same date is the one with the matching
							//   psv registration number
							forvalues m = `i'/`j' {
								local psv_counter = `psv_counter' + psvcount[`m']
								
								if "$debug" == "on" {
									display "psv_counter: `psv_counter'"
									display "m: `m'"
								}
								
								if (`psv_counter' >= `position') {
									local group_ct = same_date_grouped[`i']
									
									if "$debug" == "on" {
										display "putting '`group_ct'' in record `m'" 
									}
									
									replace duplicates_grouped = same_date_grouped[`i'] if _n == `m'
									continue, break
								}
							}
							
							// then add the duplicate to the list anyways so future
							//   counts are consistent
							local psvlist `psvlist' `psvregistration_k_j'
							local psvlist_size = `psvlist_size' + 1
						}
					}	
					local k = `k' + 1
				}
				local j = `j' + 1
			}
			local i = `i' + `amt_to_check' + 1
		}
		
		// using the previously determined and marked duplicate records, use
		//   the duplicates function to generate a variable containing the 
		//   traditional values expected in the duplicates variable (contained in
		//   duplicates_amt)
		duplicates tag duplicates_grouped if duplicates_grouped != 0, gen(duplicates_amt)
		
// 		preserve
		drop if duplicates_grouped == 0
		gsort - duplicates_grouped psvregistration1 submissiondate
		
		// get number and percent of duplicates
		count
		local dups_incl_originals = r(N)
		local duplicate_count = 0
		local i = 1
		while `i' <= `dups_incl_originals' {
			local duplicate_count = `duplicate_count' + duplicates_amt[`i']
			local i = `i' + duplicates_amt[`i'] + 1
		}
		
		local duplicate_pct = `duplicate_count'/`total_records'
		
		// export to excel
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("Quality")
		
		putexcel `export_col'9 = `duplicate_count'
		putexcel `export_col'10 = (`duplicate_pct'), nformat(percent_d2)
		
		if (`HFC_loop_num' == `loop_end') {
			putexcel A9 = "This is the amount of records that are likely duplicates of another", italic font("Calibri (Body)", 11, red)
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" if duplicates_grouped != 0, sheetreplace sheet("_export dups") firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet("_export dups")
			local dup_highlight_length = `dups_incl_originals'+1
			putexcel (A1:GJ1), bold border(bottom, thin, black)
		
			// highlight exported duplicates to make viewing easier
			local i = 1
			local highlight_start = 2
			local loops = 0
			while `i' <= `dups_incl_originals' {
				local highlight_length = duplicates_amt[`i']
				local highlight_end = `highlight_start' + `highlight_length'
				
				if ("$debug" == "on") {
					display "Higlighting from A`highlight_start' to GJ`highlight_end'"
				}
				
				if (mod(`loops', 2) == 0) {
					putexcel (A`highlight_start':GJ`highlight_end'), fpattern(solid, "198 242 255", "198 242 255") overwritefmt
				}
				else if (mod(`loops', 2) == 1) {
					putexcel (A`highlight_start':GJ`highlight_end'), fpattern(solid, "255 222 173", "255 222 173") overwritefmt
				}
		
				local i = `i' + duplicates_amt[`i'] + 1
				local highlight_start = `highlight_end' + 1
				local loops = `loops' + 1
			}
		}
		
		restore, preserve
		
		if ("$debug" == "on") {
			disp "End of loop `HFC_loop_num'"
		}
	}
	
	putexcel close
}
