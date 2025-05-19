% Constants
c = 3e8;               % Speed of light (m/s)
k = 1.38e-23;          % Boltzmann constant (J/K)
T = 290;               % Temperature (Kelvin)
NF_dB = 5;             % Noise figure (dB)
NF = 10^(NF_dB/10);    % Linear scale
B = 100e6;             % Bandwidth (Hz) - Starlink uses ~100 MHz/user
f = 12e9;              % Frequency (Hz, Ku band)
lambda = c / f;

% System Parameters
P_tx_dBm = 40;         % Satellite TX power (dBm)
G_tx_dBi = 35;         % Satellite antenna gain (dBi)
G_rx_dBi = 35;         % Ground station phased array gain (dBi)
d = 550e3;             % Slant range ~550 km (Starlink orbit)

% Free Space Path Loss (FSPL)
FSPL_dB = 20*log10(d) + 20*log10(f) + 20*log10(4*pi/c);

% Received Signal Power (dBm)
P_rx_dBm = P_tx_dBm + G_tx_dBi + G_rx_dBi - FSPL_dB;

% Convert to mW
P_signal_mW = 10^(P_rx_dBm / 10);

% Interference Modeling (3 neighboring satellites, 15 dB lower each)
num_interferers = 3;
interf_dB_offset = 15;
P_interf_dBm = P_rx_dBm - interf_dB_offset;
P_interf_mW = num_interferers * 10^(P_interf_dBm / 10);  % Total interference power

% Noise Power Calculation
P_noise_W = k * T * B * NF;
P_noise_dBm = 10*log10(P_noise_W) + 30;
P_noise_mW = 10^(P_noise_dBm / 10);

% SINR Calculation
SINR_linear = P_signal_mW / (P_interf_mW + P_noise_mW);
SINR_dB = 10 * log10(SINR_linear);

% Throughput using Shannon capacity
throughput_bps = B * log2(1 + SINR_linear);
throughput_Mbps = throughput_bps / 1e6;

% Display Results
fprintf('--- Starlink/Walker Star Link Performance ---\n');
fprintf('Distance to Satellite: %.0f km\n', d / 1000);
fprintf('FSPL: %.2f dB\n', FSPL_dB);
fprintf('Received Signal Power: %.2f dBm\n', P_rx_dBm);
fprintf('Interference Power (3 sats): %.2f dBm\n', 10*log10(P_interf_mW));
fprintf('Noise Power: %.2f dBm\n', P_noise_dBm);
fprintf('SINR: %.2f dB\n', SINR_dB);
fprintf('Estimated Max Throughput: %.2f Mbps (Shannon)\n', throughput_Mbps);
