# Randomized decay-scheme model — overview

**Implemented in:** MTAS Simulation Library v1.2.3, `src/apps/GenerateDecaySchemes.cpp`. **Reviewed source SHA-256:** `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`.

`GenerateDecaySchemes` builds **one fixed excitation-energy skeleton** and many randomized β− feeding and γ de-excitation schemes on that skeleton. It is a **phenomenological coarse-grained ensemble generator**, not a microscopic nuclear-structure model or a fitted evaluation of transition probabilities.

For the complete equations and selection rules, use these dedicated chapters:

| Chapter | Questions answered |
|---|---|
| **[β-feeding models — full implementation](BetaFeedingModels.md)** | How is the β-fed fraction chosen? How do `sparse_statistical`, `phase_space_weighted`, `clustered` and `mixed` select levels and assign intensities? Which known β branches remain present? What exactly is the phase-space integral and positive intensity floor? |
| **[γ-transition model — full implementation](GammaTransitionModels.md)** | How are γ destinations selected? What does the \(E_\gamma^3 e^{-E_\gamma/E_s}\) weight mean? How are branch counts and partial widths sampled, weak branches pruned, and γ-only-fed levels introduced? Which experimental γ intensities remain fixed? |
| **[Construction, validation and cascade statistics](DecaySchemeValidation.md)** | In what order are β and γ patterns sampled? Which variations fail? How are γ multiplicity, γ-only cascade probability, and path counts calculated? How are the RNG seeds and output XMLs constructed? |

## Skeleton and preservation rules

Known daughter levels within the configurable trusted energy region are retained; new effective levels occupy the centers of unoccupied higher-energy bins on the fixed nonuniform MTAS 354-bin energy grid. The first added level lies above the **highest retained known level**, even if the numerical trusted-energy cutoff is higher. Added levels have unknown spin/parity. The output XML includes only the daughter levels reachable in each variation, while `skeleton.csv` retains the full common skeleton.

**β and γ are preserved differently.** With the supplied defaults, every originally positive trusted β branch remains positive but its numerical intensity may change. By contrast, the destinations **and branching probabilities** of the known γ transitions are frozen. Generated γ patterns apply the stochastic model described below.

## Model summary

- **β feeding:** `sparse_statistical` produces sparse, highly uneven feeding; `phase_space_weighted` adds an approximate allowed phase-space prior; `clustered` favors randomly chosen excitation-energy regions; `mixed` randomly chooses one of these for each attempted scheme. Selection and intensity generation are separate stages.
- **γ generation:** `strength_weighted_sparse` is the only implemented γ model. It draws a limited number of downward destinations using a phenomenological transition-energy weight, then fluctuates relative widths using a shape-½ gamma distribution and prunes low-intensity branches. **It does not connect every level to every lower level:** ordinary generated destinations are restricted to directly β-fed lower levels and the ground state, with explicit exceptions for forced γ-only-fed levels and frozen experimental transitions.
- **Constraints:** Positivity, branch floors, branch-count bounds, γ-only populations and complete first-γ branching for β-fed excited levels are validated. Failing samples are retried up to a bounded number of attempts. γ multiplicity is reported rather than constrained to a target distribution.

## Distinguish β feeding from the electron energy spectrum

The generator assigns \(b_i\), the integrated probability of populating daughter level \(i\) by β decay. The response program later samples the emitted electron's kinetic energy using a different calculation. See [β-electron spectra](BetaSpectra.md). The generator does not produce β-delayed neutron transitions, apply nuclear-spin selection rules to invented γ branches, or synthesize internal-conversion electrons.

**Practical references:** [GenerateDecaySchemes executable](../programs/GenerateDecaySchemes.md), [generate schemes guide](../guides/GenerateSchemes.md), and [configuration reference](../reference/Configurations.md).
