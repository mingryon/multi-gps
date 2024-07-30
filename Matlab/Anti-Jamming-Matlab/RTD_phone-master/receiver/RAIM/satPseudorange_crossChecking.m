function satPseudorange_crossCheckPass = satPseudorange_crossChecking(SYST, eph, ephUpdate, last_pos, last_transmitime)

switch SYST
    case 'GPS_L1CA'
        [satPositions_eph, satClkCorr_eph] = gpsl1ca_calc_OneSatPosition(last_transmitime, eph);
        [satPositions_ephUpdate, satClkCorr_ephUpdate] = gpsl1ca_calc_OneSatPosition(last_transmitime, ephUpdate);
    case 'BDS_B1I'
        
end

pseudorange_eph = norm(satPositions_eph(1:3) - last_pos(1:3));
pseudorange_ephUpdate = norm(satPositions_ephUpdate(1:3) - last_pos(1:3));

satPseudorange_crossCheckPass = 0;
if abs(pseudorange_eph - pseudorange_ephUpdate)/1000 < 50 %[km]
    %�������α��Ĳ�ֵС��50���������ΪephUpdateΪ��Ч��
    satPseudorange_crossCheckPass = 1;
end