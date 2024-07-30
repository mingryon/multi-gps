function channelList = acq_proc_multiCH(SYST, channelList, satelliteTable, listNum, config, sis, N)

for i = 1 : listNum
    
    switch SYST
        case 'GPS_L1CA'
            if (channelList(i).CH_L1CA.acq.ACQ_STATUS ~=0)  %�жϲ�����״̬
                break; 
            end;
            switch channelList(i).CH_L1CA.CH_STATUS
                case 'HOT_ACQ'
                    if channelList(i).CH_L1CA.acq.processing == -1
                        channelList(i).CH_L1CA.acq.STATUS = 'HOT';
                        % ����������Ϣ��������λ��������bit��Եλ�ã�ʹ�ò����������ʱ�����ɻ���
                        channelList(i).CH_L1CA.Samp_Posi = channelList(i).CH_L1CA.Samp_Posi + bitEdge(channelList(i).CH_L1CA, SYST);   % ע�⣺�˺���Ҫ��ÿ��ѭ���������ݴ���20ms������������
                        channelList(i).CH_L1CA.acq.processing = 0;
                    end
                    if channelList(i).CH_L1CA.Samp_Posi >= N
                        channelList(i).CH_L1CA.Samp_Posi = channelList(i).CH_L1CA.Samp_Posi - N;
                        channelList(i).CH_L1CA.acq.TimeLen = N;
                    else 
                        channelList(i) = acq_proc(config, channelList(i), satelliteTable, sis, N);
                    end
                case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
                    if channelList(i).CH_L1CA.acq.processing == -1
                        channelList(i).CH_L1CA.acq.processing = 0;
                    end
                    %channelList(i) = acq_proc(config, channelList(i), satelliteTable, sis, N); %�ɰ汾
                    channelList(i) = acq_l1ca_cold(config, channelList(i), satelliteTable, sis, N);         
            end   % EOF : switch channelList(i).CH_L1CA.CH_STATUS
            
        case 'GPS_L1CA_L2C'
            switch channelList(i).CH_L1CA_L2C.CH_STATUS
                case 'HOT_ACQ'
                    % ����������Ϣ��������λ��������bit��Եλ�ã�ʹ�ò����������ʱ�����ɻ���
                    if ( channelList(i).CH_L1CA_L2C.acq.processing == -1 )
                        channelList(i).CH_L1CA_L2C.Samp_Posi = channelList(i).CH_L1CA_L2C.Samp_Posi ...
                            + bitEdge(channelList(i).CH_L1CA_L2C, SYST);
                        channelList(i).CH_L1CA_L2C.acq.processing = 0;  %������������־λ��0
                    end
                    
                    if ( channelList(i).CH_L1CA_L2C.Samp_Posi >= N) %�����������������ȴ������´�ѭ��
                        channelList(i).CH_L1CA_L2C.Samp_Posi = channelList(i).CH_L1CA_L2C.Samp_Posi - N;
                        channelList(i).CH_L1CA_L2C.acq.TimeLen = channelList(i).CH_L1CA_L2C.acq.TimeLen + N;
                    else
                        channelList(i) = acq_l1ca_l2c_hot(config, channelList(i), sis, N);
                    end
                    
                case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
                    if (channelList(i).CH_L1CA_L2C.acq.ACQ_STATUS ~=0)  %�жϲ�����״̬
                        break;
                    end;
                    channelList(i) = acq_l1ca_cold(config, channelList(i), satelliteTable, sis, N);         
            end   % EOF : switch channelList(i).CH_L1CA.CH_STATUS
            
        case 'BDS_B1I'
            if (channelList(i).CH_B1I.acq.ACQ_STATUS ~=0)
                break;
            end;
            switch channelList(i).CH_B1I.CH_STATUS
                case 'HOT_ACQ' 
                    if channelList(i).CH_B1I.acq.processing == -1
                        channelList(i).CH_B1I.acq.STATUS = 'HOT';
                        % ����������Ϣ��������λ��������bit��Եλ�ã�ʹ�ò����������ʱ�����ɻ���
                        channelList(i).CH_B1I.Samp_Posi = channelList(i).CH_B1I.Samp_Posi + bitEdge(channelList(i).CH_B1I, SYST);   % ע�⣺�˺���Ҫ��ÿ��ѭ���������ݴ���20ms������������
                        channelList(i).CH_B1I.acq.processing = 0;
                    end
                    if channelList(i).CH_B1I.Samp_Posi >= N
                        channelList(i).CH_B1I.Samp_Posi = channelList(i).CH_B1I.Samp_Posi - N;
                    else 
                        channelList(i) = acq_proc(config, channelList(i), satelliteTable, sis, N);
                    end
                case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
                    if channelList(i).CH_B1I.acq.processing == -1
                        channelList(i).CH_L1CA.acq.processing = 0;
                    end
                    channelList(i) = acq_proc(config, channelList(i), satelliteTable, sis, N);     
            end    % EOF : switch channelList(i).CH_B1I.CH_STATUS
    end % EOF : switch SYST
end % EOF : for i = 1 : listNum

end % EOF : function