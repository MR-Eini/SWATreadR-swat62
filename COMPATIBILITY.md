# SWAT+ 62 compatibility development fork

This repository preserves the upstream history and license of SWATreadR. Package names remain unchanged so existing R scripts can continue using `library(SWATreadR)`. This is a tested development update, not an upstream release.

Upstream starting commit: `f6a11c8ce7cda0ce1d4e083f43a4d963ffb9253a`. SWATrunR uses upstream `remove_legacy` (1.1.0.9017), matching the bundled workflow; its one local difference was portable library propagation to workers, which is retained in this update.

## Verified scope

Windows, R 4.5.2; supplied Mini_setup_CREATE model at commit `f3c8035a697567f41973445754d45c650c170db5`; four-year runs (2004–2007) with 2007 daily output. The official Intel revision 62 executable completed the runs. The official GNU 62.0.0 executable raised a floating-point exception during weather initialization on this model.

- Two parameter sets execute in parallel and a curve-number change alters basin runoff.
- Verification reads 314 HRUs, 114,610 daily plant/weather records and 4,212 management records without truncating files.
- The legacy 61.0_M executable still completes through the updated runner.
- Calibration export includes ordinary and plant-only parameter sets. Maturity fields require whole numbers.
- Focused tests cover changed control layouts, adjacent fixed-width output labels, date alignment, calibration precision and invalid run indices.

The updated runner and verifier require `SWATreadR >= 0.1.0.9011` from [MR-Eini/SWATreadR-swat62](https://github.com/MR-Eini/SWATreadR-swat62). Install that source package first, then the other packages, into the same R library. These repositories are private development copies; GitHub installation requires access to them. Git clone followed by local R package installation also works.

## Model conversion is a separate step

Replacing the executable alone is insufficient. For this non-carbon reference model, migration adds the optional carbon-file slot to the basin row of `file.cio`, writes integer `days_mat`/`yrs_mat` values in `plants.plt`, and converts `print.prt` to named-object mode. The obsolete `region_cha` output row is removed; `region_sd_cha` remains available. Existing hydrologic parameter values are retained.

The package helpers preserve extra control fields and use output headers. They do not invent values for new physical processes or promise compatibility with every future schema. Carbon, GWFlow, time-series recall, other catchments, non-Windows executables, and a full scientific recalibration/validation remain outside the completed test coverage. The existing workflow's Editor 2.1.0 setup database and SWATprepR/SWATfarmR generation routines require a separate migration before regenerating arbitrary revision 62 projects.

The legacy and new executables produce different unperturbed mean daily basin runoff in this test (0.338866 vs 0.359504 mm/day). This is an observed model-version difference, not a validation against measurements.

## Sources

- [Official SWAT+ downloads](https://swat.tamu.edu/software/plus/)
- [SWAT+ 62.0.0 source release](https://github.com/swat-model/swatplus/releases/tag/62.0.0)
- [Print reader](https://github.com/swat-model/swatplus/blob/62.0.0/src/basin_print_codes_read.f90)
- [HRU output formats](https://github.com/swat-model/swatplus/blob/62.0.0/src/hru_output.f90)
- [Reference model](https://github.com/MR-Eini/Mini_setup_CREATE/tree/f3c8035a697567f41973445754d45c650c170db5/5_NBS/1_Managment_scenario/1_Statusquo/FarmR_project/clean_setup)

Official Intel executable SHA-256: `d680b142b6029762d9a9deeade50494ed0ec5a7e7f68fbace193b2c760f163d0`.
Official GNU executable SHA-256: `e757daf64a597ca2da80f12ff6a0075c4e8260c6fcf871f8da979aef21a37db3`.
