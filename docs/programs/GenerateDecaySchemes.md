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

## Detailed statistical models (v1.2.3 source review)

The preceding description is a program reference. The actual sampling algorithms, distributions, numerical constants, and validation equations are documented separately to avoid conflating these assumptions with nuclear-structure theory:

- [β-feeding generation — selection, intensities and floors](../physics/BetaFeedingModels.md)
- [γ-transition generation — weights, widths and γ-only-fed levels](../physics/GammaTransitionModels.md)
- [Full algorithm — preservation, cascade statistics, validation and reproducibility](../physics/DecaySchemeValidation.md)

**Key implementation distinctions:** known positive β feedings stay *present* but not *numerically fixed*; default frozen known γ patterns preserve **both** connections and numerical branching fractions; generated ordinary γ destinations are restricted to lower *directly β-fed* levels or ground state (with frozen and forced-γ-only exceptions). `PhaseSpace()` is a coarse β feeding prior, not the emitted β spectrum from `GenerateResponse`.

**Source identity:** these model pages were checked against `src/apps/GenerateDecaySchemes.cpp` from the v1.2.3 source release, SHA-256 `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`.
