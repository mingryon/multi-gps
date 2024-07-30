% Constant Velocity model for GPS navigation.
function [Val, Jacob] = ConstantVelocity_static(X, T)
% �˺���Ϊ����ģ���е�״̬ת�ƾ���
Val = zeros(size(X));
Val(4) = X(4) + T * X(5);     % λ��Ԥ��
Val([1,2,3,5]) = X([1,2,3,5]);      % Ԥ��λ�ñ��ֲ���
Jacob = [1,T; 0,1];
Jacob = blkdiag(1,1,1,Jacob);

end