function net_validate_one(net)
n = net.N; L = net.metadata.areaSize;
assert(isequal(size(net.xy),[n 2]) && all(isfinite(net.xy(:))) && ...
    all(net.xy(:)>=0 & net.xy(:)<=L),'Invalid node coordinates.');
assert(size(unique(net.xy,'rows'),1)==n,'Duplicate node coordinates.');
assert(isequal(size(net.Adj),[n n]) && isequal(net.Adj,net.Adj') && ...
    ~any(diag(net.Adj)) && all(ismember(net.Adj(:),[0 1])),'Invalid adjacency matrix.');
% Independently check every pair rather than reuse the generator's vectorized helper.
expected = zeros(n);
for i = 1:n
    for j = i+1:n
        linked = norm(net.xy(i,:)-net.xy(j,:))<net.Lim;
        expected(i,j) = linked; expected(j,i) = linked;
    end
end
assert(isequal(net.Adj,expected), ...
    'Adjacency does not match the strict distance threshold.');
degree = sum(net.Adj,2); component = conncomp(graph(net.Adj))';
assert(all(degree>0) && isequal(degree,net.degree),'Isolated nodes or invalid degrees.');
assert(isequal(component,net.component) && ...
    max(component)==net.metadata.componentCount && ...
    isequal(accumarray(component,1),net.metadata.componentSizes),'Invalid component metadata.');
if strcmp(net.name,'Disconnected')
    assert(max(component)==4,'Disconnected must have exactly four components.');
    assert(~any(net.Adj(net.group~=net.group')),'An edge crosses geographic components.');
    for g = 1:4
        assert(isscalar(unique(component(net.group==g))),'A geographic component is disconnected.');
    end
else
    assert(max(component)==1,'%s must be connected.',net.name);
end
centers = net.metadata.clusterCenters;
for g = 1:size(centers,1)
    rows = find(net.group==g);
    assert(numel(rows)==net.metadata.clusterSizes(g),'Invalid cluster size.');
    assert(isequal(net.xy(rows(1),:),centers(g,:)),'The first node must be the cluster center.');
    d = sqrt(sum((net.xy(rows(2:end),:)-centers(g,:)).^2,2));
    assert(all(d>net.metadata.clusterInnerRadius & d<net.metadata.clusterOuterRadius), ...
        'Coordinates do not follow the original annulus sampling rule.');
end
if strcmp(net.name,'Regular')
    axisValues = linspace(.075*L,.925*L,round(sqrt(n)));
    [xx,yy] = meshgrid(axisValues);
    assert(isequal(net.xy,[xx(:) yy(:)]),'Incorrect regular grid coordinates.');
end
end
