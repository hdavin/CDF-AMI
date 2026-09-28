function summary = main_validate_networks(resultDir)
% Validate saved geometry, connectivity, file aliases, and seed reproducibility.
base = fileparts(mfilename('fullpath'));
if nargin < 1 || isempty(resultDir), resultDir = fullfile(base,'results'); end
z = load(fullfile(resultDir,'network_datasets.mat'),'datasets','o');
dataDir = fullfile(resultDir,'data');
for k = 1:numel(z.o.networks)
    name = z.o.networks{k}; net = z.datasets.(name);
    net_validate_one(net);
    fresh = net_generate_one(name,z.o);
    assert(isequal(fresh.xy,net.xy) && isequal(fresh.Adj,net.Adj), ...
        '%s cannot be reproduced using its saved configuration.',name);
    [coordinateFile,legacyVariable] = net_filenames(name);
    a = load(fullfile(dataDir,coordinateFile));
    b = load(fullfile(dataDir,['Coordinates_' name '.mat']));
    c = load(fullfile(dataDir,['Network_' name '.mat']));
    assert(isequal(a.xy,net.xy) && isequal(a.(legacyVariable),net.xy) && ...
        isequal(b.xy,net.xy) && isequal(c.xy,net.xy) && isequal(c.Adj,net.Adj), ...
        '%s saved files are inconsistent.',name);
    assert(isequal(c.N,net.N) && isequal(c.Lim,net.Lim) && ...
        isequal(c.metadata,net.metadata),'Saved metadata differ from the dataset.');
end
summary = net_summary(z.datasets,z.o.networks);
summary.Validated = true(height(summary),1);
writetable(summary,fullfile(resultDir,'validation_summary.csv'));
fprintf('Validated %d networks: geometry, connectivity, saved files, and reproducibility.\n',height(summary));
disp(summary);
end
