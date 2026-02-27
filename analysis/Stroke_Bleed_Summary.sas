%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;
libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

data strok1 (keep = patient_id Resp cohort: cohort1n)
     bleed1 (keep = patient_id Resp cohort: cohort1n);  
    set code.cohort_final;

    if STROK ne . then Resp = 1;
    else Resp = 2;
    output strok1;

    if Bleed ne . then Resp = 1;
    else Resp = 2;
    output bleed1;

    if cohortN in (2 3) then cohort1n = 2; 
    else if cohortN = 1 then cohort1n = 1; 
run;

proc sql noprint;
    select strip(put(count(distinct patient_id),5.)) into :trt1 from strok1 where cohort1n = 1;
    select strip(put(count(distinct patient_id),5.)) into :trt2 from strok1 where cohort1n = 2;
quit;

%macro binary_chi (ds =, label =);
    proc sort data = &ds. out = bi_resp;
        by cohort1n;
    run;

    ods output OneWayFreqs = respfreq 
               BinomialCLs = limit (where = (type = 'Clopper-Pearson (Exact)'));
    proc freq data = bi_resp;
        by cohort1n;
        tables resp / binomial (exact);
    run;

    ods output ChiSq = ChiSq(where = (statistic = 'Chi-Square') keep = statistic prob);
    proc freq data = bi_resp;
        tables cohort1n * resp / chisq;
    run;

    data limit2;
        length cp $100 avalc $100;
        set limit;
        cp = '(' || strip(put(LowerCL * 100, 5.2)) || ',' || strip(put(UpperCL * 100, 5.2)) || ')';
        avalc = '(95% CI)';
        keep cp cohort1n avalc;
    run;

    data respfreq1;
        length cp $100 avalc $100;
        set respfreq;
        if resp = 1;
        if cohort1n = 1 then denom = &trt1;
        else if cohort1n = 2 then denom = &trt2;
        
        cd = strip(put(frequency, 5.)) || '/' || strip(put(denom, 5.));
        pct = put((frequency / denom) * 100, 5.1);
        cp = strip(cd) || ' (' || strip(pct) || '%)';
        avalc = 'Proportion (n/N)';
        keep cp cohort1n avalc;
    run;

    data combined_rows;
        set respfreq1 limit2;
    run;

    proc transpose data = combined_rows out = transposed prefix = _;
        by descending avalc;
        id cohort1n;
        var cp;
    run;

    data resp4_&ds.;
        length param $100 avalc $100 _1 _2 $100;
        set transposed (in = a) ChiSq (in = b);
        if a then do;
            ord = 1;
        end;
        if b then do;
            ord = 2;
            avalc = 'Chi-Square P Value';
            _1 = put(prob, 6.4);
            _2 = _1;
        end;
        param = "&label";
    run;
%mend;

%binary_chi(ds = strok1, label = Stroke);
%binary_chi(ds = bleed1, label = Bleeding);

data all_results;
    set resp4_strok1 resp4_bleed1;
run;

options center nonumber nodate;
ods pdf file = '/home/u64338212/sasuser.v94/Reports/Strok_Bleed_Summary.pdf' style = Journal;
ods rtf file = '/home/u64338212/sasuser.v94/Reports/Strok_Bleed_Summary.rtf' style = Journal;

title 'Summary of Stroke and Bleeding Occurrences - Binary Analysis';
footnote1 'P-value is calculated using Chi Square';

proc report data = all_results nowd headline split = '*' center wrap spacing = 1 
    style(header) = [just = c fontweight=bold];
    
    column param ord avalc ("Cohorts*" _1 _2);
    
    define param / 'Parameter' order order=data style(column)=[just=l cellwidth=15% fontweight=bold];
    define ord   / group noprint;
    define avalc / 'Analysis Metric' style(column)=[just=l cellwidth=25%];
    
    define _1 / "NOAC*(n = &trt1)" style(column)=[just=c cellwidth=20%];
    define _2 / "Aspirin + Warfarin*(n = &trt2)" style(column)=[just=c cellwidth=20%];
    
    compute after param;
        line ' '; 
    endcomp;
run;

ods pdf close;
ods rtf close;