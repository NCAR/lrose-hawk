%Date:  October 11, 2011
%Author:  S. Powell, UW
%Description:  Compute standard deviation of humidity plots for product generation.

%Produce "minimum" and "maximum" soundings.

%minsnd(k) = min(mean(abshum(rhgt==ihgt(k))).*mean(rho(rhgt==ihgt(k))),minsnd(k));
%maxsnd(k) = max(mean(abshum(rhgt==ihgt(k))).*mean(rho(rhgt==ihgt(k))),maxsnd(k));
minsnd(k) = min(mean(abshum(rhgt==ihgt(k))),minsnd(k));
maxsnd(k) = max(mean(abshum(rhgt==ihgt(k))),maxsnd(k));
