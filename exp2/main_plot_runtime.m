function summary=main_plot_runtime(outputDir,targetDegree)
% Plot four network runtimes on one axes, without rerunning the solver.
% main_plot_runtime(fullfile(pwd,'results_extended'))
% main_plot_runtime(fullfile(pwd,'degree_results'),6)
if nargin<1||isempty(outputDir)
 outputDir=fullfile(fileparts(mfilename('fullpath')),'results');
end
csvPath=fullfile(outputDir,'scalability_trials.csv');
matPath=fullfile(outputDir,'scalability_results.mat');
% CSV is updated after every case, so it also supports interrupted studies.
if exist(csvPath,'file'),T=readtable(csvPath,'TextType','string');
elseif exist(matPath,'file'),z=load(matPath,'results');T=z.results;
else,error('No scalability_trials.csv or scalability_results.mat in %s',outputDir);end
if nargin<2||isempty(targetDegree)
 degrees=unique(T.TargetDegree);
 assert(numel(degrees)==1,'Multiple degree settings found. Specify targetDegree as the second argument.');
 targetDegree=degrees(1);
end
T=T(T.TargetDegree==targetDegree,:);assert(~isempty(T),'No results for the requested mean degree.');
if ~islogical(T.Converged)
 if isnumeric(T.Converged),T.Converged=logical(T.Converged);
 else,T.Converged=ismember(lower(string(T.Converged)),["true","1"]);end
end
names={'Random','Regular','Clustered','Disconnected'};
labels={'Uniformly random','Regular','Clustered','Disconnected'};
colors=[0 .447 .741;.85 .325 .098;.466 .674 .188;.494 .184 .556];
markers={'o','s','^','d'};styles={'-','--','-.',':'};
fig=figure('Visible','off','Color','w','Position',[100 100 900 650]);
ax=axes(fig,'Position',[.12 .27 .84 .58]);hold(ax,'on');
summary=table;handles=gobjects(0);legendLabels={};anyFailed=false;
for t=1:4
 r=T(string(T.Topology)==string(names{t}),:);if isempty(r),continue;end
 ns=unique(r.N);mu=zeros(size(ns));sd=mu;failed=false(size(ns));counts=mu;
 for k=1:numel(ns)
  q=r(r.N==ns(k),:);assert(all(isfinite(q.SolverSeconds)),'Nonfinite solver runtime.');
  mu(k)=mean(q.SolverSeconds);sd(k)=std(q.SolverSeconds);counts(k)=height(q);
  failed(k)=any(~q.Converged);anyFailed=anyFailed||failed(k);
  row=table(string(names{t}),targetDegree,ns(k),height(q),mu(k),sd(k),mean(q.Converged),...
   'VariableNames',{'Topology','TargetDegree','N','Runs','MeanSolverSeconds','SDSolverSeconds','ConvergedFraction'});
  summary=[summary;row]; %#ok<AGROW>
 end
 h=plot(ax,ns,mu,'Color',colors(t,:),'LineStyle',styles{t},'Marker',markers{t},...
  'MarkerSize',6,'MarkerFaceColor','w','LineWidth',1.7);
 handles(end+1)=h;legendLabels{end+1}=labels{t}; %#ok<AGROW>
 repeated=counts>1;
 if any(repeated)
  errorbar(ax,ns(repeated),mu(repeated),sd(repeated),'Color',colors(t,:),...
   'LineStyle','none','LineWidth',.8,'CapSize',5,'HandleVisibility','off');
 end
 if any(failed)
  plot(ax,ns(failed),mu(failed),'kx','MarkerSize',10,'LineWidth',1.4,'HandleVisibility','off');
 end
end
xlabel(ax,'Number of SMs, N');ylabel(ax,'Computation time (s)');
set(ax,'FontName','Times New Roman','FontSize',14,'LineWidth',.9,...
 'TickDir','out','Box','on','XGrid','off','YGrid','on','GridAlpha',.15,...
 'XColor','k','YColor','k','Color','w');
ns=unique(T.N);if numel(ns)<=8,xticks(ax,ns);end
xlim(ax,[0 max(T.N)*1.035]);ylim(ax,[0 max(1,max(summary.MeanSolverSeconds+summary.SDSolverSeconds)*1.15)]);
lg=legend(ax,handles,legendLabels,'Location','northoutside','NumColumns',2,...
 'Box','off','FontName','Times New Roman','FontSize',13);lg.TextColor='k';
note=sprintf('Mean degree = %g. Means across repeats; error bars: one standard deviation.',targetDegree);
if all(summary.Runs==1),note=sprintf('Mean degree = %g. One run per configuration; no error bars.',targetDegree);end
if anyFailed,note=sprintf('%s\nBlack crosses: at least one run stopped before reaching the convergence tolerance.',note);end
annotation(fig,'textbox',[.09 .02 .87 .12],'String',note,'EdgeColor','none',...
 'HorizontalAlignment','center','FontName','Times New Roman','FontSize',11,'Color','k','Interpreter','none');
stem=sprintf('fig7_runtime_vs_network_size');
exportgraphics(fig,fullfile(outputDir,[stem '.pdf']),'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(outputDir,[stem '.svg']),'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(outputDir,[stem '.png']),'Resolution',300,'BackgroundColor','white');
print(fig,fullfile(outputDir,[stem '.svg']),'-dsvg');
savefig(fig,fullfile(outputDir,[stem '.fig']));close(fig);
writetable(summary,fullfile(outputDir,[stem '.csv']));
fprintf('Runtime plot saved in %s\n',outputDir);
end
