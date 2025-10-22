%% Circles_Discrimination_vGitHub.m
% By Michael Crespo @ UB
% mdcrespo@buffalo.edu

% 2025-08-26

% the Circles_Discrimination_vGitHub is built from running_reward_association_2AFC_v241107
% Requires mouse to lick upon initiated presentation of go stimulus

function varargout = Circles_Discrimination_vGitHub(varargin)
% CIRCLES_DISCRIMINATION_VGITHUB MATLAB code for Circles_Discrimination_vGitHub.fig
%      CIRCLES_DISCRIMINATION_VGITHUB, by itself, creates a new CIRCLES_DISCRIMINATION_VGITHUB or raises the existing
%      singleton*.
%
%      H = CIRCLES_DISCRIMINATION_VGITHUB returns the handle to a new CIRCLES_DISCRIMINATION_VGITHUB or the handle to
%      the existing singleton*.
%
%      CIRCLES_DISCRIMINATION_VGITHUB('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CIRCLES_DISCRIMINATION_VGITHUB.M with the given input arguments.
%
%      CIRCLES_DISCRIMINATION_VGITHUB('Property','Value',...) creates a new CIRCLES_DISCRIMINATION_VGITHUB or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Circles_Discrimination_vGitHub_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Circles_Discrimination_vGitHub_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Circles_Discrimination_vGitHub

% Last Modified by GUIDE v2.5 20-Oct-2025 16:14:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Circles_Discrimination_vGitHub_OpeningFcn, ...
                   'gui_OutputFcn',  @Circles_Discrimination_vGitHub_OutputFcn, ...
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

% --- Executes just before Circles_Discrimination_vGitHub is made visible.
function Circles_Discrimination_vGitHub_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output argHs, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Circles_Discrimination_vGitHub (see VARARGIN)
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

% Choose default command line output for Circles_Discrimination_vGitHub
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
handles.sHandle.UserData.templogfilename = ['scLog1_',d,'.txt'];
scLogFile = fopen(handles.sHandle.UserData.templogfilename,'w+'); %automatically start logging to a new file
handles.sHandle.UserData.logFileHandle = scLogFile;
handles.sHandle.UserData.history = [];
handles.sHandle.UserData.callbackFunctionHandle = callbackFunctionHandle;
exp_history = [];
flush(handles.sHandle)

%% Update handles structure
set(handles.status,'String','Ready!')
set(handles.status,'ForegroundColor',[0,1,0])
handles.sHandle.UserData.rewardreceived = 0;
handles.sHandle.UserData.trialnum = 0;
handles.sHandle.UserData.timeoutstatus = 0;
handles.sHandle.UserData.lengthentimeout = 0;
handles.result=zeros(3,2);
handles.decisiontime = 4;
handles.rewarddelay = 0.5;
handles.numRewards = 0; % handle to keep track of the number of rewards
handles.itiMin = 0.5;
handles.itiMax = 2.5;
handles.timeAfterReward = 0.5;
handles.currenttrial = 0;
handles.datasaved = 0;
screenDistance = 25;
guidata(hObject, handles);
axes(handles.axes1)
global dropsize primed default_timeout imageCenteringTime sensitivityControl nRewards
dropsize = 45;
primed = 0;
default_timeout = 3; %default timeout
nRewards = 0;

hold on

%% set up psych toolbox
global window black targetLocation screenXpixels screenYpixels
global theRects leftImageCenter rightImageCenter xCenter yCenter imageSep
global imageWidth ifi grey centerBox imageTexture_all corridorImage encConversionFactor pixpercm_x
global approachCorridorLength circlesImage nogoGratingImage screenNumber

PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 0);

% Get the screen numbers
screens = Screen('Screens');

% Draw to the external screen if avaliable
% screenNumber = max(screens);
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

global gratingtex onedegree onecm
pixpercm_x = 2560/43.18;
pixpercm_y = 1600/40.01;
onedegree = 2*screenDistance*tand(0.5);
onecm = pixpercm_x;
res = ceil(sqrt(screenXpixels^2+screenYpixels^2));
gratingtex = CreateProceduralSineGrating(window,res, res, [0.5 0.5 0.5 1]);

global stoptrial trialnum
stoptrial = 1;
trialnum = 0;

global grating_angle_go grating_angle_nogo appCorrLength_converted gratingCorridorLength_pix go_probability rewardzone autowater maxConsecutive

go_probability =30;
maxConsecutive = 10;
rewardzone = 0;
autowater = 0;

%% organize config as structure to save.
global taskParam
% taskParam.centerBoxPercent = centerBoxPercent;% Size of for center of rectangle to fall within--20% of image width
taskParam.dropsize = dropsize;
taskParam.itiMin = handles.itiMin;
taskParam.itiMax = handles.itiMax;
taskParam.decisiontime = handles.decisiontime;
taskParam.maxConsecutive = maxConsecutive;
taskParam.go_probability = go_probability;

end
% UIWAIT makes Circles_Discrimination_vGitHub wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Circles_Discrimination_vGitHub_OutputFcn(hObject, eventdata, handles) 
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
global stoptrial results trialschedule mouseChoice taskParam imageTypeSchedule imagePairSchedule pixpos
stoptrial = 1;

data=results;
savename_Callback(hObject,[],handles);
A = exist([handles.fname,'.mat'],'file');
if A ~= 0
    msgbox('File exists. Enter a new name!');
    return;
end
%save([handles.fname,'.mat'],'data','trialschedule','taskParam','pixpos')
save([handles.fname,'.mat'],'data','trialschedule','taskParam','pixpos', 'results')
copyfile(handles.sHandle.UserData.templogfilename,[handles.fname,'.txt']);
handles.datasaved = 1;
guidata(hObject,handles)
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
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
        Screen('CloseAll')
        fclose(handles.sHandle.UserData.logFileHandle); %close the log file
        %delete(handles.sHandle.UserData.templogfilename);       
        delete(handles.sHandle)
        delete(hObject);
    catch
        allports = instrfindall;
        fclose(allports);
        delete(allports);
        Screen('CloseAll')
        delete(hObject);
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
    case 6
        set(handles.axes1,'XLim',[500 600]);
    case 7
        set(handles.axes1,'XLim',[600 700]);
    case 8
        set(handles.axes1,'XLim',[700 800]);
    case 9
        set(handles.axes1,'XLim',[800 900]);
    case 10
        set(handles.axes1,'XLim',[900 1000]);
    case 11
        set(handles.axes1,'XLim',[1000 1100]);
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
    corridorImage encConversionFactor go_probability trialcount
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

trialcomplete = 0;
trialcount = 0;
global stoptrial results encReadout screenXpixels screenYpixels pixpercm_x appCorrLength_converted encoderData_decision 
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater trialInitiated
stoptrial = 0;
KbReleaseWait;
while ~trialcomplete && ~stoptrial

    handles.sHandle.UserData.trialnum = handles.sHandle.UserData.trialnum + 1;
    %   Initialize the current position on the track
    CurrPos = 1; % set the start point at the beginning of the track
    trialcount = trialcount + 1;
    handles.currenttrial=handles.currenttrial + 1;
    datacount = 1;
    trialInitiated = 0;
    % the corridor starts
    inApproach = true;% variable to see whether the animal has reached the end of the corridor
    set(handles.status,'ForegroundColor',[1,0,0])
    set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
    drawnow();
    write(handles.sHandle,0,"int8")
    tic;
    while inApproach
        %find whether there was a change in rotary encoder position
        t = toc;
        if trialInitiated == 1
            inApproach = false;
        end
        drawnow();
    end

    if trialschedule(trialcount) == 2
        go(hObject,handles);
    else
        nogo(hObject,handles);
    end
 
    write(handles.sHandle,6,"int8")
    pause(handles.itiMin)
    % Timeout
    global exp_history leftLick rightLick nRewards
    % Performance Feedback Display
    % hit
    if  exp_history(handles.currenttrial,2)== 2 && exp_history(handles.currenttrial,1)== 1
        handles.result(1,1) = handles.result(1,1) + 1;
        scatter(handles.currenttrial,1,'go','filled','Linewidth',0.25)
        results(handles.currenttrial) = 1;
        handles.numRewards = handles.numRewards+1;
    % miss
    elseif exp_history(handles.currenttrial,2)== 0 && exp_history(handles.currenttrial,1)== 1
        handles.result(2,1)=handles.result(2,1)+1;
        scatter(handles.currenttrial,1,'ko','filled','Linewidth',0.25) %mark blue if primed 
        results(handles.currenttrial) = 2;
    % correct reject
    elseif rightLick == 0 && exp_history(handles.currenttrial,1)== 0
        handles.result(1,2)=handles.result(1,2)+1;
        scatter(handles.currenttrial,2,'ro','filled','Linewidth',0.25)
        results(handles.currenttrial) = 3 ;
    % false alarm
    elseif rightLick == 1 && exp_history(handles.currenttrial,1)== 0
        handles.result(2,2)=handles.result(2,2)+1;
        scatter(handles.currenttrial,2,'ko','filled','Linewidth',0.25)
        results(handles.currenttrial) = 0 ;        
    end
    set(handles.uitable2,'Data',num2cell(handles.result))
    totalacc = (handles.result(1,1)+handles.result(1,2))/sum(sum(handles.result));
    rewardPercentage = totalacc;
    S = [num2str(nRewards),' (',sprintf('%0.1f',rewardPercentage*100),') %'];
    set(handles.numRewardedTrials,'String',S)
    if trialcount == length(trialschedule)
        trialcomplete = 1;
    end
    guidata(hObject,handles);
    drawnow();

    end
    set(handles.status,'ForegroundColor',[0,1,0])
    set(handles.status,'String','Trials complete!')
    set(handles.playstim,'Enable','on')
    guidata(hObject,handles)
    stoptrial = 1;
end

function go(hObject,handles)
global primed window  screenXpixels
global    imageTexture1  grey white
global encReadout CurrEncPos pixpercm_x encConversionFactor gratingCorridorLength_pix dropsize goGratingImage screenYpixels encoderData_decision 
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater rewardreceived circlesImage
% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
write(handles.sHandle,7,"int8") 
myDots("white","colorBlock",handles)
datacount = 1;
inGratingCorr = true;
timeInTask = handles.decisiontime;
rewarded = 0;
rewardreceived = 0;
tic;
while inGratingCorr
     t = toc;
     if t > handles.rewarddelay & rewardzone == 0
         write(handles.sHandle,3,"int8") 
         rewardzone = 1;
     end

     if t >= timeInTask
         inGratingCorr = false;
     end
     drawnow();
end
Screen('FillRect', window, grey);
Screen('Flip', window);
rewardzone = 0;
end

function nogo(hObject,handles)
global primed window black targetLocation screenXpixels
global theRects leftImageCenter rightImageCenter xCenter yCenter imageSep sensitivityControl
global imageWidth s ifi imageTexture1 imageTexture2 grey centerBox imageCenteringTime gratingtex onedegree onecm screenYpixels
global encReadout CurrEncPos pixpercm_x encConversionFactor gratingCorridorLength_pix nogoGratingImage encoderData_decision
global biasauto numtrialsbias biasprotectionL biasprotectionR consecutiveL consecutiveR rewardzone autowater rewardreceived
% update display
set(handles.status,'ForegroundColor',[1,0,0])
set(handles.status,'String',['Trial ',num2str(handles.currenttrial)])
drawnow();
write(handles.sHandle,8,"int8") 
myDots("black","colorBlock",handles)
datacount = 1;
inGratingCorr = true;
timeInTask = handles.decisiontime;
rewarded = 0;
rewardreceived = 0;
tic;
while inGratingCorr
     t = toc;

     if t >= timeInTask
         inGratingCorr = false;
     end
     drawnow();
end
Screen('FillRect', window, grey);
Screen('Flip', window);
rewardzone = 0;
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

% This function creates trials
function trialorder = trial_creator(numtrials,difficulty)
global maxConsecutive
prevtrial = 2; % previous trial to keep track of how many trials have been the same
trialorder = zeros(numtrials,1);
sametrialcount = 0;% keeps track of how many trials of the same kind has been created in a row
for i = 1:numtrials
    temp = rand;% create a random variable to start the 
    if sametrialcount == maxConsecutive
        % if set amount of the same trial type has been presented, automatically set
        % the next trial to be the other type
        if prevtrial == 1
            temp = 1; % if last trial was a reward trial, make sure the random number generates a non-reward trial
        else
            temp = 0;
        end
    end
    if (temp <= difficulty/100) 
        trialorder(i) = 2;
    elseif (temp > difficulty/100)
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
global exp_history rewardreceived trialInitiated leftLick rightLick nRewards
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
    exp_history(sHandle.UserData.trialnum,1) = 1;
    leftLick = 0;
    rightLick = 0;
elseif ~isempty(strfind(newLine,'gostate = 0'))
    exp_history(sHandle.UserData.trialnum,1) = 0;
    sHandle.UserData.rewardreceived = 0;
    rewardreceived = 0;
elseif ~isempty(strfind(newLine,'gostate = 8'))
    leftLick = 0;
    rightLick = 0;
elseif ~isempty(strfind(newLine,'left reward triggered!'))
    sHandle.UserData.rewardreceived = 1;
    rewardreceived = 1;
    nRewards = nRewards + 1;
elseif ~isempty(strfind(newLine,'right reward triggered!'))
    sHandle.UserData.rewardreceived = 2;
    rewardreceived = 1;
    nRewards = nRewards + 1;
end
if ~isempty(strfind(newLine,'Center Touch!'))
    trialInitiated = 1;
end
if ~isempty(strfind(newLine,'left lick!'))
    leftLick = 1;
end
if ~isempty(strfind(newLine,'right lick!'))
   rightLick = 1; 
end
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

function myDots(dotColor,blockType,handles)
global window grey pixpos screenNumber
% Let's define a structure 'dots' that holds the paramters for the field of dots:

dots.nDots = 40;                % number of dots
dots.size = 50;                   % size of dots (pixels)
dots.center = [0,5];           % center of the field of dots (x,y)
dots.apertureSize = [30,26];     % size of rectangular aperture [w,h] in degrees.

switch dotColor  % color of the dots
    case 'white'
        dots.color = [255,255,255];      
    case 'black'
        dots.color = [0,0,0];
end


% Now we'll define a random position within the aperture for each of the dots. 'dots.x' and 'dots.y'will hold the x and y positions for each dot.

dots.x(handles.currenttrial,:) = (rand(1,dots.nDots)-.5)*dots.apertureSize(1) + dots.center(1);
dots.y(handles.currenttrial,:) = (rand(1,dots.nDots)-.5)*dots.apertureSize(2) + dots.center(2);

display.dist = 30;  %cm
display.width = 43; %cm

%We need to determine the screen resolution, too. We can do this by calling Screen's 'Resolution' function which returns a structure holding the values we want:

tmp = Screen('Resolution',screenNumber);
display.resolution = [tmp.width,tmp.height];

% Converting from visual angle to pixels 

pixpos.x(handles.currenttrial,:) = angle2pix(display,dots.x(handles.currenttrial,:));
pixpos.y(handles.currenttrial,:) = angle2pix(display,dots.y(handles.currenttrial,:));

% This generates pixel positions, but they're centered at [0,0].  The last
% step for this conversion is to add in the offset for the center of the
% screen:
%
pixpos.x(handles.currenttrial,:) = pixpos.x(handles.currenttrial,:) + display.resolution(1)/2;
pixpos.y(handles.currenttrial,:) = pixpos.y(handles.currenttrial,:) + display.resolution(2)/2;

%% present the stimulus

switch blockType
    case 'colorBlock'
        try
            % display.skipChecks=1;
            % display = OpenWindow(display);
            Screen(window,'FillRect',grey);
            Screen('DrawDots',window,[pixpos.x(handles.currenttrial,:);pixpos.y(handles.currenttrial,:)], dots.size, dots.color,[0,0],1);
            Screen('Flip',window);
        catch ME
            Screen('CloseAll');
            rethrow(ME)
        end
      
     
    case 'motionBlock'

            dots.speed = 3;       %degrees/second
            dots.duration = stimDuration;    %seconds
            dots.direction = 90;  %degrees (clockwise from straight up)

            dots.lifetime = 12;  %lifetime of each dot (frames)

                    % First we'll calculate the left, right top and bottom of the aperture (in
                    % degrees)
                    l = dots.center(1)-dots.apertureSize(1)/2;
                    r = dots.center(1)+dots.apertureSize(1)/2;
                    b = dots.center(2)-dots.apertureSize(2)/2;
                    t = dots.center(2)+dots.apertureSize(2)/2;
                    
                    % New random starting positions
                    dots.x = (rand(1,dots.nDots)-.5)*dots.apertureSize(1) + dots.center(1);
                    dots.y = (rand(1,dots.nDots)-.5)*dots.apertureSize(2) + dots.center(2);
                    
                    % Each dot will have a integer value 'life' which is how many frames the
                    % dot has been going.  The starting 'life' of each dot will be a random
                    % number between 0 and dots.lifetime-1 so that they don't all 'die' on the
                    % same frame:
                    
                    dots.life =    ceil(rand(1,dots.nDots)*dots.lifetime);
                    
                    try
                        display = OpenWindow(display);

                         nFrames = sec2frame(display,dots.duration);
                            % We're ready to animate:
                                % The distance traveled by a dot (in degrees) is the speed (degrees/second) divided by the frame rate (frames/second). The units cancel, leaving degrees/frame which makes sense. Basic trigonometry (sines and cosines) allows us to determine how much the changes in the x and y position.
                            % 
                            % So the x and y position changes, which we'll call dx and dy, can be calculated by:
                            
                            dx = dots.speed*sin(dots.direction*pi/180)/display.frameRate;
                            dy = -dots.speed*cos(dots.direction*pi/180)/display.frameRate;


                        for i=1:nFrames
                            %convert from degrees to screen pixels
                            pixpos.x = angle2pix(display,dots.x)+ display.resolution(1)/2;
                            pixpos.y = angle2pix(display,dots.y)+ display.resolution(2)/2;
                            gray=GrayIndex(display.windowPtr); % do not use if need gamma corraction!!  Should be updated in that case
                            Screen(winow,'FillRect',grey);
                            Screen('DrawDots',window,[pixpos.x;pixpos.y], dots.size, dots.color,[0,0],1);
                            %update the dot position
                            dots.x = dots.x + dx;
                            dots.y = dots.y + dy;
                    
                            %move the dots that are outside the aperture back one aperture
                            %width.
                            dots.x(dots.x<l) = dots.x(dots.x<l) + dots.apertureSize(1);
                            dots.x(dots.x>r) = dots.x(dots.x>r) - dots.apertureSize(1);
                            dots.y(dots.y<b) = dots.y(dots.y<b) + dots.apertureSize(2);
                            dots.y(dots.y>t) = dots.y(dots.y>t) - dots.apertureSize(2);
                    
                            %increment the 'life' of each dot
                            dots.life = dots.life+1;
                    
                            %find the 'dead' dots
                            deadDots = mod(dots.life,dots.lifetime)==0;
                    
                            %replace the positions of the dead dots to a random location
                            dots.x(deadDots) = (rand(1,sum(deadDots))-.5)*dots.apertureSize(1) + dots.center(1);
                            dots.y(deadDots) = (rand(1,sum(deadDots))-.5)*dots.apertureSize(2) + dots.center(2);
                    
                            Screen('Flip',display.windowPtr);
                        end
                    catch ME
                        Screen('CloseAll');
                        rethrow(ME)
                    end


    case 'motionBlockTest'
        dots.speed = 3;       %degrees/second
        dots.duration = stimDuration;    %seconds
        dots.direction = 90;  %degrees (clockwise from straight up)

        try
            display = OpenWindow(display);
             % The total number of frames for the animation is determined by the duration (seconds) multiplied by the frame rate (frames/second). Although it's a simple calculation, I've made a function to convert from seconds to frames so I don't ever have to think about it again:
                % 
            nFrames = sec2frame(display,dots.duration);
            % We're ready to animate:
                % The distance traveled by a dot (in degrees) is the speed (degrees/second) divided by the frame rate (frames/second). The units cancel, leaving degrees/frame which makes sense. Basic trigonometry (sines and cosines) allows us to determine how much the changes in the x and y position.
            % 
            % So the x and y position changes, which we'll call dx and dy, can be calculated by:
            
            dx = dots.speed*sin(dots.direction*pi/180)/display.frameRate;
            dy = -dots.speed*cos(dots.direction*pi/180)/display.frameRate;

            for i=1:nFrames
                %convert from degrees to screen pixels
                pixpos.x = angle2pix(display,dots.x)+ display.resolution(1)/2;
                pixpos.y = angle2pix(display,dots.y)+ display.resolution(2)/2;
                Screen(window,'FillRect',grey);
                Screen('DrawDots',window,[pixpos.x;pixpos.y], dots.size, dots.color,[0,0],1);
                %update the dot position
                dots.x = dots.x + dx;
                dots.y = dots.y + dy;
        
                Screen('Flip',display.windowPtr);
            end
        catch ME
            Screen('CloseAll');
            rethrow(ME)
        end


end % switch blockType
end

function [ang] = pix2angle(display, pix)
% [ang] = pix2angle(display, pix)
%
% Converts monitor pixels into degrees of visual angle with the formula:
%
% ang = 2 * arctan(sz/(2*dist)) * (180/pi);
%
% Input:
%   display             A structure containing display information (see 
%                       OpenWindow.m), must have fields: 
%       dist            Distance from screen, cm
%       width           Width of screen, cm
%       resolution      Screen resolution [width height], pixels
% 
%   pix                 Pixels to be converted to visual angles, pixels
%
% Output: 
%   ang                 Converted 'pix' to visual angle, degrees
%
% Example:
% display.dist = 60; % cm
% display.width = 44.5; % cm
% display.resolution = [1680 1050]; % pixels
%
% pix = 100; % pixel size to convert
% ang = pix2angle(display, pix) % visual angles, degrees
% 
% Note:
% - Warning: Assumes isotropic (square) pixels

% Written by G.M. Boynton & Zach Ernst - 11/1/07
% Edited by Kelly Chang - February 23, 2017

%% Convert Pixels to Visual Angels

pixSize = display.width / display.resolution(1); % cm/pix
sz = pix * pixSize; % cm
ang = 2*atan(sz/(2*display.dist))*(180/pi); % visual angle, degrees
end

function [pix] = angle2pix(display, ang)
% [pix] = angle2pix(display, ang)
%
% Converts visual angles in degrees to pixels.
%
% Input:
%   display             A structure containing display information (see 
%                       OpenWindow.m), must have fields: 
%       dist            Distance from screen, cm
%       width           Width of screen, cm
%       resolution      Screen resolution [width height], pixels
% 
%   ang                 Visual angle to be converted to pixels, degrees
%
% Output: 
%   pix                 Converted 'ang' to pixels, pixels
%
% Example:
% display.dist = 60; % cm
% display.width = 44.5; % cm
% display.resolution = [1680 1050]; % pixels
% 
% ang = 2.529; % visual angle to convert, degrees
% pix = angle2pix(display, ang); % pixels
% 
% Note:
% - Warning: Assumes isotropic (square) pixels

% Written by G.M. Boynton & Zach Ernst - 11/1/07
% Edited by Kelly Chang - February 23, 2017

%% Convert Visual Angles to Pixels 

pixSize = display.width / display.resolution(1); % cm/pix
sz = 2*display.dist*tan(pi*ang/(2*180)); % cm
pix = round(sz/pixSize); % pixels
end
