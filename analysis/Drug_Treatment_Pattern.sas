%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;
libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

data presc_1;
    set code.TRT_PATTERN;
    length presc $10. cat $10.;

    if num_presc <= 2 then presc = '0-2';
    else if num_presc = 3 then presc = '3';
    else if num_presc = 4 then presc = '4';
    else if num_presc >= 5 then presc = '5 or More';

    if num_cat = 0 then cat = '0';
    else if num_cat = 1 then cat = '1';
    else if num_cat >= 2 then cat = '2 or More';
    output;

    cohort = 'All';
    cohortN = 9;
    cohort1n = 9;
    output;
run;

%let N1=0; %let N2=0; %let N3=0; %let N4=0;

proc sql noprint;
    select count(distinct patient_id) into :N1 - :N4 from presc_1
    group by cohortn
    order by cohortn;
quit;

proc freq data = presc_1 noprint;
    tables cohort * cohortN * presc / out = freq_1 (drop = percent);
    tables cohort * cohortN * cat / out = freq_2 (drop = percent);
run;

data freq_3;
    set freq_1 (in = a rename = (presc = cat)) freq_2 (in = b);
    length col1 $50. val $50.;
    
    if a then col1 = 'Number of Prescriptions';
    else if b then col1 = 'Number of Different AF Treatment Category Received';
    
    if cohortN = 1 then pct_denom = &N1;
    else if cohortN = 2 then pct_denom = &N2;
    else if cohortN = 3 then pct_denom = &N3;
    else if cohortN = 9 then pct_denom = &N4;

    if pct_denom > 0 then 
        val = strip(put(count, 8.)) || ' (' || strip(put(count * 100/pct_denom, 8.2)) || '%)';
    else val = '0 (0.00%)';
run;

proc sort data = freq_3; by col1 cat; run;

proc transpose data = freq_3 out = freq_4 (drop=_name_) prefix=_;
    by col1 cat;
    id cohortn;
    var val;
run;

data dummy;
    length col1 $50. cat $10.;
    col1 = 'Number of Prescriptions';
    cat = '0-2'; output;
    cat = '3'; output;
    cat = '4'; output;
    cat = '5 or More'; output;
    col1 = 'Number of Different AF Treatment Category Received';
    cat = '0'; output;
    cat = '1'; output;
    cat = '2 or More'; output;
run;

proc sort data = dummy; by col1 cat; run;

data freq_5;
    merge dummy freq_4;
    by col1 cat;
    array colx(*) _:;
    do i = 1 to dim(colx);
        if colx(i) = '' then colx(i) = '0 (0.00%)';
        else colx(i) = strip(colx(i));
    end;
    drop i;
run;

option nodate nonumber;
ods escapechar = '^';
ods pdf file = '/home/u64338212/sasuser.v94/Reports/Drug_Treatment_Pattern.pdf' style = Journal;
ods rtf file = '/home/u64338212/sasuser.v94/Reports/Drug_Treatment_Pattern.rtf' style = Journal;

title1 'Drug Treatment Pattern Summary';

proc report data = freq_5 headline split ='|' missing
            spacing = 1 wrap style(header) = {just = C}
            style(report) = [rules = group frame = hsides];
            
    column col1 cat _1 _2 _3 _9;
    define col1 / 'Parameter' order;
    define cat / order 'Category';
    
    define _1 / group "NOAC|(N=&N1)" style(column)={just=c cellwidth=15%};
    define _2 / group "Warfarin|(N=&N2)" style(column)={just=c cellwidth=15%};
    define _3 / group "Aspirin|(N=&N3)" style(column)={just=c cellwidth=15%};
    define _9 / group "Total|(N=&N4)" style(column)={just=c cellwidth=15%};

    compute before col1;
        line ' ';
    endcomp;
run;

ods pdf close;
ods rtf close;