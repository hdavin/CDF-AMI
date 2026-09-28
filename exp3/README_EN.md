# exp3: Monitoring Resource Allocation Experiment

Run `analysis = main_fig8_fig9;`. To display the figures, use `main_fig7_fig8(struct('visible','on'))`. The `eta` input is no longer required. Optimization Toolbox is required.

**GRA:** Nodes update in a fixed order, using `fmincon` to maximize their individual security utilities. **GURA:** Centralized maximization of `sum_j SL_j log(1+s_j)`. **RRA:** Random allocation using each node's full capacity, evaluated with the same security-utility metric. The vertical axis of Fig. 7 is labeled **Total security utility**. Fig. 8 retains the relationship between received resources and security levels under GRA.

Equilibrium-gap checks use multiplier bisection to compute best responses, together with a concavity-based upper bound. The positivity of effective trust coefficients and security weights is checked at runtime.

The equilibrium gap for GRA and the global optimality gap for GURA are checked separately. Their security-utility values should be close.