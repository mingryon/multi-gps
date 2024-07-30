% Compute Val = || Xs - X || + b and its Jacobian.
function [Val, Jacob] = obsEquation(X, SV)
% �۲����
% Each row of SV is the coordinate of a satellite.
dX = bsxfun(@minus, X([1,3,5])', SV(:,1:3));% ����λ������ջ�λ�ò�
%����������������۲ⷽ�̡�������������������%
Jacob = zeros(2*size(SV, 1), size(X, 1));
Jacob(1:2:2*size(SV,1), [1,3,5]) = bsxfun(@rdivide, dX, sum(dX .^2, 2) .^0.5);
Jacob(2:2:2*size(SV,1), [2,4,6]) = bsxfun(@rdivide, dX, sum(dX .^2, 2) .^0.5);
Jacob(1:2:2*size(SV,1), 7) = 1;
Jacob(2:2:2*size(SV,1), 8) = 1;
%��������������������Ԥ��۲�ֵ��������������������%
Val(1:2:2*size(SV,1), 1) = sum(dX .^2, 2) .^0.5 + X(7);  % Ԥ��α��ֵ
Val(2:2:2*size(SV,1), 1) = Jacob(2:2:2*size(SV,1), [2,4,6,8]) * X([2,4,6,8]);  % Ԥ�������Ƶ��
end