function replot_figures
base=fileparts(mfilename('fullpath'));
s=load(fullfile(base,'results','loss_analysis.mat'),'analysis');
a=s.analysis;a.options.outputDir=fullfile(base,'results');
plot_sm_losses(a);
end
