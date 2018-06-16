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
global precleaning "off"
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

	use "$TempFolder/Speakup_Round4_preclean.dta", clear
	
	/* get Total records */
	count
	local total_records = r(N)

	/* get number and percent of hit&runs */
	count if hitandrun == 1
	local hitandrun_amt = r(N)
	local hitandrun_pct = `hitandrun_amt'/`total_records'
	
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
	
	gsort - same_date_grouped psvcount
	gen duplicates_grouped = 0
	local i = 1
	while `i' <= `total_records' & same_date_grouped[`i'] != 0 {
		local grouping = same_date_grouped[`i']
		local amt_to_check = same_date[`i']
		
		local psvlist
		local psvlist_size = 0
		local j = `i'
		while `j' <= (`i' + `amt_to_check') {
			local k = 1
			while `k' <= psvcount[`j'] {
				local psvregistration_k_j = psvregistration`k'[`j']
				
				if "$debug" == "on" {
					display "psvregistration`k'[`j']: `psvregistration_k_j'" 
				}
				
				if (`psvlist_size' == 0) {
					local psvlist `psvregistration_k_j'
					local psvlist_size = `psvlist_size' + 1
					
					if ("$debug" == "on") {
						display "size of the list is 0, add `psvregistration_k_j' to list"
						display "list is now `psvlist'"
						display "size is now `psvlist_size'"
					}
				}
				else if !(`: list psvregistration_k_j in psvlist') {
					local psvlist `psvlist' `psvregistration_k_j'
					// local psvlist_size : list sizeof `psvlist'
					local psvlist_size = `psvlist_size' + 1
					
					if ("$debug" == "on") {
						display "`psvregistration_k_j' is not on the list; add it"
						display "list is now `psvlist'"
						display "size is now `psvlist_size'"
					}
				}
				else {
					local group_ct = same_date_grouped[`i']
					
					if ("$debug" == "on") {
						display "`psvregistration_k_j' is already on the list!!"
						display "putting '`group_ct'' in record `j'"
					}
					
					replace duplicates_grouped = same_date_grouped[`i'] if _n == `j'
					local position : list posof "`psvregistration_k_j'" in psvlist
					local psv_counter = 0
					
					forvalues m = `i'/`j' {
						local psv_counter = `psv_counter' + psvcount[`m']
						if (`psv_counter' >= `position') {
							local group_ct = same_date_grouped[`i']
							
							if "$debug" == "on" {
								display "putting '`group_ct'' in record `m'" 
							}
							
							replace duplicates_grouped = same_date_grouped[`i'] if _n == `m'
							continue, break
						}
					}
				}
				local k = `k' + 1
			}
			local j = `j' + 1
		}
		local i = `i' + `amt_to_check' + 1
	}
	
	duplicates tag duplicates_grouped if duplicates_grouped != 0, gen(duplicates_amt)
}
