%% Import data from text file
pupilRecorded = 0; % Enter 1 to plot and 0 to skip plotting
txtfileFullName =  ['.txt']; % Enter text file location
fileFullName =  ['.mat']; % Enter Matlab file location
encoderLocation = ['_encData']; % Enter location of folder containing trial files
OutputSaveLocation = ['\dataStruct.mat']; % Enter location of folder where output is desired
if pupilRecorded == 1
pupilLocation = ['.mat']; % Enter Generated Pupil Information Location
predictionLocation = ['.mat']; % Enter DLM Prediction Location
load(pupilLocation)
load(predictionLocation)
end
load(fileFullName)
% import .txt. file (lick times and state)
opts = delimitedTextImportOptions("NumVariables", 5);
% Specify range and delimiter
opts.DataLines = [1, Inf];
opts.Delimiter = [" ", "!"];
% Specify column names and types
opts.VariableNames = ["timestamp_ms", "portInteracted", "eventDescription", "state", "openValveDuration_ms"];
opts.VariableTypes = ["double", "categorical", "categorical", "double", "double"];
% Specify file level properties
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
% Import the data
txtData = readtable(txtfileFullName, opts);
stateTransitions= table2array(txtData(:,4));
timestamps_ms= table2array(txtData(:,1));
lickSide= table2array(txtData(:,2));
catagoryLabels= table2array(txtData(:,3));
% Clear temporary variables
clear opts
%% Sort Trial type
numTotalTrials= numel( find(stateTransitions== 0) );
rewardZoneStartIndices= find(stateTransitions== 3);
gratingStartIndicies=  find(stateTransitions== 2 | stateTransitions== 5);
leftStartIndicies= find(stateTransitions== 2);
rightStartIndicies= find(stateTransitions== 5);
trialStartIndicies= find(stateTransitions== 0);
trialEndIndicies= find(stateTransitions== 6);
isLick_session= catagoryLabels== 'lick';
isLick_sessionLeft= lickSide== 'left' & catagoryLabels== 'lick';
isLick_sessionRight= lickSide== 'right' & catagoryLabels== 'lick';
isGratingStart_session= (stateTransitions== 2 | stateTransitions== 5);
isRewardZoneEntry_session= stateTransitions== 3;
isRewardTriggered_session= catagoryLabels== 'reward'; % mouse licks and triggers the water valve to open
isManualValveOpen_session= catagoryLabels== 'manually';
isGratingEnd_session= stateTransitions== 6;
count=1;
trialType_fromTxt= [];
trialTypeCatagory= categorical(NaN(numTotalTrials,1));
i=1;
while i< gratingStartIndicies(end)+1
    if ismember(i,leftStartIndicies)
        trialType_fromTxt(count)= 2;      % Vertical
        trialTypeCatagory(count)= 'Vertical';
        count=count + 1;
        %disp(i)
    elseif ismember(i,rightStartIndicies)
        trialType_fromTxt(count)= 1;      % Angled
        trialTypeCatagory(count)= 'Angled';
        count=count + 1;
    end
    i=i+1;
end
% Import Encoder Data
Encoder = struct;
if pupilRecorded == 1
Frame = struct;
end
if m == 27
    numTotalTrials = 125;
end
for i=1:numTotalTrials
    trialNum=string(i);
    if i < 10
    load(append(encoderLocation,filesep,'trial_00',trialNum,'.mat'));
    elseif i <100
    load(append(encoderLocation,filesep,'trial_0',trialNum,'.mat')); 
    else
    load(append(encoderLocation,filesep,'trial_',trialNum,'.mat')); 
    end
    if pupilRecorded == 1
    Frame(i).app=frameData_app(:,1:2);
    Frame(i).grating=frameData_grating(:,1:2);
    Frame(i).app = Frame(i).app(all(Frame(i).app,2),:);
    Frame(i).grating = Frame(i).grating(all(Frame(i).grating,2),:);
    try
    Frame(i).app(:,1) = Frame(i).app(:,1) - Frame(i).app(end,1) + (Timestamps_temp(isGratingStart_temp)-Timestamps_temp(1))/1000;
    catch 
        Frame(i).app(:,1) = nan;
    end
    Frameapp_temp = Frame(i).app;
    Framegrating_temp = Frame(i).grating;
    try
    Frameapp_temp(:,1) = Frameapp_temp(:,1)-(max(Frameapp_temp(:,1)))-(min(Frameapp_temp(2,1)));
    Frameapp_temp(:,2)=-Frameapp_temp(:,2);
    catch
        Encoderapp_temp(:,1) = nan;
        Encoderapp_temp(:,2) = nan;
    end
    Frame(i).combined = vertcat(Frameapp_temp, Framegrating_temp);
    end

    Timestamps_temp= timestamps_ms( trialStartIndicies(i): trialEndIndicies(i) );
    isGratingStart_temp= isGratingStart_session( trialStartIndicies(i): trialEndIndicies(i) );

    Encoder(i).app=encoderData_app;
    Encoder(i).grating=encoderData_grating;
    Encoder(i).app(:,2)=encoderData_app(:,2)*45/4500;
    Encoder(i).grating(:,2)=encoderData_grating(:,2)*45/4500;
    Encoder(i).app = Encoder(i).app(all(Encoder(i).app,2),:);
    Encoder(i).grating = Encoder(i).grating(all(Encoder(i).grating,2),:);
    try
    Encoder(i).app(:,1) = Encoder(i).app(:,1) - Encoder(i).app(end,1) + (Timestamps_temp(isGratingStart_temp)-Timestamps_temp(1))/1000;
    catch 
        Encoder(i).app(:,1) = nan;
    end
    Encoder(i).app = [[0 0]; Encoder(i).app];
    Encoderapp_temp = Encoder(i).app;
    Encodergrating_temp = Encoder(i).grating;
    try
    Encoderapp_temp(:,1) = Encoderapp_temp(:,1)-(max(Encoderapp_temp(:,1)))-(min(Encoderapp_temp(2,1)));
    Encoderapp_temp(:,2)=-Encoderapp_temp(:,2);
    catch
        Encoderapp_temp(:,1) = nan;
        Encoderapp_temp(:,2) = nan;
    end
    curPos = -50;
    for rowNum = 1:height(Encoderapp_temp)
        Encoderapp_temp(rowNum,2) = curPos - Encoderapp_temp(rowNum,2);
        curPos = Encoderapp_temp(rowNum,2);
        if curPos < -50
            curPos = -50;
            Encoderapp_temp(rowNum,2) = -50;
        end
    end
    curPos = 0;
    for rowNum = 1:height(Encodergrating_temp)
        Encodergrating_temp(rowNum,2) = curPos + Encodergrating_temp(rowNum,2);
        curPos = Encodergrating_temp(rowNum,2);
        if curPos < 0
            curPos = 0;
            Encodergrating_temp(rowNum,2) = 0;
        end
    end    
    clear isLickRight_tempFrame isLickLeft_tempFrame
    Encoder(i).combined = vertcat(Encoderapp_temp, Encodergrating_temp);
    
    for n=2:height(Encoder(i).combined)
        velocity(i).dif(n,:) = Encoder(i).combined(n,:)-Encoder(i).combined(n-1,:);
    end
    velocity(i).vel(:,1) = Encoder(i).combined(:,1);
    for n=1:length(Encoder(i).combined)
        velocity(i).vel(n,2) = velocity(i).dif(n,2)/velocity(i).dif(n,1);
        if isnan(velocity(i).vel(n,1))
            velocity(i).vel(n,1) = 0;
        end
    end  
    velocity(i).vel(1,2) = nan;
end
% create data structure, # of rows is number of total trials within the session, there are 8 catagories [0,2,3,6,5,lick,manual reward, reward triggered]
dataStruct= struct;
for trialID= 1:numTotalTrials
    numTimestampsInTrial= numel( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).Trial_ID= trialID;
    dataStruct(trialID).Trial_Type= char(trialTypeCatagory(trialID));
    dataStruct(trialID).NoOfTimestamps= numTimestampsInTrial;
    dataStruct(trialID).Timestamps= timestamps_ms( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLick= isLick_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLickLeft= isLick_sessionLeft( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLickRight= isLick_sessionRight( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isGratingStart= isGratingStart_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardZoneEntry= isRewardZoneEntry_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardTriggered= isRewardTriggered_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isManualValveOpen= isManualValveOpen_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isGratingEnd= isGratingEnd_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).encoderData_app= Encoder(trialID).app;
    dataStruct(trialID).encoderData_grating= Encoder(trialID).grating;
    dataStruct(trialID).encoderData_combined= Encoder(trialID).combined;
    dataStruct(trialID).velocity = velocity(trialID).vel;

    if pupilRecorded == 1
    dataStruct(trialID).FrameData_app= Frame(trialID).app;
    dataStruct(trialID).FrameData_grating= Frame(trialID).grating;
    dataStruct(trialID).FrameData_combined= Frame(trialID).combined;

    dataStruct(trialID).pupilRadius_app= dataStruct(trialID).FrameData_app;
    dataStruct(trialID).pupilRadius_app(:,2)= eyeDataByFrame.radius(dataStruct(trialID).FrameData_app(:,2));
   
    dataStruct(trialID).pupilDistFromUserPoint_app= dataStruct(trialID).FrameData_app;
    dataStruct(trialID).pupilDistFromUserPoint_app(:,2)= eyeDataByFrame.distFromUserPoint(dataStruct(trialID).FrameData_app(:,2));
    
    dataStruct(trialID).pupilCentersDark_app(:,1)= dataStruct(trialID).FrameData_app(:,1);
    dataStruct(trialID).pupilCentersDark_app(:,2:3)= eyeDataByFrame.centersDark(dataStruct(trialID).FrameData_app(:,2),1:2);

    dataStruct(trialID).pupilMetric_app= dataStruct(trialID).FrameData_app;
    dataStruct(trialID).pupilMetric_app(:,2)= eyeDataByFrame.metric(dataStruct(trialID).FrameData_app(:,2));

    dataStruct(trialID).openEyePrediction_app= dataStruct(trialID).FrameData_app;
    dataStruct(trialID).openEyePrediction_app(:,2)= predictionsArray(dataStruct(trialID).FrameData_app(:,2));

    dataStruct(trialID).pupilRadius_grating= dataStruct(trialID).FrameData_grating;
    dataStruct(trialID).pupilRadius_grating(:,2)= eyeDataByFrame.radius(dataStruct(trialID).FrameData_grating(:,2)); 

    dataStruct(trialID).pupilDistFromUserPoint_grating= dataStruct(trialID).FrameData_grating;
    dataStruct(trialID).pupilDistFromUserPoint_grating(:,2)= eyeDataByFrame.distFromUserPoint(dataStruct(trialID).FrameData_grating(:,2)); 

    dataStruct(trialID).pupilCentersDark_grating(:,1)= dataStruct(trialID).FrameData_grating(:,1);
    dataStruct(trialID).pupilCentersDark_grating(:,2:3)= eyeDataByFrame.centersDark(dataStruct(trialID).FrameData_grating(:,2),1:2);  

    dataStruct(trialID).pupilMetric_grating= dataStruct(trialID).FrameData_grating;
    dataStruct(trialID).pupilMetric_grating(:,2)= eyeDataByFrame.metric(dataStruct(trialID).FrameData_grating(:,2)); 

    dataStruct(trialID).openEyePrediction_grating= dataStruct(trialID).FrameData_grating;
    dataStruct(trialID).openEyePrediction_grating(:,2)= predictionsArray(dataStruct(trialID).FrameData_grating(:,2));

    pupilRadius_Temp = flip(dataStruct(trialID).pupilRadius_app);
    pupilRadius_Temp(:,1) = -pupilRadius_Temp(:,1);
    dataStruct(trialID).pupilRadius_combined= vertcat(pupilRadius_Temp, dataStruct(trialID).pupilRadius_grating);
    
    pupilDistFromUserPoint_Temp = flip(dataStruct(trialID).pupilDistFromUserPoint_app);
    pupilDistFromUserPoint_Temp(:,1) = -pupilDistFromUserPoint_Temp(:,1);
    dataStruct(trialID).pupilDistFromUserPoint_combined= vertcat(pupilDistFromUserPoint_Temp, dataStruct(trialID).pupilDistFromUserPoint_grating); 

    pupilCentersDark_Temp = flip(dataStruct(trialID).pupilCentersDark_app);
    pupilCentersDark_Temp(:,1) = -pupilCentersDark_Temp(:,1);
    dataStruct(trialID).pupilCentersDark_combined= vertcat(pupilCentersDark_Temp, dataStruct(trialID).pupilCentersDark_grating);

    pupilMetric_Temp = flip(dataStruct(trialID).pupilMetric_app);
    pupilMetric_Temp(:,1) = -pupilMetric_Temp(:,1);
    dataStruct(trialID).pupilMetric_combined= vertcat(pupilMetric_Temp, dataStruct(trialID).pupilMetric_grating);

    openEyePrediction_Temp = flip(dataStruct(trialID).openEyePrediction_app);
    openEyePrediction_Temp(:,1) = -openEyePrediction_Temp(:,1);
    dataStruct(trialID).openEyePrediction_combined= vertcat(openEyePrediction_Temp, dataStruct(trialID).openEyePrediction_grating);
    
    for frame = 1:height(dataStruct(trialID).openEyePrediction_combined)
        dataStruct(trialID).noCircleFound(frame,1) = dataStruct(trialID).openEyePrediction_combined(frame,1);
        if isnan(dataStruct(trialID).pupilRadius_combined(frame,2)) & dataStruct(trialID).openEyePrediction_combined(frame,2) == 1
            dataStruct(trialID).noCircleFound(frame,2) = 1;
        else
            dataStruct(trialID).noCircleFound(frame,2) = 0;
        end
    end
    clear pupilRadius_Temp pupilDistFromUserPoint_Temp pupilCentersDark_Temp pupilMetric_Temp openEyePrediction_Temp
    end
end
for trialID= 1: numTotalTrials
    try
    isLickLeft_tempTime = (dataStruct(trialID).Timestamps(dataStruct(trialID).isLickLeft) - dataStruct(trialID).Timestamps(dataStruct(trialID).isGratingStart == 1))/1000;
    catch
        isLickLeft_tempTime = nan;
    end
    try
    isLickRight_tempTime = (dataStruct(trialID).Timestamps(dataStruct(trialID).isLickRight) - dataStruct(trialID).Timestamps(dataStruct(trialID).isGratingStart == 1))/1000;
    catch
        isLickRight_tempTime = nan;
    end
    for nLick = 1: height(isLickLeft_tempTime)
        if isLickLeft_tempTime(nLick) < 0
            diffValues = isLickLeft_tempTime(nLick) - dataStruct(trialID).encoderData_combined(:,1) ;
            diffValues(diffValues < 0) = inf;
            [~, indexMin] = min(diffValues);
            isLickLeft_tempDistance(nLick,1) = dataStruct(trialID).encoderData_combined(indexMin,2);
        else
            diffValues = dataStruct(trialID).encoderData_combined(:,1) - isLickLeft_tempTime(nLick) ;
            diffValues(diffValues > 0) = -inf;
            [~, indexMax] = max(diffValues);
            isLickLeft_tempDistance(nLick,1) = dataStruct(trialID).encoderData_combined(indexMax,2);
        end
    end
    for nLick = 1: height(isLickRight_tempTime)
         if isLickRight_tempTime(nLick) < 0
            diffValues = isLickRight_tempTime(nLick) - dataStruct(trialID).encoderData_combined(:,1) ;
            diffValues(diffValues < 0) = inf;
            [~, indexMin] = min(diffValues);
            isLickRight_tempDistance(nLick,1) = dataStruct(trialID).encoderData_combined(indexMin,2);
        else
            diffValues = dataStruct(trialID).encoderData_combined(:,1) - isLickRight_tempTime(nLick) ;
            diffValues(diffValues > 0) = -inf;
            [~, indexMax] = max(diffValues);
            isLickRight_tempDistance(nLick,1) = dataStruct(trialID).encoderData_combined(indexMax,2);
        end
    end 
    try
    dataStruct(trialID).DistanceStamps.isLickLeft = isLickLeft_tempDistance;
    catch
    dataStruct(trialID).DistanceStamps.isLickLeft = [];
    end
    try
    dataStruct(trialID).DistanceStamps.isLickRight = isLickRight_tempDistance;
    catch
    dataStruct(trialID).DistanceStamps.isLickRight = [];
    end
    clear isLickRight_tempDistance isLickLeft_tempDistance isLickLeft_tempTime isLickRight_tempTime
end

for n= 1:numTotalTrials
    % left on left
    if data(n) == 1 
        dataStruct(n).Trial_Outcome = 'Correct';
    % left on right
    elseif data(n) == 2
        dataStruct(n).Trial_Outcome = 'Incorrect'; 
    % right on left
    elseif data(n) == 3
        dataStruct(n).Trial_Outcome = 'Incorrect'; 
    % right on right
    elseif data(n) == 4
        dataStruct(n).Trial_Outcome = 'Correct';
    % miss on left
    elseif data(n) == 6
        dataStruct(n).Trial_Outcome = 'Miss';
    % miss on right
    elseif data(n) == 5
        dataStruct(n).Trial_Outcome = 'Miss';
    end
end
if pupilRecorded == 1
for trialID= 1: numTotalTrials
    isLickLeft_tempTime = (dataStruct(trialID).Timestamps(dataStruct(trialID).isLickLeft) - dataStruct(trialID).Timestamps(dataStruct(trialID).isGratingStart == 1))/1000;
    isLickRight_tempTime = (dataStruct(trialID).Timestamps(dataStruct(trialID).isLickRight) - dataStruct(trialID).Timestamps(dataStruct(trialID).isGratingStart == 1))/1000;
    for nLick = 1: height(isLickLeft_tempTime)
        if isLickLeft_tempTime(nLick) < 0
            diffValues = isLickLeft_tempTime(nLick) - dataStruct(trialID).FrameData_combined(:,1) ;
            diffValues(diffValues < 0) = inf;
            [~, indexMin] = min(diffValues);
            isLickLeft_tempFrame(nLick,1) = dataStruct(trialID).FrameData_combined(indexMin,2);
        else
            diffValues = dataStruct(trialID).FrameData_combined(:,1) - isLickLeft_tempTime(nLick) ;
            diffValues(diffValues > 0) = -inf;
            [~, indexMax] = max(diffValues);
            isLickLeft_tempFrame(nLick,1) = dataStruct(trialID).FrameData_combined(indexMax,2);
        end
    end
    for nLick = 1: height(isLickRight_tempTime)
         if isLickRight_tempTime(nLick) < 0
            diffValues = isLickRight_tempTime(nLick) - dataStruct(trialID).FrameData_combined(:,1) ;
            diffValues(diffValues < 0) = inf;
            [~, indexMin] = min(diffValues);
            isLickRight_tempFrame(nLick,1) = dataStruct(trialID).FrameData_combined(indexMin,2);
        else
            diffValues = dataStruct(trialID).FrameData_combined(:,1) - isLickRight_tempTime(nLick) ;
            diffValues(diffValues > 0) = -inf;
            [~, indexMax] = max(diffValues);
            isLickRight_tempFrame(nLick,1) = dataStruct(trialID).FrameData_combined(indexMax,2);
        end
    end 
    try
    dataStruct(trialID).FrameStamps.isLickLeft = isLickLeft_tempFrame;
    catch
    dataStruct(trialID).FrameStamps.isLickLeft = [];
    end
    try
        dataStruct(trialID).FrameStamps.isLickRight = isLickRight_tempFrame;
    catch
        dataStruct(trialID).FrameStamps.isLickRight = [];
    end
    clear isLickRight_tempFrame isLickLeft_tempFrame
end
end
if pupilRecorded == 1
C = {'Trial_ID','Trial_Type','Trial_Outcome','encoderData_combined','velocity','FrameData_combined','pupilRadius_combined','pupilDistFromUserPoint_combined','pupilCentersDark_combined','openEyePrediction_combined','DistanceStamps','FrameStamps','NoOfTimestamps','Timestamps','isLick','isLickLeft','isLickRight','isGratingStart','isRewardZoneEntry','isRewardTriggered','isManualValveOpen','isGratingEnd','noCircleFound','encoderData_app','encoderData_grating','FrameData_app','FrameData_grating','pupilRadius_app','pupilDistFromUserPoint_app','pupilCentersDark_app','pupilMetric_app','pupilRadius_grating','pupilDistFromUserPoint_grating','pupilCentersDark_grating','pupilMetric_grating','pupilMetric_combined','openEyePrediction_app','openEyePrediction_grating'};
dataStruct = orderfields(dataStruct,C);
else
C = {'Trial_ID','Trial_Type','Trial_Outcome','encoderData_combined','velocity','DistanceStamps','NoOfTimestamps','Timestamps','isLick','isLickLeft','isLickRight','isGratingStart','isRewardZoneEntry','isRewardTriggered','isManualValveOpen','isGratingEnd','encoderData_app','encoderData_grating'};
dataStruct = orderfields(dataStruct,C);
end
save(OutputSaveLocation,'dataStruct');
clearvars -except Dates mouse exp pupilRecorded