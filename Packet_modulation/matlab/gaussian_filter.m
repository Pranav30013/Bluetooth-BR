clear; clc; close all;

%% 1. Parameters
Rs   = 1e6;            % symbol rate (sym/s)
OSR  = 8;              % oversampling ratio (samples per symbol)
span = 2;              % filter span in symbols
BT   = 0.5;            % Gaussian BT product
h    = 0.32;           % modulation index (Bluetooth BR: 0.28 to 0.35)
Fs   = Rs*OSR;         % sample rate
Ts   = 1/Fs;

%% 2. Gaussian filter (gaussdesign)
g = gaussdesign(BT, span, OSR);          % span*OSR + 1 = 25 taps, sum(g) = 1
t = (-span*OSR/2 : span*OSR/2)/OSR;      % tap time axis in symbol periods

figure; stem(t, g); grid on;
xlabel('Time (symbol periods)'); ylabel('Amplitude');
title('Gaussian filter taps, BT=0.5, OSR=8, span=3');

%% 3. Input bit patterns
bits_max = [0 0 0 0 1 1 1 1];            % max deviation pattern
bits_min = repmat([1 0], 1, 8);          % 1010... repeated to reach steady state

%% 4. Run the modulator
[f_max, ph_max, tt_max] = gfsk_mod(bits_max, g, OSR, h, Rs, Ts, span);
[f_min, ph_min, tt_min] = gfsk_mod(bits_min, g, OSR, h, Rs, Ts, span);

%% 5. Deviation measurement
mid     = round(length(f_min)*0.25) : round(length(f_min)*0.75);  % ignore edges
dev_max = max(abs(f_max));
dev_min = max(abs(f_min(mid)));

fprintf('Nominal full deviation (h*Rs/2) : %.1f kHz\n', h*Rs/2/1e3);
fprintf('Max deviation (00001111)        : %.1f kHz\n', dev_max/1e3);
fprintf('Min deviation (1010)            : %.1f kHz\n', dev_min/1e3);
fprintf('Ratio min/max                   : %.1f %%\n', 100*dev_min/dev_max);

%% 6. Input bits vs time, and frequency deviation vs time
plot_bits_and_freq(bits_max, f_max, tt_max, OSR, '00001111 (max deviation)');
plot_bits_and_freq(bits_min, f_min, tt_min, OSR, '1010 (min deviation)');

%% 7. Sweep over the allowed modulation index range
for hh = [0.28 0.32 0.35]
    [fm,~,~] = gfsk_mod(bits_max, g, OSR, hh, Rs, Ts, span);
    [fn,~,~] = gfsk_mod(bits_min, g, OSR, hh, Rs, Ts, span);
    fprintf('h=%.2f -> max dev = %.1f kHz, min dev = %.1f kHz\n', ...
        hh, max(abs(fm))/1e3, max(abs(fn(mid)))/1e3);
end

%% 8. Local function: GFSK modulator
function [freq, phase, tt] = gfsk_mod(bits, g, OSR, h, Rs, Ts, span)
nrz  = 2*bits - 1;                                  % 0 -> -1, 1 -> +1
up   = repelem(nrz, OSR);                           % rectangular pulse shaping
D    = span*OSR/2;                                  % filter group delay (samples)
up_p = [up(1)*ones(1,D), up, up(end)*ones(1,D)];    % edge padding
y    = conv(up_p, g, 'valid');                      % filtered NRZ, same length as up
freq  = (h*Rs/2) * y;                               % instantaneous freq deviation (Hz)
phase = 2*pi*cumsum(freq)*Ts;                       % integrate frequency to get phase
tt    = (0:length(freq)-1)*Ts;                      % time axis
end

%% 9. Local function: bits vs time and frequency vs time
function plot_bits_and_freq(bits, freq, tt, OSR, name)
bits_t = repelem(bits, OSR);                 % each bit held for OSR samples
figure;
subplot(2,1,1);
plot(tt*1e6, bits_t, 'LineWidth', 1.5); grid on;
ylim([-0.2 1.2]); yticks([0 1]);
ylabel('Input bit'); title(['Input bits: ' name]);
subplot(2,1,2);
plot(tt*1e6, freq/1e3, 'LineWidth', 1.5); grid on;
xlabel('Time (\mus)'); ylabel('Freq dev (kHz)');
title('Frequency deviation');
end