%% Initialize data collection with cross-link consideration to define the matrices size
fprintf('Starting first pass to count valid samples (with cross-links)...\n');
validSamples = 0;

% Cache access objects to avoid recomputation
leoToLeoAccess = cell(leoNum, numel(leoGsList));
geoToGeoAccess = cell(geoNum, numel(geoGsList));
leoToGeoAccess = cell(leoNum, numel(geoGsList));
geoToLeoAccess = cell(geoNum, numel(leoGsList));

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

for i = 1:geoNum
    for j = 1:numel(geoGsList)
        geoToGeoAccess{i,j} = access(geoSats{i}, geoGsList{j});
        geoToGeoAccess{i,j}.LineColor = 'blue';
        geoToGeoAccess{i,j}.LineWidth = 3;
    end
    for j = 1:numel(leoGsList)
        geoToLeoAccess{i,j} = access(geoSats{i}, leoGsList{j});
        geoToLeoAccess{i,j}.LineColor = 'cyan';
        geoToLeoAccess{i,j}.LineWidth = 2;
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

    %% Check GEO ↔ GEO GS
    if ~sampleHasAccess
        for i = 1:geoNum
            for gsIdx = 1:numel(geoGsList)
                if accessStatus(geoToGeoAccess{i, gsIdx}, t)
                    fprintf('  GEO-%d to GEO GS %s at %s\n', i, geoGsList{gsIdx}.Name, datestr(t));
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
    end

    %% Check LEO ↔ GEO GS (Cross-Link)
    if ~sampleHasAccess
        for i = 1:leoNum
            for gsIdx = 1:numel(geoGsList)
                if accessStatus(leoToGeoAccess{i, gsIdx}, t)
                    fprintf('  CROSS: LEO-%d to GEO GS %s at %s\n', i, geoGsList{gsIdx}.Name, datestr(t));
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
    end

    %% Check GEO ↔ LEO GS (Cross-Link)
    if ~sampleHasAccess
        for i = 1:geoNum
            for gsIdx = 1:numel(leoGsList)
                if accessStatus(geoToLeoAccess{i, gsIdx}, t)
                    fprintf('  CROSS: GEO-%d to LEO GS %s at %s\n', i, leoGsList{gsIdx}.Name, datestr(t));
                    sampleHasAccess = true;
                    break;
                end
            end
            if sampleHasAccess, break; end
        end
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
logData.GEO = struct();
logData.LEO = struct();
logData.Cross = struct();

% GEO satellites
for i = 1:geoNum
    logData.GEO(i).Name = geoSats{i}.Name;
    logData.GEO(i).Latitude = zeros(validSamples, 1);
    logData.GEO(i).Longitude = zeros(validSamples, 1);
    logData.GEO(i).Frequency = baseFreq * ones(validSamples, 1);
    logData.GEO(i).Access = zeros(validSamples, numel(geoGsList));
    logData.GEO(i).SNR = NaN(validSamples, numel(geoGsList));
    logData.GEO(i).RSSI = NaN(validSamples, numel(geoGsList));
end

% LEO satellites
for i = 1:leoNum
    logData.LEO(i).Name = leoSats(i).Name;
    logData.LEO(i).Latitude = zeros(validSamples, 1);
    logData.LEO(i).Longitude = zeros(validSamples, 1);
    logData.LEO(i).Frequency = zeros(validSamples, 1);
    logData.LEO(i).Access = zeros(validSamples, numel(leoGsList));
    logData.LEO(i).SNR = NaN(validSamples, numel(leoGsList));
    logData.LEO(i).RSSI = NaN(validSamples, numel(leoGsList));
end

% Cross-links: LEO → GEO GS
for i = 1:leoNum
    logData.Cross.LEO2GEO(i).Name = leoSats(i).Name;
    logData.Cross.LEO2GEO(i).Access = zeros(validSamples, numel(geoGsList));
    logData.Cross.LEO2GEO(i).SINR = NaN(validSamples, numel(geoGsList));
    logData.Cross.LEO2GEO(i).RSSI = NaN(validSamples, numel(geoGsList));
    logData.Cross.LEO2GEO(i).Frequency = zeros(validSamples, 1);
end

% Cross-links: GEO → LEO GS
for i = 1:geoNum
    logData.Cross.GEO2LEO(i).Name = geoSats{i}.Name;
    logData.Cross.GEO2LEO(i).Access = zeros(validSamples, numel(leoGsList));
    logData.Cross.GEO2LEO(i).SINR = NaN(validSamples, numel(leoGsList));
    logData.Cross.GEO2LEO(i).RSSI = NaN(validSamples, numel(leoGsList));
    logData.Cross.GEO2LEO(i).Frequency = zeros(validSamples, 1);
end

% Time-series SNR per satellite
snrTimeline = struct();
for i = 1:leoNum
    snrTimeline.(sprintf('LEO%d', i)) = [];
    snrTimeline.(sprintf('LEO%d_XL', i)) = [];
end
for i = 1:geoNum
    snrTimeline.(sprintf('GEO%d', i)) = [];
    snrTimeline.(sprintf('GEO%d_XL', i)) = [];
end
snrTimeline.Time = datetime.empty;