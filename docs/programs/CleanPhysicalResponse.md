# CleanPhysicalResponse

**Source:** `src/apps/CleanPhysicalResponse.cpp`. This is a **copy-and-validate** operation on an already weighted physical ROOT mixture, not a physics simulation or renormalization step.

```bash
bin/CleanPhysicalResponse intermediate.root physical.root
```

Exactly two positional paths are required; it refuses an output path identical to the input. It reads the input `final/` group, `components/main`, `components/pileup_ss`, `components/pileup_sbkg` and each directory found below `components/contaminants/`. For each it requires `3300`, `3350`, `3351` and `energyTime`.

Before writing, it verifies regular histogram bins satisfy `final = sum(component)` with tolerance `1e-8*max(1,abs(final))`. It clones those four histograms into each output group without changing values, energy binning or amplitude, and checks the copied file again after reopening it. It copies root-level `TObjString` metadata into `metadata/`, adds `CleanPhysicalConditions`, and omits `raw_sources`, `unrebinned`, diagnostic pileup keys, noncanonical aggregates and extra ROOT cycles.

## Standard output

```text
physical.root
  final/3300,3350,3351,energyTime
  components/main/3300,3350,3351,energyTime
  components/contaminants/<name>/3300,3350,3351,energyTime
  components/pileup_ss/3300,3350,3351,energyTime
  components/pileup_sbkg/3300,3350,3351,energyTime
  metadata/{...TObjString metadata...,CleanPhysicalConditions}
```

All elementary components are already weighted physical **linear counts**. Downstream code must not independently normalize them. In a schema-2 campaign, this output is retained, while `intermediate.root` is removed only after final validation succeeds. See [PreprocessResponse](PreprocessResponse.md) and [output reference](../reference/OutputFormats.md).
