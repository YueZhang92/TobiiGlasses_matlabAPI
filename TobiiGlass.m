% TobiiGlass class contains functions for running Tobii Pro2
% Glasses.
% 1. import the class into any scripts, to run Tobii at the same time with
% behavoural/EEG task:
% 2. call functions to operate the glasses;
% 3. retrieve Tobii status and codes for .json data files in Tobii SD card.
% See listenPupil.m for a running example.
% Yue 2018-03-29
% Calibration changed to dlg instead of input to block in-experiment
% calibration; Calibration lines updated at the end to allow for several
% calibrations in one epxeriment
% Yue 20180703

classdef TobiiGlass
    properties
        GlassURL % URL address of Tobii
        codes % test-related info 
        opts %data type options
        screen %any screen display needed
        dummy %to use TobiiGlasses or not (for debug purposes)
    end
    properties (SetAccess=private, GetAccess=public)
        TobiiStatus
    end
    
    methods
        % to check whether glasses are connected
        function obj = isconnected(obj)
            if ~isempty(webread([obj.GlassURL '/api/system/status']))
                sys = webread([obj.GlassURL '/api/system/status']);
                obj.TobiiStatus = sys.sys_status;
            else 
                obj.TobiiStatus = 'Not connected: check computer network or Glasses battery.';
            end
        end
        
        % to config glasses settigns
        function obj = setups(obj, propName, propSet, doprint)
            if ~isempty(propSet)
                setInfo = webwrite([obj.GlassURL '/api/system/conf'],struct(propName, propSet),obj.opts);
                if doprint == 1
                    disp(setInfo);
                end
            else 
                disp('No setups to perform.');
            end
            
        end
        
        %to setup new project, with project information
        function obj = newproject(obj,varargin)
            projInfo = webwrite([obj.GlassURL '/api/projects'],{},obj.opts);
            %to update project details
            if length(varargin)>1
                for index=1:2:length(varargin)
                    if length(varargin) < index+1
                        break;
                    elseif strcmp('Name', varargin{index})
                        projName = char(varargin{index+1});
                    elseif strcmp('Notes',varargin{index})
                        projNotes = char(varargin{index+1});
                    elseif strcmp('xid',varargin{index})
                        projID = char(varargin{index+1});
                    else
                        error('Illegal options');
                    end
                    
                end
            end
            projInfo = webwrite([obj.GlassURL '/api/projects/' projInfo.pr_id],struct('pr_info',struct('Name',projName, 'Notes',projNotes,'xid',projID)),obj.opts);
            
            obj.TobiiStatus = ['Project ' projInfo.pr_id ' created and updated.'];
            obj.codes= struct('project',projInfo.pr_id);
        end
        
        %to create new participant under certain project
        function obj = newpart(obj, varargin)
            parInfo = webwrite([obj.GlassURL '/api/participants'],struct('pa_project',obj.codes.project),obj.opts);
            %to update project details
            if length(varargin)>1
                for index=1:2:length(varargin)
                    if length(varargin) < index+1
                        break;
                    elseif strcmp('Name', varargin{index})
                        parName = char(varargin{index+1});
                    elseif strcmp('Notes',varargin{index})
                        parNotes = char(varargin{index+1});
                    else
                        error('Illegal options');
                    end
                    
                end
            end
            parInfo = webwrite([obj.GlassURL '/api/participants/' parInfo.pa_id],struct('pa_info',struct('Name',parName,'Notes',parNotes)),obj.opts);
            
            obj.TobiiStatus = ['Participant ' parInfo.pa_id ' in project ' obj.codes.project ' created and updated.'];
            obj.codes = setfield(obj.codes, 'participant', parInfo.pa_id);
        end
        
        % to calibrate certain participant until successful
        function [obj,success] = calib(obj)
            while ~strcmp(obj.TobiiStatus, 'calibrated')
                answer =inputdlg('Calibration take: ','s');
                calTry = str2num(answer{1});
                if calTry > 4 %give up after certain number of tryes
                    disp('Something is very wrong with the eyes...');
                    break;
                end
                calInfo = webwrite([obj.GlassURL '/api/calibrations'],struct('ca_participant',obj.codes.participant,'ca_type','default'),obj.opts);
                webwrite([obj.GlassURL, '/api/calibrations/' calInfo.ca_id '/start'],{},obj.opts);
                obj.TobiiStatus = calInfo.ca_state;
                while ~strcmp(obj.TobiiStatus, 'calibrated')
                    disp('Calibrating...')
                    pause(0.1);
                    calInfo = webread([obj.GlassURL, '/api/calibrations/' calInfo.ca_id '/status']);
                    obj.TobiiStatus = calInfo.ca_state;
                    if strcmp(obj.TobiiStatus,'failed')
                        obj.TobiiStatus = calInfo.ca_error;
                        success=0;
                        break;
                    end 
                end
            end
            obj.TobiiStatus = calInfo.ca_state;
            obj.codes = setfield(obj.codes, 'calibration', calInfo.ca_id);
            success=1;
            disp('Calibration successful');
            obj.TobiiStatus = 'another calibration';
        end
        
        % to start the recording
        % !! note that if no sufficient battery left, recording initiation
        % will fail.
        function obj = startrec(obj,varargin)
            %recInfo = webwrite([obj.GlassURL '/api/recordings/'], struct('rec_participant',obj.codes.participant),obj.opts);
            if length(varargin)>1
                for index=1:2:length(varargin)
                    if length(varargin) < index+1
                        break;
                    elseif strcmp('Name', varargin{index})
                        recName = char(varargin{index+1});
                    elseif strcmp('Notes',varargin{index})
                        recNotes = char(varargin{index+1});
                    %elseif strcmp('Segments', varargin{index})
                    %    recSeg = varargin{index+1};
                    %    recInfo = webwrite([obj.GlassURL '/api/recordings/'],struct('rec_participant',obj.codes.participant,'rec_segments', recSeg), obj.opts);
                    else
                        error('Illegal options');
                    end
                    
                end
            end
            recInfo = webwrite([obj.GlassURL '/api/recordings/'],struct('rec_participant',obj.codes.participant,'rec_info',struct('Name',recName,'Notes',recNotes)),obj.opts);
            
            recCode = recInfo.rec_id;
            obj.TobiiStatus = ['Participant ' obj.codes.participant ' recording ' recCode ' is ' recInfo.rec_state];
            recInfo = webwrite([obj.GlassURL '/api/recordings/' recInfo.rec_id '/start'],{},obj.opts);
            obj.TobiiStatus = ['Participant ' obj.codes.participant ' recording ' recCode ' is ' recInfo.rec_state];
            obj.codes = setfield(obj.codes, 'recording',recCode);
            
        end
        
        % to stop the recording
        function [obj,success] = stoprec(obj)
            recInfo = webwrite([obj.GlassURL '/api/recordings/' obj.codes.recording '/stop'],{},obj.opts);
            obj.TobiiStatus = ['Project ' obj.codes.project ' participant ' recInfo.rec_participant ' recording ' recInfo.rec_id ' is ' recInfo.rec_state];
            if strcmp(recInfo.rec_state,'done')
                success=1;
            else
                success=0;
            end
        end 
        
        % to send events during the recording
        function obj = sendevt(obj,varargin)
            if length(varargin)>1
                for index=1:2:length(varargin)
                    if length(varargin) < index+1
                        break;
                    elseif strcmp('Type', varargin{index})
                        evtType = char(varargin{index+1});
                    elseif strcmp('Tag',varargin{index})
                        evtTag = char(varargin{index+1});
                    else
                        error('Illegal options');
                    end
                    
                end
            end            
            
            evtTime = datestr(clock,'HHMMSSFFF');%get the current time
            evtInfo = webwrite([obj.GlassURL '/api/events'],struct('type',evtType,'tag',evtTag,'ets',evtTime(1:8)),obj.opts); %pass the current time to ets
            obj.TobiiStatus = [evtInfo ': ' evtType ' in ' evtTag ' at ' evtTime];
        end
        
        %to check Tobii status during recordings
        function obj = checkup(obj)
            obj.TobiiStatus = webread([obj.GlassURL '/api/recordings/' obj.codes.recording '/status']);
    
        end
        
        %webwrite([tb.GlassURL '/api/recordings/2o7dmlb/stop'],{},tb.opts)
    end
end
