function [Xo,Po] = EKF_MP(Q,R,Z,Xi,Pi,T)
N_state = size(Xi, 1);    

[Xp, ~] = ConstantVelocity_MP(Xi, T);%1 ״̬Ԥ��ֵ

[~, fy] = ConstantVelocity_MP(Xp, T);%2 ״̬ת�ƾ���

[gXp, H] = obsEquation_MP(Xp);%3 �۲ⷽ�̣�  gXp��Ԥ��۲�ֵ   H���۲����

Pp = fy * Pi * fy.' + Q;%4 ����������Э�������

K = Pp * H' / (H * Pp * H.' + R);%5 �������˲�����
    
Xo = Xp + K * (Z - gXp);%6 ״̬����

I = eye(N_state, N_state);
Po = (I - K * H) * Pp;%7 ���º�����Э�������
    
 