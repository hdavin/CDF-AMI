function datasets = main_generate_networks(options)
% Generate four spatial SM network datasets from the supplied generation rules.
% Example: datasets = main_generate_networks(struct('visible','on'));
if nargin < 1, options = struct; end
base = fileparts(mfilename('fullpath'));
o = net_options(options,base);
dataDir = fullfile(o.outputDir,'data');
if ~isfolder(dataDir), mkdir(dataDir); end
datasets = struct;
for k = 1:numel(o.networks)
    name = o.networks{k};
    net = net_generate_one(name,o);
    net_validate_one(net);
    datasets.(name) = net;
    net_save_one(net,dataDir);
    fprintf('%s: N=%d, edges=%d, mean degree=%.2f, components=%d, attempts=%d.\n', ...
        name,net.N,nnz(net.Adj)/2,mean(net.degree), ...
        net.metadata.componentCount,net.metadata.attempts);
end
summary = net_summary(datasets,o.networks);
save(fullfile(o.outputDir,'network_datasets.mat'),'datasets','summary','o','-v7');
writetable(summary,fullfile(o.outputDir,'network_summary.csv'));
if o.plotResults
    net_plot(datasets,o.networks,fullfile(o.outputDir,'figures'),o.visible);
end
end
