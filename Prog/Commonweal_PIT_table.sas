/**************************************************************************
 Program:  Commonweal_PIT_table.sas
 Library:  Requests
 Project:  NeighborhoodInfo DC
 Author:   S. Zhang
 Created:  10/15/14
 Version:  SAS 9.2
 Environment:  Local Windows session
 
 Description:  Prepare data for Commonweal data request . 
 (memo 10/27/14).
 
 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Census )
%DCData_lib( ACS )
%DCData_lib( Tanf )
%DCData_lib( Vital )
%DCData_lib( NLIHC )
%DCData_lib( HUD )
%DCData_lib( NCDB )
%DCData_lib( RealProp )
%DCData_lib( PresCat )
%DCData_lib ( Commweal );
%DCData_lib ( Police );
%DCData_lib ( Rod );
%DCData_lib ( Schools );


** Define Time **;
%let year = 2008_12;
%let year_lbl = 2008-12;
%let year_dollar = 2012;

** Select tracts **;
filename fimport "K:\Metro\PTatian\DCData\Libraries\Commweal\Data\selected_tracts.csv" lrecl=256;

data selected_tracts;
  infile fimport dsd stopover firstobs=2;
  input geo2010 : $11.;
  label geo2012= "Full census tract ID (2010): ssccctttttt";
  format geo2010 $geo10v.; 
run;

filename fimport clear;

proc sort data=selected_tracts;
  by geo2010;
run;

proc print;
run;

%Data_to_format(FmtLib=work, FmtName=$Trsel, Desc=, Data=selected_tracts, Value=Geo2010,
  Label=Geo2010, OtherLabel='', DefaultLen=., MaxLen=., MinLen=., Print=Y, Contents=N)

** Create ACS 2008-2012 summaries for ward and city level **;
%create_summary_from_tracts( geo=city,
lib=commweal, data_pre=acs_sf_2008_12_sum, count_vars= b0: b1: b2: c2: , tract_yr=2010, register=n);

%create_summary_from_tracts( geo=ward2012,
lib=commweal, data_pre=acs_sf_2008_12_sum, count_vars= b0: b1: b2: c2: , tract_yr=2010, register=n);


** Preservation Catalogue**;

** Subsidized housing/NLIHC catalog **;

proc format;
  value ProgCat (notsorted)
    1 = 'Public Housing only'
    2 = 'Section 8 only'
    9 = 'Section 8 and other subsidies'
    3 = 'LIHTC only'
    4 = 'HOME only'
    5 = 'CDBG only'
    6 = 'HPTF only'
    /*7 = 'Other single subsidy'*/

    8 = 'LIHTC and Tax Exempt Bond only'
    7, 10 = 'All other combinations';
run;


data NLIHC_cat_pr NLIHC_cat_pr_all;
	set PresCat.Project_assisted_units (where=(status= "A"));

  	if put( geo2010, $trsel. ) ~= '' then select = 1;
  	else select = 0;
  
  select ( ProgCat );
    when ( 1 ) asst_units_pub_hsng = mid_asst_units;
    when ( 2 ) asst_units_s8_only  = mid_asst_units;
    when ( 9 ) asst_units_s8_plus  = mid_asst_units;
    otherwise  asst_units_other = mid_asst_units;
  end;
  

  rename mid_asst_units=asst_units_total;
  
  format ProgCat ProgCat.; 
  
  if select then output NLIHC_cat_pr;
  
  output NLIHC_cat_pr_all;
  
run;

filename fexport "K:\Metro\PTatian\DCData\Libraries\Commweal\Maps\Commweal_all_projects.csv" lrecl=2000;

proc export data=NLIHC_cat_pr_all
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

filename fexport "K:\Metro\PTatian\DCData\Libraries\Commweal\Maps\Commweal_sel_projects.csv" lrecl=2000;

proc export data=NLIHC_cat_pr
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

proc print data=NLIHC_cat_pr n;
run;

proc summary data=NLIHC_cat_pr nway;
  class geo2010;
  var asst_units_: ;
  output out=NLIHC_cat_tr10 sum= ;
run;

proc summary data=NLIHC_cat_pr_all nway;
  class ward2012;
  var asst_units_: ;
  output out=NLIHC_cat_wd12 sum= ;
run;

proc summary data=NLIHC_cat_pr_all nway;
  class Proj_ST;
  var asst_units_: ;
  output out=NLIHC_cat_city sum= ;
run;

data NLIHC_cat_city; set NLIHC_cat_city (drop=proj_st); city="1"; run;

** Create Master Datasets**;
** tk **;
%macro create_vars(level, lvl);
 data vouchers_sum_&lvl.;
 	set HUD.vouchers_sum_&lvl.;
 	&level._new = STRIP(PUT(&level., 11.));
	drop &level.;
	rename &level._new=&level.;
run;

data ACS_&lvl.;

  merge
    Commweal.acs_sf_2008_12_sum_&lvl. 
      (keep=&level. b01001e: b01003e1 B11001e1 B11003e: B11013e: B17001e: B23001e: B03002: B05: B19: B17: B25: /*B15001: B13014:*/ )
    Acs.Acs_2008_12_sum_tr_&lvl. 
      (keep=&level. aggfamilyincome_2008_12 numfamilies_2008_12 Pop25andOverYears_2008_12 Pop25andOverWoutHS_2008_12 Pop25andOverWHS_2008_12 
		Pop25andOverWCollege_2008_12)
    Tanf.Tanf_sum_&lvl.
      (keep=&level. tanf_client_2014 tanf_unborn_2014 tanf_child_2014 tanf_adult_2014)
    Tanf.Fs_sum_&lvl.
      (keep=&level. fs_client_2014 fs_unborn_2014 fs_child_2014 fs_adult_2014)
    Vital.Births_sum_&lvl.
      (keep=&level. births_total_2011 births_teen_2011 births_single_2011 births_prenat_inad_2011)
    Vital.Deaths_sum_&lvl.
      (keep=&level. deaths_total_2007 deaths_violent_2007 deaths_heart_2007)
	  
    NLIHC_cat_&lvl.
      (keep=&level. asst_units_total asst_units_pub_hsng asst_units_s8_only asst_units_s8_plus asst_units_other)
    vouchers_sum_&lvl. 
      (keep=&level. total_units)
	  
    Ncdb.Ncdb_sum_&lvl. 
      (keep=&level. totpop_2000 /*PopUnder5years_2000*/ popunder18years_2000 /*avgfamilyincome_2000*/)
    Ncdb.Ncdb_sum_2010_&lvl. 
      (keep=&level. totpop_2010 popunder18years_2010)
	/*
    PopUnder5years_2010 
      (keep=geo2000 PopUnder5years_2010)
	  */
	Police.Crimes_sum_&lvl.
	  (keep=&level. crimes_pt1_property_2011 crimes_pt1_violent_2011 crime_rate_pop_2011)
	Rod.Foreclosures_sum_&lvl.
	  (keep=&level. forecl_ssl_sf_condo_2013 forecl_ssl_1kpcl_sf_condo_2013 trustee_ssl_sf_condo_2013 FORECL_SF_CONDO_2013  PARCEL_SF_CONDO_2013 )	

	Realprop.Sales_sum_&lvl.
	  (keep=&level. sales_tot_2013 r_mprice_tot_2013 )	
	
	Schools.msf_sum_&lvl.
	  (keep=&level. dcps_present_2013 charter_present_2013 )	
  ;

  
  by &level.;
  
  %if &level.=geo2010 %then %do;
  where put( &level., $trsel. ) ~= '';
  %end;
  %if &level.=ward2012 %then %do;
  where ward2012="7" or ward2012="8";
  %end;
  
  
  Pop18andOverYears_2000 = totpop_2000 - popunder18years_2000;
  Pop18andOverYears_2010 = totpop_2010 - popunder18years_2010;
  
  ** Change **;
  
  Chg_TotPop_2000_10 = TotPop_2010 - TotPop_2000;
  Chg_Pop18andOverYears_2000_10 = Pop18andOverYears_2010 - Pop18andOverYears_2000;
  /*Chg_PopUnder5years_2000_10 = PopUnder5years_2010 - PopUnder5years_2000;*/
  Chg_PopUnder18years_2000_10 = PopUnder18years_2010 - PopUnder18years_2000;


  ** Recode missings to 0 **;


array a{*} asst_units_: number_reported;
  
  do i = 1 to dim( a );
    if a{i} = . then a{i} = 0;
  end;
 
    ** Demographics **;
    
    TotPop_&year = B01003e1;
    
    NumHshlds_&year = B11001e1;

    NumFamilies_&year = B11003e1;

    PopUnder5Years_&year = sum( B01001e3, B01001e27 );
    
    PopUnder18Years_&year = 
      sum( B01001e3, B01001e4, B01001e5, B01001e6, 
           B01001e27, B01001e28, B01001e29, B01001e30 );
    
    Pop18andOverYears_&year = TotPop_&year - PopUnder18Years_&year;
    
    Pop65andOverYears_&year = 
      sum( B01001e20, B01001e21, B01001e22, B01001e23, B01001e24, B01001e25, 
           B01001e44, B01001e45, B01001e46, B01001e47, B01001e48, B01001e49 );

	HispanicOther_&year. = sum(B03002e5, B03002e7, B03002e8, B03002e9, B03002e10, B03002e11);

	Pop18to24ACS_&year. = sum(OF B01001e7-B01001e10 B01001e31-B01001e34);

    PopUnder5to9Years_&year = sum( B01001e4, B01001e28 );
	PopUnder10to14Years_&year = sum( B01001e5, B01001e29 );
	PopUnder15to17Years_&year = sum( B01001e6, B01001e30 );


	/*WorkingAge16to64_&year. = sum(of );*/

	 label 
  	  B03002e4="Black, Not-Hispanic"
	  B03002e3="White, Not-Hispanic"
	  B03002e6="Asian, Not-Hispanic"
	  HispanicOther_&year.="Other, Not-Hispanic"
	  B03002e12="Hispanic"
	  Pop18to24ACS_&year. = "Population 18 to 24"
;
  
    
    ** Household type **;

    NumFamiliesOwnChild_&year = 
      sum( B11003e3, B11003e10, B11003e16 ) + 
      sum( B11013e3, B11013e5, B11013e6 );
    
    NumFamiliesOwnChildFH_&year = B11003e16 + B11013e5;
	NumFamiliesOwnChildMH_&year = B11003e10 + B11013e6;
	NumFamiliesOwnChildMAR_&year = B11003e3 + B11013e3;

    label
      NumFamiliesOwnChild_&year = "Total families and subfamilies with own children, &year_lbl"
      NumFamiliesOwnChildFH_&year = "Female-headed families and subfamilies with own children, &year_lbl"
	  NumFamiliesOwnChildMH_&year = "Male-headed families and subfamilies with own children, &year_lbl"
	  NumFamiliesOwnChildMAR_&year = "Married-couple families and subfamilies with own children, &year_lbl"
    ;

	
    
    ** Family income **;
    
    if numfamilies_&year. > 0 then avgfamilyincome_&year.  = aggfamilyincome_&year. / numfamilies_&year.;


    
    %dollar_convert( avgfamilyincome_2000, avgfamilyincome_2000_d12, 1999, 2011 )
    
    chg_avgfamilyincome_2000_0812 = avgfamilyincome_&year. - avgfamilyincome_2000_d12;
    
    ** Poverty **;
    
    ChildrenPovertyDefined_&year = 
      sum( B17001e4, B17001e5, B17001e6, B17001e7, B17001e8, B17001e9, 
           B17001e18, B17001e19, B17001e20, B17001e21, B17001e22, B17001e23,
           B17001e33, B17001e34, B17001e35, B17001e36, B17001e37, B17001e38, 
           B17001e47, B17001e48, B17001e49, B17001e50, B17001e51, B17001e52
          );

    ElderlyPovertyDefined_&year = 
      sum( B17001e15, B17001e16, B17001e29, B17001e30,
           B17001e44, B17001e45, B17001e58, B17001e59
      );

    PersonsPovertyDefined_&year = B17001e1;
    
    PopPoorChildren_&year = 
      sum( B17001e4, B17001e5, B17001e6, B17001e7, B17001e8, B17001e9, 
           B17001e18, B17001e19, B17001e20, B17001e21, B17001e22, B17001e23 );

    PopPoorElderly_&year = 
      sum( B17001e15, B17001e16, B17001e29, B17001e30 );

    PopPoorPersons_&year = B17001e2;
    
    PopPoorAdults_&year = PopPoorPersons_&year - ( PopPoorChildren_&year + PopPoorElderly_&year );
	PopPoorAdultsDef_&year = PersonsPovertyDefined_&year - (ChildrenPovertyDefined_&year + ElderlyPovertyDefined_&year);

	PopPoorUnder5_&year. = sum(B17001e4,B17001e18);
	PopPoor5_&year. = sum(B17001e5,B17001e19);
	PopPoor6to11_&year. = sum(B17001e6,B17001e20);
	PopPoor12to14_&year. = sum(B17001e7,B17001e21);
	PopPoor15_&year. = sum(B17001e8,B17001e22);
	PopPoor16to17_&year. = sum(B17001e9,B17001e23);

	PopPoorDefUnder5_&year. = sum(PopPoorUnder5_&year., B17001e33,B17001e47);
	PopPoorDef5_&year. = sum(PopPoor5_&year., B17001e34,B17001e48);
	PopPoorDef6to11_&year. = sum(PopPoor6to11_&year. , B17001e35,B17001e49);
	PopPoorDef12to14_&year. = sum(PopPoor12to14_&year. , B17001e36,B17001e50);
	PopPoorDef15_&year. = sum(PopPoor15_&year., B17001e37,B17001e51);
	PopPoorDef16to17_&year. = sum(PopPoor16to17_&year., B17001e38,B17001e52);

	PovRateAll_&year. = PopPoorPersons_&year / PersonsPovertyDefined_&year ;
	PovRateAdult_&year. = PopPoorAdults_&year. / PopPoorAdultsDef_&year. ; 
	PovRateUnder5_&year. = PopPoorUnder5_&year. / PopPoorDefUnder5_&year. ;
	PovRate5_&year. = PopPoor5_&year. / PopPoorDef5_&year.;
	PovRate6to11_&year. = 	PopPoor6to11_&year. / PopPoorDef6to11_&year.;
	PovRate12to14_&year. = PopPoor12to14_&year. / PopPoorDef12to14_&year. ;
	PovRate15_&year. = PopPoor15_&year. / PopPoorDef15_&year.;
	PovRate16to17_&year. = PopPoor16to17_&year. / PopPoorDef16to17_&year.;

    label
      PopPoorPersons_&year = "Persons below the poverty level last year, &year_lbl"
      PersonsPovertyDefined_&year = "Persons with poverty status determined, &year_lbl"
      PopPoorChildren_&year = "Children under 18 years old below the poverty level last year, &year_lbl"
      ChildrenPovertyDefined_&year = "Children under 18 years old with poverty status determined, &year_lbl"
      PopPoorElderly_&year = "Persons 65 years old and over below the poverty level last year, &year_lbl"
      ElderlyPovertyDefined_&year = "Persons 65 years old and over with poverty status determined, &year_lbl"
    ;
    
    ** Employment **;
    
    PopCivilianEmployed_&year = 
      sum( B23001e7, B23001e14, B23001e21, B23001e28, B23001e35, B23001e42, B23001e49, 
           B23001e56, B23001e63, B23001e70, B23001e75, B23001e80, B23001e85,
           B23001e93, B23001e100, B23001e107, B23001e114, B23001e121, B23001e128, 
           B23001e135, B23001e142, B23001e149, B23001e156, B23001e161, B23001e166, B23001e171 );

    PopUnemployed_&year = 
      sum( B23001e8, B23001e15, B23001e22, B23001e29, B23001e36, B23001e43, B23001e50, 
           B23001e57, B23001e64, B23001e71, B23001e76, B23001e81, B23001e86, 
           B23001e94, B23001e101, B23001e108, B23001e115, B23001e122, B23001e129, 
           B23001e136, B23001e143, B23001e150, B23001e157, B23001e162, B23001e167, B23001e172 );
    
    PopInCivLaborForce_&year = sum( PopCivilianEmployed_&year, PopUnemployed_&year );
    
    Pop16andOverEmployed_&year = PopCivilianEmployed_&year +
      sum( B23001e5, B23001e12, B23001e19, B23001e26, B23001e33, B23001e40, 
           B23001e47, B23001e54, B23001e61, B23001e68,
           B23001e91, B23001e98, B23001e105, B23001e112, B23001e119, B23001e126, 
           B23001e133, B23001e140, B23001e147, B23001e154 );

	UnemploymentRate_&year = PopUnemployed_&year/PopInCivLaborForce_&year;
	EmplyomentRateCiv_&year = PopCivilianEmployed_&year/PopInCivLaborForce_&year;

    Pop16andOverYears_&year = B23001e1;
    
    label
      PopCivilianEmployed_&year = "Persons 16+ years old in the civilian labor force and employed, &year_lbl"
      PopUnemployed_&year = "Persons 16+ years old in the civilian labor force and unemployed, &year_lbl"
      PopInCivLaborForce_&year = "Persons 16+ years old in the civilian labor force, &year_lbl"
      Pop16andOverEmployed_&year = "Persons 16+ years old who are employed (includes armed forces), &year_lbl"
      Pop16andOverYears_&year = "Persons 16+ years old, &year_lbl"
    ;
	/* CRIME */
	PropCrimesPer1000 = 1000*crimes_pt1_property_2011 / crime_rate_pop_2011;
	ViolCrimesPer1000 = 1000* crimes_pt1_violent_2011/crime_rate_pop_2011;
    
    rename total_units=asst_units_vouchers;

	/* HOUSING */
	NumOccupiedHsgUnits_&year = B25003e1;
    NumOwnerOccupiedHsgUnits_&year = B25003e2;
    NumRenterOccupiedHsgUnit_&year = B25003e3;

	MedGrossRent_&year = B25064e1;

	RentLessThan15Pct_&year =	B25070e2 + B25070e3;
	Rent15to20Pct_&year = 		B25070e4;
	Rent20to25Pct_&year = 		B25070e5;
	Rent25to30Pct_&year = 		B25070e6;
	Rent30to35Pct_&year =		B25070e7;
	Rent35PctPlusPct_&year = 		B25070e8 + B25070e9 + B25070e10;
	RentNotComputed_&year = 	B25070e11;

	NumVacantHsgUnitsForRent_&year = B25004e2;
    NumVacantHsgUnitsForSale_&year = B25004e4;
	NumOwnerOccupiedHsgUnits_&year = B25003e2;
    NumRenterOccupiedHsgUnit_&year = B25003e3;

	NumRenterHsgUnits_&year = NumRenterOccupiedHsgUnit_&year + NumVacantHsgUnitsForRent_&year;
	NumOwnerHsgUnits_&year = NumOwnerOccupiedHsgUnit_&year + NumVacantHsgUnitsForSale_&year;

	RenterHsgUnitsVacancy_&year =  NumVacantHsgUnitsForRent_&year/NumRenterHsgUnits_&year;
	OwnerHsgUnitsVacancy_&year = NumVacantHsgUnitsForSale_&year / NumOwnerHsgUnits_&year ;
      
run;
%mend create_vars;

%create_vars(geo2010, tr10);
%create_vars(city, city);
%create_vars(ward2012, wd12);

** CREATE TABLES **;
** tk2 **;

%macro run_table(level, lvl);
ODS html FILE="K:\Metro\PTatian\DCData\Libraries\Commweal\Data\pit_output_&level..XLS";
proc tabulate data=ACS_&lvl. noseps missing;
  class &level.;
  var B01001e1 B01001e2 B01001e26 B03002e4 B03002e3 B03002e6 HispanicOther_&year. B03002e12 B05002e13 Pop18andOverYears_&year. Pop18to24ACS_&year. 
			Pop65andOverYears_&year. PopUnder18Years_&year PopUnder5Years_&year PopUnder5to9Years_&year PopUnder10to14Years_&year PopUnder15to17Years_&year
NumFamiliesOwnChild_&year NumFamiliesOwnChildFH_&year  NumFamiliesOwnChildMH_&year NumFamiliesOwnChildMAR_&year B19013m1 
Pop25andOverYears_2008_12 Pop25andOverWoutHS_2008_12 Pop25andOverWHS_2008_12 Pop25andOverWCollege_2008_12

avgfamilyincome_&year.
births_total_2011 births_teen_2011 births_single_2011 births_prenat_inad_2011
UnemploymentRate_&year EmplyomentRateCiv_&year
UnemploymentRate_&year EmplyomentRateCiv_&year
PovRateAll_&year PovRateAdult_&year PovRateUnder5_&year PovRate5_&year. PovRate6to11_&year. PovRate12to14_&year. PovRate15_&year. PovRate16to17_&year. 

PropCrimesPer1000 ViolCrimesPer1000

forecl_ssl_sf_condo_2013 forecl_ssl_1kpcl_sf_condo_2013 trustee_ssl_sf_condo_2013

NumOccupiedHsgUnits_&year NumOwnerOccupiedHsgUnits_&year NumRenterOccupiedHsgUnit_&year MedGrossRent_&year 
RentLessThan15Pct_&year Rent15to20Pct_&year Rent20to25Pct_&year Rent25to30Pct_&year  Rent30to35Pct_&year Rent35PctPlusPct_&year  RentNotComputed_&year

RenterHsgUnitsVacancy_&year OwnerHsgUnitsVacancy_&year 

sales_tot_2013 r_mprice_tot_2013

dcps_present_2013 charter_present_2013 
;
table B01001e1 B01001e2 B01001e26 B03002e4 B03002e3 B03002e6 HispanicOther_&year.  B03002e12 B05002e13 Pop18andOverYears_&year. 
		Pop18to24ACS_&year. Pop65andOverYears_&year.      PopUnder18Years_&year PopUnder5Years_&year PopUnder5to9Years_&year PopUnder10to14Years_&year 
		PopUnder15to17Years_&year 
NumFamiliesOwnChild_&year NumFamiliesOwnChildFH_&year  NumFamiliesOwnChildMH_&year NumFamiliesOwnChildMAR_&year B19013m1 avgfamilyincome_&year.
births_total_2011 births_teen_2011 births_single_2011 births_prenat_inad_2011
UnemploymentRate_&year EmplyomentRateCiv_&year
PovRateAll_&year PovRateAdult_&year PovRateUnder5_&year PovRate5_&year. PovRate6to11_&year. PovRate12to14_&year. PovRate15_&year. PovRate16to17_&year. 
Pop25andOverYears_2008_12 Pop25andOverWoutHS_2008_12 Pop25andOverWHS_2008_12 Pop25andOverWCollege_2008_12, &level

;

table PropCrimesPer1000 ViolCrimesPer1000, &level;
table  forecl_ssl_sf_condo_2013 forecl_ssl_1kpcl_sf_condo_2013 trustee_ssl_sf_condo_2013, &level;
table NumOccupiedHsgUnits_&year NumOwnerOccupiedHsgUnits_&year NumRenterOccupiedHsgUnit_&year MedGrossRent_&year 
RentLessThan15Pct_&year Rent15to20Pct_&year Rent20to25Pct_&year Rent25to30Pct_&year  Rent30to35Pct_&year Rent35PctPlusPct_&year  RentNotComputed_&year
RenterHsgUnitsVacancy_&year OwnerHsgUnitsVacancy_&year 
sales_tot_2013 r_mprice_tot_2013, &level ;
table dcps_present_2013 charter_present_2013, &level;
run;
ODS HTML CLOSE; 
/*additional output for counts*/
ODS html FILE="K:\Metro\PTatian\DCData\Libraries\Commweal\Data\pit_add_output_&level..XLS";
proc tabulate data=ACS_&lvl. noseps missing;
  class &level.;
  var    

births_teen_2011 
births_single_2011 
births_prenat_inad_2011
births_total_2011 

PopUnemployed_&year
PopInCivLaborForce_&year

PopPoorPersons_&year 
PersonsPovertyDefined_&year

PopPoorChildren_&year 
ChildrenPovertyDefined_&year 

PopPoorAdults_&year
PopPoorAdultsDef_&year

PopPoorUnder5_&year. PopPoorDefUnder5_&year.
PopPoor5_&year. PopPoorDef5_&year.
PopPoor6to11_&year.  	PopPoorDef6to11_&year. 
PopPoor12to14_&year.  	PopPoorDef12to14_&year. 
PopPoor15_&year.  PopPoorDef15_&year. 
PopPoor16to17_&year.  PopPoorDef16to17_&year.

Crimes_pt1_property_2011
Crimes_pt1_violent_2011
Crime_rate_pop_2011

forecl_sf_condo_2013
parcel_sf_condo_2013

NumVacantHsgUnitsForRent_&year
NumRenterHsgUnits_&year
;

table 
births_teen_2011 
births_single_2011 
births_prenat_inad_2011
births_total_2011 
PopUnemployed_&year
PopInCivLaborForce_&year
PopPoorPersons_&year 
PersonsPovertyDefined_&year
PopPoorChildren_&year 
ChildrenPovertyDefined_&year 
PopPoorAdults_&year
PopPoorAdultsDef_&year
PopPoorUnder5_&year. PopPoorDefUnder5_&year.
PopPoor5_&year. PopPoorDef5_&year.
PopPoor6to11_&year.  	PopPoorDef6to11_&year. 
PopPoor12to14_&year.  	PopPoorDef12to14_&year. 
PopPoor15_&year.  PopPoorDef15_&year. 
PopPoor16to17_&year.  PopPoorDef16to17_&year.
Crimes_pt1_property_2011
Crimes_pt1_violent_2011
Crime_rate_pop_2011
forecl_sf_condo_2013
parcel_sf_condo_2013
NumVacantHsgUnitsForRent_&year
NumRenterHsgUnits_&year, &level
;
run;
ODS HTML CLOSE; 
%mend run_table;

%run_table(geo2010, tr10)
%run_table(city, city)
%run_table(ward2012, wd12)
