function fig = main_plot_networks(resultDir,options)
% Replot saved networks without regenerating positions or adjacency matrices.
base = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(resultDir), resultDir = fullfile(base,'results'); end
if nargin < 2, options = struct; end
defaults = struct('visible','on','outputDir',fullfile(resultDir,'figures'));
keys = fieldnames(options);
for k = 1:numel(keys)
    assert(isfield(defaults,keys{k}),'Unknown plotting option: %s.',keys{k});
    defaults.(keys{k}) = options.(keys{k});
end
defaults.visible = validatestring(defaults.visible,{'on','off'});
z = load(fullfile(resultDir,'network_datasets.mat'),'datasets','o');
fig = net_plot(z.datasets,z.o.networks,defaults.outputDir,defaults.visible);
end
