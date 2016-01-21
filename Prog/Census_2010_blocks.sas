/**************************************************************************
 Program:  Census_2010_blocks.sas
 Library:  Bainum
 Project:  NeighborhoodInfo DC
 Author:   P. Tatian
 Created:  10/16/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Extract block data from Census 2010 SF1 tabulations.

 Modifications:
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( Bainum, local=n )
%DCData_lib( Census, local=n )

data Census_2010_blocks;

  set Census.Census_sf1_2010_dc_blks (keep=geoblk2010 p12i3 p12i27 P31i1);
  
  kids1n = sum( p12i3, p12i27 );
  kids18 = p31i1;
  
  format geoblk2010 ;
  
  drop p12i: p31i1;

run;

filename fexport "&_dcdata_r_path\Bainum\Raw\Census_2010_blocks.csv" lrecl=256;

proc export data=Census_2010_blocks
    outfile=fexport
    dbms=csv replace;
run;

filename fexport clear;

