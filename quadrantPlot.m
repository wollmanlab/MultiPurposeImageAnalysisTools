function Cent = quadrantPlot(x1,x2, varargin)
Cent = ParseInputs('crosshair',[],varargin);

if isempty(Cent)
    %First, ask user to identify quadrants
    figure
    h = histogram2(x1,x2,40,'FaceColor','flat');
    Xedges = h.XBinEdges;
    Yedges = h.YBinEdges;
    XCenters = mean([Xedges(1:end-1); Xedges(2:end)]);
    YCenters = mean([Yedges(1:end-1); Yedges(2:end)]);
    imagesc(XCenters,YCenters,h.Values');
    set(gca,'ydir','normal');
    shg
    Cent = ginput(1)
end



cla
h = PlotColorCoded_v1(x1,x2,1:numel(x1), 1:numel(x1), 25,'np', 10000);


%If Cents are given, start here
QuadPer = [nnz((x1>=Cent(1)).*(x2>=Cent(2))), nnz((x1>=Cent(1)).*(x2<Cent(2))), nnz((x1<Cent(1)).*(x2>=Cent(2))), nnz((x1<Cent(1)).*(x2<Cent(2)))]./numel(x1);
hold on
plot([min(h.XData(:)) max(h.XData(:))], [Cent(2) Cent(2)],'k');
plot([Cent(1) Cent(1)], [min(h.YData(:)) max(h.YData(:))],'k');

text(mean([max(h.XData(:)),Cent(1)]),mean([max(h.YData(:)),Cent(2)]), num2str(QuadPer(1)*100,'%.1f'),'FontSize', 14,'BackgroundColor', [1 1 1 0.75]);
text(mean([max(h.XData(:)),Cent(1)]),mean([min(h.YData(:)),Cent(2)]), num2str(QuadPer(2)*100,'%.1f'),'FontSize', 14,'BackgroundColor', [1 1 1 0.75]);
text(mean([min(h.XData(:)),Cent(1)]),mean([max(h.YData(:)),Cent(2)]), num2str(QuadPer(3)*100,'%.1f'),'FontSize', 14,'BackgroundColor', [1 1 1 0.75]);
text(mean([min(h.XData(:)),Cent(1)]),mean([min(h.YData(:)),Cent(2)]), num2str(QuadPer(4)*100,'%.1f'),'FontSize', 14,'BackgroundColor', [1 1 1 0.75]);