function summary = net_summary(datasets,names)
rows = cell(numel(names),11);
for k = 1:numel(names)
    net = datasets.(names{k});
    rows(k,:) = {net.name,net.N,net.Lim,nnz(net.Adj)/2,mean(net.degree), ...
        min(net.degree),max(net.degree),net.metadata.componentCount, ...
        net.metadata.attempts,net.metadata.seed,mat2str(net.metadata.componentSizes')};
end
summary = cell2table(rows,'VariableNames',{'Topology','N','RadiusMeters','Edges', ...
    'MeanDegree','MinDegree','MaxDegree','Components','Attempts','Seed','ComponentSizes'});
end
