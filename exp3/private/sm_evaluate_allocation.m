function r=sm_evaluate_allocation(p,x,eta)
% Consistent metrics for any feasible directed-edge allocation (zeros retained).
x=x(:); assert(numel(x)==p.m && all(isfinite(x)) && all(x>=0),'Invalid allocation.');
assert(all(x<=p.ub+1e-9) && all(accumarray(p.src,x,[p.n 1])<=p.C+1e-9),'Infeasible allocation.');
M=log1p(accumarray(p.dst,p.a.*x,[p.n 1]));
benefit=full(p.Adj*(p.SL.*M)); cost=zeros(p.n,1);
r=struct('totalSecurityBenefit',sum(p.SL.*M),'totalMonitoringCost',sum(cost),...
 'potential',sum(p.SL.*M)-sum(cost),'sumPlayerNetUtility',sum(benefit-cost),...
 'playerNetUtility',benefit-cost,'monitoringDegree',M,...
 'receivedResource',accumarray(p.dst,x,[p.n 1]));
end
