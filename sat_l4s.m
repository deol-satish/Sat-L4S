clear; close all hidden; clc;

%% === Parameters
E = wgs84Ellipsoid;
Re = earthRadius("m");

% --- OneWeb Parameters ---
Param.h = 1200e3;                      % Altitude ~1200 km
Elem.a = Re + Param.h;                % Semi-major axis
Elem.Inc = 87.9;                      % Inclination ~87.9°
Param.NPln = 18;                      % Number of orbital planes
Param.NSat = 36;                      % Satellites per plane
Param.TNSats = Param.NPln * Param.NSat;
Param.sampleTime = 60;               % Sample every 60 sec

% --- Simulation Time ---
startTime = datetime(2025,3,6,15,0,0);
stopTime  = startTime + hours(1);

%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);

% --- Generate Walker Delta Constellation ---
% Relative spacing = 1 (like OneWeb)
sats = walkerDelta(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 1);
set(sats, 'ShowLabel', false);

%% === Ground Station(s)
gs1 = groundStation(sc, "Latitude", -33.86, "Longitude", 151.21, 'Name','Sydney');

%% === Visualization
v  = satelliteScenarioViewer(sc);
campos(v, -33.86, 151.21, 2e7);  % View from above Sydney
play(sc, PlaybackSpeedMultiplier=100);
