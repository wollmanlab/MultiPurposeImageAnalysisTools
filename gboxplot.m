function gboxplot(C)

C=cellfun(@(c) c(:),C,'uniformoutput',0); 
g=num2cell((1:numel(C)));
C=C(:); 
g=g(:); 
g=cellfun(@(c,g) g*ones(size(c)),C,g,'uniformoutput',0); 
C=cat(1,C{:}); 
g=cat(1,g{:}); 
boxplot(C,g)
