%% GFSK I/Q from the RTL Gaussian filter output
% filter output (Q1.15 integers) -> frequency -> phase (integrate) -> I = cos(phase), Q = sin(phase)
clear; clc; close all;

%% Parameters
Rs   = 1e6;                  % symbol rate
OSR  = 8;                    % samples per symbol
Fs   = Rs*OSR;  Ts = 1/Fs;
BT   = 0.5;  span = 2;
W    = 16;   F = W-1;        % Q1.15
h    = 0.32;                 % modulation index (0.28 to 0.35)
Fdev = h*Rs/2;               % frequency for a full-scale filter output (160 kHz)
DELAY = 2;  
NTAPS = span*OSR + 1;
folder = 'D:/Files/Documents/bluetooth/GFSK/Verilog_code/';

%% 1. Read the RTL Gaussian filter output (one integer per clock, used exactly as the hardware produced it)
y_int = readmatrix([folder 'filter_out.txt']);
y_int = y_int(:).';
if any(isnan(y_int)), error('filter_out.txt has non-numeric entries (x values?)'); end

[f, phi, I, Q] = iq_from_filter(y_int, F, h, Rs, OSR);
s = I + 1j*Q;                                        % complex baseband signal, exp(j*phase)
t = (0:numel(f)-1) * Ts * 1e6;                       % time in us

%% Read the phase from the RTL
phase_rtl = readmatrix([folder 'Phase_acc.txt']);
phase_rtl = phase_rtl(:).';
% Convert from raw 24-bit RTL integer to Radians [0, 2*pi)
phase_rtl_rad = (phase_rtl / 2^24) * 2 * pi;

%% DIAGNOSTIC PLOT: Phase Trajectory 
% % Wrap MATLAB continuous phase to the same circular bounds [0, 2*pi)
% phi_wrapped = mod(phi, 2*pi);

% Unwrap both signals to remove the circular 2*pi jumps.
% This creates a continuous line, making it incredibly easy to spot the error.
phi_unwrapped = phi;
rtl_unwrapped = unwrap(phase_rtl_rad);

% Plot the first 500 samples
figure('Name', 'Phase Diagnostic', 'NumberTitle', 'off');
plot(phi_unwrapped(1:591), 'b', 'LineWidth', 2); hold on;
% Shift RTL back by 1 clock to align it (Accumulators usually have a DELAY of 1)
plot(rtl_unwrapped(2:591), 'r--', 'LineWidth', 2); 
title('Unwrapped Phase Trajectory (MATLAB vs RTL)');
xlabel('Sample');
ylabel('Accumulated Phase (Radians)');
legend('MATLAB Ideal', 'RTL Hardware', 'Location', 'best');
grid on;
%% Local function
function [f, phi, I, Q] = iq_from_filter(y_int, F, h, Rs, OSR)
Ts  = 1/(Rs*OSR);
f   = y_int / 2^F * (h*Rs/2);        % filter output (Q1.15) -> frequency deviation in Hz
phi = 2*pi*cumsum(f)*Ts;             % integrate frequency to get phase
I   = cos(phi);
Q   = sin(phi);
end