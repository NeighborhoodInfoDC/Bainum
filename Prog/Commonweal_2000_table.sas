/**************************************************************************
 Program:  Commonweal_PIT_table.sas
 Library:  Requests
 Project:  NeighborhoodInfo DC
 Author:   S. Zhang
 Created:  11/3/14
 Version:  SAS 9.2
 Environment:  Local Windows session
 
 Description:  Prepare data for Commonweal data request, pulling NCDB data. 
 
 Modifications:

**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Census )
%DCData_lib( NCDB )
%DCData_lib ( Bainum );
%DCData_lib ( RealProp );



** Define Time **;
%let year = 2000;
%let year_lbl = 2008-12;
%let year_dollar = 2012;

** Select tracts **;
filename fimport "K:\Metro\PTatian\DCData\Libraries\Bainum\Data\selected_tracts.csv" lrecl=256;

data selected_tracts;
  infile fimport dsd stopover firstobs=2;
  input geo2000 : $11.;
  label geo2000= "Full census tract ID (2000): ssccctttttt";
  format geo2000 $geo00v.; 
run;

filename fimport clear;

proc sort data=selected_tracts;
  by geo2000;
run;

%Data_to_format(FmtLib=work, FmtName=$Trsel, Desc=, Data=selected_tracts, Value=Geo2000,
  Label=Geo2000, OtherLabel='', DefaultLen=., MaxLen=., MinLen=., Print=Y, Contents=N)

proc print;
run;

** Create Master Datasets**;
** tk **;
%macro create_vars(level, lvl);
data NCDB_&lvl.;

  merge
    Ncdb.Ncdb_sum_&lvl. 
    /*Ncdb.Ncdb_sum_2010_&lvl. 
      (keep=&level. totpop_2010 popunder18years_2010)*/
		Realprop.Sales_sum_&lvl.
	  (keep=&level. sales_tot_2000 sales_tot_2013 r_mprice_tot_2000 r_mprice_tot_2013 )	
  ;

  
  by &level.;
  
  %if &level.=geo2000 %then %do;
  where put( &level., $trsel. ) ~= '';
  %end;
  %if &level.=ward2012 %then %do;
  where ward2012="7" or ward2012="8";
  %end;
  
 
    ** Demographics **;
    

    
    ** Family income **;
    
    if numfamilies_&year. > 0 then avgfamilyincome_&year.  = aggfamilyincome_&year. / numfamilies_&year.;    
    %dollar_convert( avgfamilyincome_2000, avgfamilyincome_2000_d12, 1999, 2012 )
	%dollar_convert( medianfamilyincome_2000, medianfamilyincome_2000_d12, 1999, 2012 )
        
    ** Poverty **;

    ** Employment **;
    
    PopInCivLaborForce_&year = sum( PopCivilianEmployed_&year, PopUnemployed_&year );
    
	UnemploymentRate_&year = PopUnemployed_&year/PopInCivLaborForce_&year;
	EmploymentRateCiv_&year = PopCivilianEmployed_&year/PopInCivLaborForce_&year;
run;
%mend create_vars;

%create_vars(geo2000, tr00);
%create_vars(city, city);
%create_vars(ward2012, wd12);

** CREATE TABLES **;
** tk2 **;

%macro run_table(level, lvl);
ODS html FILE="K:\Metro\PTatian\DCData\Libraries\Bainum\Data\pit_output_2000_&level..XLS";
proc tabulate data=NCDB_&lvl. noseps missing;
  class &level.;
  var popwithrace_2000 popblacknonhispalone_2000 popwhitenonhispalone_2000 pophisp_2000
totpop_2000 pop65andoveryears_2000 popunder5years_2000 popunder18years_2000
avgfamilyincome_2000_d12 medianfamilyincome_2000_d12
PopUnemployed_&year PopInCivLaborForce_&year
poppoorpersons_2000 personspovertydefined_2000
poppoorchildren_2000 childrenpovertydefined_2000
numoccupiedhsgunits_2000 numowneroccupiedhsgunits_2000 numrenteroccupiedhsgunits_2000
r_mprice_tot_2000

numfamilies_2000  avgfamilyincome_2000_d12 medianfamilyincome_2000_d12
;
table popwithrace_2000 popblacknonhispalone_2000 popwhitenonhispalone_2000 pophisp_2000
totpop_2000 pop65andoveryears_2000 popunder5years_2000 popunder18years_2000
avgfamilyincome_2000_d12 medianfamilyincome_2000_d12
PopUnemployed_&year PopInCivLaborForce_&year
poppoorpersons_2000 personspovertydefined_2000
poppoorchildren_2000 childrenpovertydefined_2000
numoccupiedhsgunits_2000 numowneroccupiedhsgunits_2000 numrenteroccupiedhsgunits_2000
r_mprice_tot_2000
, &level
;

table numfamilies_2000  avgfamilyincome_2000_d12 medianfamilyincome_2000_d12, &level;

run;
ODS HTML CLOSE; 


%mend run_table;

%run_table(geo2000, tr00)
%run_table(city, city)
%run_table(ward2012, wd12)
