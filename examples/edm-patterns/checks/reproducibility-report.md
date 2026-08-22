# R-ClaimLab reproducibility report

Generated: 2026-08-22 01:56:22 PDT
Mode: strict (warnings fail)

| Check | Status | Message |
|---|---|---|
| project_config | PASS | _quarto.yml exists |
| lesson_entrypoint | PASS | index.qmd exists |
| browser_scene | PASS | scene/index.html exists |
| lesson_manifest | PASS | lesson-manifest.json exists |
| manifest_contract | PASS | lesson manifest satisfies the version 2 contract |
| evidence_ir | PASS | Evidence IR satisfies rclaimlab-evidence-2 |
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
| artifact_hash | PASS | 29fdcca4e170793b46ba91146be468fa, 2c5e753ed38b5b2257c1bc3f341f3773, f747ada4d41af69ac1b37203d24521bc |
| quarto_available | FAIL | Quarto CLI was not found; CI must render the lesson before release |

This report checks project hygiene and structural accessibility markers. PASS does not guarantee identical results on every operating system or replace a browser assistive-technology audit.
