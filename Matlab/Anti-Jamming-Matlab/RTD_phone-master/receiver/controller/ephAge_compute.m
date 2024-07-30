function ephemerisAge = ephAge_compute(SYST, timer, eph)
% ����������Чʱ��
switch SYST
    case 'BDS_B1I'
        timeDiff = timer.recvSOW_BDS - eph.toe;
        ephemerisAge = check_t(timeDiff);
    case 'GPS_L1CA'
        timeDiff = timer.recvSOW_GPS - eph.toe;
        ephemerisAge = check_t(timeDiff);
end