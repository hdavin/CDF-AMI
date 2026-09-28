# exp2: Scalability Experiment for Cyclic Best-Response Resource Allocation
## Running the Experiment

Place the complete `exp1-add` folder in your MATLAB working directory, open that folder, and run:

```matlab
results = main_scalability;
```

By default, the experiment evaluates four topologies with `N=200:200:10000` and a mean degree of six. Each configuration is repeated independently three times, giving 600 solver runs. Only scalability figures are generated; attack and system-loss experiments are not performed. MATLAB must support `graph`, `delaunayTriangulation`, `tiledlayout`, and `exportgraphics`. The main experiment does not require Optimization Toolbox.

To first check the environment and solver:

```matlab
results = main_pilot;
```

The pilot experiment evaluates each topology at 200, 1,000, and 10,000 nodes, with one repetition per configuration and limits of 30 seconds and 200 sweeps. It also independently compares 40 local optimization problems against `fmincon` from Optimization Toolbox. If that toolbox is unavailable, call:

```matlab
results = main_scalability(struct('sizes',[200 1000 10000], ...
    'repetitions',1,'maxSweeps',200,'timeLimitSeconds',30, ...
    'outputDir',fullfile(pwd,'my_pilot_results')));
```

To run the mean-degree sensitivity experiment, comprising 2,400 solves:

```matlab
results = main_scalability(struct('targetDegrees',[2 4 6 8], ...
    'outputDir',fullfile(pwd,'degree_results')));
```

To increase the solver limits and number of independent repetitions:

```matlab
results = main_scalability(struct('repetitions',5,'maxSweeps',2000, ...
    'timeLimitSeconds',600,'outputDir',fullfile(pwd,'extended_results')));
```

Runs with the same configuration can resume automatically. After changing computational settings, use a different `outputDir` or set `resume=false`. Completed cases are retained after an interruption. Calling `replot_figures('path_to_results')` regenerates figures without rerunning the computations.

## Relationship to the Original Experiment

The experiment uses utility:

`U_i=sum_j SL_j*log(1+s_j)`,

where `s_j=sum_i a_ij*x_ij`. Resource constraints require each node's allocations to be nonnegative and their sum not to exceed its capacity. Total security utility is `sum_j SL_j*log(1+s_j)`; it is not the sum of all individual utilities. Nodes update sequentially in a fixed order during each sweep, and subsequent nodes use the latest allocations.

This experiment evaluates only the cyclic best-response solution procedure used by GRA. To prevent general-purpose optimizer initialization and linear-algebra overhead from obscuring the algorithm's scaling behavior, the local concave logarithmic problems are solved using a sorting-based water-filling method. This method is mathematically equivalent to solving the original local optimization problem. The utility function, resource constraints, and outer update order remain unchanged. Consequently, the measured runtimes should not be presented as measurements of the original NIRA or `fmincon` implementations.

For the current node, define `b_j=1+s_j-a_ij*x_ij`. The local solution is

`z_j=max(0,SL_j/lambda-b_j/a_ij)`.

The active set is determined by sorting `SL_j/(b_j/a_ij)`, and the resource constraint is satisfied with equality. Positive weights ensure that this local problem has a unique solution. Rescaling to the feasible set is applied only when floating-point errors cause a slight capacity violation.

## Network Design: Explicit Changes to the Original Generation Rules

A fixed 200 × 200 region and a 30-meter communication radius cannot simultaneously accommodate increasing node counts and maintain a sparse mean degree. This experiment retains the four spatial distribution types while allowing the spatial scale to grow with `sqrt(N)`. A minimum spanning tree is constructed from Delaunay and two-hop spatial candidate edges, after which the shortest remaining candidate edges are added to control the mean degree.

These are **controlled sparse spatial graphs**. They are neither direct extensions of the original rule of connecting every pair less than 30 meters apart nor unrestricted samples of fixed-radius random geometric graphs.

- **Random:** Uniformly random coordinates with a connected network.
- **Regular:** Regular grid coordinates, using an incomplete final row when the node count is not a perfect square; the network is connected.
- **Clustered:** Five spatial clusters connected through a global spanning-tree backbone.
- **Disconnected:** Four separated spatial clusters with intra-cluster edges only. Each cluster is connected, yielding four connected components.

The default mean degree is exactly six. The settings 2, 4, 6, and 8 also achieve their target mean degrees exactly. These constraints apply to the mean degree, not to every individual node's degree. `MaxDegree` is recorded to support the complexity analysis. Connectivity constraints cause low-degree networks to approach tree-like structures.

The workload uses controlled synthetic distributions that remain the same across network sizes: trust weights follow `U(0.2,1)`, security weights follow `U(0.5,1.5)`, and resource capacities follow `U(1,20)`. All values are positive. Positions and parameters are regenerated for each repetition, except that regular-grid positions remain fixed while their parameters are regenerated. These are not measured device parameters and should not be interpreted as a direct expansion of the original manuscript's dataset that preserves all its properties.

## Stopping Criteria and Interpretation of Results

By default, the algorithm evaluates each node's maximum unilateral improvement after every complete sweep, using a fixed allocation profile. A first-order upper bound derived from local concavity accounts for local numerical optimization error. All deviations are evaluated against the same profile.

A run is labeled `converged` only when the maximum individual improvement upper bound does not exceed `epsilon=1e-6`. This criterion provides an epsilon-Nash condition with the same accuracy requirement for every node. The sum and mean of the upper bounds are also reported. The bound holds in exact arithmetic; the implementation evaluates it using floating-point arithmetic rather than interval arithmetic.

The default limits are 500 sweeps or 120 seconds. The time limit is checked at sweep and gap-evaluation boundaries, so the elapsed time may exceed the limit by the time required for a sweep and its associated check. Both `time_limit` and `iteration_limit` indicate that the stopping criterion was not satisfied within the computational budget; these cases must not be reported as converged.

Runtime includes the initial, intermediate, and final gap evaluations, but excludes data generation, saving, and plotting. Times shown in the figures are times until termination. A red cross indicates that at least one repetition did not converge, so the associated time should not be interpreted as time to convergence.

One sweep consists of one update by each of the `N` nodes. The columns of the `history` matrix are, in order:

1. Completed sweeps.
2. Elapsed time in seconds.
3. Maximum unilateral-improvement upper bound.
4. Sum of unilateral-improvement upper bounds.
5. Total security utility.
6. Total allocated resources.

## Computational Complexity

Let `d_i` denote node degree, `m=sum_i d_i=2|E|` the number of directed allocation variables, `K` the number of completed cyclic sweeps, and `Q` the number of gap evaluations. Solving one local problem requires `O(d_i log(max(2,d_i)))` time, while incrementally updating the affected monitoring inputs requires an additional `O(d_i)` operations. The overall complexity of the updates and gap evaluations is therefore

`O((K+Q)*(N + sum_i d_i*log(max(2,d_i))))`.

When the gap is evaluated after every sweep, `Q=K+1`. A mean degree of at most eight implies `m<=8N`, giving the bound

`O((K+Q)*N*log(max(2,d_max)))`.

The per-sweep cost can be further described as `O(N)` only when the maximum degree also has a bound independent of `N`. A bounded mean degree alone does not justify removing the dependence on maximum degree. Likewise, the convergence theorem does not imply that the required number of sweeps `K` is independent of network size.

The sparse solver model and working vectors require `O(N+m+d_max)` storage. Saving the convergence history requires an additional `O(Q)` storage, while summaries of all experimental runs require separate storage. The two-hop candidate matrix used for network generation may be larger and is not included in this solver-storage bound.

`ModelBytes` and `AlgorithmArrayBytes` measure the storage occupied by specified MATLAB variables, not peak process memory. `SortWorkProxy` is a proxy for sorting work rather than an actual floating-point operation count. `BestResponseCalls` counts all local solver calls made during allocation updates and gap evaluations.

## Communication Overhead: Estimates Under a Protocol Model

The current implementation runs on a single machine and does not simulate transmission delays or a network stack. Communication overhead is a logical message budget under an explicit protocol, **not a measurement obtained from packet captures**:

- **Each complete cyclic sweep:** Request the monitoring input, return that input, and transmit the new allocation for every directed neighbor relation, giving `3m` messages, plus `N` scheduling messages.
- **Each fixed-profile gap evaluation:** Neighbor requests and replies contribute `2m` messages, plus `N` scalar gap reports that are aggregated by taking their maximum.
- **Initialization:** `2m` scalar-exchange messages.
- **Total:** `K*(3m+N)+Q*(2m+N)+2m`.
- **Message size:** An assumed 32-byte application header, 4-byte identifier, and 8-byte scalar payload, giving 44 bytes per message. These values can be changed through the options.

This budget assumes that scheduling and aggregation can use a separate control channel. It excludes multi-hop forwarding of control messages, retransmissions, handshakes, additional transport-layer or link-layer headers, and synchronization delays.

These assumptions should be stated explicitly in the manuscript, particularly for aggregation across components of disconnected networks. If the deployment protocol differs, the communication budget should be recalculated. These estimates must not be described as measured communication latency.

## Outputs

- `scalability_trials.csv`: Network size, actual degree, runtime, sweeps, gap, convergence status, computational counters, and communication estimates for each run.
- `scalability_summary.csv`: Summaries for each configuration, including the standard deviation of termination times and the fraction of converged runs.
- `scalability_overview.pdf/.png/.fig`: Six-panel overview.
- `scalability_results.mat`: Results table and options.
- **Individual-case MAT files:** Configuration, spatial coordinates and edges, results, and convergence history. The complete model can be reproduced using the saved seed and generator.
- `best_response_validation.csv`: Comparisons used to validate the local solver.

The manuscript should report the CPU, RAM, MATLAB release, repetition count, tolerance, computational limits, and whether other processes competed for resources. Preferably, perform the complete experiment on an otherwise idle machine. The included pilot results establish that the implementation can run; they do not replace the full scalability curves.

Additional output, `convergence_histories.pdf/.png/.fig`, shows the gap versus completed sweeps for three representative sizes from the first repetition and first mean-degree setting. `validate_scalability` checks all four topologies at 200 and 10,000 nodes with mean degrees of two and eight. It also checks utility monotonicity, feasibility, termination status, and counter consistency in the pilot results.

The average update time per sweep can be calculated as `UpdateSeconds/Sweeps`, and the average gap-certificate evaluation time as `GapSeconds/GapChecks`. These quantities help distinguish the effects of per-sweep computational cost and iteration count on total runtime. Avoid division by zero for cases that complete no sweeps.

## Additional Figure: Runtime Versus Network Size for All Four Networks

To read existing results and generate the figure without recomputing:

```matlab
main_plot_runtime(fullfile(pwd,'results_extended'));
% Use the included pilot results:
main_plot_runtime(fullfile(pwd,'pilot_results'));
% When multiple mean degrees are available, select one explicitly:
main_plot_runtime(fullfile(pwd,'degree_results'),6);
```

All four topologies are plotted on the same axes. The horizontal axis shows the number of nodes, and the vertical axis shows solver computation time, including equilibrium-gap evaluations but excluding network generation and plotting.

For repeated runs, curves show means with error bars of ±1 standard deviation. Results with one repetition have no error bars. Black crosses indicate configurations in which at least one run stopped before reaching the convergence tolerance. Consequently, the figure shows accumulated computation time at termination, which is not uniformly equivalent to time to convergence.

All available network sizes are read from the saved results. No interpolation is used to generate results for uncomputed sizes. The CSV input also supports experiments that have not yet completed. Different mean-degree settings are exported separately to avoid ambiguity.

The output files are `runtime_vs_network_size_degree_6.pdf/.svg/.png/.fig/.csv`. The main experiment and `replot_figures` also generate this figure automatically. The included pilot covers only 200, 1,000, and 10,000 nodes; obtaining curves for all 50 sizes requires completing the full experiment.