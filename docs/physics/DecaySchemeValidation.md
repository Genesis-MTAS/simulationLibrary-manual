# Constructing, validating and enumerating generated decay schemes

**Source verified against:** MTAS Simulation Library v1.2.3, `src/apps/GenerateDecaySchemes.cpp` (`LoadScheme`, `CompleteSkeleton`, `FrozenGammaOnly`, `OneVariation`, `Populations`, `GammaOnlyStats`, `Multiplicity`, `ReachableDaughterLevels`, `WriteVariation`, `main`). See the linked chapters for the precise [β-feeding priors](BetaFeedingModels.md) and [γ-transition priors](GammaTransitionModels.md).

This page describes the **complete algorithm**, including preservation rules, rejection criteria, cascade statistics, XML pruning and reproducibility. All statements describe the existing implementation; no changes to the generator are proposed by this documentation update.

## 1. Per-run skeleton and common weights

`GenerateDecaySchemes` reads a `Decay.xml` manifest plus the β-minus parent and daughter XML, or uses synthetic parent parameters when no manifest is supplied. It retains the daughter levels within `skeleton.trusted_energy_keV`, including the ground state, and eligible known γ transitions between retained levels. Known positive β feedings to retained levels are tracked separately. `Fake` transitions are skipped.

If `fill_every_available_bin=true`, the code adds effective daughter levels above the **highest retained known level** at unoccupied centers of the fixed 354-bin MTAS grid, up to the configured excitation cap (at or below \(Q_\beta\)). These are shared across all variations. The code precomputes normalized β phase-space proxies \(\phi_i\) and pairwise relative γ weights \(w_{ij}\) for this skeleton **once**.

**Preservation is asymmetric:** `keep_known_beta_fed_nonzero=true` holds original positive β transitions **present but not numerically constant**; `freeze_known_gamma_patterns=true` holds original known γ **destinations and numerical fractions constant**. The latter can create inherited γ-only-fed levels that override synthetic γ-only constraints. The detailed rules are in the two model chapters.

## 2. One attempted variation

Each attempt follows the source's `OneVariation()` order:

1. Choose the β model (`mixed` randomly picks one of three model classes) and determine whether a frozen inherited γ-only set applies.
2. Optionally select a small number of new γ-only-fed targets, protecting them from direct β feeding.
3. Draw the number and identities of β-fed levels; activate required known feedings and additional levels reached through frozen γ edges; generate β strengths and apply the positive intensity floor.
4. Generate outgoing γ patterns for all nonfrozen excited levels, including explicitly forced links to newly requested γ-only targets; copy frozen patterns without reweighting.
5. Propagate β populations, compute the actual γ-only set and the probability of visiting it; enforce inherited-versus-synthetic restrictions.
6. Validate γ directions, positivity, generated intensity floors, outgoing branch counts, branch normalization and complete first-γ branching for directly β-fed excited states.
7. Calculate exact expected γ multiplicity; optionally calculate the full 0–32/33+ γ-multiplicity probability distribution. If all checks succeed, return the variation.

An unsuccessful attempt throws an error internally and consumes more random numbers from the **same per-variation RNG stream**. The program tries at most `run.max_attempts_per_variation` attempts (default 12) and fails explicitly if none succeeds; it does not silently relax constraints.

## 3. Population propagation on the directed cascade graph

Let \(b_i\) be the direct β fraction to level \(i\), and let \(g_{ij}\) be the nonzero γ branching fraction from \(i\) to a lower level \(j<i\). Because the γ graph only points downward, the total **expected number of visits** (population) to each level, \(P_i\), is obtained by initializing \(P_i=b_i\) and processing sources from high to low energy:

\[
P_j\;\leftarrow\;P_j+P_i\,g_{ij}\qquad\text{for each edge }i\to j.
\]

This is a sum over visits to individual levels, not generally the probability of visiting **at least one** level from a collection. In particular, the γ-only cascade fraction uses the separate exact dynamic-programming probability described in [γ-only levels](GammaTransitionModels.md#exact-definition-of-the-cascade-share-constraint), avoiding double-counting paths that visit multiple special levels.

## 4. Exact γ-multiplicity distribution

For a starting level \(i\), define \(D_i(k)\) as the probability that its de-excitation cascade emits exactly \(k\) γ transitions. A terminal level (including the ground state) has \(D_i(0)=1\). For levels with outgoing γ edges,

\[
\boxed{D_i(k)=\sum_{j<i}g_{ij}D_j(k-1)\qquad(k\ge1).}
\]

The complete β-decay multiplicity distribution is

\[
\boxed{\Pr(N_\gamma=k)=\sum_i b_i D_i(k).}
\]

When `gamma.validate_multiplicity_distribution=true`, `Multiplicity()` evaluates bins \(k=0,\ldots,32\) and an overflow probability \(\Pr(N_\gamma\ge33)\), recorded in `multiplicity.csv`. Thus direct ground-state β feeding contributes to the **zero-γ** bin, and long cascades are not discarded merely because the reported histogram stops at 32.

The exact mean number of γ transitions is calculated **independently of the 32-transition reporting cutoff** using the expected remaining cascade length \(M_i\):

\[
M_i=\sum_{j<i}g_{ij}\,(1+M_j),\qquad
\boxed{\langle N_\gamma\rangle=\sum_i b_i M_i.}
\]

This mean appears in `variations.csv` whether or not writing the full multiplicity distribution is enabled. The generator does **not** impose a target γ-multiplicity distribution; it reports the distribution induced by the sampled β/γ network.

## 5. Counting distinct β + γ cascade paths

A **decay path** means one direct β transition to daughter level \(i\), followed by one permitted sequence of downward γ links to a terminal state. It is a *structural* path, independent of how large its positive probability is.

If all reachable excited levels ultimately terminate at ground state, set \(C_0=1\) and compute upward

\[
\boxed{C_i=\sum_{j:\ i\to j,\ g_{ij}>0}C_j},\qquad
\boxed{N_{\mathrm{paths}}=\sum_{i:b_i>0}C_i}.
\]

This is the correct path-count formula for an actual sampled scheme. If the graph has terminal excited levels, it must first be decided whether such paths count as terminal-at-excitation or are invalid for the intended decay model; the equations above assume complete de-excitation to ground state. The generator separately rejects a **β-fed excited level** whose first-γ branching is absent or insufficiently normalized; scientific review should still inspect the full cascade network.

The familiar \(2^N\) expression applies only under additional idealized assumptions, such as a fully connected descending γ graph with β feeding allowed to every one of \(N\) excited levels (plus the ground state). **It is not a default property of `strength_weighted_sparse`**: that model usually selects only a small number of γ edges and also restricts ordinary generated destinations to β-fed levels plus ground state.

Changing positive branching intensities *without removing edges* changes **path probabilities**, not **path counts**. Changing β connectivity or pruning γ edges at the intensity floor can change the path counts.

## 6. Acceptance checks and failure cases

The source checks the following for each attempt:

| Check | Implemented requirement |
|---|---|
| Direct β distribution | Active branches have the configured positive floor; impossible total floor fails; feeding sums to unity through normalization |
| γ direction | Every retained/generated edge must go to a lower indexed level and have positive branching fraction |
| Generated γ minimum | Nonfrozen positive branches meet `min_branch_intensity_percent` |
| Generated γ outgoing count | Each generated/nonfrozen excited level has 1 through `max_outgoing_branches_per_level` outgoing positive branches |
| General nonempty γ list | Sum is within **0.025 absolute fraction** of unity |
| β-fed excited level | Must have at least one outgoing γ branch and a branching sum within **0.0005 absolute fraction** of unity |
| Inherited γ-only set | No new γ-only level outside the identified inherited frozen set |
| Synthetic γ-only set | Count and *at-least-one-visit* cascade probability satisfy the configured caps; requested/nonrequested status is consistent |
| Retry budget | At most `max_attempts_per_variation` attempts; otherwise fail with diagnostics |

The 0.025 and 0.0005 tolerances apply to **fractional** sums (i.e. ±2.5 and ±0.05 percentage points). A trusted γ pattern is not changed to satisfy these checks; an invalid trusted pattern may therefore cause repeated rejection. Additional input checks ensure acceptable configuration ranges, supported model names and valid level/transition XML.

## 7. Reproducibility and exported files

For variation index \(k\), the seed is calculated using 64-bit unsigned arithmetic:

\[
\boxed{s_k=s_0+k\times\texttt{0x9e3779b97f4a7c15}\pmod{2^{64}}.}
\]

An independent `std::mt19937_64` RNG is initialized from this seed for that variation. Random decisions and any retries for variation \(k\) cannot change the RNG stream of variation \(k+1\). As usual for standard-library random distributions, **exact byte-identical generated output across different C++ standard-library implementations is not guaranteed**, even if the algorithm and seed agree.

After acceptance, `WriteVariation()` creates `Parent.xml` with **positive β** branches; `Daughter.xml` contains only levels reached by direct β feeding or positive γ cascades, plus the ground state required by `StopLevel`. It omits unreachable levels and zero-intensity γ transitions. The full common skeleton is retained separately in `skeleton.csv`. Frozen γ transitions preserve input attributes/conversion metadata; new transitions have `Origin="Added"`.

```
generated_schemes/
  skeleton.csv
  variations.csv
  multiplicity.csv              # only when configured
  scheme_000000/
    Decay.xml
    Parent.xml
    Daughter.xml
  scheme_000001/
    Decay.xml
    Parent.xml
    Daughter.xml
```

`variations.csv` records `variation`, `seed`, `attempts`, `beta_model`, `fed_fraction`, `gamma_only_levels`, `gamma_only_cascade_fraction`, `mean_gamma_multiplicity`, and `frozen_gamma_only_override`. `multiplicity.csv` has `P0`, …, `P32`, `P33plus`. The `--check-only` mode constructs and validates the common skeleton, inputs and model tables but does **not** sample or write variation XMLs.

## 8. Scientific limits

The generated decay-scheme ensemble uses a fixed, coarse, effective excitation-level skeleton; unmeasured levels do not acquire predicted spins/parities; no neutron branches are invented; no internal-conversion electron emission is sampled; no microscopic γ multipole strengths or nuclear β matrix elements are calculated. The role of the generator is to produce **controlled diverse structural hypotheses** that the downstream detector-response pipeline can simulate and compare—not to assert that every variation is a realistic evaluated decay scheme.

**Related reading:** [β models](BetaFeedingModels.md), [γ model](GammaTransitionModels.md), [generator program and INI options](../programs/GenerateDecaySchemes.md), [decay scheme matrix](DecaySchemeMatrix.md), [electron-energy spectra](BetaSpectra.md).
