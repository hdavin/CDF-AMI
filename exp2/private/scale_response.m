function z=scale_response(b,a,w,C)
% Exact weighted water filling (up to floating-point arithmetic), eta=0.
% Max sum_j w_j log(b_j+a_j*z_j), z>=0, sum(z)<=C.
if isempty(a)||C==0,z=zeros(size(a));return;end
c=b./a;threshold=w./c;[t,order]=sort(threshold,'descend');
levels=cumsum(w(order))./(C+cumsum(c(order)));
k=find(t>levels,1,'last');lambda=levels(k);
z=max(0,w/lambda-c);
if sum(z)>C,z=z*(C/sum(z));end
end
