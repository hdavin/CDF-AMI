# Net: Four SM Network Datasets

This package reorganizes the supplied `net_generate.m` into main functions, private helpers, and saved results, following the structure of the preceding experiments. Generated datasets and topology figures are included.

## Run

Set the MATLAB current folder to this `Net` directory and run:

```matlab
datasets = main_generate_networks;
```

Defaults: four topologies, 100 SMs per topology, a 200-by-200-meter deployment area, and an undirected edge exactly when the Euclidean distance is strictly less than 30 meters. Self-edges are excluded. Optimization Toolbox and NIRA are not required. The code uses MATLAB's `graph`, `conncomp`, `tiledlayout`, and `exportgraphics`; it has been validated in MATLAB R2026a.

```matlab
main_plot_networks;       % Replot existing results without regenerating data
main_validate_networks;   % Validate geometry, saved files, and reproducibility
```

Use another seed and output directory:

```matlab
datasets = main_generate_networks(struct( ...
    'seed',20260930, ...
    'visible','off', ...
    'outputDir',fullfile(pwd,'results_seed2')));

main_plot_networks(fullfile(pwd,'results_seed2'));
main_validate_networks(fullfile(pwd,'results_seed2'));
```

Generate one topology:

```matlab
datasets = main_generate_networks(struct( ...
    'networks',{{'Random'}}, ...
    'outputDir',fullfile(pwd,'results_random')));
```

The default base seed is `20260929`. Each topology uses a fixed seed offset, so its coordinates do not depend on the requested topology order. The caller's random-number state is restored after generation. Reusing an output directory updates the selected network files and the current run's summary. Use separate output directories to preserve different configurations. Replotting and validation use the topology list in the most recently saved summary.

## Network Definitions

| Topology | Coordinate rule | Acceptance condition |
|---|---|---|
| Random | Uniform coordinates in the deployment square | One connected component |
| Regular | A 10-by-10 grid from `linspace(15,185,10)` | One connected component |
| Clustered | Five centers: (100,100), (40,40), (160,40), (40,160), (160,160); 20 nodes per cluster | One connected component |
| Disconnected | Four centers: (40,40), (40,160), (160,40), (160,160); 25 nodes per cluster | Exactly four connected components, one per geographic cluster |

Clustered and Disconnected retain the original shared pool of 1,000 uniformly sampled candidate points. Each cluster includes its center. Other points are selected in pool order, without reusing a point, at center distances in `(0.3*Lim,1.2*Lim)` and `(0.3*Lim,1.7*Lim)`, respectively. All coordinates lie inside the deployment square.

The original undefined `xy` and `Edge` references and the erroneous assignment of adjacency entries into the regular coordinate matrix have been corrected. The missing external functions `isconnected` and `plot_net` are no longer needed.

The supplied script did not guarantee connectivity for Clustered or exactly four components for Disconnected. This version adds rejection sampling of complete coordinate sets to enforce the conditions above. It does not insert edges beyond the distance threshold or shrink the original sampling annuli. Insufficient candidate pools are resampled. Generation fails explicitly after `maxAttempts=10000` unsuccessful attempts instead of looping indefinitely. These connectivity selection conditions should be stated when describing the generated data.

Mean degree follows from the coordinates and distance threshold; it is not explicitly constrained. This is not the controlled sparse generator used in the earlier scalability experiment. Changing `nodeCount`, `areaSize`, or `radius` changes the network distribution. Regular requires a perfect-square node count. Grid locations and cluster centers scale proportionally with `areaSize`.

## Files and Data

```text
Net/
  main_generate_networks.m
  main_plot_networks.m
  main_validate_networks.m
  private/
  reference/net_generate_original.m
  results/
    data/
      Network_Random.mat       Complete topology; likewise for the other networks
      Coordinates_Random.mat   Coordinate alias; likewise for the other networks
      xy_net1_Random.mat
      xy_net2_Regular.mat
      xy_net3_Cluster.mat
      xy_net4_Disconnected.mat
    figures/network_topologies.pdf/.svg/.png/.fig
    network_datasets.mat
    network_summary.csv
    validation_summary.csv
```

Each `Network_*.mat` contains `N`, `xy` (N-by-2 coordinates in meters), `Adj` (N-by-N adjacency), `Lim` (connection threshold), `degree`, `component`, `group` (sampling-cluster membership), `name`, and `metadata`. Metadata include seeds, attempts, component sizes, sampling radii, and the MATLAB version.

Coordinate files contain `xy` and a legacy variable alias such as `Net1_Random_xy` or `Net3_Cluster_xy`. The aggregate `network_datasets.mat` contains the selected dataset structures, summary table, and options.

```matlab
S = load(fullfile('results','data','Network_Random.mat'));
xy = S.xy;
Adj = S.Adj;
N = S.N;
```

## Use in Subsequent Experiments

The trustworthiness experiment can read the coordinate filenames directly by setting its `dataDir` and using the same radius. From the trustworthiness experiment folder, assuming it and `Net` are siblings:

```matlab
options = struct;
options.dataDir = fullfile('..','Net','results','data');
options.networks = {'Random','Regular','Clustered','Disconnected'};
options.radius = 30;
options.outputDir = fullfile(pwd,'results_new_networks');
analysis = main_trust_evaluation(options);
```

Adjust paths as needed. Use a fresh experiment output directory to avoid reusing cached results from an older topology.

This package generates **network topology data**. The supplied script does not define new `TV`, `SL`, `C`, or `GAME` parameters, so this package does not create game `Parameter_*.mat` or `Data_*.mat` files. Resource-allocation experiments require matching trustworthiness values, security levels, and capacities generated for the new topology. Do not combine these coordinates with unrelated parameters from a previous topology. The density experiment's `Coordinates_*.mat` inputs should likewise be consistent with its baseline node and network parameters.

## Figures

The four networks appear in one 2-by-2 figure. Red nodes represent SMs, blue lines represent communication links, and both coordinate axes use meters. PDF and SVG are vector formats; PNG uses 300 dpi. FIG files retain native editable MATLAB objects and are saved with `Visible='on'`.

```matlab
fig = openfig(fullfile('results','figures','network_topologies.fig'),'new','visible');
plotedit(fig,'on');
```

## Validation

Checks cover coordinate bounds and uniqueness, symmetric adjacency without self-edges, exact agreement with the strict distance rule, absence of isolated nodes, required component structure, cluster sampling distances, consistency of saved aliases, and regeneration from the same seeds. See `VALIDATION.md` and `results/validation_summary.csv` for the actual results.
