# Research basis for the R-LearnXR curriculum

This design note translates the dated literature scan into content and feature decisions. The scan records search tiers, source selection, synthesis, and APA-ready references.

## What the literature changes

- Learning Analytics (LA) and Educational Data Mining (EDM) overlap but are not interchangeable. LA emphasizes data-informed understanding, feedback, and educational decisions; EDM emphasizes computational pattern discovery and modeling. R-LearnXR therefore keeps separate LA and EDM application tracks.
- Data Science Education needs interdisciplinary, translational, ethical, professional, and reproducible skills in addition to statistics and programming.
- Reviews identify gaps in explicit theory, empirical evidence, terminology, and reproducibility. R-LearnXR addresses these through learning objectives, decision prompts, claim/evidence/limitation rubrics, receipts, and strict lesson checks.
- Analytics are not neutral. Learners must see the measurement boundary, consent/privacy choices, uncertainty, and the consequences of a false positive or false negative.

## Sources

- Aldowah, Al-Samarraie, & Fauzy (2019), *Telematics and Informatics*. [DOI](https://doi.org/10.1016/j.tele.2019.01.007)
- Romero & Ventura (2020), *WIREs Data Mining and Knowledge Discovery*. [DOI](https://doi.org/10.1002/widm.1355)
- Ifenthaler & Yau (2020), *Educational Technology Research and Development*. [DOI](https://doi.org/10.1007/s11423-020-09788-z)
- Cerezo, Lara, Azevedo, & Romero (2024), *Computers in Human Behavior*. [DOI](https://doi.org/10.1016/j.chb.2024.108155)
- Dogucu et al. (2025), *Journal of Statistics and Data Science Education*. [DOI](https://doi.org/10.1080/26939169.2025.2486656)
- National Academies of Sciences, Engineering, and Medicine (2018), *Data Science for Undergraduates*. [DOI](https://doi.org/10.17226/25104)
- American Statistical Association (2020), *GAISE II*. [Framework PDF](https://www.amstat.org/docs/default-source/amstat-documents/gaiseiiprek-12_full.pdf)
- UNESCO IITE (2012), *Learning Analytics*. [Policy brief](https://iite.unesco.org/publications/3214711/)

## Design translation

| Evidence from research | R-LearnXR implementation |
|---|---|
| Question and educational purpose matter | Every module begins with a learner decision |
| Concepts should not be reduced to syntax | Predict before R, then explain the transformation |
| LA/EDM require measurement caution | Event-to-construct maps and no-diagnosis guardrails |
| Data science is interdisciplinary | Statistics pathway plus LA/EDM application track |
| Reproducibility is a gap | Source export, seed/runtime/hash, Quarto, manifest, CI |
| Visual analytics can mislead | 3D is optional; table, keyboard, and limitation prompts are required |
| Ethical governance is part of competence | Consent, privacy, retention, fairness, and reversible action activities |

See the executable curriculum map in [statistics-modules.md](../curriculum/statistics-modules.md) and the LA/EDM lab sequence in [learning-analytics-edm-lab.md](../curriculum/learning-analytics-edm-lab.md).
