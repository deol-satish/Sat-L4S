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
Param.sampleTime = 60; % second sampling time

startTime = datetime(2025,3,6,15,0,0);
duration_sec = 60 * 30;     % simulation duration in seconds
stopTime = startTime + seconds(duration_sec);

%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);

% Use Walker Star configuration (Phase offset = 0)
sats = walkerStar(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 0);
set(sats, 'ShowLabel', true);

%% === Ground Stations (Melbourne and Sydney)
gsMelbourne = groundStation(sc, "Latitude", -37.8136, "Longitude", 144.9631, 'Name', 'Melbourne Station');
gsSydney = groundStation(sc, "Latitude", -33.8688, "Longitude", 151.2093, 'Name', 'Sydney Station');


% Pre-allocate based on valid samples
fprintf('Pre-allocating data structures...\n');
logData = struct();



%% === Simulate Data Transfer

ts = startTime:seconds(Param.sampleTime):stopTime;
validSamples = 0;

% Preallocate time vector and access log
logData.Time = ts';
logData.DualAccessSatIndices = cell(length(ts), 1);  % Each cell will store sat indices with dual access

for tIdx = 1:length(ts)
    t = ts(tIdx);
    currentTime = datetime(t, 'Format', 'yyyy-MM-dd HH:mm:ss');
    fprintf('Current Date and Time is %s \n', currentTime);

    dualAccessSats = [];  % List of satellite indices with dual access at this time step

    % Create access objects once outside the time loop
    melbAccess = access(sats, gsMelbourne);
    sydAccess = access(sats, gsSydney);

    melbAccess.LineColor = 'red';
    melbAccess.LineWidth = 3;
    sydAccess.LineColor = 'blue';
    sydAccess.LineWidth = 3;


    for i = 1:Param.TNSats

        if accessStatus(melbAccess(i), t) && accessStatus(sydAccess(i), t)
            fprintf(' Found access to both ground stations (Melbourne and Sydney) at %s (LEO-%d)\n', currentTime, i);
            dualAccessSats(end+1) = i;  % Append satellite index
        end
    end

    logData.DualAccessSatIndices{tIdx} = dualAccessSats;  % Store list for this timestep

    fprintf('================================================================================================================= \n');
end



save('OneWebSatelliteScenariov2.mat', 'sc');


% Initialize cell arrays for table
numEntries = length(logData.Time);
TimeStr = strings(numEntries, 1);            % For formatted timestamps
AccessSatStr = strings(numEntries, 1);       % For satellite indices as strings

for i = 1:numEntries
    TimeStr(i) = datestr(logData.Time(i), 'yyyy-mm-dd HH:MM:SS');
    satIndices = logData.DualAccessSatIndices{i};
    
    if ~isempty(satIndices)
        AccessSatStr(i) = strjoin(string(satIndices), ',');  % Convert indices to comma-separated string
    else
        AccessSatStr(i) = "";  % No access
    end
end

% Create table
logTable = table(TimeStr, AccessSatStr, 'VariableNames', {'Time', 'SatelliteIndices'});

% Write to CSV
writetable(logTable, 'DualAccessLogv2.csv');

fprintf('✅ logData saved to DualAccessLog.csv\n');



%% === Visualize Satellite Constellation
v = satelliteScenarioViewer(sc);
play(sc, PlaybackSpeedMultiplier=100);
