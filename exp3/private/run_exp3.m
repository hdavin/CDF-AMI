function analysis=run_exp3(options)
% Experiment 1: compute only manuscript Figures 7 and 8.
% Called through main_fig7_fig8.
% GRA: cost-free equilibrium; GURA: centralized maximum of the total security utility.
% RRA: original normalized uniform random weights, using full donor capacities.
if nargin<1,options=struct;end
eta=0; % Compatibility field only; all objectives are cost-free.
base=fileparts(fileparts(mfilename('fullpath')));
o=struct('randomCount',1000,'seed',20260920,'outputDir',fullfile(base,'results'),...
 'visible','off','globalTolerance',1e-5,'globalMaxIterations',20000,'solverOptions',struct('verbose',false,'bestResponseSolver','fmincon'));
f=fieldnames(options);for k=1:numel(f),assert(isfield(o,f{k}),'Unknown option: %s',f{k});o.(f{k})=options.(f{k});end
assert(eta==0,'Cost-free experiment.');
assert(isscalar(o.randomCount)&&o.randomCount>=1&&o.randomCount==floor(o.randomCount),'Invalid sample count.');
assert(isscalar(o.seed)&&isfinite(o.seed)&&o.seed>=0&&o.seed==floor(o.seed),'Invalid seed.');
assert(isscalar(o.globalTolerance)&&isfinite(o.globalTolerance)&&o.globalTolerance>0,'Invalid tolerance.');
assert(isscalar(o.globalMaxIterations)&&o.globalMaxIterations>=0&&o.globalMaxIterations==floor(o.globalMaxIterations),'Invalid limit.');
if ~exist(o.outputDir,'dir'),mkdir(o.outputDir);end
assert(~isfield(o.solverOptions,'bestResponseSolver') || strcmp(o.solverOptions.bestResponseSolver,'fmincon'),'Step3 GRA requires fmincon.');
o.solverOptions.bestResponseSolver='fmincon';
state=rng;restore=onCleanup(@()rng(state));rng(o.seed,'twister'); %#ok<NASGU>
names={'Random','Regular','Clustered','Disconnected'};analysis=struct;
metricNames={'totalSecurityBenefit','totalMonitoringCost','potential','sumPlayerNetUtility'};
summary=table; samples=table;
for k=1:4
    name=names{k}; file=fullfile(base,'data',['Parameter_' name '.mat']);p=sm_load_model(file);
    game=solve_sm_game(file,eta,o.solverOptions);
    assert(game.converged,'GRA failed its gap tolerance for %s; refusing to plot as equilibrium.',name);
    globalResult=sm_global_benefit(p,o.globalTolerance,o.globalMaxIterations);
    assert(globalResult.converged,'GURA failed its optimality tolerance for %s.',name);
    gra=sm_evaluate_allocation(p,game.x,eta);gura=sm_evaluate_allocation(p,globalResult.x,eta);
    randomMetrics=zeros(o.randomCount,4);randomReceived=zeros(p.n,1);
    for trial=1:o.randomCount
        x=zeros(p.m,1);
        for i=1:p.n
            e=p.rows{i};if isempty(e),continue;end
            weights=rand(numel(e),1);x(e)=p.C(i)*weights/sum(weights);
        end
        r=sm_evaluate_allocation(p,x,eta);randomReceived=randomReceived+r.receivedResource/o.randomCount;
        for j=1:4,randomMetrics(trial,j)=r.(metricNames{j});end
    end
    metrics=zeros(3,4);for j=1:4,metrics(:,j)=[gura.(metricNames{j});gra.(metricNames{j});mean(randomMetrics(:,j))];end
    rows=table(repmat(string(name),3,1),["GURA";"GRA";"RRA mean"],repmat(eta,3,1),...
      metrics(:,1),metrics(:,2),metrics(:,3),metrics(:,4),...
      'VariableNames',{'Network','Method','Eta','TotalSecurityUtility','MonitoringCost','Potential','SumPlayerNetUtility'});
    rows.NetworkNetSecurityUtility=rows.TotalSecurityUtility-rows.MonitoringCost;
    summary=[summary;rows]; %#ok<AGROW>
    rows=array2table(randomMetrics,'VariableNames',metricNames);
    rows=addvars(rows,repmat(string(name),o.randomCount,1),(1:o.randomCount)',...
      'Before',1,'NewVariableNames',{'Network','Trial'});samples=[samples;rows]; %#ok<AGROW>
    assert(gura.potential+globalResult.gapUpper+1e-8>=max([gra.potential;randomMetrics(:,3)]),'GURA security utility upper bound violated.');
    monitor=accumarray(p.dst,p.a.*game.x,[p.n 1]);
    grad=p.a.*p.SL(p.dst)./(1+monitor(p.dst));
    support=0;
    for donor=1:p.n
        edges=p.rows{donor};
        if ~isempty(edges),support=support+p.C(donor)*max([0;grad(edges)]);end
    end
    game.globalSecurityGapUpper=max(0,support-grad'*game.x);
    assert(gra.potential+game.globalSecurityGapUpper+1e-8>=max([gura.potential;randomMetrics(:,3)]),'Global security utility certificate violated.');
    analysis.(name)=struct('game',game,'global',globalResult,'GRA',gra,'GURA',gura,...
      'randomMetrics',randomMetrics,'randomMeanReceived',randomReceived,'securityLevel',p.SL);
    fprintf('%s: GRA gap %.3g, GURA gap %.3g, %d RRA samples\n',name,game.gapUpper,globalResult.gapUpper,o.randomCount);
end
summary=summary(:,{'Network','Method','TotalSecurityUtility'});
samples=removevars(samples,{'totalMonitoringCost','potential'});
analysis.summary=summary;analysis.options=o;analysis.objective='total security utility (cost-free)';
sm_plot_analysis(analysis,names,o);
writetable(summary,fullfile(o.outputDir,'strategy_summary.csv'));
writetable(samples,fullfile(o.outputDir,'random_samples.csv'));
save(fullfile(o.outputDir,'analysis_results.mat'),'analysis');
disp(summary);
end
