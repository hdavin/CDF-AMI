function analysis=main_fig11_fig13(options)
% Cost-free targeted-attack experiment.
if nargin<1,options=struct;end
assert(isstruct(options),'Provide options only; no eta argument.');
analysis=run_exp5(options);
end
