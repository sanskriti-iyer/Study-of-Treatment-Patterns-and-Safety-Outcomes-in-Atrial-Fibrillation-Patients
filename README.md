# Treatment-Patterns-and-Safety-Outcomes-SAS-Analysis
_
**AFib RWE Analysis: Production TLF Pipeline (SAS Viya 9.4)**_

**Project Overview**
Real-world evidence study analyzing 282 AFib patients comparing NOAC vs Warfarin/Aspirin safety, survival, and treatment patterns (p=0.0175 clinical significance).

Full pipeline generates 7 validated TLF reports (PDF/RTF):
- Baseline demographics + CHA2DS2-VASc/HAS-BLED
- CV parameter changes (HR, SBP, DBP) with T-tests  
- Drug treatment patterns (Rx count/category)
- Healthcare resource utilization by encounter type
- Overall survival summary (Kaplan-Meier quartiles)
- Stroke/Bleeding binary analysis (Chi-square)
- Cohort validation (100% PROC COMPARE match)

