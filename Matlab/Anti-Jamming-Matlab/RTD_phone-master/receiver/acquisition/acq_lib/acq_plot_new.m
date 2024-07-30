function acq_plot_new(SYST,array,fd_search,peak_freq_idx, peak_code_idx, sv)
% �䲶������ͼ

if strcmp(SYST,'BDS_B1I')
    Title = ['Acq BDS_B1I PRN=',num2str(sv)];
    %Len = 2046;
elseif strcmp(SYST,'GPS_L1CA')
    Title = ['Acq GPS_L1CA PRN=',num2str(sv)];
    %Len = 1023;
end
[~, sampN] = size(array);

figure('Name',Title,'NumberTitle','off');

% subplot(2,1,1);
% plot(Len*(0:sampN-1)/sampN, array(peak_freq_idx,:));
% xlabel('��Ƭ/samples');ylabel('���ֵ');
% set(gca,'FontSize',14); % �������ִ�С��ͬʱӰ���������ע��ͼ��������ȡ�
% set(get(gca,'XLabel'),'FontSize',14);%ͼ������Ϊ8 point��С5��
% set(get(gca,'YLabel'),'FontSize',14);

subplot(2,1,1);
plot((0:sampN-1), array(peak_freq_idx,:));
xlabel('����λ/samples');ylabel('���ֵ')
set(gca,'FontSize',14); % �������ִ�С��ͬʱӰ���������ע��ͼ��������ȡ�
set(get(gca,'XLabel'),'FontSize',14);%ͼ������Ϊ8 point��С5��
set(get(gca,'YLabel'),'FontSize',14);

subplot(2,1,2);
plot(fd_search,array(:,peak_code_idx));

xlabel('������Ƶ�� [Hz]');ylabel('���ֵ')
set(get(gca,'XLabel'),'FontSize',14);%ͼ������Ϊ8 point��С5��
set(get(gca,'YLabel'),'FontSize',14);

