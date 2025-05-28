%% P05_GReceivers
%% Receivers on Ground Stations
fprintf('Setting up ground station receivers...\n');
fprintf('Setting up dual receivers and gimbals for each ground station...\n');

rxGimbals_LEO = containers.Map();
rxReceivers_LEO = containers.Map();

%% Create and store LEO receiver and gimbal for each LEO GS
for i = 1:numel(leoGsList)
    gs = leoGsList{i};
    gsName = gs.Name;
    % --- Gimbal and receiver for LEO GS
    leoGimbal = gimbal(gs);
    leoRx = receiver(leoGimbal, ...
        'GainToNoiseTemperatureRatio', 30, ...
        'RequiredEbNo', 10, ...
        'SystemLoss', 1.0);
    gaussianAntenna(leoRx, ...
        'DishDiameter', gsAntenna);
    % Point to first LEO satellite as placeholder (dynamic pointing happens during simulation)
    pointAt(leoGimbal, leoSats(1));
    % Store
    rxGimbals_LEO(gsName) = leoGimbal;
    rxReceivers_LEO(gsName) = leoRx;
end