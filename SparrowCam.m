%% SparrowCam - The beam profiler

function SparrowCam()
    global src imageRes;
    global margin;
    
    global cmap pos running background vidobj hImage ;
    
    % colormap definition
    cmap = jet(256);
    pos = find(cmap(:,3)==1);
    cmap(1:pos(1),:) = [zeros(pos(1),2) linspace(0,1,pos(1))'];

    margin = 0.03;
    %% Set Up Video Object and Figure

    % Access an image acquisition device.
    load('Sparrow_format.mat','camera_format');
   
    vidobj = videoinput('winvideo', 2, 'Y16 _1280x720');
    
    %save('Sparrow_format.mat', 'camera_format');

    
    % identifies, if the preview is active or paused
    running = 1;
    % identifies, if the background is beign subtracted
    background = 0;
    
    % Convert the input images to grayscale.
    vidobj.ReturnedColorSpace = 'grayscale';
    src = getselectedsource(vidobj);
    
    %%
    % An image object of the same size as the video is used to store and
    % display incoming frames.

    % Retrieve the video resolution. 
    vidRes = vidobj.VideoResolution;

    % Create a figure and an image object.
    scrsz = get(groot,'ScreenSize');

    f = figure('Visible', 'off','Position',[scrsz(3)/6 scrsz(4)/6 scrsz(3)*2/3 scrsz(4)*2/3],'SizeChangedFcn',@resizeui, 'CloseRequestFcn', @destroy);

    sliders_cam_position = [.65 .5 .35 .5];
    sliders_layout_cc(f, sliders_cam_position);
    
    labels_beam_position = [.65 .0 .35 .5];
    labels_layout_cc(f, labels_beam_position);
    
    
    % The Video Resolution property returns values as width by height, but
    % MATLAB images are height by width, so flip the values.
    imageRes = fliplr(vidRes);

   
    axes('Position', [.2+margin .4+margin .6-2*margin .5-2*margin]);
    hImage = imshow(ind2rgb(zeros(imageRes), cmap));

    % Set the axis of the displayed image to maintain the aspect ratio of the 
    % incoming frame.
    %     axis image;

    %%
    % Specify the UpdatePreviewWindowFcn callback function that is called each 
    % time a new frame is available. The callback function is responsible for
    % displaying new frames and updating the histgram. It can also be used to 
    % apply custom processing to the frames. More details on how to use this 
    % callback can be found in the documentation for the PREVIEW function. 
    % This callback function itself is defined in the file 
    % <matlab:edit(fullfile(matlabroot,'toolbox','imaq','imaqdemos','helper','update_livehistogram_display.m')) update_livehistogram_display.m>
    setappdata(hImage,'UpdatePreviewWindowFcn',@updateCam_cc);


    %% Start Previewing

    % The PREVIEW function starts the camera and display. The image on which to
    % display the video feed is also specified.
     preview(vidobj,hImage);
    
    function destroy(~,~)
%     global vidobj f
    % Stop the preview image and delete the figure.
    try
        stoppreview(vidobj);
    catch

    end
    delete(f);

    %%
    % Once the video input object is no longer needed, delete and 
    % clear the associated variable.
    delete(vidobj)
    clear vidobj
    end

    
    function resizeui(~,~)
        sliders_layout_cc(f, sliders_cam_position);
        labels_layout_cc(f, labels_beam_position);
       
    end
end

