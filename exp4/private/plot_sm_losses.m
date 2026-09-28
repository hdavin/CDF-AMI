function fig=plot_sm_losses(a)
names={'Random','Regular','Clustered','Disconnected'};o=a.options;
fig=figure('Visible',o.visible,'Color','w','Position',[80 80 1120 820]);
layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
gray=[.4 .4 .4];
for k=1:4
 r=a.(names{k});ax=nexttile(layout);hold(ax,'on');t=(1:o.trials)';
 % Show finite values only; underlying MAT/CSV retain any Inf/NaN values.
 v=r.delta(:,3);mask=isfinite(v);h1=scatter(ax,t(mask),v(mask),30,gray,'s','filled');
 v=r.delta(:,2);mask=isfinite(v);h2=scatter(ax,t(mask),v(mask),30,[255,0,0]/255,'o','filled');
 h4=yline(ax,0,'-.','Color',[0,0,255]/255,'LineWidth',4);
 xlabel(ax,'Experiment');ylabel(ax,'\Delta L_A','Interpreter','tex');
 set(ax,'FontName','Times New Roman','FontSize',16,'Color','w','XColor','k','YColor','k',...
 'TickDir','in','Box','on','LineWidth',.8,'YGrid','on','XGrid','off','GridAlpha',.12);
 xlim(ax,[0 o.trials+1]);xticks(ax,unique(round(linspace(1,o.trials,7))));
 values=r.delta(isfinite(r.delta));values=[values;0];lo=min(values);hi=max(values);span=max(hi-lo,1);
 ylim(ax,[lo-.08*span hi+.2*span]);
 name=names{k};if strcmp(name,'Random'),name='Uniformly random';end
 text(ax,.03,.97,sprintf('(%c) %s','a'+k-1,name),'Units','normalized',...
 'VerticalAlignment','top','FontName','Times New Roman','FontSize',16,'Color','k');
end
lg=legend([h1 h2 h4],{'RRA','GRA','GURA'},'Orientation','horizontal','Box','off',...
 'FontName','Times New Roman','FontSize',16);lg.Layout.Tile='north';lg.TextColor='k';
drawnow;
exportgraphics(fig, fullfile(o.outputDir,'Fig10_relative_system_losses.svg'),'ContentType', 'vector', 'BackgroundColor', 'white');exportgraphics(fig,fullfile(o.outputDir,'Fig10_relative_system_losses.pdf'),'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(o.outputDir,'Fig10_relative_system_losses.png'),'Resolution',300,'BackgroundColor','white');
savefig(fig,fullfile(o.outputDir,'Fig10_relative_system_losses.fig'));
if strcmpi(o.visible,'off'),close(fig);end
end
