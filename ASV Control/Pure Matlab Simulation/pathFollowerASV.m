function [yawRef, ASV] = pathFollowerASV(ASV, ref, sim, i)
%% PATH FOLLOWING controller for ASV
%Input 2 points, generates a path between them and commands the vehicle to
%follow it.

%% Process Path
start = ref.start;
finish = ref.finish;

% gradient [m]
m = (finish(2,1)-start(2,1)) / (finish(1,1)-start(1,1));
% constant desired yaw [yawD]
yawD = atan2d( (finish(2,1) - start(2,1)) , (finish(1,1) - start(1,1)));
% y intersect [c]
c = start(2,1) - m*start(1,1);

%% Path Error
% find nearest point's x
if m == -1
    % adjusting for sigularity in xD function
    xD = (ASV.state.x - ASV.state.y)/2;
else
    % standard case
    xD = (ASV.state.x + ASV.state.y - c)/(m + 1);
end

% find nearest point's y
yD = m*xD + c;

closestPoint = [xD;yD];

% find cross track error
crossTrack = sqrt((xD - ASV.state.x)^2 + (yD - ASV.state.y)^2);

path = m*ASV.state.x + c;
if ASV.state.y < path
    crossTrack = - crossTrack;
end

ASV.error.e = crossTrack;

%% Integral
if i == 1
    ASV.error.eIntHold = 0;
end
ASV.error.eInt = ASV.error.eIntHold + ASV.error.e*sim.Ts;
ASV.error.eIntHold = ASV.error.eInt;

%% Yaw error
ASV.error.yaw = yawD - ASV.state.yaw;

%% Provide Yaw Ref
% gain values
K1 =  10.0; %yaw proportional
K2 =  5.0; %cross-track proportional
K4 =  0.2; %integral

if ASV.state.x > 0
    direc = -1;
else
    direc = 1;
end

% delta term
yawDel = K1*ASV.error.yaw + direc*K2*crossTrack/ref.uRef ...
         + direc*K4*ASV.error.eInt;
yawRef = yawD + yawDel;

end

