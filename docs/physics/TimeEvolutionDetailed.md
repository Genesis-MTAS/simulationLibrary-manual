# Time evolution of the main decay, contaminants and pileup

**Current code:** `src/mixture/MixtureConfig.cpp` (`DecayRateLambda`, `TimeBinFraction`, `TimeOverlapK`, `ChooseTimeAxis`) and `src/mixture/MixtureRoot.cpp` (`AddEnergyTime`, `WriteMixture`), with source-pair histograms produced by `PileupEngine.cpp`. **Planned development:** Bateman parent–daughter chains and daughter grow-in. The distinction is critical: the existing code applies **independent exponentials** (or constant rates), not Bateman solutions.

## 1. Decay constant versus half-life

For a source with half-life `t_1/2`, its decay constant is

\[
\lambda=\frac{\ln 2}{t_{1/2}}\quad [\mathrm{s}^{-1}].
\]

If its inventory is `N(t)=N_0 e^{-λt}`, the decay rate (activity) is

\[
A(t)=\lambda N_0e^{-\lambda t}=A_0e^{-\lambda t}.
\]

A shorter half-life means a larger `λ`, so the *instantaneous* mixture of sources changes over time even when their integrated mixture fractions are fixed. For a source labeled `stable`/`inf`, the **software time model** sets `λ=0` and uses a constant count rate. This is a phenomenological stationary-source convention, *not* the nuclear activity `A=λN` of a physically stable nuclide, which is zero. Use it for stationary background-like or long-lived externally sustained contributions, not to claim stable nuclei undergo radioactive decay.

### What can be configured?

- Main half-life: `[mixture] main_half_life_s`, or inferred from embedded XML if omitted.
- Each contaminant: `[contaminant:NAME] half_life_s`, or an embedded XML half-life if available.
- Time window: `[energy_time] time_range_mode = half_lives` with `half_lives = n`, or `fixed` with `max_time_s`.
- Time binning: exactly 354 time bins in current `energyTime`; `time_unit=auto|ns|us|ms|s|min|h|day|year`, optionally `time_bin_width`. The chosen integer bin width may cause the actual observation window to differ slightly from the requested target; check `metadata/EnergyTimeConditions`.

The main output uses the `mtas354` energy axis unless configured otherwise; its `energyTime` X axis is energy and Y axis is **time**, in the units recorded in metadata.

## 2. Why a finite observation window changes the normalization

A physically weighted 1D source energy spectrum `S_i(E)` already describes its **total integrated contribution over the selected observation window**, not its initial-rate spectrum. The time-evolution algorithm distributes the *same integrated counts* over the 354 time bins without changing their total.

For an exponential source observed in `0 ≤ t ≤ T` define

\[
p_i(t\mid[0,T])=\frac{\lambda_i e^{-\lambda_i t}}{1-e^{-\lambda_i T}}
\quad(\lambda_i>0).
\]

This integrates to 1 over `[0,T]`. In time bin `[t_j,t_{j+1}]` the exact fraction is

\[
P_{ij}=\frac{e^{-\lambda_i t_j}-e^{-\lambda_i t_{j+1}}}{1-e^{-\lambda_i T}},
\qquad\sum_jP_{ij}=1.
\]

For `λ_i=0`, the code instead uses `P_ij=(t_{j+1}-t_j)/T`. Numerically it evaluates exponential differences via `expm1` to reduce cancellation errors when `λT` or bin widths are small.

The 2D energy–time histogram is

\[
H_i(E_b,t_j)=S_i(E_b)\,P_{ij}.
\]

Consequently, for every energy bin `b`,

\[
\sum_j H_i(E_b,t_j)=S_i(E_b).
\]

The **final** energyTime histogram is a sum of all weighted source and pileup time histograms, and its projection onto energy agrees with physical `final/3300` (to rounding tolerance). Do not take an already normalized source energy histogram, multiply it by an unnormalized `e^{-λt}` sampled at bin centers and expect conservation; the code uses exact integrated and finite-window-normalized bin probabilities.

### Example: a 5-half-life observation window

For `T=5 t_{1/2}`, an exponential source emits a fraction `1−2^{-5}=31/32≈96.875%` of its *infinite-time* integrated decays during the window. The code makes the **observed** source's 1D integral represent **100% of that source's configured window contribution**; it divides the time shape by `1−2^{-5}`. This is why time integration reproduces the given 3300 spectrum rather than only 96.875% of it.

## 3. Independent contaminant half-lives and changing instantaneous fractions

Suppose main and contaminant have rates `λ_m` and `λ_c` and **integrated** physical 3300 contributions `N_m` and `N_c` in the time window. Their time-dependent rates in a given energy interval are proportional to

\[
r_m(E,t)=S_m(E)\,p_m(t),\qquad
r_c(E,t)=S_c(E)\,p_c(t).
\]

The contaminant's instantaneous fraction at a fixed energy is

\[
f_c(E,t)=\frac{r_c(E,t)}{r_m(E,t)+r_c(E,t)+\cdots},
\]

which is **not generally equal** to its configured *integrated* 3300 fraction in `Mixture.ini`. A short-lived contaminant dominates more at early times and contributes relatively less at late times, even though its entire observation-window contribution is fixed. An independent contaminant with a longer half-life than the main decay behaves oppositely.

The code does not derive contaminant amplitudes from production yields or parent-decay branching ratios. The operator supplies their overall mixture fractions, with independent exponential time behavior. The half-life affects how weighted counts are **distributed in time**, not the already chosen integrated contaminant fraction.

## 4. Accidental-coincidence time shapes

If independent radioactive sources `i` and `j` have instantaneous rates proportional to `e^{-λ_i t}` and `e^{-λ_j t}`, an accidental S+S coincidence has rate proportional to their **product**:

\[
r_{ij}^{\mathrm{SS}}(t)\propto e^{-\lambda_i t}e^{-\lambda_j t}
=e^{-(\lambda_i+\lambda_j)t}.
\]

Thus the S+S time shape uses the **effective decay constant**

\[
\boxed{\lambda_{ij}^{\mathrm{SS}}=\lambda_i+\lambda_j}.
\]

Two events from the *same* source have `λ_SS=2λ`, and hence an effective half-life

\[
t_{1/2,\mathrm{SS}}=\frac{t_{1/2}}{2}.
\]

For **S+B**, the experimental background is assumed stationary, so only the triggered primary activity changes:

\[
r_i^{\mathrm{SB}}(t)\propto e^{-\lambda_i t}\times\mathrm{constant},
\qquad \boxed{\lambda_i^{\mathrm{SB}}=\lambda_i}.
\]

A mixed-source S+S pair and a mixed-source S+B pair may have different time constants from their component source. This is intentional. The 1D raw pair-energy templates are stored by source-pair identity during sampling; `MixtureRoot.cpp` evolves each source pair using its appropriate λ and **then adds** all source-pair `energyTime` histograms into the corresponding `pileup_ss` or `pileup_sbkg` component.

### Relative rates and source-pair allocation

When source rates are normalized to unit integral over the common window, their instantaneous overlap is

\[
K_{ij}=T\int_0^T p_i(t)p_j(t)\,dt.
\]

For positive λ values this gives the implemented expression

\[
K_{ij}=\frac{T\int_0^T e^{-(\lambda_i+\lambda_j)t}\,dt}
{\left(\int_0^T e^{-\lambda_i t}\,dt\right)
\left(\int_0^T e^{-\lambda_j t}\,dt\right)}.
\]

When either λ is zero, `TimeOverlapK` returns **1**, consistent with a normalized constant-in-time rate in this model. `K_ij` changes how the **fixed total S+S mixture fraction** is allocated among pairs `(i,j)`; it does not determine the total S+S fraction on its own. The total S+S and S+B fractions are specified separately in `Mixture.ini`.

The source-pair sampler also includes source-specific counts of primary and secondary reservoir events; see [pileup details](PileupDetailed.md). Do **not** interpret `K` as a nuclear decay branching probability.

## 5. How time evolution interacts with energy and normalization

1. Build the unrebinned detector/pileup contributions, then rebin to the selected energy axis.
2. Draw exclusive integrated main, contaminant, S+S and S+B fractions. Apply physical count weights to each component.
3. Construct the **energyTime** component using each source's (or source pair's) normalized time probabilities `P_ij`.
4. Sum components linearly to `final/energyTime`; verify its energy projection matches `final/3300`.
5. Leave physical values as weighted **counts per energy/time cell**. In ML preprocessing, divide only by the **energy-bin width correction**, not by seconds per time bin, before applying the reversible shared-log mapping.

Because the 2D time cells are integrated counts, and not counts per second, comparing different time-axis bin widths must take the bin width into account when interpreting the *rate*. If you want a count rate, divide the **decoded physical bin count** by its actual time-bin duration. That is an analysis operation; the stored physical `energyTime` itself is not a rate density.

## 6. Priority for future development: Bateman grow-in of daughter contaminants

**Status: NOT IMPLEMENTED. First requested scientific development after the initial production run.** The current implementation treats main and contaminants as **independent preset exponential components**. It cannot describe a daughter nuclide whose activity starts near zero, grows as its parent decays, and may subsequently decrease. In particular, **setting a daughter's independent `half_life_s` does not reproduce Bateman grow-in**.

### One parent and one daughter

For a parent `P` and a daughter `D` with decay constants `λ_P`, `λ_D` and a branching fraction `b` feeding the daughter, the Bateman inventory equations are

\[
\frac{dN_P}{dt}=-\lambda_P N_P,
\qquad
\frac{dN_D}{dt}=b\lambda_P N_P-\lambda_D N_D.
\]

For `λ_D≠λ_P`, the solution is

\[
N_P(t)=N_P(0)e^{-\lambda_P t},
\]

\[
N_D(t)=N_D(0)e^{-\lambda_D t}+
\frac{b\lambda_P N_P(0)}{\lambda_D-\lambda_P}
\left(e^{-\lambda_P t}-e^{-\lambda_D t}\right).
\]

For a daughter initially absent, `N_D(0)=0`, the daughter activity is

\[
\boxed{A_D(t)=\lambda_DN_D(t)=
\frac{b\lambda_P\lambda_D N_P(0)}{\lambda_D-\lambda_P}
\left(e^{-\lambda_P t}-e^{-\lambda_D t}\right)}.
\]

For equal decay constants, take the smooth limit:

\[
N_D(t)=e^{-\lambda t}\left[N_D(0)+b\lambda N_P(0)t\right].
\]

The daughter activity can **increase at early times** and later fall. A stable daughter has λ_D=0 and accumulates in inventory but does not produce daughter radioactive decays (`A_D=0`). This is fundamentally different from the existing constant-rate `lambda=0` contaminant convention.

### Multistep chains and branching

For several daughters and multiple decay branches, the general coupled form is

\[
\frac{d\mathbf N}{dt}=\mathbf M\mathbf N,
\qquad \mathbf N(t)=e^{\mathbf Mt}\mathbf N(0),
\]

where diagonal terms are negative loss constants, and off-diagonal terms include branch-weighted parent-to-daughter production. The detected spectrum of species `i` is weighted by the **activity** `A_i(t)=λ_iN_i(t)` and its detector response, not by the inventory `N_i(t)` alone. Detector efficiency and β gating remain separate response factors.

### Required software design for Bateman support

The first development step should specify and test:

1. A **decay-chain input model** listing parent/daughter relations, branch probabilities, half-lives and initial inventories or production history, independently of the per-nuclide emitted cascade scheme.
2. A stable, numerically validated solver, including `λ_P≈λ_D`, truly stable species, longer decay chains, and isomeric branches.
3. A per-source activity curve `A_i(t)` and bin-integrated **window-normalized** probabilities, replacing the current single `TimeBinFraction(λ,...)` where a Bateman chain is specified.
4. Updated source-pair probabilities using \(\int_0^T A_i(t)A_j(t)dt\) for S+S and \(\int_0^T A_i(t)B(t)dt\) for S+B, including non-exponential pair time shapes.
5. A scientifically explicit convention for **initial activities** and **integrated mixture fractions** to prevent double counting a daughter present initially and also produced by the parent.
6. Acceptance tests showing that energyTime projects back to the physical 3300 components, that chain populations/activities obey analytical reference solutions, and that no parent/daughter contribution is counted twice.

**Do not retrofit daughter growth by merely replacing `λ_D` with an effective λ or by summing two unrelated exponential contaminant templates.** Bateman curves may be signed combinations of exponentials mathematically, but the resulting daughter activity must stay nonnegative and be calculated from the common chain solution. Neither the existing `Mixture.ini` nor the existing pileup pair sampler has a chain topology input today.

## Source cross-reference

- `MixtureConfig.cpp` lines ~92–122: time units, integer 354-bin axis, λ, bin fractions, `K_ij`.
- `PileupEngine.cpp` lines ~300–318: time-overlap weighted source pair draw; ~353–365: pair-specific 1D energy templates.
- `MixtureRoot.cpp` lines ~118–124, ~199–263: window-normalized time binning and physical 3300 projection check.

Related: [Pileup in detail](PileupDetailed.md), [Normalization and reconstruction](NormalizationAndReconstruction.md), [Existing energy binning/time overview](EnergyBinningAndTime.md).
