function [coordinateFile,legacyVariable] = net_filenames(name)
names = {'Random','Regular','Clustered','Disconnected'};
files = {'xy_net1_Random.mat','xy_net2_Regular.mat','xy_net3_Cluster.mat','xy_net4_Disconnected.mat'};
variables = {'Net1_Random_xy','Net2_Regular_xy','Net3_Cluster_xy','Net4_Disconnected_xy'};
k = find(strcmp(name,names));
assert(isscalar(k),'Unknown topology.');
coordinateFile = files{k}; legacyVariable = variables{k};
end
