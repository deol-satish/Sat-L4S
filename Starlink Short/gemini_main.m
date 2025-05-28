%% Satellite Simulation: LEO over Australia
clear; clc; close all hidden;
fprintf('=== Starting Satellite Simulation ===\n');

%% Control Verbosity
verboseOutput = true; % Set to true for detailed console output, false for speed

%% Load Parameters
% P01_Parameters
%% Earth-Space Propagation Losses from ITU documents
maps = exist('maps.mat','file');
p836 = exist('p836.mat','file');
p837 = exist('p837.mat','file');
p840 = exist('p840.mat','file');
matFiles = [maps p836 p837 p840];
if ~all(matFiles)
    if ~exist('ITURDigitalMaps.tar.gz','file')
        url = 'https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz';
        fprintf('Downloading ITURDigitalMaps.tar.gz...\n');
        websave('ITURDigitalMaps.tar.gz', url);
        fprintf('Untarring ITURDigitalMaps.tar.gz...\n');
        untar('ITURDigitalMaps.tar.gz');
    else
        fprintf('Untarring existing ITURDigitalMaps.tar.gz...\n');
        untar('ITURDigitalMaps.tar.gz');
    end
    % Add path to the directory containing the .mat files if its not the current directory
    % For example, if untar creates a subfolder: addpath('ITUR_DigitalMaps');
    % If files are in current dir, addpath(cd) is usually not needed if cd is on path.
    addpath(cd); 
    fprintf('Added current directory to path for ITU maps.\n');
end
%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');
startTime = datetime(2025, 4, 10, 12, 0, 0, 'TimeZone', 'Australia/Sydney'); % Start time in Sydney local time
duration_sec = 60 * 1; % 1 min simulation in seconds (shortened for quick test, was 30 min)
sampleTime = 60; % Time step in seconds
stopTime = startTime + seconds(duration_sec);
ts = startTime:seconds(sampleTime):stopTime;

%% Frequencies (Hz)
% In particular, the 10.7-12.7 and 14.0- 14.5 GHz band will be used for the user downlink and uplink communications
baseFreq = 11.7e9; % Base frequency in Hz

%% For DownLink
channelBW = 250e6; % Each channel 250 MHz wide, typical in Ku-band
channelFreqs = 1e9 * (10.7 : 0.2 : 12.7); % 10 channels in Ku downlink band

%% Transmit Power (in dBW)
leoPower = 10 * log10(20); % LEO Tx power: 20 W -> ~13.01 dBW

%% Antenna Parameters (Dish Diameter in meters)
leoAntenna = 0.5; % LEO satellite antenna diameter
gsAntenna = 2.4; % Ground station antenna diameter

%% Multi-path Fading Parameters
fadingModel = 'Rician'; % Options: 'None', 'Rayleigh', 'Rician'
ricianK_dB = 10; % Rician K-factor in dB (K=10: strong LoS)

%% Physical Constants
EarthRadius = earthRadius; % Use MATLAB Aerospace Toolbox Earth radius [m]
kb = physconst('Boltzmann'); % Boltzmann constant [J/K]
tempK = 293; % System noise temperature [K]

%% LEO Walker-Delta Constellation Parameters
walker.a = 547e3 + EarthRadius; % Semi-major axis: 547 km altitude (corrected from 650km comment)
walker.Inc = 53; % Inclination in degrees
walker.NPlanes = 14; % Number of orbital planes
walker.SatsPerPlane = 14; % Number of satellites per plane
walker.PhaseOffset = 1; % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;

%% Create Scenario
fprintf('Creating satellite scenario...\n');
sc = satelliteScenario(startTime, stopTime, sampleTime);

%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');
% P02_GStations
leoCities = {
    'Sydney',    -33.8688, 151.2093;
    'Melbourne', -37.8136, 144.9631;
};
leoGsList = cell(1, size(leoCities, 1));

% P03_SStations
fprintf('Defining ground stations...\n');
for i = 1:size(leoCities,1)
    leoGsList{i} = groundStation(sc, leoCities{i,2}, leoCities{i,3}, 'Name', leoCities{i,1});
    leoGsList{i}.MarkerColor = [0 0 1]; % Blue
end

%% Create Satellites
% P04_Satellites
fprintf('Creating LEO Walker-Delta constellation...\n');
leoSats = walkerDelta(sc, ...
    walker.a, ...
    walker.Inc, ...
    walker.SatsPerPlane * walker.NPlanes, ...
    walker.NPlanes, ...
    walker.PhaseOffset, ...
    'Name', "Starlink-Shell-1", ... % Name prefix for satellites
    'OrbitPropagator', 'two-body-keplerian');

leoTx = cell(1, leoNum);

fprintf('Configuring satellites...\n');
for i = 1:leoNum
    if verboseOutput
        fprintf('  Configuring satellite: %s\n', leoSats(i).Name );
    end
    leoSats(i).MarkerColor = [0.3010 0.7450 0.9330]; % Light Blue
    
    tx = transmitter(leoSats(i), ...
        'Frequency', channelFreqs(1), ... % Initial frequency, will be updated
        'Power', leoPower);
    gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    leoTx{i} = tx;
end
% save('mySatelliteScenario_starlink.mat', 'sc'); % Optional: save scenario after creation

%% Receivers on Ground Stations
% P05_GReceivers
fprintf('Setting up ground station receivers...\n');
rxGimbals_LEO = containers.Map();
rxReceivers_LEO = containers.Map();

for i = 1:numel(leoGsList)
    gs = leoGsList{i};
    gsName = gs.Name;
    if verboseOutput
        fprintf('  Setting up receiver for GS: %s\n', gsName);
    end
    leoGimbal = gimbal(gs);
    leoRx = receiver(leoGimbal, ...
        'GainToNoiseTemperatureRatio', 30, ... % Typical G/T for Ku-band terminal
        'RequiredEbNo', 10, ...
        'SystemLoss', 1.0); % dB
    gaussianAntenna(leoRx, 'DishDiameter', gsAntenna);
    if ~isempty(leoSats) % Point to first LEO satellite if constellation exists
        pointAt(leoGimbal, leoSats(1));
    end
    rxGimbals_LEO(gsName) = leoGimbal;
    rxReceivers_LEO(gsName) = leoRx;
end

%% Initialize data collection
fprintf('Initializing data collection (first pass to count valid samples)...\n');
% Cache access objects to avoid recomputation
leoToLeoAccess = cell(leoNum, numel(leoGsList)); % Access objects between LEO sats and LEO GS
for i = 1:leoNum
    for j = 1:numel(leoGsList)
        leoToLeoAccess{i,j} = access(leoSats(i), leoGsList{j});
        % leoToLeoAccess{i,j}.LineColor = 'red'; % Styling for viewer, not critical for speed
        % leoToLeoAccess{i,j}.LineWidth = 3;
    end
end

validSamples = 0;
for tIdx = 1:length(ts)
    t = ts(tIdx);
    sampleHasAccessThisTimeStep = false;
    % Check LEO <-> LEO GS
    for i = 1:leoNum
        for gsIdx = 1:numel(leoGsList)
            if accessStatus(leoToLeoAccess{i, gsIdx}, t) % Use cached access object
                if verboseOutput && ~sampleHasAccessThisTimeStep % Print only once per time step
                   % fprintf('  Access detected at %s (LEO-%d to LEO GS %s)\n', datestr(t), i, leoGsList{gsIdx}.Name);
                end
                sampleHasAccessThisTimeStep = true;
                break; 
            end
        end
        if sampleHasAccessThisTimeStep, break; end
    end
    
    if sampleHasAccessThisTimeStep
        validSamples = validSamples + 1;
    end
end
fprintf('First pass complete. Found %d valid time samples with any access.\n', validSamples);

%% Pre-allocate data structures
fprintf('Pre-allocating data structures...\n');
logData = struct();
if validSamples > 0
    logData.Time = NaT(validSamples, 1, 'TimeZone', 'Australia/Sydney');

    logData.LEO = repmat(struct(...
        'Name', '', ...
        'Latitude', zeros(validSamples, 1), ...
        'Longitude', zeros(validSamples, 1), ...
        'Frequency', zeros(validSamples, 1), ...
        'Access', zeros(validSamples, numel(leoGsList)), ...
        'SNR', NaN(validSamples, numel(leoGsList)), ...
        'RSSI', NaN(validSamples, numel(leoGsList)), ...
        'Thrpt', NaN(validSamples, numel(leoGsList)), ...
        'BER_QPSK', NaN(validSamples, numel(leoGsList)), ...
        'BER_MQAM', NaN(validSamples, numel(leoGsList)), ...
        'Latency', NaN(validSamples, numel(leoGsList)), ...
        'TimeOut', NaT(validSamples, numel(leoGsList), 'TimeZone', 'Australia/Sydney') ...
        ), leoNum, 1);

    for i = 1:leoNum
        logData.LEO(i).Name = leoSats(i).Name;
    end
else
    fprintf('No valid samples found. Skipping data logging structure initialization.\n');
    % Initialize with empty or handle appropriately if no samples
    logData.Time = NaT(0,1, 'TimeZone', 'Australia/Sydney');
    logData.LEO = struct([]); 
end


%% Simulation Loop with Selective Logging
fprintf('Starting main simulation loop...\n');
% P07_SelectiveLogging
sampleCount = 0;
% warning('off', 'MATLAB:datetime:NonstandardFormat'); % Example of specific warning
% warning('off', 'all'); % Suppress all warnings - use with caution

resultsDir = 'Results';
if ~exist(resultsDir, 'dir')
    mkdir(resultsDir);
end

% Precompute Random Frequencies allocation and thermal noise
leoFreqMatrix = channelFreqs(randi([1 length(channelFreqs)], leoNum, length(ts)));
thermalNoise_dB = 10 * log10(kb * tempK * channelBW);
% thermalNoise = kb * tempK * channelBW; % Linear noise power, not directly used in dB calculations below

%% Start actual collection
for tIdx = 1:length(ts)
    t = ts(tIdx);
    if verboseOutput || mod(tIdx, 10) == 0 % Print progress every 10 steps or if verbose
        fprintf('Processing time step %d/%d: %s (Sample count: %d)\n', tIdx, length(ts), char(t), sampleCount);
    end
    
    % Determine if there's any access at this time step to log data
    hasAnyAccessThisTimeStep = false;
    for i = 1:leoNum
        for gsIdx = 1:numel(leoGsList)
            if accessStatus(leoToLeoAccess{i, gsIdx}, t) % USE CACHED ACCESS OBJECT
                hasAnyAccessThisTimeStep = true;
                break;
            end
        end
        if hasAnyAccessThisTimeStep, break; end
    end

    if hasAnyAccessThisTimeStep
        sampleCount = sampleCount + 1;
        logData.Time(sampleCount) = t;
        
        currentLEOFreqs = leoFreqMatrix(:, tIdx);

        %% LEO -> LEO GS
        for i = 1:leoNum % Iterate over LEO satellites
            tx = leoTx{i};
            tx.Frequency = currentLEOFreqs(i); % Update transmitter frequency
            
            [pos, ~] = states(leoSats(i), t, 'CoordinateFrame', 'geographic');
            logData.LEO(i).Latitude(sampleCount) = pos(1);
            logData.LEO(i).Longitude(sampleCount) = pos(2);
            logData.LEO(i).Frequency(sampleCount) = currentLEOFreqs(i);

            for gsIdx = 1:numel(leoGsList) % Iterate over ground stations
                % Point gimbal and satellite antenna
                pointAt(rxGimbals_LEO(leoGsList{gsIdx}.Name), leoSats(i));
                pointAt(leoSats(i), leoGsList{gsIdx}); % Assumes LEO antenna is steerable towards GS

                % Check access status using the cached access object
                currentLinkAccessStatus = accessStatus(leoToLeoAccess{i, gsIdx}, t);
                logData.LEO(i).Access(sampleCount, gsIdx) = currentLinkAccessStatus;

                if currentLinkAccessStatus
                    linkObj = link(tx, rxReceivers_LEO(leoGsList{gsIdx}.Name));
                    
                    [~, Pwr_dBW] = sigstrength(linkObj, t); % Received power in dBW
                    [~, el, ~] = aer(rxReceivers_LEO(leoGsList{gsIdx}.Name), leoSats(i), t); % Elevation angle
                    
                    cfg = p618Config; 
                    cfg.Frequency = max(currentLEOFreqs(i), 4e9); % Ensure freq is >= 4GHz for p618
                    cfg.ElevationAngle = max(el, 5); % Min elevation 5 deg
                    cfg.Latitude = leoGsList{gsIdx}.Latitude;
                    cfg.Longitude = leoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001; % p-value for propagation losses
                    
                    atmosLoss = p618PropagationLosses(cfg).At; % Atmospheric losses in dB
                    fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB); % Multipath fading loss in dB
                    % fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB, el); % If elevation dependent

                    rssi = Pwr_dBW - atmosLoss - fading_dB; % RSSI in dBW
                    snr = rssi - thermalNoise_dB; % SNR in dB
                    
                    logData.LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.LEO(i).SNR(sampleCount, gsIdx) = snr;
                    
                    snrLinear = 10^(snr / 10); % SNR in linear scale
                    throughput = channelBW * log2(1 + snrLinear); % Shannon throughput in bits/s
                    logData.LEO(i).Thrpt(sampleCount, gsIdx) = throughput;

                    % BER Calculations
                    berQPSK = qfunc(sqrt(2 * snrLinear)); % QPSK BER
                    M_qam = 16; % For 16-QAM
                    berMQAM = (4 / log2(M_qam)) * (1 - 1 / sqrt(M_qam)) * qfunc(sqrt(3 * snrLinear / (M_qam - 1)));
                    logData.LEO(i).BER_QPSK(sampleCount, gsIdx) = berQPSK;
                    logData.LEO(i).BER_MQAM(sampleCount, gsIdx) = berMQAM;
                    
                    [delay, timeOut] = latency(leoSats(i), leoGsList{gsIdx}, t);
                    logData.LEO(i).Latency(sampleCount, gsIdx) = delay;
                    logData.LEO(i).TimeOut(sampleCount, gsIdx) = timeOut;
                    
                    if verboseOutput
                        timeoutStr = char(timeOut);
                        fprintf(['  LEO-%d (%s) to %s:\n' ...
                            '    RSSI=%.2f dBW, SNR=%.2f dB, Thrpt=%.2f Mbps\n' ...
                            '    BER(QPSK)=%.2e, BER(16QAM)=%.2e, Latency=%.4f s, Timeout=%s\n' ...
                            '    Details: Pwr_rcvd=%.2f dBW, AtmosLoss=%.2f dB, Fading=%.2f dB, NoiseFloor=%.2f dBW\n'], ...
                            i, leoSats(i).Name, leoGsList{gsIdx}.Name, ...
                            rssi, snr, throughput/1e6, ...
                            berQPSK, berMQAM, delay, timeoutStr, ...
                            Pwr_dBW, atmosLoss, fading_dB, thermalNoise_dB);
                    end
                end % if currentLinkAccessStatus
            end % gsIdx loop
        end % i (leoNum) loop
        
        % DO NOT SAVE IN LOOP FOR PERFORMANCE
        % saveFileName = sprintf('log_step_%03d.mat', tIdx);
        % save(fullfile(resultsDir, saveFileName), 'logData', 't', 'sampleCount', '-v7.3');
    end % if hasAnyAccessThisTimeStep
end % tIdx loop
fprintf('\nSimulation logging complete: %d samples logged.\n', sampleCount);

% Make sure logData is trimmed if validSamples was an overestimate or if sampleCount < validSamples
if validSamples > 0 && sampleCount < validSamples
    fprintf('Trimming logData from %d to %d entries.\n', validSamples, sampleCount);
    logData.Time = logData.Time(1:sampleCount);
    for i = 1:leoNum
        logData.LEO(i).Latitude = logData.LEO(i).Latitude(1:sampleCount);
        logData.LEO(i).Longitude = logData.LEO(i).Longitude(1:sampleCount);
        logData.LEO(i).Frequency = logData.LEO(i).Frequency(1:sampleCount);
        logData.LEO(i).Access = logData.LEO(i).Access(1:sampleCount, :);
        logData.LEO(i).SNR = logData.LEO(i).SNR(1:sampleCount, :);
        logData.LEO(i).RSSI = logData.LEO(i).RSSI(1:sampleCount, :);
        logData.LEO(i).Thrpt = logData.LEO(i).Thrpt(1:sampleCount, :);
        logData.LEO(i).BER_QPSK = logData.LEO(i).BER_QPSK(1:sampleCount, :);
        logData.LEO(i).BER_MQAM = logData.LEO(i).BER_MQAM(1:sampleCount, :);
        logData.LEO(i).Latency = logData.LEO(i).Latency(1:sampleCount, :);
        logData.LEO(i).TimeOut = logData.LEO(i).TimeOut(1:sampleCount, :);
    end
    validSamples = sampleCount; % Update validSamples to actual logged count
end


%% Save Full Log Data (once, after loop)
if validSamples > 0
    fprintf('\nSaving full log data...\n');
    save(fullfile(resultsDir, 'Satellite_Simulation_Log_Full_starlink.mat'), 'logData', 'ts', 'sampleCount', 'validSamples', '-v7.3');
    fprintf('Full log data saved to %s\n', fullfile(resultsDir, 'Satellite_Simulation_Log_Full_starlink.mat'));
else
    fprintf('\nNo valid samples logged. Skipping full log data save.\n');
end

%% Save Data to CSV (only valid samples)
if validSamples > 0
    fprintf('\nPreparing data for CSV export...\n');
    csvData = table();
    csvData.Time = logData.Time; % Already trimmed to sampleCount

    for i = 1:leoNum
        if verboseOutput
            fprintf('  Adding LEO-%d (%s) data to CSV structure\n', i, logData.LEO(i).Name);
        end
        csvData.(sprintf('LEO%d_Name', i)) = repmat(string(logData.LEO(i).Name), validSamples, 1); % Ensure string
        csvData.(sprintf('LEO%d_Lat', i)) = logData.LEO(i).Latitude;
        csvData.(sprintf('LEO%d_Lon', i)) = logData.LEO(i).Longitude;
        csvData.(sprintf('LEO%d_Freq_Hz', i)) = logData.LEO(i).Frequency;
        
        for gsIdx = 1:numel(leoGsList)
            gsName = strrep(leoGsList{gsIdx}.Name, ' ', '_'); % Sanitize GS name for column header
            csvData.(sprintf('LEO%d_%s_Access', i, gsName)) = logData.LEO(i).Access(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_SNR_dB', i, gsName)) = logData.LEO(i).SNR(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_RSSI_dBW', i, gsName)) = logData.LEO(i).RSSI(:, gsIdx); % Note: was dBm, now dBW based on Pwr_dBW
            csvData.(sprintf('LEO%d_%s_Throughput_bps', i, gsName)) = logData.LEO(i).Thrpt(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_BER_QPSK', i, gsName)) = logData.LEO(i).BER_QPSK(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_BER_MQAM', i, gsName)) = logData.LEO(i).BER_MQAM(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_Latency_s', i, gsName)) = logData.LEO(i).Latency(:, gsIdx);
            csvData.(sprintf('LEO%d_%s_TimeOut', i, gsName)) = logData.LEO(i).TimeOut(:, gsIdx);
        end
    end
    
    csvFilename = 'Satellite_Australia_Simulation_Log_starlink.csv';
    fprintf('Writing data to CSV file: %s\n', csvFilename);
    writetable(csvData, fullfile(resultsDir, csvFilename));
    fprintf('CSV saved with %d valid samples: %s\n', validSamples, fullfile(resultsDir, csvFilename));
else
    fprintf('\nNo data to save to CSV.\n');
end

%% Optional: Play Simulation or Load and Play
% Comment these out if you only need data generation for speed.
% fprintf('\nStarting visualization (optional)...\n');
% v = satelliteScenarioViewer(sc);
% v.ShowDetails = true; % Show names and orbits
% play(sc, 'PlaybackSpeedMultiplier', 10); % Reduced speed for better viewing

fprintf('=== Simulation Complete ===\n');

%% Optional: Save Simulation State (Scenario, etc.)
% fprintf('\nSaving simulation scenario and objects...\n');
% save(fullfile(resultsDir,'SatelliteSimulationState_starlink.mat'), 'sc', 'logData', 'leoSats', 'leoGsList', 'leoTx', 'leoToLeoAccess');
% fprintf('Simulation state saved to %s\n', fullfile(resultsDir,'SatelliteSimulationState_starlink.mat'));

%% To Load and visualize later:
% fprintf('\nTo load and visualize later, run the following commands:\n');
% fprintf('load(''%s'');\n', fullfile(resultsDir,'SatelliteSimulationState_starlink.mat'));
% fprintf('v = satelliteScenarioViewer(sc);\n');
% fprintf('v.ShowDetails = true;\n');
% % To show access lines if desired (can be slow for many links)
% % for i=1:size(leoToLeoAccess,1)
% %     for j=1:size(leoToLeoAccess,2)
% %         if ~isempty(leoToLeoAccess{i,j})
% %             show(leoToLeoAccess{i,j});
% %         end
% %     end
% % end
% fprintf('play(sc, ''PlaybackSpeedMultiplier'', 10);\n');

%% Dummy function for F01_GetMultipathFadingLoss if not provided
% Create this function in a separate .m file (F01_GetMultipathFadingLoss.m)
% function fading_dB = F01_GetMultipathFadingLoss(modelType, kFactor_dB, elevation)
% % Example implementation of F01_GetMultipathFadingLoss
% % modelType: 'Rician', 'Rayleigh', 'None'
% % kFactor_dB: Rician K-factor in dB
% % elevation: optional, satellite elevation in degrees
%
%     switch modelType
%         case 'Rician'
%             % For simplicity, returning a fixed value or a simple model.
%             % A real model would involve random number generation based on distributions.
%             % This is a placeholder. For simulation, you'd generate a random variate.
%             % Here, we return a conceptual average impact or a fixed loss for simplicity.
%             % K (linear) = 10^(kFactor_dB / 10);
%             % Example: small fixed loss for strong LoS
%             fading_dB = 1.0; % Placeholder value
%         case 'Rayleigh'
%             % Example: larger fixed loss for Rayleigh
%             fading_dB = 3.0; % Placeholder value
%         case 'None'
%             fading_dB = 0;
%         otherwise
%             fading_dB = 0;
%             warning('Unknown fading model: %s. Assuming no fading.', modelType);
%     end
%
%     % Optionally, make fading dependent on elevation
%     % if nargin > 2 && elevation < 10 % More fading at low elevation
%     %     fading_dB = fading_dB + (10 - elevation) * 0.5;
%     % end
% end