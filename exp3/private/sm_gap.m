function [upper,lower,z] = sm_gap(p,x,eta,tol)
% Upper/lower bounds on the total Nikaido-Isoda gap, up to floating-point error.
s=accumarray(p.dst,p.a.*x,[p.n 1]); upper=0; lower=0; z=zeros(size(x));
for i=1:p.n
    e=p.rows{i}; j=p.dst(e); b=1+s(j)-p.a(e).*x(e);
    [z(e),g,u]=sm_best_response(x(e),b,p.a(e),p.SL(j),p.C(i),p.ub(e),eta,tol);
    upper=upper+u; lower=lower+g;
end
end
