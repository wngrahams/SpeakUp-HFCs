/******************************************************************************
			High Frequency Checks for Speakup Round 4 Data Collection
Author: Béatrice Leydier, William Stubbs, Yuou Wu
Email: bl517@georgetown.edu
Date: 12/06/2018
Updated: 21/06/2018
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
// Graham:
else if "`c(username)'" == "grahamstubbs" {
	cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp-HFCs"
}
// Yuou:
else if "`c(username)'" == "yuouwu" {
	cd "/users/yuouwu/Box Sync/"
}

*File paths
global RawFolder "Data/Raw/Speakup Round4"
global TempFolder "Data/Temp"
global FinalFolder "Data/Final"
global OutputFolder "Monitoring/Round 4 monitoring"	
	
*Switches
global precleaning "on"
global pairs "off"
global enum_graph "on"
global enums "off"
global quality "off"
global debug "off"
global fill_in_previous_dates "off" // explanation found in quality section

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
	
	// Drop if survey was started before the beginning of Round 4
	drop if starttime < mdyhms(6, 14, 2018, 00, 00, 00)
	
	// Team change 
	replace userid = "C8" if userid=="K3" & starttime >= ///
		mdyhms(6, 19, 2018, 00, 00, 00)
	
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

	use "$TempFolder/Speakup_Round4_preclean.dta", clear

	preserve 
	
	// generate a string variable for each date
	gen entrydate = dofc(submissiondate)
	format entrydate %td
	gen sub_date_day = day(entrydate)
	gen sub_date_month = month(entrydate)
	tostring sub_date_day, replace
	tostring sub_date_month, replace
	gen date_str = sub_date_day + "_" + sub_date_month + "_2018"
	
	// sort bu userid and entrydate
	sort userid entrydate

	// collapse on userid and entrydate
	by userid entrydate: egen entry_amt=count(entrydate)
	collapse entry_amt, by(userid entrydate date_str)
	
	drop entrydate
	
	// reshape such that data shows amount of entries per userid per date
	reshape wide entry_amt, i(userid) j(date_str) string
	
	// generate variables to distinguish supervisors and interns
	gen intern = 0
	replace intern = 1 if (substr(userid, 1, 1) == "I")
	gen supervisor = 0
	replace supervisor = 1 if (substr(userid, 2, 1) == "1" & intern != 1)
	
	// replace missing values with zeros for amount of entries on each date
	foreach x of varlist entry_amt* {
		replace `x' = 0 if missing(`x') 
	}
	
	// set labels for output
	label var userid "User ID"
	local number_of_days = c(k) - 3
	// this is only valid for June and July with a start date of June 14
	// this should be changed if this code is used for another purpose
	local last_day = 14 + `number_of_days' - 1
	forvalues i = 14/`last_day' {
		if (`i' <= 30) {
			label var entry_amt`i'_6_2018 "`i' Jun 2018"
		}
		else {
			local day = `i' - 30
			label var entry_amt`day'_7_2018 "`day' Jul 2018"
		}
	}
	
	// Export to excel
	export excel userid entry_amt* ///
		using "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
		if supervisor != 1 & intern != 1, ///
		sheetreplace sheet("Pairs") firstrow(varl) cell(A2)
		
	count if supervisor != 1 & intern != 1
	local enum_ct = r(N)
	local sup_cell = `enum_ct' + 5
	export excel userid entry_amt* ///
		using "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
		if supervisor == 1 & intern != 1, ///
		sheetmodify sheet("Pairs") firstrow(varl) cell(A`sup_cell')
		
	count if supervisor == 1
	local sup_ct = r(N)
	local intern_cell = `sup_cell' + `sup_ct' + 3
	export excel userid entry_amt* ///
		using "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
		if supervisor != 1 & intern == 1, ///
		sheetmodify sheet("Pairs") firstrow(varl) cell(A`intern_cell')
		
	putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify ///
			sheet("Pairs")
			
	putexcel A1 = "Enumerators", bold overwritefmt
	// Ensure column loops to AA after Z
	local export_col_num = 65 + `number_of_days'
	local export_col = "A"
	if (`export_col_num') <= 90 {
		local export_col = char(`export_col_num')
	}
	else {
		local export_col = char(`export_col_num' - 26)
		local export_col = "A" + "`export_col'"
	}
	putexcel (A2:`export_col'2), bold border(bottom, medium, black)
	local enum_end = `enum_ct' + 2
	putexcel (A3:A`enum_end'), border(right, medium, black)
	
	local sup_title = `sup_cell' - 1
	putexcel A`sup_title' = "Supervisors", bold overwritefmt
	putexcel (A`sup_cell':`export_col'`sup_cell'), ///
		bold border(bottom, medium, black)
	local sup_start = `sup_cell' + 1
	local sup_end = `sup_ct' + `sup_cell'
	putexcel (A`sup_start':A`sup_end'), border(right, medium, black)
		
	local intern_title = `intern_cell' - 1
	putexcel A`intern_title' = "Interns", bold overwritefmt
	putexcel (A`intern_cell':`export_col'`intern_cell'), ///
		bold border(bottom, medium, black)
	local intern_start = `intern_cell' + 1
	count if intern == 1
	local intern_ct = r(N)
	local intern_end = `intern_ct' + `intern_cell'
	putexcel (A`intern_start':A`intern_end'), border(right, medium, black)
	
	local teams "I" "C" "E" "K" "N" "U" "W"
	local team_sizes = ""
	local team_ct : list sizeof teams
	forvalues i = 1/`team_ct' {
		local team_to_check `: word `i' of `teams''
		if (`"`team_to_check'"' != `"I"') {
			count if substr(userid, 1, 1) == `"`team_to_check'"' /// 
				& substr(userid, 2, 1) != "1"
			local team_size = r(N)
			local team_sizes `team_sizes' "`team_size'"
		}
	}
	
	local hl_start = 2
	forvalues i = 2/`team_ct' {
		local hl_dist `: word `i' of `team_sizes''
		local hl_start = `hl_start' + `hl_dist'
		putexcel (A`hl_start':`export_col'`hl_start'), ///
			border(bottom, thin, black) 
	}
		
	restore
	
}
	
***********************graph******************************

if ("$enum_graph" == "on") {

	use "$TempFolder/Speakup_Round4_preclean.dta", clear

	preserve
	format starttime %tcHH:MM:SS
	format endtime %tcHH:MM:SS
	
	// CHOOSE WHICH TEAM IS GRAPHED HERE:
// 	local team_choice = "E"
// 	local team_choice = "W"
// 	local team_choice = "N"
// 	local team_choice = "C"
// 	local team_choice = "K"
// 	local team_choice = "U"
	local team_choice = "I"

	if ("$debug" == "on") {
		disp "The chosen team is: `team_choice'"
	}
	
	// SELECT DATE OF GRAPH HERE
	gen startdate=dofc(starttime)
	keep if startdate==mdy(06,19,2018) // THIS IS THE VALUE TO CHANGE
	
	gen date_HRF = dofc(starttime)
	format date_HRF %td
	local title_d = day(date_HRF)
	local title_m = month(date_HRF)
	local title_y = year(date_HRF)
	
	keep if userid == "`team_choice'1" | userid == "`team_choice'2" | /// 
		userid == "`team_choice'3" | userid == "`team_choice'4" | /// 
		userid == "`team_choice'5" | userid == "`team_choice'6" | ///
		userid == "`team_choice'7" | userid == "`team_choice'8" | ///
		userid == "`team_choice'9" 
	gen starttime2 = hh(starttime)+mm(starttime)/60+ss(starttime)/3600
	
	// generate missing enumerators
	local max_team = 9
	list userid
	forvalues i = 1/`max_team' {
		local userid_to_check = "`team_choice'`i'"
		if  !(`: list userid_to_check in userid') {
			local numobs = _N + 1
			set obs `numobs'
			replace userid = "`team_choice'`i'" in l
		}
	}
	
	// Drop unused ID's for each enumerator
	local number_team=0
	/*central*/ 
	if "`team_choice'"== "C" {
		drop if userid == "C3" | userid == "C5" | userid == "C6" |  userid == "C9" 
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Rosemary A." 2 "Martin R.E." 3 "Cissy N." /// 
			4 "Samuel Besigwa" 5 "Flavia N.", modify
		local number_team = 5
	}

	/*Kampala*/
	if "`team_choice'"== "K" {
		drop if userid == "K3"
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Joseline N." 2 "Peter K." 3 "Davis M." 4 /// 
			"Doreen T." 5 "Kenneth Y." 6 "Anita K." 7 "Mary Clare K." 8 ///
			"Irene(Atto) N.", modify
		local number_team = 8
	}
	/*Uganda*/	
	if "`team_choice'"== "U" {
		drop if userid == "U8" | userid == "U9"
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Isaac Kimbugwe" 2 "Justine K." 3 ///
			"Rosemary U." 4 "Mercy C." 5 "Isaac Kitabye" 6 ///
			"Abdulrazaq(Zach) S." 7 "Pamela N.", modify
		local number_team = 7
	}
	/*eastern*/
	if "`team_choice'"== "E" {
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Honda A." 2 "Catherine N." 3 "Alfred B." ///
			4 "Tom E." 5 "Brenda K." 6 "Paul S." 7 "Emmanuel B." 8 ///
			"Christine L." 9 "Martha T.", modify
		local number_team = 9
	}
	/*western*/
	if "`team_choice'"== "W" {
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Blaise M." 2 "Owen A." 3 "Anthony K." 4 ///
			"Christine Kansiime" 5 "Janet M." 6 "Irene(Annet) K." 7 ///
			"Edwin B." 8 "Kaunda(Kakaya) E." 9 "Patrick A.", modify
		local number_team = 9
	}
	/*northern*/
	if "`team_choice'"== "N" {
		drop if userid == "N5"
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Julie G." 2 "Samuel Basoga" 3 "Ritah K." 4 ///
			"Reagan K." 5 "Allan Erema S." 6 "Kizito K." 7 ///
			"Dora A." 8 "Agnes N.", modify
		local number_team = 8
	}
	/*intern*/
	if "`team_choice'"== "I" {
		drop if userid == "I4" | userid == "I5" | userid == "I6" | /// 
			userid == "I7" | userid == "I8" | userid == "I9" 
		encode userid, generate (userid2)
		label list userid2
		label define userid2 1 "Graham S." 2 "Yuou W." 3 "Jacklyn P.", modify
		local number_team = 3
	}
	
	// generate graph
	twoway scatter userid2 starttime2, ///
		title("Survey Distribution for Team `team_choice' on `title_d'/`title_m'/`title_y'") ///
		yti("Enumerator") xti("Survey Start") /// 
		xlabel(8 "8:00" 9 "09:00" 10 "10:00" 11 "11:00" 12 "12:00" 13 "13:00" ///
		14 "14:00" 15 "15:00" 16 "16:00" 17 "17:00" 18 "18:00") ///
		ylabel(1(1)`number_team', valuelabel angle(0))
	
	if "`c(username)'" == "grahamstubbs" {
		cd "/Users/grahamstubbs/Documents/Summer_2018/SpeakUp_Uganda"
		graph export "Team_`team_choice'_`title_d'_`title_m'_`title_y'.png", as(png)
		cd "/Users/grahamstubbs/Documents/Summer_2018/stata/SpeakUp-HFCs"
	}
	drop startdate starttime2
	
	restore
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

use "$TempFolder/Speakup_Round4_preclean.dta", clear
preserve

*************************dashboard set up************************
	putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify sheet ("Enums")
	putexcel A2 = ("enums") B2 = ("number of entries") /// 
		C2= ("avg. duration or entries") D2=("avg. start time") ///
		E2=("avg. end time") H2=("TAR") J2=("Time") L2=("# deaths") ///
		N2=("# injuries") B1=("Metadata") ///
		F1=("H+R") H1=("Missing Values")
	putexcel (A3:O3), border(bottom, thin, black)

**********************record values******************************
	*average duration*
	destring duration, replace
	bysort userid: egen avg_durationsec = mean(duration)
	gen avg_duration=avg_durationsec/60
	*average start/end times*
	bysort userid: egen avg_starttime = mean(starttime)
	bysort userid: egen avg_endtime = mean(endtime)
	format avg_starttime %tcHH:MM:SS
	format avg_endtime %tcHH:MM:SS
	*total entries*
	egen totalentries = count(userid), by (userid)
	
	*H+R*

	bysort userid: egen totalhitandrun=total(hitandrun==1)
	gen percenthitandrun = totalhitandrun/totalentries
	format percenthitandrun %9.2fc
	
	*missing values*
	*TAR*
	bysort userid: egen totalTARmissing=total(tar_number==9999)
	gen percentTARmissing=totalTARmissing/totalentries
	format percentTARmissing %9.2fc
	*time*
	destring time, replace
	bysort userid: egen totaltimemissing=total(time==9999)
	gen percenttimemissing=totaltimemissing/totalentries
	format percenttimemissing %9.2fc
	*death*
	bysort userid: egen totaldeathmissing=total(deathcount==9999)
	gen percentdeathmissing=totaldeathmissing/totalentries 
	format percentdeathmissing %9.2fc
	*injury*
	bysort userid: egen totalinjurymissing=total(injurycount==9999)
	gen percentinjurymissing=totalinjurymissing/totalentries
	format percentinjurymissing %9.2fc
	
	/*export to excel*/
	collapse totalentries avg_duration avg_starttime avg_endtime ///
		totalhitandrun percenthitandrun totalTARmissing percentTARmissing ///
		totaltimemissing percenttimemissing totaldeathmissing ///
		percentdeathmissing totalinjurymissing percentinjurymissing, by(userid)
	export excel using "$OutputFolder/Monitoring_template_Rd4.xlsx", ///
		cell(A4) sheet ("Enums", modify)
	levelsof userid
	local linedist = r(r) + 3
	putexcel (A1:A`linedist'), border(right, thin, black)
	putexcel (E1:E`linedist'), border(right, thin, black)
	putexcel (G1:G`linedist'), border(right, thin, black)
	putexcel (O1:O`linedist'), border(right, thin, black)
	
	putexcel (G4:G60), nformat(percent_d2)
	putexcel (I4:I60), nformat(percent_d2)
	putexcel (K4:K60), nformat(percent_d2)
	putexcel (M4:M60), nformat(percent_d2)
	putexcel (O4:O60), nformat(percent_d2)
	
	putexcel F3 = "#"
	putexcel G3 = "%"
	putexcel H3 = "#"
	putexcel I3 = "%"
	putexcel J3 = "#"
	putexcel K3 = "%"
	putexcel L3 = "#"
	putexcel M3 = "%"
	putexcel N3 = "#"
	putexcel O3 = "%"
	putexcel (A1:O3), bold
	
restore
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
	
	// Use the global variable $fill_in_previous_dates to posthumously perform 
	//   the HFC for previous dates, (may be slow) - turn off to only perform 
	//   HFC for today's date. If the HFC is run every day this is not needed,
	//   but it is useful if a day is missed

	local loop_end = 1
	// Figure out how many days need to be filled in
	if ("$fill_in_previous_dates" == "on") {
		// this is only valid for June and July with a start date of June 14
		// this should be changed if this code is used for another purpose
		gen date_num = substr("$today", 1, 2)
		gen month_str = substr("$today", 4, 3)
		gen month_num = "0"
		if (month_str == "Jun") {
			replace month_num = "6"
		}
		if (month_str == "Jul") {
			replace month_num = "7"
		}
		destring date_num, replace
		destring month_num, replace
		local loop_end = 0
		if (month_num == 6) {
			local loop_end = date_num - 13
		}
		else if (month_num == 7) {
			local loop_end = date_num + 17
		}
		if ("$debug" == "on") {
			disp "Previous dates will be filled in"
			disp "Number of loops to be performed: `loop_end'"
		}
	}
	
	forvalues HFC_loop_num = 1/`loop_end' {
	
		use "$TempFolder/Speakup_Round4_preclean.dta", clear
		preserve
		
		if ("$fill_in_previous_dates" == "on") {
			// as the outer loop iterates, this (temporaritly) drops all obs 
			//  submitted for dates after the date the current iteration of the 
			//  loop is looking at
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
			
			// drop unneeded vars
			drop sub_date_day sub_date_month sub_date_num
		}
	
		*************************** get Total records **************************
		count
		local total_records = r(N)
		
		// determine export column depding on date of observations currently
		//  being viewed by this iteration of the for loop
		local export_col = "A"
		local export_col_num = 0
		if ("$fill_in_previous_dates" == "on") {
			local export_col_num = `HFC_loop_num' + 13 + 53
		}
		else {
			gen date_num = substr("$today", 1, 2)
			destring date_num, replace
			local export_col_num = date_num + 53
			drop date_num
		}
		
		// Ensure column loops to AA after Z
		if (`export_col_num') <= 90 {
			local export_col = char(`export_col_num')
		}
		else {
			local export_col = char(`export_col_num' - 26)
			local export_col = "A" + "`export_col'"
		}
		
		// export to excel
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify ///
			sheet("Quality")
		
		// this only needs to be exported once
		if (`HFC_loop_num' == `loop_end') {
			putexcel A2 = "Summary of Potential Errors", bold
			putexcel B4 = "Total Records"
			putexcel B6 = "# H+R accidents"
			putexcel B7 = "% of H+R accidents"
			putexcel B9 = "# duplicate accidents"
			putexcel B10 = "% of duplicate accidents"
			putexcel B12 = "# flags from comment"
			putexcel B13 = "% flags from comment"
			putexcel (B4:B13), border(right, medium, black)
		}
		if ("$debug" == "on") {
			disp "Today: $today"
			disp "Exporting summaries to column `export_col'"
		}
		
		// Determine what to label column dates
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
		putexcel `export_col'3 = "`date_str'", bold ///
			border(bottom, medium, black) font("Calibri (Body)", 11, black) ///
			overwritefmt
		putexcel `export_col'4 = `total_records'
		
		
		/* get number and percent of hit&runs */
		count if hitandrun == 1
		local hitandrun_amt = r(N)
		local hitandrun_pct = `hitandrun_amt'/`total_records'
		
		// export to excel
		putexcel `export_col'6 = `hitandrun_amt'
		putexcel `export_col'7 = (`hitandrun_pct'), nformat(percent_d2)	
		
		// these only need to be exported once
		if (`HFC_loop_num' == `loop_end') {
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
				if hitandrun == 1, sheetreplace sheet("_export H+R ") ///
				firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", ///
				modify sheet("_export H+R ")
			local hr_highlight_length = `hitandrun_amt'+1
			putexcel (AA1:AA`hr_highlight_length'), ///
				fpattern(solid, lightpink, lightpink) overwritefmt
			putexcel (A1:GF1), bold border(bottom, thin, black)
		}
		
		*********** Flag and export all entries with potential issues **********
		gen potential_issues = 0
		
		// generate a new variable that is equivalent to additionalinfo but 
		//   ensures all values are lowercase for easy comparison
		gen additionalinfo_lower = lower(additionalinfo)
		
		// remove punctuation
		replace additionalinfo_lower = ///
			subinstr(additionalinfo_lower, ".", "", .)
		
		// flag entries that may contain something worth checking
		replace potential_issues = 1 if (additionalinfo_lower != "" ///
			& additionalinfo_lower != "none" & additionalinfo_lower != "no" ///
			& additionalinfo_lower != "n/a" & additionalinfo_lower != "nothing")
		
		// drop uneeded var
		drop additionalinfo_lower
		
		// get counts
		count if potential_issues == 1
		local flags_count = r(N)
		local flags_pct = `flags_count'/`total_records'
		
		// export to excel
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify ///
			sheet("Quality")
		putexcel `export_col'12 = `flags_count'
		putexcel `export_col'13 = `flags_pct', nformat(percent_d2)
		
		if (`HFC_loop_num' == `loop_end') {
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
				if potential_issues==1, sheetreplace sheet("_export flags") ///
				firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", ///
				modify sheet("_export flags")
			local flags_highlight_length = `flags_count' + 1
			putexcel (AM1:AM`flags_highlight_length'), ///
				fpattern(solid, lightpink, lightpink) overwritefmt
			putexcel (A1:GH1), bold border(bottom, thin, black)
		}
		
		// drop var that is no longer needed
		drop potential_issues
		
		
		********************* search and record duplicates *********************
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
		
		// iterate through records until reaching the records for which they 
		//   have no duplicate dates
		while `i' <= `total_records' & same_date_grouped[`i'] != 0 {
		
			local amt_to_check = same_date[`i']	
			local psvlist
			local psvlist_size = 0
			local j = `i'
			
			// iterate through groups of records that were determined to have  
			//   the same date
			while `j' <= (`i' + `amt_to_check') {
			
				local k = 1
				
				// for each of these records, add their psv registration numbers 
				//   to a list. If one of their psv registration numbers is 
				//   already on the list, mark the matching records as 
				//   duplicates
				while `k' <= psvcount[`j'] {
				
					local psvregistration_k_j = psvregistration`k'[`j']
					if "$debug" == "on" {
							display ///
								"psvregistration`k'[`j']: `psvregistration_k_j'" 
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
						
						// if the list is not empty but the psv registration 
						//   number is not found on the list, add it to the list
						else if !(`: list psvregistration_k_j in psvlist') {
							local psvlist `psvlist' `psvregistration_k_j'
							local psvlist_size = `psvlist_size' + 1
							
							if ("$debug" == "on") {
								display "`psvregistration_k_j' is not on the list; add it"
								display "list is now `psvlist'"
								display "size is now `psvlist_size'"
							}
						}
						
						// if the psv registration number IS on the list, mark  
						//   the records as duplicates
						else {
							local group_ct = same_date_grouped[`i']
							
							if ("$debug" == "on") {
								display "`psvregistration_k_j' is already on the list!!"
								display "putting '`group_ct'' in record `j'"
							}
							
							replace duplicates_grouped = /// 
								same_date_grouped[`i'] if _n == `j'
							local position : list posof ///
								"`psvregistration_k_j'" in psvlist
							local psv_counter = 0
							
							if "$debug" == "on" {
								display "position: `position'"
							}
							
							// search the list for the matching psv registration 
							//   number and use its position to determine which 
							//   of the other records with the same date is the 
							//   one with the matching psv registration number
							forvalues m = `i'/`j' {
								local psv_counter = `psv_counter' + ///
									psvcount[`m']
								
								if "$debug" == "on" {
									display "psv_counter: `psv_counter'"
									display "m: `m'"
								}
								
								if (`psv_counter' >= `position') {
									local group_ct = same_date_grouped[`i']
									
									if "$debug" == "on" {
										display ///
											"putting '`group_ct'' in record `m'" 
									}
									
									replace duplicates_grouped = ///
										same_date_grouped[`i'] if _n == `m'
									continue, break
								}
							}
							
							// then add the duplicate to the list anyways so 
							//   future counts are consistent
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
		//   traditional values expected in the duplicates variable (contained 
		//   in duplicates_amt)
		duplicates tag duplicates_grouped if duplicates_grouped != 0, /// 
			gen(duplicates_amt)
		
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
		putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify ///
			sheet("Quality")
		
		putexcel `export_col'9 = `duplicate_count'
		putexcel `export_col'10 = (`duplicate_pct'), nformat(percent_d2)
		
		// These only need to be exported once
		if (`HFC_loop_num' == `loop_end') {
			putexcel A9 = ///
				"This is the amount of records that are likelyduplicates of another", ///
				italic font("Calibri (Body)", 11, red)
			export excel "$OutputFolder/Monitoring_template_Rd4.xlsx" ///
				if duplicates_grouped != 0, sheetreplace /// 
				sheet("_export dups") firstrow(var)
			putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", /// 
				modify sheet("_export dups")
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
					putexcel (A`highlight_start':GJ`highlight_end'), /// 
						fpattern(solid, "198 242 255", "198 242 255") ///
						overwritefmt
				}
				else if (mod(`loops', 2) == 1) {
					putexcel (A`highlight_start':GJ`highlight_end'), /// 
						fpattern(solid, "255 222 173", "255 222 173") ///
						overwritefmt
				}
		
				local i = `i' + duplicates_amt[`i'] + 1
				local highlight_start = `highlight_end' + 1
				local loops = `loops' + 1
			}
		}
		
		restore
		
		if ("$debug" == "on") {
			disp "End of loop `HFC_loop_num'"
		}
	}
	
****************************    SURVEY PROGRESS    *****************************
		
	use "$TempFolder/Speakup_Round4_preclean.dta", clear
	preserve
	
	// Get total number of records (for percent)
	count
	local total_records = r(N)
	
	// sort by region and ignore capitalization for substations
	sort region subregion station substation
	replace substation = lower(substation)
	
	// contract to variables of interest
	contract region subregion station substation
	rename _freq amount
	gen percent = (amount/`total_records')
	
	count
	local pct_length = r(N) + 1
	
	// Export to excel
	export excel "$OutputFolder/Monitoring_template_Rd4.xlsx", ///
			sheetmodify sheet("Progress") firstrow(var)
	
	putexcel set "$OutputFolder/Monitoring_template_Rd4.xlsx", modify ///
			sheet("Progress")
			
	putexcel (A1:F1), bold border(bottom, medium, black)
	putexcel (F2:F`pct_length'), nformat(percent_d2)
	
	restore
	
	putexcel close
}
