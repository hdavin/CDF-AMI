function [graphs,meta]=s6_density_graphs(xy,name,degrees)
% Fixed coordinates and nested edge sets; no fixed communication radius.
assert(isnumeric(degrees)&&isreal(degrees)&&isvector(degrees)&&~isempty(degrees)&&...
 all(isfinite(degrees)&degrees>=2&degrees==fix(degrees)),...
 'Mean-degree settings must be finite integers >= 2.');
degrees=degrees(:)';
n=size(xy,1);groups=ones(n,1);
if strcmp(name,'Disconnected')
    centers=[40 40;40 160;160 40;160 160];distance=zeros(n,4);
    for k=1:4,distance(:,k)=sum((xy-centers(k,:)).^2,2);end
    [~,groups]=min(distance,[],2);assert(numel(unique(groups))==4);
end
componentIds=unique(groups);
componentSizes=arrayfun(@(c)sum(groups==c),componentIds);
componentSizes=componentSizes(:);
assert(all(componentSizes>1),'Every component must contain at least two nodes.');
% Match the GLOBAL edge count exactly; separately rounding each component
% would produce the wrong mean degree for odd degrees and odd component sizes.
targetEdges=n*degrees/2;
assert(all(abs(targetEdges-round(targetEdges))<1e-10),...
 'N*meanDegree/2 must be an integer for an undirected network.');
targetEdges=round(targetEdges);
idealCounts=componentSizes*degrees/2;
componentEdges=floor(idealCounts);
for k=1:numel(degrees)
    remaining=targetEdges(k)-sum(componentEdges(:,k));
    fractions=idealCounts(:,k)-componentEdges(:,k);
    [~,priority]=sortrows([-fractions,(1:numel(componentIds))'],[1 2]);
    componentEdges(priority(1:remaining),k)=componentEdges(priority(1:remaining),k)+1;
end
assert(all(componentEdges>=componentSizes-1,'all')&&...
 all(componentEdges<=componentSizes.*(componentSizes-1)/2,'all'),...
 'Requested mean degree is incompatible with the connected-component sizes.');
graphs=cell(numel(degrees),1);
for k=1:numel(degrees),graphs{k}=false(n);end
for component=1:numel(componentIds)
    c=componentIds(component);
    ids=find(groups==c);nc=numel(ids);assert(nc>1);
    [ii,jj]=find(triu(true(nc),1));d=sqrt(sum((xy(ids(ii),:)-xy(ids(jj),:)).^2,2));
    G=graph(ii,jj,d,nc);tree=minspantree(G);backbone=sort(tree.Edges.EndNodes,2);
    isTree=ismember([ii jj],backbone,'rows');other=find(~isTree);
    [~,order]=sortrows([d(other),ii(other),jj(other)],[1 2 3]);edgeOrder=[find(isTree);other(order)];
    for k=1:numel(degrees)
        count=componentEdges(component,k);
        assert(count>=nc-1&&count<=numel(ii),'Mean degree incompatible with component size.');
        e=edgeOrder(1:count);u=ids(ii(e));v=ids(jj(e));A=graphs{k};
        A(sub2ind([n n],u,v))=true;A(sub2ind([n n],v,u))=true;graphs{k}=A;
    end
end
meta=struct('xy',xy,'groups',groups,'targetDegrees',degrees,'meanDegrees',zeros(size(degrees)),'components',zeros(size(degrees)));
meta.componentSizes=componentSizes;meta.componentEdges=componentEdges;
[~,order]=sort(degrees);
for k=1:numel(degrees)
    A=graphs{k};assert(~any(diag(A))&&isequal(A,A')&&all(sum(A,2)>0));
    meta.meanDegrees(k)=nnz(A)/n;meta.components(k)=max(conncomp(graph(A)));
    assert(abs(meta.meanDegrees(k)-degrees(k))<1e-10,'Requested mean degree is not exactly attainable with current groups.');
    assert(meta.components(k)==numel(unique(groups)));
    if k>1,old=graphs{order(k-1)};new=graphs{order(k)};assert(all(new(old)));end
end
end
