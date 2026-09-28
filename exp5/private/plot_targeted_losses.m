function plot_targeted_losses(a)
% Vector hatching without third-party packages. Pattern and color encode method.
names={'Random','Regular','Clustered','Disconnected'};o=a.options;
files={'Fig11_security_level_attacks','Fig12_trust_attacks','Fig13_degree_attacks'};
colors=[0 .28 .72;.78 .08 .12;.12 .12 .12];
patterns={'diagonal','cross','horizontal'};
for type=1:3
 fig=figure('Visible',o.visible,'Color','w','Position',[80 80 1120 820]);
 layout=tiledlayout(fig,2,2,'TileSpacing','compact','Padding','compact');
 layout.OuterPosition=[0 0 1 .93];
 axs=gobjects(4,1);
 for k=1:4
  ax=nexttile(layout);axs(k)=ax;hold(ax,'on');
  y=a.(names{k}).losses(:,:,type);v=y(isfinite(y));if isempty(v),v=0;end
  xlabel(ax,'P_C','Interpreter','tex');ylabel(ax,'L_A','Interpreter','tex');
  xticks(ax,1:numel(o.attackRates));xticklabels(ax,arrayfun(@(v)sprintf('%.2g',v),o.attackRates,'UniformOutput',false));
  xlim(ax,[.5 numel(o.attackRates)+.5]);ylim(ax,[0 max(1,max(v)*1.2)]);
  set(ax,'FontName','Times New Roman','FontSize',13,'Color','w','XColor','k','YColor','k',...
   'TickDir','out','Box','on','LineWidth',.8,'XGrid','off','YGrid','on','GridAlpha',.10,'Layer','bottom');
  name=names{k};if strcmp(name,'Random'),name='Uniformly random';end
  text(ax,.03,.97,sprintf('(%c) %s','a'+k-1,name),'Units','normalized',...
   'VerticalAlignment','top','FontName','Times New Roman','FontSize',14,'Color','k');
 end
 % A dedicated top legend uses actual hatched vector rectangles, rather than
 % empty proxy bar handles that cannot show the overlaid hatch lines.
 lg=axes('Parent',fig,'Position',[.25 .945 .52 .04],'Visible','off',...
  'XLim',[0 1],'YLim',[0 1]);hold(lg,'on');
 drawnow;
 for k=1:4
  ax=axs(k);y=a.(names{k}).losses(:,:,type);
  for j=1:3
   for n=1:size(y,1)
    if ~isfinite(y(n,j))||y(n,j)<=0,continue;end
    center=n+(j-2)*.26;width=.18;
    hatched_rect(ax,center-width/2,center+width/2,0,y(n,j),patterns{j},colors(j,:),7,.7);
   end
  end
 end
 labels={'GURA','GRA','RRA'};
 for j=1:3
  x=(j-1)/3;
  hatched_rect(lg,x,x+.095,.3,.7,patterns{j},colors(j,:),5,.75);
  text(lg,x+.115,.5,labels{j},'VerticalAlignment','middle',...
   'FontName','Times New Roman','FontSize',14,'Color','k');
 end
 drawnow;pause(.3);drawnow;
 exportgraphics(fig,fullfile(o.outputDir,[files{type} '.svg']),'ContentType','vector','BackgroundColor','white');
 exportgraphics(fig,fullfile(o.outputDir,[files{type} '.pdf']),'ContentType','vector','BackgroundColor','white');
 exportgraphics(fig,fullfile(o.outputDir,[files{type} '.png']),'Resolution',300,'BackgroundColor','white');
 savefig(fig,fullfile(o.outputDir,[files{type} '.fig']));
 if strcmpi(o.visible,'off'),close(fig);end
end
end

function hatched_rect(ax,x0,x1,y0,y1,pattern,color,spacing,lw)
% Construct clipped lines in display coordinates for consistent spacing/angles
% across panels with different data ranges. All exported marks remain vectors.
patch(ax,[x0 x1 x1 x0],[y0 y0 y1 y1],'w','EdgeColor','none','HandleVisibility','off');
pix=getpixelposition(ax,true);xl=xlim(ax);yl=ylim(ax);
sx=pix(3)/diff(xl);sy=pix(4)/diff(yl);W=(x1-x0)*sx;H=(y1-y0)*sy;
xx=[];yy=[];
if strcmp(pattern,'horizontal')
 for c=spacing/2:spacing:H
  xx=[xx 0 W NaN];yy=[yy c c NaN]; %#ok<AGROW>
 end
else
 slopes=1;if strcmp(pattern,'cross'),slopes=[1 -1];end
 for slope=slopes
  if slope==1,cs=-W:spacing*sqrt(2):H;else,cs=0:spacing*sqrt(2):H+W;end
  for c=cs
   % y=slope*x+c, clipped analytically to rectangle [0,W] x [0,H].
   if slope==1,lo=max(0,-c);hi=min(W,H-c);
   else,lo=max(0,c-H);hi=min(W,c);end
   if hi>lo
    xx=[xx lo hi NaN];yy=[yy slope*lo+c slope*hi+c NaN]; %#ok<AGROW>
   end
  end
 end
end
if ~isempty(xx)
 line(ax,x0+xx/sx,y0+yy/sy,'Color',color,'LineWidth',lw,'Clipping','on','HandleVisibility','off');
end
% Draw the border last so every bar has an uninterrupted outline.
line(ax,[x0 x1 x1 x0 x0],[y0 y0 y1 y1 y0],'Color',[.12 .12 .12],...
 'LineWidth',.8,'HandleVisibility','off');
end
