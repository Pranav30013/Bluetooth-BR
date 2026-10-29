clear; clc; close all;

%% Parameters (must match the RTL)
W = 16;  F = W-1;  OSR = 8;  span = 2;  BT = 0.5;
h = 0.32;  Rs = 1e6;  Fdev = h*Rs/2;   % full deviation in Hz (used to express errors in Hz)
g     = gaussdesign(BT, span, OSR);     % ideal double-precision taps
g_int = round(g * 2^F);                 % same integer taps as gauss_coeff.vh
HALF  = span*OSR/2;                     % 8
LAT   = HALF + 2;                       % latency of the registered-hold_bit version
% (use HALF + 1 for the pass-through version)
folder = 'D:/Files/Documents/bluetooth/GFSK/Verilog_code/';

%% 1. Write the stimulus  (run this section BEFORE the simulation)
bits = [0 0 0 0 1 1 1 1, repmat([1 0],1,8), 1 1 0 1 0 0 1 0];   % 32 symbols
fprintf('NSYM = %d  (must equal NSYM in the testbench)\n', numel(bits));
fid = fopen([folder 'stim_bits.mem'], 'w');
fprintf(fid, '%d\n', bits);
fclose(fid);

%% 2. Load RTL output and build both MATLAB models  (run AFTER the simulation)
rtl = load([folder 'rtl_out.txt']);     % integers: Q1.F values scaled by 2^F
rtl = rtl(:).';

up    = repelem(2*bits - 1, OSR);                        % +/-1 stream
L     = numel(up);
up_p  = [up(1)*ones(1,HALF), up, up(end)*ones(1,HALF)];  % edge padding

y_int   = conv(up_p, g_int, 'valid');   % fixed-point model: integer taps
y_ideal = conv(up_p, g,     'valid');   % ideal model: double-precision taps

m       = HALF : L-1-HALF;              % skip the edges (reset zeros in the RTL)
rtl_int = rtl(m + LAT + 1);             % RTL output as integers
rtl_val = rtl_int / 2^F;                % RTL output as real numbers (Q1.F -> value)

%% 2a. RTL vs fixed-point model: should be bit-exact
err_bit = rtl_int - y_int(m + 1);
fprintf('\n--- RTL vs integer model (bit-exact check) ---\n');
fprintf('Compared %d samples, max abs error = %d\n', numel(m), max(abs(err_bit)));
if all(err_bit == 0), disp('MATCH'); else, disp('MISMATCH'); end

%% 2b. Quantization error: RTL vs ideal double-precision filter
q_err    = rtl_val - y_ideal(m + 1);    % error in real-number units (full scale = 1.0)
bound    = sum(abs(g - g_int/2^F));     % worst case: every tap error aligned with its sign

fprintf('\n--- Quantization error (RTL vs ideal taps), F = %d ---\n', F);
fprintf('Max abs error : %.3e  (%.2f LSB, %.1f Hz at h=%.2f)\n', ...
    max(abs(q_err)), max(abs(q_err))*2^F, max(abs(q_err))*Fdev, h);
fprintf('RMS error     : %.3e  (%.1f Hz)\n', sqrt(mean(q_err.^2)), sqrt(mean(q_err.^2))*Fdev);
fprintf('Worst-case bound (sum of tap errors): %.3e (%.1f Hz)\n', bound, bound*Fdev);
fprintf('SQNR          : %.1f dB\n', 10*log10(mean(y_ideal(m+1).^2)/mean(q_err.^2)));
fprintf('Sum of integer taps = %d  (ideal would be %d), steady-state level = %.6f\n', ...
    sum(g_int), 2^F, sum(g_int)/2^F);

%% Plots
figure;
subplot(2,1,1);
plot(m, y_ideal(m+1), 'o-', m, rtl_val, 'x--'); grid on;
ylabel('Output (full scale = 1)'); legend('Ideal (double)', 'RTL (Q1.15)');
title('Gaussian filter: ideal vs RTL');
subplot(2,1,2);
plot(m, q_err*Fdev, '.-'); grid on;
xlabel('Sample'); ylabel('Error (Hz)');
title('Quantization error (RTL - ideal), in Hz at h = 0.32');


figure
subplot(4,1,1);
plot(up_p);
grid on; 
xlabel('samples');
ylabel('Input'); 
title('Upsampled NRZ input with edge padding');

subplot(4,1,2);
plot(y_ideal);
grid on; 
xlabel('samples');
ylabel('Output'); 
title('Output of the ideal gaussian filter');

subplot(4,1,3)
plot(y_int/2^F);
grid on; 
xlabel('samples');
ylabel('Output'); 
title('Output of the matlab quantized gaussian filter');

subplot(4,1,4);
plot(rtl_val);
grid on;
xlabel('Sample');
ylabel('RTL output');
title('Output of verilog filter');