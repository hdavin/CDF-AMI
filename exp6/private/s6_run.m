function out=s6_run(kind,input)
assert(any(strcmp(kind,{'capacity','penalty'})));
o=s6_options(input,kind);config=rmfield(o,{'outputDir','visible','plotResults','resume'});records=cell(0,1);
for t=1:numel(o.topologies)
 name=o.topologies{t};basep=sm_load_model(fullfile(o.dataDir,['Parameter_' name '.mat']));
 assert(all(basep.a>0),'Stored monitoring-edge trust must be positive; do not silently floor zeros.');
 if ~strcmp(kind,'penalty')
  config.priorityDefinition='random_gamma_times_max_mean_v3';
  config.capacityDefinition='uniform_per_node_absolute_v1';
 end
 for rep=1:o.repetitions
  seed=o.seed+10000*t+rep;path=fullfile(o.outputDir,sprintf('%s_R%03d.mat',name,rep));
  if o.resume&&exist(path,'file')
   z=load(path);assert(isequaln(z.config,config),'Settings changed: choose a new outputDir or resume=false.');trial=z.trial;
  else
   state=rng;cleanup=onCleanup(@()rng(state));rng(seed,'twister');
   n=basep.n;Adj=full(basep.Adj);
   if ~strcmp(kind,'penalty'),[priority,peak,average,gamma]=s6_security_level(o,n);end
   if strcmp(kind,'penalty')
    attack=randperm(n,round(o.trustAttackRate*n));normal=setdiff(1:n,attack);trial=table;
    for pt=o.testRates
     for w=o.penalties
      [T,d]=s6_trust(o.K,Adj,pt,attack,w,o,seed+300000);
      % Only honest receivers assess trusted providers; per-provider means.
      nodeScore=nan(n,1);
      for j=1:n,ids=normal(Adj(normal,j)>0);if ~isempty(ids),nodeScore(j)=mean(T(ids,j));end;end
      normalScores=nodeScore(normal);badScores=nodeScore(attack);
      normalScores=normalScores(isfinite(normalScores));badScores=badScores(isfinite(badScores));
      mn=mean(normalScores);mb=mean(badScores);
      auc=NaN;if ~isempty(normalScores)&&~isempty(badScores)
       delta=normalScores(:)-badScores(:)';auc=mean((delta>0)+.5*(delta==0),'all');
      end
      row=table(string(name),rep,seed,w,pt,mn,mb,mn-mb,auc,numel(normalScores),numel(badScores),d.testRounds,d.ties,...
       'VariableNames',{'Topology','Repetition','Seed','Penalty','TestRate','NormalTrust','CompromisedTrust','TrustSeparation','RankingAUC','NormalObserved','CompromisedObserved','TestRounds','NeutralTies'});
      trial=[trial;row]; %#ok<AGROW>
     end
    end
    inputs=struct('attack',attack,'Adj',Adj);
   else
    % Preserve the previous attack/RRA random draws. This reference draw is
    % saved only for reproducibility and is NOT used as the resource budget.
    legacyC0=20*rand(n,1);attackMasks=false(n,o.trials);
    for k=1:o.trials,attackMasks(randperm(n,round(o.attackRate*n)),k)=true;end
    fractions=rand(basep.m,o.trials);tot=zeros(n,o.trials);
    for k=1:o.trials,tot(:,k)=accumarray(basep.src,fractions(:,k),[n 1]);end
    fractions=fractions./tot(basep.src,:);trial=table;diagnostics=cell(0,1);
    values=o.capacities;
    for value=values
     p=basep;
     p.C=value*ones(n,1);p.SL=priority;
     p.ub=p.C(p.src);
     gra=s6_solve(p,o);gura=sm_global_benefit(p,o.globalTolerance,o.globalMaxIterations);
     randomX=fractions.*p.C(p.src);rr=cell(o.trials,1);
     for k=1:o.trials,rr{k}=s6_metrics(p,randomX(:,k),attackMasks(:,k),o.kappa);end
     rra=rr{1};f=fieldnames(rra);for j=1:numel(f),rra.(f{j})=mean(cellfun(@(q)q.(f{j}),rr));end
     metrics={s6_metrics(p,gura.x,attackMasks,o.kappa),s6_metrics(p,gra.x,attackMasks,o.kappa),rra};
     methods={'GURA','GRA','RRA'};conv=[gura.converged gra.converged true];gaps=[gura.gapUpper gra.gap NaN];
     for j=1:3
      q=metrics{j};row=table(string(name),rep,seed,value,string(methods{j}),conv(j),gaps(j),q.Utility,q.NormalizedUtility,q.Loss,q.NormalizedLoss,q.InfiniteLossFraction,q.UnmonitoredFraction,...
       'VariableNames',{'Topology','Repetition','Seed','Parameter','Method','Converged','GapUpper','Utility','NormalizedUtility','Loss','NormalizedLoss','InfiniteLossFraction','UnmonitoredFraction'});
      trial=[trial;row]; %#ok<AGROW>
     end
     diagnostics{end+1}=struct('parameter',value,'C',p.C,'GRA',gra,'GURA',gura); %#ok<AGROW>
    end
    inputs=struct('capacityValues',o.capacities,'capacityRule','uniform_per_node',...
     'legacyC0',legacyC0,'attackMasks',attackMasks,'randomFractions',fractions,...
     'peak',peak,'average',average,'priority',priority,'gamma',gamma,'TV',basep.TV,'Adj',Adj);
   end
   if strcmp(kind,'penalty'),diagnostics=[];end
   save(path,'trial','inputs','diagnostics','config');clear cleanup;
  end
  records{end+1}=trial;out=vertcat(records{:});writetable(out,fullfile(o.outputDir,'trials.csv')); %#ok<AGROW>
  fprintf('%s %s repetition %d/%d complete\n',kind,name,rep,o.repetitions);
 end
end
save(fullfile(o.outputDir,'analysis_results.mat'),'out','o','kind');
if o.plotResults,s6_plot(out,o,kind);end
end
