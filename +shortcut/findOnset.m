function onset = findOnset(timeTrace,thresh)
onsetListFinal=zeros(size(cutTimeTraceMatArray{1},1),length(cutTimeTraceMatArray));
   
    for odorNum=1:length(timeTrace)
        onsetList=[];
        timeTraceChosen=timeTrace{odorNum};
            for m=1:length(timeTraceChosen)
                responseOnset=[];
                responseOnset= find(timeTraceChosen(m,:)>(thresh));   
                if isempty(responseOnset)
                   responseOnset=NaN;%length(timeTraceChosen); 
                end 
                onsetList=[onsetList;responseOnset(1)];
            end
          onsetListFinal(:,odorNum)= onsetList;    
    end
          
end