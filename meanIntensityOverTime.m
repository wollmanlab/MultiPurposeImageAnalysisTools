function [avg2, cellids] = meanIntensityOverTime(stk,lbl,func)

if nargin==2
    func='mean'; 
%     func = @(x) nanmean(x,1)'; % func gets a matrix per where each col is a tiempoint and 
%                                % must return a col with measurment per
%                                % timepoint as rows. 
end

%% make a 2D table
bw = lbl>0; 
tbl = zeros(nnz(bw),size(stk,3),'single');
for i=1:size(stk,3), 
    m=stk(:,:,i); 
    tbl(:,i)=m(bw);
end


%% create cells per cell
[cl, cellids]=grp2cell(tbl,lbl(bw));
avg=cell(size(cl)); 
if ischar(func)
    switch func
        case 'mean'
            for i=1:numel(cl)
                avg{i}=nanmean(cl{i},1)';
            end
        case 'median'
            for i=1:numel(cl)
                avg{i}=nanmedian(cl{i},1)';
            end
    end
else
    for i=1:numel(cl)
        avg{i}=func(cl{i});
    end
end
avg = cat(2,avg{:}); 

%% redo labels in case there were missing number in lbl
t=tabulate(lbl(:)); 
tix=t(2:end,1); 
avg2=nan(size(avg,1),max(tix)); 
avg2(:,tix)=avg; 