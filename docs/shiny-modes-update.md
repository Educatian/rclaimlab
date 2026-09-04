# Run the updated local four-mode builder

The Shiny **builder** imports data and runs R. The generated **workspace** uses
the same role labels, phases and contextual controls as the public demo.
The two screens serve different purposes and are not pixel-identical.

From this repository's RStudio project:

```r
# Load the development source, not an older installed copy.
pkgload::load_all(".")
rclaimlab::run_workflow_wizard(port = 8791)
```

Stop an existing app before restarting on the same port. To install a checked
package persistently, install the local source tarball, restart R, then call
`library(rclaimlab); run_workflow_wizard()`.

1. Choose Guided Learning, Data Analyst, Data Scientist, or Model Reviewer.
2. Choose a local file, Hugging Face, or Kaggle. Alternatively select **Try
   synthetic practice data** for 80 artificial rows, with no network download.
3. Inspect the preview and license; import the selected data locally.
4. Enter the question and variable roles. For a model, select an outcome and
   remove that outcome from the predictor list; a variable cannot predict itself.
5. Review the method and create the plan. Creating a plan does not run analysis.
6. Expand each step for its input, task, expected output and criteria. Approve
   all four decisions. A changed question, mode, source or method needs a new plan.
7. Run the workflow, then open its generated workspace. Its activity work starts
   incomplete even though the R analysis has executed.

The generated app remains portable at `<new build folder>/app/index.html`.
The local HTTP link works only while its Shiny session is running. New builds
never overwrite prior results.

`run_rclaimlab_shiny()` is the separate educator console, not this wizard.
The hosted demo does not accept data into a remote R server. Remote provider
credentials, licenses and data access must still be checked for the chosen source.
