function channelList = CM_acq_proc_multiCH(channelList, listNum, config, sis, N)
% ��ͨ��CM�벶�����CA�벶����������

for i = 1:listNum
    
    switch channelList(i).STATUS
        case 'HOT_ACQ'
            break; %�Ȳ�����Ҫ
        case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
            if (channelList(i).CH_L1CA_L2C.acq.ACQ_STATUS == 2 )  %�жϲ�����״̬
                [channelList(i).CH_L1CA_L2C, channelList(i).STATUS] = ...
                    acq_l2cm_aid(channelList(i).CH_L1CA_L2C, config, sis, N, channelList(i).bpSampling_OddFold);
            end
    end
  
end