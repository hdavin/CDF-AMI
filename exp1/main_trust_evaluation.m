function results = main_trust_evaluation(options)
%MAIN_TRUST_EVALUATION Compute and plot the two trustworthiness experiments.
%   results = main_trust_evaluation;
%   results = main_trust_evaluation(struct('repetitions',100));
%   See README.md for parameters, caching, and definitions of the statistics.
if nargin < 1, options = struct; end
base = fileparts(mfilename('fullpath'));
o = te_options(options,base);
results = te_run(o);
if o.plotResults, te_plot(results,o); end
end
