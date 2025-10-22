%% running_reward_association_2AFC_vGitHub.m
% By Brian Jeon @ CMU/Chase Lab
% bjeon@cmu.edu

% 2016-10-17
% integrated balltracker to the shaping system.  The mouse must stay still
% for at least 2 seconds in addition to the no licking requirement.

% 2016-07-15
% added beep to go along with the reward tone
% reduced the sound to 75% of the full amplitude to allow for beep to be
% heard

% 2015-10-02

% the running_reward_association_2AFC_vGitHub is built from behaviortrainingv4 with only the go
% trials

function varargout = running_reward_association_2AFC_vGitHub(varargin)
% RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB MATLAB code for running_reward_association_2AFC_vGitHub.fig
%      RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB, by itself, creates a new RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB or raises the existing
%      singleton*.
%
%      H = RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB returns the handle to a new RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB or the handle to
%      the existing singleton*.
%
%      RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB.M with the given input arguments.
%
%      RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB('Property','Value',...) creates a new RUNNING_REWARD_ASSOCIATION_2AFC_VGITHUB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before running_reward_association_2AFC_vGitHub_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to running_reward_association_2AFC_vGitHub_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help running_reward_association_2AFC_vGitHub

% Last Modified by GUIDE v2.5 20-Oct-2025 15:28:18

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @running_reward_association_2AFC_vGitHub_OpeningFcn, ...
                   'gui_OutputFcn',  @running_reward_association_2AFC_vGitHub_OutputFcn, ...
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

% --- Executes just before running_reward_association_2AFC_vGitHub is made visible.
function running_reward_association_2AFC_vGitHub_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output argHs, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to running_reward_association_2AFC_vGitHub (see VARARGIN)
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

% Choose default command line output for running_reward_association_2AFC_vGitHub
clear global

handles.output = hObject;

%% Initialize Lickports
global exp_history
ser_port = 'COM4'; % serial port that Arduino is connected to
baud = 9600; % communication speed
callbackFunctionHandle = @LiveCallback_AUDshaping4; % Custom callback function handle
handles.sHandle = serialport(ser_port, baud, 'DataBits',8,'StopBits',1,'Parity','none');
pause(2) % allow time for matlab to set up serial communication with the arduino
configureTerminator(handles.sHandle,'CR/LF');
configureCallback(handles.sHandle,'terminator',@rewardControllerCallback);
% set up a log file
d = datestr(now); %current date and time
d = d(setdiff(1:length(d),strfind(d,':'))); %remove :'s
d(strfind(d,' ')) = '_'; %change space to underscore
handles.sHandle.UserData.templogfilename = ['scLog_',d,'.txt'];
scLogFile = fopen(handles.sHandle.UserData.templogfilename,'w+'); %automatically start logging to a new file
handles.sHandle.UserData.logFileHandle = scLogFile;
handles.sHandle.UserData.history = [];
handles.sHandle.UserData.callbackFunctionHandle = callbackFunctionHandle;
exp_history = [];
flush(handles.sHandle)

%% Initialize Autoclicker
global autoclick
serPort = 'COM5';
baud2 = 9600;
autoclick = serialport(serPort, baud2, 'DataBits',8,'StopBits',1,'Parity','none');
pause(2)
configureTerminator(autoclick,'CR/LF');
flush(autoclick);

%% initialize Wheel Encoder
global s
s = serial('COM3', 'BaudRate', 9600);
fopen(s);
pause(1);
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
handles.decisiontime = 6;
handles.rewarddelay = 0.5;
handles.numRewards = 0; % handle to keep track of the number of rewards
handles.iti = 2;
handles.currenttrial = 0;
handles.datasaved = 0;
screenDistance = 25;
guidata(hObject, handles);
axes(handles.axes1)
global dropsize primed default_timeout imageCenteringTime sensitivityControl
dropsize = 80;
primed = 0;
default_timeout = 3; %default timeout

hold on

%% set up psych toolbox
global window black targetLocation screenXpixels screenYpixels
global theRects leftImageCenter rightImageCenter xCenter yCenter imageSep
global imageWidth ifi grey centerBox imageTexture_all corridorImage encConversionFactor pixpercm_x
global approachCorridorLength goGratingImage nogoGratingImage skip

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);

% Get the screen numbers
screens = Screen('Screens');

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

% wheel calibration
encConversionFactor = 45/4500; % circumference of the wheel / encoder readout for 1 full rotation.

global gratingtex onedegree onecm
pixpercm_x = 2560/64.135;
pixpercm_y = 1600/40.01;
onedegree = 2*screenDistance*tand(0.5);
onecm = pixpercm_x;
res = ceil(sqrt(screenXpixels^2+screenYpixels^2));
gratingtex = CreateProceduralSineGrating(window,res, res, [0.5 0.5 0.5 1]);

global stoptrial trialnum
stoptrial = 1;
trialnum = 0;

% Bias prevention variables
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR
biasauto = 0;
numtrialsbias = 3;
biasprotectionL = 0;
biasprotectionR = 0;
consecutiveL = 0;
consecutiveR = 0;
skip = 0;

global grating_angle_go grating_angle_nogo appCorrLength_converted gratingCorridorLength_pix go_probability rewardzone autowater

approachCorridorLength = 20;  % length of the approach corridor in cm
appCorrLength_converted = round(approachCorridorLength*pixpercm_x);
go_probability = 50;
rewardzone = 0;
autowater = 0;

%% organize config as structure to save.
global taskParam
% taskParam.centerBoxPercent = centerBoxPercent;% Size of for center of rectangle to fall within--20% of image width
taskParam.dropsize = dropsize;
taskParam.CorridorLength = approachCorridorLength;
taskParam.iti = handles.iti;
taskParam.decisiontime = handles.decisiontime;

end
% UIWAIT makes running_reward_association_2AFC_vGitHub wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = running_reward_association_2AFC_vGitHub_OutputFcn(hObject, eventdata, handles) 
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
global stoptrial results trialschedule mouseChoice taskParam imageTypeSchedule imagePairSchedule
stoptrial = 1;

data=results;
savename_Callback(hObject,[],handles);
A = exist([handles.fname,'.mat'],'file');
if A ~= 0
    msgbox('File exists. Enter a new name!');
    return;
end
save([handles.fname,'.mat'],'data','trialschedule','taskParam')
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
        % scClose(handles.sHandle)
        fclose(handles.balltracker);% close balltracker serial object
        delete(handles.balltracker);% delete balltracker serial object
        Screen('CloseAll')
        fclose(handles.sHandle.UserData.logFileHandle); %close the log file
        delete(handles.sHandle.UserData.templogfilename);
        delete(handles.sHandle)
        delete(hObject);
        write(autoclick,9,"int8")
    catch
        allports = instrfindall;
        fclose(allports);
        delete(allports);
        Screen('CloseAll')
        delete(hObject);
        write(autoclick,9,"int8")
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
global  trialschedule window ...
    corridorImage encConversionFactor go_probability
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
    trialschedule = trial_creator(handles.numtrialtotal,go_probability);

    % get number of tones used for this shaping
    % create imageType schedule
    % each pair of images are evenly distributed
    % shuffle the image type order so that it is random
end
mkdir([handles.fname,'_encData'])

trialcomplete = 0;
trialcount = 0;
global stoptrial results encReadout screenXpixels screenYpixels pixpercm_x appCorrLength_converted encoderData_decision 
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater skip
stoptrial = 0;
KbReleaseWait;
while ~trialcomplete && ~stoptrial
    handles.sHandle.UserData.trialnum = handles.sHandle.UserData.trialnum + 1;
%   Initialize the current position on the track
    CurrPos = 1; % set the start point at the beginning of the track
    skip = 0;
    CurrEncPos = encReadout; % current position at the time of encoder readout
    trialcount = trialcount + 1;
    handles.currenttrial=handles.currenttrial + 1;
     datacount = 1;
     encoderData_app = zeros(1,2);
    % the corridor starts
    inApproach = true;% variable to see whether the animal has reached the end of the corridor
    write(handles.sHandle,0,"int8")
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
tic;
    while inApproach
        %find whether there was a change in rotary encoder position
        if encReadout ~= CurrEncPos
            % if there was a change in position
            t = toc;
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
                 encoderData_app(datacount,1) = t;
                 encoderData_app(datacount,2) = movement; 
                 datacount = datacount + 1;
            end
        end
        if skip == 1
            break;
        end
        drawnow();
    end
    
    if trialschedule(trialcount) == 2
        whiteScreen(hObject,handles);
    else
        blackScreen(hObject,handles);
    end

        write(handles.sHandle,6,"int8")    
        tic;
        interTrialZone = true;
        encoderData_it = zeros(1,2);
        datacountIT = 1;
        CurrEncPos = encReadout;
        while interTrialZone
            t = toc;
            if encReadout ~= CurrEncPos
                % if there was a change in position
                movement = encReadout - CurrEncPos;
                CurrEncPos = encReadout;
                encoderData_it(datacountIT,1) = t;
                encoderData_it(datacountIT,2) = movement;
                datacountIT = datacountIT +1;
            end
            drawnow();
            if t > handles.iti
                interTrialZone = false;
            end
        end
        save([handles.fname,'_encData',filesep,'trial_',sprintf('%03d',handles.currenttrial),'.mat'],'encoderData_app','encoderData_decision','encoderData_it'); 
    % Timeout
    global exp_history
    % Performance Feedback Display
    % left hit
    if  exp_history(handles.currenttrial,2)== 1   
        handles.result(2,1) = handles.result(2,1) + 1;
        scatter(handles.currenttrial,1,'go','filled','Linewidth',0.25)
        results(handles.currenttrial) = 1;
    % right hit
    elseif exp_history(handles.currenttrial,2)== 2
        handles.result(1,1)=handles.result(1,1)+1;
        scatter(handles.currenttrial,1,'ro','filled','Linewidth',0.25) %mark blue if primed 
        results(handles.currenttrial) = 2;
    % miss
    elseif exp_history(handles.currenttrial,2)== 0
        handles.result(3,1)=handles.result(3,1)+1;
        scatter(handles.currenttrial,1,'ko','filled','Linewidth',0.25)
        results(handles.currenttrial) = 0 ;
    % auto left
    elseif exp_history(handles.currenttrial,2)== 3
        handles.result(2,2)=handles.result(2,2)+1;
        scatter(handles.currenttrial,1,'go','Linewidth',0.25)
        results(handles.currenttrial) = 3 ;
    % auto right
    elseif exp_history(handles.currenttrial,2)== 4
        handles.result(1,2)=handles.result(1,2)+1;
        scatter(handles.currenttrial,1,'ro','Linewidth',0.25)
        results(handles.currenttrial) = 4 ;
    end
    set(handles.uitable2,'Data',num2cell(handles.result))
    if results(handles.currenttrial)~= 0
        handles.numRewards = handles.numRewards+1;
    end
    % Update Accuracy Information
    totalacc = (handles.result(1,1)+handles.result(2,1))/sum(sum(handles.result));
    TPR = (handles.result(2,1))/(handles.result(1,1)+handles.result(2,1));
    TNR = (handles.result(1,1))/(handles.result(1,1)+handles.result(2,1));
    S = [num2str(handles.numRewards)];
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
    guidata(hObject,handles);
    drawnow();

    if results(handles.currenttrial) == 1
        if consecutiveR == 0
            consecutiveL = consecutiveL + 1;
        else
            consecutiveL = 0;
            consecutiveR = 0;
            numtrialsbias = randi([3 8],1);
        end
    elseif results(handles.currenttrial) == 2
        if consecutiveL == 0
            consecutiveR = consecutiveR + 1;
        else
            consecutiveL = 0;
            consecutiveR = 0;
            numtrialsbias = randi([3 8],1);
        end
    end

    if consecutiveL == numtrialsbias
        write(handles.sHandle,5,"int8")
        biasprotectionL = 1;
        consecutiveL = 0;
        consecutiveR = 0;
        numtrialsbias = randi([3 8],1);
        biasauto = 1;
    end
    if consecutiveR == numtrialsbias
        write(handles.sHandle,2,"int8")
        biasprotectionR = 1;
        consecutiveL = 0;
        consecutiveR = 0;
        numtrialsbias = randi([3 8],1);
        biasauto = 1;
    end

    end
    set(handles.status,'ForegroundColor',[0,1,0])
    set(handles.status,'String','Trials complete!')
    set(handles.playstim,'Enable','on')
    guidata(hObject,handles)
    stoptrial = 1;
end

function whiteScreen(hObject,handles)
global primed window  screenXpixels
global    imageTexture1  grey white
global encReadout CurrEncPos pixpercm_x encConversionFactor gratingCorridorLength_pix dropsize goGratingImage screenYpixels encoderData_decision 
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater rewardreceived
% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
write(handles.sHandle,7,"int8") 
Screen('FillRect', window, white);
Screen('Flip', window);
datacount = 1;
encoderData_decision = zeros(1,2);
inGratingCorr = true;
CurrEncPos = encReadout;
tic;
while inGratingCorr
     t = toc;
     if encReadout ~= CurrEncPos
        % if there was a change in position
        movement = encReadout - CurrEncPos;
        CurrEncPos = encReadout;
        encoderData_decision(datacount,1) = t;
        encoderData_decision(datacount,2) = movement;
        datacount = datacount +1;
     end
     if t > handles.rewarddelay && rewardzone == 0
         write(handles.sHandle,3,"int8") 
         rewardzone = 1;
     end

     if t > handles.decisiontime
         inGratingCorr = false;
     end
     if t > handles.iti && autowater == 0
         if (get(handles.autowaterdelivery,'Value') == 1) || biasauto == 1
             if (rewardreceived ~= 1)
             write(handles.sHandle,1,"int8") % send message to manually trigger reward
             autowater = 1;
             end
         end
     end
     drawnow();
end
Screen('FillRect', window, grey);
Screen('Flip', window);
rewardzone = 0;
autowater = 0;
biasauto = 0;
end

function blackScreen(hObject,handles)
global primed window black targetLocation screenXpixels
global theRects leftImageCenter rightImageCenter xCenter yCenter imageSep sensitivityControl
global imageWidth s ifi imageTexture1 imageTexture2 grey centerBox imageCenteringTime gratingtex onedegree onecm screenYpixels
global encReadout CurrEncPos pixpercm_x encConversionFactor gratingCorridorLength_pix nogoGratingImage encoderData_decision
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater rewardreceived
% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
write(handles.sHandle,7,"int8") 
Screen('FillRect', window, black);
Screen('Flip', window);
datacount = 1;
encoderData_decision = zeros(1,2);
inGratingCorr = true;
CurrEncPos = encReadout;
tic;
while inGratingCorr
     t = toc;
     if encReadout ~= CurrEncPos
        % if there was a change in position
        movement = encReadout - CurrEncPos;
        CurrEncPos = encReadout;
        encoderData_decision(datacount,1) = t;
        encoderData_decision(datacount,2) = movement;
        datacount = datacount +1;
     end
     if t > handles.rewarddelay && rewardzone == 0
         write(handles.sHandle,3,"int8") 
         rewardzone = 1;
     end

     if t > handles.decisiontime
         inGratingCorr = false;

     end
     if t > handles.iti && autowater == 0
         if (get(handles.autowaterdelivery,'Value') == 1) || biasauto == 1
             if (rewardreceived ~= 1)
             write(handles.sHandle,1,"int8") % send message to manually trigger reward
             autowater = 1;
             end
         end
     end
     drawnow();
end

Screen('FillRect', window, grey);
Screen('Flip', window);
rewardzone = 0;
autowater = 0;
biasauto = 0;
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
    write(handles.sHandle,1,"int8")
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
function trialorder = trial_creator(numtrials,difficulty)
prevtrial = 2; % previous trial to keep track of how many trials have been the same
trialorder = zeros(numtrials,1);
sametrialcount = 0;% keeps track of how many trials of the same kind has been created in a row
for i = 1:numtrials
    temp = rand;% create a random variable to start the 
    if sametrialcount == 3
        % if 3 of the same trial type has been presented, automatically set
        % the next trial to be the other type
        if prevtrial == 1
            temp = temp/2; % if last trial was a reward trial, make sure the random number generates a non-reward trial
        else
            temp = 1;
        end
    end
    if (temp > 0.5) 
        trialorder(i) = 2;
    elseif (temp <= 0.5)
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
     %   disp(num2str(encReadout));
    end
end



function corr_length_Callback(hObject, eventdata, handles)
% hObject    handle to corr_length (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of corr_length as text
%        str2double(get(hObject,'String')) returns contents of corr_length as a double
global approachCorridorLength appCorrLength_converted pixpercm_x
approachCorridorLength = str2double(get(handles.corr_length,'String'));
appCorrLength_converted = round(approachCorridorLength*pixpercm_x);
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


%%
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
global exp_history rewardreceived
if ~isempty(strfind(newLine,'gostate = 6'))
    if sHandle.UserData.rewardreceived == 1
        exp_history(sHandle.UserData.trialnum,2) = 1;
    elseif sHandle.UserData.rewardreceived == 2
        exp_history(sHandle.UserData.trialnum,2) = 2;
    elseif sHandle.UserData.rewardreceived == 3
        exp_history(sHandle.UserData.trialnum,2) = 3;
    elseif sHandle.UserData.rewardreceived == 4
        exp_history(sHandle.UserData.trialnum,2) = 4;
    else
        exp_history(sHandle.UserData.trialnum,2) = 0;
    end
end
if ~isempty(strfind(newLine,'gostate = 3'))
    sHandle.UserData.rewardreceived = 0;
    exp_history(sHandle.UserData.trialnum,1) = 1;
    rewardreceived = 0;
elseif ~isempty(strfind(newLine,'left reward triggered!'))
    sHandle.UserData.rewardreceived = 1;
    rewardreceived = 1;
elseif ~isempty(strfind(newLine,'right reward triggered!'))
    sHandle.UserData.rewardreceived = 2;
    rewardreceived = 1;
elseif ~isempty(strfind(newLine,'left manually rewarded!')) && sHandle.UserData.rewardreceived == 0
    sHandle.UserData.rewardreceived = 3;
    rewardreceived = 1;
elseif ~isempty(strfind(newLine,'right manually rewarded!')) && sHandle.UserData.rewardreceived == 0
    sHandle.UserData.rewardreceived = 4;
    rewardreceived = 1;
end
end


% --- Executes on button press in DecisionButton.
function DecisionButton_Callback(hObject, eventdata, handles)
% hObject    handle to DecisionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global skip
skip = 1;
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


% --- Executes on button press in valveL.
function valveL_Callback(hObject, eventdata, handles)
% hObject    handle to valveL (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
write(handles.sHandle,10,"int8")
end

% --- Executes on button press in valveR.
function valveR_Callback(hObject, eventdata, handles)
% hObject    handle to valveR (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
write(handles.sHandle,11,"int8")
end


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
global grey window
   Screen('FillRect', window, grey);
   Screen('Flip', window); 
end
