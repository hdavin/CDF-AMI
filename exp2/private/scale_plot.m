function scale_plot(T,o)
fig=figure('Visible',o.visible,'Color','w','Position',[60 60 1400 860]);
tiledlayout(fig,2,3,'TileSpacing','compact','Padding','compact');
fields={'SolverSeconds','Sweeps','MaxRegretUpper','EstimatedBytes','ModelBytes','Converged'};
ylabels={'Time until termination (s)','Completed sweeps','Maximum regret upper bound','Modeled communication (MiB)','Model storage (MiB)','Converged fraction'};
colors=lines(numel(o.topologies));summary=table;
for panel=1:6
 ax=nexttile;hold(ax,'on');
 for t=1:numel(o.topologies)
  for d=o.targetDegrees
   base=T(T.Topology==string(o.topologies{t}) & T.TargetDegree==d,:);ns=unique(base.N);vals=zeros(size(ns));fails=false(size(ns));
   for k=1:numel(ns)
    r=base(base.N==ns(k),:);v=r.(fields{panel});
    if panel==6,vals(k)=mean(v);else,vals(k)=median(v);end
    fails(k)=any(~r.Converged);
    if panel==1
     ok=r.Converged;convtime=NaN;if any(ok),convtime=median(r.SolverSeconds(ok));end
     row=table(string(o.topologies{t}),d,ns(k),height(r),mean(ok),median(r.SolverSeconds),std(r.SolverSeconds),convtime,median(r.Sweeps),median(r.EstimatedBytes),...
      'VariableNames',{'Topology','TargetDegree','N','Runs','ConvergedFraction','MedianTerminationSeconds','SDTerminationSeconds','MedianConvergedSeconds','MedianSweeps','MedianModeledBytes'});
     summary=[summary;row]; %#ok<AGROW>
    end
   end
   if panel==4||panel==5,vals=vals/2^20;end
   plot(ax,ns,vals,'-o','Color',colors(t,:),'MarkerSize',3,'LineWidth',1.1,...
    'DisplayName',sprintf('%s, degree %g',o.topologies{t},d));
   if panel<6&&any(fails),plot(ax,ns(fails),vals(fails),'rx','MarkerSize',8,'LineWidth',1.4,'HandleVisibility','off');end
  end
 end
 xlabel(ax,'Number of SMs');ylabel(ax,ylabels{panel});grid(ax,'on');
 set(ax,'FontName','Times New Roman','FontSize',12,'Color','w','XColor','k','YColor','k');
 if panel==3,set(ax,'YScale','log');yline(ax,o.epsilon,'k--','Tolerance','HandleVisibility','off');end
 if panel==6,ylim(ax,[-.05 1.05]);end
 if panel==1,legend(ax,'Location','best','FontSize',9);end
end
sgtitle('Cyclic best response: medians across repeats; red crosses indicate incomplete convergence','FontSize',13);
exportgraphics(fig,fullfile(o.outputDir,'scalability_overview.pdf'),'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,fullfile(o.outputDir,'scalability_overview.png'),'Resolution',200,'BackgroundColor','white');
savefig(fig,fullfile(o.outputDir,'scalability_overview.fig'));if strcmpi(o.visible,'off'),close(fig);end
writetable(summary,fullfile(o.outputDir,'scalability_summary.csv'));
end
