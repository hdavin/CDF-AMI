# exp5: Comparison of Three Attack Scenarios

Run `analysis = main_fig11_fig13;`. To display the figures during execution, use `main_fig11_fig13(struct('visible','on'))`. The `eta` input is no longer required. Optimization Toolbox is required. To regenerate figures from existing results, run `replot_figures`.

GRA maximizes individual security utility through cyclic best-response updates using `fmincon`; GURA centrally maximizes total security utility; RRA randomly allocates each node’s full resource capacity. The best-response error upper bound is computed independently using a multiplier-bisection formula.

Only Figures 11–13 are generated. The attacks target the top 10%, 30%, 50%, and 70% of nodes ranked by security level, received trustworthiness, and degree centrality, respectively. The plotting patterns, colors, attack rankings, and 100 sets of RRA allocations from the uploaded code are retained, with random seed `20260924`. The figures report system loss \(L_A\) and do not contain the label “Total net security utility.”

The loss definition follows the original `Lsm` function, with `kappa=100` and `M=log(1+s)`. The monitoring benefit in the optimization objective is also `log(1+s)`. All three methods use the same compromised-node set within each attack scenario. The GURA and GRA bars represent deterministic losses, whereas the RRA bars represent the average loss over 100 random allocations.

The third attack scenario uses degree centrality, defined as the number of neighbors of each node. Nodes are selected for attack in descending order of degree. Ties follow the original node-index ordering, with larger node indices selected first. Figure 13 is saved as `Fig13_degree_attacks`, and the corresponding metric field in the CSV output is `Degree`.