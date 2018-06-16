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
	
	// get Total records
	count
	local total_records = r(N)
	// dis `total_records'

	// get number and percent of hit&runs
	count if hitandrun == 1
	local hitandrun_amt = r(N)
	// dis `hitandrun_amt'
	local hitandrun_pct = `hitandrun_amt'/`total_records'
	// dis `hitandrun_pct'
	
	// search and record duplicates
	duplicates tag date, gen(same_date)
	sort date
	
	gen same_date_grouped = 0
	
	local date_duplicate_num = 0
	local counter = 0
	local i = 1
	while `i' <= `total_records' {
	
		if same_date[`i'] != 0 {
			local date_duplicate_num = same_date[`i']
			local counter = `counter' + 1
			
			local j = `i'
			while `j' <= (`i' + `date_duplicate_num') {
				replace same_date_grouped = `counter' if _n == `j'
				local j = `j' + 1
			}
			
			local i = `i' + `date_duplicate_num' + 1
		}
		else {
			local i = `i' + 1
		}
	}
	
	
}
