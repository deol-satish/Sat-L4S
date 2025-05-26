%% Full Simulation Loop with Logging for All Link Types
sampleCount = 0;
warning('off', 'all');

% Save to a MAT file
save('save_bw_channels.mat', 'channelBW', 'channelFreqs');
for tIdx = 1:length(ts)
    t = ts(tIdx);
    fprintf('\nProcessing time step %d/%d: %s\n', tIdx, length(ts), char(t));
    sampleHasAccess = false;
    accessDetails = '';
    %% Frequency allocation
    currentLEOFreqs = channelFreqs(randi([1 10], 1, leoNum));
    fprintf('  Selected LEO frequencies: %s MHz\n', mat2str(currentLEOFreqs/1e6));
    currentGEOFreqs = channelFreqs(randi([1 10], 1, geoNum));
    fprintf('  Selected GEO frequencies: %s MHz\n', mat2str(currentGEOFreqs/1e6));
    %% Check and log access
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
            fprintf('  LEO-%d Links (%.6f GHz):\n', i, currentLEOFreqs(i)/1e9);
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
                    atmosLoss = p618PropagationLosses(cfg).At;
                    rssi = Pwr_dBW - atmosLoss; % in dbW
                    snr = rssi - 10*log10(kb*tempK*channelBW); % in dbW
                    logData.LEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.LEO(i).SNR(sampleCount, gsIdx) = snr;
                    throughput = channelBW * log2(1 + 10^(snr/10)); % in bits/s
                    logData.LEO(i).Thrpt(sampleCount, gsIdx) = throughput;

                    snrLinear = 10^(snr / 10); % Convert dB to linear scale

                    % QPSK BER
                    berQPSK = qfunc(sqrt(2 * snrLinear));
                    
                    % M-QAM BER (e.g., M = 16 for 16-QAM)
                    M = 16;
                    berMQAM = (4 / log2(M)) * (1 - 1 / sqrt(M)) * qfunc(sqrt(3 * snrLinear / (M - 1)));
                    
                    % Store in logData
                    logData.LEO(i).BER_QPSK(sampleCount, gsIdx) = berQPSK;
                    logData.LEO(i).BER_MQAM(sampleCount, gsIdx) = berMQAM;


                    fprintf('    LEO-%d to %s: RSSI=%.2f dBm, SNR=%.2f dB, Throughput=%.2f bit/s, BER(QPSK)=%.2e, BER(MQAM)=%.2e\n', ...
                        i, leoGsList{gsIdx}.Name, rssi, snr, (throughput), berQPSK, berMQAM);

                else
                    fprintf('    LEO-%d to %s: No access\n', i, leoGsList{gsIdx}.Name);
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
            fprintf('  GEO-%d Links (%.6f GHz):\n', i, currentGEOFreqs(i)/1e9);
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
                    rssi = Pwr_dBW - atmosLoss;
                    snr = rssi - 10*log10(kb*tempK*channelBW);
                    logData.GEO(i).RSSI(sampleCount, gsIdx) = rssi;
                    logData.GEO(i).SNR(sampleCount, gsIdx) = snr;
                    logData.GEO(i).Thrpt(sampleCount, gsIdx) = throughput;
                    fprintf('    GEO-%d to %s: RSSI=%.2f dBm, SNR=%.2f dB, Throughput=%.2f bit/s\n', i, geoGsList{gsIdx}.Name, rssi, snr, (throughput));
                else
                    fprintf('    GEO-%d to %s: No access\n', i, geoGsList{gsIdx}.Name);
                end
            end
        end
    end
end

fprintf('\nSimulation logging complete: %d samples logged.\n', sampleCount);

% function overlapFactor = getOverlapFactor(txFreq, txBW, intfFreq, intfBW)
%     txRange = [txFreq - txBW/2, txFreq + txBW/2];
%     intfRange = [intfFreq - intfBW/2, intfFreq + intfBW/2];
%     overlap = max(0, min(txRange(2), intfRange(2)) - max(txRange(1), intfRange(1)));
%     overlapFactor = overlap / intfBW;
% end
