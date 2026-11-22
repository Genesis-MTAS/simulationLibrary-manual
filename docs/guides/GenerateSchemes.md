# Guide: generate randomized decay schemes

Use `GenerateDecaySchemes` by itself when you only need the **XML scheme collection** and statistics, with no detector simulation.

## Inputs

You need `GenerateDecaySchemes.ini`. It can reference an existing `Decay.xml` and its nuclide files, or specify a synthetic parent with A, Z, and Qβ. The source generator supports β−/γ cascades; it does not generate neutron branches. The generator has a distinct skeleton spelling `mtas_354` (as opposed to the `mtas354` spelling in mixture binning).

**Recommended standalone working directory:** create a folder for a named project and a copy of the INI; never edit `config/defaults/GenerateDecaySchemes.ini` in place.

```bash
export TREE=/global/common/software/gen0018/mtas/mtas-simulation-v1.2.2
export PROJECT=/pscratch/sd/m/michals/MTAS/production/scheme_study_example
mkdir -p "$PROJECT/config" "$PROJECT/inputs"
cp "$TREE/config/defaults/GenerateDecaySchemes.ini" "$PROJECT/config/"
```

Review the copied INI. A compact illustrative excerpt (other sections must remain as supplied) is:

```ini
[run]
variations = 16
seed = 20261118
max_attempts_per_variation = 12
output_directory = ../schemes

[input]
decay_xml = /absolute/path/to/Decay.xml
```

The generator resolves relative `input.decay_xml` and `run.output_directory` **relative to the location of the INI**. For standalone use, the input manifest must still have accessible referenced XML files (do not move only `Decay.xml` if it uses sibling paths). For synthetic mode, make `decay_xml` blank and supply `[input] parent_A`, `parent_Z`, `qbeta_keV` and optional parent spin/parity.

## Validate and generate

```bash
"$TREE/bin/GenerateDecaySchemes" "$PROJECT/config/GenerateDecaySchemes.ini" --check-only
"$TREE/bin/GenerateDecaySchemes" "$PROJECT/config/GenerateDecaySchemes.ini"
```

The `--check-only` pass validates setup/model-table preparation without writing variations. For a substantive job, run the generator in a compute allocation, not as a long calculation on a Perlmutter login node.

## Expected output

```text
PROJECT/schemes/
  skeleton.csv
  variations.csv
  multiplicity.csv       # if configured
  scheme_000000/{Decay.xml,Parent.xml,Daughter.xml}
  scheme_000001/{Decay.xml,Parent.xml,Daughter.xml}
  ...
```

`variations.csv` records variation seeds, attempts, model choice and statistics; `multiplicity.csv` has gamma-cascade multiplicities. Not every variation is guaranteed scientifically acceptable merely because the generator succeeded: inspect feeding fractions, gamma branches, reachability and statistics against your target scientific distribution.

## Key scientific choices

Use [GenerateDecaySchemes program reference](../programs/GenerateDecaySchemes.md) and [config reference](../reference/Configurations.md) to review the trusted-level cutoff, inherited data preservation, β model, γ weighting and branch floor, gamma-only limits and number of requested variations. The default generator makes **one common skeleton and many variations**, not independent unrelated skeletons. If a variation cannot satisfy constraints after the configured attempts, the generator reports an error rather than relaxing constraints silently.

## Driver alternative

In an initialized schema-2 campaign, run only its first stage:

```bash
"/global/common/software/gen0018/mtas/root-env/bin/python3" \
  "$TREE/scripts/campaign_driver.py" run --run-dir "$RUN" --until schemes
```

This requires a **previously initialized full driver campaign** with valid source inputs; it does not mean the current driver can initialize a schemes-only campaign without supplying full-stage inputs. For a **new schemes-only project**, use the installed [production controller](NewCampaign.md) with `Campaign.ini` setting `scope = schemes`. The controller submits just scheme generation, with no response shards. This is different from the legacy schema-2 `--until schemes` mode.


**For jobs submitted through Slurm:** see [Check NERSC job status](CheckingJobs.md) for `squeue`, `sacct`, pending reasons, array tasks and logs.
