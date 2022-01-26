function montage_cropping(folder,ini_folder, basePath)
    fLUT = 'LUT.csv';
    exl=fopen(fullfile(folder,fLUT),'r');
    lutData = textscan(exl,'%s%f%f%f%f','delimiter',',');
    axiel_length = lutData{2};
    ppd = lutData{3};

    


    filelist=read_folder_contents(folder,'tif');
    img = imread([folder '\' cell2mat(filelist(1))]);
    imshow(img);
    
    if isnan(lutData{4});
    %% this is where a message asking for fovea location input can be added.
        [x, y] = getpts;
        lutData{4} = x;
        lutData{5} = y;
        lutT = cell2table(lutData);
        writetable(lutT, [folder '\' fLUT],'WriteVariableNames',0);
    else
        x = lutData{4};
        y = lutData{5};
    
    end

    
    [loc, rect] = imcrop(img);
    x_mid = rect(1) + rect(3)/2;
    y_mid = rect(2) + rect(4)/2;
    x_diff = x_mid - x;
    y_diff = y_mid - y;
    x_deg = x_diff/ppd;
    y_deg = -y_diff/ppd;
    

    
    if ~exist(ini_folder, 'dir')
        mkdir(ini_folder)
    end
    
    cd([basePath ini_folder])
    
    str_split = strsplit(cell2mat(filelist(1)),'_');
    name = string([str_split{1} '_' num2str(x_deg) '_' num2str(y_deg) '_cropped.tif']);
    
    imwrite(loc, name);
    img_name = name;
    t_name = img_name(1);
    t_al = axiel_length;
    t_ppd = ppd;
    
    t = table(t_name, t_al,t_ppd);
    t_deg = table(name, x_deg, y_deg);
    
    
    
    writetable(t_deg, string([str_split{1} '.csv']), 'WriteVariableNames',0);
    writetable(t,string(fLUT),'WriteVariableNames',0);
    
    
    

end