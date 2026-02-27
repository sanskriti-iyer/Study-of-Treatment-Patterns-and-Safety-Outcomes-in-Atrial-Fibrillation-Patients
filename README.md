# Treatment-Patterns-and-Safety-Outcomes-SAS-Analysis

_**AFib RWE Analysis: Production TLF Pipeline (SAS Viya 9.4)**_

**Project Overview**:

Real-world evidence study analyzing 282 AFib patients comparing NOAC vs Warfarin/Aspirin safety, survival, and treatment patterns (p=0.0175 clinical significance).

**Full pipeline generates 7 validated TLF reports (PDF/RTF):**
- Baseline demographics + CHA2DS2-VASc/HAS-BLED
- CV parameter changes (HR, SBP, DBP) with T-tests  
- Drug treatment patterns (Rx count/category)
- Healthcare resource utilization by encounter type
- Overall survival summary (Kaplan-Meier quartiles)
- Stroke/Bleeding binary analysis (Chi-square)
- Cohort validation (100% PROC COMPARE match)

**File Structure:**
Base cohort creation/

├── analysis.sas - Main cohort pipeline (1,000+ EHR → n=282 w/ CHA2DS2-VASc, HAS-BLED)

├── Cohort Creation.log - Execution log

└── Cohort HRU TRT OS.pdf - Full validation + TLF report

TLF Generation/

├── CV_Change.sas - Macro TTEST → CV_Change.pdf

├── Demographic.sas - PROC MEANS/FREQ → Baseline.pdf  

├── Drug_Treatment_Pattern.sas - Rx intensity → Drug_Treatment_Pattern.pdf

├── HRU_Summary.sas - Encounter utilization → HRU_summary.pdf

├── OS_Summary.sas - PROC LIFETEST → OS_Summary.pdf

└── Stroke_Bleed_Summary.sas - Chi-square binary → Strok_Bleed_Summary.pdf

**Key Clinical Features Demonstrated:**
- Production TLF generation (PDF/RTF dual output)
- Macro programming (stat_calculate, binary_chi)
- Risk score calculations (CHA2DS2-VASc max=9, HAS-BLED max=9)
- Survival analysis quartiles + 95% CI
- Table 1-style baseline N(%) tables
- Clinical reporting standards n/N(%)
- PROC COMPARE 100% validation
