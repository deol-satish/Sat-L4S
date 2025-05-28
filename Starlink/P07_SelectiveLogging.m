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

                    snrLinear = 10^(snr / 10); % Convert dB to linear scale

                    % QPSK BER
                    berQPSK = qfunc(sqrt(2 * snrLinear));
                    
                    % M-QAM BER (e.g., M = 16 for 16-QAM)
                    M = 16;
                    berMQAM = (4 / log2(M)) * (1 - 1 / sqrt(M)) * qfunc(sqrt(3 * snrLinear / (M - 1)));
                    
                    % Store in logData
                    logData.LEO(i).BER_QPSK(sampleCount, gsIdx) = berQPSK;
                    logData.LEO(i).BER_MQAM(sampleCount, gsIdx) = berMQAM;


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
                     '        1 + SNR (linear) = %.4f\n'], ...
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
                     1 + snrLinear);

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
