
function sliders_layout(fig, position)
    global src data cmap;
    global margin;
    global running background setBackgroundData vidobj hImage;
    % Camera properties
    
    info = imaqhwinfo('tisimaq_r2013',1);
    range = info.SupportedFormats;
    
    % Gain
    gain_max = 48;
    gain_min = 0;

    init_gain_val = 20;

    % Exposure
    
    exp_max = 1;
    exp_min = -4;

    init_exp_val = -1;
    
    % ------------
    win_pos = get(fig, 'Position');
    
    % Layout variables
    font_size = 12;
    
    
    label_width = 45;
    label_height = 20;

    panel_cam_size_x = position(3) - 2*margin;
    panel_cam_size_y = position(4) - 2*margin;

    panel_cam_left = position(1) + margin;
    panel_cam_bottom = position(2) + margin;
    
    slider_length = win_pos(3)*panel_cam_size_x - 2*label_width;
    slider_height = label_height;

    % MOST BOTTOM SLIDER
    
    base_pos = 5;
    panel_cam = uipanel(fig,'Title','Camera','FontSize',font_size,...
                        'Position',...
                        [panel_cam_left panel_cam_bottom panel_cam_size_x panel_cam_size_y]);

    label_gain_val = uicontrol(panel_cam, 'Style','Text', 'String', ['Gain:' num2str(init_gain_val)],...
                                'Position', [label_width base_pos + label_height slider_length label_height],...
                                'FontSize',font_size);

    label_gain_min = uicontrol(panel_cam, 'Style','Text', 'String', gain_min,...
                                'Position', [0 base_pos label_width label_height],...
                                'FontSize',font_size);
    label_gain_max = uicontrol(panel_cam, 'Style','Text', 'String', gain_max,...
                                'Position', [label_width + slider_length base_pos label_width label_height],...
                                'FontSize',font_size);
    
    slider_gain = uicontrol(panel_cam, 'Style','slider',...
                            'Min',gain_min,'Max',gain_max,'Value',init_gain_val,...
                            'Position',[label_width base_pos slider_length slider_height],'SliderStep',[0.005 0.05],...
                            'Callback', @changeGain);
    function changeGain(source,callbackdata)
        % here logic of changing camera gain
        src.Gain = source.Value;
        set(label_gain_val, 'String', ['Gain:' num2str(source.Value)])
    end

    % NEXT SLIDER UPWARDS

    base_pos = base_pos + 2*label_height;
    
    label_exp_val = uicontrol(panel_cam, 'Style','Text', 'String', ['Exposure:' num2str(10^(init_exp_val))],...
                                'Position', [label_width base_pos + label_height slider_length label_height],...
                                'FontSize',font_size);
    
    label_exp_min = uicontrol(panel_cam, 'Style','Text', 'String', ['10^' num2str(exp_min)],...
                                'Position', [0 base_pos label_width label_height],...
                                'FontSize',font_size);
    label_exp_max = uicontrol(panel_cam, 'Style','Text', 'String', ['10^' num2str(exp_max)],...
                                'Position', [label_width + slider_length base_pos label_width label_height],...
                                'FontSize',font_size);
    
    slider_exp = uicontrol(panel_cam, 'Style','slider',...
                            'Min',exp_min,'Max',exp_max,'Value',init_exp_val,...
                            'Position',[label_width base_pos slider_length slider_height],'SliderStep',[0.01 0.1],...
                            'Callback', @changeExp);
                        
    function changeExp(source,callbackdata)
        % here logic of changing camera exposure
        src.Exposure = exp(source.Value);
        set(label_exp_val, 'String', ['Exposure[s]:' num2str(10^(source.Value))])
    end
    
    % BUTTON TOGGLE PREVIEW

   

    % BACKGROUND TOGGLE

    base_pos = base_pos + 2*label_height;
    
    button_toggle_background = uicontrol(panel_cam, 'Style','pushbutton', 'String', 'Subtract Background',...
                                'Position', [label_width base_pos slider_length slider_height],...
                                'FontSize',font_size,...
                                'Callback', @toggle_background);
                            
    function toggle_background(source, ~)
        if background
            set(source,'String', 'Subtract Background');
            background = 0;
        else
            set(source,'String', 'Return Background');
            background = 1;
            setBackgroundData = 1;
        end
    end


    base_pos = base_pos + 2*label_height;
    
    
    button_toggle_preview = uicontrol(panel_cam, 'Style','pushbutton', 'String', 'Pause',...
                                'Position', [label_width base_pos slider_length*0.5 slider_height],...
                                'FontSize',font_size,...
                                'Callback', @toggle_preview);
                            
    function toggle_preview(source, ~)
        if running
            stoppreview(vidobj);
            set(source,'String', 'Go');
            running = 0;
        else
            preview(vidobj, hImage);
            set(source,'String', 'Pause');
            running = 1;
        end
    end
    
    button_toggle_save = uicontrol(panel_cam, 'Style','pushbutton', 'String', 'Save',...
                                'Position', [label_width+slider_length*0.5 base_pos slider_length*0.5 slider_height],...
                                'FontSize',font_size,...
                                'Callback', @toggle_save);
                            
     function toggle_save(source, callbackdata)
     dd = datestr(now, 'yyyymmdd_HHMMSS');
     filename = [dd,'.tif'];
     imwrite(data, cmap, filename,'tif')
     end
 
   
    
    


   base_pos = base_pos + 2*label_height;
    
    
    popup_format = uicontrol(panel_cam, 'Style','popup', 'String', range,...
                                'Position', [label_width base_pos slider_length slider_height],...
                                'FontSize',font_size,...
                                'Callback', @change_format);
    
     
    function change_format(source, ~)
        val = source.Value;
        maps = source.String;
        delete('Sparrow_format.mat') ;
        camera_format = char(maps(val));
        save('Sparrow_format.mat','camera_format');
      
        close; 
        SparrowCam_cc();
  
    end

    base_pos = base_pos + 2*label_height;
    
    load('Sparrow_format.mat','camera_format');
    text_format = uicontrol(panel_cam, 'Style','text','FontSize',font_size,...
        'Position',[label_width base_pos slider_length slider_height],...
        'String', ['Format:' camera_format]);
 
end 


