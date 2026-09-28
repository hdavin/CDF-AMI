function net_save_one(net,dataDir)
% Network_*.mat includes topology only. Do not masquerade as game Parameter_*.mat.
[coordinateFile,legacyVariable] = net_filenames(net.name);
coordinates = struct('xy',net.xy,'N',net.N,'Lim',net.Lim,'metadata',net.metadata);
coordinates.(legacyVariable) = net.xy;
save(fullfile(dataDir,coordinateFile),'-struct','coordinates','-v7');
save(fullfile(dataDir,['Coordinates_' net.name '.mat']),'-struct','coordinates','-v7');
save(fullfile(dataDir,['Network_' net.name '.mat']),'-struct','net','-v7');
end
