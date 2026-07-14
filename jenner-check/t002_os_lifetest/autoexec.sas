options obs=100;  /* cap input rows for the captured run */

/* --------------------------------------------------------------------------
   Stand-in for code.os (normally read from an external libname on the
   author's SAS Viya home). Populated with the columns OS_Summary.sas reads:
   cohort (Aspirin / Warfarin / NOAC), AVAL (survival time in months),
   and CNSR (0 = event/death, 1 = censored). A spread of times and both
   censoring states per cohort so PROC LIFETEST produces the Quartiles table
   the report's block2 consumes.
   -------------------------------------------------------------------------- */
data code_os;
    length cohort $10;
    input cohort $ AVAL CNSR;
    datalines;
NOAC 34.2 1
NOAC 12.5 0
NOAC 28.9 1
NOAC 41.0 1
NOAC 9.3 0
NOAC 30.1 1
NOAC 22.7 0
NOAC 38.4 1
Warfarin 18.6 0
Warfarin 26.3 1
Warfarin 8.1 0
Warfarin 31.7 1
Warfarin 14.9 0
Warfarin 29.0 1
Warfarin 20.4 0
Aspirin 24.8 1
Aspirin 6.2 0
Aspirin 33.5 1
Aspirin 11.0 0
Aspirin 27.6 1
Aspirin 16.3 0
Aspirin 35.9 1
;
run;
