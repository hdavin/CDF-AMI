function o = net_options(input,base)
o = struct('networks',{{'Random','Regular','Clustered','Disconnected'}}, ...
    'nodeCount',100,'areaSize',200,'radius',30,'candidateCount',1000, ...
    'seed',20260929,'maxAttempts',10000,'plotResults',true,'visible','on', ...
    'outputDir',fullfile(base,'results'));
assert(isstruct(input) && isscalar(input),'Options must be a scalar struct.');
keys = fieldnames(input);
for k = 1:numel(keys)
    assert(isfield(o,keys{k}),'Unknown option: %s.',keys{k});
    o.(keys{k}) = input.(keys{k});
end
if ischar(o.networks) || isstring(o.networks), o.networks = cellstr(o.networks); end
valid = {'Random','Regular','Clustered','Disconnected'};
assert(iscell(o.networks) && ~isempty(o.networks) && all(ismember(o.networks,valid)), ...
    'networks must contain Random, Regular, Clustered, or Disconnected.');
assert(numel(unique(o.networks))==numel(o.networks),'Duplicate network names.');
validateattributes(o.nodeCount,{'numeric'},{'scalar','integer','finite','>=',2});
for key = {'areaSize','radius'}
    validateattributes(o.(key{1}),{'numeric'},{'real','scalar','positive','finite'});
end
for key = {'candidateCount','maxAttempts'}
    validateattributes(o.(key{1}),{'numeric'},{'scalar','integer','positive','finite'});
end
validateattributes(o.seed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(o.plotResults,{'logical','numeric'},{'scalar','binary'});
o.visible = validatestring(o.visible,{'on','off'});
assert(ischar(o.outputDir) || (isstring(o.outputDir) && isscalar(o.outputDir)), ...
    'outputDir must be a folder path.');
o.outputDir = char(o.outputDir);
assert(~isempty(o.outputDir),'outputDir must not be empty.');
if any(strcmp(o.networks,'Regular'))
    assert(round(sqrt(o.nodeCount))^2==o.nodeCount, ...
        'Regular uses a square grid; nodeCount must be a perfect square.');
end
if any(strcmp(o.networks,'Clustered'))
    assert(o.nodeCount>=10,'Clustered requires at least two nodes per cluster.');
end
if any(strcmp(o.networks,'Disconnected'))
    assert(o.nodeCount>=8,'Disconnected requires at least two nodes per component.');
end
if any(ismember(o.networks,{'Clustered','Disconnected'}))
    assert(o.candidateCount>=o.nodeCount,'candidateCount must be at least nodeCount.');
end
end
