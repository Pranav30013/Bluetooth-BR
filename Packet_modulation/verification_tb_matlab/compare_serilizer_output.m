clc;
close all;
clearvars;

%% Compare the serializer log with the expected bits (each bit held OSR clocks)
OSR    = 8;
folder = 'D:/Files/Documents/bluetooth/GFSK/Verilog_code/';

exp_bits = load('D:\Files\Documents\bluetooth\GFSK\Verilog_code\expected_bits.mem');        % 366 expected bits
rtl      = load('D:\Files\Documents\bluetooth\GFSK\Verilog_code\serializer_out.txt');       % one data_out value per clock

up  = repelem(exp_bits(:).', OSR);                    % each bit repeated OSR times
rtl = rtl(:).';
n   = numel(rtl);

% try a few start offsets, in case the log has a leading row from before bit 0 appears
best_off = 0;  best_mis = inf;
for off = 0
    m   = min(n - off, numel(up));                    % only compare what the simulation produced
    mis = sum(rtl(1+off : off+m) ~= up(1:m));
    fprintf('offset %d: %d mismatches over %d clocks\n', off, mis, m);
    if mis < best_mis, best_mis = mis; best_off = off; end
end

m = min(n - best_off, numel(up));
bad = find(rtl(1+best_off : best_off+m) ~= up(1:m));
if isempty(bad)
    fprintf('MATCH: %d clocks (%.1f symbols) checked, offset %d\n', m, m/OSR, best_off);
else
    fprintf('MISMATCH: first wrong clock %d (symbol %d)\n', bad(1)-1, floor((bad(1)-1)/OSR));
end

figure;
stairs(0:m-1, up(1:m)); hold on;
stairs(0:m-1, rtl(1+best_off : best_off+m), '--');
grid on; xlabel('Clock'); ylabel('Bit');
legend('Expected (x8)', 'RTL data\_out');