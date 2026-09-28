function results=main_capacity_sensitivity(options)
% Experiment 1: identical per-node capacity C = 10:10:100 by default.
if nargin<1,options=struct;end
results=s6_run('capacity',options);
end
