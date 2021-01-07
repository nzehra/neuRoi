%% Add neuRoi rood directory to path
addpath('../../neuRoi')
%% Clear variables
clear all
%close all
foo = load('\\tungsten-nas.fmi.ch\tungsten\scratch\gfriedri\teminesi\NTImaging\clut2b.mat');
clut2b = foo.clut2b;
%% Step01a Configure experiment and image processing parameters
%% Step01b Load experiment configuration from file
resultDir = '\\tungsten-nas.fmi.ch\tungsten\scratch\gfriedri\teminesi\2Photon_RawData\NT0012_2\20200624\f2\results';
expName = 'Nesibe-20200624-f2';
planeNum = 4;
planeString = NrModel.getPlaneString(planeNum);
traceResultDir = fullfile(resultDir,'time_trace_MC', ...
                         planeString);

expFilePath = fullfile(resultDir,sprintf('experimentConfig_%s.mat',expName));
foo = load(expFilePath);
myexp = foo.myexp;
disp(myexp.expInfo)
fileNameArray = myexp.rawFileList;

%% dF/F maps for all trials

inFileType = 'binned';
mapType = 'response';
mapOption1 = struct('offset',-10,...
                    'fZeroWindow',[8 13],...
                    'responseWindow',[17 25]);
mapOption2 = struct('offset',-10,...
                    'fZeroWindow',[6 9 ],...
                    'responseWindow',[16 20]);

startPointList = [0 0 0 0 0 0 0 0]% [79 95 85 95 95 95 95 95];
odorDelayList = startPointList - min(startPointList);

saveMap = false;
trialOption = [];
[responseArray1,trialTable] = myexp.calcMapBatch(inFileType,...
                                   mapType,mapOption1,...
                                   'trialOption',trialOption,...
                                   'odorDelayList',odorDelayList,...
                                   'sortBy','odor',...
                                   'planeNum',planeNum,...
                                    'fileIdx',[1:24]);
% [responseArray2,trialTable2] = myexp.calcMapBatch(inFileType,...
%                                    mapType,mapOption2,...
%                                    'trialOption',trialOption,...
%                                    'odorDelayList',odorDelayList,...
%                                    'sortBy','odor',...
%                                    'planeNum',planeNum,...
%                                     'fileIdx',1:3);
% TODO filtering of response maps
%% Plot dF/F maps
nTrialPerOdor = 3;
climit = [0 0.5];
sm = 50;
% responseArray = cat(3,responseArray2(:,:,1),responseArray1(:,:,1:2),...
%                     responseArray2(:,:,2),responseArray1(:,:,3:end));
% trialTable = [trialTable2(1,:);trialTable1(1:2,:);trialTable2(2,:);trialTable1(3:end,:)];
batch.plotMaps(responseArray1,trialTable, ...
               nTrialPerOdor,climit,clut2b,sm)
%% Save dF/F map
responseDir = fullfile(myexp.resultDir, 'responseMap');
if ~exist(responseDir, 'dir')
    mkdir(responseDir)
end
responseMapFileName = sprintf('responseMap_plane%d.tif',planeNum);
responseMapFilePath = fullfile(responseDir,responseMapFileName);
                               
saveas(gcf,responseMapFilePath)

