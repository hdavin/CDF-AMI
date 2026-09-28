function [priority,peak,average,gamma]=s6_security_level(o,n)
% Calculate SM security levels using the user-specified formula.
SL_data=load(fullfile(o.dataDir,'SL.mat'));
assert(size(SL_data.SL,1)==n&&all(isfinite(SL_data.SL),'all'));
gamma=1-0.5*rand(n,1); % once per paired repetition, unchanged
assert(numel(gamma)==n&&all(isfinite(gamma)&gamma>0));
w1=o.w1;w2=o.w2;
SL=(w1*max(SL_data.SL,[],2)+w2*mean(SL_data.SL,2)).*gamma;
priority=SL;
peak=max(SL_data.SL,[],2);average=mean(SL_data.SL,2);
assert(all(isfinite(priority)&priority>0),'Security levels must be positive.');
end
