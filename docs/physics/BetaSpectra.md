# β− energy distributions and response-library sampling

**Implemented in:** `src/apps/GenerateResponse.cpp` (`InferredShape`, `ShapeFactor`, `BetaDensity`, `BetaSampler`, `NearestLibraryEnergy`).

The electron kinetic endpoint for a branch is `Q_beta - E_daughter`. For each branch, `BetaSampler` calculates a relativistic β− continuum with Coulomb/Fermi correction, a branch shape factor and an energy endpoint, then groups sampled probabilities into the discrete available monoenergetic library energies.

## Shape selection

The source accepts `BetaTransitionType` codes 0–4 from XML; when unspecified it estimates a type from spin/parity. With known opposite parity, ΔJ≈0,1,2 select codes 1,2,3; otherwise unknown/unsupported classification falls back to allowed code 0. `--all-allowed` applies allowed shape unless XML explicitly specifies otherwise. The code uses:

- `shape=0`: `C(T)=1` (allowed fallback).
- `shape=1`: `p²+ν²+2 β² ν E_e`.
- `shape=2`: `p²+ν²−(4/3) β² ν E_e`.
- `shape=3`: `p²+ν²`.
- `shape=4`: `p²+ν²+(2/3) β² ν E_e`.

Here `E_e=T+m_e`, `p²=T(T+2m_e)`, `ν=E_endpoint−T`, `β²=p²/E_e²`, with natural-energy units in these expressions. The program treats unknown shapes as allowed by design, rather than inventing a forbiddenness correction. The Fermi factor uses a numerically accumulated log of an Euler product and the chosen β− sign convention. **Atomic screening is not included** (`screening=disabled` in generated metadata).

## Discretization

`BetaSampler` uses a midpoint quadrature with `ceil(endpoint_keV)` integration cells (nominally about 1 keV each); each cell contributes to `NearestLibraryEnergy(T)`. The response event is selected from the matching pure-electron file. This discretization is not the same as making electron energy strictly continuous in the final detector simulation.

### Library energy limits

Current source constants are `minLibraryKeV=10`, `fineLibraryMaxKeV=1000`, `maxLibraryKeV=10000`; fine step 1 keV, coarse step 10 keV. The current deployed library ends at 10 MeV, matching the compiled guard. The 12-MeV output histogram range is a distinct choice.

## Assumptions

The generated β continuum samples kinetic energy of a β− particle, not nucleus recoil or internal conversion electrons. The source includes no atomic screening correction. Test behavior at unusual Qβ, unknown spin/parity and transition-type inputs before using such cases as physically reliable targets.
