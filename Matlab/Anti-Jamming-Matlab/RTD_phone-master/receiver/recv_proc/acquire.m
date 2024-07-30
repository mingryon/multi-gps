function [acqCHTable, channels] = acquire(config, acqCHTable, channels, satelliteTable, sis, N, MatlabAcq, gpuExist)

global GSAR_CONSTANTS;

fprintf('ACQUIRE PROC INFO:\n');
%----------------------�������������������ģ�飬���������б�----------------%
[acqCHTable, channels] = acquireCHTable_scheduler(config, acqCHTable, channels, N);

%acqEngineParallelNum = config.recvConfig.acqEngineParallelNum;  %����в�����
coldAcqEngineParallelNum = config.recvConfig.coldAcqEngineParallelNum; %������䲶��ͨ����
hotAcqEngineParallelNum = config.recvConfig.hotAcqEngineParallelNum;   %������Ȳ���ͨ����

% enableCH_Num = 0;  %�Ѽ���Ĳ���ͨ����
enableCH_Num_coldAcq = 0;  %�Ѽ�����䲶��ͨ����
enableCH_Num_hotAcq  = 0;  %�Ѽ�����Ȳ���ͨ����

%% ������������������������������������ʵ�ֱ�������ģ�顪����������������������������������
if (acqCHTable(1).coldAcqCHWaitNum + acqCHTable(1).hotAcqCHWaitNum) > 0 %There is waiting BDS channels for acquisition
%     if acqCHTable(1).acqCHWaitNum > acqEngineParallelNum
%         toactive_num = acqEngineParallelNum;
%     else
%         toactive_num = acqCHTable(1).acqCHWaitNum;
%     end
    if acqCHTable(1).hotAcqCHWaitNum > hotAcqEngineParallelNum
        toactive_num_hotAcq = hotAcqEngineParallelNum;
    else
        toactive_num_hotAcq = acqCHTable(1).hotAcqCHWaitNum;
    end
    toactive_chlist_hotAcq = acqCHTable(1).hotAcqCHWaitList(1:toactive_num_hotAcq);%�Ȳ���ͨ���б�
    
    if acqCHTable(1).coldAcqCHWaitNum > coldAcqEngineParallelNum
        toactive_num_coldAcq = coldAcqEngineParallelNum;
    else
        toactive_num_coldAcq = acqCHTable(1).coldAcqCHWaitNum;
    end
    toactive_chlist_coldAcq = acqCHTable(1).coldAcqCHWaitList(1:toactive_num_coldAcq);%�䲶��ͨ���б�
    
    toactive_num = toactive_num_coldAcq + toactive_num_hotAcq;
%     toactive_chlist = acqCHTable(1).acqCHWaitList(1:toactive_num);
    toactive_chlist = [toactive_chlist_hotAcq, toactive_chlist_coldAcq];%�䡢�Ȳ���ͨ���б�ϲ���ͬʱ�Ȳ����������䲶��
    channelList_BDS = channels(toactive_chlist');
    
    % ����ģ��
    if MatlabAcq
        channelList_BDS = acq_proc_multiCH('BDS_B1I', channelList_BDS, satelliteTable, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_B1}, N);      
        for i = 1:toactive_num
            channels(toactive_chlist(i)) = channelList_BDS(i);
        end
    else
        % sis_int = sis;
        for i=1:GSAR_CONSTANTS.STR_RECV.dataNum
            sis{i} = int8(sis{i});
        end
        channelList_BDS_tmp = cmex_acq_proc_multiCH('BDS_B1I', channelList_BDS, satelliteTable, toactive_num, config, sis, N, GSAR_CONSTANTS, gpuExist,config.recvConfig.acq_Batch1msN);
        % �������ظ�ֵ        
        for i = 1:toactive_num
            channelList_BDS(i).STATUS = channelList_BDS_tmp(i).STATUS;
            channelList_BDS(i).CH_B1I = acq_valueTransfer(channelList_BDS(i).CH_B1I, channelList_BDS_tmp(i).CH_B1I, 'BDS_B1I');
            channels(toactive_chlist(i)) = channelList_BDS(i);
        end
    end
     
    % Update enableCH_Num
    enableCH_Num_hotAcq = toactive_num_hotAcq;
    enableCH_Num_coldAcq = toactive_num_coldAcq;
%     acqCHTable(1).acqCHWaitNum = acqCHTable(1).acqCHWaitNum - toactive_num;
%     acqCHTable(1).acqCHWaitList = [acqCHTable(1).acqCHWaitList(toactive_num+1 : config.recvConfig.numberOfChannels(1).channelNum), zeros(1,toactive_num)];
    acqCHTable(1).coldAcqCHWaitNum = acqCHTable(1).coldAcqCHWaitNum - toactive_num_coldAcq;
    acqCHTable(1).coldAcqCHWaitList = [acqCHTable(1).coldAcqCHWaitList(toactive_num_coldAcq+1 :config.recvConfig.numberOfChannels(1).channelNum), zeros(1, toactive_num_coldAcq)];
    acqCHTable(1).hotAcqCHWaitNum = acqCHTable(1).hotAcqCHWaitNum - toactive_num_hotAcq;
    acqCHTable(1).hotAcqCHWaitList = [acqCHTable(1).hotAcqCHWaitList(toactive_num_hotAcq+1 :config.recvConfig.numberOfChannels(1).channelNum), zeros(1, toactive_num_hotAcq)];
    
end

%% ������������������������������������ʵ��GPS����ģ�顪����������������������������������
% isL1CA = zeros(1,acqCHTable(2).acqCHWaitNum);
% for i = 1:acqCHTable(2).acqCHWaitNum
%     isL1CA(i) = strcmp('GPS_L1CA',channels(acqCHTable(2).acqCHWaitList(i)).SYST);
% end
% isL1CA = logical(isL1CA);
% acqWaitList_L1CA = acqCHTable(2).acqCHWaitList(isL1CA);   %��Ƶͨ�����к�
% acqWaitList_L1L2 = acqCHTable(2).acqCHWaitList(~isL1CA);  %˫Ƶͨ�����к�
% acqWaitNum_L1CA = length(acqWaitList_L1CA);     %��Ƶͨ���ȴ�����
% acqWaitNum_L1L2 = length(acqWaitList_L1L2);     %˫Ƶͨ���ȴ�����

isL1CA_hotAcq = zeros(1,acqCHTable(2).hotAcqCHWaitNum);
isL1CA_coldAcq = zeros(1,acqCHTable(2).coldAcqCHWaitNum);
for i = 1:acqCHTable(2).hotAcqCHWaitNum
    isL1CA_hotAcq(i) = strcmp('GPS_L1CA',channels(acqCHTable(2).hotAcqCHWaitList(i)).SYST);
end
for i = 1:acqCHTable(2).coldAcqCHWaitNum
    isL1CA_coldAcq(i) = strcmp('GPS_L1CA',channels(acqCHTable(2).coldAcqCHWaitList(i)).SYST);
end
isL1CA_hotAcq = logical(isL1CA_hotAcq);
isL1CA_coldAcq = logical(isL1CA_coldAcq);
hotAcqWaitList_L1CA = acqCHTable(2).hotAcqCHWaitList(isL1CA_hotAcq);%�Ȳ���Ƶͨ��
hotAcqWaitList_L1L2 = acqCHTable(2).hotAcqCHWaitList(~isL1CA_hotAcq);%�Ȳ���˫Ƶͨ��
coldAcqWaitList_L1CA = acqCHTable(2).coldAcqCHWaitList(isL1CA_coldAcq);%�䲶��Ƶͨ��
coldAcqWaitList_L1L2 = acqCHTable(2).coldAcqCHWaitList(~isL1CA_coldAcq);%�䲶��˫Ƶͨ��
hotAcqWaitNum_L1CA = length(hotAcqWaitList_L1CA);
hotAcqWaitNum_L1L2 = length(hotAcqWaitList_L1L2);
coldAcqWaitNum_L1CA = length(coldAcqWaitList_L1CA);
coldAcqWaitNum_L1L2 = length(coldAcqWaitList_L1L2);

%����L1��Ƶͨ��
res_acqengineCHs_hotAcq = hotAcqEngineParallelNum - enableCH_Num_hotAcq; %ʣ����ò�����
res_acqengineCHs_coldAcq = coldAcqEngineParallelNum - enableCH_Num_coldAcq; %ʣ����ò�����
if (res_acqengineCHs_coldAcq + res_acqengineCHs_hotAcq)>0
    if (hotAcqWaitNum_L1CA + coldAcqWaitNum_L1CA) > 0 %There is waiting GPS_L1CA channels for acquisition
        if hotAcqWaitNum_L1CA > res_acqengineCHs_hotAcq
            toactive_num_hotAcq = res_acqengineCHs_hotAcq;
        else
            toactive_num_hotAcq = hotAcqWaitNum_L1CA;
        end   
        toactive_chlist_hotAcq = hotAcqWaitList_L1CA(1:toactive_num_hotAcq);
        
        if coldAcqWaitNum_L1CA > res_acqengineCHs_coldAcq
            toactive_num_coldAcq = res_acqengineCHs_coldAcq;
        else
            toactive_num_coldAcq = coldAcqWaitNum_L1CA;
        end   
        toactive_chlist_coldAcq = coldAcqWaitList_L1CA(1:toactive_num_coldAcq);
 
        toactive_chlist = [toactive_chlist_hotAcq, toactive_chlist_coldAcq];
        toactive_num = toactive_num_hotAcq + toactive_num_coldAcq;
        channelList_GPS_L1 = channels(toactive_chlist'); 
        
        % ����ģ��   
        if MatlabAcq  
            channelList_GPS_L1 = acq_proc_multiCH(...
                'GPS_L1CA', channelList_GPS_L1, satelliteTable, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L1}, N); %�䲶��
            
            channelList_GPS_L1 = fine_acq_proc_multiCH(...
                'GPS_L1CA', channelList_GPS_L1, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L1}, N) ; %������
            
            for i=1:toactive_num
                channels(toactive_chlist(i)) = channelList_GPS_L1(i);
            end
        else
            % sis_int = sis;
            for i=1:GSAR_CONSTANTS.STR_RECV.dataNum
                sis{i} = int8(sis{i});
            end
            channelList_GPS_L1_tmp = cmex_acq_proc_multiCH('GPS_L1CA', channelList_GPS_L1, satelliteTable, toactive_num, config, sis, N, GSAR_CONSTANTS,gpuExist,config.recvConfig.acq_Batch1msN);
            % �������ظ�ֵ
            for i = 1:toactive_num
                channelList_GPS_L1(i).STATUS = channelList_GPS_L1_tmp(i).STATUS;
                channelList_GPS_L1(i).CH_L1CA = acq_valueTransfer(channelList_GPS_L1(i).CH_L1CA, channelList_GPS_L1_tmp(i).CH_L1CA, 'GPS_L1CA');
                channels(toactive_chlist(i)) = channelList_GPS_L1(i);
            end
        end
        
        
        % Update enableCH_Num
        %enableCH_Num = enableCH_Num + toactive_num;
        enableCH_Num_hotAcq = enableCH_Num_hotAcq + toactive_num_hotAcq;
        enableCH_Num_coldAcq = enableCH_Num_coldAcq + toactive_num_coldAcq;
        %acqCHTable(2).acqCHWaitNum = acqCHTable(2).acqCHWaitNum - toactive_num;
        acqCHTable(2).hotAcqCHWaitNum = acqCHTable(2).hotAcqCHWaitNum - toactive_num_hotAcq;
        acqCHTable(2).coldAcqCHWaitNum = acqCHTable(2).coldAcqCHWaitNum - toactive_num_coldAcq;
%         for i=1:toactive_num  % �Ӳ����б���ȥ��,ĩ����
%             acqCHTable(2).acqCHWaitList( find(acqCHTable(2).acqCHWaitList == toactive_chlist(i)) ) = [];
%         end
        for i=1:toactive_num_hotAcq  % ���Ȳ����б���ȥ��,ĩ����
            acqCHTable(2).hotAcqCHWaitList( find(acqCHTable(2).hotAcqCHWaitList == toactive_chlist_hotAcq(i)) ) = [];
        end
        acqCHTable(2).hotAcqCHWaitList = [acqCHTable(2).hotAcqCHWaitList, zeros(1,toactive_num_hotAcq)];
         for i=1:toactive_num_coldAcq  % ���䲶���б���ȥ��,ĩ����
            acqCHTable(2).coldAcqCHWaitList( find(acqCHTable(2).coldAcqCHWaitList == toactive_chlist_coldAcq(i)) ) = [];
        end
        acqCHTable(2).coldAcqCHWaitList = [acqCHTable(2).coldAcqCHWaitList, zeros(1,toactive_num_coldAcq)];
    end
end

%����L1L2˫Ƶͨ��
res_acqengineCHs_hotAcq = hotAcqEngineParallelNum - enableCH_Num_hotAcq; %ʣ����ò�����
res_acqengineCHs_coldAcq = coldAcqEngineParallelNum - enableCH_Num_coldAcq; %ʣ����ò�����
if (res_acqengineCHs_coldAcq + res_acqengineCHs_hotAcq)>0
    if (hotAcqWaitNum_L1L2 + coldAcqWaitNum_L1L2) > 0 %There is waiting GPS_L1CA channels for acquisition
        if hotAcqWaitNum_L1L2 > res_acqengineCHs_hotAcq
            toactive_num_hotAcq = res_acqengineCHs_hotAcq;
        else
            toactive_num_hotAcq = hotAcqWaitNum_L1L2;
        end   
        toactive_chlist_hotAcq = hotAcqWaitList_L1L2(1:toactive_num_hotAcq);
        
        if coldAcqWaitNum_L1L2 > res_acqengineCHs_coldAcq
            toactive_num_coldAcq = res_acqengineCHs_coldAcq;
        else
            toactive_num_coldAcq = coldAcqWaitNum_L1L2;
        end   
        toactive_chlist_coldAcq = coldAcqWaitList_L1L2(1:toactive_num_coldAcq);   
        
        toactive_chlist = [toactive_chlist_hotAcq, toactive_chlist_coldAcq];
        toactive_num = toactive_num_hotAcq + toactive_num_coldAcq;
        channelList_GPS_L1L2 = channels(toactive_chlist'); 
        
        % ����ģ�� 
        if MatlabAcq
            channelList_GPS_L1L2 = acq_proc_multiCH(...  %L1����
                'GPS_L1CA_L2C', channelList_GPS_L1L2, satelliteTable, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L1}, N);

            channelList_GPS_L1L2 = fine_acq_proc_multiCH(...
                'GPS_L1CA_L2C', channelList_GPS_L1L2, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L1}, N) ; %������

            channelList_GPS_L1L2 = CM_acq_proc_multiCH(...
                channelList_GPS_L1L2, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L2},N); %CM�벶��

            channelList_GPS_L1L2 = CL_acq_proc_multiCH(...
                channelList_GPS_L1L2, toactive_num, config, sis{GSAR_CONSTANTS.STR_RECV.dataSource_L2},N); %CM�벶��

            for i=1:toactive_num
                channels(toactive_chlist(i)) = channelList_GPS_L1L2(i);
            end
        else
           % sis_int = sis;
            for i=1:GSAR_CONSTANTS.STR_RECV.dataNum
                sis{i} = int8(sis{i});
            end
            channelList_GPS_L1L2_tmp = cmex_acq_proc_multiCH(...
                'GPS_L1CA_L2C', channelList_GPS_L1L2, satelliteTable, toactive_num, config, sis, N, GSAR_CONSTANTS,gpuExist,config.recvConfig.acq_Batch1msN);
            % �������ظ�ֵ
            for i = 1:toactive_num
                channelList_GPS_L1L2(i).STATUS = channelList_GPS_L1L2_tmp(i).STATUS;
                channelList_GPS_L1L2(i).CH_L1CA_L2C = acq_valueTransfer(...
                    channelList_GPS_L1L2(i).CH_L1CA_L2C, channelList_GPS_L1L2_tmp(i).CH_L1CA_L2C, 'GPS_L1CA_L2C');
                channels(toactive_chlist(i)) = channelList_GPS_L1L2(i);
            end
        end
        
        % Update enableCH_Num
        %enableCH_Num = enableCH_Num + toactive_num;
        acqCHTable(2).hotAcqCHWaitNum = acqCHTable(2).hotAcqCHWaitNum - toactive_num_hotAcq;
        acqCHTable(2).coldAcqCHWaitNum = acqCHTable(2).coldAcqCHWaitNum - toactive_num_coldAcq;
        
        for i=1:toactive_num_hotAcq  % ���Ȳ����б���ȥ��,ĩ����
            acqCHTable(2).hotAcqCHWaitList( find(acqCHTable(2).hotAcqCHWaitList == toactive_chlist_hotAcq(i)) ) = [];
        end
        acqCHTable(2).hotAcqCHWaitList = [acqCHTable(2).hotAcqCHWaitList, zeros(1,toactive_num_hotAcq)];
         for i=1:toactive_num_coldAcq  % ���䲶���б���ȥ��,ĩ����
            acqCHTable(2).coldAcqCHWaitList( find(acqCHTable(2).coldAcqCHWaitList == toactive_chlist_coldAcq(i)) ) = [];
        end
        acqCHTable(2).coldAcqCHWaitList = [acqCHTable(2).coldAcqCHWaitList, zeros(1,toactive_num_coldAcq)];
    end
end

fprintf('  \n');

end

