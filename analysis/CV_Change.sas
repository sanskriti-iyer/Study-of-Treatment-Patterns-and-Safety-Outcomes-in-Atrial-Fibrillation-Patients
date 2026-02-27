%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;
libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

/* Summary of change in CV */
%macro stat_calculate (loinc =, label =, ord =);
    data vs3;
        set code.vital_sign_analysis;
        where loinc = "&loinc.";
    run;

    proc sql noprint;
        select count(*) into :n_obs from vs3;
    quit;

    %if &n_obs. > 0 %then %do;
        ods output TTests = Ttest (where = (Variances = 'Equal'))
                   statistics = stat;
        proc ttest data = vs3;
            class cohort1n;
            var chg;
        run;

        data stat1;
            set stat;
            /* stderr is the standard SAS variable name from proc ttest */
            meanx = put(mean, 8.2) || ' (' || strip(put(stderr, 8.2)) || ')';
            CI = '(' || strip(put(LowerCLMean, 8.2)) || ', ' || strip(put(UpperCLMean, 8.2)) || ')';
            min_max = '(' || strip(put(Minimum, 8.2)) || ', ' || strip(put(Maximum, 8.2)) || ')';
            if class in (1, 2);
            keep meanx CI min_max class;
        run;

        proc transpose data = stat1 out = stat2 prefix = _;
            id class;
            var meanx CI min_max;
        run;

        data Ttest1;
            set Ttest;
            _Name_ = 'P_Value';
            _l = put(probt, 8.4);
            keep _Name_ _l;
        run;

        data allstat_&ord;
            length col1 $50. _name_ $32. _1 _2 $100. param $50.;
            set stat2(rename=(_1=char1 _2=char2)) ttest1(rename=(_l=char_p));
            
            if _name_ = 'meanx' then col1 = 'Mean (SE)';
            else if _name_ = 'CI' then col1 = '95% CI';
            else if _name_ = 'min_max' then col1 ='Min, Max';
            else if _name_ = 'P_Value' then col1 = 'T test P Value';

            if _name_ = 'P_Value' then do;
                _1 = char_p; _2 = char_p;
            end;
            else do;
                _1 = char1; _2 = char2;
            end;

            param = "&label.";
            paramn = &ord.; /* Standardized as numeric */
            keep param paramn col1 _1 _2;
        run;
    %end;
    %else %do;
        /* Create a dummy row so the dataset exists for the SET statement */
        data allstat_&ord;
            length col1 $50. param $50. _1 _2 $100.;
            param = "&label.";
            paramn = &ord.;
            col1 = "No data found for this parameter";
            _1 = "N/A"; _2 = "N/A";
        run;
    %end;
%mend;

%stat_calculate(loinc = 8867-4, label = Heart Rate, ord = 1);
%stat_calculate(loinc = 8480-6, label = Systolic Blood Pressure, ord = 2);
%stat_calculate(loinc = 8462-4, label = Diastolic Blood Pressure, ord = 3);

data all_combined;
    set allstat_1 allstat_2 allstat_3;
run;

options center nonumber nodate;
ods pdf file = '/home/u64338212/sasuser.v94/Reports/CV_Change.pdf' style = Journal;
ods rtf file ='/home/u64338212/sasuser.v94/Reports/CV_Change.rtf' style = Journal;

title1 'Summary of Change in CV Parameters';
footnote1 'P value is calculated using T test';

proc report data = all_combined nowd headline headskip;
    column paramn param col1 _1 _2;
    define paramn / noprint order;
    define param / 'Parameter' group style(column)=[cellwidth=25%];
    define col1 / 'Statistics' display style(column)=[cellwidth=20%];
    define _1 / 'NOAC' display style(column)=[just=c cellwidth=15%];
    define _2 / 'Aspirin + Warfarin' display style(column)=[just=c cellwidth=15%];
    
    compute after param;
        line ' ';
    endcomp;
run;

ods pdf close;
ods rtf close;