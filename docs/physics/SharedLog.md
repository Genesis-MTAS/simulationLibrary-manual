**Detailed implementation chapter:** [Read the full audited treatment](NormalizationAndReconstruction.md). This page is a shorter overview.

# Shared reversible logarithmic ML mapping

**Implemented in:** `src/apps/PreprocessResponse.cpp`, `src/preprocessing/SharedLogMath.cpp`. **Input:** physically weighted, linear and already rebinned histograms. **Output:** nonlinearly transformed ML histograms.

For a physical bin count `C`, form density `D` using energy widths. Standard 2D energy-energy correction uses both X and Y widths, referenced to `reference_width_kev=10`; energyTime corrects only the energy axis, **not the time width**.

For histogram family `h`, define `Dmax_h = max(D(final_h))` and use the common positive `D0 = log_reference_density`. Apply the same mapping to the final histogram and all its elementary components:

\[
L_h(D) = \frac{\ln(1 + D/D_0)}{\ln(1 + D_{\mathrm{max},h}/D_0)}.
\]

The inverse, using stored shared metadata, is:

\[
D = D_0\left[\exp\left(L_h\ln(1 + D_{\mathrm{max},h}/D_0)\right)-1\right].
\]

The implementation uses `log1p` and `expm1` for improved precision. Zero maps to zero and any positive input remains positive. Only the **final** family's largest cell reaches 1 (if nonzero), while component maxima are generally smaller. Logged components do not add linearly. To reconstruct original weighted `final`, invert the components and divide by energy-bin width factors before summation.

The `decaySchemeMatrix` is a separate probability object; it is written **without** width correction or log scaling.
