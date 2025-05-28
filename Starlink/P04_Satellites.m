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
    'Name', " ", ...
    'OrbitPropagator', 'two-body-keplerian');

leoTx = cell(1, leoNum);

% % Turn off default labels
% for i = 1:leoNum
%     leoSats(i).ShowLabel = false;
% end

% Configure each satellite: assign name mapping and transmitter
for i = 1:leoNum
    % Set marker color
    leoSats(i).MarkerColor = [0.3010 0.7450 0.9330];  % Light Blue
    
    % Add transmitter
    tx = transmitter(leoSats(i), ...
        'Frequency', channelFreqs(1), ...
        'Power', leoPower);
    gaussianAntenna(tx, 'DishDiameter', leoAntenna);
    leoTx{i} = tx;
end
