function [multiPara] = MP_process_auto(multiPara , sys, multipathNum, sheetName, timeIndex)


%%%%%%%%%%%%%%%%%%%%%%%%% �Զ�������������  %%%%%%%%%%%%%%%%%%%%
%%% ���²����Ļ�������timeInterval = 0.1; %%%%
grad_start_1 = 6; % ��ʼ���б������1
grad_start_2 = 1.5; % ��ʼ���б������1
var_start = 0.15; % ��ʼ���б������
endRange = 25; % ���(С)ֵ��������ֵ�ķ�Χ
grad_conti = 2; % ����������С�����ݶ�ɾ��
var_conti = 0.2; % ��б�ʵı������ж�
grad_less1s = 1.2; % 1s���ݵ���ʱб������
var_less1s = 0.2; % ��б�ʵı������ж�

%������������ȥ���ز���0��180�ȸ�����������������㡪��������������%
dopp_time_len = 30; % �ز���λ�жϵ���Чʱ��
dopp_grad = 25; % �ز�б��
dopp_range = 33; % ��180�����ҵĲ�����Χ
proba_dopp = 0.8; % ֻҪ�ٷ�֮proba�ĵ�������Ҫ�󼴿�
proba_rang = 28; %����ȡ���ʣ�Ҫ���ϸ�Щ
%������������ȥ���ز������ܵ͵Ķྶ����������������%
power_atten = 30;
%������������ȥ����ʱ���GEO�ྶ��������������������%
GEO_time_len = 100;
%����������������ȥ����ʱ��С�ĵ㡪������������������%
time_Delay = 18;
proba_delay = 0.75; % ֻҪ�ٷ�֮proba�ĵ�������Ҫ�󼴿�


%%%%%%%%%%%%%%%%%%%%%%%%% �Զ�������������  %%%%%%%%%%%%%%%%%%%%
timeDiv = 7; % ���ݰ���timeDiv/10��ָ�
%�������������������������������������������Զ����������ݡ�����������������������������������%
% ���������������������ݰ�0.5s�ָ������������������%
for i = 1 : multipathNum
    path_Num_1s = 0;
    for j = 1 : size(multiPara(i).pathIndex, 1)
        if (multiPara(i).pathIndex(j,2) - multiPara(i).pathIndex(j,1)) >= 10 % ɾ��С��1s������
            for k = (multiPara(i).pathIndex(j,1)+1):timeDiv:(multiPara(i).pathIndex(j,2)-timeDiv+1) % ����0.2�����ݣ���ֹ�ز���λͻ��
                path_Num_1s = path_Num_1s + 1;
                multiPara(i).pathIndex_1s(path_Num_1s,1) = k; %
                multiPara(i).pathIndex_1s(path_Num_1s,2) = k + timeDiv - 1;
            end
        end
    end
end
%���������������������������ݺϲ���������������������% pathIndex_Auto
for i = 1:multipathNum
    auto_Num = 0; % �����Ķྶ����
    running = 0; % �ж��Ƿ����ڼ�¼�ྶ����
    conti_flag = 0; % �ж�ԭʼ��������һ���Ƿ�����
    dopp_flag = 0; % �ж϶ྶ˥��Ƶ���Ƿ�ͨ��У��
    log_flag = 0; % �ж��Ƿ��¼�ྶ��
    power_flag = 0; % �ж�����˥��
    GEO_flag = 0; % �ж�GEO����ʱ�� / ȥ��С��n�������
    delay_flag = 0; % ɾ����ʱ��С�����ݵ�
    grad_conti_sign = [0, 0]; % ����λ�ݶȷ���[��һ�룬 ����]
    for j = 1:size(multiPara(i).pathIndex_1s, 1) % 1s���ݵ�ѭ������
        x_1s = multiPara(i).pathIndex_1s(j, 1);
        y_1s = multiPara(i).pathIndex_1s(j, 2);
        grads_1s = polyfit(timeIndex(x_1s:y_1s), multiPara(i).codeDelay(x_1s:y_1s), 1); % 1s���ݵ�б��
        delay_fit_1s = grads_1s(1)*timeIndex(x_1s:y_1s) + grads_1s(2); %��ʱ�����ֵ
        delay_fit_err_1s = multiPara(i).codeDelay(x_1s:y_1s) - delay_fit_1s;
        grad_conti_sign(1) = grad_conti_sign(2); % ������һ��ֵ
        if grads_1s(1) > 0
            grad_conti_sign(2) = 1;
        else
            grad_conti_sign(2) = -1;
        end
        max_1s = max(multiPara(i).codeDelay(x_1s:y_1s)); % 1s����������λ��ʱ���ֵ
        min_1s = min(multiPara(i).codeDelay(x_1s:y_1s)); % 1s����������λ��ʱ��Сֵ
        mean_1s = mean(multiPara(i).codeDelay(x_1s:y_1s)); % 1s����������λ��ʱƽ��ֵ
        var_fitErr_1s = var(delay_fit_err_1s) / (max_1s - min_1s);
        % �ж�ԭʼ��������һ���Ƿ�����
        if j < size(multiPara(i).pathIndex_1s, 1) % �������һ������
            if y_1s == (multiPara(i).pathIndex_1s(j+1,1)-1) % ��һ����������
                conti_flag = 1;
            else
                conti_flag = 0;
            end
        else
            conti_flag = 0;
        end
        
        % ��ʼ���ྶ����
        if running == 0
            % ��ʼ��⣬��ʼ������
            x_start = 0; % ���ּ�����ʼ��
            y_end = 0; % �յ�
            y_end_temp = 0; % ��ʱ�յ�
%             y_end_temp_1 = 0; % ��ʱ�յ����ʱ��
            log_flag = 0;
            dopp_flag = 0;
            power_flag = 0;
            GEO_flag = 0; % �ж�GEO����ʱ�� / ȥ��С��n�������
            grad_delay_flag = 0 ; %�жϽ���1s�����ݵ�����λб��
            delay_flag = 0; % ɾ����ʱ��С�����ݵ�
            grad_conti_sign(1) = 0; % ����λ�ݶȷ���[��һ�룬 ����]
            % ����߼���1�����ݶ�ֵС����ֵ��ʼ��¼
            if (abs(grads_1s(1))<grad_start_1 && var_fitErr_1s>var_start) || (abs(grads_1s(1))<grad_start_2)
                x_start = x_1s;
                y_end_temp = y_1s;
                running = 1;
            end
        end
       %������������������������������������������ʼ���������жϡ���������������������������������������% pathIndex_Auto
        if running == 1
            max_temp = max(multiPara(i).codeDelay(x_start:y_end_temp)); % ��ʱ����������λ��ʱ���ֵ
            min_temp = min(multiPara(i).codeDelay(x_start:y_end_temp)); % ��ʱ����������λ��ʱ��Сֵ
            mean_temp = mean(multiPara(i).codeDelay(x_start:y_end_temp)); % ��ʱ����������λ��ʱƽ��ֵ
            % ����߼���2����ǰ��ķ�ֵ���ܾ�ֵ�Ĳ������ֵ�����¼y_end_temp_1
            if (abs(max_1s - mean_temp)<endRange) && (abs(min_1s - mean_temp)<endRange)
                % ����߼���3��ɾ������������ݼ���ֵ����Ϊ�ǹ���״̬���˴��жϹ���״̬��������2����
                % 1������������������б�ʴ��ڶ�ֵ��     2�������ֵ��ķ���С�ڶ�ֵ
                if ~((abs(grads_1s(1))>=grad_conti) && (var_fitErr_1s<abs(var_conti*grads_1s(1))) &&...
                        ((grad_conti_sign(1)*grad_conti_sign(2)==1)||(grad_conti_sign(1)==0)))
                    y_end_temp = y_1s;
                end
                % ����߼���2��������ֵ����ֹͣ��¼����������һ�μ��
            else
                y_end = y_end_temp;
                log_flag = 1;% ������һ�μ��
                running = 0; % ������һ�μ��
            end
            % ԭʼ�����ж�
            if conti_flag == 0
                y_end = y_end_temp;
                log_flag = 1;
                running = 0; % ������һ�μ��
            end
        end % if start == 1
        
        % ���ݼ�¼
        if log_flag == 1 && y_end~=0
            % ���������������������ྶ˥��Ƶ�����޼�⣺����1������������������������
            if y_end - x_start > dopp_time_len
                % �ྶ�ز���λ��б��
                dopp_fad_temp = polyfit(timeIndex(x_start:y_end), multiPara(i).contiPhase(x_start:y_end), 1);
                % �ྶ�ز���λ��������
                N_cycle = round(mean(abs(multiPara(i).contiPhase(x_start:y_end))) / 180);
                % �ྶ�ز���λ�ļ�ֵ
                contiPhase_max = max(abs(multiPara(i).contiPhase(x_start:y_end)));
                contiPhase_min = min(abs(multiPara(i).contiPhase(x_start:y_end)));
                % �ྶ�ز���λ�ļ�ֵ��180���ܵĲ�ֵ�����ֵ
                contiPhase_N_cycle = max(abs(contiPhase_max-N_cycle*180), abs(contiPhase_min-N_cycle*180));
                if (dopp_fad_temp(1)<dopp_grad) && (contiPhase_N_cycle<dopp_range)
                    % �ྶ˥��Ƶ��У��δͨ��
                    dopp_flag = 1;
                end
            end
            % �����������������������ྶ˥��Ƶ�����޼�⣺����2������������������������
            if dopp_flag == 0
                % �ྶ�ز���λ��������
                contiPhase_mean = mean(abs(multiPara(i).contiPhase(x_start:y_end)));
                N_cycle = round(contiPhase_mean / 180);
                contiPhase_minus = abs(multiPara(i).contiPhase(x_start:y_end)) - 180 * N_cycle;
                target_Num = sum(abs(contiPhase_minus)<proba_rang); % ��180��������������
                proba_dopp_real = target_Num/(y_end - x_start + 1);
                if proba_dopp_real >= proba_dopp
                    % �ྶ˥��Ƶ��У��δͨ��
                    dopp_flag = 1;
                end
            end
            
            % ������������������������������GEOʱ���жϡ���������������������������
            if ((y_end-x_start)<GEO_time_len) && strcmp(sheetName, 'BDS_GEO')
                GEO_flag = 1;
            end
            
            % ��������������������������������1s�����������μ�⡪��������������������������
            if (y_end-x_start) < 15
                grads_temp = polyfit(timeIndex(x_start:y_end), multiPara(i).codeDelay(x_start:y_end), 1);
                delay_fit_temp = grads_temp(1)*timeIndex(x_start:y_end) + grads_temp(2); %��ʱ�����ֵ
                delay_fit_err_temp = multiPara(i).codeDelay(x_start:y_end) - delay_fit_temp;
                var_fitErr_temp = var(delay_fit_err_temp);
                if (abs(grads_temp(1))>grad_less1s) && (var_fitErr_temp<abs(var_less1s*grads_temp(1)))
                    grad_delay_flag = 1;
                end
            end
            
            %������������������������ɾ����ʱ����15�׵Ķྶ������������������������
            if strcmp(sys, 'BDS')
                time_Delay_thre = time_Delay;
            else
                time_Delay_thre = time_Delay * 1.7; % ���ǵ�GPS��Ƭ����
            end
            proba_delay_real = sum(multiPara(i).codeDelay(x_start:y_end)<time_Delay_thre) / (y_end-x_start+1);
            if proba_delay_real >= proba_delay
                delay_flag = 1;
            end
            
            % ���������������������������ྶ����˥�����޼�⡪����������������������
            if mean(multiPara(i).attenu(x_start:y_end))> power_atten
                power_flag = 1; %δͨ��
            end
            if dopp_flag == 0 && power_flag == 0 && GEO_flag == 0 && delay_flag == 0 && grad_delay_flag == 0
                % ���ݼ�¼
                auto_Num = auto_Num + 1;
                multiPara(i).pathIndex_Auto(auto_Num , 1) = x_start;
                multiPara(i).pathIndex_Auto(auto_Num , 2) = y_end;
            end
            log_flag = 0;
            
        end % if log_flag == 1 && y_end~=0
    end % for j = 1:size(multiPara(i).pathIndex_1s, 1) % 1s���ݵ�ѭ������
end % for i = 1:3