%% Initialize data collection with cross-link consideration to define the matrices size
fprintf('Starting first pass to count valid samples (with cross-links)...\n');
validSamples = 0;

% Cache access objects to avoid recomputation


leoToLeoAccess = cell(numel(leoGsList));

leoToLeoAccessIntervals = cell(numel(leoGsList));


uniqueSatIDs = [];  % Initialize list to hold all satellite IDs with access

for j = 1:numel(leoGsList)
    % Create access object between all satellites and current GS
    leoToLeoAccess{j} = access(leoSats, leoGsList{j});
    fprintf('LEO GS %s\n', leoGsList{j}.Name);
    
    % Set visualization options (optional)
    leoToLeoAccess{j}.LineColor = 'red';
    leoToLeoAccess{j}.LineWidth = 3;
    
    % Get access intervals table
    leoToLeoAccessIntervals{j} = accessIntervals(leoToLeoAccess{j});
    
    % Extract 'Source' values that match pattern "_number"
    sourceNames = leoToLeoAccessIntervals{j}.Source;  % Cell array of names
    for k = 1:length(sourceNames)
        name = sourceNames{k};
        tokens = regexp(name, '_([0-9]+)$', 'tokens');  % Match trailing _number
        if ~isempty(tokens)
            satNum = str2double(tokens{1}{1});
            uniqueSatIDs(end+1) = satNum;  % Append to list
        end
    end
end

% Remove duplicates and sort
uniqueSatIDs = unique(uniqueSatIDs);

% Display result
fprintf('Unique LEO Satellite IDs with access:\n');
disp(uniqueSatIDs);





validSamples = length(ts); % Assume all samples are valid initially
fprintf('First pass complete. Found %d timesteps samples with any access.\n', length(ts));
%% Pre-allocate data structures
fprintf('Pre-allocating data structures (including cross-links)...\n');
logData = struct();
logData.Time = NaT(validSamples, 1);
logData.Time.TimeZone = 'Australia/Sydney'; % Set time zone
logData.LEO = struct();

% LEO satellites
for i = 1:leoNum
fprintf(' Processing  LEO-%d \n', i);
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
