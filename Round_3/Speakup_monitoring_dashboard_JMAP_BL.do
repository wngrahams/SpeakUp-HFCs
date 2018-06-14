/* 
Name: Speakup_monitoring_dashboard_Round3_JMAP.do
Date Created: November 10, 2017
Date Last Modified: November 22, 2017
Created by: John Marshall and Akaravuit Pancharoen
Uses data: Speak Up Midline Survey.dta
Creates data: 
Description: This file generates the monitoring dashboard
for round 3 data collection in Uganda. However, in order to track daily update,
we have to run dofile once the data(dta) file update.
*/

clear all
capture log close
set more off

*Beatrice 1
else if c(username)=="bl517" {
	global user "C:/Users/bl517/Box Sync/Data Analysis/SpeakUp"
	}
*Jack	
else if c(username)=="jackmarshall"{
	global user "/Users/jackmarshall/Desktop/Gui2de"
	}
*Woody	(Windows)
else if c(username)=="p.akaravuit"{
	global user "C:/Users/p.akaravuit/Desktop/Box Sync/SpeakUp"
	}
	
cd "$user"

*file paths
global RawFolder "$user/Data/Raw/Speakup Round3"
global TempFolder "$user/Data/Temp"
global DofileFolder "$user/Dofiles/Monitoring"
global ExcelFolder "$user/Monitoring/Round 3 monitoring dashboard"

* Pull data

use "$RawFolder/Speak Up Round 3 Survey.dta", clear

	//////////////////////////////////////////
		********Summary Stat********
	//////////////////////////////////////////

/*Supervisor and fired persons - Assign types to enums*/

****Check with Beatrice who are supervisors and who were fired for the current round****
*Supervisor
gen supervisor = 0
replace supervisor = 1 if username=="veronica.viata" | username=="faith.ndungu" | ///
	username=="dickens.adoyo" | username=="alex.amolo" | username=="rahma.rashid" | ///
	username=="julia.wangare"
	
	*As of 10/9/2017 Jack Omondi took over for Ibramhim in Garissa. Garissa is an NTSA officer.
replace username="ntsa officers" if username=="ibrahim.sheikh"
	
	//On 05/23, 12 obs submitted by supervisors (Dickens acting on behalf of Michael)
replace supervisor = 1 if username=="staff/interns"
replace supervisor = 1 if username=="ntsa officers"

*Fired persons	
gen fired = 0
replace fired = 1 if username=="may.odhiambo" | username=="geoflas.ijakaa" | username=="tessy.njoroge"
	//On 05/23, 4 entries by May and 0 by Geoflas
	//428 entries from Tessy


/*This sheet consists of multi summary stat for round 3. it is date-specific output.
And a single sheet summarizes some important stats and adds every time we rerun this dofile.*/

putexcel set "$ExcelFolder/results.xlsx", modify sheet("Summary Stat", replace)

	*A. usernames
*program writeenums
	levelsof user_id if supervisor == 0 & fired==0, local(enums)
	putexcel A2 = ("Enum")
	local i = 3
		foreach name in `enums' {
			putexcel A`i' = ("`name'")
			local i = `i' + 1
		}
/* This part is cut-off once confirm who is supervisor and fired person*** (loop usernames)
	levelsof user_id if supervisor == 0 & fired==1, local(enumsfired)
	local i = `i'+2
	global firstlinefired = `i'
		foreach name in `enumsfired' {
			putexcel A`i' = ("`name'")
			local i = `i' + 1
		}
		
	levelsof user_id if supervisor == 1, local(supervisors)
	local i = `i'+2
	global firstlinesupervisors = `i'
		foreach name in `supervisors' {
			putexcel A`i' = ("`name'")
			local i = `i' + 1
		}		
*/	
*end	writeenums	

	*B. total
putexcel B2 = ("Total entries")
tab user_id if supervisor == 0 & fired==0, matcell(totals)
putexcel B3=matrix(totals)
/*  This part is cut-off once confirm who is supervisor and fired person*** (total entries)
tab user_id if supervisor == 0 & fired==1, matcell(totals)
putexcel B$firstlinefired = matrix(totals)
tab user_id if supervisor == 1, matcell(totals)
putexcel B$firstlinesupervisors = matrix(totals)
*/
	*C. duration
putexcel C2 = ("Av. duration")
destring(duration), replace
bysort user_id: egen meanduration = mean(duration)
local i = 3
levelsof user_id if supervisor == 0 & fired==0, local(enums)
foreach name in `enums' {
	levelsof meanduration if user_id=="`name'", local(meanduration_enum)
	putexcel C`i' = ("`meanduration_enum'")
	*putexcel C`i' = nformat("number_d2")
	local i = `i' + 1
}

/*  This part is cut-off once confirm who is supervisor and fired person*** (mean duration)
local i = $firstlinefired
levelsof user_id if supervisor == 0 & fired==1, local(enums)
foreach name in `enums' {
	levelsof meanduration if user_id=="`name'", local(meanduration_enum)
	putexcel C`i' = ("`meanduration_enum'", nformat(number))
	local i = `i' + 1
}
local i = $firstlinesupervisors
levelsof user_id if supervisor == 1, local(enums)
foreach name in `enums' {
	levelsof meanduration if user_id=="`name'", local(meanduration_enum)
	putexcel C`i' = ("`meanduration_enum'", nformat(number))
	local i = `i' + 1
}
*/

	*D. Av number of surveys each day
preserve
*change format of submissiondate from string to numeric(date)
	gen subdate_temp = dofc(submissiondate)
	format subdate_temp %td 
*create new variable to capture number of surveys for each day
	sort user_id subdate_temp
	by user_id subdate_temp: egen surveys_perday=count(subdate_temp) 
	*count surveys done each day	
	collapse (mean) surveys_perday, by(user_id subdate_temp)
	collapse (mean) avg_surveys_perday=surveys_perday, by(user_id)
	save "$TempFolder/Round3formerge_temp.dta", replace
restore

sort user_id
merge m:1 user_id using "$TempFolder/Round3formerge_temp.dta",gen(_merge_survey_avg)

putexcel set "$ExcelFolder/results.xlsx", sheet("Summary Stat") modify
putexcel D2=("Av. number of surveys")	

local i = 3
levelsof user_id if supervisor == 0 & fired==0, local(enums)
foreach name in `enums' {
	levelsof avg_surveys_perday if user_id=="`name'", local(avg_surveys_perday_enum)
	putexcel D`i' = ("`avg_surveys_perday_enum'")
	local i = `i' + 1
}
/*
local i = $firstlinefired
levelsof username if supervisor == 0 & fired==1, local(enums)
foreach name in `enums' {
	levelsof avg_surveys_perday if username=="`name'", local(avg_surveys_perday_enum)
	putexcel D`i' = "`avg_surveys_perday_enum'", nformat(number)
	local i = `i' + 1
}
local i = $firstlinesupervisors
levelsof username if supervisor == 1, local(enums)
foreach name in `enums' {
	levelsof avg_surveys_perday if username=="`name'", local(avg_surveys_perday_enum)
	putexcel D`i' = "`avg_surveys_perday_enum'", nformat(number)
	local i = `i' + 1
}
*/

	*E. Average start time

putexcel set "$ExcelFolder/results.xlsx", sheet("Summary Stat") modify
putexcel E2=("Average start time")

*determine starttime for each day by each username
sort user_id starttime
by user_id starttime: egen starttime_day=min(starttime)
format %tC starttime_day

*pull out time of date variable
gen starttime_hour=hh(starttime_day)+mm(starttime_day)/60

sort user_id
by user_id: egen meanstarttime=mean(starttime_hour)

local i = 3
levelsof user_id if supervisor == 0 & fired==0, local(enums)
foreach name in `enums' {
	levelsof meanstarttime if user_id=="`name'", local(meanstarttime_enum)
	putexcel E`i' = ("`meanstarttime_enum'")
	local i = `i' + 1
}
/*
local i = $firstlinefired
levelsof username if supervisor == 0 & fired==1, local(enums)
foreach name in `enums' {
	levelsof meanstarttime if username=="`name'", local(meanstarttime_enum)
	putexcel E`i' = "`meanstarttime_enum'", nformat(number)
	local i = `i' + 1
}
local i = $firstlinesupervisors
levelsof username if supervisor == 1, local(enums)
foreach name in `enums' {
	levelsof meanstarttime if username=="`name'", local(meanstarttime_enum)
	putexcel E`i' = "`meanstarttime_enum'", nformat(number)
	local i = `i' + 1
}
*/
	*F. Av. Submission time
putexcel set "$ExcelFolder/results.xlsx", sheet("Summary Stat") modify
putexcel F2=("Av. submission time")


gen hour=hh(submissiondate) + mm(submissiondate)/60
sort user_id
by user_id: egen meansubmissiontime=mean(hour)

local i = 3
levelsof user_id if supervisor == 0 & fired==0, local(enums)
foreach name in `enums' {
	levelsof meansubmissiontime if user_id=="`name'", local(meansubmissiontime_enum)
	putexcel F`i' = ("`meansubmissiontime_enum'")
	local i = `i' + 1
}
/*
local i = $firstlinefired
levelsof username if supervisor == 0 & fired==1, local(enums)
foreach name in `enums' {
	levelsof meansubmissiontime if username=="`name'", local(meansubmissiontime_enum)
	putexcel F`i' = "`meansubmissiontime_enum'", nformat(number)
	local i = `i' + 1
}
local i = $firstlinesupervisors
levelsof username if supervisor == 1, local(enums)
foreach name in `enums' {
	levelsof meansubmissiontime if username=="`name'", local(meansubmissiontime_enum)
	putexcel F`i' = "`meansubmissiontime_enum'", nformat(number)
	local i = `i' + 1
}
*/ 
/*
	*G. Duplicate Count
putexcel set "$ExcelFolder/results.xlsx", sheet("Summary Stat") modify
putexcel G2=("Duplicate Count")

bysort user_id: egen duplicate_count= count(duplicatescheck)

local i = 3
levelsof user_id if supervisor == 0 & fired==0, local(enums)
foreach name in `enums' {
	levelsof duplicate_count if user_id=="`name'", local(duplicate_count)
	putexcel G`i' = ("`duplicate_count'")
	local i = `i' + 1
}
duplicates report psvregistration1 user_id
duplicates tag psvregistration1 user_id, gen(duplicates)
sort psvregistration1 user_id
br if duplicates>0 
tab duplicates, matcell(entries) matrow(duplicates)
matrix list duplicates
putexcel A4=matrix(duplicates)
matrix list entries
putexcel B4=matrix(entries)

/*
local i = $firstlinefired
levelsof username if supervisor == 0 & fired==1, local(enums)
foreach name in `enums' {
	levelsof duplicate_count if username=="`name'", local(duplicate_count)
	putexcel G`i' = "`duplicate_count'", nformat(number)
	local i = `i' + 1
}
local i = $firstlinesupervisors
levelsof username if supervisor == 1, local(enums)
foreach name in `enums' {
	levelsof duplicate_count if username=="`name'", local(duplicate_count)
	putexcel G`i' = "`duplicate_count'", nformat(number)
	local i = `i' + 1
}
*/	
*/
		
	//////////////////////////////////////////
		******Part 1: Daily Entries****** 
	//////////////////////////////////////////
	
*this part counts number of daily entry by each enumerators.
  
*First step: create link to excel file 	
*creates the monitoring dashboard excel file, first sheet - daily entries
putexcel set "$ExcelFolder/results.xlsx", modify sheet("Daily Entries", replace)

*Second step: Enumerator namelist
*For now, we will use user_id as it is easier to understand compare to username
*creates the new column for each enumerators
putexcel A2 = ("Enum")
levelsof(user_id), local(enums)
local rownumber = 3
foreach i in `enums' {
	putexcel A`rownumber' = ("`i'")
	local rownumber = `rownumber' + 1
}


*Third step: days

/*creating a new submission date variable that doesn't include a time-stamp, 
in order to make it easier to sort enumerator entries by date*/
gen entry_date = dofc(submissiondate)
format entry_date %td 

*Cols: days
levelsof entry_date, local(days)
local alphabet = "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z AA AB AC AD AE AF AG AH AI AJ AK AL AM AN AO AP AQ AR AS AT AU AV AW AX AY AZ BA BB BC BD BE BF BG BH BI BJ BK BL BM BN BO BP BQ BR BS BT BU BV BW BX BY BZ CA CB CC CD CE CF CG CH CI CJ CK CL CM CN CO CP CQ CR CS CT CU CV CW CX CY CZ DA DB DC DD DE DF DG DH DI DJ DK DL DM DN DO DP DQ DR DS DT DU DV DW DX DY DZ EA EB EC ED EE EF EG EH"
local i = 2
foreach day in `days' {
	local colname = word("`alphabet'", `i')
	putexcel `colname'2 = `day', asdate
	local i = `i' + 1
	}

/*Second plan: manual update
putexcel A1=("User ID") B1=("Nov 6") C1=("Nov 7") D1=("Nov 8") ///
 E1=("Nov 9")F1=("Nov 10") G1=("Nov 11") H1=("Nov 12") I1=("Nov 13")J1=("Nov 14") ///
 K1=("Nov 15") L1=("Nov 16") M1=("Nov 17") N1=("Nov 18") O1=("Nov 19") ///
 P1=("Nov 20") Q1=("Nov 21") R1=("Nov 22") S1=("Nov 23") T1=("Nov 24") ///
 U1=("Nov 25") V1=("Nov 26") W1=("Nov 27") X1=("Nov 28") Y1=("Nov 29") Z1=("Nov 30")	
*/


*Fourth step: Counts number of entry for each enumerators separated into 3 cases:
*Case 1: non-supervisor and non-fired 
levelsof (user_id) if supervisor == 0 & fired==0, local(enums)
local iday = 2
local jenum = 3
foreach name in `enums' {
	foreach day in `days' {
		count if user_id =="`name'" & entry_date==`day'
		local colname = word("`alphabet'", `iday')
		putexcel `colname'`jenum' = ("`r(N)'")
		local iday = `iday' + 1
	}
	local jenum = `jenum' + 1
	local iday = 2
}
/* To be confirm supervisor and fired
*Case 2: non-supervisor and fired
levelsof (user_id) if supervisor == 0 & fired==1, local(enums)
local iday = 2
local jenum = $firstlinefired
foreach name in `enums' {
	foreach day in `days' {
		count if user_id=="`name'" & entry_date==`day'
		local colname = word("`alphabet'", `iday')
		putexcel `colname'`jenum' = ("`r(N)'")
		local iday = `iday' + 1
	}
	local jenum = `jenum' + 1
	local iday = 2
}

*Case 3: Supervisor
levelsof user_id if supervisor ==1, local(enums)
local iday = 2
local jenum = $firstlinesupervisors
foreach name in `enums' {
	foreach day in `days' {
		count if user_id=="`name'" & entry_date==`day'
		local colname = word("`alphabet'", `iday')
		putexcel `colname'`jenum' = ("`r(N)'")
		local iday = `iday' + 1
	}
	local jenum = `jenum' + 1
	local iday = 2
}
*/
/*Backup plan: loop through each day
*perpares the code for new round: loop for each day (problem: have to add new day)
levelsof(user_id), local(enums)
local rownumber = 2
foreach i in `enums' {
	matrix entries =[0]
	tab user_id if user_id == ("`i'") & entry_date==mdy(06,29,2017), matcell(entries)
	putexcel B`rownumber' = matrix(entries)
	local rownumber = `rownumber' + 1	
}
*/

	//////////////////////////////////////////
		******Part 2: Duration****** 
	//////////////////////////////////////////

*creates a second sheet "Duration" for the average duration time for each enumerators.
destring duration, replace // destringing duration variable
 	
putexcel set "$ExcelFolder/results.xlsx", modify sheet("Duration", replace)
putexcel A1=("User ID") B1=("Average Duration (Seconds)")

bysort user_id: egen avg_duration = mean(duration)

gen duration_mins = (1/60)*(duration)
bysort user_id: egen avg_duration_mins = mean(duration_mins)

levelsof(user_id), local(enums)
local rownumber = 2
foreach i in `enums' {
	putexcel A`rownumber' = ("`i'")
	sum avg_duration if user_id=="`i'"
	return list
	putexcel B`rownumber'=(r(mean))
	local rownumber = `rownumber' + 1
}
*Highlight enumerators' group, but we can leave it is for now as it might 
*unaccurate due to changing number of enumerators
/*
putexcel A1:B1=border(bottom, thick, black)
putexcel A10:B10=border(bottom, thick, black)
putexcel A18:B18=border(bottom, thick, black)
putexcel A25:B25=border(bottom, thick, black)
putexcel A29:B29=border(bottom, thick, black)
putexcel A35:B35=border(bottom, thick, black)
*/
	//////////////////////////////////////////
		******Part 3: Survey Progress****** 
	//////////////////////////////////////////

*new excel sheet 
putexcel set "$ExcelFolder/results.xlsx", modify sheet("Survey Progress", replace)
putexcel B1=("Observations") C1=("Percent")

*Total Entries
putexcel A2=("Total Entries")
count
return list
putexcel B2=(r(N))
*Percent
count 
local numerator = r(N)
putexcel C2=(`numerator'/`numerator')

*Duplicates 
putexcel A3=("Duplicates (no. of copies)")
duplicates report psvregistration1 tar_number
duplicates tag psvregistration1 tar_number, gen(duplicates)
sort psvregistration1 tar_number
br if duplicates>0 
tab duplicates, matcell(entries) matrow(duplicates)
matrix list duplicates
putexcel A4=matrix(duplicates)
matrix list entries
putexcel B4=matrix(entries)

/* *There is some errors, have to figure it out. 19 dups****
*Missing Value Patterns
count if additional==1 & notation =="" // 0
count if hiredpsv1==1 & privateuse1 =="" // 0
tab natureofaccident deathcount, missing // deathcount only positive for Fatal
*/

*TAR NUMBER - Missing from TAR/Case File - setting the scene
putexcel A8=("Missing from TAR/Case File")
*putexcel (A8:C8), merge
*Frequency
putexcel A9=("TAR Number")
count if tar_number=="9999"
putexcel B9=(r(N))
*Percent
count if tar_number=="9999"
local numerator = r(N)
count if tar_number !=""
local denominator = r(N)
putexcel C9=(`numerator'/`denominator')

*Time
*Frequency
putexcel A10=("Time")
count if time=="9999"
putexcel B10=(r(N))
*Percent
count if time=="9999"
local numerator = r(N)
count if time !=""
local denominator = r(N)
putexcel C10=(`numerator'/`denominator')

*Death count
*Frequency
putexcel A11=("Death Count")
count if deathcount==9999
putexcel B11=(r(N))
*percent
count if deathcount==9999
local numerator = r(N)
count if deathcount !=.
local denominator = r(N)
putexcel C11=(`numerator'/`denominator')

*Injury
*Frequency
putexcel A12=("Injury Count")
count if injurycount==9999
putexcel B12=(r(N))
*percent
count if injurycount==9999
local numerator = r(N)
count if injurycount !=.
local denominator = r(N)
putexcel C12=(`numerator'/`denominator')

*Cause of Accident
*Frequency
putexcel A13=("Cause of Accident")
count if causeofaccident==9999
putexcel B13=(r(N))
*Percent
count if causeofaccident==9999
local numerator = r(N)
count if causeofaccident !=.
local denominator = r(N)
putexcel C13=(`numerator'/`denominator')

*Hit and Runs
putexcel A7=("Hit and Runs")
count if hitandrun==1
putexcel B7=(r(N))
*Percent
count if hitandrun==1
local numerator = r(N)
count if hitandrun !=.
local denominator = r(N)
putexcel C7=(`numerator'/`denominator')
*making better table
putexcel C2:C13, nformat("percent")
putexcel A8:C8, border(bottom, thick, black)
putexcel B1:C1, border(bottom, thick, black)

	//////////////////////////////////////////
	****Part 4: MISSING FROM TAR/CASE FILE**** 
	//////////////////////////////////////////

putexcel set "$ExcelFolder/results.xlsx", modify sheet("Missing From TAR and Case File", replace)

putexcel A1=("User ID") B1=("Number of Entries") C1=("TAR Number") D1=("TPercentage") E1=("Time") F1=("TPercentage") G1=("Death Count") H1=("TPercentage") I1=("Injury Count") J1=("TPercentage") K1=("Cause of Accident") L1=("TPercentage")

levelsof(user_id), local(enums)
local rownumber = 2
foreach i in `enums' {
	putexcel A`rownumber' = ("`i'")
	local rownumber = `rownumber' + 1
}
gen temp = 1
tab user_id temp, matcell(totals)
matrix list entries
putexcel B2=matrix(totals)

tab user_id tar_number if tar_number=="9999", matcell(entries)
matrix list entries


local length = rowsof(entries)

local matrixstring = ""
forvalues i=1/`length' {
	gen numeric = entries[`i',1]
	tostring numeric, gen(currentstring)
	local matrixstring = "`matrixstring'" + currentstring + "\"
	drop currentstring
	drop numeric
}

local matrixstring = substr("`matrixstring'", 1, strlen("`matrixstring'") -1)

local additional_rows = rowsof(totals) - rowsof(entries)
forvalues i=1/`additional_rows' {
	local matrixstring = "`matrixstring'" + "\0"
}

matrix entries = (`matrixstring')
putexcel C2=matrix(entries)

matrix list entries

mata : st_matrix("percentage", 100 * st_matrix("entries") :/ st_matrix("totals"))

matrix list percentage

putexcel D2=matrix(percentage)


tab user_id time if time=="9999", matcell(entries)
matrix list entries


local length = rowsof(entries)

local matrixstring = ""
forvalues i=1/`length' {
	gen numeric = entries[`i',1]
	tostring numeric, gen(currentstring)
	local matrixstring = "`matrixstring'" + currentstring + "\"
	drop currentstring
	drop numeric
}

local matrixstring = substr("`matrixstring'", 1, strlen("`matrixstring'") -1)

local additional_rows = rowsof(totals) - rowsof(entries)
forvalues i=1/`additional_rows' {
	local matrixstring = "`matrixstring'" + "\0"
}

matrix entries = (`matrixstring')
putexcel E2=matrix(entries)

matrix list entries

mata : st_matrix("percentage", 100 * st_matrix("entries") :/ st_matrix("totals"))

matrix list percentage

putexcel F2=matrix(percentage)


tab user_id deathcount if deathcount==9999, matcell(entries)
matrix list entries


local length = rowsof(entries)

local matrixstring = ""
forvalues i=1/`length' {
	gen numeric = entries[`i',1]
	tostring numeric, gen(currentstring)
	local matrixstring = "`matrixstring'" + currentstring + "\"
	drop currentstring
	drop numeric
}

local matrixstring = substr("`matrixstring'", 1, strlen("`matrixstring'") -1)

local additional_rows = rowsof(totals) - rowsof(entries)
forvalues i=1/`additional_rows' {
	local matrixstring = "`matrixstring'" + "\0"
}

matrix entries = (`matrixstring')
putexcel G2=matrix(entries)

matrix list entries

mata : st_matrix("percentage", 100 * st_matrix("entries") :/ st_matrix("totals"))

matrix list percentage

putexcel H2=matrix(percentage)


tab user_id injurycount if injurycount==9999, matcell(entries)
matrix list entries


local length = rowsof(entries)

local matrixstring = ""
forvalues i=1/`length' {
	gen numeric = entries[`i',1]
	tostring numeric, gen(currentstring)
	local matrixstring = "`matrixstring'" + currentstring + "\"
	drop currentstring
	drop numeric
}

local matrixstring = substr("`matrixstring'", 1, strlen("`matrixstring'") -1)

local additional_rows = rowsof(totals) - rowsof(entries)
forvalues i=1/`additional_rows' {
	local matrixstring = "`matrixstring'" + "\0"
}

matrix entries = (`matrixstring')
putexcel I2=matrix(entries)

matrix list entries

mata : st_matrix("percentage", 100 * st_matrix("entries") :/ st_matrix("totals"))

matrix list percentage

putexcel J2=matrix(percentage)


tab user_id causeofaccident if causeofaccident==9999, matcell(entries)
matrix list entries


local length = rowsof(entries)

local matrixstring = ""
forvalues i=1/`length' {
	gen numeric = entries[`i',1]
	tostring numeric, gen(currentstring)
	local matrixstring = "`matrixstring'" + currentstring + "\"
	drop currentstring
	drop numeric
}

local matrixstring = substr("`matrixstring'", 1, strlen("`matrixstring'") -1)

local additional_rows = rowsof(totals) - rowsof(entries)
forvalues i=1/`additional_rows' {
	local matrixstring = "`matrixstring'" + "\0"
}

matrix entries = (`matrixstring')
putexcel K2=matrix(entries)

matrix list entries

mata : st_matrix("percentage", 100 * st_matrix("entries") :/ st_matrix("totals"))

matrix list percentage

putexcel L2=matrix(percentage)


	//////////////////////////////////////////
		****Part 5: Progress update**** 
	//////////////////////////////////////////

*This part tell us the number of accident recorded for each station 

putexcel set "$ExcelFolder/results.xlsx", modify sheet("Progress", replace)

putexcel A1=("Station name") B1=("Accident number") ///C1=("Percent of accident")

*station name lists in the first column (decode from string to numeric)
decode stationl, generate(stationl_temp)

levelsof(stationl_temp), local(enums)
local rownumber = 2
foreach i in `enums' {
	putexcel A`rownumber' = ("`i'")
	local rownumber = `rownumber' + 1
}

*adds frequency to the excel sheet
tab stationl_temp, matcell(entries)
matrix list entries
putexcel B2=matrix(entries)

/*percent
estpost tab stationl_temp
putexcel D2=matrix(e(pct))
*or
tabulate stationl_temp, matcell(pct)
putexcel D2=matrix(pct)
drop stationl_temp
*/

