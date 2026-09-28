function p = sm_load_model(input)
% Read the four supplied NIRA GAME files without eval or Symbolic Toolbox.
% Alternatively input = struct('Adj',Adj,'TV',TV,'SL',SL,'C',C).
if isstruct(input)
    p = input;
    required = {'Adj','TV','SL','C'};
    for k=1:numel(required), assert(isfield(p,required{k}), 'Missing %s',required{k}); end
    p.n = numel(p.C);
    p.Adj = logical(p.Adj);
    p.src=[]; p.dst=[];
    for i=1:p.n
        js=find(p.Adj(i,:));
        p.src=[p.src;repmat(i,numel(js),1)]; %#ok<AGROW>
        p.dst=[p.dst;js(:)]; %#ok<AGROW>
    end
    p.ub=p.C(p.src); p.ub=p.ub(:);
    p.name='numeric_model';
else
    S=load(input,'GAME'); assert(isfield(S,'GAME'),'The file must contain GAME.');
    g=S.GAME; p.n=double(g.numplayers); p.name=char(input);
    assert(g.type(1)==0,'Only static games are supported.');
    if isfield(g,'eqconstraints'), assert(isempty(g.eqconstraints),'Equality constraints are unsupported.'); end
    p.TV=zeros(p.n); p.SL=nan(p.n,1); p.C=nan(p.n,1);
    seen=false(p.n); p.src=[]; p.dst=[]; p.ub=[];
    for k=1:numel(g.constants)
        c=g.constants(k); v=str2double(c.value);
        assert(isfinite(v),'Non-numeric constant: %s',c.consym);
        token=regexp(c.consym,'^TV_(\d+)_(\d+)_$','tokens','once');
        if ~isempty(token)
            i=str2double(token{1}); j=str2double(token{2});
            assert(i>=1 && i<=p.n && j>=1 && j<=p.n,'Invalid trust index.');
            assert(~seen(i,j),'Duplicate trust constant.'); p.TV(i,j)=v; seen(i,j)=true;
        else
            token=regexp(c.consym,'^SL_(\d+)_$','tokens','once');
            assert(~isempty(token),'Unsupported constant: %s',c.consym);
            i=str2double(token{1}); assert(i>=1 && i<=p.n && isnan(p.SL(i)),'Invalid security constant.');
            p.SL(i)=v;
        end
    end
    assert(numel(g.variables)==p.n,'Invalid player variables.');
    for i=1:p.n
        vars=g.variables{i};
        for k=1:numel(vars)
            tok=regexp(vars(k).varsym,'^x_(\d+)_(\d+)_$','tokens','once');
            assert(~isempty(tok) && str2double(tok{1})==i,'Invalid allocation variable.');
            j=str2double(tok{2}); assert(j>=1 && j<=p.n && j~=i,'Invalid receiver.');
            assert(vars(k).lower==0 && isfinite(vars(k).upper) && vars(k).upper>=0,'Unsupported variable bounds.');
            p.src(end+1,1)=i; p.dst(end+1,1)=j; p.ub(end+1,1)=vars(k).upper; %#ok<AGROW>
        end
        % Check the exact supplied constraint: sum of outgoing variables - C_i.
        raw=regexprep(g.lessconstraints(i).raw,'\s','');
        prefix=strjoin({vars.varsym},'+');
        assert(startsWith(raw,[prefix '-']),'Unsupported capacity constraint for SM %d.',i);
        p.C(i)=str2double(raw(numel(prefix)+2:end));
    end
    assert(numel(g.lessconstraints)==p.n,'Unsupported extra constraints.');
    p.Adj=logical(sparse(p.src,p.dst,1,p.n,p.n));
    assert(nnz(p.Adj)==numel(p.src),'Duplicate allocation variables.');
    % Validate the actual stored benefit expressions instead of silently replacing them.
    assert(numel(g.customfunctions)==p.n && numel(g.payoffs)==p.n,'Unsupported GAME structure.');
    for i=1:p.n
        js=find(p.Adj(i,:)); terms=cell(1,numel(js));
        for k=1:numel(js), terms{k}=sprintf('+TV_%d_%d_*x_%d_%d_',i,js(k),js(k),i); end
        expected=['log(1' strjoin(terms,'') ')'];
        assert(strcmp(regexprep(g.customfunctions(i).code,'\s',''),expected),'Unsupported monitoring expression at node %d.',i);
        terms=cell(1,numel(js));
        for k=1:numel(js), terms{k}=sprintf('SL_%d_*M_%d_',js(k),js(k)); end
        assert(strcmp(regexprep(g.payoffs(i).raw,'\s',''),strjoin(terms,'+')),'Unsupported payoff at player %d.',i);
        assert(g.payoffs(i).weight==1,'Non-unit payoff weights are unsupported.');
    end
    assert(all(seen(sub2ind([p.n p.n],p.dst,p.src))),'Missing receiver-to-donor trust values.');
end
p.C=p.C(:); p.SL=p.SL(:);
assert(isequal(size(p.Adj),[p.n p.n]) && isequal(size(p.TV),[p.n p.n]),'Invalid matrix dimensions.');
assert(isequal(p.Adj,p.Adj.') && ~any(diag(p.Adj)),'An undirected network without self-edges is required.');
assert(all(isfinite(p.C) & p.C>=0) && all(isfinite(p.SL) & p.SL>=0),'Invalid capacity/security values.');
p.m=numel(p.src); p.a=p.TV(sub2ind([p.n p.n],p.dst,p.src)); p.a=p.a(:);
assert(all(isfinite(p.a) & p.a>=0 & p.a<=1),'Trust must lie in [0,1].');
p.rows=cell(p.n,1);
for i=1:p.n, p.rows{i}=find(p.src==i); end
% Exact eigenvalue of the conservative H bound, using small receiver blocks.
p.LphiBound=0;
for j=1:p.n
    a=p.a(p.dst==j); d=numel(a);
    if d>1
        H=p.SL(j)*((d-2)*(a*a.')+diag(a.^2));
        p.LphiBound=max(p.LphiBound,max(eig(H)));
    end
end
end
