function scale_history_plot(o)
fig=figure('Visible',o.visible,'Color','w','Position',[80 80 1100 780]);
tiledlayout(fig,2,2,'TileSpacing','compact');
for t=1:numel(o.topologies)
 ax=nexttile;hold(ax,'on');
 % 从实际配置的节点规模中均匀选取10个
sizes = sort(unique(o.sizes));
idx = round(linspace(1,numel(sizes),min(10,numel(sizes))));
selected = sizes(idx);

% 为10条曲线设置不同颜色
colororder(ax,lines(numel(selected)));
 for n=selected
  path=fullfile(o.outputDir,sprintf('%s_N%d_D%g_R1.mat',o.topologies{t},n,o.targetDegrees(1)));
  z=load(path,'history','record');h=z.history;
  semilogy(ax,h(:,1),max(realmin,h(:,3)),'LineWidth',2,...
    'DisplayName',sprintf('N=%d (%s)',n,z.record.Status));
 end
 set(ax,'YScale','log','FontName','Times New Roman','FontSize',12);
 yline(ax,o.epsilon,'k--','Tolerance','HandleVisibility','off');
 xlabel(ax,'Completed sweeps');ylabel(ax,'Maximum regret upper bound');
 axis([0 450 10^(-8) 10^2]);
 title(ax,o.topologies{t});
 grid(ax,'off');
 set(ax,'XMinorGrid','off','YMinorGrid','off','Color','w');
 legend(ax,'Location','northeast', ...
    'NumColumns',2, ...
    'Interpreter','none', ...
    'FontSize',9);
end
sgtitle('Representative convergence histories: first repetition and first degree setting');
exportgraphics(fig,fullfile(o.outputDir,'fig6_convergence_histories.pdf'),'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(o.outputDir,'fig6_convergence_histories.png'),'Resolution',150,'BackgroundColor','white');
exportgraphics(fig, fullfile(o.outputDir,'fig6_convergence_histories.svg'),'ContentType', 'vector', 'BackgroundColor', 'white');
savefig(fig,fullfile(o.outputDir,'fig6_convergence_histories.fig'));if strcmpi(o.visible,'off'),close(fig);end
end
