function results = main_plot_trust(resultDir, options)
%MAIN_PLOT_TRUST Replot saved results without running any simulations.
%   main_plot_trust;
%   main_plot_trust(fullfile(pwd,'results'),struct('visible','on'));
base = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(resultDir), resultDir = fullfile(base,'results'); end
if nargin < 2, options = struct; end
path = fullfile(resultDir,'analysis_results.mat');
assert(isfile(path),'No saved results at %s. Run main_trust_evaluation first.',path);
z = load(path,'results'); results = z.results;
allowed = {'visible','outputDir','formats'};
keys = fieldnames(options);
assert(all(ismember(keys,allowed)), ...
    'Replot options are visible, outputDir, and formats; simulation settings cannot change.');
o = results.options;
o.outputDir = char(resultDir); o.visible = 'on';
for k = 1:numel(keys), o.(keys{k}) = options.(keys{k}); end
o = te_options(o,base);
te_plot(results,o);
end
