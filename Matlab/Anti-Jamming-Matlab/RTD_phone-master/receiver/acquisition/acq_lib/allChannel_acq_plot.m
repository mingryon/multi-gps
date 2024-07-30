function  allChannel_acq_plot(receiver,gpuExist)

global GSAR_CONSTANTS;
sampPerTC_1ms = round(GSAR_CONSTANTS.STR_RECV.fs * 1e-3);

channelAllNum = receiver.config.recvConfig.numberOfChannels(1).channelNumAll;
channelNum_BDS = 0;%BDSͨ������
channelNum_GPS = 0;%GPSͨ������

for i =1:channelAllNum
    if strcmp(receiver.channels(i).SYST,'BDS_B1I')
        channelNum_BDS = channelNum_BDS + 1;
    else
        channelNum_GPS = channelNum_GPS + 1;
    end
end


%for n = 1:channelAllNum
%    if strcmp(receiver.channels(n).SYST,'BDS_B1I')
    %------------------------------- BDS���ǲ�����ز��λ�ͼ ---------------------------------%
    if channelNum_BDS > 0
        chlist_bds = 1:channelNum_BDS;
        
        fid = fopen('..\data\BDS_B1I_acq_corr.bin','r+');
        flag_BDS_corr_UpdatedOrNot = fread(fid,1,'int8');%%% 1:�������ļ��Ѹ��� 0:�������ļ�δ����

        if flag_BDS_corr_UpdatedOrNot
           for i = 1:channelNum_BDS
                [PRNID,count] = fread(fid, 1, 'int8');
                if ~count %%%% countΪ0��˵������ʧ��
                    break;
                end

                for j = 1:channelNum_BDS
                    if PRNID == receiver.channels(chlist_bds(j)).CH_B1I(1).PRNID
                        if (receiver.channels(chlist_bds(j)).CH_B1I(1).acq.acqResults.acqed == 1)

                            corr_tmp = fread(fid,receiver.channels(chlist_bds(j)).CH_B1I(1).acq.freqSearch * sampPerTC_1ms,'double');
                            corr = zeros(receiver.channels(chlist_bds(j)).CH_B1I(1).acq.freqSearch,sampPerTC_1ms);
                            for k = 1:receiver.channels(chlist_bds(j)).CH_B1I(1).acq.freqSearch
                                corr(k,:) = corr_tmp((k-1)*sampPerTC_1ms+1 : k * sampPerTC_1ms,1);
                            end

                            acq_plot(receiver.channels(chlist_bds(j)).CH_B1I(1).CH_STATUS,...
                                     receiver.channels(chlist_bds(j)).SYST,corr,...
                                     receiver.channels(chlist_bds(j)).CH_B1I(1).acq.acqResults);

                            corr_tmp = [];
                            corr = [];
                            break;
                        end
                    end
                end
            end
        end
        fseek(fid, 0, 'bof');%%���ļ�ָ�붨λ����ʼλ��
        fwrite(fid, 0, 'int8');%%�޸��ļ����±�־λ��0��δ���£�
        fclose(fid);
    end
%    end%%end of if strcmp(SYST,'BDS_B1I')


% �����䡢�Ȳ���ͨ��
% ĿǰGPUģʽ�£�����Ҫ���䡢�Ȳ���ͨ���ֿ�
if gpuExist 
    channelNum_GPS_coldAcq = 0;
    channelNum_GPS_hotAcq = 0;
    u1 = 1;
    u2 = 1;
    if channelNum_GPS > 0
        chlist_gps = (channelNum_BDS+1):channelAllNum;
       for t = 1:channelNum_GPS
           if strcmp(receiver.channels(chlist_gps(t)).CH_L1CA(1).CH_STATUS, 'BIT_SYNC')
               channelNum_GPS_coldAcq = channelNum_GPS_coldAcq + 1;
               chlist_gps_coldAcq(u1) = t + channelNum_BDS;
               u1 = u1+1;
           else
               if strcmp(receiver.channels(chlist_gps(t)).CH_L1CA(1).CH_STATUS, 'HOT_BIT_SYNC')
                   channelNum_GPS_hotAcq = channelNum_GPS_hotAcq + 1;
                   chlist_gps_hotAcq(u2) = t + channelNum_BDS;
                   u2 = u2+1;
               end
           end

       end
    end
end

%    if strcmp(receiver.channels(n).SYST,'GPS_L1CA')
    % ------------------------ GPS���ǲ�����ز��λ�ͼ ------------------------------------%
    if(gpuExist)
        % �䲶��ͨ����������ͼ
        if channelNum_GPS_coldAcq > 0
            fid = fopen('..\data\GPS_L1CA_coldAcq_corr_vMULTICH.bin','r+');
            flag_GPS_corr_UpdatedOrNot = fread(fid,1,'int8');%%% 1:�������ļ��Ѹı� 0:�������ļ�δ�ı�

            if flag_GPS_corr_UpdatedOrNot
                for i = 1:channelNum_GPS_coldAcq
                    [PRNID,count] = fread(fid, 1, 'int8');
                    if ~count %%%% countΪ0��˵������ʧ��
                        break;
                    end

                    for j = 1:channelNum_GPS_coldAcq
                        if PRNID == receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).PRNID
                            if (receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).acq.acqResults.acqed == 1)
                                corr_tmp = fread(fid,receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).acq.freqSearch * sampPerTC_1ms,'float');
                                corr = zeros(receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).acq.freqSearch,sampPerTC_1ms);
                                for k = 1:receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).acq.freqSearch
                                    corr(k,:) = corr_tmp((k-1)*sampPerTC_1ms+1 : k * sampPerTC_1ms,1);
                                end

                                acq_plot(receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).CH_STATUS,...
                                         receiver.channels(chlist_gps_coldAcq(j)).SYST,corr,...
                                         receiver.channels(chlist_gps_coldAcq(j)).CH_L1CA(1).acq.acqResults);

                                corr_tmp = [];
                                corr = [];
                                break;
                            end
                        end
                    end
                end 
            end
            fseek(fid, 0, 'bof');%%���ļ�ָ�붨λ����ʼλ��
            fwrite(fid, 0, 'int8');
            fclose(fid);
        end
        % �Ȳ���ͨ����������ͼ
        if channelNum_GPS_hotAcq > 0
            fid = fopen('..\data\GPS_L1CA_hotAcq_corr_vMULTICH.bin','r+');
            flag_GPS_corr_UpdatedOrNot = fread(fid,1,'int8');%%% 1:�������ļ��Ѹı� 0:�������ļ�δ�ı�

            if flag_GPS_corr_UpdatedOrNot
                for i = 1:channelNum_GPS_hotAcq
                    [PRNID,count] = fread(fid, 1, 'int8');
                    if ~count %%%% countΪ0��˵������ʧ��
                        break;
                    end

                    for j = 1:channelNum_GPS_hotAcq
                        if PRNID == receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).PRNID
                            if (receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).acq.acqResults.acqed == 1)
                                corr_tmp = fread(fid,receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).acq.freqSearch * sampPerTC_1ms,'double');
                                corr = zeros(receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).acq.freqSearch,sampPerTC_1ms);
                                for k = 1:receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).acq.freqSearch
                                    corr(k,:) = corr_tmp((k-1)*sampPerTC_1ms+1 : k * sampPerTC_1ms,1);
                                end

                                acq_plot(receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).CH_STATUS,...
                                         receiver.channels(chlist_gps_hotAcq(j)).SYST,corr,...
                                         receiver.channels(chlist_gps_hotAcq(j)).CH_L1CA(1).acq.acqResults);

                                corr_tmp = [];
                                corr = [];
                                break;
                            end
                        end
                    end
                end 
            end
            fseek(fid, 0, 'bof');%%���ļ�ָ�붨λ����ʼλ��
            fwrite(fid, 0, 'int8');
            fclose(fid);
        end
    else
        if channelNum_GPS>0
            chlist_gps = (channelNum_BDS+1):channelAllNum;

            fid = fopen('..\data\GPS_L1CA_acq_corr.bin','r+');
            flag_GPS_corr_UpdatedOrNot = fread(fid,1,'int8');%%% 1:�������ļ��Ѹı� 0:�������ļ�δ�ı�

            if flag_GPS_corr_UpdatedOrNot
                for i = 1:channelNum_GPS
                    [PRNID,count] = fread(fid, 1, 'int8');
                    if ~count %%%% countΪ0��˵������ʧ��
                        break;
                    end

                    for j = 1:channelNum_GPS
                        if PRNID == receiver.channels(chlist_gps(j)).CH_L1CA(1).PRNID
                            if (receiver.channels(chlist_gps(j)).CH_L1CA(1).acq.acqResults.acqed == 1)
                                corr_tmp = fread(fid,receiver.channels(chlist_gps(j)).CH_L1CA(1).acq.freqSearch * sampPerTC_1ms,'double');
                                corr = zeros(receiver.channels(chlist_gps(j)).CH_L1CA(1).acq.freqSearch,sampPerTC_1ms);
                                for k = 1:receiver.channels(chlist_gps(j)).CH_L1CA(1).acq.freqSearch
                                    corr(k,:) = corr_tmp((k-1)*sampPerTC_1ms+1 : k * sampPerTC_1ms,1);
                                end

                                acq_plot(receiver.channels(chlist_gps(j)).CH_L1CA(1).CH_STATUS,...
                                         receiver.channels(chlist_gps(j)).SYST,corr,...
                                         receiver.channels(chlist_gps(j)).CH_L1CA(1).acq.acqResults);

                                corr_tmp = [];
                                corr = [];
                                break;
                            end
                        end
                    end
                end 
            end
            fseek(fid, 0, 'bof');%%���ļ�ָ�붨λ����ʼλ��
            fwrite(fid, 0, 'int8');
            fclose(fid);
        end
    end
%    end%%end of if strcmp(SYST,'GPS_L1CA')
%end%%EOF for n = 1:receiver.config.recvConfig.numberOfChannels(1).channelNumAll
