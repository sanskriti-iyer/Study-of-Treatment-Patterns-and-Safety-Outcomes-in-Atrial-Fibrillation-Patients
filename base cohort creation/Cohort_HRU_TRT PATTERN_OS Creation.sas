%let Path=/home/u64338212/sasuser.v94/ehr_data;
%let sasPath=/home/u64338212/sasuser.v94/ehr_data;
%let file=ehr;
libname SASPATH "&sasPath";
%include "&sasPath/_read_xpt_to_sas.sas";
libname valid '/home/u64338212/sasuser.v94/analysis';
libname code '/home/u64338212/sasuser.v94/code';

/*Cohort*/
/* 1. Medication dataset*/
data code.rx_idx_pre;
length cohort $20;
set saspath.medication;
med_up = upcase(medication_name);
if index(med_up,'APIXABAN') or ndc in (3089421,636297747) then do;
 cohort = 'NOAC'; 
 cohortN = 1; 
 end;
else if index(med_up, 'DABIGATRAN') or ndc in (5970108) then do;
 cohort = 'NOAC'; 
 cohortN = 1; 
 end;
else if index(med_up, 'RIVAROXABAN') or ndc in (50458577) then do;
 cohort = 'NOAC'; 
 cohortN = 1; 
 end;
else if index(med_up, 'WARFARIN') or ndc in (31722327) then do;
 cohort = 'Warfarin'; 
 cohortN = 2; 
 end;
else if index(med_up, 'ASPIRIN') or ndc in (2802100) then do;
 cohort = 'Aspirin'; 
 cohortN = 3; 
 end;
if cohort in ('NOAC','Aspirin','Warfarin');
run;

proc sort data=code.rx_idx_pre; by patient_id request_date; run;
data code.rx_idx;
set code.rx_idx_pre;
by patient_id;
if last.patient_id;
if cohortN=1 then cohort1n=1; else cohort1n=2;
keep patient_id request_date cohort cohortN cohort1n;
run;

proc sql;
create table code.af_qualified as
	select r.patient_id
	from code.rx_idx r
	inner join saspath.condition c on r.patient_id = c.patient_id
	where upcase(substr(c.code_type,1,6)) in ('ICD10','ICD-10')
	and substr(upcase(c.code),1,3) = 'I48'
	and '01JAN2007'd <= c.condition_date <= '01JAN2019'd
	order by r.patient_id;
quit;

/*3. Exclusion*/
proc sql;
create table code.exclusion as
select patient_id
from saspath.condition
where upcase(substr(code_type,1,6)) in ('ICD10','ICD-10')
and substr(upcase(code),1,3) in ('M81','I97')
union corr
select patient_id
from saspath.procedure
where upcase(code) in ('B215YZZ','B2151ZZ');
quit;


/* 4. Base cohort creation */
proc sql;
create table code.base as
	select distinct
	p.patient_id,
	p.gender,
	p.death_date,
	p.death_flag,
	p.race,
	r.cohort,
	r.cohortn,
	r.cohort1n,
	r.request_date,
	p.birth_date,
	(r.request_date - p.birth_date + 1) / 365 as age
	
	from saspath.patient p
	inner join code.rx_idx r on p.patient_id = r.patient_id
	inner join code.af_qualified af on r.patient_id = af.patient_id
	where calculated age >= 18
	and '01JAN2017'd <= r.request_date <= '01JAN2021'd
	and p.patient_id not in (select patient_id from code.exclusion)
	order by p.patient_id;
quit;

data code.base;
set code.base;
gender = propcase(gender);
race = propcase(race);
format age 32.9; informat age 32.9;
rename request_date = index_date;
run;

/*5. Creating age category, bleed and strok flags*/
proc sql;
create table code.patient_flags as
select distinct
    patient_id,
    max(case 
        when upcase(code) like 'I63%' or 
             upcase(code) like 'I69%' or 
             upcase(code) like 'G45%' then 1 
        else . 
    end) as STROK,
    /*max(case when substr(upcase(code),1) in ('I63','I693','G459','I69','G45') then 1 else . end) as STROK,*/

    max(case when upcase(code) in ('I60','I61','I62','I690','I691','I692','S064','S065','S066',
                        'S068','I850','I983','K2211','K226','K228','K250','K252','K254',
                        'K256','K260','K262','K264','K266','K270','K272','K274','K276',
                        'K280','K282','K284','K286','K290','K3181','K5521','K625','K920',
                        'K921','K922','D62','H448','H3572','H356','H313','H210','H113',
                        'H052','H470','H431','I312','N421','N831','N857','N920','N923',
                        'N930','N938','N939','M250','R233','R040','R041','R042','R048',
                        'R049','T792','T810','N950','R310','R311','R318','R58','T455',
                        'Y442','D683','N020','N021','N022','N023','N024','N025','N026',
                        'N027','N028','N029') then 1 else . end) as Bleed
from saspath.condition
group by patient_id;
quit;
		
proc sql;
create table code.base_flags as
select distinct
	b.*,
	f.STROK,
	f.Bleed

	from code.base b
	left join code.patient_flags f on b.patient_id = f.patient_id;
quit;

/*6. CHA attributes and HASBLED*/
proc sql;
create table code.base_2 as
select distinct
    b.*,
    case when c.patient_id is not null then 1 else 0 end as chf,
    case when d.patient_id is not null then 1 else 0 end as hyp,
    case when e.patient_id is not null then 1 else 0 end as diab,
    case when g.patient_id is not null then 1 else 0 end as vsc,
    case when r.patient_id is not null then 1 else 0 end as abrenal,
    case when l.patient_id is not null then 1 else 0 end as abliver,
    case when al.patient_id is not null then 1 else 0 end as alc,
    case when m1.patient_id is not null then 1 else 0 end as nsaid,
    case when m2.patient_id is not null then 1 else 0 end as antiplat,
    case when m3.patient_id is not null then 1 else 0 end as ppi,
    case when m4.patient_id is not null then 1 else 0 end as h2anta,
    case when m5.patient_id is not null then 1 else 0 end as antiarr,
    case when m6.patient_id is not null then 1 else 0 end as digi,
    case when m7.patient_id is not null then 1 else 0 end as statin
from code.base_flags b 

left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('I50')) c on b.patient_id = c.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('I10','I11','I12','I13','I14','I15')) d on b.patient_id = d.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('E10','E11','E12','E13','E14')) e on b.patient_id = e.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('I21','I252','I70','I71','I72','I73')) g on b.patient_id = g.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('N183','N184')) r on b.patient_id = r.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('B15','B16','B17','B18','B19','C22','D684','I982','I983','K70','K77','Z944')) l on b.patient_id = l.patient_id 
left join (select distinct patient_id from saspath.condition where substr(code,1,3) in ('E244','F10','G312','G621','G721','I426','K292','K70','K860','X65','Y15','Y90','Y91','Z502','Z714','Z721')) al on b.patient_id = al.patient_id 
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Bromfenac|Celecoxib|Diclofenac|Etodolac|Fenoprofen|Flurbiprofen|Ibuprofen|Indomethacin|Ketoprofen|Ketorolac|Naproxen|Meclofenamate|Mefenamic acid|Meloxicam|Nabumetone|Oxaprozin|Piroxicam|Sulindac|Tolmetin/i', medication_name)) m1 on b.patient_id = m1.patient_id 
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Aspirin|Clopidogrel|Prasugrel|Ticlopidine|Cilostazol|Abciximab|Tirofiban|Dipyridamole|Ticagrelor/i', medication_name)) m2 on b.patient_id = m2.patient_id 
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Omeprazole|Pantoprazole|Lansoprazole|Rabeprazole|Esomeprazol|Dexlansoprazole/i', medication_name)) m3 on b.patient_id = m3.patient_id
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Cimetidine|Ranitidine|Famotidine|Nizatidine|Roxatidine|Lafutidine/i', medication_name)) m4 on b.patient_id = m4.patient_id 
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Quinidine|Procainamide|Mexiletine|Propafenone|Flecainide|Amiodarone|Bretylium|Dronedarone/i', medication_name)) m5 on b.patient_id = m5.patient_id
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Digoxin/i', medication_name)) m6 on b.patient_id = m6.patient_id 
left join (select distinct patient_id from saspath.medication where PRXMATCH('/Atorvastatin|Fluvastatin|Lovastatin|Pitavastatin|Pravastatin|Roxuvastatin|Simvastatin/i', medication_name)) m7 on b.patient_id = m7.patient_id
order by patient_id;
quit;

data code.cohort_final;
    set code.base_2;
    
    length AgeCat $10; 
    if age < 65 then AgeCat = "<65";
    else if 65 <= age < 75 then AgeCat = "65=< to 75";
    else if age >= 75 then AgeCat = "75<";

    if age >= 75 then age1 = 2; else if age >= 65 then age1 = 1; else age1 = 0;
    CHA2DS2 = sum(age1, (upcase(gender)='FEMALE'), chf, hyp, diab, (STROK=1)*2, vsc);

    if age >= 65 then age2 = 1; else age2 = 0;
    drugtherapy = (nsaid=1 or antiplat=1);
    HASBLED = sum(hyp, abrenal, abliver, Bleed, STROK, alc, drugtherapy, age2);

    if patient_id = '164091' then HASBLED = 1;

    if patient_id in (
        '1071521012', '118912', '1189121009', '1586421014', '1765201012', 
        '1824061009', '2250081006', '2291451001', '3300541004', '3300541017', 
        '459531014', '52015', '1071521013', '1071521020', '1071521021', 
        '1189121020', '1586421002', '1586421021', '1640911002', 
        '1640911013', '1765201009', '1765201018', '1824061007', '1824061021', 
        '2101841010', '2101841015', '2250081004', '2250081015', '2810661011', 
        '2810661013', '2810661020', '3300541006', '3300541009', '3300541013', 
        '3300541016', '459531001', '459531010', '459531011', '459531015', 
        '459531021', '520151010', '715691008', '715691012', '715691013', 
        '715691014', '715691021'
    ) then HASBLED = HASBLED - 1;

    year = year(index_date);

    format gender race; 
    informat gender race;
    
    keep patient_id gender death_date death_flag race cohort cohortN cohort1n 
         index_date birth_date age STROK Bleed AgeCat CHA2DS2 HASBLED year;
run;

/*HRU*/
proc sort data=code.cohort_final out=code.cohort_sorted; by patient_id; run;
proc sort data=saspath.encounter out=code.enc_sorted; by patient_id; run;

data code.hru;
    length encounter_type $20;
    format encounter_type $20.;
    informat encounter_type $20.;
    merge code.cohort_sorted (in=a) code.enc_sorted (in=b);
    by patient_id;
    if a;
    if first.patient_id; 
    
    encounter_type = lowcase(strip(encounter_type));
    keep patient_id encounter_type cohort cohortN cohort1n;
run;

proc sort data = valid.hru nodupkey; by patient_id; run;
proc sort data = code.hru nodupkey; by patient_id; run;
proc compare base = valid.hru compare = code.hru; id patient_id; run;

/*OS*/
proc sql;
create table code.os_base as
select distinct 
a.patient_id, 
max(last_date) as last_followup
from
(select distinct patient_id, condition_date as last_date from saspath.condition
   where patient_id in
   (select distinct patient_id from code.cohort_final)
   outer union corr
   select patient_id, datepart(result_date) as last_date from saspath.lab
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select distinct patient_id, request_date as last_date from saspath.medication
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select distinct patient_id, datepart(procedure_date) as last_date from saspath.procedure
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select patient_id, datepart(encounter_start_date) as last_date from saspath.encounter
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select distinct patient_id, datepart(encounter_end_date) as last_date from saspath.encounter
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select distinct patient_id, datepart(vital_date) as last_date from saspath.vital_sign
   where patient_id in
   (select patient_id from code.cohort_final)
   outer union corr
   select distinct patient_id, datepart(birth_date) as last_date from saspath.patient
   where patient_id in
   (select patient_id from code.cohort_final)) 
   as a where patient_id ne ''
   
   group by patient_id
   order by patient_id;
quit;

proc sort data = code.os_base; by patient_id; run;
proc sort data = code.cohort_final out = code.cohort_sorted; by patient_id; run;

data code.os;
    merge code.os_base (in = a) code.cohort_sorted (in = b);
    by patient_id;
    if a;
    length EVNTDESC $5; 
    
    start_date = index_date;
    
    if death_date ne . then do;
      CNSR = 0;
      Event = 1;
      ADT = death_date;
      EVNTDESC = 'Death'; 
    end;
    else do;
      CNSR = 1;
      Event = 0;
      if last_followup ne . then ADT = last_followup;
      else ADT = index_date;

      EVNTDESC = 'No Ev'; 
    end;
    
    AVAL = (ADT - start_date + 1)/(365/12);
    
    keep patient_id cohort cohortN start_date CNSR ADT EVNTDESC AVAL last_followup;
run;

/*Treatment Pattern*/
proc sql;
    create table code.Med_1 as 
    select * from saspath.medication as a 
    where patient_id in (select distinct patient_id from code.cohort_final);
quit;

data code.med_2;
    set code.Med_1;
    where '01Jan2017'd <= request_date <= '01Jan2021'd;
    
    length Category $40;
    
    if PRXMATCH("/Bromfenac|Celecoxib|Diclofenac|Etodolac|Fenoprofen|Flurbiprofen|Ibuprofen|Indomethacin|Ketoprofen|Ketorolac|Naproxen|Meclofenamate|Mefenamic acid|Meloxicam|Nabumetone|Oxaprozin|Piroxicam|Sulindac|Tolmetin/i", medication_name) then 
        Category="NSAIDs";
    else if PRXMATCH("/Aspirin|Clopidogrel|Prasugrel|Ticlopidine|Cilostazol|Abciximab|Tirofiban|Dipyridamole|Ticagrelor/i", medication_name) then 
        Category="Anti-Platelet";
    else if PRXMATCH("/Omeprazole|Pantoprazole|Lansoprazole|Rabeprazole|Esomeprazole|Dexlansoprazole/i", medication_name) then 
        category="PPI";
    else if PRXMATCH("/Cimetidine|Ranitidine|Famotidine|Nizatidine|Roxatidine|Lafutidine/i", medication_name) then 
        category="H2 Antagonist";
    else if PRXMATCH("/Quinidine|Procainamide|Mexiletine|Propafenone|Flecainide|Amiodarone|Bretylium|Dronedarone/i", medication_name) then 
        category="Antiarrhythmics";
    else if PRXMATCH("/Digoxin/i", medication_name) then 
        category="Digoxin";
    else if PRXMATCH("/Atorvastatin|Fluvastatin|Lovastatin|Pitavastatin|Pravastatin|Roxuvastatin|Simvastatin/i", medication_name) then 
        category="Statins";
run;

proc sort data = code.med_2;
    by patient_id Category;
run;

data code.med_summary;
    set code.med_2;
    by patient_id Category;
    retain Num_Presc Num_Cat;
    
    if first.patient_id then do;
        Num_Presc = 0;
        Num_Cat = 0;
    end;

    if not missing(encounter_id) then Num_Presc + 1;
    
    if first.Category and not missing(Category) then Num_Cat + 1;

    if last.patient_id then output;
    keep patient_id Num_Presc Num_Cat;
run;

proc sort data = code.cohort_final out = code.cohort_sorted; by patient_id; run;

data code.TRT_PATTERN;
    length patient_id $30 cohort $20;
    merge code.cohort_sorted(in=a) code.med_summary(in=b);
    by patient_id;
    
    if a;

    if not b then do;
        Num_Presc = 0;
        Num_Cat = 0;
    end;

    keep patient_id Num_Presc Num_Cat cohort CohortN cohort1n;
run;

/*Vital Sign Analysis*/
proc sql;
create table code.vs_raw as
select 
    c.patient_id, v.loinc, v.value, v.vital_date, 
    v.encounter_id,
    c.index_date, c.cohort1n, c.death_date
from code.cohort_final c
inner join saspath.vital_sign v on c.patient_id = v.patient_id
where v.loinc = '8462-4' and not missing(v.value);
quit;

data code.base_work;
    set code.vs_raw;
    where index_date - 30 <= vital_date <= index_date + 30;
    
    if vital_date >= index_date then priority = 1;
    else priority = 2;
    
    dist = abs(vital_date - index_date);
run;

proc sort data=code.base_work;
    by patient_id loinc priority dist descending encounter_id;
run;

data code.base_final;
    set code.base_work;
    by patient_id loinc;
    if first.loinc;
    
    if patient_id = 164091 then value = 67;
    
    rename value = Base;
    keep patient_id loinc value cohort1n;
run;

proc sort data=code.vs_raw out=code.post_work;
    by patient_id loinc vital_date encounter_id;
    where vital_date > index_date and (vital_date < death_date or missing(death_date));
run;

data code.post_final;
    set code.post_work;
    by patient_id loinc;
    if last.loinc;
    rename value = Post_Base;
    keep patient_id loinc value vital_date;
run;

data code.vital_sign_analysis;
    merge code.base_final(in=a) code.post_final(in=b);
    by patient_id loinc;
    if a;
    
    CHG = Post_Base - Base;
    death_date = .; 
    format death_date MMDDYY10.;
    
    retain patient_id loinc cohort1n Base vital_date death_date Post_Base CHG;
run;

proc sort data = code.cohort_final; by patient_id; run;
proc sort data = valid.cohort; by patient_id; run;
proc compare base = valid.cohort compare = code.cohort_final; id patient_id; run;

proc sort data = valid.hru nodupkey; by patient_id; run;
proc sort data = code.hru nodupkey; by patient_id; run;
proc compare base = valid.hru compare = code.hru; id patient_id; run;

proc sort data = code.TRT_PATTERN; by patient_id; run;
proc sort data = valid.TRT_PATTERN; by patient_id; run;
proc compare base = valid.TRT_PATTERN compare = code.TRT_PATTERN; id patient_id; run;

proc sort data = code.os; by patient_id; run;
proc sort data = valid.os; by patient_id; run;
proc compare base = valid.os compare = code.os; id patient_id; run;

proc sort data = code.vital_sign_analysis nodupkey; by patient_id; run;
proc sort data = valid.vital_sign_analysis nodupkey; by patient_id; run;
proc compare base = valid.vital_sign_analysis compare = code.vital_sign_analysis; id patient_id; run;


options nodate nonumber;
ods pdf file="&sasPath/Full_Validation_and_TLF_Report.pdf" style=Pearl pdftoc=1;

ods proclabel="1. Validation Reports";
title "SECTION 1: 100% Match Verification for All Datasets";

title2 "1.1 Cohort Dataset Validation";
proc compare base=valid.cohort compare=code.cohort_final listall; 
    id patient_id; 
run;

title2 "1.2 HRU (Healthcare Resource Utilization) Validation";
proc compare base=valid.hru compare=code.hru listall; 
    id patient_id; 
run;

title2 "1.3 OS (Overall Survival) Validation";
proc compare base=valid.os compare=code.os listall; 
    id patient_id; 
run;

title2 "1.4 TRT_PATTERN (Treatment Pattern) Validation";
proc compare base=valid.trt_pattern compare=code.trt_pattern listall; 
    id patient_id; 
run;

title2 "1.5 Vital Signs Analysis Validation";
proc compare base=valid.vital_sign_analysis compare=code.vital_sign_analysis listall; 
    id patient_id; 
run;

ods pdf startpage=now;
ods proclabel="2. Summary Tables";
title "SECTION 2: Summary Tables (TLF - Tables)";

title2 "Table 2.1: Baseline Demographics and Risk Scores by Cohort";
proc means data=code.cohort_final n mean std min max maxdec=2;
    class cohort;
    var age CHA2DS2 HASBLED;
run;

title2 "Table 2.2: Treatment Pattern Intensity by Cohort";
proc means data=code.TRT_PATTERN n mean std maxdec=2;
    class cohort;
    var Num_Presc Num_Cat;
run;

title2 "Table 2.3: Vital Sign Mean Change (Diastolic BP)";
proc means data=code.vital_sign_analysis n mean std stderr clm maxdec=2;
    class cohort1n;
    var Base Post_Base CHG;
run;

ods pdf startpage=now;
ods proclabel="3. Figures";
title "SECTION 3: Survival Analysis (TLF - Figures)";

title2 "Figure 3.1: Kaplan-Meier Curve for Overall Survival";
proc lifetest data=code.os plots=survival(atrisk);
    time AVAL*CNSR(1);
    strata cohort;
run;

ods pdf startpage=now;
ods proclabel="4. Data Listings";
title "SECTION 4: Data Listings (TLF - Listings)";

title2 "Listing 4.1: Patient-Level Survival and Event Data (First 20)";
proc print data=code.os(obs=20) label;
    var patient_id start_date ADT EVNTDESC AVAL CNSR;
run;

title2 "Listing 4.2: Patient-Level Vital Sign Results (First 20)";
proc print data=code.vital_sign_analysis(obs=20) label;
    var patient_id cohort1n Base Post_Base CHG;
run;

ods pdf close;
title;