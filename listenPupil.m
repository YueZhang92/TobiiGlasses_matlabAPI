%% This is a running example of using Tobii Pro Glasses 2 for pupillometry experiment.
%% TobiiGlass.m is imported for glasses-related functions.
%% In this example:
%% 1) check Tobii glasses connection
%% 2) create new project and participant info
%% 3) calibrate
%% 4) start recording
%% 5) play sentences and send events regarding stages of the experiment
%% 6) stop recording 
%% 
%%
%% Yue 2018/05/10

function listenPupil(participant, dummy)

%% 1. mark starting time and set up Tobii connection
% ! Before processing, make sure that PC/Mac is connected to the Wifi
% signal of Tobii Glasses !

StartTime=fix(clock);
FileStartTime=sprintf('%02d-%02d', StartTime(4), StartTime(5));
StartTimeString=sprintf('%02d:%02d:%02d', StartTime(4), StartTime(5), StartTime(6));
StartDate= date;

%prepare Tobii
import TobiiGlass %import the Tobii Class
tb = TobiiGlass;
tb.dummy = dummy;
if tb.dummy == 0 %if it's not in dummy mode
    tb.GlassURL = 'http://192.168.71.50'; %Each Tobii machine has a unique URL address, check with the manual
    tb.opts = weboptions('MediaType','application/json','Timeout',20);
    %check Tobii is connected
    tb = tb.isconnected();
    if strcmp(tb.TobiiStatus,'ok' )
        disp('Tobii is connected.');
    else
        error('Check the error message.');
    end
    %configure recording settings
    pause(1);
    tb = tb.setups('sys_et_freq',100,1); %set sampling frequency to 100Hz
    
    %% 2. start a new project, participant 
    pause(1);
    tb = tb.newproject('Name','listenPupil','Notes',['p' num2str(participant,'%02d') '_' StartDate '_' FileStartTime],'xid',[]);
    disp(tb.TobiiStatus);
    tb = tb.newpart('Name',['p' num2str(participant)],'Notes', [StartDate '_' FileStartTime ]);
    disp(tb.TobiiStatus);
    pause(1);
    
    %% 3. Calibration
    [tb,s] = tb.calib();
    % the Matlab command window will then prompt you to enter the take of
    % calibration. Enter 1 and kick 'Enter' to start the first calibration
    % take. The command window will display in real time whether the
    % calibration is successful. If successful, the calibration stage will stop
    % and all infomration stored in the Tobii SD card. If unsuccessful, the
    % command window will prompt you to take another try. Maximum number of
    % calibration try is 5.If unsuccessful after 5 times, it is most likely
    % to be hardware setup problems.
    
    %% 4. read in sounds and start recording
    sentenceDir = 'listenPupil';
    sentenceFiles = dir(fullfile(sentenceDir,'*.wav'));
    %start recording
    tb = tb.startrec('Name',num2str(participant,'%02d'),...
        'Notes',datestr(clock,'YYYY_mm_dd_HH_MM_SS_FFF'));
    disp(DATA.tb.TobiiStatus);
    
    
    for itrial = 1: size(sentenceFiles,1)
        %read the sound
        [y,Fs] = audioread(fullfile(sentenceDir, sentenceFiles(itrial).name));
        %send the marking triger to the Tobii
        tb = tb.sendevt('Type','start','Tag',num2str(itrial,'%02d') );
        disp(tb.TobiiStatus);
        playblocking(y,Fs);
        tb=tb.sendevt('Type','finish','Tag', num2str(itrial, '%02d'));
        disp(tb.TobiiStatus);
        
    end
    
    tb = tb.checkup; %check up the status
    if ~strcmp(tb.TobiiStatus.rec_state,'done')
        %send an event to mark the stop of recording
        tb = tb.sendevt('Type','stop','Tag',num2str(participant, '%02d'));
        disp(tb.TobiiStatus);
        tb = tb.stoprec(); %stop the recording whatever
        
        disp(tb.TobiiStatus);
    end
    
    disp('ListenPupil finished.')

end
