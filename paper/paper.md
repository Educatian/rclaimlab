---
title: 'R-LearnXR: An Evidence Compiler for Reproducible Data-Science Education'
tags:
  - R
  - reproducibility
  - data science education
  - learning analytics
  - visualization
authors:
  - name: Jewoong Moon
    affiliation: 1
affiliations:
  - name: Affiliation to be confirmed before submission
    index: 1
date: 20 August 2026
bibliography: paper.bib
---

# Summary

R-LearnXR compiles existing R analysis objects into a method-independent Evidence Intermediate Representation. Stable observation, dimension, and evidence identifiers connect analytical values to semantic tables, 2D and 3D representations, learner explanations, transfer tasks, and reproducibility receipts.

# Statement of need

Educational visualizations often duplicate analytical state across code, browser graphics, worksheets, and assessment. That duplication makes it difficult to verify that a learner's explanation cites the same evidence shown by the analysis. R-LearnXR provides adapters for data frames, principal component analysis, linear and generalized linear models, and k-means clustering. It does not reimplement these statistical methods.

# Architecture and quality

R owns statistical computation and provenance. Renderers consume the Evidence IR and retain semantic-table and keyboard fallbacks. Contract tests cover stable identifiers, invalid values, deterministic hashes, JSON round trips, five reference lesson builds, and learning receipts. The release workflow checks multiple operating systems and R versions, browser interaction, offline fallback, documentation, and links.

# Research and community use

The software supports representation-comparison research without assuming that 3D is superior. Human-subjects outcomes will be reported separately from software functionality. JOSS submission will follow CRAN release, an archived DOI, and documented external lesson or adapter contributions.

# Acknowledgements

Grant, maintainer, advisor, and contributor acknowledgements will be added only after roles and support are confirmed.

# References
