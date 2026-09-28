function summary = s6_plot(T,o,kind)
% One axes per metric; topology identifies each GRA curve.
% GURA/RRA remain in the saved tables, but are not plotted.
% Plot means only; standard deviations remain available in summary.csv.
names=cellstr(string(o.topologies));
cols=[0 .447 .741; .85 .325 .098; .466 .674 .188; .494 .184 .556];
markers={'o','s','^','d'}; styles={'-','--','-.',':'};
isPenalty=strcmp(kind,'penalty');
if isPenalty
    fields={'TrustSeparation','RankingAUC'};
    ylabs={'Mean trust separation','Trust-ranking AUC'};
    param='Penalty'; required={'Topology','Penalty','TestRate',fields{:}};
elseif any(strcmp(kind,{'capacity','density'}))
    fields={'Utility','Loss'};
    ylabs={'Total security utility','System loss, L_A'};
    param='Parameter'; required={'Topology','Method','Parameter','Converged',fields{:}};
else
    error('Unknown experiment kind: %s.',kind);
end
assert(istable(T)&&~isempty(T),'The input must be a nonempty trial table.');
assert(all(ismember(required,T.Properties.VariableNames)),'Required result columns are missing.');
if ~isfolder(o.outputDir), mkdir(o.outputDir); end

% Preserve statistics for all methods, including nonfinite observations.
summary=table;
for f=1:numel(fields)
    for t=1:numel(names)
        r=T(string(T.Topology)==string(names{t}),:);
        if isPenalty, groups=o.testRates; else, groups=1:3; end
        for j=1:numel(groups)
            if isPenalty
                q=r(r.TestRate==groups(j),:);
                label=sprintf('P_T = %.2g',groups(j));
            else
                methods={'GURA','GRA','RRA'};
                q=r(string(r.Method)==string(methods{j}),:); label=methods{j};
            end
            values=unique(q.(param));
            for k=1:numel(values)
                v=q(q.(param)==values(k),:); raw=v.(fields{f});
                fail=false; if ~isPenalty, fail=any(~v.Converged); end
                row=table(string(names{t}),string(label),string(fields{f}),values(k), ...
                    height(v),mean(raw),std(raw),sum(isinf(raw)),sum(isnan(raw)),fail, ...
                    'VariableNames',{'Topology','Series','Metric','Parameter','Runs', ...
                    'Mean','SD','InfiniteRuns','MissingRuns','SolverFailure'});
                summary=[summary;row]; %#ok<AGROW>
            end
        end
    end
end
assert(~isempty(summary),'No data match the selected topologies and parameter groups.');
writetable(summary,fullfile(o.outputDir,'summary.csv'));

if isPenalty
    plotPenaltyPanels(summary,o,names,fields,ylabs,cols,markers,styles);
    return;
end

for f=1:numel(fields)
    fig=figure('Visible',o.visible,'Color','w','Position',[80 80 960 680]);
    ax=axes('Parent',fig); hold(ax,'on');
    h=gobjects(0); labels={}; plottedParameters=[];
    for t=1:numel(names)
        r=summary(summary.Topology==string(names{t}) & summary.Metric==string(fields{f}),:);
        name=names{t}; if strcmp(name,'Random'), name='Uniformly random'; end
        c=1+mod(t-1,size(cols,1));
        if isPenalty, groups=o.testRates; else, groups=1; end
        for j=1:numel(groups)
            if isPenalty
                series=sprintf('P_T = %.2g',groups(j));
                q=r(r.Series==string(series),:);
                label=sprintf('%s, %s',name,series);
                lineStyle=styles{1+mod(j-1,numel(styles))};
            else
                % Only GRA is drawn; one curve for each of the four networks.
                q=r(r.Series=="GRA",:); label=name;
                lineStyle=styles{1+mod(t-1,numel(styles))};
            end
            if isempty(q)
                warning('EXP6:MissingSeries','No data for %s (%s).',name,fields{f});
                continue;
            end
            q=sortrows(q,'Parameter'); values=q.Parameter;
            mu=q.Mean;
            % Leave nonfinite results as gaps, never compute finite-only means.
            mu(~isfinite(mu))=NaN;
            h(end+1)=plot(ax,values,mu, ...
                'LineStyle',lineStyle,'Marker',markers{1+mod(t-1,numel(markers))}, ...
                'Color',cols(c,:),'LineWidth',1.6,'MarkerSize',7, ...
                'MarkerFaceColor','w'); %#ok<AGROW>
            labels{end+1}=label; %#ok<AGROW>
            plottedParameters=[plottedParameters;values]; %#ok<AGROW>
            fail=q.SolverFailure;
            if any(fail)
                plot(ax,values(fail),mu(fail),'kx','LineWidth',1.5, ...
                    'MarkerSize',10,'HandleVisibility','off');
            end
        end
    end
    if isPenalty
        xlabel(ax,'Penalty factor, w','Interpreter','tex');
    elseif strcmp(kind,'density')
        xlabel(ax,'Mean degree','Interpreter','tex');
    elseif isfield(o,'capacities')
        xlabel(ax,'Resource capacity, C','Interpreter','tex');
    else
        xlabel(ax,'Capacity multiplier, \rho','Interpreter','tex');
    end
    values=unique(plottedParameters);
    if numel(values)>12
        values=values(unique(round(linspace(1,numel(values),7))));
    end
    if ~isempty(values), xticks(ax,values); end
    ylabel(ax,ylabs{f},'Interpreter','tex');
    set(ax,'FontName','Times New Roman','FontSize',14,'Box','on', ...
        'TickDir','out','Color','w','XColor','k','YColor','k','LineWidth',.9);
    ax.XLabel.FontSize=16; ax.YLabel.FontSize=16;
    grid(ax,'off');
    if strcmp(fields{f},'RankingAUC')
        ylim(ax,[0 1]); yline(ax,.5,'k:','HandleVisibility','off');
    end
    if ~isempty(h)
        legend(ax,h,labels,'Location','northoutside','NumColumns',2, ...
            'Box','off','TextColor','k','FontName','Times New Roman','FontSize',14, ...
            'Interpreter','tex');
    end
    stem=[kind '_' fields{f}]; drawnow;
    exportgraphics(fig,fullfile(o.outputDir,[stem '.pdf']),'ContentType','vector','BackgroundColor','white');
    exportgraphics(fig,fullfile(o.outputDir,[stem '.png']),'Resolution',300,'BackgroundColor','white');
    set(fig,'PaperPositionMode','auto');
    print(fig,fullfile(o.outputDir,[stem '.svg']),'-dsvg','-painters');
    saveVisibleFigure(fig,fullfile(o.outputDir,[stem '.fig']));
    if strcmpi(o.visible,'off'), close(fig); end
end
if any(summary.InfiniteRuns>0)
    warning('EXP6:InfiniteLoss', ...
        'Some losses are infinite; summary.csv retains them for all methods. Nonfinite plotted means are gaps.');
end
if any(summary.SolverFailure)
    warning('EXP6:Unconverged', ...
        'summary.csv records optimizer failures for all methods; black crosses mark failures on plotted GRA series.');
end
end

function plotPenaltyPanels(summary,o,names,fields,ylabs,cols,markers,styles)
% Double-column publication layout. This helper changes presentation only.
% All six sampled penalties are drawn at their original linear-axis positions.
testRates=o.testRates(:)';
nc=min(2,numel(testRates)); nr=ceil(numel(testRates)/nc);
fontName='Times New Roman';
tickFont=9; labelFont=10.5; panelFont=10.5; legendFont=9.5;
lineWidth=1.15; markerSize=4.6;
for f=1:numel(fields)
    fig=figure('Visible',o.visible,'Color','w','Units','centimeters', ...
        'Position',[2 2 18 6.4*nr+1.2],'InvertHardcopy','off');
    layout=tiledlayout(fig,nr,nc,'TileSpacing','compact','Padding','compact');
    metric=summary(summary.Metric==string(fields{f}),:);
    finiteMean=metric.Mean(isfinite(metric.Mean));
    if isempty(finiteMean), commonY=[0 1];
    elseif strcmp(fields{f},'RankingAUC'), commonY=[0 1.13];
    else
        lo=min(finiteMean); hi=max(finiteMean); span=max(hi-lo,.05);
        commonY=[lo-.08*span hi+.22*span];
    end
    for p=1:numel(testRates)
        ax=nexttile(layout); hold(ax,'on');
        h=gobjects(0); labels={}; allValues=[];
        series=sprintf('P_T = %.2g',testRates(p));
        for t=1:numel(names)
            q=metric(metric.Topology==string(names{t}) & metric.Series==string(series),:);
            assert(~isempty(q), ...
                'Missing %s data for %s. Run main_penalty_sensitivity before plotting.',series,names{t});
            q=sortrows(q,'Parameter'); values=q.Parameter; mu=q.Mean;
            mu(~isfinite(mu))=NaN;
            c=1+mod(t-1,size(cols,1));
            h(end+1)=plot(ax,values,mu, ...
                'LineStyle',styles{1+mod(t-1,numel(styles))}, ...
                'Marker',markers{1+mod(t-1,numel(markers))}, ...
                'Color',cols(c,:),'LineWidth',lineWidth,'MarkerSize',markerSize, ...
                'MarkerFaceColor','w','MarkerEdgeColor',cols(c,:)); %#ok<AGROW>
            label=names{t}; if strcmp(label,'Random'), label='Uniformly random'; end
            labels{end+1}=label; allValues=[allValues;values]; %#ok<AGROW>
        end
        values=unique(allValues);
        % Representative ticks avoid crowding at w=1.1, 2, 3; every sample
        % remains present as a marker, with no interpolation or x offset.
        if isequal(values(:),[1.1;2;3;5;10;20])
            xticks(ax,[1.1 5 10 15 20]);
        else
            xticks(ax,values);
        end
        if numel(values)>1
            pad=.035*(max(values)-min(values));
            xlim(ax,[min(values)-pad max(values)+pad]);
        end
        ylim(ax,commonY);
        if strcmp(fields{f},'RankingAUC')
            yticks(ax,0:.2:1);
            yline(ax,.5,':','Color',[.45 .45 .45],'LineWidth',.65, ...
                'HandleVisibility','off');
        end
        set(ax,'FontName',fontName,'FontUnits','points','FontSize',tickFont, ...
            'Box','on','TickDir','out','TickLength',[.014 .014], ...
            'Color','w','XColor','k','YColor','k','LineWidth',.7, ...
            'XMinorTick','off','YMinorTick','off','Layer','top');
        grid(ax,'off');
        text(ax,.5,.97,sprintf('(%c)  {\\it P}_{T} = %.2g','a'+p-1,testRates(p)), ...
            'Units','normalized','HorizontalAlignment','center','VerticalAlignment','top', ...
            'FontName',fontName,'FontSize',panelFont,'Interpreter','tex','Color','k');
    end
    xlabel(layout,'Punishment coefficient, {\it w}', ...
        'FontName',fontName,'FontSize',labelFont,'Color','k','Interpreter','tex');
    ylabel(layout,ylabs{f},'FontName',fontName,'FontSize',labelFont, ...
        'Color','k','Interpreter','tex');
    lg=legend(h,labels,'Orientation','horizontal','NumColumns',4, ...
        'Box','off','TextColor','k','FontName',fontName,'FontSize',legendFont, ...
        'Interpreter','none');
    lg.Layout.Tile='north';
    stem=['penalty_' fields{f}]; drawnow;
    exportgraphics(fig,fullfile(o.outputDir,[stem '.pdf']),'ContentType','vector','BackgroundColor','white');
    exportgraphics(fig,fullfile(o.outputDir,[stem '.png']),'Resolution',300,'BackgroundColor','white');
    set(fig,'PaperPositionMode','auto');
    print(fig,fullfile(o.outputDir,[stem '.svg']),'-dsvg','-painters');
    saveVisibleFigure(fig,fullfile(o.outputDir,[stem '.fig']));
    if strcmpi(o.visible,'off'), close(fig); end
end
end

function saveVisibleFigure(fig,filename)
% A hidden batch figure must reopen visibly when its FIG file is opened.
% Restore the live figure's previous visibility after saving (also on error).
previousVisibility=fig.Visible;
restoreVisibility=onCleanup(@()set(fig,'Visible',previousVisibility)); %#ok<NASGU>
% Batch/export sessions can otherwise save MenuBar='none', hiding editing tools.
set(fig,'MenuBar','figure','ToolBar','figure','WindowStyle','normal');
fig.Visible='on';
savefig(fig,filename);
end
