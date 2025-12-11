clear;


%  ------  enter .avi file name here  -----------------
load('directoryPathForPredictionsTable.csv') % Load prediction Table
predictionsArray(:,1) = table2array(predictions(:,1));
myEyePath = ['folderOfInterest\'];
movieName = dir(myEyePath);
myEyeFile = movieName(4).name;
fullpath_rawEye = [myEyePath myEyeFile];
mySavePath= ['FolderToSaveIn\'];
generateMyMovieVariable= 0;  % toggle, 1 to generate movie, takes about 6 hours!  DO not need to generate movie to get variable outputs

% ------------------------------------------------

Rmin= 10;   % radius min, pixels
Rmax= 30;  % radius max, pixels
EdgeThreshold= 0.05;

disp('   ------------------')
disp('')
disp(['You selected movie:  ' myEyeFile])
disp('')


disp('   ------------------')
disp('')
disp('Data will be saved in this location:')
disp(['... ' myEncPath(56:end)])
newFileName= [myEncFile(1:end-4) '_pupilDataTest.mat'];

% Import the file    -takes about 3 minutes
tic
fileToRead = fullpath_rawEye;
myMovie = importdata(fileToRead);
toc

[ySize, xSize] = size(myMovie(1).cdata);
boundingBoxSize= [100,100];  % in pixels, this is the area to be analysed after cropping
myTrackingMovie= struct;

warning('off','images:imfindcircles:warnForSmallRadius')

timerVal= tic;
counter= 1000;
for frameID= 1: size(myMovie,2) % temp mod 1: 50
    t= toc(timerVal);
    if frameID > counter
        counter= counter + 1000;
        disp([num2str(frameID) ' / ' num2str(size(myMovie,2)) '    elaspsed time (min): ' num2str(t/60)])
    end

    f=  myMovie(frameID).cdata;
    if frameID==1
        figure('Name','    CLICK on center of pupil.', 'Position', [600 300 800 800])  % left bottom width height
        imshow(f)
        daspect([1 1 1])
        [myPoint(1), myPoint(2)]= ginput(1);
        pause (1)
        close gcf

        A= f(max(0, round(myPoint(2)- boundingBoxSize(2)/2)):  min(ySize, round(myPoint(2)+ boundingBoxSize(2)/2)),...
            max(0, round(myPoint(1)- boundingBoxSize(1)/2)):  min(xSize, round(myPoint(1)+ boundingBoxSize(1)/2))  );
        figure1= figure('Name','    This area will be analyzed. CLICK on center of pupil again.','OuterPosition',[592 292 1077 775]);
        axes1 = axes('Parent',figure1,...
            'Position',[0.351428562779816 0.39227641313299 0.289795918367347 0.432926829268293]);
        axis off
        imshow(A)
        daspect([1 1 1])
        [myPoint2(1), myPoint2(2)]= ginput(1);
        pause (1)
        close gcf
    else

        A= f(max(0, round(myPoint(2)- boundingBoxSize(2)/2)):  min(ySize, round(myPoint(2)+ boundingBoxSize(2)/2)),...
            max(0, round(myPoint(1)- boundingBoxSize(1)/2)):  min(xSize, round(myPoint(1)+ boundingBoxSize(1)/2))  );
    end

    centersDark= [];
    radiiDark= [];

    % figure('Position', [600 300 800 800])
    % imshow(A)
    [centersDark, radiiDark, metric] = imfindcircles(A,[Rmin Rmax],'ObjectPolarity','dark', 'Sensitivity',0.92);
    % viscircles(gca,centersDark, radiiDark,'LineStyle','--' )

    if size(radiiDark,1) >1  % more than one circle found
        D= nan(size(radiiDark));
        for i= 1: size(radiiDark,1)
            D(i) = pdist([centersDark(i,:); myPoint2]);
            [~,indx]= sort(D);
            finalIndex=indx(1);
        end
    else
        finalIndex= 1;
    end



    %  organizing data to be saved
    if ~isempty(centersDark) && ~isnan(radiiDark(1)) && predictionsArray(frameID) == 1
        distFromUserPoint= pdist([centersDark(finalIndex,:); myPoint2]);

        eyeDataByFrame.radius(frameID,1)= radiiDark(finalIndex,1);
        eyeDataByFrame.centersDark(frameID, 1:2)= centersDark(finalIndex,1:2);
        %eyeDataByFrame.distFromUserPoint(frameID,1)= D(finalIndex);
        eyeDataByFrame.distFromUserPoint(frameID,1)= distFromUserPoint;
        eyeDataByFrame.metric(frameID,1)= metric(finalIndex,1);
    else
        eyeDataByFrame.radius(frameID,1)= nan;
        eyeDataByFrame.centersDark(frameID,1:2)= nan;
        eyeDataByFrame.distFromUserPoint(frameID,1)= nan;
        eyeDataByFrame.metric(frameID,1)= nan;
    end


end


status= cell((size(myMovie,2)),1);
verifiedFrames= [];
% -----   now select pupil center by hand for low confidence frames ITERATION #1 (of 2)
frames=struct;
myPoint3 = [];
lowConfidenceFrames= find(isnan(eyeDataByFrame.radius(:,1)) & predictionsArray==1);
for frameID= 1:  size(lowConfidenceFrames,1)  % temp mod , maybe do just the first 10
    f=  myMovie( lowConfidenceFrames(frameID) ).cdata;
    frames(frameID).A= f(max(0, round(myPoint(2)- boundingBoxSize(2)/2)):  min(ySize, round(myPoint(2)+ boundingBoxSize(2)/2)),...
    max(0, round(myPoint(1)- boundingBoxSize(1)/2)):  min(xSize, round(myPoint(1)+ boundingBoxSize(1)/2))  );
    [frames(frameID).centersUpdate, frames(frameID).radiiUpdate, frames(frameID).metrics] = imfindcircles(frames(frameID).A,[Rmin Rmax],'ObjectPolarity','dark', 'Sensitivity',0.93);
    % need to pick best circle if more than one
    if size(frames(frameID).radiiUpdate,1) > 1  % more than one circle found
        D= nan(size(frames(frameID).radiiUpdate));
        for ii= 1: size(frames(frameID).radiiUpdate,1)
            D(ii) = pdist([frames(frameID).centersUpdate(ii,:); myPoint2]);
            [~,indx]= sort(D);
            frames(frameID).finalIndex=indx(1);
        end
    else
        frames(frameID).finalIndex= 1;
    end
end

for frameID= 1:10: size(lowConfidenceFrames,1)
    n=1;
    figure('Position', [10 200 1900 800]);
    for i = frameID:frameID+9
        if i <=size(lowConfidenceFrames,1) && size(frames(i).centersUpdate,1) ~= 0
            subplot(2, 5, n); % Create a 2x5 grid and select the n-th position
            imshow(frames(i).A); % Display the i-th frame
            title(['Frame ', num2str(i)]); % Add a title to each subplot
            hold on
            viscircles(gca,frames(i).centersUpdate(frames(i).finalIndex,:), frames(i).radiiUpdate(frames(i).finalIndex),'LineStyle','--' , 'LineWidth',0.5);
        end
        n = n+1;
    end
    answer = input('Press enter if pupils look good, or type 1 to curate each frame: ','s');
    close all
    if strcmp(answer,'1')
        for i = frameID:frameID+9
            if i <=size(lowConfidenceFrames,1) && size(frames(i).centersUpdate,1) ~= 0
                figure1= figure('Name','    Click in upper right corner to accept  Click elsewhere to reject','OuterPosition',[592 292 1077 775]);
                axes1 = axes('Parent',figure1,...
                    'Position',[0.351428562779816 0.39227641313299 0.289795918367347 0.432926829268293]);
                axis off
                imshow(frames(i).A)
                hold on
                annotation(figure1,'rectangle',...
                    [0.591951932139491 0.763929618768328 0.0414128180961357 0.0586510263929618],...
                    'Color',[0 1 0]);
                title ([num2str(i)])
                viscircles(gca,frames(i).centersUpdate(frames(i).finalIndex,:), frames(i).radiiUpdate(frames(i).finalIndex,:),'LineStyle','--' , 'LineWidth',0.5);
                daspect([1 1 1])
                [myPoint3(1), myPoint3(2)]= ginput(1);
                pause (1)
                close gcf

                if myPoint3(1) > 59 && myPoint3(2) < 12
                    eyeDataByFrame.centersDark(lowConfidenceFrames(i),1:2)= frames(i).centersUpdate(frames(i).finalIndex,:);
                    eyeDataByFrame.radius(lowConfidenceFrames(i))= frames(i).radiiUpdate(frames(i).finalIndex);
                    eyeDataByFrame.metric(lowConfidenceFrames(i))= frames(i).metrics(frames(i).finalIndex);
                    status{i} = 'accept';
                    verifiedFrames= [verifiedFrames lowConfidenceFrames(i)];
                else
                    status{i} = 'reject';
                    eyeDataByFrame.radius(lowConfidenceFrames(i),1)= nan;
                    eyeDataByFrame.centersDark(lowConfidenceFrames(i),1:2)= nan;
                    eyeDataByFrame.distFromUserPoint(lowConfidenceFrames(i),1)= nan;
                    eyeDataByFrame.metric(lowConfidenceFrames(i),1)= nan;
                end
                disp(['Frame # ' num2str(i) ' of ' num2str(size(lowConfidenceFrames,1)) ' set to  ' status{i}])
            else
                status{i} = 'reject';
                eyeDataByFrame.radius(lowConfidenceFrames(i),1)= nan;
                eyeDataByFrame.centersDark(lowConfidenceFrames(i),1:2)= nan;
                eyeDataByFrame.distFromUserPoint(lowConfidenceFrames(i),1)= nan;
                eyeDataByFrame.metric(lowConfidenceFrames(i),1)= nan;
                disp(['Frame # ' num2str(i) ' of ' num2str(size(lowConfidenceFrames,1)) ' set to  ' status{i}])
            end
        end
    else
        for i = frameID:frameID+9
            if i <=size(lowConfidenceFrames,1)
                if  size(frames(i).centersUpdate,1) ~= 0
                    eyeDataByFrame.centersDark(lowConfidenceFrames(i),1:2)= frames(i).centersUpdate(finalIndex,:);
                    eyeDataByFrame.radius(lowConfidenceFrames(i))= frames(i).radiiUpdate(finalIndex);
                    eyeDataByFrame.metric(lowConfidenceFrames(i))= frames(i).metrics(finalIndex);
                    status{i} = 'accept';
                    verifiedFrames = [verifiedFrames lowConfidenceFrames(i)];
                else %if myPoint3(1) < 12 && myPoint3(2) < 12
                    status{i} = 'reject';
                    eyeDataByFrame.radius(lowConfidenceFrames(i),1)= nan;
                    eyeDataByFrame.centersDark(lowConfidenceFrames(i),1:2)= nan;
                    eyeDataByFrame.distFromUserPoint(lowConfidenceFrames(i),1)= nan;
                    eyeDataByFrame.metric(lowConfidenceFrames(i),1)= nan;
                % else
                %     status{checkFrames(i)} = 'updateCenter';
                %     [centersUpdate, radiiUpdate, metrics] = imfindcircles(A,[Rmin Rmax],'ObjectPolarity','dark', 'EdgeThreshold', EdgeThreshold + .05);
                %     % need to pick best circle if more than one
                end
                disp(['Frame # ' num2str(i) ' of ' num2str(size(lowConfidenceFrames,1)) ' set to  ' status{i}])
            end
        end
    end
end

%     -----   ITERATION #2 (of 2) select pupil center by hand for low confidence frames 

    distFromUserPointUpdated= nan(size(myMovie,2),1);
    for frameID= 1:  size(myMovie,2) % temp mod 1: 50

        distFromUserPointUpdated(frameID)= pdist([eyeDataByFrame.centersDark(frameID,:); myPoint2]);
        myPoint3 = [];
        distanceFromUserPointDiff = diff(distFromUserPointUpdated);
        lowConfidenceFramesUpdated= find( abs(distanceFromUserPointDiff) > 12 );
    end

    for frameID= 1:  size(lowConfidenceFramesUpdated,1)  % temp mod , maybe do just the first 10
        checkFrames = lowConfidenceFramesUpdated(frameID) -1 : lowConfidenceFramesUpdated(frameID) +1
        for i = 1: size(checkFrames,2)
            if ismember(checkFrames(i),verifiedFrames)
                break
            end
                f=  myMovie( checkFrames(i) ).cdata;
                A= f(max(0, round(myPoint(2)- boundingBoxSize(2)/2)):  min(ySize, round(myPoint(2)+ boundingBoxSize(2)/2)),...
                max(0, round(myPoint(1)- boundingBoxSize(1)/2)):  min(xSize, round(myPoint(1)+ boundingBoxSize(1)/2))  );
                centerDark = eyeDataByFrame.centersDark(checkFrames(i), 1:2);
                radiusDark = eyeDataByFrame.radius(checkFrames(i),1);

                figure1= figure('Name','#2    Click in upper right corner to accept  Click upper left corner for NaN  Click center of pupil to re-do','OuterPosition',[592 292 1077 775]);
                axes1 = axes('Parent',figure1,...
                'Position',[0.351428562779816 0.39227641313299 0.289795918367347 0.432926829268293]);
                axis off
                imshow(A)
                hold on
                annotation(figure1,'rectangle',...
                [0.591951932139491 0.763929618768328 0.0414128180961357 0.0586510263929618],...
                'Color',[0 1 0]);

                annotation(figure1,'rectangle',...
                [0.359152686145146 0.768328445747801 0.0385852968897267 0.0542521994134897],...
                'Color',[1 1 0.0666666666666667]);

                title ([num2str(checkFrames(i))])

                viscircles(gca,centerDark, radiusDark,'LineStyle','--' , 'LineWidth',0.5);
                daspect([1 1 1])
                [myPoint3(1), myPoint3(2)]= ginput(1);
                pause (1)
                close gcf

                if myPoint3(1) > 59 && myPoint3(2) < 12
                    status{checkFrames(i)} = 'accept';
                elseif myPoint3(1) < 12 && myPoint3(2) < 12
                    status{checkFrames(i)} = 'NaN';
                    eyeDataByFrame.radius(checkFrames(i),1)= nan;
                    eyeDataByFrame.centersDark(checkFrames(i),1:2)= nan;
                    eyeDataByFrame.distFromUserPoint(checkFrames(i),1)= nan;
                    eyeDataByFrame.metric(checkFrames(i),1)= nan;

                else
                    status{checkFrames(i)} = 'updateCenter';
                    [centersUpdate, radiiUpdate, metrics] = imfindcircles(A,[Rmin Rmax],'ObjectPolarity','dark', 'Sensitivity',0.93);
                    % need to pick best circle if more than one

                    if size(radiiUpdate,1) > 1  % more than one circle found
                        D= nan(size(radiiUpdate));    
                            for ii= 1: size(radiiUpdate,1)
                                D(ii) = pdist([centersUpdate(ii,:); myPoint3]); 
                                [~,indx]= sort(D);
                                finalIndex=indx(1);
                            end
                     else
                            finalIndex= 1;
                     end

                    eyeDataByFrame.centersDark(checkFrames(i),1:2)= centersUpdate(finalIndex, :);
                    figure1= figure('Name','  ATTEMPT #2    Click in upper right corner to accept  Click upper left corner for NaN ','OuterPosition',[592 292 1077 775]);
                    axes1 = axes('Parent',figure1,...
                    'Position',[0.351428562779816 0.39227641313299 0.289795918367347 0.432926829268293]);
                    axis off
                    imshow(A)
                    hold on
                    viscircles(gca,centersUpdate(finalIndex,:), radiiUpdate(finalIndex),'LineStyle','--' , 'LineWidth',0.5);

                    annotation(figure1,'rectangle',...
                    [0.591951932139491 0.763929618768328 0.0414128180961357 0.0586510263929618],...
                    'Color',[0 1 0]);

                    annotation(figure1,'rectangle',...
                    [0.359152686145146 0.768328445747801 0.0385852968897267 0.0542521994134897],...
                    'Color',[1 1 0.0666666666666667]);

                    [myPoint3(1), myPoint3(2)]= ginput(1);
                    pause (1)
                    close gcf

                    if myPoint3(1) > 59 && myPoint3(2) < 12
                        status{checkFrames(i)} = 'accept';
                        eyeDataByFrame.centersDark(checkFrames(i),1:2)= centersUpdate(finalIndex,:);
                        eyeDataByFrame.radius(checkFrames(i))= radiiUpdate(finalIndex);
                        eyeDataByFrame.metric(checkFrames(i))= metrics(finalIndex);
                    else
                        status{checkFrames(i)} = 'NaN';
                        eyeDataByFrame.radius(checkFrames(i),1)= nan;
                        eyeDataByFrame.metric(checkFrames(i))= nan;
                    end

                end
                verifiedFrames= [verifiedFrames checkFrames(i)];
        end

    end
% --- end ITERATION # 2 of 2

save([mySavePath newFileName], 'eyeDataByFrame', 'myEyePath','myEyeFile','Rmin','Rmax','EdgeThreshold','verifiedFrames','-mat')
disp('saved variables, not movie.  Save movie manually from workspace if you want it saved')

warning('on','images:imfindcircles:warnForSmallRadius')

 % ---- this takes about 6 hours to run, user must manually save, NOTE this code does not save the movie

    if generateMyMovieVariable
        tic;
        counter= 100;
        for frameID= 1 : size(myMovie,2)  % % temp mod 1: 50
             if frameID > counter
                counter= counter + 100;
                disp([num2str(frameID) ' / ' num2str(size(myMovie,2)) '    elaspsed time (min): ' num2str(toc/60)])
            end
            f=  myMovie(frameID).cdata;  
            A= f(max(0, round(myPoint(2)- boundingBoxSize(2)/2)):  min(ySize, round(myPoint(2)+ boundingBoxSize(2)/2)),...
            max(0, round(myPoint(1)- boundingBoxSize(1)/2)):  min(xSize, round(myPoint(1)+ boundingBoxSize(1)/2))  );

            figure()
             hold on
            imshow(A)
           
                if ~isempty(eyeDataByFrame.radius(frameID,1)) && ~isnan(eyeDataByFrame.radius(frameID,1))
                    viscircles(gca,eyeDataByFrame.centersDark(frameID, 1:2),eyeDataByFrame.radius(frameID,1),'LineStyle','--', 'LineWidth', 0.05 );
                elseif predictionsArray(frameID) == 0
                    text(gca,myPoint2(1),myPoint2(2),'X', 'FontSize',28, 'Color','red');
                else
                    text(gca,myPoint2(1),myPoint2(2),'X', 'FontSize',28, 'Color','blue');
                end
            a= getframe(gca);
            myTrackingMovie(frameID).cdata= a.cdata;
            myTrackingMovie(frameID).colormap= [];
            
            close(gcf)
    
        end
        toc
    videoFileName= [myEncFile(1:end-4) '_TrackedVideoTest.mat'];
    save([mySavePath videoFileName], 'myTrackingMovie','-mat')
    end
    % -----------------------------------