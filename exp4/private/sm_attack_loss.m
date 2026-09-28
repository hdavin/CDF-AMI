function [loss,M]=sm_attack_loss(p,x,sigma,kappa,offset)
% offset=2 exactly reproduces supplied Lsm.m; offset=1 matches paper M=log(1+s).
if nargin<4,kappa=100;end
if nargin<5,offset=2;end
x=x(:);sigma=sigma(:);
assert(numel(x)==p.m&&all(isfinite(x)&x>=0),'Invalid allocation.');
assert(numel(sigma)==p.n&&all(sigma==0|sigma==1),'Invalid attack indicators.');
assert(isscalar(offset)&&any(offset==[1 2]),'offset must be 1 or 2.');
assert(isscalar(kappa)&&isfinite(kappa)&&kappa>=0,'Invalid kappa.');
M=log(offset+accumarray(p.dst,p.a.*x,[p.n 1]));
active=sigma>0 & p.SL>0;
if kappa==0,loss=0;else,loss=sum(kappa*p.SL(active)./M(active));end
end
