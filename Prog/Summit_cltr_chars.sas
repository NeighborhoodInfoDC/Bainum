/**************************************************************************
 Program:  Summit_cltr_chars.sas
 Library:  Requests
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  03/18/15
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Compile cluster characteristics for Summit Fund
presentation.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Requests )
%DCData_lib( TANF, local=n )
%DCData_lib( ACS, local=n )
%DCData_lib( Police, local=n )

data Summit_cltr_chars;

  merge
    Tanf.Fs_sum_cltr00 (keep=cluster_tr2000 fs_client_2014)
    Tanf.Tanf_sum_cltr00 (keep=cluster_tr2000 tanf_client_2014)
    ACS.Acs_2008_12_sum_tr_cltr00 
      (keep=cluster_tr2000 PopPoorPersons: PopUnemployed: NumFamiliesOwnChildrenFH:
            PopPoorChildren: Pop25andOver: )
    Police.Crimes_sum_cltr00
      (keep=cluster_tr2000 crimes_pt1_violent_2011 crimes_pt1_property_2011)
  ;
  by cluster_tr2000;
  
  if cluster_tr2000 ~= '99';

run;

%File_info( data=Summit_cltr_chars, printobs=0 )

** Summary tables **;

ods listing close;

ods tagsets.excelxp file="L:\Libraries\Requests\Prog\2015\Summit_cltr_chars.xls" style=Printer options(sheet_interval='Proc' );

proc print data=Summit_cltr_chars label;
  id cluster_tr2000;
  var 
    fs_client_2014
    tanf_client_2014
    PopPoorPersons_2008_12
    PopUnemployed_2008_12
    NumFamiliesOwnChildrenFH_2008_12
    Pop25andOverwouths_2008_12
    pop25andoverwhs_2008_12
    crimes_pt1_violent_2011;
  format cluster_tr2000 $clus00f. _numeric_ comma10.0;
run;

ods tagsets.excelxp close;

ods listing;

filename fexport "&_dcdata_r_path\Requests\Raw\2015\Summit_cltr_chars.csv" lrecl=2000;

proc export data=Summit_cltr_chars
    outfile=fexport
    dbms=csv replace;

run;

filename fexport clear;

