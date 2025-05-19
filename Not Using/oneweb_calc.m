% Constants
c = 3e8;               % Speed of light (m/s)
k = 1.38e-23;          % Boltzmann constant (J/K)
T = 290;               % System temperature (K)
NF_dB = 5;             % Noise figure (dB)
NF = 10^(NF_dB/10);    % Convert to linear scale
B = 20e6;              % Bandwidth (Hz) - 20 MHz
f = 12e9;              % Frequency (Hz) - Ku band
lambda = c/f;          % Wavelength

% Link Budget Parameters
P_tx_dBm = 30;         % Satellite transmit power (dBm)
G_tx_dBi = 40;         % Satellite antenna gain (dBi)
G_rx_dBi = 35;         % Ground station antenna gain (dBi)
d = 1200e3;            % Slant range from ground to satellite (m)

% Free Space Path Loss (FSPL)
FSPL_dB = 20*log10(d) + 20*log10(f) + 20*log10(4*pi/c);

% Signal Power Received (dBm)
P_rx_dBm = P_tx_dBm + G_tx_dBi + G_rx_dBi - FSPL_dB;

% Convert to mW
P_signal_mW = 10^(P_rx_dBm/10);

% Interference Power (Assume one interferer 15 dB lower)
P_interf_dBm = P_rx_dBm - 15;
P_interf_mW = 10^(P_interf_dBm/10);

% Noise Power (in dBm)
P_noise_W = k * T * B * NF;
P_noise_dBm = 10*log10(P_noise_W) + 30;
P_noise_mW = 10^(P_noise_dBm/10);

% SINR Calculation
SINR_linear = P_signal_mW / (P_interf_mW + P_noise_mW);
SINR_dB = 10 * log10(SINR_linear);

% Throughput (Shannon Capacity)
throughput_bps = B * log2(1 + SINR_linear);       % in bits per second
throughput_Mbps = throughput_bps / 1e6;           % in Mbps

% Display Results
fprintf('--- Link Performance Metrics ---\n');
fprintf('Distance to Satellite: %.1f km\n', d/1000);
fprintf('FSPL: %.2f dB\n', FSPL_dB);
fprintf('Received Signal Power: %.2f dBm\n', P_rx_dBm);
fprintf('Interference Power: %.2f dBm\n', P_interf_dBm);
fprintf('Noise Power: %.2f dBm\n', P_noise_dBm);
fprintf('SINR: %.2f dB\n', SINR_dB);
fprintf('Estimated Throughput: %.2f Mbps\n', throughput_Mbps);
