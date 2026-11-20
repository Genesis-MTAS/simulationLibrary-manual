# GenerateDecaySchemes

**Source:** `src/apps/GenerateDecaySchemes.cpp` (independent C++17/libxml2 executable). Generates a common excitation-level skeleton once, then many randomized β−/γ schemes with per-variation metadata.

## Invocation and paths

```bash
bin/GenerateDecaySchemes /path/to/GenerateDecaySchemes.ini --check-only
bin/GenerateDecaySchemes /path/to/GenerateDecaySchemes.ini
```

`--check-only` loads the input, builds the common skeleton and model tables, and exits before creating variations. The only accepted CLI switch is `--check-only`. Relative `input.decay_xml` and `run.output_directory` paths are interpreted relative to the INI **directory**. For synthetic input leave `decay_xml` empty and supply parent A/Z and Qβ.

## Scheme-generation algorithm

1. Read `Decay.xml` and referenced parent/daughter nuclide XML (or synthesize parent data). Preserve known levels in the trusted energy region and selected initial β and γ information.
2. Populate unoccupied bins above the highest retained level with effective added levels at centers of the fixed MTAS 354-bin energy grid, subject to the upper excitation cutoff. Added levels carry `Origin=Added` and unknown spin/parity.
3. Precompute approximate β phase-space integrals at all excitation energies and per-pair γ weighting factors. The β prior integrates a simple Coulomb-corrected allowed phase-space proxy over 160 midpoint steps, **not** the detailed β sampler used downstream.
4. For each variation, derive a reproducible `mt19937_64` seed from the master seed and variation index; sample an active β-fed set and strengths, meeting positive-feeding and minimum intensity requirements.
5. Generate downward γ branches with a phenomenological `Eγ^3 exp(-Eγ / scale)` destination prior and fluctuating strength weights; frozen experimental branches are preserved when configured. The generated network is acyclic because γ transitions go to lower levels.
6. Enforce gamma-only-fed level and cascade-population constraints, with inherited frozen gamma-only levels taking precedence. Propagate feeding through the decay network to compute multiplicity probabilities, including direct feeding to ground state.
7. Save pruned, physically reachable `Parent.xml`/`Daughter.xml`, a `Decay.xml` manifest and CSV reports. Abort with a diagnostic if the bounded number of attempts fails.

## Configuration reference

These keys are explicitly parsed in `ReadOptions()`; unspecified values shown are source defaults. Some default INI values are also repeated in `config/defaults/GenerateDecaySchemes.ini`.

| Section | Keys | Meaning / source defaults |
|---|---|---|
| `[run]` | `variations`, `seed`, `max_attempts_per_variation`, `output_directory` | 10000, 12345, 12 (maximum accepted 100), `generated_schemes` |
| `[input]` | `decay_xml`, `parent_a`, `parent_z`, `qbeta_kev`, `parent_spin`, `parent_parity` | `Decay.xml`; synthetic parent fields used when empty |
| `[skeleton]` | `binning_profile`, `trusted_energy_kev`, `fill_start`, `fill_every_available_bin`, `upper_energy_offset_kev`, `max_level_energy_kev`, `added_level_origin` | `mtas_354`, 2500, `above_highest_retained_level`, true, 0, unset/Qβ-derived, `Added` |
| `[preservation]` | `keep_known_beta_fed_nonzero`, `freeze_known_gamma_patterns`, `frozen_gamma_only_overrides_constraints` | All true; final field required true in this version |
| `[beta]` | `model`, `fed_fraction_mode`, `fed_fraction_min`, `fed_fraction_max`, `min_fed_levels`, `max_fed_levels`, `min_intensity_percent` | `mixed`, `model_dependent`, 0.1, 0.5, 1, 0 (uncapped), 0.01 percent |
| `[gamma]` | `model`, `min_branch_intensity_percent`, `max_outgoing_branches_per_level`, `energy_scale_kev`, `mean_outgoing_branches`, `resample_destinations_each_variation`, `resample_branching_each_variation`, `validate_multiplicity_distribution` | `strength_weighted_sparse`, 1%, 15, 1000 keV, 3; final three true; the two resample options must be true |
| `[gamma_only]` | `probability_per_variation`, `max_levels`, `max_cascade_fraction` | 0.30, 2, 0.10 |

### β models

`sparse_statistical`: draws sparse independent strength fluctuations; `phase_space_weighted`: weights them with approximate β phase space; `clustered`: creates energy-localized feeding strengths; `mixed`: randomly chooses among the three each variation. `fed_fraction_mode` is `model_dependent` or `uniform`. See [decay-scheme physics](../physics/DecaySchemeGeneration.md).

### γ model restrictions

Only `strength_weighted_sparse` is accepted. `resample_destinations_each_variation` and `resample_branching_each_variation` **must both be true**. Preserved experimental branches can fall below the generated intensity floor or exceed the generated maximum branch count; they are not rewritten to satisfy synthetic constraints.

## Outputs

```text
generated_schemes/
  skeleton.csv
  variations.csv
  multiplicity.csv                  # if validate_multiplicity_distribution=true
  scheme_000000/{Decay.xml,Parent.xml,Daughter.xml}
  scheme_000001/{Decay.xml,Parent.xml,Daughter.xml}
  ...
```

`variations.csv` includes seed, attempts, chosen β model, fraction fed, gamma-only metrics and mean γ multiplicity. `multiplicity.csv` contains probabilities for 0–32 γ rays plus a 33+ tail. Per-variation seeds are recorded; the generator does not use current time for these seeds.

## Limits / cautions

- β− and γ-only de-excitation: this generator does **not** invent neutron emission or a full spin/parity-coupled photon-strength model.
- The 354-bin skeleton is fixed for a generator invocation; effective quasilevels should not be interpreted as discovered discrete nuclear levels.
- A failed variation aborts the run rather than silently relaxing constraints. Large runs generate **three XML files per case**, plus CSV tables.
- Test: `tests/fixtures/legacy_package_tests/MTAS_DecaySchemeMatrix_v1/` includes representative XML; campaign tests exercise scheme generation structurally.

## Source-level detail: β population and generated γ widths

`ReadOptions()` reads INI keys and enforces explicit value constraints. Unrecognized keys in the generator's lightweight INI map are not all rejected; therefore a typo may quietly use the source default. The documented keys should be reviewed carefully for real campaigns. In contrast, `MixtureConfig.cpp` rejects unknown sections and option names.

`CompleteSkeleton()` constructs one skeleton for the entire invocation. The generator evaluates a coarse allowed β phase-space proxy once per level using **160 midpoint integration samples**, then normalizes the resulting weights to their maximum. For every variation, `mixed` chooses one of three β strength models, and `fed_fraction_mode = model_dependent` changes the distribution of the target fed fraction depending on the selected model. Mandatory originally fed known levels take precedence over an undersized target; reachable frozen transitions may cause additional states to be promoted to beta-fed unless intentionally protected as gamma-only.

In the β intensity assignment, active strengths are gamma-distributed, with shape `0.35` for `sparse_statistical` and `1` otherwise; the phase-space or cluster model changes their weights. The positive intensity floor `min_intensity_percent` applies only to *active* branches, in **percent**, and the remainder is redistributed proportionally. Exact zeros remain zero. If the number of active branches makes the floor impossible, generation fails rather than relaxing the rule.

The number of newly generated outgoing γ branches is drawn from a broadened Poisson-like prior and limited by the configured maximum and intensity floor. Candidate destinations are lower-energy levels with weights proportional to `Eγ³ exp(-Eγ / energy_scale_kev)`. Partial-width strengths use a gamma distribution with shape `0.5` (Porter–Thomas-like fluctuations). Low-intensity generated branches are pruned and the survivors renormalized. Frozen experimental branches are not rewritten to satisfy synthetic lower bounds. All β-fed excited states must end up with complete first-γ branching before their XML is emitted.

`OneVariation()` retries at most `max_attempts_per_variation` times; per-variation seeds use `master_seed + index × 0x9e3779b97f4a7c15` (64-bit arithmetic) and are written in `variations.csv`. `Daughter.xml` omits unreachable levels and zero-intensity transitions, but the common full skeleton remains available in `skeleton.csv` for comparing target schemes.

**Scientific interpretation:** the γ strength weighting and β statistical choices are synthetic priors, not validated microscopic models of nuclear transition rates. The generated XML format preserves the interface needed by detector-response simulation. See [the decay-generation model](../physics/DecaySchemeGeneration.md).
