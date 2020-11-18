function [corrMat] = calcCosineDistance(timeTraceMat1, ...
                                               timeTraceMat2)

corrMat = squareform(pdist(timeTraceMat1,timeTraceMat2));

end
