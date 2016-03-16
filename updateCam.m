function updateCam(~,event,hImage)

global imageRes data margin;
global edit_BRan_x edit_BRan_y edit_FWHM_x edit_FWHM_y edit_maxpos_x edit_maxpos_y edit_maxval;

global cmap background backgroundData setBackgroundData;
% This callback function updates the displayed frame and the histogram.

% Copyright 2007 The MathWorks, Inc.

% Display the current image frame. 

if background
    if setBackgroundData
        backgroundData = event.Data;
        setBackgroundData = 0;
    end
    data = event.Data - backgroundData;
else
    data = event.Data;
end

set(hImage, 'CData', ind2rgb(data, cmap));
% Select the second subplot on the figure for the histogram.

mod_data = medfilt2(data);

% Slice at the center of imageRes(1).
[val,ind] = max(mod_data(:));

[Y,X] = ind2sub(size(mod_data),ind); % Position of maximum(inversed).
pixsize_x = 5.86; % Pixel size of x direction.
pixsize_y = 5.86; % Pixel size of y direction.
maxint = 255; % Upper limit of intensity.
slice_x = mod_data(Y,:); % Slice on x direction. 
slice_y = mod_data(:,X); % Slice on y direction.
thr_2 = 1/2; % Threshold of peak(1/2).
thr_e2 = 1/exp(2); % Threshold of peak(1/(e^2)).

ccd_res_x = 1920; % Actual resolution for x direction(DMK 23UX174).
ccd_res_y = 1200; % Actual resolution for y direction(DMK 23UX174).

c_x = pixsize_x*(ccd_res_x/imageRes(2)); % Length for 1 pixel on x direction.
c_y = pixsize_y*(ccd_res_y/imageRes(1)); % Length for 1 pixel on y direction.

half_x = slice_x > (val*thr_2); % Judgement if it is included in peak or not on x direction(1/2).
tot_half_x = sum(half_x); % Number of pixels on x direction.
area_x = tot_half_x*c_x; % Total area on x direction.

half_y = slice_y > (val*thr_2); % Judgement if it is included in peak or not on y direction(1/2).
tot_half_y = sum(half_y); % Number of pixels on x direction.
area_y = tot_half_y*c_y; % Total area on x direction.

two_e_x = slice_x > (val*thr_e2); % Judgement if it is included in peak or not on x direction(1/(e^2)).
tot_e_x = sum(two_e_x); % Number of pixels on x direction.
range_x = tot_e_x*c_x; % Total area on x direction.

two_e_y = slice_y > (val*thr_e2); % Judgement if it is included in peak or not on y direction(1/(e^2)).
tot_e_y = sum(two_e_y); % Number of pixels on x direction.
range_y = tot_e_y*c_y; % Total area on x direction.

font_size = 12;

% function [inds, vals] = center_of_mass(X, Y, data)
% 
%     t1 = data.*X;
%     t2 = data.*Y;
% 
%     mass = sum(data(:));
%     x_pos = sum(t1(:))/mass;
%     y_pos = sum(t2(:))/mass;
%     vals = [x_pos y_pos];
%     
%     [~,x_ind] = min(abs(X(1,:) - x_pos));
%     [~,y_ind] = min(abs(Y(:,1) - y_pos));
%     inds = [x_ind, y_ind];
%     
% end
% 
% [inds, vals] = center_of_mass(X, Y, data);
conv_num = 30; 
conv_c = (1/conv_num)*ones(1,conv_num);
    function xplot()
positionvector_x = [.3+margin .2+margin .4-2*margin .2-2*margin];
axes('Position', positionvector_x);

grid_x = linspace(0, imageRes(2)*c_x, imageRes(2)); %Grid for x direction.
plot(grid_x, slice_x);
title('Position x and its intensity');
ax = gca;
ax.FontSize = font_size;
xlabel('Position x[\mum]');
ylabel('Intensity');
axis([0,imageRes(2)*c_x,0,maxint]);

hold(ax,'on');

smooth_x = conv(double(slice_x),double(conv_c),'same');
plot(grid_x,smooth_x);
    end

% Slice at the center of imageRes(2).

    function yplot()
positionVector_y = [.05+margin .4+margin .2-margin .5-margin];
axes('Position',positionVector_y)

grid_y = linspace(0, imageRes(1)*c_y, imageRes(1)); %Grid for y direction.
plot(slice_y, grid_y);
ax = gca;
ax.FontSize = font_size;
ax.YDir = 'reverse';

title('Position y and its intensity');


xlabel('Intensity');
ylabel('Position y[\mum]');

axis([0,maxint,0,imageRes(1)*c_y]);

hold(ax,'on');

smooth_y = conv(double(slice_y),double(conv_c),'same');
plot(smooth_y,grid_y);
    end

function color_bar()
    positionColorbar = [.3+margin .9+margin .4-2*margin .1-2*margin];
    axes('Position',positionColorbar);

    bar_255 = 1:1:255;
    imshow(ind2rgb(bar_255, cmap));
    
    
end

set(edit_maxval, 'String', sprintf('%3d',val));
set(edit_maxpos_x, 'String', sprintf('%1.2f um',X*c_x));
set(edit_maxpos_y, 'String', sprintf('%1.2f um',Y*c_y));
set(edit_FWHM_x, 'String', sprintf('%1.2f um',area_x));
set(edit_FWHM_y, 'String', sprintf('%1.2f um',area_y));
set(edit_BRan_x, 'String', sprintf('%1.2f um',range_x));
set(edit_BRan_y, 'String', sprintf('%1.2f um',range_y));
xplot();
yplot();
color_bar();

% Refresh the display.
drawnow
end
