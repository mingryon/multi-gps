function [pvtCalculator, pvtForecast_Succ] = pvt_forecast_filt(SYST, pvtCalculator, recv_timer, config,parameter, Loop)

pvtForecast_Succ = 0;

% ���㵱ǰ���ջ�ʱ����ϴζ�λʱ�̵�ʱ���ֵ��ִ�иò����ǰ���ǽ��ջ�����ʱ���Ѿ�
if (recv_timer.recvSOW ~= -1) && (pvtCalculator.timeLast ~= -1) && (pvtCalculator.posiCheck > 0)
    timeDiff = recv_timer.recvSOW - pvtCalculator.timeLast;
    
    if timeDiff > pvtCalculator.maxInterval %�����ϴζ�λʱ���Ѿ�����Ԥ��ֵ������Ϊͨ��Ԥ���õ�λ����Ϣ�Ѿ���Ч
        pvtCalculator.positionValid = -1;
        pvtCalculator.posiCheck = -1;
        pvtCalculator.kalman.preTag = 0; %�����ʱ���޷�����㹻�����Ĺ۲���Ϣ����Ԥ���λ�ý������ɢ������ֵ֮�⣬��˽�����Kalman�˲�����־
    end
end

if (pvtCalculator.positionValid == 1) && (pvtCalculator.posiCheck >0)
    switch config.recvConfig.positionType
        case {00,100} % single-point least-square positioning mode
            pvtCalculator.posForecast(1:3) = pvtCalculator.posiLast(1:3) + pvtCalculator.positionVelocity(1:3) * timeDiff; % vector 3x1
            % Considering the accumulated clk error caused by the drifting
            % for both GPS and BDS systems
            pvtCalculator.clkErrForecast(1:2) = pvtCalculator.clkErr(1:2, 2) * timeDiff;
            
        case {01,101} % single-point Kalman positioning mode
            if pvtCalculator.kalman.preTag == 2 % preTag==2: the code ready for initialization
                % For the first time, we need initialize Kalman filter,
                % when both positionValid and posiCheck are 1.
                [pvtCalculator] = pvtEKF_init(SYST, pvtCalculator);
                pvtCalculator.kalman.preTag = 1;
            end
            
            if pvtCalculator.kalman.preTag == 1
                % Predict the positions and velocities
                pvtCalculator.kalman = pvtEKF_prediction(SYST, pvtCalculator.kalman,parameter, Loop);
                pvtCalculator.posForecast(1:3) = [pvtCalculator.kalman.stt_x(1), pvtCalculator.kalman.stt_y(1), pvtCalculator.kalman.stt_z(1)]';
                pvtCalculator.clkErrForecast(1:2) = pvtCalculator.kalman.stt_dtf(1, 1:2)';
%             nxtState = pvtCalculator.kalman.PHI * pvtCalculator.kalman.state;
%             pvtCalculator.posForecast(1:3) = nxtState(1:3);
%             pvtCalculator.kalman.state = nxtState;
%             pvtCalculator.kalman.P = pvtCalculator.kalman.PHI * pvtCalculator.kalman.P * (pvtCalculator.kalman.PHI).' + pvtCalculator.kalman.Qw;
            else
                pvtCalculator.posForecast(1:3) = pvtCalculator.posiLast(1:3) + pvtCalculator.positionVelocity(1:3) * timeDiff; % vector 3x1
                pvtCalculator.clkErrForecast(1:2) = pvtCalculator.clkErr(1:2, 2) * timeDiff;
            end
    end
    
    pvtForecast_Succ = 1;
end