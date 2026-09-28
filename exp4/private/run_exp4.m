function analysis=run_exp4(options)
% Loss comparison with identical attacked nodes for GURA, GRA and RRA.
% Default monitoringOffset=2 reproduces the supplied Lsm.m exactly.
if nargin<1,options=struct;end
eta=0; % Compatibility metadata; all allocation objectives are cost-free.
base=fileparts(fileparts(mfilename('fullpath')));
o=struct('attackRate',.1,'trials',200,'seed',20260921,'kappa',100,...
 'monitoringOffset',1,'visible','off','outputDir',fullfile(base,'results'),...
 'solverOptions',struct('verbose',false,'bestResponseSolver','fmincon'));
f=fieldnames(options);for k=1:numel(f),assert(isfield(o,f{k}),'Unknown option: %s',f{k});o.(f{k})=options.(f{k});end
assert(eta==0,'Cost-free experiment.');
assert(isscalar(o.attackRate)&&isfinite(o.attackRate)&&o.attackRate>=0&&o.attackRate<=1,'Invalid attack rate.');
assert(isscalar(o.trials)&&isfinite(o.trials)&&o.trials>=1&&fix(o.trials)==o.trials,'Invalid trial count.');
assert(isscalar(o.monitoringOffset)&&any(o.monitoringOffset==[1 2]),'Invalid monitoring offset.');
assert(isscalar(o.kappa)&&isfinite(o.kappa)&&o.kappa>=0,'Invalid kappa.');
if ~exist(o.outputDir,'dir'),mkdir(o.outputDir);end
old=rng;cleanup=onCleanup(@()rng(old));rng(o.seed,'twister'); %#ok<NASGU>
names={'Random','Regular','Clustered','Disconnected'};analysis=struct;rows=table;summary=table;
for k=1:4
 name=names{k};p=sm_load_model(fullfile(base,'data',['Parameter_' name '.mat']));
 o.solverOptions.bestResponseSolver='fmincon';
 game=solve_sm_game(fullfile(base,'data',['Parameter_' name '.mat']),eta,o.solverOptions);
 assert(game.converged,'GRA did not converge for %s.',name);
 globalResult=sm_global_benefit(p,1e-5,20000);
 assert(globalResult.converged,'GURA did not converge for %s.',name);
 % GURA keeps the supplied codebase's cost-free log(1+s) benefit objective.
 losses=zeros(o.trials,3);attacks=false(p.n,o.trials);randomAllocations=zeros(p.m,o.trials);
 count=round(p.n*o.attackRate);
 for t=1:o.trials
  xr=zeros(p.m,1);
  for i=1:p.n
   e=p.rows{i};if isempty(e),continue;end
   w=rand(numel(e),1);xr(e)=p.C(i)*w/sum(w);
  end
  sigma=false(p.n,1);sigma(randperm(p.n,count))=true;
  attacks(:,t)=sigma;randomAllocations(:,t)=xr;
  % Same attack scenario for all three strategies; retain all zero edge entries.
  losses(t,1)=sm_attack_loss(p,globalResult.x,sigma,o.kappa,o.monitoringOffset);
  losses(t,2)=sm_attack_loss(p,game.x,sigma,o.kappa,o.monitoringOffset);
  losses(t,3)=sm_attack_loss(p,xr,sigma,o.kappa,o.monitoringOffset);
 end
 delta=losses-losses(:,1);
 if any(~isfinite(delta(:)))
  warning('AMI:UndefinedLoss','%s has nonfinite losses/differences. They are retained in data and omitted from plots.',name);
 end
 analysis.(name)=struct('eta',eta,'game',game,'global',globalResult,...
  'xRRA',randomAllocations,'attacks',attacks,'losses',losses,'delta',delta,...
  'methods',{{'GURA','GRA','RRA'}},'realizedAttackRate',count/p.n);
 tab=array2table([losses delta],'VariableNames',{'LA_GURA','LA_GRA','LA_RRA',...
 'Delta_GURA','Delta_GRA','Delta_RRA'});
 tab=addvars(tab,repmat(string(name),o.trials,1),(1:o.trials)',...
  'Before',1,'NewVariableNames',{'Network','Trial'});rows=[rows;tab]; %#ok<AGROW>
 tab=table(repmat(string(name),3,1),["GURA";"GRA";"RRA"],...
  mean(losses,1)',std(losses,0,1)',mean(delta,1)',sum(~isfinite(losses),1)',...
  'VariableNames',{'Network','Method','MeanLoss','StdLoss','MeanDelta','NonfiniteLossCount'});
 summary=[summary;tab]; %#ok<AGROW>
 fprintf('%s: %d/%d attacked, GRA gap %.3g; mean losses [GURA GRA RRA] = %s\n',...
 name,count,p.n,game.gapUpper,mat2str(mean(losses),6));
end
analysis.options=o;analysis.eta=eta;analysis.summary=summary;
plot_sm_losses(analysis);
writetable(rows,fullfile(o.outputDir,'loss_trials.csv'));writetable(summary,fullfile(o.outputDir,'loss_summary.csv'));
save(fullfile(o.outputDir,'loss_analysis.mat'),'analysis');
fid=fopen(fullfile(o.outputDir,'figure_caption.tex'),'w');
fprintf(fid,['\\caption{Relative system losses $\\Delta L_A=L_A^{\\mathrm{method}}-L_A^{\\mathrm{GURA}}$ ',...
 'across four SM networks: (a) uniformly random; (b) regular; (c) clustered; and (d) disconnected. ',...
 'In each of %d experiments, %.0f\\%% of the SMs are sampled uniformly without replacement ',...
 'as compromised nodes ($P_C=%.4g$). All strategies share the same attacked nodes in each experiment. ',...
 'All allocation methods exclude monitoring costs; $\\kappa=%.4g$. ',...
 'Losses use $M_i=\\ln(%g+s_i)$. The GURA baseline has zero relative loss.}\n'],...
 o.trials,100*o.attackRate,o.attackRate,o.kappa,o.monitoringOffset);
fclose(fid);
end
