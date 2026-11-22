# NERSC execution and scaling

Use `mtas` on login, then choose the versioned installation ([Installation](Installation.md)). Keep the runtime and binaries on Global Common, active response and output on Scratch, and durable input masters and verified archive bundles on CFS/HPSS. Global Common is read-only on compute nodes; submit with writable working directory and absolute log paths.

The production controller creates one scheme job plus dependent independent one-node shard tasks. Perlmutter CPU nodes have 128 physical cores and 256 logical CPUs; the tested workload uses 256 workers per node and four successive waves of 256 cases in a 1,024-case shard. The scheme stage is separate. The controller checks allocated CPU count and affinity; do not oversubscribe. Worker count, shard size and node throttle are distinct.

| Objective | Measured recommendation |
|---|---|
| Minimize allocated node-hours | 4 concurrent nodes |
| High aggregate throughput | Up to 32 concurrent nodes; 16 intermediate |
| New physics or altered event count | Small representative pilot and scale tests |

Use 1,024 cases/shard initially and 256 workers for the tested full workload. New settings are editable before freeze. After freeze, only scheduling throttle may be overridden using `scontrol update JobId=ARRAY ArrayTaskThrottle=N`; do not change case ranges. The scheduler may delay or stagger allocations. For explicit initial ranges and resume see [New campaign](NewCampaign.md).

The 100k campaign passed at 2, 4, 8, 16 and 32 nodes. Full measured table, cost, outliers and limitations: [Performance and storage](PerformanceAndStorage.md). Larger shard sizes and >32 nodes are untested. Do not use old 136I numbers to predict a full 92Y+92Sr campaign. Use [Checking jobs](CheckingJobs.md) for accounting and [Recovery](Recovery.md) for interrupted submissions. Historical single-node packed launcher documentation is retained at [Packed workers](PackedWorkers.md).
