% Getting the signal-in-space data
function [signal, siscount, config] = GetSignal(signal, config, N)

global GSAR_CONSTANTS;
fileNum = GSAR_CONSTANTS.STR_RECV.fileNum; %�ܹ������ȡ���ļ�����
dataNum = GSAR_CONSTANTS.STR_RECV.dataNum; %�ܹ��洢����Ƶ�ź�cell����
signal.sis = cell(1,dataNum); %��ʼ�����⸳ֵ����

%% ��־�豸��֧��L1��B1Ƶ��ĸ�������������Ƶ�����ļ�
if signal.equipType == 1
    if GSAR_CONSTANTS.STR_RECV.DataSource > 0  % external data source
        
        if 0 == signal.fid(1)
            signal.fid(1) = fopen( GSAR_CONSTANTS.STR_RECV.datafilename{1} , 'rb');
            if (fseek(signal.fid(1), round(config.sisConfig.skipNumberOfBytes), 'bof') ~= 0)
                error('fseek operation at the beginning of GetSignal failed!');
            end
        end
        % Complex          
        [sis_temp, siscount] = fread(signal.fid(1), 2*N, GSAR_CONSTANTS.STR_RECV.dataType);
        signal.sis{1}(1,:) = sis_temp(1:2:end) + 1i*sis_temp(2:2:end);
        siscount = floor(siscount/2);
        
        config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + 2*N; %2*bit8

    else % internal signal genenrator
        error('Internal signal generator is not defined in this version!');
    end
end

%% Keda Device File Reading
% ���ݸ�ʽ˵����
% �����ʣ�100MHz    ����λ����4bit   L1: 37.42MHz     B1: 23.098MHz
% ÿ4092���ֽں󣬼�8184�������㣬����4���ֽڵ�У���
if signal.equipType == 2
    if GSAR_CONSTANTS.STR_RECV.DataSource > 0  % external data source
        
        checkNum = ceil((N-signal.headData)/8184) * 8; % У��λ��������,�ұ�֤��ֹ���У��λ
        numAll = checkNum + N; %����У��λ�Ĳ�������Ŀ
        for fN = 1:fileNum
            if 0 == signal.fid(fN)
                signal.fid(fN) = fopen( GSAR_CONSTANTS.STR_RECV.datafilename{fN} , 'rb');
                if (fseek(signal.fid(fN), floor(config.sisConfig.skipNumberOfBytes+0.1), 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end
                %�ϵ�����ʱ��Ҫ������ֽ�����
                if (rem(config.sisConfig.skipNumberOfBytes,1)>0.1)
                    fread(signal.fid(fN), 1, GSAR_CONSTANTS.STR_RECV.dataType);
                end        
            end
            [sis_temp(:,1), siscount] = fread(signal.fid(fN), numAll, GSAR_CONSTANTS.STR_RECV.dataType);
            
            tail_N = mod(siscount-signal.headData-8, 8192);
            sis_head = sis_temp(1:signal.headData);
            sis_tail = sis_temp(siscount-tail_N+1:end);
            sis_body = reshape( sis_temp(signal.headData+9:siscount-tail_N), 8192, [] );
            sis_body(8185:8192,:) = []; %ȥУ��λ
            signal.sis{fN}(1,:) = [ sis_head; reshape(sis_body,[],1); sis_tail ];
        end
        
        siscount = size(signal.sis,1);
        signal.headData = 8184 - tail_N;
        config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + N/2; %bit4
        
    else % internal signal genenrator
        error('Internal signal generator is not defined in this version!');
    end
    
end

%% ��վȥУ��λ����
% ���ݸ�ʽ˵����
% �����ʣ�100MHz    ����λ����4bit  real
if signal.equipType == 21
    
    if GSAR_CONSTANTS.STR_RECV.DataSource > 0  % external data source       
        for fN = 1:fileNum
            if 0 == signal.fid(fN)
                signal.fid(fN) = fopen( GSAR_CONSTANTS.STR_RECV.datafilename{fN} , 'rb');
                if (fseek(signal.fid(fN), floor(config.sisConfig.skipNumberOfBytes+0.1), 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end
                %�ϵ�����ʱ��Ҫ������ֽ�����
                if (rem(config.sisConfig.skipNumberOfBytes,1)>0.1)
                    fread(signal.fid(fN), 1, GSAR_CONSTANTS.STR_RECV.dataType);
                end
            end
            [signal.sis{fN}(1,:), siscount] = fread(signal.fid(fN), N, GSAR_CONSTANTS.STR_RECV.dataType);             
        end           
    else % internal signal genenrator
        error('Internal signal generator is not defined in this version!');
    end 
    
    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + N/2; %bit4
end

%% Sample Device File Reading
if signal.equipType == 3
    if GSAR_CONSTANTS.STR_RECV.DataSource > 0  % external data source
        
        for fN = 1:fileNum
            if 0 == signal.fid(fN)
                signal.fid(fN) = fopen( GSAR_CONSTANTS.STR_RECV.datafilename{fN} , 'rb');
                % File header 128byte
                if (fseek(signal.fid(fN), config.sisConfig.skipNumberOfBytes + 128, 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end    
            end

            if strcmp('Real', GSAR_CONSTANTS.STR_RECV.IQForm)
                [signal.sis{fN}(1,:), siscount] = fread(signal.fid(fN), N, GSAR_CONSTANTS.STR_RECV.dataType);
            else % Complex
                [sis_temp, siscount] = fread(signal.fid(fN), 2*N, GSAR_CONSTANTS.STR_RECV.dataType);
                signal.sis{fN}(1,:) = sis_temp(1:2:end) + 1i*sis_temp(2:2:end);
                siscount = floor(siscount/2);
            end
        end
    else % internal signal genenrator
        error('Internal signal generator is not defined in this version!');
    end
end %EOF "if signal.equipType == 3"

%% ��־ȫƵ������豸�������ļ���һ������Ƶ�����ݰ�һ��˳������
if signal.equipType == 4
    switch mod(signal.devSubtype, 10)
        case 0 %9Ƶ��ģʽ��������
            
        case {1,2,3,4,5} %4Ƶ��ģʽ
            if 0 == signal.fid(1)
                signal.fid(1) = fopen( GSAR_CONSTANTS.STR_RECV.datafilename{1} , 'rb');
                if (fseek(signal.fid(1), round(4*config.sisConfig.skipNumberOfBytes), 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end
            end
            [sis_temp, siscount] = fread(signal.fid(1), 4*N, GSAR_CONSTANTS.STR_RECV.dataType);
            signal.sis{1}(1,:) = sis_temp(1:4:end);
            signal.sis{2}(1,:) = sis_temp(2:4:end);
            signal.sis{3}(1,:) = sis_temp(3:4:end);
            signal.sis{4}(1,:) = sis_temp(4:4:end);
            siscount = floor(siscount/4);
            
            switch floor(signal.devSubtype/100)
                case 0 %4bits
                    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + 0.5*N;
                case 1 %8bits
                    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + N;
                case 2 %12bits
                    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + 1.5*N;
            end
            
    end
    
end %EOF "if signal.equipType == 3"

%% ��������  20M, 4bit, real
if signal.equipType == 100
    
    for fN = 1:fileNum
        if 0 == signal.fid(fN)
            signal.fid(fN) = fopen( cell2mat(GSAR_CONSTANTS.STR_RECV.datafilename(fN)) , 'rb');
                if (fseek(signal.fid(fN), floor(config.sisConfig.skipNumberOfBytes+0.1), 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end
                %�ϵ�����ʱ��Ҫ������ֽ�����
                if (rem(config.sisConfig.skipNumberOfBytes,1)>0.1)
                    fread(signal.fid(fN), 1, GSAR_CONSTANTS.STR_RECV.dataType);
                end   
        end
        [signal.sis{fN}(1,:), siscount] = fread(signal.fid(fN), N, GSAR_CONSTANTS.STR_RECV.dataType);         
    end
    
    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + N/2; %bit4
end

%% ��������2  16.384M, 8bit, real
if signal.equipType == 101
    
    for fN = 1:fileNum
        if 0 == signal.fid(fN)
            signal.fid(fN) = fopen( cell2mat(GSAR_CONSTANTS.STR_RECV.datafilename(fN)) , 'rb');
                if (fseek(signal.fid(fN), config.sisConfig.skipNumberOfBytes, 'bof') ~= 0)
                    error('fseek operation at the beginning of GetSignal failed!');
                end
 
        end
        [signal.sis{fN}(1,:), siscount] = fread(signal.fid(fN), N, GSAR_CONSTANTS.STR_RECV.dataType);         
    end
    
    config.sisConfig.skipNumberOfBytes = config.sisConfig.skipNumberOfBytes + N; %bit8
end
