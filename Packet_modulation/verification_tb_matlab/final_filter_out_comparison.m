clc; close all; clearvars;

%% Parameters
W = 16;  F = W-1;  OSR = 8;  span = 2;  BT = 0.5;
NTAPS = span*OSR + 1;                  % 17
DELAY = 2;                       % 8 (wait for tick) + 1 (hold_bit) + 1 (data_out register)
folder = 'D:/Files/Documents/bluetooth/GFSK/Verilog_code/';

g_int = round(gaussdesign(BT, span, OSR) * 2^F);

%% Load the two logs (one value per clock)
bits = readmatrix([folder 'serializer_out.txt']);   bits = bits(~isnan(bits));
rtl  = readmatrix([folder 'filter_out.txt']);       rtl  = rtl(~isnan(rtl));
x    = 2*bits(:) - 1;                  % 0 -> -1, 1 -> +1
rtl  = rtl(:);

%% Reference: full convolution of the logged serializer stream
y = conv(x, g_int(:));                 % y(n+1) is the output at 0-based index n

%% Compare: skip the first Delay samples, and stop where either file ends
n   = (NTAPS-1) : min(numel(x), numel(rtl) - DELAY) - 2;
ref = y(n + 1)/2^F;
hw  = rtl(n + DELAY + 1)/2^F;
err = ref - hw;

fprintf('Compared %d samples, mismatches: %d, max abs error: %d\n', ...
    numel(n), nnz(err ~= 0), max(abs(err)));
if all(err == 0), disp('MATCH'); else, disp('MISMATCH'); end

%% Optional: see which delay fits best

% for D = 0:15
%     m = (NTAPS-1) : min(numel(x), numel(rtl) - D) - 1;
%     fprintf('delay %2d: max abs error %g\n', D, max(abs(y(m+1) - rtl(m + D + 1))));
% end

%% Plot
figure;
subplot(2,1,1); plot(n, ref, 'o-', n, hw, 'x--'); grid on;
legend('MATLAB', 'RTL'); xlabel('Sample'); ylabel('Integer output');
subplot(2,1,2); plot(n, err); grid on; xlabel('Sample'); ylabel('Error');