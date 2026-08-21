## Test environments

- GitHub Actions: Windows, macOS, and Ubuntu with R release
- GitHub Actions: Ubuntu with R oldrel, release, and devel
- Local Windows: R 4.6.1

## R CMD check results

The release gate requires 0 errors and 0 warnings. The local `--as-cran` check may report the expected informational `New submission` note until the package has a CRAN history. Any other note must be resolved or explained here. Update this file with the final matrix URLs before submission.

## Downstream dependencies

There are currently no known downstream CRAN dependencies.

## Scope

The package compiles existing R analysis objects into educational evidence artifacts. Quarto, Shiny, and WebR are optional authoring or browser runtimes and are not required for core Evidence IR construction.
