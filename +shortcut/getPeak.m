aminoacidMean=[];
bileacidMean=[];
maxA=[];
maxB=[];

for n=1:3
aminoacid=[aminoacidMean;meanTimeTrace(n,:)];
maxA=[maxA;max(aminoacid)];
end

for n=4:6
bileacid=[bileacidMean;meanTimeTrace(n,:)];
maxB=[maxB;max(bileacid)];
end

Meanaa=mean(aminoacidMean);
Meanba=mean(bileacidMean);

max(Meanaa)
max(Meanba)