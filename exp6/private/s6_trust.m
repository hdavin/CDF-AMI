function [T,detail]=s6_trust(K,Adj,testRate,attack,w,o,seed)
% Paired random draws: the same seed is reused for every w and testRate.
state=rng;restore=onCleanup(@()rng(state));rng(seed,'twister'); %#ok<NASGU>
Adj=logical(Adj);N=size(Adj,1);alpha=zeros(N);beta=zeros(N);
normal=setdiff(1:N,attack);isBad=false(N,1);isBad(attack)=true;
test=rand(1,K)<testRate;degree=sum(Adj,2);
majority=false(N,1);majority(normal)=sum(Adj(normal,attack),2)./max(1,degree(normal))>.5;
for k=1:K
 X=double(Adj);passive=Adj(attack,:)&(rand(numel(attack),N)<o.maliciousProbability);
 q=X(attack,:);q(passive)=.5*rand(nnz(passive),1);X(attack,:)=q;alpha=alpha+X';
 F=zeros(N);F(attack,:)=Adj(attack,:).*(rand(numel(attack),N)<o.maliciousProbability);
 % Draw on every round so the underlying histories are paired across PT.
 falseReport=Adj(normal,:).*(rand(numel(normal),N)<o.normalErrorRate);
 if test(k),beta=beta+w*F';
 else
  F(normal,:)=falseReport;
  if strcmp(o.trustMode,'legacy')
   F(majority,:)=1; % Original sender/receiver indexing, retained for audit only.
  else
   % Receiver i judges each normal neighbor; not all nodes in sender row i.
   for i=find(majority)'
    js=find(Adj(i,:)&~isBad');F(js,i)=1;
   end
   F=F.*Adj;
  end
  beta=beta+F';
 end
end
na=alpha./(sqrt(sum(alpha.^2,2))+1e-10);nb=beta./(sqrt(sum(beta.^2,2))+1e-10);
T=zeros(N);ties=0;
for i=1:N
 js=find(Adj(i,:));if isempty(js),continue;end
 if strcmp(o.trustMode,'legacy')
  va=na(i,na(i,:)>0);vb=nb(i,nb(i,:)>=0);
 else,va=na(i,js);vb=nb(i,js);end
 ap=max(va);am=min(va);bp=min(vb);bm=max(vb);
 dp=hypot(na(i,js)-ap,nb(i,js)-bp);dm=hypot(na(i,js)-am,nb(i,js)-bm);
 score=dm./(dm+dp+1e-10);
 if strcmp(o.trustMode,'neighbor')
  tie=dm+dp<=1e-14;score(tie)=.5;ties=ties+nnz(tie);
 end
 T(i,js)=score;
end
detail=struct('alpha',alpha,'beta',beta,'testRounds',sum(test),'ties',ties);
end
