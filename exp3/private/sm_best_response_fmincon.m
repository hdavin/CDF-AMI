function z=sm_best_response_fmincon(x,b,a,w,C,ub,eta)
% Individual cost-free utility maximization using Optimization Toolbox, not potential.
if isempty(x)||C==0,z=zeros(size(x));return;end
persistent options
if isempty(options)
 options=optimoptions('fmincon','Algorithm','sqp','Display','off',...
 'SpecifyObjectiveGradient',true,'OptimalityTolerance',1e-12,...
 'ConstraintTolerance',1e-12,'StepTolerance',1e-14,'MaxIterations',500,...
 'MaxFunctionEvaluations',10000);
end
[z,~,flag]=fmincon(@objective,x,ones(1,numel(x)),C,[],[],zeros(size(x)),ub,[],options);
% Remove numerical feasibility drift; the outer gap check still decides success.
z=max(0,min(ub,z));if sum(z)>C,z=z*(C/sum(z));end
if flag<=0 && localGap(z)>1e-9
    retry=optimoptions(options,'Algorithm','interior-point','MaxIterations',2000,...
        'MaxFunctionEvaluations',30000,'OptimalityTolerance',1e-10);
    [z,~,flag]=fmincon(@objective,z,ones(1,numel(x)),C,[],[],zeros(size(x)),ub,[],retry);
    z=max(0,min(ub,z));if sum(z)>C,z=z*(C/sum(z));end
end
assert(all(isfinite(z)) && (flag>0 || localGap(z)<=1e-9),...
    'Individual fmincon solve failed (exit flag %d, local gap %.3g).',flag,localGap(z));
% Nonpositive exit flags are accepted only with an independent unscaled
% concavity certificate. The global NI-gap check remains unchanged.
    function gap=localGap(y)
        grad=w.*a./(b+a.*y);
        [g,order]=sort(grad,'descend');left=C;support=0;
        for j=1:numel(g)
            if g(j)<=0||left<=0,break;end
            amount=min(left,ub(order(j)));support=support+g(j)*amount;left=left-amount;
        end
        gap=max(0,support-grad'*y);
    end

    function [v,g]=objective(y)
        % Objective shifted by its value at x to resolve small improvements.
        v=-sum(w.*log1p(a.*(y-x)./(b+a.*x)));
        g=-w.*a./(b+a.*y);
        % Positive objective scaling improves SQP stopping resolution without
        % changing the maximizer or any reported utility/cost coefficient.
        v=1e4*v;g=1e4*g;
    end
end
