function replot_figures
base=fileparts(mfilename('fullpath'));
s=load(fullfile(base,'results','analysis_results.mat'),'analysis');
a=s.analysis;o=a.options;o.outputDir=fullfile(base,'results');
sm_plot_analysis(a,{'Random','Regular','Clustered','Disconnected'},o);
end
