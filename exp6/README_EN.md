# exp6: Sensitivity Analysis—Resource Capacity, Trust Penalty Coefficient, and Network Density

This update modifies only the first experiment, concerning resource capacity: all SMs are assigned the same per-node capacity \(C\), varied from 10 to 100 in increments of 10. The computational settings for the punishment-coefficient and network-density experiments remain unchanged. By default, the first experiment saves its results to the new `results/capacity_absolute` directory, preserving the previous results in `results/capacity`.

## Running the Experiments

Run the following commands from this folder:

```matlab
main_capacity_sensitivity   % Experiment 1: capacity C=10:10:100 for all SMs
main_penalty_sensitivity    % Experiment 2: punishment coefficient; original design retained
main_density_sensitivity    % Experiment 3: network density
```

To run all experiments:

```matlab
results = main_sensitivity;
```

To generate plots separately, run the following commands from the `exp6` folder:

```matlab
main_plot_sensitivity('capacity');
main_plot_sensitivity('density');
```

By default, these commands read `results/capacity_absolute` and `results/density`, respectively. New figures are saved to the `combined_GRA` subfolder within each directory in PDF, SVG, PNG, and FIG formats.

The default configuration uses four network topologies and 20 independent repetitions. Each resource-allocation experiment evaluates 200 paired attack/RRA samples per repetition. By default, GRA solves individual best-response problems using `fmincon` from Optimization Toolbox, with cyclic updates in the outer loop. GURA is solved independently using accelerated projected gradient with backtracking and restarts; GRA results are not reused as GURA solutions. An equivalent, faster water-filling solver is also available:

```matlab
main_density_sensitivity(struct('bestResponseSolver','analytic', ...
    'outputDir',fullfile(pwd,'density_analytic')));
```

For GRA, the default stopping threshold for the maximum individual improvement upper bound is `1e-6`, with a maximum of 5,000 sweeps and a check every five sweeps. For GURA, the global improvement upper-bound threshold is `1e-5`, with a maximum of 20,000 iterations. These two bounds have different meanings. Runs that do not satisfy their stopping criteria are recorded as `Converged=false` and marked with black crosses in the figures; they are not reported as converged.

## Experiment 1: Resource Capacity—Updated

The default setting is `capacities=10:10:100`. At each parameter value, the capacity vector is defined as `p.C=C*ones(N,1)`, assigning the same per-node resource capacity to all SMs. Here, \(C\) is neither a scaling multiplier nor the upper bound of a random capacity distribution.

The input topology, trustworthiness values, security levels, attack samples, and RRA allocation fractions remain fixed. Only capacity changes, and the GRA, GURA, and RRA allocations are recomputed at each value. The weights remain fixed at `w1=.4` and `w2=.6`, and the security-level formula is unchanged.

```matlab
results = main_capacity_sensitivity;
% Use the capacities field to specify absolute capacities, for example:
% main_capacity_sensitivity(struct('capacities',10:10:100));
```

The previous `rho` parameter has been removed from this experiment. The saved `legacyC0` variable is retained only to reproduce the attack/RRA random-number sequences from the previous version; it does not determine any capacity setting. The actual capacity vector is stored in the `C` field of each `diagnostics` entry.

Total security utility and system loss are reported for all three methods and saved to `results/capacity_absolute`. The horizontal axis is labeled “Resource capacity, C.” The main figure files are `capacity_Utility` and `capacity_Loss`, provided in PDF, SVG, PNG, and FIG formats. Previous results in `results/capacity` are not overwritten. When older results are replotted, the original “Capacity multiplier” label is retained.

## Experiment 2: Punishment Coefficient—Retained

The settings are `w=[1.1 2 3 5 10 20]`, `PT=[.1 .5]`, `PC=.5`, `K=20`, and a malicious-behavior probability of `.1`. Identical seeds reconstruct paired behavior records, so only the punishment setting changes. The outputs are the difference between the mean trustworthiness of normal and compromised nodes and the trust-ranking AUC, with normal nodes treated as the positive class expected to receive higher scores.

The corrections introduced in the previous version of `exp6` are retained by default:

- TOPSIS ideal solutions are calculated using actual neighbors only.
- Majority-vote penalties are applied according to the receiver and its normal neighbors.
- A neutral score of `0.5` is returned when the available information provides no basis for differentiation.
- Only evaluations from honest neighbors are included. Nodes without an honest evaluator are recorded as unobserved.

The original code disabled random false reports from normal nodes, so the default is `normalErrorRate=0`. All nodes share the same test indicator in each interaction round. Setting `trustMode='legacy'` enables comparison with the original treatment of non-neighbors and entire-row penalties, but does not guarantee bit-for-bit reproduction of the original random-number call sequence. The regenerated trust matrix `T` is not passed to the game solver in this experiment.

Results are saved to `results/penalty`. These algorithmic corrections should also be described in the manuscript; the resulting measurements should not be presented as outputs of the original, unmodified trustworthiness algorithm.

## Experiment 3: Network Density—Added

### Controlled Variables

- Fix `N=100` and retain the four spatial distributions: Random, Regular, Clustered, and Disconnected.
- Use the default mean degrees `meanDegrees=[2 4 6 8 10 12]`. The number of undirected edges is `N*meanDegree/2`, corresponding to 100, 200, 300, 400, 500, and 600 edges.
- Also record edge density, `D=2|E|/[N(N-1)]=meanDegree/(N-1)`, in the CSV output. Mean degree is used on the horizontal axis to represent the average number of potential collaboration neighbors per SM.
- Within each repetition, keep node positions, capacities, load-based priorities, pairwise trustworthiness values, and random attack sets fixed. Attacked nodes are sampled uniformly without replacement, with `PC=.1`. All three strategies face identical attack sets.
- Adding edges does not increase a node’s total resources. GRA, GURA, and RRA allocations are recomputed at every density setting.

### Network Construction and Connectivity

Input coordinates come from the four original user-provided `xy_net*.mat` datasets and are saved as `data/Coordinates_*.mat`. A minimum spanning tree based on Euclidean distance provides a fixed backbone, after which additional edges are added in order of distance. Every edge in a lower-density network is retained in higher-density networks, producing a nested sequence of networks.

Random, Regular, and Clustered each maintain one connected component. Disconnected is divided into four geographic components according to the original four centers. Edges are permitted only within components, and each component remains connected. This design separates the effect of increasing density from the effect of connecting previously disconnected components.

This experiment does not use a fixed 30-meter communication radius: backbone and additional edges may exceed 30 meters. It also does not enforce equal degree at every node. “Regular” refers to fixed, regular grid coordinates. The experiment compares resource-allocation performance across these controlled spatial networks at different mean degrees. Other mean-degree settings must be exactly realizable using integer numbers of edges within the components; the default even-valued settings satisfy this requirement.

### Trust Parameters for Added Edges

The original data provide trustworthiness values only for existing neighbors. Positive trustworthiness values for existing node pairs are retained. At the beginning of each repetition, values for potential new node pairs are sampled with replacement from the empirical distribution of positive trustworthiness values in that network. These values remain fixed across all density settings. The inputs include the complete `pairTrust` matrix, allowing parameter consistency on shared edges to be checked.

Trustworthiness values assigned to new edges are synthetic control variables. They are neither field observations nor values obtained by rerunning TOPSIS on each topology. This design isolates the effect of the number of available collaboration links. Recomputing trustworthiness would additionally capture the effect of topology changes on trust evaluation and would constitute a separate joint sensitivity experiment.

### RRA and Paired Comparisons

Random positive weights are generated for every directed edge in the highest-density network. Sparser networks use the same weights for their corresponding edges. The weights are then normalized separately for each resource provider so that its total allocation equals \(C_i\).

The underlying random weights on shared edges remain fixed, although actual resource fractions may change when new neighbors are added. Additional edges must not introduce additional resource capacity.

### Metrics and Interpretation

The following metrics are compared across GURA, GRA, and RRA:

1. Total security utility: `Uhat=sum_i xi_i*log(1+s_i)`.
2. System loss after an attack: `LA=sum_attacked kappa*xi_i/log(1+s_i)`, with `kappa=100`.

The third experiment uses the fixed priority definition:

```matlab
xi = (w1*max(SL_data.SL,[],2) + w2*mean(SL_data.SL,2)).*gamma;
```

The weights are not varied. The vector `gamma=1-0.5*rand(N,1)` is generated once per network in each independent repetition and remains fixed across all density settings within that repetition.

Because edges are added cumulatively, every previously feasible allocation remains feasible by assigning zero resources to new edges. Therefore, the exact optimal total security utility should not decrease. Numerical errors or incomplete convergence must be investigated separately. However, maximizing total utility does not imply that the monitoring level of every attacked node increases. Consequently, neither a monotonic decrease in `LA` nor a monotonic increase in RRA utility should be assumed.

## Data and Statistics

The security-level input is the user-provided `100×24` matrix in `data/SL.mat`. Both the capacity and density experiments call `private/s6_security_level.m`, which uses the following formula:

```matlab
gamma = 1-0.5*rand(N,1);
SL = (w1*max(SL_data.SL,[],2) + w2*mean(SL_data.SL,2)).*gamma;
```

The default weights are `w1=.4` and `w2=.6`. The vector `gamma=1-0.5*rand(N,1)` is generated once per independent repetition and remains fixed across all parameter values within that repetition. The 24 columns are no longer summed and interpreted as daily energy consumption, and no additional scaling is applied. The punishment-coefficient experiment does not use `SL` and remains unchanged. Security levels are held fixed across all capacity or density settings within each repetition.

By default, node coordinates are not resampled across the 20 repetitions. In the resource-capacity experiment, repetitions randomize `gamma`, attacks, and RRA allocation fractions; per-node capacity is determined by the selected value of \(C\). In the density experiment, repetitions continue to randomize capacities, `gamma`, attacks, RRA allocations, and trustworthiness values for added edges.

Error bars represent the standard deviation of repetition-level means across the 20 repetitions. They are neither the standard deviation of the 200 attack samples within a repetition nor confidence intervals.

If an attacked node has zero monitoring, its loss is recorded as `Inf`, as required by the model. No epsilon is added, and no finite cap is substituted. The CSV output records `InfiniteLossFraction` and `UnmonitoredFraction`. Values that cannot be plotted are left as gaps, and warnings are issued. Means are not calculated using only finite samples.

## Output Files

Each experiment’s results directory contains `trials.csv` with individual repetition results, `summary.csv` with aggregated results, `analysis_results.mat`, and figures in PDF, SVG, PNG, and FIG formats. The two density-experiment figures are:

- `density_Utility`: security utility versus mean degree.
- `density_Loss`: system loss versus mean degree.

For each topology and repetition, a MAT file stores the fixed inputs, adjacency matrices for all density settings, actual mean degrees, edge counts, connected components, GRA/GURA solutions, error measures, and convergence histories.

Interrupted experiments can be resumed when the configuration is unchanged. After changing the configuration, use a new `outputDir` or set `resume=false`.

## Validation

`main_smoke_test` uses all four topologies, one repetition per configuration, a reduced parameter grid, 10 attack samples, and the fast water-filling solver, with tolerances of `1e-5` and `1e-4`. It checks that the implementation runs successfully; it is not the complete manuscript experiment.

`validate_density` checks nesting, connectivity, trustworthiness consistency on shared edges, resource capacities, GRA/GURA feasibility, and optimal-utility trends in preliminary checks across the six default mean degrees. Validation records for the capacity update are provided in `VALIDATION.md`.

## Security-Level Formula Correction

Experiments 1 and 3 now consistently calculate security levels as the weighted maximum and mean, multiplied by `gamma`. Previous `dailyEnergy` results must not be mixed with results from this version. The configuration identifier has been updated to prevent incompatible cached results from being loaded. A new output directory is recommended:

```matlab
results=main_sensitivity(struct('outputDir',fullfile(pwd,'results_max_mean_gamma')));
```

When node positions, capacities, trustworthiness values, or attack samples differ from earlier experiments, the resulting metrics need not be identical. This correction addresses the inconsistent definition used to calculate security levels.