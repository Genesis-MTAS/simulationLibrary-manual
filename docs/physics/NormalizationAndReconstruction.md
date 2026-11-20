# Histogram normalization: physical ROOT versus shared-log ML ROOT

**Source audit:** `src/mixture/MixtureRoot.cpp` (physical scales and final mixture), `src/apps/CleanPhysicalResponse.cpp` (linear count additivity), `src/apps/PreprocessResponse.cpp` (`Density`, `FinalScale`, `ProcessHistogram`, transform metadata), `src/preprocessing/SharedLogMath.cpp` (forward/inverse). Use this chapter when training an ML model or reconstructing a simulated spectrum from individual source channels.

## 1. First identify **which** normalization is intended

Three entirely different operations appear in the workflow:

1. **Physical component weighting** in the mixture: an exclusive fraction specifies how much a source contributes to the positive 3300 integral over 0–12 MeV. The final counts are anchored to the original main 3300 integral. The components' ROOT bin contents are **already scaled** and must **not** be independently normalized.
2. **Energy-bin-width correction** before ML: physical counts per variable-width energy bin are converted to a common reference-energy-bin density. This is **not** an integral normalization.
3. **Shared-log maximum normalization** for ML: all final and elementary component histograms within a family use **one** final-based log scale. This maps the final family's peak to 1, **not its total integral to 1**.

If you need a conventional **unit-area probability distribution**, that is a **separate optional analysis step after inverse-transforming to linear counts**. Never confuse unit-area normalization with the stored shared-log convention.

## 2. `physical.root`: additive, weighted, linear **counts**

For each family `h∈{3300,3350,3351,energyTime}` and cell `(i,j)` (only `i` for 3300):

\[
C_{\rm final}^{(h)}(i,j)=
C_{\rm main}^{(h)}(i,j)+\sum_{k}C_{{\rm contaminant},k}^{(h)}(i,j)+
C_{\rm SS}^{(h)}(i,j)+C_{\rm SB}^{(h)}(i,j).
\]

This identity is **cell by cell**, not only for overall integrals. `CleanPhysicalResponse` checks it and retains only the weighted elementary components plus final, along with text metadata. It does **not** alter a histogram's counts during cleaning. Individual component bin contents can be noninteger after weighting; these are expected **weighted counts**, not raw event tallies.

### 3300 reference convention

Let the unweighted main spectrum's 0–12-MeV integral be `N_main`. For configured exclusive 3300 fractions `f_main`, `f_contam_k`, `f_SS`, `f_SB`, the final mixture satisfies

\[
\int C_{\rm final}^{(3300)}\,d(\text{histogram bins})=N_{\rm main};
\qquad \sum_s f_s=1.
\]

Here the 'integral' means **summing bin contents**, not multiplying them by keV widths. The `f_s` specify each component's share of the **final 3300 integral**, and do **not** imply the same shares for 3350 or 3351.

**If you want a normalized 1D 3300 spectrum**, compute

\[
p_{3300}(i)=\frac{C^{(3300)}_{\rm final}(i)}{\sum_iC^{(3300)}_{\rm final}(i)}.
\]

Its bin contents sum to 1. For a true **probability density per keV**, use `p(i)/ΔE_i`, since `mtas354` bins have different widths.

### Important differences between the 2D families

- `3350`: one entry per **noncentral crystal** with an accepted positive deposit (up to 18 per event); it is **not one count per β event**. Its integral need not equal the 3300 integral.
- `3351`: one potential central-crystal entry per event, but final output removes the Y<10-keV raw bin; its integral can be less than 3300.
- `energyTime`: contains physically weighted counts **in each energy–time cell**. Summing over the 354 time bins recovers physical `3300`; summing over all cells therefore gives the final 3300 count integral (to rounding), provided energyTime is enabled.

For comparison among isotopes or experimental spectra, first state whether you want equal event count, equal observed 3300 integral, equal integrated activity, or a rate; those are different physical comparisons.

## 3. `ml.root`: corrected **density** followed by shared-log mapping

Only `3350`, `3351`, and `energyTime` are preprocessed; the 3300 1D histogram is in `physical.root`, not stored as a separate transformed `final/3300` in ML. The decay-scheme matrix is another object with its own probability normalization.

Let `C` be a **physical** 2D bin count. Let `ΔE_x`, `ΔE_y` be the corresponding energy-bin widths, and let the INI's `reference_width_kev = ΔE_ref` (default 10 keV). With `width_2d=both`, the code creates an equivalent reference-width cell density:

\[
\boxed{D_{3350,3351}(i,j)=C(i,j)
\frac{\Delta E_{\rm ref}}{\Delta E_{x,i}}
\frac{\Delta E_{\rm ref}}{\Delta E_{y,j}}.}
\]

This compensates for having fewer but wider bins at high energy. For `energyTime`, the Y axis is time, and the code corrects **energy width only**:

\[
\boxed{D_{\rm energyTime}(i,j)=C(i,j)
\frac{\Delta E_{\rm ref}}{\Delta E_{x,i}}.}
\]

**Do not divide by time-bin width for the stored ML convention.** If a model needs a physical time-rate density, derive that separately from decoded physical counts and the actual time bin widths.

The `Preprocess.ini` switch `width_2d` may instead be `x_only`, `y_only` or `none` for energy–energy histograms. `energyTime` always applies the energy-X factor regardless of `width_2d`. The exact configured mode and reference width are recorded per family.

### Shared-log transform

For each histogram family `h`, calculate

\[
D_{\max,h}=\max_{i,j}D_{\rm final}^{(h)}(i,j)
\]

from the **final** physically weighted spectrum. With the configured common `D_0 = log_reference_density > 0` (default 1), transform **both final and every component** using

\[
\boxed{L_h(D)=\frac{\ln(1+D/D_0)}{\ln(1+D_{\max,h}/D_0)}.}
\]

The formula is equivalent with `log10`; the implementation uses `log1p` for stability. Both `D_0` and `D_max` are **shared across all components of the same histogram family**, but `D_max` is separately calculated for 3350, 3351 and energyTime.

The results have the following properties:

- `L_h(0)=0`, and every positive `D` produces strictly positive `L_h(D)`.
- The **final** family's largest cell maps to 1 if it has any positive bins.
- Component maxima are normally **below 1**, because they represent only part of final. The source explicitly rejects a component density that exceeds the shared final maximum beyond numerical tolerance.
- **The sum of log-transformed components is NOT the log-transformed sum.** Logarithms destroy additivity.
- The sum of all stored transformed cells is **not 1**. The transform is a **peak-oriented numerical scaling**, not a probability normalization.

Per-family metadata are stored as `metadata/Transform_3350`, `metadata/Transform_3351`, `metadata/Transform_energyTime`, including `final_max_density`, `log_reference_density`, `ln_denominator`, `reference_width_kev` and `width_2d`.

## 4. Reconstruct complete spectra from the **log-transformed components**

This is the crucial reconstruction rule. **Never sum the logged component histograms directly.** Instead:

### Step 1: inverse each component to linear density

Read each component's `L_s(i,j)` and the **same family**'s transform metadata. Compute

\[
\boxed{D_s(i,j)=D_0\left[\exp\!\left(L_s(i,j)
\ln(1+D_{\max}/D_0)\right)-1\right].}
\]

Use `expm1` numerically. Equivalent C++ is `DecodeSharedLog` in `SharedLogMath.cpp`. Never estimate `Dmax` from a component's own maximum. Use the stored **final-family Dmax**.

### Step 2: add components **in linear density**

\[
\boxed{D_{\rm reconstructed}=D_{\rm main}+
\sum_k D_{{\rm contaminant},k}+D_{\rm SS}+D_{\rm SB}.}
\]

Because the width correction is linear and shared, the sum equals the final *density* up to floating-point rounding. If you want the **same ML representation** of the complete mixture, encode **after** the sum:

\[
L_{\rm reconstructed}=\frac{\ln(1+D_{\rm reconstructed}/D_0)}
{\ln(1+D_{\max}/D_0)}.
\]

This should match `ml.root:final/h` cell by cell. For ordinary analysis, you can instead use `ml.root:final/h` directly if you want the already-complete transformed spectrum; reconstruction matters when selecting/removing components or manipulating the mixture.

### Step 3: convert density back to physical bin counts (if desired)

For `3350` and `3351` with `width_2d=both`:

\[
\boxed{C(i,j)=D(i,j)
\frac{\Delta E_{x,i}}{\Delta E_{\rm ref}}
\frac{\Delta E_{y,j}}{\Delta E_{\rm ref}}.}
\]

For `energyTime`:

\[
\boxed{C(i,j)=D(i,j)\frac{\Delta E_{x,i}}{\Delta E_{\rm ref}}.}
\]

For other `width_2d` modes, invert **exactly the axes applied when encoding**; don't assume `both` if the metadata says otherwise. Decoded counts can be compared directly to `physical.root` and summed over time to reconstruct `3300` from `energyTime`.

### Step 4: optional unit-area normalization

If you want a probability **per cell**, divide the reconstructed count array by **its own total**:

\[
P(i,j)=C(i,j)/\sum_{i,j}C(i,j).
\]

If you want a density per energy cell area, divide by `ΔE_xΔE_y` as appropriate **after** unit-area normalization. For time evolution, a probability/rate per unit time is a separate choice. **Do not unit-normalize each component before adding**, or you will lose their physical mixture weights. In experiments, there may also be a distinct desired normalization to a known number of decays or acquisition live time; the software does not infer those quantities from the normalized ML output.

## 5. Numerical example: why direct addition fails

Suppose one output cell has a final density `D_final=100`, composed of main density 30 and pileup density 70. Take `D0=1` and the family maximum `Dmax=100`.

\[
L_{\rm main}=\frac{\ln31}{\ln101}\approx0.744,
\qquad L_{\rm pileup}=\frac{\ln71}{\ln101}\approx0.924.
\]

Their **logged sum is about 1.67**, even though the complete final logged cell should be `L_final=1`. Inverting instead gives `D_main=30`, `D_pileup=70`, and `D_final=30+70=100`, which then re-encodes as 1. Independent component max-normalization would hide the 30:70 relationship entirely and would not be reversible without external scale factors.

## 6. Decay-scheme matrix is a different normalization object

`ml.root:final/decaySchemeMatrix` encodes β feeding and first-γ-path probabilities, **not detected counts or a detector response histogram**. It is written from the decay XML when `PreprocessResponse` is called with `--decay-xml`. Its total integral is 1 to numerical precision. It receives **no energy-bin density correction and no shared-log transformation**.

It must not be added to, inverted with, or interpreted as a fourth `3350`-like signal component. It is a target/label describing the decay scheme.

## 7. Worked algorithm and validation checklist

The accompanying [Python example](../examples/ReconstructML.py) demonstrates decoding a ROOT `ml.root` with `uproot` and `numpy`, summing all elementary components, returning physical counts, and comparing against `physical.root`. That example requires `pip install uproot numpy`; it does not modify the ROOT files.

For each `h=3350,3351,energyTime`:

1. Load `ml.root:metadata/Transform_h` and parse `D0`, `Dmax`, `reference_width_kev`, `width_2d`.
2. Load all elementary ML histograms: `components/main`, every `components/contaminants/NAME`, `components/pileup_ss`, `components/pileup_sbkg`.
3. Decode **each** logged component using the **one** common family transform.
4. Sum decoded densities. Compare to decoded `final/h` and, optionally, re-encode and compare to stored `final/h`.
5. Invert width factors using the actual axis edges. Check equality against `physical.root:final/h` **within roundoff**.
6. If desired, normalize the complete physical counts to integral 1 **once**, after the component sum.
7. For `energyTime`, project decoded physical counts over time to recover `physical.root:final/3300`.
8. Keep the decay-scheme matrix untransformed; separately check that its probability integral is 1.

### Common incorrect operations

| Operation | Why wrong |
|---|---|
| Add ML components before inverting | Log mapping is nonlinear; the result is generally > or < the true final ML cell. |
| Normalize each component independently to maximum 1 | Erases actual source intensities. |
| Divide energyTime by time-bin width during **ML inverse** | Encoder never applied that factor. |
| Treat final ML histogram as unit-integral | The final **maximum** is one, not its integral. |
| Divide a component by `Dmax` instead of applying `expm1` | Reverses a linear mapping that was not used. |
| Use `final/3350` integral as the number of β decays | Each event can contribute multiple IMO crystal entries. |
| Expect raw Y=0 central/IMO entries in final 2D | Those entries were dropped by the final rebinner's 10-keV Y cutoff. |

Related reading: [exact pileup](PileupDetailed.md), [time evolution](TimeEvolutionDetailed.md), [output format](../reference/OutputFormats.md), [ML program](../programs/PreprocessResponse.md).
