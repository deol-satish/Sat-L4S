%% Main Script to define the Geometrical simulator, Receivers, and Interference
clear; clc;close all hidden
%% Define Parameters and Ground stations
%% P01_Parameters
%% Physical Constants
c = physconst('LightSpeed');
kb = physconst('Boltzmann');      % Boltzmann constant [J/K]
TempK = 293;                      % System noise temperature [K]
%% General Simulation Parameters
fprintf('Initializing simulation parameters and GS locations...\n');
startTime = datetime(2025, 4, 10, 12, 0, 0);  % Simulation start
duration_sec = 0.5 * 3600;                   % 30 min simulation in seconds
sampleTime = 60;                             % Time step in seconds
stopTime = startTime + seconds(duration_sec);
ts = startTime:seconds(sampleTime):stopTime;
%% Frequencies (Hz)
fc = 11.5e9;                       % Base frequency in Ku-band (10.7-12.7 GHz)
ChannelBW = 250e6;                 % Channel bandwidth of 250 MHz
%% LEO Walker-Star Constellation Parameters
walker.a = 1200e3 + earthRadius;   % Semi-major axis: 650 km altitude
walker.Inc = 87;                   % Inclination in degrees (typical for OneWeb)
walker.NPlanes = 12;               % Number of orbital planes (original 12)
walker.SatsPerPlane = 49;          % Number of satellites per plane (original 49)
walker.PhaseOffset = 1;            % Phase offset for phasing between planes
leoNum = walker.NPlanes * walker.SatsPerPlane;
%% GEO Satellite Parameters
geoNum = 1;                        % Number of GEO satellites (adjust as needed)
geoLong = [150, 160, 170];         % GEO longitudes [deg E]
geo.a = 35786e3 + earthRadius;     % Semi-major axis
geo.e = 0;                         % Eccentrivcity for circular orbit
geo.Inc = 0;                       % Inclination in degrees for Equatorial plane
geo.omega = 0;                     % Argument of periapsis
geo.mu = 0;                        % True anamoly
%% Transmit Power (in dBW)
geoPower = 10 * log10(300e3);    % GEO Tx power: 300 W → ~24.77 dBW
leoPower = 10 * log10(5e3);      % LEO Tx power: 5 W → ~36.98 dBm
%% Antenna Parameters (Dish Diameter in meters)
leoAntenna = 0.6;     % LEO satellite antenna diameter
geoAntenna = 3.0;     % GEO satellite antenna diameter
gsAntenna = 0.6;      % Ground station antenna diameter
eff = 0.5;            % Antenna efficiency
%% Atmospheric Loss Parameters
Att.H = 2.0;            % Effective atmosphere thickness [km] (ITU‐R’s rule of thumb)
Att.M = 0.25;           % liquid‐water density [g/m³]
Att.k_l = 0.08;         % From ITU-R P.840 tables k_l(11.5 GHz) ≈ 0.08 [dB/km/(g/m³)]
Att.Hcloud = 1.0;       % Cloud layer thickness H_cloud [km] e.g. 1 km of liquid water layer
Att.R = 5;              % Choose rain rate R [mm/h], moderate rain
Att.k_r   = 0.075;      % approx. from tables
Att.alpha = 1.16;       % approx. from tables
% Rain‐height above sea level:
Att.h_R = 5.0;  % [km], typical tropical/temperate storm height  
Att.h_s = 0.0;  % [km], ground‐station altitude (sea level = 0)
%% Multi-path Fading Parameters
FadingModel = 'Rician';    % Options: 'None', 'Rayleigh', 'Rician'
% RicianKdB = 10;           % Rician K-factor in dB (K=10: strong LoS)




%% P02_GStations
% Ground Stations in Australia
GsLocations = {
    'Sydney',       -33.8688, 151.2093;
    'Melbourne',    -37.8136, 144.9631;
    'Brisbane',     -27.4698, 153.0251;
    'Perth',        -31.9505, 115.8605;
    'Adelaide',     -34.9285, 138.6007;
    'Hobart',       -42.8821, 147.3272;
    'Darwin',       -12.4634, 130.8456;
    'Canberra',     -35.2809, 149.1300;
    'Cairns',       -16.9203, 145.7710;
    'Gold_Coast',   -28.0167, 153.4000;
    'Newcastle',    -32.9283, 151.7817;
    'Geelong',      -38.1499, 144.3617;
    'Sunshine_Coast', -26.6500, 153.0667;
    'Mandurah',     -32.5366, 115.7447;
    'Victor_Harbor', -35.5500, 138.6167;
    'Launceston',   -41.4333, 147.1667;
    'Katherine',    -14.4667, 132.2667;
    'Wollongong',   -34.4244, 150.8939;
    'Townsville',   -19.2500, 146.8167;
    'Toowoomba',    -27.5667, 151.9500};

NumGeoUser = size(GsLocations,1)/2; %  10 uesers each with seperate channel (10 Channels)
NumLeoUser = size(GsLocations,1)/2; %  10 uesers each with seperate channel (10 Channels)
NumGS = NumLeoUser + NumGeoUser;        % total ground stations
GSLEOFilter = logical([ones(NumGeoUser,1); zeros(NumLeoUser,1) ]);
GSGEOFilter = logical([zeros(NumGeoUser,1); ones(NumLeoUser,1) ]);

%% Create Scenario
fprintf('Creating satellite scenario...\n');
sc = satelliteScenario(startTime, stopTime, sampleTime);
%% Satellite and GS creation

%% P03_GeometricSimulatoion
%% Create the LEO constellation using walkerStar
fprintf('Creating LEO Walker-Star constellation...\n');
leoSats = walkerStar(sc, ...
    walker.a, ...
    walker.Inc, ...
    walker.SatsPerPlane * walker.NPlanes, ...
    walker.NPlanes, ...
    walker.PhaseOffset, ...
    'Name', " ", ...
    'OrbitPropagator', 'two-body-keplerian');
%% Create the GEO satellite
% Optional: Find refernce lla at the start time to use refernce longitude on the generation
% RefPosition = eci2lla([earthRadius,0,0],datevec(startTime));
% lonRef = RefPosition(2);
% geo.RAAN = -lonRef + geoLong;    % RAAN based on Reference lon otherwise
for i = 1:geoNum
    fprintf('  Creating GEO satellite %d at %d°E longitude\n', i, geoLong(i));
    geoSats{i} = satellite(sc, geo.a, geo.e, geo.Inc, geo.omega, geo.mu, geoLong(i), ...
        'Name', sprintf('GEO-%d', i), 'OrbitPropagator', 'two-body-keplerian');
    geoSats{i}.MarkerColor = [0.9290 0.6940 0.1250];  % Orange
end
%% Create ground stations
fprintf('Setting up ground stations in Australia...\n');
for i = 1:size(GsLocations,1)
    GS{i} = groundStation(sc, GsLocations{i,2}, GsLocations{i,3}, 'Name', GsLocations{i,1});
end
%% Find elevatin and range for LEO
for i= 1:length(GS)
    [~,ElLEO(i,:,:), RhoLEO(i,:,:)] = aer(GS{i},leoSats);
    % disp (i)
end
%% Find elevatin and range for GEO
for i= 1:length(GS)
    [~,ElGEO(i,:,:), RhoGEO(i,:,:)] = aer(GS{i},geoSats{1});
    % disp (i)
end


% play(sc,PlaybackSpeedMultiplier=100);
% save('Geometric',"gsAntenna","fc","c","leoAntenna","ElLEO","RhoLEO","eff", ...
%     "geoAntenna","ElGEO", "RhoGEO", "NumLeoUser", "NumGeoUser", "ts", "GS", ...
%     "leoNum", "geoNum", "GSLEOFilter", "GSGEOFilter", "leoPower", "geoPower");
%% Power Simulation
% clear; clc;close all hidden
% load("Geometric")

%% P04_RxSimulation
%% Reciever Gain
Grx = 10* log10((pi * gsAntenna *fc /c)^2 * eff);
ThermalNoisedBm = 10 * log10(kb * TempK * ChannelBW) +30; % Noise in dBm
%% LEO Power calculations
GtxLEO = 10* log10((pi * leoAntenna *fc /c)^2 * eff);
RhoLEO(ElLEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoLEO) -147.55;
AtmoLLEO = F01_ComputeAtmosphericLoss(fc, ElLEO, Att);
FadingLEO = F02_MultipathFadingLoss(FadingModel, ElLEO);
PrxLEO = leoPower + GtxLEO + Grx - PathLoss - AtmoLLEO - FadingLEO;
% PrxLEO = leoPower + GtxLEO + Grx - PathLoss;
SNRLEO = PrxLEO - ThermalNoisedBm;
%% GEO Power calculations
GtxGEO = 10* log10((pi * geoAntenna *fc /c)^2 * eff);
RhoGEO(ElGEO<0) = Inf;
PathLoss = 20*log10(fc) + 20*log10(RhoGEO) -147.55;
AtmoLGEO = F01_ComputeAtmosphericLoss(fc, ElGEO , Att);
FadingGEO = F02_MultipathFadingLoss(FadingModel, ElGEO);
PrxGEO = geoPower + GtxGEO + Grx - PathLoss - AtmoLGEO - FadingGEO;
% PrxGEO = geoPower + GtxGEO + Grx - PathLoss;
SNRGEO = PrxGEO - ThermalNoisedBm;


% save('Power',"PrxLEO","PrxGEO");
%% Channel allocation and Serving satellites
% clear; clc;close all hidden
% load("Geometric")
% load('Power');

%% Define which is RFI based on channel allocation
fprintf('Channel allocation...\n');
% Define number of channels based of number of LEO and GEO users + 5 extra
% Each GEO users will always have its own channel
% LEO users will always share all channel randemoly assigned with unique channels per timestep
numChannels = 5 + NumLeoUser + NumGeoUser;
ChannelListLeo = nan(NumGS, leoNum, length(ts));
ChannelListGeo = nan(NumGS, geoNum, length(ts));
LEOUsers = find(GSLEOFilter);  % e.g., 1:10
GEOUsers = find(GSGEOFilter);  % e.g., 11:20
% Only Assign Channels to Valid Users (LEO or GEO)
for t = 1:length(ts)
    for s = 1:leoNum
        ChannelListLeo(LEOUsers, s, t) = randperm(numChannels, NumLeoUser);
    end
    for g = 1:geoNum
        ChannelListGeo(GEOUsers, g, t) = randperm(NumGeoUser, NumGeoUser)';
    end
end
%% Finding the serving LEO for each LEO GS (20 x 31)
fprintf('Finding the serving LEO for each LEO GS...\n');
ActualPrxLEO = PrxLEO .*GSLEOFilter;
[PservLEO, Serv_idxLEO] = max(ActualPrxLEO, [], 2);  % Max over LEO satellites
PservLEO = squeeze(PservLEO);                        % [NumGS × Time]
Serv_idxLEO = GSLEOFilter .* squeeze(Serv_idxLEO);   % [NumGS × Time]
%% Find the serving GEO for each GEO GS (20 x 31)
ActualPrxGEO = PrxGEO .*GSGEOFilter;
[PservGEO, Serv_idxGEO] = max(ActualPrxGEO, [], 2);  % Max over GEOs (dim 2)
PservGEO = squeeze(PservGEO);                        % [NumGS × Time]
Serv_idxGEO =  GSGEOFilter .* squeeze(Serv_idxGEO);  % [NumGS × Time]
%% Find the final channel allocations per users
FreqAlloc = NaN(NumGS, length(ts));  % Initialize

for t = 1:length(ts)
    for u = 1:NumGS
        if GSLEOFilter(u)
            s_serv = Serv_idxLEO(u, t);
            if s_serv > 0 && ~isnan(s_serv)
                FreqAlloc(u, t) = ChannelListLeo(u, s_serv, t);
            end
        elseif GSGEOFilter(u)
            s_serv = Serv_idxGEO(u, t);
            if s_serv > 0 && ~isnan(s_serv)
                FreqAlloc(u, t) = ChannelListGeo(u, s_serv, t);
            end
        end
    end
end


% save('Data');
%% Interference calculation
%% Interference Calculations
fprintf('Interference calculation step...\n');
T = length(ts);
SINR = NaN(NumGS, T);  % Output SINR matrix [NumGS x T]
for t = 1:T
    PrxLEO1 = PrxLEO(:, :, t);              % [NumGS x LEO]
    PrxGEO1 = PrxGEO(:, :, t);              % [NumGS x GEO]
    ChannelListLeo1 = ChannelListLeo(:, :, t);
    ChannelListGeo1 = ChannelListGeo(:, :, t);
    PservLEO1 = PservLEO(:, t);
    Serv_idxLEO1 = Serv_idxLEO(:, t);
    PservGEO1 = PservGEO(:, t);
    Serv_idxGEO1 = Serv_idxGEO(:, t);
    for userIdx = 1:NumGS
        isLEOUser = GSLEOFilter(userIdx);
        isGEOUser = GSGEOFilter(userIdx);

        if isLEOUser
            s_serv = Serv_idxLEO1(userIdx);
            if s_serv == 0 || isnan(s_serv), continue; end
            ch_user = ChannelListLeo1(userIdx, s_serv);
            Psig_dBm = PservLEO1(userIdx);
        elseif isGEOUser
            s_serv = Serv_idxGEO1(userIdx);
            if s_serv == 0 || isnan(s_serv), continue; end
            ch_user = ChannelListGeo1(userIdx, s_serv);
            Psig_dBm = PservGEO1(userIdx);
        else
            continue;  % undefined user
        end
        %% Interference from LEO
        PintLEO_mW = 0;
        for s = 1:leoNum
            if isLEOUser && s == s_serv
                continue;
            end
            for u = LEOUsers
                ch_other = ChannelListLeo1(u, s);
                if ch_other == ch_user
                    Pint_dBm = PrxLEO1(userIdx, s);
                    if ~isnan(Pint_dBm) && ~isinf(Pint_dBm)
                        PintLEO_mW = PintLEO_mW + 10^(Pint_dBm / 10);
                    end
                end
            end
        end
        %% Interference from GEO
        PintGEO_mW = 0;
        for g = 1:geoNum
            if isGEOUser && g == s_serv
                continue;
            end
            for u = GEOUsers
                ch_other = ChannelListGeo1(u, g);
                if ch_other == ch_user
                    Pint_dBm = PrxGEO1(userIdx, g);
                    if ~isnan(Pint_dBm) && ~isinf(Pint_dBm)
                        PintGEO_mW = PintGEO_mW + 10^(Pint_dBm / 10);
                    end
                end
            end
        end
        %% Final SINR
        Pint_total_mW = PintLEO_mW + PintGEO_mW;
        Psig_mW = 10^(Psig_dBm / 10);
        Noise_mW = 10^(ThermalNoisedBm / 10);
        SINR_mW = Psig_mW / (Pint_total_mW + Noise_mW);
        SINR(userIdx, t) = 10 * log10(SINR_mW);
    end
end


%% Visualization
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
histogram(SINR(:), 'BinWidth', 0.5, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'k');
xlabel('SINR [dB]');
ylabel('Frequency');
title('SINR Distribution Across All Users and Time Steps');
grid on;
xlim([min(SINR(:))-1, max(SINR(:))+1]);
%% Compute average SINR per user
meanSINR = mean(SINR, 2, 'omitnan');
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
plot(1:NumGS, meanSINR,'k-o','LineWidth',1);
xlabel('User Index');
ylabel('Mean SINR [dB]');
title('Average SINR per User');
grid on;
ylim([10 25]);
xline(NumGeoUser + 0.5, '--k', 'LineWidth', 1.2); 
text(NumGeoUser/2, max(meanSINR)+0.5, 'LEO Users', 'HorizontalAlignment', 'center');
text(NumGeoUser + NumLeoUser/2, max(meanSINR)+0.5, 'GEO Users', 'HorizontalAlignment', 'center');
%%  Per-Satellite/User SINR Timeline Plot
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
tiledlayout(2,1, 'TileSpacing','compact', 'Padding','compact');
nexttile;
hold on;
for i = 1:length(LEOUsers)
    u = LEOUsers(i);
    plot(ts, SINR(u,:), '-o', 'LineWidth', 1.2, 'DisplayName', sprintf('LEO-%d', u));
end
title('SINR Over Time - LEO Users');
ylabel('SINR [dB]');
grid on;
legend('Location','eastoutside');
xtickformat('HH:mm');
% === GEO Users Plot ===
nexttile;
hold on;
for i = 1:length(GEOUsers)
    u = GEOUsers(i);
    plot(ts, SINR(u,:), '-s', 'LineWidth', 1.2, 'DisplayName', sprintf('GEO-%d', u));
end
title('SINR Over Time - GEO Users');
xlabel('Time');
ylabel('SINR [dB]');
grid on;
legend('Location','eastoutside');
xtickformat('HH:mm');
%% Heatmap of SINR Over Time
Scale = 0.7;
h_Fig=figure('PaperPositionMode', 'manual','PaperUnits','inches','PaperPosition',[0 0 3.5*2 3.5*2/1.618*Scale],'Position',[200 300 800 800/1.618*Scale]);
imagesc(SINR);
colorbar;
xlabel('Time Step');
ylabel('User Index');
title('SINR Heatmap (Users vs Time)');
colormap('jet');
