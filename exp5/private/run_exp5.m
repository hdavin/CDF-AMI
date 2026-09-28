function analysis=run_exp5(options)
if nargin<1,options=struct;end
eta=0; % Compatibility metadata only.
base=fileparts(fileparts(mfilename('fullpath')));
o=struct('attackRates',[.1 .3 .5 .7],'randomCount',100,'seed',20260924,...
 'kappa',100,'monitoringOffset',1,'visible','off','dataDir',fullfile(base,'data'),...
 'outputDir',fullfile(base,'results'),'solverOptions',struct('verbose',false,'bestResponseSolver','fmincon'));
f=fieldnames(options);for k=1:numel(f),assert(isfield(o,f{k}),'Unknown option: %s',f{k});o.(f{k})=options.(f{k});end
assert(eta==0,'Cost-free experiment.');
assert(isvector(o.attackRates)&&~isempty(o.attackRates)&&all(isfinite(o.attackRates))&&all(o.attackRates>=0&o.attackRates<=1)&&all(diff(o.attackRates)>0),'Invalid attack rates.');o.attackRates=o.attackRates(:)';
assert(isscalar(o.randomCount)&&isfinite(o.randomCount)&&o.randomCount>=2&&fix(o.randomCount)==o.randomCount,'Invalid randomCount.');
assert(isscalar(o.kappa)&&isfinite(o.kappa)&&o.kappa>=0,'Invalid kappa.');
assert(isscalar(o.monitoringOffset)&&any(o.monitoringOffset==[1 2]),'Invalid offset.');
if ~exist(o.outputDir,'dir'),mkdir(o.outputDir);end
old=rng;cleanup=onCleanup(@()rng(old));rng(o.seed,'twister'); %#ok<NASGU>
names={'Random','Regular','Clustered','Disconnected'};types={'SecurityLevel','Trust','Degree'};
analysis=struct;summary=table;trialTable=table;rankTable=table;
for net=1:4
 name=names{net};file=fullfile(o.dataDir,['Parameter_' name '.mat']);p=sm_load_model(file);
 o.solverOptions.bestResponseSolver='fmincon';game=solve_sm_game(file,eta,o.solverOptions);
 assert(game.converged,'GRA did not converge for %s.',name);
 globalResult=sm_global_benefit(p,1e-5,20000);assert(globalResult.converged,'GURA did not converge for %s.',name);
 xRRA=zeros(p.m,o.randomCount);
 for t=1:o.randomCount
  for i=1:p.n
   e=p.rows{i};if isempty(e),continue;end
   w=rand(numel(e),1);xRRA(e,t)=p.C(i)*w/sum(w);
  end
 end
 % Preserve original column-based received trust and exclude zero entries.
 den=sum(p.TV>0,1)';trust=zeros(p.n,1);has=den>0;
 sums=sum(p.TV,1)';trust(has)=sums(has)./den(has);
 degreeScore=centrality(graph(p.Adj),'degree');scores=[p.SL trust degreeScore];
 nr=numel(o.attackRates);counts=round(p.n*o.attackRates);
 attacks=false(p.n,nr,3);ranks=zeros(p.n,3);
 losses=zeros(nr,3,3);randomLosses=zeros(o.randomCount,nr,3);randomSD=zeros(nr,3);
 for type=1:3
  % Explicit stable ascending rank, then take the tail, as in supplied sort code.
  [~,rank]=sortrows([scores(:,type),(1:p.n)'],[1 2]);ranks(:,type)=rank;
  for j=1:nr
   ids=rank(p.n-counts(j)+1:p.n);sigma=false(p.n,1);sigma(ids)=true;attacks(:,j,type)=sigma;
   losses(j,1,type)=sm_attack_loss(p,globalResult.x,sigma,o.kappa,o.monitoringOffset);
   losses(j,2,type)=sm_attack_loss(p,game.x,sigma,o.kappa,o.monitoringOffset);
   for t=1:o.randomCount
    randomLosses(t,j,type)=sm_attack_loss(p,xRRA(:,t),sigma,o.kappa,o.monitoringOffset);
   end
   losses(j,3,type)=mean(randomLosses(:,j,type));randomSD(j,type)=std(randomLosses(:,j,type));
   assert(sum(sigma)==counts(j));
  end
  tab=table(repmat(string(name),nr,1),repmat(string(types{type}),nr,1),o.attackRates',counts'/p.n,...
   losses(:,1,type),losses(:,2,type),losses(:,3,type),randomSD(:,type),...
   'VariableNames',{'Network','AttackType','PC','RealizedPC','LossGURA','LossGRA','MeanLossRRA','StdLossRRA'});
  summary=[summary;tab]; %#ok<AGROW>
  [t,pc]=ndgrid(1:o.randomCount,o.attackRates);
  tab=table(repmat(string(name),numel(t),1),repmat(string(types{type}),numel(t),1),pc(:),t(:),...
   reshape(randomLosses(:,:,type),[],1),'VariableNames',{'Network','AttackType','PC','Trial','LossRRA'});
  trialTable=[trialTable;tab]; %#ok<AGROW>
 end
 if any(~isfinite(losses(:))),warning('AMI:NonfiniteLoss','%s has nonfinite losses; retained in data, omitted from plots.',name);end
 rankTable=[rankTable;table(repmat(string(name),p.n,1),(1:p.n)',scores(:,1),scores(:,2),scores(:,3),...
  'VariableNames',{'Network','Node','SecurityLevel','ReceivedTrust','Degree'})]; %#ok<AGROW>
 analysis.(name)=struct('game',game,'global',globalResult,'xRRA',xRRA,'scores',scores,'ascendingRanks',ranks,...
  'attacks',attacks,'losses',losses,'randomLosses',randomLosses,'randomSD',randomSD,...
  'methods',{{'GURA','GRA','RRA'}},'attackTypes',{types},'realizedAttackRates',counts/p.n);
 fprintf('%s: 3 targeted-attack types x %d proportions; GRA gap %.3g\n',name,nr,game.gapUpper);
end
analysis.eta=eta;analysis.options=o;analysis.summary=summary;
plot_targeted_losses(analysis);
writetable(summary,fullfile(o.outputDir,'targeted_loss_summary.csv'));
writetable(trialTable,fullfile(o.outputDir,'random_loss_trials.csv'));
writetable(rankTable,fullfile(o.outputDir,'node_attack_scores.csv'));
save(fullfile(o.outputDir,'targeted_loss_analysis.mat'),'analysis');
fid=fopen(fullfile(o.outputDir,'figure_captions.tex'),'w');labels={'security level','received trust','degree centrality'};
for type=1:3
 fprintf(fid,['%% Figure %d\n\\caption{System losses $L_A$ under GURA, GRA, and RRA across four SM networks: ',...
 '(a) uniformly random; (b) regular; (c) clustered; and (d) disconnected. ',...
 'For each $P_C\\in\\{%s\\}$, the top-ranked proportion of SMs by %s is compromised. ',...
 'All strategies use the same attacked nodes. RRA bars show means over %d random allocations; ',...
 'GURA and GRA bars show deterministic losses. All methods exclude monitoring costs. Here $\\kappa=%.4g$, ',...
 'and loss evaluation uses $M_i=\\ln(%g+s_i)$.}\n\n'],10+type,...
 strjoin(arrayfun(@(v)sprintf('%.2g',v),o.attackRates,'UniformOutput',false),','),labels{type},o.randomCount,o.kappa,o.monitoringOffset);
end
fclose(fid);
end
