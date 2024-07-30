function [mpError,pvtCalculator] = kalmanMp_BDS(parameter, rawP, inteDopp,activeChannel,codeDelay,mpCnr,pvtCalculator,codeDelay,mpCnr,CNR,parameter)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%
%
%
%
%
%
%
%
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
T = 1;  % �۲���1s
mpError = 0;
%������������ Set Q����������������%
Sf = 25;
Sg = 0.01;
Q = [Sf*T+Sg*T*T*T/3, Sg*T*T/2; Sg*T*T/2, Sg*T];

% ������������Set R����������������%
R = [49,0;0,0.01];  % variance of measurement error(pseudorange error)
% R = [];
% for ii = 1:size(activeChannel,2)
%     R = blkdiag(R, Rhoerror); 
% end
if codeDelay(2,activeChannel(2,1)) == 0
    pvtCalculator.kalman.mpPreTag(1) = 0;
else
    if pvtCalculator.kalman.mpPreTag(1) == 0
        if codeDelay(2,activeChannel(2,1))>=1 || codeDelay(2,activeChannel(2,1))<=0
            pvtCalculator.kalman.state_MP = [0;0];
        elseif codeDelay(2,activeChannel(2,1))>=0.2 && codeDelay(2,activeChannel(2,1))<=0.8 %&& parameter(codeDelay(activeChannel(2,1),2))>0.2 && parameter(codeDelay(activeChannel(2,1),2))<0.8
            pvtCalculator.kalman.state_MP = [16;0];
        elseif codeDelay(2,activeChannel(2,1))>=0.8  && codeDelay(2,activeChannel(2,1))<1
            pvtCalculator.kalman.state_MP = [(1-codeDelay(2,activeChannel(2,1)))*0.5*16;0];
        elseif codeDelay(2,activeChannel(2,1))>0 || codeDelay(2,activeChannel(2,1))<0.2
            pvtCalculator.kalman.state_MP = [codeDelay(2,activeChannel(2,1))*0.5*16;0];
        end
        pvtCalculator.kalman.P_MP = [10,0;0,0.1];
        pvtCalculator.kalman.mpPreTag(1) = 1;
        pvtCalculator.kalman.mp(activeChannel(2,1)).rawP = rawP(activeChannel(2,1));
        pvtCalculator.kalman.mp(activeChannel(2,1)).inteDopp = inteDopp(activeChannel(2,1));
    else
        X_MP = pvtCalculator.kalman.state_MP;     % ״̬����  N-by-1    ��̬ģ��ֻ����λ�ú��Ӳ�
        P_MP = pvtCalculator.kalman.P_MP;         % ���Э�������
    
        %�����������������������˲����¡���������������%
        %=== Initialization =======================================================
        %nmbOfIterations = 11;


        nmbOfSatellites = size(activeChannel, 2);


        %if length(activeChannel(1,:))>=4 && checkNGEO==1
            %=== Iteratively find receiver position ===================================
        %    for iter = 1:nmbOfIterations
        delta_rawP = rawP(activeChannel(2,1)) - pvtCalculator.kalman.mp(activeChannel(2,1)).rawP;
        pvtCalculator.kalman.mp(activeChannel(2,1)).rawP = rawP(activeChannel(2,1));
        delta_inteDopp = inteDopp(activeChannel(2,1)) - pvtCalculator.kalman.mp(activeChannel(2,1)).inteDopp;
        pvtCalculator.kalman.mp(activeChannel(2,1)).inteDopp = inteDopp(activeChannel(2,1));

        useNum = 0;     % ʹ�����ǵ���Ŀ//ÿ�ε�����Ҫ����
        if codeDelay(2,activeChannel(2,1))>=1 || codeDelay(2,activeChannel(2,1))<=0
            obsKalman(1,1) = 0;
        elseif codeDelay(2,activeChannel(2,1))>=0.2 && codeDelay(2,activeChannel(2,1))<=0.8 %&& parameter(codeDelay(activeChannel(2,1),2))>0.2 && parameter(codeDelay(activeChannel(2,1),2))<0.8
            obsKalman(1,1) = 16;
        elseif codeDelay(2,activeChannel(2,1))>=0.8  && codeDelay(2,activeChannel(2,1))<1
            obsKalman(1,1) = (1-codeDelay(2,activeChannel(2,1)))*0.5*16;
        elseif codeDelay(2,activeChannel(2,1))>0 || codeDelay(2,activeChannel(2,1))<0.2
            obsKalman(1,1) = (codeDelay(2,activeChannel(2,1)))*0.5*16;
        end
        obsKalman(1,1) = codeDelay(2,activeChannel(2,1));
        obsKalman(2,1) = delta_rawP - delta_inteDopp;

        [X_MP,P_MP] = EKF_MP(Q,R,obsKalman,X_MP,P_MP,T);
        pvtCalculator.kalman.state_MP = X_MP;
        pvtCalculator.kalman.P_MP = P_MP;
        mpError = X_MP(1);
    end
end
% for i = 1:nmbOfSatellites         
%     useNum = useNum + 1;
%     
%     obsKalman(2*useNum-1,1) = obs(activeChannel(2,i)) - trop;   % �������˲��е�α��۲�ֵ
%     obsKalman(2*useNum,1) = [(-(Rot_X(1, activeChannel(2,i)) - pos(1))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
%                                 (-(Rot_X(2, activeChannel(2,i)) - pos(2))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro') ...
%                                 (-(Rot_X(3, activeChannel(2,i)) - pos(3))) / norm(Rot_X(:, activeChannel(2,i)) - pos(1:3), 'fro')]*satVel(:,activeChannel(2,i))...
%                                 + deltaP + 299792458*satClkCorr(activeChannel(2,i)); % �������˲��еĶ�����Ƶ�ƹ۲�ֵ
%     satKalman(useNum,1:3) = Rot_X(:,activeChannel(2,i))';     % �������˲��е�����λ��     N-by-6
%     satKalman(useNum,4:6) = satVel(:,activeChannel(2,i))';
%     elUse(useNum) = el.BDS(1,i);
% end % for i = 1:nmbOfSatellites
        
       
% satUsed = posiChannel(2,:);  % ����λ�����ٶȽ�������Ǻ�
% bEsti = omc - A/(A'*A)*A'*omc;    % �������
% WSSE = (norm(bEsti))^2;         % �����ֵ
% if WSSE < chi2inv(0.99999, size(A,1)-4)     % ����ж��д������ǣ��򲻾����������ж�
%     for j= useNum:-1:1  %ȥ�����ǵ���elevationMask������
%          if elUse(j) < elevationMask            
%              if size(A,1) >= 4
%                  satUsed(j)=[];
%              end
%          end
%     end
% end
          
% [X_static,P_MP] = EKF_static(Q,R,obsKalman,X_static,P_MP,satKalman,T,posiChannel);
% 
% 
% %�������������������˲����״̬��ֵ��������������������%
% pvtCalculator.kalman.state_static = X_static;     % ״̬����  N-by-1
% pvtCalculator.kalman.P_static = P_MP;         % Э�������
% pos = X_static([1,2,3,4]);
% %vel = X_static([2,4,6,8]);
% posvel = [pos',0,0,0,0,0,0];




