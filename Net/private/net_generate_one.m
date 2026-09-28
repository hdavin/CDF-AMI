function net = net_generate_one(name,o)
% Preserve the supplied pool sampling and strict distance rule; reject invalid topologies.
names = {'Random','Regular','Clustered','Disconnected'};
id = find(strcmp(name,names));
assert(isscalar(id),'Unknown topology.');
seed = mod(double(o.seed)+1009*(id-1),2^32);
previous = rng; restore = onCleanup(@() rng(previous));
rng(seed,'twister'); initialState = rng;
N = o.nodeCount; L = o.areaSize; Lim = o.radius;
centers = zeros(0,2); innerRadius = 0; outerRadius = 0;
groups = ones(N,1); counts = N;
if strcmp(name,'Clustered')
    centers = L*[.5 .5;.2 .2;.8 .2;.2 .8;.8 .8];
    innerRadius = .3*Lim; outerRadius = 1.2*Lim;
elseif strcmp(name,'Disconnected')
    centers = L*[.2 .2;.2 .8;.8 .2;.8 .8];
    innerRadius = .3*Lim; outerRadius = 1.7*Lim;
end
if ~isempty(centers)
    nGroups = size(centers,1);
    counts = floor(N/nGroups)*ones(nGroups,1);
    counts(1:mod(N,nGroups)) = counts(1:mod(N,nGroups))+1;
    groups = repelem((1:nGroups)',counts);
end
valid = false; insufficientPools = 0;
for attempt = 1:o.maxAttempts
    if strcmp(name,'Random')
        xy = L*rand(N,2);
    elseif strcmp(name,'Regular')
        v = linspace(.075*L,.925*L,round(sqrt(N)));
        [xx,yy] = meshgrid(v); xy = [xx(:) yy(:)];
    else
        % A shared ordered pool, just as in the original code; never wait indefinitely.
        pool = L*rand(o.candidateCount,2); used = false(o.candidateCount,1);
        xy = zeros(N,2); enough = true;
        for g = 1:size(centers,1)
            rows = groups==g;
            distances = sqrt(sum((pool-centers(g,:)).^2,2));
            candidates = find(~used & distances>innerRadius & distances<outerRadius);
            if numel(candidates)<counts(g)-1, enough = false; break; end
            selected = candidates(1:counts(g)-1);
            xy(rows,:) = [centers(g,:);pool(selected,:)];
            used(selected) = true;
        end
        if ~enough, insufficientPools = insufficientPools+1; continue; end
    end
    Adj = net_adjacency(xy,Lim);
    component = conncomp(graph(Adj))'; degree = sum(Adj,2);
    valid = all(degree>0) && size(unique(xy,'rows'),1)==N;
    if strcmp(name,'Disconnected')
        valid = valid && max(component)==4;
        for g = 1:4
            valid = valid && isscalar(unique(component(groups==g)));
        end
    else
        valid = valid && max(component)==1;
    end
    if valid, break; end
    if strcmp(name,'Regular')
        error('Net:RegularDisconnected', ...
            'The grid is disconnected at radius %.6g; change radius, areaSize, or nodeCount.',Lim);
    end
end
if ~valid
    error('Net:GenerationFailed', ...
        ['Could not generate %s after %d attempts (%d insufficient candidate pools). ' ...
         'Check radius, areaSize, nodeCount, or candidateCount.'], ...
        name,o.maxAttempts,insufficientPools);
end
metadata = struct('topology',name,'seed',seed,'baseSeed',o.seed,'rngInitial',initialState, ...
    'attempts',attempt,'insufficientCandidatePools',insufficientPools,'areaSize',L, ...
    'radius',Lim,'candidateCount',o.candidateCount,'edgeRule','Euclidean distance < radius', ...
    'componentCount',max(component),'componentSizes',accumarray(component,1), ...
    'clusterCenters',centers,'clusterSizes',counts,'clusterInnerRadius',innerRadius, ...
    'clusterOuterRadius',outerRadius,'generatorVersion','original_radius_rules_v1', ...
    'units','meters','runtime',version);
if strcmp(name,'Disconnected')
    metadata.acceptanceCondition = 'Four connected geographic clusters; no edges between clusters.';
else
    metadata.acceptanceCondition = 'One connected component.';
end
net = struct('name',name,'N',N,'xy',xy,'Adj',Adj,'Lim',Lim, ...
    'degree',degree,'component',component,'group',groups,'metadata',metadata);
end
