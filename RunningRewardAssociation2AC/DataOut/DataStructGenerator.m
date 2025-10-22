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
% gostate=0  start of corridor
%
% gostate=7  Decision Zone Start, not reward zone yet
%
% gostate=3 reward is now armed
%
% gostate=6 gray screen
stateTransitions= table2array(txtData(:,4));
timestamps_ms= table2array(txtData(:,1));
lickSide= table2array(txtData(:,2));
catagoryLabels= table2array(txtData(:,3));
% Clear temporary variables
clear opts

%% Sort Trial type

numTotalTrials= numel( find(stateTransitions== 0) );
rewardZoneStartIndices= find(stateTransitions== 3);
decisionZoneStartIndicies=  find(stateTransitions== 7);
trialStartIndicies= find(stateTransitions== 0);
trialEndIndicies= find(stateTransitions== 6);
isLick_session= catagoryLabels== 'lick';
isLick_sessionLeft= lickSide== 'left' & catagoryLabels== 'lick';
isLick_sessionRight= lickSide== 'right' & catagoryLabels== 'lick';
isDecisionZoneStart_session= (stateTransitions== 7);
isRewardZoneEntry_session= stateTransitions== 3;
isRewardTriggered_session= catagoryLabels== 'reward'; % mouse licks and triggers the water valve to open
isManualValveOpen_session= catagoryLabels== 'manually';
isDecisionZoneEnd_session= stateTransitions== 6;
isBiasProtection_session= (stateTransitions== 2 | stateTransitions== 5);
trialType_fromTxt= [];
trialTypeCatagory= categorical(NaN(numTotalTrials,1));
i=1;

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
    dataStruct(trialID).isDecisionZoneStart= isDecisionZoneStart_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardZoneEntry= isRewardZoneEntry_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isRewardTriggered= isRewardTriggered_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isManualValveOpen= isManualValveOpen_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
    dataStruct(trialID).isDecisionZoneEnd= isDecisionZoneEnd_session( trialStartIndicies(trialID): trialEndIndicies(trialID) );
end
save(OutputSaveLocation,'dataStruct');