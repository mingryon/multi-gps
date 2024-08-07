% Compute Val = || Xs - X || + b and its Jacobian.
function [Val, Jacob] = obsEquation_static(X, SV)
% �۲����
% Each row of SV is the coordinate of a satellite.
dX = bsxfun(@minus, X([1,2,3])', SV(:,1:3));% ����λ������ջ�λ�ò�
%����������������۲ⷽ�̡�������������������%
Jacob = zeros(2*size(SV, 1), size(X, 1));
Jacob(1:2:2*size(SV,1), [1,2,3]) = bsxfun(@rdivide, dX, sum(dX .^2, 2) .^0.5);
Jacob(2:2:2*size(SV,1), [1,2,3]) = 0;
Jacob(1:2:2*size(SV,1), 4) = 1;
Jacob(2:2:2*size(SV,1), 5) = 1;
%��������������������Ԥ��۲�ֵ��������������������%
Val(1:2:2*size(SV,1), 1) = sum(dX .^2, 2) .^0.5 + X(4);  % Ԥ��α��ֵ
Val(2:2:2*size(SV,1), 1) = X(5);  % Ԥ�������Ƶ��
end