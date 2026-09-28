function r=sm_global_benefit(p,tolerance,maxIterations)
% GURA: maximize total security utility (no monitoring cost).
% Base MATLAB only; first-order gap bounds remaining global improvement.
if nargin<2,tolerance=1e-5;end
if nargin<3,maxIterations=20000;end
assert(all(p.ub>=p.C(p.src)),'This baseline expects redundant edge bounds.');
x=zeros(p.m,1);y=x;t=1;L=1;gap=inf;
for iteration=0:maxIterations
    [value,g]=benefit(x,p);
    support=0;
    for i=1:p.n
        e=p.rows{i};if ~isempty(e),support=support+p.C(i)*max([0;g(e)]);end
    end
    gap=max(0,support-g'*x);
    if gap<=tolerance || iteration==maxIterations,break;end
    [fy,gy]=benefit(y,p);
    if ~isfinite(fy),y=x;t=1;[fy,gy]=benefit(y,p);end
    L=max(L*.8,1e-12);
    for backtrack=1:100
        z=project(y+gy/L,p);d=z-y;fz=benefit(z,p);
        if fz>=fy+gy'*d-L/2*(d'*d)-1e-13*max(1,abs(fy)),break;end
        L=L*2;
    end
    assert(backtrack<100,'Global line search failed.');
    nextT=(1+sqrt(1+4*t*t))/2;
    nextY=z+(t-1)/nextT*(z-x);
    % Adaptive momentum restart preserves feasibility of the reported iterate.
    if (y-z)'*(z-x)>0,nextT=1;nextY=z;end
    x=z;y=nextY;t=nextT;
end
r=struct('x',x,'totalSecurityUtility',value,'benefit',value,'objective','total security utility','gapUpper',gap,...
 'converged',gap<=tolerance,'iterations',iteration);
if ~r.converged,warning('AMI:GlobalNotConverged','GURA gap %.3g exceeds tolerance.',gap);end
end
function [v,g]=benefit(x,p)
s=accumarray(p.dst,p.a.*x,[p.n 1]);
% Extrapolated profiles can be outside X; backtracking uses a domain-safe restart.
if any(s<=-1),v=-inf;g=nan(p.m,1);return;end
v=sum(p.SL.*log1p(s));
if nargout>1,g=p.a.*p.SL(p.dst)./(1+s(p.dst));end
end
function z=project(v,p)
z=max(v,0);
for i=1:p.n
    e=p.rows{i};if isempty(e),continue;end
    if p.C(i)==0,z(e)=0;continue;end
    if sum(z(e))>p.C(i)
        u=sort(v(e),'descend');c=cumsum(u)-p.C(i);
        k=find(u>c./(1:numel(e))',1,'last');z(e)=max(0,v(e)-c(k)/k);
    end
end
end
