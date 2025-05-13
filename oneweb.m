clear; close all hidden; clc;
%% === Parameters
E = wgs84Ellipsoid;
Re = earthRadius("m");
Param.h = 1200e3;  % OneWeb altitude ~1200 km
Elem.a = Re + Param.h;
Elem.Inc = 87.9;   % Near-polar inclination
Param.NPln = 12;   % Number of orbital planes
Param.NSat = 8;    % Satellites per plane
Param.TNSats = Param.NPln * Param.NSat;
Param.sampleTime = 60;
startTime = datetime(2025,3,6,15,0,0);
stopTime  = startTime + hours(1);

%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);

% Use Walker Star configuration (Phase offset = 0)
sats = walkerStar(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 0);

set(sats, 'ShowLabel', false);

%% === Ground Station Example
gs = groundStation(sc, "Latitude", 0, "Longitude", 0, 'Name', 'Equator Station');

%% === Visualize
v  = satelliteScenarioViewer(sc);
play(sc, PlaybackSpeedMultiplier=100);
