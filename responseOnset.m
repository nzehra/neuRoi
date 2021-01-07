timeTraceMatArray = dir('*.mat');

for n=1:24
a=load(timeTraceMatArray(n).name);
b=a.traceResult.timeTraceMat; 
meanTimeTrace(n,:)=mean(b);
responseOn= find(meanTimeTrace(n,:)>(0.4*max(meanTimeTrace(n,:))));
%responseOn=find(b> 0.35*max(b));
onset(n)=responseOn(1);
end


trialNum=3;
x=numel(onset);
xx=reshape(onset(1:x-mod(x,trialNum)),trialNum, []);
y=sum(xx,1).'/trialNum;

%%
base=min(y);
frameOffsetArray=y-base;