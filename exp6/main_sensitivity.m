function results=main_sensitivity(options)
if nargin<1,options=struct;end
base=fileparts(mfilename('fullpath'));
if isfield(options,'outputDir'),root=options.outputDir;else,root=fullfile(base,'results');end
for kind={'capacity','penalty','density'}
    o=options;o.outputDir=fullfile(root,kind{1});
    if strcmp(kind{1},'capacity')
        o.outputDir=fullfile(root,'capacity_absolute');
    elseif isfield(o,'capacities')
        o=rmfield(o,'capacities');
    end
    if strcmp(kind{1},'penalty')
        o.outputDir=fullfile(root,'penalty');
    end
    if strcmp(kind{1},'density'),results.density=s6_run_density(o);
    else,results.(kind{1})=s6_run(kind{1},o);end
end
end
