function [peak_nc_corr, peak_freq_idx, peak_code_idx, th] = find2DPeakWithThre( corr_mt, mode )


[peak_corr_set, peak_freq_set] = max(corr_mt,[],1); %�ҳ�ÿ����λ�ķ�ֵ����������ֵ��Ӧ��Ƶ��
[peak_nc_corr, peak_code_idx] = max(peak_corr_set);  %��һ��ȷ����ֵ�еķ�ֵ��������ֵ��λ
peak_freq_idx = peak_freq_set(peak_code_idx);  %������ֵƵ��

switch mode
    case 'CM'
        %�ҳ�CM�����ֵ����������
        %corr_mt��ÿ����һ��Ƶ�ʣ�ÿ����һ����λ����20��
        corr_mt(:,peak_code_idx) = []; %ȥ����ֵ��λ��һ��
        th = peak_nc_corr/( mean(mean(corr_mt)) ); %�����ֵ��Ƿ�ֵ��ֵ�ı�������Ϊ���޲���
        
    case 'hotAcq'
        %�Ȳ�����ж�ά������Ѱ�ҷ�ֵ
        %��������ʱ�۳���ֵ��������������
        [freqN, codeN] = size(corr_mt);
        freqDelete =  mod( (peak_freq_idx-1:peak_freq_idx+1)-1,freqN )+1; %��Ҫɾ������
        codeDelete =  mod( (peak_code_idx-1:peak_code_idx+1)-1,codeN )+1; %��Ҫɾ������
        corr_mt(freqDelete,:) = [];
        corr_mt(:,codeDelete) = [];
        th = peak_nc_corr/( mean(mean(corr_mt)) );
end


