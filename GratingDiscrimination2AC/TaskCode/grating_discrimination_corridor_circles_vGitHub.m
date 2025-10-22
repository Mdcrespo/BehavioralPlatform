%% grating_discrimination_corridor_circles_vGitHub.m
% By Michael Crespo @ UB
% mdcrespo@buffalo.edu
% Updated from Brian Jeon @ CMU/Chase Lab
% bjeon@cmu.edu

% 2024-12-13 - Michael Crespo
% Added Extra water toggles for both water ports (allows 3 drops to be collected per trial)
% Moved Autowater threshold into the reward zone rather than at the end
% Updated how water collection is counted

% 2024-06-02 - Michael Crespo
% Converted to 2 lickport based trial
% Go trials now require a left lick while no-go trials now request a right lick
% Added Diode sensor as 9 bit binary to count trials from 1-513 in 2.2 second span during discrimination corridor

% 2024-01-22 - Brian Jeon
% added a timelimit for the grating corridor (line 149)
% added a way to set dropsize from the GUI
% fixed a bug where messages from the arduino did not print on the command window during the approach corridor 

% 2016-10-17 - Brian Jeon
% integrated balltracker to the shaping system.  The mouse must stay still
% for at least 2 seconds in addition to the no licking requirement.

% 2016-07-15 - Brian Jeon
% added beep to go along with the reward tone
% reduced the sound to 75% of the full amplitude to allow for beep to be
% heard

% 2015-10-02 - Brian Jeon

% the grating_discrimination_corridor_circles_vGitHub is built from behaviortrainingv4 with only the go
% trials

% D:\visStimComputerData\behaviorTxtLogs

function varargout = grating_discrimination_corridor_circles_vGitHub(varargin)
% GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB MATLAB code for grating_discrimination_corridor_circles_vGitHub.fig
%      GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB, by itself, creates a new GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB or raises the existing
%      singleton*.
%
%      H = GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB returns the handle to a new GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB or the handle to
%      the existing singleton*.
%
%      GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB.M with the given input arguments.
%
%      GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB('Property','Value',...) creates a new GRATING_DISCRIMINATION_CORRIDOR_CIRCLES_VGITHUB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before grating_discrimination_corridor_circles_vGitHub_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to grating_discrimination_corridor_circles_vGitHub_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help grating_discrimination_corridor_circles_vGitHub

% Last Modified by GUIDE v2.5 20-Oct-2025 15:45:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @grating_discrimination_corridor_circles_vGitHub_OpeningFcn, ...
                   'gui_OutputFcn',  @grating_discrimination_corridor_circles_vGitHub_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before grating_discrimination_corridor_circles_vGitHub is made visible.
function grating_discrimination_corridor_circles_vGitHub_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output argHs, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to grating_discrimination_corridor_circles_vGitHub (see VARARGIN)
% global functionMFile
% functionMFile=[];
% p=[];
%     
%     p = mfilename('fullpath');
%     c = [p '.txt'];
%     p(end+1:end+2)= '.m';   
%     copyfile (p, c)
%     opts = detectImportOptions(c);
%     opts.DataLines = [1 Inf];
%     functionMFile= readtable(c, opts);

% Choose default command line output for grating_discrimination_corridor_circles_vGitHub
clear global

handles.output = hObject;

%% Initialize Arduino

ser_port = 'COM4'; % serial port that Arduino is connected to
baud = 9600; % communication speed
callbackFunctionHandle = @LiveCallback_AUDshaping4; % Custom callback function handle

handles.sHandle = serialport(ser_port, baud, 'DataBits',8,'StopBits',1,'Parity','none');
pause(2) % allow time for matlab to set up serial communication with the arduino
configureTerminator(handles.sHandle,'CR/LF');
configureCallback(handles.sHandle,'terminator',@rewardControllerCallback);

global exp_history
% set up a log file
d = datestr(now); %current date and time
d = d(setdiff(1:length(d),strfind(d,':'))); %remove :'s
d(strfind(d,' ')) = '_'; %change space to underscore
handles.sHandle.UserData.templogfilename = ['scLog_',d,'.txt'];
scLogFile = fopen(handles.sHandle.UserData.templogfilename,'w+'); %automatically start logging to a new file
handles.sHandle.UserData.logFileHandle = scLogFile;
exp_history = [];
handles.sHandle.UserData.callbackFunctionHandle = callbackFunctionHandle;
flush(handles.sHandle)

%% Initialize Autoclicker
global autoclick
serPort = 'COM5';
baud2 = 9600;
autoclick = serialport(serPort, baud2, 'DataBits',8,'StopBits',1,'Parity','none');
pause(2)
configureTerminator(autoclick,'CR/LF');
configureCallback(autoclick,'terminator',@cameraFrameCallback);
flush(autoclick);

%% initialize ball tracker
global s
s = serial('COM3', 'BaudRate', 9600);
fopen(s);
pause(2);
readasync(s);
s.bytesavailablefcn = @readEncoderCallback;
% configureCallback(s,"terminator",@readEncoderCallback)
%% Update handles structure
set(handles.status,'String','Ready!')
set(handles.status,'ForegroundColor',[0,1,0])
handles.sHandle.UserData.rewardreceived = 0;
handles.sHandle.UserData.trialnum = 0;
handles.sHandle.UserData.timeoutstatus = 0;
handles.sHandle.UserData.lengthentimeout = 0;
handles.result=zeros(3,2);
handles.rewardtime = 3; 
handles.iti = 2; % minimum of 3 seconds is required for realtime feedback to have enough time to check
handles.pausestatus=0;
handles.currenttrial = 0;
handles.datasaved = 0;
screenDistance = 25;
guidata(hObject, handles);
axes(handles.axes1)
global dropsize primed default_timeout screenRestartFreq
dropsize = 80;
primed = 0;
default_timeout = 3; %default timeout
%set contrast level for corridor and grating
contrastLevel_corridor = 0.9;
contrastLevel_grating = 1;
handles.maxGratingTime = 300; % time limit for the grating corridor, if the mouse does not progress through the gratings in 300 seconds, the trial will end, and next trial will begin.  If you do not wish to put a timelimit, use inf

% PTB screen restart
% how often to restart the screen
screenRestartFreq = 5;

hold on

% images to be used for the selection task.  
% Each row contains the pair of images that show up on the screen: 
% second column is the short duration stimuli and first column is the long duration

%% set up psych toolbox
global window black  screenXpixels screenYpixels
global xCenter yCenter 
global ifi grey encConversionFactor pixpercm_x
global goGratingImage nogoGratingImage corridorImage

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);
Screen('Preference', 'ConserveVRAM', 4096)
% Draw to the external screen if avaliable
%screenNumber = max(screens);
screenNumber = 1;


% Define black and white
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, grey);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Maximum priority level
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

%load images
% imgDir = 'C:\Users\KuhlmanAna2.KuhlmanAna2-PC\Documents\MATLAB\selectionTask\73waves_Lumcor_SFredo_LOW_170324';
goGratingImage = load('grating_vertical.mat');
nogoGratingImage = load('grating_45.mat');
corridorImage = load('corridorImage.mat');
% apply contrast level
corridorImage.corridorImage = round((corridorImage.corridorImage-127)*contrastLevel_corridor+127);

% wheel calibration
encConversionFactor = 45/4500; % circumference of the wheel / encoder readout for 1 full rotation.

%%
% The target width of the images are 15 degrees in length and 15 degrees imageWidth in
% height
% 15 degree = 6.5826 cm
% Screen size = [64.135cm x 40.01 cm]/[2560 pix x 1600 pix]
% pix/cm conversion = 

global onedegree onecm
pixpercm_x = 2560/64.135;
onedegree = 2*screenDistance*tand(0.5);
onecm = pixpercm_x;
% imageSize_cm = 6.5826;
% imageWidth = round(imageSize_cm*pixpercm_x); % 50 degrees
% imageSep = screenXpixels/2;
% imageHeight = round(imageSize_cm*pixpercm_y);
% 
% % define destination rectangles
% theRects = [0 0 imageWidth imageHeight];
% destRects = zeros(4, 2);
% leftImageCenter = screenXpixels/4;
% rightImageCenter = leftImageCenter + imageSep;


% define centering box
% % centering box is 35 degrees in width and covers the height of the monitor
% % 30 degrees = 13.397 cm (626 pixels)
% blackTargetBox = [0 0 round(targetSize*pixpercm_x) screenYpixels];
% targetLocation = CenterRectOnPointd(blackTargetBox, xCenter, yCenter);
% centerBox = [0 0 round(targetSize*pixpercm_x) screenYpixels];
% % Size of for center of rectangle = 30 degrees (13.397 cm)

% Size of for center of rectangle to fall within--20% of image width
% centerBox = [0 0 imageWidth*centerBoxPercent 100];


global stoptrial trialnum
stoptrial = 1;
trialnum = 0;

global grating_angle_go grating_angle_nogo appCorrLength_converted gratingCorridorLength_pix go_probability autoPercent

approachCorridorLength = 50;  % length of the approach corridor in cm
appCorrLength_converted = round(approachCorridorLength*pixpercm_x);
gratingCorridorLength = 50;
gratingCorridorLength_pix = round(gratingCorridorLength*pixpercm_x);
grating_angle_go = 0;% 90 degrees with respect to horizontal
grating_angle_nogo = 45; % 45 degrees with respect to horizontal 
go_probability = 50;
autoPercent = 5/6;

%% create diode textures
global diodeDest diodeOn_tex diodeOff_tex diodeOn diodeOff next miss
diode = 1;
if diode
    diodeDest = [0 0 60 60];
    diodeOn= ones(60,60)*white;
    diodeOn_tex=Screen('MakeTexture', window, diodeOn);
    diodeOff= ones(60,60)*black;
    diodeOff_tex=Screen('MakeTexture', window, diodeOff);
    next = 0;
    miss = 0;
end

%% organize config as structure to save.
global taskParam
% taskParam.centerBoxPercent = centerBoxPercent;% Size of for center of rectangle to fall within--20% of image width
taskParam.dropsize = dropsize;
taskParam.grating_angle_go = grating_angle_go;
taskParam.grating_angle_nogo  = grating_angle_nogo;
taskParam.contrastLevel_corridor = contrastLevel_corridor;
taskParam.contrastLevel_grating = contrastLevel_grating;
taskParam.approachCorridorLength = approachCorridorLength;
taskParam.gratingCorridorLength = gratingCorridorLength;
taskParam.go_probability = go_probability;
taskParam.maxGratingTime = handles.maxGratingTime;
taskParam.autoPercent = autoPercent;

guidata(hObject,handles)
end
% UIWAIT makes grating_discrimination_corridor_circles_vGitHub wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = grating_discrimination_corridor_circles_vGitHub_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

% --- Executes on button press in Save.
function Save_Callback(hObject, eventdata, handles)
% hObject    handle to Save (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%   organize data to save
global stoptrial results trialschedule taskParam nRewards
stoptrial = 1;

data=results;
savename_Callback(hObject,[],handles);
A = exist([handles.fname,'.mat'],'file');
if A ~= 0
    msgbox('File exists. Enter a new name!');
    return;
end
save([handles.fname,'.mat'],'data','trialschedule','taskParam','nRewards')
copyfile(handles.sHandle.UserData.templogfilename,[handles.fname,'.txt']);
handles.datasaved = 1;
guidata(hObject,handles)
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
global autoclick
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: delete(hObject) closes the figure
if ~handles.datasaved
    exitstatus = questdlg('Data not saved, Exit?','Confirm Exit','Yes','No','No');
else
    exitstatus = 'Yes';
end
switch exitstatus
    case 'Yes'
        exitconfirm = 1;
    case 'No'
        exitconfirm = 0;
end
if handles.datasaved || exitconfirm
    try
        fclose(handles.balltracker);% close balltracker serial object
        delete(handles.balltracker);% delete balltracker serial object
        Screen('CloseAll')
        fclose(handles.sHandle.UserData.logFileHandle); %close the log file
        delete(handles.sHandle.UserData.templogfilename);
        delete(handles.sHandle)
        delete(hObject);
        write(autoclick,9,"int8")
        write(autoclick,11,"int8")
        delete(autoclick);
        fclose(autoclick);
    catch
        allports = instrfindall;
        fclose(allports);
        delete(allports);
        Screen('CloseAll')
        delete(hObject);
        write(autoclick,9,"int8")
        write(autoclick,11,"int8")
    end
else 
    return;
end
end

function savename_Callback(hObject, eventdata, handles)
% hObject    handle to savename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of savename as text
%        str2double(get(hObject,'String')) returns contents of savename as a double
handles.fname=get(handles.savename,'String');
guidata(hObject,handles)
end

% --- Executes during object creation, after setting all properties.
function savename_CreateFcn(hObject, eventdata, handles)
% hObject    handle to savename (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

currentwindow = get(handles.slider1,'Value');
switch round(currentwindow)
    case 1
        set(handles.axes1,'XLim',[0 100]);
    case 2
        set(handles.axes1,'XLim',[100 200]);
    case 3
        set(handles.axes1,'XLim',[200 300]);
    case 4
        set(handles.axes1,'XLim',[300 400]);
    case 5
        set(handles.axes1,'XLim',[400 500]);
    otherwise
        %currentwindow*10
end
    
end

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end


% --- Executes on button press in playstim.
function playstim_Callback(hObject, eventdata, handles)
% hObject    handle to playstim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global  trialschedule window encConversionFactor go_probability nRewards manualTrial licked autoclick
% set(handles.playstim,'Enable','off')
% get the total number of trials
handles.numtrialtotal = str2double(get(handles.totaltrial,'String'));
savename_Callback(hObject,[],handles);
if isempty(get(handles.savename,'String'))
    msgbox('Enter a save name first!')
    set(handles.playstim,'Enable','on')
    return;
end
if isnan(handles.numtrialtotal)
    handles.numtrialtotal = 0;
end
if ~handles.numtrialtotal
    msgbox('Please input a valid number of trials!');
    set(handles.playstim,'Enable','on')
    return;
else
    % get number of tones used for this shaping
    trialschedule = trial_creator(handles.numtrialtotal,go_probability);
    % create imageType schedule
    % each pair of images are evenly distributed
    % shuffle the image type order so that it is random
end
mkdir([handles.fname,'_encData'])

handles.pausestatus=0;
trialcomplete = 0;
trialcount = 0;
nRewards = 0; % function to keep track of the number of rewards
global stoptrial results encReadout pixpercm_x appCorrLength_converted grey corridorImage screenYpixels screenXpixels exp_history
global diodeDest diodeOn_tex diodeOff_tex diodeOn diodeOff frameRead inApproach leftLick rightLick
stoptrial = 0;
diodeBreakDur = 0.250;
KbReleaseWait;
while ~trialcomplete && ~stoptrial
    handles.sHandle.UserData.trialnum = handles.sHandle.UserData.trialnum + 1;
%   Initialize the current position on the track
    CurrPos = 1; % set the start point at the beginning of the track
    manualTrial = 0;
    CurrEncPos = encReadout; % current position at the time of encoder readout
    trialcount = trialcount + 1;
    handles.currenttrial=handles.currenttrial + 1;
    datacount = 1;
    frameCount = 1;
    CurrFrame = 0;
    frameData_app = zeros(1000,4);
    encoderData_app = zeros(1000,2);
    % the corridor starts
    inApproach = true;% variable to see whether the animal has reached the end of the corridor
%     encoderPosData = 
%     Screen('FillRect', window, grey);
    beginningImage = fliplr(corridorImage.corridorImage(1:screenYpixels,CurrPos:CurrPos+screenXpixels-1))/255;
    imageTexture1 = Screen('MakeTexture', window, beginningImage);
%    Screen('DrawTexture', window, imageTexture1);
%    Screen('Flip', window);
    write(handles.sHandle,0,"int8")
    diodeOn_tex = Screen('MakeTexture', window, diodeOn);
    diodeOff_tex = Screen('MakeTexture', window, diodeOff);
    Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    Screen('Flip',window);
    pause(diodeBreakDur)
    %
    Screen('DrawTexture', window, imageTexture1);
    Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
    Screen('Flip', window);
        % scSendMessage(handles.sHandle,'gostate=0;');
        % scSendMessage(handles.sHandle,'disp(gostate);');
    leftLick = 0;
    rightLick = 0;
    tic;
    while inApproach
        t = toc;
        write(autoclick,10,"int8")
        if frameRead ~= CurrFrame
            t = toc;
            frameData_app(frameCount,1) = t;
            frameData_app(frameCount,2) = frameRead;
            if frameCount ~=1
                if leftLick == 1
                    frameData_app(frameCount-1,3) = 1;
                    leftLick = 0;
                end
                if rightLick == 1
                    frameData_app(frameCount-1,4) = 1;
                    rightLick = 0;
                end
            end
            frameCount = frameCount + 1;
            CurrFrame = frameRead;
        end
        %find whether there was a change in rotary encoder position
        if encReadout ~= CurrEncPos
            % if there was a change in position
            movement = encReadout - CurrEncPos;
            movement_screen = round(encConversionFactor*movement*pixpercm_x);
            CurrPos = CurrPos + movement_screen;
            CurrEncPos = encReadout;
            if CurrPos > appCorrLength_converted
                break; % the animal moved past the corridor, teleport to another location
            else
                if CurrPos < 1 %you cannot go further back than the starting point
                    CurrPos = 1;
                end
                beginningImage = fliplr(corridorImage.corridorImage(1:screenYpixels,CurrPos:CurrPos+screenXpixels-1))/255;
                imageTexture1 = Screen('MakeTexture', window, beginningImage);
                Screen('DrawTexture', window, imageTexture1);
                Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
                Screen('Flip', window);
                encoderData_app(datacount,1) = t;
                encoderData_app(datacount,2) = movement; 
                datacount = datacount + 1;
            end

        end
        drawnow;
%         pause((1/60))
    end
    
    if trialschedule(trialcount) == 2
        go2(hObject,handles);
    else
        nogo2(hObject,handles);
    end
    save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'encoderData_app','-append');
    save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'frameData_app','-append');
    clearvars encoderData_app frameData_app
    Screen('Close',imageTexture1);
    %pause(handles.iti-diodeBreakDur) % pause for intertrial interval    
     pause(handles.iti) % pause for intertrial interval
    
    % Timeout
    
    global exp_history
    % Performance Feedback Display
    % right on left
    if trialschedule(trialcount,1) == 2 && exp_history(handles.currenttrial,2)== 2   
        handles.result(2,1) = handles.result(2,1) + 1;
        scatter(handles.currenttrial,2,'ko','filled','Linewidth',0.25)
        results(handles.currenttrial) = 3;
    % left on left
    elseif trialschedule(trialcount,1) == 2 && exp_history(handles.currenttrial,2)== 1
        handles.result(1,1)=handles.result(1,1)+1;
        scatter(handles.currenttrial,2,'go','filled','Linewidth',0.25) %mark blue if primed 
        results(handles.currenttrial) = 1;
    % left on right
    elseif trialschedule(trialcount,1) == 1 && exp_history(handles.currenttrial,2)== 1
        handles.result(2,2)=handles.result(2,2)+1;
        scatter(handles.currenttrial,1,'ko','filled','Linewidth',0.25)
        results(handles.currenttrial) = 2 ;
    % right on right
    elseif trialschedule(trialcount,1) == 1 && exp_history(handles.currenttrial,2)== 2 
        handles.result(1,2)=handles.result(1,2)+1;
        scatter(handles.currenttrial,1,'ro','filled','Linewidth',0.25)
        results(handles.currenttrial) = 4;
    % miss on right
    elseif trialschedule(trialcount,1) == 1 && exp_history(handles.currenttrial,2)== 0
        handles.result(3,2)=handles.result(3,2)+1;
        scatter(handles.currenttrial,1,'bo','filled','Linewidth',0.25)
        results(handles.currenttrial) = 5;
    % miss on left
    elseif trialschedule(trialcount,1) == 2 && exp_history(handles.currenttrial,2)== 0 
        handles.result(3,1)=handles.result(3,1)+1;
        scatter(handles.currenttrial,2,'bo','filled','Linewidth',0.25)
        results(handles.currenttrial) = 6;
    end

    set(handles.uitable2,'Data',num2cell(handles.result))

    % Update Accuracy Information
    totalacc = (handles.result(1,1)+handles.result(1,2))/sum(sum(handles.result));
    TPR = handles.result(1,1)/sum(handles.result(:,1));
    TNR = handles.result(1,2)/sum(handles.result(:,2));
    rewardPercentage = totalacc;
    S = [num2str(nRewards),' (',sprintf('%0.1f',rewardPercentage*100),') %'];
    set(handles.numRewardedTrials,'String',S)
    if isnan(TPR)
        TPR = 0;
    end
    if isnan(TNR)
        TNR = 0;
    end
    S = [sprintf('%0.1f',totalacc*100),' %'];
    set(handles.totalacc,'String',S)
    S = [sprintf('%0.1f',TPR*100),' %'];
    set(handles.TPR,'String',S)
    S = [sprintf('%0.1f',TNR*100),' %'];
    set(handles.TNR,'String',S)
    if trialcount == length(trialschedule)
        trialcomplete = 1;
    end
%     guidata(hObject,handles);
    drawnow();
    % close off screen windows and textures to conserve memeory
    Screen('Close')
    % restart PTB screen to clear memory
%     if mod(handles.currenttrial,screenRestartFreq) == 0
%         cleanupWindow;
%     end
end
    write(autoclick,11,"int8")
    set(handles.status,'ForegroundColor',[0,1,0])
    set(handles.status,'String','Trials complete!')
    set(handles.playstim,'Enable','on')
    guidata(hObject,handles)
    stoptrial = 1;
end


function go2(hObject,handles)
global primed window  screenXpixels rewardreceived
global  grey     
global encReadout pixpercm_x encConversionFactor gratingCorridorLength_pix dropsize goGratingImage screenYpixels
global diodeDest diodeOn_tex diodeOff_tex next miss autoPercent autoWater licked frameRead inGratingCorr leftLick rightLick

% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
primed = 0;% reset primed status
autoWater = 0;
% start the tone (gostate 1)
gratingPos = 1;
% Phase = gratingPos/onecm/onedegree/20*360;
beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
% Screen('DrawTexture', window, gratingtex,[],[],180,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
imageTexture1 = Screen('MakeTexture', window, beginningImage);
Screen('DrawTexture', window, imageTexture1, [], []);
Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
Screen('Flip', window);
datacount = 1;
frameCount = 1;
CurrFrame = frameRead;
frameData_grating = zeros(1000,4);
encoderData_grating = zeros(1000,2);
% scSendMessage(handles.sHandle,'gostate=2;');
% scSendMessage(handles.sHandle,'disp(gostate);');
write(handles.sHandle,2,"int8") 
handles.sHandle.UserData.rewardreceived = 0;
rewardreceived = 0;

inGratingCorr = true;
rewardArmed = false;

trialn=dec2bin(handles.currenttrial,9);
trialnstr=num2str(trialn)-'0';
x=1;
f=0.15;
diode = 0;
CurrEncPos = encReadout;
leftLick = 0;
rightLick = 0;
tic;
while inGratingCorr
    t = toc;
    if t >= handles.maxGratingTime % if 
        inGratingCorr = false;
    end

    if frameRead ~= CurrFrame
        frameData_grating(frameCount,1) = t;
        frameData_grating(frameCount,2) = frameRead;
        if frameCount ~= 1
        if leftLick == 1
            frameData_grating(frameCount,3) = 1;
            leftLick = 0;
        end
        if rightLick == 1
            frameData_grating(frameCount,4) = 1;
            rightLick = 0;
        end
        end
        frameCount = frameCount + 1;
        CurrFrame = frameRead;
    end

if toc<=0.15
    beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
    imageTexture1 = Screen('MakeTexture', window, beginningImage);
    Screen('DrawTexture', window, imageTexture1, [], []);
    Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    Screen('Flip', window);
    diode=0;
elseif x <= 9
    if trialnstr(x) && ~diode
        beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f+0.15
            x=x+1;
            f=f+0.15+0.15;
            diode=1;
        end
    elseif ~trialnstr(x) && ~diode
        beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f
            x=x+1;
            f=f+0.15;
            diode=1;
        end
    elseif diode
        beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f
            f=f+0.15;
            diode=0;
        end
    end
else
    beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
    imageTexture1 = Screen('MakeTexture', window, beginningImage);
    Screen('DrawTexture', window, imageTexture1, [], []);
    Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    Screen('Flip', window);
end

if encReadout ~= CurrEncPos
    % if there was a change in position
    movement = encReadout - CurrEncPos;
    CurrEncPos = encReadout;
    movement_screen = round(encConversionFactor*movement*pixpercm_x);
    gratingPos = gratingPos + movement_screen;
    if gratingPos < 1
        gratingPos = 1;
    end
    if gratingPos > (gratingCorridorLength_pix/6) && ~rewardArmed
        % scSendMessage(handles.sHandle,'gostate=3;');
        % scSendMessage(handles.sHandle,'licked=0;')
        % scSendMessage(handles.sHandle,'disp(gostate);');
        write(handles.sHandle,3,"int8")
        handles.sHandle.UserData.rewardreceived = 0;
        rewardArmed = true;
        right = true;
        rewardreceived = 0;
        licked = 0;
        %         elseif gratingPos > (gratingCorridorLength_pix*0.8333) && (handles.sHandle.UserData.rewardreceived ~= 1)
        %             scSendMessage(handles.sHandle,'gostate=4;');
        %             scSendMessage(handles.sHandle,'disp(gostate);');
        %             scSendMessage(handles.sHandle,'portout[4]=0;')
        %             pause(dropsize/1000);
        %             scSendMessage(handles.sHandle,'portout[4]=1;')
        %             primed = 1;
        %             scSendMessage(handles.sHandle,'disp(primed);')
    end
    %         Phase = gratingPos/onecm/onedegree/20*360;
    %         Screen('DrawTexture', window, gratingtex,[],[],180,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
    % beginningImage = fliplr(goGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
    % % Screen('DrawTexture', window, gratingtex,[],[],180,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
    % imageTexture1 = Screen('MakeTexture', window, beginningImage);
    % Screen('DrawTexture', window, imageTexture1, [], []);
    % Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    % Screen('Flip', window);
    encoderData_grating(datacount,1) = t;
    encoderData_grating(datacount,2) = movement;
    datacount = datacount +1;

    if gratingPos > gratingCorridorLength_pix*autoPercent
        if (rewardreceived ~= 1) && (get(handles.autowaterdelivery,'Value') == 1) && autoWater == 0
            write(handles.sHandle,1,"int8")
            primed = 1;
            autoWater = 1;

        end
    end
    if gratingPos > gratingCorridorLength_pix
        inGratingCorr = false;
    end
end
drawnow();
end
% scSendMessage(handles.sHandle,'gostate=6;');
% scSendMessage(handles.sHandle,'disp(gostate);');
write(handles.sHandle,6,"int8")
Screen('FillRect', window, grey);
Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
Screen('Flip', window);
save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'encoderData_grating');
save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'frameData_grating','-append');
clearvars encoderData_grating beginningImage imageTexture1 frameData_grating;
end

function nogo2(hObject,handles)
global primed window  screenXpixels
global  grey screenYpixels rewardreceived
global encReadout pixpercm_x encConversionFactor gratingCorridorLength_pix nogoGratingImage 
global diodeDest diodeOn_tex diodeOff_tex next miss autoPercent autoWater licked frameRead inGratingCorr leftLick rightLick

% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
primed = 0;% reset primed status
autoWater = 0;
% start the tone (gostate 1)
gratingPos = 1;
beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
% Screen('DrawTexture', window, gratingtex,[],[],180,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
imageTexture1 = Screen('MakeTexture', window, beginningImage);
Screen('DrawTexture', window, imageTexture1, [], []);
Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
Screen('Flip', window);
datacount = 1;
frameCount = 1;
CurrFrame = frameRead;
frameData_grating = zeros(1000,4);
encoderData_grating = zeros(1000,2);
% Phase = gratingPos/onecm/onedegree/20*360;
% Screen('DrawTexture', window, gratingtex,[],[],180-50,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
% Screen('Flip', window);
% scSendMessage(handles.sHandle,'gostate=5;');
% scSendMessage(handles.sHandle,'disp(gostate);');
% scSendMessage(handles.sHandle,'licked=0;')
write(handles.sHandle,5,"int8")
handles.sHandle.UserData.rewardreceived = 0;

rewardreceived = 0;

inGratingCorr = true;
rewardArmed = false;

trialn=dec2bin(handles.currenttrial,9);
trialnstr=num2str(trialn)-'0';
x=1;
f=0.15;
diode = 1;
CurrEncPos = encReadout;
leftLick = 0;
rightLick = 0;
tic;
while inGratingCorr
    t = toc;
    if t >= handles.maxGratingTime % if 
        inGratingCorr = false;
    end

    if frameRead ~= CurrFrame
        frameData_grating(frameCount,1) = t;
        frameData_grating(frameCount,2) = frameRead;
        if frameCount ~= 1
        if leftLick == 1
            frameData_grating(frameCount,3) = 1;
            leftLick = 0;
        end
        if rightLick == 1
            frameData_grating(frameCount,4) = 1;
            rightLick = 0;
        end
        end
        frameCount = frameCount + 1;
        CurrFrame = frameRead;

    end

if t<=0.14
    beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
    imageTexture1 = Screen('MakeTexture', window, beginningImage);
    Screen('DrawTexture', window, imageTexture1, [], []);
    Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    Screen('Flip', window);
    diode=0;
elseif x <= 9
    if trialnstr(x) && ~diode
        beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f+0.15
            x=x+1;
            f=0.15+f+0.15;
            diode=1;
        end
    elseif ~trialnstr(x) && ~diode
        beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f
            x=x+1;
            f=f+0.15;
            diode=1;
        end
    elseif diode
        beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        imageTexture1 = Screen('MakeTexture', window, beginningImage);
        Screen('DrawTexture', window, imageTexture1, [], []);
        Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
        Screen('Flip', window);
        if toc>=0.15+f
            f=f+0.15;
            diode=0;
        end
    end
else
    beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
    imageTexture1 = Screen('MakeTexture', window, beginningImage);
    Screen('DrawTexture', window, imageTexture1, [], []);
    Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
    Screen('Flip', window);
end

     if encReadout ~= CurrEncPos
        % if there was a change in position
        movement = encReadout - CurrEncPos;
        CurrEncPos = encReadout;
        movement_screen = round(encConversionFactor*movement*pixpercm_x);
        gratingPos = gratingPos + movement_screen;
        if gratingPos < 1
            gratingPos = 1;
        end
        if gratingPos > (gratingCorridorLength_pix/6) && ~rewardArmed
            % scSendMessage(handles.sHandle,'gostate=3;');
            % scSendMessage(handles.sHandle,'licked=0;')
            % scSendMessage(handles.sHandle,'disp(gostate);');
            write(handles.sHandle,3,"int8")
            handles.sHandle.UserData.rewardreceived = 0;
            rewardArmed = true;
            left = true;
            rewardreceived = 0;
            licked = 0;
%         elseif gratingPos > (gratingCorridorLength_pix*0.8333) && (handles.sHandle.UserData.rewardreceived ~= 1)
%             scSendMessage(handles.sHandle,'gostate=4;');
%             scSendMessage(handles.sHandle,'disp(gostate);');
%             scSendMessage(handles.sHandle,'portout[4]=0;')
%             pause(dropsize/1000);
%             scSendMessage(handles.sHandle,'portout[4]=1;')
%             primed = 1;
%             scSendMessage(handles.sHandle,'disp(primed);')
        end
%         Phase = gratingPos/onecm/onedegree/20*360;
%         Screen('DrawTexture', window, gratingtex,[],[],180-50,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
        %  beginningImage = fliplr(nogoGratingImage.I(1:screenYpixels,gratingPos:gratingPos +screenXpixels-1));
        % % Screen('DrawTexture', window, gratingtex,[],[],180,[],[],[],[],[],[Phase,0.05/onedegree/onecm,0.5,0]);
        % imageTexture1 = Screen('MakeTexture', window, beginningImage);
        % Screen('DrawTexture', window, imageTexture1, [], []);
        % %Screen('DrawTexture', window, diodeOff_tex, [], [diodeDest],[]);
        % Screen('Flip', window);
        encoderData_grating(datacount,1) = t;
        encoderData_grating(datacount,2) = movement;
        datacount = datacount +1;
        
        if gratingPos > gratingCorridorLength_pix*autoPercent
            if (rewardreceived ~= 1) && (get(handles.autowaterdelivery,'Value') == 1) && autoWater == 0
                write(handles.sHandle,1,"int8")
                primed = 1;
                autoWater = 1;
            end
        end
        if gratingPos > gratingCorridorLength_pix
            inGratingCorr = false;
        end
     end
    %  toc
    % toc-t
     drawnow();
end
% scSendMessage(handles.sHandle,'gostate=6;');
% scSendMessage(handles.sHandle,'disp(gostate);');
write(handles.sHandle,6,"int8")
Screen('FillRect', window, grey);
Screen('DrawTexture', window, diodeOn_tex, [], [diodeDest],[]);
Screen('Flip', window);
save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'encoderData_grating');
save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'frameData_grating','-append');
clearvars encoderData_grating beginningImage imageTexture1 frameData_grating;
end


function totaltrial_Callback(hObject, eventdata, handles)
% hObject    handle to totaltrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of totaltrial as text
%        str2double(get(hObject,'String')) returns contents of totaltrial as a double

end

% --- Executes during object creation, after setting all properties.
function totaltrial_CreateFcn(hObject, eventdata, handles)
% hObject    handle to totaltrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on selection change in timeoutdur.
function timeoutdur_Callback(hObject, eventdata, handles)
% hObject    handle to timeoutdur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns timeoutdur contents as cell array
%        contents{get(hObject,'Value')} returns selected item from timeoutdur
end

% --- Executes during object creation, after setting all properties.
function timeoutdur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeoutdur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in openvalve.
% This is the function to manually open the valve of the lick port.
function openvalve_Callback(hObject, eventdata, handles)
% hObject    handle to openvalve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if stoptrial
%     handles.sHandle.UserData.trialnum = handles.sHandle.UserData.trialnum + 1;
%     trialnum = trialnum + 1;
%     tonecount = 1;
%     tic;
%     t = toc;
%     
%     scSendMessage(handles.sHandle,'gostate = 3;');
%     scSendMessage(handles.sHandle,'disp(gostate);');
%     scSendMessage(handles.sHandle,'licked = 0;'); % reset lick tracker
%     if (get(handles.autowaterdelivery,'Value') == 1)
%         while (t < 2)
%             sound(soundtemplate{6},Fs);
%             t = toc;
%             if tonecount == 2
%                  scSendMessage(handles.sHandle,'portout[4]=0;');
%                  scSendMessage(handles.sHandle,'disp(portout[4]);');
%             elseif tonecount == 3
%                  scSendMessage(handles.sHandle,'portout[4]=1;')
%             end
%             pause(0.2);
%             tonecount = tonecount+1;
%         end
%     else
%         while (t < 2)
%             sound(soundtemplate{end},Fs);
%             t = toc;
%             if tonecount == 2
%                 scSendMessage(handles.sHandle,'portopen=1;');
%                 scSendMessage(handles.sHandle,'disp(portopen);');
%             end
%             pause(0.2);
%             tonecount = tonecount+1;
%         end
%         scSendMessage(handles.sHandle,'portopen=0;');
%         scSendMessage(handles.sHandle,'disp(portopen);');
%         
%     end
%     
%     scSendMessage(handles.sHandle,'gostate = 0;');
%     scSendMessage(handles.sHandle,'disp(gostate);');
%     % Enter Timeout
%     contents = cellstr(get(handles.timeoutdur,'String'));
%     timeoutdur = str2double(contents{get(handles.timeoutdur,'Value')});
%     if timeoutdur ~= 0 
%         % if a timeout duration is selected and the trial was a no-trial
%         handles.sHandle.UserData.timeoutstatus = timeoutdur; 
%         handles.pausestatus = 1;
%         set(handles.status,'ForegroundColor',[1,0,0])
%         set(handles.status,'String','In Timeout Mode!')
%         set(handles.lickstatus,'BackgroundColor',[1,0,0]);
%         drawnow();
%         scSendMessage(handles.sHandle,['timeout=',num2str(timeoutdur),';'])
%         scSendMessage(handles.sHandle,'disp(timeout)')
%         % if in timeout, intialize timeout clock
%         tic;
%         % enter timeout loop
%         while handles.pausestatus
%             timeoutclock = toc;
%             % if mouse licked during timeout period, reset timer
%             if handles.sHandle.UserData.lengthentimeout
%                 handles.sHandle.UserData.lengthentimeout = 0;
%                 tic;
%             % If mouse cleared timeout clock, end timeout and return to trial
%             elseif timeoutclock >= timeoutdur
%                 handles.pausestatus = 0;
%                 scSendMessage(handles.sHandle,'timeout=0')
%                 scSendMessage(handles.sHandle,'disp(timeout)');
%             end   
%         end
%     end
%     handles.sHandle.UserData.timeoutstatus = 0; 
%     set(handles.lickstatus,'BackgroundColor',[0,1,0]);
%     set(handles.status,'ForegroundColor',[0,1,0])
%     set(handles.status,'String','Ready!')
%     axes(handles.axes1)
% 
%     if handles.sHandle.UserData.history(trialnum,2)== 0
%         scatter(trialnum,1,'ro','filled','Linewidth',0.25)
%         results(trialnum) = 0;
%     % Hit, (go & go)
%     elseif handles.sHandle.UserData.history(trialnum,2)==1
%         scatter(trialnum,1,'go','filled','Linewidth',0.25)
%         results(trialnum) = 1;
%     end
% else
    global primed
    % scSendMessage(handles.sHandle,'portout[4]=0;')
    % pause(dropsize/1000);
    % scSendMessage(handles.sHandle,'portout[4]=1;')
    primed = 1;
    % scSendMessage(handles.sHandle,'disp(primed);')
    write(handles.sHandle,1,"int8")
% end
end


% --- Executes on selection change in MaxToneHoldCount.
function MaxToneHoldCount_Callback(hObject, eventdata, handles)
% hObject    handle to MaxToneHoldCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns MaxToneHoldCount contents as cell array
%        contents{get(hObject,'Value')} returns selected item from MaxToneHoldCount
end

% --- Executes during object creation, after setting all properties.
function MaxToneHoldCount_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MaxToneHoldCount (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in stopsession.
% stops the current session
function stopsession_Callback(hObject, eventdata, handles)
% hObject    handle to stopsession (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global stoptrial
stoptrial = 1;
end


% --- Executes on button press in lickstatus.
function lickstatus_Callback(hObject, eventdata, handles)
% hObject    handle to lickstatus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --- Executes on button press in autowaterdelivery.
function autowaterdelivery_Callback(hObject, eventdata, handles)
% hObject    handle to autowaterdelivery (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end
% Hint: get(hObject,'Value') returns toggle state of autowaterdelivery



function numnogotones_Callback(hObject, eventdata, handles)
% hObject    handle to numnogotones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numnogotones as text
%        str2double(get(hObject,'String')) returns contents of numnogotones as a double
end

% --- Executes during object creation, after setting all properties.
function numnogotones_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numnogotones (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% This function creates trials
function trialorder = trial_creator(numtrials,a)
prevtrial = 2; % previous trial to keep track of how many trials have been the same
trialorder = zeros(numtrials,1);
a = a/100;
sametrialcount = 0;% keeps track of how many trials of the same kind has been created in a row
for i = 1:numtrials
    temp = rand;% create a random variable to start the 
    if sametrialcount == 3
        % if 3 of the same trial type has been presented, automatically set
        % the next trial to be the other type
        if prevtrial == 1
            temp = 1; % if last trial was a reward trial, make sure the random number generates a non-reward trial
        else
            temp = 0;
        end
    end
    if (temp < a) 
        trialorder(i) = 2;
    else
        % the difficulty determines how many different tones are mixed into
        % the trials
        trialorder(i) = 1;
    end
    % Check how many trials of the same kind in a row has been created
    if prevtrial == 1 && trialorder(i) == 2
        % the last trial and the current trial are both reward trials,
        % increase the same trial counter
        sametrialcount = sametrialcount + 1;
    elseif prevtrial ~= 1 && trialorder(i) ~= 2
        % the lasts trial and the current trial are both non-rewarding
        % trials,  increase the same trial counter
        sametrialcount = sametrialcount + 1;
    else
        % the last trial and current trial are not matched, reset the
        % counter to 1
        sametrialcount = 1;
    end
    
    % set the prev trial 
    if trialorder(i) == 2
        prevtrial = 1;
    else
        prevtrial = 0;
    end
end

end



function dropsize_Callback(hObject, eventdata, handles)
% hObject    handle to dropsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of dropsize as text
%        str2double(get(hObject,'String')) returns contents of dropsize as a double
global dropsize taskParam
dropsize = str2double(get(handles.dropsize,'String'));
scSendMessage(handles.sHandle,['dropsize=',num2str(dropsize),';']);
taskParam.dropsize = dropsize;
end

% --- Executes during object creation, after setting all properties.
function dropsize_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dropsize (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function readEncoderCallback(object,eventdata)
    global s encReadout
    temp = fscanf(s,'%i');
    if ~isempty(temp)
        encReadout = temp;
    end
end



function corr_length_Callback(hObject, eventdata, handles)
% hObject    handle to corr_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of corr_length as text
%        str2double(get(hObject,'String')) returns contents of corr_length as a double
global approachCorridorLength appCorrLength_converted pixpercm_x taskParam
approachCorridorLength = str2double(get(handles.corr_length,'String'));
appCorrLength_converted = round(approachCorridorLength*pixpercm_x);
taskParam.approachCorridorLength = approachCorridorLength;
end

% --- Executes during object creation, after setting all properties.
function corr_length_CreateFcn(hObject, eventdata, handles)
% hObject    handle to corr_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function cleanupWindow
    % restart the PTB window to reduce memory overload at a given frequency
    global window screenNumber grey
    Screen('Close',window)
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 3);
    [window, winRect] = PsychImaging('OpenWindow', screenNumber, grey);
    
end



function prob_go_Callback(hObject, eventdata, handles)
% hObject    handle to prob_go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of prob_go as text
%        str2double(get(hObject,'String')) returns contents of prob_go as a double
global go_probability taskParam
go_probability = str2double(get(hObject,'String'));
taskParam.go_probability = go_probability;
end



% --- Executes during object creation, after setting all properties.
function prob_go_CreateFcn(hObject, eventdata, handles)
% hObject    handle to prob_go (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

function rewardControllerCallback(device,event)
% callback for when data is received from Arduino
    newLine = readline(device);
    if (device.UserData.logFileHandle ~= -1) %if a log file is open, write the line to it
        fprintf(device.UserData.logFileHandle,[newLine{:},'\n']);
    end
    
    disp(newLine)
    
    if ~isempty(device.UserData.callbackFunctionHandle)
        feval(device.UserData.callbackFunctionHandle,device,newLine);
    end  
end

function cameraFrameCallback(device,event)
% callback for when data is received from Arduino
global autoclick frameRead
    frameRead = str2double(readline(device));
end

function LiveCallback_AUDshaping4(sHandle,newLine)

%this is the custom callback function.  When events occur, scCallback will
%call this function. 
%sHandle is the handle to the open serial object
%newLine is the last text string sent from the microcontroller

%this function works with the main program to allow real time reading of
%the output of the statescript microcontroller

%the history is stored in the serial object for future use: sHandle.UserData.history
%and it is a 2-column matrix [trialtype rewardreceived].  In this example, the code
%assumes that the trial type is either 0 (no-go) or  1 (go).  Reward
%is either 0 (reward not received) or 1 (reward received).

% V2 update (2015-09-21)
% Callbacks for timeout is added

%now we update the trial and reward history
global exp_history rewardreceived nRewards manualTrial autoWater licked framedata_app framedata_grating leftLick rightLick
if ~isempty(strfind(newLine,'gostate = 6'))
    if manualTrial == 1
        exp_history(sHandle.UserData.trialnum,2) = 0;
    elseif sHandle.UserData.rewardreceived == 1
        exp_history(sHandle.UserData.trialnum,2) = 1;
    elseif sHandle.UserData.rewardreceived == 2
        exp_history(sHandle.UserData.trialnum,2) = 2;
    else
        exp_history(sHandle.UserData.trialnum,2) = 0;
    end
elseif ~isempty(strfind(newLine,'gostate = 5'))
    if sHandle.UserData.rewardreceived == 1
        exp_history(sHandle.UserData.trialnum,2) = 1;
    elseif sHandle.UserData.rewardreceived == 2
        exp_history(sHandle.UserData.trialnum,2) = 2;
    else
        exp_history(sHandle.UserData.trialnum,2) = 0;
    end
elseif ~isempty(strfind(newLine,'gostate = 3'))
    sHandle.UserData.rewardreceived = 0;
    exp_history(sHandle.UserData.trialnum,1) = 1;
% elseif ~isempty(strfind(newLine,'gostate = ')) % if manual open valve is pressed
%     sHandle.UserData.rewardreceived = 0;
%     sHandle.UserData.history(sHandle.UserData.trialnum,1) = 3;
% elseif ~isempty(strfind(newLine,' 0 2'))
%     % do nothing if valve is manually opened
elseif ~isempty(strfind(newLine,'left lick')) && ~sHandle.UserData.rewardreceived
    sHandle.UserData.rewardreceived = 1;
    licked = 1;
    leftLick = 1;
elseif ~isempty(strfind(newLine,'right lick')) && ~sHandle.UserData.rewardreceived
    sHandle.UserData.rewardreceived = 2;
    licked = 1;
    rightLick = 1;
    % Timeout cases
elseif ~isempty(strfind(newLine,'lick')) && sHandle.UserData.timeoutstatus ~= 0
    % Lengthen timeout if the mouse licks during the timeout
    sHandle.UserData.lengthentimeout = 1;

elseif ~isempty(strfind(newLine,'manually')) & licked == 0
    manualTrial = 1;
elseif ~isempty(strfind(newLine,'left lick'))
    leftLick = 1;
elseif ~isempty(strfind(newLine,'right lick'))
    rightLick = 1;
end
if ~isempty(strfind(newLine,'reward'))
    nRewards = nRewards + 1;
    rewardreceived = 1;
end
end

% --- Executes on button press in AutoClicker.
function AutoClicker_Callback(hObject, eventdata, handles)
global autoclick
% hObject    handle to AutoClicker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if get(hObject,'Value')
    write(autoclick,4,"int8")
else
    write(autoclick,9,"int8")
end
% Hint: get(hObject,'Value') returns toggle state of AutoClicker
end


% --- Executes on button press in XLeft.
function XLeft_Callback(hObject, eventdata, handles)
% hObject    handle to XLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of XLeft
if get(hObject,'Value')
    write(handles.sHandle,10,"int8")
else
    write(handles.sHandle,11,"int8")
end
end
% --- Executes on button press in XRight.
function XRight_Callback(hObject, eventdata, handles)
% hObject    handle to XRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of XRight
if get(hObject,'Value')
    write(handles.sHandle,12,"int8")
else
    write(handles.sHandle,13,"int8")
end
end


% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global grey window
   Screen('FillRect', window, grey);
Screen('Flip', window); 
end
