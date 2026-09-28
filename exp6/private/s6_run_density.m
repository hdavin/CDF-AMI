function out=s6_run_density(input)
kind='density';o=s6_options(input,kind);config=rmfield(o,{'outputDir','visible','plotResults','resume'});config.priorityDefinition='random_gamma_times_max_mean_v3';records=cell(0,1);
for t=1:numel(o.topologies)
 name=o.topologies{t};basep=sm_load_model(fullfile(o.dataDir,['Parameter_' name '.mat']));n=basep.n;
 coords=load(fullfile(o.dataDir,['Coordinates_' name '.mat']),'xy');
 assert(size(coords.xy,1)==n);
 [graphs,network]=s6_density_graphs(coords.xy,name,o.meanDegrees);
 [~,imax]=max(o.meanDegrees);[allSrc,allDst]=find(graphs{imax}'); % row-major donor order
 tmp=allSrc;allSrc=allDst;allDst=tmp;
 allEdges=sub2ind([n n],allSrc,allDst);
 for rep=1:o.repetitions
  seed=o.seed+10000*t+rep;path=fullfile(o.outputDir,sprintf('%s_R%03d.mat',name,rep));
  if o.resume&&exist(path,'file')
   z=load(path,'trial','config');assert(isequaln(z.config,config),'Settings changed: choose a new outputDir or resume=false.');trial=z.trial;
  else
   state=rng;cleanup=onCleanup(@()rng(state));rng(seed,'twister');
   [priority,peak,average,gamma]=s6_security_level(o,n);
   C0=20*ones(n,1);attackMasks=false(n,o.trials);
   for k=1:o.trials,attackMasks(randperm(n,round(o.attackRate*n)),k)=true;end
   % Existing pair-specific scores retained; potential new links sample the
   % empirical positive-edge score distribution once, before the density sweep.
   pool=basep.TV(basep.Adj);assert(all(pool>0&pool<=1));
   pairTrust=pool(randi(numel(pool),n,n));pairTrust(basep.Adj)=basep.TV(basep.Adj);pairTrust(1:n+1:end)=0;
   randomWeights=rand(numel(allEdges),o.trials);trial=table;diagnostics=cell(numel(o.meanDegrees),1);
   for g=1:numel(o.meanDegrees)
    Adj=graphs{g};p=sm_load_model(struct('Adj',Adj,'TV',pairTrust.*Adj,'SL',priority,'C',C0));
    edgeIds=sub2ind([n n],p.src,p.dst);[present,idx]=ismember(edgeIds,allEdges);assert(all(present));
    rweights=randomWeights(idx,:);den=zeros(n,o.trials);
    for k=1:o.trials,den(:,k)=accumarray(p.src,rweights(:,k),[n 1]);end
    randomX=(rweights./den(p.src,:)).*C0(p.src);
    gra=s6_solve(p,o);gura=sm_global_benefit(p,o.globalTolerance,o.globalMaxIterations);
    rr=cell(o.trials,1);for k=1:o.trials,rr{k}=s6_metrics(p,randomX(:,k),attackMasks(:,k),o.kappa);end
    rra=rr{1};fields=fieldnames(rra);for j=1:numel(fields),rra.(fields{j})=mean(cellfun(@(q)q.(fields{j}),rr));end
    metrics={s6_metrics(p,gura.x,attackMasks,o.kappa),s6_metrics(p,gra.x,attackMasks,o.kappa),rra};
    methods={'GURA','GRA','RRA'};conv=[gura.converged gra.converged true];gaps=[gura.gapUpper gra.gap NaN];
    for j=1:3
     q=metrics{j};row=table(string(name),rep,seed,o.meanDegrees(g),string(methods{j}),conv(j),gaps(j),...
      q.Utility,q.NormalizedUtility,q.Loss,q.NormalizedLoss,q.InfiniteLossFraction,q.UnmonitoredFraction,...
      n,nnz(Adj)/n,nnz(Adj)/2,nnz(Adj)/(n*(n-1)),network.components(g),...
      'VariableNames',{'Topology','Repetition','Seed','Parameter','Method','Converged','GapUpper',...
      'Utility','NormalizedUtility','Loss','NormalizedLoss','InfiniteLossFraction','UnmonitoredFraction',...
      'N','MeanDegree','Edges','EdgeDensity','Components'});
     trial=[trial;row]; %#ok<AGROW>
    end
    diagnostics{g}=struct('meanDegree',o.meanDegrees(g),'Adj',Adj,'src',p.src,'dst',p.dst,'GRA',gra,'GURA',gura);
   end
   inputs=struct('C0',C0,'attackMasks',attackMasks,'peak',peak,'average',average,'priority',priority,'gamma',gamma,...
    'pairTrust',pairTrust,'randomWeights',randomWeights,'allSrc',allSrc,'allDst',allDst);
   save(path,'trial','inputs','diagnostics','network','config');clear cleanup;
  end
  records{end+1}=trial;out=vertcat(records{:});writetable(out,fullfile(o.outputDir,'trials.csv')); %#ok<AGROW>
  fprintf('density %s repetition %d/%d complete\n',name,rep,o.repetitions);
 end
end
save(fullfile(o.outputDir,'analysis_results.mat'),'out','o','kind');
if o.plotResults,s6_plot(out,o,kind);end
end
