% Compute Val = || Xs - X || + b and its Jacobian.
function [Val, Jacob] = obsEquation_MP(X)
% �۲����
% Each row of SV is the coordinate of a satellite.

%����������������۲ⷽ�̡�������������������%

Jacob = blkdiag(1,1);

%��������������������Ԥ��۲�ֵ��������������������%
Val(1, 1) = X(1);  % Ԥ��ྶ�ӳ����
Val(2, 1) = X(2);  % Ԥ��ྶ�ӳ����ı仯��
end