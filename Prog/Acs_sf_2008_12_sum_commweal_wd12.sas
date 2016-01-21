/**************************************************************************
 Program:  ACS_2008_12_sum_dmped_wd12.sas
 Library:  ACS
 Project:  NeighborhoodInfo DC
 Author:   M. Woluchem/S. Zhang
 Created:  10/17/14
 Version:  SAS 9.2
 Environment:  Local Windows session (desktop)
 
 Description:  Create summary file from ACS 5-year data: 2008-12 solely for Ward 2012 for Commonweal analysis
 
 Modifications:
  01/21/14 PAT  Updated for new SAS1 server (not tested).
  01/31/14 MSW	Adapted from ACS_2007_11_sum_all.sas
  02/02/14 MSW	Adapted to add additional summary variables for DMPED analysis. 
**************************************************************************/

%include "L:\SAS\Inc\StdLocal.sas";

** Define libraries **;
%DCData_lib( ACS )
%DCData_lib( Bainum )

%global year year_lbl year_dollar;

%** Program parameters **;

%let year = 2008_12;
%let year_lbl = 2008-12;
%let year_dollar = 2012;

/** Macro Summary_geo - Start Definition **/

%macro Summary_geo( geo, source_geo );

  %local geo_name geo_wt_file geo_var geo_suffix geo_label count_vars moe_vars;

  %let geo_name = %upcase( &geo );
  %let geo_wt_file = %sysfunc( putc( &geo_name, &source_geo_wt_file_fmt ) );;
  %let geo_var = %sysfunc( putc( &geo_name, $geoval. ) );
  %let geo_suffix = %sysfunc( putc( &geo_name, $geosuf. ) );
  %let geo_label = %sysfunc( putc( &geo_name, $geodlbl. ) );

  %if %upcase( &source_geo ) = BG00 or %upcase( &source_geo ) = BG10 %then %do;
  
    %** Count and MOE variables for block group data **;

    %let count_vars = NUM:;
           
    %let moe_vars =       
           ;
              
	%let prop_vars = Med:;
  %end;
  %else %do;
  
    %** Count and MOE variables for tract data **;
  
    %let count_vars = NUM:;
           
    %let moe_vars =
           ;
               
	%let prop_vars = Med:
		;

  %end;
  
  %put _local_;
  
  %if ( &geo_name = GEO2000 and %upcase( &source_geo_var ) = GEO2000 ) or 
      ( &geo_name = GEO2010 and %upcase( &source_geo_var ) = GEO2010 ) %then %do;

    ** Census tracts from census tract source: just recopy selected vars **;
    
    data Bainum.&source_ds_work._COMM&geo_suffix (label="ACS summary, &year_lbl, &source_geo_label source, DC, &geo_label");
    
      set &source_ds_work (keep=&geo_var &count_vars &moe_vars);

    run;

  %end;
  %else %do;
  
    ** Transform data from source geography (&source_geo_var) to target geography (&geo_var) **;
    
    *OPTIONS MPRINT SYMBOLGEN MLOGIC;


    %Transform_geo_data(
      dat_ds_name=&source_ds_work,
      dat_org_geo=&source_geo_var,
      dat_count_vars=&count_vars,
      dat_count_moe_vars=&moe_vars,
      dat_prop_vars=&prop_vars,
      wgt_ds_name=General.&geo_wt_file,
      wgt_org_geo=&source_geo_var,
      wgt_new_geo=&geo_var,
      wgt_id_vars=,
      wgt_wgt_var=popwt,
	  wgt_prop_var=popwt_prop,
      out_ds_name=Bainum.&source_ds_work._COMM&geo_suffix,
      out_ds_label=%str(ACS summary, &year_lbl, &source_geo_label source, DC, &geo_label),
      calc_vars=,
      calc_vars_labels=,
      keep_nonmatch=N,
      show_warnings=10,
      print_diag=Y,
      full_diag=N
    )
    
  %end;  

  proc datasets library=Bainum memtype=(data) nolist;
    modify &source_ds_work._COMM&geo_suffix (sortedby=&geo_var);
  quit;

  %File_info( data=Bainum.&source_ds_work._COMM&geo_suffix, printobs=0 )

%mend Summary_geo;

/** End Macro Definition **/


/** Macro Summary_geo_source - Start Definition **/

%macro Summary_geo_source( source_geo );

  %global source_geo_var source_geo_suffix source_geo_wt_file_fmt source_ds source_ds_work source_geo_label;

  %if %upcase( &source_geo ) = BG00 %then %do;
     %let source_geo_var = GeoBg2000;
     %let source_geo_suffix = _bg;
     %let source_geo_wt_file_fmt = $geobw0f.;
     %let source_ds = Acs_sf_&year._bg00;
     %let source_geo_label = Block group;
  %end;
  %else %if %upcase( &source_geo ) = TR00 %then %do;
     %let source_geo_var = Geo2000;
     %let source_geo_suffix = _tr;
     %let source_geo_wt_file_fmt = $geotw0f.;
     %let source_ds = Acs_sf_&year._tr00;
     %let source_geo_label = Census tract;
  %end;
  %else %if %upcase( &source_geo ) = BG10 %then %do;
     %let source_geo_var = GeoBg2010;
     %let source_geo_suffix = _bg;
     %let source_geo_wt_file_fmt = $geobw1f.;
     %let source_ds = Acs_sf_&year._bg10;
     %let source_geo_label = Block group;
  %end;
  %else %if %upcase( &source_geo ) = TR10 %then %do;
     %let source_geo_var = Geo2010;
     %let source_geo_suffix = _tr;
     %let source_geo_wt_file_fmt = $geotw1f.;
     %let source_ds = Acs_sf_&year._tr10;
     %let source_geo_label = Census tract;
  %end;
  %else %do;
    %err_mput( macro=Summary_geo_source, msg=Geograpy &source_geo is not supported. )
    %goto macro_exit;
  %end;
     
  %let source_ds_work = ACS_&year._sum&source_geo_suffix;

  %put _global_;

  ** Create new variables for summarizing **;

  data &source_ds_work;

    set ACS_r.&source_ds;
    
    ** Unweighted sample counts **;

    NumFamilies_&year = B11003e1;
	MedFamIncome_&year = B19113e1;
  run;

  %Summary_geo( geo2010, &source_geo )
  %Summary_geo( city, &source_geo )
  %Summary_geo( ward2012, &source_geo )
  
  proc datasets library=work nolist;
    delete &source_ds_work /memtype=data;
  quit;
  
  %macro_exit:

%mend Summary_geo_source;

/** End Macro Definition **/


**** Create summary files from block group source ****;

%Summary_geo_source( bg10 )


**** Create summary files from census tract source ****;

%Summary_geo_source( tr10 )


