# exp1: Smart Meter Trustworthiness Evaluation

This experiment evaluates the trustworthiness of normal and compromised smart meters (SMs). It examines the effects of the test-data probability `P_T` and the compromised-node proportion `P_C`. Two figures are generated for each network: a trustworthiness distribution at a fixed `P_C`, and mean trustworthiness curves over varying `P_C`.

The main entry point is `main_trust_evaluation.m`. This directory contains the trustworthiness experiment; it does not solve the GRA/GURA resource-allocation problems or calculate security utility or system loss.

This README describes the source code supplied in `exp1.zip`. **The current defaults are `P_T = [0.3 0.5 0.7 0.9]`, 1,000 repetitions per parameter combination, and the uniformly random network only.** Saved results for that network are included and can be replotted directly.

## 1. Requirements

- MATLAB with support for the functions and language features used in the code, including `tiledlayout`, `exportgraphics`, `savefig`, `jsonencode`, and implicit array expansion.
- The full experiment requires MATLAB's Java Virtual Machine because cache hashes use Java's SHA-256 implementation. Do not launch the full experiment with `-nojvm`.
- The code does not call Optimization Toolbox or Parallel Computing Toolbox. The hatching functions are included; no external hatching toolbox is required.
- Figures use Times New Roman. Their appearance may differ if the font is unavailable on the system.

The entry points, default parameters, and statistical definitions in this README were checked against the source code and supplied figure captions. The full simulations and minimum MATLAB version compatibility were not retested for this documentation update.

## 2. Directory Structure

```text
exp1/
├── README.md
├── main_trust_evaluation.m       # Compute, save, and plot results
├── main_plot_trust.m             # Replot saved results
├── data/
│   ├── xy_net1_Random.mat
│   ├── xy_net2_Regular.mat
│   ├── xy_net3_Cluster.mat
│   └── xy_net4_Disconnected.mat
├── private/
│   ├── te_options.m              # Defaults and input validation
│   ├── te_load_network.m         # Construct adjacency from coordinates
│   ├── te_trustworthiness.m      # Trustworthiness evaluation
│   ├── te_run.m                  # Parameter sweeps, repetitions, and caching
│   ├── te_hash.m                 # Hashes for caches and random seeds
│   ├── te_plot.m                 # Figures and hatch patterns
│   ├── te_export.m               # Figure export
│   └── te_write_tables.m         # CSV and caption export
└── results/
    ├── analysis_results.mat      # Aggregated results and configuration
    ├── cache/                    # Completed parameter combinations
    ├── mean_trustworthiness.csv
    ├── trust_distribution.csv
    ├── figure_captions.txt
    └── Exported figures
```

Keep `private/` beside the main functions. Its functions are called internally and do not need to be run separately. Any `__MACOSX/` directories and `.DS_Store` files in the archive are operating-system metadata and are not used by the experiment.

## 3. Quick Start

Set MATLAB's **Current Folder** to the extracted `exp1` directory. All examples below assume this starting location.

### 3.1 Replot the included results

```matlab
results = main_plot_trust;
```

This loads `results/analysis_results.mat`, displays the figure windows, and regenerates both figure types using the saved configuration. **It does not rerun the trustworthiness simulations.**

If moving the directory or using another computer produces a `Data folder does not exist` error, follow the path-repair procedure in Section 9.

To export the regenerated figures to a separate directory:

```matlab
base = pwd;
plotOptions = struct;
plotOptions.visible = 'on';
plotOptions.outputDir = fullfile(base,'replots');
plotOptions.formats = {'pdf','svg','png','fig'};

results = main_plot_trust(fullfile(base,'results'),plotOptions);
```

`main_plot_trust` exports figures only. It does not write additional aggregated MAT, CSV, or caption files to `replots`.

### 3.2 Run the full experiment with default settings

```matlab
results = main_trust_evaluation;
```

Matching cached results are reused by default; parameter combinations without a matching cache are computed. The default is `visible='off'`, so figure windows may not remain open even though the figures have been exported to `results/`.

To display figures during a full run:

```matlab
results = main_trust_evaluation(struct('visible','on'));
```

### 3.3 Run a small trial first

```matlab
options = struct;
options.repetitions = 10;
options.attackRates = [0.1 0.5 0.9];
options.visible = 'on';
options.outputDir = fullfile(pwd,'results_quick');

results = main_trust_evaluation(options);
```

This is a quick configuration for checking the workflow, rather than the full configuration with 1,000 repetitions per parameter combination. `attackRates` must include `distributionPC`, which is `0.5` by default.

## 4. Experimental Configuration

### 4.1 Networks and simulated attacks

- Fixed synthetic network coordinates are loaded from `data/`. The topology is not regenerated for each repetition.
- An undirected link is created when the Euclidean distance between two nodes is strictly less than `radius`. Self-links are removed.
- The number of nodes is determined by the number of rows in the coordinate matrix. The included random-network results use `N=100`.
- A network may contain multiple connected components, but the current implementation requires every node to have at least one neighbor.
- In each repetition, `floor(P_C*N)` compromised nodes are sampled uniformly without replacement from all `N` nodes. Thus, the realized proportion for a custom network is `floor(P_C*N)/N`.
- Each repetition contains 20 interaction rounds by default. Each round is designated as a test-data round with probability `P_T`; all nodes in that repetition share these test-round indicators.
- Reduced resource contributions and abnormal behavior by compromised nodes are generated using separate random draws with probability `maliciousProbability`. No additional independent random false reports are introduced for normal nodes, although normal nodes can still be affected by the implemented majority-vote penalty rule.

### 4.2 Default parameters

Parameters can be overridden through the `options` structure. Defaults are defined in `private/te_options.m`.

| Field | Default | Description |
|---|---|---|
| `networks` | `{'Random'}` | Networks to evaluate |
| `testRates` | `[0.3 0.5 0.7 0.9]` | Test-data probabilities `P_T` |
| `attackRates` | `0.05:0.05:0.95` | Compromised-node proportions `P_C` |
| `distributionPC` | `0.5` | `P_C` used for the distribution figure |
| `repetitions` | `1000` | Repetitions per `(network, P_T, P_C)` combination |
| `rounds` | `20` | Interaction rounds per repetition |
| `radius` | `30` | Communication distance threshold, in the units of the coordinates |
| `maliciousProbability` | `0.1` | Probability of the corresponding malicious behavior |
| `punishment` | `10` | Penalty coefficient for abnormal behavior identified through test data |
| `resource` | `1` | Resource contribution per directed link under normal cooperation |
| `epsilon` | `1e-10` | Denominator stabilization constant for normalization and trust calculation |
| `seed` | `20260924` | Base value used to derive parameter-specific random seeds |
| `binEdges` | `0:0.2:1` | Histogram bin boundaries |
| `resume` | `true` | Whether to reuse matching caches |
| `plotResults` | `true` | Whether to plot after computing results |
| `visible` | `'off'` | Figure visibility during a full run |
| `formats` | `{'pdf','svg','png','fig'}` | Figure export formats |
| `dataDir` | `data/` beside the main functions | Input directory |
| `outputDir` | `results/` beside the main functions | Output and cache directory |

The default configuration contains `4 × 19 = 76` parameter combinations per network, corresponding to 76,000 randomized simulations. The distribution figure reuses the results at `P_C=0.5`; no separate simulation is performed for that figure.

### 4.3 Evaluate all four networks

```matlab
options = struct;
options.networks = {'Random','Regular','Clustered','Disconnected'};
options.outputDir = fullfile(pwd,'results_all_networks');

results = main_trust_evaluation(options);
```

Each network produces two separate figures, giving eight figures for all four networks. The networks are not combined into a single figure. The option name `Clustered` maps to `xy_net3_Cluster.mat`; this spelling difference is intentional in the current loader.

### 4.4 Change test probabilities or other simulation parameters

For example, to use `P_T=[0.1 0.3 0.5 0.7]`:

```matlab
options = struct;
options.testRates = [0.1 0.3 0.5 0.7];
options.outputDir = fullfile(pwd,'results_PT_01357');

results = main_trust_evaluation(options);
```

Use `main_trust_evaluation` when changing simulation parameters. `main_plot_trust` accepts only the overrides `visible`, `outputDir`, and `formats`; it cannot change experimental settings or recompute data.

`testRates` and `attackRates` must be strictly increasing. Each attack-rate setting must leave at least one normal node and one compromised node. Use separate output directories for different configurations to avoid overwriting summary files and figures with the same names.

## 5. Statistics and Figure Interpretation

### 5.1 Trustworthiness distribution

Filename: `trust_distribution_<Network>.*`.

- `P_C` is fixed at `distributionPC`; subplots correspond to different `P_T` values.
- Normal SMs use blue diagonal hatching; compromised SMs use red crosshatching.
- The default bins are `[0,0.2)`, `[0.2,0.4)`, `[0.4,0.6)`, `[0.6,0.8)`, and `[0.8,1]`.
- Neighbor-to-target evaluation scores are pooled across repetitions and grouped by whether the target is normal or compromised. Percentages are normalized separately within each group, so each distribution sums to 100%.

### 5.2 Mean trustworthiness curves

Filename: `mean_trustworthiness_<Network>.*`.

- The horizontal axis is `P_C`; subplots correspond to different `P_T` values.
- Blue curves with circular markers represent normal SMs. Red curves with square markers represent compromised SMs.
- Within each repetition, the mean is calculated over all valid neighboring evaluations received by targets in the same group. These repetition-level means are then averaged across repetitions.
- Error bars show one sample standard deviation across repetition-level means (`std(...,0,1)`), not standard errors or confidence intervals.

These statistics are **weighted by evaluation edges** and include both normal and compromised evaluators. A target with more neighboring evaluations contributes more weight to the pooled mean. The implementation does not first compute an equally weighted mean for each target, and it does not restrict evaluators to normal nodes. The manuscript should use the same statistical definitions.

## 6. Output Files and Accessing Results

| Output | Contents |
|---|---|
| `analysis_results.mat` | The `results` structure: options, topology, summary statistics, and repetition-level group means |
| `mean_trustworthiness.csv` | Group means, standard deviations, and repetition counts for each network, `P_T`, and `P_C` |
| `trust_distribution.csv` | Group percentages in each bin and bin-boundary information |
| `figure_captions.txt` | English captions generated from the actual run configuration |
| `trust_distribution_<Network>.*` | Trustworthiness distribution figure |
| `mean_trustworthiness_<Network>.*` | Mean trustworthiness figure |
| `cache/<Network>_<hash>.mat` | Results and configuration for one parameter combination |

PDF and SVG figures are exported as vector graphics. PNG files use 300 dpi. FIG files retain MATLAB graphics objects.

To inspect the random-network results:

```matlab
z = load(fullfile(pwd,'results','analysis_results.mat'),'results');
results = z.results;
r = results.Random;

results.options.testRates     % P_T values used in this run
results.options.attackRates   % P_C values used in this run
results.groupOrder            % {'Normal','Compromised'}
r.meanTrust(:,:,1)            % Normal-SM means
r.meanTrust(:,:,2)            % Compromised-SM means
r.stdTrust                   % SD across repetition-level means
r.pointSeeds                 % Random seed for each parameter combination
```

Let `np` be the number of attack rates, `nt` the number of test probabilities, `nb` the number of bins, and `R` the number of repetitions:

| Field | Dimensions |
|---|---|
| `meanTrust`, `stdTrust` | `np × nt × 2` |
| `trialMeans` | `R × np × nt × 2` |
| `histCounts`, `histPercent` | `nb × nt × 2` |
| `distributionObservations` | `nt × 2` |
| `pointSeeds` | `np × nt` |

The final dimension follows the order normal, then compromised. The complete edge-level trust matrix `T` is not saved separately for every repetition.

## 7. Caching and Reproducibility

Completed parameter combinations are cached separately. After an interruption, rerunning with the same configuration reuses completed combinations. A combination interrupted before it was fully saved must be recomputed.

Cache keys include the network adjacency, `P_T`, `P_C`, repetition count, bin boundaries, core model parameters, and a hash of the trustworthiness function's source code. Changing only figure formatting does not invalidate the simulation cache. Editing `te_trustworthiness.m` changes its source hash, so the next full run uses new cache keys. **Replotting alone still uses the saved aggregated results and does not automatically recompute them.**

Seeds are derived separately from configuration hashes. Consequently, the implementation does not enforce shared compromised-node sets or shared random interaction histories across different `P_T` or `P_C` values. The same configuration, adjacency, and trustworthiness source code define the reproducible random computation procedure. Parameter-specific seeds are stored in `pointSeeds`.

To ignore existing caches and recompute:

```matlab
options = struct;
options.resume = false;
options.outputDir = fullfile(pwd,'results_fresh');

results = main_trust_evaluation(options);
```

Editing the statistical logic in `te_run.m` does not automatically change the trustworthiness source hash. After such changes, use a new output directory or `resume=false` to avoid reusing caches produced by the previous logic.

## 8. Algorithm Version Notes

The archive retains the majority-vote and TOPSIS rules of the supplied trustworthiness implementation, including full-row assignments when the majority-vote condition holds and the use of whole rows for some ideal-solution calculations. These rules are implemented in `private/te_trustworthiness.m`; this documentation update does not modify them.

The final calculation in the current source is:

```matlab
T = (Adj.*dn)./(dn+dp+o.epsilon);
```

For adjacent nodes, this corresponds to:

$$
\tau_{ij}=\frac{d_{ij}^{-}}{d_{ij}^{+}+d_{ij}^{-}+\varepsilon}.
$$

**The numerator does not contain `epsilon`.** When both distances are zero, this implementation returns zero; it does not assign a tie score of 0.5 or 1. The denominator stabilization constant also does not guarantee strictly positive trust scores on every edge.

Adding `epsilon` to the numerator, restricting ideal-solution calculations to neighbors, or changing the tie rule defines a different algorithm version. If the manuscript adopts such a version, the implementation and corresponding results must be updated together; changing captions alone is insufficient. This README describes the version actually present in the archive.

## 9. Troubleshooting

### 9.1 No figure window appears

The full experiment defaults to `visible='off'` for automatic export. Set `visible='on'`, or run `main_plot_trust` to display saved results.

To open a FIG file whose saved visibility is off:

```matlab
fig = openfig(fullfile(pwd,'results','trust_distribution_Random.fig'), ...
    'new','visible');
set(fig,'MenuBar','figure','ToolBar','figure');
plotedit(fig,'on');
```

Hatched bars consist of individual line segments and patches, and mouse selection is disabled for some objects. To change fonts, hatching, or colors consistently, edit `private/te_plot.m` and replot. The hatched graphics should not be treated as a single ordinary MATLAB `bar` object.

### 9.2 Replotting on another computer reports a missing data directory

`analysis_results.mat` stores absolute paths from the original run, and `main_plot_trust` validates the saved `dataDir`. An obsolete path can therefore cause an error even when only replotting.

The following creates a result copy with corrected paths in a separate directory. It leaves the original aggregated file and numerical results unchanged:

```matlab
base = pwd;  % Current Folder must be the extracted exp1 directory
sourceDir = fullfile(base,'results');
replotDir = fullfile(base,'results_relocated');
if ~isfolder(replotDir), mkdir(replotDir); end

z = load(fullfile(sourceDir,'analysis_results.mat'),'results');
results = z.results;
results.options.dataDir = fullfile(base,'data');
results.options.outputDir = replotDir;
save(fullfile(replotDir,'analysis_results.mat'),'results','-v7');

main_plot_trust(replotDir,struct('visible','on'));
```

### 9.3 How do I change fonts, panel labels, hatching, or export quality?

- Tick-label and axis-label font sizes: edit `styleAxes` in `te_plot.m`.
- Panel-label size and position: edit `panelLabel`.
- Hatch spacing, line thickness, and bar widths: edit `hatch.spacing`, `hatch.lineWidth`, `hatch.groupWidth`, and `hatch.barFraction`.
- Export settings: edit `te_export.m`, or select output formats using `formats`.
- After changing the layout or window dimensions, rerun `main_plot_trust` so the hatch geometry is calculated from the final axes dimensions.

These plotting changes do not require recomputing trustworthiness values.

### 9.4 Changing the communication radius produces an isolated-node error

The current model requires every SM to have at least one neighbor. Check the coordinates and `radius`; do not simply remove the assertion, because the subsequent trust statistics rely on valid neighboring evaluations.

### 9.5 How can I confirm which parameters produced a figure?

Inspect `results.options` in the actual result file and the `figure_captions.txt` generated by the same run. Figure filenames do not encode `P_T` or the repetition count, so filenames alone cannot identify the configuration.
