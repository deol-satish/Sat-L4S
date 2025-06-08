clear; close all hidden; clc;

%% Satellite Simulation: LEO over Australia
fprintf('=== Starting Satellite Simulation ===\n');

%% Earth-Space Propagation Losses from ITU documents
maps = exist('maps.mat','file');
p836 = exist('p836.mat','file');
p837 = exist('p837.mat','file');
p840 = exist('p840.mat','file');
matFiles = [maps p836 p837 p840];
if ~all(matFiles)
    if ~exist('ITURDigitalMaps.tar.gz','file')
        url = 'https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz';
        websave('ITURDigitalMaps.tar.gz',url);
        untar('ITURDigitalMaps.tar.gz');
    else
        untar('ITURDigitalMaps.tar.gz');
    end
    addpath(cd);
end

%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');
startTime = datetime(2025,4,10,12,0,0);
duration_sec = 60 * 5;     % simulation duration in seconds
sampleTime = 60;            % second sampling time
stopTime = startTime + seconds(duration_sec);

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
earthRadius = 6371;     % km
kb = physconst('Boltzmann');
tempK = 293;           % Noise temperature
%rainLoss = 2.0;        % dB
%cloudLoss = 1.5;       % dB


%% === Parameters
E = wgs84Ellipsoid;
Re = 6371000;  % Earths mean radius in meters

Param.h = 1200e3;  % OneWeb altitude ~1200 km
Elem.a = Re + Param.h;
Elem.Inc = 87.9;   % Near-polar inclination
Param.NPln = 4;   % Number of orbital planes
Param.NSat = 4;    % Satellites per plane
Param.TNSats = Param.NPln * Param.NSat;
Param.sampleTime = 60; % second sampling time

startTime = datetime(2025,3,6,15,0,0);
duration_sec = 60 * 30;     % simulation duration in seconds
stopTime = startTime + seconds(duration_sec);

%% === Create Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);

% Use Walker Star configuration (Phase offset = 0)
leoSats = walkerStar(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 0);
set(leoSats, 'ShowLabel', true);

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



leoTx = [];

%% Add transmitter and antenna pattern to each Walker Star satellite
for i = 1:numel(leoSats)
    fprintf('  Adding transmitter to satellite %d\n', i);
    tx = transmitter(leoSats(i), 'Frequency', channelFreqs(1), 'Power', leoPower);
    gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    pattern(tx);  % Optional: plot the radiation pattern
    LeoTx(i) = tx;
end

%% Receivers on Ground Stations
fprintf('Setting up ground station receivers...\n');
fprintf('Setting up dual receivers and gimbals for each ground station...\n');


rxGimbals_LEO = containers.Map();
rxReceivers_LEO = containers.Map();


% Create and store LEO receiver and gimbal for each LEO GS
for i = 1:numel(leoGsList)
    gs = leoGsList{i};
    gsName = gs.Name;

    % --- Gimbal and receiver for LEO GS
    leoGimbal = gimbal(gs);
    leoRx = receiver(leoGimbal, ...
        'GainToNoiseTemperatureRatio', 30, ...
        'RequiredEbNo', 10, ...
        'SystemLoss', 1.0);
    gaussianAntenna(leoRx, ...
        'DishDiameter', gsAntenna);

    % Point to first LEO initially
    pointAt(leoGimbal, leoSats(1));

    % Store
    rxGimbals_LEO(gsName) = leoGimbal;
    rxReceivers_LEO(gsName) = leoRx;
end






%% Initialize data collection
fprintf('Initializing data collection...\n');
ts = startTime:seconds(sampleTime):stopTime;
validSamples = 0;

fprintf('Starting first pass to count valid samples...\n');
% First pass to count valid samples (where at least one LEO has access)
for tIdx = 1:length(ts)
    t = ts(tIdx);
    leoAccess = false;
    % access line is drawn based on visibility and elevation, not antenna pattern gain.
    
    % Check if any LEO has access to any ground station
    for i = 1:numel(leoSats)
        for gsIdx = 1:numel(leoGsList)
            lac = access(leoSats(i), leoGsList{gsIdx});
            lac.LineColor = 'red';
            lac.LineWidth = 3;
            if accessStatus(lac, t)
                leoAccess = true;
                fprintf('  Found LEO access at %s (LEO-%d to %s)\n', datestr(t), i, leoGsList{gsIdx}.Name);
                break;
            end
        end
        if leoAccess, break; end
    end
    
    if leoAccess
        validSamples = validSamples + 1;
    end

end
fprintf('First pass complete. Found %d valid samples with LEO access.\n', validSamples);


% Pre-allocate based on valid samples
fprintf('Pre-allocating data structures...\n');
logData = struct();
logData.Time = NaT(validSamples, 1);
logData.LEO = struct();


% Initialize LEO data
for i = 1:numel(leoSats)
    logData.LEO(i).Name = leoSats(i).Name;
    logData.LEO(i).Latitude = zeros(validSamples, 1);
    logData.LEO(i).Longitude = zeros(validSamples, 1);
    logData.LEO(i).Frequency = zeros(validSamples, 1);
    logData.LEO(i).Access = zeros(validSamples, numel(leoGsList));
    logData.LEO(i).SNR = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).RSSI = NaN(validSamples, numel(leoGsList));
end

%store time-series SNR for each satellite
snrTimeline = struct();
for i = 1:numel(leoSats)
    snrTimeline.(sprintf('LEO%d', i)) = [];
end

snrTimeline.Time = datetime.empty;



%% Simulation Loop with Selective Logging
fprintf('Starting main simulation loop...\n');
sampleCount = 0;

for tIdx = 1:length(ts)
    t = ts(tIdx);
    fprintf('\nProcessing time step %d/%d: %s\n', tIdx, length(ts), datestr(t));
    
    leoAccess = false;
    geoAccess = false;
    accessDetails = '';
    
    % First check if any LEO has access to any ground station
    for i = 1:numel(leoSats)
        for gsIdx = 1:numel(leoGsList)
            lac = access(leoSats(i), leoGsList{gsIdx});
            lac.LineColor = 'red';
            lac.LineWidth = 3;
            if accessStatus(lac, t)
                leoAccess = true;
                accessDetails = sprintf('LEO-%d to %s', i, leoGsList{gsIdx}.Name);
                fprintf('  Access detected: %s\n', accessDetails);
                break;
            end
        end
        if leoAccess, break; end
    end


    
    % Only process if at least one LEO has access (GEOs can be added later)
    if leoAccess
        sampleCount = sampleCount + 1;
        logData.Time(sampleCount) = t;
        fprintf('  Processing sample %d (valid sample %d)\n', tIdx, sampleCount);
        
        %% Fequecy allocation logic (random channel selection for both LEO)
        % Update LEO frequencies
        currentLEOFreqs = channelFreqs(randi([1 10], 1, numel(leoSats)));
        fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));


        % Update LEO satellite data
        for i = 1:numel(leoSats)
            
            [pos, ~] = states(leoSats(i), t, 'CoordinateFrame', 'geographic');
            logData.LEO(i).Latitude(sampleCount) = pos(1);
            logData.LEO(i).Longitude(sampleCount) = pos(2);
            logData.LEO(i).Frequency(sampleCount) = currentLEOFreqs(i);
            
            % Update transmitter frequency for this LEO
            tx = LeoTx(i);
            tx.Frequency = currentLEOFreqs(i);
            %pattern(tx);
            
            % Check access and calculate metrics for each ground station
            for gsIdx = 1:numel(leoGsList)
                lac = access(leoSats(i), leoGsList{gsIdx});
                %lac.LineColor = 'red';
                %lac.LineWidth = 3;
                acc = accessStatus(lac, t);
                logData.LEO(i).Access(sampleCount, gsIdx) = acc;
                
                %if acc
                if acc
                    pointAt(rxGimbals_LEO(leoGsList{gsIdx}.Name), leoSats(i));
                    % Calculate link metrics
                    linkLEO = link(tx, rxReceivers_LEO(leoGsList{gsIdx}.Name));
                    [~, Pwr_dBW] = sigstrength(linkLEO, t);


                    % Calculate elevation angle
                    [~, elevationAngle, ~] = aer(rxReceivers_LEO(leoGsList{gsIdx}.Name), leoSats(i), t);

                    % Use ITU-R P.618 atmospheric propagation loss model
                    cfg = p618Config;
                    cfg.Frequency = max(baseFreq, 4e9); %ITU P.618 model is not officially validated for frequencies below 4 GHz.
                    cfg.ElevationAngle = max(elevationAngle, 5);
                    cfg.Latitude = leoGsList{gsIdx}.Latitude;
                    cfg.Longitude = leoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001; % Typical exceedance

                    [pl, ~, ~] = p618PropagationLosses(cfg);
                    atmosLoss = pl.At; % Atmospheric attenuation (dB)

                    rssi = Pwr_dBW - atmosLoss;
                    snr = rssi - 10*log10(kb*tempK*channelBW);
                    
                    logData.LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.LEO(i).SNR(sampleCount, gsIdx) = snr;
                    
                    fprintf('    LEO-%d to %s (%.6f GHz): RSSI=%.2f dBm, SNR=%.2f dB\n', ...
                        i, leoGsList{gsIdx}.Name, currentLEOFreqs(i)/1e9, rssi, snr);
                end
            end
        end
        
        % Log average SNRs only after SNRs have been computed
        snrTimeline.Time(end+1) = t;
        for i = 1:numel(leoSats)
            avgSNR = nanmean(logData.LEO(i).SNR(sampleCount, :));
            snrTimeline.(sprintf('LEO%d', i))(end+1) = avgSNR;
        end
        
    else
        fprintf('  No LEO access detected - skipping this time step\n');

    end
end
fprintf('\nMain simulation loop completed. Processed %d valid samples.\n', sampleCount);


%% Save Data to CSV (only valid samples)
fprintf('\nPreparing data for CSV export...\n');
% Prepare data for CSV export
csvData = table();
csvData.Time = logData.Time;


% Add LEO data
for i = 1:numel(leoSats)
    fprintf('  Adding LEO-%d data to CSV structure\n', i);
    csvData.(sprintf('LEO%d_Name', i)) = repmat(logData.LEO(i).Name, validSamples, 1);
    csvData.(sprintf('LEO%d_Lat', i)) = logData.LEO(i).Latitude;
    csvData.(sprintf('LEO%d_Lon', i)) = logData.LEO(i).Longitude;
    csvData.(sprintf('LEO%d_Freq_Hz', i)) = logData.LEO(i).Frequency;
    
    for gsIdx = 1:numel(leoGsList)
        gsName = strrep(leoGsList{gsIdx}.Name, ' ', '_');
        csvData.(sprintf('LEO%d_%s_Access', i, gsName)) = logData.LEO(i).Access(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_SNR_dB', i, gsName)) = logData.LEO(i).SNR(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_RSSI_dBm', i, gsName)) = logData.LEO(i).RSSI(:, gsIdx);
    end
end

% Write to CSV
fprintf('Writing data to CSV file...\n');
writetable(csvData, 'Satellite_Australia_Simulation_Log.csv');
fprintf('CSV saved with %d valid samples: Satellite_Australia_Simulation_Log.csv\n', validSamples);

%% Play Simulation
%fprintf('\nStarting visualization...\n');
%v = satelliteScenarioViewer(sc);
%v.ShowDetails = true;
%play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Complete ===\n');


function overlapFactor = getOverlapFactor(txFreq, txBW, intfFreq, intfBW)
    txRange = [txFreq - txBW/2, txFreq + txBW/2];
    intfRange = [intfFreq - intfBW/2, intfFreq + intfBW/2];
    overlap = max(0, min(txRange(2), intfRange(2)) - max(txRange(1), intfRange(1)));
    overlapFactor = overlap / intfBW;
end


%% Save Simulation State
fprintf('\nSaving simulation scenario and log data...\n');
save('SatelliteSimulationState.mat', 'sc', 'logData',  'leoSats', 'leoGsList', 'leoTx', 'snrTimeline');
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
for i = 1:numel(leoSats)
    h = plot(snrTimeline.Time, snrTimeline.(sprintf('LEO%d', i)), '-o');
    plotHandles(end+1) = h;
    legendEntries{end+1} = sprintf('LEO-%d', i);
end

xlabel('Time'); ylabel('Avg SNR (dB)');
title('Replay: SNR Over Time');
legend(plotHandles, legendEntries, 'Location', 'northeastoutside');
grid on;
hold off;


