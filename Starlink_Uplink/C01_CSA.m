%% Satellite Simulation: LEO over Australia
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
%% Create LEO ground statsions
fprintf('Defining ground stations for each Sat...\n');
P03_SStations
%% Create Satellites
P04_Satellites
save('mySatelliteScenario_starlink.mat', 'sc');
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
writetable(csvData, 'Satellite_Australia_Simulation_Log_starlink.csv');
fprintf('CSV saved with %d valid samples: Satellite_Australia_Simulation_Log_starlink.csv\n', validSamples);
%% Play Simulation
%fprintf('\nStarting visualization...\n');
%v = satelliteScenarioViewer(sc);
%v.ShowDetails = true;
%play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Complete ===\n');
%% Save Simulation State
fprintf('\nSaving simulation scenario and log data...\n');
save('SatelliteSimulationState_starlink.mat', 'sc', 'logData', 'leoSats', 'leoGsList', 'leoRx');
fprintf('Simulation state saved to SatelliteSimulationState_starlink.mat\n');
%% Load Simulation State
fprintf('\nLoading simulation scenario data...\n');
load('SatelliteSimulationState_starlink.mat');
v = satelliteScenarioViewer(sc);
v.ShowDetails = true;
play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Load Complete ===\n');

