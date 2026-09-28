function [r,h]=scale_solve(p,o)
x=p.x0;s=accumarray(p.dst,p.a.*x,[p.n 1]);
h=zeros(o.maxSweeps+1,6);checks=0;updateSeconds=0;gapSeconds=0;
clock=tic;maxGap=inf;sumGap=inf;status='iteration_limit';lastChecked=-1;
for sweep=0:o.maxSweeps
 if mod(sweep,o.gapEvery)==0||sweep==o.maxSweeps||toc(clock)>=o.timeLimitSeconds
  timer=tic;[maxGap,sumGap]=scale_gap(p,x,s);gapSeconds=gapSeconds+toc(timer);checks=checks+1;lastChecked=sweep;
  h(checks,:)=[sweep,toc(clock),maxGap,sumGap,sum(p.SL.*log1p(s)),sum(x)];
 end
 if maxGap<=o.epsilon,status='converged';break;end
 if toc(clock)>=o.timeLimitSeconds
  if lastChecked~=sweep
   timer=tic;[maxGap,sumGap]=scale_gap(p,x,s);gapSeconds=gapSeconds+toc(timer);checks=checks+1;lastChecked=sweep;
   h(checks,:)=[sweep,toc(clock),maxGap,sumGap,sum(p.SL.*log1p(s)),sum(x)];
  end
  if maxGap<=o.epsilon,status='converged';else,status='time_limit';end
  break;
 end
 if sweep==o.maxSweeps,break;end
 timer=tic;
 for i=1:p.n
  e=p.ptr(i):p.ptr(i+1)-1;j=p.dst(e);a=p.a(e);
  b=max(1,1+s(j)-a.*x(e));z=scale_response(b,a,p.w(e),p.C(i));
  s(j)=s(j)+a.*(z-x(e));x(e)=z;
 end
 s=accumarray(p.dst,p.a.*x,[p.n 1]);updateSeconds=updateSeconds+toc(timer);
end
assert(lastChecked==sweep,'Final profile must have a gap certificate.');
seconds=toc(clock);h=h(1:checks,:);
violation=max([0;-x;accumarray(p.src,x,[p.n 1])-p.C]);
assert(violation<1e-8 && all(isfinite(x)),'Invalid allocation.');
% Explicit hypothetical unicast protocol: per update, request s, reply s,
% send new allocation on every directed edge; one scheduling message per SM.
updateMessages=sweep*(3*p.m+p.n);
% Gap check: frozen-profile request/reply on each directed edge; N reports.
gapMessages=checks*(2*p.m+p.n);setupMessages=2*p.m;
messages=updateMessages+gapMessages+setupMessages;
info=whos('x','s');arrayBytes=sum([info.bytes]);
r=struct('seconds',seconds,'updateSeconds',updateSeconds,'gapSeconds',gapSeconds,...
 'sweeps',sweep,'checks',checks,'status',status,'converged',strcmp(status,'converged'),...
 'maxGap',maxGap,'sumGap',sumGap,'utility',sum(p.SL.*log1p(s)),...
 'violation',violation,'brCalls',(sweep+checks)*p.n,...
 'coordinateVisits',(sweep+checks)*p.m,...
 'sortWork',(sweep+checks)*sum(p.degree.*log2(max(2,p.degree))),...
 'arrayBytes',arrayBytes,'updateMessages',updateMessages,'gapMessages',gapMessages,...
 'setupMessages',setupMessages,'messages',messages,...
 'bytes',messages*(o.headerBytes+o.identifierBytes+o.scalarBytes));
end
