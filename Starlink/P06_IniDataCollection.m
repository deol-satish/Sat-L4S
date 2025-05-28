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
    for j = 1:numel(geoGsList)
        leoToGeoAccess{i,j} = access(leoSats(i), geoGsList{j});
        leoToGeoAccess{i,j}.LineColor = 'magenta';
        leoToGeoAccess{i,j}.LineWidth = 2;
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
end


% Time-series SNR per satellite
snrTimeline = struct();
for i = 1:leoNum
    snrTimeline.(sprintf('LEO%d', i)) = [];
    snrTimeline.(sprintf('LEO%d_XL', i)) = [];
end
snrTimeline.Time = datetime.empty;