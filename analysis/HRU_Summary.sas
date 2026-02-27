%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;
libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

data p_1;
    set code.hru;
    encounter_type = propcase(encounter_type);
    output;
    cohort = 'All'; cohortn = 9; cohort1n = 9;
    output;
run;

proc sql noprint;
    select count(distinct patient_id) into :N1 - :N4 
    from p_1
    group by cohortn
    order by cohortn;
quit;

%put N-values: &N1 &N2 &N3 &N4;

proc freq data = p_1 noprint;
    tables cohort * cohortn * encounter_type / out = freq_1(drop=percent);
run;

data freq_3;
    set freq_1;
    length col1 $50. val $50.;
    col1 = 'Healthcare Visit: Encounter Type';
    
    if cohortn = 1 then denom = &N1;
    else if cohortn = 2 then denom = &N2;
    else if cohortn = 3 then denom = &N3;
    else if cohortn = 9 then denom = &N4;
    
    if denom > 0 then 
        val = strip(put(count, 5.)) || ' (' || strip(put(count * 100/denom, 5.2)) || '%)';
    else val = '0 (0.00%)';
run;

proc sort data = freq_3;
    by col1 encounter_type;
run;

proc transpose data = freq_3 out = freq_4 prefix = _;
    by col1 encounter_type;
    id cohortn;
    var val;
run;

data freq_5;
    set freq_4;
    array colx (*) _:;
    do i = 1 to dim(colx);
        if colx(i) = '' then colx(i) = '0 (0.00%)';
        else colx(i) = strip(colx(i));
    end;
    drop i;
run;

options nodate nonumber;
ods escapechar ='^';
ods pdf file = '/home/u64338212/sasuser.v94/Reports/HRU_summary.pdf' style = Journal;
ods rtf file = '/home/u64338212/sasuser.v94/Reports/HRU_summary.rtf' style = Journal;

proc report data = freq_5 headline headskip split = '|' missing
            spacing = 1 wrap style(header) = {just = C}
            style(report) = [rules = group frame = hsides]; 
    
    column col1 encounter_type _1 _2 _3 _9;
    
    define col1 / 'Parameter' order style(column)=[just=l cellwidth=30%];
    define encounter_type / 'Encounter Visits' order style(column)=[just=l cellwidth=20%];
    
    define _1 / "NOAC|(N=&N1)" style(column)=[just=c cellwidth=12%];
    define _2 / "Warfarin|(N=&N2)" style(column)=[just=c cellwidth=12%];
    define _3 / "Aspirin|(N=&N3)" style(column)=[just=c cellwidth=12%];
    define _9 / "TOTAL|(N=&N4)" style(column)=[just=c cellwidth=12%];

    compute before col1;
        line ' ';
    endcomp;
run;

ods pdf close;
ods rtf close;