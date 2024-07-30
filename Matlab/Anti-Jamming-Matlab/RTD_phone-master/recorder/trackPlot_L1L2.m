function trackPlot_L1L2(recorder, PRN)
%����̶�֡��ʽ����

filePath = recorder.trk_L1L2_package;
fileInfo = dir(filePath);

frameSize = 21; %Bytes per frame
LoopN = round(fileInfo.bytes / frameSize);

if (LoopN<1)
    return;
end


fid = fopen(filePath, 'r');

if (recorder.DEBUG_LEVEL>0)    
    data = fread(fid, frameSize*LoopN, 'double');
    data = reshape(data,frameSize,[]);
    
    %�ز����������
    Title = ['Carrier phase discriminator output, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(3,1,1);
    plot(data(1,:),180/pi*data(2,:));
    title('CA');
    xlabel('time / s');
    ylabel('degree');
    subplot(3,1,2);
    plot(data(1,:),180/pi*data(3,:));
    title('CM');
    xlabel('time / s');
    ylabel('degree');
    subplot(3,1,3);
    plot(data(1,:),180/pi*data(4,:));
    title('CL');
    xlabel('time / s');
    ylabel('degree');
    
    %CA�뻷·����ֵ
    Title = ['CA code correlator output, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(3,1,1);
    plot(data(1,:),data(5,:));
    title('I');
    xlabel('time / s');
    subplot(3,1,2);
    plot(data(1,:),data(8,:));
    title('Q');
    xlabel('time / s');
    subplot(3,1,3);
    plot(data(1,:),abs(data(5,:)+1i*data(8,:)) );
    title('Amplitude');
    xlabel('time / s');
    
    %CM�뻷·����ֵ
    Title = ['CM code correlator output, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(3,1,1);
    plot(data(1,:),data(6,:));
    title('I');
    xlabel('time / s');
    subplot(3,1,2);
    plot(data(1,:),data(9,:));
    title('Q');
    xlabel('time / s');
    subplot(3,1,3);
    plot(data(1,:),abs(data(6,:)+1i*data(9,:)) );
    title('Amplitude');
    xlabel('time / s');
    
    %CL�뻷·����ֵ
    Title = ['CL code correlator output, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(3,1,1);
    plot(data(1,:),data(7,:));
    title('I');
    xlabel('time / s');
    subplot(3,1,2);
    plot(data(1,:),data(10,:));
    title('Q');
    xlabel('time / s');
    subplot(3,1,3);
    plot(data(1,:),abs(data(7,:)+1i*data(10,:)) );
    title('Amplitude');
    xlabel('time / s');
    
    %���������
    Title = ['Doppler frequency, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(2,1,1);
    plot(data(1,:),data(11,:));
    title('L1');
    xlabel('time / s');
    ylabel('Hz');
    subplot(2,1,2);
    plot(data(1,:),data(12,:));
    title('L2');
    xlabel('time / s');
    ylabel('Hz');
    
    %�����ձ仯�����
    Title = ['Doppler frequency rate, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(2,1,1);
    plot(data(1,:),data(13,:));
    title('L1');
    xlabel('time / s');
    ylabel('Hz/s');
    subplot(2,1,2);
    plot(data(1,:),data(14,:));
    title('L2');
    xlabel('time / s');
    ylabel('Hz/s');
    
    %�뻷�������
    Title = ['Code phase discriminator output, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    subplot(3,1,1);
    plot(data(1,:),data(15,:));
    title('CA');
    xlabel('time / s');
    ylabel('chip');
    subplot(3,1,2);
    plot(data(1,:),data(16,:));
    title('CM');
    xlabel('time / s');
    ylabel('chip');
    subplot(3,1,3);
    plot(data(1,:),data(17,:));
    title('CL');
    xlabel('time / s');
    ylabel('degree');
    
    %����λ��ʱ���
    Title = ['L2-L1 code phase delay, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    plot(data(1,:),293.05*data(18,:));
    xlabel('time / s');
    ylabel('meters');
    
    %��������
    Title = ['CN0 estimate, GPS PRN = ', num2str(PRN)];
    figure('Name',Title, 'NumberTitle','off');
    plot(data(1,:),data(19:21,:));
    legend('CA','CM','CL');
    xlabel('time / s');
    ylabel('dB-Hz');
end

fclose(fid);


