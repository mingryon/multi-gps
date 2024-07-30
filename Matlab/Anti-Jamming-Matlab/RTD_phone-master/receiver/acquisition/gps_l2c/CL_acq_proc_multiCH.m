function channelList = CL_acq_proc_multiCH(channelList, listNum, config, sis, N)
% ��ͨ��CL�벶�����CM�벶����������

% ���ü򻯰��Ǽ丨����ʽ�������ͨ��ͬʱ����CL����ʱ����һ�ųɹ���������Ǽ�¼CL����λ��Ϣ�����Լ����������ǵĲ�����̡�
% ���ٵ������ǵ�ǰ�����㹻��ɲ�����̡���������GPU���в���
% CL_time��¼���ǵ�ǰ���ݿ���ʼ�ض�Ӧ��CL��ʱ�䣨0~1.5s������ʼ-1������Ч��
% �Ǽ丨����ǿ����Ҫά��һ���������ջ��ɼ���CL_time������ֻҪ������һ�����CL�벶������ǣ�������֡ͬ�������ǣ�����ʵ�ּ��١�Ŀǰδ���á�
CL_time = -1;  

for i = 1:listNum    
        
    switch channelList(i).STATUS
        case 'HOT_ACQ'
            break; %�Ȳ�����Ҫ
        case {'COLD_ACQ', 'COLD_ACQ_AGAIN'}
            if (channelList(i).CH_L1CA_L2C.acq.ACQ_STATUS == 3 )  %�жϲ�����״̬
                [channelList(i).CH_L1CA_L2C, channelList(i).STATUS, CL_time] = acq_l2cl_aid( ...
                    channelList(i).CH_L1CA_L2C, config, sis, N, channelList(i).bpSampling_OddFold, CL_time);
            end
    end
    
    if (strcmp('PULLIN',channelList(i).STATUS))  %����CL�벶����ɵ�ͨ�����ڴ˴�������ٳ�ʼ��
        channelList(i) = pullin_ini(channelList(i));
        channelList(i) = phase_ini(channelList(i));
    end            
    
end