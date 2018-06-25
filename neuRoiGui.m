function handles = neuRoiGui(varargin)
% NEUROIGUI creates a gui for drawing ROI on two-phonton imaging
% movies.

    handles = {};

    handles.mainFig = figureDM('Position',[600,300,700,600]); % figureDM is a
                                                % function to
                                                % create figure on dual monitor by Jan
    handles.mapAxes = axes('Position',[0.2,0.1,0.7,0.7]);

    handles.anatomyButton  = uicontrol('Style','pushbutton',...
                               'String','Anatomy',...
                               'Units','normal',...
                               'Position',[0.2,0.8,0.1,0.08]);
    
    handles.responseButton  = uicontrol('Style','pushbutton',...
                               'String','dF/F',...
                               'Units','normal',...
                               'Position',[0.3,0.8,0.1,0.08]);
    
    handles.addRoiButton  = uicontrol('Style','togglebutton',...
                              'String','Add ROI',...
                              'Units','normal',...
                              'Position',[0.05,0.7,0.1,0.08]);
    
    % Sliders for contrast adjustment
    handles.contrastMinSlider = uicontrol('style','slider','Units','normal','position',[0.5 0.9 0.25 0.04]);
    handles.contrastMaxSlider = uicontrol('style','slider','Units','normal','position',[0.5 0.8 0.25 0.04]);
    
    handles.traceFig = figureDM('Name','Time Trace','Tag','traceFig',...
                                'Position',[50,500,500,400],'Visible','off');
    handles.traceAxes = axes();
    figure(handles.mainFig)
end
