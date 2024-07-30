function [N, receiver, signal] = sigRead_N_Calc(receiver, signal)
global GSAR_CONSTANTS

if signal.Tunit > receiver.pvtCalculator.pvtT
    signal.Tunit = receiver.pvtCalculator.pvtT;
end

Tunit = signal.Tunit;
if receiver.timer.recvSOW ~= -1
%    Tres = receiver.pvtCalculator.pvtT - mod(receiver.timer.recvSOW, receiver.pvtCalculator.pvtT);
    
    if receiver.pvtCalculator.dataNum == 0   
        round_check = mod(receiver.timer.recvSOW, receiver.pvtCalculator.pvtT);
        if round_check >= receiver.pvtCalculator.pvtT/2
            timeAdd = 2 * receiver.pvtCalculator.pvtT - round_check;    % �������һ��������ʱ��С��pvtT/2�����һ��pvtTʱ��
        else
            timeAdd = receiver.pvtCalculator.pvtT - round_check;
        end 
        % ��ֹʣ��ʱ�䲻��(dataLoopNum-1) * signal.Tunit��ʱ�䣬�����һ��ѭ��N��С��0
        dataLoopNum = round(timeAdd/Tunit); % ����Ӧ�ı�dataLoopNum����ֵ
        receiver.pvtCalculator.dataNum = dataLoopNum;
        receiver.timer.tNext = receiver.timer.recvSOW + timeAdd;
    end
    if receiver.pvtCalculator.dataNum == 1 
        Tunit = receiver.timer.tNext - receiver.timer.recvSOW;
    end
    
    receiver.pvtCalculator.dataNum = receiver.pvtCalculator.dataNum - 1;
end
N = ceil(GSAR_CONSTANTS.STR_RECV.fs * Tunit); 
