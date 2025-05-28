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
    'Name', "", ...
    'OrbitPropagator', 'two-body-keplerian');

% leoTx = cell(1, leoNum);
leoRx = cell(1, leoNum);  % Updated variable to represent receivers

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
    
    % % Add transmitter
    % tx = transmitter(leoSats(i), ...
    %     'Frequency', channelFreqs(1), ...
    %     'Power', leoPower);
    % gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    % leoTx{i} = tx;

    % Add receiver with Starlink-like values
    rx = receiver(leoSats(i), ...
        'GainToNoiseTemperatureRatio', 30, ...  % in dB/K
        'RequiredEbNo', 10, ...                 % in dB
        'SystemLoss', 1.5);                     % approx. 1.76 dB
    gaussianAntenna(rx, 'DishDiameter', leoAntenna);
    leoRx{i} = rx;


end
