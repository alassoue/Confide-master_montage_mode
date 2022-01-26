close all;
clear all;
clc;

warning off

%---------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------
%% Initialization

workspace; % Display the workspace panel.
fontSize = 10;
% Check version number
ver = version('-release');
if str2double(ver(1:4)) < 2011 % If less than 2011, must use RandStream generator
    newstream= RandStream('mt19937ar','Seed',sum(100*clock));
    RandStream.setGlobalStream(newstream);
else % 2011-12 has a rng function that allows easy resetting of the random num generator
    rng('shuffle');
end
% Find what path this script is running from
thisPath=which('ROI_selector.m');

% Get the absolute path
basePath=thisPath(1:end-14);

% Add the bin directory to run the remainder of the files
path(path,fullfile(basePath,'bin'))
% montage_folder_suffix = 'montage_crop\PrefixS\'; %change this t
% 
% montage_folder_path = basePath(1:end-4);

montage_folder = uipickfiles %fullfile(montage_folder_path,montage_folder_suffix)
montage_folder = cell2mat(montage_folder);

filelist=read_folder_contents((montage_folder),'tif');
img = imread([(montage_folder) '\' cell2mat(filelist(1))]);


fLUT = 'LUT.csv';
exl=fopen(fullfile(montage_folder,fLUT),'r');
lutData = textscan(exl,'%s%f%f%f%f','delimiter',',');
axial_length = lutData{2};
ppd = lutData{3};
micronsPerPixel = (291*24./axial_length)./ppd;

figure(1); imshow(img, 'InitialMagnification',100);
    promptMessage = sprintf('Select Fovea ? ');
    titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No','Yes' );
	
    if strcmpi(button, 'Yes')
        GetFovea = drawpoint
		x = GetFovea.Position(1);
        y = GetFovea.Position(2);
        lutData{4} = x;
        lutData{5} = y;
        lutT = cell2table(lutData);
        writetable(lutT, [montage_folder '\' fLUT],'WriteVariableNames',0);
     
    end

    
    if isnan(lutData{4})
        GetFovea = drawpoint;
        x = GetFovea.Position(1);
        y = GetFovea.Position(2);
        lutData{4} = x;
        lutData{5} = y;
        lutT = cell2table(lutData);
        writetable(lutT, [montage_folder '\' fLUT],'WriteVariableNames',0);
    else
        x = lutData{4};
        y = lutData{5};

    end

    %% Drawing Multiple ROIs and saving them
[rows, columns, numberOfColorChannels] = size(img);
figure(1); imshow(img);
title('Draw ROIs', 'FontSize', fontSize);

figure(1);
axis on;
again = true;
regionCount = 0;

while again && regionCount < 20
    figure(1);
	promptMessage = sprintf('Draw new rectangular ROI, for square, hold down SHIFT key, double-click inside ROI to accept \nor Quit?', regionCount + 1);
    
    
	titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Free Draw', 'Quit', 'Predefined Size','Free Draw' );
	
    if strcmpi(button, 'Quit')
		again = 0;
        break;
    end
	
    
    if strcmpi(button, 'Predefined Size')
        promptMessage = sprintf('Choose square ROIsize (in microns)?')
        
        titleBarCaption = 'ROI sizes';
	    button = questdlg(promptMessage, titleBarCaption, '50', '100', '150','50' );
        Predef_ROIsize = str2num(button);    
        
        h = drawrectangle('Position',[1 1 Predef_ROIsize.*(1/micronsPerPixel) Predef_ROIsize.*(1/micronsPerPixel)]);
        pos = customWait(h)
    end

    if strcmpi(button, 'Free Draw')
	h = drawrectangle;
    pos = customWait(h);
    
    end
	
    
    x_mid = h.Position(1) + h.Position(3)/2;
    y_mid = h.Position(2) + h.Position(4)/2;
    x_diff = x_mid - x;
    y_diff = y_mid - y;
    x_deg = round(x_diff/ppd,2);
    y_deg = round(-y_diff/ppd,2);
    ROISize = [round(h.Position(3).*micronsPerPixel,0) round(h.Position(4).*micronsPerPixel,0)];
    
    
    figure (2)
    
    
    temp = imcrop(img, h.Position);
	imshow(temp,'InitialMagnification','fit', 'Border','loose'); 
    
% 	caption =['ROI selected ecc. = (',num2str(x_deg), ',', num2str(y_deg),')\nROISize (um) =']; % Need to add eccentricity, ROI size
	title({...
        ['ROI selected']...
        ['ecc. = (',num2str(x_deg), ',', num2str(y_deg),')']...
        ['ROI size (um) = (',num2str(ROISize(1)), ',', num2str(ROISize(2)),')']...
        });
	
    promptMessage = sprintf('New ROI ok ?');
	titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No/TryAgain', 'Yes');
    
	if strcmpi(button, 'Yes')
		regionCount = regionCount + 1;
        ROIs(regionCount,:) = pos;
        ROI_ecc_size(regionCount,:) = [x_deg y_deg squeeze(ROISize)];
    else 
        delete(h);
    end
    
    
    
    close(2);
	
end
 
%% Crop and save ROIs
ROI_folder = fullfile(montage_folder,'ROIs\');

    if ~exist(ROI_folder, 'dir')
        mkdir(ROI_folder)
    end
    
    cd(ROI_folder)
    
    filename_prefix = [ROI_folder, cell2mat(filelist(1))];
    
    for jj = 1:size(ROIs,1)
    name = [filename_prefix(1:end-4),'_', num2str(ROI_ecc_size(jj,1)),'_'...
        num2str(ROI_ecc_size(jj,2)),'_'...
        num2str(ROI_ecc_size(jj,3)),'_'...
        num2str(ROI_ecc_size(jj,4)),...
    '.tif'];
    
    cropROI = imcrop(img,ROIs(jj,:));
    
    imwrite(cropROI, name);    
    
    end
    
    %% 
    
function pos = customWait(hROI)

% Listen for mouse clicks on the ROI
l = addlistener(hROI,'ROIClicked',@clickCallback);

% Block program execution
uiwait;

% Remove listener
delete(l);

% Return the current position
pos = hROI.Position;

end

function clickCallback(~,evt)

if strcmp(evt.SelectionType,'double')
    uiresume;
end

end

