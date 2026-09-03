# SWATreadR: old and updated versions

These version tags expose the source before the SWAT+ 62 update and the tested updated source in this same repository. They do not replace or rewrite the original Git history.

| Snapshot | Package version | Git tag |
| --- | --- | --- |
| Old source baseline | 0.1.0.9010 | [before-swat62-update](https://github.com/MR-Eini/SWATreadR-swat62/tree/before-swat62-update) |
| Updated development version | 0.1.0.9013 | [swat62-v0.1.0.9013](https://github.com/MR-Eini/SWATreadR-swat62/tree/swat62-v0.1.0.9013) |

The old tag points to commit [`f6a11c8ce7cda0ce1d4e083f43a4d963ffb9253a`](https://github.com/MR-Eini/SWATreadR-swat62/commit/f6a11c8ce7cda0ce1d4e083f43a4d963ffb9253a), the exact upstream source commit used before these edits. It is a source baseline for this update, not a claim that every bundled package dates from three years ago.

## Review the differences on GitHub

1. Open the [old-to-updated comparison](https://github.com/MR-Eini/SWATreadR-swat62/compare/before-swat62-update...swat62-v0.1.0.9013?w=1).
2. Scroll to the changed files. GitHub marks removed lines red and added lines green.
3. Open individual files or commits to inspect each change. Where available, select the split view to see old and new code side by side.

The comparison above hides whitespace-only changes, which is especially useful for files with different Windows line endings. The [complete comparison](https://github.com/MR-Eini/SWATreadR-swat62/compare/before-swat62-update...swat62-v0.1.0.9013) includes every change. The [commit history](https://github.com/MR-Eini/SWATreadR-swat62/commits/main) shows the incremental updates.

Both tags are fixed snapshots. Future versions should receive new version tags; `main` remains the current working branch. These are maintained development versions, not releases issued by the original authors.

## Main changes

- Add shared helpers for named controls and legacy/revision 62 print options.
- Read management records by their headers and preserve short operation records and extra columns.
- Read adjacent fixed-width plant/management labels without losing HRU records; retain average-annual calibration metadata as cal_sim and cal_adj.
- Write plant maturity fields as integers while preserving the other values and additional columns.

## Tested scope

The updated packages ran the supplied migrated reference model with the Windows Intel SWAT+ revision 62 executable. The supplied verification, discharge calibration/validation, sensitivity, crop and water-yield workflows produced outputs. The final source test run covered all seven package test directories and passed 83 expectations. These results do not establish compatibility for every model, executable or optional process; scientific calibration acceptance has not been achieved.

See [COMPATIBILITY.md](COMPATIBILITY.md) and [the workflow results](compatibility/workflow-summary.json) for the tests and limitations. Model input migration and updating the old project-generation layer are separate from these package source comparisons.
