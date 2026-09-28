function fig = net_plot(datasets,names,outputDir,visible)
% Editable MATLAB objects: red SM nodes, blue communication links, metric axes.
if ~isfolder(outputDir), mkdir(outputDir); end
count = numel(names); columns = min(2,count); rows = ceil(count/columns);
fig = figure('Color','w','Visible',visible,'Position',[80 80 1080 465*rows], ...
    'Name','SM network topologies','NumberTitle','off');
layout = tiledlayout(fig,rows,columns,'TileSpacing','compact','Padding','loose');
for k = 1:count
    net = datasets.(names{k}); ax = nexttile(layout); hold(ax,'on');
    [i,j] = find(triu(net.Adj,1));
    xx = [net.xy(i,1) net.xy(j,1) nan(numel(i),1)]';
    yy = [net.xy(i,2) net.xy(j,2) nan(numel(i),1)]';
    links = plot(ax,xx(:),yy(:),'-','Color',[0 .25 .85],'LineWidth',.65, ...
        'DisplayName','Communication links','HitTest','on','PickableParts','visible');
    nodes = scatter(ax,net.xy(:,1),net.xy(:,2),27,[.88 .08 .08],'filled', ...
        'DisplayName','SMs','HitTest','on','PickableParts','visible');
    axis(ax,'equal'); L = net.metadata.areaSize;
    xlim(ax,[0 L]); ylim(ax,[0 L]); xticks(ax,linspace(0,L,5)); yticks(ax,linspace(0,L,5));
    set(ax,'FontName','Times New Roman','FontSize',13,'Box','on','TickDir','out', ...
        'LineWidth',.8,'XColor','k','YColor','k','Color','w','XGrid','off','YGrid','off');
    xlabel(ax,'x-coordinate (m)','FontName','Times New Roman','FontSize',15);
    ylabel(ax,'y-coordinate (m)','FontName','Times New Roman','FontSize',15);
    label = names{k}; if strcmp(label,'Random'), label = 'Uniformly random'; end
    title(ax,sprintf('(%c) %s network','a'+k-1,label), ...
        'FontName','Times New Roman','FontSize',16,'FontWeight','normal','Color','k');
end
lg = legend([nodes links],{'SMs','Communication links'},'Orientation','horizontal', ...
    'FontName','Times New Roman','FontSize',14,'Box','off');
lg.Layout.Tile = 'north'; lg.AutoUpdate = 'off'; lg.TextColor = 'k';
drawnow;
stem = fullfile(outputDir,'network_topologies');
exportgraphics(fig,[stem '.pdf'],'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,[stem '.png'],'Resolution',300,'BackgroundColor','white');
try
    exportgraphics(fig,[stem '.svg'],'ContentType','vector','BackgroundColor','white');
catch
    print(fig,[stem '.svg'],'-dsvg');
end
% Store a visible, editable FIG even when generation was run with visible='off'.
set(fig,'Visible','on'); drawnow;
savefig(fig,[stem '.fig']);
if strcmpi(visible,'off'), close(fig); end
end
