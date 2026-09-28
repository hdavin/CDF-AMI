function [maximum,total]=scale_gap(p,x,s)
maximum=0;total=0;
for i=1:p.n
 e=p.ptr(i):p.ptr(i+1)-1;j=p.dst(e);a=p.a(e);w=p.w(e);
 b=max(1,1+s(j)-a.*x(e));z=scale_response(b,a,w,p.C(i));
 gain=sum(w.*log1p(a.*(z-x(e))./(b+a.*x(e))));
 grad=w.*a./(b+a.*z);
 upper=max(0,gain+max(0,p.C(i)*max([0;grad])-grad'*z));
 maximum=max(maximum,upper);total=total+upper;
end
end
