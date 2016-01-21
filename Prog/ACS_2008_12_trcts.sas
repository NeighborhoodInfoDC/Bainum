/**************************************************************************
 Program:  ACS_2008_12_trcts.sas
 Library:  Commweal
 Project:  NeighborhoodInfo DC
 Author:   S.Zhang
 Created:  10/16/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Extract block data from ACS 2008-12 data for mapping. 

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Commweal)
%DCData_lib( ACS, local=n )

data ACS_extract;

  set Commweal.acs_sf_2008_12_sum_tr10  (keep=geo2010 B17001:);
  
  kids5pov = sum( B17001e4, B17001e18 );
  kids18pov = sum(OF B17001e4-B17001e9  B17001e18-B17001e23);
  
  format geo2010 ;
  
  drop b17001:;

run;

filename fexport "&_dcdata_r_path\Commweal\Raw\ACS_2008_12_mapping.csv" lrecl=256;

proc export data=ACS_extract
    outfile=fexport
    dbms=csv replace;
run;

filename fexport clear;

