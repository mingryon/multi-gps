function [ acc_filtered ] = acc_filter( acc,FS,Fpass )
%	input:  acc = 3*n
%   output: acc_filtered = 1*n
[~,FIR_B,N] = Lowpass_Equiripple(FS,Fpass); %calculate FIR coef �Ȳ������FIR�˲���
% acc_m = sum(acc.^2).^0.5;
acc_m = acc;
acc_filtered_delay  = filter(FIR_B,1,acc_m);%ת��2��FIR
sample_count = length(acc_m);
% delay of FIR: N->order of filter
% delay = N/2 (N is even);delay = (N-1)/2 (N is odd)
acc_filtered = acc_filtered_delay(floor(N/2):end); % first delay point is discarded
acc_filtered(end+1:sample_count) = mean(acc_filtered_delay);  % mean is used to fill at the end
end

