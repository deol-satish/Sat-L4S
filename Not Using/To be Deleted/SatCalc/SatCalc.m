% Create LEO satellite
% Define simulation start and stop times
startTime = datetime('2025-05-09 12:00:00');
stopTime = startTime + minutes(10);

% Create satellite scenario
sc = satelliteScenario(startTime, stopTime, 60); % 60s sample interval

% Use correct semi-major axis for 550 km orbit
altitude = 550e3;              % Altitude in meters
earthRadius = 6371e3;          % Earth radius in meters
sma = earthRadius + altitude;  % Semi-major axis

% [sma, eccentricity, inclination, RAAN, argumentOfPerigee, trueAnomaly]
sat = satellite(sc, sma, 0, 53, 0, 0, 0);  % circular orbit (eccentricity = 0)


% Ground station
gs = groundStation(sc, 37.7749, -122.4194);

% Visualize pass
% access = access(sat, gs);

% Assume Ku-band downlink at 14 GHz
freq = 14e9; % Hz
bw = 20e6;   % 20 MHz bandwidth

% EIRP (Effective Isotropic Radiated Power)
eirp = 50; % dBW (approx from satellite power and antenna gain)

% G/T (Gain-to-noise-temperature) of user terminal
gt = 20; % dB/K

% Link margin using link budget equation
linkMargin = eirp + gt - 10*log10(bw) - 228.6;  % in dB


% Traffic source
packetRate = 1000;   % packets/sec
packetSize = 1500*8; % bits

% Link capacity estimation (based on Shannon or SNR)
snr = 10^(linkMargin/10);
capacity = bw * log2(1 + snr);  % in bps

% Throughput
throughput = min(capacity, packetRate * packetSize);  % bits/sec

% Queue delay (Little’s Law)
lambda = packetRate;
mu = capacity / packetSize;
utilization = lambda / mu;

if utilization < 1
    avgQueueDelay = 1 / (mu - lambda);  % seconds
else
    avgQueueDelay = Inf;  % system is unstable
end

% Packet loss rate (assume buffer size B)
bufferSize = 100;  % packets
if utilization >= 1
    lossRate = 1; % all packets lost
else
    lossRate = utilization^bufferSize;  % approximation
end
