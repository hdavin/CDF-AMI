function replot_figures
% Re-export Figures 11--13 from saved results without resolving the game.
base=fileparts(mfilename('fullpath'));s=load(fullfile(base,'results','targeted_loss_analysis.mat'),'analysis');
a=s.analysis;a.options.outputDir=fullfile(base,'results');plot_targeted_losses(a);
end
