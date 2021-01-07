function sortedTimeTraceArray = sortNeurons(timeTrace,odorNum,thresh)

timeTraceChosen=timeTrace{odorNum};
onsetList=[];

    for n=1:length(timeTraceChosen)
        responseOnset=[];
         %responseOnset= find(timeTraceChosen(n,38:75)>thresh*max(timeTraceChosen(n,:)));
         responseOnset= find(timeTraceChosen(n,38:75)>thresh);   
        if isempty(responseOnset)
           responseOnset=length(timeTraceChosen);
        else
           responseOnset=responseOnset+38; 
        end 
        onsetList=[onsetList;responseOnset(1)];
    end
    
    order=unique(onsetList);
    finalOrder=[];      
    
    for t=1:length(order)
         finalOrder=[finalOrder;find(onsetList==order(t))];
    end
    
    for y=1:length(timeTrace)
        tempMat=timeTrace{y};
        for z=1:length(tempMat)
            sortedMat(z,:)=tempMat(finalOrder(z),:);
        end
        sortedTimeTraceArray{y}=sortedMat;
    end               
end


   

