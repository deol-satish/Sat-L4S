%% P05_GReceivers
%% Receivers on Ground Stations
fprintf('Setting up ground station receivers...\n');
fprintf('Setting up dual receivers and gimbals for each ground station...\n');

% rxGimbals_LEO = containers.Map();
% rxReceivers_LEO = containers.Map();


txGimbals_LEO = containers.Map();
txTransmitters_LEO = containers.Map();

%% Create and store LEO receiver and gimbal for each LEO GS
for i = 1:numel(leoGsList)
    gs = leoGsList{i};
    gsName = gs.Name;
    % --- Gimbal and receiver for LEO GS

    % rxleoGimbal = gimbal(gs);
    % leorx = receiver(rxleoGimbal, ...
    %     'GainToNoiseTemperatureRatio', 30, ...
    %     'RequiredEbNo', 10, ...
    %     'SystemLoss', 1.0);
    % gaussianAntenna(leorx, ...
    %     'DishDiameter', gsAntenna);
    % % Point to first LEO satellite as placeholder (dynamic pointing happens during simulation)
    % pointAt(rxleoGimbal, leoSats(1));
    % % Store
    % rxGimbals_LEO(gsName) = rxleoGimbal;
    % rxReceivers_LEO(gsName) = leorx;


    txleoGimbal = gimbal(gs);
    % Create transmitter mounted on the SAME gimbal
    leotx = transmitter(txleoGimbal, ...
        'Frequency', channelFreqs(1), ...  % uplink frequency
        'Power', 3);                % e.g., 3 W
    gaussianAntenna(leotx, ...
        'DishDiameter', gsAntenna);
    % Point to first LEO satellite as placeholder (dynamic pointing happens during simulation)
    pointAt(txleoGimbal, leoSats(1));
    % Store
    txGimbals_LEO(gsName) = txleoGimbal;
    txTransmitters_LEO(gsName) = leotx;

end