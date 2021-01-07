
addpath('../../neuRoi')
%% Clear variables
clear all
%% Step01 Configure experiment and image processing parameters
% Load 
% Experiment parameters
expInfo.name = 'Nesibe-20200604-f2';
expInfo.frameRate = 30;
expInfo.odorList = {'Ala','Trp','Ser','TCA','GCA','TDCA','ACSF','Spont'};
expInfo.nTrial = 3;
expInfo.nPlane = 4;
expSubDir = expInfo.name;

% Raw data
rawDataDir = 'W:\scratch\gfriedri\teminesi\2Photon_RawData\NT0012_2\20200604\f2';
rawFileList = {'NT0012_21dpf_f2_o1Ala_001_.tif';...
               'NT0012_21dpf_f2_o1Ala_002_.tif';...
               'NT0012_21dpf_f2_o1Ala_003_.tif';...
               'NT0012_21dpf_f2_o2Trp_001_.tif';...
               'NT0012_21dpf_f2_o2Trp_002_.tif';...
               'NT0012_21dpf_f2_o2Trp_003_.tif';...
               'NT0012_21dpf_f2_o3Ser_001_.tif';...
               'NT0012_21dpf_f2_o3Ser_002_.tif';...
               'NT0012_21dpf_f2_o3Ser_003_.tif';...
               'NT0012_21dpf_f2_o4TCA_001_.tif';...
               'NT0012_21dpf_f2_o4TCA_002_.tif';...
               'NT0012_21dpf_f2_o4TCA_003_.tif';...
               'NT0012_21dpf_f2_o5GCA_001_.tif';...
               'NT0012_21dpf_f2_o5GCA_002_.tif';...
               'NT0012_21dpf_f2_o5GCA_003_.tif';...
               'NT0012_21dpf_f2_o6TDCA_001_.tif';...
               'NT0012_21dpf_f2_o6TDCA_002_.tif';...
               'NT0012_21dpf_f2_o6TDCA_003_.tif';...
               'NT0012_21dpf_f2_o7ACSF_001_.tif';...
               'NT0012_21dpf_f2_o7ACSF_002_.tif';...
               'NT0012_21dpf_f2_o7ACSF_003_.tif';...
               'NT0012_21dpf_f2_o8Spont_001_.tif';...
               'NT0012_21dpf_f2_o8Spont_002_.tif';...
               'NT0012_21dpf_f2_o8Spont_003_.tif'};

% Data processing configuration
% Directory for saving processing results
resultDir = 'W:\scratch\gfriedri\teminesi\2Photon_RawData\NT0012_2\20200604\f2\results';

% Directory for saving binned movies
binDir = 'W:\scratch\gfriedri\teminesi\2Photon_RawData\NT0012_2\20200604\f2\results\binned';

%% Step02 Initialize NrModel with experiment confiuration
myexp = NrModel(rawDataDir,rawFileList,resultDir,...
                expInfo);
%% Step03a (optional) Bin movies
% Bin movie parameters
binParam.shrinkFactors = [1, 1, 2];
binParam.trialOption = struct('process',true,'noSignalWindow',[1 4]);
binParam.depth = 8;
for planeNum=1:myexp.expInfo.nPlane
myexp.binMovieBatch(binParam,binDir,planeNum);
end
%% Step03b (optional) If binning has been done, load binning
%% parameters to experiment
%read from the binConfig file to get the binning parameters
binConfigFileName = 'binConfig.json';
binConfigFilePath = fullfile(binDir,binConfigFileName);
myexp.readBinConfig(binConfigFilePath);
%% Step04 Calculate anatomy maps
% anatomyParam.inFileType = 'raw';
%anatomyParam.trialOption = {'process',true,'noSignalWindow',[1 24]};
anatomyParam.inFileType = 'binned';
anatomyParam.trialOption = [];
for planeNum=1:myexp.expInfo.nPlane
    myexp.calcAnatomyBatch(anatomyParam,planeNum);
end
%% Step04b If anatomy map has been calculated, load anatomy
%% parameters to experiment
anatomyDir = myexp.getDefaultDir('anatomy');
anatomyConfigFileName = 'anatomyConfig.json';
anatomyConfigFilePath = fullfile(anatomyDir,anatomyConfigFileName);
myexp.readAnatomyConfig(anatomyConfigFilePath);
%% Step05 Align trial to template
templateRawName = myexp.rawFileList{10};
% plotFig = false;
% climit = [0 0.5];
for planeNum=1:myexp.expInfo.nPlane
    myexp.alignTrialBatch(templateRawName,...
                          'planeNum',planeNum,...
                          'alignOption',{'plotFig',false});
end
%% Save experiment configuration
expFileName = strcat('experimentConfig_',expInfo.name,'.mat');
expFilePath = fullfile(resultDir,expFileName);
save(expFilePath,'myexp')
