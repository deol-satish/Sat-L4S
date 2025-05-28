%% Satellite Simulation: LEO over Australia
clear; clc;close all hidden
fprintf('=== Starting Satellite Simulation ===\n');
%% Load Parameters

%% P01_Parameters
%% Earth-Space Propagation Losses from ITU documents
maps = exist('maps.mat','file');
p836 = exist('p836.mat','file');
p837 = exist('p837.mat','file');
p840 = exist('p840.mat','file');
matFiles = [maps p836 p837 p840];
if ~all(matFiles)
    if ~exist('ITURDigitalMaps.tar.gz','file')
        url = 'https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz';
        websave('ITURDigitalMaps.tar.gz', url);
        untar('ITURDigitalMaps.tar.gz');
    else
        untar('ITURDigitalMaps.tar.gz');
    end
    addpath(cd);  % Add current directory (assumed to have required .mat files) to path
end
%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');
startTime = datetime(2025, 4, 10, 12, 0, 0);  % Simulation start
startTime = datetime(2025, 4, 10, 12, 0, 0, 'TimeZone', 'Australia/Sydney');  % Start time in Sydney local time
duration_sec = 60 * 1;                   % 30 min simulation in seconds
sampleTime = 60;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);
ts = startTime:seconds(sampleTime):stopTime;
%% Frequencies (Hz)


% In particular, the 10.7-12.7 and 14.0- 14.5 GHz band will be used for the user downlink and uplink communications
% user communications respectively
% From, A Technical Comparison of Three Low Earth Orbit Satellite 
% Constellation Systems to Provide Global
% Broadband


baseFreq = 11.7e9;          % Base frequency in Hz

%% For DownLink
channelBW = 250e6;  % Each channel 250 MHz wide, typical in Ku-band
% Start from 10.7 GHz and space them evenly
channelFreqs = 1e9 * (10.7 : 0.2 : 12.7);  % 10 channels in Ku downlink band

% %% For Uplink
% channelBW = 250e6;  % 250 MHz
% channelFreqs = 1e9 * (14.0 : 0.05 : 14.5);  % 10 channels across uplink

%% Transmit Power (in dBW)
leoPower = 10 * log10(20);   % LEO Tx power: 20 W → ~13.01 dBW
%% Antenna Parameters (Dish Diameter in meters)
leoAntenna = 0.5;     % LEO satellite antenna diameter
gsAntenna = 2.4;      % Ground station antenna diameter
%% Multi-path Fading Parameters
fadingModel = 'Rician';    % Options: 'None', 'Rayleigh', 'Rician'
ricianK_dB = 10;           % Rician K-factor in dB (K=10: strong LoS)
%% Physical Constants
EarthRadius = earthRadius;        % Use MATLAB Aerospace Toolbox Earth radius [m]
kb = physconst('Boltzmann');      % Boltzmann constant [J/K]
tempK = 293;                      % System noise temperature [K]
%% LEO Walker-Delta Constellation Parameters
walker.a = 547e3 + EarthRadius;     % Semi-major axis: 650 km altitude
walker.Inc = 53;                  % Inclination in degrees (typical for Starlink)
walker.NPlanes = 12;               % Number of orbital planes (original 18)
walker.SatsPerPlane = 12;          % Number of satellites per plane (original 49)
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;


%% Create Scenario
fprintf('Creating satellite scenario...\n');
sc = satelliteScenario(startTime, stopTime, sampleTime);
%% Ground Stations in Australia
fprintf('Setting up ground stations in Australia...\n');

%% P02_GStations
%% Ground Stations in Australia
leoCities = {
    'Sydney',       -33.8688, 151.2093;
    'Melbourne',    -37.8136, 144.9631;
};
leoGsList = cell(1, size(leoCities, 1));



%% Create LEO ground statsions
fprintf('Defining ground stations for each Sat...\n');
%% P03_SStations
%% Create LEO ground statsions
for i = 1:size(leoCities,1)
    leoGsList{i} = groundStation(sc, leoCities{i,2}, leoCities{i,3}, 'Name', leoCities{i,1});
    leoGsList{i}.MarkerColor = [0 0 1];  % Blue
end

%% Create Satellites
%% P04_Satellites
%% Create LEO Satellites (Walker-Delta Constellation)
fprintf('Creating LEO Walker-Delta constellation...\n');

% Create the LEO constellation using walkerDelta
leoSats = walkerDelta(sc, ...
    walker.a, ...
    walker.Inc, ...
    walker.SatsPerPlane * walker.NPlanes, ...
    walker.NPlanes, ...
    walker.PhaseOffset, ...
    'Name', "Starlink-Shell-1", ...
    'OrbitPropagator', 'two-body-keplerian');

leoTx = cell(1, leoNum);

% % Turn off default labels
% for i = 1:leoNum
%     leoSats(i).ShowLabel = false;
% end

fprintf('Done: Creating LEO Walker-Delta constellation...\n')

% Configure each satellite: assign name mapping and transmitter
for i = 1:leoNum
    % Set marker color
    fprintf('  Configure each satellite: assign name mapping and transmitter, Sat_id: %d\n', i );
    leoSats(i).MarkerColor = [0.3010 0.7450 0.9330];  % Light Blue
    
    % Add transmitter
    tx = transmitter(leoSats(i), ...
        'Frequency', channelFreqs(1), ...
        'Power', leoPower);
    gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    leoTx{i} = tx;
end

save('mySatelliteScenario_starlink.mat', 'sc');
% satelliteScenarioViewer(sc);
% play(sc,PlaybackSpeedMultiplier=100);
% play(sc)
%% Receivers on Ground Stations
%% P05_GReceivers
%% Receivers on Ground Stations
fprintf('Setting up ground station receivers...\n');
fprintf('Setting up dual receivers and gimbals for each ground station...\n');

rxGimbals_LEO = containers.Map();
rxReceivers_LEO = containers.Map();

%% Create and store LEO receiver and gimbal for each LEO GS
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
    % Point to first LEO satellite as placeholder (dynamic pointing happens during simulation)
    pointAt(leoGimbal, leoSats(1));
    % Store
    rxGimbals_LEO(gsName) = leoGimbal;
    rxReceivers_LEO(gsName) = leoRx;
end

%% Initialize data collection
fprintf('Initializing data collection...\n');
%% Initialize data collection with cross-link consideration to define the matrices size
fprintf('Starting first pass to count valid samples (with cross-links)...\n');
validSamples = 0;

% Cache access objects to avoid recomputation
leoToLeoAccess = cell(leoNum, numel(leoGsList));

for i = 1:leoNum
    for j = 1:numel(leoGsList)
        leoToLeoAccess{i,j} = access(leoSats(i), leoGsList{j});
        leoToLeoAccess{i,j}.LineColor = 'red';
        leoToLeoAccess{i,j}.LineWidth = 3;
    end
end

% First pass to count valid samples
for tIdx = 1:length(ts)
    t = ts(tIdx);
    sampleHasAccess = false;

    %% Check LEO ↔ LEO GS
    for i = 1:leoNum
        for gsIdx = 1:numel(leoGsList)
            if accessStatus(leoToLeoAccess{i, gsIdx}, t)
                fprintf('  LEO-%d to LEO GS %s at %s\n', i, leoGsList{gsIdx}.Name, datestr(t));
                sampleHasAccess = true;
                break;
            end
        end
        if sampleHasAccess, break; end
    end

    %% Count valid sample
    if sampleHasAccess
        validSamples = validSamples + 1;
    end
end
fprintf('First pass complete. Found %d valid samples with any access.\n', validSamples);

%% Pre-allocate data structures
fprintf('Pre-allocating data structures (including cross-links)...\n');
logData = struct();
logData.Time = NaT(validSamples, 1);
logData.Time.TimeZone = 'Australia/Sydney'; % Set time zone
logData.LEO = struct();

% LEO satellites
for i = 1:leoNum
    logData.LEO(i).Name = leoSats(i).Name;
    logData.LEO(i).Latitude = zeros(validSamples, 1);
    logData.LEO(i).Longitude = zeros(validSamples, 1);
    logData.LEO(i).Frequency = zeros(validSamples, 1);
    logData.LEO(i).Access = zeros(validSamples, numel(leoGsList));
    logData.LEO(i).SNR = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).RSSI = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).Thrpt = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).BER_QPSK = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).BER_MQAM = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).Latency = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).TimeOut = NaT(validSamples, numel(leoGsList));
    % Set the time zone for the entire array to Australia/Sydney
    logData.LEO(i).TimeOut.TimeZone = 'Australia/Sydney';
end

%% Simulation Loop with Selective Logging
fprintf('Starting main simulation loop...\n');
%% P07_SelectiveLogging
%% Full Simulation Loop with Logging for All Link Types
sampleCount = 0;
warning('off', 'all');
resultsDir = 'Results';
tStartIdx = 1;
%% Precompute Random Frequencies allocation and thermal noise
leoFreqMatrix = channelFreqs(randi([1 10], leoNum, length(ts)));
thermalNoise_dB = 10 * log10(kb * tempK * channelBW);
thermalNoise = kb * tempK * channelBW;
%% Start actual collection
for tIdx = tStartIdx:length(ts)
    t = ts(tIdx);
    fprintf('\nProcessing time step %d/%d: %s\n', tIdx, length(ts), char(t));
    fprintf('\nProcessing sampleCount %d \n', sampleCount);
    sampleHasAccess = false;
    accessDetails = '';
    %% Frequency allocation
    currentLEOFreqs = leoFreqMatrix(:, tIdx);
    % fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));
    %% Check and log access using cached access objects
    for i = 1:leoNum
        for gsIdx = 1:numel(leoGsList)
            if accessStatus(access(leoSats(i), leoGsList{gsIdx}), t)
                sampleHasAccess = true;
                break;
            end
        end
        if sampleHasAccess, break; end
    end
    %% Logging
    if sampleHasAccess
        sampleCount = sampleCount + 1;
        logData.Time(sampleCount) = t;
        %% LEO → LEO GS
        for i = 1:leoNum
            tx = leoTx{i}; tx.Frequency = currentLEOFreqs(i);
            [pos, ~] = states(leoSats(i), t, 'CoordinateFrame', 'geographic');
            logData.LEO(i).Latitude(sampleCount) = pos(1);
            logData.LEO(i).Longitude(sampleCount) = pos(2);
            logData.LEO(i).Frequency(sampleCount) = currentLEOFreqs(i);
            % fprintf('  LEO-%d Links (%.6f GHz):\n', i, currentLEOFreqs(i)/1e9);
            for gsIdx = 1:numel(leoGsList)
                pointAt(rxGimbals_LEO(leoGsList{gsIdx}.Name), leoSats(i));
                pointAt(leoSats(i), leoGsList{gsIdx});
                linkObj = link(tx, rxReceivers_LEO(leoGsList{gsIdx}.Name));
                acc = accessStatus(access(leoSats(i), leoGsList{gsIdx}), t);
                logData.LEO(i).Access(sampleCount, gsIdx) = acc;
                if acc
                    [~, Pwr_dBW] = sigstrength(linkObj, t); % accounts for FSPL, antenna gains, and system loss
                    [~, el, ~] = aer(rxReceivers_LEO(leoGsList{gsIdx}.Name), leoSats(i), t);
                    cfg = p618Config; cfg.Frequency = max(baseFreq, 4e9);
                    cfg.ElevationAngle = max(el, 5);
                    cfg.Latitude = leoGsList{gsIdx}.Latitude;
                    cfg.Longitude = leoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001;
                    atmosLoss = p618PropagationLosses(cfg).At; % space propagation losses,Rain, Cloud and fog, Gaseous absorption
                    fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB);
                    % fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB, el);
                    rssi = Pwr_dBW - atmosLoss - fading_dB;
                    snr = rssi - thermalNoise_dB;
                    logData.LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.LEO(i).SNR(sampleCount, gsIdx) = snr;
                    throughput = channelBW * log2(1 + 10^(snr/10)); % in bits/s
                    logData.LEO(i).Thrpt(sampleCount, gsIdx) = throughput;

                    [delay,timeOut] = latency(leoSats(i),leoGsList{gsIdx},t);

                    timeoutStr = char(timeOut);  % or: datestr(timeOut, 'yyyy-mm-dd HH:MM:SS.FFF')


                    snrLinear = 10^(snr / 10); % Convert dB to linear scale

                    % QPSK BER
                    berQPSK = qfunc(sqrt(2 * snrLinear));
                    
                    % M-QAM BER (e.g., M = 16 for 16-QAM)
                    M = 16;
                    berMQAM = (4 / log2(M)) * (1 - 1 / sqrt(M)) * qfunc(sqrt(3 * snrLinear / (M - 1)));
                    
                    % Store in logData
                    logData.LEO(i).BER_QPSK(sampleCount, gsIdx) = berQPSK;
                    logData.LEO(i).BER_MQAM(sampleCount, gsIdx) = berMQAM;


                    logData.LEO(i).Latency(sampleCount, gsIdx) = delay;
                    logData.LEO(i).TimeOut(sampleCount, gsIdx) = timeOut;

                    timeOut.TimeZone = 'Australia/Sydney'; % Set time zone


                    fprintf('    LEO-%d to %s: RSSI=%.2f dBm, SNR=%.2f dB\n', i, leoGsList{gsIdx}.Name, rssi, snr);
                    fprintf(['    LEO-%d to %s:\n' ...
                     '        RSSI = %.2f dBW\n' ...
                     '        SNR = %.2f dB\n' ...
                     '        SNR (linear) = %.4f\n' ...
                     '        Throughput = %.2f bit/s\n' ...
                     '        BER(QPSK) = %.2e\n' ...
                     '        BER(MQAM) = %.2e\n' ...
                     '        Recieve Signal Power (Pwr_dBW) = %.2f dBW\n' ...
                     '        Atmospheric Loss = %.2f dB\n' ...
                     '        fading_dB = %.2f dBW\n' ...
                     '        thermalNoise_dB = %.4f\n' ...
                     '        log2(1 + SNR) = %.4f\n' ...
                     '        1 + SNR (linear) = %.4f\n' ...
                     '        Latency = %.4f s\n' ...
                     '        Timeout = %s \n'], ...
                     i, ...
                     leoGsList{gsIdx}.Name, ...
                     rssi, ...
                     snr, ...
                     snrLinear, ...
                     throughput, ...
                     berQPSK, ...
                     berMQAM, ...
                     Pwr_dBW, ...
                     atmosLoss, ...
                     fading_dB, ...
                     thermalNoise_dB, ...
                     log2(1 + snrLinear), ...
                     1 + snrLinear,...
                     delay, ...
                     timeoutStr);

                % else
                %     fprintf('    LEO-%d to %s: No access\n', i, leoGsList{gsIdx}.Name);
                end
            end
        end
        % Save current time step log
        saveFileName = sprintf('log_step_%03d.mat', tIdx);
        save(fullfile(resultsDir, saveFileName), 'logData', 't', 'sampleCount', '-v7.3');
    end
end
fprintf('\nSimulation logging complete: %d samples logged.\n', sampleCount);

%% Save Data to CSV (only valid samples)
fprintf('\nPreparing data for CSV export...\n');
% Prepare data for CSV export
csvData = table();
csvData.Time = logData.Time;

% Add LEO data
for i = 1:leoNum
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

        % New data
        csvData.(sprintf('LEO%d_%s_Throughput', i, gsName)) = logData.LEO(i).Thrpt(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_BER_QPSK', i, gsName)) = logData.LEO(i).BER_QPSK(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_BER_MQAM', i, gsName)) = logData.LEO(i).BER_MQAM(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_Latency', i, gsName)) = logData.LEO(i).Latency(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_TimeOut', i, gsName)) = logData.LEO(i).TimeOut(:, gsIdx);
        
    end
end
% Write to CSV
fprintf('Writing data to CSV file...\n');

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
save('SatelliteSimulationState_starlink.mat', 'sc', 'logData', 'leoSats', 'leoGsList', 'leoTx');
fprintf('Simulation state saved to SatelliteSimulationState_starlink.mat\n');
%% Load Simulation State
fprintf('\nLoading simulation scenario data...\n');
load('SatelliteSimulationState_starlink.mat');
v = satelliteScenarioViewer(sc);
v.ShowDetails = true;
play(sc, 'PlaybackSpeedMultiplier', 100);
fprintf('=== Simulation Load Complete ===\n');

