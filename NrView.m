classdef NrView < handle
    properties
        model
        controller
        guiHandles
    end
    
    methods
        function self = NrView(mymodel,mycontroller)
            self.model = mymodel;
            self.controller = mycontroller;
            self.guiHandles = neuRoiGui();
            
            self.updateFileListBox();
            % self.displayLoadMovieOption();
            
            self.listenToModel();
            self.displayResponseOption();
            self.displayResponseMaxOption();
            self.assignCallbacks();
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.fileListBox,'Callback',...
                @(s,e)self.controller.fileListBox_Callback(s,e));
            set(self.guiHandles.mainFig,'CloseRequestFcn',...
                @(s,e)self.controller.mainFigClosed_Callback(s,e));
            set(self.guiHandles.loadRangeGroup,'SelectionChangedFcn',...
             @(s,e)self.controller.loadRangeGroup_Callback(s,e));
            set(self.guiHandles.loadRangeStartText,'Callback',...
                @(s,e)self.controller.loadRangeText_Callback(s,e));
            set(self.guiHandles.loadRangeEndText,'Callback',...
                @(s,e)self.controller.loadRangeText_Callback(s,e));
            set(self.guiHandles.loadStepText,'Callback',...
                @(s,e)self.controller.loadStepText_Callback(s,e));
            
            % Callbacks for dF/F map
            set(self.guiHandles.resIntensityOffsetText,'Callback',...
              @(s,e)self.controller.resIntensityOffset_Callback(s,e));

            set(self.guiHandles.resFZeroStartText,'Callback',...
                @(s,e)self.controller.resFZero_Callback(s,e));
            set(self.guiHandles.resFZeroEndText,'Callback',...
                @(s,e)self.controller.resFZero_Callback(s,e));

            set(self.guiHandles.responseStartText,'Callback',...
               @(s,e)self.controller.responseWindow_Callback(s,e));
            set(self.guiHandles.responseEndText,'Callback',...
               @(s,e)self.controller.responseWindow_Callback(s,e));
            
            set(self.guiHandles.addResponseMapButton,'Callback',...
            @(s,e) self.controller.addMapButton_Callback(s,e));

            set(self.guiHandles.updateResponseMapButton,'Callback',...
            @(s,e) self.controller.updateMapButton_Callback(s,e));


            % Callbacks for max dF/F
            set(self.guiHandles.rmaxIntensityOffsetText,'Callback',...
              @(s,e)self.controller.rmaxIntensityOffset_Callback(s,e));

            set(self.guiHandles.rmaxFZeroStartText,'Callback',...
                @(s,e)self.controller.rmaxFZero_Callback(s,e));
            set(self.guiHandles.rmaxFZeroEndText,'Callback',...
                @(s,e)self.controller.rmaxFZero_Callback(s,e));
            
            set(self.guiHandles.rmaxSlidingWindowText,'Callback',...
                @(s,e)self.controller.rmaxSlidingWindow_Callback(s,e));

            set(self.guiHandles.addResponseMaxMapButton,'Callback',...
            @(s,e) self.controller.addMapButton_Callback(s,e));

            set(self.guiHandles.updateResponseMaxMapButton,'Callback',...
            @(s,e) self.controller.updateMapButton_Callback(s,e));

        end
        
        function listenToModel(self)
            addlistener(self.model,'rawFileList','PostSet',@self.updateFileListBox);
            addlistener(self.model,'responseOption','PostSet',...
                        @(s,e)self.displayResponseOption());
            addlistener(self.model,'responseMaxOption','PostSet',...
                        @(s,e)self.displayResponseMaxOption());
        end
        
        function updateFileListBox(self)
            rawFileList = self.model.rawFileList;
            fileNameArray = {};
            for k = 1:length(rawFileList)
                filePath = rawFileList{k};
                [~,fileNameArray{k},~] = fileparts(filePath);
            end
            set(self.guiHandles.fileListBox,'String',fileNameArray);
        end
        
        function displayLoadMovieOption(self)
            option = self.model.loadMovieOption;
            nFramePerStep = option.nFramePerStep;
            self.guiHandles.loadStepText.String = num2str(nFramePerStep);
            zrange = option.zrange;
            if isnumeric(zrange)
                self.guiHandles.loadRangeButton2.Value = 1;
                self.toggleLoadRangeText('on');
                self.setLoadRangeText(zrange);
            elseif strcmp(zrange,'all')
                self.guiHandles.loadRangeButton1.Value = 1;
                self.toggleLoadRangeText('off');
            else
                error('Cannot display load movie range!')
            end
        end
        
        function displayResponseOption(self)
            self.guiHandles.resIntensityOffsetText.String = ...
                num2str(self.model.responseOption.offset);
            self.guiHandles.resFZeroStartText.String = ...
                num2str(self.model.responseOption.fZeroWindow(1));
            self.guiHandles.resFZeroEndText.String = ...
                num2str(self.model.responseOption.fZeroWindow(2));
            self.guiHandles.responseStartText.String = ...
                num2str(self.model.responseOption.responseWindow(1));
            self.guiHandles.responseEndText.String = ...
                num2str(self.model.responseOption.responseWindow(2));
        end
        
        function displayResponseMaxOption(self)
            self.guiHandles.rmaxIntensityOffsetText.String = ...
                num2str(self.model.responseMaxOption.offset);
            self.guiHandles.rmaxFZeroStartText.String = ...
                num2str(self.model.responseMaxOption.fZeroWindow(1));
            self.guiHandles.rmaxFZeroEndText.String = ...
                num2str(self.model.responseMaxOption.fZeroWindow(2));
            self.guiHandles.rmaxSlidingWindowText.String = ...
            num2str(self.model.responseMaxOption.slidingWindowSize);
        end

        
        function toggleLoadRangeText(self,state)
            if strcmp(state,'on') || strcmp(state,'off')
                set(self.guiHandles.loadRangeStartText,'Enable',state);
                set(self.guiHandles.loadRangeEndText,'Enable',state);
            else
                error('The state should be ''on'' or ''off''');
            end
        end
        
        function setLoadRangeText(self,zrange)
            set(self.guiHandles.loadRangeStartText,'String', ...
                              num2str(zrange(1)));
            set(self.guiHandles.loadRangeEndText,'String', ...
                              num2str(zrange(2)));
        end
        
        function zrange = getLoadRangeFromText(self);
            zrange(1) = str2num(self.guiHandles.loadRangeStartText.String);
            zrange(2) = str2num(self.guiHandles.loadRangeEndText.String);
        end
        
        function deleteFigures(self)
            mainFig = self.guiHandles.mainFig;
            delete(mainFig);
        end
        
        function raiseMainWindow(self)
            mainFig = self.guiHandles.mainFig;
            figure(mainFig)
        end

        function displayError(self,errorStruct)
            self.guiHandles.errorDlg = errordlg(errorStruct.message,'NrController');
        end

    end
end
