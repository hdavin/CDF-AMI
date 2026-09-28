function results = te_run(o)
if ~isfolder(o.outputDir), mkdir(o.outputDir); end
cacheDir = fullfile(o.outputDir,'cache');
if ~isfolder(cacheDir), mkdir(cacheDir); end
oldRng = rng; cleanup = onCleanup(@() rng(oldRng)); %#ok<NASGU>
core = struct('version','uploaded_trust_v1','rounds',o.rounds, ...
    'maliciousProbability',o.maliciousProbability,'punishment',o.punishment, ...
    'resource',o.resource,'epsilon',o.epsilon,'seed',o.seed, ...
    'trustSource',te_hash(fileread(fullfile(fileparts(mfilename('fullpath')),'te_trustworthiness.m'))));
results = struct('version','exp1-2_v1','options',o, ...
    'generatedAt',datestr(now,30),'groupOrder',{{'Normal','Compromised'}}, ...
    'computedPoints',0,'cachedPoints',0);
for ni = 1:numel(o.networks)
    name = o.networks{ni}; net = te_load_network(name,o);
    np = numel(o.attackRates); nt = numel(o.testRates); nb = numel(o.binEdges)-1;
    r = struct('network',net,'meanTrust',zeros(np,nt,2), ...
        'stdTrust',zeros(np,nt,2),'trialMeans',zeros(o.repetitions,np,nt,2), ...
        'histCounts',zeros(nb,nt,2),'histPercent',zeros(nb,nt,2), ...
        'distributionObservations',zeros(nt,2),'pointSeeds',zeros(np,nt));
    for ti = 1:nt
        for pi = 1:np
            config = core;
            config.network = name; config.adjacency = te_hash(net.Adj);
            config.PT = o.testRates(ti); config.PC = o.attackRates(pi);
            seedHash = te_hash(config);
            pointSeed = hex2dec(seedHash(1:8));
            config.repetitions = o.repetitions; config.binEdges = o.binEdges;
            key = te_hash(config);
            path = fullfile(cacheDir,[name '_' key '.mat']);
            if o.resume && isfile(path)
                z = load(path,'trial','config');
                assert(isequaln(z.config,config),'Corrupt or incompatible cache: %s.',path);
                trial = z.trial; results.cachedPoints = results.cachedPoints+1;
            else
                rng(pointSeed,'twister');
                trial = runPoint(net,o,config.PT,config.PC);
                % Commit each completed parameter point separately.
                tempPath = [tempname(cacheDir) '.mat'];
                save(tempPath,'trial','config','-v7'); movefile(tempPath,path,'f');
                results.computedPoints = results.computedPoints+1;
            end
            r.meanTrust(pi,ti,:) = reshape(mean(trial.means,1),1,1,2);
            r.stdTrust(pi,ti,:) = reshape(std(trial.means,0,1),1,1,2);
            r.trialMeans(:,pi,ti,:) = reshape(trial.means,o.repetitions,1,1,2);
            r.pointSeeds(pi,ti) = pointSeed;
            if abs(config.PC-o.distributionPC)<1e-12
                r.histCounts(:,ti,:) = reshape(trial.histCounts,nb,1,2);
                r.histPercent(:,ti,:) = reshape(100*trial.histCounts./sum(trial.histCounts,1),nb,1,2);
                r.distributionObservations(ti,:) = sum(trial.histCounts,1);
            end
            fprintf('%s | P_T=%.2g, P_C=%.2g | %d trials complete\n',name,config.PT,config.PC,o.repetitions);
        end
    end
    results.(name) = r;
end
save(fullfile(o.outputDir,'analysis_results.mat'),'results','-v7');
te_write_tables(results,o);
fprintf('Saved to %s (%d new / %d cached parameter points).\n', ...
    o.outputDir,results.computedPoints,results.cachedPoints);
end

function trial = runPoint(net,o,pt,pc)
n = net.N; a = net.Adj; nAttack = floor(pc*n);
trial = struct('means',zeros(o.repetitions,2), ...
    'histCounts',zeros(numel(o.binEdges)-1,2));
for rep = 1:o.repetitions
    order = randperm(n); attack = sort(order(1:nAttack));
    normal = setdiff(1:n,attack);
    T = te_trustworthiness(a,pt,attack,o);
    assert(all(isfinite(T(:))) && all(T(:)>=0 & T(:)<=1),'Invalid trust scores.');
    columns = {normal,attack};
    for group = 1:2
        values = T(:,columns{group}); mask = a(:,columns{group})>0;
        values = values(mask); % Original edge-weighted scores; all evaluators.
        trial.means(rep,group) = mean(values);
        trial.histCounts(:,group) = trial.histCounts(:,group)+histcounts(values,o.binEdges)';
    end
end
end
