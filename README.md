# A collaborative defense framework against insider threats in mesh-structured smart meter networks

MATLAB simulation code accompanying the paper **“A collaborative defense framework against insider threats in mesh-structured smart meter networks.”**

This repository implements the simulation studies of the proposed collaborative insider threat defense framework for advanced metering infrastructure (AMI). It includes synthetic network generation, smart meter (SM) trustworthiness evaluation, cyclic best-response resource allocation, comparisons under random and targeted insider attacks, scalability evaluation, and parameter sensitivity analysis.

The experiments compare the proposed **game-based resource allocation (GRA)** method with **global utility-based resource allocation (GURA)** and **random resource allocation (RRA)**. Each experiment has its own entry functions, private implementation, input data where applicable, and result directory.

## 1. Runtime Environment

| Component | Requirement or reference setting |
|---|---|
| MATLAB | MATLAB R2026a Update 5 was used for the local environment checks and network-generation validation. Other releases must support the functions used below; they have not been independently validated here. |
| Optimization Toolbox | Required for the supplied GRA entry points in `exp3`, `exp4`, and `exp5`, and for the default capacity/density solvers in `exp6`, which use `fmincon`. |
| Base MATLAB workflows | `Net`, `exp1`, the main scalability experiment in `exp2`, and the penalty experiment in `exp6` do not require Optimization Toolbox. |
| Main MATLAB features | `graph`, `conncomp`, `delaunayTriangulation`, tables, `tiledlayout`, `exportgraphics`, and `savefig`. Several plotting functions directly export SVG using `exportgraphics`; use a MATLAB release supporting that operation. |
| Additional software | No NIRA GUI, Symbolic Math Toolbox, GPU, or external plotting package is required by the documented main workflows. |
| Hardware reported in the manuscript | Intel Core i7-14700K and 32 GB RAM. These are the manuscript's experimental settings, not minimum hardware requirements. |

Runtime depends on the machine, MATLAB release, solver settings, network realization, and background workload. Record these settings when comparing timings with the paper.

Check the local MATLAB installation with:

```matlab
version
ver
license('test','Optimization_Toolbox')
which fmincon
```

## 2. Repository Structure

```text
AMI_Experiments/
├── README.md
├── Net/                         Four synthetic network topologies
│   ├── main_generate_networks.m
│   ├── main_plot_networks.m
│   ├── main_validate_networks.m
│   ├── private/
│   └── results/
├── exp1/                        Trustworthiness evaluation
│   ├── main_trust_evaluation.m
│   ├── main_plot_trust.m
│   ├── data/
│   ├── private/
│   └── results/
├── exp2/                        Convergence and scalability
│   ├── main_scalability.m
│   ├── main_plot_runtime.m
│   ├── main_pilot.m
│   ├── replot_figures.m
│   ├── private/
│   └── results/
├── exp3/                        Resource-allocation comparison
│   ├── main_fig8_fig9.m
│   ├── replot_figures.m
│   ├── data/
│   ├── private/
│   └── results/
├── exp4/                        Relative loss under random attacks
│   ├── main_fig10.m
│   ├── replot_figures.m
│   ├── data/
│   ├── private/
│   └── results/
├── exp5/                        Three targeted attack scenarios
│   ├── main_fig11_fig13.m
│   ├── replot_figures.m
│   ├── data/
│   ├── private/
│   └── results/
└── exp6/                        Parameter sensitivity analysis
    ├── main_sensitivity.m
    ├── main_capacity_sensitivity.m
    ├── main_penalty_sensitivity.m
    ├── main_density_sensitivity.m
    ├── main_plot_sensitivity.m
    ├── main_edit_figure.m
    ├── data/
    ├── private/
    └── results/
```

Each folder also contains `README_EN.md` and `README_zh-CN.md`. The entry names and current defaults below were checked against the executable code; some older comments and experiment-level descriptions retain earlier figure numbers or settings.

### Relationship to the manuscript

| Folder | Study | Figures in the supplied manuscript |
|---|---|---|
| `Net` | Uniformly random, regular, clustered, and disconnected network generation | Fig. 3: network topology examples |
| `exp1` | Trustworthiness distributions and mean trustworthiness | Figs. 4–5 |
| `exp2` | Convergence histories and runtime versus network size | Figs. 6–7 |
| `exp3` | Total security utility and received resources versus security level | Figs. 8–9 |
| `exp4` | Relative system losses under unbiased random attacks | Fig. 10 |
| `exp5` | Value-oriented, trust-oriented, and degree-based attacks | Figs. 11–13 |
| `exp6` | Punishment coefficient, resource capacity, and mean degree | Figs. 14–16, respectively |

The generators can produce new network realizations. To reproduce experiments using the supplied inputs, retain the data already stored in the corresponding experiment folders. Running `Net` is optional and does not automatically replace their input files.

## 3. Running the Experiments

Start MATLAB in the repository root and retain its location:

```matlab
projectRoot = pwd;
```

Run each experiment from its own folder. Several folders intentionally contain functions named `replot_figures` and similarly named private helpers; avoid recursively adding every folder to the MATLAB path. No project-wide installation or compilation step is required.

### Network generation

```matlab
cd(fullfile(projectRoot,'Net'));
datasets = main_generate_networks;
main_validate_networks;
```

Defaults are 100 SMs in a 200-by-200-meter area, with an edge whenever the Euclidean distance is strictly less than 30 meters. The first three topologies are connected. The disconnected topology contains four connected components of 25 nodes each. Invalid realizations are rejected and resampled within a finite attempt limit.

Outputs include coordinates, adjacency matrices, network statistics, and a four-panel topology figure. Red nodes represent SMs, and blue lines represent communication links.

### exp1: Trustworthiness evaluation

```matlab
cd(fullfile(projectRoot,'exp1'));
trustResults = main_trust_evaluation;
```

The default study uses the uniformly random network, testing probabilities `P_T=[0.3 0.5 0.7 0.9]`, compromised-node proportions `P_C=0.05:0.05:0.95`, 20 interaction rounds, and 1,000 repetitions per parameter combination. The distribution figure uses `P_C=0.5`. The malicious-behavior probability is `0.1`, and the punishment coefficient is `10`.

To evaluate all four networks:

```matlab
trustResults = main_trust_evaluation(struct( ...
    'networks',{{'Random','Regular','Clustered','Disconnected'}}, ...
    'outputDir',fullfile(pwd,'results_all_networks')));
```

### exp2: Convergence and scalability

```matlab
cd(fullfile(projectRoot,'exp2'));
scalabilityResults = main_scalability;
```

The default study uses four topologies, `N=200:200:10000`, mean degree `6`, and three repetitions per configuration: 600 solver runs in total. The stopping tolerance is `1e-6`, checked every five sweeps, with limits of 5,000 sweeps and 1,800 seconds per run.

A reduced configuration for checking the workflow is:

```matlab
scalabilityResults = main_scalability(struct( ...
    'sizes',[200 1000 10000], ...
    'repetitions',1, ...
    'outputDir',fullfile(pwd,'results_quickcheck')));
```

This experiment uses a sorting-based water-filling solution of each local best-response problem. It evaluates the same allocation model through a specialized solver, rather than measuring the runtime of `fmincon` or the original NIRA implementation.

Its networks are controlled sparse spatial graphs whose deployment scale grows with network size. They are not obtained by placing up to 10,000 nodes in the fixed 200-by-200-meter area used by `Net`. Trust weights, security priorities, and capacities are positive synthetic inputs.

### exp3: Monitoring resource allocation

```matlab
cd(fullfile(projectRoot,'exp3'));
allocationResults = main_fig8_fig9;
```

The experiment compares GRA, GURA, and 1,000 RRA allocations across the four supplied networks. It produces total security utility comparisons and the relationship between security level and received monitoring resources under GRA. Use `main_fig8_fig9`, which is the actual current entry point, rather than the earlier name `main_fig7_fig8`.

### exp4: Relative losses under random attacks

```matlab
cd(fullfile(projectRoot,'exp4'));
randomAttackResults = main_fig10;
```

For each network, 200 attack realizations select 10% of SMs uniformly without replacement. GURA, GRA, and RRA face the same compromised-node set in each realization. The plotted quantity is the difference between each method's system loss and the GURA loss.

### exp5: Targeted insider attacks

```matlab
cd(fullfile(projectRoot,'exp5'));
targetedAttackResults = main_fig11_fig13;
```

Three attack rankings are evaluated: security level, received trustworthiness, and degree centrality. Each scenario compromises the highest-ranked 10%, 30%, 50%, or 70% of nodes. All methods share the selected attack set, and RRA losses are averaged over 100 random allocations. Degree ties are resolved using the existing node-index rule, which selects larger indices first when taking the highest-ranked nodes.

### exp6: Parameter sensitivity

```matlab
cd(fullfile(projectRoot,'exp6'));
sensitivityResults = main_sensitivity;
```

Alternatively, run the three studies separately:

```matlab
capacityResults = main_capacity_sensitivity;
penaltyResults  = main_penalty_sensitivity;
densityResults  = main_density_sensitivity;
```

Current settings are:

| Study | Parameter settings | Evaluation |
|---|---|---|
| Resource capacity | Equal capacity for every SM: `C=10:10:100` | Total security utility and system loss |
| Punishment coefficient | `w=[1.1 2 3 5 10 20]`; `P_T=[0.1 0.3 0.5 0.7]`; `P_C=0.5`; 20 interaction rounds | Mean trust separation; ranking AUC is also computed/exported by the current code |
| Network density | Mean degree `4:13`; fixed capacity `C_i=20` | Total security utility and system loss |

Each study uses four networks and 20 repetitions. Capacity and density studies use 200 paired attack/RRA samples per repetition, with 10% of nodes attacked. Their saved tables contain GURA, GRA, and RRA results; the current plots display GRA across the four networks. Penalty plots contain four panels, one for each testing probability, and show means without error bars. The manuscript uses mean trust separation as its reported penalty metric.

Capacity and density utility/loss plots are exported separately; their placement into manuscript panels is a presentation step. The density study adds nested distance-ranked edges within the prescribed connected components, rather than enforcing a fixed communication radius.

The capacity/density solvers also support an analytic best-response backend:

```matlab
densityResults = main_density_sensitivity(struct( ...
    'bestResponseSolver','analytic', ...
    'outputDir',fullfile(pwd,'results_density_analytic')));
```

## 4. Models and Data

For monitoring input received by SM `j`, the code uses:

```text
s_j = sum_i tau_ji * x_ij
M_j = log(1 + s_j)
U_i = sum_{j in neighbors(i)} xi_j * M_j
Uhat = sum_j xi_j * M_j
```

Allocations are nonnegative, and each SM's outgoing allocation must not exceed its resource capacity. GRA maximizes individual utility through sequential best responses. GURA independently maximizes `Uhat` using accelerated projected gradient with backtracking and restarts. RRA distributes each SM's full capacity randomly among its neighbors.

All current allocation objectives exclude monitoring costs; legacy cost fields, where retained, are zero. Network utility `Uhat` counts each monitored SM once and is not the sum of all individual utilities.

With the current default loss setting:

```text
L_A = sum_{j attacked} kappa * xi_j / log(1 + s_j),  kappa = 100
Delta L_A = L_A(method) - L_A(GURA)
```

These losses are comparative model indices, not calibrated monetary damages. Utility maximization does not directly minimize loss for each realized attack set, so relative losses may be negative. Zero monitoring of an attacked node with positive priority produces infinite loss; the code retains nonfinite values in the numerical results rather than replacing them with a finite cap.

### Input files

- `exp1/data/xy_net*.mat`: coordinates used to reconstruct the four network topologies.
- `exp3/data/Parameter_*.mat`, `exp4/data/Parameter_*.mat`, and `exp5/data/Parameter_*.mat`: supplied game parameters, parsed without launching NIRA.
- `exp6/data/Parameter_*.mat`: baseline network and trust parameters.
- `exp6/data/Coordinates_*.mat`: positions used in the density study.
- `exp6/data/SL.mat`: a 100-by-24 input matrix used to calculate security priorities.

According to the manuscript, electricity-demand inputs originate from Australia's **Smart Grid, Smart City** project. Network configurations, compromised-node selections, simulated malicious behavior, and scalability workloads are synthetic. The supplied data do not contain observed attack damage for calibrating the loss model.

The capacity and density studies calculate security levels using:

```matlab
gamma = 1 - 0.5*rand(N,1);
SL = (w1*max(SL_data.SL,[],2) + w2*mean(SL_data.SL,2)).*gamma;
```

Here `w1=0.4` and `w2=0.6`. Within each repetition, `gamma` and the resulting priorities remain fixed across the scanned parameter values. This implementation uses the row maximum and row mean, not the sum of the 24 entries.

Generating new coordinates in `Net` does not regenerate matching game parameters. Keep coordinates, trust matrices, capacities, and security levels consistent when preparing a new allocation experiment.

## 5. Outputs and Replotting

Results are normally written under each experiment's `results` directory. MAT files preserve numerical results and options, CSV files provide trial records and summaries, and plotting functions export PDF, SVG, PNG, and FIG files as supported by each workflow.

| Folder | Principal numerical outputs |
|---|---|
| `Net` | `network_datasets.mat`, `network_summary.csv`, and topology files under `results/data/` |
| `exp1` | `analysis_results.mat`, `trust_distribution.csv`, `mean_trustworthiness.csv` |
| `exp2` | `scalability_results.mat`, `scalability_trials.csv`, `scalability_summary.csv`, and per-run MAT files |
| `exp3` | `analysis_results.mat`, `strategy_summary.csv`, `random_samples.csv` |
| `exp4` | `loss_analysis.mat`, `loss_trials.csv`, `loss_summary.csv` |
| `exp5` | `targeted_loss_analysis.mat`, `targeted_loss_summary.csv`, `random_loss_trials.csv`, `node_attack_scores.csv` |
| `exp6` | `analysis_results.mat`, `trials.csv`, `summary.csv`, and per-repetition MAT files within each study's result directory |

Run the following from the corresponding experiment folder to replot existing results:

```matlab
% Net
main_plot_networks;

% exp1
main_plot_trust;

% exp2
replot_figures;
% Or plot only runtime versus network size:
main_plot_runtime(fullfile(pwd,'results'),6);

% exp3, exp4, or exp5: run separately from the appropriate folder
replot_figures;

% exp6
main_plot_sensitivity('capacity');
main_plot_sensitivity('density');
```

For `exp6`, `main_sensitivity` saves the penalty study under `results/penalty`, whereas a direct call to `main_penalty_sensitivity` defaults to `results/penalty_PT4`. Specify the corresponding directory when replotting:

```matlab
% Results from main_sensitivity:
main_plot_sensitivity('penalty',fullfile(pwd,'results','penalty'));

% Results from main_penalty_sensitivity:
main_plot_sensitivity('penalty',fullfile(pwd,'results','penalty_PT4'));
```

To open and edit an existing MATLAB figure:

```matlab
fig = openfig('path_to_figure.fig','new','visible');
plotedit(fig,'on');
```

Replotting uses saved numerical values; it does not rerun solvers or apply changes to the underlying model.

## 6. Reproducibility and Interpretation

- **Seeds and paired comparisons:** experiment defaults use fixed seeds. Allocation comparisons share attack realizations, and sensitivity studies reuse specified inputs across parameter values within each repetition. Keep the saved options and input data with each result.
- **Cache consistency:** workflows supporting `resume` require compatible saved configurations. After changing parameters, use a new `outputDir` or set `resume=false` where supported. A fresh output directory also avoids mixing results after code or input-data changes.
- **Convergence checks:** `exp3–5` use an upper bound on the sum of unilateral improvement gains, with default tolerance `1e-6`. `exp2` and `exp6` use the maximum individual improvement upper bound with tolerance `1e-6`. GURA uses a separate global improvement bound, normally with tolerance `1e-5`. Inspect status and gap fields rather than inferring convergence from a completed function call.
- **Exact versus numerical iteration:** the theoretical convergence result concerns exact cyclic best responses under the stated assumptions. Numerical solutions are assessed using the computed gap bounds; arbitrary approximate local solves are not automatically guaranteed to reach the prescribed tolerance.
- **Runtime and communication:** scalability timings include equilibrium-gap checks and exclude network generation and plotting. Communication counts are estimates under the implemented message-budget model, not measured network traffic or latency. Near-linear timing is an experimental observation for the tested sparse configurations.
- **Trust evaluation variants:** `exp1` retains the uploaded full-row majority-vote and ideal-set rules. The default `exp6` penalty experiment uses neighbor-based ideal sets, receiver-based penalties, and a neutral score of 0.5 for indistinguishable cases; scores are averaged over honest neighboring evaluators. These workflows should not be treated as identical implementations or directly interchangeable statistics.

### Notes on the supplied result snapshot

The following points were checked against the supplied files and matter when reproducing the current model:

1. **Pilot entry:** the supplied `main_pilot.m` calls `validate_best_response`, which is not included in the current folder. Use the reduced `main_scalability` command shown above unless that validation function is supplied separately.

2. **Relocated result folders:** saved options can contain absolute input paths. In particular, `main_plot_trust` validates its saved `dataDir`. If a saved folder is moved to another machine, update the path in a copy of its result MAT file before replotting, or recompute using the local input directory.

## 7. Authors and Contact

**Da-Wen Huang**  
College of Computer Science, Sichuan Normal University, China  
Email: [hdawen@sicnu.edu.cn](mailto:hdawen@sicnu.edu.cn)

## 8. Citation

If you use this code in your research, please cite the accompanying paper:

Da-Wen Huang, Fengji Luo, Jichao Bi, Chenquan Gan, and Mingyang Sun. **A collaborative defense framework against insider threats in mesh-structured smart meter networks.**

Use the final bibliographic details when they become available.
