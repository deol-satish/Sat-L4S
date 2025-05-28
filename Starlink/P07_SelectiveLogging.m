%% P07_SelectiveLogging
%% Full Simulation Loop with Logging for All Link Types
sampleCount = 2;
warning('off', 'all');
resultsDir = 'Results';
tStartIdx = 3;
%% Precompute Random Frequencies allocation and thermal noise
leoFreqMatrix = channelFreqs(randi([1 10], leoNum, length(ts)));
geoFreqMatrix = channelFreqs(randi([1 4], geoNum, length(ts)));
thermalNoise_dB = 10 * log10(kb * tempK * channelBW);
thermalNoise = kb * tempK * channelBW;
%% Start actual collection
for tIdx = tStartIdx:length(ts)
    t = ts(tIdx);
    fprintf('\nProcessing time step %d/%d: %s\n', tIdx, length(ts), char(t));
    sampleHasAccess = false;
    accessDetails = '';
    %% Frequency allocation
    currentLEOFreqs = leoFreqMatrix(:, tIdx);
    % fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));
    currentGEOFreqs = geoFreqMatrix(:, tIdx);
    % fprintf('  Selected GEO frequencies: %s MHz\n', mat2str(currentGEOFreqs/1e6));
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
    if ~sampleHasAccess
        for i = 1:geoNum
            for gsIdx = 1:numel(geoGsList)
                if accessStatus(access(geoSats{i}, geoGsList{gsIdx}), t)
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
    end
    if ~sampleHasAccess
        for i = 1:leoNum
            for gsIdx = 1:numel(geoGsList)
                if accessStatus(access(leoSats(i), geoGsList{gsIdx}), t)
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
    end
    if ~sampleHasAccess
        for i = 1:geoNum
            for gsIdx = 1:numel(leoGsList)
                if accessStatus(access(geoSats{i}, leoGsList{gsIdx}), t)
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
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
                    fprintf('    LEO-%d to %s: RSSI=%.2f dBm, SNR=%.2f dB\n', i, leoGsList{gsIdx}.Name, rssi, snr);
                % else
                %     fprintf('    LEO-%d to %s: No access\n', i, leoGsList{gsIdx}.Name);
                end
            end
        end
        %% GEO → GEO GS
        for i = 1:geoNum
            tx = geoTx{i}; tx.Frequency = currentGEOFreqs(i);
            [pos, ~] = states(geoSats{i}, t, 'CoordinateFrame', 'geographic');
            logData.GEO(i).Latitude(sampleCount) = pos(1);
            logData.GEO(i).Longitude(sampleCount) = pos(2);
            logData.GEO(i).Frequency(sampleCount) = currentGEOFreqs(i);
            % fprintf('  GEO-%d Links (%.6f GHz):\n', i, currentGEOFreqs(i)/1e9);
            for gsIdx = 1:numel(geoGsList)
                pointAt(rxGimbals_GEO(geoGsList{gsIdx}.Name), geoSats{i});
                linkObj = link(tx, rxReceivers_GEO(geoGsList{gsIdx}.Name));
                acc = accessStatus(access(geoSats{i}, geoGsList{gsIdx}), t);
                logData.GEO(i).Access(sampleCount, gsIdx) = acc;
                if acc
                    [~, Pwr_dBW] = sigstrength(linkObj, t);
                    [~, el, ~] = aer(rxReceivers_GEO(geoGsList{gsIdx}.Name), geoSats{i}, t);
                    cfg = p618Config; cfg.Frequency = max(baseFreq, 4e9);
                    cfg.ElevationAngle = max(el, 5);
                    cfg.Latitude = geoGsList{gsIdx}.Latitude;
                    cfg.Longitude = geoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001;
                    atmosLoss = p618PropagationLosses(cfg).At;
                    fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB);
                    rssi = Pwr_dBW - atmosLoss - fading_dB;
                    snr = rssi - thermalNoise_dB;
                    logData.GEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.GEO(i).SNR(sampleCount, gsIdx) = snr;
                    fprintf('    GEO-%d to %s: RSSI=%.2f dBm, SNR=%.2f dB\n', i, leoGsList{gsIdx}.Name, rssi, snr);
                % else
                %     fprintf('    GEO-%d to %s: No access\n', i, geoGsList{gsIdx}.Name);
                end
            end
        end
        %% LEO → GEO GS (Cross-link)
        for i = 1:leoNum
            tx = leoTx{i}; tx.Frequency = currentLEOFreqs(i);
            for gsIdx = 1:numel(geoGsList)
                pointAt(rxGimbals_GEO(geoGsList{gsIdx}.Name), leoSats(i));
                linkObj = link(tx, rxReceivers_GEO(geoGsList{gsIdx}.Name));
                acc = accessStatus(access(leoSats(i), geoGsList{gsIdx}), t);
                logData.Cross.LEO2GEO(i).Access(sampleCount, gsIdx) = acc;
                if acc
                    [~, Pwr_dBW] = sigstrength(linkObj, t);
                    [~, el, ~] = aer(rxReceivers_GEO(geoGsList{gsIdx}.Name), leoSats(i), t);
                    cfg = p618Config; cfg.Frequency = max(baseFreq, 4e9);
                    cfg.ElevationAngle = max(el, 5);
                    cfg.Latitude = geoGsList{gsIdx}.Latitude;
                    cfg.Longitude = geoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001;
                    atmosLoss = p618PropagationLosses(cfg).At;
                    fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB);
                    rssi = Pwr_dBW - atmosLoss - fading_dB;
                    logData.Cross.LEO2GEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.Cross.LEO2GEO(i).Frequency(sampleCount) = currentLEOFreqs(i);
                    fprintf('    LEO-%d to GEO GS %s: RSSI=%.2f dBm\n', i, geoGsList{gsIdx}.Name, rssi);
                % else
                %     fprintf('    LEO-%d to GEO GS %s: No access\n', i, geoGsList{gsIdx}.Name);
                end
            end
        end

        %% GEO → LEO GS (Cross-link)
        for i = 1:geoNum
            tx = geoTx{i}; tx.Frequency = currentGEOFreqs(i);
            for gsIdx = 1:numel(leoGsList)
                pointAt(rxGimbals_LEO(leoGsList{gsIdx}.Name), geoSats{i});
                linkObj = link(tx, rxReceivers_LEO(leoGsList{gsIdx}.Name));
                acc = accessStatus(access(geoSats{i}, leoGsList{gsIdx}), t);
                logData.Cross.GEO2LEO(i).Access(sampleCount, gsIdx) = acc;
                if acc
                    [~, Pwr_dBW] = sigstrength(linkObj, t);
                    [~, el, ~] = aer(rxReceivers_LEO(leoGsList{gsIdx}.Name), geoSats{i}, t);
                    cfg = p618Config; cfg.Frequency = max(baseFreq, 4e9);
                    cfg.ElevationAngle = max(el, 5);
                    cfg.Latitude = leoGsList{gsIdx}.Latitude;
                    cfg.Longitude = leoGsList{gsIdx}.Longitude;
                    cfg.TotalAnnualExceedance = 0.001;
                    atmosLoss = p618PropagationLosses(cfg).At;
                    fading_dB = F01_GetMultipathFadingLoss(fadingModel, ricianK_dB);
                    rssi = Pwr_dBW - atmosLoss - fading_dB;
                    logData.Cross.GEO2LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.Cross.GEO2LEO(i).Frequency(sampleCount) = currentGEOFreqs(i);
                    fprintf('    GEO-%d to LEO GS %s: RSSI=%.2f dBm\n', i, leoGsList{gsIdx}.Name, rssi);
                % else
                %     fprintf('    GEO-%d to LEO GS %s: No access\n', i, leoGsList{gsIdx}.Name);
                end
            end
        end
        %% Compute SINR using overlap factor for Cross-Links
        for i = 1:leoNum
            for gsIdx = 1:numel(geoGsList)
                rssi_dBW = logData.Cross.LEO2GEO(i).RSSI(sampleCount, gsIdx);
                if ~isnan(rssi_dBW)
                    signalPwr_W = exp(rssi_dBW * log(10) / 10);
                    intfPower_W = 0;
                    for j = 1:leoNum
                        if j == i, continue; end
                        intfFreq = logData.LEO(j).Frequency(sampleCount);
                        overlap = F02_GetOverlapFactor(logData.Cross.LEO2GEO(i).Frequency(sampleCount), channelBW, intfFreq, channelBW);
                        intf_dBW = logData.LEO(j).RSSI(sampleCount, gsIdx);
                        if overlap > 0 && ~isnan(intf_dBW)
                            intfPower_W = intfPower_W + 10^(intf_dBW/10) * overlap;
                        end
                    end
                    SINR_dB = 10 * log10(signalPwr_W / (thermalNoise + intfPower_W));
                    logData.Cross.LEO2GEO(i).SINR(sampleCount, gsIdx) = SINR_dB;
                    fprintf('    LEO-%d to GEO GS %s: RSSI=%.2f dBm, SINR=%.2f dB\n', i, geoGsList{gsIdx}.Name, SINR_dB);
                end
            end
        end

        for i = 1:geoNum
            for gsIdx = 1:numel(leoGsList)
                rssi_dBW = logData.Cross.GEO2LEO(i).RSSI(sampleCount, gsIdx);
                if ~isnan(rssi_dBW)
                    signalPwr_W = exp(rssi_dBW * log(10) / 10);
                    intfPower_W = 0;
                    for j = 1:geoNum
                        if j == i, continue; end
                        intfFreq = logData.GEO(j).Frequency(sampleCount);
                        overlap = F02_GetOverlapFactor(logData.Cross.GEO2LEO(i).Frequency(sampleCount), channelBW, intfFreq, channelBW);
                        intf_dBW = logData.GEO(j).RSSI(sampleCount, gsIdx);
                        if overlap > 0 && ~isnan(intf_dBW)
                            intfPower_W = intfPower_W + 10^(intf_dBW/10) * overlap;
                        end
                    end
                    SINR_dB = 10 * log10(signalPwr_W / (thermalNoise + intfPower_W));
                    logData.Cross.GEO2LEO(i).SINR(sampleCount, gsIdx) = SINR_dB;
                    fprintf('    GEO-%d to LEO GS %s: RSSI=%.2f dBm, SINR=%.2f dB\n', i, leoGsList{gsIdx}.Name, SINR_dB);
                end
            end
        end
        % Save current time step log
        saveFileName = sprintf('log_step_%03d.mat', tIdx);
        save(fullfile(resultsDir, saveFileName), 'logData', 't', 'sampleCount', '-v7.3');
    end
end
fprintf('\nSimulation logging complete: %d samples logged.\n', sampleCount);
