function o = te_options(input,base)
% All paths are independent of the MATLAB current folder.
o = struct('networks',{{'Random'}},'testRates',[.3 .5 .7 .9], ...
    'attackRates',.05:.05:.95,'distributionPC',.5,'repetitions',1000, ...
    'rounds',20,'radius',30,'maliciousProbability',.1,'punishment',10, ...
    'resource',1,'epsilon',1e-10,'seed',20260924,'binEdges',0:.2:1, ...
    'dataDir',fullfile(base,'data'),'outputDir',fullfile(base,'results'), ...
    'resume',true,'plotResults',true,'visible','off', ...
    'formats',{{'pdf','svg','png','fig'}});
assert(isstruct(input) && isscalar(input),'Options must be a scalar struct.');
keys = fieldnames(input);
for k = 1:numel(keys)
    assert(isfield(o,keys{k}),'Unknown option: %s.',keys{k});
    o.(keys{k}) = input.(keys{k});
end
if ischar(o.networks) || isstring(o.networks), o.networks = cellstr(o.networks); end
valid = {'Random','Regular','Clustered','Disconnected'};
assert(~isempty(o.networks) && all(ismember(o.networks,valid)), ...
    'networks must contain Random, Regular, Clustered, or Disconnected.');
assert(numel(unique(o.networks)) == numel(o.networks),'Duplicate network names.');
validateattributes(o.testRates,{'numeric'},{'vector','nonempty','finite','>=',0,'<=',1});
validateattributes(o.attackRates,{'numeric'},{'vector','nonempty','finite','>',0,'<',1});
o.testRates = o.testRates(:)'; o.attackRates = o.attackRates(:)';
assert(all(diff(o.testRates)>0) && all(diff(o.attackRates)>0),'Rates must increase strictly.');
validateattributes(o.distributionPC,{'numeric'},{'scalar','finite','>',0,'<',1});
assert(any(abs(o.attackRates-o.distributionPC)<1e-12), ...
    'attackRates must include distributionPC (default 0.5).');
for key = {'repetitions','rounds'}
    validateattributes(o.(key{1}),{'numeric'},{'scalar','integer','positive','finite'});
end
for key = {'radius','punishment','resource','epsilon'}
    validateattributes(o.(key{1}),{'numeric'},{'scalar','positive','finite'});
end
validateattributes(o.maliciousProbability,{'numeric'},{'scalar','finite','>=',0,'<=',1});
validateattributes(o.seed,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(o.binEdges,{'numeric'},{'vector','finite','nonempty'});
o.binEdges = o.binEdges(:)';
assert(o.binEdges(1)==0 && o.binEdges(end)==1 && all(diff(o.binEdges)>0), ...
    'binEdges must increase strictly from 0 to 1.');
for key = {'resume','plotResults'}
    validateattributes(o.(key{1}),{'logical','numeric'},{'scalar','binary'});
end
o.visible = validatestring(o.visible,{'on','off'});
if ischar(o.formats) || isstring(o.formats), o.formats = cellstr(o.formats); end
assert(~isempty(o.formats) && all(ismember(o.formats,{'pdf','svg','png','fig'})), ...
    'formats may contain pdf, svg, png, and fig.');
o.dataDir = char(o.dataDir); o.outputDir = char(o.outputDir);
assert(isfolder(o.dataDir),'Data folder does not exist: %s.',o.dataDir);
end
