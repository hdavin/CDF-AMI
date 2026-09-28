function r=s6_solve(p,o)
if strcmp(o.bestResponseSolver,'fmincon'),assert(exist('fmincon','file')==2&&license('test','Optimization_Toolbox'),'Default GRA requires Optimization Toolbox; analytic backend is available.');end
degree=full(sum(p.Adj,2));x=p.C(p.src)./degree(p.src);
s=accumarray(p.dst,p.a.*x,[p.n 1]);timer=tic;hist=zeros(0,4);
for k=0:o.maxSweeps
 if mod(k,o.gapEvery)==0||k==o.maxSweeps
  gap=0;
  for i=1:p.n
   e=p.rows{i};if isempty(e),continue;end
   b=max(1,1+s(p.dst(e))-p.a(e).*x(e));
   z=s6_response(b,p.a(e),p.SL(p.dst(e)),p.C(i));
   g=p.SL(p.dst(e)).*p.a(e)./(b+p.a(e).*z);
   gain=sum(p.SL(p.dst(e)).*log1p(p.a(e).*(z-x(e))./(b+p.a(e).*x(e))));
   upper=max(0,gain+max(0,p.C(i)*max([0;g])-g'*z));gap=max(gap,upper);
  end
  hist(end+1,:)=[k,gap,sum(p.SL.*log1p(s)),toc(timer)]; %#ok<AGROW>
  if gap<=o.epsilon,break;end
 end
 if k==o.maxSweeps,break;end
 for i=1:p.n
  e=p.rows{i};if isempty(e),continue;end
  j=p.dst(e);b=max(1,1+s(j)-p.a(e).*x(e));
  if strcmp(o.bestResponseSolver,'fmincon')
   z=sm_best_response_fmincon(x(e),b,p.a(e),p.SL(j),p.C(i),p.ub(e),0);
  else,z=s6_response(b,p.a(e),p.SL(j),p.C(i));end
  s(j)=s(j)+p.a(e).*(z-x(e));x(e)=z;
 end
 s=accumarray(p.dst,p.a.*x,[p.n 1]);
end
r=struct('x',x,'gap',gap,'converged',gap<=o.epsilon,'sweeps',k,'seconds',toc(timer),'history',hist);
assert(max([0;-x;accumarray(p.src,x,[p.n 1])-p.C])<1e-8);
end
