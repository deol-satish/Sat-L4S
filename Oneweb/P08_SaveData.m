% Prepare data for CSV export
csvData = table();
csvData.Time = logData.Time;

% Add GEO data
for i = 1:geoNum
    fprintf('  Adding GEO-%d data to CSV structure\n', i);
    csvData.(sprintf('GEO%d_Name', i)) = repmat(logData.GEO(i).Name, validSamples, 1);
    csvData.(sprintf('GEO%d_Lat', i)) = logData.GEO(i).Latitude;
    csvData.(sprintf('GEO%d_Lon', i)) = logData.GEO(i).Longitude;
    csvData.(sprintf('GEO%d_Freq_Hz', i)) = logData.GEO(i).Frequency;
    
    for gsIdx = 1:numel(geoGsList)
        gsName = strrep(geoGsList{gsIdx}.Name, ' ', '_');
        csvData.(sprintf('GEO%d_%s_Access', i, gsName)) = logData.GEO(i).Access(:, gsIdx);
        csvData.(sprintf('GEO%d_%s_SNR_dB', i, gsName)) = logData.GEO(i).SNR(:, gsIdx);
        csvData.(sprintf('GEO%d_%s_RSSI_dBm', i, gsName)) = logData.GEO(i).RSSI(:, gsIdx);
        csvData.(sprintf('GEO%d_%s_Throughput', i, gsName))    = logData.GEO(i).Thrpt(:, gsIdx);
    end
end

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
        csvData.(sprintf('LEO%d_%s_Throughput', i, gsName))    = logData.LEO(i).Thrpt(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_BER_QPSK', i, gsName))      = logData.LEO(i).BER_QPSK(:, gsIdx);
        csvData.(sprintf('LEO%d_%s_BER_MQAM', i, gsName))      = logData.LEO(i).BER_MQAM(:, gsIdx);
    end
end
% Write to CSV
fprintf('Writing data to CSV file...\n');
