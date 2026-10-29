clear; clc; close all;

%% Parameters
Rs = 1e6; OSR = 8; span = 2; BT = 0.5; h = 0.32;
Fdev = h*Rs/2;                               % full deviation in Hz
g = gaussdesign(BT, span, OSR);              % double-precision reference taps

%% Test stream: mix of 00001111, 1010 and random bits
bits = [0 0 0 0 1 1 1 1, repmat([1 0],1,4), randi([0 1],1,64)];
up   = repelem(2*bits-1, OSR);
D    = span*OSR/2;
up_p = [up(1)*ones(1,D), up, up(end)*ones(1,D)];
y_ref = conv(up_p, g, 'valid');              % reference filter output

%% Sweep number of fractional bits for the coefficients
Fbits = [6 8 10 12 14 16 20];
fprintf('Fbits | max tap err | DC gain err (ppm) | max freq err (Hz)\n');
for k = 1:numel(Fbits)
    q  = 2^Fbits(k);
    gq = round(g*q)/q;                       % quantized taps (multiples of 1/q)
    yq = conv(up_p, gq, 'valid');            % exact accumulate (input is +/-1)
    fprintf('%5d | %11.2e | %17.0f | %17.1f\n', Fbits(k), ...
        max(abs(gq-g)), (sum(gq)-1)*1e6, max(abs(yq-y_ref))*Fdev);
end

%% Frequency response of the quantized vs ideal filter
% Bit size for the coefficients = 16 bits
Fb = 16; gq = round(g*2^Fb)/2^Fb;
[H0,w] = freqz(g, 1, 1024); H1 = freqz(gq, 1, 1024);
figure; plot(w/pi, 20*log10(abs(H0)), w/pi, 20*log10(abs(H1))); grid on;
xlabel('Normalized frequency (\times\pi rad/sample)'); ylabel('Magnitude (dB)');
legend('double', sprintf('%d fractional bits', Fb));
title('Gaussian filter response, ideal vs quantized taps');