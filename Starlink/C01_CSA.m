%% Satellite Simulation: GEO + LEO over Australia
clear; clc;close all hidden
fprintf('=== Starting Satellite Simulation ===\n');
%% Load Parameters
P01_Parameters
%% Create Scenario
fprintf('Creating satellite scenario...\n');
sc = satelliteScenario(startTime, stopTime, sampleTime);
%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');
P02_GStations
%% Create GEO and LEO ground statsions
fprintf('Defining ground stations for each Sat...\n');
P03_SStations
%% Create Satellites
P04_Satellites
% satelliteScenarioViewer(sc);
% play(sc,PlaybackSpeedMultiplier=100);
% play(sc)
%% Receivers on Ground Stations
P05_GReceivers
%% Initialize data collection
fprintf('Initializing data collection...\n');
P06_IniDataCollection
%% Simulation Loop with Selective Logging
fprintf('Starting main simulation loop...\n');
P07_SelectiveLogging
%% Save Data to CSV (only valid samples)
fprintf('\nPreparing data for CSV export...\n');
P08_SaveData
writetable(csvData, 'Satellite_Australia_Simulation_Log.csv');
fprintf('CSV saved with %d valid samples: Satellite_Australia_Simulation_Log.csv\n', validSamples);
%% Play Simulation
%fprintf('\nStarting visualization...\n');
%v = satelliteScenarioViewer(sc);
%v.ShowDetails = true;
%play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Complete ===\n');
%% Save Simulation State
fprintf('\nSaving simulation scenario and log data...\n');
save('SatelliteSimulationState.mat', 'sc', 'logData', 'geoSats', 'leoSats', 'geoGsList', 'leoGsList', 'geoTx', 'leoTx', 'snrTimeline');
fprintf('Simulation state saved to SatelliteSimulationState.mat\n');
%% Load Simulation State
fprintf('\nLoading simulation scenario data...\n');
load('SatelliteSimulationState.mat');
v = satelliteScenarioViewer(sc);
v.ShowDetails = true;
play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Load Complete ===\n');
%% plot
figure;
hold on;

plotHandles = [];
legendEntries = {};

% Plot LEO SNR
for i = 1:leoNum
    h = plot(snrTimeline.Time, snrTimeline.(sprintf('LEO%d', i)), '-o');
    plotHandles(end+1) = h;
    legendEntries{end+1} = sprintf('LEO-%d', i);
end

% Plot GEO SNR
for i = 1:geoNum
    h = plot(snrTimeline.Time, snrTimeline.(sprintf('GEO%d', i)), '-x');
    plotHandles(end+1) = h;
    legendEntries{end+1} = sprintf('GEO-%d', i);
end

xlabel('Time'); ylabel('Avg SNR (dB)');
title('Replay: SNR Over Time');
legend(plotHandles, legendEntries, 'Location', 'northeastoutside');
grid on;
hold off;


