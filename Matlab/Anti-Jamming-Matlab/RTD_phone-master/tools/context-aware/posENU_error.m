function [parameter] = posENU_error(parameter, calibration, fileType)

for i = 1 : parameter.length
    if fileType==1 || fileType==2
        [~, col] = ismember(parameter.SOW(1, i), calibration.SOW(1,:));
        parameter.ENU_error(1:3, i) = xyz2enu(parameter.pos_xyz(:, i), calibration.pos_xyz(:, col));
    else
        parameter.ENU_error(1:3, i) = xyz2enu(parameter.pos_xyz(:, i), calibration.pos_xyz(:, 1)); % ��̬���ݶԱȽ��
    end
    theata = parameter.vel_angle(i) / 360 * 2 * pi;
    % ������������������������ ����� ����������������������������%
    parameter.ENU_error(4, i) = norm(parameter.ENU_error(1:3, i));
    % ������������������������ ƽ���ں����ϵ���� ����������������������������%
    vect_1 = parameter.ENU_error(1:2, i);
    vect_2 = [sin(theata); cos(theata)];
    parameter.ENU_error(5, i) = abs(dot(vect_1, vect_2));
    % ������������������������ �����ں����ϵ���� ����������������������������%
    vect_1 = [parameter.ENU_error(1:2, i); 0]; % ��������������ά��
    vect_2 = [sin(theata); cos(theata); 0];
    parameter.ENU_error(6, i) = norm(cross(vect_1, vect_2));
    % ������������������������ ƽ�м����� ����������������������������%
    parameter.ENU_error(7, i) = parameter.ENU_error(5, i) - parameter.ENU_error(6, i);
end