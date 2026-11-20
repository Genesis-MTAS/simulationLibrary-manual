# Event-resolved pileup: mathematics, zeros, reservoirs, 3350 and normalization

**Implementation audited:** `src/sorting/SortEngine.cpp` (`ProcessDetectors`, `ProcessEvent`); `src/mixture/PileupEngine.cpp` (`ConsiderPrimary`, `ConsiderSecondary`, `DrawSS`, `DrawBackground`, `SampleFamily`, `Yield`); `src/mixture/MixtureRoot.cpp` (`RebinRawHistograms`, `WriteMixture`). This chapter describes the C++ implementation in the **uploaded November 2026 source archive**, which remains the scientific engine of the tested production workflow. The original code and the exact-crystal background reader should be consulted for any subsequent change.

## 1. What is being simulated?

The two accidental-coincidence families are:

- **S+S:** a primary β-triggered radioactive event plus an independent secondary radioactive event falling inside the acquisition window. The secondary can come from the main source or from an **event-based** contaminant; `secondary_signal=ungated` permits a secondary that fails its own silicon trigger.
- **S+B:** a β-triggered radioactive primary plus one background event from a measured **MTASBKG1** crystal-resolved binary file. The background's time intensity is treated as stationary in the present implementation.

This is an **event-level** model. We do **not** combine the already-filled `3300`, `3350`, or `3351` histograms to make pileup. A 1D sum or 2D convolution of those histograms loses the association between crystals within each event; in particular it cannot tell whether the same IMO crystal was hit twice.

### Event notation

After applying the detector conditions **individually to each decay** (calibration → resolution folding → central efficiency → IMO thresholds), a processed event is

\[
\mathbf e=(C,I_0,\ldots,I_5,M_0,\ldots,M_5,O_0,\ldots,O_5),\qquad
T=C+\sum_{k=1}^{18} e_k.
\]

Here `e_1 ... e_18` denote all noncentral crystals, not a summed IMO channel. The record also has its own raw `SiTop` and `SiBottom` values, used for β gating *before* processing. The raw Monte Carlo library retains zero/no-deposit events to preserve response efficiency. The sorted event reservoirs contain **processed positive-total** events only.

For a pair of events `a` and `b`:

\[
T_{a+b}=T_a+T_b,\quad C_{a+b}=C_a+C_b,\quad
(e_k)_{a+b}=(e_k)_a+(e_k)_b\quad(k=1,\ldots,18).
\]

For S+B, `b` comes from the 19-crystal experimental background record (one stored total, central and 18 individual crystal energies). Its recorded total is used for `T_{a+b}`; the code allows the small float-rounding difference between that total and the sum of the 19 entries. Neither the summed pulse nor the background gets a **second** calibration, smearing or threshold pass. This is the current **process-separately-then-add** model; different accidental-summing electronics models would require a physics change.

## 2. Three different meanings of zero

There are three distinct uses of zero; they must not be conflated.

| Zero | Where it occurs | Current treatment |
|---|---|---|
| **Entire event has `T=0`** | Monte Carlo source response, including inefficient detection | Such events are retained in raw response files but do **not** fill β-gated `3300`, enter the positive-total pileup reservoir or become a positive pileup pair. This distinction preserves efficiency in the source library. |
| **An individual crystal has `e_k=0` but `T>0`** | An otherwise accepted decay, or a member of an accidental pair | It participates **as exactly zero in the event-level sum**; zero is not broadened into a fake low-energy deposit. |
| **A 2D histogram has Y below the output cutoff** | Raw or final `3350`/`3351` | Such entries are excluded when building the final 0–12 MeV physically weighted 2D spectra; the input energy was still used in computing the pair total and the individual crystal sums. |

This policy matters because ``zero + positive = positive`` and ``positive + positive = a larger positive pulse``. Deleting zero crystal entries **before** forming the pair would produce a different 3350 spectrum, alter the apparent probability of depositing energy in each crystal, and destroy useful hit-overlap information.

### Explicit zero examples

Consider one IMO crystal and two processed events:

| Primary `e_k` | Secondary/background `e_k` | Pair crystal energy | Raw pileup `3350` fill, with `min_2d_y_keV=10`? | Provenance |
|---:|---:|---:|---|---|
| 0 | 0 | 0 | No | Neither source |
| 0 | 150 | 150 | Yes | Secondary only |
| 80 | 0 | 80 | Yes | Primary only |
| 80 | 150 | 230 | Yes | Both |
| 3 | 5 | 8 | No | Both, but below the Y cutoff |
| 7 | 5 | 12 | Yes | Both |

All six combinations contribute their crystal energies to `T_{a+b}`. The cutoff affects only whether a *separate Y entry* is recorded for that particular crystal, **not** whether the pair exists.

## 3. Baseline sorting: how 3350 is filled **from individual events**

`SortEngine::ProcessEvent` first tests

\[
\max(\mathrm{SiTop},\mathrm{SiBottom})\geq E_{\beta,\mathrm{thr}}.
\]

For a triggered event, it processes the 19 detector energies. If the processed total `T<=0`, it does not fill the β-gated histograms. Otherwise:

```cpp
h3300.Fill(total);                 // exactly one entry per accepted event
h3310.Fill(crystals[0]);          // central can be zero
h3351.Fill(total, crystals[0]);
for (int k = 1; k <= 18; ++k) {
    h3305.Fill(crystals[k]);       // includes exact zeros
    h3350.Fill(total, crystals[k]); // 18 entries per accepted event
}
```

**Consequences:** raw `3350` has one Y entry for **each of the 18 IMO crystals per accepted event**, including zero-energy entries. Its raw total entry count can therefore be 18 times the number of events accepted into raw `3300` (provided no axis overflow; ROOT overflow must be treated separately). `3350` is *not* a probability distribution of one selected crystal per decay. `3305` is the corresponding distribution of **individual IMO energies**, not the sum of all 18 energies per event. Raw `3351` carries one central energy per event, including `C=0` when other crystals fire.

### The **final**, rebinned 3350 is different from raw 3350

The mixer/rebinner reads the raw 10-keV-grid 2D histogram and keeps only cells with X in `[0,12000)` keV and **Y≥10 keV**. The entire first raw Y bin (0–10 keV) is excluded, so raw zeros and sub-10-keV deposits never survive into `physical.root` `final/3350` or `components/*/3350`. A positive 10–40-keV crystal deposit still contributes to the broad first `mtas354` Y bin (0–40 keV). This is *not* the same as removing that whole first final bin.

Exactly the same Y≥10 keV rebinner applies to raw `3351`: central-zero entries exist in the source histogram but are absent from the final 2D spectrum. **The final `3300` still counts an otherwise accepted event when its central energy is zero.** Thus a projection/integral of final `3351` is not generally the same as final `3300`.

## 4. Building the primary and secondary reservoirs

`PileupEngine` employs reservoir sampling for positive-MTAS processed events. For every event encountered, a fixed-size reservoir either appends it or randomly replaces an existing entry, avoiding storage of all million raw events. Both primary and secondary pools are maintained; a primary can also be considered for the secondary pool.

- **Primary pool:** β-gated, positive-total events.
- **Secondary pool, `ungated`:** positive-total processed events may be included even if they did not pass the β trigger; a separate detector-smearing random stream prevents enabling secondary pileup from changing the baseline primary spectrum.
- **Secondary pool, `triggered`:** only triggered primary events are admitted as secondaries.
- **Multiple event sources:** source-specific reservoirs, with capacity approximately `reservoir_size / n_event_sources` (at least 1). **Histogram-mode contaminants cannot supply event samples.**

The reservoir is not a list of particle energies: every retained item carries the processed 19-crystal vector. This is what enables exact `3350` after summation.

### Source selection

In the multi-source mixture, the primary source index for S+B is drawn with weights proportional to

\[
q_i^{\mathrm{SB}} \propto w_i N^{\mathrm{primary}}_i.
\]

The ordered S+S source pair `(i,j)` is drawn with weights

\[
q_{ij}^{\mathrm{SS}}\propto
w_iN_i^{\mathrm{primary}}\,w_jN_j^{\mathrm{secondary}}\,K_{ij}.
\]

`w_i` is the source's realized mixture scale, the `N` factors are numbers seen by the reservoirs (not the number currently stored), and `K_ij` accounts for overlap of the normalized source time curves. The engine samples **ordered** first/second sources, but later combines symmetric pairs for their time evolution because `λ_i+λ_j` is symmetric. See [Time evolution](TimeEvolutionDetailed.md).

## 5. How pileup 3350 is actually calculated

The engine repeatedly draws an entire pair of processed events. For each accepted candidate pair it forms the **same** summed total `T` and 19 pulse energies. Then it fills each histogram under **independent acceptance targets**:

```text
Draw complete signal+signal or signal+background pair
  → sum T, central C, and all 18 IMO crystal energies
  → reject invalid or zero total, or total >= 15 MeV
  → for 3300, record T if the 1D entry target is not reached
  → for 3351, record (T,C) if the 2D target is not reached and C >= min_2d_y_keV
  → for 3350, loop through k=1..18:
       record (T, e_k) for each crystal with e_k >= min_2d_y_keV
       stop when the 3350 entry target is reached
  → continue sampling until each of 3300, 3350 and 3351 has reached its own target
```

The upper raw histogram range is 15 MeV. The **final** physical output is cut to 12 MeV. `3350` may receive many accepted entries from **one** pair, but `3351` receives at most one. The target entries, for example 1M in 1D and 10M per 2D histogram, are **separately configurable**. The code does not force all three histograms to be based on exactly the same number of pair attempts; it records each histogram's sampling exposure to correct that difference.

The common cutoff `min_2d_y_keV` is used at pair-fill time for 3350 and 3351. The final rebinner has its own fixed 10-keV lower Y cutoff (`MixtureRoot.cpp`), so setting a pileup cutoff below 10 keV does not restore the first raw Y bin in final 3350/3351.

### IMO hit-overlap diagnostics

For a crystal that actually fills pileup 3350, the engine records whether its nonzero pulse came from the first event only, second event only, or **both** before summation. This is the **provenance of a summed crystal pulse**, not a decomposition of the 2D histogram into independent 1D spectra. Additional diagnostic counters measure how many valid sampled pairs contain at least one IMO hit and at least one double-hit crystal within 0–12 MeV. They are written to the original intermediate metadata, not kept as full diagnostics in the compact physical ROOT file.

## 6. Exposure-normalized pileup yields: why 2D is not scaled like 3300

A sampling attempt is **not** identical to an accepted 3300 entry, nor to an accepted crystal entry. Let

- `H_h` be the accepted raw histogram integral **after** the standard final energy/Y cuts, for family `h ∈ {3300,3350,3351}`;
- `A_h` be the total number of pair attempts at the instant that histogram's target was reached;
- `Y_h = H_h/A_h` be its **yield per pair attempt** in the selected energy region.

The implementation computes these `Y_h` using `PileupEngine::Yield()`. Importantly, **`Y_3350` can exceed one entry per attempt** because one pair contributes up to 18 IMO crystal entries.

For a requested overall 3300 pileup fraction `f_p`, the physical target count is `N_p = f_p N_main`, with `N_main` the original positive 3300 main count in 0–12 MeV. The resulting scale factors are

\[
s_{p,3300}=\frac{f_p N_{\rm main}}{H_{3300}},
\qquad
s_{p,h}=\frac{f_pN_{\rm main}(Y_h/Y_{3300})}{H_h},
\quad h\in\{3350,3351\}.
\]

This matches the use of `PileupEngine::Yield()` and the distinct `rawPileupScales` in `MixtureRoot.cpp`. A **separate 2D scale** is required to preserve the experimentally meaningful 2D accepted-entries-per-eligible-pair relationship. Simply multiplying every raw pileup histogram by the 3300 factor is not the implemented algorithm and would generally be wrong.

`pileup_ss` and `pileup_sbkg` are treated independently, with fractions `ss` and `sb` drawn from `Mixture.ini`. Their target fractions refer to the **nonzero 3300 integral in [0,12 MeV)**, **not** to either 2D integral. The raw 2D templates are *statistics-generation devices*; their accepted entry counts do not directly represent physical mixture amplitudes.

## 7. Physical mixture shares and output normalization

The mixture draws exclusive fractions for all named contaminants plus S+S and S+B. The main fraction is their remainder:

\[
f_{\rm main}=1-\sum_i f_i-f_{\rm SS}-f_{\rm SB}>0.
\]

If `R_i = ∫raw_i(3300)` within 0–12 MeV, the unpiled component scales are

\[
w_{\rm main}=f_{\rm main},\qquad
w_i=f_i\frac{R_{\rm main}}{R_i}.
\]

These **same unpiled component factors** multiply their 3300/3350/3351 shapes. With the pileup-specific rules above, the final `3300` integral equals the original `R_main`, and each component's integral accounts for its requested exclusive 3300 share. This is *reference normalization*, **not** unit-area normalization of every histogram. The physical components are already weighted; **do not re-normalize them independently**.

The physical final histograms are linear sums, cell by cell:

\[
H_{\rm final,h}=H_{\rm main,h}+\sum_iH_{\rm contam_i,h}+H_{\rm SS,h}+H_{\rm SB,h}.
\]

The compact `physical.root` retains precisely these elementary terms. `CleanPhysicalResponse` verifies the identity in every normal bin before and after copying. The nonlinear ML representation is explained in [Normalization and reconstruction](NormalizationAndReconstruction.md).

## 8. Interpretation pitfalls and tests

1. **Raw versus final zeros:** Raw sorted 3350 includes 18 zero-or-positive IMO entries per accepted event; cleaned physical 3350 excludes sub-10-keV Y entries.
2. **No-deposit efficiency:** An original zero-total simulated event stays part of the source population in the library but does not become a visible MTAS event. Do not replace those zeros with smeared positive pulses.
3. **No histogram convolution shortcut:** Pileup 3350 comes from per-pair **crystal-by-crystal sums**, not by convolving raw 3350 histograms or spreading a total IMO energy among 18 crystals.
4. **Beta trigger belongs to the primary:** An ungated secondary can contribute energy without independently firing the β detector.
5. **2D counts are not event counts:** The 18 IMO entries per event and the nonzero-Y cuts mean 3350 is not the same normalization object as 3300.
6. **No second processing of the pair:** Deposits are calibrated, broadened and thresholded before summing. The model does not simulate a secondary post-summing threshold decision.
7. **Source pair timing:** The choice of two radioactive sources includes a rate-overlap factor, while pair decay time uses the **sum** of source decay constants; this is not Bateman daughter growth.
8. **Histogram-mode contaminants:** They are added after pileup and are not present in event-level accidental source-pair generation.
9. **Reproducibility:** Source selection, reservoir sampling, random pairs and background selection use independent seeded streams. Retain both INIs and realized metadata.
10. **Validation:** Verify positivity, cutoff handling, 3300 fractions, per-bin physical additivity, 3300 time projection, and decoded ML additivity. The detailed physics of the accidental-coincidence rate itself still rests on configured `ss`/`sb` fractions; they are not inferred from acquisition dead time by this code.

## Source cross-reference

- `SortEngine.cpp`: lines ~228–296 (per-event detector processing, β gate, 18 IMO fills).
- `PileupEngine.cpp`: lines ~259–350 (reservoirs, source selection, exact 19-crystal sums); ~381–485 (entry targets, Y cuts, zero policy); ~543–559 (accepted yields/exposures).
- `MixtureRoot.cpp`: lines ~41–62 (final 2D Y filter), ~136–183 (mixture scales), ~199–263 (energy–time components).

See also [Detector processing](DetectorProcessing.md), [Time evolution](TimeEvolutionDetailed.md), [Configuration reference](../reference/Configurations.md), and [Output formats](../reference/OutputFormats.md).
