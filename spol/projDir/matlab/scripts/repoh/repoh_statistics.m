%Date:  October 11, 2011
%Author:  S. Powell, UW
%Description:  Compute standard deviation of humidity plots for product generation.

%Produce error bars.
if azi_sep == 'y'
  E = nan(length(hgtbin)-1,length(azibin)-1); U = E; L = E;
  for l = 1:length(azibin)-1
    for k = 1:length(hgtbin) - 1
      if isfinite(humbin_mean(k,l)) == 1
        E(k,l) = 2*std(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        dev = 2*std(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        mn = mean(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        max_allow = mn + dev;
        min_allow = mn - dev;
        L(k,l) = humbin_mean(k,l) - prctile(scathum(((scathum < max_allow) .* (scathum > min_allow) .* (scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ),10);
        U(k,l) = prctile(scathum(( (scathum < max_allow) .* (scathum > min_allow) .* (scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ),90) - humbin_mean(k,l);
      end  
    end
  end
else
  E = nan(1,length(hgtbin)-1); U = E; L = E;
  for k = 1:length(hgtbin) - 1
    if isfinite(humbin_mean(k)) == 1
      E(k) = 2*std(scathum( (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        dev = 2*std(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        mn = mean(scathum(((scatazi >= azibin(l)) .* (scatazi < azibin(l+1))) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ));
        max_allow = mn + dev;
        min_allow = mn - dev;
      L(k) = humbin_mean(k) - prctile(scathum( (scathum < max_allow) .* (scathum > min_allow) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ),10);
      U(k) = prctile(scathum( (scathum < max_allow) .* (scathum > min_allow) .* (scathgt >= hgtbin(k)) .* (scathgt < hgtbin(k+1)) == 1 ),90) - humbin_mean(k);
    end
  end
end
