function te_plot(a,o)
% Two figures per network. Normal: blue diagonal; compromised: red crosshatch.
if ~isfolder(o.outputDir), mkdir(o.outputDir); end
blue = [0 0 1]; red = [1 0 0];

% Hatch settings: spacing/line width are in points, not trustworthiness units.
hatch.spacing = 6;       % Increase for fewer stripes; decrease for denser stripes.
hatch.lineWidth = .65;   % Stripe thickness.
hatch.groupWidth = .8;   % Total width of each group (bin spacing is 1).
hatch.barFraction = .8;  % Filled fraction of each method's slot in the group.
hatch.faceColors = [.72 .84 .96; 1 .68 .67];
hatch.edgeColors = [blue;red];
hatch.patterns = {'/','x'};

nt = numel(o.testRates); nc = min(2,nt); nr = ceil(nt/nc);
labels = cell(1,numel(o.binEdges)-1);
for j = 1:numel(labels)
    closeBracket = ')'; if j==numel(labels), closeBracket = ']'; end
    labels{j} = sprintf('[%.2g, %.2g%s',o.binEdges(j),o.binEdges(j+1),closeBracket);
end
for ni = 1:numel(o.networks)
    name = o.networks{ni}; r = a.(name);
    titleName = name; if strcmp(name,'Random'), titleName = 'Uniformly random'; end
    fig = figure('Visible',o.visible,'Color','w','Position',[80 80 1120 390*nr]);
    layout = tiledlayout(fig,nr,nc,'TileSpacing','compact','Padding','compact');
    % Reserve a header for the patterned legend. No third-party legend utility.
    layout.Units = 'normalized'; layout.OuterPosition = [0 0 1 .90];
    axesList = gobjects(nt,1); bounds = cell(nt,1);
    for ti = 1:nt
        ax = nexttile(layout); hold(ax,'on'); axesList(ti) = ax;
        y = reshape(r.histPercent(:,ti,:),numel(labels),2);
        % Explicit rectangles give exact bar boundaries for clipped hatching.
        bounds{ti} = patternBars(ax,1:numel(labels),y,hatch);
        xticks(ax,1:numel(labels)); xticklabels(ax,labels);
        xlim(ax,[.4 numel(labels)+.6]); ylim(ax,[0 112]); yticks(ax,0:20:100);
        xlabel(ax,'Trustworthiness interval'); ylabel(ax,'Percentage (%)');
        styleAxes(ax); panelLabel(ax,ti,o.testRates(ti));
    end
    title(layout,sprintf('%s network; P_C = %.2g',titleName,o.distributionPC), ...
        'FontName','Times New Roman','FontWeight','normal','FontSize',16,'Interpreter','tex');
    [legendAx,legendBounds] = patternLegend(fig,hatch);
    drawnow; % Finalize axes dimensions before calculating 45-degree stripes.
    for ti = 1:nt
        hatchBars(axesList(ti),bounds{ti},hatch);
    end
    hatchBars(legendAx,legendBounds,hatch);
    te_export(fig,o,['trust_distribution_' name]);

    fig = figure('Visible',o.visible,'Color','w','Position',[80 80 1120 390*nr]);
    layout = tiledlayout(fig,nr,nc,'TileSpacing','compact','Padding','compact');
    for ti = 1:nt
        ax = nexttile(layout); hold(ax,'on');
        y = reshape(r.meanTrust(:,ti,:),numel(o.attackRates),2);
        sd = reshape(r.stdTrust(:,ti,:),numel(o.attackRates),2);
        h = gobjects(2,1);
        h(1) = errorbar(ax,o.attackRates,y(:,1),sd(:,1),'-o', ...
            'Color',blue,'MarkerFaceColor','w','MarkerSize',8,'LineWidth',2,'CapSize',4);
        h(2) = errorbar(ax,o.attackRates,y(:,2),sd(:,2),'-s', ...
            'Color',red,'MarkerFaceColor',red,'MarkerSize',8,'LineWidth',2,'CapSize',4);
        xlim(ax,[0 1]); xticks(ax,0:.2:1);
        lower = min([0;y(:)-sd(:)]); upper = max([1;y(:)+sd(:)]);
        ylim(ax,[lower-.025*(upper-lower),upper+.2*(upper-lower)]);
        xlabel(ax,'Compromised-node proportion, P_C','FontName','Times New Roman','FontSize',16);
        ylabel(ax,'Mean trustworthiness','FontName','Times New Roman','FontSize',16);
        styleAxes(ax); panelLabel(ax,ti,o.testRates(ti));
    end
    lg = legend(h,{'Normal SMs','Compromised SMs'},'Orientation','horizontal', ...
        'Box','off','FontName','Times New Roman','FontSize',16);
    lg.Layout.Tile = 'north';
    title(layout,sprintf('%s network',titleName),'FontName','Times New Roman', ...
        'FontWeight','normal','FontSize',16);
    te_export(fig,o,['mean_trustworthiness_' name]);
end
end

function bounds = patternBars(ax,x,y,s)
% One row per rectangle: [left right bottom top methodIndex].
nMethod = size(y,2); slot = s.groupWidth/nMethod;
width = s.barFraction*slot;
bounds = zeros(numel(x)*nMethod,5); count = 0;
for i = 1:numel(x)
    for j = 1:nMethod
        value = y(i,j);
        if ~isfinite(value) || value==0, continue; end
        center = x(i)+(j-(nMethod+1)/2)*slot;
        rect = [center-width/2 center+width/2 min(0,value) max(0,value) j];
        count = count+1; bounds(count,:) = rect;
        patch(ax,rect([1 2 2 1]),rect([3 3 4 4]),s.faceColors(j,:), ...
            'EdgeColor',s.edgeColors(j,:),'LineWidth',.9,'HandleVisibility','off');
    end
end
bounds = bounds(1:count,:);
end

function [ax,bounds] = patternLegend(fig,s)
% Vector legend: both the bar fill and its hatch pattern are represented.
ax = axes('Parent',fig,'Units','normalized','Position',[.22 .925 .65 .05], ...
    'XLim',[0 1],'YLim',[0 1],'Visible','off','Color','none', ...
    'HandleVisibility','off','HitTest','off');
hold(ax,'on');
left = [.02 .48]; width = .09; bottom = .16; top = .84;
labels = {'Normal SMs','Compromised SMs'};
bounds = zeros(2,5);
for j = 1:2
    bounds(j,:) = [left(j) left(j)+width bottom top j];
    patch(ax,bounds(j,[1 2 2 1]),bounds(j,[3 3 4 4]),s.faceColors(j,:), ...
        'EdgeColor',s.edgeColors(j,:),'LineWidth',.9,'HandleVisibility','off');
    text(ax,left(j)+width+.015,.5,labels{j},'FontName','Times New Roman', ...
        'FontSize',16,'VerticalAlignment','middle','Interpreter','none');
end
end

function hatchBars(ax,bounds,s)
% Clip every segment explicitly to its own bar (axes clipping is insufficient).
p = getpixelposition(ax,true);
sx = p(3)/diff(ax.XLim); sy = p(4)/diff(ax.YLim);
spacingPixels = s.spacing*get(groot,'ScreenPixelsPerInch')/72;
step = spacingPixels*sqrt(2); % Perpendicular distance between adjacent stripes.
for k = 1:size(bounds,1)
    r = bounds(k,:); j = r(5);
    W = (r(2)-r(1))*sx; H = (r(4)-r(3))*sy;
    if W<=0 || H<=0, continue; end
    X = []; Y = [];
    % / lines: y=x+c in local display coordinates.
    for c = (ceil(-W/step):floor(H/step))*step
        x0 = max(0,-c); x1 = min(W,H-c);
        if x1>x0
            X = [X x0 x1 NaN]; Y = [Y x0+c x1+c NaN]; %#ok<AGROW>
        end
    end
    if strcmp(s.patterns{j},'x')
        % Add backslash lines for a crosshatched pattern.
        for c = 0:step:W+H
            x0 = max(0,c-H); x1 = min(W,c);
            if x1>x0
                X = [X x0 x1 NaN]; Y = [Y c-x0 c-x1 NaN]; %#ok<AGROW>
            end
        end
    end
    line(ax,r(1)+X/sx,r(3)+Y/sy,'Color',s.edgeColors(j,:), ...
        'LineWidth',s.lineWidth,'Clipping','on','HandleVisibility','off', ...
        'HitTest','off','Tag','TrustBarHatch');
    % Redraw the outline so stripe ends meet a clean bar boundary.
    line(ax,r([1 2 2 1 1]),r([3 3 4 4 3]),'Color',s.edgeColors(j,:), ...
        'LineWidth',.9,'HandleVisibility','off','HitTest','off');
end
end

function styleAxes(ax)
set(ax,'FontName','Times New Roman','Color','w', ...
    'XColor','k','YColor','k','TickDir','out','Box','on', ...
    'LineWidth',.85,'XGrid','off','YGrid','off','Layer','top');
ax.XAxis.FontSize = 14;
ax.YAxis.FontSize = 14;
ax.XLabel.FontSize = 16;
ax.YLabel.FontSize = 16;
end

function panelLabel(ax,ti,pt)
text(ax,.38,.965,sprintf('(%c) P_T = %.2g','a'+ti-1,pt), ...
    'Units','normalized','VerticalAlignment','top','FontName','Times New Roman', ...
    'FontSize',20,'Interpreter','tex');
end
