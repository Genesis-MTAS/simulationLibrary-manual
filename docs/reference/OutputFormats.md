# ROOT and XML output reference

## Raw `EventInfo` ROOT

When writing event-level responses, `EventInfo` carries per-event deposits in central `C`, 6 I, 6 M, 6 O and `SiTop`/`SiBottom` channels. **No-response events can exist** in the raw tree and must not be collapsed into positive detector energy. This differs from a β-gated 3300 histogram.

## Initial sorted response

`3300` total MTAS; `3305` individual IMO deposits; `3310` central; `3350` total vs 18 individual IMO crystal deposits; `3351` total vs central. For raw histograms, 3305/3350 and 3310/3351 can contain zero-Y entries whenever total MTAS energy is positive. `3300` excludes total-zero events.

## Clean `physical.root`

```text
final/3300
final/3350
final/3351
final/energyTime
components/main/{3300,3350,3351,energyTime}
components/contaminants/<NAME>/{3300,3350,3351,energyTime}
components/pileup_ss/{3300,3350,3351,energyTime}
components/pileup_sbkg/{3300,3350,3351,energyTime}
metadata/*
```

All counts are already weighted *additive contributions*. For each bin, `final = main + Σ contaminants + S+S + S+B`. No default redundant aggregate branches. Intermediate diagnostics and unrebinned spectra stay out of the clean file.

## Final `ml.root`

```text
final/{3350,3351,energyTime}
final/decaySchemeMatrix
final/DecaySchemePathsCSV
final/DecaySchemeMatrixConditions
components/main/{3350,3351,energyTime}
components/contaminants/<NAME>/{3350,3351,energyTime}
components/pileup_ss/{3350,3351,energyTime}
components/pileup_sbkg/{3350,3351,energyTime}
metadata/{Transform_3350,Transform_3351,Transform_energyTime,
          PreprocessingConditions,PreprocessingReport}
```

Only 3350/3351/energyTime are shared-log transformed. `decaySchemeMatrix` is an untransformed probability matrix. The common transform metadata makes each component individually invertible.

## Campaign files

Per run, `schemes/scheme_NNNNNN/` contains the three XML files, and `cases/case_NNNNNN/` contains configs, logs, stage status JSON, final outputs and `validation.json`. Schema-2 campaigns normally delete `outputs/intermediate.root` *after* validation; its disposition is recorded for restarts. The exact XML input and random seeds remain traceable.
