options obs=100;  /* cap input rows for the captured run */

/* --------------------------------------------------------------------------
   Stand-in for code.hru (normally read from an external libname on the
   author's SAS Viya home). Populated with the columns HRU_Summary.sas reads:
   patient_id, encounter_type, cohortN (1=NOAC, 2=Warfarin, 3=Aspirin).
   A mix of encounter types across the three cohorts so the PROC FREQ /
   PROC TRANSPOSE utilization table renders for each column.
   -------------------------------------------------------------------------- */
data code_hru;
    length patient_id $10 encounter_type $20;
    input patient_id $ encounter_type $ cohortN;
    datalines;
p01 inpatient 1
p02 outpatient 1
p03 emergency 1
p04 outpatient 1
p05 inpatient 1
p06 telehealth 1
p07 outpatient 2
p08 inpatient 2
p09 emergency 2
p10 outpatient 2
p11 telehealth 2
p12 outpatient 3
p13 inpatient 3
p14 emergency 3
p15 outpatient 3
p16 outpatient 3
p17 telehealth 3
p18 inpatient 1
p19 outpatient 2
p20 emergency 3
;
run;
