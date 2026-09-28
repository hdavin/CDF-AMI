function result = solve_sm_game(parameterFile,eta,options)
% SOLVE_SM_GAME Cyclic individual best responses; default backend is fmincon.
% result=solve_sm_game('data/Parameter_Random.mat',0)
% Positive effective weights are checked for the cost-free convergence theorem.
% Uses cyclic individual best responses, NOT the original NIRA line search.
if nargin<2, eta=0; end
if nargin<3, options=struct; end
opts=struct('gapTolerance',1e-6,'innerTolerance',1e-12,'maxSweeps',10000,...
    'verbose',true,'initialAllocation',[],'storeAllocations',false,'bestResponseSolver','fmincon');
names=fieldnames(options);
for k=1:numel(names)
    assert(isfield(opts,names{k}),'Unknown option: %s',names{k});
    opts.(names{k})=options.(names{k});
end
assert(isscalar(opts.gapTolerance)&&isfinite(opts.gapTolerance)&&opts.gapTolerance>0,'Invalid gap tolerance.');
assert(isscalar(opts.innerTolerance)&&isfinite(opts.innerTolerance)&&opts.innerTolerance>0,'Invalid inner tolerance.');
assert(isscalar(opts.maxSweeps)&&opts.maxSweeps>=0&&opts.maxSweeps==floor(opts.maxSweeps),'Invalid sweep limit.');
assert(any(strcmp(opts.bestResponseSolver,{'fmincon','analytic'})),'Unknown best-response solver.');
if strcmp(opts.bestResponseSolver,'fmincon')
    assert(exist('fmincon','file')==2 && license('test','Optimization_Toolbox'),'GRA requires Optimization Toolbox.');
end
clock=tic; p=sm_load_model(parameterFile);
assert(isnumeric(eta)&&isscalar(eta)&&eta==0,'This solver is cost-free; eta must be zero.');
etaMode='cost_free';
active=p.C(p.src)>0;
assert(all(p.a(active)>0 & p.SL(p.dst(active))>0),'Point-convergence theorem requires positive effective weights.');
x=zeros(p.m,1);
if ~isempty(opts.initialAllocation)
    x=opts.initialAllocation;
    if isequal(size(x),[p.n p.n]), x=x(sub2ind([p.n p.n],p.src,p.dst)); end
    x=x(:);
    assert(numel(x)==p.m && all(isfinite(x)&x>=0&x<=p.ub),'Invalid initial allocation.');
    assert(all(accumarray(p.src,x,[p.n 1])<=p.C+1e-12),'Initial allocation exceeds capacity.');
end
s=accumarray(p.dst,p.a.*x,[p.n 1]);
h=zeros(opts.maxSweeps+1,6); if opts.storeAllocations, allocations=zeros(p.m,opts.maxSweeps+1); end
status='max_sweeps';
for sweep=0:opts.maxSweeps
    [gu,gl]=sm_gap(p,x,eta,opts.innerTolerance);
    benefit=sum(p.SL.*log1p(s)); cost=0;
    h(sweep+1,:)=[sweep,gu,gl,benefit,benefit-cost,toc(clock)];
    if opts.storeAllocations, allocations(:,sweep+1)=x; end
    if opts.verbose && (sweep==0 || mod(sweep,10)==0 || gu<=opts.gapTolerance)
        fprintf('sweep=%d  gapUpper=%.3g  benefit=%.6g  cost=%.6g\n',sweep,gu,benefit,cost);
    end
    if gu<=opts.gapTolerance, status='converged'; break; end
    if sweep==opts.maxSweeps, break; end
    old=x;
    for i=1:p.n
        e=p.rows{i}; j=p.dst(e); b=1+s(j)-p.a(e).*x(e);
        if strcmp(opts.bestResponseSolver,'fmincon')
        z=sm_best_response_fmincon(x(e),b,p.a(e),p.SL(j),p.C(i),p.ub(e),eta);
    else
        z=sm_best_response(x(e),b,p.a(e),p.SL(j),p.C(i),p.ub(e),eta,opts.innerTolerance);
    end
        s(j)=s(j)+p.a(e).*(z-x(e)); x(e)=z;
    end
    s=accumarray(p.dst,p.a.*x,[p.n 1]); % remove accumulated roundoff
    if norm(x-old,inf)==0
        status='numerical_stagnation';
        % Evaluate the certificate at the unchanged profile on the next pass.
        if gu>opts.gapTolerance, break; end
    end
end
monitor=log1p(s); playerBenefit=full(p.Adj*(p.SL.*monitor));
playerCost=zeros(p.n,1);
result=struct('status',status,'converged',strcmp(status,'converged'),...
 'eta',eta,'etaMode',etaMode,'LphiBound',p.LphiBound,...
 'satisfiesConservativeNiraBound',eta>p.LphiBound/4,...
 'method','cyclic_individual_best_response','bestResponseSolver',opts.bestResponseSolver,'x',x,...
 'X_Game',full(sparse(p.src,p.dst,x,p.n,p.n)),...
 'src',p.src,'dst',p.dst,'monitoringDegree',monitor,...
 'playerBenefit',playerBenefit,'playerCost',playerCost,...
 'playerNetUtility',playerBenefit-playerCost,'totalSecurityBenefit',sum(p.SL.*monitor),...
 'totalMonitoringCost',sum(playerCost),'potential',sum(p.SL.*monitor)-sum(playerCost),...
 'sumPlayerNetUtility',sum(playerBenefit-playerCost),...
 'gapUpper',gu,'gapLower',gl,'sweeps',sweep,'seconds',toc(clock),...
 'history',h(1:sweep+1,:),'historyColumns',{{'sweep','gapUpper','gapLower','totalSecurityBenefit','potential','seconds'}},...
 'options',opts,'source',p.name);
if opts.storeAllocations, result.allocations=allocations(:,1:sweep+1); end
if ~result.converged, warning('AMI:NotConverged','Stopped with %s, gap upper bound %.3g.',status,gu); end
end
