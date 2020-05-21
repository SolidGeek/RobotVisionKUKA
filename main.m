%% RobotVision Camera sutff

clc;
close all;

% Includes helper functions and FIXED Robolink class
addpath('functions');
addpath('source');

disp('--- Build a Simpson v1.0 ---');

% Link MATLAB with RoboDK
RDK = Robolink;

% Set the simulation speed. This is a ratio, for example, simulation speed
% of 5 (default) means that 1 second of simulated time corresponds to 1
% second of real time.
RDK.setSimulationSpeed(5);

% Define the robot
arm = RDK.Item('KUKA KR 6 R700 sixx');
arm.setSpeed(100); % Set the TCP linear speed in mm/s

reset = RDK.Item('Reset');
reset.RunProgram();

% Get world frame
world_frame = RDK.Item('World Frame');
arm.setPoseFrame(world_frame);

% Get build frame and its position
build_frame = RDK.Item('LEGO Build Frame');

% Get reference to the tool TCP
tool = RDK.Item('GripperTCP');

% Get reference to the gripper
gripper = RDK.Item('RobotiQ 2F85');

targetHome = RDK.Item('Home');
jhome = targetHome.Joints();
% Move robot to the home position (defined in the simulation)
arm.MoveJ(jhome);


% Initiate robot helper functions with references to the items
robot = Robot;
robot.roboarm = arm; 
robot.robotool = tool;
robot.robogripper = gripper;

% Get the center point of the plate
plate_pos = build_frame.Pose() + robot.addTrans(130, 130, 30);


% --- Now initate the camera stuff ---
RDK.Cam2D_Close(0);

camera = RDK.Item('Camera');
camera_id = RDK.Cam2D_Add(camera);

% Take a picture and close again
RDK.Cam2D_Snapshot('images/raw.jpg', camera_id);
RDK.Cam2D_Close(0);


% Import the python script for image processing
import py.find_lego_bricks.*

name = input('Select between: marge, bart, homer, maggie or lisa \n','s');

if isempty(name)
    disp('Please type a name');
else

    disp('Initiating brick detection...');
    
    % Call the Python script with the wanted character name
    results = py.find_lego_bricks.run(name); 

    % Convert the results to a matrix
    table = cell(results);

    coordinates = zeros(length(table), 2);

    for i = 1:length(table)
        array = cell(table{i});
        coordinates(i, :) = cellfun(@double, array);
    end
    
    disp('- All bricks detected!');
    
    disp(coordinates);
    disp('Building you a Simpson');
    
    for i = 1:length(coordinates)
        % Get the target 
        pos = coordinates(i,:); 
        disp('Going to:'); disp(pos);
        
        % Move to target positon
        robot.setXYZ( pos(1,1) , pos(1,2), 50 );
        robot.setXYZ( pos(1,1) , pos(1,2), 30 );
        
        % Pickup the brick
        robot.attach();
        
        % Move up a little 
        robot.moveZ(50);
        
        % Move to the building zone (a little above)
        pos = plate_pos + robot.addTrans(0,0, (i-1)*20 + 30);
        robot.setTrans(pos);
        
        % Lower to correct height
        robot.moveZ(-30);
        
        % Detach the brick
        robot.detach();
        
        % Raise the tool again
        robot.moveZ(30);
 
    end
    
    arm.MoveJ(jhome);
    
    robot.clap();
    
end
