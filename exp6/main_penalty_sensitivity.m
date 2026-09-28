function results=main_penalty_sensitivity(options)
% PT = [0.1 0.3 0.5 0.7]; each metric has four PT panels with four networks.
% Default output: results/penalty_PT4 (separate from previous two-PT caches).
if nargin<1,options=struct;end
results=s6_run('penalty',options);
end
