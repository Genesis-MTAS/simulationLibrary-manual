"""Inspect a produced MTAS ml.root and reconstruct final linear-count spectra.

Requires: python -m pip install numpy uproot
Usage: python ReconstructML.py /path/ml.root [/path/physical.root]
Read-only example; output is stdout. Assumes current TObjString metadata keys.
"""
import sys
import numpy as np
import uproot


def transform_settings(root, family):
    obj = root[f"metadata/Transform_{family}"]
    # uproot's TObjString behavior converts to the stored text with str(...).
    text = str(obj)
    fields = dict(line.split("=", 1) for line in text.splitlines() if "=" in line)
    return {
        "dmax": float(fields["final_max_density"]),
        "d0": float(fields["log_reference_density"]),
        "ref": float(fields["reference_width_kev"]),
        "mode": fields["width_2d"].strip(),
    }


def to_linear_density(log_values, settings):
    if settings["dmax"] == 0:
        return np.zeros_like(log_values)
    return settings["d0"] * np.expm1(
        log_values * np.log1p(settings["dmax"] / settings["d0"])
    )


def density_to_counts(density, edges_x, edges_y, settings, family):
    ref = settings["ref"]
    dx = np.diff(edges_x)[:, None]
    dy = np.diff(edges_y)[None, :]
    result = density.copy()
    if family == "energyTime" or settings["mode"] in ("both", "x_only"):
        result *= dx / ref
    if family != "energyTime" and settings["mode"] in ("both", "y_only"):
        result *= dy / ref
    return result


def main(ml_path, physical_path=None):
    with uproot.open(ml_path) as f:
        physical = uproot.open(physical_path) if physical_path else None
        try:
            keys = f.keys(recursive=True, cycle=False)
            components = sorted({
                key.rsplit("/", 1)[0]
                for key in keys
                if key.startswith("components/") and key.endswith("/3350")
            })
            print("Elementary components:", components)
            for family in ("3350", "3351", "energyTime"):
                settings = transform_settings(f, family)
                final_h = f[f"final/{family}"]
                final_log = final_h.values(flow=False)
                linear = np.zeros_like(final_log, dtype=float)
                for component in components:
                    h = f[f"{component}/{family}"]
                    linear += to_linear_density(h.values(flow=False), settings)
                final_density = to_linear_density(final_log, settings)
                np.testing.assert_allclose(linear, final_density, rtol=1e-9, atol=1e-9)
                counts = density_to_counts(
                    linear, final_h.axis(0).edges(), final_h.axis(1).edges(), settings, family
                )
                if physical is not None:
                    np.testing.assert_allclose(
                        counts, physical[f"final/{family}"].values(flow=False),
                        rtol=1e-9, atol=1e-8
                    )
                if family == "energyTime" and physical is not None:
                    np.testing.assert_allclose(
                        counts.sum(axis=1), physical["final/3300"].values(flow=False),
                        rtol=1e-9, atol=1e-8
                    )
                total = counts.sum()
                unit_area = counts / total if total else counts
                print(f"{family}: counts={total:.8g}, unit-area sum={unit_area.sum():.12g}, "
                      f"final ML max={final_log.max():.8g}, checked")
        finally:
            if physical is not None:
                physical.close()


if __name__ == "__main__":
    if len(sys.argv) not in (2, 3):
        raise SystemExit(__doc__)
    main(sys.argv[1], sys.argv[2] if len(sys.argv) == 3 else None)
