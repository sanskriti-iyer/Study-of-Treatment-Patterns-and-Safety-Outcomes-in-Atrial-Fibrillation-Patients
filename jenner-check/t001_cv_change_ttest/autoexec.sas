options obs=100;  /* cap input rows for the captured run */

/* --------------------------------------------------------------------------
   Stand-in for code.vital_sign_analysis (normally read from an external
   libname on the author's SAS Viya home). Small synthetic sample with the
   same columns %stat_calculate reads: loinc, cohort1n, chg. Three LOINC
   codes (HR 8867-4, SBP 8480-6, DBP 8462-4) x two cohorts so the macro's
   PROC TTEST class comparison and "if class in (1,2)" filter both fire.
   -------------------------------------------------------------------------- */
data code_vital_sign_analysis;
    length loinc $8;
    input loinc $ cohort1n chg;
    datalines;
8867-4 1 -3.2
8867-4 1 -1.0
8867-4 1  0.5
8867-4 1 -2.4
8867-4 2 -0.8
8867-4 2  1.2
8867-4 2 -1.5
8867-4 2  0.3
8480-6 1 -6.1
8480-6 1 -4.8
8480-6 1 -2.0
8480-6 1 -5.5
8480-6 2 -1.2
8480-6 2  0.9
8480-6 2 -2.7
8480-6 2  1.4
8462-4 1 -2.9
8462-4 1 -1.7
8462-4 1 -3.3
8462-4 1 -0.6
8462-4 2  0.4
8462-4 2 -1.1
8462-4 2  0.8
8462-4 2 -0.5
;
run;
