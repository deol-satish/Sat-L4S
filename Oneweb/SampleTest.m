% Constants
c = 3e8;                          % Speed of light (m/s)
f = 12.5e9;                       % Ku-band downlink frequency (Hz)
lambda = c / f;                  % Wavelength (m)
Pt_dBW = 10*log10(10);           % Transmit power = 10 W in dBW
Gt_dBi = 30;                     % Transmit antenna gain in dBi
Gr_dBi = 40;                     % Receiver antenna gain in dBi
L_fs = @(d) 20*log10(4*pi*d/lambda); % Free space path loss (dB)
elevation_deg = 60;              % Example elevation angle for visibility

% Orbit parameters for OneWeb
alt_km = 1200;
Re = 6371;                       % Earth radius in km
d_km = sqrt((Re + alt_km)^2 - Re^2 * cosd(elevation_deg)^2) - Re * sind(elevation_deg);
d_m = d_km * 1e3;                % Convert to meters

% Calculate Free Space Path Loss
Lfs_dB = L_fs(d_m);

% Received Power in dBW
Pr_dBW = Pt_dBW + Gt_dBi + Gr_dBi - Lfs_dB;

% Convert to dBm
Pr_dBm = Pr_dBW + 30;

% Display Results
fprintf('--- OneWeb Ku-Band Receiver Power Calculation ---\n');
fprintf('Slant range: %.2f km\n', d_km);
fprintf('Free space path loss: %.2f dB\n', Lfs_dB);
fprintf('Received Power: %.2f dBW (%.2f dBm)\n', Pr_dBW, Pr_dBm);


% Bandwidth and Noise
B = 250e6;                        % Bandwidth: 250 MHz
T = 500;                          % System noise temperature in K
k = 1.38e-23;                     % Boltzmann constant
N = k * T * B;                    % Noise power in W
Pr_W = 10^((Pr_dBm - 30)/10);     % Convert dBm to Watts

% SNR
SNR = Pr_W / N;

% Channel Capacity
C = B * log2(1 + SNR);            % in bits per second

% Display results
fprintf('--- Channel Capacity ---\n');
fprintf('Noise Power: %.2e W\n', N);
fprintf('Received Power: %.2e W\n', Pr_W);
fprintf('SNR: %.2f dB\n', 10*log10(SNR));
fprintf('Capacity: %.2f Mbps\n', C / 1e6);

