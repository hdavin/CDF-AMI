function [z, gain, upper] = sm_best_response(x,b,a,w,C,ub,eta,tol)
% Solve sum w*log(b+a*z) with box bounds and sum(z)<=C.
% b = 1 + incoming weighted resource from OTHER players, so b>=1.
if isempty(x) || C==0
    z=zeros(size(x)); gain=0; upper=0; return;
end
b=max(b,1); z=at_lambda(0,b,a,w,ub,eta);
if sum(z)>C
    lo=0; hi=max(w.*a./b);
    for k=1:100
        mid=(lo+hi)/2; v=at_lambda(mid,b,a,w,ub,eta);
        if sum(v)>C, lo=mid; else, hi=mid; end
        if hi-lo<=tol*max(1,hi), break; end
    end
    z=at_lambda(hi,b,a,w,ub,eta); % feasible side of the multiplier bracket
end
% log1p avoids subtracting nearly equal logarithms near equilibrium.
gain=sum(w.*log1p(a.*(z-x)./(b+a.*x)));
grad=w.*a./(b+a.*z);
% Concavity gives an upper bound on the unresolved best-response error.
% Maximize the linearized objective over the same capped simplex.
if all(ub>=C)
    support=C*max([0;grad]);
else
    [g,order]=sort(grad,'descend'); left=C; support=0;
    for k=1:numel(g)
        if g(k)<=0 || left<=0, break; end
        q=min(left,ub(order(k))); support=support+g(k)*q; left=left-q;
    end
end
upper=max(0,gain+max(0,support-grad.'*z));
gain=max(0,gain);
end
function z=at_lambda(lambda,b,a,w,ub,eta)
assert(eta==0,'Cost-free best response expected.');
z=zeros(size(a));active=(a>0 & w>0);
if lambda==0
 z(active)=ub(active);
else
 z(active)=min(ub(active),max(0,w(active)/lambda-b(active)./a(active)));
end
end
