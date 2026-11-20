# PreprocessResponse

**Source:** `src/apps/PreprocessResponse.cpp`, `src/preprocessing/SharedLogMath.*`, `src/decay/DecaySchemeMatrix*`. Input is a **clean physical weighted** ROOT file already rebinned by the mixture stage.

## CLI

```bash
bin/PreprocessResponse physical.root ml.root   [--config Preprocess.ini] [--decay-xml scheme_000000/Decay.xml]
```

`--config` and `--decay-xml` each accept a path. With `--decay-xml`, the program independently calculates the **untransformed** decay-scheme probability matrix and inserts it into `final/` in the same ML ROOT file. The campaign template supplies `--decay-xml` by default.

## Options from `[preprocessing]`

| Key | Default | Meaning |
|---|---:|---|
| `reference_width_kev` | `10` | Reference width used to turn counts into comparable energy-density values; positive finite |
| `width_2d` | `both` | `both`, `x_only`, `y_only`, `none` for 3350/3351; energyTime is always X-energy-only |
| `log_reference_density` | `1` | Positive `D0` for shared reversible logarithm |

For a 2D energy-energy histogram using `width_2d=both`, calculate `D=counts*(w_ref/ΔE_X)*(w_ref/ΔE_Y)`. For `energyTime`, `D=counts*(w_ref/ΔE_X)`; **no division by time width**.

For each family independently, compute `Dmax` on the **final** spectrum. Apply the same transformation to final and all corresponding components:

\[
L(D) = \frac{\ln(1+D/D_0)}{\ln(1+D_{\mathrm{max}}/D_0)}.
\]

Inverse: `D = D0*expm1(L*ln(1+Dmax/D0))`; recover counts by undoing the recorded bin-width factors. Only final has maximum 1 (if nonzero). Zero stays zero. **Logged components do not sum linearly**: invert them to physical counts first.

## Output and metadata

- `final/{3350,3351,energyTime}` as transformed `TH2D`, matching transformed elementary components.
- `final/decaySchemeMatrix`, `DecaySchemePathsCSV`, matrix conditions when `--decay-xml` is supplied.
- `metadata/Transform_3350`, `Transform_3351`, `Transform_energyTime` with common `Dmax`, `D0`, width convention and logarithm denominator; plus `PreprocessingConditions` and `PreprocessingReport`.

The physical input is preserved unchanged. No `final/3300` is included by default in ML output. This program rejects negative or nonfinite physical bins and missing final histograms; see [shared-log physics](../physics/SharedLog.md).
