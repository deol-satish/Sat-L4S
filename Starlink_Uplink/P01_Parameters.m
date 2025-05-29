%% P01_Parameters
%% Earth-Space Propagation Losses from ITU documents
maps = exist('maps.mat','file');
p836 = exist('p836.mat','file');
p837 = exist('p837.mat','file');
p840 = exist('p840.mat','file');
matFiles = [maps p836 p837 p840];
if ~all(matFiles)
    if ~exist('ITURDigitalMaps.tar.gz','file')
        url = 'https://www.mathworks.com/supportfiles/spc/P618/ITURDigitalMaps.tar.gz';
        websave('ITURDigitalMaps.tar.gz', url);
        untar('ITURDigitalMaps.tar.gz');
    else
        untar('ITURDigitalMaps.tar.gz');
    end
    addpath(cd);  % Add current directory (assumed to have required .mat files) to path
end
%% General Simulation Parameters
fprintf('Initializing simulation parameters...\n');
startTime = datetime(2025, 4, 10, 12, 0, 0);  % Simulation start
startTime = datetime(2025, 4, 10, 12, 0, 0, 'TimeZone', 'Australia/Sydney');  % Start time in Sydney local time
duration_sec = 60 * 30;                   % 30 min simulation in seconds
sampleTime = 30;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);
ts = startTime:seconds(sampleTime):stopTime;
%% Frequencies (Hz)


% In particular, the 10.7-12.7 and 14.0- 14.5 GHz band will be used for the user downlink and uplink communications
% user communications respectively
% From, A Technical Comparison of Three Low Earth Orbit Satellite 
% Constellation Systems to Provide Global
% Broadband


% baseFreq = 11.7e9;          % Base frequency in Hz

% %% For DownLink
% channelBW = 250e6;  % Each channel 250 MHz wide, typical in Ku-band
% % Start from 10.7 GHz and space them evenly
% channelFreqs = 1e9 * (10.7 : 0.2 : 12.7);  % 10 channels in Ku downlink band

%% For Uplink
baseFreq = 14.3e9;          % Base frequency in Hz
channelBW = 150e6;  % 150 MHz
channelFreqs = 1e9 * (14.0 : 0.05 : 14.5);  % 10 channels across uplink

%% Transmit Power (in dBW)
leoPower = 10 * log10(3);   % LEO Tx power: 3 W →  dBW
%% Antenna Parameters (Dish Diameter in meters)
leoAntenna = 0.5;     % LEO satellite antenna diameter
gsAntenna = 2.4;      % Ground station antenna diameter

leoGain = 38;  % in dBi, typical for small phased-array receivers at Ku-band

leoGain = 30;  % in dBi, typical for small phased-array receivers at Ku-band


%% Multi-path Fading Parameters
fadingModel = 'Rician';    % Options: 'None', 'Rayleigh', 'Rician'
ricianK_dB = 10;           % Rician K-factor in dB (K=10: strong LoS)
%% Physical Constants
EarthRadius = earthRadius;        % Use MATLAB Aerospace Toolbox Earth radius [m]
kb = physconst('Boltzmann');      % Boltzmann constant [J/K]
tempK = 293;                      % System noise temperature [K]
%% LEO Walker-Delta Constellation Parameters
walker.a = 547e3 + EarthRadius;     % Semi-major axis: 650 km altitude
walker.Inc = 53;                  % Inclination in degrees (typical for Starlink)
walker.NPlanes = 72;               % Number of orbital planes (original 18)
walker.SatsPerPlane = 22;          % Number of satellites per plane (original 49)
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;
