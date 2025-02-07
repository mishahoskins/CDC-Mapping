
/*Reset Macros in case running separately*/
options compress=yes;
options nofmterr;
title;footnote;

/*Macros -- Don't update these*/
%let cardio = C:\Users\mhoskins1\Desktop\Work Files\Workflows\Cardiovascular;*<----- Pathway to extract;
/*Extract Source: https://archive.org/download/20250128-cdc-datasets*/

data cardio_import;
       %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
       infile "&cardio./Cardiovascular_Disease_Death_Rates_Trends_and_Excess_Death_Rates_Among_US_Adults_35_by_County_and_Age_Group_2010-2020.csv"

   delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;

          informat LocationID best32. ;
          informat Year $best32. ;
          informat LocationAbbr $2. ;
          informat GeographicLevel $6. ;
          informat DataSource $4. ;
          informat Class $23. ;
          informat Topic $28. ;
          informat Data_Value best32. ;
          informat Data_Value_Unit $13. ;
          informat Data_Value_Type $43. ;
          informat Data_Value_Footnote_Symbol $1. ;
          informat Data_Value_Footnote $1. ;
          informat Confidence_limit_Low best32. ;
          informat Confidence_limit_High best32. ;
          informat StratificationCategory1 $9. ;
          informat Stratification1 $16. ;
          informat TopicID $2. ;
          informat X_long best32. ;
          informat Y_lat best32. ;
          format LocationID best12. ;
          format Year best12. ;
          format LocationAbbr $2. ;
          format GeographicLevel $6. ;
          format DataSource $4. ;
          format Class $23. ;
          format Topic $28. ;
          format Data_Value best12. ;
          format Data_Value_Unit $13. ;
          format Data_Value_Type $43. ;
          format Data_Value_Footnote_Symbol $1. ;
          format Data_Value_Footnote $1. ;
          format Confidence_limit_Low best12. ;
          format Confidence_limit_High best12. ;
          format StratificationCategory1 $9. ;
          format Stratification1 $16. ;
          format TopicID $2. ;
          format X_long best12. ;
          format Y_lat best12. ;

       input
                   LocationID
                   Year $
                   LocationAbbr  $
                   GeographicLevel  $
                   DataSource  $
                   Class  $
                   Topic  $
                   Data_Value
                   Data_Value_Unit  $
                   Data_Value_Type  $
                   Data_Value_Footnote_Symbol  $
                   Data_Value_Footnote  $
                   Confidence_limit_Low
                   Confidence_limit_High
                   StratificationCategory1  $
                   Stratification1  $
                   TopicID  $
                   X_long
                   Y_lat
       ;
       if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

/*Confine to North Carolina*/
data cardio_import_nc;
set cardio_import;

if LocationAbbr not in ('NC') then delete;
run;

/*Assign 'County' variable with no leading 0's according to FIPS #*/
data cardio_nc_clean;
set cardio_import_nc;

x = put(LocationID, 5.); /*Make character*/
	county_1 = substr(x,3,3); /*Select last three digits (county # 001-199 by odd numbers)*/

		 county = input(county_1, 5.);/*back to numeric with proper naming*/

/*Tweak data_value; drop negatives and rename to Rate*/

Rate=.;
	if Stratification1 in ('Ages 35-64 years') and Data_value_type in ('Age-Standardized, Spatially Smoothed Rate') then Rate=Data_Value;

if Rate=. then delete;

/*Delete year ranges (we'll grab our own average rate from 2010-2020*/
	Year=Year;
	if Year = '2010-201' then delete;

/*Now year to numeric*/

	Year_new = input(year, 4.);

run;

/*Project map West-East (SAS flips it for some reason) using gproject with "degrees"*/
proc gproject data=maps.counties out=counties_projected degrees;
id county;
run;

/*Create count of avg. rate for each numeric county 1-199*/
proc sql;
create table map_counts as
select distinct

	county,
	mean(Rate) as avg_rate

from cardio_nc_clean
	group by County	 
;
quit;
/*100 rows (1 for each NC county)*/
/*Add state variable*/
data map_counts;
set map_counts;

	state=37;

run;
/*Run proc means to find averages/median for state*/
proc means data=map_counts Q1 Q3 Median Mean;
var avg_rate;
run;
/*Create buckets: adjust as necessary but make sure to update values in labels below*/
data map_counts_final;
set map_counts;

	if avg_rate <=117.21 then case_display=1;/*Lower quartile of values*/
	if 142.96=> avg_rate > 117.21 then case_display=2; /*Lower-middle quartile range*/
	if 163.85=> avg_rate > 142.96 then case_display=3; /*Upper-middle quartile range*/
	if 163.85 < avg_rate then case_display=4;/*Upper quartile*/


	if avg_rate <= 143.37 then case_display_med=1; /*at or below median*/
	if avg_rate > 143.37 then case_display_med=2; /*above median*/


run;



/*Format buckets*/
proc format;
	value case_display
	
	1= "117.21 excess mortality rate or less (Q1)"
	2= "117.21-142.96 excess mortality rate (Q2)"
	3= "142.96-163.85 excess mortality rate (Q3)"
	4= "163.85 excess mortality rate or more (Q4)"
;


	value case_display_med

	1= "Mortalty rate at or below NC median"
	2= "Mortality rate above NC median"
;
run;


/*Maps: I like blue/red mapping*/
/*Colors and legend*/
pattern1 value=solid color='CX90B0D9'; ****Pale blue****;
pattern2 value=solid color='CX8585A6'; ****Very light greenish blue****;
pattern3 value=solid color='CXE5C5C2'; ****Pale yellowish pink****;
pattern4 value=solid color='CX99615C'; ****Dark yellowish pink****;

pattern5 value=empty;****Blank/empty pattern****;



legend1 label =(f="albany amt" position=top j=c h=10pt "Rate per 100k Population (NC Median: 142.96)")
 value=(f="albany amt" h=8pt c=black tick=3)
 across=1
 position=(right middle) 
 offset=(-2,3)
 space=1
 mode=reserve
 order=descending
 shape=bar(.15in,.15in)
 ;



title height=12pt "Excess Cardiovascular Burden NC Counties"; /* add year macro */
title2 height=10pt "Excess rate expressed as average mortality rate per 100,000 Population ";
title3 height=10pt "Aged 35-64 years 2010-2020";
proc gmap map=counties_projected data=map_counts_final all;
format case_display case_display.;

	id county; /*Map to data by county identifier*/
	choro case_display/ discrete midpoints = 1 2 3 4 legend=legend1 coutline=white cdefault=white;  /*areas with no data (default) are also lightblue/green */


	where state= 37;	/*NC only*/
	label case_display = "Excess Death Rate per 100k Population";


	run;

	/*Binary map by median*/
pattern1 value=solid color='CX90B0D9'; ****Very light greenish blue****;
pattern2 value=solid color='CX99615C'; ****Dark yellowish pink****;

title height=12pt "Excess Cardiovascular Burden NC Counties"; /* add year macro */
title2 height=10pt "Excess rate expressed as average mortality rate per 100,000 Population ";
title3 height=10pt "Aged 35-64 years 2010-2020";
proc gmap map=counties_projected data=map_counts_final all;
format case_display_med case_display_med.;

	id county; /*Map to data by county identifier*/
	choro case_display_med/ discrete midpoints = 1 2  legend=legend1 coutline=white cdefault=white;  /*areas with no data (default) are also lightblue/green */


	where state= 37;	/*NC only*/
	label case_display_med = "Excess Death Rate per 100k Population";


	run;
