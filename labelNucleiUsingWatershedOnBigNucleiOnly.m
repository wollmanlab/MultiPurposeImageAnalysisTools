function nuclbl = labelNucleiUsingWatershedOnBigNucleiOnly(nucbw,hWtrshd,maxNucArea,minNucArea)

nuclbl = bwlabel(nucbw);
t=tabulate(nuclbl(:));
t=t(2:end,1:2);

nucbwsml = ismember(nuclbl,t(t(:,2)<maxNucArea,1));
nucbwbig = nucbw & ~nucbwsml;

% segment nuclei
dst=bwdist(~nucbwbig);
dst(~nucbwbig)=-Inf;
dst=imhmax(dst,hWtrshd);
nuclbl=watershed(-dst);
nuclbl(~nucbw)=0;
% nuclbl=seperateLbl(nuclbl);

nucbw = nuclbl | nucbwsml;
nuclbl = bwlabel(nucbw);
tbl=tabulate(nuclbl(:));
nuclbl(ismember(nuclbl(:),tbl(tbl(:,2)>maxNucArea | tbl(:,2)<minNucArea,1)))=0;
nuclbl=bwlabel(nuclbl>0);