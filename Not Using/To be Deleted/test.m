% Clear workspace
clc; clear; close all;

% Create a satellite scenario
startTime = datetime('now');
startTime = datetime('2025-05-12 14:30:00', 'InputFormat', 'yyyy-MM-dd HH:mm:ss')
stopTime = startTime + hours(24);
sampleTime = 60; % seconds
scenario = satelliteScenario(startTime, stopTime, sampleTime);

% Read TLE file
tleFile = 'starlink_only.tle';

% Method 1: Using satelliteScenario (recommended for newer MATLAB versions)
sat = satellite(scenario, tleFile);
disp('Satellite created directly from TLE file:');
disp(sat);


% Visualize the scenario
v = satelliteScenarioViewer(scenario);

% Access orbital elements
[position, velocity] = states(sat, 'CoordinateFrame', 'inertial');
disp('First position (ECI coordinates in meters):');
disp(position(:,1));

% Get Keplerian orbital elements
[semiMajorAxis, eccentricity, inclination, ...
 rightAscensionOfAscendingNode, argumentOfPeriapsis, trueAnomaly] = orbitalElements(sat);
disp('Orbital elements:');
fprintf('Semi-major axis: %.2f km\n', semiMajorAxis/1000);
fprintf('Eccentricity: %.6f\n', eccentricity);
fprintf('Inclination: %.2f degrees\n', inclination);
fprintf('RAAN: %.2f degrees\n', rightAscensionOfAscendingNode);
fprintf('Argument of periapsis: %.2f degrees\n', argumentOfPeriapsis);
fprintf('True anomaly: %.2f degrees\n', trueAnomaly);

% Add ground track visualization
groundTrack(sat, 'LeadTime', 1200, 'TrailTime', 1200);