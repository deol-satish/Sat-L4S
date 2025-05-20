%% Create GEO Satellites
fprintf('Creating GEO satellites...\n');
geoSats = [];
geoTx = cell(1, geoNum);
geoTxGimbals = cell(1, geoNum); % Gimbals (used for directional antennas to track ground stations)
for i = 1:geoNum
    fprintf('  Creating GEO satellite %d at %d°E longitude\n', i, geoLongitudes(i));
    geoSats{i} = satellite(sc, sma_geo, 0, 0, 0, 0, geoLongitudes(i), ...
        'Name', sprintf('GEO-%d', i), 'OrbitPropagator', 'two-body-keplerian');
    geoSats{i}.MarkerColor = [0.9290 0.6940 0.1250];  % Orange
    
    % Add gimbal for pointing at ground stations
    geoTxGimbals{i} = gimbal(geoSats{i});
    
    % Create transmitter mounted on gimbal
    tx = transmitter(geoTxGimbals{i}, 'Frequency', baseFreq, 'Power', geoPower, 'SystemLoss', 1.0);
    gaussianAntenna(tx, 'DishDiameter', geoAntenna);
    geoTx{i} = tx;

    % Point gimbal at all GS (for now, point at 1st GS)
    % pointAt(geoTxGimbals{i}, geoGsList{i});
end
%% Create LEO Satellites (Walker-Delta Constellation)
% fprintf('Creating LEO Walker-Delta constellation...\n');



% % Create the LEO constellation using walkerDelta
% leoSats = walkerDelta(sc, ...
%     walker.a, ...
%     walker.Inc, ...
%     walker.SatsPerPlane * walker.NPlanes, ...
%     walker.NPlanes, ...
%     walker.PhaseOffset, ...
%     'Name', " ", ...
%     'OrbitPropagator', 'two-body-keplerian');

% Use Walker Star configuration (Phase offset = 0)
fprintf('Creating LEO Walker-Star constellation...\n');
leoSats = walkerStar(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 0);
set(leoSats, 'ShowLabel', true);

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
