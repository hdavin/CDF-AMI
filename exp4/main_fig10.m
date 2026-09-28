function analysis=main_fig10(options)
% Cost-free experiment 2. No eta argument is needed.
if nargin<1,options=struct;end
assert(isstruct(options),'Use main_fig9 or main_fig9(options); no eta argument.');
analysis=run_exp4(options);
end
