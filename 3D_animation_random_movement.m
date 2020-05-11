%% Call the function OpenWindow
% It contains the resolution, framerate, width ...
%% Setup Psychtoolbox for OpenGL 3D rendering support and initialize the mogl OpenGL for Matlab wrapper:
%%
AssertOpenGL;
InitializeMatlabOpenGL;
PsychImaging('PrepareConfiguration');
%% Path to the code file
%%
cd ('~/Documents/Ph.D_with_Paul/Matlab/Learning/moving_dots/3D/')
%% Define a display window
%%
display = OpenWindow();
%% Let's define a structure 'dots' that holds the paramters for the field of dots

dots.nDots = 100;                       % number of dots
dots.color = [255,255,255];             % color of the dots
dots.size = 10;                         % size of dots (pixels)
dots.center = [0,0,0];                  % center of the field of dots (x,y,z)
dots.apertureSize = [15,15,15];         % size of rectangular aperture [w,h,depth] in degrees
%% Parameters of the Projection
%%
proj.aspect_ratio = display.resolution(1)/display.resolution(2);     % Aspect ratio : used frame buffer Width / Height
proj.fov = 90;                                                       % Field of View; typical value range 45 – 90 degrees
proj.z_near = 0.4;                                                   % Distance from camera to near clip plane in Z
proj.z_far = 200;                                                    % Distance from camera to far clip plane. MUST be greater than zNear
proj.eyeheight = 50; 
%% Now we'll define a random position within the apeure for each of the dots. 'dots.x' and 'dots.y' will hold the x and y positions for each dot.

[dots.x,dots.y,dots.z] = CreateUniformDotsIn3DFrustum(dots.nDots, proj.fov, 1/proj.aspect_ratio, proj.z_near, proj.z_far, proj.eyeheight);                                                                       
%% Next we'll convert these dot positions from visual angle into pixel coordinates using the function 'angle2pix'
% To do this, we need three piecedisplay = OpenWindow(display)s of information: 
% (1) The pixel resolution of the screen . (2) The width of the screen in real 
% units (we'll use centimeters) . (3) The distance of the screen from the observer 
% in centimeters. To do this right you'll need a ruler.
% 
% For this example I'll use numbers that approximate the dimensions I have 
% on my laptop for me sitting in my office. We'll put these values in the 'display' 
% structure:

tmp = Screen('Resolution',0);                       % (1) Screen's 'Resolution' function determine the screen resolution.
display.resolution = [tmp.width,tmp.height];

display.width = 30;                                 % (2) Width of the screen in cm (with a ruler).
display.dist = 50;                                  % (3) Distance of the screen from the observer in cm.

% This generates pixel positions, but they're centered at [0,0], which is the top left corner

pixpos.x = angle2pix(display,dots.x);               % Convert the x position of the dots from visual angle to pixel.
pixpos.y = angle2pix(display,dots.y);               % Convert the y position of the dots from visual angle to pixel.
pixpos.z = angle2pix(display,dots.z);
%pixpos.z =  -1+ 2 .*rand(1,dots.nDots);
%% We need to define some timing and motion parameters, which we'll append to the 'dots' structure:

dots.speed = 3;                             % degrees/second
dots.duration = 10;                          % seconds
dots.theta_deg = randi(360,1,dots.nDots);   % degrees 
dots.phi_deg = 30;                          % degrees 
dots.theta_rad = dots.theta_deg * pi /180;  % direction converted to radians
dots.phi_rad = dots.phi_deg * pi /180;      % direction converted to radians
%% Our First Animation 
% Animation is performed by updating the dot position on each frame and re-drawing 
% the frame. We need to know the frame-rate of our monitor so that we can calculate 
% how much we need to change the dot positions on each frame. Fortuantely, our 
% 'OpenWindow' function appends the field 'frameRate' to the 'display' structure.
% 
% |The distance traveled by a dot (in degrees) is the speed(degrees/second) 
% divided by the frame rate (frames/second).| The units cancel, leaving degrees/frame 
% which makes sense. Basic trigonometry (sines and cosines) allows us to determine 
% how much the changes in the x and y position.
% 
% So the x and y position changes, which we'll call dx and dy (derivates), 
% can be calculated by: moglDrawDots3D

dx = dots.speed* sin(-dots.phi_rad-dots.theta_rad)/display.frameRate;
dy = -dots.speed* cos(dots.phi_rad + dots.theta_rad)/display.frameRate;
dz = -dots.speed*cos(dots.theta_rad)/display.frameRate;
%% 
% The total number of frames for the animation is determined by the duration 
% (seconds) multiplied by the frame rate (frames/second). The function secs2frames 
% performs the calculation

nFrames = secs2frames(display,dots.duration);

%% Keeping the Dots in the Aperture
% We need to deal with dots moving beyond the edge of the aperture. This requrires 
% a couple more lines of code.
% 
% 
%% First we'll calculate the left, right top, bottom  and depth (forward and backward) of the aperture (in degrees)

l = dots.center(1)-dots.apertureSize(1)/2;
r = dots.center(1)+dots.apertureSize(1)/2;
b = dots.center(2)-dots.apertureSize(2)/2;
t = dots.center(2)+dots.apertureSize(2)/2;
d_forward = dots.center(3)- dots.apertureSize(3)/2;
d_backward = dots.center(3)+ dots.apertureSize(3)/2;
%% New random starting positions
%%
[dots.x,dots.y,dots.z] = CreateUniformDotsIn3DFrustum(dots.nDots, proj.fov, 1/proj.aspect_ratio, proj.z_near, proj.z_far,proj.eyeheight);

%% Close the animation by pressing the ESC botton
%%
% Restrict KbCheck to checking of ESCAPE key:
KbName('UnifyKeynames');
RestrictKeysForKbCheck(KbName('ESCAPE'));
%% Let's make the dots move in the aperture we have just specified
%%
try
    for i=1:nFrames
        
        %convert from degrees to screen pixels
        pixpos.x = angle2pix(display,dots.x)+ display.resolution(1)/2;
        pixpos.y = angle2pix(display,dots.y)+ display.resolution(2)/2;
        pixpos.z = -1+ 2 .*rand(1,dots.nDots);
              
        % Modulate the size
        dots.size = exp((dots.z + 6)/4);
        
        % Draw the dots
        moglDrawDots3D(display.windowPtr, [pixpos.x;pixpos.y;pixpos.z],dots.size, dots.color, dots.center,2);
        
        
        % Modulate the speed
        dx = dots.speed.* sin(-dots.phi_rad-dots.theta_rad)/display.frameRate;
        dy = -dots.speed.* cos(dots.phi_rad + dots.theta_rad)/display.frameRate;
        dz = -dots.speed.*cos(dots.theta_rad)/display.frameRate;
        
        dots.speed =  (dots.z + 6)/4;
        
        %update the dot position
        
        %% If we want something that looks like an orthographic project : comment dots.x and dots.y
        dots.x = dots.x + dx;
        dots.y = dots.y + dy;
        dots.z = dots.z + dz;

        % When the dots are outside the aperture, reinitialise random dots coordinates
        
        w=find(dots.x<l | dots.x>r | dots.y<b |dots.y>t | dots.z>d_backward | dots.z<d_forward);
        %w=find(dots.x<l | dots.x>r | dots.y<b |dots.y>t | dots.size == dots.size_max);

        dots.x(w)=(rand(1,length(w))-0.5)*12;
        dots.y(w)=(rand(1,length(w))-0.5)*12;
        dots.z(w)=(rand(1,length(w))-0.5)*12;
        
      
        Screen('Flip',display.windowPtr,0,0);
    end
catch ME
    Screen('CloseAll');
    rethrow(ME)
end
Screen('CloseAll');