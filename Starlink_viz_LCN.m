clear; close all hidden; clc;

%% Satellite Simulation: LEO over Australia
fprintf('=== Starting Satellite Simulation ===\n');

%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');



% Frequencies (GHz)
baseFreq = 1.5e9;      % Base frequency
channelBW = 200e3;     % Channel bandwidth
channelFreqs = 1e9 * [1.498875, 1.500125, 1.500375, 1.500625, 1.500875, ...
                      1.501125, 1.501375, 1.501625, 1.501875, 1.502125]; % 10 channels

%% For DownLink
% channelBW = 250e6;  % Each channel 250 MHz wide, typical in Ku-band
% % Start from 10.7 GHz and space them evenly
% channelFreqs = 1e9 * (10.7 : 0.2 : 12.5);  % 10 channels in Ku downlink band

% Power (dBW)
leoPower = 10*log10(20);  % 20 W in dBW

% Antennas (m)
leoAntenna = 0.5;      % LEO antenna diameter
gsAntenna = 2.4;       % Ground station antenna diameter

% Constants
kb = physconst('Boltzmann');
tempK = 293;           % Noise temperature
%rainLoss = 2.0;        % dB
%cloudLoss = 1.5;       % dB


%% === Parameters


startTime = datetime(2025, 4, 10, 12, 0, 0, 'TimeZone', 'Australia/Sydney');  % Start time in Sydney local time
duration_sec = 60 * 30;                   % 30 min simulation in seconds
sampleTime = 60;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);

%% === Create Scenario
sc = satelliteScenario(startTime, stopTime, sampleTime);

% Use Walker Star configuration (Phase offset = 0)
EarthRadius = earthRadius;        % Use MATLAB Aerospace Toolbox Earth radius [m]
%% LEO Walker-Delta Constellation Parameters
walker.a = 547e3 + EarthRadius;     % Semi-major axis: 650 km altitude
walker.Inc = 53;                  % Inclination in degrees (typical for Starlink)
walker.NPlanes = 72;               % Number of orbital planes (original 18)
walker.SatsPerPlane = 22;          % Number of satellites per plane (original 49)
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;


% walker.Inc = 53;                  % Inclination in degrees (typical for Starlink)
% walker.NPlanes = 12;               % Number of orbital planes (original 18)
% walker.SatsPerPlane = 12;          % Number of satellites per plane (original 49)
% walker.PhaseOffset = 1;            % Phase offset for phasing between planes
% leoNum = walker.NPlanes * walker.SatsPerPlane;



% Create the LEO constellation using walkerDelta
leoSats = walkerDelta(sc, ...
    walker.a, ...
    walker.Inc, ...
    walker.SatsPerPlane * walker.NPlanes, ...
    walker.NPlanes, ...
    walker.PhaseOffset, ...
    'Name', "", ...
    'OrbitPropagator', 'two-body-keplerian');
set(leoSats, 'ShowLabel', false);

%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');


% 
% leoCities = {
%     'Newcastle',    -32.9283, 151.7817;
%     'Geelong',      -38.1499, 144.3617;
%     'Sunshine_Coast', -26.6500, 153.0667;
%     'Mandurah',     -32.5366, 115.7447;
%     'Victor_Harbor', -35.5500, 138.6167;
%     'Launceston',   -41.4333, 147.1667;
%     'Katherine',    -14.4667, 132.2667;
%     'Wollongong',   -34.4244, 150.8939;
%     'Townsville',   -19.2500, 146.8167;
%     'Toowoomba',    -27.5667, 151.9500;
% };




leoCities = {
    'Sydney',       -33.8688, 151.2093;
    'Melbourne',    -37.8136, 144.9631;
};


leoGsList = cell(1, size(leoCities, 1));


%% Create LEO ground statsions
for i = 1:size(leoCities,1)
    leoGsList{i} = groundStation(sc, leoCities{i,2}, leoCities{i,3}, 'Name', leoCities{i,1});
    leoGsList{i}.MarkerColor = [0 0 1];  % Blue
end



% leoTx = [];
% 
% %% Add transmitter and antenna pattern to each Walker Star satellite
% for i = 1:numel(leoSats)
%     fprintf('  Adding transmitter to satellite %d\n', i);
%     tx = transmitter(leoSats(i), 'Frequency', channelFreqs(1), 'Power', leoPower);
%     gaussianAntenna(tx, 'DishDiameter', leoAntenna);
%     pattern(tx);  % Optional: plot the radiation pattern
%     LeoTx(i) = tx;
% end
% 
% %% Receivers on Ground Stations
% fprintf('Setting up ground station receivers...\n');
% fprintf('Setting up dual receivers and gimbals for each ground station...\n');
% 
% 
% rxGimbals_LEO = containers.Map();
% rxReceivers_LEO = containers.Map();
% 
% 
% % Create and store LEO receiver and gimbal for each LEO GS
% for i = 1:numel(leoGsList)
%     gs = leoGsList{i};
%     gsName = gs.Name;
% 
%     % --- Gimbal and receiver for LEO GS
%     leoGimbal = gimbal(gs);
%     leoRx = receiver(leoGimbal, ...
%         'GainToNoiseTemperatureRatio', 30, ...
%         'RequiredEbNo', 10, ...
%         'SystemLoss', 1.0);
%     gaussianAntenna(leoRx, ...
%         'DishDiameter', gsAntenna);
% 
%     % Point to first LEO initially
%     pointAt(leoGimbal, leoSats(1));
% 
%     % Store
%     rxGimbals_LEO(gsName) = leoGimbal;
%     rxReceivers_LEO(gsName) = leoRx;
% end






%% Initialize data collection
fprintf('Initializing data collection...\n');
ts = startTime:seconds(sampleTime):stopTime;
validSamples = 0;

% Cache access objects to avoid recomputation


leoToLeoAccess = cell(numel(leoGsList));

leoToLeoAccessIntervals = cell(numel(leoGsList));


uniqueSatIDs = [];  % Initialize list to hold all satellite IDs with access

for j = 1:numel(leoGsList)
    % Create access object between all satellites and current GS
    leoToLeoAccess{j} = access(leoSats, leoGsList{j});
    fprintf('LEO GS %s\n', leoGsList{j}.Name);
    
    % Set visualization options (optional)
    leoToLeoAccess{j}.LineColor = 'red';
    leoToLeoAccess{j}.LineWidth = 3;
end

leoToLeoAccess{1}.LineColor = 'red';
leoToLeoAccess{2}.LineColor = 'magenta';
% leoToLeoAccess{2}.LineColor = 'white';


% fprintf('Starting first pass to count valid samples...\n');
% % First pass to count valid samples (where at least one LEO has access)
% for tIdx = 1:length(ts)
%     t = ts(tIdx);
%     leoAccess = false;
%     % access line is drawn based on visibility and elevation, not antenna pattern gain.
% 
%     % Check if any LEO has access to any ground station
%     for i = 1:numel(leoSats)
%         for gsIdx = 1:numel(leoGsList)
%             lac = access(leoSats(i), leoGsList{gsIdx});
%             lac.LineColor = 'red';
%             lac.LineWidth = 3;
%             if accessStatus(lac, t)
%                 leoAccess = true;
%                 fprintf('  Found LEO access at %s (LEO-%d to %s)\n', datestr(t), i, leoGsList{gsIdx}.Name);
%                 break;
%             end
%         end
%         if leoAccess, break; end
%     end
% 
%     if leoAccess
%         validSamples = validSamples + 1;
%     end
% 
% end
% fprintf('First pass complete. Found %d valid samples with LEO access.\n', validSamples);


%% Save Simulation State
fprintf('\nSaving simulation scenario and log data...\n');
save('SatelliteSimulationState.mat', 'sc');
fprintf('Simulation state saved to SatelliteSimulationState.mat\n');

%% Load Simulation State
fprintf('\nLoading simulation scenario data...\n');
load('SatelliteSimulationState.mat');
v = satelliteScenarioViewer(sc);
v.ShowDetails = true;
play(sc, 'PlaybackSpeedMultiplier', 50);
fprintf('=== Simulation Load Complete ===\n');


