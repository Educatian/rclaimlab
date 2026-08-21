# R-LearnXR reproducibility report

Generated: 2026-08-21 12:52:39 PDT
Mode: advisory

| Check | Status | Message |
|---|---|---|
| project_config | PASS | _quarto.yml exists |
| lesson_entrypoint | PASS | index.qmd exists |
| browser_scene | PASS | scene/index.html exists |
| lesson_manifest | PASS | lesson-manifest.json exists |
| manifest_contract | PASS | lesson manifest satisfies the version 2 contract |
| evidence_ir | PASS | Evidence IR satisfies rlearnxr-evidence-2 |
| data_license | PASS | lesson data source, provenance, and reuse terms are documented |
| data_presence | PASS | data directory contains at least one file |
| portable_paths | PASS | no common absolute local paths detected |
| deterministic_seed | PASS | a deterministic seed is declared |
| education_content | PASS | lesson prose includes objectives, prediction, explanation, and transfer activities |
| environment_lock | PASS | renv.lock found and contains the expected R and Packages sections |
| accessible_structure | PASS | keyboard canvas, live feedback, text inputs, and a data table markers are present |
| static_fallback | PASS | table, source, and learning receipt exports remain available without the visual runtime |
| ai_safety_markers | PASS | optional AI path omits browser credentials, records the privacy boundary, and validates returned code |
| learning_loop | PASS | predict, run R, explore, explain, reproduce, and completion controls are present |
| artifact_hash | PASS | abc68298243baacfa82cf67f0d503a4d, 8a04997baa91b8206b2ca56d41b4d5b7, 40c92ccc52eeabb20034489f3e616185 |
| quarto_available | WARN | Quarto CLI was not found; CI must render the lesson before release |

This report checks project hygiene and structural accessibility markers. PASS does not guarantee identical results on every operating system or replace a browser assistive-technology audit.
