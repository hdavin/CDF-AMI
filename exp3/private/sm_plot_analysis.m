function sm_plot_analysis(a,names,o)
% Publication figures: consistent panels, grayscale-safe styles, vector output.
files={'Fig8_total_security_utility','Fig9_resource_vs_security'};
gray=[.4 .4 .4];
for kind=1:numel(files)
 fig=figure('Visible',o.visible,'Color','w','Position',[80 80 1120 820]);
 layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
 for k=1:4
  r=a.(names{k});ax=nexttile(layout);hold(ax,'on');
  switch kind
   case 1
    h1=scatter(ax,1:o.randomCount,r.randomMetrics(:,1),8,gray,'filled','MarkerFaceAlpha',.55,'DisplayName','RRA');
    h2=yline(ax,r.GRA.totalSecurityBenefit,'-','Color','r','LineWidth',2.5,'DisplayName','GRA');
    h3=yline(ax,r.GURA.totalSecurityBenefit,'-.','Color',[0,0,255]/255,'LineWidth',2.5,'DisplayName','GURA');
    xlabel(ax,'Random allocation trial');ylabel(ax,'Total security utility');
    xlim(ax,[0 o.randomCount]);legendHandles=[h2 h3 h1];
   case 2
    h1=scatter(ax,r.securityLevel,r.GRA.receivedResource,60,'r','filled','MarkerFaceAlpha',.8,'DisplayName','GRA','MarkerEdgeColor',[1,1,1],'LineWidth', 1);
    legendHandles=h1;
    if numel(unique(r.securityLevel))>1
     coefficients=polyfit(r.securityLevel,r.GRA.receivedResource,1);
     xx=linspace(min(r.securityLevel),max(r.securityLevel),100);
     h2=plot(ax,xx,polyval(coefficients,xx),'k--','LineWidth',1.5,'DisplayName','Linear fit');legendHandles=[h1 h2];
    end
    xlabel(ax,'Security level, \xi_i','Interpreter','tex','FontSize',16);ylabel(ax,'Received monitoring resources','FontSize',16);

  end
  set(ax,'FontName','Times New Roman','FontSize',16,'Color','w','XColor','k','YColor','k',...
   'LineWidth',.8,'TickDir','out','Box','on','XGrid','off','YGrid','on',...
   'GridColor',[.5 .5 .5],'GridAlpha',.18,'MinorGridAlpha',.1,'Layer','top');
  limits=ylim(ax);span=max(diff(limits),1);ylim(ax,[limits(1)-.03*span limits(2)+.16*span]);
  label=names{k};if strcmp(label,'Random'),label='Uniformly random';end
  text(ax,.035,.96,sprintf('(%c) %s','a'+k-1,label),'Units','normalized',...
   'VerticalAlignment','top','FontName','Times New Roman','FontSize',16,...
   'FontWeight','normal','Color','k');
 end
 if kind<=2
  lg=legend(legendHandles,'Orientation','horizontal','Box','off','FontName','Times New Roman','FontSize',16);
  lg.Layout.Tile='north';lg.TextColor='k';
 end
 drawnow;
 exportgraphics(fig, fullfile(o.outputDir, [files{kind} '.svg']),'ContentType', 'vector', 'BackgroundColor', 'white');
 exportgraphics(fig,fullfile(o.outputDir,[files{kind} '.pdf']),'ContentType','vector','BackgroundColor','white');
 exportgraphics(fig,fullfile(o.outputDir,[files{kind} '.png']),'Resolution',300,'BackgroundColor','white');
 savefig(fig,fullfile(o.outputDir,[files{kind} '.fig']));
 if strcmpi(o.visible,'off'),close(fig);end
end
end
