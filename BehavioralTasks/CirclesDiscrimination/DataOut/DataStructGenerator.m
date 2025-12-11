%% Import data from text file
txtfileFullName =  ['.txt']; % Text File location
OutputSaveLocation = ['\dataStruct.mat']; % Enter location of folder where output is desired

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
% gostate=0  grey screen
%
% gostate=3 reward is now armed
%
% gostate=6 stimulus offset
%
% gostate=7 white circle onset
%
% gostate= 8 black circle onset
stateTransitions= table2array(txtData(:,4));
timestamps_ms= table2array(txtData(:,1));
lickSide= table2array(txtData(:,2));
catagoryLabels= table2array(txtData(:,3));
% Clear temporary variables
clear opts

%% Sort Trial type
numTotalTrials= numel( find(stateTransitions== 0) );
rewardZoneStartIndices= find(stateTransitions== 3);
stimulusStartIndicies=  find(stateTransitions== 7 | stateTransitions== 8 | stateTransitions== 4 | stateTransitions== 5);
whiteCircleStartIndicies= find(stateTransitions== 7);
blackCircleStartIndicies= find(stateTransitions== 8);
staticTrialStartIndicies= find(stateTransitions== 4);
movingTrialStartIndicies= find(stateTransitions== 5);
trialStartIndicies= find(stateTransitions== 0);
trialEndIndicies= find(stateTransitions== 6);
isLick_session= catagoryLabels== 'lick';
isTouch_sessionCenter= lickSide== 'Center' & catagoryLabels== 'Touch';
isLick_sessionRight= lickSide== 'right' & catagoryLabels== 'lick';
isLick_sessionLeft= lickSide == 'left' & catagoryLabels== 'lick';
isStimulusStart_session= ((stateTransitions== 7 | stateTransitions== 8) | (stateTransitions== 4 | stateTransitions == 5));
isCircleBlockStimulusStart_session= (stateTransitions== 7 | stateTransitions== 8);
isMovementBlockStimulusStart_session= (stateTransitions== 4 | stateTransitions == 5);
isRewardZoneEntry_session= stateTransitions== 3;
isRewardTriggered_session= catagoryLabels== 'reward'; % mouse licks and triggers the water valve to open
isStimulusEnd_session= stateTransitions== 6;
count=1;
trialType_fromTxt= [];
trialTypeCategory= categorical(NaN(numTotalTrials,1));
i=1;

while i< stimulusStartIndicies(end)+1
    if ismember(i,whiteCircleStartIndicies)
        trialType_fromTxt(count)= 2;      % White Circles
        trialTypeCategory(count)= 'White';
        count=count + 1;
    elseif ismember(i,blackCircleStartIndicies)
        trialType_fromTxt(count)= 1;      % Black Circles
        trialTypeCategory(count)= 'Black';
        count=count + 1;
    elseif ismember(i,staticTrialStartIndicies)
        trialType_fromTxt(count)= 3;
        trialTypeCategory(count)= 'Static';
        count=count+1;
    elseif ismember(i,movingTrialStartIndicies)
        trialType_fromTxt(count)=4;
        trialTypeCategory(count)= 'Moving';
        count=count+1;
    end
    i=i+1;
end

% create data structure, # of rows is number of total trials within the session, there are 8 catagories [0,2,3,6,5,lick,manual reward, reward triggered]
dataStruct= struct;
for trialID= 1:numTotalTrials
    numTimestampsInTrial= numel( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).Trial_ID= trialID;
    dataStruct(trialID).Trial_Type= char(trialTypeCategory(trialID));
    dataStruct(trialID).NoOfTimestamps= numTimestampsInTrial;
    dataStruct(trialID).Timestamps= timestamps_ms( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLick= isLick_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLickCenter= isTouch_sessionCenter( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLickRight= isLick_sessionRight( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isLickLeft= isLick_sessionLeft( trialStartIndicies(trialID): trialEndIndicies (trialID) );
    dataStruct(trialID).isStimulusStart= isStimulusStart_session( trialStartIndicies(trialID): trialEndIndicies(trialID) ); 
    dataStruct(trialID).isCircleBlockStimulusStart= isCircleBlockStimulusStart_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isMovementBlockStimulusStart= isMovementBlockStimulusStart_session(trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardZoneEntry= isRewardZoneEntry_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardTriggered= isRewardTriggered_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isStimulusEnd= isStimulusEnd_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );

    if(strcmp(dataStruct(trialID).Trial_Type,'White'))
        if sum(dataStruct(trialID).isRewardTriggered == 1)
            dataStruct(trialID).data = 1;
        else
            dataStruct(trialID).data = 2;
        end
    else
        startPointTemp = find(dataStruct(trialID).isCircleBlockStimulusStart == 1);
        if sum(dataStruct(trialID).isLickRight(startPointTemp:end) >= 1)
            dataStruct(trialID).data = 0;
        else
            dataStruct(trialID).data = 3;
        end
    end
end
save(OutputSaveLocation,'dataStruct');