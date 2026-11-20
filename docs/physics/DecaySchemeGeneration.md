# Randomized decay-scheme model

**Implemented in:** `src/apps/GenerateDecaySchemes.cpp` (`LoadScheme`, `CompleteSkeleton`, `PhaseSpace`, `OneVariation`, `WriteVariation`).

The generator creates one fixed level-energy skeleton per run and resamples β feeding and γ decay networks over that skeleton. It is deliberately a **phenomenological coarse-grained ensemble generator**, not a quantum-number-constrained microscopic nuclear-structure calculation.

## Known levels and added quasilevels

Known levels in the trusted region are preserved. The highest retained level governs the start of added bins, regardless of the numeric cutoff if a level lies below it. In the default 354-bin MTAS grid, available higher-energy bin centers become candidate effective levels. Known levels may share a bin; the one-per-bin rule applies to added quasilevels. Only physically reachable levels are exported in each daughter XML.

## β population

The number of levels receiving direct β feeding is chosen within configured fractions of all accessible skeleton levels. Originally beta-fed known levels remain fed if `keep_known_beta_fed_nonzero=true`, although their intensities may change. A positive floor in **percent** is applied to every nonzero branch before final normalization to 100%; direct zero-feeding remains zero. The approximate allowed phase-space prior is computed once per level, and is distinct from the relativistic spectral sampler in the response program.

The `sparse_statistical`, `phase_space_weighted` and `clustered` strength models offer different ensemble priors. The `mixed` mode selects among them on each realization. These modes are assumptions chosen for synthetic variation; they do not imply experimental validation of that prior distribution.

## γ paths

For each generated excited level, destinations lie at lower excitation energies. Weights use `E_gamma^3 exp(-E_gamma / energy_scale_kev)` and independent fluctuating widths. Outgoing branch number, fraction floor and minimum intensity limits apply to generated branches only. Fixed known γ transitions have priority and retain their original destinations/probabilities. Each complete sampled scheme is explicitly checked for finite total intensity and cascade-population constraints.

Gamma-only-fed levels are beta-unfed excited states reached via γ cascades. The constraint on their total `max_cascade_fraction` concerns the probability of visiting **at least one**, not a sum of populations that double counts cascades. Existing frozen gamma-only levels override synthetic caps when configured.

## Reproducibility and limitations

A master seed and variation index determine each scheme's RNG stream. Per-variation rejects are bounded by `max_attempts_per_variation`. No neutron branching or electron conversion sampling is generated; known conversion attributes may be preserved as metadata. Added levels have unknown spin/parity. All variations in one invocation share a skeleton, which is useful for aligned ML targets.
