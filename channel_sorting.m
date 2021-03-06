function [output] = channel_sorting(in)

%% 
% 1. Set samling rate (line 29)
% 1. Adjust baseline, rms-noise and signal amplitudes (line 31-34)



% set test_amp_setings to 1 to see if amplitude settings are correct, to skip, set to 0... Data is plotted in black, baseline in red with peak_to_peak noise levels as dotted lines. 
% The low_conductance signal level is blue, and the high conductance is green
test_amp_setings = 0; 

% set test_low_conductance_signal_level_1 to 1 to see if detection of a
% single opened low conductance channel work as intended. To skip, set 
% test_low_conductance_signal_level_1 to 0.
test_low_conductance_signal_level_1 = 0; 


%% Preparing input

data = in(1:size(in,1));
nRows = size(data,1);
time = (1:nRows)';
mastervector = zeros(nRows,1);


%% Adjust sampling rate, baseline, rms-noise and signal amplitudes

Sampling_rate = 250000;

baseline = 0;
low_conductance_signal_amp = 15;
high_conductance_signal_amp = 28;
peak_to_peak_noise = 11;

%% Adjust deadtimes

% set the minimal dwell time for events to include in analysis (in
% micro-seconds)

deadtime = 40;






%%

peak_to_peak_noise = peak_to_peak_noise/2;
deadtime_dp = round(deadtime /(1000000/Sampling_rate)); % convert deadtime in microseconds to data points

if sum(data(1:10) > (baseline+peak_to_peak_noise)) > 0 || sum(data(end-10:end) > (baseline+peak_to_peak_noise)) > 0
    disp('error: data fragment analysed must begin and end at baseline level')
    return
end
    
if test_amp_setings == 1
    figure('name','test_amp_settings');
    plot(in,'k')
    hold on
    plot(mastervector + baseline,'r')
    plot(mastervector + low_conductance_signal_amp,'b')
    plot(mastervector + high_conductance_signal_amp,'g')
    plot(mastervector + baseline - peak_to_peak_noise,'r:')
    plot(mastervector + baseline + peak_to_peak_noise,'r:')
end




%% adjustables

% The minimum number of peaks a cluster of low_conductance_signal_level_1
% must have not to be discarded
low_conductance_signal_level_1_sensitivity = 2;

% The span that low_conductance_signal_level_1 ligates over to make
% clusters (in microseconds)
ligate_threshold_1 = 800;



ligate_thr_inout_1 = 200;
ligate_thr_outout_2 = 200;
ligate_thr_outout_1_inout_1 = 300;
ligate_thr_outout_1_inout_1_large = 400;
ligate_thr_outout_3 = 200;
ligate_thr_inout_2 = 200;
ligate_thr_inout_2_outout = 300;
ligate_thr_left = 50;


%%
ligate_threshold_1_dp = round(ligate_threshold_1 /(1000000/Sampling_rate)); % convert deadtime in microseconds to data points



%% tools

peakvector = zeros(nRows,1);
for row = 2:nRows-1
    if ((data(row) >= data(row-1)) && (data(row) >= data(row+1)))
        peakvector(row) = data(row);
    end
end
peakvector_bin = peakvector;
peakvector_bin(peakvector_bin > 0) = 1;


closing_vector = zeros(nRows,1);
for row = 1:nRows-1
    if ((data(row) > (baseline + peak_to_peak_noise)) && (data(row+1) < (baseline + peak_to_peak_noise)))
        closing_vector(row) = 1;
    end
end

closing_vector_level_inout2 = zeros(nRows,1);
for row = 1:nRows-1
    if ((data(row) > (baseline +peak_to_peak_noise+ high_conductance_signal_amp)) && (data(row+1) < (baseline + peak_to_peak_noise + high_conductance_signal_amp)))
        closing_vector_level_inout2(row) = 1;
    end
end

closing_vector_level2 = zeros(nRows,1);
for row = 1:nRows-1
    if ((data(row) > (baseline + peak_to_peak_noise + high_conductance_signal_amp)) && (data(row+1) < (baseline + peak_to_peak_noise + high_conductance_signal_amp)))
        closing_vector_level2(row) = 1;
    end
end



nadirvector = zeros(nRows,1);
for row = 2:nRows-1
    if ((data(row) <= data(row-1)) && (data(row) <= data(row+1)))
        nadirvector(row) = data(row);
    end
end

%% Clusters where one low conductance channel is open

low_conductance_signal_level_1 = data;
low_conductance_signal_level_1(low_conductance_signal_level_1 < peak_to_peak_noise) = 0;
low_conductance_signal_level_1(low_conductance_signal_level_1 > (low_conductance_signal_amp + peak_to_peak_noise)) = 0;

% All peaks that are not outout_1 positive, drives down in both directions
% and remove outout_1.

for row = 2:nRows
    if ((low_conductance_signal_level_1(row) < data(row-1)) && (low_conductance_signal_level_1(row-1) == 0))
        low_conductance_signal_level_1(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((low_conductance_signal_level_1(row) < data(row+1)) && (low_conductance_signal_level_1(row+1) == 0))
        low_conductance_signal_level_1(row) = 0;
    end
end

low_conductance_signal_level_1_binary = low_conductance_signal_level_1;
low_conductance_signal_level_1_binary(low_conductance_signal_level_1_binary > 0) = 1;

% remove events shorter than deadtime points

low_conductance_signal_level_1_binary_v2 = low_conductance_signal_level_1_binary;

for row = 2:nRows
    if (((low_conductance_signal_level_1_binary(row-1))+(low_conductance_signal_level_1_binary(row))) == 1)
        low_conductance_signal_level_1_binary_StartStop(row) = time(row);
    else low_conductance_signal_level_1_binary_StartStop(row) = 0;
    end
end

low_conductance_signal_level_1_binary_StartStop(low_conductance_signal_level_1_binary_StartStop==0) = [];
low_conductance_signal_level_1_binary_StartStop_matrix = vec2mat(low_conductance_signal_level_1_binary_StartStop,2);
low_conductance_signal_level_1_binary_StartStop_matrix(:,2)=low_conductance_signal_level_1_binary_StartStop_matrix(:,2)-1;
low_conductance_signal_level_1_binary_StartStop_matrix_size = size(low_conductance_signal_level_1_binary_StartStop_matrix,1);

for row = 1:low_conductance_signal_level_1_binary_StartStop_matrix_size-1
    if  low_conductance_signal_level_1_binary_StartStop_matrix(row,2)-low_conductance_signal_level_1_binary_StartStop_matrix(row,1) < deadtime_dp
        low_conductance_signal_level_1_binary_v2(low_conductance_signal_level_1_binary_StartStop_matrix(row,1):low_conductance_signal_level_1_binary_StartStop_matrix(row,2)) = 0;
    end
end


% Ligate low_conductance_signal_level_1 fragments that are closer together
% than ligate_threshold_1, but include a penalty if signal between
% fragments are larger or smaller than the range of the
% low_conductance_signal_level_1 signal.

ligate_blocker_low_conductance_signal_level_1 = data;
ligate_blocker_low_conductance_signal_level_1(ligate_blocker_low_conductance_signal_level_1 < (baseline + peak_to_peak_noise*2)) = 50;
ligate_blocker_low_conductance_signal_level_1(ligate_blocker_low_conductance_signal_level_1 >= (baseline + peak_to_peak_noise*2 + low_conductance_signal_amp)) = 50;
ligate_blocker_low_conductance_signal_level_1(ligate_blocker_low_conductance_signal_level_1 ~= 50) = 0;

for row = 2:nRows
    if (((low_conductance_signal_level_1_binary_v2(row-1))+(low_conductance_signal_level_1_binary_v2(row))) == 1)
        low_conductance_signal_level_1_binary_StartStop_v2(row) = time(row);
    else low_conductance_signal_level_1_binary_StartStop_v2(row) = 0;
    end
end

low_conductance_signal_level_1_binary_StartStop_v2(low_conductance_signal_level_1_binary_StartStop_v2==0) = [];
low_conductance_signal_level_1_binary_StartStop_matrix_v2 = vec2mat(low_conductance_signal_level_1_binary_StartStop_v2,2);
low_conductance_signal_level_1_binary_StartStop_matrix_v2(:,2)=low_conductance_signal_level_1_binary_StartStop_matrix_v2(:,2)-1;
low_conductance_signal_level_1_binary_StartStop_matrix_size_v2 = size(low_conductance_signal_level_1_binary_StartStop_matrix_v2,1);

low_conductance_signal_level_1_binary_v3 = low_conductance_signal_level_1_binary_v2;

for row = 1:low_conductance_signal_level_1_binary_StartStop_matrix_size_v2-1
    if (low_conductance_signal_level_1_binary_StartStop_matrix_v2(row+1,1) - low_conductance_signal_level_1_binary_StartStop_matrix_v2(row,2)) + (sum(ligate_blocker_low_conductance_signal_level_1(low_conductance_signal_level_1_binary_StartStop_matrix_v2(row,2):low_conductance_signal_level_1_binary_StartStop_matrix_v2(row+1,1)))) < ligate_threshold_1_dp
        low_conductance_signal_level_1_binary_v3((low_conductance_signal_level_1_binary_StartStop_matrix_v2(row,2)):(low_conductance_signal_level_1_binary_StartStop_matrix_v2(row+1,1))) = 1;
    end
end


% Remove clusters of low_conductance_signal_level_1 with fewer than
% low_conductance_signal_level_1_sensitivity peaks

for row = 2:nRows
    if (((low_conductance_signal_level_1_binary_v3(row-1))+(low_conductance_signal_level_1_binary_v3(row))) == 1)
        low_conductance_signal_level_1_binary_v1_StartStop(row) = time(row);
    else low_conductance_signal_level_1_binary_v1_StartStop(row) = 0;
    end
end

low_conductance_signal_level_1_binary_v1_StartStop(low_conductance_signal_level_1_binary_v1_StartStop==0) = [];
low_conductance_signal_level_1_binary_v1_StartStop_matrix = vec2mat(low_conductance_signal_level_1_binary_v1_StartStop,2);
low_conductance_signal_level_1_binary_v1_StartStop_matrix(:,2)=low_conductance_signal_level_1_binary_v1_StartStop_matrix(:,2)-1;
low_conductance_signal_level_1_binary_v1_StartStop_matrix_size = size(low_conductance_signal_level_1_binary_v1_StartStop_matrix,1);

low_conductance_signal_level_1_binary_v4 = low_conductance_signal_level_1_binary_v3;

peakvector_low_conductance_signal_level_1 = peakvector;
peakvector_low_conductance_signal_level_1(peakvector_low_conductance_signal_level_1 < (peak_to_peak_noise*2)) = 0;
peakvector_low_conductance_signal_level_1_binary = peakvector_low_conductance_signal_level_1;
peakvector_low_conductance_signal_level_1_binary(peakvector_low_conductance_signal_level_1_binary > 0) = 1;


for row = 1:low_conductance_signal_level_1_binary_v1_StartStop_matrix_size
    if sum(peakvector_low_conductance_signal_level_1_binary(low_conductance_signal_level_1_binary_v1_StartStop_matrix(row,1):low_conductance_signal_level_1_binary_v1_StartStop_matrix(row,2))) < low_conductance_signal_level_1_sensitivity
        low_conductance_signal_level_1_binary_v4(low_conductance_signal_level_1_binary_v1_StartStop_matrix(row,1):low_conductance_signal_level_1_binary_v1_StartStop_matrix(row,2)) = 0;
    end
end


% Alocate low_conductance_signal_level_1_binary_v4 to mastervector with
% value 3

for row = 1:nRows
    if low_conductance_signal_level_1_binary_v4(row) == 1
        mastervector(row) = 3;
    end
end


if test_low_conductance_signal_level_1 == 1;
    figure('name','test_low_conductance_signal_level_1')
    plot(in,'k')            
    hold on
    plot(low_conductance_signal_level_1_binary - 2*peak_to_peak_noise)
    plot(low_conductance_signal_level_1_binary_v2 - 2*peak_to_peak_noise - 4)
    plot(low_conductance_signal_level_1_binary_v3 - 2*peak_to_peak_noise - 8)
    plot(low_conductance_signal_level_1_binary_v4 - 2*peak_to_peak_noise - 12)
end

    
    
%% Clusters where one high conductance channel is open


high_conductance_signal_level_1 = data;
high_conductance_signal_level_1(high_conductance_signal_level_1 > baseline + high_conductance_signal_amp + peak_to_peak_noise) = 0;
high_conductance_signal_level_1(high_conductance_signal_level_1 < baseline + high_conductance_signal_amp - peak_to_peak_noise) = 0;

high_conductance_signal_level_1_lower = ones(nRows,1);
high_conductance_signal_level_1_lower = high_conductance_signal_level_1_lower*-(baseline + high_conductance_signal_amp + peak_to_peak_noise);
high_conductance_signal_level_1_upper = ones(nRows,1);
high_conductance_signal_level_1_upper = high_conductance_signal_level_1_upper*-(baseline + high_conductance_signal_amp - peak_to_peak_noise);


% All peaks that are not high_conductance_signal_level_1 positive, drives down in both directions
% and remove high_conductance_signal_level_1.

for row = 2:nRows
    if ((high_conductance_signal_level_1(row) < data(row-1)) && (high_conductance_signal_level_1(row-1) == 0))
        high_conductance_signal_level_1(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((high_conductance_signal_level_1(row) < data(row+1)) && (high_conductance_signal_level_1(row+1) == 0))
        high_conductance_signal_level_1(row) = 0;
    end
end

high_conductance_signal_level_1_binary = high_conductance_signal_level_1;
high_conductance_signal_level_1_binary(high_conductance_signal_level_1_binary > 0) = 1;
high_conductance_signal_level_1_binary_v2 = high_conductance_signal_level_1_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (high_conductance_signal_level_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        high_conductance_signal_level_1_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (high_conductance_signal_level_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        high_conductance_signal_level_1_binary(row-1) = 1;
    end
end


for row = 2:nRows
    if (((high_conductance_signal_level_1_binary(row-1))+(high_conductance_signal_level_1_binary(row))) == 1)
        high_conductance_signal_level_1_binary_StartStop(row) = time(row);
    else high_conductance_signal_level_1_binary_StartStop(row) = 0;
    end
end

ligate_blocker_inout_1 = data;
ligate_blocker_inout_1(ligate_blocker_inout_1 < (baseline + peak_to_peak_noise + high_conductance_signal_amp)) = 0;
ligate_blocker_inout_1(ligate_blocker_inout_1 >= (baseline + peak_to_peak_noise + high_conductance_signal_amp)) = 50;

ligate_blocker_inout_1(ligate_blocker_inout_1 > 0) = 50;

high_conductance_signal_level_1_binary_StartStop(high_conductance_signal_level_1_binary_StartStop==0) = [];
inout_1_binary_StartStop_matrix = vec2mat(high_conductance_signal_level_1_binary_StartStop,2);
inout_1_binary_StartStop_matrix(:,2)=inout_1_binary_StartStop_matrix(:,2)-1;
inout_1_binary_StartStop_matrix_size = size(inout_1_binary_StartStop_matrix,1);

inout_1_binary_v1 = high_conductance_signal_level_1_binary;


for row = 1:inout_1_binary_StartStop_matrix_size-1
    if (inout_1_binary_StartStop_matrix(row+1,1) - inout_1_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_inout_1(inout_1_binary_StartStop_matrix(row,2):inout_1_binary_StartStop_matrix(row+1,1)))) < ligate_thr_inout_1
        inout_1_binary_v1((inout_1_binary_StartStop_matrix(row,2)):(inout_1_binary_StartStop_matrix(row+1,1))) = 1;
    end
end

for row = 2:nRows
    if (((inout_1_binary_v1(row-1))+(inout_1_binary_v1(row))) == 1)
        inout_1_binary_v1_StartStop(row) = time(row);
    else inout_1_binary_v1_StartStop(row) = 0;
    end
end

inout_1_binary_v1_StartStop(inout_1_binary_v1_StartStop==0) = [];
inout_1_binary_v1_StartStop_matrix = vec2mat(inout_1_binary_v1_StartStop,2);
inout_1_binary_v1_StartStop_matrix(:,2)=inout_1_binary_v1_StartStop_matrix(:,2)-1;
inout_1_binary_v1_StartStop_matrix_size = size(inout_1_binary_v1_StartStop_matrix,1);


% give points to inout_1 clusters

% closing frequency is the number of closings in a cluster normalized to
% the length of the cluster. Closings per 400 us. It is alocated to 
% outout_2_and_inout_1_evaluationvector so that less than 1 closing per 800
% us count -1, more count 1 and 1 per 400 us count 2.

inout_1_evaluationvector = zeros(nRows,1);
for row = 1:inout_1_binary_v1_StartStop_matrix_size
    if ((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1)) > 10)
        inout_1_evaluationvector(inout_1_binary_v1_StartStop_matrix(row,2)-(round((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))./4))) = (1-(1/((sum(closing_vector(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))))/((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))/250))))*10;
    end
end

inout_1_evaluationvector(inout_1_evaluationvector < 0) = 0;
inout_1_evaluationvector_vClosing = inout_1_evaluationvector;

% The slope_vector_threepoint system identifies points where three
% consecutive points increase by more than 8.

slope_vector = zeros(nRows,1);
for row = 2:nRows
    if data(row) > -100000
        slope_vector(row) = data(row) - data(row-1);
    end
end

slope_vector_threepoint = zeros(nRows,1);
for row = 2:nRows-1
    if data(row) > -100000
        slope_vector_threepoint(row) = (log10((((slope_vector(row))+ (slope_vector(row-1))+ (slope_vector(row+1)))/8)^8));
    end
end
slope_vector_threepoint_v2 = slope_vector_threepoint;
slope_vector_threepoint(slope_vector_threepoint < 0.05) = 0;
slope_vector_threepoint_v2(slope_vector_threepoint_v2 < 0) = 0;
slope_norm = sort(slope_vector_threepoint_v2);
slope_norm_mean = mean(slope_norm((end-100):end));
slope_vector_threepoint_v2 = slope_vector_threepoint_v2./slope_norm_mean;
slope_vector_threepoint_v2 = slope_vector_threepoint_v2+1;
slope_vector_threepoint_v2(slope_vector_threepoint_v2 == 1) = 0;

slope_vector_threepoint_binary = slope_vector_threepoint;
slope_vector_threepoint_binary(slope_vector_threepoint_binary > 0) = 1;




for row = 1:inout_1_binary_v1_StartStop_matrix_size
    if ((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1)) > 4)
        inout_1_evaluationvector(inout_1_binary_v1_StartStop_matrix(row,2)-(round((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))./2))) = (1-(1/((sum(slope_vector_threepoint_v2(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))))/((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))/30))))*10;
    end
end
inout_1_evaluationvector(inout_1_evaluationvector < 0) = 0.01;
inout_1_evaluationvector_vSlope = inout_1_evaluationvector;

inout_1_evaluationvector_vSlope = inout_1_evaluationvector_vSlope-inout_1_evaluationvector_vClosing;



% giver points til inout ved stigninger p� over outout_1 r�kkeviden, men
% betinget af at der ogs� er et fald af lignende propationer i samme
% cluster, for at reducere falske positive.

slope_vector_increase = slope_vector;
slope_vector_increase(slope_vector_increase < 0) = 0;
slope_vector_increase_binary = slope_vector_increase;
slope_vector_increase_binary(slope_vector_increase_binary > 0) = 1;
for row = 2:nRows
    if (((slope_vector_increase_binary(row-1))+(slope_vector_increase_binary(row))) == 1)
        slope_vector_increase_StartStop(row) = time(row);
    else slope_vector_increase_StartStop(row) = 0;
    end
end

slope_vector_increase_StartStop(slope_vector_increase_StartStop==0) = [];
slope_vector_increase_StartStop_matrix = vec2mat(slope_vector_increase_StartStop,2);
slope_vector_increase_StartStop_matrix(:,2)=slope_vector_increase_StartStop_matrix(:,2)-1;
slope_vector_increase_StartStop_matrix_size = size(slope_vector_increase_StartStop_matrix,1);

delta_increase_vector = zeros(nRows,1);
for row = 1:slope_vector_increase_StartStop_matrix_size
    if (slope_vector_increase_StartStop_matrix(row,2)-slope_vector_increase_StartStop_matrix(row,1)) > 5
        delta_increase_vector(slope_vector_increase_StartStop_matrix(row,2)) = data(slope_vector_increase_StartStop_matrix(row,2)) - data(slope_vector_increase_StartStop_matrix(row,1));
    end
end


slope_vector_decrease = slope_vector;
slope_vector_decrease(slope_vector_decrease > 0) = 0;
slope_vector_decrease_binary = slope_vector_decrease;
slope_vector_decrease_binary(slope_vector_decrease_binary < 0) = 1;
for row = 2:nRows
    if (((slope_vector_decrease_binary(row-1))+(slope_vector_decrease_binary(row))) == 1)
        slope_vector_decrease_StartStop(row) = time(row);
    else slope_vector_decrease_StartStop(row) = 0;
    end
end

slope_vector_decrease_StartStop(slope_vector_decrease_StartStop==0) = [];
slope_vector_decrease_StartStop_matrix = vec2mat(slope_vector_decrease_StartStop,2);
slope_vector_decrease_StartStop_matrix(:,2)=slope_vector_decrease_StartStop_matrix(:,2)-1;
slope_vector_decrease_StartStop_matrix_size = size(slope_vector_decrease_StartStop_matrix,1);

delta_decrease_vector = zeros(nRows,1);
for row = 1:slope_vector_decrease_StartStop_matrix_size
    if (slope_vector_decrease_StartStop_matrix(row,2)-slope_vector_decrease_StartStop_matrix(row,1)) > 5
        delta_decrease_vector(slope_vector_decrease_StartStop_matrix(row,2)) = data(slope_vector_decrease_StartStop_matrix(row,1)) - data(slope_vector_decrease_StartStop_matrix(row,2));
    end
end

delta_increase_vector_binary = delta_increase_vector;
delta_increase_vector_binary(delta_increase_vector_binary <= (low_conductance_signal_amp + peak_to_peak_noise)) = 0;
delta_increase_vector_binary(delta_increase_vector_binary > (low_conductance_signal_amp + peak_to_peak_noise)) = 1;

delta_decrease_vector_binary = delta_decrease_vector;
delta_decrease_vector_binary(delta_decrease_vector_binary <= (low_conductance_signal_amp + peak_to_peak_noise)) = 0;
delta_decrease_vector_binary(delta_decrease_vector_binary > (low_conductance_signal_amp + peak_to_peak_noise)) = 1;

for row = 1:inout_1_binary_v1_StartStop_matrix_size
    if (sum(delta_increase_vector_binary(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2)))) + (sum(delta_decrease_vector_binary(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2)))) >= 3
        inout_1_evaluationvector(inout_1_binary_v1_StartStop_matrix(row,1)+(round((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))./4))) = (1-(1/(((sum(delta_increase_vector_binary(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2)))) + (sum(delta_decrease_vector_binary(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2)))))/((inout_1_binary_v1_StartStop_matrix(row,2)-inout_1_binary_v1_StartStop_matrix(row,1))/250))))*10;
    end
end

inout_1_evaluationvector_vDIncrease = inout_1_evaluationvector;
inout_1_evaluationvector_vDIncrease = inout_1_evaluationvector_vDIncrease - inout_1_evaluationvector_vSlope - inout_1_evaluationvector_vClosing;

inout_1_evaluationvector_binary = inout_1_evaluationvector;
inout_1_evaluationvector_binary(inout_1_evaluationvector_binary > 0) = 1;

inout_eval_sum = zeros(nRows,1);
for row = 1:inout_1_binary_v1_StartStop_matrix_size
    if (sum(inout_1_evaluationvector_binary(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))) > 1)
        inout_eval_sum(inout_1_binary_v1_StartStop_matrix(row,1)) = (1+sum(inout_1_evaluationvector_vClosing(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))))*(1+sum(inout_1_evaluationvector_vSlope(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))))*(1+sum(inout_1_evaluationvector_vDIncrease(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))));
    end
end




for row = 1:inout_1_binary_v1_StartStop_matrix_size
    if (sum(inout_eval_sum(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2))) > 10)
        mastervector(inout_1_binary_v1_StartStop_matrix(row,1):inout_1_binary_v1_StartStop_matrix(row,2)) = 2;
    end
end

inout_1_sure = mastervector;
inout_1_sure(inout_1_sure ~= 2) = 0;
inout_1_sure(inout_1_sure > 0) = 1;

inout_1_evaluationvector(inout_1_evaluationvector == 0) = NaN;

%% detect outout_2

outout_2 = data;
outout_2(outout_2 > baseline + low_conductance_signal_amp*2 + peak_to_peak_noise) = 0;
outout_2(outout_2 < baseline + low_conductance_signal_amp*2 - peak_to_peak_noise) = 0;

outout_2_lower = ones(nRows,1);
outout_2_lower = outout_2_lower*-(baseline + low_conductance_signal_amp*2 + peak_to_peak_noise);
outout_2_upper = ones(nRows,1);
outout_2_upper = outout_2_upper*-(baseline + low_conductance_signal_amp*2 - peak_to_peak_noise);



% All peaks that are not outout_2_and_inout_1 positive, drives down in both directions
% and remove outout_2_and_inout_1.

for row = 2:nRows
    if ((outout_2(row) < data(row-1)) && (outout_2(row-1) == 0))
        outout_2(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((outout_2(row) < data(row+1)) && (outout_2(row+1) == 0))
        outout_2(row) = 0;
    end
end

outout_2_binary = outout_2;
outout_2_binary(outout_2_binary > 0) = 1;
outout_2_binary_v2a = outout_2_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (outout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_2_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (outout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_2_binary(row-1) = 1;
    end
end

for row = 2:nRows
    if (((outout_2_binary(row-1))+(outout_2_binary(row))) == 1)
        outout_2_binary_StartStop(row) = time(row);
    else outout_2_binary_StartStop(row) = 0;
    end
end

ligate_blocker_outout_2 = data;
ligate_blocker_outout_2(ligate_blocker_outout_2 < (baseline + low_conductance_signal_level_1)) = 90;
ligate_blocker_outout_2(ligate_blocker_outout_2 < (baseline + peak_to_peak_noise*2 + low_conductance_signal_amp*2)) = 0;
ligate_blocker_outout_2(ligate_blocker_outout_2 == 90) = -25;
ligate_blocker_outout_2(ligate_blocker_outout_2 >= (baseline + peak_to_peak_noise*2 + low_conductance_signal_amp*2)) = 50;
ligate_blocker_outout_2 = ligate_blocker_outout_2 + low_conductance_signal_level_1_binary_v4 + inout_1_sure;
ligate_blocker_outout_2(ligate_blocker_outout_2 > 0) = 50;
ligate_blocker_outout_2(ligate_blocker_outout_2 < -20) = 25;

outout_2_binary_StartStop(outout_2_binary_StartStop==0) = [];
outout_2_binary_StartStop_matrix = vec2mat(outout_2_binary_StartStop,2);
outout_2_binary_StartStop_matrix(:,2)=outout_2_binary_StartStop_matrix(:,2)-1;
inout_1_binary_StartStop_matrix_size = size(outout_2_binary_StartStop_matrix,1);

outout_2_binary_v1 = outout_2_binary;

for row = 1:inout_1_binary_StartStop_matrix_size-1
    if (outout_2_binary_StartStop_matrix(row+1,1) - outout_2_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_outout_2(outout_2_binary_StartStop_matrix(row,2):outout_2_binary_StartStop_matrix(row+1,1)))) < ligate_thr_outout_2
        outout_2_binary_v1((outout_2_binary_StartStop_matrix(row,2)):(outout_2_binary_StartStop_matrix(row+1,1))) = 1;
    end
end

outout_2_binary_v2show = outout_2_binary_v1;
outout_2_binary_v2show(outout_2_binary_v2show < 0) = 0;

outout_2_binary_v2 = outout_2_binary_v1 - low_conductance_signal_level_1_binary_v4 - inout_1_sure;
outout_2_binary_v2(outout_2_binary_v2 < 0) = 0;

for row = 2:nRows
    if (((outout_2_binary_v2(row-1))+(outout_2_binary_v2(row))) == 1)
        outout_2_binary_v2_StartStop(row) = time(row);
    else outout_2_binary_v2_StartStop(row) = 0;
    end
end

outout_2_binary_v2_StartStop(outout_2_binary_v2_StartStop==0) = [];
outout_2_binary_v2_StartStop_matrix = vec2mat(outout_2_binary_v2_StartStop,2);
outout_2_binary_v2_StartStop_matrix(:,2)=outout_2_binary_v2_StartStop_matrix(:,2)-1;
outout_2_binary_v2_StartStop_matrix_size = size(outout_2_binary_v2_StartStop_matrix,1);

% outout_2 parametre

% closing frequency is the number of closings in a cluster normalized to
% the length of the cluster. Closings per 400 us. It is alocated to 
% outout_2_and_inout_1_evaluationvector so that less than 1 closing per 800
% us count -1, more count 1 and 1 per 400 us count 2.

outout_2_evaluationvector = zeros(nRows,1);
for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1)) > 5)
        outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,1)+(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./4))) = (1/(1+((0.1+sum(closing_vector(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))/((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))/250))))*10;
    end
end



outout_2_evaluationvector_vClosing = outout_2_evaluationvector;
% The slope_vector_threepoint system identifies points where three
% consecutive points increase by more than 8.

for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1)) > 5) && ((sum(slope_vector_threepoint_v2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))) > 0)
        outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,1)+(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./2.5))) = (1/(1+(((sum(slope_vector_threepoint_v2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))).^2)/(((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1)))))))*10;
    end
end

outout_2_evaluationvector_vSlope = outout_2_evaluationvector - outout_2_evaluationvector_vClosing;

% increase point
delta_increase_vector_v2 = (delta_increase_vector-low_conductance_signal_amp).^2;

delta_decrease_vector_v2 = (delta_decrease_vector-low_conductance_signal_amp).^2;


for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1)) > 5)
        outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,1)+(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./1.5)))  = (1/(1+(abs(((sum(delta_increase_vector_v2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))) + sum(delta_decrease_vector_v2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))/(((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))).^2.5)))))*10;
    end
end

outout_2_evaluationvector_vDIncrease = outout_2_evaluationvector - outout_2_evaluationvector_vClosing - outout_2_evaluationvector_vSlope;

% giver points til outout_2 for direkte kontakt med outout_1

outout_1_nabosize = 100; % number of data points required to be full neighbour

for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((sum(low_conductance_signal_level_1_binary_v4((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))) > (outout_1_nabosize - 75)) || (sum(low_conductance_signal_level_1_binary_v4(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize))) > (outout_1_nabosize - 75)))
        outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,2)-(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./3.5))) = ((1+sum(low_conductance_signal_level_1_binary_v4((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))))*(1+sum(low_conductance_signal_level_1_binary_v4(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize)))))/1000;
    end
end

outout_2_evaluationvector_vNabo = outout_2_evaluationvector - outout_2_evaluationvector_vClosing-outout_2_evaluationvector_vSlope-outout_2_evaluationvector_vDIncrease;

outout_2_close_inout = zeros(nRows,1);
for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((sum(inout_1_sure((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))) > (outout_1_nabosize - 75)) || (sum(inout_1_sure(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize))) > (outout_1_nabosize - 75)))
        outout_2_close_inout(outout_2_binary_v2_StartStop_matrix(row,2)-(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./3.5))) = ((1+sum(inout_1_sure((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))))*(1+sum(inout_1_sure(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize)))))/1000;
    end
end


outout_2_sumEval = zeros(nRows,1);

for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if (sum(outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))) > 0 
        outout_2_sumEval(outout_2_binary_v2_StartStop_matrix(row,1)) = ((1+sum(outout_2_evaluationvector_vDIncrease(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vSlope(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vClosing(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vNabo(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))))./(1+sum(outout_2_close_inout(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))));
    end
end


for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if (sum(outout_2_sumEval(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))) > 100)
        mastervector(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)) = 5;
    end
end

outout_2_sure = mastervector;
outout_2_sure(outout_2_sure ~= 5) = 0;
outout_2_sure(outout_2_sure > 0) = 1;


outout_2_evaluationvector_round2 = zeros(nRows,1);
for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if ((sum(outout_2_sure((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))) > (outout_1_nabosize - 75)) || (sum(outout_2_sure(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize))) > (outout_1_nabosize - 75)))
        outout_2_evaluationvector_round2(outout_2_binary_v2_StartStop_matrix(row,2)-(round((outout_2_binary_v2_StartStop_matrix(row,2)-outout_2_binary_v2_StartStop_matrix(row,1))./3.7))) = ((1+sum(outout_2_sure((outout_2_binary_v2_StartStop_matrix(row,1)-outout_1_nabosize):outout_2_binary_v2_StartStop_matrix(row,1))))*(1+sum(outout_2_sure(outout_2_binary_v2_StartStop_matrix(row,2):(outout_2_binary_v2_StartStop_matrix(row,2)+outout_1_nabosize)))))/10;
    end
end
outout_2_sumEval_v2 = zeros(nRows,1);

for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if (sum(outout_2_evaluationvector(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))) > 0 
        outout_2_sumEval_v2(outout_2_binary_v2_StartStop_matrix(row,1)) = (sum(outout_2_evaluationvector_round2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)))+1)*(1+sum(outout_2_evaluationvector_vDIncrease(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vSlope(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vClosing(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))))*(1+sum(outout_2_evaluationvector_vNabo(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))));
    end
end


for row = 1:outout_2_binary_v2_StartStop_matrix_size
    if (sum(outout_2_sumEval_v2(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2))) > 75)
        mastervector(outout_2_binary_v2_StartStop_matrix(row,1):outout_2_binary_v2_StartStop_matrix(row,2)) = 5;
    end
end

for row = 1:nRows
    if (mastervector(row) == 5) && (data(row) < (low_conductance_signal_amp + peak_to_peak_noise))
        mastervector(row) = 3;
    end
end

outout_2_evaluationvector(outout_2_evaluationvector==0) = NaN;


%% outout_1_inout_1


outout_1_inout_1 = data;
outout_1_inout_1(outout_1_inout_1 > baseline + high_conductance_signal_amp + low_conductance_signal_amp + peak_to_peak_noise) = 0;
outout_1_inout_1(outout_1_inout_1 < baseline + high_conductance_signal_amp + low_conductance_signal_amp - peak_to_peak_noise) = 0;

outout_1_inout_1_lower = ones(nRows,1);
outout_1_inout_1_lower = outout_1_inout_1_lower*-(baseline + high_conductance_signal_amp + low_conductance_signal_amp + peak_to_peak_noise);
outout_1_inout_1_upper = ones(nRows,1);
outout_1_inout_1_upper = outout_1_inout_1_upper*-(baseline + high_conductance_signal_amp + low_conductance_signal_amp - peak_to_peak_noise);


% All peaks that are not outout_1_inout_1 positive, drives down in both directions
% and remove outout_1_inout_1.

for row = 2:nRows
    if ((outout_1_inout_1(row) < data(row-1)) && (outout_1_inout_1(row-1) == 0))
        outout_1_inout_1(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((outout_1_inout_1(row) < data(row+1)) && (outout_1_inout_1(row+1) == 0))
        outout_1_inout_1(row) = 0;
    end
end

outout_1_inout_1_binary = outout_1_inout_1;
outout_1_inout_1_binary(outout_1_inout_1_binary > 0) = 1;
outout_1_inout_1_binary_v2a = outout_1_inout_1_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (outout_1_inout_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_1_inout_1_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (outout_1_inout_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_1_inout_1_binary(row-1) = 1;
    end
end


for row = 2:nRows
    if (((outout_1_inout_1_binary(row-1))+(outout_1_inout_1_binary(row))) == 1)
        outout_1_inout_1_binary_StartStop(row) = time(row);
    else outout_1_inout_1_binary_StartStop(row) = 0;
    end
end

ligate_blocker_outout_1_inout_1 = data;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 < (baseline + low_conductance_signal_amp - peak_to_peak_noise)) =  90;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 < (baseline + peak_to_peak_noise + high_conductance_signal_amp + low_conductance_signal_amp)) = 0;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 == 90) = -20;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 >= (baseline + peak_to_peak_noise + high_conductance_signal_amp + low_conductance_signal_amp)) = 100;
ligate_blocker_outout_1_inout_1 = ligate_blocker_outout_1_inout_1 + outout_2_sure;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 > 0) = 100;
ligate_blocker_outout_1_inout_1(ligate_blocker_outout_1_inout_1 < -10) = 10;


outout_1_inout_1_binary_StartStop(outout_1_inout_1_binary_StartStop==0) = [];
outout_1_inout_1_binary_StartStop_matrix = vec2mat(outout_1_inout_1_binary_StartStop,2);
outout_1_inout_1_binary_StartStop_matrix(:,2)=outout_1_inout_1_binary_StartStop_matrix(:,2)-1;
outout_1_inout_1_binary_StartStop_matrix_size = size(outout_1_inout_1_binary_StartStop_matrix,1);

outout_1_inout_1_binary_v1 = outout_1_inout_1_binary;

for row = 1:outout_1_inout_1_binary_StartStop_matrix_size-1
    if (outout_1_inout_1_binary_StartStop_matrix(row+1,1) - outout_1_inout_1_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_outout_1_inout_1(outout_1_inout_1_binary_StartStop_matrix(row,2):outout_1_inout_1_binary_StartStop_matrix(row+1,1)))) < ligate_thr_outout_1_inout_1
        outout_1_inout_1_binary_v1((outout_1_inout_1_binary_StartStop_matrix(row,2)):(outout_1_inout_1_binary_StartStop_matrix(row+1,1))) = 1;
    end
end

for row = 2:nRows
    if (((outout_1_inout_1_binary_v1(row-1))+(outout_1_inout_1_binary_v1(row))) == 1)
        outout_1_inout_1_binary_v1_StartStop(row) = time(row);
    else outout_1_inout_1_binary_v1_StartStop(row) = 0;
    end
end

outout_1_inout_1_binary_v1_StartStop(outout_1_inout_1_binary_v1_StartStop==0) = [];
outout_1_inout_1_binary_v1_StartStop_matrix = vec2mat(outout_1_inout_1_binary_v1_StartStop,2);
outout_1_inout_1_binary_v1_StartStop_matrix(:,2)=outout_1_inout_1_binary_v1_StartStop_matrix(:,2)-1;
outout_1_inout_1_binary_v1_StartStop_matrix_size = size(outout_1_inout_1_binary_v1_StartStop_matrix,1);

% points til outout_1_inout_1

outout_1_inout_1_evaluationvector = zeros(nRows,1);


for row = 1:outout_1_inout_1_binary_v1_StartStop_matrix_size
    if ((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1)) > 4)
        outout_1_inout_1_evaluationvector(outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-(round((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1))./4))) = (1-(1/((sum(slope_vector_threepoint_v2(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2))))/((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1))/30))))*10;
    end
end
outout_1_inout_1_evaluationvector(outout_1_inout_1_evaluationvector < 0) = 0.01;
outout_1_inout_1_evaluationvector_v1 = outout_1_inout_1_evaluationvector;



% number of "close to perfect" peaks per size

peakvector_outout_1_inout_1 = peakvector;
peakvector_outout_1_inout_1(peakvector_outout_1_inout_1 < (baseline + low_conductance_signal_amp + high_conductance_signal_amp - peak_to_peak_noise)) = 0;
peakvector_outout_1_inout_1(peakvector_outout_1_inout_1 > (baseline + low_conductance_signal_amp + high_conductance_signal_amp + peak_to_peak_noise)) = 0;
peakvector_outout_1_inout_1(peakvector_outout_1_inout_1 > 0) = 1;

for row = 1:outout_1_inout_1_binary_v1_StartStop_matrix_size
    if ((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1)) > 4)
        outout_1_inout_1_evaluationvector(outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-(round((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1))./2))) = (1-(1/(((sum(peakvector_outout_1_inout_1(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2)))))/((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1))^0.1))))*10;
    end
end
outout_1_inout_1_evaluationvector(outout_1_inout_1_evaluationvector < 0.1) = 0;
outout_1_inout_1_evaluationvector_v2 = outout_1_inout_1_evaluationvector-outout_1_inout_1_evaluationvector_v1;

% naboskab med outout_1 og inout_1 p� den ene og anden side

outout_1_inout_1_LargeCluster = outout_1_inout_1_binary;
for row = 1:outout_1_inout_1_binary_StartStop_matrix_size-1
    if (outout_1_inout_1_binary_StartStop_matrix(row+1,1) - outout_1_inout_1_binary_StartStop_matrix(row,2)) < ligate_thr_outout_1_inout_1_large
        outout_1_inout_1_LargeCluster((outout_1_inout_1_binary_StartStop_matrix(row,2)):(outout_1_inout_1_binary_StartStop_matrix(row+1,1))) = 1;
    end
end
for row = 2:nRows
    if (((outout_1_inout_1_LargeCluster(row-1))+(outout_1_inout_1_LargeCluster(row))) == 1)
        outout_1_inout_1_LargeCluster_StartStop(row) = time(row);
    else outout_1_inout_1_LargeCluster_StartStop(row) = 0;
    end
end

outout_1_inout_1_LargeCluster_StartStop(outout_1_inout_1_LargeCluster_StartStop==0) = [];
outout_1_inout_1_LargeCluster_StartStop_matrix = vec2mat(outout_1_inout_1_LargeCluster_StartStop,2);
outout_1_inout_1_LargeCluster_StartStop_matrix(:,2)=outout_1_inout_1_LargeCluster_StartStop_matrix(:,2)-1;
outout_1_inout_1_LargeCluster_StartStop_matrix_size = size(outout_1_inout_1_LargeCluster_StartStop_matrix,1);

outout_1_nabosize_large = 300; % number of data points required to be full neighbour
outout_1_inout_1_LargeCluster_v1 = outout_1_inout_1_LargeCluster;

for row = 1:outout_1_inout_1_LargeCluster_StartStop_matrix_size
    if (((sum(low_conductance_signal_level_1_binary_v4((outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_1_nabosize_large):outout_1_inout_1_LargeCluster_StartStop_matrix(row,1))) > (outout_1_nabosize_large - 250)) || (sum(low_conductance_signal_level_1_binary_v4((outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_1_nabosize_large)) > (outout_1_nabosize_large - 250))) && (((sum(inout_1_sure(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2):(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)+outout_1_nabosize_large))) > (outout_1_nabosize_large - 250))) || (sum(inout_1_sure(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)-outout_1_nabosize_large:(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)))) > (outout_1_nabosize_large - 250))))
        outout_1_inout_1_LargeCluster_v1(outout_1_inout_1_LargeCluster_StartStop_matrix(row,1):outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)) = 2;
    end
end
for row = 1:outout_1_inout_1_LargeCluster_StartStop_matrix_size
    if (((sum(inout_1_sure((outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_1_nabosize_large):outout_1_inout_1_LargeCluster_StartStop_matrix(row,1))) > (outout_1_nabosize_large - 250)) || (sum(inout_1_sure((outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_1_nabosize_large)) > (outout_1_nabosize_large - 250))) && (((sum(low_conductance_signal_level_1_binary_v4(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2):(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)+outout_1_nabosize_large))) > (outout_1_nabosize_large - 250))) || (sum(low_conductance_signal_level_1_binary_v4(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)-outout_1_nabosize_large:(outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)))) > (outout_1_nabosize_large - 250))))
        outout_1_inout_1_LargeCluster_v1(outout_1_inout_1_LargeCluster_StartStop_matrix(row,1):outout_1_inout_1_LargeCluster_StartStop_matrix(row,2)) = 2;
    end
end

for row = 1:outout_1_inout_1_binary_v1_StartStop_matrix_size
    if  outout_1_inout_1_LargeCluster_v1(outout_1_inout_1_binary_v1_StartStop_matrix(row,1)) == 2
        outout_1_inout_1_evaluationvector(outout_1_inout_1_binary_v1_StartStop_matrix(row,1)+(round((outout_1_inout_1_binary_v1_StartStop_matrix(row,2)-outout_1_inout_1_binary_v1_StartStop_matrix(row,1))./4))) = 2;
    end
end

outout_1_inout_1_evaluationvector_v3 = outout_1_inout_1_evaluationvector - outout_1_inout_1_evaluationvector_v2 - outout_1_inout_1_evaluationvector_v1;




outout_1_inout_1_sumEval = zeros(nRows,1);

for row = 1:outout_1_inout_1_binary_v1_StartStop_matrix_size
    if (sum(outout_1_inout_1_evaluationvector(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2)))) > 0 
        outout_1_inout_1_sumEval(outout_1_inout_1_binary_v1_StartStop_matrix(row,1)) = (1+sum(outout_1_inout_1_evaluationvector_v3(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2))))*(1+sum(outout_1_inout_1_evaluationvector_v2(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2))))*(1+sum(outout_1_inout_1_evaluationvector_v1(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2))));
    end
end


for row = 1:outout_1_inout_1_binary_v1_StartStop_matrix_size
    if (sum(outout_1_inout_1_sumEval(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2))) > 30)
        mastervector(outout_1_inout_1_binary_v1_StartStop_matrix(row,1):outout_1_inout_1_binary_v1_StartStop_matrix(row,2)) = 6;
    end
end



outout_1_inout_1_sure = mastervector;
outout_1_inout_1_sure(outout_1_inout_1_sure ~= 6) = 0;
outout_1_inout_1_sure(outout_1_inout_1_sure > 0) = 1;

for row = 1:nRows
    if (outout_1_inout_1_sure(row) == 1) && (low_conductance_signal_level_1_binary_v4(row) == 1)
        mastervector(row) = 3;
    end
end
for row = 1:nRows
    if (outout_1_inout_1_sure(row) == 1) && (inout_1_binary_v1(row) == 1)
        mastervector(row) = 2;
    end
end
for row = 1:nRows
    if (mastervector(row) == 6) && (data(row) < (peak_to_peak_noise))
        mastervector(row) = 0;
    end
end
for row = 1:nRows
    if (mastervector(row) == 6) && (data(row) < (low_conductance_signal_amp+peak_to_peak_noise))
        mastervector(row) = 3;
    end
end

outout_1_inout_1_evaluationvector(outout_1_inout_1_evaluationvector == 0) = NaN;



%% Inout_2

inout_2 = data;
inout_2(inout_2 > baseline + high_conductance_signal_amp *2 + peak_to_peak_noise) = 0;
inout_2(inout_2 < baseline + high_conductance_signal_amp *2 - peak_to_peak_noise) = 0;

inout_2_lower = ones(nRows,1);
inout_2_lower = inout_2_lower*-(baseline + high_conductance_signal_amp *2 + peak_to_peak_noise);
inout_2_upper = ones(nRows,1);
inout_2_upper = inout_2_upper*-(baseline + high_conductance_signal_amp *2 - peak_to_peak_noise);


% All peaks that are not outout_1_inout_1 positive, drives down in both directions
% and remove outout_1_inout_1.

for row = 2:nRows
    if ((inout_2(row) < data(row-1)) && (inout_2(row-1) == 0))
        inout_2(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((inout_2(row) < data(row+1)) && (inout_2(row+1) == 0))
        inout_2(row) = 0;
    end
end

inout_2_binary = inout_2;
inout_2_binary(inout_2_binary > 0) = 1;
inout_2_binary_v2a = inout_2_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (inout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        inout_2_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (inout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        inout_2_binary(row-1) = 1;
    end
end


for row = 2:nRows
    if (((inout_2_binary(row-1))+(inout_2_binary(row))) == 1)
        inout_2_binary_StartStop(row) = time(row);
    else inout_2_binary_StartStop(row) = 0;
    end
end

ligate_blocker_inout_2 = data;

ligate_blocker_inout_2(ligate_blocker_inout_2 < (baseline + peak_to_peak_noise + high_conductance_signal_amp *2)) = 0;

ligate_blocker_inout_2(ligate_blocker_inout_2 >= (baseline + peak_to_peak_noise + high_conductance_signal_amp *2)) = 25;
ligate_blocker_inout_2 = (ligate_blocker_inout_2 + low_conductance_signal_level_1_binary_v4 + outout_2_sure)*-1;
ligate_blocker_inout_2(ligate_blocker_inout_2 < 0) = 5;



inout_2_binary_StartStop(inout_2_binary_StartStop==0) = [];
inout_2_binary_StartStop_matrix = vec2mat(inout_2_binary_StartStop,2);
inout_2_binary_StartStop_matrix(:,2)=inout_2_binary_StartStop_matrix(:,2)-1;
inout_2_binary_StartStop_matrix_size = size(inout_2_binary_StartStop_matrix,1);

inout_2_binary_v1 = inout_2_binary;

for row = 1:inout_2_binary_StartStop_matrix_size-1
    if (inout_2_binary_StartStop_matrix(row+1,1) - inout_2_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_inout_2(inout_2_binary_StartStop_matrix(row,2):inout_2_binary_StartStop_matrix(row+1,1)))) < ligate_thr_inout_2
        inout_2_binary_v1((inout_2_binary_StartStop_matrix(row,2)):(inout_2_binary_StartStop_matrix(row+1,1))) = 1;
    end
end




for row = 2:nRows
    if (((inout_2_binary_v1(row-1))+(inout_2_binary_v1(row))) == 1)
        inout_2_binary_v1_StartStop(row) = time(row);
    else inout_2_binary_v1_StartStop(row) = 0;
    end
end

inout_2_binary_v1_StartStop(inout_2_binary_v1_StartStop==0) = [];
inout_2_binary_v1_StartStop_matrix = vec2mat(inout_2_binary_v1_StartStop,2);
inout_2_binary_v1_StartStop_matrix(:,2)=inout_2_binary_v1_StartStop_matrix(:,2)-1;
inout_2_binary_v1_StartStop_matrix_size = size(inout_2_binary_v1_StartStop_matrix,1);

% parameters that identify inout_2

% closing frequency is the number of closings in a cluster normalized to
% the length of the cluster. Closings per 400 us. It is alocated to 
% outout_2_and_inout_1_evaluationvector so that less than 1 closing per 800
% us count -1, more count 1 and 1 per 400 us count 2.

inout_2_evaluationvector = zeros(nRows,1);
for row = 1:inout_2_binary_v1_StartStop_matrix_size
    if ((inout_2_binary_v1_StartStop_matrix(row,2)-inout_2_binary_v1_StartStop_matrix(row,1)) > 100)
        inout_2_evaluationvector(inout_2_binary_v1_StartStop_matrix(row,1)+(round((inout_2_binary_v1_StartStop_matrix(row,2)-inout_2_binary_v1_StartStop_matrix(row,1))./2))) = (((sum(closing_vector_level_inout2(inout_2_binary_v1_StartStop_matrix(row,1):inout_2_binary_v1_StartStop_matrix(row,2)))))/(((inout_2_binary_v1_StartStop_matrix(row,2)-inout_2_binary_v1_StartStop_matrix(row,1))/250)))*2;
    end
end


% neighbour
inout_2_nabosize_large = 300; % number of data points required to be full neighbour

inout_1_bin = mastervector;
inout_1_bin(inout_1_bin ~= 2) = 0;
inout_1_bin(inout_1_bin > 0) = 1;

for row = 1:inout_2_binary_v1_StartStop_matrix_size
    if (((sum(inout_1_bin((inout_2_binary_v1_StartStop_matrix(row,1)-inout_2_nabosize_large):inout_2_binary_v1_StartStop_matrix(row,1))) > 1) || (sum(inout_1_bin((inout_2_binary_v1_StartStop_matrix(row,1)):inout_2_binary_v1_StartStop_matrix(row,1)+inout_2_nabosize_large)) > 1))) 
        inout_2_evaluationvector(inout_2_binary_v1_StartStop_matrix(row,1)+1) = (sum(inout_1_bin((inout_2_binary_v1_StartStop_matrix(row,1)-inout_2_nabosize_large):inout_2_binary_v1_StartStop_matrix(row,1))) + sum(inout_1_bin((inout_2_binary_v1_StartStop_matrix(row,1)):inout_2_binary_v1_StartStop_matrix(row,1)+inout_2_nabosize_large)))/100;
    end
end




for row = 1:inout_2_binary_v1_StartStop_matrix_size
    if (sum(inout_2_evaluationvector(inout_2_binary_v1_StartStop_matrix(row,1):inout_2_binary_v1_StartStop_matrix(row,2))) > 2)
        mastervector(inout_2_binary_v1_StartStop_matrix(row,1):inout_2_binary_v1_StartStop_matrix(row,2)) = 4;
    end
end

for row = 1:nRows
    if (mastervector(row) == 4) && (data(row) < low_conductance_signal_amp)
        mastervector(row) = 0;
    end
end
for row = 1:nRows
    if (mastervector(row) == 4) && (data(row) < high_conductance_signal_amp)
        mastervector(row) = 2;
    end
end






%%      Inout_2_Outout_1

outout_1_inout_2 = data;
outout_1_inout_2(outout_1_inout_2 > baseline + low_conductance_signal_amp  + high_conductance_signal_amp *2+ peak_to_peak_noise) = 0;
outout_1_inout_2(outout_1_inout_2 < baseline + low_conductance_signal_amp  + high_conductance_signal_amp *2- peak_to_peak_noise) = 0;

outout_1_inout_2_lower = ones(nRows,1);
outout_1_inout_2_lower = outout_1_inout_2_lower*-(baseline + low_conductance_signal_amp  + high_conductance_signal_amp*2 + peak_to_peak_noise);
outout_1_inout_2_upper = ones(nRows,1);
outout_1_inout_2_upper = outout_1_inout_2_upper*-(baseline + low_conductance_signal_amp  + high_conductance_signal_amp*2 - peak_to_peak_noise);


% All peaks that are not outout_2_inout_1 positive, drives down in both directions
% and remove outout_1_inout_1.

for row = 2:nRows
    if ((outout_1_inout_2(row) < data(row-1)) && (outout_1_inout_2(row-1) == 0))
        outout_1_inout_2(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((outout_1_inout_2(row) < data(row+1)) && (outout_1_inout_2(row+1) == 0))
        outout_1_inout_2(row) = 0;
    end
end

outout_1_inout_2_binary = outout_1_inout_2;
outout_1_inout_2_binary(outout_1_inout_2_binary > 0) = 1;
outout_1_inout_2_binary_v2a = outout_1_inout_2_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (outout_1_inout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_1_inout_2_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (outout_1_inout_2_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_1_inout_2_binary(row-1) = 1;
    end
end


for row = 2:nRows
    if (((outout_1_inout_2_binary(row-1))+(outout_1_inout_2_binary(row))) == 1)
        outout_1_inout_2_binary_StartStop(row) = time(row);
    else outout_1_inout_2_binary_StartStop(row) = 0;
    end
end

ligate_blocker_outout_1_inout_2 = data;

ligate_blocker_outout_1_inout_2(ligate_blocker_outout_1_inout_2 < (baseline + low_conductance_signal_amp  + high_conductance_signal_amp *2+ peak_to_peak_noise)) = 0;

ligate_blocker_outout_1_inout_2(ligate_blocker_outout_1_inout_2 >= (baseline + low_conductance_signal_amp  + high_conductance_signal_amp *2+ peak_to_peak_noise)) = 5;
ligate_blocker_outout_1_inout_2 = ligate_blocker_outout_1_inout_2 + ligate_blocker_inout_2 + low_conductance_signal_level_1_binary_v4 + outout_2_sure;
ligate_blocker_outout_1_inout_2(ligate_blocker_outout_1_inout_2 > 0) = 5;



outout_1_inout_2_binary_StartStop(outout_1_inout_2_binary_StartStop==0) = [];
outout_1_inout_2_binary_StartStop_matrix = vec2mat(outout_1_inout_2_binary_StartStop,2);
outout_1_inout_2_binary_StartStop_matrix(:,2)=outout_1_inout_2_binary_StartStop_matrix(:,2)-1;
outout_1_inout_2_binary_StartStop_matrix_size = size(outout_1_inout_2_binary_StartStop_matrix,1);

outout_1_inout_2_binary_v1 = outout_1_inout_2_binary;

for row = 1:outout_1_inout_2_binary_StartStop_matrix_size-1
    if (outout_1_inout_2_binary_StartStop_matrix(row+1,1) - outout_1_inout_2_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_outout_1_inout_2(outout_1_inout_2_binary_StartStop_matrix(row,2):outout_1_inout_2_binary_StartStop_matrix(row+1,1)))) < ligate_thr_inout_2_outout
        outout_1_inout_2_binary_v1((outout_1_inout_2_binary_StartStop_matrix(row,2)):(outout_1_inout_2_binary_StartStop_matrix(row+1,1))) = 1;
    end
end

for row = 2:nRows
    if (((outout_1_inout_2_binary_v1(row-1))+(outout_1_inout_2_binary_v1(row))) == 1)
        outout_1_inout_2_binary_v1_StartStop(row) = time(row);
    else outout_1_inout_2_binary_v1_StartStop(row) = 0;
    end
end

outout_1_inout_2_binary_v1_StartStop(outout_1_inout_2_binary_v1_StartStop==0) = [];
outout_1_inout_2_binary_v1_StartStop_matrix = vec2mat(outout_1_inout_2_binary_v1_StartStop,2);
outout_1_inout_2_binary_v1_StartStop_matrix(:,2)=outout_1_inout_2_binary_v1_StartStop_matrix(:,2)-1;
outout_1_inout_2_binary_v1_StartStop_matrix_size = size(outout_1_inout_2_binary_v1_StartStop_matrix,1);

% naboskab med outout_1 og inout_1 p� den ene og anden side

outout_1_inout_2_LargeCluster = outout_1_inout_2_binary_v1;
for row = 1:outout_1_inout_2_binary_v1_StartStop_matrix_size-1
    if (outout_1_inout_2_binary_v1_StartStop_matrix(row+1,1) - outout_1_inout_2_binary_v1_StartStop_matrix(row,2)) < ligate_thr_outout_1_inout_1_large
        outout_1_inout_2_LargeCluster((outout_1_inout_2_binary_v1_StartStop_matrix(row,2)):(outout_1_inout_2_binary_v1_StartStop_matrix(row+1,1))) = 1;
    end
end
for row = 2:nRows
    if (((outout_1_inout_2_LargeCluster(row-1))+(outout_1_inout_2_LargeCluster(row))) == 1)
        outout_1_inout_2_LargeCluster_StartStop(row) = time(row);
    else outout_1_inout_2_LargeCluster_StartStop(row) = 0;
    end
end

outout_1_inout_2_LargeCluster_StartStop(outout_1_inout_2_LargeCluster_StartStop==0) = [];
outout_1_inout_2_LargeCluster_StartStop_matrix = vec2mat(outout_1_inout_2_LargeCluster_StartStop,2);
outout_1_inout_2_LargeCluster_StartStop_matrix(:,2)=outout_1_inout_2_LargeCluster_StartStop_matrix(:,2)-1;
outout_1_inout_2_LargeCluster_StartStop_matrix_size = size(outout_1_inout_2_LargeCluster_StartStop_matrix,1);

outout_2_inout_1_nabosize_large = 300; % number of data points required to be full neighbour
outout_1_inout_2_eval = zeros(nRows,1);

inout_2_bin = mastervector;
inout_2_bin(inout_2_bin ~= 4) = 0;
inout_2_bin(inout_2_bin > 0) = 1;

for row = 1:outout_1_inout_2_LargeCluster_StartStop_matrix_size
    if (((sum(inout_2_bin((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))) > 1) || (sum(inout_2_bin((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)) > 1))) 
        outout_1_inout_2_eval((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))+1) = (sum(inout_2_bin((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))) + sum(inout_2_bin((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)))/25;
    end
end

outout_inout_bin = mastervector;
outout_inout_bin(outout_inout_bin ~= 6) = 0;
outout_inout_bin(outout_inout_bin > 0) = 1;

for row = 1:outout_1_inout_2_LargeCluster_StartStop_matrix_size
    if (((sum(outout_1_inout_1_sure((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))) > 1) || (sum(outout_1_inout_1_sure((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)) > 1))) 
        outout_1_inout_2_eval((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))+2) = (sum(outout_1_inout_1_sure((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1))) + sum(outout_1_inout_1_sure((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)):outout_1_inout_2_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)))/25;
    end
end



mastervector_c2 = zeros(nRows,1);

for row = 1:outout_1_inout_2_LargeCluster_StartStop_matrix_size
    if (sum(outout_1_inout_2_eval((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1):(outout_1_inout_2_LargeCluster_StartStop_matrix(row,2)))))) > 5
        mastervector_c2((outout_1_inout_2_LargeCluster_StartStop_matrix(row,1):(outout_1_inout_2_LargeCluster_StartStop_matrix(row,2)))) = 7;
    end
end

for row = 1:outout_1_inout_2_binary_v1_StartStop_matrix_size
    if  sum(mastervector_c2((outout_1_inout_2_binary_v1_StartStop_matrix(row,1)):(outout_1_inout_2_binary_v1_StartStop_matrix(row,2)))) > 0
        mastervector((outout_1_inout_2_binary_v1_StartStop_matrix(row,1)):(outout_1_inout_2_binary_v1_StartStop_matrix(row,2))) = 7;
    end
end


for row = 1:nRows
    if (mastervector(row) == 7) && (peakvector_bin(row) == 1) && (data(row) < (baseline + high_conductance_signal_amp *2 + peak_to_peak_noise)) && (data(row) > (baseline + high_conductance_signal_amp *2 - peak_to_peak_noise))
        mastervector(row) = -4;
    end
end
for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (mastervector(row) == -4) && (data(row) > high_conductance_signal_amp))
        mastervector(row+1) = -4;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (mastervector(row) == -4) && (data(row) > high_conductance_signal_amp))
        mastervector(row-1) = -4;
    end
end

for row = 1:nRows
    if (mastervector(row) == 7) && (peakvector_bin(row) == 1) && (data(row) < (baseline + high_conductance_signal_amp + low_conductance_signal_amp + peak_to_peak_noise)) && (data(row) > (baseline + high_conductance_signal_amp + low_conductance_signal_amp - peak_to_peak_noise))
        mastervector(row) = -6;
    end
end
for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (mastervector(row) == -6) && (data(row) > low_conductance_signal_amp))
        mastervector(row+1) = -6;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (mastervector(row) == -6) && (data(row) > low_conductance_signal_amp))
        mastervector(row-1) = -6;
    end
end

for row = 1:nRows
    if (mastervector(row) == 7) && (peakvector_bin(row) == 1) && (data(row) < (baseline + high_conductance_signal_amp + peak_to_peak_noise)) && (data(row) > (baseline + high_conductance_signal_amp - peak_to_peak_noise))
        mastervector(row) = -2;
    end
end
for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (mastervector(row) == -2) && (data(row) > peak_to_peak_noise))
        mastervector(row+1) = -2;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (mastervector(row) == -2) && (data(row) > peak_to_peak_noise))
        mastervector(row-1) = -2;
    end
end


mastervector(mastervector == -4) = 4;
mastervector(mastervector == -6) = 6;
mastervector(mastervector == -2) = 2;
%%      Outout_2_inout_1

outout_2_inout_1 = data;
outout_2_inout_1(outout_2_inout_1 > baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp + peak_to_peak_noise) = 0;
outout_2_inout_1(outout_2_inout_1 < baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp - peak_to_peak_noise) = 0;

outout_2_inout_1_lower = ones(nRows,1);
outout_2_inout_1_lower = outout_2_inout_1_lower*-(baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp + peak_to_peak_noise);
outout_2_inout_1_upper = ones(nRows,1);
outout_2_inout_1_upper = outout_2_inout_1_upper*-(baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp - peak_to_peak_noise);


% All peaks that are not outout_2_inout_1 positive, drives down in both directions
% and remove outout_1_inout_1.

for row = 2:nRows
    if ((outout_2_inout_1(row) < data(row-1)) && (outout_2_inout_1(row-1) == 0))
        outout_2_inout_1(row) = 0;
    end
end
for row = nRows-1:-1:1
    if ((outout_2_inout_1(row) < data(row+1)) && (outout_2_inout_1(row+1) == 0))
        outout_2_inout_1(row) = 0;
    end
end

outout_2_inout_1_binary = outout_2_inout_1;
outout_2_inout_1_binary(outout_2_inout_1_binary > 0) = 1;
outout_2_inout_1_binary_v2a = outout_2_inout_1_binary;

for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (outout_2_inout_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_2_inout_1_binary(row+1) = 1;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (outout_2_inout_1_binary(row) == 1) && (data(row) > peak_to_peak_noise))
        outout_2_inout_1_binary(row-1) = 1;
    end
end


for row = 2:nRows
    if (((outout_2_inout_1_binary(row-1))+(outout_2_inout_1_binary(row))) == 1)
        outout_2_inout_1_binary_StartStop(row) = time(row);
    else outout_2_inout_1_binary_StartStop(row) = 0;
    end
end

ligate_blocker_outout_2_inout_1 = data;

ligate_blocker_outout_2_inout_1(ligate_blocker_outout_2_inout_1 < (baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp + peak_to_peak_noise)) = 0;

ligate_blocker_outout_2_inout_1(ligate_blocker_outout_2_inout_1 >= (baseline + low_conductance_signal_amp *2 + high_conductance_signal_amp + peak_to_peak_noise)) = 25;
ligate_blocker_outout_2_inout_1 = (ligate_blocker_outout_2_inout_1 + ligate_blocker_inout_2 + low_conductance_signal_level_1_binary_v4 + outout_2_sure)*-1;
ligate_blocker_outout_2_inout_1(ligate_blocker_outout_2_inout_1 < 0) = 5;



outout_2_inout_1_binary_StartStop(outout_2_inout_1_binary_StartStop==0) = [];
outout_2_inout_1_binary_StartStop_matrix = vec2mat(outout_2_inout_1_binary_StartStop,2);
outout_2_inout_1_binary_StartStop_matrix(:,2)=outout_2_inout_1_binary_StartStop_matrix(:,2)-1;
outout_2_inout_1_binary_StartStop_matrix_size = size(outout_2_inout_1_binary_StartStop_matrix,1);

outout_2_inout_1_binary_v1 = outout_2_inout_1_binary;

for row = 1:outout_2_inout_1_binary_StartStop_matrix_size-1
    if (outout_2_inout_1_binary_StartStop_matrix(row+1,1) - outout_2_inout_1_binary_StartStop_matrix(row,2)) + (sum(ligate_blocker_outout_2_inout_1(outout_2_inout_1_binary_StartStop_matrix(row,2):outout_2_inout_1_binary_StartStop_matrix(row+1,1)))) < ligate_thr_inout_2
        outout_2_inout_1_binary_v1((outout_2_inout_1_binary_StartStop_matrix(row,2)):(outout_2_inout_1_binary_StartStop_matrix(row+1,1))) = 1;
    end
end

for row = 2:nRows
    if (((outout_2_inout_1_binary_v1(row-1))+(outout_2_inout_1_binary_v1(row))) == 1)
        outout_2_inout_1_binary_v1_StartStop(row) = time(row);
    else outout_2_inout_1_binary_v1_StartStop(row) = 0;
    end
end

outout_2_inout_1_binary_v1_StartStop(outout_2_inout_1_binary_v1_StartStop==0) = [];
outout_2_inout_1_binary_v1_StartStop_matrix = vec2mat(outout_2_inout_1_binary_v1_StartStop,2);
outout_2_inout_1_binary_v1_StartStop_matrix(:,2)=outout_2_inout_1_binary_v1_StartStop_matrix(:,2)-1;
outout_2_inout_1_binary_v1_StartStop_matrix_size = size(outout_2_inout_1_binary_v1_StartStop_matrix,1);


% naboskab med outout_1 og inout_1 p� den ene og anden side

outout_2_inout_1_LargeCluster = outout_2_inout_1_binary_v1;
for row = 1:outout_2_inout_1_binary_v1_StartStop_matrix_size-1
    if (outout_2_inout_1_binary_v1_StartStop_matrix(row+1,1) - outout_2_inout_1_binary_v1_StartStop_matrix(row,2)) < ligate_thr_outout_1_inout_1_large
        outout_2_inout_1_LargeCluster((outout_2_inout_1_binary_v1_StartStop_matrix(row,2)):(outout_2_inout_1_binary_v1_StartStop_matrix(row+1,1))) = 1;
    end
end
for row = 2:nRows
    if (((outout_2_inout_1_LargeCluster(row-1))+(outout_2_inout_1_LargeCluster(row))) == 1)
        outout_2_inout_1_LargeCluster_StartStop(row) = time(row);
    else outout_2_inout_1_LargeCluster_StartStop(row) = 0;
    end
end

outout_2_inout_1_LargeCluster_StartStop(outout_2_inout_1_LargeCluster_StartStop==0) = [];
outout_2_inout_1_LargeCluster_StartStop_matrix = vec2mat(outout_2_inout_1_LargeCluster_StartStop,2);
outout_2_inout_1_LargeCluster_StartStop_matrix(:,2)=outout_2_inout_1_LargeCluster_StartStop_matrix(:,2)-1;
outout_2_inout_1_LargeCluster_StartStop_matrix_size = size(outout_2_inout_1_LargeCluster_StartStop_matrix,1);

outout_2_inout_1_nabosize_large = 300; % number of data points required to be full neighbour
outout_2_inout_1_eval = zeros(nRows,1);

outout_2_bin = mastervector;
outout_2_bin(outout_2_bin ~= 5) = 0;
outout_2_bin(outout_2_bin > 0) = 1;

for row = 1:outout_2_inout_1_LargeCluster_StartStop_matrix_size
    if (((sum(outout_2_bin((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))) > 1) || (sum(outout_2_bin((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)) > 1))) 
        outout_2_inout_1_eval((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))+1) = (sum(outout_2_bin((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))) + sum(outout_2_bin((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)))/25;
    end
end

outout_inout_bin = mastervector;
outout_inout_bin(outout_inout_bin ~= 6) = 0;
outout_inout_bin(outout_inout_bin > 0) = 1;

for row = 1:outout_2_inout_1_LargeCluster_StartStop_matrix_size
    if (((sum(outout_1_inout_1_sure((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))) > 1) || (sum(outout_1_inout_1_sure((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)) > 1))) 
        outout_2_inout_1_eval((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))+2) = (sum(outout_1_inout_1_sure((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)-outout_2_inout_1_nabosize_large):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1))) + sum(outout_1_inout_1_sure((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)):outout_2_inout_1_LargeCluster_StartStop_matrix(row,1)+outout_2_inout_1_nabosize_large)))/25;
    end
end



mastervector_c1 = zeros(nRows,1);

for row = 1:outout_2_inout_1_LargeCluster_StartStop_matrix_size
    if (sum(outout_2_inout_1_eval((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1):(outout_2_inout_1_LargeCluster_StartStop_matrix(row,2)))))) > (sum(inout_2_evaluationvector((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1):(outout_2_inout_1_LargeCluster_StartStop_matrix(row,2))))))
        mastervector_c1((outout_2_inout_1_LargeCluster_StartStop_matrix(row,1):(outout_2_inout_1_LargeCluster_StartStop_matrix(row,2)))) = 8;
    end
end

for row = 1:outout_2_inout_1_binary_v1_StartStop_matrix_size-1
    if (sum(mastervector_c1((outout_2_inout_1_binary_v1_StartStop_matrix(row,1)):(outout_2_inout_1_binary_v1_StartStop_matrix(row,2)))) > 1)
        mastervector((outout_2_inout_1_binary_v1_StartStop_matrix(row,1)):(outout_2_inout_1_binary_v1_StartStop_matrix(row,2))) = 8;
    end
end

outout_2_inout_1_eval(outout_2_inout_1_eval == 0) = NaN;
inout_2_evaluationvector(inout_2_evaluationvector==0) = NaN;

%%      Outout_2_inout_2

for row = 1:nRows
    if data(row) > (baseline + high_conductance_signal_amp*2 + low_conductance_signal_amp*2 - peak_to_peak_noise)
        mastervector(row) = 11;
    end
end




%% misallocated outout_2


mis_outout_2 = mastervector;
mis_outout_2(mis_outout_2 ~= 5) = 0;
mis_outout_2(mis_outout_2 == 5) = 1;

for row = 2:nRows
    if (((mis_outout_2(row-1))+(mis_outout_2(row))) == 1)
        mis_outout_2_StartStop(row) = time(row);
    else mis_outout_2_StartStop(row) = 0;
    end
end

mis_outout_2_StartStop(mis_outout_2_StartStop==0) = [];
mis_outout_2_StartStop_matrix = vec2mat(mis_outout_2_StartStop,2);
mis_outout_2_StartStop_matrix(:,2)=mis_outout_2_StartStop_matrix(:,2)-1;
mis_outout_2_StartStop_matrix_size = size(mis_outout_2_StartStop_matrix,1);

mis_outout_2_nabosize_large = 200; % number of data points required to be full neighbour
mis_outout_2_sensitivity = 50;

mis_sure_inouts = mastervector;
mis_sure_inouts(mis_sure_inouts == 2) = -1;
mis_sure_inouts(mis_sure_inouts == 4) = -1;
mis_sure_inouts(mis_sure_inouts > 0) = 0;
mis_sure_inouts = mis_sure_inouts*-1;


for row = 1:mis_outout_2_StartStop_matrix_size
    if (sum(mis_sure_inouts((mis_outout_2_StartStop_matrix(row,1)-mis_outout_2_nabosize_large):mis_outout_2_StartStop_matrix(row,1))) > mis_outout_2_sensitivity) && (sum(mis_sure_inouts(mis_outout_2_StartStop_matrix(row,2):(mis_outout_2_StartStop_matrix(row,2)+mis_outout_2_nabosize_large))) > mis_outout_2_sensitivity)
        mastervector(mis_outout_2_StartStop_matrix(row,1):mis_outout_2_StartStop_matrix(row,2)) = 2;
    end
end
        
for row = 1:nRows-1
    if ((data(row) > data(row+1)) && (mastervector(row) == 2) && (data(row) > peak_to_peak_noise))
        mastervector(row+1) = 2;
    end
end
for row = nRows-1:-1:2
    if ((data(row) > data(row-1)) && (mastervector(row) == 2) && (data(row) > peak_to_peak_noise))
        mastervector(row-1) = 2;
    end
end



%% prepare plot

for row = 1:nRows
    if data(row) < peak_to_peak_noise
        mastervector(row) = 0;
    end
end

for row = 1:nRows
    if mastervector(row) == 2
        inout_1_plot(row) = data(row);
    else inout_1_plot(row) = 0;
    end
end
inout_1_plot(inout_1_plot == 0) = NaN;
for row = 1:nRows
    if mastervector(row) == 12
        inout_1_plot_v1(row) = data(row);
    else inout_1_plot_v1(row) = 0;
    end
end
inout_1_plot_v1(inout_1_plot_v1 == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 3
        outout_1_plot(row) = data(row);
    else outout_1_plot(row) = 0;
    end
end
outout_1_plot(outout_1_plot == 0) = NaN;
for row = 1:nRows
    if mastervector(row) == 13
        outout_1_plot_v1(row) = data(row);
    else outout_1_plot_v1(row) = 0;
    end
end
outout_1_plot_v1(outout_1_plot_v1 == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 5
        outout_2_plot(row) = data(row);
    else outout_2_plot(row) = 0;
    end
end
outout_2_plot(outout_2_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 6
        outout_1_inout_1_plot(row) = data(row);
    else outout_1_inout_1_plot(row) = 0;
    end
end
outout_1_inout_1_plot(outout_1_inout_1_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 10
        outout_3_plot(row) = data(row);
    else outout_3_plot(row) = 0;
    end
end
outout_3_plot(outout_3_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 4
        inout_2_plot(row) = data(row);
    else inout_2_plot(row) = 0;
    end
end
inout_2_plot(inout_2_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 8
        outout_2_inout_1_plot(row) = data(row);
    else outout_2_inout_1_plot(row) = 0;
    end
end
outout_2_inout_1_plot(outout_2_inout_1_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 7
        outout_1_inout_2_plot(row) = data(row);
    else outout_1_inout_2_plot(row) = 0;
    end
end
outout_1_inout_2_plot(outout_1_inout_2_plot == 0) = NaN;

for row = 1:nRows
    if mastervector(row) == 11
        outout_2_inout_2_plot(row) = data(row);
    else outout_2_inout_2_plot(row) = 0;
    end
end
outout_2_inout_2_plot(outout_2_inout_2_plot == 0) = NaN;



%% data output

inout_idialize_vector = mastervector;
inout_idialize_vector(inout_idialize_vector == 2) = -1;
inout_idialize_vector(inout_idialize_vector == 6) = -1;
inout_idialize_vector(inout_idialize_vector == 4) = -2;
inout_idialize_vector(inout_idialize_vector == 7) = -2;
inout_idialize_vector(inout_idialize_vector == 8) = -1;
inout_idialize_vector(inout_idialize_vector == 11) = -2;
inout_idialize_vector(inout_idialize_vector > 0) = 0;
inout_idialize_vector = inout_idialize_vector*-1;

outout_idialize_vector = mastervector;
outout_idialize_vector(outout_idialize_vector == 3) = -1;
outout_idialize_vector(outout_idialize_vector == 5) = -2;
outout_idialize_vector(outout_idialize_vector == 6) = -1;
outout_idialize_vector(outout_idialize_vector == 7) = -1;
outout_idialize_vector(outout_idialize_vector == 8) = -2;
outout_idialize_vector(outout_idialize_vector == 11) = -2;
outout_idialize_vector(outout_idialize_vector > 0) = 0;
outout_idialize_vector = outout_idialize_vector*-1;



%% plot

dist_1 = 185;
dist_2 = 90;
dist_3 = 30;


nRows_3 = size(in,1);
data_3 = in(1:nRows_3);
time_3 = (1:nRows_3)';

outout_1_lower = ones(nRows,1);
outout_1_lower = outout_1_lower*-peak_to_peak_noise;
outout_1_upper = ones(nRows,1);
outout_1_upper = outout_1_upper*-(low_conductance_signal_amp + peak_to_peak_noise);


low_conductance_signal_level_1_v2 = low_conductance_signal_level_1;
low_conductance_signal_level_1_v2(low_conductance_signal_level_1_v2 > 0) = 1;



outout_2_inout_1_eval(outout_2_inout_1_eval == 0) = NaN;
inout_2_evaluationvector(inout_2_evaluationvector==0) = NaN;


inout_1_evaluationvector_vClosing(inout_1_evaluationvector_vClosing == 0) = NaN;
inout_1_evaluationvector_vSlope(inout_1_evaluationvector_vSlope == 0) = NaN;
inout_1_evaluationvector_vDIncrease(inout_1_evaluationvector_vDIncrease == 0) = NaN;
inout_eval_sum(inout_eval_sum == 0) = NaN;

outout_2_evaluationvector_vClosing(outout_2_evaluationvector_vClosing==0) = NaN;
outout_2_evaluationvector_vNabo(outout_2_evaluationvector_vNabo==0) = NaN;
outout_2_evaluationvector_vSlope(outout_2_evaluationvector_vSlope==0) = NaN;
outout_2_evaluationvector_vDIncrease(outout_2_evaluationvector_vDIncrease==0) = NaN;

outout_1_inout_1_evaluationvector_v1(outout_1_inout_1_evaluationvector_v1==0) = NaN;
outout_1_inout_1_evaluationvector_v2(outout_1_inout_1_evaluationvector_v2==0) = NaN;
outout_1_inout_1_evaluationvector_v3(outout_1_inout_1_evaluationvector_v3==0) = NaN;
outout_1_inout_1_sumEval(outout_1_inout_1_sumEval==0) = NaN;

outout_2_evaluationvector_round2(outout_2_evaluationvector_round2==0) = NaN;
outout_2_sumEval(outout_2_sumEval == 0) = NaN;
outout_2_sumEval_v2(outout_2_sumEval_v2 == 0) = NaN;

inout_2_evaluationvector(inout_2_evaluationvector ==0) = NaN;

data(data==0)=NaN;
data_3(data_3==0)=NaN;

outout_1_lower(outout_1_lower>(data*-1)) = NaN;
outout_1_upper(outout_1_upper>(data*-1)) = NaN;
high_conductance_signal_level_1_lower(high_conductance_signal_level_1_lower>(data*-1)) = NaN;
high_conductance_signal_level_1_upper(high_conductance_signal_level_1_upper>(data*-1)) = NaN;
outout_2_lower(outout_2_lower>(data*-1)) = NaN;
outout_2_upper(outout_2_upper>(data*-1)) = NaN;
outout_1_inout_1_lower(outout_1_inout_1_lower>(data*-1)) = NaN;
outout_1_inout_1_upper(outout_1_inout_1_upper>(data*-1)) = NaN;
inout_2_lower(inout_2_lower>(data*-1)) = NaN;
inout_2_upper(inout_2_upper>(data*-1)) = NaN;
outout_2_inout_1_lower(outout_2_inout_1_lower>(data*-1)) = NaN;
outout_2_inout_1_upper(outout_2_inout_1_upper>(data*-1)) = NaN;

figure;
plot(outout_1_lower,'color',[141/250 36/250 21/250],'LineWidth',1.5)
hold on
plot(outout_1_upper,'color',[141/250 36/250 21/250],'LineWidth',1.5)
plot(high_conductance_signal_level_1_lower,'color',[105/250 151/250 47/250],'LineWidth',1.5)
plot(high_conductance_signal_level_1_upper,'color',[105/250 151/250 47/250],'LineWidth',1.5)
plot(outout_2_lower,'color',[0/250 111/250 105/250],'LineWidth',1.5)
plot(outout_2_upper,'color',[0/250 111/250 105/250],'LineWidth',1.5)
plot(outout_1_inout_1_lower,'color',[131/250 161/250 191/250],'LineWidth',1.5)
plot(outout_1_inout_1_upper,'color',[131/250 161/250 191/250],'LineWidth',1.5)
plot(inout_2_lower,'color',[209/250 183/250 0/250],'LineWidth',1.5)
plot(inout_2_upper,'color',[209/250 183/250 0/250],'LineWidth',1.5)
plot(outout_2_inout_1_lower,'color',[127/250 104/250 39/250],'LineWidth',1.5)
plot(outout_2_inout_1_upper,'color',[127/250 104/250 39/250],'LineWidth',1.5)
plot(outout_1_inout_2_lower,'color',[188/250 75/250 123/250],'LineWidth',1.5)
plot(outout_1_inout_2_upper,'color',[188/250 75/250 123/250],'LineWidth',1.5)

plot(data*-1,'color',[50/250 50/250 50/250])



plot(low_conductance_signal_level_1_v2*-4-100,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(low_conductance_signal_level_1_binary_v4*-4-100,'color',[141/250 36/250 21/250],'LineWidth',1.5)


plot(high_conductance_signal_level_1_binary_v2*-4-108,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(inout_1_binary_v1*-4-108,'color',[105/250 151/250 47/250],'LineWidth',1.5)
%plot(((inout_1_evaluationvector_vSlope-10)*-1)-115,'+','color',[100/250 100/250 100/250],'MarkerSize',6,'LineWidth',1.5)
%plot(((inout_1_evaluationvector_vClosing-10)*-1)-115,'x','color',[50/250 50/250 50/250],'MarkerSize',6,'LineWidth',2)
%plot(((inout_1_evaluationvector_vClosing-10)*-1)-115,'x','color',[150/250 150/250 150/250],'MarkerSize',6,'LineWidth',1)
%plot(((inout_1_evaluationvector_vDIncrease-10)*-1)-115,'o','color',[50/250 50/250 50/250],'MarkerSize',4,'LineWidth',1.5)


plot(outout_2_binary_v2a*-4-116,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(outout_2_binary_v2show*-4-116,'color',[0/250 111/250 105/250],'LineWidth',1.5)
%plot(((outout_2_evaluationvector_vClosing-10)*-1)-130,'x','color',[50/250 50/250 50/250],'MarkerSize',6,'LineWidth',2)
%plot(((outout_2_evaluationvector_vClosing-10)*-1)-130,'x','color',[150/250 150/250 150/250],'MarkerSize',6,'LineWidth',1)
%plot(((outout_2_evaluationvector_vNabo-10)*-1)-130,'.','color',[0/250 0/250 0/250],'MarkerSize',6)
%plot(((outout_2_evaluationvector_vSlope-10)*-1)-130,'+','color',[100/250 100/250 100/250],'MarkerSize',6,'LineWidth',1.5)
%plot(((outout_2_evaluationvector_vDIncrease-10)*-1)-130,'o','color',[50/250 50/250 50/250],'MarkerSize',4,'LineWidth',1.5)




plot(outout_1_inout_1_binary_v2a*-4-124,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(outout_1_inout_1_binary_v1*-4-124,'color',[131/250 161/250 191/250],'LineWidth',1.5)


plot(inout_2_binary_v2a*-4-132,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(inout_2_binary_v1*-4-132,'color',[209/250 183/250 0/250],'LineWidth',1.5)


plot(outout_2_inout_1_binary_v2a*-4-140,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(outout_2_inout_1_binary_v1*-4-140,'color',[127/250 104/250 39/250],'LineWidth',1.5)


plot(outout_1_inout_2_binary_v2a*-4-148,'color',[150/250 150/250 150/250],'LineWidth',0.3)
plot(outout_1_inout_2_binary_v1*-4-148,'color',[188/250 75/250 123/250],'LineWidth',1.5)


plot(data*-1-dist_1,'color',[50/250 50/250 50/250])
plot(outout_1_plot*-1-dist_1,'color',[141/250 36/250 21/250])
plot(inout_1_plot*-1-dist_1,'color',[105/250 151/250 47/250])
plot(outout_1_plot_v1*-1-dist_1,'color',[141/250 36/250 21/250])
plot(inout_1_plot_v1*-1-dist_1,'color',[105/250 151/250 47/250])
plot(outout_2_plot*-1-dist_1,'color',[0/250 111/250 105/250])
plot(outout_1_inout_1_plot*-1-dist_1,'color',[131/250 161/250 191/250])
plot(inout_2_plot*-1-dist_1,'color',[209/250 183/250 0/250])
plot(outout_2_inout_1_plot*-1-dist_1,'color',[127/250 104/250 39/250])
plot(outout_1_inout_2_plot*-1-dist_1,'color',[188/250 75/250 123/250])
plot(outout_2_inout_2_plot*-1-dist_1,'color',[0/250 0/250 0/250])


% reference bars
Y_1 = (1:100);

hline_X1 = zeros(100,1);
hline_X1(hline_X1==0)=30;
plot(Y_1,hline_X1,'r')
hline_X1 = zeros(100,1);
hline_X1(hline_X1==0)=0;
plot(Y_1,hline_X1,'r')

plot((inout_idialize_vector*-10)-dist_1-dist_2,'color',[50/250 50/250 50/250],'LineWidth',1.5)
plot((outout_idialize_vector*-10)-dist_1-dist_2-dist_3,'color',[50/250 50/250 50/250],'LineWidth',1.5)

slope_vector_threepoint_v2(slope_vector_threepoint_v2==0) = NaN;
plot(slope_vector_threepoint_v2*5,'.','color',[141/250 36/250 21/250],'MarkerSize',4)

