function replot_figures(outputDir)
if nargin<1,outputDir=fullfile(fileparts(mfilename('fullpath')),'results');end
s=load(fullfile(outputDir,'scalability_results.mat'),'results','o');s.o.outputDir=outputDir;
scale_plot(s.results,s.o);scale_history_plot(s.o);
for degree=s.o.targetDegrees,main_plot_runtime(outputDir,degree);end
end
