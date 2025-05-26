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
duration_sec = 60 *5;                   % 30 min simulation in seconds
sampleTime = 60;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);
%% Frequencies (Hz)
baseFreq = 1.5e9;          % Base frequency in Hz
% channelBW = 200e3;         % Channel bandwidth in Hz
% channelFreqs = 1e9 * [...
%     1.498875, 1.500125, 1.500375, 1.500625, 1.500875, ...
%     1.501125, 1.501375, 1.501625, 1.501875, 1.502125];  % 10 narrow channels


% In particular, the 10.7-12.7 and 12.75-
% 14.5 GHz band will be used for the downlink and uplink
% user communications respectively
% From, A Technical Comparison of Three Low Earth Orbit Satellite 
% Constellation Systems to Provide Global
% Broadband

%% For DownLink
channelBW = 250e6;  % Each channel 250 MHz wide, typical in Ku-band
% Start from 10.7 GHz and space them evenly
channelFreqs = 1e9 * (10.7 : 0.2 : 12.5);  % 10 channels in Ku downlink band

% %% For Uplink
% channelBW = 250e6;  % 250 MHz
% channelFreqs = 1e9 * (14.0 : 0.05 : 14.45);  % 10 channels across uplink



% Uncomment for interference testing (same frequency reuse)
% channelFreqs = 1.5e9 * ones(1,10);
%% Transmit Power (in dBW)
geoPower = 10 * log10(300);  % GEO Tx power: 300 W → ~24.77 dBW
leoPower = 10 * log10(20);   % LEO Tx power: 20 W → ~13.01 dBW
%% Antenna Parameters (Dish Diameter in meters)
leoAntenna = 0.5;     % LEO satellite antenna diameter
geoAntenna = 3.0;     % GEO satellite antenna diameter
gsAntenna = 2.4;      % Ground station antenna diameter
%% Multi-path Fading Parameters
fadingModel = 'Rician';    % Options: 'None', 'Rayleigh', 'Rician'
ricianK_dB = 10;           % Rician K-factor in dB (K=10: strong LoS)
%% Physical Constants
EarthRadius = earthRadius;        % Use MATLAB Aerospace Toolbox Earth radius [m]
kb = physconst('Boltzmann');      % Boltzmann constant [J/K]
tempK = 293;                      % System noise temperature [K]
%% LEO Walker-Delta Constellation Parameters
walker.a = 650e3 + EarthRadius;     % Semi-major axis: 650 km altitude
walker.Inc = 87.9;                  % Inclination in degrees (typical for OneWeb)
walker.NPlanes = 18;               % Number of orbital planes (original 18)
walker.SatsPerPlane = 20;          % Number of satellites per plane (original 49)
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;
%% GEO Satellite Parameters
geoNum = 1;                                  % Number of GEO satellites (adjust as needed)
geoLongitudes = [150, 160, 170];             % GEO longitudes [deg E]
sma_geo = 35786e3 + EarthRadius;             % GEO semi-major axis [m] (altitude + radius)

%% LEO Walker-Star
%% === Parameters
% E = wgs84Ellipsoid;
Re = 6371000;  % Earths mean radius in meters

Param.h = 1200e3;  % OneWeb altitude ~1200 km
Elem.a = Re + Param.h;
Elem.Inc = 87.9;   % Near-polar inclination
Param.NPln = 18;   % Number of orbital planes
Param.NSat = 40;    % Satellites per plane
Param.TNSats = Param.NPln * Param.NSat;
Param.sampleTime = 60; % second sampling time

leoNum = Param.NPln * Param.NSat;

% Temp assignment for Dev
Param.NPln = 18;
Param.NSat = 40;




% Save all relevant parameters into a .mat file
save('simulation_parameters.mat', ...
    'maps', 'p836', 'p837', 'p840', ...
    'startTime', 'duration_sec', 'sampleTime', 'stopTime', ...
    'baseFreq', 'channelBW', 'channelFreqs', ...
    'geoPower', 'leoPower', ...
    'leoAntenna', 'geoAntenna', 'gsAntenna', ...
    'fadingModel', 'ricianK_dB', ...
    'EarthRadius', 'kb', 'tempK', ...
    'walker', 'leoNum', ...
    'geoNum', 'geoLongitudes', 'sma_geo', ...
    'Re', 'Param', 'Elem');


