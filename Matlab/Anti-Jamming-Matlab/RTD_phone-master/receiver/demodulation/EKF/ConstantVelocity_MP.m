function [Val, Jacob] = ConstantVelocity_MP(X, T)
% �˺���Ϊ����ģ���е�״̬ת�ƾ���
Val = zeros(size(X));
Val(1) = X(1) + T * X(2);     % λ��Ԥ��
Val(2) = X(2);      % Ԥ��λ�ñ��ֲ���
Jacob = [1,T; 0,1];


end