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

%% === Ground Stations (Melbourne and Sydney)
gsMelbourne = groundStation(sc, "Latitude", -37.8136, "Longitude", 144.9631, 'Name', 'Melbourne Station');
gsSydney = groundStation(sc, "Latitude", -33.8688, "Longitude", 151.2093, 'Name', 'Sydney Station');

%% === Visualize Satellite Constellation
v = satelliteScenarioViewer(sc);
play(sc, PlaybackSpeedMultiplier=100);

%% === Simulate Data Transfer

% Iterate through each time step of the scenario
for t = startTime:Param.sampleTime/60/60:stopTime
    % Get current time in the scenario
    currentTime = datetime(t, 'Format', 'yyyy-MM-dd HH:mm:ss');
    
    % Check if a satellite is in communication range of both ground stations
    for i = 1:Param.TNSats
        satellite = sats(i);
        
        % Get satellite position at the current time
        satPos = position(satellite, currentTime);
        
        % Check if the satellite is in range of both ground stations
        visibleToMelbourne = isVisible(gsMelbourne, satellite, currentTime);
        visibleToSydney = isVisible(gsSydney, satellite, currentTime);
        
        if visibleToMelbourne && visibleToSydney
            fprintf('Data transfer possible at %s between Melbourne and Sydney via Satellite %d\n', currentTime, i);
        end
    end
end
