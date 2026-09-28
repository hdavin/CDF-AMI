function o=s6_options(input,kind)
base=fileparts(fileparts(mfilename('fullpath')));
o=struct('topologies',{{'Random','Regular','Clustered','Disconnected'}},...
 'repetitions',20,'seed',20260924,'rho',[.25 .5 .75 1 1.5 2],...
 'meanDegrees',4:13,'penalties',[1.1 2 3 5 10 20],...
 'testRates',[.1 .5],'attackRate',.1,'trustAttackRate',.5,...
 'K',20,'maliciousProbability',.1,'normalErrorRate',0,...
 'trustMode','neighbor','w1',.4,'w2',.6,...
 'kappa',100,'trials',200,'epsilon',1e-6,'maxSweeps',5000,'gapEvery',5,...
 'bestResponseSolver','fmincon','globalTolerance',1e-5,'globalMaxIterations',20000,...
 'dataDir',fullfile(base,'data'),'outputDir',fullfile(base,'results',kind),...
 'visible','off','plotResults',true,'resume',true);
if strcmp(kind,'penalty')
 o.testRates=[.1 .3 .5 .7];
 % Separate cache from the earlier two-PT experiment; retain all other settings.
 o.outputDir=fullfile(base,'results','penalty_PT4');
end
if strcmp(kind,'capacity')
 o=rmfield(o,'rho');
 o.capacities=10:10:100;
 o.outputDir=fullfile(base,'results','capacity_absolute');
 assert(~isfield(input,'rho'),'Capacity now uses absolute per-node values: use capacities, not rho.');
end
f=fieldnames(input);for k=1:numel(f),assert(isfield(o,f{k}),'Unknown option %s',f{k});o.(f{k})=input.(f{k});end
if strcmp(kind,'capacity')
 assert(isvector(o.capacities)&&~isempty(o.capacities)&&all(isfinite(o.capacities)&o.capacities>0),...
  'capacities must contain positive finite per-node resource capacities.');
 o.capacities=o.capacities(:)';
else
 assert(all(o.rho>0));
end
assert(isnumeric(o.meanDegrees)&&isreal(o.meanDegrees)&&isvector(o.meanDegrees)&&...
 ~isempty(o.meanDegrees)&&all(isfinite(o.meanDegrees)&o.meanDegrees>=2&...
 o.meanDegrees==fix(o.meanDegrees)),...
 'meanDegrees must contain finite integers >= 2; odd values are supported.');
assert(all(o.penalties>1));
assert(o.repetitions>=1&&fix(o.repetitions)==o.repetitions&&o.trials>=1&&fix(o.trials)==o.trials);
assert(o.K>=1&&fix(o.K)==o.K&&o.epsilon>0&&o.globalTolerance>0);
assert(o.gapEvery>=1&&fix(o.gapEvery)==o.gapEvery&&o.maxSweeps>=1);
assert(all(o.testRates>=0&o.testRates<=1)&&o.attackRate>0&&o.attackRate<1);
assert(o.trustAttackRate>0&&o.trustAttackRate<1);
assert(any(strcmp(o.trustMode,{'neighbor','legacy'})));
assert(o.w1>=0&&o.w2>=0&&o.w1+o.w2>0&&o.kappa>0);
assert(o.maliciousProbability>=0&&o.maliciousProbability<=1&&o.normalErrorRate>=0&&o.normalErrorRate<=1);
assert(any(strcmp(o.bestResponseSolver,{'fmincon','analytic'})));
if ~exist(o.outputDir,'dir'),mkdir(o.outputDir);end
end
