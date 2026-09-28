function te_export(fig,o,stem)
drawnow;
for k = 1:numel(o.formats)
    fmt = o.formats{k}; path = fullfile(o.outputDir,[stem '.' fmt]);
    switch fmt
        case 'fig'
            savefig(fig,path);
        case 'png'
            exportgraphics(fig,path,'Resolution',300,'BackgroundColor','white');
        case 'pdf'
            exportgraphics(fig,path,'ContentType','vector','BackgroundColor','white');
        case 'svg'
            % print supports SVG on releases preceding exportgraphics SVG support.
            set(fig,'PaperPositionMode','auto');
            print(fig,path,'-dsvg','-painters');
    end
end
if strcmpi(o.visible,'off'), close(fig); end
end
