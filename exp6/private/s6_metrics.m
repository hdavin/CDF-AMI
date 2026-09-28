function rows=s6_metrics(p,x,attackMasks,kappa)
M=log1p(accumarray(p.dst,p.a.*x,[p.n 1]));
U=sum(p.SL.*M);q=size(attackMasks,2);loss=zeros(q,1);normLoss=loss;
for k=1:q
 idx=attackMasks(:,k);loss(k)=sum(kappa*p.SL(idx)./M(idx));
 normLoss(k)=loss(k)/(kappa*sum(p.SL(idx)));
end
rows=struct('Utility',U,'NormalizedUtility',U/sum(p.SL),...
 'Loss',mean(loss),'NormalizedLoss',mean(normLoss),...
 'InfiniteLossFraction',mean(isinf(loss)),'UnmonitoredFraction',mean(M==0));
end
