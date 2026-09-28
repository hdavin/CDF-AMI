function Adj = net_adjacency(xy,radius)
% All and only pairs closer than radius are linked; no artificial backbone edges.
n = size(xy,1);
distance = sqrt((xy(:,1)-xy(:,1)').^2+(xy(:,2)-xy(:,2)').^2);
Adj = double(distance<radius);
Adj(1:n+1:end) = 0;
end
