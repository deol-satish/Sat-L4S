clear; close all hidden; clc;

%% This is Starlink First Shell

%% === Earth and Orbit Parameters
Re = earthRadius("m");
altitude = 550e3;               % 550 km
semiMajorAxis = Re + altitude;  % Total semi-major axis
inclination = 53;               % Inclination in degrees

%% === Constellation Configuration
numPlanes = 32;       % Number of orbital planes
satsPerPlane = 50;    % Satellites per plane
totalSats = numPlanes * satsPerPlane;
walkerPhase = 1;      % Walker Delta phase offset

%% === Simulation Time
sampleTime = 60;      % 60 seconds
startTime = datetime(2025,3,6,15,0,0);
stopTime  = startTime + hours(1);

%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Create Walker Delta Constellation
sats = walkerDelta(sc, semiMajorAxis, inclination, totalSats, numPlanes, walkerPhase);

% Optional: hide satellite labels for clarity
set(sats, 'ShowLabel', false);

%% === Add Ground Station (Optional)
gs = groundStation(sc, "Latitude", 37.7749, "Longitude", -122.4194, 'Name', 'San Francisco');

%% === Visualize Scenario
viewer = satelliteScenarioViewer(sc);
% Optional: camera position
% campos(viewer, 37.7749, -122.4194, 200e5);

play(sc, PlaybackSpeedMultiplier = 100);
hj