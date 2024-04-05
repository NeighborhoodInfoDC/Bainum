/**************************************************************************
 Program:  Commonweal_2016_Index.sas
 Library:  Bainum
 Project:  NeighborhoodInfo DC
 Author:   K.Abazajian
 Created:  10/13/14
 Version:  SAS 9.2
 Environment:  Local Windows session
 
 Description:  Prepare data for Bainum data request, formerly Commonweal
			   Report (2/2016)

 TRACT LEVEL DATA.
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Requests )
%DCData_lib( Census )
%DCData_lib( ACS )
%DCData_lib( Tanf )
%DCData_lib( Vital )
%DCData_lib( Police )


libname Bainum "L:\Libraries\Bainum\Data\";



** Define time periods  **;
%let year = 2009_13;
%let year_lbl = 2009-13;


** Combine all data **;

data ACS_tr;
/*Carl - review merge statement to ensure all index components are included in keep= statements*/
  merge
    ACS.acs_sf_2009_13_dc_tr10 
      (keep=geo2010 b01001e: b01003e1 B11001e1 B11003e: B11013e: B17001e: ) /*Katya reviewed*/
    Acs.Acs_2009_13_dc_sum_tr_tr10 
      (keep=geo2010 numfamilies_2009_13)
    Tanf.Tanf_sum_tr10
      (keep=geo2010 tanf_unborn_2014 tanf_child_2014)
    Tanf.Fs_sum_tr10
      (keep=geo2010 fs_unborn_2014 fs_child_2014)
    Vital.Births_sum_tr10
      (keep=geo2010 births_total_2011 births_teen_2011 births_single_2011 births_low_wt_2011)
	Vital.Deaths_sum_tr10
      (keep=geo2010 deaths_infant_3yr_2007)
	Police.Crimes_sum_tr10
      (keep=geo2010 Crimes_pt1_2011 Crimes_pt1_violent_2011)
  ;
  by geo2010;
  
  *where put( geo2010, $trsel. ) ~= '';
 
/*Carl - comment out demographic calculations we won't use, insert notes for calculations we still need*/

 ** Demographics **;
   
    TotPop_&year = B01003e1;
    
   /* NumHshlds_&year = B11001e1;*/

    NumFamilies_&year = B11003e1;

  /*  PopUnder5Years_&year = sum( B01001e3, B01001e27 );*/
    
    PopUnder18Years_&year = 
      sum( B01001e3, B01001e4, B01001e5, B01001e6, 
           B01001e27, B01001e28, B01001e29, B01001e30 ); 
    
 /* Pop18andOverYears_&year = TotPop_&year - PopUnder18Years_&year; */
    
  /*Pop65andOverYears_&year = 
      sum( B01001e20, B01001e21, B01001e22, B01001e23, B01001e24, B01001e25, 
           B01001e44, B01001e45, B01001e46, B01001e47, B01001e48, B01001e49 ); */
    
    ** Household type **;

    NumFamiliesOwnChildren_&year = 
      sum( B11003e3, B11003e10, B11003e16 ) + 
      sum( B11013e3, B11013e5, B11013e6 );
    
    NumFamiliesOwnChildrenS_&year = sum(B11003e16, B11013e5, B11003e10, B11013e6);

    label
      NumFamiliesOwnChildren_&year = "Total families and subfamilies with own children, &year_lbl"
      NumFamiliesOwnChildrenS_&year = "Single-parent families and subfamilies with own children, &year_lbl"
	  TotPop_&year = "Total population, &year_lbl" 
	  PopUnder18Years_&year = "Total population under 18, &year_lbl" 
    ;
    
 
    ** Poverty **;
    
    Under5PovertyDefined_&year = 
      sum( B17001e4, B17001e18, B17001e33, B17001e47 );

 	PopPoorUnder5_&year = 
      sum( B17001e4, B17001e18 );

  /*  ElderlyPovertyDefined_&year = 
      sum( B17001e15, B17001e16, B17001e29, B17001e30,
           B17001e44, B17001e45, B17001e58, B17001e59
      ); 

    PersonsPovertyDefined_&year = B17001e1;*/
    
   

 /*     PopPoorElderly_&year = 
      sum( B17001e15, B17001e16, B17001e29, B17001e30 );

    PopPoorPersons_&year = B17001e2;
    
    PopPoorAdults_&year = PopPoorPersons_&year - ( PopPoorChildren_&year + PopPoorElderly_&year );
*/
    label
      PopPoorUnder5_&year = "Children under 5 years old below the poverty level last year, &year_lbl"
      Under5PovertyDefined_&year = "Children under 5 years old with poverty status determined, &year_lbl"
 /*   PopPoorElderly_&year = "Persons 65 years old and over below the poverty level last year, &year_lbl" 
      ElderlyPovertyDefined_&year = "Persons 65 years old and over with poverty status determined, &year_lbl" */
    ;
    

run;

data Bainum.Input_Bainum_Index (drop = NumFamiliesOwnChildrenS_&year NumFamiliesOwnChildren_&year PopPoorUnder5_&year Under5PovertyDefined_&year );
set ACS_tr (keep = Births_low_wt_2011 
Births_single_2011 
Births_teen_2011 
Births_total_2011 
Crimes_pt1_2011 
Crimes_pt1_violent_2011
Deaths_infant_3yr_2007 
Fs_child_2014 
Fs_unborn_2014 
Geo2010 
NumFamiliesOwnChildrenS_2009_13 
NumFamiliesOwnChildren_2009_13 
NumFamilies_2009_13 
PopPoorUnder5_2009_13  
Tanf_child_2014 
Tanf_unborn_2014 
Under5PovertyDefined_2009_13 
TotPop_2009_13
PopUnder18Years_2009_13)
;
PercentSingleFamOwnChild_&year = NumFamiliesOwnChildrenS_&year / NumFamiliesOwnChildren_&year;
PercentPoorUnder5_&year = PopPoorUnder5_&year / Under5PovertyDefined_&year;
format geo2010 12.; 
format Tanf_child_2014 4.; 
format Fs_child_2014 4.;
run;

proc export data = Bainum.Input_Bainum_Index outfile = "L:\Libraries\Bainum\Data\Input_Bainum_Index.csv" dbms = csv replace;
run;
