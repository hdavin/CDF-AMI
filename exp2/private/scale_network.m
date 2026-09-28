function [p,meta]=scale_network(n,name,targetDegree)
% Spatial candidate graph + MST backbone + shortest unused candidate edges.
% No dense N-by-N arrays. These are controlled sparse spatial graphs, NOT
% unrestricted fixed-radius random geometric graph samples.
switch name
 case 'Random'
  xy=200*sqrt(n/100)*rand(n,2);group=ones(n,1);
 case 'Regular'
  cols=ceil(sqrt(n));q=(0:n-1)';xy=20*[mod(q,cols),floor(q/cols)];group=ones(n,1);
 case {'Clustered','Disconnected'}
  if strcmp(name,'Clustered'),centers=[100 100;40 40;160 40;40 160;160 160];radius=36;
  else,centers=[40 40;40 160;160 40;160 160];radius=45;end
  c=size(centers,1);counts=floor(n/c)*ones(c,1);counts(1:mod(n,c))=counts(1:mod(n,c))+1;
  xy=zeros(n,2);group=zeros(n,1);idx=0;
  for k=1:c
   z=idx+(1:counts(k));angle=2*pi*rand(numel(z),1);r=sqrt(9^2+(radius^2-9^2)*rand(numel(z),1));
   xy(z,:)=centers(k,:)+[r.*cos(angle),r.*sin(angle)];group(z)=k;idx=idx+counts(k);
  end
  xy=xy*sqrt(n/100);
 otherwise,error('Unknown topology.');
end
% Independent disconnected components; clustered topology uses a global backbone.
if ~strcmp(name,'Disconnected'),group(:)=1;end
u=[];v=[];
for c=unique(group)'
 ids=find(group==c);local=xy(ids,:);nc=numel(ids);
 tri=delaunayTriangulation(local);edge=edges(tri);
 A=sparse([edge(:,1);edge(:,2)],[edge(:,2);edge(:,1)],1,nc,nc);
 % Two-hop candidates provide enough edges for target degrees up to 8.
 candidate=spones(A+A*A);candidate=candidate-spdiags(diag(candidate),0,nc,nc);
 [ii,jj]=find(triu(candidate,1));dist=sqrt(sum((local(ii,:)-local(jj,:)).^2,2));
 G=graph(ii,jj,dist,nc);tree=minspantree(G);backbone=sort(tree.Edges.EndNodes,2);
 isTree=ismember([ii jj],backbone,'rows');desired=round(targetDegree*nc/2);
 assert(nnz(isTree)==nc-1 && desired>=nc-1 && numel(ii)>=desired,'Insufficient connected candidates.');
 remaining=find(~isTree);[~,order]=sortrows([dist(remaining),ii(remaining),jj(remaining)],[1 2 3]);
 selected=[find(isTree);remaining(order(1:desired-(nc-1)))];
 u=[u;ids(ii(selected))];v=[v;ids(jj(selected))]; %#ok<AGROW>
end
pairs=sortrows([u v;v u],[1 2]);p.src=pairs(:,1);p.dst=pairs(:,2);p.n=n;p.m=size(pairs,1);
p.degree=accumarray(p.src,1,[n 1]);p.ptr=[1;1+cumsum(p.degree)];
% Controlled synthetic workloads: held to the same distribution at every N.
p.a=.2+.8*rand(p.m,1);p.SL=.5+rand(n,1);p.C=1+19*rand(n,1);
p.w=p.SL(p.dst);p.x0=p.C(p.src)./p.degree(p.src);
cc=conncomp(graph(u,v,[],n));
assert(p.m/n>=2-1e-10&&p.m/n<=8+1e-10);
if strcmp(name,'Disconnected'),assert(max(cc)==4);else,assert(max(cc)==1);end
meta=struct('meanDegree',p.m/n,'maxDegree',max(p.degree),'edges',numel(u),...
 'components',max(cc),'xy',xy,'undirectedEdges',[u v],...
 'generator','spatial Delaunay/two-hop candidates with MST and shortest-edge degree control',...
 'workload','synthetic positive trust U(0.2,1), priority U(0.5,1.5), capacity U(1,20)');
end
