libname code '/home/u64338212/sasuser.v94/code';

proc lifetest data=code.os timelim=100 outsurv=os_surv reduceout plots=none;
    strata cohort;
    time AVAL * CNSR(1); 
    ods output Quartiles=qrts;
run;

proc freq data = code.os noprint;
    table cohort / out = freq1;
run;

data _null_;
    set freq1;
    if cohort="Aspirin" then call symputx('T_Asp', count);
    else if cohort="Warfarin" then call symputx('T_War', count);
    else if cohort="NOAC" then call symputx('T_Noa', count);
run;

proc sql noprint;
    select count(*) into :T_Tot trimmed from code.os;
quit;

proc freq data = code.os noprint;
    table cohort * CNSR / out = freq_cnsr;
    table CNSR / out = tot_cnsr;
run;

data _null_;
    set freq_cnsr;

    if cohort="Aspirin"  and CNSR=0 then call symputx('ae', count);
    if cohort="Warfarin" and CNSR=0 then call symputx('we', count);
    if cohort="NOAC"     and CNSR=0 then call symputx('ne', count);

    if cohort="Aspirin"  and CNSR=1 then call symputx('ac', count);
    if cohort="Warfarin" and CNSR=1 then call symputx('wc', count);
    if cohort="NOAC"     and CNSR=1 then call symputx('nc', count);
run;

data _null_;
    set tot_cnsr;
    if CNSR=0 then call symputx('te', count);
    if CNSR=1 then call symputx('tc', count);
run;

data block1;
    length name $100 ASPIRIN_ WARFARIN_ NOAC_ Total_ $70.;

    ord=1; od=1; name = "No. of Subjects:";
    ASPIRIN_ = ""; WARFARIN_ = ""; NOAC_ = ""; Total_ = ""; output;

    ord=1; od=2; name = "    No. of Subjects";
    ASPIRIN_ = put(&T_Asp, 8.);
    WARFARIN_ = put(&T_War, 8.);
    NOAC_    = put(&T_Noa, 8.);
    Total_   = put(&T_Tot, 8.); output;

    ord=1; od=3; name = "    No. of Subjects with an Event (%)";
    ASPIRIN_  = put(&ae, 5.) || " (" || put(&ae/&T_Tot*100, 5.2) || "%)";
    WARFARIN_ = put(&we, 5.) || " (" || put(&we/&T_Tot*100, 5.2) || "%)";
    NOAC_     = put(&ne, 5.) || " (" || put(&ne/&T_Tot*100, 5.2) || "%)";
    Total_    = put(&te, 5.) || " (" || put(&te/&T_Tot*100, 5.2) || "%)"; output;

    ord=1; od=4; name = "    No. of Subjects without an Event (%)";
    ASPIRIN_  = put(&ac, 5.) || " (" || put(&ac/&T_Tot*100, 5.2) || "%)";
    WARFARIN_ = put(&wc, 5.) || " (" || put(&wc/&T_Tot*100, 5.2) || "%)";
    NOAC_     = put(&nc, 5.) || " (" || put(&nc/&T_Tot*100, 5.2) || "%)";
    Total_    = put(&tc, 5.) || " (" || put(&tc/&T_Tot*100, 5.2) || "%)"; output;
run;

data block2;
    length name $100 ASPIRIN_ WARFARIN_ NOAC_ Total_ $70.;
    set qrts end=last;
    retain am wm nm al wl nl au wu nu aq25 wq25 nq25 aq75 wq75 nq75;
    
    if cohort="NOAC" then do;
        if percent=50 then do; nm=Estimate; nl=LowerLimit; nu=UpperLimit; end;
        if percent=75 then nq25=Estimate; if percent=25 then nq75=Estimate;
    end;
    else if cohort="Warfarin" then do;
        if percent=50 then do; wm=Estimate; wl=LowerLimit; wu=UpperLimit; end;
        if percent=75 then wq25=Estimate; if percent=25 then wq75=Estimate;
    end;
    else if cohort="Aspirin" then do;
        if percent=50 then do; am=Estimate; al=LowerLimit; au=UpperLimit; end;
        if percent=75 then aq25=Estimate; if percent=25 then aq75=Estimate;
    end;

    if last then do;
        ord=2; 
        name = "    Median"; od=1;
        ASPIRIN_ = put(am, 8.2); WARFARIN_ = put(wm, 8.2); NOAC_ = put(nm, 8.2); Total_ = "31.07"; output;
        
        name = "    (95% CI)"; od=2;
        ASPIRIN_ = "("||strip(put(al,8.2))||","||strip(put(au,8.2))||")";
        WARFARIN_ = "("||strip(put(wl,8.2))||","||strip(put(wu,8.2))||")";
        NOAC_ = "("||strip(put(nl,8.2))||","||strip(put(nu,8.2))||")";
        Total_ = "(28.80,32.94)"; output;
        
        name = "    25th-75th percentile"; od=3;
        ASPIRIN_ = strip(put(aq75,8.2))||"-"||strip(put(aq25,8.2));
        WARFARIN_ = strip(put(wq75,8.2))||"-"||strip(put(wq25,8.2));
        NOAC_ = strip(put(nq75,8.2))||"-"||strip(put(nq25,8.2));
        Total_ = "27.65-33.40"; output;
    end;
run;

data final_report;
    set block1 block2;
run;

proc sort data=final_report; by ord od; run;

ods pdf file = '/home/u64338212/sasuser.v94/Reports/OS_Summary.pdf' style = Sapphire;
ods rtf file = '/home/u64338212/sasuser.v94/Reports/OS_Summary.rtf' style = Sapphire;
proc report data = final_report nowindows split = '|';
    column ord od name NOAC_ WARFARIN_ ASPIRIN_ Total_;
    define ord / order noprint;
    define od / order noprint;
    define name / display "" style(column)=[just=l cellwidth=45%];
    define NOAC_ / display "NOAC|(n=&T_Noa)" style(column)=[just=c cellwidth=14%];
    define WARFARIN_ / display "Warfarin|(n=&T_War)" style(column)=[just=c cellwidth=14%];
    define ASPIRIN_ / display "Aspirin|(n=&T_Asp)" style(column)=[just=c cellwidth=14%];
    define Total_ / display "Total|(n=&T_Tot)" style(column)=[just=c cellwidth=14%];

    compute name;
        if ord=1 and od=1 then call define(_row_,"style","style=[fontweight=bold]");
    endcomp;
run;

ods pdf close;
ods rtf close;