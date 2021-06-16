% SparrowCam - The beam profiler

function SparrowCam(adaptor_path)
    global src imageRes settings;
    global cmap pos running background vidobj ROI popup_value format pixsize_x pixsize_y;
    global hImage hImageAxes hXSlice hYSlice hLineSliceX hLineSliceY hCrosshairX hCrosshairY hEllipse

    % to show user (when interactive mode is not available) names of
    % adaptors
    imaqhwinfo
    
    % to enter the path to the proper adaptor as argument and register the
    % adaptor
    if nargin > 0
        imaqregister(adaptor_path, 'unregister')
        imaqregister(adaptor_path)
    end
    % load configuration
    settings = ini2struct('SparrowCam.ini');
    
    pixsize_x = str2double(settings.pixsize_x); % Pixel size of x direction.
    pixsize_y = str2double(settings.pixsize_y); % Pixel size of y direction.
    
    % colormap definition
    cmap = jet(256);
    pos = find(cmap(:,3)==1);
    cmap(1:pos(1),:) = [zeros(pos(1),2) linspace(0,1,pos(1))'];

    
    % identifies, if the preview is active or paused
    running = 1;
    % identifies, if the background is beign subtracted
    background = 0;

    
    % Create a figure and an image object.
    scrsz = get(groot,'ScreenSize');

    fig = figure('Visible', 'off',...
               'Position',[scrsz(3)/6 scrsz(4)/6 scrsz(3)*2/3 scrsz(4)*2/3],...
               'CloseRequestFcn', @destroy,...
               'ResizeFcn', @resizeui);
    margin = str2double(settings.margin); % some space between widgets
    
    slice_height_x = str2double(settings.slice_height_x);
    slice_height_y = str2double(settings.slice_height_y);

    % to show user (when interactive mode is not available)
    % available device ids
    strct = imaqhwinfo(settings.adaptor);
    available_deviceIDs = strct.DeviceIDs
    
    % Initializing the camera
    try
        % if changing format or loading previous configuration
        load('SparrowCam_format.mat', 'format');
        vidobj = videoinput(settings.adaptor, str2double(settings.device_id), format);
    catch
        % first run of program or fixing error in previous
        msg = 'SparrowCam might run for the first time. Taking default camera format.'
        vidobj = videoinput(settings.adaptor, str2double(settings.device_id));
        format = vidobj.VideoFormat;
        popup_value = 1;
    end
    

    vidobj.ReturnedColorSpace = 'grayscale';
    src = getselectedsource(vidobj);
    
    src.ExposureAuto = 'Off';
    src.GainAuto = 'Off';
    vidRes = vidobj.VideoResolution;
    
    % The Video Resolution property returns values as width by height, but
    % MATLAB images are height by width, so flip the values.    
    imageRes = fliplr(vidRes);
    
    %vidobj.ROIPosition = [314 289 341 251];
    
    if length(ROI) == 4 % this four identifies position vector
        % number 4 corresponds to binning factor
        vidobj.ROIPosition = 4*ROI;
        
        m = get(vidobj, 'ROIPosition');
        imageRes = [m(4) m(3)];
    end
    %ROI = [1 1 vidRes(1)/4 vidRes(2)/4];
        
    
    image_xsize = .55; % normed
    p = get(fig, 'Position');
    figure_xsize_abs = p(3);%fig.Position(3);
    figure_ysize_abs = p(4);%fig.Position(4);
    ratio = imageRes(1)/imageRes(2);
    
    imagePosition = [0.1+margin ...
                     0.15+margin ...
                     image_xsize ...
                     figure_xsize_abs*image_xsize*ratio/figure_ysize_abs];

    % positioning of 1D slices at maxima
    positionvector_x = [.0+margin imagePosition(2)-slice_height_y .6-2*margin slice_height_y];
    hXSlice = axes('Position', positionvector_x);
    hLineSliceX = plot(zeros(1,imageRes(2)));
    %axis off;
    
    positionVector_y = [imagePosition(1)-slice_height_x .4+margin slice_height_x .1-margin];
    hYSlice = axes('Position',positionVector_y);
    hLineSliceY = plot(zeros(1,imageRes(1)));
    %axis off;


    % Camera image
    hImageAxes = axes('Position', imagePosition,...
                      'Box', 'on');
    
    % reprogram zooming feature of Matlab
    set(zoom(hImageAxes),'ActionPostCallback', @setROI);

    hImage = imshow(ind2rgb(zeros(imageRes), cmap));
    axis normal;
    
    crosshair_width = str2double(settings.crosshair_width);
    crosshair_color = settings.crosshair_color;
    
    hCrosshairX = line([0 0], [1000 1000], 'Color', crosshair_color,...
                                           'LineWidth', crosshair_width);
    hCrosshairY = line([0 0], [1000 1000], 'Color', crosshair_color,...
                                           'LineWidth', crosshair_width);
    
    % centroid of beam (ellipse)
    hEllipse = line([0 0], [1000 1000], 'Color', crosshair_color,...
                                        'LineWidth', crosshair_width);
    
    % appearance settings
    panel_left_pos = image_xsize + imagePosition(1);
    
    sliders_cam_position = [panel_left_pos .45 1 - panel_left_pos .55];
    panel_cam = sliders_layout(fig, sliders_cam_position); % frame with format switch and gain and exposure
    
    labels_beam_position = [panel_left_pos .0 1 - panel_left_pos .5];
    labels_layout(fig, labels_beam_position); % frame with measured values
    
    % Set the axis of the displayed image to maintain the aspect ratio of the 
    % incoming frame.
    %axis image;

    setappdata(hImage,'UpdatePreviewWindowFcn',@updateCam);
    
    % FPS counting
    tic;
    
    preview(vidobj,hImage);
    
    function destroy(~,~)

    % Stop the preview image and delete the figure.
        try
            stoppreview(vidobj);
            save('SparrowCam_format.mat', 'format', 'popup_value', 'ROI');

        catch

        end
        delete(fig);

        % Once the video input object is no longer needed, delete and 
        % clear the associated variable.
        delete(vidobj)
        clear vidobj
    end

    function [x,y] = setROI(obj, event_obj)
        
        global checkbox_preview
        
        % ROI was selected; uncheck the indicater of ROI selecting regime
        set(checkbox_preview, 'Value', 0);
        
        stoppreview(vidobj);
                
        pos_x_um = get(event_obj.Axes, 'XLim');
        pos_y_um = get(event_obj.Axes, 'YLim');
        
        pos_x = floor(pos_x_um/pixsize_x);
        pos_y = floor(pos_y_um/pixsize_y);
        
        size_x = floor(pos_x(2) - pos_x(1));
        size_y = floor(pos_y(2) - pos_y(1));
        
        % conversion to pixels
        ROI = [pos_x(1) pos_y(1) size_x size_y];
        
        format = settings.fullframe_format;
        
        close; 
        SparrowCam;

    end

    function resizeui(~,~)
        
        % when dragging the figure corners rebuild the widgets
%         ch = get(panel_cam, 'Children');
% 
%         for ii = 1:length(ch)
%             if isprop(ch(ii), 'Visible')
%                 %set(ch(ii), 'Visible', 'off');
%                 delete(ch(ii));
%             end
%         end
%         sliders_layout(fig, sliders_cam_position);
%         labels_layout(fig, labels_beam_position);
       
        pp = get(fig, 'Position');
        figure_xsize_abs = pp(3);
        figure_ysize_abs = pp(4);
        ratio = imageRes(1)/imageRes(2);

        pIAxes = get(hImageAxes, 'Position');
        pIAxes(4) = figure_xsize_abs*pIAxes(3)*ratio/figure_ysize_abs;
        %hImageAxes.Position = [hImageAxes.Position(1) ...
        %                     hImageAxes.Position(2) ...
        %                     hImageAxes.Position(3) ...
        %                     figure_xsize_abs*hImageAxes.Position(3)*ratio/figure_ysize_abs];
        set(hImageAxes, 'Position', pIAxes);
    end
end

