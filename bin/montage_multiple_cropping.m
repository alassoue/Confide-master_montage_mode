% Robert Cooper 4-11-2012
% Requires: Image Processing and Statistics toolboxes.
%
% This script is the starter script for the cone counting program
% distribution edition. EVERYTHING HERE IS PROVIDED AS IS. I make no claims
% of any warranty or any other guarantee on the maintenance of this
% software.
%
% This script will run a cone coordinate selection procedure on all of the images in the 'etc' folder in
% this program's subdirectory. Note that you MUST update the LUT.csv in the format: ID,axial,pix/degree, or it 
% will SKIP the images that it can't find an ID lookup for!
%
% To change the micron size that is analyzed, simply change the sizes array below.

close all;
clear all;
clc;


warning off

%---------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------
%% Perform the analysis for each of the below sizes (in microns) on each respective trial
sizes = [ ];
%---------------------------------------------------------------------------------------------
%---------------------------------------------------------------------------------------------

ini_folder = 'etc'; % change folder name in 'etc' if you wish to save your inital images and excel in a different folder
%montage_folder = uipickfiles('Prompt','Select the folder containing the montage') ;  %fullfile(montage_folder_path,montage_folder_suffix).
montage_folder = uigetdir('','Select the folder containing the AOSLO montage') ;
%montage_folder = cell2mat(montage_folder);

% montage_folder = 'montage_crop';

progBar = waitbar(0,'Beginning cone counting...');

% % Check version number
% ver = version('-release');
% if str2double(ver(1:4)) < 2011 % If less than 2011, must use RandStream generator
%     newstream= RandStream('mt19937ar','Seed',sum(100*clock));
%     RandStream.setGlobalStream(newstream);
% else % 2011-12 has a rng function that allows easy resetting of the random num generator
%     rng('shuffle');
% end
% % Find what path this script is running from
% thisPath=which('cone_counting.m');
% 
% % Get the absolute path
% basePath=thisPath(1:end-15);
% 
% % Add the bin directory to run the remainder of the files
% path(path,fullfile(basePath,'bin'))

%% doing the montage image cropping and re-initating 

   % montage_folder = fullfile(basePath, montage_folder);
%     montage_cropping_multiple(montage_folder,ini_folder, basePath);
% 
% function montage_cropping_multiple(montage_folder,ini_folder, basePath)
    fLUT = 'LUT.csv';
    exl=fopen(fullfile(montage_folder,fLUT),'r');
    lutData = textscan(exl,'%s%f%f%f%f','delimiter',',');
    axial_length = lutData{2};
    ppd = lutData{3};
    micronsPerPixel = (291*24./axial_length)./ppd;
    


    filelist=read_folder_contents(montage_folder,'tif');
    img = imread([montage_folder '\' cell2mat(filelist(1))]);
    imshow(img);
    %% from Ram's code
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
%     %%
%     if isnan(lutData{4});
%     %% this is where a message asking for fovea location input can be added.
%         [x, y] = getpts;
%         lutData{4} = x;
%         lutData{5} = y;
%         lutT = cell2table(lutData);
%         writetable(lutT, [montage_folder '\' fLUT],'WriteVariableNames',0);
%     else
%         x = lutData{4};
%         y = lutData{5};
%     
%     end
    %% this is where the user selects ROIs from the montage. Before each selection, the user is
    %% asked if he wants to draw another ROI. 
    t_al = [] ;
    t_name = [] ; 
    t_ppd = [] ; 
    t_x_deg = [] ;
    t_y_deg = [] ;
%     for i=1:100
%     prompt = 'Do you wish to draw ROI? (Y/N)';
%     res = input(prompt, 's');
%     yes = 'y';
%     if ~strcmpi(yes,res)
%         break 
%     end
%     [loc, rect] = imcrop(img);
%     x_mid = rect(1) + rect(3)/2;
%     y_mid = rect(2) + rect(4)/2;
%     x_diff = x_mid - x;
%     y_diff = y_mid - y;
%     x_deg = x_diff/ppd;
%     y_deg = -y_diff/ppd;
%     t_x_deg = [t_x_deg ; x_deg] ; 
%     t_y_deg = [t_y_deg ; y_deg] ; 
% %     
%     if ~exist(ini_folder, 'dir')
%         mkdir(ini_folder)
%     end
%     
%     cd([basePath ini_folder])
%     
%     str_split = strsplit(cell2mat(filelist(1)),'_');
%     name = string([str_split{1} '_' num2str(round(x_deg,4)) '_' num2str(round(y_deg,4)) '_cropped.tif']);
%     
%     imwrite(loc, name);
%     img_name =  string([str_split{1} '_' num2str(round(x_deg,4))]);
%     t_name = [t_name ; img_name(1)];
%     t_al = [t_al ; axial_length] ;
%     t_ppd = [t_ppd ; ppd];
    
  
%% this part is copied from Ram's code
[rows, columns, numberOfColorChannels] = size(img);
figure(1); imshow(img); axis on ; 
fontSize = 10;
again = true;
regionCount = 0;
title('Draw ROIs', 'FontSize', fontSize);
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
    x_deg = round(x_diff/ppd,10);
    y_deg = round(-y_diff/ppd,10);
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
        t_x_deg = [t_x_deg ; x_deg] ;
        t_y_deg = [t_y_deg ; y_deg] ;
        t_al = [t_al ; axial_length] ;
        t_ppd = [t_ppd ; ppd];
    else 
        delete(h);
    end

    close(2);
	if ~exist(ini_folder, 'dir')
        mkdir(ini_folder)
    end
    
%     cd([basePath ini_folder])
    
%     str_split = strsplit(cell2mat(filelist(1)),'_');
%     name = string([str_split{1} '_' num2str(round(x_deg,4)) '_' num2str(round(y_deg,4)) '_cropped.tif']);
%     
%     imwrite(loc, name);
%     img_name =  string([str_split{1} '_' num2str(round(x_deg,4))]);
%     t_name = [t_name ; img_name(1)];

end
%%
%% Crop and save ROIs
    promptMessage = sprintf('Which meridian ?');
	titleBarCaption = 'Continue?';
	button = questdlg(promptMessage, titleBarCaption, 'Horizontal', 'Vertical','Horizontal');
    if strcmpi(button, 'Horizontal')
        promptMessage = sprintf('Which direction ?');
        titleBarCaption = 'Continue?';
        button_2 = questdlg(promptMessage, titleBarCaption, 'Temporal', 'Nasal','Temporal');
        if strcmpi(button, 'Temporal')
            ROI_folder = fullfile(montage_folder,'temporal ROIs\');
        else
            ROI_folder = fullfile(montage_folder,'nasal ROIs\');
        end
    else
        promptMessage = sprintf('Which direction ?');
        titleBarCaption = 'Continue?';
        button_2 = questdlg(promptMessage, titleBarCaption, 'Inferior', 'Superior','Inferior');
        if strcmpi(button_2, 'Inferior')
            ROI_folder = fullfile(montage_folder,'inferior ROIs\');
        else
            ROI_folder = fullfile(montage_folder,'superior ROIs\');
        end
        
    end       
                
% ROI_folder = fullfile(montage_folder,'inferior ROIs\');

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
    [filepath,name_temp,ext] = fileparts(cell2mat(filelist(1))) ;
    name_confide = [name_temp,'_',num2str(t_x_deg(jj))] ;
   
    imwrite(cropROI, name);    
    t_name{jj} = name_confide;
    end
    
%%    
    t_name = string(t_name) ; 
    t = table(t_name', t_al,t_ppd,t_x_deg,t_y_deg);
%     t_deg = table(t_name', t_x_deg, t_y_deg);    
    writetable(t,string(fLUT),'WriteVariableNames',0, 'WriteMode','append');
%     writetable(t_deg, string([str_split{1} '.csv']), 'WriteVariableNames',0);
close 1 ; 

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
