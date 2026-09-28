function results=main_scalability(options)
% Full study: 200:200:10000, four topologies, three independent repetitions.
% Example smoke run: main_scalability(struct('sizes',[200 1000 10000],'repetitions',1))
if nargin<1,options=struct;end
base=fileparts(mfilename('fullpath'));
o=struct('sizes',200:200:10000,'topologies',{{'Random','Regular','Clustered','Disconnected'}},...
 'targetDegrees',6,'repetitions',3,'seed',20260922,'epsilon',1e-6,...
 'maxSweeps',5000,'timeLimitSeconds',1800,'gapEvery',5,'headerBytes',32,...
 'identifierBytes',4,'scalarBytes',8,'outputDir',fullfile(base,'results'),...
 'visible','off','plotResults',true,'resume',true);
f=fieldnames(options);for i=1:numel(f),assert(isfield(o,f{i}),'Unknown option: %s',f{i});o.(f{i})=options.(f{i});end
assert(all(o.sizes>=200 & mod(o.sizes,200)==0 & o.sizes<=10000),'Sizes must be multiples of 200 in [200,10000].');
assert(all(o.targetDegrees>=2&o.targetDegrees<=8),'Mean degrees must be in [2,8].');
assert(o.repetitions>=1&&fix(o.repetitions)==o.repetitions);
assert(o.gapEvery>=1&&fix(o.gapEvery)==o.gapEvery&&o.epsilon>0);
assert(o.maxSweeps>=0&&fix(o.maxSweeps)==o.maxSweeps&&o.timeLimitSeconds>0);
assert(all(ismember(o.topologies,{'Random','Regular','Clustered','Disconnected'})));
if ~exist(o.outputDir,'dir'),mkdir(o.outputDir);end
records=struct([]);counter=0;
for t=1:numel(o.topologies)
 for d=1:numel(o.targetDegrees)
  for n=o.sizes
   for rep=1:o.repetitions
    name=o.topologies{t};key=sprintf('%s_N%d_D%g_R%d',name,n,o.targetDegrees(d),rep);
    path=fullfile(o.outputDir,[key '.mat']);seed=o.seed+100000*t+10000*d+10*n+rep;
    config=rmfield(o,{'outputDir','visible','plotResults','resume'});
    if o.resume&&exist(path,'file')
     cached=load(path,'record','history','config');
     assert(isequaln(cached.config,config),'Resume settings changed. Use another outputDir or resume=false.');
     record=cached.record;
    else
     state=rng;cleanup=onCleanup(@()rng(state));rng(seed,'twister');
     timer=tic;[p,meta]=scale_network(n,name,o.targetDegrees(d));genSeconds=toc(timer);
     [r,history]=scale_solve(p,o);info=whos('p');
     record=struct('Topology',string(name),'N',n,'TargetDegree',o.targetDegrees(d),...
      'Repetition',rep,'Seed',seed,'MeanDegree',meta.meanDegree,'MaxDegree',meta.maxDegree,...
      'Edges',meta.edges,'DirectedVariables',p.m,'Components',meta.components,...
      'GenerationSeconds',genSeconds,'SolverSeconds',r.seconds,'UpdateSeconds',r.updateSeconds,...
      'GapSeconds',r.gapSeconds,'Sweeps',r.sweeps,'GapChecks',r.checks,...
      'Converged',r.converged,'Status',string(r.status),'MaxRegretUpper',r.maxGap,...
      'SumRegretUpper',r.sumGap,'MeanRegretUpper',r.sumGap/n,'TotalSecurityUtility',r.utility,...
      'FeasibilityViolation',r.violation,'BestResponseCalls',r.brCalls,...
      'CoordinateVisits',r.coordinateVisits,'SortWorkProxy',r.sortWork,...
      'ModelBytes',info.bytes,'AlgorithmArrayBytes',r.arrayBytes,...
      'UpdateMessages',r.updateMessages,'GapMessages',r.gapMessages,...
      'SetupMessages',r.setupMessages,'TotalMessages',r.messages,'EstimatedBytes',r.bytes);
     save(path,'record','history','config','meta');clear cleanup;
    end
    counter=counter+1;
    if counter==1,records=record;else,records(counter)=record;end %#ok<AGROW>
    results=struct2table(records);writetable(results,fullfile(o.outputDir,'scalability_trials.csv'));
    fprintf('%s: %.2fs, %d sweeps, gap %.3g, %s\n',key,record.SolverSeconds,record.Sweeps,record.MaxRegretUpper,record.Status);
   end
  end
 end
end
environment=struct('MATLAB',version,'Computer',computer,'CompletedAt',char(datetime('now')));
save(fullfile(o.outputDir,'scalability_results.mat'),'results','o','environment');
if o.plotResults,scale_plot(results,o);scale_history_plot(o);
 for degree=o.targetDegrees,main_plot_runtime(o.outputDir,degree);end
end
end
