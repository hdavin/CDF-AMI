function net = te_load_network(name,o)
names = {'Random','Regular','Clustered','Disconnected'};
files = {'xy_net1_Random.mat','xy_net2_Regular.mat', ...
    'xy_net3_Cluster.mat','xy_net4_Disconnected.mat'};
k = find(strcmp(name,names)); z = load(fullfile(o.dataDir,files{k}));
if isfield(z,'xy')
    xy = z.xy;
elseif isfield(z,'Net4_Disconnected_xy')
    xy = z.Net4_Disconnected_xy;
else
    error('Missing coordinates in %s.',files{k});
end
validateattributes(xy,{'numeric'},{'2d','ncols',2,'finite','real'});
n = size(xy,1); assert(n>1,'The network must contain at least two SMs.');
dx = xy(:,1)-xy(:,1)'; dy = xy(:,2)-xy(:,2)';
Adj = double(sqrt(dx.^2+dy.^2)<o.radius);
Adj(1:n+1:end) = 0;
assert(all(sum(Adj,2)>0), ...
    '%s contains isolated SMs; the uploaded trust model requires at least one neighbor.',name);
counts = floor(n*o.attackRates);
assert(all(counts>=1 & counts<n),'Each rate must select at least one SM of each class.');
net = struct('name',name,'xy',xy,'N',n,'Adj',Adj, ...
    'meanDegree',mean(sum(Adj,2)),'radius',o.radius);
end
