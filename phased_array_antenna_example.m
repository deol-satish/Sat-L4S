%% === Satellite Scenario
sc = satelliteScenario(startTime, stopTime, Param.sampleTime);

% Create a Walker Star constellation
sats = walkerStar(sc, Elem.a, Elem.Inc, Param.TNSats, Param.NPln, 0);
set(sats, 'ShowLabel', true);

% Loop through each satellite to add a phased array antenna
for i = 1:length(sats)
    % Define a phased array antenna object (example: 8x8 uniform rectangular array)
    antennaArray = phased.URA('Size', [8 8], 'ElementSpacing', [0.5 0.5]);
    
    % Create a satellite antenna with the phased array
    % You can also use "customAntenna" or "arrayAntenna" depending on MATLAB version
    satAntenna = satelliteAntenna(sats(i), 'Antenna', antennaArray, ...
        'MountingLocation', [0 0 0], ...
        'MountingAngles', [0 0 0]);

    % Optional: define tracking behavior
    % For example, track a ground station (targetObj)
    % pointAt(satAntenna, targetObj);
end
