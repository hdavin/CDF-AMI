# Exp4: Relative System Loss Comparison Experiment

Run `analysis = main_fig10;`. To display the figures, use `main_fig10(struct('visible','on'))`. The `eta` input is no longer required. Optimization Toolbox is required. `replot_figures` only regenerates figures from existing results.

GRA uses cyclic individual best responses without monitoring costs, computed using `fmincon`. GURA centrally maximizes total security utility without monitoring costs. RRA retains the original random allocation using each node's full capacity, with no cost deduction. Only Fig. 9 is generated; no additional figures are created. Fig. 9 reports relative system loss, `Delta L_A`. The original figure does not contain the label **Total net security utility**.

The experiment retains the four networks and settings from the uploaded `exp2`: random seed `20260921`, 200 trials, and 10% of nodes randomly selected as compromised. All three strategies use the same compromised-node set within each trial. System loss follows the original definition in `Lsm.m`, with `kappa=100`.


GRA and GURA maximize total security utility rather than directly minimizing attack losses. Relative losses may therefore be negative, and these values are retained without modification.