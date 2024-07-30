function [CNAV, SOW] = CNAV_decoder(CNAV, channel_spc)
%����CNAV�Ľ�����CRCУ��͵��Ľ��

%% ����ת��
rawBits = zeros(1,670);
for i=1:20
    bits_str = dec2bin(channel_spc.Msg_CNAV_prev(i),32);
    bits_double = double(bits_str-'0');
    rawBits(30*(i-1)+(1:30)) = bits_double(32:-1:3);
end
for i=1:2
    bits_str = dec2bin(channel_spc.Msg_CNAV(i),32);
    bits_double = double(bits_str-'0');
    rawBits(600+30*(i-1)+(1:30)) = bits_double(32:-1:3);
end
bits_str = dec2bin(channel_spc.Msg_CNAV(3),32);
bits_double = double(bits_str-'0');
rawBits(661:670) = bits_double(32:-1:23);
%������ʱʹ�õļĴ�����ʼ״̬Ϊ�㣬��˶�ǰ12�����������⴦��
rawBits(1:12) = [1 1 1 0   1 1 1 1   1 1 1 1]; 

%% ������У��
trellis = poly2trellis(7,[171 133]);
cnavBits = vitdec(rawBits, trellis, 35, 'cont', 'hard'); %Ĭ��·������ȡ35��Ϊ���������Ƴ��ȵ��屶
cnavBits = cnavBits(36:end); %������300bits���С�ǰ35λ���������0����Ҫȥ��

g = [1 1 0 0 0   0 1 1 0 0   1 0 0 1 1   0 0 1 1 1   1 1 0 1 1];  %У��λ���ɶ���ʽg(x) 24->0 ��������

cnav_check = cnavBits;
for i=1:276
    if (cnav_check(i))
        cnav_check(i:i+24) = mod( cnav_check(i:i+24)+g, 2);
    end
end
parity = cnav_check(277:300);
if (sum(parity)>0) 
    fprintf('\tCRC check failed! PRN = %2d\n', channel_spc.PRNID);
    SOW = -1; %��Ч����ֵ
    return; %��У��ʧ�ܣ������н��
end

%% ���Ľ��
ephReceiveFlag = 0;

prn = channel_spc.PRNID;
bits = char(cnavBits+'0'); %ת�ַ�������

messageID = bin2dec(bits(15:20));
SOW = bin2dec(bits(21:37));

switch messageID
    
    case 10 %���� part 1
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);         
        ephReceiveFlag = 1;
        
        if ( 0==mod(CNAV.ephemeris(prn).updateLevel,2) )  %ȡĩλ
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 1;
        end
    
    case 11 %���� part 2
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);       
        ephReceiveFlag = 1;
        
        if ( mod(floor(CNAV.ephemeris(prn).updateLevel/2),2)==0 ) %����1λȡĩλ�õ�����״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 2;
        end       
        
    case 30 %ʱ�ӡ�IONO��Group delay
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
        
        CNAV.ISC(prn).ISC_ready = 1;
        if (strcmp(bits(128:140),'1000000000000'))
            CNAV.ISC(prn).T_GD       = 0;
        else
            CNAV.ISC(prn).T_GD       = twosComp2dec(bits(128:140))*2^(-35);
        end
        if (strcmp(bits(141:153),'1000000000000'))
            CNAV.ISC(prn).ISC_L1CA   = 0;
        else
            CNAV.ISC(prn).ISC_L1CA   = twosComp2dec(bits(141:153))*2^(-35);
        end
        if (strcmp(bits(154:166),'1000000000000'))
            CNAV.ISC(prn).ISC_L2C    = 0;
        else
            CNAV.ISC(prn).ISC_L2C    = twosComp2dec(bits(154:166))*2^(-35);
        end
        if (strcmp(bits(167:179),'1000000000000'))
            CNAV.ISC(prn).ISC_L5I5   = 0;
        else
            CNAV.ISC(prn).ISC_L5I5   = twosComp2dec(bits(167:179))*2^(-35);
        end
        if (strcmp(bits(180:192),'1000000000000'))
            CNAV.ISC(prn).ISC_L5Q5   = 0;
        else
            CNAV.ISC(prn).ISC_L5Q5   = twosComp2dec(bits(180:192))*2^(-35);
        end
        
        CNAV.IONO(prn).IONO_ready = 1;
        CNAV.IONO(prn).alpha0 = twosComp2dec(bits(193:200))*2^(-30);
        CNAV.IONO(prn).alpha1 = twosComp2dec(bits(201:208))*2^(-27);
        CNAV.IONO(prn).alpha2 = twosComp2dec(bits(209:216))*2^(-24);
        CNAV.IONO(prn).alpha3 = twosComp2dec(bits(217:224))*2^(-24);
        CNAV.IONO(prn).beta0  = twosComp2dec(bits(225:232))*2^11;
        CNAV.IONO(prn).beta1  = twosComp2dec(bits(233:240))*2^14;
        CNAV.IONO(prn).beta2  = twosComp2dec(bits(241:248))*2^16;
        CNAV.IONO(prn).beta3  = twosComp2dec(bits(249:256))*2^16;
        CNAV.IONO(prn).WN_OP  = 0; %unused
    
    case 31 %ʱ�ӡ���������
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
        
    case 32 %ʱ�ӡ�EOP
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
                
    case 33 %ʱ�ӡ�UTC
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
        
    case 34 %ʱ�ӡ������Ϣ
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
                
    case 35 %ʱ�ӡ�GGTO
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
                
    case 36 %ʱ�ӡ�Text
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
        
    case 37 %ʱ�ӡ��е�����
        CNAV.ephemeris(prn).ephUpdate = CNAV_get_eph( ...
            CNAV.ephemeris(prn).ephUpdate, bits, messageID);
        ephReceiveFlag = 1;
        if ( floor(CNAV.ephemeris(prn).updateLevel/4)==0 ) %����2λ�õ�ʱ�ӽ���״̬
            CNAV.ephemeris(prn).updateLevel = CNAV.ephemeris(prn).updateLevel + 4;
        end
        
    case 12 %��������
        
    case 13 %ʱ�Ӳ��
        
    case 14 %�������
        
    case 15 %Text
        
end

%% �����������³���
if (ephReceiveFlag)
    if (0==CNAV.ephemeris(prn).ephReady) %�״λ�ȡ������Ϣ
        if (7==CNAV.ephemeris(prn).updateLevel) %������������ʱ�Ӿ�������
            if (CNAV.ephemeris(prn).ephUpdate.t_oe_10 == CNAV.ephemeris(prn).ephUpdate.t_oe_11)
                %�����������ο�ʱ��Ҫ��ͬ�����������½���
                CNAV.ephemeris(prn).eph = CNAV.ephemeris(prn).ephUpdate;
                CNAV.ephemeris(prn).ephReady = 1;
            end
            CNAV.ephemeris(prn).updateLevel = 0;
        end
    else %����������Ϣ
        if (7==CNAV.ephemeris(prn).updateLevel)
            if (0==CNAV.ephemeris(prn).updating) %δ���ڸ���״̬           
                ephEqualFlag = CNAV_eph_compare(CNAV.ephemeris(prn).ephUpdate, CNAV.ephemeris(prn).eph);
                if (~ephEqualFlag) %�����ν��ղ���ͬ���������
                    CNAV.ephemeris(prn).ephRaid = CNAV.ephemeris(prn).ephUpdate;
                    CNAV.ephemeris(prn).updating = 1;
                end         
            else  %���ڼ�����״̬
                ephEqualFlag = CNAV_eph_compare(CNAV.ephemeris(prn).ephUpdate, CNAV.ephemeris(prn).ephRaid);
                if (ephEqualFlag) %�����յ�������ͬ��������Ϣ����ȷ�ϸ���,�����������
                    CNAV.ephemeris(prn).eph = CNAV.ephemeris(prn).ephUpdate;
                end
                CNAV.ephemeris(prn).updating = 0; %��ԭ��־λ
            end
            CNAV.ephemeris(prn).updateLevel = 0;
        end
    end   
end



