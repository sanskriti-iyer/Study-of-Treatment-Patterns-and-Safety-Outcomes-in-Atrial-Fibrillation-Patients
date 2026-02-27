%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;

libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

data cha_has;
    set code.cohort_final;
    length cha $10. hasb $10. year_cat $10. cohort1 $10. age_cat $10.;

    if year(index_date) = 2020 then year_cat='2020';
    else if year(index_date)=2019 then year_cat='2019';
    else if year(index_date)=2018 then year_cat='2018';
    else year_cat='Other';

    if CHA2DS2 <= 2 then cha='0-2';
    else if CHA2DS2=3 then cha='3';
    else if CHA2DS2=4 then cha='4';
    else if CHA2DS2>=5 then cha='>=5';

    if HASBLED <=2 then hasb='0-2';
    else if HASBLED >=3 then hasb='>=3';

    if age < 65 then age_cat = '<65';
    else if 65 <= age <= 75 then age_cat = '65-75';
    else if age > 75 then age_cat = '>75';

    if index(cohort,'Aspirin')>0 then cohort1='Aspirin';
    else if index(cohort,'Warfarin')>0 then cohort1='Warfarin';
    else if index(cohort,'NOAC')>0 then cohort1='NOAC';
run;

proc sql noprint;
    select count(distinct patient_id) into :N1 trimmed from cha_has where cohort1='Aspirin';
    select count(distinct patient_id) into :N2 trimmed from cha_has where cohort1='Warfarin';
    select count(distinct patient_id) into :N3 trimmed from cha_has where cohort1='NOAC';
    select count(distinct patient_id) into :N4 trimmed from cha_has;
quit;

proc means data=cha_has n mean median min max std noprint;
    class cohort1;
    var age;
    output out=age_stats n=n mean=mean median=median min=min max=max std=std;
run;

data age_final;
    length value $70. ASPIRIN_ WARFARIN_ NOAC_ Total_ $70.;
    ord=1;
    
    value='Age (Years)'; od=0; output;

    value='  N'; od=1;
    set age_stats(where=(_TYPE_=0)) ; Total_ = put(n, 8.);
    set age_stats(where=(cohort1='Aspirin')) ; ASPIRIN_ = put(n, 8.);
    set age_stats(where=(cohort1='Warfarin')); WARFARIN_ = put(n, 8.);
    set age_stats(where=(cohort1='NOAC'))    ; NOAC_ = put(n, 8.);
    output;

    value='  Mean'; od=2;
    set age_stats(where=(_TYPE_=0)) ; Total_ = put(mean, 8.1);
    set age_stats(where=(cohort1='Aspirin')) ; ASPIRIN_ = put(mean, 8.1);
    set age_stats(where=(cohort1='Warfarin')); WARFARIN_ = put(mean, 8.1);
    set age_stats(where=(cohort1='NOAC'))    ; NOAC_ = put(mean, 8.1);
    output;

    value='  Median'; od=3;
    set age_stats(where=(_TYPE_=0)) ; Total_ = put(median, 8.1);
    set age_stats(where=(cohort1='Aspirin')) ; ASPIRIN_ = put(median, 8.1);
    set age_stats(where=(cohort1='Warfarin')); WARFARIN_ = put(median, 8.1);
    set age_stats(where=(cohort1='NOAC'))    ; NOAC_ = put(median, 8.1);
    output;

    value='  Min, Max'; od=4;
    set age_stats(where=(_TYPE_=0)) ; Total_ = catx(', ', put(min, 3.), put(max, 3.));
    set age_stats(where=(cohort1='Aspirin')) ; ASPIRIN_ = catx(', ', put(min, 3.), put(max, 3.));
    set age_stats(where=(cohort1='Warfarin')); WARFARIN_ = catx(', ', put(min, 3.), put(max, 3.));
    set age_stats(where=(cohort1='NOAC'))    ; NOAC_ = catx(', ', put(min, 3.), put(max, 3.));
    output;

    value='  Standard Deviation'; od=5;
    set age_stats(where=(_TYPE_=0)) ; Total_ = put(std, 8.2);
    set age_stats(where=(cohort1='Aspirin')) ; ASPIRIN_ = put(std, 8.2);
    set age_stats(where=(cohort1='Warfarin')); WARFARIN_ = put(std, 8.2);
    set age_stats(where=(cohort1='NOAC'))    ; NOAC_ = put(std, 8.2);
    output;
run;

proc freq data=cha_has noprint; tables age_cat*cohort1 / out=agecat_stat; run;
proc transpose data=agecat_stat out=agecat_wide; by age_cat; id cohort1; var count; run;

data agecat_sub;
    set agecat_wide;
    length ASPIRIN_ WARFARIN_ NOAC_ Total_ $70. value $70.;
    array d[*] Aspirin Warfarin NOAC Total;
    array out[*] ASPIRIN_ WARFARIN_ NOAC_ Total_;
    array n_t[4] _temporary_ (&N1,&N2,&N3,&N4);

    value = '  ' || compress(age_cat);
    do i=1 to 4;
        v=d[i]; if v=. then v=0;
        out[i]=put(v,5.) || ' (' || put(v/n_t[i]*100,5.1) || '%)';
    end;
    ord=6;
    if age_cat='<65' then od=1;
    else if age_cat='65-75' then od=2;
    else if age_cat='>75' then od=3;
run;
data agecat_header; length value $70.; value='Age Categorization (%)'; ord=6; od=0; run;

proc freq data=cha_has noprint; tables year_cat*cohort1 / out=yearstat; run;
proc transpose data=yearstat out=year_wide; by year_cat; id cohort1; var count; run;

data year_sub;
    set year_wide;
    length ASPIRIN_ WARFARIN_ NOAC_ Total_ $70. value $70.;
    array d[*] Aspirin Warfarin NOAC Total;
    array out[*] ASPIRIN_ WARFARIN_ NOAC_ Total_;
    array n_t[4] _temporary_ (&N1,&N2,&N3,&N4);

    value = '  ' || compress(year_cat);
    do i=1 to 4;
        v=d[i]; if v=. then v=0;
        out[i]=put(v,5.) || ' (' || put(v/n_t[i]*100,5.1) || '%)';
    end;
    ord=7;
    if year_cat='2020' then od=1;
    else if year_cat='2019' then od=2;
    else if year_cat='2018' then od=3;
run;
data year_header; length value $70.; value='Year of Diagnosis of AF'; ord=7; od=0; run;

data final_table;
    set age_final
        gen_header gen_sub
        race_header race_sub
        cha_header cha_ms cha_sub
        has_header has_ms has_sub
        agecat_header agecat_sub
        year_header year_sub;
run;

ods pdf file = '/home/u64338212/sasuser.v94/Reports/Baseline.pdf' style = Sapphire;
ods rtf file = '/home/u64338212/sasuser.v94/Reports/Baseline.rtf' style = Sapphire;
proc report data=final_table nowd split='*';
    column ord od value ("Treatment Cohorts" ASPIRIN_ WARFARIN_ NOAC_) Total_;
    define ord / order noprint;
    define od / order noprint;
    define value / display "Characteristic" style(column)=[cellwidth=2.5in];
    define ASPIRIN_  / display "Aspirin*(N=&N1)" center;
    define WARFARIN_ / display "Warfarin*(N=&N2)" center;
    define NOAC_      / display "NOAC*(N=&N3)" center;
    define Total_     / display "Total*(N=&N4)" center;

    compute value;
        if od=0 then call define(_row_,"style","style=[fontweight=bold]");
    endcomp;
run;

ods pdf close;
ods rtf close;