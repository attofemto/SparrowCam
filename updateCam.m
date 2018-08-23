function updateCam(~,event,hImage)

global hImageAxes hXSlice hYSlice hLineSliceX hLineSliceY hCrosshairX hCrosshairY hEllipse;
global edit_FWHM_x edit_FWHM_y edit_maxpos_x edit_maxpos_y edit_maxval edit_fps;
global settings imageRes pixsize_x pixsize_y margin prev_toc data;
global cmap background backgroundData backgroundMean setBackgroundData maxint;

% This callback function updates the displayed frame and the histogram.


margin = str2double(settings.margin);
% smoothing of 1D slices is CPU costy?
toggle_smoothing = str2double(settings.toggle_smoothing);

% subtracting the background
if background
    if setBackgroundData
        backgroundData = event.Data;
        backgroundMean = mean(backgroundData(:));
        setBackgroundData = 0;
        
    end
    maxint = str2double(settings.max_int) - backgroundMean;
    data = event.Data - backgroundData;
    
else
    maxint = str2double(settings.max_int);
    data = event.Data;
end

c_x = pixsize_x;
c_y = pixsize_y;

% nex command was timed to 0.13 s
% Display the current image frame. 
false_colors = ind2rgb(data, cmap);
set(hImage, 'CData', false_colors);

if str2double(settings.toggle_fmedian)
    mod_data = medfilt2(data);
else
    mod_data = data;
end
[val,ind] = max(mod_data(:));
 
% regionprops method to get the beam and its properties
% apply threshold as fraction of the maximum intensity
thresh_data = im2bw(data, str2double(settings.max_ratio)*double(val)/maxint);
measurements = regionprops(thresh_data, data, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'MaxIntensity');

% find the region with highest intensity
[val, ind_reg] = max(vertcat(measurements.MaxIntensity));
if ind_reg > 0
    X = int16(measurements(ind_reg).Centroid(1));
    Y = int16(measurements(ind_reg).Centroid(2));

    slice_x = data(Y,:); % Slice on x direction. 
    slice_y = data(:,X); % Slice on y direction.

    major_length = measurements(ind_reg).MajorAxisLength * c_x;
    minor_length = measurements(ind_reg).MinorAxisLength * c_y;
end

% specifiing coordinates for image corners (must coincide with axes limits)
set(hImage, 'XData', [0 imageRes(2)*c_x]);
set(hImage, 'YData', [0 imageRes(1)*c_y]);

set(hImageAxes, 'Visible', 'on');

set(hImageAxes, 'XLimMode', 'manual');
set(hImageAxes, 'YLimMode', 'manual');

% adjusting the limits of axes for the image
hImageAxes.XLim = [0 imageRes(2)*c_x];
hImageAxes.YLim = [0 imageRes(1)*c_y];
hImageAxes.TickDir = 'in';

% Keeps ticks in the picture
set(hImageAxes, 'XTickMode', 'auto');
set(hImageAxes, 'YTickMode', 'auto');

% deactivating Tick labels
hImageAxes.YTickLabel = '';
hImageAxes.XTickLabel = '';

set(hImageAxes, 'XGrid', settings.xgrid);
set(hImageAxes, 'YGrid', settings.ygrid);

colormap(cmap);
try
 colorbar(hImageAxes);
catch
    'Sorry colorbar is not available in this system.'
    
end

if ind_reg > 0
    % Draw crosshair at the maximum
    hCrosshairX.XData = [0 imageRes(2)*c_x];
    hCrosshairX.YData = [Y*c_y Y*c_y];

    hCrosshairY.XData = [X*c_x X*c_x];
    hCrosshairY.YData = [0 imageRes(1)*c_y];

    % Ellipse drawing
    phi = linspace(0,2*pi,50);
    cosphi = cos(phi);
    sinphi = sin(phi);

    s = measurements;
    xbar = s(ind_reg).Centroid(1)*c_x;
    ybar = s(ind_reg).Centroid(2)*c_y;
    a = s(ind_reg).MajorAxisLength*c_x/2;
    b = s(ind_reg).MinorAxisLength*c_y/2;
    theta = pi*s(ind_reg).Orientation/180;
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];
    xy = [a*cosphi; b*sinphi];
    xy = R*xy;

    hEllipse.XData = xy(1,:) + xbar;
    hEllipse.YData = xy(2,:) + ybar;

    % mask for smoothing 1D slices
    if toggle_smoothing
        conv_num = str2double(settings.mask_size); 
        conv_c = (1/conv_num)*ones(1,conv_num);
    end
end

function xplot()

    grid_x = linspace(0, imageRes(2)*c_x, imageRes(2)); %Grid for x direction.
    
    set(hImageAxes.Parent, 'CurrentAxes', hXSlice);
    hXSlice.Position = [hImageAxes.Position(1) hXSlice.Position(2) hImageAxes.Position(3) hXSlice.Position(4)];
    hLineSliceX.XData = grid_x;
    hLineSliceX.YData = slice_x;
%     title('Position x and its intensity');
    xlabel('x [\mum]');
%     ylabel('Intensity');
    
    axis([0,imageRes(2)*c_x,0,maxint]);
    
    if toggle_smoothing
        hold(hXSlice,'on');

        smooth_x = conv(double(slice_x),double(conv_c),'same');
        plot(grid_x,smooth_x);
        hold(hXSlice,'off');
    end

end

% Slice at the center of imageRes(2).

function yplot()
    
    grid_y = linspace(0, imageRes(1)*c_y, imageRes(1)); %Grid for y direction.
    set(hImageAxes.Parent, 'CurrentAxes', hYSlice);
    hYSlice.Position = [ hYSlice.Position(1) hImageAxes.Position(2) hYSlice.Position(3) hImageAxes.Position(4)];
    hLineSliceY.XData = slice_y;
    hLineSliceY.YData = grid_y;
    hYSlice.YDir = 'reverse';

    ylabel('y [\mum]');

    axis([0,maxint,0,imageRes(1)*c_y]);
    if toggle_smoothing
        hold(hYSlice,'on');

        smooth_y = conv(double(slice_y),double(conv_c),'same');
        plot(smooth_y,grid_y);
        hold(hYSlice,'off');
    end

end

if ind_reg > 0
    % updating values in monitors
    set(edit_maxval, 'String', sprintf('%3d',val));
    set(edit_maxpos_x, 'String', sprintf('%4.0f um',X*c_x));
    set(edit_maxpos_y, 'String', sprintf('%4.0f um',Y*c_y));
    set(edit_FWHM_x, 'String', sprintf('%4.0f um',major_length));
    set(edit_FWHM_y, 'String', sprintf('%4.0f um',minor_length));

    xplot();
    yplot();
end


% FPS counting:

time = toc;
fps = 1./(time - prev_toc);
prev_toc = time;

set(edit_fps, 'String', sprintf('%2.1f',fps));


end

