# Statistical β-feeding models — complete implementation

**Source verified against:** MTAS Simulation Library **v1.2.3**, `src/apps/GenerateDecaySchemes.cpp` (`PhaseSpace`, `ChooseBetaModel`, `DrawFedFraction`, `ClusterWeights`, `AssignBeta`, `OneVariation`). SHA-256 of reviewed generator source: `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`.

This page specifies the actual randomized **daughter-level β-feeding model**, not the β-electron kinetic-energy spectrum. The two are separate: `GenerateDecaySchemes` assigns integrated feeding fractions to nuclear levels, while `GenerateResponse` later samples the energy of each electron ([β spectra](BetaSpectra.md)). The models below are *phenomenological priors for synthetic decay-scheme ensembles*. They are not fitted nuclear β-strength distributions or calculations of nuclear matrix elements.

## Notation and the common skeleton

One generator invocation uses a fixed, ascending set of daughter levels

\[
E_0=0<E_1<\dots<E_{n-1}<Q_\beta.
\]

The index **includes the ground state**; direct β feeding to it is permitted and corresponds to a zero-γ cascade. The skeleton is constructed **once** for all variations. Original daughter levels with \(E_i\le E_{\mathrm{trusted}}\) (and within \(Q_\beta\)) are retained. Any added effective levels are placed at centers of unoccupied bins on the fixed, nonuniform `mtas_354` energy grid, *above the highest retained experimental level*, up to the configured upper energy. Added levels have no assigned spin/parity. One-per-bin applies to **added** levels, not necessarily to known levels.

Let \(b_i\ge0\) be the **fraction** of β decays directly feeding level \(i\), with \(\sum_i b_i=1\); XML stores \(100b_i\) as a percentage. Define the active set \(B=\{i:b_i>0\}\). The generator first decides **which** indices belong to \(B\), then draws their positive strengths and imposes normalization and a minimum-branch floor.

## 1. β phase-space proxy (shared ingredient)

For daughter charge \(Z_d=Z_{\mathrm{parent}}+1\) and endpoint \(q_i=Q_\beta-E_i\), `PhaseSpace()` evaluates an approximate allowed β− phase-space integral:

\[
I_i\simeq \frac{q_i}{160}\sum_{r=0}^{159}
 p(T_r)\,W(T_r)\,(q_i-T_r)^2\,F(Z_d,T_r),
\qquad T_r=\frac{q_i(r+\tfrac12)}{160},
\]

where all energies are in keV,

\[
\begin{aligned}
W(T)&=T+m_e,& m_e&=510.99895\ \mathrm{keV},\\
p(T)&=\sqrt{T(T+2m_e)},&
\eta(T)&=\alpha Z_d\frac{W(T)}{p(T)},\\
F(Z_d,T)&=\frac{2\pi\eta}{1-\exp(-2\pi\eta)},&
\alpha&=1/137.035999084.
\end{aligned}
\]

The code evaluates the Fermi-factor denominator numerically using `expm1` for stability. The phase-space proxy is zero for a nonpositive endpoint. It is calculated once for each skeleton level, then converted into a dimensionless weight

\[
\phi_i=\max\left(10^{-15},\frac{I_i}{\max_j I_j}\right)
\]

when the maximum is positive (otherwise the fallback is one). Thus \(\phi_i\) is positive and at most 1, even for a very small phase-space integral. **These are relative sampling weights**: the integration contains no fitted nuclear matrix element, β-shape classification, screening correction, or normalization to an experimental \(ft\) value. This is **not** `GenerateResponse`'s more detailed electron-energy sampler.

## 2. Model choice and target number of directly β-fed levels

`beta.model` accepts `sparse_statistical`, `phase_space_weighted`, `clustered`, or `mixed`. `mixed` draws **one of the first three with equal probability** for *each attempted variation*; it does not interpolate their intensities within a variation.

Draw \(U\sim\mathrm{Uniform}(0,1)\). The requested direct-feeding fraction is

\[
f_\mathrm{draw}=f_{\min}+(f_{\max}-f_{\min})\,g(U),
\]

with the following choices:

| Model selected | `fed_fraction_mode=model_dependent`: \(g(U)\) | Interpretation |
|---|---:|---|
| `sparse_statistical` | \(U^{1.8}\) | Bias toward the low end of the allowed fraction range |
| `phase_space_weighted` | \(U\) | Uniform across the allowed range |
| `clustered` | \(U^{0.75}\) | Bias toward the high end of the allowed range |

With `fed_fraction_mode=uniform`, **all three** instead use \(g(U)=U\). These power laws bias the *fraction of active levels*; they do not themselves define β intensities.

The initial target count is approximately

\[
N_\mathrm{target}=\operatorname{clamp}
\left(\operatorname{round}(nf_\mathrm{draw}),\;N_{\min},\;n-N_\mathrm{protected}\right).
\]

If nonzero, `max_fed_levels` imposes an additional upper cap. The count is then raised if necessary to accommodate originally β-fed levels that must remain active. **The initial rounding uses the full \(n\), including the ground state and any protected levels**, rather than a denominator restricted to currently eligible levels; the upper clamp separately accounts for protected levels. Mandatory feeding and the later frozen-graph promotion can make the **final** number exceed the sampled target (or the configured optional maximum). The reported `fed_fraction` is the *final* \(|B|/n\), not necessarily \(f_\mathrm{draw}\).

For each new active slot, the generator selects **without replacement** from eligible, not-already-chosen levels, using the model-dependent selection weights in the next section. Known positive β feedings are mandatory when `preservation.keep_known_beta_fed_nonzero=true`, but **their numerical probabilities are redrawn**, not retained.

## 3. Selecting directly fed levels

All candidate indices satisfying \(E_i<Q_\beta\) can be selected, except protected γ-only levels and already-selected levels. Let \(s_i\) denote the selection weight used in a weighted draw, with probability \(s_i/\sum_{j\in\mathrm{eligible}}s_j\) at each step.

| Model | Level-selection weight \(s_i\) | Strength model after selection |
|---|---|---|
| `sparse_statistical` | \(1\) | Strongly fluctuating gamma-distributed weights |
| `phase_space_weighted` | \(\phi_i^{0.45}\) | Gamma-distributed weights multiplied by \(\phi_i\) |
| `clustered` | \(c_i\phi_i^{0.20}\) | Gamma-distributed weights multiplied by \(c_i\phi_i^{0.25}\) |

The source bounds selection weights below by \(10^{-12}\). Thus even a strongly disfavored energetically accessible level can, in principle, be selected. The `sparse_statistical` model has no phase-space bias in **selection**, although every emitted β branch still uses its physical endpoint \(q_i\) downstream.

### Cluster prior used by `clustered`

The code first draws \(K\) uniformly from the integers 1, 2, and 3. For each cluster \(k\), it samples independently:

\[
\mu_k\sim U(0,Q_\beta),\qquad
\sigma_k\sim U(200,1300)\ \mathrm{keV},\qquad
A_k\sim U(0.3,2.0).
\]

The energy-localization weight for level \(i\) is

\[
\boxed{c_i=0.02+\sum_{k=1}^{K}A_k
\exp\!\left[-\frac{(E_i-\mu_k)^2}{2\sigma_k^2}\right]}
\]

The baseline 0.02 leaves nonzero weight outside the sampled clusters. **Each attempted variation draws new cluster centers, widths and amplitudes.** The clusters are phenomenological regions in daughter excitation energy, not assignments of nuclear bands or spin/parity families.

## 4. Drawing β strengths for active levels

After active-set selection, the generator follows all **frozen** positive γ links from active levels. If a non-ground-state destination is not β-fed and is not protected as γ-only, it is **promoted to direct β-fed status**. The traversal repeats until no further promotions occur. This prevents ordinary additional γ-only-fed levels from appearing through the preserved experimental graph. Promotions can increase the active set beyond the initial requested fraction.

For each active level \(i\), independently draw \(G_i\) from a gamma distribution with unit **scale**:

\[
G_i\sim\begin{cases}
\mathrm{Gamma}(0.35,1),&\texttt{sparse\_statistical},\\
\mathrm{Gamma}(1,1),&\texttt{phase\_space\_weighted}\text{ or }\texttt{clustered}.
\end{cases}
\]

The unnormalized strengths \(a_i\) are:

\[
\boxed{a_i=\begin{cases}
G_i,&\texttt{sparse\_statistical},\\
G_i\phi_i,&\texttt{phase\_space\_weighted},\\
G_i c_i\phi_i^{0.25},&\texttt{clustered}.
\end{cases}}
\]

An implementation floor of \(10^{-15}\) is applied to any active raw weight, before normalization; all inactive levels remain **exactly zero**. In the absence of a minimum intensity constraint, the final feeding fractions would simply be \(b_i=a_i/\sum_{j\in B}a_j\).

Because a gamma distribution with shape \(0.35<1\) is heavily concentrated near zero with a long positive tail, the sparse model naturally produces very uneven strengths among its chosen levels. `phase_space_weighted` and `clustered` instead use exponential (shape-one gamma) fluctuations, modulated by their deterministic weights.

## 5. Positive-branch minimum and normalization

`beta.min_intensity_percent` is a **percentage**, not a fractional probability. With default 0.01%, the fraction floor is

\[
b_\mathrm{min}=\frac{0.01}{100}=10^{-4}.
\]

All \(b_i>0\) must satisfy \(b_i\ge b_\mathrm{min}\), while unselected levels stay at zero. If \(|B|b_\mathrm{min}>1\), the variation fails: the requested floor cannot fit within 100%.

The implementation does **not** add a constant baseline to each active intensity. Instead, it repeatedly:

1. Scales the still-unfixed raw weights to fill the remaining probability budget.
2. Fixes every branch that would fall below \(b_\mathrm{min}\) at exactly \(b_\mathrm{min}\).
3. Subtracts the reserved probability, rescales the remaining unfixed branches proportionally, and repeats until no additional branch violates the floor.

This produces a normalized direct-feeding distribution while perturbing the original randomly drawn relative strengths only where the floor requires it. It is a deterministic post-processing step conditional on the active set and raw weights.

## 6. Interaction with preserved experimental information

- `keep_known_beta_fed_nonzero=true` protects the *presence* of every originally positive retained β branch; **it does not freeze that branch's intensity**. Retained initial β attributes may be reused as XML metadata, but generated `Intensity`, `TransitionQValue` and `Origin=Added` are written anew.
- `freeze_known_gamma_patterns=true` preserves known daughter γ destinations and their **numerical branching fractions**, not merely the transition list. Such links can cause extra direct-feeding promotions as described above.
- An existing experimentally inherited γ-only-fed level is protected against direct β feeding; the treatment of such levels and optional newly introduced ones is described in [γ-transition models](GammaTransitionModels.md#gamma-only-fed-excited-levels).
- A candidate with an impossible feeding-floor constraint or conflicting graph restrictions is rejected; the variation is regenerated within `run.max_attempts_per_variation` rather than silently changing the model parameters.

## 7. What these priors do and do not mean

The four `beta.model` options determine the randomized **integrated level-feeding distribution**. They do not generate a nuclear-level-density function, determine spins/parities, fit transition matrix elements, or guarantee that the resulting feeding pattern is physically probable for the nuclide under study. In particular, the arbitrary exponents 0.45, 0.20 and 0.25, and the cluster Gaussian parameters, are ensemble-model choices from the code—not experimentally derived universal β-strength laws.

**Related reading:** [γ-transition generation](GammaTransitionModels.md), [full construction and validation](DecaySchemeValidation.md), [generator executable](../programs/GenerateDecaySchemes.md), [configuration keys](../reference/Configurations.md), and [β-electron spectra](BetaSpectra.md).
