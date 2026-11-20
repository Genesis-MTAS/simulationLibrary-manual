# β feeding × first-γ probability matrix

**Implemented in:** `src/decay/DecaySchemeMatrixModel.cpp` and `DecaySchemeMatrixRoot.cpp`.

This is **not a detector response histogram** and it does **not** enumerate all later γ transitions in its two axes. It represents the information from the **β-fed excitation level and destination of the first γ transition** (with the direct β-to-ground-state path mapped to coordinate `(0,0)`).

`decaySchemeMatrix` is a `TH2D` with X = beta-fed daughter excitation energy and Y = first-γ destination excitation energy. For each allowed β+first-γ path the weight is the β feeding probability multiplied by its first-γ branching probability; multiple paths within the same X,Y bin **sum**, not overwrite. The exact path data also appear as `DecaySchemePathsCSV`, and `DecaySchemeMatrixConditions` records source details, normalization and `stop_level=ignored_by_design`.

The model ignores `StopLevel` because that simulation termination marker is not a restriction on the physical β feeding × first γ representation. The matrix integral is verified as 1 (tolerance `1e-9` in `DecaySchemeMatrixRoot.cpp`), including direct β feeding to ground state. No ML logarithm is applied to this probability matrix.
