# Complete configuration reference — source review for production

**Source of truth for the scientific INIs:** `src/apps/GenerateDecaySchemes.cpp`, `src/sorting/SortConfig.cpp`, `src/mixture/PileupEngine.cpp`, `src/mixture/MixtureConfig.cpp`, `src/preprocessing/EnergyBinning.cpp`, `src/apps/PreprocessResponse.cpp`, `scripts/campaign_driver.py`, and `config/defaults/*` from the uploaded November 18, 2026 canonical source archive. The packed-worker interface is taken from the separately delivered `MTAS_PackedWorkers_v1.zip` subsequently installed on Perlmutter. Most options are unchanged by the subsequent v1.2.3 S+B patch, which modifies `SortEngine.cpp` and `PileupEngine.cpp` only. See [PileupDetailed](../physics/PileupDetailed.md) for its zero-MTAS β-triggered S+B rule; the original sources listed here are a historical snapshot.

**Defaults in the tables below are values in the supplied default/example INI**, not necessarily defaults of an executable invoked with no configuration. A blank means intentionally unspecified; `—` means not a parameter of that file. All paths and outputs must be reviewed for the actual isotope and campaign. Avoid modifying a campaign's frozen inputs after `init`; create a new campaign instead. **Canonical default INIs are read-only examples and may be the source for a new project's config, or the user may choose a previous approved project.** The new project must have its own copies, not live links to either source. See [configuration guide](../guides/ConfigureCampaign.md).

## 1. `GenerateDecaySchemes.ini`

The generator builds **one common level skeleton**, then attempts randomized variations. Its config parser also supplies fallback defaults when a key is absent. Option names are lowercased for this generator.

### `[run]` and `[input]`

| Key | Supplied default | Meaning / accepted values |
|---|---|---|
| `run.variations` | `10000` | Number of requested variations, integer ≥ 1. **Campaign `--cases` overrides this in its staged copy**. |
| `run.seed` | `12345` | Generator RNG seed (unsigned integer). **Campaign `--master-seed` determines its staged run seed**; inspect `RUN/config/GenerateDecaySchemes.ini`. |
| `run.max_attempts_per_variation` | `12` | Retry limit for a valid variation, integer 1–100; failure is explicit. |
| `run.output_directory` | `generated_schemes` | Destination of `scheme_000000/` etc.; campaign patches it to `RUN/schemes`. |
| `input.decay_xml` | `Decay.xml` | Manifest (and linked parent/daughter XML). Blank selects fully synthetic input. |
| `input.parent_A`, `input.parent_Z`, `input.qbeta_keV` | blank | Required for synthetic input, otherwise read from XML. |
| `input.parent_spin`, `input.parent_parity` | blank | Optional spin and parity for synthetic parent. |

### `[skeleton]` and `[preservation]`

| Key | Supplied default | Meaning / accepted values |
|---|---|---|
| `skeleton.binning_profile` | `mtas_354` | **Only** `mtas_354` currently accepted; different spelling from mixture's `mtas354`. |
| `skeleton.trusted_energy_keV` | `2500` | Boundary of trusted database region; nonnegative. |
| `skeleton.fill_start` | `above_highest_retained_level` | Only accepted value; begins beyond highest preserved level. |
| `skeleton.fill_every_available_bin` | `true` | When true add quasilevels at available nonuniform-grid bin centers above the retained region. |
| `skeleton.upper_energy_offset_keV` | `0` | Limit defaults to Qβ minus this nonnegative offset. |
| `skeleton.max_level_energy_keV` | blank | Positive explicit upper energy replaces default; blank parses as zero. |
| `skeleton.added_level_origin` | `Added` | Only accepted label for generated levels. |
| `preservation.keep_known_beta_fed_nonzero` | `true` | Previously positive trusted β feedings remain positive, with values allowed to vary. |
| `preservation.freeze_known_gamma_patterns` | `true` | Preserve known transition destinations *and* branching fractions. |
| `preservation.frozen_gamma_only_overrides_constraints` | `true` | **Must be true** in this version; inherited frozen γ-only levels supersede random caps. |

### `[beta]`, `[gamma]`, `[gamma_only]`

| Key | Supplied default | Meaning / accepted values |
|---|---|---|
| `beta.model` | `mixed` | `mixed`, `sparse_statistical`, `phase_space_weighted`, `clustered`. |
| `beta.fed_fraction_mode` | `model_dependent` | `model_dependent` or `uniform`; affects target fed-level fraction. |
| `beta.fed_fraction_min`, `beta.fed_fraction_max` | `0.10`, `0.50` | Applied to the **full skeleton size**, including ground and protected levels; the final active fraction can exceed the draw after mandatory promotions. Require 0 < min ≤ max ≤ 1. |
| `beta.min_fed_levels` | `1` | Minimum beta-fed level count, ≥1. |
| `beta.max_fed_levels` | `0` | Optional upper count; zero = no additional cap; mandatory known levels take priority. |
| `beta.min_intensity_percent` | `0.01` | Lower positive β branch intensity in **percent**, allowed 0–100. Zero feeding for non-fed levels remains possible. |
| `gamma.model` | `strength_weighted_sparse` | Only supported γ statistical model. |
| `gamma.min_branch_intensity_percent` | `1.0` | Positive minimum generated γ branch intensity in **percent**, 0 < value ≤ 100. |
| `gamma.max_outgoing_branches_per_level` | `15` | Maximum generated outgoing branches per level; 1–100. |
| `gamma.energy_scale_keV` | `1000` | Energy scale in approximate statistical strength weighting `Eγ³ exp(-Eγ/scale)`, >0. |
| `gamma.mean_outgoing_branches` | `3` | Scale of the broadened-Poisson candidate branch-count prior (not the exact final mean), 1–100. |
| `gamma.resample_destinations_each_variation` | `true` | Currently required to be `true`. |
| `gamma.resample_branching_each_variation` | `true` | Currently required to be `true`. |
| `gamma.validate_multiplicity_distribution` | `true` | Calculate multiplicity statistics and write `multiplicity.csv` (if enabled). |
| `gamma_only.probability_per_variation` | `0.30` | Probability of introducing 1 to max new γ-only-fed excited levels when allowed; 0–1. |
| `gamma_only.max_levels` | `2` | Maximum random γ-only-fed levels; nonnegative. |
| `gamma_only.max_cascade_fraction` | `0.10` | Maximum fraction of β cascades passing through ≥1 γ-only-fed level, 0–1 (not sum of populations). |

For exact model equations and source-level sampling order, see [β feeding](../physics/BetaFeedingModels.md), [γ transitions](../physics/GammaTransitionModels.md) and [scheme validation and multiplicity](../physics/DecaySchemeValidation.md). In particular, generated ordinary γ destinations require *direct β feeding* or ground state; the model is **not** a fully connected downward γ graph.

**Production review:** resolve trusted level boundary, generator β/γ randomization assumptions, sample count, and whether the existing 92Y-like skeleton setup matches the planned target. These settings determine the scientific training distribution, not merely performance.

## 2. `SortResponse.ini` (shared by standalone sorter and direct-sort)

The campaign uses the explicit file. `SortEngine.h` has different internal defaults for certain randomization flags if invoked without an INI. **Percentage fields use numeric percentages (`1.0` means 1%, not 100%)**.

| Section / key | Supplied default | Meaning / constraints |
|---|---|---|
| `sorting.silicon_threshold_keV` | `75` | β gate uses `max(SiTop, SiBottom)` against this nonnegative keV threshold. |
| `sorting.imo_threshold_keV` | `30` | Noncentral I/M/O processing threshold, nonnegative keV. |
| `sorting.central_correction_file` | `Sr90_Ratio_CC12toCC1_his.root` | Central efficiency correction ROOT; campaign patches path to staged correction. |
| `calibration.randomize` | `true` | Draw calibration perturbations once per output when true. |
| `calibration.central_max_percent` | `1.0` | Uniform random central scale variation within ±1%. |
| `calibration.imo_max_percent` | `1.0` | Uniform random I/M/O scale variation within ±1%. |
| `calibration.central_fixed_percent` | `0.0` | Fixed central shift when `randomize=false`. |
| `calibration.imo_fixed_percent` | `0.0` | Fixed I/M/O shift when `randomize=false`. |
| `resolution.randomize` | `true` | Draw experimental target FWHM variations once per output when true. |
| `resolution.central_max_percent` | `3.0` | Uniform experimental FWHM target perturbation ±3%, not intrinsic resolution. |
| `resolution.imo_max_percent` | `3.0` | Uniform I/M/O target FWHM perturbation ±3%. |
| `resolution.central_fixed_percent` | `0.0` | Fixed central target FWHM shift when not randomized. |
| `resolution.imo_fixed_percent` | `0.0` | Fixed I/M/O target FWHM shift when not randomized. |
| `random.smearing_seed` | `12345` | Per-event smearing/acceptance RNG seed, nonnegative and ≤32-bit unsigned maximum. |
| `random.conditions_seed` | `auto` | Separate RNG for choosing once-per-output conditions; explicit integer for reproducibility. Campaign patches deterministic integer. |

The source validates nonnegative thresholds, calibration/resolution maximum perturbations in `[0,100)`%, and fixed perturbations strictly above −100%. Once-per-response calibration and resolution variations remain fixed while processing the events. `--sili`, `--imo`, `--central`, `--seed`, `--conditions-seed` override INI values in the applicable executable. **Review both β threshold and I/M/O threshold against experimental reference spectra before production.**

## 3. `Pileup.ini` — exact 19-crystal model

| Section / key | Supplied default | Meaning / constraints |
|---|---|---|
| `pileup.seed` | `90731` | Integer or `auto` (nondeterministic); campaign patches deterministic integer. |
| `pileup.ss_1d_entries` | `1000000` | Accepted 3300 signal+signal entries, positive integer. |
| `pileup.sbkg_1d_entries` | `1000000` | Accepted 3300 signal+background entries, positive integer. |
| `pileup.ss_2d_entries` | `10000000` | Accepted 2D S+S statistics target, positive integer. |
| `pileup.sbkg_2d_entries` | `10000000` | Accepted 2D S+B statistics target, positive integer. |
| `pileup.min_2d_y_keV` | `10` | Shared minimum accepted Y for 3350 and 3351 2D pileup fills; 0 ≤ value < 15000 keV. |
| `pileup.reservoir_size` | `200000` | Retained event reservoir for sampling; 1–100,000,000. |
| `pileup.secondary_signal` | `ungated` | `ungated` or `triggered`; controls second signal event selection. |
| `pileup.max_attempts_per_target` | `100` | Bound on pair draws relative to target; 1–1,000,000. |
| `background.file` | `background.mtasbkg` | **MTASBKG1** exact crystal-resolved event file; campaign patches staged Scratch location. |
| `background.exclude_beta_coincident` | `false` | Optional whole-background-event selection; default preserves exported sample. |
| `background.min_total_keV` | `0` | Minimum background-event total energy, nonnegative. Alias `min_total_kev` accepted. |

The `1d_entries` and `2d_entries` are **accepted statistics targets, not pair-attempt counts**. `3350` may contribute several individual-crystal fills for one pair. Zero crystal deposits remain legitimate inputs to 19-crystal energy sums; the 2D fill threshold does not erase them. Old `ss_pairs`, `sbkg_pairs`, and `min_3351_c_keV` are rejected; a ROOT TH2 background approximation is not the current model.

**Production review:** the 10-million accepted 2D targets may dominate runtime; lower values must be justified by output-quality/variance tests, not by speed alone. Background file and event selections are scientific inputs.

## 4. `Mixture.ini` — composition, time and final physical binning

Supports **zero, one, or many** named `[contaminant:NAME]` sections. For schema-2 campaigns the file must be supplied even if no contaminants are used.

### Global composition and pileup fractions

| Section / key | Supplied example | Meaning |
|---|---|---|
| `mixture.seed` | `31072026` | RNG seed controlling realized random fractions; campaign overrides the effective per-case seed via `--mixture-seed`. |
| `mixture.write_unrebinned` | `true` in example; `false` in no-contaminant example | Whether source mixture writes high-resolution intermediate component histograms. **Set `false` for compact production.** This is distinct from driver `--keep-intermediate`. |
| `mixture.main_half_life_s` | omitted | Optional parent half-life override; positive seconds or `stable`/`inf`/`infinity`. |
| `pileup_fractions.ss_mode` | `random` | `fixed` or `random`. |
| `pileup_fractions.ss_value` | omitted | Fixed S+S fraction of final nonzero 3300 counts in 0–12 MeV. |
| `pileup_fractions.ss_min`, `ss_max` | `0.005`, `0.02` | Uniform draw bounds for S+S fraction (0.5–2% in example). |
| `pileup_fractions.sb_mode` | `random` | `fixed` or `random`. |
| `pileup_fractions.sb_value` | omitted | Fixed S+B fraction. |
| `pileup_fractions.sb_min`, `sb_max` | `0.002`, `0.01` | Uniform draw bounds for S+B fraction. |

For `fixed`, use `*_value`; for `random`, use `*_min` and `*_max`. Fractions must be in `[0,1]` and together with all contaminants must leave **a strictly positive main contribution**. Draws are retried, up to 10,000 attempts, if a valid combination is possible but not initially drawn. The final normalized 3300 total is tied to the original main nonzero 0–12 MeV integral. `0.20` means 20%, not 0.20%.

### Named contaminants `[contaminant:NAME]`

| Key | Default / example | Meaning |
|---|---|---|
| `mode` | `events` | `events` (existing ROOT `EventInfo` tree; source participates in event-based source-aware pileup) or `histograms` (precomputed 3300/3350/3351; added after pileup). |
| `file` | **required** | Input ROOT path. Standalone reader resolves relative paths against the INI; schema-2 campaign requires absolute file paths and records SHA-256 provenance. |
| `intensity_mode` | `fixed` | `fixed` or `random`. |
| `intensity` | `0` | Fixed fraction of final nonzero 3300 0–12 MeV counts. |
| `intensity_min`, `intensity_max` | `0.01`, `0.50` | Random fraction bounds (used when `intensity_mode=random`). |
| `half_life_s` | omitted | Optional explicit source half-life, otherwise read from embedded XML where supported; positive seconds or stable/infinity sentinel. |

Contaminant names become output directory names and must not contain slashes. **An event contaminant file is not automatically generated by `GenerateDecaySchemes` or the campaign driver.** Its production and validation are a separate prerequisite.

### Time and physical energy binning

| Section / key | Default | Meaning / constraints |
|---|---|---|
| `energy_time.enabled` | `true` | Generate energy–time histograms. Current ML preprocessing expects `energyTime` in final and each component. |
| `energy_time.time_range_mode` | `half_lives` | `half_lives` or `fixed`. |
| `energy_time.half_lives` | `5.0` | Requested duration as a multiple of main half-life, positive; default 5. |
| `energy_time.max_time_s` | `100.0` example (`0` C++ default) | Duration in seconds when `fixed`, strictly positive. |
| `energy_time.time_unit` | `auto` | `auto`, `ns`, `us`, `ms`, `s`, `min`, `h`, `day`, `year`. |
| `energy_time.time_bin_width` | omitted | Optional positive integer time width in chosen time units; otherwise auto-selected to approximate chosen duration using 354 equal integer-width bins. |
| `energy_binning.model` | `mtas354` | `mtas354`, `uniform`, `custom`; **different** spelling from generator skeleton `mtas_354`. |
| `energy_binning.uniform_width_kev` | `100` (struct default) | Uniform width ≥10 keV dividing 12000 keV exactly; currently raw 2D grid limits resolution to 10 keV. |
| `energy_binning.edges_file` | omitted | Required for `custom`; whitespace/comma-separated bin edges including 0 and 12000 keV, strictly increasing multiples of 10 keV; 1–1200 bins. |

`mtas354` generates 354 energy bins over 0–12 MeV. Time histograms are 354 time bins; their widths are integer multiples of the selected unit. If no valid finite half-life is known, use a scientifically justified `main_half_life_s` or `fixed` time range. With `enabled=false`, current final ML path may fail because it expects `energyTime`; **do not disable for production without an end-to-end test**.

## 5. `Preprocess.ini` — shared-log ML outputs

| Section / key | Default | Meaning |
|---|---|---|
| `preprocessing.reference_width_kev` | `10` | Reference energy width for density correction, positive finite. |
| `preprocessing.width_2d` | `both` | `both` (recommended), `x_only`, `y_only`, `none`; `energyTime` applies energy X-width correction only, not time-bin width. |
| `preprocessing.log_reference_density` | `1` | Common positive `D0` density in `log(1 + D/D0)` mapping. |

The **same** `D0` and final-family density maximum are used for all weighted components in a histogram family; components are not independently normalized. Only the final maximum maps to one. The transform is reversible, and component additivity must be checked after inversion.

## 6. Underlying schema-2 `campaign_driver.py` and command templates

The driver accepts command-line flags (not an INI). Its init-only values are frozen when a new run directory is created.

| Subcommand / flag | Default | Meaning |
|---|---|---|
| `init --tree` | required | Canonical software tree. |
| `init --run-dir` | required | **New** immutable campaign directory; do not reuse an old run. |
| `init --decay-xml` | required | Nuclear decay manifest and neighboring XMLs. |
| `init --background-file` | required | Exact background MTASBKG1 file. |
| `init --central-file` | required | Central correction ROOT file. |
| `init --mixture-file` | required in schema 2 | Composition INI, even if it has zero contaminants. |
| `init --commands` | required | JSON argv templates for response/clean/preprocess/validate. |
| `init --cases` | `1` | Number of randomized schemes and responses (100,000 planned). |
| `init --events` | `1000000` | Events per case, not case count. |
| `init --batch` | `100000` | Per-process event composition batch size. |
| `init --master-seed` | `20261117` | Master RNG seed for reproducible per-case streams. |
| `init --stage-mode` | `link` | `link` or `copy` for staged small input files. |
| `init --dry-run` | off | Check initialization without creating normal campaign outputs. |
| `init --keep-intermediate` | off | **Leave off** for production: validated intermediate ROOT deleted by default. |
| `plan --run-dir` | required | Existing campaign to inspect. |
| `plan --case-id` | `0` | Which case command sequence to print. |
| `plan --audit` | off | Input and binary integrity audit. |
| `run --run-dir` | required | Execute/restart existing campaign or a case. |
| `run --case-id` | absent | Run one case if supplied; without it, sequential case execution (not cluster-scale scheduling). |
| `run --until` | `validate` | Stop after one of `schemes`, `response`, `clean`, `preprocess`, `validate`. |
| `run --retry-failed` | off | Explicitly quarantine/retry failed/interrupted stages; investigate first. |
| `status --run-dir` | required | Print passed/failed/running/pending stage counts. |

`config/defaults/campaign_commands.json` contains **argv lists**, not shell command strings. Its supported expansion placeholders include `{tree}`, `{python}`, `{decay_xml}`, `{binary_library}`, `{sort_ini}`, `{pileup_ini}`, `{mixture_ini}`, `{preprocess_ini}`, `{central_root}`, `{intermediate_root}`, `{physical_root}`, `{ml_root}`, `{response_seed}`, `{smearing_seed}`, `{conditions_seed}`, `{mixture_seed}`, `{events}`, `{batch}`, `{case}`. `pileup_seed` is applied to the per-case `Pileup.ini`. The default command templates invoke `GenerateResponse --direct-sort`, `CleanPhysicalResponse`, `PreprocessResponse --decay-xml`, and `validate_case.py`.

**Current supported per-project workflow (production v1.2.3):** use `production_project.py create` to copy **six** INIs from canonical defaults or a previous project. Edit them under `PROJECT/config/`, run `preflight`, and `freeze`. The production controller uses the extended `campaign_driver.py init --config-dir PROJECT/config`, stages the reviewed INIs into the frozen run, and records their SHA-256 hashes. **The canonical defaults are not live configuration files.** The older schema-2-only `campaign_driver.py init` remains useful for legacy campaigns. See [New campaign](../guides/NewCampaign.md).


## 7. Legacy single-node packed-worker launcher

`packed_campaign.py --run-dir RUN [--workers N] [--dry-run] [--retry-failed]` defaults to **256 concurrent case processes**, accepts 1–256, and operates on **one allocated CPU node**, using a file lock to prevent two launchers sharing the same campaign directory. The Slurm script requests one node, one task, 256 logical CPUs, multithreading, and defaults to a two-hour wall time (can be overridden with `sbatch --time`). It measures full-node case throughput in `RUN/jobs/packed_summary.json`. See [Packed workers](../guides/PackedWorkers.md).

**For new multi-node campaigns, use `production_project.py` and `production_shard.py` instead.** The older packed launcher remains available for single-node benchmarks. Do not launch several instances of that older whole-run launcher against the same campaign.


## 8. Options not yet configurable by user files

These are presently source constants / interface constraints, **not INI keys**: `GenerateResponse.cpp` `minLibraryKeV=10`, `maxLibraryKeV=10000` (matching the currently available particle library), grid 1 keV up to 1000 and 10 keV above; raw SortEngine histogram range to 15000 keV; mixture and decay-matrix final axis 0–12000 keV; current fixed 354-bin time-axis structure. Histogram **creation versus saving** controls remain an agreed outstanding task: do not claim that every intermediate/internal histogram can presently be switched off independently.

For reviewing these options before any new large run, use the [configuration decision worksheet](ProductionConfigurationReview.md). For execution readiness, use the [100k operations guide](../guides/Production100k.md).

## 9. `Campaign.ini` (new projects, production controller v1.2.3)

The controller parses `PROJECT/config/Campaign.ini`, independently copied from the software's default or a previous campaign. Frozen runs preserve the exact reviewed bytes, plus independent copies of the five scientific INIs. Unknown keys/sections fail validation; **do not add arbitrary keys and expect them to be ignored.**

| Section / key | Template default | Meaning / constraints |
|---|---|---|
| `campaign.cases` | `1` | Number of randomized case IDs, `1..1,000,000`. |
| `campaign.events` | `1000000` | Primary response events per case, integer >0. |
| `campaign.batch` | `100000` | Per-process response composition batch, integer >0. |
| `campaign.master_seed` | `20261118` | Nonnegative integer used for reproducible scheme/response streams. |
| `campaign.scope` | `full` | `schemes` (XML only), `response` (intermediate), `physical` (through cleaned physical), or `full` (physical+ML+validation). |
| `campaign.stage_mode` | `link` | `link` or `copy` for staging small files; large binary library is referenced in place. |
| `inputs.decay_xml` | blank | Existing absolute path to parent decay `Decay.xml` and linked files. |
| `inputs.background_file` | blank | Existing absolute path to `MTASBKG1` background. |
| `inputs.central_file` | blank | Existing absolute path to central correction ROOT. |
| `execution.account` | `gen0018` | Slurm account; approved alphanumeric `-._` identifier. |
| `execution.qos` | `regular` | Slurm QOS; verify availability on system before submit. |
| `execution.workers` | `256` | Independent processes per CPU-node allocation, `1..256`. Measured baseline for the full 92Y+92Sr workload, not guaranteed optimal. |
| `execution.shard_size` | `1024` | Consecutive disjoint cases per array task; >0; shard count ≤1000. |
| `execution.max_active_nodes` | `4` | Maximum simultaneous shard allocations via Slurm array throttle, 1..1000. |
| `execution.scheme_walltime` | `00:20:00` | Slurm scheme job wall time, `HH:MM:SS` or `DD-HH:MM:SS`. |
| `execution.shard_walltime` | `00:45:00` | Wall time per shard allocation, same syntax; determine from observed workload. |

`create` defaults to a **zero-contaminant** `Mixture.ini` example; deliberately replace/edit it if contaminants are part of the experiment. `freeze` stages the reviewed INIs and creates `runs/run_NNNN`; no run reads the editable project INIs afterward. Only approved new scopes are `schemes`, `response`, `physical`, `full`. Sorting an existing EventInfo ROOT is currently a **standalone `SortResponse` workflow**, not a production-controller scope.

**Known partial-scope constraint:** `preflight` currently still requires valid `decay_xml`, `background_file`, and `central_file` paths even for schemes-only or response-only projects. `scope=response`/`scope=physical` retain intermediates; `scope=full` deletes only after validation. See [New campaign](../guides/NewCampaign.md) and [Recovery](../guides/Recovery.md).

## 10. Production controller CLI and source verification

| Command | Supported arguments | Purpose |
|---|---|---|
| `create` | `--tree`, `--project-dir`, optional `--from-config` | Create a new editable project with independent copies. |
| `preflight` | `--tree`, `--project-dir` | Validate paths/configs/sharding; print planning estimates. |
| `freeze` | `--tree`, `--project-dir`, optional `--run-id` | Immutable `run_NNNN`, full input and orchestration hashes. |
| `submit` | `--run-dir`, optional `--dry-run` | Schemes once, then dependent Slurm array of non-overlapping shards. |
| `status` | `--run-dir` | Scheme, shard and failure status. |
| `resume` | `--run-dir`, required `--shards`, optional `--retry-failed`, `--dry-run` | Explicitly retry selected shards after prior job exits. |
| `complete-submission` | `--run-dir`, optional `--dry-run` | Recover after partial Slurm submission without duplicating schemes. |

The production controller hashes the frozen six INIs, records orchestration script hashes and verifies the staged input fingerprint before submission. A read-only SQLite scheme index (`jobs/scheme_index.sqlite`) avoids rereading a full 100,000-scheme manifest for each case; integrity checks remain enforced.

**Current unimplemented physics-feature request:** independent switches for histogram **creation** versus **saving** are not fully exposed for all histogram families; internal histograms needed to form final `physical.root` and `ml.root` are generated by existing processing modules. Keep any new creation/saving optimization independent of the scientific invariants and test on references first.

## 11. Model and configuration development priorities

The first requested *post-production scientific development* is Bateman-chain evolution and daughter grow-in (not currently implemented). Review [Time evolution and Bateman](../physics/TimeEvolutionDetailed.md) before adding an apparent `daughter_half_life` setting: a single exponential contaminant is **not** daughter grow-in.
