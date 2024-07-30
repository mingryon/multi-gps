function  channelList = fine_acq_proc_multiCH(SYST, channelList, listNum, config , sis, N)
% ��ͨ����������� L1,B1

for i = 1:listNum
    
    switch SYST
        case 'GPS_L1CA'         
                          
            switch channelList(i).STATUS
                case 'HOT_ACQ'
                    break;  %�Ȳ������辫��
                case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
                    if (channelList(i).CH_L1CA.acq.ACQ_STATUS ==1)  %�жϲ�����״̬
                        [channelList(i).CH_L1CA, channelList(i).STATUS] = ...
                            l1ca_fine_acq('GPS_L1CA',channelList(i).CH_L1CA, config, sis, N, channelList(i).bpSampling_OddFold);
                    end
            end
            
        case 'GPS_L1CA_L2C'  
            
            switch channelList(i).STATUS
                case 'HOT_ACQ'
                    break;
                case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
                    if (channelList(i).CH_L1CA_L2C.acq.ACQ_STATUS ==1)  %�жϲ�����״̬
                        [channelList(i).CH_L1CA_L2C, channelList(i).STATUS] = ...
                            l1ca_fine_acq('GPS_L1CA_L2C',channelList(i).CH_L1CA_L2C, config, sis, N, channelList(i).bpSampling_OddFold); %��GPS_L1CA���Ը��ã���MATLAB
                    end
            end
            
        case 'BDS_B1I' %������ʵ��
%             
%             switch channelList(i).STATUS
%                 case 'HOT_ACQ'
%                     break;
%                 case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
%                     if (channelList(i).CH_B1I.acq.ACQ_STATUS ==1)  %�жϲ�����״̬
%                         [channelList(i).CH_B1I, channelList(i).STATUS] = b1i_fine_acq(channelList(i).CH_B1I, config, sis, N, channelList(i).bpSampling_OddFold);
%                     end                     
%             end
                    
    end %EOF��switch SYST
    
end