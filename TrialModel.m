classdef TrialModel < handle
    properties
        filePath
        loadMovieOption
        preprocessOption

        yxShift
        intensityOffset

        fileBaseName
        tag
        name
        
        
        meta
        rawMovie
        
        roiArray
        resultDir
        roiFilePath
    end
        
    properties (Access = private)
        mapArray
    end
    
    properties (SetObservable)
        currentMapInd
        roiVisible
        selectedRoiTagArray
        syncTimeTrace
    end
    
    properties (Constant)
        MAX_N_ROI = 200
    end
    
    events
        mapArrayLengthChanged
        mapUpdated
        
        roiAdded
        roiDeleted
        roiUpdated
        roiArrayReplaced
        
        roiSelected
        roiUnSelected
        roiSelectionCleared
        
        trialDeleted
    end
    
    methods
        function self = TrialModel(filePath,varargin)
            defaultLoadMovieOption = struct('zrange','all',...
                                            'nFramePerStep',1);
            defaultPreprocessOption = struct('process',false);

            pa = inputParser;
            addRequired(pa,'filePath',@ischar);
            addOptional(pa,'zrange','all', @(s) ischar(s)|ismatrix(s));
            addOptional(pa,'nFramePerStep',1)
            addOptional(pa,'process',false);
            addOptional(pa,'noSignalWindow',[1 12]);
            validYxShift = @(x) isequal(size(x),[1 2]);
            addParameter(pa,'yxShift',[0 0],validYxShift);
            addParameter(pa,'intensityOffset',0);
            addParameter(pa,'resultDir',pwd());
            parse(pa,filePath,varargin{:})
            pr = pa.Results;
            
            self.filePath = pr.filePath;
            self.loadMovieOption = struct('zrange',pr.zrange,...
                                          'nFramePerStep', ...
                                          pr.nFramePerStep);
            self.preprocessOption = struct('process',pr.process,...
                                           'noSignalWindow',pr.noSignalWindow);
            if ~exist(self.filePath,'file')
                warning(['The file path does not exist! returning ' ...
                         'an TrialModel object with a random ' ...
                         'movie.'])
                [~,self.fileBaseName,~] = fileparts(filePath);
                self.name = self.fileBaseName;
                self.meta = struct('width',12,...
                                   'height',10,...
                                   'totalNFrame',5);
                self.rawMovie = rand(self.meta.height,...
                                     self.meta.width,...
                                     self.meta.totalNFrame);
            else
                [~,self.fileBaseName,~] = fileparts(self.filePath);
                self.name = ...
                    TrialModel.getDefaultTrialName(self.fileBaseName,pr.zrange,pr.nFramePerStep);
                
                % Read data from file
                self.meta = movieFunc.readMeta(self.filePath);
                self.loadMovie(self.filePath,self.loadMovieOption);
                
                if self.preprocessOption.process
                    self.preprocessMovie(self.preprocessOption.noSignalWindow);
                end
                
                if pr.resultDir
                    self.resultDir = pr.resultDir;
                end
            end
            
            % Intensity offset for calculating dF/F
            self.intensityOffset = pr.intensityOffset;
            
            % shift movie in x and y axis
            self.yxShift = [0 0];
            if pr.yxShift
                self.shiftMovieYx(pr.yxShift)
            end

            
            % Initialize map array
            self.mapArray = {};

            % Calculate anatomy map
            self.calculateAndAddNewMap('anatomy');
            
            % Initialize ROI array
            self.roiVisible = true;
            self.roiArray = RoiFreehand.empty();
            
        end
        
        function loadMovie(self,filePath,loadMovieOption)
            if ~isnumeric(self.loadMovieOption.zrange)
                if strcmp(self.loadMovieOption.zrange,'all')
                    self.loadMovieOption.zrange = ...
                        [1,self.meta.totalNFrame];
                end
            end
            
            disp(loadMovieOption)
            disp('Loading movie ...')
            
            self.rawMovie = movieFunc.readMovie(filePath,...
                                      self.meta,...
                                      self.loadMovieOption.zrange,...
                                      self.loadMovieOption.nFramePerStep);
        end
        
        function nf = getNFrameRawMovie(self)
            nf = size(self.rawMovie,3);
        end
        
        function preprocessMovie(self,noSignalWindow)
            if ~exist('noSignalWindow','var')
                noSignalWindow = [1, 12];
            end
            self.rawMovie = movieFunc.subtractPreampRing(self.rawMovie,noSignalWindow);
        end
        
        function shiftMovieYx(self,yxShift)
            disp('Shift movie by yxShift')
            disp(yxShift)
            self.yxShift = self.yxShift+yxShift;
            self.rawMovie = circshift(self.rawMovie,[yxShift 0]);
            nMap = self.getMapArrayLength();
            for k=1:nMap
                map = self.getMapByInd(nMap);
                map.data = circshift(map.data,yxShift);
                self.mapArray{k} = map;
                notify(self,'mapUpdated', ...
                   NrEvent.ArrayElementUpdateEvent(k));
            end

        end

        function transfromMovie2D(self,tform)
        end
        
        
        function mapSize = getMapSize(self)
            mapSize = size(self.rawMovie(:,:,1));
        end
        
        function map = getMapByInd(self,ind)
            map = self.mapArray{ind};
        end
        
        function mapArrayLen = getMapArrayLength(self)
            mapArrayLen = length(self.mapArray);
        end
        
        function map = getCurrentMap(self)
            map = self.mapArray{self.currentMapInd};
        end
        
        function map = calculateAndAddNewMap(self,mapType,varargin)
            map.type = mapType;
            [map.data,map.option] = self.calculateMap(mapType,varargin{:});
            self.addMap(map);
        end
        
        function findAndUpdateMap(self,mapType,mapOption)
            mapInd = find(cellfun(@(x) strcmp(x.type,mapType),self.mapArray));
            mapInd = mapInd(1);
            self.updateMap(mapInd,mapOption);
        end
            
        function selectMap(self,ind)
            self.currentMapInd = ind;
        end
        
        function addMap(self,newMap)
            self.mapArray{end+1} = newMap;
            mapArrayLen = self.getMapArrayLength();
            self.selectMap(mapArrayLen);
            notify(self,'mapArrayLengthChanged');
        end
        
        function deleteMap(self,mapInd)
            self.mapArray(mapInd) = [];
            notify(self,'mapArrayLengthChanged');
        end
        
        function updateMap(self,mapInd,mapOption)
            map = self.mapArray{mapInd};
            [map.data,map.option] = self.calculateMap(map.type,mapOption);
            self.mapArray{mapInd} = map;
            notify(self,'mapUpdated',NrEvent.ArrayElementUpdateEvent(mapInd));
        end
        
        function importMap(self,mapFilePath)
            map.type = 'import';
            [~,map.option.fileName,~] = fileparts(mapFilePath);
            
            TifLink = Tiff(mapFilePath, 'r');
            map.data = TifLink.read();
            self.addMap(map);
        end
        
        function saveContrastLimToCurrentMap(self,contrastLim)
            self.mapArray{self.currentMapInd}.contrastLim = ...
                contrastLim;
        end
        
        function [mapData,mapOption] = calculateMap(self,mapType,varargin)
            switch mapType
              case 'anatomy'
                [mapData,mapOption] = self.calcAnatomy(varargin{:});
              case 'response'
                [mapData,mapOption] = self.calcResponse(varargin{:});
              case 'responseMax'
                [mapData,mapOption] = self.calcResponseMax(varargin{:});
              case 'localCorrelation'
                [mapData,mapOption] = self.calcLocalCorrelation(varargin{:});
            end
        end

        function [mapData,mapOption] = calcAnatomy(self,varargin)
        % Method to calculate anatomy map
        % Usage: anatomyMap = nrmodel.calcAnatomy([nFrameLimit])
        % nFrameLimit: 1x2 array of two integers that specify the
        % beginning and end number of frames used to calculate the
        % anatomy.
            pp = inputParser;
            
            defaultNFrameLimit = [1 size(self.rawMovie,3)];
            addOptional(pp,'nFrameLimit',defaultNFrameLimit);
            addParameter(pp,'sigma',0);
            
            parse(pp,varargin{:});
            pr = pp.Results;
            
            nFrameLimit = pr.nFrameLimit;
            if ~(length(nFrameLimit) && nFrameLimit(2)>= ...
                 nFrameLimit(1))
                error(['nFrameLimit should be an 1x2 integer array with ' ...
                       '2nd element bigger that the 1st one.']);
            end
            if nFrameLimit(1)<1 || nFrameLimit(2)>size(self.rawMovie,3)
                error(sprintf(['nFrameLimit [%d, %d] exceeded ' ...
                               'the frame number of the movie %d'],[nFrameLimit, size(self.rawMovie,3)]));
            end
            
            mapData = mean(self.rawMovie(:,:,nFrameLimit(1): ...
                                            nFrameLimit(2)),3);
            if pr.sigma
                mapData = conv2(mapData,fspecial('gaussian',[3 3], pr.sigma),'same');
                mapOption.sigma = pr.sigma;
            end
            mapOption.nFrameLimit = nFrameLimit;
        end
        
        function [mapData,mapOption] = calcResponse(self,varargin)
        % Method to calculate response map (dF/F)
        % Usage: 
        % mymodel.calcResponse(offset,fZeroWindow,responseWindow) 
        % mymodel.calcResponse(mapOption)
        % mapOption is a structure that contains
        % offset,fZeroWindow,responseWindow in its field
            if nargin == 2
                mapOption = varargin{1};
            elseif nargin == 4
                mapOption = struct('offset',varargin{1}, ...
                                       'fZeroWindow',varargin{2}, ...
                                       'responseWindow', ...
                                       varargin{3});
            else
                error('Wrong usage!')
                help TrialModel.calcResponse
            end
            
            mapData = movieFunc.dFoverF(self.rawMovie,mapOption.offset, ...
                              mapOption.fZeroWindow, ...
                              mapOption.responseWindow);
        end
        
        function [mapData,mapOption] = calcResponseMax(self, ...
                                                       varargin)
            if nargin == 2
                mapOption = varargin{1};
            elseif nargin == 4
                mapOption = struct('offset',varargin{1}, ...
                                   'fZeroWindow',varargin{2}, ...
                                   'slidingWindowSize', ...
                                       varargin{3});
            else
                error('Wrong Usage!')
            end
            mapData = movieFunc.dFoverFMax(self.rawMovie,mapOption.offset,...
                                 mapOption.fZeroWindow,...
                                 mapOption.slidingWindowSize);
        end
        
        function [mapData,mapOption] = calcLocalCorrelation(self, ...
                                                            varargin)
            if nargin == 2
                if isstruct(varargin{1})
                    mapOption = varargin{1};
                else
                    mapOption.tileSize = varargin{1};
                end
            else
                error('Wrong Usage!');
            end
            mapData = movieFunc.computeLocalCorrelation(self.rawMovie,mapOption.tileSize);
        end
        
        % Methods for ROI-based processing
        % TODO set roiArray to private
        function addRoi(self,varargin)
        % ADDROI add ROI to ROI array
        % input arguments can be a RoiFreehand object
        % or a structure containing position and imageSize
            
            if nargin == 2
                if isa(varargin{1},'RoiFreehand')
                    roi = varargin{1};
                elseif isstruct(varargin{1})
                    % Add ROI from structure
                    roiStruct = varargin{1};
                    roi = RoiFreehand(roiStruct);
                else
                    % TODO add ROI from mask
                    error('Wrong usage!')
                    help TrialModel.addRoi
                end
            else
                error('Wrong usage!')
                help TrialModel.addRoi
            end
            
            nRoi = length(self.roiArray);
            if nRoi >= self.MAX_N_ROI
                error('Maximum number of ROIs exceeded!')
            end
            
            self.checkRoiImageSize(roi);

            if isempty(self.roiArray)
                roi.tag = 1;
            else
                roi.tag = self.roiArray(end).tag+1;
            end
            self.roiArray(end+1) = roi;
            
            notify(self,'roiAdded')
        end
        
        function selectSingleRoi(self,varargin)
            if nargin == 2
                if strcmp(varargin{1},'last')
                    ind = length(self.roiArray);
                    tag = self.roiArray(ind).tag;
                else
                    tag = varargin{1};
                    ind = self.findRoiByTag(tag);
                end
            else
                error('Too Many/few input args!')
            end
            
            if ~isequal(self.selectedRoiTagArray,[tag])
                self.unselectAllRoi();
                self.selectRoi(tag);
            end
        end
        
        function selectRoi(self,tag)
            if ~ismember(tag,self.selectedRoiTagArray)
                ind = self.findRoiByTag(tag);
                self.selectedRoiTagArray(end+1)  = tag;
                notify(self,'roiSelected',NrEvent.RoiEvent(tag));
                disp(sprintf('ROI #%d selected',tag))
            end
        end
        
        function unselectRoi(self,tag)
            tagArray = self.selectedRoiTagArray;
            tagInd = find(tagArray == tag);
            if tagInd
                self.selectedRoiTagArray(tagInd) = [];
                notify(self,'roiUnSelected',NrEvent.RoiEvent(tag));
            end
        end
        
        function selectAllRoi(self)
        % TODO
        end
        
        function unselectAllRoi(self)
            self.selectedRoiTagArray = [];
            notify(self,'roiSelectionCleared');
        end
        
        function updateRoi(self,tag,varargin)
            ind = self.findRoiByTag(tag);
            oldRoi = self.roiArray(ind);
            freshRoi = RoiFreehand(varargin{:});
            freshRoi.tag = tag;
            self.checkRoiImageSize(freshRoi);
            self.roiArray(ind) = freshRoi;

            notify(self,'roiUpdated', ...
                   NrEvent.RoiUpdatedEvent(self.roiArray(ind)));
            disp(sprintf('Roi #%d updated',tag))
        end
        
        function deleteSelectedRoi(self)
            tagArray = self.selectedRoiTagArray;
            self.unselectAllRoi();
            indArray = self.findRoiByTagArray(tagArray);
            self.roiArray(indArray) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent(tagArray));
        end
        
        function deleteRoi(self,tag)
            ind = self.findRoiByTag(tag);
            self.unselectRoi(tag);
            self.roiArray(ind) = [];
            notify(self,'roiDeleted',NrEvent.RoiDeletedEvent([tag]));
        end
        
        function roiArray = getRoiArray(self)
            roiArray = self.roiArray;
        end
        
        function roi = getRoiByTag(self,tag)
            if strcmp(tag,'end')
                roi = self.roiArray(end);
            else
                ind = self.findRoiByTag(tag);
                roi = self.roiArray(ind);
            end
        end
        
        function saveRoiArray(self,filePath)
            roiArray = self.roiArray;
            save(filePath,'roiArray');
        end
        
        function loadRoiArray(self,filePath,option)
            foo = load(filePath);
            roiArray = foo.roiArray;
            nRoi = length(roiArray);
                if nRoi >= self.MAX_N_ROI
                    error('Maximum number of ROIs exceeded!')
                end
            if strcmp(option,'merge')
                arrayfun(@(x) self.addRoi(x),roiArray);
            elseif strcmp(option,'replace')
                self.roiArray = roiArray;
                notify(self,'roiArrayReplaced');
            end
        end
        
        function checkRoiImageSize(self,roi)
            mapSize = self.getMapSize();
            if ~isequal(roi.imageSize,mapSize)
                error(['Image size of ROI does not match the map size ' ...
                       '(pixel size in x and y)!'])
            end
        end
        
        function ind = findRoiByTag(self,tag)
            ind = find(arrayfun(@(x) isequal(x.tag,tag), ...
                                self.roiArray),1);
            if ~isempty(ind)
                ind = ind(1);
            else
                error(sprintf('Cannot find ROI with tag %d!',tag))
            end
        end
        
        function roiIndArray = findRoiByTagArray(self,tagArray)
            roiIndArray = arrayfun(@(x) self.findRoiByTag(x), ...
                                   tagArray);
        end
        
        % Methods for time trace
        function timeTrace = getTimeTraceByTag(self,tag,varargin)
            if nargin == 2
                sm = false;
            elseif nargin == 3
                sm = varargin{1};
            end

            ind = self.findRoiByTag(tag);
            roi = self.roiArray(ind);
            timeTrace = TrialModel.getTimeTrace(self.rawMovie,roi,...
                                                self.intensityOffset,sm);
        end
        
        function [timeTraceMat,roiTagArray] = ...
                extractTimeTraceMat(self,varargin)
            if nargin == 1
                % intensityOffset does not change
            elseif nargin ==2
                self.intensityOffset = varargin{2};
            end
            nRoi = length(self.roiArray);
            timeTraceMat = zeros(nRoi,size(self.rawMovie,3));
            roiTagArray = zeros(1,nRoi);
            for k=1:nRoi
                roi = self.roiArray(k);
                timeTrace = TrialModel.getTimeTrace(self.rawMovie,roi,...
                                       self.intensityOffset);
                timeTraceMat(k,:) = timeTrace;
                roiTagArray(k) = roi.tag;
            end
        end
        
        
    end
    
    methods
        function delete(self)
            notify(self,'trialDeleted');
        end
    end
    
    methods (Static)        
        function timeTraceDf = getTimeTrace(rawMovie,roi,varargin)
        % GETTIMETRACE get time trace of dF/F within a ROI
        % from the input raw movie
        % Usage: getTimeTrace(rawMovie,roi,[intensityOffset])
            
            if nargin == 2
                intensityOffset = 0;
                sm = false;
            elseif nargin == 3
                intensityOffset = varargin{1};
                sm = false;
            elseif nargin == 4
                intensityOffset = varargin{1};
                sm = varargin{2};
            else
                error('Usage: getTimeTrace(rawMovie,roi,[intensityOffset])')
            end
            
            mask = roi.createMask;
            [maskIndX maskIndY] = find(mask==1);
            roiMovie = rawMovie(maskIndX,maskIndY,:);
            timeTraceRaw = mean(mean(roiMovie,1),2);
            timeTraceRaw =timeTraceRaw(:);

            timeTraceFg = timeTraceRaw - intensityOffset;
            if sm
                timeTraceSm = smooth(timeTraceFg,10);
                fZero = quantile(timeTraceSm(10:end-10),0.1);
                
                % Time trace of dF/F, unit in percent
                timeTraceDf = (timeTraceSm - fZero) / fZero;
            else
                fZero = quantile(timeTraceRaw(10:end-10),0.15);
                
                % Time trace of dF/F, unit in percent
                timeTraceDf = (timeTraceRaw - fZero) / fZero;
            end
        end
        
        function dfName = getDefaultTrialName(fileBaseName,zrange, ...
                                                           nFramePerStep)
            dfName = sprintf('%s_frame%dto%dby%d',fileBaseName, ...
                             zrange(1),zrange(2),nFramePerStep);
        end
                

    end
end
