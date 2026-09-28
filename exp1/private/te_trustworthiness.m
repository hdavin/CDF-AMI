function T = te_trustworthiness(Adj,testRate,attack,o)
% Vectorized uploaded trustworthiness algorithm, with identical random draws.
% Preserve original majority-vote row assignment and TOPSIS ideal sets.
n = size(Adj,1); normal = setdiff(1:n,attack);
alpha = zeros(n); beta = zeros(n);
testIndex = rand(1,o.rounds)<testRate;
majority = zeros(n,1);
majority(normal) = sum(Adj(normal,attack),2)./sum(Adj(normal,:),2);
for t = 1:o.rounds
    X = o.resource*Adj;
    bad = Adj(attack,:).*(rand(numel(attack),n)<o.maliciousProbability);
    contribution = X(attack,:);
    contribution(logical(bad)) = .5*o.resource*rand(1,nnz(bad));
    X(attack,:) = contribution;
    alpha = alpha+X';
    F = zeros(n);
    F(attack,:) = Adj(attack,:).*(rand(numel(attack),n)<o.maliciousProbability);
    if testIndex(t)
        beta = beta+o.punishment*F';
    else
        % Intentionally retain the uploaded full-row rule, including nonedges.
        F(majority>.5,:) = 1;
        beta = beta+F';
    end
end
na = alpha./(sqrt(sum(alpha.^2,2))+o.epsilon);
nb = beta./(sqrt(sum(beta.^2,2))+o.epsilon);
positiveA = max(na,[],2);
positiveOnly = na; positiveOnly(positiveOnly<=0) = Inf;
negativeA = min(positiveOnly,[],2);
positiveB = min(nb,[],2); negativeB = max(nb,[],2);
dp = sqrt((na-positiveA).^2+(nb-positiveB).^2);
dn = sqrt((na-negativeA).^2+(nb-negativeB).^2);
T = (Adj.*dn)./(dn+dp+o.epsilon);
end
