classdef NrView < handle
% NRVIEW view class for neuRoi
% Usage: myview = NrView(controller,fileBaseName,mapSize)
% controller: an NrController object
% fileBaseName: the base name of data file to be displayed in the
% title line
% mapSize: 1 x2 array that specifies the number of pixels in x and
% y direction (equal to size(rawMovie(:,:,1)))
    properties
        model
        controller
        
        guiHandles
        currentMapName
        contrastLimStc
        unselectedRoiColor
    end
    
    methods
        function self = NrView(controller,fileBaseName,mapSize)
            self.controller = controller;
            self.guiHandles = neuRoiGui(mapSize);
            self.guiHandles.mainFig.Name = fileBaseName;
            self.guiHandles.traceFig.Name = [fileBaseName,'_time_trace'];

            self.unselectedRoiColor = 'red';

            self.assignCallbacks();
            self.addListners();
            
            % self.plotMap('anatomy');
            % self.currentMapName = 'anatomy';
            % self.contrastLimStc = self.initContrastLimStc();
        end
        
        function contrastLimStc = initContrastLimStc(self)
            contrastLimStc.anatomy = minMax(self.model.mapArray{1}.data);
            contrastLimStc.response = ...
                minMax(self.model.mapArray{2}.data);
        end
                
        function addListners(self)
            
            % addlistener(self.model,'currentRoi','PostSet', ...
            %             @(src,evnt)NrView.updateCurrentRoiDisplay(self,src,evnt));
            
            % addlistener(self.model,'currentTimeTrace','PostSet', ...
            %             @(src,evnt)NrView.plotTimeTrace(self,src, ...
            %                                              evnt));

            % TODO
            % addlistener(self.controller,'timeTraceState','PostSet', ...
            %             @(src,evnt)NrView.plotTimeTrace(self,src, ...
            %                                              evnt));

            addlistener(self.controller,'roiDisplayState','PostSet', ...
                        @(src,evnt)NrView.toggleRoiDisplay(self,src, ...
                                                         evnt));

            % Listen to mapImage CData and update contrast slider limits
            % addlistener(self.guiHandles.mapImage,'CData','PostSet', ...
            %             @(src,evnt)NrView.updateContrastSliders(self,src,evnt));
            
            % Listen to contrast slider value and update mapImage
            % color map (caxis)
            % addlistener(self.guiHandles.contrastMinSlider,'Value','PostSet',...
            %             @(src,evnt)NrView.adjustContrast(self,src,evnt));
            % addlistener(self.guiHandles.contrastMaxSlider,'Value','PostSet',...
            %             @(src,evnt)NrView.adjustContrast(self,src,evnt));
        end
        
        function assignCallbacks(self)
            set(self.guiHandles.mapButtonGroup,'SelectionChangedFcn',...
                @(src,evnt)self.mapButtonSelected_Callback(src,evnt))
            
            set(self.guiHandles.addRoiButton,'Callback',...
                @(src,evnt)self.addRoi_Callback(src,evnt));
            % set(self.gui,'CloseRequestFcn',@(src,evnt)...
            %              self.controller.closeGUI(src,evnt));
            set(self.guiHandles.mainFig,'WindowKeyPressFcn', ...
                              @(src,evnt)self.keyPressCallback(src,evnt));
            
            set(self.guiHandles.traceFig,'WindowKeyPressFcn',@(src,evnt)...
                         self.keyPressCallback(src,evnt));
            set(self.guiHandles.mainFig,'WindowButtonDownFcn',...
                @(src,evnt)self.selectRoi_Callback(src,evnt));
            set(self.guiHandles.traceFig,'CloseRequestFcn', ...
                              @(src,evnt)self.closeTraceFig(src, ...
                                                             evnt));
            
        end
                
    end

    % Methods for displaying maps
    methods
        function selectMapButton(self,ind)
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            mapButtonGroup.SelectedObject = mapButtonArray(end+1-ind);
        end

        function toggleMapButtonValidity(self,nActiveButton)
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            for k=1:length(mapButtonArray)
                mb = mapButtonArray(end+1-k);
                if k <= nActiveButton
                    mb.Enable = 'on';
                else
                    mb.Enable = 'off';
                end
            end
        end

        function displayMap(self,map)
            self.showMapOption(map);
            self.plotMap(map);
        end
        
        function showMapOption(self,map)
            optionStr = NrView.convertOptionToString(map.option);
            self.guiHandles.mapOptionText.String = optionStr;
        end
        
        function plotMap(self,map)
            mapAxes = self.guiHandles.mapAxes;
            mapImage = self.guiHandles.mapImage;
            switch map.type
              case 'anatomy'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,gray);
              case 'response'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
              case 'responseMax'
                set(mapImage,'CData',map.data);
                colormap(mapAxes,'default');
            end
        end
            
        function enableMapOptionPanel(self,map)
            disp(sprintf('showMapOptionPanel: %s',map.type));
        end
        
        function ind = getCurrentMapInd(self)
            tag = self.mapButtonGroup.SelectedObject.Tag;
            ind = convertTagToInd(tag,'mapButton');
        end
        
        function nMapButton = getNMapButton(self)
            mapButtonGroup = self.guiHandles.mapButtonGroup;
            mapButtonArray = mapButtonGroup.Children;
            nMapButton = length(mapButtonArray);
        end
    end
    
    % Callbacks for maps
    methods
        function addMapButton_Callback()
            self.controller.addMap(type,option);
        end
        
        function mapButtonSelected_Callback(self,src,event)
            tag = event.NewValue.Tag;
            ind = NrView.convertTagToInd(tag,'mapButton');
            self.controller.selectMap(ind);
        end
        
        function deleteCurrentMapButton_Callback()
            ind = getCurrentMapInd(self);
            self.controller.deleteCurrentMap(ind);
        end
        
        function updateCurrentMap_Callback()
            ind = getCurrentMapInd(self);
            self.controller.updateCurrentMap(ind,option);
        end
    end
    
    methods
        function switchMap_Callback(self,newMapName)
            if ~strcmp(self.currentMapName,newMapName)
                currentContrastLim = self.getCurrentContrastLim();
                self.contrastLimStc = setfield(self.contrastLimStc, ...
                                               self.currentMapName,currentContrastLim);
                self.currentMapName = newMapName;
                self.plotMap(newMapName);
                contrastLim = getfield(self.contrastLimStc,self.currentMapName);
                self.setCurrentContrastLim(contrastLim);
            end
        end
        
        function addRoi_Callback(self,src,evnt)
            self.controller.addRoiInteract();
        end
        
        function selectRoi_Callback(self,src,evnt)
            selectionType = get(gcf,'SelectionType');
            if strcmp(selectionType,'normal')
                self.controller.selectSingleRoi();
            elseif strcmp(selectionType,'alt') % Ctrl pressed
                self.controller.selectMultRoi_Callback();
            end
        end
        
        function deleteRoi_Callback(self,src,evnt)
            self.controller.deleteRoi();
        end
        
        function keyPressCallback(self,src,evnt)
            if strcmp(src.Tag,'traceFig')
                figure(self.guiHandles.mainFig)
            end
            if isempty(evnt.Modifier)
                switch evnt.Key
                  case 'q'
                    self.switchMap_Callback('anatomy')
                  case 'w'
                    self.switchMap_Callback('response')
                  case 'r'
                    self.controller.toggleRoiDisplayState()
                  case 'f'
                    self.addRoi_Callback()
                  case 'd'
                    self.deleteRoi_Callback()
                end
            elseif strcmp(evnt.Modifier,'control')
                switch evnt.Key
                  case 'a'
                    self.controller.selectAllRoi();
                end
            end
        end
        
        function closeMainFig(self,src,evnt)
        % TODO
        end
        
        function closeTraceFig(self,src,evnt)
            if isvalid(self.guiHandles.mainFig)
                src.Visible = 'off';
            else
                delete(src)
            end
        end
    end

    methods
        function contrastLim = getCurrentContrastLim(self)
            minSliderVal = get(self.guiHandles.contrastMinSlider, ...
                               'Value');
            maxSliderVal = get(self.guiHandles.contrastMaxSlider, ...
                               'Value');
            contrastLim = [minSliderVal,maxSliderVal];
        end
        
        function setCurrentContrastLim(self,contrastLim)
            set(self.guiHandles.contrastMinSlider,'Value',contrastLim(1));
            set(self.guiHandles.contrastMaxSlider,'Value',contrastLim(2));
        end
        
        % Methods for viewing ROIs
        function roiPatch = addRoiPatch(self,roi)
            roiPatch = createRoiPatch(roi,self.guiHandles.mapAxes, ...
                           self.unselectedRoiColor);
        end
        
        function selectRoiPatch(self,roiPatch)
            roiPatch.Selected = 'on';
        end
        
        function unselectRoiPatch(self,roiPatch)
            roiPatch.Selected = 'off';
        end
        
        function selectSingleRoiPatch(self,slRoiPatch)
            slTag = get(slRoiPatch,'Tag');
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                tag = get(roiPatch,'Tag');
                if strcmp(tag,slTag)
                    roiPatch.Selected = 'on';
                else
                    roiPatch.Selected = 'off';
                end
            end
        end
        
        function unselectAllRoiPatch(self)
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                roiPatch.Selected = 'off';
            end
        end
        
        function deleteRoiPatch(self,roiPatch)
            delete(roiPatch)
        end
                
        function roiPatchArray = getRoiPatchArray(self)
            mapAxes = self.guiHandles.mapAxes;
            children = mapAxes.Children;
            patchInd = arrayfun(@isaRoiPatch,children);
            roiPatchArray = children(patchInd);
        end
        
        function slRoiPatchArray = getSelectedRoiPatchArray(self)
            mapAxes = self.guiHandles.mapAxes;
            children = mapAxes.Children;
            patchInd = arrayfun(@(x) isaRoiPatch(x) && ...
                                strcmp(x.Selected,'on'),children);
            
            slRoiPatchArray = children(patchInd);
        end
        
        
        function holdTraceAxes(self,holdState)
            hold(self.guiHandles.traceAxes,holdState)
        end
        
        function plotTimeTrace(self,trace,roiId)
            traceFig = self.guiHandles.traceFig;                
            traceFig.Visible = 'on';
            figure(traceFig)
            if ~isempty(trace)
                if strcmp(self.controller.timeTraceState,'raw')
                    plot(trace{1},'Tag',sprintf('trace_%04d',roiId));
                elseif strcmp(self.controller.timeTraceState,'dfOverF')
                    plot(trace{2},'Tag',sprintf('trace_%04d',roiId));
                else
                    error('Wrong timeTraceState in Controller!')
                end
            else
                cla(traceFig.CurrentAaxes)
            end
            figure(self.guiHandles.mainFig)
        end
        
        function deleteTraceLine(self,roiId)
            traceAxes = self.guiHandles.traceAxes;
            tag = sprintf('trace_%04d',roiId);
            lineInd = find(arrayfun(@(x) strcmp(x.Tag,tag), ...
                                    traceAxes.Children));
            if lineInd
                delete(traceAxes.Children(lineInd));
            end
        end

    end
    
    
    methods (Static)
        function optionStr = convertOptionToString(option)
            nameArray = fieldnames(option);
            stringArray = {};
            for i = 1:length(nameArray)
                name = nameArray{i};
                value = option.(name);
                stringArray{i} = sprintf('%s: %s',name,mat2str(value));
            end
            optionStr = [sprintf(['%s; '],stringArray{1:end-1}), ...
                         stringArray{end}];
                
        end
            
        function ind = convertTagToInd(tag,prefix)
            indStr = regexp(tag,[prefix '_(\d+)'],'tokens');
            ind = str2num(indStr{1}{1});
        end
        
        function updateMapDisplay(self,src,evnt)
            preContrastLim = self.getCurrentContrastLim();
            switch src.Name
              case 'anatomyMap'
                if strcmp(self.currentMapName,'anatomy')
                    self.plotMap('response');
                end
              case 'responseMap'
                if strcmp(self.currentMapName,'response')
                    self.plotMap('response');
                end
            end
            minCData = self.guiHandles.contrastMinSlider.Min;
            maxCData = self.guiHandles.contrastMinSlider.Max;
            postContrastLim = [min(max(preContrastLim(1),minCData),maxCData), ...
                               max(min(preContrastLim(2),maxCData),minCData)];
            self.setCurrentContrastLim(postContrastLim);
        end
        
        
        
        % function updateCurrentRoiDisplay(self,src,evnt)
        % % TODO current roi display after adding new            
        %     evntObj = evnt.AffectedObject;
        %     currentRoi = evntObj.currentRoi;
            
        %     if ~isempty(currentRoi)
        %         roiPatchArray = self.getRoiPatchArray();
        %         for i=1:length(roiPatchArray)
        %             roiPatch = roiPatchArray(i);
        %             roiHandle = getappdata(roiPatch,'roiHandle');
        %             if roiHandle == currentRoi
        %                 self.currentRoiPatch = roiPatch;
        %                 set(roiPatch,'Facecolor','red')
        %             else
        %                 set(roiPatch,'Facecolor',self.unselectedRoiColor)
        %             end
        %         end
        %     else
        %         if ~isempty(self.currentRoiPatch)
        %             set(self.currentRoiPatch,'Facecolor',self.unselectedRoiColor)
        %         end
        %     end
        % end

        function toggleRoiDisplay(self,src,evnt)
            affectedObj = evnt.AffectedObject;
            roiDisplayState = affectedObj.roiDisplayState;
            if roiDisplayState
                visibility = 'on';
            else
                visibility = 'off';
            end
            
            roiPatchArray = self.getRoiPatchArray();
            for i=1:length(roiPatchArray)
                roiPatch = roiPatchArray(i);
                set(roiPatch,'Visible',visibility);
            end
        end
        
        function updateContrastSliders(self,src,evnt)
            himage = evnt.AffectedObject;
            cdata = get(himage,'CData');
            cdlim = minMax(cdata);
            set(self.guiHandles.contrastMinSlider,'Min',cdlim(1), ...
                              'Max',cdlim(2),'Value',cdlim(1));
            set(self.guiHandles.contrastMaxSlider,'Min',cdlim(1), ...
                              'Max',cdlim(2),'Value',cdlim(2));
        end
        
        function adjustContrast(self,src,evnt)
            contrastLim = self.getCurrentContrastLim();
            if contrastLim(1) < contrastLim(2)
                caxis(self.guiHandles.mapAxes,contrastLim);
            end
        end
        
    end
end    
