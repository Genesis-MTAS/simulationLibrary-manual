# Statistical γ-transition model — complete implementation

**Source verified against:** MTAS Simulation Library **v1.2.3**, `src/apps/GenerateDecaySchemes.cpp` (`GammaWeight`, `DrawBranchCount`, `WeightedIndex`, `Widths`, `GenerateGammas`, `FrozenGammaOnly`, `GammaOnlyStats`). Source SHA-256: `889ab065aa1f26f2ace49059f8b404d082850693975212594aa89774d78a360f`.

The generator offers **one** supported γ model, `strength_weighted_sparse`. It resamples γ **destinations** and **branching fractions** for generated patterns while optionally freezing the experimental patterns of retained daughter levels. It is a stochastic downward cascade model, **not** a complete electromagnetic transition-rate theory, a spin/parity selection-rule calculation, or an evaluated photon-strength function.

## 1. Fixed skeleton and available transitions

With daughter levels ordered \(E_0=0<E_1<\dots<E_{n-1}\), an energetically downward transition from source \(i\) to destination \(j<i\) has photon energy

\[
E_{\gamma,ij}=E_i-E_j>0.
\]

`GenerateDecaySchemes` precomputes a positive weight for **every** downward pair in the common level skeleton. However, this is **not** the same as allowing every such pair to be a candidate when a particular sparse decay network is sampled. For an ordinary *generated* branch the candidate set is

\[
\boxed{D_i=\{0\}\cup\{j:0<j<i\ \text{and}\ b_j>0\}.}
\]

That is, the ground state and **lower levels with positive direct β feeding** are ordinary generated destinations. Levels with exactly zero direct β feeding are normally not ordinary generated destinations. An exception is a specially forced γ-only-fed level (explained below). Frozen experimental γ transitions retain their original destination choices regardless of this generated-branch restriction.

This restriction is essential when interpreting ensembles: although every lower-energy pair has a stored energy weight, individual sampled networks are **sparse** and **not fully connected**. The combinatorial \(2^N\) bound for fully connected cascades is not the number of actual sampled paths in this generator. For a generated scheme, path counts must be computed on its **actual nonzero γ edges**; see [construction and cascade statistics](DecaySchemeValidation.md).

## 2. Phenomenological transition-energy weight

For each pair \(i>j\), the source defines

\[
\boxed{w_{ij}=\left(\frac{\max(E_{\gamma,ij},1\,\mathrm{keV})}{1000\,\mathrm{keV}}\right)^3
\exp\left(-\frac{E_{\gamma,ij}}{E_s}\right),\qquad E_s=\texttt{gamma.energy\_scale\_keV}.}
\]

The default is \(E_s=1000\,\mathrm{keV}\). The precomputed weight is bounded below by \(10^{-16}\) for numerical sampling. For physical positive excitation differences, the \(\max(E_\gamma,1\,\mathrm{keV})\) only guards exceptionally small differences.

For a source level \(i\), each ordinary destination is drawn, **without replacement**, in proportion to its remaining \(w_{ij}\). Thus selection probabilities at a given draw are

\[
\Pr(j\mid\text{remaining destinations},i)=\frac{w_{ij}}{\sum_{\ell\in D_i^{\mathrm{remaining}}}w_{i\ell}}.
\]

**Illustrative destination draw:** For a generated source at 2000 keV, suppose only the ground state and a directly β-fed 1000-keV level are eligible. At the default scale of 1000 keV, their destination weights are \(8e^{-2}\simeq1.083\) and \(e^{-1}\simeq0.368\), respectively. The probability of choosing the ground state in the *first destination draw* is then \(1.083/(1.083+0.368)\simeq0.746\). These numbers illustrate the **destination selection**, not the final γ branch intensities: the latter are separately randomized through width fluctuations and renormalization.

This favours certain γ energies, with the cubic factor competing against the exponential suppression. Its **shape is phenomenological**. The code contains no angular-momentum multipolarity identification, transition-specific electromagnetic reduced matrix elements, level-spin selection rules, or detailed energy-dependent photon-strength normalization. **Do not interpret \(E_\gamma^3\exp(-E_\gamma/E_s)\) as a derived universal γ-strength function.**

## 3. Random number of outgoing branches

For every level whose γ pattern is to be generated, the model first samples an intended outgoing count. Let

\[
H\sim U(0.55,1.8),\quad \mu=H\,m_\gamma,\quad
K_\mathrm{raw}=1+\mathrm{Poisson}(\max(0,\mu-1)),
\]

where \(m_\gamma=\texttt{gamma.mean\_outgoing\_branches}\) (default 3). The uniform multiplier makes the Poisson mean vary between levels/realizations; the value 3 is **not an exact mean of the final outgoing count**, because of this mixing, capping, and branch pruning.

The count is restricted to at least one and at most

\[
K=\min\left(K_\mathrm{raw},\ |D_i|,\ K_\mathrm{max},\left\lfloor\frac{1}{b_{\gamma,\min}}\right\rfloor\right),
\]

where `max_outgoing_branches_per_level` gives \(K_\mathrm{max}\) (default 15), and

\[
b_{\gamma,\min}=\frac{\texttt{min\_branch\_intensity\_percent}}{100}
\]

(default 0.01, meaning 1%). If there is only one allowed destination, it is selected directly. When optional **forced γ-only** destinations are assigned, additional logic ensures that each forced branch is included and at least one ordinary branch remains; see the γ-only section.

After destinations are selected without replacement, there are \(K\) candidate branches, before pruning weak branches. The number of **surviving** positive γ branches can be smaller than \(K\).

## 4. Random partial widths and relative intensities

For each selected ordinary destination, the code draws an independent unit-scale gamma variate with shape \(1/2\):

\[
X_{ij}\sim\mathrm{Gamma}(1/2,1),\qquad
\widetilde\Gamma_{ij}=w_{ij}\,X_{ij}.
\]

These are **Porter–Thomas-like** fluctuations of a phenomenological mean strength, not measured partial widths. Because all outgoing widths are eventually normalized, the absolute scale of \(X\) cancels. The initial normalized branch fraction is

\[
\boxed{b_{ij}=\frac{\widetilde\Gamma_{ij}}{\sum_{k\ \mathrm{selected}}\widetilde\Gamma_{ik}}.}
\]

The `Widths()` algorithm then imposes the synthetic branch floor:

1. Set each currently positive \(b_{ij}<b_{\gamma,\min}\) to zero, unless it is the sole active branch.
2. Renormalize remaining fractions to sum to one.
3. Repeat until no positive branch is below the floor, or only one branch remains.

If numerical sampling produced no positive sum, a one-branch fallback is used. A single surviving branch has 100% intensity. Crucially, **weak synthetic γ branches are removed**, whereas the β-feeding floor in the preceding chapter **retains** every active β branch by raising its intensity to its minimum. These are distinct algorithms.

The XML writes the positive generated percentages \(100b_{ij}\), generated γ energies \(E_i-E_j\), and `Origin="Added"`. Zero-width branches are omitted.

## 5. Preserved experimental patterns

With `preservation.freeze_known_gamma_patterns=true` (the supplied default), each retained known excited level copies its `initialGamma` list rather than invoking the statistical γ model. This preserves:

- The original destination level for every trusted non-Fake γ transition.
- The original **numerical branching fractions**, not just the set of connections.
- Associated transition attributes and any included electron-conversion-coefficient attributes as XML **metadata**.

The numerical probability stored in the input trusted transitions is **not randomly varied under this default**. This is easy to confuse with the β-feeding rule: known **β intensities are resampled** (while their positivity can be preserved), but known **γ intensities are frozen** when the γ-pattern option is enabled.

`Type="Fake"` transitions are ignored. The generator does not synthesize internal conversion electrons or new conversion coefficients. Frozen patterns are not required to satisfy the generated-branch 1% floor or the generated 15-branch limit, although the validation checks still apply. With `freeze_known_gamma_patterns=false`, retained known levels still exist, but their γ patterns are generated afresh by the synthetic model; experimental destinations and branching fractions are no longer frozen.

**Important configuration limitation:** There is **no current mode** that keeps the experimental low-energy γ **destinations fixed while independently varying only their intensities**. The `true` setting freezes **both** destinations and intensities; the `false` setting regenerates **both** according to the synthetic model. If such a partially frozen ensemble is desired, that is a **future code change**, not an option implemented in v1.2.3.

## 6. γ-only-fed excited levels

A **γ-only-fed** excited level is populated through at least one γ cascade but has **zero direct β feeding**. The ground state does **not** count as a γ-only-fed excited level. The code treats **inherited frozen** and **synthetically introduced** γ-only levels differently.

### Inherited γ-only levels

Before variations are generated, `FrozenGammaOnly()` propagates the **original** positive β feedings downward through **frozen, positive** experimental γ branches. Any reachable excited level with no original direct β feeding is recorded as inherited γ-only. If at least one exists and the known γ patterns are frozen, the implementation uses the inherited set rather than asking for new random γ-only targets.

- Those inherited levels are protected from direct β feeding in the new variations.
- New additional γ-only-fed excited levels are **not** permitted in an inherited-override variation.
- The configured synthetic limits on their **count** and **cascade share** are overridden; an inherited set can be larger or more strongly populated.
- `frozen_gamma_only_overrides_constraints` must be true in the current implementation.

### Optional new γ-only levels

If there is no inherited override, the generator draws a Bernoulli choice with probability `gamma_only.probability_per_variation` (default 0.30) to request a γ-only component, provided `gamma_only.max_levels > 0`. If requested:

1. Candidate targets are added (not known) excited levels **below the highest added level**, with at least one higher added level available.
2. Shuffle eligible targets and choose a count uniformly from 1 through the smaller of `max_levels` (default 2) and the number eligible.
3. Protect these levels from direct β feeding.
4. After β sampling, choose **one** higher direct-β-fed, nonfrozen source for each requested target, uniformly from those eligible. Some attempts may fail if no such source exists.
5. Force the corresponding γ link from that source to its requested γ-only target, while generating at least one additional **ordinary** outgoing branch from the same source.

The forced destinations are added to that source's destination list with a temporary weight of 0.02 for the initial width draw; afterwards **each forced branch is assigned exactly the configured minimum γ fraction** \(b_{\gamma,\min}\) (1% by default), and the remaining ordinary branches share \(1-N_{\mathrm{forced}}b_{\gamma,\min}\). Ordinary branches that then fall below the floor are removed and the remainder is renormalized again.

The selection probability 0.30 is the probability of *attempting* such a category before rejection/retry—not necessarily the observed fraction in the final ensemble, because impossible or invalid variations are retried.

### Exact definition of the cascade-share constraint

Let \(G\) be the set of γ-only excited levels in a completed variation, and let \(q_i\) be the probability that a cascade **starting at level \(i\)** visits **at least one** member of \(G\). Since transitions only go downward, the source computes exactly

\[
q_i=\begin{cases}
1,&i\in G,\\
\displaystyle\sum_{j<i}b_{ij}q_j,&i\notin G.
\end{cases}
\]

The total probability for a β decay to traverse a γ-only-fed excited level is then

\[
\boxed{P_{\gamma\text{-only}}=\sum_i b_i q_i.}
\]

Here \(b_i\) denotes the **direct β fraction** and \(b_{ij}\) the **γ branching fraction** (the two are distinct). Each β–γ cascade is counted **once**, even if it visits two different γ-only levels. For synthetic γ-only variations, the source requires

\[
|G|\le\texttt{gamma\_only.max\_levels},\qquad
P_{\gamma\text{-only}}\le\texttt{gamma\_only.max\_cascade\_fraction}.
\]

If no new γ-only component was requested, the generator requires that none emerged accidentally. If new levels were requested, at least one γ-only-fed excited level must actually be populated. A rejected attempt is resampled within the configured retry limit.

## 7. Validation and interpretation

The model validates that every generated γ transition goes strictly downward and has positive intensity; nonfrozen positive branches must meet the floor, and generated levels must have a nonempty outgoing list no larger than `max_outgoing_branches_per_level`. It checks sums of nonempty γ branch lists to within 0.025 of unity, and applies a **stricter 0.0005 absolute tolerance** to the complete first-γ branching of every directly β-fed excited level. Consequently, invalid trusted input patterns can cause rejection even though they are not rewritten. See [full validation and multiplicity](DecaySchemeValidation.md).

This model intentionally **does not** impose nuclear-spin/parity selection rules, explicitly derive E1/M1/E2 strengths, invent β-delayed neutrons, or generate internal-conversion electrons. Generated γ-energy dependence, width fluctuations, and branch-sparsity constraints should be understood as **ensemble priors** that need external validation for any scientific application.

**Related reading:** [β-feeding models](BetaFeedingModels.md), [construction and validation](DecaySchemeValidation.md), [program reference](../programs/GenerateDecaySchemes.md), and [configuration reference](../reference/Configurations.md).
