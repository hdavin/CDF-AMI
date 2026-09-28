function summary = main_plot_sensitivity(kind,resultDir,outputDir,visible)
% Replot cached tables only: no solvers, trust simulations, or resume checks.
% main_plot_sensitivity('capacity')
% main_plot_sensitivity('density')
% main_plot_sensitivity('density',fullfile(pwd,'results','my_density_run'))
base=fileparts(mfilename('fullpath'));
if nargin<1, kind='capacity'; end
kind=validatestring(kind,{'capacity','density','penalty'});
if nargin<2 || isempty(resultDir)
    folder=kind; if strcmp(kind,'capacity'), folder='capacity_absolute'; end
    if strcmp(kind,'penalty'), folder='penalty'; end
    resultDir=fullfile(base,'results',folder);
    if strcmp(kind,'capacity') && ~isfile(fullfile(resultDir,'analysis_results.mat'))
        resultDir=fullfile(base,'results','capacity'); % Older multiplier experiment.
    end
end
if nargin<3 || isempty(outputDir)
    folder='combined_GRA'; if strcmp(kind,'penalty'), folder='PT_panels'; end
    outputDir=fullfile(resultDir,folder);
end
if nargin<4, visible='off'; end
file=fullfile(resultDir,'analysis_results.mat');
assert(isfile(file),'Saved analysis not found: %s.',file);
z=load(file,'out','o','kind');
assert(isfield(z,'out')&&isfield(z,'o')&&isfield(z,'kind'), ...
    'analysis_results.mat must contain out, o, and kind.');
assert(strcmp(z.kind,kind),'Saved experiment is %s, not %s.',z.kind,kind);
o=z.o; o.outputDir=outputDir; o.visible=validatestring(visible,{'on','off'});
summary=s6_plot(z.out,o,kind);
fprintf('Replotted saved %s results: %s\n',kind,outputDir);
end
