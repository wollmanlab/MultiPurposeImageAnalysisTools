function traj = traverseGraph_mcode(gr,possibleStart)
% Traverse a direcred graph of connected nodes and returns an array where
% every list of nodes that are connected to one another (e.g. I could walk
% them all) have the same number. 

 cnt=0;
 traj=zeros(length(gr),1);
 while any(possibleStart)
     cnt=cnt+1;
     nxt=find(possibleStart,1,'first');
     while nxt>0
         traj(nxt)=cnt;
         possibleStart(nxt)=false;
         nxt=gr(nxt);
     end
 end