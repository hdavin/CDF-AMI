function analysis=main_fig8_fig9(options)
% Cost-free experiment: main_fig7_fig8 or main_fig7_fig8(struct('visible','on')).
if nargin<1,options=struct;end
assert(isstruct(options),'This cost-free version accepts an options structure, not eta.');
analysis=run_exp3(options);
end
